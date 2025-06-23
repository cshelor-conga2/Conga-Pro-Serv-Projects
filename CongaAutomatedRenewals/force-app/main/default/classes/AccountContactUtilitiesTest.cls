/**
* @author CongaServices
* @date 20180608
* @version 1.00
* @description AccountContactUtilitiesTest - Test class for the AccountContactUtilities class
*/
@isTest
public with sharing class AccountContactUtilitiesTest {

    /**
    * @description test_method_one 
    */
    static testmethod void test_method_one() {
        List<Account> testAccounts = createTestAccounts(1);
        List<Contact> testContacts = createTestContacts(testAccounts, 4);
        List<Opportunity> testOpportunities = createTestOpportunities(testAccounts, 2);
        List<OpportunityContactRole> testOpportunityContactRoles = createTestOpportunityContactRoles(testContacts, testOpportunities, 2);

        List<Contact> contactsToInsert = new List<Contact>();
        List<AccountContactRelation> accConsToUpsert = new List<AccountContactRelation>();
        List<Id> contactIds = new List<Id>();
        for(Integer i=0; i<3; i++){
            Contact newContact = new Contact();
            newContact.FirstName = 'Test' +i;
            newContact.LastName = 'Contact' +i;
            newContact.Email = 'test'+i+'@test.com';
            newContact.AccountId = testAccounts[0].Id;
            contactsToInsert.add(newContact);
        }
        for(Integer j=0; j<testContacts.size(); j++){   
            if(testContacts[j].AccountId != testAccounts[0].Id){
                AccountContactRelation acr = new AccountContactRelation();
                acr.AccountId = testAccounts[0].Id;
                acr.ContactId = testContacts[j].Id;
                accConsToUpsert.add(acr);
            }
            contactIds.add(testContacts[j].Id);
        }

        List<OpportunityContactRole> newOppContactRoles = new List<OpportunityContactRole>();
        OpportunityContactRole newOppContactRole = new OpportunityContactRole();
        newOppContactRole.Role = 'Administrator';
        newOppContactRole.ContactId = testContacts[3].Id;
        newOppContactRole.OpportunityId = testOpportunities[0].Id;
        newOppContactRoles.add(newOppContactRole);


        Test.startTest();
        //ApexPages.StandardController sc = new ApexPages.StandardController(testOpportunities[0]);
        PageReference pageRef = Page.AccountContactTable;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('opportunityId',testOpportunities[0].Id);       
        AccountContactUtilities eu = new AccountContactUtilities();
        System.assertEquals(true, eu.isValid);
        System.assertEquals(true, eu.isForOpportunityContactRoleMaintenance);
        System.assertEquals(testOpportunities[0].Id, eu.opportunityId);
        AccountContactUtilities.searchAccountContacts('Contact', 'Name', 'Id', 1, 'AccountId', testAccounts[0].Id, 'LastName');
        AccountContactUtilities.saveContactRoles(JSON.serialize(testOpportunityContactRoles));
        AccountContactUtilities.getAccountContacts(testAccounts[0].Id);
        AccountContactUtilities.getOpportunityContactRoles(testOpportunities[0].Id);
        AccountContactUtilities.deleteContactRoles(testOpportunityContactRoles);
        AccountContactUtilities.findContacts('Test C', testAccounts[0].Id, contactIds);
        AccountContactUtilities.upsertContactRoles(newOppContactRoles);
        List<Contact> upsertedContacts = AccountContactUtilities.upsertContacts(contactsToInsert);      
        List<AccountContactRelation> upsertedAccountContactRelation = AccountContactUtilities.upsertAccountContacts(accConsToUpsert);
        AccountContactUtilities.getContactRoles();
        Test.stopTest();        
    }   

    /**
    * @description getContactPersonaTest 
    */
    static testmethod void getContactPersonaTest() {
        List<String> personas = AccountContactUtilities.getContactPersona();
        System.assert(!personas.isEmpty());
        Map<String, String> personasMap = new Map<String, String>();
        for(String persona : personas) {
            personasMap.put(persona, persona);
        }
        for (Schema.PicklistEntry pickListVal : AccountContactRelation.Persona__c.getDescribe().getPicklistValues()) {
            System.assert(personasMap.containsKey(pickListVal.getLabel()));
        }
    }

    /**
    * @description getContactPersonaTest 
    */
    static testmethod void getContactStatusTest() {
        List<String> statusList = AccountContactUtilities.getContactStatus();
        System.assert(!statusList.isEmpty());
        Map<String, String> statusMap = new Map<String, String>();
        for(String status : statusList) {
            statusMap.put(status, status);
        }
        for (Schema.PicklistEntry pickListVal : AccountContactRelation.Status__c.getDescribe().getPicklistValues()) {
            System.assert(statusMap.containsKey(pickListVal.getLabel()));
        }
    }

    /**
    * @description getContactPersonaTest 
    */
    static testmethod void getJobLevelTest() {
        List<String> jobLevels = AccountContactUtilities.getJobLevel();
        System.assert(!jobLevels.isEmpty());
        Map<String, String> jobLevelMap = new Map<String, String>();
        for(String jobLevel : jobLevels) {
            jobLevelMap.put(jobLevel, jobLevel);
        }
        for (Schema.PicklistEntry pickListVal : AccountContactRelation.Job_Level__c.getDescribe().getPicklistValues()) {
            System.assert(jobLevelMap.containsKey(pickListVal.getLabel()));
        }
    }   

    /**
    * @description getContactPersonaTest 
    */
    static testmethod void upsertContactsAccountRelationTest() {
        // Test Accounts
        List<Account> testAccounts = createTestAccounts(2);
        List<Id> accountIds = new List<Id>();
        for (Account a : testAccounts) {
            accountIds.add(a.Id);
        }

        // Page Reference
        PageReference pageRef = Page.AccountContactTable;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('accountId',testAccounts[0].Id);        
        AccountContactUtilities eu = new AccountContactUtilities();
        System.assertEquals(true, eu.isValid);
        System.assertEquals(true, eu.isForAccountContactRelationshipMaintenance);
        System.assertEquals(testAccounts[0].Id, eu.accountId);

        // Test Contacts
        List<Contact> contactsToUpsert = createTestContacts(testAccounts[0].Id, 4, false);
        contactsToUpsert[3].AccountId = testAccounts[1].Id;
        insert contactsToUpsert;
        List<Id> contactIds = new List<Id>();
        for (Contact c : contactsToUpsert) {
            contactIds.add(c.Id);
        }

        // Build Account Relations
        List<AccountContactRelation> accountContacts = getAccountContactRelation(accountIds, contactIds);
        System.assertEquals(4, accountContacts.size());

        List<AccountContactRelation> accountContactsToUpsert = new List<AccountContactRelation>();
        for (Id contactId : contactIds) {
            for (AccountContactRelation acr : accountContacts) {
                if (acr.ContactId == contactId) {
                    if (acr.AccountId == testAccounts[1].Id) {
                        accountContactsToUpsert.add(new AccountContactRelation(AccountId = testAccounts[0].Id, ContactId = contactId));
                    }
                    else {
                        accountContactsToUpsert.add(acr);
                    }                       
                    break;
                }
            }
        }

        Test.startTest();
        AccountContactUtilities.upsertContactsAccountRelation(contactsToUpsert, testAccounts[0].Id, accountContactsToUpsert);               
        Test.stopTest();

        accountContacts = getAccountContactRelation(new List<Id> {testAccounts[0].Id}, contactIds);
        System.assertEquals(4, accountContacts.size());
    }

    /**
    * @description getContactPersonaTest 
    */
    static testmethod void processChangesTest() {

        List<Account> testAccounts = createTestAccounts(1);
        List<Contact> testContacts = createTestContacts(testAccounts, 2);

        List<AccountContactRelation> accountContacts = getAccountContactRelation(testAccounts, testContacts);

        List<Opportunity> testOpportunities = createTestOpportunities(testAccounts, 1);

        List<OpportunityContactRole> newOppContactRoles = new List<OpportunityContactRole>();
        for (Contact c : testContacts) {
            OpportunityContactRole newOppContactRole = new OpportunityContactRole();
            newOppContactRole.Role = 'Administrator';
            newOppContactRole.ContactId = c.Id;
            newOppContactRole.OpportunityId = testOpportunities[0].Id;
            newOppContactRoles.add(newOppContactRole);
        }

        List<OpportunityContactRole> opportunityContactRolesToDelete = new List<OpportunityContactRole>();

        Test.startTest();
        List<OpportunityContactRole> processedOppContactRoles = AccountContactUtilities.processChanges(testAccounts[0].Id, newOppContactRoles, testContacts, accountContacts, opportunityContactRolesToDelete);
        Test.stopTest();
            
        System.assertEquals(2, processedOppContactRoles.size());
    }

    /**
    * @description getContactPersonaTest 
    */
    static testmethod void invalidAccountPageTest() {
        PageReference pageRef = Page.AccountContactTable;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('accountId', 'TEST');       

        Test.startTest();
        AccountContactUtilities eu = new AccountContactUtilities();
        Test.stopTest();                

        System.assertEquals(false, eu.isValid);
        System.assertEquals(null, eu.accountId);
    }

    /**
    * @description getContactPersonaTest 
    */
    static testmethod void invalidOpportunityPageTest() {
        PageReference pageRef = Page.AccountContactTable;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('opportunityId', 'TEST');       

        Test.startTest();
        AccountContactUtilities eu = new AccountContactUtilities();
        Test.stopTest();                

        System.assertEquals(false, eu.isValid);
        System.assertEquals(null, eu.opportunityId);
    }


    // *******
    // helpers
    // *******
    private static List<Account> createTestAccounts(Integer numRecords) {
        List<Account> testAccounts = new List<Account>();
        if (numRecords == 0) return testAccounts;
        for (Integer i=0;i<numRecords;i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;
        return testAccounts;
    }

    private static List<Contact> createTestContacts(List<Account> accounts, Integer numRecords) {
        List<Contact> testContacts = new List<Contact>();       
        if (accounts.isEmpty()) return testContacts;
        for (Account a : accounts) {
            for (Integer i=0;i<numRecords;i++) {
                Contact newContact = new Contact();
                newContact.FirstName = 'Test' + i;
                newContact.LastName = 'Contact' + i;
                newContact.Email = 'test' + i + '@test.com';
                newContact.AccountId = a.Id;
                testContacts.add(newContact);
            }
        }
        insert testContacts;
        return testContacts;
    }

    private static List<Contact> createTestContacts(Id accountId, Integer numRecords, Boolean saveRecords) {        
        List<Contact> testContacts = new List<Contact>();
        if (numRecords == 0) return testContacts;
        for (Integer i=0;i<numRecords;i++) {
            Contact newContact = new Contact();
            newContact.FirstName = 'Test' + i;
            newContact.LastName = 'Contact' + i;
            newContact.Email = 'test' + i + '@test.com';
            newContact.AccountId = accountId;
            testContacts.add(newContact);
        }
        if (saveRecords) insert testContacts;
        return testContacts;
    }   

    private static List<Opportunity> createTestOpportunities(List<Account> accounts, Integer numRecords) {

        List<Opportunity> testOpportunities = new List<Opportunity>();
        if (numRecords == 0) return testOpportunities;
        if (accounts.isEmpty()) return testOpportunities;
        for (Account a : accounts) {
            for(Integer i=0;i<numRecords;i++) {
                Opportunity opp = new Opportunity();
                opp.Name = 'Test Opportunity ' + i;
                opp.AccountId = a.Id;
                opp.Type = 'New Business';
                opp.LeadSource = 'Event';
                //opp.StageName = 'Negotiation';
                opp.StageName = 'Qualify';
                opp.ForecastCategoryName = 'Most Likely';
                opp.CloseDate = Date.today();
                testOpportunities.add(opp);
            }
        }
        insert testOpportunities;
        return testOpportunities;
    }

    private static List<OpportunityContactRole> createTestOpportunityContactRoles(List<Contact> contacts, List<Opportunity> opportunities, Integer numRecords) {
        List<String> roles = AccountContactUtilities.getContactRoles();
        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
        if (numRecords == 0) return opportunityContactRoles; 
        for(Integer i=0;i<numRecords;i++) {
            OpportunityContactRole opc = new OpportunityContactRole();
            opc.ContactId = Contacts[i].Id;
            opc.OpportunityId = Opportunities[i].Id;
            opc.Role = roles[math.mod(i,roles.size())];
            opportunityContactRoles.add(opc);
        }
        insert OpportunityContactRoles;
        return OpportunityContactRoles;
    }

    // *********
    // selectors
    // *********
    private static List<AccountContactRelation> getAccountContactRelation(List<Account> accounts, List<Contact> contacts) {
        
        List<Id> accountIds = new List<Id>();
        for (Account a : accounts) {
            accountIds.add(a.Id);
        }

        List<Id> contactIds = new List<Id>();
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }

        return getAccountContactRelation(accountIds, contactIds);

    }

    private static List<AccountContactRelation> getAccountContactRelation(List<Id> accountIds, List<Id> contactIds) {
        return [
            SELECT 
                Id, 
                Roles, 
                ContactId, 
                Persona__c, 
                Status__c, 
                AccountId, 
                IsPrimary__c,
                Job_Level__c
            FROM 
                AccountContactRelation 
            WHERE 
                AccountId IN :accountIds 
                AND ContactId IN :contactIds
        ];      
    }
}