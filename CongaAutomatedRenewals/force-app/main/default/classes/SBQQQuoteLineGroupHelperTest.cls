/**
* @author Conga Services, ERedding
* @date 20181206
* @version 1.00
* @description SBQQQuoteLineGroupHelperTest  - Test class for the SBQQQuoteLineGroupHelper class
*/
@isTest
public with sharing class SBQQQuoteLineGroupHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        //// TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', true, 2);    
        testProducts[0].Name = 'Rev Schedule Prod';
        testProducts[0].ProductCode = 'RSP1';   
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[1].Name = 'Rev Schedule Prod 2';
        testProducts[1].ProductCode = 'RSP2';
        insert testProducts;

        //// TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', true, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[0].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        insert testQuotes;

        //// TEST QUOTE LINE GROUP
        List<SBQQ__QuoteLineGroup__c> testQuoteLineGroup = TestingUtility.createSObjectList('SBQQ__QuoteLineGroup__c', true, 1);
        testQuoteLineGroup[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLineGroup[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuoteLineGroup[0].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        insert testQuoteLineGroup;

        // TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', true, 2);
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Group__c = testQuoteLineGroup[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 75;
        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__Group__c = testQuoteLineGroup[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__Quantity__c = 15;
        insert testQuoteLines;
    }

    /*
    * @description updateQuoteLineOppItemDatesTest - Test updateQuoteLineOppItemDates trigger method
    */
    public static testMethod void updateQuoteLineOppItemDatesTest(){
        // GET TEST GROUP
        List<SBQQ__QuoteLineGroup__c> testQuoteLineGroup = [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c];
        System.assert(testQuoteLineGroup.size() == 1);

        Test.startTest();

        // MAKE QUALIFYING GROUP CHANGES
        testQuoteLineGroup[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 15);
        testQuoteLineGroup[0].SBQQ__EndDate__c = Date.newInstance(2020, 1, 14);
        update testQuoteLineGroup;

        // GET TEST QUOTE LINES AND TEST FOR CORRECT DATA
        List<SBQQ__QuoteLine__c> testQuoteLines = [SELECT Id, Opp_Item_Start_Date__c, Opp_Item_End_Date__c FROM SBQQ__QuoteLine__c];
        System.assert(testQuoteLines.size() == 2);
        System.assert(testQuoteLines[0].Opp_Item_Start_Date__c == testQuoteLineGroup[0].SBQQ__StartDate__c);
        System.assert(testQuoteLines[0].Opp_Item_End_Date__c == testQuoteLineGroup[0].SBQQ__EndDate__c);
        System.assert(testQuoteLines[1].Opp_Item_Start_Date__c == testQuoteLineGroup[0].SBQQ__StartDate__c);
        System.assert(testQuoteLines[1].Opp_Item_End_Date__c == null);

        // MAKE QUALIFYING GROUP CHANGES
        testQuoteLineGroup[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 15);
        testQuoteLineGroup[0].SBQQ__EndDate__c = null;
        testQuoteLineGroup[0].SBQQ__SubscriptionTerm__c = 36;
        update testQuoteLineGroup;

        // GET TEST QUOTE LINES AND TEST FOR CORRECT DATA
        testQuoteLines = [SELECT Id, Opp_Item_Start_Date__c, Opp_Item_End_Date__c, Has_Leap_Year_Day__c FROM SBQQ__QuoteLine__c];
        System.assert(testQuoteLines.size() == 2);
        System.assert(testQuoteLines[0].Opp_Item_Start_Date__c == testQuoteLineGroup[0].SBQQ__StartDate__c);
        System.assert(testQuoteLines[0].Opp_Item_End_Date__c == testQuoteLineGroup[0].SBQQ__StartDate__c.addMonths((Integer)testQuoteLineGroup[0].SBQQ__SubscriptionTerm__c));
        System.assert(testQuoteLines[0].Has_Leap_Year_Day__c == true);
        System.assert(testQuoteLines[1].Opp_Item_Start_Date__c == testQuoteLineGroup[0].SBQQ__StartDate__c);
        System.assert(testQuoteLines[1].Opp_Item_End_Date__c == null);

        Test.stopTest();
    }


}