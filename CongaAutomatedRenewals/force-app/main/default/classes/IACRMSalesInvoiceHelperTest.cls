/**
* @author ECS, ERedding
* @date 20190925
* @version 1.00
* @description IACRMSalesInvoiceHelperTest - Test class for the IACRMSalesInvoiceHelper class
*/
@isTest
public with sharing class IACRMSalesInvoiceHelperTest {

    /**
    * @description stampInvoiceWithPeriodTest - Test IACRMSalesInvoiceHelper.stampInvoiceWithPeriod trigger method
    */
    public static testMethod void stampInvoiceWithPeriodTest(){
        // CREATE TEST INVOICES
        List<ia_crm__Sales_Invoice__c> testInvoices = TestingUtility.createSObjectList('ia_crm__Sales_Invoice__c', false, 3);
		testInvoices[0].ia_crm__Date__c = Date.newInstance(2019, 9, 16);
        testInvoices[0].ia_crm__Document_Type__c = 'Sales Invoice';
		testInvoices[1].ia_crm__Date__c = Date.newInstance(2019, 9, 20);
        testInvoices[1].ia_crm__Document_Type__c = 'Sales Invoice';
        testInvoices[2].ia_crm__Date__c = Date.newInstance(2019, 9, 25);
        testInvoices[2].ia_crm__Document_Type__c = 'Contract Invoice';  
		insert testInvoices;

        Test.startTest();

        testInvoices = [SELECT Id, ia_crm__Date__c, Period__c FROM ia_crm__Sales_Invoice__c WHERE Id IN :testInvoices];
        System.assert(testInvoices[0].Period__c == '8 September 2019 - 14 September 2019');
        System.assert(testInvoices[1].Period__c == '8 September 2019 - 14 September 2019');
        System.assert(String.isBlank(testInvoices[2].Period__c));

        // UPDATE DATES AND RETEST
		testInvoices[0].ia_crm__Date__c = Date.newInstance(2019, 9, 10);
		testInvoices[1].ia_crm__Date__c = Date.newInstance(2019, 10, 8); // PRIOR WEEK OCCURS IN TWO DIFFERENT MONTHS
        testInvoices[2].ia_crm__Date__c = Date.newInstance(2019, 9, 30);
		update testInvoices;

        testInvoices = [SELECT Id, ia_crm__Date__c, Period__c FROM ia_crm__Sales_Invoice__c WHERE Id IN :testInvoices];
        System.assert(testInvoices[0].Period__c == '1 September 2019 - 7 September 2019');
        System.assert(testInvoices[1].Period__c == '29 September 2019 - 5 October 2019');
        System.assert(String.isBlank(testInvoices[2].Period__c));

        Test.stopTest();
    }


}