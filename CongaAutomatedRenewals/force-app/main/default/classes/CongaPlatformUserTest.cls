@isTest
public class CongaPlatformUserTest {

    // ACCOUNT AI PROVISIONING SETTINGS TEST METADATA
    private static Id NamedUserProductId {get; set;}
    public static Account_AI_Provisioning_Settings__mdt AccountAIProvisioningTestMeta {
    get {
        Map<String, Object> metaFieldValues = new Map<String, Object>{ 
            'Named_User_Product_Id__c' => NamedUserProductId
        };
        Account_AI_Provisioning_Settings__mdt customTestMeta = (Account_AI_Provisioning_Settings__mdt)TestingUtility.createTestMeta('Account_AI_Provisioning_Settings__mdt', metaFieldValues);
        AccountAIProvisioningTestMeta = customTestMeta;
        return AccountAIProvisioningTestMeta;
    } set; }

    @testSetup 
    private static void setup() {
        Id rAcctTypeId = [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND DeveloperName = 'Business_Account'][0].Id;
        Id rAssetTypeId = [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE IsActive = true AND SobjectType = 'Asset' AND DeveloperName = 'Standard'][0].Id;

        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 3);
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].RecordTypeId = rAcctTypeId;
        testAccounts[1].Name = 'Winter is Coming';
        testAccounts[1].RecordTypeId = rAcctTypeId;
        testAccounts[2].Name = 'worst final ever';
        testAccounts[2].RecordTypeId = rAcctTypeId;
        insert testAccounts;

        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 5);
        for (Integer i = 0; i < 5; i++) {
            if (i < 2) {
                testContacts[i].AccountId = testAccounts[0].Id;
            }
            else if(i < 4) {
                testContacts[i].AccountId = testAccounts[1].Id;
            }
            else testContacts[i].AccountId = testAccounts[2].Id;
            testContacts[i].FirstName = 'Test';
            testContacts[i].LastName = 'Contact'+String.valueOf(i);
            if(i!=4) testContacts[i].Email = 'test'+String.valueOf(i)+'@contact.com';
        }
        insert testContacts;

        List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
        for (AccountContactRelation acr : [SELECT Id, Roles FROM AccountContactRelation]) {
            acr.Roles = 'Admin';
            acrsToUpdate.add(acr);
        }
        update acrsToUpdate;

        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', true, 1);
        testProducts[0].Name = 'Test Product ' + String.valueOf(0);
        testProducts[0].ProductCode = 'prod' + String.valueOf(0);
        testProducts[0].Product_Line__c = 'Conga AI';
        insert testProducts;

        List<Asset> testAssets = (List<Asset>)TestingUtility.createSObjectList('Asset', true, 2);
        for (Integer i = 0; i < 2; i++) {
            if (i ==0 ) {
                testAssets[i].AccountId = testAccounts[0].Id;
            } else {
                testAssets[i].AccountId = testAccounts[1].Id;
            }
            testAssets[i].Product2Id = testProducts[0].Id;
            testAssets[i].RecordTypeId = rAssetTypeId;
            testAssets[i].Type__c = 'Subscription';
            testAssets[i].Quantity = 10;
            testAssets[i].Start_Date__c = System.today();
            testAssets[i].End_Date__c = System.today().addYears(1);
            testAssets[i].Name = 'Asset '+String.valueOf(i);
        }
        insert testAssets;
    }

    @isTest
    private static void ExistingDataReturnSuccess(){
        Conga_Platform_API__c cpa = new Conga_Platform_API__c();
        cpa.ResourceManagementBaseURL__c = 'https://na-dev-platform.congaplatform.com/v1/resourcemanagement';
        cpa.Username__c = 'testUser';
        cpa.Password__c = 'testPassword';
        cpa.AuthenticationURL__c = 'https://na-dev-platform.congaplatform.com/v1/access/login';
        cpa.APIKey__c = 'testkey';
        insert cpa;
        List<Account> accounts = [Select Id, Name FROM Account];
        List<CongaPlatformUserController.ContactWrapper> contactWrapper= CongaPlatformUserController.getContactList(String.valueOf(accounts[0].Id));

        List<Asset> assets = CongaPlatformUserController.getAssetList(String.valueOf(accounts[0].Id));
        Map<string,HttpResponse> responses = new Map<string,HttpResponse>();
        String baseURL = cpa.ResourceManagementBaseURL__c;

        // SET NAMED USER PRODUCT ID
        NamedUserProductId = assets[0].Product2Id;

        HttpResponse authRes = new HttpResponse();
        authRes.setHeader('Content-Type', 'application/json');
        authRes.setBody('{"idtoken": "u23hnbnbkn3j423"}');
        authRes.setStatusCode(200);
        responses.put(cpa.AuthenticationURL__c,authRes);

        HttpResponse accountResp = new HttpResponse();
        accountResp.setHeader('Content-Type', 'application/json');
        accountResp.setBody('{"accountId":"be4ca50c-e113-45b3-84a6-9470de3a21ad","name":"' + String.valueOf(accounts[0].Name) + '","externalId":{"id":"' + String.valueOf(accounts[0].Id) + '","type":"salesforce"},"regionAffinity":{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"United States","regionCode":"US"}}');
        accountResp.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ACCOUNT_EXTERNAL, new List<String> { 'salesforce', String.valueOf(accounts[0].Id) }), accountResp);

        HttpResponse regionAffinityResponse = new HttpResponse();
        regionAffinityResponse.setHeader('Content-Type', 'application/json');
        regionAffinityResponse.setBody('[{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"Colorado","regionCode":"US-CO"},{"regionAffinityId":"87be6776-0afc-40d3-9265-55846c98a834","name":"United States","regionCode":"US"},{"regionAffinityId":"7b264d78-2a68-40a7-8696-e18a366a0fce","name":"Canada","regionCode":"CA"}]');
        regionAffinityResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_REGION_AFFINITY, regionAffinityResponse);

        HttpResponse userResponse = new HttpResponse();
        userResponse.setHeader('Content-Type', 'application/json');
        userResponse.setBody('{"externalId":{"id":"' + String.valueOf(contactWrapper[0].ContactId) + '","type":"salesforce"},"userId":"71a0bbbc-dc8e-4287-906c-024b4e2926f4","userName":"' + String.valueOf(ContactWrapper[0].Email) + '","emailAddress":"' + String.valueOf(ContactWrapper[0].Email) + '","givenName":"' + String.valueOf(ContactWrapper[0].FirstName) + '","familyName":"' + String.valueOf(ContactWrapper[0].LastName) + '"}');
        userResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_EXTERNAL, new List<String> { 'salesforce', String.valueOf(ContactWrapper[0].ContactId) }), userResponse);

        HttpResponse connectedUserResponse = new HttpResponse();
        connectedUserResponse.setHeader('Content-Type', 'application/json');
        connectedUserResponse.setBody('{"userId":"71a0bbbc-dc8e-4287-906c-024b4e2926f4","userName":"' + String.valueOf(ContactWrapper[0].Email) + '","accountId":"be4ca50c-e113-45b3-84a6-9470de3a21ad","emailAddress":"' + String.valueOf(ContactWrapper[0].Email) + '","givenName":"' + String.valueOf(ContactWrapper[0].FirstName) + '","familyName":"' + String.valueOf(ContactWrapper[0].LastName) + '","isActive":true,"displayName":"' + String.valueOf(ContactWrapper[0].Email) + '"}');
        connectedUserResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_ACCOUNT, new List<String> { 'be4ca50c-e113-45b3-84a6-9470de3a21ad', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), connectedUserResponse);

        HttpResponse productResponse = new HttpResponse();
        productResponse.setHeader('Content-Type', 'application/json');
        productResponse.setBody('{"productId":"c6dcec0e-3046-4f30-8976-6daf0e502de5","name":"Test Product","rootScopeName":"test_analyze","externalId":{"id":"' + String.valueOf(assets[0].Product2Id) + '","type":"salesforce"}}');
        productResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_PRODUCT_EXTERNAL, new List<String> { 'Salesforce', String.valueOf(assets[0].Product2Id) }), productResponse);

        HttpResponse assetResponse = new HttpResponse();
        assetResponse.setHeader('Content-Type', 'application/json');
        assetResponse.setBody('{"assetId":"9f4420bb-ee1b-43df-9b09-daf7fea01336","externalId":{"id":"' + String.valueOf(assets[0].Id) + '","type":"salesforce"},"accountId":"be4ca50c-e113-45b3-84a6-9470de3a21ad","accountName":"' + String.valueOf(Accounts[0].Name) + '","productId":"jds3523l-jadljf34-fjhf23h-fjkdln238","productName":"Test Product","designeeType":"namedUser"}');
        assetResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSET_EXTERNAL, new List<String> { 'salesforce', String.valueOf(assets[0].Id) }), assetResponse);

        HttpResponse userDesigneeResponse = new HttpResponse();
        userDesigneeResponse.setHeader('Content-Type', 'application/json');
        userDesigneeResponse.setBody('[{"licenseDesigneeId": "3hfiu3-3h9hfh3-38fjdnf3-vjannb3"}]');
        userDesigneeResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USER_DESIGNEE, new List<String> { 'be4ca50c-e113-45b3-84a6-9470de3a21ad', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), userDesigneeResponse);

        HttpResponse userLicenseResponse = new HttpResponse();
        userLicenseResponse.setHeader('Content-Type', 'application/json');
        userLicenseResponse.setBody('{"assetId": "nnb3jds-32h4jkb-bjkdsf3-xeuhfw32"}');
        userLicenseResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USER_LICENSES, new List<String> { 'be4ca50c-e113-45b3-84a6-9470de3a21ad', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), userLicenseResponse);

        Test.setMock(HttpCalloutMock.class, new MockConfigurableHttpResponseGenerator(responses));
        Test.startTest();
        String result = CongaPlatformUserController.createCongaAccount(String.valueOf(accounts[0].Id), contactWrapper, assets);
        Test.stopTest();
        System.assertEquals('SUCCESS', result);
    } 

    @isTest
    private static void NewDataReturnSuccess(){
        Conga_Platform_API__c cpa = new Conga_Platform_API__c();
        cpa.ResourceManagementBaseURL__c = 'https://na-dev-platform.congaplatform.com/v1/resourcemanagement';
        cpa.Username__c = 'testUser';
        cpa.Password__c = 'testPassword';
        cpa.AuthenticationURL__c = 'https://na-dev-platform.congaplatform.com/v1/access/login';
        cpa.APIKey__c = 'testkey';
        insert cpa;
        List<Account> accounts = [Select Id, Name FROM Account];
        List<CongaPlatformUserController.ContactWrapper> contactWrapper = CongaPlatformUserController.getContactList(String.valueOf(accounts[1].Id));
        //System.debug('contactWrapper='+contactWrapper);     
        List<Asset> assets = CongaPlatformUserController.getAssetList(String.valueOf(accounts[1].Id));
        Map<string,HttpResponse> responses = new Map<string,HttpResponse>();
        String baseURL = cpa.ResourceManagementBaseURL__c;

        // SET NAMED USER PRODUCT ID
        NamedUserProductId = assets[0].Product2Id;

        HttpResponse authRes = new HttpResponse();
        authRes.setHeader('Content-Type', 'application/json');
        authRes.setBody('{"idtoken": "u23hnbnbkn3j423"}');
        authRes.setStatusCode(200);
        responses.put(cpa.AuthenticationURL__c,authRes);

        HttpResponse regionAffinityResponse = new HttpResponse();
        regionAffinityResponse.setHeader('Content-Type', 'application/json');
        regionAffinityResponse.setBody('[{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"Colorado","regionCode":"US-CO"},{"regionAffinityId":"87be6776-0afc-40d3-9265-55846c98a834","name":"United States","regionCode":"US"},{"regionAffinityId":"7b264d78-2a68-40a7-8696-e18a366a0fce","name":"Canada","regionCode":"CA"}]');
        regionAffinityResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_REGION_AFFINITY, regionAffinityResponse);

        HttpResponse accountCreateResp = new HttpResponse();
        accountCreateResp.setHeader('Content-Type', 'application/json');
        accountCreateResp.setBody('{"accountId":"6f5d751d-7d18-4ac6-b6b7-a03fbc278984","firstUserId":"ec0ff159-1fe2-4735-9b41-5120b6fb1177"}');
        accountCreateResp.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_ACCOUNTS, accountCreateResp);
        
        HttpResponse userCreateResponse = new HttpResponse();
        userCreateResponse.setHeader('Content-Type', 'application/json');
        userCreateResponse.setBody('{"userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"}');
        userCreateResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_USERS, userCreateResponse);

        HttpResponse connectedUserCreateResponse = new HttpResponse();
        connectedUserCreateResponse.setHeader('Content-Type', 'application/json');
        connectedUserCreateResponse.setBody('{"userId": "ec0ff159-1fe2-4735-9b41-5120b6fb1177"}');
        connectedUserCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_ACCOUNT, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), connectedUserCreateResponse);

        HttpResponse productResponse = new HttpResponse();
        productResponse.setHeader('Content-Type', 'application/json');
        productResponse.setBody('{"productId":"c6dcec0e-3046-4f30-8976-6daf0e502de5","name":"Test Product","rootScopeName":"test_analyze","externalId":{"id":"' + String.valueOf(assets[0].Product2Id) + '","type":"salesforce"}}');
        productResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_PRODUCT_EXTERNAL, new List<String> { 'salesforce', String.valueOf(assets[0].Product2Id) }), productResponse);

        HttpResponse assetCreateResponse = new HttpResponse();
        assetCreateResponse.setHeader('Content-Type', 'application/json');
        assetCreateResponse.setBody('{"assetId":"a4c98f3d-bd16-4ed3-9b69-929e53c85cf0","externalId":{"id":"' + String.valueOf(assets[0].Id) + '","type":"salesforce"},"accountId":"be4ca50c-e113-45b3-84a6-9470de3a21ad","accountName":"' + String.valueOf(Accounts[0].Name) + '","productId":"jds3523l-jadljf34-fjhf23h-fjkdln238","productName":"Test Product","designeeType":"namedUser"}');
        assetCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSETS, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984' }), assetCreateResponse);

        HttpResponse userDesigneeResponse = new HttpResponse();
        userDesigneeResponse.setHeader('Content-Type', 'application/json');
        userDesigneeResponse.setStatusCode(404);
        userDesigneeResponse.setBody('[]');
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USER_DESIGNEE, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), userDesigneeResponse);

        HttpResponse userDesigneeCreateResponse = new HttpResponse();
        userDesigneeCreateResponse.setHeader('Content-Type', 'application/json');
        userDesigneeCreateResponse.setBody('{"licenseDesigneeId":"6a9bd5ec-87e2-4044-813d-e7fd991a1860"}, "userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"');
        userDesigneeCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_LICENSE_DESIGNEES, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984' }), userDesigneeCreateResponse);

        HttpResponse userLicenseCreateResponse = new HttpResponse();
        userLicenseCreateResponse.setHeader('Content-Type', 'application/json');
        userLicenseCreateResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_ASSIGN_LICENSE, userLicenseCreateResponse);
        
        // jcdiaz - start
        /*
        HttpResponse userResponse1 = new HttpResponse();
        userResponse1.setHeader('Content-Type', 'application/json');
        userResponse1.setBody('{"externalId":{"id":"' + String.valueOf(contactWrapper[0].ContactId) + '","type":"salesforce"},"userId":"71a0bbbc-dc8e-4287-906c-024b4e2926f4","userName":"' + String.valueOf(ContactWrapper[0].Email) + '","emailAddress":"' + String.valueOf(ContactWrapper[0].Email) + '","givenName":"' + String.valueOf(ContactWrapper[0].FirstName) + '","familyName":"' + String.valueOf(ContactWrapper[0].LastName) + '"}');
        userResponse1.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_EXTERNAL, new List<String> { 'salesforce', String.valueOf(ContactWrapper[0].ContactId) }), userResponse1);       
        
        HttpResponse userResponse2 = new HttpResponse();
        userResponse2.setHeader('Content-Type', 'application/json');
        userResponse2.setBody('{"externalId":{"id":"' + String.valueOf(contactWrapper[1].ContactId) + '","type":"salesforce"},"userId":"71a0bbbc-dc8e-4287-906c-024b4e2926f4","userName":"' + String.valueOf(ContactWrapper[1].Email) + '","emailAddress":"' + String.valueOf(ContactWrapper[1].Email) + '","givenName":"' + String.valueOf(ContactWrapper[1].FirstName) + '","familyName":"' + String.valueOf(ContactWrapper[1].LastName) + '"}');
        userResponse2.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_EXTERNAL, new List<String> { 'salesforce', String.valueOf(ContactWrapper[1].ContactId) }), userResponse2);       
        */      

        HttpResponse assetResponse = new HttpResponse();
        assetResponse.setHeader('Content-Type', 'application/json');
        assetResponse.setBody('{"assetId":"9f4420bb-ee1b-43df-9b09-daf7fea01336","externalId":{"id":"' + String.valueOf(assets[0].Id) + '","type":"salesforce"},"accountId":"be4ca50c-e113-45b3-84a6-9470de3a21ad","accountName":"' + String.valueOf(Accounts[0].Name) + '","productId":"jds3523l-jadljf34-fjhf23h-fjkdln238","productName":"Test Product","designeeType":"namedUser"}');
        assetResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSET_EXTERNAL, new List<String> { 'salesforce', String.valueOf(assets[0].Id) }), assetResponse);      
        // jcdiaz - end

        Test.setMock(HttpCalloutMock.class, new MockConfigurableHttpResponseGenerator(responses));

        Test.startTest();
        String result = CongaPlatformUserController.createCongaAccount(String.valueOf(accounts[1].Id), contactWrapper, assets);
        Test.stopTest();
        System.assertEquals('SUCCESS', result);
    } 

    @isTest
    private static void BadRequest(){
        Map<string,HttpResponse> responses = new Map<string,HttpResponse>();
        Conga_Platform_API__c cpa = new Conga_Platform_API__c();
        cpa.ResourceManagementBaseURL__c = 'https://na-dev-platform.congaplatform.com/v1/resourcemanagement';
        cpa.Username__c = 'testUser';
        cpa.Password__c = 'testPassword';
        cpa.AuthenticationURL__c = 'https://na-dev-platform.congaplatform.com/v1/access/login';
        // cpa.APIKey__c = 'testkey';
        insert cpa;
        HttpResponse authRes = new HttpResponse();
        authRes.setHeader('Content-Type', 'application/json');
        authRes.setBody('{"idtoken": "u23hnbnbkn3j423"}');
        authRes.setStatusCode(200);
        responses.put(cpa.AuthenticationURL__c,authRes);
        // System.debug('CPAPI: '+ CPAPI.Id);
        // update CPAPI;
        Map<string,Object> params = new Map<string,Object>();
        params.put('method','GET');
        params.put('headers', new Map<String, Object>{ 'Content-Type'=>'application/json'});
        params.put('route', CongaPlatformConstants.API_REGION_AFFINITY);

        Test.setMock(HttpCalloutMock.class, new MockConfigurableHttpResponseGenerator(responses));
        Test.startTest();
        HttpResponse result = CongaPlatformConnector.generateCallout(params);
        Test.stopTest();
        System.assertEquals('UNAUTHORIZED', result.getStatus());
    }

    @isTest
    private static void NewDataValidationError(){
        Conga_Platform_API__c cpa = new Conga_Platform_API__c();
        cpa.ResourceManagementBaseURL__c = 'https://na-dev-platform.congaplatform.com/v1/resourcemanagement';
        cpa.Username__c = 'testUser';
        cpa.Password__c = 'testPassword';
        cpa.AuthenticationURL__c = 'https://na-dev-platform.congaplatform.com/v1/access/login';
        cpa.APIKey__c = 'testkey';
        insert cpa;
        List<Account> accounts = [Select Id, Name FROM Account];
        List<CongaPlatformUserController.ContactWrapper> contactWrapper = CongaPlatformUserController.getContactList(String.valueOf(accounts[2].Id));
        //System.debug('contactWrapper='+contactWrapper);     
        List<Asset> assets = CongaPlatformUserController.getAssetList(String.valueOf(accounts[2].Id));
        Map<string,HttpResponse> responses = new Map<string,HttpResponse>();
        String baseURL = cpa.ResourceManagementBaseURL__c;

        HttpResponse authRes = new HttpResponse();
        authRes.setHeader('Content-Type', 'application/json');
        authRes.setBody('{"idtoken": "u23hnbnbkn3j423"}');
        authRes.setStatusCode(200);
        responses.put(cpa.AuthenticationURL__c,authRes);

        HttpResponse regionAffinityResponse = new HttpResponse();
        regionAffinityResponse.setHeader('Content-Type', 'application/json');
        regionAffinityResponse.setBody('[{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"Colorado","regionCode":"US-CO"},{"regionAffinityId":"87be6776-0afc-40d3-9265-55846c98a834","name":"United States","regionCode":"US"},{"regionAffinityId":"7b264d78-2a68-40a7-8696-e18a366a0fce","name":"Canada","regionCode":"CA"}]');
        regionAffinityResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_REGION_AFFINITY, regionAffinityResponse);

        HttpResponse accountCreateResp = new HttpResponse();
        accountCreateResp.setHeader('Content-Type', 'application/json');
        accountCreateResp.setBody('{"accountId":"6f5d751d-7d18-4ac6-b6b7-a03fbc278984","firstUserId":"ec0ff159-1fe2-4735-9b41-5120b6fb1177"}');
        accountCreateResp.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_ACCOUNTS, accountCreateResp);

        // jcdiaz - end
        String result = '';
        Test.setMock(HttpCalloutMock.class, new MockConfigurableHttpResponseGenerator(responses));
        try{
            Test.startTest();
             result = CongaPlatformUserController.createCongaAccount(String.valueOf(accounts[1].Id), contactWrapper, assets);
            Test.stopTest();
        }catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
            
        }
        //System.debug('result message: '+result);
    } 

    
    @isTest
    private static void ConnectAccountUserTest(){
        Conga_Platform_API__c cpa = new Conga_Platform_API__c();
        cpa.ResourceManagementBaseURL__c = 'https://na-dev-platform.congaplatform.com/v1/resourcemanagement';
        cpa.Username__c = 'testUser';
        cpa.Password__c = 'testPassword';
        cpa.AuthenticationURL__c = 'https://na-dev-platform.congaplatform.com/v1/access/login';
        cpa.APIKey__c = 'testkey';
        insert cpa;
        List<Account> accounts = [Select Id, Name FROM Account];
        List<CongaPlatformUserController.ContactWrapper> contactWrapper = CongaPlatformUserController.getContactList(String.valueOf(accounts[0].Id));
        //System.debug('contactWrapper='+contactWrapper);     
        List<Asset> assets = CongaPlatformUserController.getAssetList(String.valueOf(accounts[0].Id));
        Map<string,HttpResponse> responses = new Map<string,HttpResponse>();
        String baseURL = cpa.ResourceManagementBaseURL__c;

        // SET NAMED USER PRODUCT ID
        NamedUserProductId = assets[0].Product2Id;

        HttpResponse authRes = new HttpResponse();
        authRes.setHeader('Content-Type', 'application/json');
        authRes.setBody('{"idtoken": "u23hnbnbkn3j423"}');
        authRes.setStatusCode(200);
        responses.put(cpa.AuthenticationURL__c,authRes);

        HttpResponse regionAffinityResponse = new HttpResponse();
        regionAffinityResponse.setHeader('Content-Type', 'application/json');
        regionAffinityResponse.setBody('[{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"Colorado","regionCode":"US-CO"},{"regionAffinityId":"87be6776-0afc-40d3-9265-55846c98a834","name":"United States","regionCode":"US"},{"regionAffinityId":"7b264d78-2a68-40a7-8696-e18a366a0fce","name":"Canada","regionCode":"CA"}]');
        regionAffinityResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_REGION_AFFINITY, regionAffinityResponse);

        HttpResponse accountCreateResp = new HttpResponse();
        accountCreateResp.setHeader('Content-Type', 'application/json');
        accountCreateResp.setBody('{"accountId":"6f5d751d-7d18-4ac6-b6b7-a03fbc278984","firstUserId":"ec0ff159-1fe2-4735-9b41-5120b6fb1177"}');
        accountCreateResp.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_ACCOUNTS, accountCreateResp);
        
        HttpResponse accountResp = new HttpResponse();
        accountResp.setHeader('Content-Type', 'application/json');
        accountResp.setBody('{"accountId":"6f5d751d-7d18-4ac6-b6b7-a03fbc278984","name":"' + String.valueOf(accounts[0].Name) + '","externalId":{"id":"' + String.valueOf(accounts[0].Id) + '","type":"salesforce"},"regionAffinity":{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"United States","regionCode":"US"}}');
        accountResp.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ACCOUNT_EXTERNAL, new List<String> { 'salesforce', String.valueOf(accounts[0].Id) }), accountResp);

        HttpResponse userCreateResponse = new HttpResponse();
        userCreateResponse.setHeader('Content-Type', 'application/json');
        userCreateResponse.setBody('{"userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"}');
        userCreateResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_USERS, userCreateResponse);

        HttpResponse connectedUserCreateResponse = new HttpResponse();
        connectedUserCreateResponse.setHeader('Content-Type', 'application/json');
        connectedUserCreateResponse.setBody('{"userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"}');
        connectedUserCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_ACCOUNT, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), connectedUserCreateResponse);

        HttpResponse productResponse = new HttpResponse();
        productResponse.setHeader('Content-Type', 'application/json');
        productResponse.setBody('{"productId":"c6dcec0e-3046-4f30-8976-6daf0e502de5","name":"Test Product","rootScopeName":"test_analyze","externalId":{"id":"' + String.valueOf(assets[0].Product2Id) + '","type":"salesforce"}}');
        productResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_PRODUCT_EXTERNAL, new List<String> { 'salesforce', String.valueOf(assets[0].Product2Id) }), productResponse);

        HttpResponse assetCreateResponse = new HttpResponse();
        assetCreateResponse.setHeader('Content-Type', 'application/json');
        assetCreateResponse.setBody('{"assetId":"a4c98f3d-bd16-4ed3-9b69-929e53c85cf0","externalId":{"id":"' + String.valueOf(assets[0].Id) + '","type":"salesforce"},"accountId":"6f5d751d-7d18-4ac6-b6b7-a03fbc278984","accountName":"' + String.valueOf(Accounts[0].Name) + '","productId":"jds3523l-jadljf34-fjhf23h-fjkdln238","productName":"Test Product","designeeType":"namedUser"}');
        assetCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSETS, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984' }), assetCreateResponse);

        HttpResponse userDesigneeResponse = new HttpResponse();
        userDesigneeResponse.setHeader('Content-Type', 'application/json');
        userDesigneeResponse.setStatusCode(404);
        userDesigneeResponse.setBody('[]');
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USER_DESIGNEE, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), userDesigneeResponse);

        HttpResponse userDesigneeCreateResponse = new HttpResponse();
        userDesigneeCreateResponse.setHeader('Content-Type', 'application/json');
        userDesigneeCreateResponse.setBody('{"licenseDesigneeId":"6a9bd5ec-87e2-4044-813d-e7fd991a1860"}, "userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"');
        userDesigneeCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_LICENSE_DESIGNEES, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984' }), userDesigneeCreateResponse);

        HttpResponse userLicenseCreateResponse = new HttpResponse();
        userLicenseCreateResponse.setHeader('Content-Type', 'application/json');
        userLicenseCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSIGN_LICENSE,new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984', '6a9bd5ec-87e2-4044-813d-e7fd991a1860' }), userLicenseCreateResponse);
        
        // jcdiaz - start
        HttpResponse userResponse1 = new HttpResponse();
        userResponse1.setHeader('Content-Type', 'application/json');
        userResponse1.setBody('{"externalId":{"id":"' + String.valueOf(contactWrapper[0].ContactId) + '","type":"salesforce"},"userId":"71a0bbbc-dc8e-4287-906c-024b4e2926f4","userName":"' + String.valueOf(ContactWrapper[0].Email) + '","emailAddress":"' + String.valueOf(ContactWrapper[0].Email) + '","givenName":"' + String.valueOf(ContactWrapper[0].FirstName) + '","familyName":"' + String.valueOf(ContactWrapper[0].LastName) + '"}');
        userResponse1.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_EXTERNAL, new List<String> { 'salesforce', String.valueOf(ContactWrapper[0].ContactId) }), userResponse1);       
        /*
        HttpResponse userResponse2 = new HttpResponse();
        userResponse2.setHeader('Content-Type', 'application/json');
        userResponse2.setBody('{"externalId":{"id":"' + String.valueOf(contactWrapper[1].ContactId) + '","type":"salesforce"},"userId":"71a0bbbc-dc8e-4287-906c-024b4e2926f4","userName":"' + String.valueOf(ContactWrapper[1].Email) + '","emailAddress":"' + String.valueOf(ContactWrapper[1].Email) + '","givenName":"' + String.valueOf(ContactWrapper[1].FirstName) + '","familyName":"' + String.valueOf(ContactWrapper[1].LastName) + '"}');
        userResponse2.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_EXTERNAL, new List<String> { 'salesforce', String.valueOf(ContactWrapper[1].ContactId) }), userResponse2);       
        */      

        HttpResponse assetResponse = new HttpResponse();
        assetResponse.setHeader('Content-Type', 'application/json');
        assetResponse.setBody('{"assetId":"9f4420bb-ee1b-43df-9b09-daf7fea01336","externalId":{"id":"' + String.valueOf(assets[0].Id) + '","type":"salesforce"},"accountId":"be4ca50c-e113-45b3-84a6-9470de3a21ad","accountName":"' + String.valueOf(Accounts[0].Name) + '","productId":"jds3523l-jadljf34-fjhf23h-fjkdln238","productName":"Test Product","designeeType":"namedUser"}');
        assetResponse.setStatusCode(400);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSET_EXTERNAL, new List<String> { 'salesforce', String.valueOf(assets[0].Id) }), assetResponse);      
        // jcdiaz - end

        Test.setMock(HttpCalloutMock.class, new MockConfigurableHttpResponseGenerator(responses));

        Test.startTest();
        String result = CongaPlatformUserController.createCongaAccount(String.valueOf(accounts[0].Id), contactWrapper, assets);
        Test.stopTest();
        System.assertEquals('SUCCESS', result);
    }

    @isTest
    private static void NoConnectedAccountUserTest(){
        Conga_Platform_API__c cpa = new Conga_Platform_API__c();
        cpa.ResourceManagementBaseURL__c = 'https://na-dev-platform.congaplatform.com/v1/resourcemanagement';
        cpa.Username__c = 'testUser';
        cpa.Password__c = 'testPassword';
        cpa.AuthenticationURL__c = 'https://na-dev-platform.congaplatform.com/v1/access/login';
        cpa.APIKey__c = 'testkey';
        insert cpa;
        List<Account> accounts = [Select Id, Name FROM Account];
        List<CongaPlatformUserController.ContactWrapper> contactWrapper = CongaPlatformUserController.getContactList(String.valueOf(accounts[0].Id));
        //System.debug('contactWrapper='+contactWrapper);     
        List<Asset> assets = CongaPlatformUserController.getAssetList(String.valueOf(accounts[0].Id));
        Map<string,HttpResponse> responses = new Map<string,HttpResponse>();
        String baseURL = cpa.ResourceManagementBaseURL__c;

        // SET NAMED USER PRODUCT ID
        NamedUserProductId = assets[0].Product2Id;

        HttpResponse authRes = new HttpResponse();
        authRes.setHeader('Content-Type', 'application/json');
        authRes.setBody('{"idtoken": "u23hnbnbkn3j423"}');
        authRes.setStatusCode(200);
        responses.put(cpa.AuthenticationURL__c,authRes);

        HttpResponse regionAffinityResponse = new HttpResponse();
        regionAffinityResponse.setHeader('Content-Type', 'application/json');
        regionAffinityResponse.setBody('[{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"Colorado","regionCode":"US-CO"},{"regionAffinityId":"87be6776-0afc-40d3-9265-55846c98a834","name":"United States","regionCode":"US"},{"regionAffinityId":"7b264d78-2a68-40a7-8696-e18a366a0fce","name":"Canada","regionCode":"CA"}]');
        regionAffinityResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_REGION_AFFINITY, regionAffinityResponse);

        HttpResponse accountCreateResp = new HttpResponse();
        accountCreateResp.setHeader('Content-Type', 'application/json');
        accountCreateResp.setBody('{"accountId":"6f5d751d-7d18-4ac6-b6b7-a03fbc278984","firstUserId":"ec0ff159-1fe2-4735-9b41-5120b6fb1177"}');
        accountCreateResp.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_ACCOUNTS, accountCreateResp);
        
        HttpResponse accountResp = new HttpResponse();
        accountResp.setHeader('Content-Type', 'application/json');
        accountResp.setBody('{"accountId":"6f5d751d-7d18-4ac6-b6b7-a03fbc278984","name":"' + String.valueOf(accounts[0].Name) + '","externalId":{"id":"' + String.valueOf(accounts[0].Id) + '","type":"salesforce"},"regionAffinity":{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"United States","regionCode":"US"}}');
        accountResp.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ACCOUNT_EXTERNAL, new List<String> { 'salesforce', String.valueOf(accounts[0].Id) }), accountResp);

        HttpResponse userCreateResponse = new HttpResponse();
        userCreateResponse.setHeader('Content-Type', 'application/json');
        userCreateResponse.setBody('{"userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"}');
        userCreateResponse.setStatusCode(200);
        responses.put(baseURL + CongaPlatformConstants.API_USERS, userCreateResponse);

        HttpResponse connectedUserCreateResponse = new HttpResponse();
        connectedUserCreateResponse.setHeader('Content-Type', 'application/json');
        connectedUserCreateResponse.setBody('{"userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"}');
        connectedUserCreateResponse.setStatusCode(400);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_ACCOUNT, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), connectedUserCreateResponse);

        HttpResponse CreateconnectionUserCreateResponse = new HttpResponse();
        connectedUserCreateResponse.setHeader('Content-Type', 'application/json');
        connectedUserCreateResponse.setBody('{"userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"}');
        connectedUserCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_ACCOUNT, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984'}), CreateconnectionUserCreateResponse);

        HttpResponse productResponse = new HttpResponse();
        productResponse.setHeader('Content-Type', 'application/json');
        productResponse.setBody('{"productId":"c6dcec0e-3046-4f30-8976-6daf0e502de5","name":"Test Product","rootScopeName":"test_analyze","externalId":{"id":"' + String.valueOf(assets[0].Product2Id) + '","type":"salesforce"}}');
        productResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_PRODUCT_EXTERNAL, new List<String> { 'salesforce', String.valueOf(assets[0].Product2Id) }), productResponse);

        HttpResponse assetCreateResponse = new HttpResponse();
        assetCreateResponse.setHeader('Content-Type', 'application/json');
        assetCreateResponse.setBody('{"assetId":"a4c98f3d-bd16-4ed3-9b69-929e53c85cf0","externalId":{"id":"' + String.valueOf(assets[0].Id) + '","type":"salesforce"},"accountId":"6f5d751d-7d18-4ac6-b6b7-a03fbc278984","accountName":"' + String.valueOf(Accounts[0].Name) + '","productId":"jds3523l-jadljf34-fjhf23h-fjkdln238","productName":"Test Product","designeeType":"namedUser"}');
        assetCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSETS, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984' }), assetCreateResponse);

        HttpResponse userDesigneeResponse = new HttpResponse();
        userDesigneeResponse.setHeader('Content-Type', 'application/json');
        userDesigneeResponse.setStatusCode(404);
        userDesigneeResponse.setBody('[]');
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USER_DESIGNEE, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984', '71a0bbbc-dc8e-4287-906c-024b4e2926f4' }), userDesigneeResponse);

        HttpResponse userDesigneeCreateResponse = new HttpResponse();
        userDesigneeCreateResponse.setHeader('Content-Type', 'application/json');
        userDesigneeCreateResponse.setBody('{"licenseDesigneeId":"6a9bd5ec-87e2-4044-813d-e7fd991a1860"}, "userId": "71a0bbbc-dc8e-4287-906c-024b4e2926f4"');
        userDesigneeCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_LICENSE_DESIGNEES, new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984' }), userDesigneeCreateResponse);

        HttpResponse userLicenseCreateResponse = new HttpResponse();
        userLicenseCreateResponse.setHeader('Content-Type', 'application/json');
        userLicenseCreateResponse.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSIGN_LICENSE,new List<String> { '6f5d751d-7d18-4ac6-b6b7-a03fbc278984', '6a9bd5ec-87e2-4044-813d-e7fd991a1860' }), userLicenseCreateResponse);
        
        // jcdiaz - start
        HttpResponse userResponse1 = new HttpResponse();
        userResponse1.setHeader('Content-Type', 'application/json');
        userResponse1.setBody('{"externalId":{"id":"' + String.valueOf(contactWrapper[0].ContactId) + '","type":"salesforce"},"userId":"71a0bbbc-dc8e-4287-906c-024b4e2926f4","userName":"' + String.valueOf(ContactWrapper[0].Email) + '","emailAddress":"' + String.valueOf(ContactWrapper[0].Email) + '","givenName":"' + String.valueOf(ContactWrapper[0].FirstName) + '","familyName":"' + String.valueOf(ContactWrapper[0].LastName) + '"}');
        userResponse1.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_EXTERNAL, new List<String> { 'salesforce', String.valueOf(ContactWrapper[0].ContactId) }), userResponse1);       
        /*
        HttpResponse userResponse2 = new HttpResponse();
        userResponse2.setHeader('Content-Type', 'application/json');
        userResponse2.setBody('{"externalId":{"id":"' + String.valueOf(contactWrapper[1].ContactId) + '","type":"salesforce"},"userId":"71a0bbbc-dc8e-4287-906c-024b4e2926f4","userName":"' + String.valueOf(ContactWrapper[1].Email) + '","emailAddress":"' + String.valueOf(ContactWrapper[1].Email) + '","givenName":"' + String.valueOf(ContactWrapper[1].FirstName) + '","familyName":"' + String.valueOf(ContactWrapper[1].LastName) + '"}');
        userResponse2.setStatusCode(200);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_USERS_EXTERNAL, new List<String> { 'salesforce', String.valueOf(ContactWrapper[1].ContactId) }), userResponse2);       
        */      

        HttpResponse assetResponse = new HttpResponse();
        assetResponse.setHeader('Content-Type', 'application/json');
        assetResponse.setBody('{"assetId":"9f4420bb-ee1b-43df-9b09-daf7fea01336","externalId":{"id":"' + String.valueOf(assets[0].Id) + '","type":"salesforce"},"accountId":"be4ca50c-e113-45b3-84a6-9470de3a21ad","accountName":"' + String.valueOf(Accounts[0].Name) + '","productId":"jds3523l-jadljf34-fjhf23h-fjkdln238","productName":"Test Product","designeeType":"namedUser"}');
        assetResponse.setStatusCode(400);
        responses.put(baseURL + String.format(CongaPlatformConstants.API_ASSET_EXTERNAL, new List<String> { 'salesforce', String.valueOf(assets[0].Id) }), assetResponse);      
        // jcdiaz - end

        Test.setMock(HttpCalloutMock.class, new MockConfigurableHttpResponseGenerator(responses));

        Test.startTest();
        String result = CongaPlatformUserController.createCongaAccount(String.valueOf(accounts[0].Id), contactWrapper, assets);
        Test.stopTest();
        System.assertEquals('SUCCESS', result);
    }

    @isTest
    private static void ResponseErrorConnectAccountUserTest(){
        Conga_Platform_API__c cpa = new Conga_Platform_API__c();
        cpa.ResourceManagementBaseURL__c = 'https://na-dev-platform.congaplatform.com/v1/resourcemanagement';
        cpa.Username__c = 'testUser';
        cpa.Password__c = 'testPassword';
        cpa.AuthenticationURL__c = 'https://na-dev-platform.congaplatform.com/v1/access/login';
        cpa.APIKey__c = 'testkey';
        insert cpa;

        List<Account> accounts = [Select Id, Name FROM Account];
        List<CongaPlatformUserController.ContactWrapper> contactWrapper = CongaPlatformUserController.getContactList(String.valueOf(accounts[0].Id));
        //System.debug('contactWrapper='+contactWrapper);     
        List<Asset> assets = CongaPlatformUserController.getAssetList(String.valueOf(accounts[0].Id));
        Map<string,HttpResponse> responses = new Map<string,HttpResponse>();
        String baseURL = cpa.ResourceManagementBaseURL__c;

        // SET NAMED USER PRODUCT ID
        NamedUserProductId = assets[0].Product2Id;

        HttpResponse authRes = new HttpResponse();
        authRes.setHeader('Content-Type', 'application/json');
        authRes.setBody('{"idtoken": "u23hnbnbkn3j423"}');
        authRes.setStatusCode(200);
        responses.put(cpa.AuthenticationURL__c,authRes);

        HttpResponse regionAffinityResponse = new HttpResponse();
        regionAffinityResponse.setHeader('Content-Type', 'application/json');
        regionAffinityResponse.setBody('[{"regionAffinityId":"ab22fa3e-b160-4862-bcfa-833cc2be071f","name":"Colorado","regionCode":"US-CO"},{"regionAffinityId":"87be6776-0afc-40d3-9265-55846c98a834","name":"United States","regionCode":"US"},{"regionAffinityId":"7b264d78-2a68-40a7-8696-e18a366a0fce","name":"Canada","regionCode":"CA"}]');
        regionAffinityResponse.setStatusCode(400);
        responses.put(baseURL + CongaPlatformConstants.API_REGION_AFFINITY, regionAffinityResponse);

        // jcdiaz - end
        string result = '';
        Test.setMock(HttpCalloutMock.class, new MockConfigurableHttpResponseGenerator(responses));

        try{
            Test.startTest();
             result = CongaPlatformUserController.createCongaAccount(String.valueOf(accounts[0].Id), contactWrapper, assets);
            Test.stopTest();
        }
        catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
            
        }
    } 



}