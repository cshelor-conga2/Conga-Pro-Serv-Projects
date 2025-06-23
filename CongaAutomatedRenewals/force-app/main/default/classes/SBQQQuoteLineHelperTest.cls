/**
* @author Conga Services
* @date 20191031
* @version 1.00
* @description SBQQQuoteLineHelperTest - Test class for the SBQQQuoteLineHelper class
*/
@isTest
public with sharing class SBQQQuoteLineHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        TriggerHelper.OverrideAllSettings(true, false);
        
        Map<String, Id> recordTypes = UtilityClass.getRecordTypesForObject('Account');

        //// TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 2);  
        testAccounts[0].Name = 'Winterfell Inc.';  
        testAccounts[0].RecordTypeId = recordTypes.get('Business_Account');
        testAccounts[0].mrr_Active_MRR__c = 100.00;                     
        testAccounts[1].Name = 'Winterfell Inc.2';  
        testAccounts[1].RecordTypeId = recordTypes.get('Business_Account');
        insert testAccounts;

        //// TEST OPPS
        List<Opportunity> testOpportunities = TestingUtility.createSObjectList('Opportunity', false, 3);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = 'Closed Won';
        testOpportunities[0].Sales_Ops_Status__c = 'Closed Won';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[1].AccountId = testAccounts[1].Id;
        testOpportunities[1].StageName = 'Closed Won';
        testOpportunities[1].Sales_Ops_Status__c = 'Closed Won';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[2].AccountId = testAccounts[1].Id;
        testOpportunities[2].StageName = 'Qualify';
        testOpportunities[2].CloseDate = Date.today();
        insert testOpportunities;

        //// TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', false, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.today();
        testQuotes[0].SBQQ__EndDate__c = Date.today().addDays(365);
        insert testQuotes;

        //// TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 4);    
        testProducts[0].Name = 'Rev Schedule Prod';
        testProducts[0].ProductCode = 'RSP1';   
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[1].Name = 'Rev Schedule Prod';
        testProducts[1].ProductCode = 'RSP2';
        testProducts[1].FY16_Revenue_Type__c = 'Recurring';
        testProducts[2].Name = 'Rev Schedule Prod';
        testProducts[2].ProductCode = 'RSP2';
        testProducts[3].Name = 'MRR Exclude Product';
        testProducts[3].ProductCode = 'MRREX';
        testProducts[3].Exclude_from_MRR__c = true;
        insert testProducts;

        // TEST QUOTE LINE GROUP
        List<SBQQ__QuoteLineGroup__c> testQuoteLineGroups = TestingUtility.createSObjectList('SBQQ__QuoteLineGroup__c', false, 2);
        testQuoteLineGroups[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLineGroups[0].SBQQ__Number__c = 1;
        testQuoteLineGroups[0].SBQQ__StartDate__c = Date.today().addDays(15);
        testQuoteLineGroups[0].SBQQ__SubscriptionTerm__c = 15;
        testQuoteLineGroups[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLineGroups[1].SBQQ__Number__c = 2;
        testQuoteLineGroups[1].SBQQ__StartDate__c = Date.today().addDays(30);
        testQuoteLineGroups[1].SBQQ__SubscriptionTerm__c = 16;
        insert testQuoteLineGroups;

        //// TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', false, 3);
        testPricebookEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[0].Product2Id = testProducts[0].Id;
        testPricebookEntries[0].IsActive = TRUE;
        testPricebookEntries[0].UnitPrice = 200.00;
        testPricebookEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[1].Product2Id = testProducts[1].Id;
        testPricebookEntries[1].IsActive = TRUE;
        testPricebookEntries[1].UnitPrice = 500.00;
        testPricebookEntries[2].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[2].Product2Id = testProducts[2].Id;
        testPricebookEntries[2].IsActive = TRUE;
        testPricebookEntries[2].UnitPrice = 150.00;
        insert testPricebookEntries;
    }

    /**
    * @description copyDataFromParentProductTest - Test copyDataFromParentProduct trigger method
    */
    public static testMethod void copyDataFromParentProductTest(){
        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id, Exclude_from_MRR__c FROM Product2];
        System.assert(!testProducts.isEmpty() && testProducts.size() == 4);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>([SELECT Id FROM SBQQ__Quote__c]);
        System.assert(!testQuotes.isEmpty() && testQuotes.size() == 1);    

        // CREATE TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', false, 2);
        // NOT EXCLUDED FROM MRR
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[2].Id;
        testQuoteLines[0].SBQQ__StartDate__c = Date.today();
        testQuoteLines[0].SBQQ__EndDate__c = Date.today().addDays(180);
        testQuoteLines[0].Exclude_from_MRR__c = true; // WILL BE OVERWRITTEN SINCE PARENT PRODUCT IS NOT EXCLUDED
        // EXCLUDED FROM MRR
        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[3].Id;
        testQuoteLines[1].SBQQ__StartDate__c = Date.today();
        testQuoteLines[1].SBQQ__EndDate__c =  Date.today().addDays(180);
        insert testQuoteLines;

        Test.startTest();

        // REFRESH QUOTE LINES AND ENSURE FIELDS WERE UPDATED PROPERLY
        testQuoteLines = [SELECT Id, Exclude_from_MRR__c FROM SBQQ__QuoteLine__c WHERE Id IN :testQuoteLines];
        System.assert(testQuoteLines[0].Exclude_from_MRR__c == testProducts[2].Exclude_from_MRR__c);
        System.assert(testQuoteLines[1].Exclude_from_MRR__c == testProducts[3].Exclude_from_MRR__c);

        // CHANGE QUOTE LINE PRODUCTS AND TEST
        testQuoteLines[0].SBQQ__Product__c = testProducts[3].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[2].Id;
        update testQuoteLines;

        // REFRESH QUOTE LINES AND ENSURE FIELDS WERE UPDATED PROPERLY
        testQuoteLines = [SELECT Id, Exclude_from_MRR__c FROM SBQQ__QuoteLine__c WHERE Id IN :testQuoteLines];
        System.assert(testQuoteLines[0].Exclude_from_MRR__c == testProducts[3].Exclude_from_MRR__c);
        System.assert(testQuoteLines[1].Exclude_from_MRR__c == testProducts[2].Exclude_from_MRR__c);

        Test.stopTest();
    }

    /**
    * @description updateOppItemStartEndDatesTest - Test updateOppItemStartEndDates trigger method
    */
    public static testMethod void updateOppItemStartEndDatesTest(){
        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];      
        System.assert(!testProducts.isEmpty() && testProducts.size() == 4);

        // GET TEST OPPS
        List<Opportunity> testOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE StageName = 'Qualify']);
        System.assert(!testOpps.isEmpty() && testOpps.size() == 1);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>([SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Quote__c]);
        System.assert(!testQuotes.isEmpty() && testQuotes.size() == 1);

        // GET TEST GROUP
        List<SBQQ__QuoteLineGroup__c> testGroups = new List<SBQQ__QuoteLineGroup__c>([SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c]);
        System.assert(!testGroups.isEmpty() && testGroups.size() == 2);

        // CREATE TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', true, 3);
        // IS RECURRING, NO GROUP
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 75;
        testQuoteLines[0].SBQQ__StartDate__c = Date.today();
        testQuoteLines[0].SBQQ__EndDate__c =  Date.today().addDays(180);
        // IS RECURRING, HAS GROUP
        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__Quantity__c = 15;
        testQuoteLines[1].SBQQ__Group__c = testGroups[0].Id;
        // NOT RECURRING
        testQuoteLines[2].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[2].SBQQ__Product__c = testProducts[2].Id;
        testQuoteLines[2].SBQQ__Quantity__c = 50;

        Test.startTest();

        insert testQuoteLines;

        // REFRESH QUOTE LINES AND ENSURE DATES WERE UPDATED
        testQuoteLines = [SELECT Id, Opp_Item_Start_Date__c, Opp_Item_End_Date__c, SBQQ__StartDate__c FROM SBQQ__QuoteLine__c WHERE Id IN :testQuoteLines];
        System.assert(!testQuoteLines.isEmpty());
        System.assert(testQuoteLines[0].Opp_Item_Start_Date__c == Date.today());
        System.assert(testQuoteLines[0].Opp_Item_End_Date__c == Date.today().addDays(180));
        System.assert(testQuoteLines[1].Opp_Item_Start_Date__c == testGroups[0].SBQQ__StartDate__c);
        System.assert(testQuoteLines[1].Opp_Item_End_Date__c == testGroups[0].SBQQ__StartDate__c.addMonths((Integer)testGroups[0].SBQQ__SubscriptionTerm__c)); 
        System.assert(testQuoteLines[2].Opp_Item_Start_Date__c == testQuotes[0].SBQQ__StartDate__c);
        System.assert(testQuoteLines[2].Opp_Item_End_Date__c == null); // NON RECURRING PRODUCTS DONT HAVE END DATES

        // CHANGE GROUP AND TEST
        testQuoteLines[1].SBQQ__Group__c = testGroups[1].Id;
        update testQuoteLines;

        // REFRESH QUOTE LINES AND ENSURE DATES WERE UPDATED
        testQuoteLines = [SELECT Id, Opp_Item_Start_Date__c, Opp_Item_End_Date__c FROM SBQQ__QuoteLine__c WHERE Id IN :testQuoteLines];
        System.assert(!testQuoteLines.isEmpty());
        System.assert(testQuoteLines[1].Opp_Item_Start_Date__c == testGroups[1].SBQQ__StartDate__c);
        System.assert(testQuoteLines[1].Opp_Item_End_Date__c == testGroups[1].SBQQ__StartDate__c.addMonths((Integer)testGroups[1].SBQQ__SubscriptionTerm__c)); 

        Test.stopTest();
    }

    /**
    * @description updateChildOppItemDatesTest - Test updateChildOppItemDates trigger method
    */
    public static testMethod void updateChildOppItemDatesTest(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(!testPricebookEntries.isEmpty() && testPricebookEntries.size() == 3);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];      
        System.assert(!testProducts.isEmpty() && testProducts.size() == 4);

        // GET TEST OPPS
        List<Opportunity> testOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE StageName = 'Qualify']);
        System.assert(!testOpps.isEmpty() && testOpps.size() == 1);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>([SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Quote__c]);
        System.assert(!testQuotes.isEmpty() && testQuotes.size() == 1);

        // GET TEST GROUP
        List<SBQQ__QuoteLineGroup__c> testGroups = new List<SBQQ__QuoteLineGroup__c>([SELECT Id, SBQQ__StartDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c]);
        System.assert(!testGroups.isEmpty() && testGroups.size() == 2);        

        // CREATE TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', true, 3);
        // IS RECURRING, NO GROUP
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 75;
        testQuoteLines[0].SBQQ__StartDate__c = Date.today();
        testQuoteLines[0].SBQQ__EndDate__c =  Date.today().addDays(180);
        // IS RECURRING, HAS GROUP
        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__Quantity__c = 15;
        testQuoteLines[1].SBQQ__Group__c = testGroups[0].Id;
        // NOT RECURRING
        testQuoteLines[2].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[2].SBQQ__Product__c = testProducts[2].Id;
        testQuoteLines[2].SBQQ__Quantity__c = 50;
        insert testQuoteLines;

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 3);
        testOppItems[0].OpportunityId = testOpps[0].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[0].ServiceDate = Date.today();
        testOppItems[0].Product_End_Date__c = Date.today().addDays(60);
        testOppItems[0].SBQQ__QuoteLine__c = testQuoteLines[0].Id;
        testOppItems[1].OpportunityId = testOpps[0].Id;
        testOppItems[1].Quantity = 5;
        testOppItems[1].UnitPrice = 500;
        testOppItems[1].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[1].ServiceDate = Date.today();
        testOppItems[1].Product_End_Date__c = Date.today().addDays(60);
        testOppItems[1].SBQQ__QuoteLine__c = testQuoteLines[1].Id;
        testOppItems[2].OpportunityId = testOpps[0].Id;
        testOppItems[2].Quantity = 10;
        testOppItems[2].UnitPrice = 500;
        testOppItems[2].PricebookEntryId = testPricebookEntries[2].Id;
        testOppItems[2].ServiceDate = Date.today();
        testOppItems[2].Product_End_Date__c = Date.today().addDays(60);
        testOppItems[2].SBQQ__QuoteLine__c = testQuoteLines[2].Id;
        insert testOppItems;

        Test.startTest();

        // UPDATE QUOTE LINES, REFRESH OPP ITEMS, TEST FOR CORRECT DATA
        testQuoteLines[0].SBQQ__StartDate__c = Date.newInstance(2019, 7, 1);
        testQuoteLines[0].SBQQ__EndDate__c = Date.newInstance(2020, 6, 30);
        testQuoteLines[1].SBQQ__StartDate__c = Date.today().addDays(30);
        testQuoteLines[2].SBQQ__StartDate__c = Date.today().addDays(30);
        testQuoteLines[2].SBQQ__EndDate__c = Date.today().addDays(300);
        update testQuoteLines;      

        testQuoteLines = [SELECT Id, Subscription_Months__c, Subscription_Years__c FROM SBQQ__QuoteLine__c WHERE Id IN :testQuoteLines];
        System.assert(testQuoteLines[0].Subscription_Months__c == 12.0000);
        System.assert(testQuoteLines[0].Subscription_Years__c == 1.0000);

        // REFRESH OPP ITEMS AND TEST FOR CORRECT DATA
        testOppItems = [SELECT Id, ServiceDate, Product_End_Date__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].ServiceDate == Date.newInstance(2019, 7, 1));
        System.assert(testOppItems[0].Product_End_Date__c == Date.newInstance(2020, 6, 30));
        System.assert(testOppItems[1].ServiceDate == Date.today().addDays(30));
        System.assert(testOppItems[1].Product_End_Date__c == testGroups[0].SBQQ__StartDate__c.addMonths((Integer)testGroups[0].SBQQ__SubscriptionTerm__c)); // GROUP NOT OVERRIDDEN
        System.assert(testOppItems[2].ServiceDate == Date.today().addDays(30));
        System.assert(testOppItems[2].Product_End_Date__c == null); // NON RECURRING PRODUCTS DONT HAVE END DATES

        Test.stopTest();
    }

    /**
    * @description updateParentMRRLeapYearTest - Test updateParentMRRLeapYear trigger method
    */
    public static testMethod void updateParentMRRLeapYearTest(){
        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];      
        System.assert(!testProducts.isEmpty() && testProducts.size() == 4);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>([SELECT Id FROM SBQQ__Quote__c]);
        System.assert(!testQuotes.isEmpty() && testQuotes.size() == 1);

        // CREATE TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', true, 1);
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 75;
        testQuoteLines[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuoteLines[0].SBQQ__EndDate__c = Date.newInstance(2020, 12, 31);

        Test.startTest();

        insert testQuoteLines;   

        // REFRESH OPP ITEMS AND TEST FOR CORRECT DATA
        testQuotes = [SELECT Id, MRR_Has_Leap_Year_Day__c FROM SBQQ__Quote__c WHERE Id IN :testQuotes];
        System.assert(testQuotes[0].MRR_Has_Leap_Year_Day__c == true);

        // UPDATE DATES SO THEY NO LONGER SPAN A LEAP YEAR
        testQuoteLines[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuoteLines[0].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        update testQuoteLines[0];

        // REFRESH OPP ITEMS AND TEST FOR CORRECT DATA
        testQuotes = [SELECT Id, MRR_Has_Leap_Year_Day__c FROM SBQQ__Quote__c WHERE Id IN :testQuotes];
        System.assert(testQuotes[0].MRR_Has_Leap_Year_Day__c == false);

        Test.stopTest();
    }

    /**
    * @description updateNetTotalTest - Test updateNetTotal trigger method
    */
    public static testMethod void updateNetTotalTest(){
        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];      
        System.assert(!testProducts.isEmpty() && testProducts.size() == 4);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>([SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Quote__c]);
        System.assert(!testQuotes.isEmpty() && testQuotes.size() == 1);   

        // CREATE TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', true, 3);
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;        
        testQuoteLines[0].SBQQ__NetPrice__c = 250.00;
        testQuoteLines[0].SBQQ__Quantity__c = 75;

        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__NetPrice__c = 50.00;
        testQuoteLines[1].SBQQ__Quantity__c = 0;
        testQuoteLines[1].SBQQ__DiscountScheduleType__c = 'Slab';
        testQuoteLines[1].SBQQ__Existing__c  = true;

        testQuoteLines[2].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[2].SBQQ__Product__c = testProducts[2].Id;
        testQuoteLines[2].SBQQ__NetPrice__c = 50.00;
        testQuoteLines[2].SBQQ__Quantity__c = 50;
        testQuoteLines[2].SBQQ__PriorQuantity__c = 100;
        testQuoteLines[2].SBQQ__UpgradedQuantity__c = 80;
        testQuoteLines[2].SBQQ__Existing__c = true;

        Test.startTest();

        insert testQuoteLines;

        // UPDATE QUOTE LINES, REFRESH OPP ITEMS, TEST FOR CORRECT DATA
        testQuoteLines = [SELECT Id, SBQQ__NetTotal__c, Net_Total__c FROM SBQQ__QuoteLine__c WHERE Id IN :testQuoteLines];
        System.assert(testQuoteLines[0].SBQQ__NetTotal__c == testQuoteLines[0].Net_Total__c);
        System.assert(testQuoteLines[1].SBQQ__NetTotal__c == testQuoteLines[1].Net_Total__c);
        System.assert(testQuoteLines[2].SBQQ__NetTotal__c == testQuoteLines[2].Net_Total__c);

        // MAKE APPLICABLE CHANGES
        testQuoteLines[0].SBQQ__NetPrice__c = 150.00;
        testQuoteLines[0].SBQQ__Quantity__c = 100;
        testQuoteLines[1].SBQQ__NetPrice__c = 300.00;
        testQuoteLines[1].SBQQ__PriorQuantity__c = 30;
        testQuoteLines[1].SBQQ__Existing__c  = false;
        testQuoteLines[2].SBQQ__PriorQuantity__c = 80;
        testQuoteLines[2].SBQQ__UpgradedQuantity__c = 10;
        testQuoteLines[2].SBQQ__Existing__c = true;

        update testQuoteLines;

        // UPDATE QUOTE LINES, REFRESH OPP ITEMS, TEST FOR CORRECT DATA
        testQuoteLines = [SELECT Id, SBQQ__NetTotal__c, Net_Total__c FROM SBQQ__QuoteLine__c WHERE Id IN :testQuoteLines];
        System.assert(testQuoteLines[0].SBQQ__NetTotal__c == testQuoteLines[0].Net_Total__c);
        System.assert(testQuoteLines[1].SBQQ__NetTotal__c == testQuoteLines[1].Net_Total__c);
        System.assert(testQuoteLines[2].SBQQ__NetTotal__c == testQuoteLines[2].Net_Total__c);

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20190723
    * @description calculateDiscountsTest - Test calculateDiscountsTest trigger method
    */
    public static testMethod void calculateDiscountsTest(){
        // GET TEST CONTRACTS
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c];
        System.assert(testQuotes.size() == 1);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 4);

        Test.startTest();

        // TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = (List<SBQQ__QuoteLine__c>)TestingUtility.createSObjectList('SBQQ__QuoteLine__c', true, 3);
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__StartDate__c = Date.today();
        testQuoteLines[0].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuoteLines[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[0].SBQQ__Quantity__c = 15;
        testQuoteLines[0].SBQQ__ListPrice__c = 250.00;
        testQuoteLines[0].SBQQ__Discount__c = 25.00; // = 187.50

        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__StartDate__c = Date.today();
        testQuoteLines[1].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuoteLines[1].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[1].SBQQ__Quantity__c = 15;
        testQuoteLines[1].SBQQ__ListPrice__c = 200.00;
        testQuoteLines[1].SBQQ__Discount__c = 15.00; // = 170.00

        testQuoteLines[2].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[2].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[2].SBQQ__StartDate__c = Date.today();
        testQuoteLines[2].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuoteLines[2].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[2].SBQQ__Quantity__c = 15;
        testQuoteLines[2].SBQQ__ListPrice__c = 100.00;
        testQuoteLines[2].SBQQ__Discount__c = 60.00; // = 40.00
        insert testQuoteLines;

        // REFRESH QUOTE AND TEST FOR CORRECT DATA
        testQuotes = [SELECT Id, Overall_Subscription_Discount__c, New_Products_Discount__c FROM SBQQ__Quote__c WHERE Id IN :testQuotes];
        System.assert(testQuotes[0].Overall_Subscription_Discount__c.setScale(2) == 27.73);
        System.assert(testQuotes[0].New_Products_Discount__c.setScale(2) == 27.73);

        // CHANGE QUOTE LINES AND CHECK DISCOUNT
        testQuoteLines[0].SBQQ__Quantity__c = 35;
        testQuoteLines[0].SBQQ__PriorQuantity__c = 15;
        testQuoteLines[1].SBQQ__ListPrice__c = 210;
        testQuoteLines[2].SBQQ__Discount__c = 45;
        update testQuoteLines;

        // REFRESH QUOTE AND TEST FOR CORRECT DATA
        testQuotes = [SELECT Id, Overall_Subscription_Discount__c, New_Products_Discount__c FROM SBQQ__Quote__c WHERE Id IN :testQuotes];
        System.assert(testQuotes[0].Overall_Subscription_Discount__c.setScale(2) == 24.89);
        System.assert(testQuotes[0].New_Products_Discount__c.setScale(2) == 24.68);

        // DELETE QUOTE LINE AND CHECK DISCOUNTS
        delete testQuoteLines[0];

        // REFRESH QUOTE AND TEST FOR CORRECT DATA
        testQuotes = [SELECT Id, Overall_Subscription_Discount__c, New_Products_Discount__c FROM SBQQ__Quote__c WHERE Id IN :testQuotes];
        System.assert(testQuotes[0].Overall_Subscription_Discount__c.setScale(2) == 24.68);
        System.assert(testQuotes[0].New_Products_Discount__c.setScale(2) == 24.68);

        Test.stopTest();
    }


}