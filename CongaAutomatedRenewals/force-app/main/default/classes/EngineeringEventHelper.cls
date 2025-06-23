/**
* @author Jordan Pesusich
* @date 20200317
* @version 1.00
* @description EngineeringEventHelper - provides data for the EngineeringEvent_REST_Data_v1 endpoint
*/
public with sharing class EngineeringEventHelper {

    /**
    * @description retrieveAccountRelatedObject - 
    */
    public static Map<String, Object> retrieveAccountRelatedObject (String salesforceId, String externalId, String externalIdObjectName) {
        // TODO: add lookup logic for other objects besides Salesforce_Org__c as their use-cases are defined
        if (isSalesforceOrgId(salesforceId)) {
            return retrieveSalesforceOrg(salesforceId);
        }
        else {
            String errorMessage = 'Unsupported Salesforce ID: ' + salesforceId + ' Only Salesforce_Org__c retrievals are supported at this time';
            SystemIssueLogHelper.LogException('EngineeringEventHelper', 'retrieveAccountRelatedObject', salesforceId, errorMessage, true);
            return null;
        }
    }

    /**
    * @description isSalesforceOrgId - 
    */    
    private static boolean isSalesforceOrgId(String salesforceId) {
        return ( (salesforceId != null) && (salesforceId.startsWith('a3m')) );
    }

    /**
    * @description retrieveSalesforceOrg - 
    */    
    private static Map<String, Object> retrieveSalesforceOrg(String salesforceId) {
        List<Engineering_Event_Setting__mdt> engEventsForSalesforceOrg = EngineeringEventMDTHelper.getEngineeringEventSettings('Salesforce_Org__c');
        List<String> salesforceOrgFields = EngineeringEventMDTHelper.createFieldListFromEventSettings(engEventsForSalesforceOrg);
        String query = 'SELECT ' + String.join(salesforceOrgFields,', ') + ' FROM Salesforce_Org__c WHERE Id = :salesforceId LIMIT 1';
        //System.debug('query for Salesforce_Org data: ' + query);
        sObject salesforceOrgObj = Database.query(query);
        //System.debug('query result:');
        //System.debug(salesforceOrgObj);
        Map<String, Object> jsonObj = formatResponse(salesforceOrgObj, salesforceOrgFields);
        //System.debug('jsonObj for SalesforceOrg response:');
        //System.debug(jsonObj);
        return jsonObj;
    }
    
    /**
    * @description formatResponse - 
    */    
    private static Map<String, Object> formatResponse (sObject salesforceOrgObj, List<String> salesforceOrgFields) {
        if (salesforceOrgObj == null) {
            return null;
        }
        // the AccountUpdateQueueReader service receiving this request requires all fields populated on the Salesforce_Org__c object
        Map<String, Object> jsonObj = new Map<String, Object>();
        for (String field : salesforceOrgFields) {
            jsonObj.put(field, salesforceOrgObj.get(field));
        }
        return jsonObj;
    }
    
    /**
    * @description isStringType - 
    */    
    private static boolean isStringType (Object obj) {
        return (obj instanceof String) || (obj instanceof Id) || (obj instanceof Date) || (obj instanceof Datetime);
    }


}