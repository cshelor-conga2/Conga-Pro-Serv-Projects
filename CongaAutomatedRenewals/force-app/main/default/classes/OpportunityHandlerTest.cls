@isTest
private class OpportunityHandlerTest {

    @testSetup
    public static void setup() {
        // settings
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

        // OVERRIDE TRIGGER SETTINGS TO DISABLE THEM
        TriggerHelper.OverrideAllSettings(true, false);

        // TEST COUNTRY RECORDS 
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'AMER');
        insert unitedStates;

        // accounts
        Account a = TestClassFactory.createAccount('Test Account for New Orders');
        a.BillingStreet = '123 Main';
        a.BillingState = 'New Mexico';
        a.BillingPostalCode = '12345';
        a.BillingCity = 'Albuquerque';
        a.BillingCountry = 'USA';
        a.Salesforce_Account_Id__c = '00Dc0000003vxrV';

        Account a_missing = TestClassFactory.createAccount('Test Account Missing Info');
        a_missing.BillingStreet = '124 Main';
        a_missing.BillingState = 'New Mexico';
        insert new Account[] { a, a_missing };

        // pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        // products
        Product2 prod1 = TestClassFactory.createProduct('TEST PRODUCT 1', 'TP1');
        //prod1.RevenueScheduleType = 'Repeat';
        //prod1.RevenueInstallmentPeriod = 'Monthly';
        //prod1.NumberOfRevenueInstallments = 12;
        prod1.CanUseRevenueSchedule = true;

        Product2 prod2 = TestClassFactory.createProduct('TEST PRODUCT 2', 'TP2');
        //prod2.RevenueScheduleType = 'Repeat';
        //prod2.RevenueInstallmentPeriod = 'Monthly';
        //prod2.NumberOfRevenueInstallments = 12;
        prod2.CanUseRevenueSchedule = true;
        
        insert new Product2[] { prod1, prod2 };

        // partner contract terms
        CHANNEL_ORDERS__Partner_Contract_Terms__c pct1 = new CHANNEL_ORDERS__Partner_Contract_Terms__c(
            Name = 'Test Term 1',
            CHANNEL_ORDERS__Partner_API_Key__c = 'asasasaa',
            CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c = '123456abc');

        CHANNEL_ORDERS__Partner_Contract_Terms__c pct2 = new CHANNEL_ORDERS__Partner_Contract_Terms__c(
            Name = 'Test Term 2',
            CHANNEL_ORDERS__Partner_API_Key__c = 'wwwwiiii',
            CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c = 'abc123456');
        
        insert new CHANNEL_ORDERS__Partner_Contract_Terms__c[] { pct1, pct2 };

        // partner product catalogs
        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc1 = new CHANNEL_ORDERS__Partner_Product_Catalog__c(
            Name = 'Test catalog 1',
            CHANNEL_ORDERS__Partner_Contract_Terms__c = pct1.Id,
            CHANNEL_ORDERS__Product_ID__c = 'Conga Test',
            CHANNEL_ORDERS__Pricing_Type__c = 'NPR',
            CHANNEL_ORDERS__Partner_Application_Name__c = 'TEST');

        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc2 = new CHANNEL_ORDERS__Partner_Product_Catalog__c(
            Name = 'Test catalog 2',
            CHANNEL_ORDERS__Partner_Contract_Terms__c = pct2.Id,
            CHANNEL_ORDERS__Product_ID__c = 'Conga Test',
            CHANNEL_ORDERS__Pricing_Type__c = 'NPR',
            CHANNEL_ORDERS__Partner_Application_Name__c = 'TEST');
        
        insert new CHANNEL_ORDERS__Partner_Product_Catalog__c[] { ppc1, ppc2 };

        // pricebook entries
        PricebookEntry entry1 = TestClassFactory.createPricebookEntry(prod1.Id, pricebookId, 200);
        entry1.Partner_Product_Catalog__c = ppc1.Id;

        PricebookEntry entry2 = TestClassFactory.createPricebookEntry(prod2.Id, pricebookId, 200);
        entry2.Partner_Product_Catalog__c = ppc2.Id;

        insert new PricebookEntry[] { entry1, entry2 };

        // Opportunities
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        for(Integer i = 1; i <= 5; i++){
            Opportunity o = TestClassFactory.createOpportunity('Test Opportunity ' + i, 'Prospecting', 'Prospecting',  Date.today().addDays(30));
            o.AccountId = a.Id;
            oppsToInsert.add(o);
        }
        insert oppsToInsert;
        
