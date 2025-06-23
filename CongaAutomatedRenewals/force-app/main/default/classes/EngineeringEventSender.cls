/**
* @author Mark Brundege
* @date 20200406
* @version 1.00
* @description EngineeringEventSender - Logic for sending Engineering_Event__e Platform Event objects to external endpoints
*/
public with sharing class EngineeringEventSender {

    /**
    * @description createEngineeringEvent - If a monitored field is updated, create a platformEvent
    *                                          --- EXECUTED AFTER INSERT AND AFTER UPDATE TRIGGERS --- objects will have Ids
    * @param List<sObject> newOrUpdatedObjects - New or Updated records
    * @param Map<Id, sObject> outdatedObjects - Outdated records
    * @return void
    */
    public static void createEngineeringEvent(List<sObject> newOrUpdatedObjects, Map<Id, sObject> outdatedObjects){
        try{
            if(TriggerHelper.DoExecute('EngineeringEventSender','createEngineeringEvent') && newOrUpdatedObjects != null){
                String objectName = newOrUpdatedObjects.get(0).getSObjectType().getDescribe().getName();
                // TODO: re-implement check below - how to set the metadata for that check for unit testing?????
                //if(!TriggerHelper.DoExecute(objectName + '.createEngEvent')){
                //    System.Debug('Trigger disabled - ' + objectName + '.createEngineeringEvent');
                //	return; //exit early
                //}

                //System.debug('going to possibly create engineering events for ' + newOrUpdatedObjects.size() + ' new or updated objects');
                
                //if (outdatedObjects == null) {
                //    System.debug('outdatedObjects is null');
                //} else {
                //    System.debug('outdatedObjects.size=' + outdatedObjects.size());
                //}
                
                List<Engineering_Event_Setting__mdt> engineeringEventSettings = EngineeringEventMDTHelper.getEngineeringEventSettings(objectName);
                //System.debug('Found ' + engineeringEventSettings.size() + ' fields for sobject of type ' + objectName);
           		String externalIdField = null;
                for(Engineering_Event_Setting__mdt eventSetting : engineeringEventSettings){
                    if(eventSetting.Is_External_Id__c){
                        externalIdField = eventSetting.Field_Name__c;
                        break;
                    }
                }
                
                List<Engineering_Event__e> newEngineeringEvents = new List<Engineering_Event__e>();
                for(sObject obj : newOrUpdatedObjects){
                    //System.debug('going to check if this object has a tracked change:');
                    //System.debug(obj);

                    Boolean createNewEvent = doesObjectHaveATrackedChange(engineeringEventSettings, obj, outdatedObjects);
                    if(createNewEvent){
                        //System.debug('it does have a tracked change');
                        Engineering_Event__e engEvent = new Engineering_Event__e();
                        engEvent.ExternalId_Object_Name__c = objectName;
                        engEvent.ExternalId__c = externalIdField;
                        engEvent.SalesforceId__c = obj.Id;
                        newEngineeringEvents.add(engEvent);
                    }
                    else {
                        //System.debug('it does NOT have a tracked change');
                    }
                }
                
                //System.debug('events ' + JSON.serialize(newEngineeringEvents));
                if(!newEngineeringEvents.isEmpty()){
                    List<Database.SaveResult> results = EventBus.publish(newEngineeringEvents);
                    SystemIssueLogHelper.CheckForDatabaseErrors(results, 'EngineeringEventSender', 'createEngineeringEvent', true);

                    //for(Database.SaveResult sr : results){
                    //    if (sr.success){
                    //        //System.debug('Successfully added EngineeringEvent to event bus: ' + EventBus.getOperationId(sr));
                    //    }
                    //    else {     
                    //        SystemIssueLogHelper.LogException('EngineeringEventSender', 'createEngineeringEvent', sr, 'Error Saving', false);
                    //        for(Database.Error err : sr.getErrors()) {
                    //        	//System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    //    	}
                    //    }
                    //}
                }
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('EngineeringEventSender', 'createEngineeringEvent', newOrUpdatedObjects, ex, false);
        }
    }
    

    /**
    * @description doesObjectHaveATrackedChange - Send Engineering Events to Conga Endpoint
    * @param List<Engineering_Event_Setting__mdt> engineeringEventSettings
    * @param sObject newEngineeringEvents obj
    * @param Map<Id, sObject> outdatedObjects
    * @return Boolean
    */
    public static Boolean doesObjectHaveATrackedChange(List<Engineering_Event_Setting__mdt> engineeringEventSettings, sObject obj, Map<Id, sObject> outdatedObjects) {
        if ( (outdatedObjects == null) || (outdatedObjects.size() == 0) ) {
            //System.debug('no outdated objects so returning true');
            return true;
        }
        sObject outdatedObj = outdatedObjects.get(obj.Id);
        if(outdatedObj != null) {
            //System.debug('going to compare against fields for this outdated object:');
            //System.debug(outdatedObj);
            //Look for only changes in the fields we are interested in
            for(Engineering_Event_Setting__mdt eventSetting : engineeringEventSettings){
                try {
                    if(!eventSetting.Is_External_Id__c){
                        if(obj.isSet(eventSetting.API_Name__c) && outdatedObj.isSet(eventSetting.API_Name__c) && 
                            obj.get(eventSetting.API_Name__c) != outdatedObj.get(eventSetting.API_Name__c)){
                            
                            return true;
                        }
                    }
                }
                catch (SObjectException sObjEx) {
                    SystemIssueLogHelper.LogException('EngineeringEventSender', 'doesObjectHaveATrackedChange', obj, sObjEx, true);
                    //System.debug('Error trying to read object fields: ' + sObjEx.getMessage());
                }
            }
            return false;
        }
        return true;
    }
    

    /**
    * @author JPesusich
    * @description sendEngineeringEvents - Send Engineering Events to Conga Endpoint
    * @param List<Engineering_Event__e> engineeringEvents
    * @return void
	*/
    public static void sendEngineeringEvents(List<Engineering_Event__e> engineeringEvents){
        try{
            if(TriggerHelper.DoExecute('EngineeringEventSender','sendEngineeringEvents') && engineeringEvents != null){
                // TODO: re-implement below when metadata updated ... how to unit test?
                //if(!TriggerHelper.DoExecute('EngineeringEvent.sendEngineeringEvents') || engineeringEvents == null || engineeringEvents.isEmpty()){
                //    return;
                //}
                //System.debug('EngineeringEventHelper.sendEngineeringEvents');
                Map<String, Engineering_Event__e> dedupedEvents = new Map<String, Engineering_Event__e>();
                for(Engineering_Event__e engineeringEvent : engineeringEvents) {
                    //create hash-like key for event
                    String key = getHashKeyForEvent(engineeringEvent);
                    if(String.isNotBlank(key) && !dedupedEvents.containsKey(key)){                
                        dedupedEvents.put(key,engineeringEvent);
                    }
                }

                if(!dedupedEvents.isEmpty()){
                    List<Engineering_Event__e> engEvents = dedupedEvents.values();
                    for(Engineering_Event__e engineeringEvent : engineeringEvents) {
                        String salesforceOrgJsonPayload = createSalesforceOrgPayload(engineeringEvent);
                        if (salesforceOrgJsonPayload != null) {
                            //System.debug('going to send this payload: ' + salesforceOrgJsonPayload);
                            sendEngineeringEventsAsync(salesforceOrgJsonPayload);
                        }
                    }
                }
            }
        }
        catch(Exception ex){
            //System.debug(ex);
            SystemIssueLogHelper.LogException('EngineeringEventSender', 'sendEngineeringEvents', engineeringEvents, ex, true);
        }
    }


    /**
    * @description createSalesforceOrgPayload - 
    * @param Engineering_Event__e salesforceOrgChangeEvent
    * @return String
    */
    private static String createSalesforceOrgPayload(Engineering_Event__e salesforceOrgChangeEvent) {
        //System.debug('going to transform this engineering_event into payload:');
        //System.debug(salesforceOrgChangeEvent);
        // {ExternalId_Object_Name__c=Salesforce_Org__c, ExternalId__c=, SalesforceId__c=a3m000000000000}
        String sfId = salesforceOrgChangeEvent.SalesforceId__c;
        String objectType = salesforceOrgChangeEvent.ExternalId_Object_Name__c;
        String msgId = salesforceOrgChangeEvent.ReplayId;
        String createdDateStr = datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        if (salesforceOrgChangeEvent.CreatedDate != null) {
            createdDateStr = salesforceOrgChangeEvent.CreatedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }
        
        String sfUrl = Url.getSalesforceBaseUrl().toExternalForm();
        if (objectType == 'Salesforce_Org__c') {
            return '{"MessageId":"' + msgId + '","SalesforceOrgId":"' + sfId + '","CreatedDateTime":"' + createdDateStr + '","Origin":"' + sfUrl + '"}';
        }
        return null;
    }
    
    
    /**
    * @description getHashKeyForEvent - 
    * @param Engineering_Event__e engineeringEvent
    * @return String
    */
    private static String getHashKeyForEvent(Engineering_Event__e engineeringEvent){
        if(engineeringEvent != null){
            //System.assert(engineeringEvent != null);

            List<String> keys = new List<String>();
            if(String.isNotBlank(engineeringEvent.SalesforceId__c)){
                keys.add(engineeringEvent.SalesforceId__c);
            }
            if(String.isNotBlank(engineeringEvent.ExternalId_Object_Name__c)){
                keys.add(engineeringEvent.ExternalId_Object_Name__c);
            }
            if(String.isNotBlank(engineeringEvent.ExternalId__c)){
                keys.add(engineeringEvent.ExternalId__c);
            }
            if(!keys.isEmpty()){
                return String.join(keys,'|');
            }
        }
        return null;
    }


	/**
    * @author JPesusich
    * @description sendEngineeringEventsAsync - Send Engineering Events to Conga Endpoint - FUTURE METHOD, HTTP CALLOUT
    * @param String body
    * @return void
	*/
	@future(callout=true)
	public static void sendEngineeringEventsAsync(String body){
		try{
            if(String.isNotBlank(body)){
                //System.debug('going to send this body to api endpoint: ' + body);

                Map<String,String> apiSettings = new Map<String,String>();
                List<Engineering_Event_API_Setting__mdt> mdtAPISettings = EngineeringEventMDTHelper.getEngineeringAPISettings();
                for(Engineering_Event_API_Setting__mdt mdtAPISetting : mdtAPISettings){
                    apiSettings.put(mdtAPISetting.DeveloperName.toLowerCase(), mdtAPISetting.Value__c);
                }


                String certificateName = apiSettings.get('certificate_name');
                String apiEndpoint = apiSettings.get('api_endpoint');
                String token = createJwtToken(certificateName, apiEndpoint);
                HttpRequest req = new HttpRequest();
                req.setHeader('Content-Type', 'application/json;charset=UTF-8');
                req.setHeader('Authorization', 'Bearer ' + token);
    			req.setEndpoint(apiEndpoint);
    			req.setMethod('POST');
    			req.setBody(body);
    			Http http = new Http();
                if ( (apiEndpoint != null) && (apiEndpoint.length() > 0) ) {
                    HttpResponse response = http.send(req);
                    Integer statusCode = response.getStatusCode();
                    if(statusCode >= 200 && statusCode < 400){
                        //System.debug('Successfully sent EngineeringEvent to remote API at ' + apiEndpoint);
                        return;
                    }
                    else{
                        // NOT SUCCESSFUL, LOG ERROR 
                        String httpErrorInfo = response.getStatusCode() + '' + response.getStatus() + ' - ' + response.getBody();
                        String errorMessage = 'Send Engineering Event HTTP Error: ' + httpErrorInfo;
                        SystemIssueLogHelper.LogException('EngineeringEventHelper', 'sendEngineeringEventsAsync', null, errorMessage, true);
                    }

                    //List<Object> parameters = new List<Object>{ apiEndpoint, response.getBody() };
                    //System.debug(string.format('Failed To POST to {0} for reason {1}',parameters));
                }
                else {
                     SystemIssueLogHelper.LogException('EngineeringEventHelper', 'sendEngineeringEventsAsync', null, 'No API endpoint was obtained from the metadata', true);
                    //System.debug('Did not send to API endpoint because no API endpoint was obtained from the metadata');
                }
            }
		}
        catch(Exception ex){
            //System.debug(ex);
            SystemIssueLogHelper.LogException('EngineeringEventHelper', 'sendEngineeringEventsAsync', body, ex, true);
        }
    }

    /**
    * @description createJwtToken - 
    * @param String certificateName
    * @param String apiEndpoint
    * @return String
    */    
    private static String createJwtToken (String certificateName, String apiEndpoint) {
        //System.debug('user info:');
        //System.debug(UserInfo.getOrganizationId());
        //System.debug(UserInfo.getUserName());
        //System.debug(UserInfo.getUserId());
        Auth.JWT jwt1 = new Auth.JWT();
        jwt1.setAud('Conga');
        jwt1.setIss(UserInfo.getOrganizationId());
        jwt1.setSub(UserInfo.getOrganizationId());

        Map<String,String> claims = new Map<String,String>();
        claims.put('sf_user_id',UserInfo.getUserId());
        claims.put('sf_org_id',UserInfo.getOrganizationId() );
        claims.put('authflow', 'client_certificate');
        claims.put('preferred_username', UserInfo.getUserName());

        jwt1.setAdditionalClaims(claims);

        Auth.JWS jws1 = new Auth.JWS(jwt1, certificateName);
        String encoded = jws1.getCompactSerialization();
        //System.debug('encoded from jws: ' + encoded);
        return encoded;
    }
    
    
}