/**
* @author ECS, ERedding
* @date 20190618
* @version 1.00
* @description Queueable_CalculateOppMRRTotalsTest - Test class for the Queueable_CalculateOppMRRTotals class
*/
@isTest
public with sharing class Queueable_CalculateOppMRRTotalsTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', true, 2);    
        testProducts[0].Name = 'Rev Schedule Prod';
        testProducts[0].ProductCode = 'RSP1';   
        testProducts[0].RevenueScheduleType = 'Repeat';
        testProducts[0].RevenueInstallmentPeriod = 'Monthly';
        testProducts[0].NumberOfRevenueInstallments = 12;
        testProducts[0].CanUseRevenueSchedule = true;
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[0].Family = 'ActionGrid';
        testProducts[0].Product_Line__c = 'Conga Grid';
        testProducts[1].Name = 'Rev Schedule Prod';
        testProducts[1].ProductCode = 'RSP2';
        testProducts[1].RevenueScheduleType = 'Repeat';
        testProducts[1].RevenueInstallmentPeriod = 'Monthly';
        testProducts[1].NumberOfRevenueInstallments = 12;
        testProducts[1].CanUseRevenueSchedule = true;
        testProducts[1].FY16_Revenue_Type__c = 'Recurring';    
        testProducts[1].Family = 'Conga Composer Licenses';
        testProducts[1].Product_Line__c = 'Conga Composer';        
        insert testProducts;

        // TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', true, 2);
        testPricebookEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[0].Product2Id = testProducts[0].Id;
        testPricebookEntries[0].IsActive = TRUE;
        testPricebookEntries[0].UnitPrice = 200.00;
        testPricebookEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[1].Product2Id = testProducts[1].Id;
        testPricebookEntries[1].IsActive = TRUE;
        testPricebookEntries[1].UnitPrice = 500.00;
        insert testPricebookEntries;
    }

    /**
    * @description testQueueableExecute - Test method for the Queueable_CalculateOppMRRTotals.execute method
    */
    public static testmethod void testQueueableExecute(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(!testPricebookEntries.isEmpty() && testPricebookEntries.size() == 2);

        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';  
        testAccounts[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
        testAccounts[0].mrr_Active_MRR__c = 100.00;                     
        insert testAccounts;

        Test.startTest();

        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', true, 1);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].Type = 'Existing Business';
        testOpportunities[0].CloseDate = Date.today();
        insert testOpportunities;

        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 2);
        testOppItems[0].OpportunityId = testOpportunities[0].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[0].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[0].Product_End_Date__c = Date.newInstance(2018, 12, 31);
        testOppItems[1].OpportunityId = testOpportunities[0].Id;
        testOppItems[1].Quantity = 5;
        testOppItems[1].UnitPrice = 500;
        testOppItems[1].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[1].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[1].Product_End_Date__c = Date.newInstance(2019, 12, 30);
        insert testOppItems;

        // CONSTRUCT NEW QUEUEABLE, CONSTRUCTOR WILL ENQUEUE
        System.enqueueJob(new Queueable_CalculateOppMRRTotals(new Set<Id>{ testOpportunities[0].Id }));

        Test.stopTest();

        testOpportunities = [SELECT Id, Net_New_MRR__c, Net_New_MRR_Number__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].Net_New_MRR__c == testOpportunities[0].Net_New_MRR_Number__c);
    }


}