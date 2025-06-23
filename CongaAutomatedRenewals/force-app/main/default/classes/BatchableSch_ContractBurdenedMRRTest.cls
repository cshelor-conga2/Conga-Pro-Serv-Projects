/**
* @author ECS, ERedding
* @date 20200331
* @version 1.00
* @description BatchableSch_ContractBurdenedMRRTest  - Test class for the BatchableSch_ContractBurdenedMRR class
*/
@isTest
public with sharing class BatchableSch_ContractBurdenedMRRTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 2);
        insert testAccounts;

        // CREATE TEST CONTRACT
        List<Contract> testContracts = (List<Contract>)TestingUtility.createSObjectList('Contract', false, 4);
        for(Contract contract : testContracts){
        	contract.Status = 'Draft';
        	contract.StartDate = Date.today();
        }
        testContracts[0].AccountId = testAccounts[0].Id;
        testContracts[0].EndDate = Date.today().addMonths(12);
        testContracts[0].Contract_Type__c = 'Customer Subscription';
        testContracts[1].AccountId = testAccounts[0].Id;
        testContracts[1].EndDate = Date.today().addMonths(12);
        testContracts[1].Contract_Type__c = 'Customer Subscription';
        testContracts[2].AccountId = testAccounts[1].Id;
        testContracts[2].EndDate = Date.today().addMonths(24);
        testContracts[2].Contract_Type__c = 'Customer Subscription';
        testContracts[3].AccountId = testAccounts[1].Id;
        testContracts[3].EndDate = Date.today().addMonths(36);
        testContracts[3].Contract_Type__c = 'Customer Subscription';
        insert testContracts;

        // CREATE TEST PRODUCTS
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 2);
        testProducts[0].Name = 'Test Product';
        testProducts[0].ProductCode = 'TP1';
        testProducts[0].Family = 'Conga Composer Licenses';
        testProducts[0].Product_Line__c = 'Conga Composer';
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProducts[1].Name = 'Test Product 2';
        testProducts[1].ProductCode = 'TP2';
        testProducts[1].Family = 'ActionGrid';
        testProducts[1].Product_Line__c = 'Conga Grid';
        testProducts[1].FY16_Revenue_Type__c = 'Recurring';
        testProducts[1].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        insert testProducts;

        // TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', false, 2);
        testPricebookEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[0].Product2Id = testProducts[0].Id;
        testPricebookEntries[0].IsActive = TRUE;
        testPricebookEntries[0].UnitPrice = 200.00;
        testPricebookEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[1].Product2Id = testProducts[1].Id;
        testPricebookEntries[1].IsActive = TRUE;
        testPricebookEntries[1].UnitPrice = 500.00;
        insert testPricebookEntries;

        Integer currentYear = Date.today().year();
        Integer nextYear = Date.today().year()+1;
        Integer yearAfterNext = Date.today().year()+2;

        // CREATE TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubs = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', false, 8);
        testSubs[0].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[0].SBQQ__Contract__c = testContracts[0].Id;
        testSubs[0].SBQQ__Product__c = testPricebookEntries[0].Product2Id;
        testSubs[0].SBQQ__SubscriptionStartDate__c = Date.newInstance(currentYear, 1, 1);
        testSubs[0].SBQQ__SubscriptionEndDate__c = Date.newInstance(currentYear, 12, 31);
        testSubs[0].SBQQ__Quantity__c = 40;
        testSubs[0].SBQQ__NetPrice__c = 2160.00;
        //
        testSubs[1].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[1].SBQQ__Contract__c = testContracts[0].Id;
        testSubs[1].SBQQ__Product__c = testPricebookEntries[1].Product2Id;
        testSubs[1].SBQQ__SubscriptionStartDate__c = Date.newInstance(nextYear, 1, 1);
        testSubs[1].SBQQ__SubscriptionEndDate__c = Date.newInstance(nextYear, 12, 31);
        testSubs[1].SBQQ__Quantity__c = 15;
        testSubs[1].SBQQ__NetPrice__c = 2600.00;
        //
        testSubs[2].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[2].SBQQ__Contract__c = testContracts[1].Id;
        testSubs[2].SBQQ__Product__c = testPricebookEntries[0].Product2Id;
        testSubs[2].SBQQ__SubscriptionStartDate__c = Date.newInstance(currentYear, 1, 15);
        testSubs[2].SBQQ__SubscriptionEndDate__c = Date.newInstance(currentYear, 12, 31);
        testSubs[2].SBQQ__Quantity__c = 15;
        testSubs[2].SBQQ__NetPrice__c = 2160.00;
        //
        testSubs[3].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[3].SBQQ__Contract__c = testContracts[1].Id;
        testSubs[3].SBQQ__Product__c = testPricebookEntries[1].Product2Id;
        testSubs[3].SBQQ__SubscriptionStartDate__c = Date.newInstance(nextYear, 1, 1);
        testSubs[3].SBQQ__SubscriptionEndDate__c = Date.newInstance(nextYear, 12, 25);
        testSubs[3].SBQQ__Quantity__c = 20;
        testSubs[3].SBQQ__NetPrice__c = 2400.00;
        //
        testSubs[4].SBQQ__Account__c = testAccounts[1].Id;
        testSubs[4].SBQQ__Contract__c = testContracts[2].Id;
        testSubs[4].SBQQ__Product__c = testPricebookEntries[0].Product2Id;
        testSubs[4].SBQQ__SubscriptionStartDate__c = Date.newInstance(currentYear, 1, 15);
        testSubs[4].SBQQ__SubscriptionEndDate__c = Date.newInstance(nextYear, 12, 31);
        testSubs[4].SBQQ__Quantity__c = 60;
        testSubs[4].SBQQ__NetPrice__c = 1800.00;
        //
        testSubs[5].SBQQ__Account__c = testAccounts[1].Id;
        testSubs[5].SBQQ__Contract__c = testContracts[2].Id;
        testSubs[5].SBQQ__Product__c = testPricebookEntries[1].Product2Id;
        testSubs[5].SBQQ__SubscriptionStartDate__c = Date.newInstance(nextYear, 1, 1);
        testSubs[5].SBQQ__SubscriptionEndDate__c = Date.newInstance(yearAfterNext, 12, 25);
        testSubs[5].SBQQ__Quantity__c = 5;
        testSubs[5].SBQQ__NetPrice__c = 2500.00;
        //
        testSubs[6].SBQQ__Account__c = testAccounts[1].Id;
        testSubs[6].SBQQ__Contract__c = testContracts[3].Id;
        testSubs[6].SBQQ__Product__c = testPricebookEntries[0].Product2Id;
        testSubs[6].SBQQ__SubscriptionStartDate__c = Date.newInstance(currentYear, 1, 1);
        testSubs[6].SBQQ__SubscriptionEndDate__c = Date.newInstance(yearAfterNext, 12, 31);
        testSubs[6].SBQQ__Quantity__c = 200;
        testSubs[6].SBQQ__NetPrice__c = 1200.00;
        //
        testSubs[7].SBQQ__Account__c = testAccounts[1].Id;
        testSubs[7].SBQQ__Contract__c = testContracts[3].Id;
        testSubs[7].SBQQ__Product__c = testPricebookEntries[1].Product2Id;
        testSubs[7].SBQQ__SubscriptionStartDate__c = Date.newInstance(nextYear, 1, 1);
        testSubs[7].SBQQ__SubscriptionEndDate__c = Date.newInstance(yearAfterNext, 12, 31);
        testSubs[7].SBQQ__Quantity__c = 50;
        testSubs[7].SBQQ__NetPrice__c = 750.00;
        insert testSubs;
    }
	
    /**
    * @description contractBurdenedMRRBatchableTest_WithoutParams - Test for the BatchableSch_ContractBurdenedMRR class using the constructor WITHOUT params
    */
    public static testmethod void contractBurdenedMRRBatchableTest_WithoutParams() {
        // GET TEST CONTRACTS
        List<Contract> testContracts = [SELECT Id, StartDate, EndDate, Contract_Type__c FROM Contract];
        System.assert(testContracts.size() == 4);

        Test.startTest();

        Database.executeBatch(new BatchableSch_ContractBurdenedMRR(), 2);

        Test.stopTest();

        // BURDENED MRR = SUM OF MRR IN LAST MONTH OF SUBSCRIPTIONS

        // REFRESH CONTRACT AND CHECK FOR CORRECT DATA
        testContracts = [SELECT Id, Burdened_MRR__c FROM Contract WHERE Id IN :testContracts];

        System.assertEquals(3250, testContracts[0].Burdened_MRR__c);
        System.assertEquals(4066, testContracts[1].Burdened_MRR__c);
        System.assertEquals(525, testContracts[2].Burdened_MRR__c);
        System.assertEquals(8229, testContracts[3].Burdened_MRR__c);

        // GET TEST ACCOUNTS AND CHECK FOR CORRECT DATA
        List<Account> testAccounts = [SELECT Id, Burdened_MRR__c FROM Account];
        System.assert(testAccounts.size() == 2);
        System.assertEquals(7316, testAccounts[0].Burdened_MRR__c);
        System.assertEquals(8754, testAccounts[1].Burdened_MRR__c);
    }

    /**
    * @description contractBurdenedMRRBatchableTest_WithParams - Test for the BatchableSch_ContractBurdenedMRR class using the constructor WITH params
    */
    public static testmethod void contractBurdenedMRRBatchableTest_WithParams() {
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, Burdened_MRR__c FROM Account];
        System.assert(testAccounts.size() == 2);

        // GET TEST CONTRACTS
        List<Contract> testContracts = [SELECT Id, StartDate, EndDate FROM Contract];
        System.assert(testContracts.size() == 4);

        Test.startTest();

        Database.executeBatch(new BatchableSch_ContractBurdenedMRR(new Set<Id>{ testAccounts[0].Id, testAccounts[1].Id }), 2);

        Test.stopTest();

        // BURDENED MRR = SUM OF MRR IN LAST MONTH OF SUBSCRIPTIONS

        // REFRESH CONTRACT AND CHECK FOR CORRECT DATA
        testContracts = [SELECT Id, Burdened_MRR__c FROM Contract WHERE Id IN :testContracts];
        System.assertEquals(3250, testContracts[0].Burdened_MRR__c);
        System.assertEquals(4066, testContracts[1].Burdened_MRR__c);
        System.assertEquals(525, testContracts[2].Burdened_MRR__c);
        System.assertEquals(8229, testContracts[3].Burdened_MRR__c);

        // RELOAD TEST ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, Burdened_MRR__c FROM Account];
        System.assert(testAccounts.size() == 2);
        System.assertEquals(7316, testAccounts[0].Burdened_MRR__c);
        System.assertEquals(8754, testAccounts[1].Burdened_MRR__c);      
    }

    /**
    * @description contractBurdenedMRRBatchableTest_ExpiredContracts - Test for the BatchableSch_ContractBurdenedMRR class using the contracts that have expired
    */
    public static testmethod void contractBurdenedMRRBatchableTest_ExpiredContracts() {
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, Burdened_MRR__c FROM Account];
        System.assert(testAccounts.size() == 2);

        // UPDATE TEST ACCOUNT TO HAVE BURDENED MRR
        testAccounts[0].Burdened_MRR__c = 7316;
        testAccounts[1].Burdened_MRR__c = 8766;
        update testAccounts;

        // GET TEST CONTRACTS
        List<Contract> testContracts = [SELECT Id, StartDate, EndDate FROM Contract];
        System.assert(testContracts.size() == 4);

        // UPDATE TEST CONTRACTS TO HAVE BURDENED MRR AND SOME TO BE EXPIRED
        testContracts[0].Burdened_MRR__c = 3250;
        testContracts[1].Burdened_MRR__c = 4066;
        testContracts[1].StartDate = Date.today().addDays(-365);
        testContracts[1].EndDate = Date.today().addDays(-1); //ENDED YESTERDAY
        //
        testContracts[2].Burdened_MRR__c = 525;
        testContracts[2].StartDate = Date.today().addDays(-380);
        testContracts[2].EndDate = Date.today().addDays(-1); //ENDED YESTERDAY
        //
        testContracts[3].Burdened_MRR__c = 8241;
        testContracts[3].StartDate = Date.today().addDays(-200);
        testContracts[3].EndDate = Date.today().addDays(-1); //ENDED YESTERDAY
        update testContracts;

        Test.startTest();

        Database.executeBatch(new BatchableSch_ContractBurdenedMRR(), 2);

        Test.stopTest();

        // BURDENED MRR = SUM OF MRR IN LAST MONTH OF SUBSCRIPTIONS BELONGING TO CURRENTLY ACTIVE CONTRACTS

        // REFRESH CONTRACT AND CHECK FOR CORRECT DATA
        testContracts = [SELECT Id, Burdened_MRR__c FROM Contract WHERE Id IN :testContracts];
        System.assertEquals(3250, testContracts[0].Burdened_MRR__c);
        System.assertEquals(0, testContracts[1].Burdened_MRR__c);
        System.assertEquals(0, testContracts[2].Burdened_MRR__c);
        System.assertEquals(0, testContracts[3].Burdened_MRR__c);

        // RELOAD TEST ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, Burdened_MRR__c FROM Account];
        System.assert(testAccounts.size() == 2);
        System.assertEquals(3250, testContracts[0].Burdened_MRR__c);
        System.assertEquals(0, testContracts[1].Burdened_MRR__c);
    }


    /**
    * @description executeSchedulableTest - 
    */
    public static testMethod void executeSchedulableTest(){
        Test.startTest();

        BatchableSch_ContractBurdenedMRR testSch = new BatchableSch_ContractBurdenedMRR();
        System.schedule('BatchableSch_ContractBurdenedMRR', '0 0 0 1 1 ? 2025', testSch);

        Test.stopTest();
    }


}