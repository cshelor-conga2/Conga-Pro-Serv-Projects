/**
* @author Mark Brundege
* @date 20200505
* @version 1.00
* @description EngineeringEventHelperTest - Test class for the EngineeringEventHelper class
*/
@isTest
public with sharing class EngineeringEventHelperTest {

    @isTest static void when_retrieveSalesforceOrgShouldGetData () {
        Test.startTest();

        Salesforce_Org__c sfOrg = new Salesforce_Org__c (Name='TestOrg');
        insert sfOrg;
        Map<String, Object> sfOrgRetrieved = EngineeringEventHelper.retrieveAccountRelatedObject(sfOrg.Id, null, null);

        Test.stopTest();

        System.assert(sfOrgRetrieved.size() > 50);
        System.assert(sfOrgRetrieved.get('Name') == 'TestOrg');
    }


}