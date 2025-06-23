@isTest
public with sharing class COAExceptionPageControllerTest {
    /*
     * author: Redpoint
     * date: 9/15/2017
     * purpose: unit test for the COA Exception Page Controller
     * note:
    */
    
    public static COAExceptionPageController cep;
    public static COA_Exception__c exRecord;
    public static Opportunity opp;
    public static Opportunity opp2;
    public static Account acct;
    
    public static void setup() {
    
        AVA_SFCORE__TaxNowSetting__c testTaxSetting = new AVA_SFCORE__TaxNowSetting__c(
            Name = 'AvaTax',
            AVA_SFCORE__Active_Setting__c = TRUE,
            AVA_SFCORE__TriggerLimit__c = 1,
            AVA_SFCORE__Service_URL__c = 'https://development.avalara.net/',
            AVA_SFCORE__Origin_Street__c = '385 Interlocken Crescent Suite 600',
            AVA_SFCORE__Origin_City__c = 'Broomfield',
            AVA_SFCORE__Origin_State__c = 'CO',
            AVA_SFCORE__Origin_Postal_Code__c = '80021',
            AVA_SFCORE__Origin_Country__c = 'US',
            AVA_SFCORE__Enable_Tax_Calculation__c = FALSE, 
            AVA_SFCORE__Enable_Address_Validation__c = FALSE,
            AVA_SFCORE__Automatic_Tax_Calculation__c = FALSE
            );

        insert testTaxSetting;

        acct = TestClassFactory.createAccount('Test Account');
        acct.BillingStreet = '123 Main';
        acct.BillingCity = 'Albuquerque';
        acct.BillingCountry = 'USA';
        acct.BillingPostalCode = '87103';
        insert acct;
        
        opp = TestClassFactory.createOpportunity('Test Opportunity', 'Prospecting', 'Prospecting',  Date.TODAY().addDays(30));
        opp.AccountId = acct.Id;
        opp.Customer_Org_Id__c = '00D123456789ABC';
        insert opp;

        opp2 = TestClassFactory.createOpportunity('Test Opportunity 2', 'Prospecting', 'Prospecting',  Date.TODAY().addDays(30));
        opp2.AccountId = acct.Id;
        opp2.Customer_Org_Id__c = '00D987654321ABC';
        insert opp2;
        
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = TestClassFactory.createProduct('TEST PRODUCT 1', 'TP1');
        prod.RevenueScheduleType = 'Repeat';
        prod.RevenueInstallmentPeriod = 'Monthly';
        prod.NumberOfRevenueInstallments = 12;
        prod.CanUseRevenueSchedule = true;
        insert prod;
        
        PricebookEntry entry = TestClassFactory.createPricebookEntry(prod.Id, pricebookId, 200);
        insert entry;
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        
        
        for(Integer i = 0; i < 5; i++){
            OpportunityLineItem oli = TestClassFactory.createLineItem(5, 200.00, Date.TODAY().addDays(30).toStartOfMonth(), entry.Id, opp.Id);
            if(i == 0)
                oli.Service_Date_Override__c = oli.ServiceDate.addMonths(6);
            if(i == 1)
                oli.Service_Date_Override__c = oli.ServiceDate.addMonths(24);
            if(i == 2)
                oli.UnitPrice = 150;
            olis.add(oli);
        }
        
        insert olis;


        exRecord = new COA_Exception__c();
        exRecord.Related_Opportunity__c = opp.Id;
        exRecord.Segmented_Deal__c = true;
        insert exRecord;
        
        cep = new COAExceptionPageController();
    }
    
    static testMethod void testConstructor() {
        setup();
   
        System.assertEquals(1, cep.exceptions.size());
    }
    
    static testMethod void testResubmitOpportunity() {
        setup();
        
        cep.record = exRecord.Id;
        cep.resubmitOpportunity();

        List<ApexPages.Message> msgs = ApexPages.getMessages();
        Boolean b = False;

        for(ApexPages.Message msg : msgs) {
            if(msg.getDetail().contains('Opportunity did not re-submit successfully.')) {
                b = true;
            }
        }
        System.assert(b);
    }
    
    static Testmethod void testResubmitOpportunitySuccess() {
        setup();

        Opportunity oppy = [
                            SELECT Id, Account.Id, Account.Name, Customer_Org_Id__c, Account.BillingStreet, 
                                Account.BillingCity, Account.BillingCountry, Account.BillingState, Account.BillingPostalCode 
                            FROM Opportunity 
                            WHERE Id =: opp.Id];

        CHANNEL_ORDERS__Customer__c customer = new CHANNEL_ORDERS__Customer__c();
        customer.CHANNEL_ORDERS__Account__c = oppy.Account.Id;
        customer.CHANNEL_ORDERS__Customer_Company_Name__c = oppy.Account.Name;
        customer.CHANNEL_ORDERS__Customer_Org_ID__c = oppy.Customer_Org_Id__c;
        customer.CHANNEL_ORDERS__Customer_Street__c = oppy.Account.BillingStreet;
        customer.CHANNEL_ORDERS__Customer_State__c = oppy.Account.BillingState;
        customer.CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = oppy.Account.BillingPostalCode;
        customer.CHANNEL_ORDERS__Customer_City__c = oppy.Account.BillingCity;
        customer.CHANNEL_ORDERS__Customer_Country__c = oppy.Account.BillingCountry;
        insert customer;
        
        CHANNEL_ORDERS__Partner_Contract_Terms__c terms = new CHANNEL_ORDERS__Partner_Contract_Terms__c();
        terms.Name = 'Test Terms 1';
        terms.CHANNEL_ORDERS__Partner_API_Key__c = '123';
        insert terms;

        CHANNEL_ORDERS__Service_Order__c serviceOrder = new CHANNEL_ORDERS__Service_Order__c();
        serviceOrder.CHANNEL_ORDERS__Customer__c = customer.Id;
        serviceOrder.CHANNEL_ORDERS__Customer_Org_ID__c = customer.CHANNEL_ORDERS__Customer_Org_ID__c;
        serviceOrder.CHANNEL_ORDERS__Service_Order_Status__c = 'Draft';
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_City__c = oppy.Account.BillingCity;
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_Country__c = oppy.Account.BillingCountry;
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_Street__c = oppy.Account.BillingStreet;
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_Zip_Postal_Code__c = oppy.Account.BillingPostalCode;
        serviceOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c = terms.Id;
        serviceOrder.CHANNEL_ORDERS__Customer_Name__c = oppy.Account.Name;
        serviceOrder.CHANNEL_ORDERS__Related_Opportunity__c = oppy.Id;
        serviceOrder.CHANNEL_ORDERS__Order_Type__c = 'Initial';
        insert serviceOrder;

        cep.record = exRecord.Id;
        cep.resubmitOpportunity();

        List<ApexPages.Message> msgs = ApexPages.getMessages();
        Boolean b = False;

        for(ApexPages.Message msg : msgs) {
            if(msg.getDetail().contains('New Service Order created.')) {
                b = true;
            }
        }
        System.assert(b);
    }

    static Testmethod void testPagination() {
        setup();

        List<COA_Exception__c> exceptionList = new List<COA_Exception__c>();
        Integer i = 0;

        for(i = 0; i < 100; i++) {
            COA_Exception__c temp = new COA_Exception__c();
            temp.Related_Opportunity__c = opp.Id;
            exceptionList.add(temp);
        }

        insert exceptionList;

        COAExceptionPageController ctrl = new COAExceptionPageController();

        ctrl.first();
        System.assertEquals(0, ctrl.offSetSize);
        System.assertEquals(25, ctrl.exceptions.size());

        ctrl.next();
        System.assertEquals(25, ctrl.offSetSize);

        ctrl.previous();
        System.assertEquals(0, ctrl.offSetSize);

        ctrl.last();
        System.assertEquals(100,ctrl.offSetSize);

        System.assert(!ctrl.getprev());

        System.assert(ctrl.getnxt());

        System.assertEquals(101, ctrl.getTotalRecords());
    }

    static Testmethod void testSorting() {
        setup();

        String test1 = cep.getSortDirection();
        System.assertEquals('ASC', test1);

        cep.setSortDirection('DESC');
        System.assertEquals('DESC', cep.SortDirection);

        cep.SortExpression = 'Customer_Org_Id__c';
        String test2 = cep.SortExpression;
        System.assertEquals('Customer_Org_Id__c', test2);

        cep.sortExpression = 'Customer_Org_Id__c';
        String test3 = cep.sortDirection;
        System.assertEquals('DESC', test3);


        COA_Exception__c ex2 = new COA_Exception__c();
        ex2.Related_Opportunity__c = opp2.Id;
        ex2.Segmented_Deal__c = true;
        insert ex2;

        List<COA_Exception__c> testList = [
                                            SELECT Id, Customer_Org_Id__c
                                            FROM COA_Exception__c 
                                            WHERE COA_Entered__c = False 
                                            ORDER BY Customer_Org_Id__c ASC];

        cep.sortDirection = 'ASC';
        cep.sortByColumn();

        System.assertEquals(testList.get(0).Customer_Org_Id__c, cep.exceptions.get(0).Customer_Org_Id__c);
    }
}