/**
* @author ECS, ERedding
* @date 20190819
* @version 1.00
* @description BillableTimeRollupHelperTest  - Test class for the BillableTimeRollupHelper class
*/
@isTest
public with sharing class BillableTimeRollupHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 2);
        insert testAccounts;

        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', false, 2);
        testContacts[0].AccountId = testAccounts[0].Id;
        testContacts[1].AccountId = testAccounts[1].Id;
        insert testContacts;

        Product2 prod = new Product2(Name = 'Basic Support', ProductCode = 'tstcde1');
        insert prod;

        List<SBQQ__Subscription__c> testSubscriptions = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', false, 1);
        testSubscriptions[0].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[0].SBQQ__Product__c = prod.Id;
        testSubscriptions[0].SBQQ__Quantity__c = 25;
        testSubscriptions[0].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 8, 1);
        testSubscriptions[0].SBQQ__SubscriptionEndDate__c = Date.newInstance(2020, 7, 31);
        insert testSubscriptions;
    }

    /**
    * @description billableTimeRollupTest - Test billableTimeRollup trigger method
    */
    public static testMethod void billableTimeRollupTest() {
        // GET TEST ACCOUNTS
		List<Account> testAccounts = [SELECT Id FROM Account];
		System.assert(testAccounts.size() == 2);

        // GET TEST CONTACTS
		List<Contact> testContacts = [SELECT Id FROM Contact];
		System.assert(testContacts.size() == 2);

        // GET TEST SUBSCRIPTIONS
		List<SBQQ__Subscription__c> testSubscriptions = [SELECT Id, SBQQ__SubscriptionStartDate__c, SBQQ__SubscriptionEndDate__c FROM SBQQ__Subscription__c];
		System.assert(testSubscriptions.size() == 1);

        String closeStatus = [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true LIMIT 1].MasterLabel;

		// CREATE TEST CASES
        List<Case> testCases = (List<Case>)TestingUtility.createSObjectList('Case', false, 2);
        testCases[0].AccountId = testAccounts[0].Id;        
        testCases[0].ContactId = testContacts[0].Id;
        testCases[0].Status = 'New';
        testCases[0].Billable_Time_Hours__c = 4;

        testCases[1].AccountId = testAccounts[1].Id;
        testCases[1].ContactId = testContacts[1].Id;
        testCases[1].Status = 'New';
        testCases[1].Billable_Time_Hours__c = 5;

        // CREATE A CASE WITH A CLOSE DATE IN THE PAST
        String caseJSON = '{"attributes":{"type":"Case","url":"/services/data/v25.0/sobjects/Case/500E0000002nH2fIAE"},"CreatedDate":"2019-07-01T17:54:26.000+0000","Status":"'+ closeStatus +'","ClosedDate":"2019-07-08T17:54:26.000+0000"}';
        Case pastCase = (Case)JSON.deserialize(caseJSON, Case.class);
        pastCase.AccountId = testAccounts[0].Id;        
        pastCase.ContactId = testContacts[0].Id;
        pastCase.Billable_Time_Hours__c = 2.5;
        testCases.add(pastCase);
        insert testCases;

    	// UPDATE FIRST TWO CASES SO THEY ARE ALL CLOSED
        testCases[0].Status = closeStatus;
        testCases[1].Status = closeStatus;
        update testCases;

        Test.startTest();

		// UPDATE ACCOUNTS AND TEST FOR CORRECT DATA
		testAccounts = [SELECT Id, Subscription_Term_Start_Date__c, Subscription_Term_End_Date__c, Billable_Time_Current_Subscription__c, Billable_Time_Non_Current_Subscription__c FROM Account];
		System.debug(testAccounts);
		System.assert(testAccounts[0].Subscription_Term_Start_Date__c == testSubscriptions[0].SBQQ__SubscriptionStartDate__c);
		System.assert(testAccounts[0].Subscription_Term_End_Date__c == testSubscriptions[0].SBQQ__SubscriptionEndDate__c);
		System.assert(testAccounts[0].Billable_Time_Current_Subscription__c == 4);
		System.assert(testAccounts[0].Billable_Time_Non_Current_Subscription__c == 2.5);

        System.debug(testAccounts[1]);

		System.assert(testAccounts[1].Subscription_Term_Start_Date__c == null); // NO SUBSCRIPTION ON ACCOUNT, NO DATA
		System.assert(testAccounts[1].Subscription_Term_End_Date__c == null); // NO SUBSCRIPTION ON ACCOUNT, NO DATA
		System.assert(testAccounts[1].Billable_Time_Current_Subscription__c == 0); // NO SUBSCRIPTION ON ACCOUNT, NO DATA
		System.assert(testAccounts[1].Billable_Time_Non_Current_Subscription__c == 5); // NO SUBSCRIPTION ON ACCOUNT, NO DATA

        Test.stopTest();
    }


}