        // opportunity line items
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for(Integer i = 0; i < 5; i++){
            OpportunityLineItem oli = TestClassFactory.createLineItem(5, 200.00, Date.TODAY().addDays(35).toStartOfMonth(), entry1.Id, oppsToInsert[i].Id);
            if(i == 0)
                oli.Service_Date_Override__c = oli.ServiceDate.addMonths(6);
            if(i == 1)
                oli.Service_Date_Override__c = oli.ServiceDate.addMonths(24);
            if(i == 2)
                oli.UnitPrice = 150;
            olis.add(oli);
        }
        insert olis;

        // coa settings
        CS_COA_Settings__c coaCustomSetting = new CS_COA_Settings__c();
        coaCustomSetting.Name = 'COA Setting';
        coaCustomSetting.Default_Sales_Order_Status__c = 'Draft';
        insert coaCustomSetting;
    }

    @isTest
    private static void testCreateNewOrdersForNewBusinessOpportunity() {
        PricebookEntry entry = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c  from PricebookEntry where Product2.Name = 'TEST PRODUCT 1'];

        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = true;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'New Business';
        opp.Trigger_COA_automation__c = true;

        Test.startTest();

        OpportunityLineItem oli = [select Id, Description, PricebookEntryId, OpportunityId, ServiceDate, UnitPrice, Quantity, Service_Date_Override__c from OpportunityLineItem where OpportunityId = :opp.Id limit 1];
        oli.Quantity = 20;
        oli.PricebookEntry = entry;
        update oli;
        update opp;

        Test.stopTest();

        List<CHANNEL_ORDERS__Service_Order__c> soTest = [SELECT Id, Name, CHANNEL_ORDERS__Related_Opportunity__r.Name, CHANNEL_ORDERS__Service_Order_Status__c FROM CHANNEL_ORDERS__Service_Order__c];
        System.assertEquals(1, soTest.size());

        List<CHANNEL_ORDERS__Service_Order_Detail__c> sodTest = [SELECT Id FROM CHANNEL_ORDERS__Service_Order_Detail__c];
        System.assertEquals(1, sodTest.size());
    }
    
    @isTest
    private static void testCreateNewOrdersForOpportunitiesRenewalAddOns() {
        Account a = [select Id, Name, BillingStreet, BillingState, BillingPostalCode, BillingCity from Account where Name = 'Test Account for New Orders' limit 1];

        CHANNEL_ORDERS__Customer__c customer = testClassFActory.createCustomer(a.Id, a.Name, '00Dc0000003vxrV', a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCity, 'US');
        insert customer;

        CHANNEL_ORDERS__Partner_Contract_Terms__c pct = [select Id, Name, CHANNEL_ORDERS__Partner_API_Key__c, CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c from CHANNEL_ORDERS__Partner_Contract_Terms__c where Name = 'Test Term 1'];

        CHANNEL_ORDERS__Service_Order__c so = testClassFactory.createServiceOrder(customer.Id, '00Dc0000003vxrV', 'Activated', a.BillingCity, 'US', a.BillingStreet, a.BillingState, a.BillingPostalCode);
        so.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        so.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct.Id;
        so.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        insert so;

        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc = [select Id, Name, CHANNEL_ORDERS__Partner_Contract_Terms__c, CHANNEL_ORDERS__Product_ID__c, CHANNEL_ORDERS__Pricing_Type__c, CHANNEL_ORDERS__Partner_Application_Name__c from CHANNEL_ORDERS__Partner_Product_Catalog__c where Name = 'Test catalog 1'];

        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = testClassFactory.createServiceOrderDetail(so.Id, ppc.Id, pct.Id, 5);
        insert soDetail;

        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'Renewal';
        opp.Trigger_COA_automation__c = true;

        PricebookEntry entry = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c  from PricebookEntry where Product2.Name = 'TEST PRODUCT 1'];


        Test.startTest();

        OpportunityLineItem oli = [select Id, Description, PricebookEntryId, OpportunityId, ServiceDate, UnitPrice, Quantity, Service_Date_Override__c from OpportunityLineItem where OpportunityId = :opp.Id limit 1];
        oli.Quantity = 20;
        oli.PricebookEntry = entry;
        update oli;
        update opp;

        Test.stopTest();

        List<CHANNEL_ORDERS__Service_Order__c> soTest = [SELECT Id, Name, CHANNEL_ORDERS__Related_Opportunity__r.Name, CHANNEL_ORDERS__Service_Order_Status__c FROM CHANNEL_ORDERS__Service_Order__c];
        System.assertEquals(2, soTest.size());

        List<CHANNEL_ORDERS__Service_Order_Detail__c> sodTest = [SELECT Id FROM CHANNEL_ORDERS__Service_Order_Detail__c];
        System.assertEquals(2, sodTest.size());
    }

    
    @isTest
    private static void testCreateNewOrdersForOpportunitiesRenewals() {
        Account a = [select Id, Name, BillingStreet, BillingState, BillingPostalCode, BillingCity from Account where Name = 'Test Account for New Orders' limit 1];

        CHANNEL_ORDERS__Customer__c customer = testClassFActory.createCustomer(a.Id, a.Name, '00Dc0000003vxrV', a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCity, 'US');
        insert customer;

        CHANNEL_ORDERS__Partner_Contract_Terms__c pct = [select Id, Name, CHANNEL_ORDERS__Partner_API_Key__c, CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c from CHANNEL_ORDERS__Partner_Contract_Terms__c where Name = 'Test Term 1'];

        CHANNEL_ORDERS__Service_Order__c so = testClassFactory.createServiceOrder(customer.Id, '00Dc0000003vxrV', 'Activated', a.BillingCity, 'US', a.BillingStreet, a.BillingState, a.BillingPostalCode);
        so.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        so.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct.Id;
        so.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        insert so;

        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc = [select Id, Name, CHANNEL_ORDERS__Partner_Contract_Terms__c, CHANNEL_ORDERS__Product_ID__c, CHANNEL_ORDERS__Pricing_Type__c, CHANNEL_ORDERS__Partner_Application_Name__c from CHANNEL_ORDERS__Partner_Product_Catalog__c where Name = 'Test catalog 1'];

        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = testClassFactory.createServiceOrderDetail(so.Id, ppc.Id, pct.Id, 5);
        insert soDetail;

        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'Renewal';
        opp.Trigger_COA_automation__c = true;

        PricebookEntry entry = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c  from PricebookEntry where Product2.Name = 'TEST PRODUCT 1'];


        Test.startTest();

        OpportunityLineItem oli = [select Id, Description, PricebookEntryId, OpportunityId, ServiceDate, UnitPrice, Quantity, Service_Date_Override__c from OpportunityLineItem where OpportunityId = :opp.Id limit 1];
        oli.Quantity = 20;
        oli.PricebookEntry = entry;
        update oli;
        update opp;

        Test.stopTest();

        List<CHANNEL_ORDERS__Service_Order__c> soTest = [SELECT Id, Name, CHANNEL_ORDERS__Related_Opportunity__r.Name, CHANNEL_ORDERS__Service_Order_Status__c FROM CHANNEL_ORDERS__Service_Order__c];
        System.assertEquals(2, soTest.size());

        List<CHANNEL_ORDERS__Service_Order_Detail__c> sodTest = [SELECT Id FROM CHANNEL_ORDERS__Service_Order_Detail__c];
        System.assertEquals(2, sodTest.size());
    }

    @isTest
    private static void testCreateNewOrdersForOpportunitiesReduction() {
        Account a = [select Id, Name, BillingStreet, BillingState, BillingPostalCode, BillingCity from Account where Name = 'Test Account for New Orders' limit 1];

        CHANNEL_ORDERS__Customer__c customer = testClassFActory.createCustomer(a.Id, a.Name, '00Dc0000003vxrV', a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCity, 'US');
        insert customer;

        CHANNEL_ORDERS__Partner_Contract_Terms__c pct = [select Id, Name, CHANNEL_ORDERS__Partner_API_Key__c, CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c from CHANNEL_ORDERS__Partner_Contract_Terms__c where Name = 'Test Term 1'];

        CHANNEL_ORDERS__Service_Order__c so = TestClassFactory.createServiceOrder(customer.Id, '00Dc0000003vxrV', 'Activated', a.BillingCity, 'US', a.BillingStreet, a.BillingState, a.BillingPostalCode);
        so.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        so.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct.Id;
        so.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        insert so;

        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc = [select Id, Name, CHANNEL_ORDERS__Partner_Contract_Terms__c, CHANNEL_ORDERS__Product_ID__c, CHANNEL_ORDERS__Pricing_Type__c, CHANNEL_ORDERS__Partner_Application_Name__c from CHANNEL_ORDERS__Partner_Product_Catalog__c where Name = 'Test catalog 1'];

        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = testClassFactory.createServiceOrderDetail(so.Id, ppc.Id, pct.Id, 5);
        insert soDetail;

        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'Renewal';
        opp.Trigger_COA_automation__c = true;

        PricebookEntry entry = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c from PricebookEntry where Product2.Name = 'TEST PRODUCT 1'];

        Test.startTest();

        OpportunityLineItem oli = [select Id, Description, PricebookEntryId, OpportunityId, ServiceDate, UnitPrice, Quantity, Service_Date_Override__c from OpportunityLineItem where OpportunityId = :opp.Id limit 1];
        oli.Quantity = 20;
        oli.PricebookEntry = entry;
        update oli;
        update opp;

        Test.stopTest();

        List<CHANNEL_ORDERS__Service_Order__c> soTest = [SELECT Id, Name, CHANNEL_ORDERS__Related_Opportunity__r.Name, CHANNEL_ORDERS__Service_Order_Status__c FROM CHANNEL_ORDERS__Service_Order__c];
        System.assertEquals(2, soTest.size());

        List<CHANNEL_ORDERS__Service_Order_Detail__c> sodTest = [SELECT Id FROM CHANNEL_ORDERS__Service_Order_Detail__c];
        System.assertEquals(2, sodTest.size());
    }

    @isTest
    private static void testCreateNewOrdersForOpportunitiesExistingBusiness() {
        Account a = [select Id, Name, BillingStreet, BillingState, BillingPostalCode, BillingCity from Account where Name = 'Test Account for New Orders' limit 1];

        CHANNEL_ORDERS__Customer__c customer = testClassFActory.createCustomer(a.Id, a.Name, '00Dc0000003vxrV', a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCity, 'US');
        insert customer;

        CHANNEL_ORDERS__Partner_Contract_Terms__c pct = [select Id, Name, CHANNEL_ORDERS__Partner_API_Key__c, CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c from CHANNEL_ORDERS__Partner_Contract_Terms__c where Name = 'Test Term 1'];

        CHANNEL_ORDERS__Service_Order__c so = testClassFactory.createServiceOrder(customer.Id, '00Dc0000003vxrV', 'Activated', a.BillingCity, 'US', a.BillingStreet, a.BillingState, a.BillingPostalCode);
        so.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        so.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct.Id;
        so.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        insert so;

        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc = [select Id, Name, CHANNEL_ORDERS__Partner_Contract_Terms__c, CHANNEL_ORDERS__Product_ID__c, CHANNEL_ORDERS__Pricing_Type__c, CHANNEL_ORDERS__Partner_Application_Name__c from CHANNEL_ORDERS__Partner_Product_Catalog__c where Name = 'Test catalog 1'];

        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = testClassFactory.createServiceOrderDetail(so.Id, ppc.Id, pct.Id, 5);
        insert soDetail;

        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'Existing Business';
        opp.Trigger_COA_automation__c = true;

        PricebookEntry entry = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c  from PricebookEntry where Product2.Name = 'TEST PRODUCT 1'];
        
        Test.startTest();

        OpportunityLineItem oli = [select Id, Description, PricebookEntryId, OpportunityId, ServiceDate, UnitPrice, Quantity, Service_Date_Override__c from OpportunityLineItem where OpportunityId = :opp.Id limit 1];
        oli.Quantity = 20;
        oli.PricebookEntry = entry;
        update oli;
        update opp;

        Test.stopTest();

        List<CHANNEL_ORDERS__Service_Order__c> soTest = [SELECT Id, Name, CHANNEL_ORDERS__Related_Opportunity__r.Name, CHANNEL_ORDERS__Service_Order_Status__c FROM CHANNEL_ORDERS__Service_Order__c];
        System.assertEquals(2, soTest.size());

        List<CHANNEL_ORDERS__Service_Order_Detail__c> sodTest = [SELECT Id FROM CHANNEL_ORDERS__Service_Order_Detail__c];
        System.assertEquals(2, sodTest.size());
    }

    @isTest
    private static void testCheckIfSegmentedOpportunity() {
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        PricebookEntry entry2 = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c  from PricebookEntry where Product2.Name = 'TEST PRODUCT 2'];

        OpportunityLineItem oli = TestClassFactory.createLineItem(40, 25.00, Date.Today(), entry2.Id, opp.Id);                                             
        insert oli;

        System.debug([SELECT Id, OpportunityId, ServiceDate FROM OpportunityLineItem WHERE OpportunityId = :opp.Id]);

        Test.startTest();

        //Update opportunity to fire trigger
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'New Business';
        opp.Trigger_COA_automation__c = true;
        update opp;

        System.debug(opp);

        Test.stopTest();

        System.debug([SELECT Id, Related_Opportunity__c, Status__c FROM COA_Exception__c]);

        List<COA_Exception__c> ex = [SELECT Id, Related_Opportunity__c, Status__c FROM COA_Exception__c WHERE Related_Opportunity__c =: opp.Id];
        System.assert(!ex.isEmpty());
        System.assertEquals('Segmented Deal', ex[0].Status__c);
    }

    @isTest
    private static void testCreateMultipleOrders(){
        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'New Business';
        opp.Trigger_COA_automation__c = true;

        PricebookEntry[] entries = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c from PricebookEntry where Product2.Name like 'TEST PRODUCT%' order by Product2.Name];
        PricebookEntry entry1 = entries[0];
        PricebookEntry entry2 = entries[1];

        OpportunityLineItem oli = [select Id, Description, PricebookEntryId, OpportunityId, ServiceDate, UnitPrice, Quantity, Service_Date_Override__c from OpportunityLineItem where OpportunityId = :opp.Id limit 1];
        oli.Quantity = 20;
        oli.ServiceDate = Date.Today();
        oli.PricebookEntry = entry1;
        update oli;

        Test.startTest();

        OpportunityLineItem oli2 = TestClassFactory.createLineItem(40, 25.00, Date.Today(), entry2.Id, opp.Id);
        insert oli2;
        update opp;

        Test.stopTest();

        List<CHANNEL_ORDERS__Service_Order__c> soTest = [SELECT Id, Name, CHANNEL_ORDERS__Related_Opportunity__r.Name, CHANNEL_ORDERS__Order_Type__c, CHANNEL_ORDERS__Service_Order_Status__c FROM CHANNEL_ORDERS__Service_Order__c];
        System.assertEquals(2, soTest.size());
        System.debug(soTest[0].CHANNEL_ORDERS__Order_Type__c);
        System.debug(soTest[1].CHANNEL_ORDERS__Order_Type__c);
    }

    @isTest
    private static void testCreateMultipleOrdersExistingBusiness(){
        Account a = [select Id, Name, BillingStreet, BillingState, BillingPostalCode, BillingCity from Account where Name = 'Test Account for New Orders' limit 1];

        CHANNEL_ORDERS__Customer__c customer = testClassFActory.createCustomer(a.Id, a.Name, '00Dc0000003vxrV', a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCity, 'US');
        insert customer;

        CHANNEL_ORDERS__Partner_Contract_Terms__c[] pcts = [select Id, Name, CHANNEL_ORDERS__Partner_API_Key__c, CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c from CHANNEL_ORDERS__Partner_Contract_Terms__c order by Name];
        CHANNEL_ORDERS__Partner_Contract_Terms__c pct1 = pcts[0];
        CHANNEL_ORDERS__Partner_Contract_Terms__c pct2 = pcts[1];

        List<CHANNEL_ORDERS__Service_Order__c> insertSOs = new List<CHANNEL_ORDERS__Service_Order__c>();
        CHANNEL_ORDERS__Service_Order__c so = testClassFactory.createServiceOrder(customer.Id, '00Dc0000003vxrV', 'Activated', a.BillingCity, 'US', a.BillingStreet, a.BillingState, a.BillingPostalCode);
        so.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        so.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct1.Id;
        so.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        insertSOs.add(so);

        CHANNEL_ORDERS__Service_Order__c so2 = testClassFactory.createServiceOrder(customer.Id, '00Dc0000003vxrV', 'Activated', a.BillingCity, 'US', a.BillingStreet, a.BillingState, a.BillingPostalCode);
        so2.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        so2.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct2.Id;
        so2.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        insertSOs.add(so2);

        insert insertSOs;

        CHANNEL_ORDERS__Partner_Product_Catalog__c[] ppcs = [select Id, Name, CHANNEL_ORDERS__Partner_Contract_Terms__c, CHANNEL_ORDERS__Product_ID__c, CHANNEL_ORDERS__Pricing_Type__c, CHANNEL_ORDERS__Partner_Application_Name__c from CHANNEL_ORDERS__Partner_Product_Catalog__c order by Name];
        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc1 = ppcs[0];
        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc2 = ppcs[1];

        List<CHANNEL_ORDERS__Service_Order_Detail__c> insertDetail = new List<CHANNEL_ORDERS__Service_Order_Detail__c>();
        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = testClassFactory.createServiceOrderDetail(so.Id, ppc1.Id, pct1.Id, 5);
        insertDetail.add(soDetail);

        CHANNEL_ORDERS__Service_Order_Detail__c soDetail2 = testClassFactory.createServiceOrderDetail(so2.Id, ppc2.Id, pct2.Id, 5);
        insertDetail.add(soDetail2);

        insert insertDetail;

        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'Existing Business';
        opp.Trigger_COA_automation__c = true;

        OpportunityLineItem oli = [select Id, Description, PricebookEntryId, OpportunityId, ServiceDate, UnitPrice, Quantity, Service_Date_Override__c from OpportunityLineItem where OpportunityId = :opp.Id limit 1];
        oli.Quantity = 20;
        oli.ServiceDate = Date.today();
        update oli;

        PricebookEntry entry2 = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c  from PricebookEntry where Product2.Name = 'TEST PRODUCT 2'];

        Test.startTest();

        OpportunityLineItem oli2 = TestClassFactory.createLineItem(40, 25.00, Date.Today(), entry2.Id, opp.Id);
        insert oli2;
        update opp;

        Test.stopTest();

        List<CHANNEL_ORDERS__Service_Order__c> soTest = [SELECT Id, Name, CHANNEL_ORDERS__Related_Opportunity__r.Name, CHANNEL_ORDERS__Service_Order_Status__c FROM CHANNEL_ORDERS__Service_Order__c];
        System.assertEquals(4, soTest.size());
    }

    @isTest
    private static void testCreateMultipleOrdersRenewalAddOn(){
        Account a = [select Id, Name, BillingStreet, BillingState, BillingPostalCode, BillingCity from Account where Name = 'Test Account for New Orders' limit 1];

        CHANNEL_ORDERS__Customer__c customer = testClassFActory.createCustomer(a.Id, a.Name, '00Dc0000003vxrV', a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCity, 'US');
        insert customer;

        CHANNEL_ORDERS__Partner_Contract_Terms__c[] pcts = [select Id, Name, CHANNEL_ORDERS__Partner_API_Key__c, CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c from CHANNEL_ORDERS__Partner_Contract_Terms__c order by Name];
        CHANNEL_ORDERS__Partner_Contract_Terms__c pct1 = pcts[0];
        CHANNEL_ORDERS__Partner_Contract_Terms__c pct2 = pcts[1];

        List<CHANNEL_ORDERS__Service_Order__c> insertSOs = new List<CHANNEL_ORDERS__Service_Order__c>();
        CHANNEL_ORDERS__Service_Order__c so = testClassFactory.createServiceOrder(customer.Id, '00Dc0000003vxrV', 'Activated', a.BillingCity, 'US', a.BillingStreet, a.BillingState, a.BillingPostalCode);
        so.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        so.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct1.Id;
        so.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        insertSOs.add(so);

        CHANNEL_ORDERS__Service_Order__c so2 = testClassFactory.createServiceOrder(customer.Id, '00Dc0000003vxrV', 'Activated', a.BillingCity, 'US', a.BillingStreet, a.BillingState, a.BillingPostalCode);
        so2.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        so2.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct2.Id;
        so2.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        insertSOs.add(so2);
        insert insertSOs;

        CHANNEL_ORDERS__Partner_Product_Catalog__c[] ppcs = [select Id, Name, CHANNEL_ORDERS__Partner_Contract_Terms__c, CHANNEL_ORDERS__Product_ID__c, CHANNEL_ORDERS__Pricing_Type__c, CHANNEL_ORDERS__Partner_Application_Name__c from CHANNEL_ORDERS__Partner_Product_Catalog__c order by Name];
        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc1 = ppcs[0];
        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc2 = ppcs[1];

        List<CHANNEL_ORDERS__Service_Order_Detail__c> insertDetail = new List<CHANNEL_ORDERS__Service_Order_Detail__c>();
        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = testClassFactory.createServiceOrderDetail(so.Id, ppc1.Id, pct1.Id, 5);
        insertDetail.add(soDetail);

        CHANNEL_ORDERS__Service_Order_Detail__c soDetail2 = testClassFactory.createServiceOrderDetail(so2.Id, ppc2.Id, pct2.Id, 5);
        insertDetail.add(soDetail2);
        insert insertDetail;

        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'Renewal';
        opp.Trigger_COA_automation__c = true;

        OpportunityLineItem oli = [select Id, Description, PricebookEntryId, OpportunityId, ServiceDate, UnitPrice, Quantity, Service_Date_Override__c from OpportunityLineItem where OpportunityId = :opp.Id limit 1];
        oli.Quantity = 20;
        oli.ServiceDate = Date.today();
        update oli;

        PricebookEntry entry2 = [select Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, Partner_Product_Catalog__c  from PricebookEntry where Product2.Name = 'TEST PRODUCT 2'];

        Test.startTest();

        OpportunityLineItem oli2 = TestClassFactory.createLineItem(40, 25.00, Date.Today(), entry2.Id, opp.Id);
        insert oli2;
        update opp;

        Test.stopTest();

        List<CHANNEL_ORDERS__Service_Order__c> soTest = [SELECT Id, Name, CHANNEL_ORDERS__Related_Opportunity__r.Name, CHANNEL_ORDERS__Service_Order_Status__c FROM CHANNEL_ORDERS__Service_Order__c];
        System.assertEquals(4, soTest.size());
    }
    

    @isTest
    private static void testMissingAddressException() {
        Account a_missing = [select Id from Account where Name = 'Test Account Missing Info'];
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];

        Test.startTest();
        //TriggerHelper.OverideAllSettings(true, false);

        //Update opportunity to fire trigger
        opp.AccountId = a_missing.Id;
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = True;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'New Business';
        opp.Trigger_COA_automation__c = true;
        update opp;

        Test.stopTest();

        List<COA_Exception__c> ex = [SELECT Id, Related_Opportunity__c, Status__c FROM COA_Exception__c WHERE Related_Opportunity__c =: opp.Id];
        System.assert(!ex.isEmpty());
        System.assertEquals('Opportunity Missing Address', ex[0].Status__c);
    }

    /**
    * @description testBatchableSchOpportunityCOA_Batchable - Test the batchable portion of BatchableSch_OpportunityCOA
    */
    private static testMethod void testBatchableSchOpportunityCOA_Batchable() {
        TriggerHelper.TemporaryOverride('Opportunity','coaTriggerEntryPoint', false); // DISABLE TRIGGER SO BATCH JOB CAN FIND THE OPP

        //Update opportunity to fire trigger
        Opportunity opp = [select Id, Name, StageName, CloseDate, Sales_Ops_Status__c, AccountId from Opportunity where Name = 'Test Opportunity 1' limit 1];
        opp.StageName = 'Closed Won';
        opp.Sales_Ops_Approved__c = true;
        opp.Customer_Org_Id__c = '00Dc0000003vxrV';
        opp.Type = 'New Business';
        opp.Trigger_COA_automation__c = true;
        update opp;

        Test.startTest();

        BatchableSch_OpportunityCOA batchClass = new BatchableSch_OpportunityCOA();
        Database.executeBatch(batchClass, 1);

        Test.stopTest();
    }

    /**
    * @description testBatchableSchOpportunityCOA_Schedulable - Test the schedulable portion of BatchableSch_OpportunityCOA
    */
    public static testMethod void testBatchableSchOpportunityCOA_Schedulable() {
        Test.startTest();

        // TEST SCHEDULE BATCH CLASS FOR CODE COVERAGE
        BatchableSch_OpportunityCOA batchClass = new BatchableSch_OpportunityCOA();
        System.schedule('TestBatchableSch_OpportunityCOA', '0 0 0 1 1 ? 2025', batchClass);

        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType IN ('ScheduledApex') AND ApexClass.Name = 'BatchableSch_OpportunityCOA'];
        System.assert(!jobs.isEmpty());
    }


}