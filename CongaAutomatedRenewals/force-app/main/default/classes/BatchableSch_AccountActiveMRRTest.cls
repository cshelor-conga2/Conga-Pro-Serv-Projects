/**
* @author Conga Services
* @date 
* @version 1.00
* @description BatchableSch_AccountActiveMRRTest - Test class for the BatchableSch_AccountActiveMRR class
*/
@isTest
public with sharing class BatchableSch_AccountActiveMRRTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // CREATE TEST ACCOUNTS
        Account testAccount = (Account)TestingUtility.createSObject('Account', false, 1);
        testAccount.Renewal_Uplift_Cap__c = null;
        testAccount.SBQQ__RenewalPricingMethod__c = 'Uplift';
        insert testAccount;
 
        // CREATE TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false, 1);
        testContract.AccountId = testAccount.Id;
        testContract.Status = 'Draft';
        testContract.StartDate = Date.today();
        testContract.ContractTerm = 12;
        insert testContract;

        // CREATE TEST PRODUCTS
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 4);
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

        testProducts[2].Name = 'Test Product 2';
        testProducts[2].ProductCode = 'TP3';
        testProducts[2].Family = 'Conga Courier';
        testProducts[2].Product_Line__c = 'Conga Courier';
        testProducts[2].FY16_Revenue_Type__c = 'Recurring';
        testProducts[2].SBQQ__SubscriptionPricing__c = 'Fixed Price';

        testProducts[3].Name = 'Test Product 2';
        testProducts[3].ProductCode = 'TP4';
        testProducts[3].Family = 'Conga Sign';
        testProducts[3].Product_Line__c = 'Conga Sign';
        testProducts[3].FY16_Revenue_Type__c = 'Recurring';
        testProducts[3].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        insert testProducts;
    }

    /**
    * @description executeBatchTest - 
    */
    public static testMethod void executeBatchTest(){
        // GET TEST ACCOUNT
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        System.assert(testAccount != null);

        // GET TEST CONTRACT
        Contract testContract = [SELECT Id, SBQQ__Opportunity__c, SBQQ__RenewalOpportunity__c FROM Contract LIMIT 1];
        System.assert(testContract != null);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(!testProducts.isEmpty());

        Integer currentYear = Date.today().year();

        // CREATE TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubs = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', false, 4);
        for(SBQQ__Subscription__c testSub : testSubs){
            testSub.SBQQ__Account__c = testAccount.Id;
            testSub.SBQQ__Contract__c = testContract.Id;
        }
        testSubs[0].SBQQ__Product__c = testProducts[0].Id;
        testSubs[0].SBQQ__SubscriptionStartDate__c = Date.newInstance(currentYear, 1, 1);
        testSubs[0].SBQQ__SubscriptionEndDate__c = Date.newInstance(currentYear, 12, 31);
        testSubs[0].SBQQ__Quantity__c = 75;
        testSubs[0].SBQQ__NetPrice__c = 25.00;

        testSubs[1].SBQQ__Product__c = testProducts[1].Id;
        testSubs[1].SBQQ__SubscriptionStartDate__c = Date.newInstance(currentYear, 1, 1);
        testSubs[1].SBQQ__SubscriptionEndDate__c = Date.newInstance(currentYear, 12, 31);
        testSubs[1].SBQQ__Quantity__c = 65;
        testSubs[1].SBQQ__NetPrice__c = 100.00;

        testSubs[2].SBQQ__Product__c = testProducts[2].Id;
        testSubs[2].SBQQ__SubscriptionStartDate__c = Date.newInstance(currentYear, 1, 15);
        testSubs[2].SBQQ__SubscriptionEndDate__c = Date.newInstance(currentYear, 12, 31);
        testSubs[2].SBQQ__Quantity__c = 35;
        testSubs[2].SBQQ__NetPrice__c = 250.00;

        testSubs[3].SBQQ__Product__c = testProducts[3].Id;
        testSubs[3].SBQQ__SubscriptionStartDate__c = Date.newInstance(currentYear, 1, 20);
        testSubs[3].SBQQ__SubscriptionEndDate__c = Date.newInstance(currentYear, 12, 31);
        testSubs[3].SBQQ__Quantity__c = 25;
        testSubs[3].SBQQ__NetPrice__c = 150.00;
        insert testSubs;

        Test.startTest();

        // TEST THAT MRR CALCULATION RECORDS WERE CREATED FOR THE ACCOUNT
        List<MRR_Calculation__c> mrrRecords = [SELECT Id FROM MRR_Calculation__c WHERE AccountId__c = :testAccount.Id];
        System.assert(!mrrRecords.isEmpty());

        // EXECUTE BATCH CLASS TO CALCULATE MRR FOR EACH PRODUCT LINE ON THE ACCOUNT
        BatchableSch_AccountActiveMRR batchClass = new BatchableSch_AccountActiveMRR();
        Database.executeBatch(batchClass, 5);

        Test.stopTest();

        // RELOAD ACCOUNT AND TEST FOR CORRECT DATA
        testAccount = [SELECT Id, Active_Composer_MRR__c, Active_Courier_MRR__c, Active_Grid_MRR__c, Active_Sign_MRR__c FROM Account LIMIT 1];
        System.assert(testAccount.Active_Composer_MRR__c > 0);
        System.assert(testAccount.Active_Courier_MRR__c > 0);
        System.assert(testAccount.Active_Grid_MRR__c > 0);
        System.assert(testAccount.Active_Sign_MRR__c > 0);
    }

    /**
    * @description executeSchedulableTest - 
    */
    public static testMethod void executeSchedulableTest(){
        Test.startTest();

        BatchableSch_AccountActiveMRR batchClass = new BatchableSch_AccountActiveMRR();
        batchClass.execute(null);

        Test.stopTest();
    }


}