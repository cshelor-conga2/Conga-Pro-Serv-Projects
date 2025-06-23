/**
* @author ECS, ERedding
* @date 20200113
* @version 1.00
* @description BatchableSch_TMContactUpdaterTest  - Test class for the BatchableSch_TMContactUpdater class
*/
@isTest
public with sharing class BatchableSch_TMContactUpdaterTest {
	
    /**
    * @description testBatch - 
    */  
    static testmethod void testBatch() {
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User tm1 = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Terr', LastName = 'Person1', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert tm1;

    	// CREATE TEST ACCOUNT
    	List<Account> testAccounts = TestingUtility.createSObjectList('Account', true, 1);
    	insert testAccounts;

    	// CREATE TEST CONTACTS
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', true, 3);
        testContacts[0].FirstName = 'Joe';
        testContacts[0].LastName = 'Shroom';
        testContacts[0].AccountId = testAccounts[0].Id;
        testContacts[1].FirstName = 'John';
        testContacts[1].LastName = 'Doe';
        testContacts[1].AccountId = testAccounts[0].Id;
        testContacts[2].FirstName = 'Bob';
        testContacts[2].LastName = 'Burger';
        testContacts[2].AccountId = testAccounts[0].Id;
        insert testContacts;

        Test.startTest();

		testAccounts[0].OwnerId = tm1.Id;
		testAccounts[0].TM_Territory_ManagerId__c = tm1.Id;
		testAccounts[0].TM_Contact_Update__c = true;
		update testAccounts;

        BatchableSch_TMContactUpdater updater = new BatchableSch_TMContactUpdater();
        Database.executeBatch(updater);

        Test.stopTest();

		testAccounts = [SELECT Id, TM_Contact_Update__c FROM Account WHERE Id IN :testAccounts];
		System.assert(testAccounts[0].TM_Contact_Update__c == false);

        testContacts = [SELECT Id, OwnerId, TM_Territory_ManagerId__c FROM Contact WHERE Id IN :testContacts];
        System.assert(testContacts[0].OwnerId == tm1.Id);
        System.assert(testContacts[0].TM_Territory_ManagerId__c == tm1.Id);
        System.assert(testContacts[1].OwnerId == tm1.Id);
        System.assert(testContacts[1].TM_Territory_ManagerId__c == tm1.Id);
        System.assert(testContacts[2].OwnerId == tm1.Id);
        System.assert(testContacts[2].TM_Territory_ManagerId__c == tm1.Id);
    }

    /**
    * @description testSchedulable - 
    */  
    private static testmethod void testSchedulable(){
        Test.startTest();
  
        String jobId = System.schedule('mqlQualificationTest', '0 0 0 1 1 ? 2025', new BatchableSch_TMContactUpdater());

        Test.stopTest();
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId]; 
        System.assert(ct != null); 
    }


}