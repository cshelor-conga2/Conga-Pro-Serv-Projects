/** 
* @author Conga Services
* @date 20180723
* @version 1.0
* @description OrderHelperTest
*/
@isTest
public with sharing class OrderHelperTest {

    /**
    * @description setup - Setup test data
    */
    @testSetup
    public static void setup() {
        // TURN OFF ALL TRIGGER METHODS TEMPORARILY
        TriggerHelper.OverrideAllSettings(true, false);

        RecordType inv = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true AND DeveloperName = 'Invoice'];
        RecordType creditMemo = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true AND DeveloperName = 'Credit_Memo'];
        Id pbId = Test.getStandardPricebookId();

        AVA_SFCORE__TaxNowSetting__c testTaxSetting = new AVA_SFCORE__TaxNowSetting__c(
            Name = 'AvaTax',
            AVA_SFCORE__Active_Setting__c = TRUE,
            AVA_SFCORE__TriggerLimit__c = 0,
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

        // TEST COUNTRY RECORDS 
        List<Country_Territory__c> testCountries = new List<Country_Territory__c>();
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'AMER');
        Country_Territory__c newZealand = new Country_Territory__c(Name = 'New Zealand', Two_Letter_Code__c = 'NZ', Three_Letter_Code__c = 'NZL', Geo__c = 'APAC');
        Country_Territory__c gambia = new Country_Territory__c(Name = 'Gambia', Two_Letter_Code__c = 'GM', Three_Letter_Code__c = 'GMB', Geo__c = 'EMEA');
        insert new List<Country_Territory__c>{ unitedStates, newZealand, gambia };

        // TEST STATE RECORDS
        State_Province__c colorado = new State_Province__c(Name = 'Colorado', English_Name__c = 'Colorado', Code__c = 'CO', Country_TerritoryId__c = unitedStates.Id);
        State_Province__c california = new State_Province__c(Name = 'California', English_Name__c = 'California', Code__c = 'CA', Country_TerritoryId__c = unitedStates.Id);
        insert new List<State_Province__c>{ colorado, california };


        Account testAcct = new Account();
        testAcct.Name = 'Test Account';
        testAcct.BillingStreet = '123 Main';
        testAcct.BillingCity = 'Broomfield';
        testAcct.BillingState = 'CO';
        testAcct.BillingPostalCode = '80021';
        testAcct.BillingCountry = 'US';
        insert testAcct;

        SBQQ__Quote__c testQuote = (SBQQ__Quote__c)TestingUtility.createSObject('SBQQ__Quote__c', false, 1);
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;

        Opportunity testOpp = (Opportunity)TestingUtility.createSObject('Opportunity', false, 1);
        testOpp.AccountId = testAcct.Id;
        testOpp.SBQQ__PrimaryQuote__c = testQuote.Id;
        testOpp.pymt__SiteQuote_Expiration__c = Date.today().addDays(14);
        insert testOpp;

        testQuote.SBQQ__Opportunity2__c = testOpp.Id;
        update testQuote;

        Order invoice = new Order();
        invoice.RecordTypeId = inv.Id;
        invoice.EffectiveDate = System.today();
        invoice.AccountId = testAcct.Id;
        invoice.OpportunityId = testOpp.Id;
        invoice.Status = 'Draft';
        invoice.Pricebook2Id = pbId;
        insert invoice;

        Order cMemo = new Order();
        cMemo.RecordTypeId = creditMemo.Id;
        cMemo.EffectiveDate = System.today();
        cMemo.AccountId = testAcct.Id;
        cMemo.Status = 'Draft';
        cMemo.Pricebook2Id = pbId;
        insert cMemo;

        Product2 prod = new Product2();
        prod.Name = 'Test Product';
        prod.ProductCode = 'TP1';        
        insert prod;

        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pbId;
        pbe.UnitPrice = 1000;
        pbe.Product2Id = prod.Id;
        pbe.IsActive = true;
        insert pbe;

        OrderItem oi = new OrderItem();
        oi.OrderId = invoice.Id;
        oi.Quantity = 5;
        oi.UnitPrice = pbe.UnitPrice;
        oi.Unit_Price_4__c = pbe.UnitPrice;
        oi.PricebookEntryId = pbe.Id;
        oi.Product_Start_Date__c = Date.today();
        oi.Product_End_Date__c = Date.today().addYears(1);
        insert oi;

        OrderItem oi2 = new OrderItem();
        oi2.OrderId = cMemo.Id;
        oi2.Quantity = 5;
        oi2.UnitPrice = pbe.UnitPrice;
        oi2.Unit_Price_4__c = pbe.UnitPrice;
        oi2.PricebookEntryId = pbe.Id;
        oi2.Product_Start_Date__c = Date.today();
        oi2.Product_End_Date__c = Date.today().addYears(1);
        insert oi2;
    }

    /**
    * @description createRevScheduleTest - Test createRevSchedule Happy Path of code 
    */
    public static testmethod void createRevScheduleTest() {  
        // GET TEST ORDER
        List<Order> testOrders = [SELECT Id FROM Order WHERE RecordType.DeveloperName = 'Invoice'];
        System.assert(testOrders.size() == 1);     

        // GET TEST ORDER ITEMS
        List<OrderItem> testOrderItems = [SELECT Id FROM OrderItem WHERE OrderId IN :testOrders];
        System.assert(testOrderItems.size() == 1);

        Test.startTest();

        testOrders[0].Status = 'Pending';
        update testOrders;

        Test.stopTest();

        List<Revenue_Schedule__c> revSchedules = [SELECT Id FROM Revenue_Schedule__c WHERE Order_ProductId__c = :testOrderItems[0].Id];
        System.assert(revSchedules.size() == 13);
    }

    /**
    * @description clearSiteQuoteExpTest - Test clearSiteQuoteExp Happy Path of code 
    */
    public static testmethod void clearSiteQuoteExpTest(){ 
        // GET TEST OPPORTUNITIES
        List<Opportunity> testOpps = [SELECT Id, pymt__SiteQuote_Expiration__c FROM Opportunity];
        System.assert(testOpps.size() == 1);

        // GET TEST ORDER
        List<Order> testOrders = [SELECT Id FROM Order WHERE OpportunityId IN :testOpps];
        System.assert(testOrders.size() == 1);

        // TEST THAT THE TEST OPP DOES HAVE A SITE QUOTE EXPIRATION DATE
        testOpps = [SELECT Id, pymt__SiteQuote_Expiration__c FROM Opportunity WHERE Id IN :testOpps];
        System.assert(testOpps.size() == 1);
        System.assert(testOpps[0].pymt__SiteQuote_Expiration__c != null);   

        Test.startTest();

        // UPDATE ORDER STATUS TO EXECUTE TRIGGER METHOD
        testOrders[0].Status = 'Paid';
        update testOrders;
        
        Test.stopTest();

        // REFRESH TEST OPP, SITE QUOTE EXPIRATION DATE SHOULD BE EMPTY
        testOpps = [SELECT Id, pymt__SiteQuote_Expiration__c FROM Opportunity WHERE Id IN :testOpps];
        System.assert(testOpps.size() == 1);
        System.assert(testOpps[0].pymt__SiteQuote_Expiration__c == null);
    }
    
    /**
    * @description validateStateAndCountryTest - Test validateStateAndCountry trigger method
    */
    public static testMethod void validateStateAndCountryTest(){
        // GET TEST ACCOUNT
        List<Account> testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccount.size() == 1);

        // GET TEST OPPORTUNITY
        List<Opportunity> testOpp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :testAccount[0].Id];
        System.assert(testOpp.size() == 1);

        // CREATE TEST ORDER
        Order testOrder = (Order)TestingUtility.createSObject('Order', true, 1);
        testOrder.AccountId = testAccount[0].Id; 
        testOrder.OpportunityId = testOpp[0].Id;                
        testOrder.BillingState = 'CO';
        testOrder.BillingCountry = 'USA';
        testOrder.ShippingState = 'CA';
        testOrder.ShippingCountry = 'USA';
        testOrder.Status = 'Draft';
        testOrder.Pricebook2Id = Test.getStandardPricebookId();

        Test.startTest();

        insert testOrder;

        // TEST THAT COUNTRIES AND STATES WERE PROPERLY CONVERTED TO THEIR FULL NAMES
        List<Order> testOrders = [SELECT Id, Name, BillingState, BillingCountry, ShippingState, ShippingCountry FROM Order WHERE Id = :testOrder.Id];
        System.assert(testOrders.size() == 1);
        System.assert(testOrders[0].BillingState == 'Colorado');
        System.assert(testOrders[0].BillingState == 'Colorado');
        System.assert(testOrders[0].BillingCountry == 'United States');
        System.assert(testOrders[0].ShippingState == 'California');
        System.assert(testOrders[0].ShippingCountry == 'United States');

        // MAKE INVALID CHANGES AND UPDATE, EACH UPDATE SHOULD CAUSE A TRIGGER ERROR TO OCCUR
        try{
            testOrders[0].BillingState = 'Colorad';
            update testOrders;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('State'));
        }
        ////
        try{
            testOrders[0].BillingState = 'Colorado';
            testOrders[0].BillingCountry = 'United Stat';
            update testOrders;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('Country'));
        }
        ////
        try{
            testOrders[0].BillingState = 'Colorado';
            testOrders[0].BillingCountry = 'United States';
            testOrders[0].ShippingState = 'Californ';
            update testOrders;     
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('State'));
        }
        ////
        try{
            testOrders[0].BillingState = 'Colorado';
            testOrders[0].BillingCountry = 'United States';
            testOrders[0].ShippingState = 'California';
            testOrders[0].ShippingCountry = 'United Stat';
            update testOrders;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('Country'));
        }

        Test.stopTest();
    }


}