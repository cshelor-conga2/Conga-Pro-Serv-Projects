@isTest
public with sharing class EngineeringEvent_REST_Data_v1Test {

    @isTest static void EngineeringEvent_REST_Data_v1_EndpointTestHappyPathForSalesforceOrg () {
        Test.startTest();
        
        Salesforce_Org__c sfOrg1 = new Salesforce_Org__c (
            Name = 'Test Org1'
        );
        insert sfOrg1;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/conga/engineering/v1/license'; 
        req.addParameter('salesforceId', sfOrg1.Id);
        req.addParameter('externalIdObjectName', 'Salesforce_Org__c');
        req.httpMethod = 'GET'; 
        RestContext.request = req;
        RestContext.response = res;
        
        EngineeringEvent_REST_Data_v1.getData();
        
        Test.stopTest();
        string responseStr = res.responseBody.toString();
        System.debug('responseStr=' + responseStr);
        System.assert(responseStr.contains('Test Org1'));
    }
    
    @isTest static void EngineeringEvent_REST_Data_v1_EndpointTestBadRequestForSalesforceOrg () {
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/conga/engineering/v1/license'; 
        req.addParameter('salesforceId', 'NotARealId');
        req.addParameter('externalIdObjectName', 'Salesforce_Org__c');
        req.httpMethod = 'GET'; 
        RestContext.request = req;
        RestContext.response = res;
        
        EngineeringEvent_REST_Data_v1.getData();
        
        Test.stopTest();
        System.assert(res.responseBody == null);
    }

    
    
    
    
}