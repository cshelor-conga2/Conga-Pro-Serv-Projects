/**
* @author Conga Services
* @date 
* @version 1.00
* @description AccountContactRelationHelperTest - [Description]
*/
@isTest
public with sharing class AccountContactRelationHelperTest {

	/**
	* @description setup - Test data setup method
	*/
	@testSetup
	public static void setup(){
		// TEMPORARILY DISABLE ALL TRIGGERS
        TriggerHelper.OverrideAllSettings(true, false);

		// CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 2);
        testAccounts[0].Type = 'Prospect';
        testAccounts[1].Type = 'Customer';
        insert testAccounts;

		// CREATE TEST CONTACTS
        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', false, 4);
    	testContacts[0].AccountId = testAccounts[0].Id;
    	testContacts[1].AccountId = testAccounts[0].Id;
    	testContacts[2].AccountId = testAccounts[1].Id;
    	testContacts[3].AccountId = testAccounts[1].Id;
        insert testContacts;

        // SET PRIMARY FLAGS
        List<AccountContactRelation> acctContactRelations = [SELECT Id, ContactId, IsPrimary__c FROM AccountContactRelation WHERE AccountId IN :testAccounts AND ContactId IN :testContacts];
    	acctContactRelations[0].IsPrimary__c = true;
    	acctContactRelations[0].Status__c = 'Working';
    	acctContactRelations[1].IsPrimary__c = false;
    	acctContactRelations[1].Status__c = 'Working';
    	acctContactRelations[2].IsPrimary__c = false;
    	acctContactRelations[2].Status__c = 'Engaged';
    	acctContactRelations[3].IsPrimary__c = true;
    	acctContactRelations[3].Status__c = 'Working';   	  
    	update acctContactRelations;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Type = 'Existing Business';
        //
        testOpportunities[1].AccountId = testAccounts[1].Id;
        testOpportunities[1].StageName = 'Qualify';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Type = 'Renewal';
        insert testOpportunities;

        // CREATE TEST OPPORTUNITYCONTACTROLES
        List<OpportunityContactRole> testOppContactRoles = (List<OpportunityContactRole>)TestingUtility.createSObjectList('OpportunityContactRole', false, 4);
        testOppContactRoles[0].OpportunityId = testOpportunities[0].Id;
        testOppContactRoles[0].ContactId = acctContactRelations[0].ContactId;
        testOppContactRoles[0].IsPrimary = acctContactRelations[0].IsPrimary__c;
        testOppContactRoles[0].Role = 'Decision Maker';
        //
        testOppContactRoles[1].OpportunityId = testOpportunities[0].Id;
        testOppContactRoles[1].ContactId = acctContactRelations[1].ContactId;
        testOppContactRoles[1].IsPrimary = acctContactRelations[1].IsPrimary__c;
        testOppContactRoles[1].Role = 'Technical Buyer';
        //
        testOppContactRoles[2].OpportunityId = testOpportunities[1].Id;
        testOppContactRoles[2].ContactId = acctContactRelations[2].ContactId;
        testOppContactRoles[2].IsPrimary = acctContactRelations[2].IsPrimary__c;
        testOppContactRoles[2].Role = 'Admin';
        //
        testOppContactRoles[3].OpportunityId = testOpportunities[1].Id;
        testOppContactRoles[3].ContactId = acctContactRelations[3].ContactId;
        testOppContactRoles[3].IsPrimary = acctContactRelations[3].IsPrimary__c;
        testOppContactRoles[3].Role = 'Decision Maker';
        insert testOppContactRoles;
	}
	

	/**
	* @description removeDepartedFromPrimaryRolesTest - Test method for AccountContactRelationHelper.removeDepartedFromPrimaryRoles trigger method
	*/
	public static testMethod void removeDepartedFromPrimaryRolesTest() {
       // GET TEST ACCOUNT CONTACT RELATIONS AND CHECK THAT DATA IS CORRECT
       List<AccountContactRelation> relations = [SELECT Id, IsPrimary__c FROM AccountContactRelation];
       System.assert(relations.size() == 4);
       System.assert(relations[0].IsPrimary__c == true);
       System.assert(relations[1].IsPrimary__c == false);
       System.assert(relations[2].IsPrimary__c == false);
       System.assert(relations[3].IsPrimary__c == true);

       // GET TEST OPP CONTACT ROLES AND CHECK THAT DATA IS CORRECT
       List<OpportunityContactRole> oppRoles = [SELECT Id, IsPrimary FROM OpportunityContactRole];
       System.assert(oppRoles.size() == 4);
       System.assert(oppRoles[0].IsPrimary == true);
       System.assert(oppRoles[1].IsPrimary == false);
       System.assert(oppRoles[2].IsPrimary == false);
       System.assert(oppRoles[3].IsPrimary == true);

       Test.startTest();

       // UPDATE ACCOUNT CONTACTS SO THEY ALL HAVE LEFT THE COMPANY
       relations[0].Status__c = 'No Longer at Company';
       relations[1].Status__c = 'No Longer at Company';
       relations[2].Status__c = 'No Longer at Company';
       relations[3].Status__c = 'No Longer at Company';
       update relations;

       // RELOAD ACCOUNT CONTACT RELATIONS AND CHECK THAT DATA IS CORRECT
       relations = [SELECT Id, IsPrimary__c FROM AccountContactRelation WHERE Id IN :relations];
       System.assert(relations[0].IsPrimary__c == false);
       System.assert(relations[1].IsPrimary__c == false);
       System.assert(relations[2].IsPrimary__c == false);
       System.assert(relations[3].IsPrimary__c == false);

       // RELOAD OPP CONTACT ROLES AND CHECK THAT DATA IS CORRECT
       oppRoles = [SELECT Id, IsPrimary FROM OpportunityContactRole WHERE Id IN :oppRoles];
       System.assert(oppRoles[0].IsPrimary == false);
       System.assert(oppRoles[1].IsPrimary == false);
       System.assert(oppRoles[2].IsPrimary == false);
       System.assert(oppRoles[3].IsPrimary == false);

       Test.stopTest();
	}


}