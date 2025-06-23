/**
* @author ECS, ERedding
* @date 20190701
* @version 1.00
* @description Queueable_UpdateOppPrimaryCountTest - Test class for the Queueable_UpdateOppPrimaryCount class
*/
@isTest
public with sharing class Queueable_UpdateOppPrimaryCountTest {

	/**
    * @description testQueueableExecute - Test method for the Queueable_CalculateOppMRRTotals.execute method
    */
    public static testmethod void testQueueableExecute(){
        Test.startTest();

        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';  
        testAccounts[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
        testAccounts[0].mrr_Active_MRR__c = 100.00;                     
        insert testAccounts;

        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 2);  
        testContacts[0].LastName = 'Smith';  
        testContacts[1].LastName = 'Roberts';           
        insert testContacts;

        // CREATE TEST OPPS
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', true, 2);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].Type = 'Existing Business';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[1].AccountId = testAccounts[0].Id;
        testOpportunities[1].StageName = 'Qualify';
        testOpportunities[1].Type = 'Renewal';
        testOpportunities[1].CloseDate = Date.today();
        insert testOpportunities;

        // CREATE TEST OPP CONTACT ROLES
        List<OpportunityContactRole> testOppContactRoles = (List<OpportunityContactRole>)TestingUtility.createSObjectList('OpportunityContactRole', true, 2);
        testOppContactRoles[0].OpportunityId = testOpportunities[0].Id;
		testOppContactRoles[0].ContactId = testContacts[0].Id;
        testOppContactRoles[0].IsPrimary = true;
        testOppContactRoles[0].Role = 'Admin';
        
        testOppContactRoles[1].OpportunityId = testOpportunities[1].Id;
		testOppContactRoles[1].ContactId = testContacts[1].Id;
        testOppContactRoles[1].IsPrimary = true;
        testOppContactRoles[1].Role = 'Decision Maker';
        insert testOppContactRoles;

        // CONSTRUCT NEW QUEUEABLE
        System.enqueueJob(new Queueable_UpdateOppPrimaryCount(new Set<Id>{ testOpportunities[0].Id, testOpportunities[1].Id }));

        Test.stopTest();

        // UPDATE OPPS AND CHECK FOR CORRECT DATA
        testOpportunities = [SELECT Id, CountofPrimaryContact__c FROM Opportunity WHERE Id IN: testOpportunities];
        System.assert(testOpportunities.size() == 2);
        System.assert(testOpportunities[0].CountofPrimaryContact__c == 1);
        System.assert(testOpportunities[1].CountofPrimaryContact__c == 1);
    }


}