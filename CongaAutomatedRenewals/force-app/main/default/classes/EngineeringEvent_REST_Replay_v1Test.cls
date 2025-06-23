@isTest
public with sharing class EngineeringEvent_REST_Replay_v1Test {

    @isTest static void EngineeringEvent_REST_Replay_v1_EndpointHappyPathTest () {
        Test.startTest();
        
        Salesforce_Org__c sfOrg1 = new Salesforce_Org__c (
            Name = 'Test Org1'
        );
        insert sfOrg1;
        
        Salesforce_Org__c sfOrg2 = new Salesforce_Org__c (
            Name = 'Test Org2'
        );
        insert sfOrg2;
        
        DateTime dateTimeNow = datetime.now();
        DateTime startTime5MinAgo = dateTimeNow.addMinutes(-5);
        DateTime endTime5MinAfterNow = dateTimeNow.addMinutes(5);

        string startTimeStr = startTime5MinAgo.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        string endTimeStr = endTime5MinAfterNow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/conga/engineering/v1/replay'; 
        req.addParameter('objectname', 'Salesforce_Org__c');
        req.addParameter('startdate', startTimeStr);
        req.addParameter('enddate', endTimeStr);
        req.httpMethod = 'GET'; 
        RestContext.request = req;
        RestContext.response = res;
        
        EngineeringEvent_REST_Replay_v1.getData();
        
        Test.stopTest();
        string responseStr = res.responseBody.toString();
        System.debug('responseStr=' + responseStr);
        System.assert(responseStr.contains(sfOrg1.Id));
        System.assert(responseStr.contains(sfOrg2.Id));
    }
    
    @isTest static void EngineeringEvent_REST_Replay_v1_EndpointBadDateOrderReturns400 () {
        Test.startTest();
        DateTime dateTimeNow = datetime.now();
        DateTime startTime5MinAgo = dateTimeNow.addMinutes(-5);
        DateTime endTime5MinAfterNow = dateTimeNow.addMinutes(5);

        string startTimeStr = startTime5MinAgo.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        string endTimeStr = endTime5MinAfterNow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/conga/engineering/v1/replay'; 
        req.addParameter('objectname', 'Salesforce_Org__c');
        // reverse date order to cause error
        req.addParameter('startdate', endTimeStr);
        req.addParameter('enddate', startTimeStr);
        req.httpMethod = 'GET'; 
        RestContext.request = req;
        RestContext.response = res;
        
        EngineeringEvent_REST_Replay_v1.getData();
        
        Test.stopTest();
        System.assert(res.statusCode == 400);
    }

    
    
    
    
}