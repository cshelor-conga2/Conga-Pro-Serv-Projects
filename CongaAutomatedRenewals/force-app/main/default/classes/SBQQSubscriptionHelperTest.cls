/**
* @author Conga Services
* @date 20181030
* @version 1.00
* @description SBQQSubscriptionHelperTest  - Test class for the SBQQSubscriptionHelper class
*/
@isTest
public with sharing class SBQQSubscriptionHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // CREATE TEST GEOs
        List<TM_Geo__c> testGeos = (List<TM_Geo__c>)TestingUtility.createSObjectList('TM_Geo__c', false, 1);
        testGeos[0].Name = 'NA';
        testGeos[0].Is_Active__c = true;
        insert testGeos;

        // CREATE TM DIVISIONS
        List<TM_Division__c> testDivisions = (List<TM_Division__c>)TestingUtility.createSObjectList('TM_Division__c', false, 7);
        for(TM_Division__c division : testDivisions){
            division.TM_GeoId__c = testGeos[0].Id;
            division.Is_Active__c = true;
        }
        testDivisions[0].CS_Division__c = 'Division 1A';
        testDivisions[0].Minimum_MRR__c = 0;
        testDivisions[0].Maximum_MRR__c = 200;
        testDivisions[1].CS_Division__c = 'Division 1B';
        testDivisions[1].Minimum_MRR__c = 201;
        testDivisions[1].Maximum_MRR__c = 500;
        testDivisions[2].CS_Division__c = 'Division 1C';
        testDivisions[2].Minimum_MRR__c = 501;
        testDivisions[2].Maximum_MRR__c = 1000;
        testDivisions[3].CS_Division__c = 'Division 2';
        testDivisions[3].Minimum_MRR__c = 1001;
        testDivisions[3].Maximum_MRR__c = 3000;
        testDivisions[4].CS_Division__c = 'Division 3';
        testDivisions[4].Minimum_MRR__c = 3001;
        testDivisions[4].Maximum_MRR__c = 15000;
        testDivisions[5].CS_Division__c = 'Division 4';
        testDivisions[5].Minimum_MRR__c = 15001;
        testDivisions[5].Maximum_MRR__c = 75000;
        testDivisions[6].CS_Division__c = 'Division 5';
        testDivisions[6].Minimum_MRR__c = 75001;
        testDivisions[6].Maximum_MRR__c = 10000000;
        insert testDivisions;

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 2);
        testAccounts[0].Renewal_Uplift_Cap__c = null;
        testAccounts[0].SBQQ__RenewalPricingMethod__c = 'Uplift';
        testAccounts[1].Renewal_Uplift_Cap__c = 5;
        testAccounts[1].SBQQ__RenewalPricingMethod__c = 'Uplift';
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpps = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].StageName = 'Qualify';
        testOpps[0].Type = 'New Business';
        testOpps[0].New_Org__c = false;
        testOpps[1].AccountId = testAccounts[0].Id;
        testOpps[1].StageName = 'Qualify';
        testOpps[1].Type = 'Renewal';
        insert testOpps;

        // TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = (List<SBQQ__Quote__c>)TestingUtility.createSObjectList('SBQQ__Quote__c', false, 3);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.today();
        testQuotes[0].SBQQ__EndDate__c = Date.today().addDays(365);

        testQuotes[1].SBQQ__Status__c = 'Draft';
        testQuotes[1].SBQQ__Type__c = 'Renewal';
        testQuotes[1].SBQQ__StartDate__c = Date.today();
        testQuotes[1].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuotes[1].SBQQ__Account__c = testAccounts[0].Id;
        testQuotes[1].SBQQ__Opportunity2__c = testOpps[1].Id;

        testQuotes[2].SBQQ__Status__c = 'Draft';
        testQuotes[2].SBQQ__Type__c = 'Renewal';
        testQuotes[2].SBQQ__StartDate__c = Date.today();
        testQuotes[2].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuotes[2].SBQQ__Account__c = testAccounts[1].Id;
        testQuotes[2].SBQQ__Opportunity2__c = testOpps[1].Id;
        insert testQuotes;

        // CREATE TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.AccountId = testAccounts[0].Id;
        testContract.Status = 'Draft';
        testContract.SBQQ__Quote__c = testQuotes[0].Id;
        testContract.StartDate = Date.today();
        testContract.ContractTerm = 12;
        testContract.SBQQ__Opportunity__c = testOpps[0].Id;
        insert testContract;

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

        // TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = (List<SBQQ__QuoteLine__c>)TestingUtility.createSObjectList('SBQQ__QuoteLine__c', false, 5);
        testQuoteLines[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[1].Id;
        testQuoteLines[0].SBQQ__StartDate__c = Date.today();
        testQuoteLines[0].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 75;
        testQuoteLines[0].SBQQ__ListPrice__c = 50;
        testQuoteLines[0].SBQQ__ProratedListPrice__c = testQuoteLines[0].SBQQ__ListPrice__c;
        testQuoteLines[0].SBQQ__CustomerPrice__c = 45;

        testQuoteLines[1].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[1].SBQQ__Quote__c = testQuotes[1].Id;
        testQuoteLines[1].SBQQ__StartDate__c = Date.today();
        testQuoteLines[1].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__Quantity__c = 45;
        testQuoteLines[1].SBQQ__ListPrice__c = 125;
        testQuoteLines[1].SBQQ__ProratedListPrice__c = testQuoteLines[1].SBQQ__ListPrice__c;     
        testQuoteLines[1].SBQQ__CustomerPrice__c = 120;

        testQuoteLines[2].SBQQ__SubscriptionPricing__c = 'Percent Of Total';
        testQuoteLines[2].SBQQ__Quote__c = testQuotes[2].Id;
        testQuoteLines[2].SBQQ__StartDate__c = Date.today();
        testQuoteLines[2].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuoteLines[2].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[2].SBQQ__Quantity__c = 350;
        testQuoteLines[2].SBQQ__ListPrice__c = 40;
        testQuoteLines[2].SBQQ__ProratedListPrice__c = testQuoteLines[2].SBQQ__ListPrice__c;    
        testQuoteLines[2].SBQQ__CustomerPrice__c = 35;

        testQuoteLines[3].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[3].SBQQ__Quote__c = testQuotes[2].Id;
        testQuoteLines[3].SBQQ__StartDate__c = Date.today();
        testQuoteLines[3].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuoteLines[3].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[3].SBQQ__Quantity__c = 155;
        testQuoteLines[3].SBQQ__ListPrice__c = 35;

        testQuoteLines[4].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[4].SBQQ__Quote__c = testQuotes[2].Id;
        testQuoteLines[4].SBQQ__StartDate__c = Date.today();
        testQuoteLines[4].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuoteLines[4].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[4].SBQQ__Quantity__c = 90;
        testQuoteLines[4].SBQQ__ListPrice__c = 255;
        insert testQuoteLines;
    }

    /**
    * @description updateLeapYearFlagTest - 
    */
    public static testMethod void updateLeapYearFlagTest(){
        // GET TEST ACCOUNT
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        System.assert(testAccount != null);

        // GET TEST CONTRACT
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        System.assert(testContract != null);
        testContract.StartDate = Date.newInstance(2019, 1, 1);
        testContract.EndDate = Date.newInstance(2020, 3, 1);
        update testContract;

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts != null && !testProducts.isEmpty());

        // CREATE TEST SUBSCRIPTION
        SBQQ__Subscription__c testSub = (SBQQ__Subscription__c)TestingUtility.createSObject('SBQQ__Subscription__c', false, 1);
        testSub.SBQQ__Account__c = testAccount.Id;
        testSub.SBQQ__Contract__c = testContract.Id;
        testSub.SBQQ__Product__c = testProducts[0].Id;
        testSub.SBQQ__Quantity__c = 15;
        testSub.SBQQ__NetPrice__c = 25.00;
        testSub.SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSub.SBQQ__SubscriptionEndDate__c = Date.newInstance(2020, 3, 1);

        Test.startTest();

        insert testSub;
        testSub = [SELECT Id, Has_Leap_Year_Day__c FROM SBQQ__Subscription__c WHERE Id = :testSub.Id];
        System.assert(testSub.Has_Leap_Year_Day__c == true);

        testSub.SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSub.SBQQ__SubscriptionEndDate__c = Date.newInstance(2019, 12, 31);
        update testSub;

        testSub = [SELECT Id, Has_Leap_Year_Day__c FROM SBQQ__Subscription__c WHERE Id = :testSub.Id];
        System.assert(testSub.Has_Leap_Year_Day__c == false);

        Test.stopTest();
    }

    /**
    * @description calculateOppCurrentAverageMRRTest_Subscription - 
    */
    public static testMethod void calculateOppCurrentAverageMRRTest_Subscription(){
        // GET TEST ACCOUNT
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        System.assert(testAccount != null);

        // GET TEST CONTRACT
        Contract testContract = [SELECT Id, SBQQ__Opportunity__c, SBQQ__RenewalOpportunity__c FROM Contract LIMIT 1];
        System.assert(testContract != null);

        // GET RENEWAL OPP
        List<Opportunity> testRenewalOpps = [SELECT Id FROM Opportunity WHERE Type = 'Renewal'];

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts != null && !testProducts.isEmpty());

        // CREATE TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubs = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', false, 2);
        testSubs[0].SBQQ__Account__c = testAccount.Id;
        testSubs[0].SBQQ__Contract__c = testContract.Id;
        testSubs[0].SBQQ__Product__c = testProducts[0].Id;
        testSubs[0].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSubs[0].SBQQ__SubscriptionEndDate__c = Date.newInstance(2019, 12, 31);
        testSubs[0].SBQQ__Quantity__c = 15;
        testSubs[0].SBQQ__NetPrice__c = 25.00;

        testSubs[1].SBQQ__Account__c = testAccount.Id;
        testSubs[1].SBQQ__Contract__c = testContract.Id;
        testSubs[1].SBQQ__Product__c = testProducts[1].Id;
        testSubs[1].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSubs[1].SBQQ__SubscriptionEndDate__c = Date.newInstance(2020, 12, 31);
        testSubs[1].SBQQ__Quantity__c = 25;
        testSubs[1].SBQQ__NetPrice__c = 100.00;

        Test.startTest();

        // INSERT SUBS
        insert testSubs;

        // SET RENEWAL OPP ON CONTRACT
        testContract.SBQQ__RenewalOpportunity__c = testRenewalOpps[0].Id;
        update testContract;

        // MAKE QUALIFYING UPDATES TO SUBS
        testSubs[0].SBQQ__NetPrice__c = 125.00;
        testSubs[1].SBQQ__NetPrice__c = 500.00;
        update testSubs;

        // TEST FOR POPULATED FIELDS ON THE PARENT RENEWAL OPP
        Opportunity renewalOpp1 = [SELECT Id, Current_Composer_Ave_MRR__c, Current_Grid_Ave_MRR__c FROM Opportunity WHERE Type = 'Renewal' LIMIT 1];
        System.assert(renewalOpp1.Current_Composer_Ave_MRR__c > 0);
        System.assert(renewalOpp1.Current_Grid_Ave_MRR__c > 0);

        // MAKE QUALIFYING CHANGES AND UPDATE
        testSubs[0].SBQQ__NetPrice__c = 250.00;
        testSubs[1].SBQQ__NetPrice__c = 1000.00;
        update testSubs;

        // TEST VALUES
        Opportunity renewalOpp2 = [SELECT Id, Current_Composer_Ave_MRR__c, Current_Grid_Ave_MRR__c FROM Opportunity WHERE Type = 'Renewal' LIMIT 1];
        System.assert(renewalOpp2.Current_Composer_Ave_MRR__c > 0);
        System.assert(renewalOpp2.Current_Grid_Ave_MRR__c > 0);
        System.assert(renewalOpp2.Current_Composer_Ave_MRR__c != renewalOpp1.Current_Composer_Ave_MRR__c);
        System.assert(renewalOpp2.Current_Grid_Ave_MRR__c != renewalOpp1.Current_Grid_Ave_MRR__c);

        Test.stopTest();
    }

    /**
    * @description calculateOppCurrentAverageMRRTest_Contract - 
    */
    public static testMethod void calculateOppCurrentAverageMRRTest_Contract(){
        // GET TEST ACCOUNT
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        System.assert(testAccount != null);

        // GET TEST CONTRACT
        Contract testContract = [SELECT Id, SBQQ__Opportunity__c, SBQQ__RenewalOpportunity__c FROM Contract LIMIT 1];
        System.assert(testContract != null);
       
        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts != null && !testProducts.isEmpty());

        // CREATE TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubs = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', false, 2);
        testSubs[0].SBQQ__Account__c = testAccount.Id;
        testSubs[0].SBQQ__Contract__c = testContract.Id;
        testSubs[0].SBQQ__Product__c = testProducts[0].Id;
        testSubs[0].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSubs[0].SBQQ__SubscriptionEndDate__c = Date.newInstance(2019, 12, 31);
        testSubs[0].SBQQ__Quantity__c = 15;
        testSubs[0].SBQQ__NetPrice__c = 25.00;

        testSubs[1].SBQQ__Account__c = testAccount.Id;
        testSubs[1].SBQQ__Contract__c = testContract.Id;
        testSubs[1].SBQQ__Product__c = testProducts[1].Id;
        testSubs[1].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSubs[1].SBQQ__SubscriptionEndDate__c = Date.newInstance(2020, 12, 31);
        testSubs[1].SBQQ__Quantity__c = 25;
        testSubs[1].SBQQ__NetPrice__c = 100.00;
        insert testSubs;

        Test.startTest();

        // GET RENEWAL OPP AND TEST THAT IT DOES NOT HAVE ANY CURRENT MRR VALUES
        List<Opportunity> testRenewalOpps = [SELECT Id, Current_Composer_Ave_MRR__c, Current_Grid_Ave_MRR__c FROM Opportunity WHERE Type = 'Renewal'];
        System.assert(testRenewalOpps[0].Current_Composer_Ave_MRR__c == 0);
        System.assert(testRenewalOpps[0].Current_Grid_Ave_MRR__c == 0);

        // MAKE QUALIFYING CHANGES AND UPDATE
        testContract.SBQQ__RenewalOpportunity__c = testRenewalOpps[0].Id;
        update testContract;

        // TEST VALUES
        testRenewalOpps = [SELECT Id, Current_Composer_Ave_MRR__c, Current_Grid_Ave_MRR__c FROM Opportunity WHERE Type = 'Renewal'];
        System.assert(testRenewalOpps[0].Current_Composer_Ave_MRR__c > 0);
        System.assert(testRenewalOpps[0].Current_Grid_Ave_MRR__c > 0);
        
        Test.stopTest();
    }
    
    /**
    * @description calculateMRRTest - 
    */
    public static testMethod void calculateMRRTest() {
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id, (SELECT Id FROM DailyMRR__r) FROM Account];
        System.assert(testAccounts.size() == 2);
        System.assert(testAccounts[0].DailyMRR__r.size() == 0);
        System.assert(testAccounts[1].DailyMRR__r.size() == 0);

        // GET TEST CONTRACT
        Contract testContract = [SELECT Id, SBQQ__Opportunity__c, SBQQ__RenewalOpportunity__c FROM Contract LIMIT 1];
        System.assert(testContract != null);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts != null && !testProducts.isEmpty());

        // CREATE TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubs = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', false, 3);
        testSubs[0].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[0].SBQQ__Contract__c = testContract.Id;
        testSubs[0].SBQQ__Product__c = testProducts[0].Id;
        testSubs[0].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSubs[0].SBQQ__SubscriptionEndDate__c = Date.newInstance(2019, 12, 31);
        testSubs[0].SBQQ__Quantity__c = 15;
        testSubs[0].SBQQ__NetPrice__c = 25.00;

        testSubs[1].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[1].SBQQ__Contract__c = testContract.Id;
        testSubs[1].SBQQ__Product__c = testProducts[1].Id;
        testSubs[1].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSubs[1].SBQQ__SubscriptionEndDate__c = Date.newInstance(2020, 12, 31);
        testSubs[1].SBQQ__Quantity__c = 25;
        testSubs[1].SBQQ__NetPrice__c = 100.00;

        testSubs[2].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[2].SBQQ__Contract__c = testContract.Id;
        testSubs[2].SBQQ__Product__c = testProducts[1].Id;
        testSubs[2].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 15);
        testSubs[2].SBQQ__SubscriptionEndDate__c = Date.newInstance(2019, 10, 15);
        testSubs[2].SBQQ__Quantity__c = 5;
        testSubs[2].SBQQ__NetPrice__c = 750.00;

        Test.startTest();

        // INSERT SUBSCRIPTIONS AND TEST FOR CORRECT NUMBER OF MRR CALCULATION RECORDS
        insert testSubs;
        List<MRR_Calculation__c> mrrCalculationsSub1 = [SELECT Id FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[0].Id];
        List<MRR_Calculation__c> mrrCalculationsSub2 = [SELECT Id FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[1].Id];
        List<MRR_Calculation__c> mrrCalculationsSub3 = [SELECT Id FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[2].Id];
        System.assert(mrrCalculationsSub1.size() == 12); // 12 MONTH CALCULATIONS
        System.assert(mrrCalculationsSub2.size() == 24); // 24 MONTH CALCULATIONS
        System.assert(mrrCalculationsSub3.size() == 40); // 8 MONTH AND 32 DAY CALCULATIONS

        // UPDATE SUBSCRIPTIONS AND TEST FOR CORRECT NUMBER OF MRR CALCULATION RECORDS
        testSubs[0].SBQQ__SubscriptionEndDate__c = Date.newInstance(2020, 12, 31);
        testSubs[1].SBQQ__SubscriptionEndDate__c = Date.newInstance(2019, 6, 30);
        testSubs[2].SBQQ__NetPrice__c = 0;
        update testSubs;
        mrrCalculationsSub1 = [SELECT Id FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[0].Id];
        mrrCalculationsSub2 = [SELECT Id FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[1].Id];
        mrrCalculationsSub3 = [SELECT Id FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[2].Id];
        System.assert(mrrCalculationsSub1.size() == 24); // 24 MONTH CALCULATIONS
        System.assert(mrrCalculationsSub2.size() == 6); // 12 MONTH CALCULATIONS
        System.assert(mrrCalculationsSub3.size() == 0); // NET PRICE WAS ZEROED, ALL CALCULATIONS SHOULD HAVE BEEN DELETED

        // UPDATE SUBSCRIPTION ACCOUNT AND TEST FOR CORRECT NUMBER OF MRR CALCULATION RECORDS ON NEW ACCOUNT
        testSubs[0].SBQQ__Account__c = testAccounts[1].Id;
        update testSubs[0];
        mrrCalculationsSub1 = [SELECT Id, AccountId__c FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[0].Id];
        mrrCalculationsSub2 = [SELECT Id, AccountId__c FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[1].Id];
        mrrCalculationsSub3 = [SELECT Id, AccountId__c FROM MRR_Calculation__c WHERE SubscriptionId__c = :testSubs[2].Id];
        System.assert(mrrCalculationsSub1.size() == 24); // 24 MONTH CALCULATIONS
        System.assert(mrrCalculationsSub2.size() == 6); // 12 MONTH CALCULATIONS
        System.assert(mrrCalculationsSub3.size() == 0); // NET PRICE WAS ZEROED, ALL CALCULATIONS SHOULD HAVE BEEN DELETED
        for(MRR_Calculation__c mrr : mrrCalculationsSub1){
            System.assert(mrr.AccountId__c == testAccounts[1].Id);
        }
        for(MRR_Calculation__c mrr : mrrCalculationsSub2){
            System.assert(mrr.AccountId__c == testAccounts[0].Id);
        }
        for(MRR_Calculation__c mrr : mrrCalculationsSub3){
            System.assert(mrr.AccountId__c == testAccounts[0].Id);
        }

        Test.stopTest();
    }  

    /**
    * @author ECS, ERedding
    * @date 20190521
    * @description updateAccountCSDivisionTest - Test for the updateAccountCSDivision trigger method
    */
    public static testmethod void updateAccountCSDivisionTest() {
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id, Product2Id FROM PricebookEntry];
        System.assert(testPricebookEntries.size() == 2);

        // GET TEST QUOTES
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c];
        System.assert(testQuotes.size() == 3);
       
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 2);

        // GET TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = [SELECT Id FROM Opportunity WHERE Type = 'New Business'];
        System.assert(testOpportunities.size() == 1);

        // CREATE TEST OPP PRODUCTS
        List<OpportunityLineItem> testOpportunityLineItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 1);
        testOpportunityLineItems[0].OpportunityId = testOpportunities[0].Id;
        testOpportunityLineItems[0].Quantity = 75;
        testOpportunityLineItems[0].UnitPrice = 175.00;
        testOpportunityLineItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOpportunityLineItems[0].ServiceDate = Date.today();
        testOpportunityLineItems[0].Product_End_Date__c = Date.today().addDays(365);
        insert testOpportunityLineItems;

        Test.startTest();

        // CLOSE WIN OPP
        testOpportunities[0].Sales_Ops_Approved__c = true;
        testOpportunities[0].StageName = 'Closed Won';
        update testOpportunities[0];

        // CREATE TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.AccountId = testAccounts[0].Id;
        testContract.Status = 'Draft';
        testContract.SBQQ__Quote__c = testQuotes[0].Id;
        testContract.StartDate = Date.today();
        testContract.ContractTerm = 12;
        testContract.SBQQ__Opportunity__c = testOpportunities[0].Id;
        insert testContract;

        // CREATE TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubs = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', false, 2);
        testSubs[0].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[0].SBQQ__Contract__c = testContract.Id;
        testSubs[0].SBQQ__Product__c = testPricebookEntries[0].Product2Id;
        testSubs[0].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSubs[0].SBQQ__SubscriptionEndDate__c = Date.newInstance(2019, 12, 31);
        testSubs[0].SBQQ__Quantity__c = 5;
        testSubs[0].SBQQ__NetPrice__c = 2160.00; // MONTHLY MRR OF 900
        //
        testSubs[1].SBQQ__Account__c = testAccounts[0].Id;
        testSubs[1].SBQQ__Contract__c = testContract.Id;
        testSubs[1].SBQQ__Product__c = testPricebookEntries[1].Product2Id;
        testSubs[1].SBQQ__SubscriptionStartDate__c = Date.newInstance(2020, 1, 1);
        testSubs[1].SBQQ__SubscriptionEndDate__c = Date.newInstance(2020, 12, 31);
        testSubs[1].SBQQ__Quantity__c = 5;
        testSubs[1].SBQQ__NetPrice__c = 2160.00; // MONTHLY MRR OF 900
        insert testSubs;

        // BURDENED MRR = SUM OF MRR IN LAST MONTH OF SUBSCRIPTIONS = 900

        // UPDATE ACCOUNT AND CHECK FOR CORRECT DATA, BURDENED MMR >= 501 AND < 1000 SHOULD HAVE A CS DIVISION OF "Division 1C"
        testAccounts = [SELECT Id, CS_Division_Stamp__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].CS_Division_Stamp__c == 'Division 1C');

        Test.stopTest();
    }

    /**
    * @description calculateRenewalUpliftTest - Test calculateRenewalUplift trigger method
    */
    public static testMethod void calculateRenewalUpliftTest(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 2);

        // GET TEST CONTRACTS
        List<Contract> testContracts = [SELECT Id FROM Contract];
        System.assert(testContracts.size() == 1);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 2);

        // GET TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuotesLines = new List<SBQQ__QuoteLine__c>([SELECT Id, SBQQ__SubscriptionPricing__c, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__QuoteLine__c]);
        System.assert(testQuotesLines.size() == 5);

        Test.startTest();

        // TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubscriptions = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', true, 5);
        // CUSTOMER PRICE EQUALS LIST PRICE, NO UPLIFT WILL HAPPEN
        testSubscriptions[0].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[0].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[0].SBQQ__Product__c = testProducts[0].Id;
        testSubscriptions[0].SBQQ__QuoteLine__c = testQuotesLines[0].Id;
        testSubscriptions[0].SBQQ__SubscriptionStartDate__c = testQuotesLines[0].SBQQ__StartDate__c;
        testSubscriptions[0].SBQQ__SubscriptionEndDate__c = testQuotesLines[0].SBQQ__EndDate__c;
        testSubscriptions[0].SBQQ__Quantity__c = 15;
        testSubscriptions[0].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[0].SBQQ__CustomerPrice__c = 250.00;

        // MEETS ALL CRITERIA, UPLIFT WILL HAPPEN AND USE 8%
        testSubscriptions[1].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[1].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[1].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[1].SBQQ__QuoteLine__c = testQuotesLines[1].Id;
        testSubscriptions[1].SBQQ__SubscriptionStartDate__c = testQuotesLines[1].SBQQ__StartDate__c;
        testSubscriptions[1].SBQQ__SubscriptionEndDate__c = testQuotesLines[1].SBQQ__EndDate__c;
        testSubscriptions[1].SBQQ__Quantity__c = 15;
        testSubscriptions[1].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[1].SBQQ__CustomerPrice__c = 150.00;

        // SUBSCRIPTION PRICING DISQUALIFIES, NO UPLIFT WILL HAPPEN
        testSubscriptions[2].SBQQ__Account__c = testAccounts[1].Id;
        testSubscriptions[2].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[2].SBQQ__Product__c = testProducts[0].Id;
        testSubscriptions[2].SBQQ__QuoteLine__c = testQuotesLines[2].Id;
        testSubscriptions[2].SBQQ__SubscriptionStartDate__c = testQuotesLines[2].SBQQ__StartDate__c;
        testSubscriptions[2].SBQQ__SubscriptionEndDate__c = testQuotesLines[2].SBQQ__EndDate__c;
        testSubscriptions[2].SBQQ__Quantity__c = 15;
        testSubscriptions[2].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[2].SBQQ__CustomerPrice__c = 150.00;

        // MEETS ALL CRITERIA, UPLIFT WILL HAPPEN AND USE ACCOUNT CAP OF 5%
        testSubscriptions[3].SBQQ__Account__c = testAccounts[1].Id;
        testSubscriptions[3].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[3].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[3].SBQQ__QuoteLine__c = testQuotesLines[3].Id;
        testSubscriptions[3].SBQQ__SubscriptionStartDate__c = testQuotesLines[3].SBQQ__StartDate__c;
        testSubscriptions[3].SBQQ__SubscriptionEndDate__c = testQuotesLines[3].SBQQ__EndDate__c;
        testSubscriptions[3].SBQQ__Quantity__c = 15;
        testSubscriptions[3].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[3].SBQQ__CustomerPrice__c = 150.00;

        // MEETS ALL CRITERIA BUT UPLIFTED PRICE WILL GO OVER LIST, WILL USE CALCULATED PERCENTAGE
        testSubscriptions[4].SBQQ__Account__c = testAccounts[1].Id;
        testSubscriptions[4].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[4].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[4].SBQQ__QuoteLine__c = testQuotesLines[4].Id;
        testSubscriptions[4].SBQQ__SubscriptionStartDate__c = testQuotesLines[3].SBQQ__StartDate__c;
        testSubscriptions[4].SBQQ__SubscriptionEndDate__c = testQuotesLines[3].SBQQ__EndDate__c;
        testSubscriptions[4].SBQQ__Quantity__c = 15;
        testSubscriptions[4].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[4].SBQQ__CustomerPrice__c = 245.00;
        insert testSubscriptions;

        // REFRESH SUBSCRIPTION LIST, TEST FOR CORRECT DATA
        testSubscriptions = [SELECT Id, SBQQ__ListPrice__c, SBQQ__RenewalUpliftRate__c, SBQQ__RenewalPrice__c FROM SBQQ__Subscription__c WHERE Id IN :testSubscriptions];
        System.assert(testSubscriptions.size() == 5);
        System.assert(testSubscriptions[0].SBQQ__RenewalUpliftRate__c == null); // OPTED OUT FROM UPLIFT, VALUE SHOULD BE UNCHANGED
        System.assert(testSubscriptions[1].SBQQ__RenewalUpliftRate__c == 8.00); // MEETS CRITERIA , NO CAP, RATE SHOULD = 8
        System.assert(testSubscriptions[2].SBQQ__RenewalUpliftRate__c == null); // DISQUALIFIED FROM UPLIFT, VALUE SHOULD BE UNCHANGED
        System.assert(testSubscriptions[3].SBQQ__RenewalUpliftRate__c == 5.00); // MEETS CRITERIA, NO CAP, RATE SHOULD = 5
        System.assert(testSubscriptions[4].SBQQ__RenewalUpliftRate__c != null); // MEETS CRITERIA BUT UPLIFT GOES OVER LIST, CALCULATED % WILL BE USED

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20190723
    * @description calculateTotalDiscountTest - Test calculateTotalDiscount trigger method
    */
    public static testMethod void calculateTotalDiscountTest(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 2);

        // GET TEST CONTRACTS
        List<Contract> testContracts = [SELECT Id FROM Contract];
        System.assert(testContracts.size() == 1);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 2);

        // GET TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuotesLines = new List<SBQQ__QuoteLine__c>([SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__ListTotal__c, SBQQ__CustomerTotal__c,
                                                                                SBQQ__CustomerPrice__c, SBQQ__ListPrice__c, SBQQ__EffectiveQuantity__c,SBQQ__Renewal__c,
                                                                                SBQQ__PriorQuantity__c, SBQQ__ProratedListPrice__c, SBQQ__Quantity__c, SBQQ__PricingMethod__c,
                                                                                SBQQ__SubscriptionPricing__c, SBQQ__Discount__c
                                                                                FROM SBQQ__QuoteLine__c]);
        System.assert(testQuotesLines.size() == 5);

        Test.startTest();

        // TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubscriptions = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', true, 3);
        testSubscriptions[0].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[0].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[0].SBQQ__Product__c = testProducts[0].Id;
        testSubscriptions[0].SBQQ__QuoteLine__c = testQuotesLines[0].Id;
        testSubscriptions[0].SBQQ__SubscriptionStartDate__c = testQuotesLines[0].SBQQ__StartDate__c;
        testSubscriptions[0].SBQQ__SubscriptionEndDate__c = testQuotesLines[0].SBQQ__EndDate__c;
        testSubscriptions[0].SBQQ__Quantity__c = 75;
        testSubscriptions[0].SBQQ__ListPrice__c = 50.00;
        testSubscriptions[0].SBQQ__NetPrice__c = testSubscriptions[0].SBQQ__ListPrice__c;
        testSubscriptions[0].SBQQ__CustomerPrice__c = 45.00;

        testSubscriptions[1].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[1].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[1].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[1].SBQQ__QuoteLine__c = testQuotesLines[1].Id;
        testSubscriptions[1].SBQQ__SubscriptionStartDate__c = testQuotesLines[1].SBQQ__StartDate__c;
        testSubscriptions[1].SBQQ__SubscriptionEndDate__c = testQuotesLines[1].SBQQ__EndDate__c;
        testSubscriptions[1].SBQQ__Quantity__c = 45;
        testSubscriptions[1].SBQQ__ListPrice__c = 100.00;
        testSubscriptions[1].SBQQ__NetPrice__c = testSubscriptions[1].SBQQ__ListPrice__c;
        testSubscriptions[1].SBQQ__CustomerPrice__c = 80.00;

        testSubscriptions[2].SBQQ__Account__c = testAccounts[1].Id;
        testSubscriptions[2].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[2].SBQQ__Product__c = testProducts[0].Id;
        testSubscriptions[2].SBQQ__SubscriptionStartDate__c = testQuotesLines[2].SBQQ__StartDate__c;
        testSubscriptions[2].SBQQ__SubscriptionEndDate__c = testQuotesLines[2].SBQQ__EndDate__c;
        testSubscriptions[2].SBQQ__Quantity__c = 350;
        testSubscriptions[2].SBQQ__ListPrice__c = 40.00;
        testSubscriptions[2].SBQQ__NetPrice__c = testSubscriptions[2].SBQQ__ListPrice__c;
        testSubscriptions[2].SBQQ__CustomerPrice__c = 35.00;
        insert testSubscriptions;

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContracts = [SELECT Id, Overall_Subscription_Discount__c, Current_Overall_Subscription_Discount__c FROM Contract WHERE Id IN :testContracts];
        System.assert(testContracts[0].Overall_Subscription_Discount__c != null);
        System.assert(testContracts[0].Current_Overall_Subscription_Discount__c != null);
        // CHANGE QUOTE LINES
        testQuotesLines[0].SBQQ__Quantity__c = 350;
        testQuotesLines[1].SBQQ__ListPrice__c = 210;
        testQuotesLines[2].SBQQ__CustomerPrice__c = 25;
        update testQuotesLines;

        // CHANGE SUBSCRIPTIONS
        testSubscriptions[0].SBQQ__Quantity__c = 350;
        testSubscriptions[1].SBQQ__ListPrice__c = 210;
        testSubscriptions[2].SBQQ__CustomerPrice__c = 25;
        update testSubscriptions;

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContracts = [SELECT Id, Overall_Subscription_Discount__c, Current_Overall_Subscription_Discount__c FROM Contract WHERE Id IN :testContracts];
        System.assert(testContracts[0].Overall_Subscription_Discount__c != null);
        System.assert(testContracts[0].Current_Overall_Subscription_Discount__c != null);

        // DELETE SUBSCRIPTION AND CHECK DISCOUNTS
        delete testSubscriptions[0];

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContracts = [SELECT Id, Overall_Subscription_Discount__c, Current_Overall_Subscription_Discount__c FROM Contract WHERE Id IN :testContracts];
        System.assert(testContracts[0].Overall_Subscription_Discount__c != null);
        System.assert(testContracts[0].Current_Overall_Subscription_Discount__c != null);

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20200227
    * @description updateParentContractDatesTest - Test updateParentContractDates trigger method
    */
    public static testMethod void updateParentContractDatesTest(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 2);

        // GET TEST CONTRACTS
        List<Contract> testContracts = [SELECT Id FROM Contract];
        System.assert(testContracts.size() == 1);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 2);

        Test.startTest();

        // TEST SUBSCRIPTIONS
        Date startDate = Date.newInstance(2020, 1, 1);
        List<SBQQ__Subscription__c> testSubscriptions = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', true, 3);
        testSubscriptions[0].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[0].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[0].SBQQ__Product__c = testProducts[0].Id;
        testSubscriptions[0].SBQQ__SubscriptionStartDate__c = startDate;
        testSubscriptions[0].SBQQ__SubscriptionEndDate__c = startDate.addDays(365);
        //
        testSubscriptions[1].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[1].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[1].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[1].SBQQ__SubscriptionStartDate__c = startDate;
        testSubscriptions[1].SBQQ__SubscriptionEndDate__c = startDate.addDays(365);
        //
        testSubscriptions[2].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[2].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[2].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[2].SBQQ__SubscriptionStartDate__c = startDate;
        testSubscriptions[2].SBQQ__SubscriptionEndDate__c = startDate.addDays(365);
        insert testSubscriptions;

        // UPDATE DATES ON SUBSCRIPTIONS
        testSubscriptions[1].SBQQ__SubscriptionEndDate__c = startDate.addDays(180);
        testSubscriptions[2].SBQQ__SubscriptionEndDate__c = startDate.addDays(90);
        update testSubscriptions;

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContracts = [SELECT Id, StartDate, EndDate FROM Contract WHERE Id = :testContracts];
        System.assert(testContracts[0].StartDate == startDate);
        System.assert(testContracts[0].EndDate == startDate.addDays(365));

        // UPDATE DATES ON SUBSCRIPTIONS BY TURNING THEM INTO A 3 YEAR DEAL
        testSubscriptions[0].SBQQ__SubscriptionStartDate__c = Date.newInstance(2019, 1, 1);
        testSubscriptions[0].SBQQ__SubscriptionEndDate__c = testSubscriptions[0].SBQQ__SubscriptionStartDate__c.addDays(365);        
        testSubscriptions[1].SBQQ__SubscriptionStartDate__c = Date.newInstance(2020, 1, 1);
        testSubscriptions[1].SBQQ__SubscriptionEndDate__c = testSubscriptions[1].SBQQ__SubscriptionStartDate__c.addDays(365);
        testSubscriptions[2].SBQQ__SubscriptionStartDate__c = Date.newInstance(2021, 1, 1);        
        testSubscriptions[2].SBQQ__SubscriptionEndDate__c = testSubscriptions[2].SBQQ__SubscriptionStartDate__c.addDays(365);
        update testSubscriptions;

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContracts = [SELECT Id, StartDate, EndDate FROM Contract WHERE Id = :testContracts];
        System.assert(testContracts[0].StartDate == Date.newInstance(2019, 1, 1));
        System.assert(testContracts[0].EndDate == testSubscriptions[2].SBQQ__SubscriptionStartDate__c.addDays(365));

        Test.stopTest();
    }


}