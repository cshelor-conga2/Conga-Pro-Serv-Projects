/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @description PYMTPaymentXHelperTest- Test class for the PYMTPaymentXHelper class
*/
@isTest
public with sharing class PYMTPaymentXHelperTest{

    /**
    * @description setup - Create test data
    */
    @testSetup
    public static void setup() {
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;

        Product2 testProduct = (Product2)TestingUtility.createSObject('Product2', false, 1);
        testProduct.Name = 'prod1';
        testProduct.ProductCode = 'prod1';          
        testProduct.LOB__c = 'Services';
        testProduct.FY16_Revenue_Type__c = 'Non-Recurring';
        insert testProduct;

        PricebookEntry testPBEntry = (PricebookEntry)TestingUtility.createSObject('PricebookEntry', false, 1);
        testPBEntry.Pricebook2Id = Test.getStandardPricebookId();
        testPBEntry.Product2Id = testProduct.Id;
        testPBEntry.IsActive = TRUE;
        testPBEntry.UnitPrice = 5.00;
        insert testPBEntry;

        SBQQ__Quote__c testQuote = (SBQQ__Quote__c)TestingUtility.createSObject('SBQQ__Quote__c', false, 1);
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;

        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'Test Opp';
        testOpp.StageName = 'Qualify';
        testOpp.CloseDate = System.today();
        testOpp.AccountId = a.Id;
        testOpp.SBQQ__PrimaryQuote__c = testQuote.Id;
        insert testOpp;

        testQuote.SBQQ__Opportunity2__c = testOpp.Id;
        update testQuote;

        OpportunityLineItem testItem = (OpportunityLineItem)TestingUtility.createSObject('OpportunityLineItem', false, 1);
        testItem.OpportunityId = testOpp.Id;
        testItem.Quantity = 3;
        testItem.UnitPrice = 200;
        testItem.PricebookEntryId = testPBEntry.Id;
        testItem.ServiceDate = Date.today();
        insert testItem;

        testOpp.StageName = 'Closed Won';
        update testOpp;
    }

    /**
    * @description testMethod1 - Test Happy Path of code
    */
    public static testMethod void testMethod1() {
        Id invoiceRt = null;
        for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Order']){
            if(rt.DeveloperName == 'Invoice'){
                invoiceRt = rt.Id;
            }
        }

        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 1);

        // GET TEST OPP
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity];
        System.assert(testOpps.size() == 1);

        // GET TEST ORDER
        //List<Order> testOrders = [SELECT Id FROM Order];
        //System.assert(testOrders.size() == 1);

        Order ord = new Order();
        ord.EffectiveDate = System.today();
        ord.AccountId = testAccounts[0].Id;
        ord.Status = 'Draft';
        ord.OpportunityId = testOpps[0].Id;
        ord.RecordTypeId = invoiceRt;
        insert ord;

        Test.startTest();

        pymt__PaymentX__c pmt = new pymt__PaymentX__c();
        pmt.pymt__Opportunity__c = testOpps[0].Id;
        pmt.pymt__Amount__c = 10000;
        pmt.pymt__Date__c = System.today();
        pmt.pymt__Payment_Type__c = 'Credit Card';
        pmt.pymt__Card_Type__c = 'Amex';
        insert pmt;

        pymt__PaymentX__c pmt2 = new pymt__PaymentX__c();
        pmt2.pymt__Opportunity__c = testOpps[0].Id;
        pmt2.Order__c = ord.Id;
        pmt2.pymt__Amount__c = 5000;
        pmt2.pymt__Date__c = System.today();
        pmt2.pymt__Payment_Type__c = 'Credit Card';
        pmt2.pymt__Card_Type__c = 'Amex';
        insert pmt2;

        pmt.pymt__Status__c = 'Completed';
        pmt2.pymt__Status__c = 'Completed';
        update new List<pymt__PaymentX__c>{ pmt, pmt2 };

        List<Order_Payment__c> payments = [SELECT Id, InvoiceId__c FROM Order_Payment__c];
        System.assert(payments.size() == 2);
        System.assert(payments[0].InvoiceId__c == ord.Id);
        System.assert(payments[1].InvoiceId__c == ord.Id);

        Test.stopTest();
    }


}