public with sharing class CongaPlatformUserController {

	public class CongaPlatformUserControllerException extends Exception {}

    // ACCOUNT AI PROVISIONING SETTINGS METADATA
    private static Account_AI_Provisioning_Settings__mdt AccountAIProvisioningSettings {
    get {
        if(AccountAIProvisioningSettings == null){
        	if(Test.isRunningTest()){
               AccountAIProvisioningSettings = CongaPlatformUserTest.AccountAIProvisioningTestMeta;
            }
            else{
	            AccountAIProvisioningSettings = [SELECT Id, Named_User_Product_Id__c FROM Account_AI_Provisioning_Settings__mdt LIMIT 1];
	        }
        }
        return AccountAIProvisioningSettings;
    } set; }


	//RETURN CONTACT WRAPPER TO DISPLAY TO USER FOR CONGA USER SELECTION
	@AuraEnabled(cacheable=true)	
    public static List<ContactWrapper> getContactList(String pAccountId) {
        try{
            List<AccountContactRelation> acrs = [SELECT Id, Roles, Contact.Id, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email FROM AccountContactRelation WHERE AccountId = :pAccountId];
            List<ContactWrapper> contactsToReturn = new List<ContactWrapper>();
            for (AccountContactRelation acr : acrs) {
                ContactWrapper cw = new ContactWrapper();
                cw.IsChecked = false;
                cw.FirstName = acr.Contact.FirstName;
                cw.LastName = acr.Contact.LastName;
                cw.DisplayName= acr.Contact.Name;
                cw.Email = acr.Contact.Email;
                cw.Roles = acr.Roles;
                cw.SObjectId = acr.Id;
                cw.ContactId = acr.Contact.Id;
                contactsToReturn.add(cw);
            }
            return contactsToReturn;
		}
		catch(Exception e) {
			System.debug(e.getMessage() + '\r\n' + e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}
    }

    //RETURN ALL CONGA AI ASSETS TO CATCH ERROR UP FRONT IF ASSETS DO NOT EXIST
    @AuraEnabled(cacheable=true)
    public static List<Asset> getAssetList(String pAccountId){
        try{
        	return [SELECT Id, Name, Product2Id, Quantity, Start_Date__c, End_Date__c, Entitlement_Status__c, Type__c FROM Asset
        			WHERE Entitlement_Status__c = 'Active' AND AccountId = :pAccountId AND Product2.Product_Line__c = 'Conga AI' AND Quantity > 0];
		}
		catch(Exception e) {
			System.debug(e.getMessage() + '\r\n' + e.getStackTraceString());			
			throw new AuraHandledException(e.getMessage());
		}
    }

	//INITIATE THE CREATION OF A CONGA ACCOUNT
	@AuraEnabled
    public static String createCongaAccount(String pAccountId, List<ContactWrapper> pUsersToCreate, List<Asset> pAssets) {
		try {
			//HttpResponse platformResponse = getCongaPlatformAccount(pAccountId, pUsersToCreate, pAssets);
			ResponseWrapper resWrap = getCongaPlatformAccount(pAccountId, pUsersToCreate, pAssets);
			//if (platformResponse.getStatusCode() >= 200 && platformResponse.getStatusCode() < 300) {
			Integer statusCode = resWrap.response.getStatusCode();
			if (statusCode >= 200 && statusCode < 300) {
				if (resWrap.createdUserContactIds != null && !resWrap.createdUserContactIds.isEmpty()){
					createContactsTask(resWrap.createdUserContactIds);
				}
				return 'SUCCESS';
			}
			else {
				return 'ERROR';
			}
		}
		catch(Exception e) {
			System.debug(e.getMessage() + '\r\n' + e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}
    }

    //CHECK IF THE CONGA ACCOUNT ALREADY EXISTS
    //public static HttpResponse getCongaPlatformAccount(String pAccountId, List<ContactWrapper> pUsersToCreate, List<Asset> pAssets) {
	public static ResponseWrapper getCongaPlatformAccount(String pAccountId, List<ContactWrapper> pUsersToCreate, List<Asset> pAssets) {		
		HttpResponse finalResult;
		Account acc = [SELECT Id, Name FROM Account WHERE Id = :pAccountId][0];
		Map<string,Object> accParams = new Map<string,Object>();
		accParams.put('method','GET');
		accParams.put('route', String.format(CongaPlatformConstants.API_ACCOUNT_EXTERNAL, new List<String> { 'salesforce', acc.Id }));
		HttpResponse accRes = CongaPlatformConnector.generateCallout(accParams);
		Integer statusCode = accRes.getStatusCode();
		if(statusCode >= 200 && statusCode < 300) {
			Map<String, Object> accBody = (Map<String, Object>)JSON.deserializeUntyped(accRes.getBody());
			ResponseWrapper resWrap = getCongaUsers(String.valueOf(accBody.get('accountId')), pUsersToCreate, pAssets);

			finalResult = resWrap.response;
			if (finalResult != null && (finalResult.getStatusCode() >= 200 && finalResult.getStatusCode() < 300)) {
				return resWrap;
			}
			else {
				//return accRes;
				return new ResponseWrapper(accRes,null);
			}
		}
		else{
			return createCongaPlatformAccount(acc, pUsersToCreate, pAssets);
		}
    }

    //GET THE REGION AFFINITY ID FOR THE ACCOUNT TODO: UPDATE TO USE ADDRESS AND NORMALIZE THE REGION
    public static String getRegionAffinity() {        
		Map<string,Object> params = new Map<string,Object>();
		params.put('method','GET');
		params.put('route', CongaPlatformConstants.API_REGION_AFFINITY);
		HttpResponse res = CongaPlatformConnector.generateCallout(params);
		Integer statusCode = res.getStatusCode();
		if (statusCode >= 200 && statusCode < 300) {
			List<Object> bodyMap = (List<Object>)JSON.deserializeUntyped(res.getBody());
			String regionAffinityId = '';			
			for (Object body : bodyMap) {
				Map<String, Object> regionBody = (Map<String, Object>)body;
				if (String.valueOf(regionBody.get('regionCode')) == 'US') {
					regionAffinityId = String.valueOf(regionBody.get('regionAffinityId'));
				}
			}
			return regionAffinityId;
		}
		else{
			throw new CongaPlatformUserControllerException(parseHttpResponseError('Unable to get Region Affinity.', res)); //TODO: Label.
		}
    }

    //IF CONGA ACCOUNT DOES NOT EXIST, CREATE ONE AS WELL AS THE FIRST USER IN THE LIST
    //public static HttpResponse createCongaPlatformAccount(Account pAccount, List<ContactWrapper> pUsersToCreate, List<Asset> pAssetsToCreate) {
	public static ResponseWrapper createCongaPlatformAccount(Account pAccount, List<ContactWrapper> pUsersToCreate, List<Asset> pAssetsToCreate) {
		//System.debug('createCongaPlatformAccount');
		HttpResponse res;
		HttpResponse finalResult;
		ResponseWrapper resWrap;
		if (pAccount != null) {
			JSONGenerator gen = JSON.createGenerator(true);   
			gen.writeStartObject();     
			gen.writeStringField('Name', pAccount.Name);
			gen.writeFieldName('ExternalId');
			gen.writeStartObject();
			gen.writeStringField('Id', pAccount.Id);
			gen.writeStringField('Type', 'Salesforce');
			gen.writeEndObject();
			gen.writeStringField('regionAffinityId', getRegionAffinity());
			if (pUsersToCreate.size() > 0) {
				validateContactFields(pUsersToCreate[0]);
				String email = pUsersToCreate[0].Email;
				String firstName = pUsersToCreate[0].FirstName;
				String lastName = pUsersToCreate[0].LastName;
				String contactId = pUsersToCreate[0].ContactId;
				gen.writeFieldName('firstUser');
				gen.writeStartObject();
				gen.writeStringField('emailAddress', email);
				gen.writeStringField('givenName', firstName); 
				gen.writeStringField('familyName', lastName);
				gen.writeStringField('displayName', email);
				gen.writeStringField('userName', email);
				gen.writeFieldName('ExternalId');
				gen.writeStartObject();
				gen.writeStringField('Id', contactId);
				gen.writeStringField('Type', 'Salesforce');
				gen.writeEndObject();
				gen.writeEndObject(); 
				pUsersToCreate.remove(0);
			} /*else {
				System.debug('Without users to create...');
			}*/
			gen.writeEndObject();   
			String jsonBodyString = gen.getAsString();

			Map<string,Object> params = new Map<string,Object>();
			params.put('method','POST');
			params.put('headers', new Map<String, Object>{ 'Content-Type'=>'application/json'});
			params.put('body', jsonBodyString);
			params.put('route', CongaPlatformConstants.API_ACCOUNTS);

			//System.debug(res);
			//System.debug(res.getStatusCode());

			res = CongaPlatformConnector.generateCallout(params);
			Integer statusCode = res.getStatusCode();
			if (statusCode >= 200 && statusCode < 300) {
				Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
				if (pUsersToCreate.size() > 0) {
					//System.debug('Create Users');
					resWrap = getCongaUsers(String.valueOf(body.get('accountId')), pUsersToCreate, pAssetsToCreate);
				}
				else if (pAssetsToCreate.size() > 0) {
					//System.debug('Create Assets');
					JSONGenerator userGen = JSON.createGenerator(true);   
					userGen.writeStartObject();     
					userGen.writeStringField('userId', String.valueOf(body.get('firstUserId')));
					userGen.writeEndObject();
					String userBodyString = userGen.getAsString();
					Set<String> users = new Set<String>();
					users.add(userBodyString);
					resWrap = getCongaAssets(String.valueOf(body.get('accountId')), pAssetsToCreate, users);
				}
			}

			//System.debug(finalResult);
			//System.debug(finalResult.getStatusCode());
			if (resWrap != null && resWrap.response != null && (resWrap.response.getStatusCode() >= 200 && resWrap.response.getStatusCode() < 300)) {
				return resWrap;
			}
			else {
				//return res;
				throw new CongaPlatformUserControllerException(parseHttpResponseError('Unable to create Conga Platform Account.', res)); //TODO: Label.
			}  
		}
		else {
			//return res;
			return new ResponseWrapper(res,null);
		}
	}
	
    //CHECK IF SELECTED CONTACTS EXIST AS CONGA USERS
    //public static HttpResponse getCongaUsers(String pAccountId, List<ContactWrapper> pUsersToCreate, List<Asset> pAssetsToCreate) {
	public static ResponseWrapper getCongaUsers(String pAccountId, List<ContactWrapper> pUsersToCreate, List<Asset> pAssetsToCreate) {
		HttpResponse res;
		Set<String> usersToConnect = new Set<String>();
		Set<ContactWrapper> usersToCreate = new Set<ContactWrapper>(pUsersToCreate);
		for (ContactWrapper cw : pUsersToCreate) {
			//System.debug('getCongaUsers.cw='+cw);
			Map<string,Object> params = new Map<string,Object>();
			params.put('method','GET');
			params.put('route', String.format(CongaPlatformConstants.API_USERS_EXTERNAL, new List<String> { 'salesforce', cw.ContactId }));
			//System.debug('getCongaUsers.route='+params.get('route'));
			res = CongaPlatformConnector.generateCallout(params);
			Integer statusCode = res.getStatusCode();
			//System.debug('getCongaUsers.statusCode='+statusCode);
			if (statusCode >= 200 && statusCode < 300) {
				Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
				if (body.get('userId') != null && body.get('accountId') != null) {
					usersToCreate.remove(cw);
				} else if (body.get('userId') != null) {
					usersToCreate.remove(cw);
					JSONGenerator userGen = JSON.createGenerator(true);
					userGen.writeStartObject();
					userGen.writeStringField('userId', String.valueOf(body.get('userId')));
					userGen.writeStringField('displayName', String.valueOf(body.get('userName')));
					userGen.writeEndObject(); 
					usersToConnect.add(userGen.getAsString());
				}
			}
		}
		if (usersToCreate.size() > 0) {
			//System.debug('getCongaUsers.usersToCreate.size() > 0');
			return createCongaUsers(pAccountId, usersToCreate, usersToConnect, pAssetsToCreate);
		} else if (usersToConnect.size() > 0) {
			//System.debug('getCongaUsers.usersToConnect.size() > 0');
			return getConnectedCongaUsers(pAccountId, usersToConnect, pAssetsToCreate);
		} else if (pAssetsToCreate.size() > 0) {
			//System.debug('getCongaUsers.pAssetsToCreate.size() > 0');
			return getCongaAssets(pAccountId, pAssetsToCreate, usersToConnect);
		} else {
			//return res;
			return new ResponseWrapper(res,null);
		}
    }
    
    //IF CONGA USERS DO NOT EXIST, CREATE THEM
    public static ResponseWrapper createCongaUsers(String pAccountId, Set<ContactWrapper> pUsersToCreate, Set<String> pUsersToConnect, List<Asset> pAssetsToCreate) {
		//System.debug('createCongaUsers');
		HttpResponse res;
		//if(pAccountId != '' && pAccountId != null){
		ResponseWrapper resWrap;
		Set<Id> createdUsersContactId = new Set<Id>(); //JCDIAZ
		if(String.isNotBlank(pAccountId)){			
			for (ContactWrapper cw : pUsersToCreate) {
				validateContactFields(cw);
				JSONGenerator gen = JSON.createGenerator(true);
				gen.writeStartObject();
				gen.writeStringField('emailAddress', cw.Email);
				gen.writeStringField('givenName', cw.FirstName);
				gen.writeStringField('familyName', cw.LastName);
				gen.writeStringField('userName', cw.Email);
				gen.writeFieldName('ExternalId');
				gen.writeStartObject();
				gen.writeStringField('Id', cw.ContactId);
				gen.writeStringField('Type', 'Salesforce');
				gen.writeEndObject();
				gen.writeEndObject();  
				String jsonBodyString = gen.getAsString();
				Map<string,Object> params = new Map<string,Object>();
				params.put('method','POST');
				params.put('headers', new Map<String, Object>{ 'Content-Type'=>'application/json'});
				params.put('body', jsonBodyString);
				params.put('route', CongaPlatformConstants.API_USERS);
				res = CongaPlatformConnector.generateCallout(params);

				Integer statusCode = res.getStatusCode();
				if (statusCode >= 200 && statusCode < 300) {
					createdUsersContactId.add(cw.ContactId); //JCDIAZ
					Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
					//System.debug('BODY='+body);
					JSONGenerator userGen = JSON.createGenerator(true);
					userGen.writeStartObject();
					userGen.writeStringField('userId', String.valueOf(body.get('userId')));
					userGen.writeStringField('displayName', cw.Email);
					userGen.writeEndObject(); 
					pUsersToConnect.add(userGen.getAsString());
				}
			}
		}

		if (pUsersToConnect.size() > 0) {
			//return getConnectedCongaUsers(pAccountId, pUsersToConnect, pAssetsToCreate);
			resWrap = getConnectedCongaUsers(pAccountId, pUsersToConnect, pAssetsToCreate);
			resWrap.createdUserContactIds = createdUsersContactId;
			return resWrap;
		}
		else if (pAssetsToCreate.size() > 0) {
			//return getCongaAssets(pAccountId, pAssetsToCreate, pUsersToConnect);
			resWrap = getCongaAssets(pAccountId, pAssetsToCreate, pUsersToConnect);
			resWrap.createdUserContactIds = createdUsersContactId;
			return resWrap;
		}
		else {
			//return res;
			return new ResponseWrapper(res,createdUsersContactId);
		}
    }

	//CHECK TO SEE IF USERS ARE ALREADY CONNECTED TO THE CONGA ACCOUNT
    //public static HttpResponse getConnectedCongaUsers(String pAccountId, Set<String> pUsersToConnect, List<Asset> pAssetsToCreate) {
	public static ResponseWrapper getConnectedCongaUsers(String pAccountId, Set<String> pUsersToConnect, List<Asset> pAssetsToCreate) {		
		HttpResponse res;
		Set<String> usersToConnect = new Set<String>(pUsersToConnect);
		Set<String> connectedUsers = new Set<String>();
		if(pAccountId != '' && pAccountId != null){
			for (String user : pUsersToConnect) {
				Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(user);
				Map<string,Object> params = new Map<string,Object>();
				params.put('method','GET');
				params.put('headers', new Map<String, Object>{ 'Content-Type'=>'application/json'});
				params.put('route', String.format(CongaPlatformConstants.API_USERS_ACCOUNT, new List<String> { pAccountId, String.valueOf(body.get('userId')) }));
				res = CongaPlatformConnector.generateCallout(params);
				Integer statusCode = res.getStatusCode();
				//System.debug('getConnectedCongaUsers.statusCode='+statusCode);
				if (statusCode >= 200 && statusCode < 300) {
					usersToConnect.remove(user);
					connectedUsers.add(user);
				}
			}
		}
		if (usersToConnect.size() > 0) {
			//System.debug('getConnectedCongaUsers.usersToConnect.size() > 0)');
			return connectAccountUsers(pAccountId, usersToConnect, connectedUsers, pAssetsToCreate);
		} else if (pAssetsToCreate.size() > 0) {
			//System.debug('getConnectedCongaUsers.pAssetsToCreate.size() > 0)');
			return getCongaAssets(pAccountId, pAssetsToCreate, connectedUsers);
		} else {
			//return res;
			return new ResponseWrapper(res,null);
		}
    }

    //IF CONGA USERS ARE NOT CONNECTED TO THE ACCOUNT, CONNECT THEM
    //public static HttpResponse connectAccountUsers(String pAccountId, Set<String> pUsersToConnect, Set<String> pConnectedUsers, List<Asset> pAssetsToCreate) {
	public static ResponseWrapper connectAccountUsers(String pAccountId, Set<String> pUsersToConnect, Set<String> pConnectedUsers, List<Asset> pAssetsToCreate) {		
		HttpResponse res;
		if(pAccountId != '' && pAccountId != null){
			for (String user : pUsersToConnect) {
				Map<string,Object> params = new Map<string,Object>();
				params.put('method','POST');
				params.put('headers', new Map<String, Object>{ 'Content-Type'=>'application/json'});
				params.put('body', user);
				params.put('route', String.format(CongaPlatformConstants.API_USERS_ACCOUNT, new List<String> { pAccountId }));
				res = CongaPlatformConnector.generateCallout(params);

				Integer statusCode = res.getStatusCode();
				if (statusCode >= 200 && statusCode < 300) {
					pConnectedUsers.add(res.getBody());
				}
			}
		}
		if (pAssetsToCreate.size() > 0) {
			return getCongaAssets(pAccountId, pAssetsToCreate, pConnectedUsers);
		} else {
			//return res;
			return new ResponseWrapper(res,null);
		}
    }

    //GET THE APPROPRIATE PRODUCT IN CONGA FOR THE ASSET TO BE LINKED TO
    public static String getCongaProduct(String pProductId) {
		Map<string,Object> params = new Map<string,Object>();
		params.put('method','GET');
		params.put('route', String.format(CongaPlatformConstants.API_PRODUCT_EXTERNAL, new List<String> { 'salesforce', pProductId }));
		HttpResponse res = CongaPlatformConnector.generateCallout(params);
		Integer statusCode = res.getStatusCode();
		if (statusCode >= 200 && statusCode < 300) {
			Map<string,Object> body = (Map<string,Object>)JSON.deserializeUntyped(res.getBody());
			String productId = String.valueOf(body.get('productId'));
			return productId;
		} else {
			//System.debug('getCongaProduct.params.route');
			//System.debug(params.get('route'));
			//System.debug('getCongaProduct.pProductId='+pProductId);
			throw new CongaPlatformUserControllerException(parseHttpResponseError('Unable to get Conga Product.', res)); //TODO: Label.
		}
	}
	
	/**
	 * @description Generic method to parse response object and obtain more information to communicate to the user interface.
	 */
	private static String parseHttpResponseError(String message, HttpResponse response) {
		if (response == null) return null;
		String status = response.getStatus();
		Integer statusCode = response.getStatusCode();
		String body = response.getBody();
		String errorMessage = message;
		if (!String.isBlank(status)) errorMessage += String.format(' Details: {0} ({1}) - {2}.',new String[] {status, String.valueOf(statusCode), body});
		return errorMessage.remove('{').remove('}');
	}

    //CHECK TO SEE IF THE CONGA ASSET ALREADY EXISTS
    //public static HttpResponse getCongaAssets(String pAccountId, List<Asset> pAssetsToCreate, Set<String> pUsers) {
	public static ResponseWrapper getCongaAssets(String pAccountId, List<Asset> pAssetsToCreate, Set<String> pUsers) {		
		HttpResponse res;
		Map<Id,String> congaAssetMap = new Map<Id,String>();
		Set<Asset> assestsToCreate = new Set<Asset>(pAssetsToCreate);
		if(pAccountId != '' && pAccountId != null){
			for (Asset asset : pAssetsToCreate) {
				Map<string,Object> params = new Map<string,Object>();
				params.put('method','GET');
				params.put('route', String.format(CongaPlatformConstants.API_ASSET_EXTERNAL, new List<String> { 'salesforce', asset.Id }));
				res = CongaPlatformConnector.generateCallout(params);
				Integer statusCode = res.getStatusCode();
				//System.debug('getCongaAssets.statusCode='+statusCode);
				if (statusCode >= 200 && statusCode < 300) {
					congaAssetMap.put(asset.Id, res.getBody());
					assestsToCreate.remove(asset);
				}
			}
		}
		if (assestsToCreate.size() > 0) {
			//System.debug('getCongaAssets.assestsToCreate.size() > 0');
			return createCongaAssets(pAccountId, assestsToCreate, pUsers, congaAssetMap);
		}
		else {
			//return res;
			return new ResponseWrapper(res,null);
		}
    }

    //IF THE CONGA ASSETS DO NOT EXIST, CREATE THEM
    //public static HttpResponse createCongaAssets(String pAccountId, Set<Asset> pAssetsToCreate, Set<String> pUsers, Map<Id,String> pCongaAssetMap) {
		public static ResponseWrapper createCongaAssets(String pAccountId, Set<Asset> pAssetsToCreate, Set<String> pUsers, Map<Id,String> pCongaAssetMap) {		
		HttpResponse res;
		System.debug(AccountAIProvisioningSettings);
		System.debug(AccountAIProvisioningSettings.Named_User_Product_Id__c);
		if (pAccountId != '' && pAccountId != null && AccountAIProvisioningSettings != null && AccountAIProvisioningSettings.Named_User_Product_Id__c != null) {
			for (Asset a : pAssetsToCreate) {
				//System.debug('a.Product2Id='+a.Product2Id);
				DateTime expiresAt = a.End_Date__c;
				JSONGenerator gen = JSON.createGenerator(true);
				gen.writeStartObject();     
				//gen.writeStringField('productId', getCongaProduct(a.Product2Id));
				gen.writeStringField('productId', getCongaProduct(AccountAIProvisioningSettings.Named_User_Product_Id__c)); // DEFAULT TO THE NAMED USER PRODUCT. ITS THE ONLY ONE
																															// THE PROVISIONING SYSTEM KNOWS ABOUT
				gen.writeStringField('designeeType', 'namedUser');
				gen.writeStringField('licenseType', a.Type__c == 'Consumable' ? 'perpetual' : 'expiring');
				gen.writeDateTimeField('expiresAt', expiresAt);
				gen.writeNumberField('licenseCount', a.Quantity);
				gen.writeFieldName('ExternalId');
				gen.writeStartObject();
				gen.writeStringField('Id', a.Id);
				gen.writeStringField('Type', 'Salesforce');
				gen.writeEndObject();
				gen.writeEndObject();   
				String jsonBodyString = gen.getAsString();

				Map<string,Object> params = new Map<string,Object>();
				params.put('method','POST');
				params.put('headers', new Map<String, Object>{ 'Content-Type'=>'application/json'});
				params.put('body', jsonBodyString);
				params.put('route', String.format(CongaPlatformConstants.API_ASSETS, new List<String> { pAccountId }));
				res = CongaPlatformConnector.generateCallout(params);

				Integer statusCode = res.getStatusCode();
				if (statusCode >= 200 && statusCode < 300) {
					Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
					pCongaAssetMap.put(a.Id, res.getBody());
				}
			}
		}
		if (pCongaAssetMap.size() > 0) {
			return getLicenseDesignees(pAccountId, pUsers, pCongaAssetMap);
		}
		else {
			//return res;
			return new ResponseWrapper(res,null);
		}
    }

    //CHECK TO SEE IF THE LICESNE DESIGNEES EXIST
    //public static HttpResponse getLicenseDesignees(String pAccountId, Set<String> pUsers, Map<Id,String> pCongaAssetMap) {
	public static ResponseWrapper getLicenseDesignees(String pAccountId, Set<String> pUsers, Map<Id,String> pCongaAssetMap) {
		HttpResponse res;
		Set<String> licenseDesigneesToCreate = new Set<String>(pUsers);
		List<String> licensesToAssign = new List<String>();
		if(pAccountId != '' && pAccountId != null){
			for (String user : pUsers) {
				Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(user);
				Map<string,Object> params = new Map<string,Object>();
				params.put('method','GET');
				params.put('route', String.format(CongaPlatformConstants.API_USER_DESIGNEE, new List<String> { pAccountId, String.valueOf(body.get('userId')) }));
				res = CongaPlatformConnector.generateCallout(params);
				Integer statusCode = res.getStatusCode();
				List<Object> bodyList = (List<Object>)JSON.deserializeUntyped(res.getBody());
				if (statusCode >= 200 && statusCode < 300 && bodyList.size() > 0) {
					licenseDesigneesToCreate.remove(user);
					for (Object designeeObject : bodyList) {
						licensesToAssign.add(JSON.serialize(designeeObject));
					}
				}
			}
		}
		if (licenseDesigneesToCreate.size() > 0) {
			return createLicenseDesignee(pAccountId, licenseDesigneesToCreate, pCongaAssetMap, licensesToAssign);
		} else if (licensesToAssign.size() > 0) {
			return getLicenses(pAccountId, licensesToAssign, pCongaAssetMap);
		} else {
			//return res;
			return new ResponseWrapper(res,null);
		}
    }

    //IF THE LICESNE DESIGNEES DO NOT EXIST, CREATE THEM
    //public static HttpResponse createLicenseDesignee(String pAccountId, Set<String> pUsers, Map<Id,String> pCongaAssetMap, List<String> pLicensesToAssign) {
	public static ResponseWrapper createLicenseDesignee(String pAccountId, Set<String> pUsers, Map<Id,String> pCongaAssetMap, List<String> pLicensesToAssign) {		
		HttpResponse res;
		for (String user : pUsers) {
			Map<string,Object> body = (Map<string,Object>)JSON.deserializeUntyped(user);
			JSONGenerator gen = JSON.createGenerator(true);   
			gen.writeStartObject();     
			gen.writeStringField('userId', String.valueOf(body.get('userId')));
			gen.writeEndObject();   
			String jsonBodyString = gen.getAsString();
			Map<string,Object> params = new Map<string,Object>();
			params.put('method','POST');
			params.put('headers', new Map<String, Object>{ 'Content-Type'=>'application/json'});
			params.put('body', jsonBodyString);
			params.put('route', String.format(CongaPlatformConstants.API_LICENSE_DESIGNEES, new List<String> { pAccountId }));
			res = CongaPlatformConnector.generateCallout(params);

			Integer statusCode = res.getStatusCode();
			if (statusCode >= 200 && statusCode < 300) {
				pLicensesToAssign.add(res.getBody());
			}
		}
		if (pLicensesToAssign.size() > 0) {
			return getLicenses(pAccountId, pLicensesToAssign, pCongaAssetMap);
		}
		else {
			//return res;
			return new ResponseWrapper(res,null);
		}
    }

    //CHECK TO SEE IF THE LICENSE DESGINEES HAVE BEEN ASSIGNED THE LICENSES
    //public static HttpResponse getLicenses(String pAccountId, List<String> pLicenseDesignees, Map<Id,String> pCongaAssetMap) {
	public static ResponseWrapper getLicenses(String pAccountId, List<String> pLicenseDesignees, Map<Id,String> pCongaAssetMap) {		
		HttpResponse res;
		Set<String> licenseDesigneesToCreate = new Set<String>(pLicenseDesignees);
		if(pAccountId != '' && pAccountId != null){
			for (String user : pLicenseDesignees) {
				Map<string,Object> body = (Map<string,Object>)JSON.deserializeUntyped(user);
				Map<string,Object> params = new Map<string,Object>();
				params.put('method','GET');
				params.put('route', String.format(CongaPlatformConstants.API_USER_LICENSES, new List<String> { pAccountId, String.valueOf(body.get('userId')) }));
				res = CongaPlatformConnector.generateCallout(params);

				Integer statusCode = res.getStatusCode();
				if (statusCode >= 200 && statusCode < 300) {
					List<Object> bodyMap = (List<Object>)JSON.deserializeUntyped(res.getBody());
					for (Object objBody : bodyMap) {
						Map<String, Object> designeeBody = (Map<String, Object>)objBody;
						Map<String, Object> externalAssetBody = (Map<String, Object>)designeeBody.get('assetExternalId');
						Map<String, Object> mapAssetBody = (Map<String, Object>)JSON.deserializeUntyped(pCongaAssetMap.get(String.valueOf(externalAssetBody.get('id'))));
						if (designeeBody.get('assetId') == mapAssetBody.get('assetId')) {
							licenseDesigneesToCreate.remove(user);
						}
					}
				}
			}
		}
		if (licenseDesigneesToCreate.size() > 0) {
			return assignLicenses(pAccountId, licenseDesigneesToCreate, pCongaAssetMap);
		}
		else {
			//return res;
			return new ResponseWrapper(res,null);
		}
    }

    //IF THE LICENSE DESIGNEES DO NOT HAVE THE LICENSES, CREATE THEM
    //public static HttpResponse assignLicenses(String pAccountId, Set<String> pLicenseDesignees, Map<Id,String> pCongaAssetMap) {
	public static ResponseWrapper assignLicenses(String pAccountId, Set<String> pLicenseDesignees, Map<Id,String> pCongaAssetMap) {		
		HttpResponse res;
		List<String> licenseAssignResponse = new List<String>();
		for (String licenseDesignee : pLicenseDesignees) {
			Map<String, Object> licenseDesigneeBody = (Map<String, Object>)JSON.deserializeUntyped(licenseDesignee);
			for (Id assetId : pCongaAssetMap.keySet()) {
				Map<string,Object> assetBody = (Map<string,Object>)JSON.deserializeUntyped(pCongaAssetMap.get(assetId));
				JSONGenerator gen = JSON.createGenerator(true);   
				gen.writeStartObject();     
				gen.writeStringField('assetId', String.valueOf(assetBody.get('assetId')));
				gen.writeEndObject();   
				String jsonBodyString = gen.getAsString();
				Map<string,Object> params = new Map<string,Object>();
				params.put('method','POST');
				params.put('headers', new Map<String, Object>{ 'Content-Type'=>'application/json'});
				params.put('body', jsonBodyString);
				params.put('route', String.format(CongaPlatformConstants.API_ASSIGN_LICENSE, new List<String> { pAccountId, String.valueOf(licenseDesigneeBody.get('licenseDesigneeId')) }));
				res = CongaPlatformConnector.generateCallout(params);

				Integer statusCode = res.getStatusCode();
				if (statusCode >= 200 && statusCode < 300) {
					licenseAssignResponse.add(res.getBody());
				}
			}
		}
		//return res;
		return new ResponseWrapper(res,null);
	}
	
	/**
	 * @description: Creates a task record for each contact id provided.
	 */
	public static void createContactsTask(Set<Id> contactIds) {
		//System.debug('createContactsTask');
		if (contactIds == null || contactIds.isEmpty()) return;
		Id currentUserId = UserInfo.getUserId();
		List<Task> tasks = new List<Task>();
		for (Id contactId : contactIds) {
			Task t = new Task(OwnerId=UserInfo.getUserId(), Subject='AI User provisioning request sent', Status='Open', Priority='Normal', WhoId = contactId); //TODO: Label.
			tasks.add(t);
		}

		if (!tasks.isEmpty()) insert tasks;
	}

	/**
	 * @description: Validates that all required fields of a Contact have a value before processing.
	 */
	private static void validateContactFields(ContactWrapper contact) {
		String email = contact.Email;
		//System.debug('contact.Email='+contact.Email);
		String firstName = contact.FirstName;
		//System.debug('contact.FirstName='+contact.FirstName);
		String lastName = contact.LastName;
		//System.debug('contact.LastName='+contact.LastName);
		String contactId = contact.ContactId;
		//System.debug('contact.ContactId='+contact.ContactId);
		if (!String.isBlank(email) && !String.isBlank(firstName) && !String.isBlank(lastName) && !String.isBlank(contactId)) return;
		List<String> blankFields = new List<String>();
		String errorMessage = 'The following fields from selected contact are blank: {0}. Please, complete this information and try again.'; //TODO: Label.
		if (String.isBlank(email)) blankFields.add(Schema.SObjectType.Contact.Fields.Email.Label);
		if (String.isBlank(firstName)) blankFields.add(Schema.SObjectType.Contact.Fields.FirstName.Label);
		if (String.isBlank(lastName)) blankFields.add(Schema.SObjectType.Contact.Fields.LastName.Label);
		if (String.isBlank(contactId)) blankFields.add(Schema.SObjectType.Contact.Fields.Id.Label);
		errorMessage = String.format(errorMessage, new List<String>{String.join(blankFields,', ')});
		throw new CongaPlatformUserControllerException(errorMessage);
	}

	///////////////////////
	// AUXILIARY CLASSES //
	///////////////////////

	//
	/**
	 * @description: Contact wrapper to easily display everything in a lightning component.
	 */
    public class contactWrapper {
		
        @AuraEnabled public Boolean IsChecked {get; set;} // CONTROLS SELECTED CONTACTS
        @AuraEnabled public String DisplayName {get;set;} //FULL NAME TO BE DISPLAYED
		@AuraEnabled public String FirstName {get;set;} //CONTACT FIRST NAME
        @AuraEnabled public String LastName {get;set;} //CONTACT LAST NAME
        @AuraEnabled public String Email {get;set;} //CONTACT EMAIL
		@AuraEnabled public String Roles {get;set;} //CONTACT ROLES
		@AuraEnabled public String SObjectId {get;set;} //CONTACT ROLE ID
        @AuraEnabled public String ContactId {get;set;} //CONTACT ID

	}

	/**
	 * @description: HttpResposeWrapper to handle additional values returned from different callouts.
	 */
	private class ResponseWrapper {
		public HttpResponse response {get;set;} 
		public Set<Id> createdUserContactIds  {get;set;}

		public ResponseWrapper(HttpResponse pResponse, Set<Id> pCreatedUserContactIds) {
			this.response = pResponse;
			this.createdUserContactIds = pCreatedUserContactIds;
		}
	}
}