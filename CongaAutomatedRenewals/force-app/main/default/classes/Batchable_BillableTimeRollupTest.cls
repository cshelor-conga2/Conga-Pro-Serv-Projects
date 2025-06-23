/**
* @author Conga Services
* @date 20190201
* @version 1.00
* @description Batchable_BillableTimeRollupTest  - Test class for the Batchable_BillableTimeRollup class
*/
@isTest
public with sharing class Batchable_BillableTimeRollupTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].mrr_Active_MRR__c = 100.00;
        insert testAccounts;

        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 1);
        testContacts[0].AccountId = testAccounts[0].Id;
        insert testContacts;

        Product2 prod = new Product2();
        prod.Name = 'Basic Support';
        prod.ProductCode = 'tstcde1';
        insert prod;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Account__c = testAccounts[0].Id;
        sub.SBQQ__Product__c = prod.Id;
        sub.SBQQ__Quantity__c = 5;
        sub.SBQQ__SubscriptionStartDate__c = Date.today().addDays(-30);
        sub.SBQQ__SubscriptionEndDate__c = Date.today().addDays(30);
        insert sub;     
    }

    /**
    * @description testMethod1 - Test Schedulable and Batchable functionality
    */
    public static testMethod void testSchedulableAndBatchable() {
        Test.startTest();

        String sch = '0 0 23 * * ?';
        System.schedule('Test Sched', sch, new Batchable_BillableTimeRollup());
        Database.executeBatch(new Batchable_BillableTimeRollup());

        ////////// PRIMARY LOGIC IN BillableTimeRollupHelper WILL BE TESTED BY ITS OWN TEST CLASS. THIS CODE ONLY COVERS THE BATCHABLE CLASS.

        Test.stopTest();
    }


}