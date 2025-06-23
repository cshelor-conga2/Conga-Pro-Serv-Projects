/**
* @author Conga Services, ERedding
* @date 20190605
* @version 1.00
* @description BatchableSch_DelinquentSalesInvoicesTest - Test class for the BatchableSch_DelinquentSalesInvoices schedulable batch class
*/
@isTest
public with sharing class BatchableSch_DelinquentSalesInvoicesTest {
    
    /**
    * @description setup - Setup test data
    */
    @testSetup
    public static void setup() {
        // CREATE TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account', false);
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].Name = 'Normal Opp';
        testOpportunities[0].AccountId = testAccount.Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[1].Name = 'Normal Opp 2';
        testOpportunities[1].AccountId = testAccount.Id;
        testOpportunities[1].StageName = 'Qualify';
        testOpportunities[1].CloseDate = Date.today();
        insert testOpportunities;

        // TEST CONTRACT
        List<Contract> testContract = (List<Contract>)TestingUtility.createSObjectList('Contract', false, 2);
        testContract[0].AccountId = testAccount.Id;
        testContract[0].Status = 'Draft';
        testContract[0].StartDate = Date.today().addDays(30);
        testContract[0].ContractTerm = 12;
        testContract[0].SBQQ__Opportunity__c = testOpportunities[0].Id;
        testContract[1].AccountId = testAccount.Id;
        testContract[1].Status = 'Draft';
        testContract[1].StartDate = Date.today().addDays(30);
        testContract[1].ContractTerm = 12;
        testContract[1].SBQQ__Opportunity__c = testOpportunities[1].Id;
        insert testContract;

        // CREATE TEST ORDERS
        List<ia_crm__Sales_Invoice__c> testSalesInvoices = TestingUtility.createSObjectList('ia_crm__Sales_Invoice__c', false, 2);
        testSalesInvoices[0].ia_crm__Account__c = testAccount.Id;
        testSalesInvoices[0].ia_crm__Opportunity__c = testOpportunities[0].Id;
        testSalesInvoices[0].ia_crm__Contract__c = testContract[0].Id;
        testSalesInvoices[0].ia_crm__Amount_Due__c = 500;
        testSalesInvoices[0].ia_crm__Ship_Date__c = Date.today().addDays(-33);
        testSalesInvoices[0].Sales_Invoice_Delinquent__c = false;
        testSalesInvoices[1].ia_crm__Account__c = testAccount.Id;
        testSalesInvoices[1].ia_crm__Opportunity__c = testOpportunities[1].Id;
        testSalesInvoices[1].ia_crm__Contract__c = testContract[1].Id;
        testSalesInvoices[1].ia_crm__Amount_Due__c = 0;
        testSalesInvoices[1].ia_crm__Ship_Date__c = Date.today().addDays(-60);
        testSalesInvoices[1].Sales_Invoice_Delinquent__c = true;
        insert testSalesInvoices;
    }

    /**
    * @description delinquentSalesInvoices_Test - Test schedulable with delinquent orders to flag and unflag
    */
    public static testMethod void delinquentSalesInvoices_Test(){
        // GET TEST ORDERS
        List<ia_crm__Sales_Invoice__c> testSalesInvoices = [SELECT Id FROM ia_crm__Sales_Invoice__c];
        System.assert(testSalesInvoices.size() == 2);

        // SCHEDULE CODE AND STOP TEST TO EXECUTE
        Test.startTest();
        System.schedule('MarkSalesInvoicesDelinquent', '0 0 0 1 1 ? 2025', new BatchableSch_DelinquentSalesInvoices());
        Database.executeBatch(new BatchableSch_DelinquentSalesInvoices());
        Test.stopTest();

        List<ia_crm__Sales_Invoice__c> delinquentOrders = [SELECT Id, Sales_Invoice_Delinquent__c FROM ia_crm__Sales_Invoice__c];
        System.assert(delinquentOrders.size() == 2);
        System.assert(delinquentOrders[0].Sales_Invoice_Delinquent__c == true);
        System.assert(delinquentOrders[1].Sales_Invoice_Delinquent__c == false);
    }


}