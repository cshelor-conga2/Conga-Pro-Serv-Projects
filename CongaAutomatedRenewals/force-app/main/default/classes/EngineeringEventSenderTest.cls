/**
* @author Mark Brundege
* @date 20200406
* @version 1.00
* @description EngineeringEventSenderTest - Test class for the EngineeringEventSender class
*/
@isTest
public with sharing class EngineeringEventSenderTest {
    
    @isTest static void SalesforceOrgInsertShouldCreateEvent () {
        Salesforce_Org__c newSfOrg = new Salesforce_Org__c (Name = 'Test Org');
        Test.startTest();

        insert newSfOrg;

        Test.stopTest();

        List<Salesforce_Org__c> testOrg = [select Id, Name from Salesforce_Org__c where name = 'Test Org' limit 1];
        System.assertEquals(1, testOrg.size());
    }
    
    @isTest static void SalesforceOrgUpdateShouldCreateEvent () {
        Salesforce_Org__c newSfOrg = new Salesforce_Org__c (Name = 'Test Org');
        insert newSfOrg;

        newSfOrg.Name = 'Updated Test Org';
        Test.startTest();
        
        update newSfOrg;

        Test.stopTest();

        List<Salesforce_Org__c> testOrg = [select Id, Name from Salesforce_Org__c where name = 'Updated Test Org' limit 1];
        System.assertEquals(1, testOrg.size());
    }
    
    @isTest static void SendEngineeringEventsSuccessfullySent () {
        List<Engineering_Event_API_Setting__mdt> apiSettings = new List<Engineering_Event_API_Setting__mdt>();
        string endpoint = 'https://qqvrezq0sh.execute-api.us-west-2.amazonaws.com/v1/mocktest';
        apiSettings.add(new Engineering_Event_API_Setting__mdt(DeveloperName='api_endpoint', Value__c=endpoint));
        apiSettings.add(new Engineering_Event_API_Setting__mdt(DeveloperName='certificate_name',Value__c=''));
        EngineeringEventMDTHelper.setEngineeringAPISettings(apiSettings);
        
        List<Engineering_Event__e> engineeringEvents = new List<Engineering_Event__e>();
        Engineering_Event__e engEvent = new Engineering_Event__e(
			ExternalId_Object_Name__c='Salesforce_Org__c',
			ExternalId__c='',
			SalesforceId__c='a3m000000000000'
        );
        engineeringEvents.add(engEvent);
        EngineeringEventSender.sendEngineeringEvents(engineeringEvents);
    }


}