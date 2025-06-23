/**
* @author Conga Services
* @date 20180611
* @version 1.00
* @description OpportunityLineItemHelperTest - Test methods for the OpportunityLineItemHelper class
*/
@isTest
public with sharing class OpportunityLineItemHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        //// TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 2);  
        testAccounts[0].Name = 'Winterfell Inc.';  
        testAccounts[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
        testAccounts[0].mrr_Active_MRR__c = 100.00;                     
        testAccounts[1].Name = 'Winterfell Inc.2';  
        testAccounts[1].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
        insert testAccounts;

        //// TEST OPPS
        List<Opportunity> testOpportunities = TestingUtility.createSObjectList('Opportunity', true, 3);
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
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', true, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.today();
        testQuotes[0].SBQQ__EndDate__c = Date.today().addDays(365);
        insert testQuotes;

        //// TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', true, 4);    
        testProducts[0].Name = 'Rev Schedule Prod';
        testProducts[0].ProductCode = 'RSP1';
        testProducts[0].Product_Line__c = 'Conga Composer';
        testProducts[0].RevenueScheduleType = 'Repeat';
        testProducts[0].RevenueInstallmentPeriod = 'Monthly';
        testProducts[0].NumberOfRevenueInstallments = 12;
        testProducts[0].CanUseRevenueSchedule = true;
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[1].Name = 'Rev Schedule Prod';
        testProducts[1].ProductCode = 'RSP2';
        testProducts[1].Product_Line__c = 'Conga Grid';
        testProducts[1].RevenueScheduleType = 'Repeat';
        testProducts[1].RevenueInstallmentPeriod = 'Monthly';
        testProducts[1].NumberOfRevenueInstallments = 12;
        testProducts[1].CanUseRevenueSchedule = true;
        testProducts[1].FY16_Revenue_Type__c = 'Recurring';
        testProducts[2].Name = 'Excluded From MRR Product';
        testProducts[2].ProductCode = 'EXMRR';
        testProducts[2].Product_Line__c = 'Conga Composer';
        testProducts[2].FY16_Revenue_Type__c = 'Recurring';
        testProducts[2].Exclude_from_MRR__c = true;
        testProducts[2].Service_Event_MRR__c = true;
        testProducts[3].Name = 'AI - Block Pricing';
        testProducts[3].ProductCode = 'BLKAI';
        testProducts[3].Product_Line__c = 'Conga AI';
        testProducts[3].FY16_Revenue_Type__c = 'Recurring';
        testProducts[3].SBQQ__PricingMethod__c = 'Block';
        insert testProducts;

        // TEST BLOCK PRICING
        List<SBQQ__BlockPrice__c> testBlockPricing = (List<SBQQ__BlockPrice__c>)TestingUtility.createSObjectList('SBQQ__BlockPrice__c', true, 1);
        testBlockPricing[0].Name = 'Test Block Pricing';
        testBlockPricing[0].SBQQ__Product__c = testProducts[3].Id;
        testBlockPricing[0].SBQQ__LowerBound__c = 21;
        testBlockPricing[0].SBQQ__UpperBound__c = 51;
        testBlockPricing[0].SBQQ__Price__c = 18500;
        insert testBlockPricing;

        // TEST QUOTE LINE GROUP
        List<SBQQ__QuoteLineGroup__c> testQuoteLineGroups = TestingUtility.createSObjectList('SBQQ__QuoteLineGroup__c', true, 1);
        testQuoteLineGroups[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLineGroups[0].SBQQ__Number__c = 1;
        testQuoteLineGroups[0].SBQQ__StartDate__c = Date.today();
        testQuoteLineGroups[0].SBQQ__SubscriptionTerm__c = 15;
        insert testQuoteLineGroups;

        // TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', true, 3);
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 50;
        testQuoteLines[0].SBQQ__ListPrice__c = 350;
        //
        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__Quantity__c = 75;
        testQuoteLines[1].SBQQ__ListPrice__c = 500;
        testQuoteLines[1].SBQQ__StartDate__c = Date.today();
        testQuoteLines[1].SBQQ__EndDate__c =  Date.today().addDays(180);
        //
        testQuoteLines[2].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[2].SBQQ__Product__c = testProducts[3].Id;
        testQuoteLines[2].SBQQ__PricingMethod__c = 'Block';
        testQuoteLines[2].SBQQ__Quantity__c = 25;
        testQuoteLines[2].SBQQ__StartDate__c = Date.today();
        testQuoteLines[2].SBQQ__EndDate__c =  Date.today().addDays(365);
        insert testQuoteLines;

        //// TEST STANDARD PRICEBOOK ENTRIES
        List<PricebookEntry> testStandardEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', true, 4);
        testStandardEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testStandardEntries[0].Product2Id = testProducts[0].Id;        
        testStandardEntries[0].IsActive = TRUE;
        testStandardEntries[0].UnitPrice = 350.00;
        //
        testStandardEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testStandardEntries[1].Product2Id = testProducts[1].Id;
        testStandardEntries[1].IsActive = TRUE;
        testStandardEntries[1].UnitPrice = 500.00;
        //
        testStandardEntries[2].Pricebook2Id = Test.getStandardPricebookId();
        testStandardEntries[2].Product2Id = testProducts[2].Id;
        testStandardEntries[2].IsActive = TRUE;
        testStandardEntries[2].UnitPrice = 750.00;
        //
        testStandardEntries[3].Pricebook2Id = Test.getStandardPricebookId();
        testStandardEntries[3].Product2Id = testProducts[3].Id;
        testStandardEntries[3].IsActive = TRUE;
        testStandardEntries[3].UnitPrice = 1000.00;
        insert testStandardEntries;
    }

    /**
    * @description copyDataFromParentProductTest - Test copyDataFromParentProduct trigger method
    */
    public static testMethod void copyDataFromParentProductTest(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id, Product2.Product_Line__c, Product2.FY16_Revenue_Type__c, Product2.Exclude_from_MRR__c, Product2.Service_Event_MRR__c
                                                     FROM PricebookEntry];      
        System.assert(testPricebookEntries.size() == 4);

        // GET TEST OPPS
        List<Opportunity> testOpps = new List<Opportunity>([SELECT Id FROM Opportunity]);

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 2);
        testOppItems[0].OpportunityId = testOpps[0].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[0].ServiceDate = Date.today();
        testOppItems[0].Product_End_Date__c = Date.today().addDays(60);
        testOppItems[0].Exclude_from_MRR__c = false;  // WILL BE OVERWRITTEN SINCE PARENT PRODUCT IS NOT EXCLUDED
        
        testOppItems[1].OpportunityId = testOpps[1].Id;
        testOppItems[1].Quantity = 5;
        testOppItems[1].TotalPrice = 70000;
        testOppItems[1].PricebookEntryId = testPricebookEntries[2].Id;
        testOppItems[1].ServiceDate = Date.today();
        testOppItems[1].Product_End_Date__c = Date.today().addDays(90);
        insert testOppItems;

        Test.startTest();

        // REFRESH QUOTE LINES AND ENSURE FIELDS WERE UPDATED PROPERLY
        testOppItems = [SELECT Id, Product_Line__c, Revenue_Type__c, Service_Event_MRR__c, Exclude_from_MRR__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].Product_Line__c == testPricebookEntries[1].Product2.Product_Line__c);
        System.assert(testOppItems[0].Revenue_Type__c == testPricebookEntries[1].Product2.FY16_Revenue_Type__c);
        System.assert(testOppItems[0].Service_Event_MRR__c == testPricebookEntries[1].Product2.Service_Event_MRR__c);
        System.assert(testOppItems[0].Exclude_from_MRR__c == testPricebookEntries[1].Product2.Exclude_from_MRR__c);

        System.assert(testOppItems[1].Product_Line__c == testPricebookEntries[2].Product2.Product_Line__c);
        System.assert(testOppItems[1].Revenue_Type__c == testPricebookEntries[2].Product2.FY16_Revenue_Type__c);
        System.assert(testOppItems[1].Service_Event_MRR__c == testPricebookEntries[2].Product2.Service_Event_MRR__c);
        System.assert(testOppItems[1].Exclude_from_MRR__c == testPricebookEntries[2].Product2.Exclude_from_MRR__c);

        Test.stopTest();
    }

    /**
    * @description overwriteCPQBlockPricingChangesTest - Test method for the OpportunityLineItemHelper.overwriteCPQBlockPricingChanges method
    */
    public static testmethod void overwriteCPQBlockPricingChangesTest(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(testPricebookEntries.size() == 4);

        // GET TEST OPPS
        List<Opportunity> testOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE StageName = 'Qualify']);
        System.assert(testOpps.size() == 1);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuote = new List<SBQQ__Quote__c>([SELECT Id FROM SBQQ__Quote__c]);
        System.assert(testQuote.size() == 1);

        // GET TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c>([SELECT Id, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__CustomerPrice__c, SBQQ__NetPrice__c, 
                                                                                        SBQQ__NetTotal__c
                                                                                FROM SBQQ__QuoteLine__c]);
        System.assert(testQuoteLines.size() == 3);

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 1);
        testOppItems[0].OpportunityId = testOpps[0].Id;
        testOppItems[0].Quantity = 1;
        testOppItems[0].UnitPrice = 18500;
        testOppItems[0].PricebookEntryId = testPricebookEntries[3].Id;
        testOppItems[0].ServiceDate = Date.today();
        testOppItems[0].Product_End_Date__c = Date.today().addDays(365);
        testOppItems[0].SBQQ__QuoteLine__c = testQuoteLines[2].Id;
        insert testOppItems;

        Test.startTest();

        // UPDATE AND TEST ITEMS
        testOppItems = [SELECT Id, Quantity, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].Quantity == testQuoteLines[2].SBQQ__Quantity__c);
        System.assert(testOppItems[0].TotalPrice == testQuoteLines[2].SBQQ__NetTotal__c);

        // MAKE UPDATE
        testOppItems[0].Quantity = 1;
        testOppItems[0].TotalPrice = 65000;
        update testOppItems;

        // UPDATE AND TEST BLOCK ITEM
        testOppItems = [SELECT Id, Quantity, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].Quantity == testQuoteLines[2].SBQQ__Quantity__c);
        System.assert(testOppItems[0].TotalPrice == testQuoteLines[2].SBQQ__NetTotal__c);

        // MAKE UPDATE
        testOppItems[0].Quantity = 1;
        testOppItems[0].TotalPrice = 45000;
        update testOppItems;

        // UPDATE AND TEST BLOCK ITEM
        testOppItems = [SELECT Id, Quantity, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE Id IN :testOppItems];       
        System.assert(testOppItems[0].Quantity == testQuoteLines[2].SBQQ__Quantity__c);
        System.assert(testOppItems[0].TotalPrice == testQuoteLines[2].SBQQ__NetTotal__c);

        Test.stopTest();
    }

    /**
    * @description updateProductSegmentationTest - Test method for the OpportunityLineItemHelper.updateProductSegmentation method
    */
    public static testmethod void updateProductSegmentationTest(){
        Id priceBookId = Test.getStandardPricebookId();

        Account acct = new Account();
            acct.Name = 'Test Account';
        insert acct;

        Product2 prod = new Product2();
            prod.Name = 'Novatus Best';
            prod.ProductCode = 'NovB';
            prod.LOB__C = 'Services';
            prod.FY16_Revenue_Type__c = 'Non-Recurring';
            prod.Family = 'Novatus Contracts';
        insert prod;

        Opportunity opp = new Opportunity();
            opp.OwnerId = UserInfo.getUserId();
            opp.AccountId = acct.Id;
            opp.Name = 'Great Opportunity';
            opp.Type = 'Renewal';
            opp.LeadSource = 'Renewal';
            opp.StageName = 'Qualify';
            opp.CloseDate = Date.today();
        insert opp;

        PricebookEntry price = new PricebookEntry();
            price.Pricebook2Id = Test.getStandardPricebookId();
            price.IsActive = TRUE;
            price.UnitPrice = 1.00;
            price.Product2Id = prod.Id;
        insert price;

        Test.startTest();
        
        OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = opp.Id;
            oli.Description = 'Test';
            oli.ServiceDate = Date.today();
            oli.UnitPrice = 225.00;
            oli.Quantity = 1;
            oli.PricebookEntryId = price.Id;

        // CREATE ITEM AND TEST FOR CORRECT OPP DATA
        insert oli;
        opp = [SELECT Id, Product_Segmentation__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(opp.Product_Segmentation__c == 'CLM');

        // DELETE ITEM AND TEST FOR CORRECT OPP DATA
        delete oli;
        opp = [SELECT Id, Product_Segmentation__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(String.isBlank(opp.Product_Segmentation__c));

        Test.stopTest();
    }

    /**
    * @description updateServiceProdEndDatesTest - Test method for the OpportunityLineItemHelper.updateServiceProdEndDates method
    */
    public static testmethod void updateServiceProdEndDatesTest(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(testPricebookEntries.size() == 4);

        // GET TEST OPPS
        List<Opportunity> testOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE StageName = 'Qualify']);
        System.assert(testOpps.size() == 1);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuote = new List<SBQQ__Quote__c>([SELECT Id FROM SBQQ__Quote__c]);
        System.assert(testQuote.size() == 1);

        // GET TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c>([SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, Opp_Item_Start_Date__c, Opp_Item_End_Date__c
                                                                                FROM SBQQ__QuoteLine__c]);
        System.assert(testQuoteLines.size() == 3);

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 2);
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

        Test.startTest();      
          
        // EXECUTE TRIGGER
        insert testOppItems;

        // UPDATE AND TEST ITEMS
        testOppItems = [SELECT Id, ServiceDate, Product_End_Date__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].ServiceDate == testQuoteLines[0].Opp_Item_Start_Date__c);
        System.assert(testOppItems[0].Product_End_Date__c == testQuoteLines[0].Opp_Item_End_Date__c);
        System.assert(testOppItems[1].ServiceDate == testQuoteLines[1].Opp_Item_Start_Date__c);
        System.assert(testOppItems[1].Product_End_Date__c == testQuoteLines[1].Opp_Item_End_Date__c);

        // MAKE UPDATE
        testOppItems[0].SBQQ__QuoteLine__c = testQuoteLines[1].Id;
        testOppItems[1].SBQQ__QuoteLine__c = testQuoteLines[0].Id;
        update testOppItems;

        // UPDATE AND TEST ITEMS
        testOppItems = [SELECT Id, ServiceDate, Product_End_Date__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].ServiceDate == testQuoteLines[1].Opp_Item_Start_Date__c);
        System.assert(testOppItems[0].Product_End_Date__c == testQuoteLines[1].Opp_Item_End_Date__c);
        System.assert(testOppItems[1].ServiceDate == testQuoteLines[0].Opp_Item_Start_Date__c);
        System.assert(testOppItems[1].Product_End_Date__c == testQuoteLines[0].Opp_Item_End_Date__c);

        Test.stopTest();
    }


    /**
    * @description updateMRRDatesTest - Test method for the OpportunityLineItemHelper.updateMRRDates method
    */
    public static testmethod void updateMRRDatesTest(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(testPricebookEntries.size() == 4);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];      
        System.assert(testProducts.size() == 4);

        // GET TEST OPPS
        List<Opportunity> testOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE StageName = 'Qualify']);
        System.assert(testOpps.size() == 1);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuote = new List<SBQQ__Quote__c>([SELECT Id FROM SBQQ__Quote__c]);
        System.assert(testQuote.size() == 1);

        // CREATE TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', true, 2);
        testQuoteLines[0].SBQQ__Quote__c = testQuote[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 50;
        testQuoteLines[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuoteLines[0].SBQQ__EndDate__c =  Date.newInstance(2018, 12, 31);
        testQuoteLines[1].SBQQ__Quote__c = testQuote[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__Quantity__c = 75;
        testQuoteLines[1].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuoteLines[1].SBQQ__EndDate__c =  Date.newInstance(2019, 12, 31);
        insert testQuoteLines;

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 2);
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
        insert testOppItems;

        Test.startTest();
          
        // TEST FOR CORRECT DATA
        testOppItems = [SELECT Id, MRR_Start_Date__c, MRR_End_Date__c, MRR_Has_Leap_Year_Day__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].MRR_Start_Date__c == testQuoteLines[0].SBQQ__StartDate__c);
        System.assert(testOppItems[0].MRR_End_Date__c == testQuoteLines[1].SBQQ__EndDate__c);
        System.assert(testOppItems[0].MRR_Has_Leap_Year_Day__c == false);
        System.assert(testOppItems[1].MRR_Start_Date__c == testQuoteLines[0].SBQQ__StartDate__c);
        System.assert(testOppItems[1].MRR_End_Date__c == testQuoteLines[1].SBQQ__EndDate__c);
        System.assert(testOppItems[1].MRR_Has_Leap_Year_Day__c == false);

        // UPDATE OPP ITEM DATE AND RETEST
        testOppItems[0].ServiceDate = Date.newInstance(2018, 1, 15);
        testOppItems[0].Product_End_Date__c = Date.newInstance(2020, 12, 31);
        update testOppItems[0];
        testOppItems = [SELECT Id, Product_End_Date__c, MRR_Start_Date__c, MRR_End_Date__c, MRR_Has_Leap_Year_Day__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].MRR_Start_Date__c == testQuoteLines[0].SBQQ__StartDate__c);
        System.assert(testOppItems[0].MRR_End_Date__c == testOppItems[0].Product_End_Date__c);
        System.assert(testOppItems[0].MRR_Has_Leap_Year_Day__c == true);
        System.assert(testOppItems[1].MRR_Start_Date__c == testQuoteLines[0].SBQQ__StartDate__c);
        System.assert(testOppItems[1].MRR_End_Date__c == testOppItems[0].Product_End_Date__c);
        System.assert(testOppItems[1].MRR_Has_Leap_Year_Day__c == true);

        // DELETE AN OPP ITEM AND RETEST
        delete testOppItems[0];
        testOppItems = [SELECT Id, Product_End_Date__c, MRR_Start_Date__c, MRR_End_Date__c, MRR_Has_Leap_Year_Day__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].MRR_Start_Date__c == testQuoteLines[0].SBQQ__StartDate__c);
        System.assert(testOppItems[0].MRR_End_Date__c == testQuoteLines[1].SBQQ__EndDate__c);
        System.assert(testOppItems[0].MRR_Has_Leap_Year_Day__c == false);      
        
        Test.stopTest();
    }


    /**
    * @description updateParentOppMRRDatesTest - Test method for the OpportunityLineItemHelper.updateParentOppMRRDates method
    */
    public static testmethod void updateParentOppMRRDatesTest(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(testPricebookEntries.size() == 4);

        // GET TEST OPPS
        List<Opportunity> testOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE StageName = 'Qualify']);
        System.assert(testOpps.size() == 1);

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 2);
        testOppItems[0].OpportunityId = testOpps[0].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[0].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[0].MRR_Start_Date__c = Date.newInstance(2018, 1, 1);
        testOppItems[0].Product_End_Date__c = Date.newInstance(2018, 12, 31);
        testOppItems[0].MRR_End_Date__c = Date.newInstance(2018, 12, 31);
        //
        testOppItems[1].OpportunityId = testOpps[0].Id;
        testOppItems[1].Quantity = 5;
        testOppItems[1].UnitPrice = 500;
        testOppItems[1].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[1].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[1].MRR_Start_Date__c = Date.newInstance(2018, 1, 1);
        testOppItems[1].Product_End_Date__c = Date.newInstance(2019, 12, 31);
        testOppItems[1].MRR_End_Date__c = Date.newInstance(2019, 12, 31);

        Test.startTest();

        // TEST FOR CORRECT DATA
        insert testOppItems;
        testOpps = [SELECT Id, MRR_Sub_Start__c, MRR_Sub_End__c, MRR_Has_Leap_Year_Day__c FROM Opportunity WHERE Id IN :testOpps];
        System.assert(testOpps[0].MRR_Sub_Start__c == testOppItems[0].MRR_Start_Date__c);
        System.assert(testOpps[0].MRR_Sub_End__c == testOppItems[1].MRR_End_Date__c);
        System.assert(testOpps[0].MRR_Has_Leap_Year_Day__c == false);

        // UPDATE OPP ITEM DATE AND RETEST
        testOppItems[0].MRR_Start_Date__c = Date.newInstance(2018, 1, 15);
        testOppItems[0].MRR_End_Date__c = Date.newInstance(2020, 12, 31);
        update testOppItems[0];

        testOpps = [SELECT Id, MRR_Sub_Start__c, MRR_Sub_End__c, MRR_Has_Leap_Year_Day__c FROM Opportunity WHERE Id IN :testOpps];
        System.assert(testOpps[0].MRR_Sub_Start__c == testOppItems[1].MRR_Start_Date__c);
        System.assert(testOpps[0].MRR_Sub_End__c == testOppItems[0].MRR_End_Date__c);
        System.assert(testOpps[0].MRR_Has_Leap_Year_Day__c == true);

        // DELETE OPP ITEM DATE AND RETEST
        delete testOppItems[0];
        testOpps = [SELECT Id, MRR_Sub_Start__c, MRR_Sub_End__c, MRR_Has_Leap_Year_Day__c FROM Opportunity WHERE Id IN :testOpps];
        System.assert(testOpps[0].MRR_Sub_Start__c == testOppItems[1].MRR_Start_Date__c);
        System.assert(testOpps[0].MRR_Sub_End__c == testOppItems[1].MRR_End_Date__c);
        System.assert(testOpps[0].MRR_Has_Leap_Year_Day__c == false);

        Test.stopTest();
    }


    /**
    * @description updateLeapYearFlagTest - Test method for the OpportunityLineItemHelper.updateLeapYearFlag method
    */
    public static testmethod void updateLeapYearFlagTest(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(testPricebookEntries.size() == 4);

        // GET TEST OPPS
        List<Opportunity> testOpps = new List<Opportunity>([SELECT Id FROM Opportunity WHERE StageName = 'Qualify']);
        System.assert(testOpps.size() == 1);

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 1);
        testOppItems[0].OpportunityId = testOpps[0].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[0].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[0].Product_End_Date__c = Date.newInstance(2019, 12, 31);

        Test.startTest(); 

        // SAVE AND TEST FOR CORRECT DATA
        insert testOppItems;
        testOppItems = [SELECT Id, Leap_Year_Day__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].Leap_Year_Day__c == false);
       
        // UPDATE OPP ITEM DATE AND RETEST
        testOppItems[0].Product_End_Date__c = Date.newInstance(2020, 12, 31);
        update testOppItems[0];
        testOppItems = [SELECT Id, Leap_Year_Day__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        System.assert(testOppItems[0].Leap_Year_Day__c == true);

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20190710
    * @description updateOppPartnerExpertiseScoreTest - Test for the updateOppPartnerExpertiseScore trigger method
    */
    public static testmethod void updateOppPartnerExpertiseScoreTest() {
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(testPricebookEntries.size() == 4);

        // CREATE TEST ACCOUNTS
        Id partnerRecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[1].RecordTypeId = partnerRecordTypeId;
        testAccounts[1].Partner_Specialist__c = 'Conga Grid;Conga Collaborate;Conga AI';
        testAccounts[1].Partner_Expert__c = 'Conga Automation;Conga Composer';
        testAccounts[2].RecordTypeId = partnerRecordTypeId;
        testAccounts[2].Partner_Specialist__c = 'Conga Collaborate;Conga AI';
        testAccounts[2].Partner_Expert__c = 'Conga Composer;Conga Automation;';
        insert testAccounts;

        // TEST OPP
        List<Opportunity> testOpps = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].ImplementationPartnerPrimary__c = testAccounts[1].Id;
        testOpps[1].AccountId = testAccounts[0].Id;
        testOpps[1].ImplementationPartnerPrimary__c = testAccounts[2].Id;
        insert testOpps;

        Date startDate = Date.today();
        Date endDate = Date.today().addDays(365);
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', false, 3);
        testOppItems[0].OpportunityId = testOpps[0].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[0].ServiceDate = startDate;
        testOppItems[0].Product_End_Date__c = endDate;

        testOppItems[1].OpportunityId = testOpps[0].Id;
        testOppItems[1].Quantity = 5;
        testOppItems[1].UnitPrice = 500;
        testOppItems[1].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[1].ServiceDate = startDate;
        testOppItems[1].Product_End_Date__c = endDate;

        testOppItems[2].OpportunityId = testOpps[1].Id;
        testOppItems[2].Quantity = 5;
        testOppItems[2].UnitPrice = 500;
        testOppItems[2].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[2].ServiceDate = startDate;
        testOppItems[2].Product_End_Date__c = endDate;
        insert testOppItems;

        Test.startTest();

        // DELETE A TEST ITEM
        delete testOppItems[1];

        // CREATE A NEW TEST ITEM
        OpportunityLineItem newTestItem = new OpportunityLineItem();
        newTestItem.OpportunityId = testOpps[1].Id;
        newTestItem.Quantity = 5;
        newTestItem.UnitPrice = 500;
        newTestItem.PricebookEntryId = testPricebookEntries[1].Id;
        newTestItem.ServiceDate = Date.newInstance(2018, 1, 1);
        newTestItem.Product_End_Date__c = Date.newInstance(2019, 12, 30);
        insert newTestItem;

        ///////////// NO TESTS, PRIMARY CODE FOUND IN THE OPPORTUNITY HELPER CLASS WILL BE TESTED BY ITS OWN TEST CLASS //////////////

        Test.stopTest();
    }


}