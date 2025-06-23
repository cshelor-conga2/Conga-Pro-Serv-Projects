/**
* @author Conga Services
* @date 20160524
* @version 1.00
* @description OpportunityHelperTest - Test methods for the OpportunityHelper class
*/
@isTest
public class OpportunityHelperTest {

    // OPP PARTNER REP MAPPING TEST METADATA
    public static Id TestPartnerAccountId {get;set;}
    public static List<Opp_Partner_Rep_Mapping__mdt> OppPartnerRepMappingTestMeta {
    get {
            Map<String, Object> meta1FieldValues = new Map<String, Object>{ 
                'Team__c' => null,
                'AccountId__c' => TestPartnerAccountId,
                'Partner_Rep__c' => 'Account Test Partner'
            };
            Opp_Partner_Rep_Mapping__mdt customTestMeta1 = (Opp_Partner_Rep_Mapping__mdt)TestingUtility.createTestMeta('Opp_Partner_Rep_Mapping__mdt', meta1FieldValues);

            Map<String, Object> meta2FieldValues = new Map<String, Object>{ 
                'Team__c' => 'APAC - CS',
                'AccountId__c' => null,
                'Partner_Rep__c' => 'Team Test Partner'
            };
            Opp_Partner_Rep_Mapping__mdt customTestMeta2 = (Opp_Partner_Rep_Mapping__mdt)TestingUtility.createTestMeta('Opp_Partner_Rep_Mapping__mdt', meta2FieldValues);
            OppPartnerRepMappingTestMeta = new List<Opp_Partner_Rep_Mapping__mdt>{ customTestMeta1, customTestMeta2 };
        return OppPartnerRepMappingTestMeta;
    } set; }

    // OPP PARTNER AUTOMATION SETTINGS TEST METADATA
    public static Id CongaProServAccountId {get;set;}
    public static Id AdditionalProductId {get;set;}
    public static Opp_Partner_Automation_Settings__mdt OppPartnerAutomationTestMeta {
    get {
            Map<String, Object> metaFieldValues = new Map<String, Object>{ 
                'Primary_Partner_Req_Stages__c' => '2 - Validation\r\n3 - Justification\r\n4 - Negotiation\r\nClosed Won',
                'Primary_Partner_Req_Product_Lines__c' => 'Conga Contracts for Salesforce\r\nConga Contracts\r\nConga AI\r\nConga Orchestrate',
                'Conga_Partner_Account_Id__c' => CongaProServAccountId,
                'Add_Products_Qualifying_for_PS_Project__c' => AdditionalProductId + ' - Test Product'
            };
            Opp_Partner_Automation_Settings__mdt customTestMeta = (Opp_Partner_Automation_Settings__mdt)TestingUtility.createTestMeta('Opp_Partner_Automation_Settings__mdt', metaFieldValues);
            OppPartnerAutomationTestMeta = customTestMeta;
        return OppPartnerAutomationTestMeta;
    } set; }

    // OOPPORTUNITY ONBOARDING SPECIALISTS TEST METADATA
    public static Id OnboardingSpecialistId1 {get; set;}
    public static Id OnboardingSpecialistId2 {get; set;}
    public static Id OnboardingSpecialistId3 {get; set;}
    public static List<Opportunity_Onboarding_Specialists__mdt> OppOnboardingSpecialistsTestMeta {
    get {
            Map<String, Object> meta1FieldValues = new Map<String, Object>{ 
                'Onboarding_Specialist__c' => OnboardingSpecialistId1,
                'Team__c' => 'EMEA',
                'Default__c' => false,
                'US_Zip_Start__c' => null,
                'US_Zip_End__c' => null
            };
            Opportunity_Onboarding_Specialists__mdt customTestMeta1 = (Opportunity_Onboarding_Specialists__mdt)TestingUtility.createTestMeta('Opportunity_Onboarding_Specialists__mdt', meta1FieldValues);

            Map<String, Object> meta2FieldValues = new Map<String, Object>{ 
                'Onboarding_Specialist__c' => OnboardingSpecialistId2,
                'Team__c' => '',
                'Default__c' => true,
                'US_Zip_Start__c' => '35',
                'US_Zip_End__c' => '69'
            };
            Opportunity_Onboarding_Specialists__mdt customTestMeta2 = (Opportunity_Onboarding_Specialists__mdt)TestingUtility.createTestMeta('Opportunity_Onboarding_Specialists__mdt', meta2FieldValues);
            
            Map<String, Object> meta3FieldValues = new Map<String, Object>{ 
                'Onboarding_Specialist__c' => OnboardingSpecialistId3,
                'Team__c' => '',
                'Default__c' => false,
                'US_Zip_Start__c' => '70',
                'US_Zip_End__c' => '99'
            };
            Opportunity_Onboarding_Specialists__mdt customTestMeta3 = (Opportunity_Onboarding_Specialists__mdt)TestingUtility.createTestMeta('Opportunity_Onboarding_Specialists__mdt', meta3FieldValues);

            OppOnboardingSpecialistsTestMeta = new List<Opportunity_Onboarding_Specialists__mdt>{ customTestMeta1, customTestMeta2, customTestMeta3 };
        return OppOnboardingSpecialistsTestMeta;
    } set; }

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        //// TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 3);    
        testProducts[0].Name = 'Rev Schedule Prod';
        testProducts[0].ProductCode = 'RSP1';   
        testProducts[0].RevenueScheduleType = 'Repeat';
        testProducts[0].RevenueInstallmentPeriod = 'Monthly';
        testProducts[0].NumberOfRevenueInstallments = 12;
        testProducts[0].CanUseRevenueSchedule = true;
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[0].Family = 'ActionGrid';
        testProducts[0].Product_Line__c = 'Conga Grid';
        //
        testProducts[1].Name = 'Rev Schedule Prod';
        testProducts[1].ProductCode = 'RSP2';
        testProducts[1].RevenueScheduleType = 'Repeat';
        testProducts[1].RevenueInstallmentPeriod = 'Monthly';
        testProducts[1].NumberOfRevenueInstallments = 12;
        testProducts[1].CanUseRevenueSchedule = true;
        testProducts[1].FY16_Revenue_Type__c = 'Recurring';
        testProducts[1].Family = 'Conga Composer Licenses';
        testProducts[1].Product_Line__c = 'Conga Composer';
        //
        testProducts[2].Name = 'Conga AI Test';
        testProducts[2].ProductCode = 'CAIT';
        testProducts[2].FY16_Revenue_Type__c = 'Recurring';
        testProducts[2].Family = 'Contract Analysis';
        testProducts[2].Product_Line__c = 'Conga AI';
        insert testProducts;

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
        testPricebookEntries[2].UnitPrice = 375.00;
        insert testPricebookEntries;

        //// TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', false, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[0].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        insert testQuotes;

        // TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', false, 2);
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 75;
        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__Quantity__c = 15;
        testQuoteLines[1].SBQQ__StartDate__c = Date.today();
        testQuoteLines[1].SBQQ__EndDate__c =  Date.today().addDays(180);
        insert testQuoteLines;

        // CREATE TEST GEO
        TM_Geo__c na = new TM_Geo__c(Name = 'AMER', Is_Active__c = true);
        insert new List<TM_Geo__c>{ na };

        // CREATE TEST REGION
        TM_Region__c southWest = new TM_Region__c(Name = 'South West', Is_Active__c = true, TM_GeoId__c = na.Id);
        insert new List<TM_Region__c>{ southWest };

        // CREATE TEST TERRITORIES
        TM_Territory__c terr1 = new TM_Territory__c(Name = 'California 1', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);    
        insert new List<TM_Territory__c>{ terr1 };       

        // CREATE TEST SEGMENTS
        TM_Segment__c enterprise = new TM_Segment__c(Name = 'Enterprise', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 5001, Maximum_Employees__c = 10000000);
        TM_Segment__c midCommercial = new TM_Segment__c(Name = 'Mid Commercial', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 201, Maximum_Employees__c = 1000);
        TM_Segment__c growth = new TM_Segment__c(Name = 'Growth', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 1, Maximum_Employees__c = 200);
        insert new List<TM_Segment__c>{ enterprise, midCommercial, growth };
    }

    /**
    * @description opportunityFieldUpdatesTest - Test method for the OpportunityHelper.opportunityFieldUpdates method
    */
    private static testmethod void opportunityFieldUpdatesTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','opportunityFieldUpdates', true);

        // TEMPORARILY DISABLE ALL TRIGGERS
        TriggerHelper.OverrideAllSettings(true, false);

        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(!testPricebookEntries.isEmpty());

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].Customer_likely_to__c = 'Churn - potential to save';
        testAccounts[0].BillingStreet = '1234 Dirt Road';
        testAccounts[0].BillingCity = 'Denver';
        testAccounts[0].BillingState = 'Colorado';
        testAccounts[0].BillingPostalCode = '80020';
        testAccounts[0].ShippingStreet = '5678 Asphalt Drive';
        testAccounts[0].ShippingCity = 'Denver';
        testAccounts[0].ShippingState = 'Colorado';
        testAccounts[0].ShippingPostalCode = '80020';
        testAccounts[2].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');
        testAccounts[2].Type = 'Partner';
        insert testAccounts;

        // CREATE TEST CONTACTS
        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', false, 2);  
        testContacts[0].AccountId = testAccounts[0].Id;
        testContacts[1].AccountId = testAccounts[1].Id;
        insert testContacts;

        // CREATE TEST SALESFORCE ACCOUNT
        List<Salesforce_Account__c> testSalesforceAccounts = TestingUtility.createSObjectList('Salesforce_Account__c', false, 2);
        testSalesforceAccounts[0].Account__c = testAccounts[0].Id;
        testSalesforceAccounts[0].Salesforce_AE_RVP_Lookup__c = testContacts[0].Id;        
        testSalesforceAccounts[1].Account__c = testAccounts[1].Id;        
        insert testSalesforceAccounts;

        // TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract');
        testContract.AccountId = testAccounts[0].Id;
        testContract.Status = 'Draft';
        testContract.StartDate = Date.today().addDays(30);
        testContract.ContractTerm = 12;
        insert testContract;

        // REENABLE ALL TRIGGERS
        TriggerHelper.OverrideAllSettings(false, true);

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 3);
        testOpportunities[0].Name = 'Normal Opp';
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Opportunity').get('Indirect');
        testOpportunities[0].Billing_Party__c = testAccounts[1].Id;
        testOpportunities[0].Billing_Address_Override__c = null;
        //
        testOpportunities[1].Name = 'Test Renewal Opp';
        testOpportunities[1].AccountId = testAccounts[0].Id;
        testOpportunities[1].StageName = '0 - Qualification';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].SBQQ__Renewal__c = true;
        testOpportunities[1].Salesforce_AE_Posture__c = 'Engaged';
        //
        testOpportunities[2].Name = 'Test Amendment Opp';
        testOpportunities[2].AccountId = testAccounts[1].Id;
        testOpportunities[2].StageName = '0 - Qualification';          
        testOpportunities[2].CloseDate = Date.today();
        testOpportunities[2].SBQQ__AmendedContract__c = testContract.Id;
        testOpportunities[2].ImplementationPartnerPrimary__c = testAccounts[2].Id;
        insert testOpportunities;

        Test.startTest();

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c];
        System.assert(!testQuotes.isEmpty());
        testQuotes[0].SBQQ__Account__c = testAccounts[0].Id;
        testQuotes[0].SBQQ__Opportunity2__c = testOpportunities[1].Id;
        update testQuotes;

        // MAKE APPLICABLE CHANGES TO OPP 1
        testOpportunities[0].StageName = 'Closed Won';

        // MAKE APPLICABLE CHANGES TO OPP 2
        testOpportunities[1].Sales_Ops_Status__c = 'Invoice Sent';        
        testOpportunities[1].Sales_Ops_Approved__c = true;
        testOpportunities[1].Salesforce_Account__c = testSalesforceAccounts[0].Id;
        //testOpportunities[1].Salesforce_AE_Posture__c = 'None - Not Engaged';

        // MAKE APPLICABLE CHANGES TO OPP 3    
        testOpportunities[2].Salesforce_Account__c = testSalesforceAccounts[1].Id;
        testOpportunities[2].Sales_Ops_Status__c = 'Cancelled';
        testOpportunities[2].pymt__Paid_Off__c = true;
        testOpportunities[2].Date_Paid__c = null;          
        testOpportunities[2].Type_of_Credit_Card__c = 'Visa';
        update testOpportunities;

        // MAKE MORE APPLICABLE CHANGES TO OPP 2  
        testOpportunities[1].Salesforce_Account__c = null;

        // MAKE MORE APPLICABLE CHANGES TO OPP 3  
        testOpportunities[2].Salesforce_Account__c = testSalesforceAccounts[0].Id;
        testOpportunities[2].Date_Paid__c = null;      
        testOpportunities[2].Type_of_Credit_Card__c = 'Amex';
        update testOpportunities;

        Test.stopTest();
    }

    /**
    * @description updateBookingsOwnerTest - Test method for the OpportunityHelper.updateBookingsOwner method
    */
    private static testmethod void updateBookingsOwnerTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','updateBookingsOwner', true);

        // CREATE TEST SALES USER MANAGER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUserMgr = new User(Alias = 'sales1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', 
        FirstName = 'Sales', LastName = 'Person1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser1' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUserMgr;

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        testAccounts[0].TM_Territory_ManagerId__c = salesUserMgr.Id;
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].Name = 'Normal Opp';
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Type = 'New Business';

        testOpportunities[1].Name = 'Renewal Opp';
        testOpportunities[1].AccountId = testAccounts[0].Id;
        testOpportunities[1].TM_Territory_ManagerId__c = salesUserMgr.Id;
        testOpportunities[1].StageName = '0 - Qualification';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Amount = 12000;
        testOpportunities[1].Type = 'Renewal';
        testOpportunities[1].LeadSource = 'Territory Manager';
        insert testOpportunities;

        Test.startTest();

        // REFRESH OPPS AND CHECK FOR CORRECT DATA
        testOpportunities = [SELECT Id, Bookings_OwnerId__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].Bookings_OwnerId__c == UserInfo.getUserId());
        System.assert(testOpportunities[1].Bookings_OwnerId__c == salesUserMgr.Id);

        // MAKE APPLICABLE CHANGES AND TEST AGAIN
        testOpportunities[0].Amount = 12000;
        testOpportunities[0].Type = 'Renewal';
        testOpportunities[0].LeadSource = 'Territory Manager';
        testOpportunities[0].Lead_Source_Detail__c = 'TM Growth';
        testOpportunities[0].TM_Territory_ManagerId__c = salesUserMgr.Id;
        testOpportunities[1].Type = 'New Business';
        update testOpportunities;

        // REFRESH OPPS AND CHECK FOR CORRECT DATA
        testOpportunities = [SELECT Id, Bookings_OwnerId__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].Bookings_OwnerId__c == salesUserMgr.Id);
        System.assert(testOpportunities[1].Bookings_OwnerId__c == UserInfo.getUserId());

        Test.stopTest();
    }

    /**
    * @description validateOwnershipChangesTest - Test method for the OpportunityHelper.validateOwnershipChanges method
    */
    private static testmethod void validateOwnershipChangesTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','validateOwnershipChanges', true);

        // CREATE TEST SALES USER MANAGER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUserMgr = new User(Alias = 'sales1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', 
        FirstName = 'Sales', LastName = 'Person1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser1' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUserMgr;

        // CREATE TEST USER
        User salesUser = new User(Alias = 'sales2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', ManagerId = salesUserMgr.Id,
        FirstName = 'Sales', LastName = 'Person2', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser2' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpportunities[0].Name = 'Normal Opp';
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].OwnerId = salesUser.Id;
        testOpportunities[0].TM_Territory_ManagerId__c = salesUser.Id;
        testOpportunities[0].Customer_Success_ManagerId__c = salesUser.Id;
        insert testOpportunities;

        Test.startTest();

        System.runas(salesUser){

            // SALES USER CAN CHANGE AWAY FROM HIMSELF
            testOpportunities[0].OwnerId = salesUserMgr.Id;
            testOpportunities[0].TM_Territory_ManagerId__c = salesUserMgr.Id;
            testOpportunities[0].Customer_Success_ManagerId__c = salesUserMgr.Id;        
            Database.saveResult[] oppResults = Database.update(testOpportunities, false);
            System.assert(!oppResults.isEmpty());
            System.assert(oppResults[0].isSuccess());

            // SALES USER CANNOT CHANGE BACK TO HIMSELF, THE CURRENT OWNER/TM/CSM HAS TO DO THAT
            testOpportunities[0].OwnerId = salesUser.Id;
            testOpportunities[0].TM_Territory_ManagerId__c = salesUser.Id;
            testOpportunities[0].Customer_Success_ManagerId__c = salesUser.Id;        
            oppResults = Database.update(testOpportunities, false);
            System.assert(!oppResults.isEmpty());
            System.assert(!oppResults[0].isSuccess());
        }

        System.runas(salesUserMgr){

            // SALES USER MANAGER CAN CHANGE AWAY FROM HIMSELF
            testOpportunities[0].OwnerId = salesUser.Id;
            testOpportunities[0].TM_Territory_ManagerId__c = salesUser.Id;
            testOpportunities[0].Customer_Success_ManagerId__c = salesUser.Id;        
            Database.saveResult[] oppResults = Database.update(testOpportunities, false);
            System.assert(!oppResults.isEmpty());
            System.assert(oppResults[0].isSuccess());

            // SALES USER MANAGER CAN CHANGE BACK TO HIMSELF
            testOpportunities[0].OwnerId = salesUserMgr.Id;
            testOpportunities[0].TM_Territory_ManagerId__c = salesUserMgr.Id;
            testOpportunities[0].Customer_Success_ManagerId__c = salesUserMgr.Id;        
            oppResults = Database.update(testOpportunities, false);
            System.assert(!oppResults.isEmpty());
            System.assert(oppResults[0].isSuccess());
        }

        Test.stopTest();
    }

    /**
    * @description validateStageChangesTest - Test method for the OpportunityHelper.validateStageChanges method
    */
    private static testmethod void validateStageChangesTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','validateStageChanges', true);

        // TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 2);
        testProducts[0].Name = 'Test CCFS Prod';
        testProducts[0].ProductCode = 'TP1';
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[0].Family = 'Contract Lifecycle Management';
        testProducts[0].Product_Line__c = 'Conga Contracts for Salesforce';
        //
        testProducts[1].Name = 'Test Grid Prod';
        testProducts[1].ProductCode = 'TP2';
        testProducts[1].FY16_Revenue_Type__c = 'Recurring';
        testProducts[1].Family = 'Data and Process Automation';
        testProducts[1].Product_Line__c = 'Conga Grid';
        insert testProducts;

        // TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', false, 2);
        testPricebookEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[0].Product2Id = testProducts[0].Id;
        testPricebookEntries[0].IsActive = true;
        testPricebookEntries[0].UnitPrice = 200.00;
        //
        testPricebookEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[1].Product2Id = testProducts[1].Id;
        testPricebookEntries[1].IsActive = true;
        testPricebookEntries[1].UnitPrice = 500.00;
        insert testPricebookEntries;

        // CREATE TEST ACCOUNTS
        Account testAccount = (Account)TestingUtility.createSObject('Account', false, 1);
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].AccountId = testAccount.Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Name = 'Test Opp';
        testOpportunities[0].Type = 'New Business';
        //
        testOpportunities[1].AccountId = testAccount.Id;
        testOpportunities[1].StageName = '0 - Qualification';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Name = 'Test Opp 2';
        testOpportunities[1].Type = 'New Business';
        insert testOpportunities;

        // CREATE TEST OPPORTUNITY ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', false, 2);
        testOppItems[0].OpportunityId = testOpportunities[0].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[0].ServiceDate = Date.newInstance(2019, 1, 1);
        testOppItems[0].Product_End_Date__c = Date.newInstance(2019, 12, 31);
        //
        testOppItems[1].OpportunityId = testOpportunities[0].Id;
        testOppItems[1].Quantity = 5;
        testOppItems[1].UnitPrice = 500;
        testOppItems[1].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[1].ServiceDate = Date.newInstance(2019, 1, 1);
        testOppItems[1].Product_End_Date__c = Date.newInstance(2019, 12, 31);
        insert testOppItems;

        Test.startTest();

        // CHANGE OPP STAGES AND TEST THAT ONE ERRORED AND THE OTHER DID NOT
        testOpportunities[0].StageName = '2 - Validation';
        testOpportunities[1].StageName = '2 - Validation';
        Database.saveResult[] oppUpdateResults = Database.update(testOpportunities, false);
        System.assert(oppUpdateResults.size() == 2);
        System.assert(oppUpdateResults[0].isSuccess() == false);
        System.assert(oppUpdateResults[1].isSuccess() == true);

        for(Database.Error error : oppUpdateResults[0].getErrors()){
            System.assert(error.getMessage().contains('Implementation Partner - Primary is required'));
            break;
        }

        Test.stopTest();
    }

    /**
    * @description setUpOpportunityTeamTest - Test method for the OpportunityHelper.setUpOpportunityTeam method
    */
    private static testmethod void setUpOpportunityTeamTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setUpOpportunityTeam', true);        

        // CREATE TEST SALES USER MANAGER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person', UserName = 'salesUser' + UserInfo.getOrganizationId() + '@testorg.com',
        Alias = 'sales', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles');
        insert salesUser;
        //
        User salesUser2 = new User(Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person2', UserName = 'salesUser2' + UserInfo.getOrganizationId() + '@testorg.com',
        Alias = 'sales2', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles');
        insert salesUser2;
        //
        User salesUser3 = new User(Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person3', UserName = 'salesUser3' + UserInfo.getOrganizationId() + '@testorg.com',
        Alias = 'sales3', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles');
        insert salesUser3;

        // GET A BDR AND AN SE USER
        User bdrUser = [SELECT Id, Name FROM User WHERE IsActive = true AND UserRole.Name LIKE 'Business Development Representative%' LIMIT 1];
        User seUser = [SELECT Id, Name FROM User WHERE IsActive = true AND UserRole.Name = 'Solutions Engineer' LIMIT 1];

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        testAccounts[0].Type = 'Customer';
        insert testAccounts;

        // CREATE ACCOUNT TEAM MEMBERS
        List<AccountTeamMember> testAcctMembers = (List<AccountTeamMember>)TestingUtility.createSObjectList('AccountTeamMember', false, 4);
        // TERRITORY MANANGER
        testAcctMembers[0].AccountId = testAccounts[0].Id;
        testAcctMembers[0].UserId = salesUser.Id;
        testAcctMembers[0].TeamMemberRole = OpportunityHelper.TMROLENAME;
        // CLM MANAGER
        testAcctMembers[1].AccountId = testAccounts[0].Id;
        testAcctMembers[1].UserId = UserInfo.getUserId();
        testAcctMembers[1].TeamMemberRole = OpportunityHelper.CLMROLENAME;
        // CUSTOMER SUCCESS MANAGER
        testAcctMembers[2].AccountId = testAccounts[0].Id;
        testAcctMembers[2].UserId = salesUser2.Id;
        testAcctMembers[2].TeamMemberRole = OpportunityHelper.CSMROLENAME;
        // RENEWALS MANAGER
        testAcctMembers[3].AccountId = testAccounts[0].Id;
        testAcctMembers[3].UserId = salesUser3.Id;
        testAcctMembers[3].TeamMemberRole = OpportunityHelper.RMROLENAME;
        insert testAcctMembers;    

        Test.startTest();

        // CREATE TEST OPP
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Type = 'Renewal';
        testOpportunities[0].SDR__c = bdrUser.Id;
        testOpportunities[0].SE_Assigned__c = seUser.Id;
        insert testOpportunities;  

        // GET OPP TEAM MEMBERS AND CHECK FOR CORRECT DATA
        for(OpportunityTeamMember oppMember : [SELECT UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN :testOpportunities]){
            if(oppMember.TeamMemberRole == 'Opportunity Owner'){
                // OPP OWNER MEMBER ROLE SHOULD HAVE BEEN CHANGED IF THE USER MATCHED TO AN ACCOUNT MEMBER
                // IT WILL ONLY EXIST IF ITS USER WAS DIFFERENT THEN ALL ACCOUNT MEMBERS
                System.assert(oppMember.UserId != UserInfo.getUserId());
                System.assert(oppMember.UserId != salesUser.Id);
                System.assert(oppMember.UserId != salesUser2.Id);
                System.assert(oppMember.UserId != salesUser3.Id);
            }
            else if(oppMember.TeamMemberRole == OpportunityHelper.TMROLENAME){
                System.assert(oppMember.UserId == salesUser.Id);
            }
            else if(oppMember.TeamMemberRole == OpportunityHelper.CLMROLENAME){
                System.assert(oppMember.UserId == UserInfo.getUserId());
            }
            else if(oppMember.TeamMemberRole == OpportunityHelper.CSMROLENAME){
                System.assert(oppMember.UserId == salesUser2.Id);
            }
            else if(oppMember.TeamMemberRole == OpportunityHelper.RMROLENAME){
                System.assert(oppMember.UserId == salesUser3.Id);
            }
            else if(oppMember.TeamMemberRole == OpportunityHelper.BDRROLENAME){
                System.assert(oppMember.UserId == bdrUser.Id);
            }
            else if(oppMember.TeamMemberRole == OpportunityHelper.SEROLENAME){
                System.assert(oppMember.UserId == seUser.Id);
            }
        }

        Test.stopTest();
    }

    /**
    * @description updateOppTeamsFromLookupsTest - Test method for the OpportunityHelper.updateOpportunityTeams method
    */
    private static testmethod void updateOppTeamsFromLookupsTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','updateOppTeamsFromLookups', true);

        // CREATE TEST SALES USER MANAGER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'sales2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8',
        FirstName = 'Sales', LastName = 'Person2', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser2' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        // GET A SDR AND AN SE USER
        User bdrUser = [SELECT Id, Name FROM User WHERE IsActive = true AND UserRole.Name LIKE 'Business Development Representative%' LIMIT 1];
        User sdrUser = [SELECT Id, Name FROM User WHERE IsActive = true AND UserRole.Name LIKE 'Sales Development Representative%' LIMIT 1];
        User seUser = [SELECT Id, Name FROM User WHERE IsActive = true AND UserRole.Name = 'Solutions Engineer' LIMIT 1];
        System.assert(bdrUser != null);
        System.assert(sdrUser != null);
        System.assert(seUser != null);

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 2);
        testAccounts[0].Type = 'Prospect';
        testAccounts[1].Type = 'Customer';
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Type = 'New Business';
        //
        testOpportunities[1].AccountId = testAccounts[1].Id;
        testOpportunities[1].StageName = '0 - Qualification';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Type = 'Renewal';
        insert testOpportunities;

        // NO TEAM MEMBERS SHOULD EXIST YET
        List<OpportunityTeamMember> teamMembers = [SELECT OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN :testOpportunities AND TeamMemberRole != 'Opportunity Owner'];
        System.assert(teamMembers.size() == 0);

        Test.startTest();

        OpportunityHelper.OppUsersMap = null; // FORCE REQUERY OF OPP OWNERS

        // MAKE UPDATES
        testOpportunities[0].TM_Territory_ManagerId__c = UserInfo.getUserId();
        testOpportunities[0].Customer_Success_ManagerId__c = salesUser.Id;
        testOpportunities[0].SDR__c = bdrUser.Id;
        testOpportunities[0].SE_Assigned__c = seUser.Id;
        //
        testOpportunities[1].TM_Territory_ManagerId__c = salesUser.Id;
        testOpportunities[1].Customer_Success_ManagerId__c = UserInfo.getUserId();
        testOpportunities[1].SDR__c = sdrUser.Id;
        testOpportunities[1].SE_Assigned__c = seUser.Id;
        update testOpportunities;

        // GET TEAM MEMBERS AND CHECK THAT THEY WERE CREATED
        List<OpportunityTeamMember>  opp1Members =  [SELECT OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember 
                                                     WHERE OpportunityId = :testOpportunities[0].Id AND TeamMemberRole != 'Opportunity Owner'];
        System.assert(opp1Members.size() == 3); // ONLY ONE, OPP OF PROSPECT ACCOUNT DOES NOT GET A CSM
        for(OpportunityTeamMember member : opp1Members){
            if(member.TeamMemberRole == OpportunityHelper.TMROLENAME){
                System.assert(member.UserId == UserInfo.getUserId()); // ORIGINAL MEMBER
            }
            else if(member.TeamMemberRole == OpportunityHelper.BDRROLENAME){
                System.assert(member.UserId == bdrUser.Id); // BDR MEMBER
            }
            else if(member.TeamMemberRole == OpportunityHelper.SEROLENAME){
                System.assert(member.UserId == seUser.Id); // SE MEMBER
            }
        }

        // GET TEAM MEMBERS AND CHECK THAT THEY WERE CREATED
        List<OpportunityTeamMember>  opp2Members =  [SELECT OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember 
                                                     WHERE OpportunityId = :testOpportunities[1].Id AND TeamMemberRole != 'Opportunity Owner'];
        System.assert(opp2Members.size() == 4);
        for(OpportunityTeamMember member : opp2Members){
            if(member.TeamMemberRole == OpportunityHelper.TMROLENAME){
                System.assert(member.UserId == salesUser.Id);
            }
            else if(member.TeamMemberRole == OpportunityHelper.CSMROLENAME){
                System.assert(member.UserId == UserInfo.getUserId());
            }
            else if(member.TeamMemberRole == OpportunityHelper.SDRROLENAME){
                System.assert(member.UserId == sdrUser.Id); // SDR MEMBER
            }
            else if(member.TeamMemberRole == OpportunityHelper.SEROLENAME){
                System.assert(member.UserId == seUser.Id); // SE MEMBER
            }
        }

        // MAKE UPDATES
        testOpportunities[0].TM_Territory_ManagerId__c = salesUser.Id;
        testOpportunities[0].Customer_Success_ManagerId__c = UserInfo.getUserId();
        testOpportunities[0].SDR__c = sdrUser.Id;
        //
        testOpportunities[1].TM_Territory_ManagerId__c = UserInfo.getUserId();
        testOpportunities[1].Customer_Success_ManagerId__c = salesUser.Id;
        testOpportunities[1].SDR__c = bdrUser.Id;
        update testOpportunities;

        // GET TEAM MEMBERS AND CHECK THAT THEY WERE CREATED
        opp1Members =  [SELECT OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember
                        WHERE OpportunityId = :testOpportunities[0].Id AND TeamMemberRole != 'Opportunity Owner'];
        System.assert(opp1Members.size() == 5); // OPPORTUNITY IS MARKED AS SPLIT, NO OUT OF DATE MEMBERS WILL BE DELETED
        for(OpportunityTeamMember member : opp1Members){
            if(member.TeamMemberRole == OpportunityHelper.TMROLENAME){
                System.assert(member.UserId == UserInfo.getUserId() || member.UserId == salesUser.Id); // TM MEMBERS
            }
            else if(member.TeamMemberRole == OpportunityHelper.SDRROLENAME){
                System.assert(member.UserId == sdrUser.Id); // BDR MEMBER
            }
            else if(member.TeamMemberRole == OpportunityHelper.SEROLENAME){
                System.assert(member.UserId == seUser.Id); // SE MEMBER
            }
        }

        // GET TEAM MEMBERS AND CHECK THAT THEY WERE CREATED
        opp2Members =  [SELECT OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember
                        WHERE OpportunityId = :testOpportunities[1].Id AND TeamMemberRole != 'Opportunity Owner'];
        System.assert(opp2Members.size() == 5);  // OPPORTUNITY IS MARKED AS SPLIT, NO OUT OF DATE MEMBERS WILL BE DELETED
        for(OpportunityTeamMember member : opp2Members){
            if(member.TeamMemberRole == OpportunityHelper.TMROLENAME){
                System.assert(member.UserId == UserInfo.getUserId() || member.UserId == salesUser.Id);
            }
            else if(member.TeamMemberRole == OpportunityHelper.CSMROLENAME){
                System.assert(member.UserId == salesUser.Id);
            }
            else if(member.TeamMemberRole == OpportunityHelper.BDRROLENAME){
                System.assert(member.UserId == bdrUser.Id); // SDR MEMBER
            }
            else if(member.TeamMemberRole == OpportunityHelper.SEROLENAME){
                System.assert(member.UserId == seUser.Id); // SE MEMBER
            }
        }   
        Test.stopTest();
    }

    /**
    * @description calculateCSForecastTest - Test method for the OpportunityHelper.calculateCSForecast method
    */
    private static testmethod void calculateCSForecastTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','calculateCSForecast', true);

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 5);
        testAccounts[0].Customer_likely_to__c = 'Churn - no chance to save';
        testAccounts[1].Customer_likely_to__c = 'Churn - potential to save';
        testAccounts[2].Customer_likely_to__c = 'Downsell';
        testAccounts[3].Customer_likely_to__c = 'Renew at current level';
        testAccounts[4].Customer_likely_to__c = null;
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 6);
        for(Opportunity testOpp : testOpportunities){
            testOpp.StageName = '0 - Qualification';
            testOpp.CloseDate = Date.today();
            testOpp.Type = 'Renewal';
        }
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].Current_Automation_Ave_MRR__c = 154.76;

        testOpportunities[1].AccountId = testAccounts[1].Id;
        testOpportunities[1].Current_Courier_Ave_MRR__c = 187.56;

        testOpportunities[2].AccountId = testAccounts[2].Id;
        testOpportunities[2].Current_Grid_Ave_MRR__c = 3256.75;

        testOpportunities[3].AccountId = testAccounts[3].Id;
        testOpportunities[3].Current_Product_Bundles_Ave_MRR__c = 7500.00;

        testOpportunities[4].AccountId = testAccounts[4].Id;
        testOpportunities[4].Current_Services_Ave_MRR__c = 5500.00;

        testOpportunities[5].AccountId = testAccounts[4].Id;
        testOpportunities[5].CS_Forecast_Override__c = 550.00;
        insert testOpportunities;

        Test.startTest();

        // REFRESH OPPS AND TEST FOR CORRECT DATA
        testOpportunities = [SELECT Id, CS_Forecast_Apex__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].CS_Forecast_Apex__c == -154.76);
        System.assert(testOpportunities[1].CS_Forecast_Apex__c == -131.292);
        System.assert(testOpportunities[2].CS_Forecast_Apex__c == -488.5125);
        System.assert(testOpportunities[3].CS_Forecast_Apex__c == -375.00);
        System.assert(testOpportunities[4].CS_Forecast_Apex__c == 0.00); // BLANK CUSTOMER LIKELY TO DEFAULTS TO 0
        System.assert(testOpportunities[5].CS_Forecast_Apex__c == 550.00); // OVERRIDE
        
        // UPDATE OPPS
        testOpportunities[0].Current_Courier_Ave_MRR__c = 650.00;
        testOpportunities[1].Current_Grid_Ave_MRR__c = 400.00;
        testOpportunities[2].Current_Product_Bundles_Ave_MRR__c = 355.75;
        testOpportunities[3].Current_Automation_Ave_MRR__c = 895.50;
        testOpportunities[4].Current_Training_Ave_MRR__c = 12500.00;
        testOpportunities[5].CS_Forecast_Override__c = null;
        update testOpportunities;

        Test.stopTest();

        // REFRESH OPPS AND TEST FOR CORRECT DATA
        testOpportunities = [SELECT Id, CS_Forecast_Apex__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].CS_Forecast_Apex__c == -804.76);
        System.assert(testOpportunities[1].CS_Forecast_Apex__c == -411.292);
        System.assert(testOpportunities[2].CS_Forecast_Apex__c == -541.875);
        System.assert(testOpportunities[3].CS_Forecast_Apex__c == -419.775);
        System.assert(testOpportunities[4].CS_Forecast_Apex__c == 0.00); // BLANK CUSTOMER LIKELY TO DEFAULTS TO 0
        System.assert(testOpportunities[5].CS_Forecast_Apex__c == 0.00); // BLANK CUSTOMER LIKELY TO DEFAULTS TO 0
    }

    /**
    * @description testCreateOnboardingProject - Test method for the OpportunityHelper.createProjectRecord method
    */   
    public static testmethod void testCreateOnboardingProject() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','createProjectRecord', true);

        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Contact';
        c.Email = 'test@test.net';
        insert c;

        Account a = new Account();
        a.Name = 'test account';
        a.BillingContact__c = c.Id;
        a.BillingStreet = 'test street';
        a.BillingCity = 'test city';
        a.BillingCountry = 'USA';
        a.ShippingCountry = 'USA';
        a.ShippingStreet = 'test street';
        a.ShippingCity = 'test city';
        a.ShippingPostalCode = '80000';
        a.BillingPostalCode = '80000';
        insert a;

        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = (Product2)TestingUtility.createSObject('Product2');
        prod.Name = 'Non PS Prod';
        prod.ProductCode = 'NPS-11';
        prod.FY16_Revenue_Type__c = 'Recurring';
        insert prod;
        
        PricebookEntry entry = (PricebookEntry)TestingUtility.createSObject('PricebookEntry');
        entry.Product2Id = prod.Id;
        entry.Pricebook2Id = pricebookId;
        entry.UnitPrice = 200;
        entry.IsActive = true;
        insert entry;

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.Name = 'Onboarding Opp';
        opp.AccountId = a.Id;
        opp.Type = 'New Business';
        opp.LeadSource = 'Inbound';
        opp.StageName = '0 - Qualification';
        opp.Customer_Implementation_Type__c = 'Self';
        opp.CloseDate = System.today();
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.PricebookEntryId = entry.Id;
        oli.OpportunityId = opp.Id;
        oli.UnitPrice = 20.00;
        oli.Quantity = 5;
        oli.ServiceDate = System.today();
        oli.Product_End_Date__c = System.today().addDays(365);
        insert oli;

        opp.StageName = 'Closed Won';
        opp.CloseDate = System.today(); 
        update opp;

        Test.stopTest();

        List<PS_Project__c> projects = [SELECT Id, OpportunityId__c FROM PS_Project__c WHERE OpportunityId__c = :opp.Id];
        System.assertEquals(1, projects.size(), 'The Project was not created');
    }

    /**
    * @description testCreateProServProject - Another test method for the OpportunityHelper.createProjectRecord method
    */ 
    public static testmethod void testCreateProServProject() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','createProjectRecord', true);

        // TEMPORARILY DISABLE ALL TRIGGERS
        TriggerHelper.OverrideAllSettings(true, false);

        // CREATE TEST PRODUCTS
        List<Product2> testProducts = TestingUtility.createSObjectList('Product2', false, 3);
        testProducts[0].Name = 'PS Prod';
        testProducts[0].ProductCode = 'PS-11';
        testProducts[0].LOB__c = 'Services';
        testProducts[0].FY16_Revenue_Type__c = 'Non-Recurring';
        testProducts[1].Name = 'PS Prod 2';
        testProducts[1].ProductCode = 'PS-12';
        testProducts[1].Hours__c = 10;
        testProducts[1].Hourly_Rate__c = 200;
        testProducts[1].LOB__c = 'Services';
        testProducts[1].FY16_Revenue_Type__c = 'Non-Recurring';
        testProducts[2].Name = 'PS Prod 3';
        testProducts[2].ProductCode = 'PS-13';
        testProducts[2].LOB__c = 'Contracts';
        testProducts[2].FY16_Revenue_Type__c = 'Non-Recurring';        
        insert testProducts;

        // SET ADDITIONAL PRODUCT ID
        AdditionalProductId = testProducts[2].Id;

        // GET ACCOUNT RECORD TYPES
        Map<String, Id> accountRTs = UtilityClass.getRecordTypesForObject('Account');

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].Name = 'Regular Account';
        testAccounts[0].RecordTypeId = accountRTs.get('Business_Account');
        testAccounts[1].Name = 'Partner Account';
        testAccounts[1].RecordTypeId = accountRTs.get('Partner_Account');
        testAccounts[2].Name = 'Conga Partner Account';
        testAccounts[2].RecordTypeId = accountRTs.get('Partner_Account');
        insert testAccounts;

        // SET CONGA PARENT ACCOUNT ID
        CongaProServAccountId = testAccounts[2].Id;

        // CREATE TEST CONTACT
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@test.net', AccountId = testAccounts[0].Id);
        insert testContact;

        // CREATE TEST OPPS
        List<Opportunity> testOpps = TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpps[0].Name = 'Test Opp 1 with Partner';
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].Type = 'New Business';
        testOpps[0].StageName = '0 - Qualification';
        testOpps[0].CloseDate = System.today();
        testOpps[0].ImplementationPartnerPrimary__c = testAccounts[1].Id;
        //
        testOpps[1].Name = 'Test Opp 2 no Partner';
        testOpps[1].AccountId = testAccounts[0].Id;
        testOpps[1].Type = 'New Business';
        testOpps[1].StageName = '0 - Qualification';
        testOpps[1].CloseDate = System.today();
        insert testOpps;

        // CREATE TEST SUPPORT REQUEST
        List<Support_Request__c> testSRs = TestingUtility.createSObjectList('Support_Request__c', false, 2);
        testSRs[0].Salesforce_Opportunity_Record__c = testOpps[0].Id;
        testSRs[0].Primary__c = true;
        testSRs[0].Project_Agreement_Type__c = 'Custom SOW';
        testSRs[0].Invoice_Type__c = 'Weekly';
        testSRs[0].Billing_Type__c = 'Time and Materials';
        testSRs[0].Payment_Terms__c = 'Net 30 days';
        testSRs[0].Product_s__c = 'Conga Grid;Conga Sign';
        //
        testSRs[1].Salesforce_Opportunity_Record__c = testOpps[1].Id;
        testSRs[1].Primary__c = true;
        testSRs[1].Project_Agreement_Type__c = 'Custom SOW';
        testSRs[1].Invoice_Type__c = 'Monthly';
        testSRs[1].Billing_Type__c = 'Time and Materials';
        testSRs[1].Payment_Terms__c = 'Net 30 days';
        testSRs[1].Product_s__c = 'Composer Family;Conga AI Analyze';
        insert testSRs;

        // CREATE TEST SUPPORT REQUEST PROJECT
        List<PS_Project__c> testProjects = TestingUtility.createSObjectList('PS_Project__c', false, 1);
        testProjects[0].Name = 'Support Request Project';
        insert testProjects;

        Id pricebookId = Test.getStandardPricebookId();

        // CREATE TEST MILESTONES
        List<Milestone__c> testMilestones = TestingUtility.createSObjectList('Milestone__c', false, 4);
        testMilestones[0].Name = 'Initiate and Design';
        testMilestones[0].PricebookId__c = pricebookId;
        testMilestones[0].Support_Request__c = testSRs[0].Id;
        testMilestones[0].ProjectId__c = testProjects[0].Id;
        testMilestones[1].Name = 'Build and Validate';
        testMilestones[1].PricebookId__c = pricebookId;
        testMilestones[1].Support_Request__c = testSRs[0].Id;
        testMilestones[1].ProjectId__c = testProjects[0].Id;
        testMilestones[2].Name = 'Deploy';
        testMilestones[2].PricebookId__c = pricebookId;
        testMilestones[2].Support_Request__c = testSRs[1].Id;
        testMilestones[2].ProjectId__c = testProjects[0].Id;
        testMilestones[3].Name = 'Data Migration';
        testMilestones[3].PricebookId__c = pricebookId;
        testMilestones[3].Support_Request__c = testSRs[1].Id;
        testMilestones[3].ProjectId__c = testProjects[0].Id;
        insert testMilestones;

        // CREATE TEST OPP CONTACT ROLES
        List<OpportunityContactRole> testOppContactRoles = TestingUtility.createSObjectList('OpportunityContactRole', false, 2);
        testOppContactRoles[0].ContactId = testContact.Id;
        testOppContactRoles[0].OpportunityId = testOpps[0].Id;
        testOppContactRoles[0].Role = 'Technical Buyer';
        testOppContactRoles[0].IsPrimary = true;
        //
        testOppContactRoles[1].ContactId = testContact.Id;
        testOppContactRoles[1].OpportunityId = testOpps[1].Id;
        testOppContactRoles[1].Role = 'Technical Buyer';
        testOppContactRoles[1].IsPrimary = true;
        insert testOppContactRoles;

        // CREATE TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testEntries = TestingUtility.createSObjectList('PricebookEntry', false, 3);
        testEntries[0].Product2Id = testProducts[0].Id;
        testEntries[0].Pricebook2Id = pricebookId;
        testEntries[0].UnitPrice = 200;
        testEntries[0].IsActive = true;
        testEntries[1].Product2Id = testProducts[1].Id;
        testEntries[1].Pricebook2Id = pricebookId;
        testEntries[1].UnitPrice = 100;
        testEntries[1].IsActive = true;
        testEntries[2].Product2Id = testProducts[2].Id;
        testEntries[2].Pricebook2Id = pricebookId;
        testEntries[2].UnitPrice = 100;
        testEntries[2].IsActive = true;        
        insert testEntries;

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = TestingUtility.createSObjectList('OpportunityLineItem', false, 3);
        testOppItems[0].PricebookEntryId = testEntries[0].Id;
        testOppItems[0].OpportunityId = testOpps[0].Id;
        testOppItems[0].UnitPrice = 20.00;
        testOppItems[0].Quantity = 1;
        testOppItems[0].ServiceDate = System.today();
        //
        testOppItems[1].PricebookEntryId = testEntries[1].Id;
        testOppItems[1].OpportunityId = testOpps[0].Id;
        testOppItems[1].UnitPrice = 2000.00;
        testOppItems[1].Quantity = 1;
        testOppItems[1].ServiceDate = System.today();
        //
        testOppItems[2].PricebookEntryId = testEntries[2].Id;
        testOppItems[2].OpportunityId = testOpps[1].Id;
        testOppItems[2].UnitPrice = 3000.00;
        testOppItems[2].Quantity = 1;
        testOppItems[2].ServiceDate = System.today();
        insert testOppItems;

        // REENABLE ALL TRIGGERS
        TriggerHelper.OverrideAllSettings(false, true);

        Test.startTest();

        testOpps[0].StageName = 'Closed Won';
        testOpps[0].CloseDate = System.today();
        testOpps[1].StageName = 'Closed Won';
        testOpps[1].CloseDate = System.today();
        update testOpps;

        Test.stopTest();

        Map<String, Id> projectRTs = UtilityClass.getRecordTypesForObject('PS_Project__c');
        List<PS_Project__c> projects = [SELECT Id, RecordTypeId, Partner_Company_Name_Engaged__c,
                                         (SELECT Id FROM Milestones__r),
                                         (SELECT Id FROM Project_Teams__r)
                                        FROM PS_Project__c WHERE OpportunityId__c IN :testOpps];
        System.assertEquals(4, projects.size(), 'One or more of the Projects were not created'); // 4, TWO PS AND TWO ONBOARDING, VALIDATE ONLY THE PS ONES
        System.assert(projects[0].RecordTypeId == projectRTs.get('Partner'));
        System.assert(projects[0].Partner_Company_Name_Engaged__c == testAccounts[1].Id);
        System.assert(projects[0].Milestones__r.size() == 2);
        System.assert(projects[0].Project_Teams__r.size() == 1);
        //
        System.assert(projects[2].RecordTypeId == projectRTs.get('PS_Project'));
        System.assert(projects[2].Partner_Company_Name_Engaged__c == testAccounts[2].Id);
        System.assert(projects[2].Milestones__r.size() == 2);
        System.assert(projects[2].Project_Teams__r.size() == 1);
    }

    /**
    * @description getPrimaryContactFromAcctTest - Test method for the OpportunityHelper.getPrimaryContactFromAcct method
    */ 
    public static testmethod void getPrimaryContactFromAcctTest() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','getPrimaryContactFromAcct', true);

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 1);
        insert testAccounts;

        // CREATE TEST CONTACTS
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', false, 6);
        testContacts[0].AccountId = testAccounts[0].Id;
        testContacts[0].LastName = 'Allen';
        testContacts[1].AccountId = testAccounts[0].Id;        
        testContacts[1].LastName = 'Brenneman';
        testContacts[2].AccountId = testAccounts[0].Id;
        testContacts[2].LastName = 'Couch';
        testContacts[3].AccountId = testAccounts[0].Id;
        testContacts[3].LastName = 'Dennis';
        testContacts[4].AccountId = testAccounts[0].Id;
        testContacts[4].LastName = 'Englemann';
        testContacts[5].AccountId = testAccounts[0].Id;
        testContacts[5].LastName = 'Fredrick';
        insert testContacts;

        // UPDATE ACCOUNT CONTACT RELATIONS
        List<AccountContactRelation> testRelations = [SELECT AccountId, ContactId, IsPrimary__c, Roles FROM AccountContactRelation];
        System.assert(testRelations.size() == 6);

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpps = TestingUtility.createSObjectList('Opportunity', false, 5);
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].Type = 'Existing Business';
        testOpps[1].AccountId = testAccounts[0].Id;
        testOpps[1].Type = 'Existing Business';
        testOpps[2].AccountId = testAccounts[0].Id;
        testOpps[2].Type = 'Existing Business';
        testOpps[3].AccountId = testAccounts[0].Id;
        testOpps[3].Type = 'Renewal';
        testOpps[4].AccountId = testAccounts[0].Id;
        testOpps[4].Type = 'Renewal';

        Test.startTest();

        // INSERT TEST OPP 1
        insert testOpps[0];

        // UPDATE CONTACT RELATIONS
        testRelations[5].Roles = 'Technical Buyer';
        testRelations[5].IsPrimary__c = true;
        update testRelations[5];

        // INSERT TEST OPP 2
        insert testOpps[1];

        // UPDATE CONTACT RELATIONS
        testRelations[3].Roles = 'Economic Buyer';
        testRelations[3].IsPrimary__c = true;
        update testRelations[3];
        
        // INSERT TEST OPP 3
        insert testOpps[2];

        // UPDATE CONTACT RELATIONS
        testRelations[4].Roles = 'Admin';
        testRelations[4].IsPrimary__c = true;
        update testRelations[4];
        
        // INSERT TEST OPP 4
        insert testOpps[3];

        // UPDATE CONTACT RELATIONS
        testRelations[2].Roles = 'Decision Maker';
        testRelations[2].IsPrimary__c = true;
        update testRelations[2];
        
        // INSERT TEST OPP 5
        insert testOpps[4];

        Test.stopTest();

        // RELOAD OPPS AND TEST FOR CORRECT DATA
        testOpps = [SELECT Id, Primary_Contact__c FROM Opportunity WHERE Id IN :testOpps];
        System.assert(testOpps[0].Primary_Contact__c == testContacts[0].Id); // FIRST CONTACT
        System.assert(testOpps[1].Primary_Contact__c == testContacts[5].Id); // ONLY PRIMARY REGARDLESS OF ROLE
        System.assert(testOpps[2].Primary_Contact__c == testContacts[3].Id); // FIRST PRIMARY BY LAST NAME
        System.assert(testOpps[3].Primary_Contact__c == testContacts[4].Id); // FIRST ADMIN PRIMARY
        System.assert(testOpps[4].Primary_Contact__c == testContacts[2].Id); // FIRST DECISION MAKER PRIMARY
    }

    /**
    * @description copyPrimaryContactToRolesTest - Test method for the OpportunityHelper.copyPrimaryContactToRoles method
    */
    public static testmethod void copyPrimaryContactToRolesTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','copyPrimaryContactToRoles', true);

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 1);
        insert testAccounts;

        // CREATE TEST CONTACTS
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', false, 6);
        testContacts[0].AccountId = testAccounts[0].Id;
        testContacts[0].LastName = 'Allen';
        testContacts[1].AccountId = testAccounts[0].Id;        
        testContacts[1].LastName = 'Brenneman';
        testContacts[2].AccountId = testAccounts[0].Id;
        testContacts[2].LastName = 'Couch';
        testContacts[3].AccountId = testAccounts[0].Id;
        testContacts[3].LastName = 'Dennis';
        testContacts[4].AccountId = testAccounts[0].Id;
        testContacts[4].LastName = 'Englemann';
        testContacts[5].AccountId = testAccounts[0].Id;
        testContacts[5].LastName = 'Fredrick';
        insert testContacts;

        // UPDATE ACCOUNT CONTACT RELATIONS
        List<AccountContactRelation> testRelations = [SELECT AccountId, ContactId, IsPrimary__c, Roles FROM AccountContactRelation];
        System.assert(testRelations.size() == 6);

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpps = TestingUtility.createSObjectList('Opportunity', false, 5);
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].Type = 'Existing Business';
        testOpps[1].AccountId = testAccounts[0].Id;
        testOpps[1].Type = 'Existing Business';
        testOpps[2].AccountId = testAccounts[0].Id;
        testOpps[2].Type = 'Existing Business';
        testOpps[3].AccountId = testAccounts[0].Id;
        testOpps[3].Type = 'Renewal';
        testOpps[4].AccountId = testAccounts[0].Id;
        testOpps[4].Type = 'Renewal';

        Test.startTest();

        // INSERT TEST OPP 1
        insert testOpps[0];

        // UPDATE CONTACT RELATIONS
        testRelations[5].Roles = 'Technical Buyer';
        testRelations[5].IsPrimary__c = true;
        update testRelations[5];

        // INSERT TEST OPP 2
        insert testOpps[1];

        // UPDATE CONTACT RELATIONS
        testRelations[3].Roles = 'Economic Buyer';
        testRelations[3].IsPrimary__c = true;
        update testRelations[3];
        
        // INSERT TEST OPP 3
        insert testOpps[2];

        // UPDATE CONTACT RELATIONS
        testRelations[4].Roles = 'Admin';
        testRelations[4].IsPrimary__c = true;
        update testRelations[4];
        
        // INSERT TEST OPP 4
        insert testOpps[3];

        // UPDATE CONTACT RELATIONS
        testRelations[2].Roles = 'Decision Maker';
        testRelations[2].IsPrimary__c = true;
        update testRelations[2];
        
        // INSERT TEST OPP 5
        insert testOpps[4];

        Test.stopTest();

        // RELOAD OPPS AND TEST FOR CORRECT DATA
        List<OpportunityContactRole> oppContactRoles = [SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId IN :testOpps AND IsPrimary = true];
        System.assert(oppContactRoles.size() == 5);
        System.assert(oppContactRoles[0].ContactId == testContacts[0].Id); // FIRST CONTACT
        System.assert(oppContactRoles[1].ContactId == testContacts[5].Id); // ONLY PRIMARY REGARDLESS OF ROLE
        System.assert(oppContactRoles[2].ContactId == testContacts[3].Id); // FIRST PRIMARY BY LAST NAME
        System.assert(oppContactRoles[3].ContactId == testContacts[4].Id); // FIRST ADMIN PRIMARY
        System.assert(oppContactRoles[4].ContactId == testContacts[2].Id); // FIRST DECISION MAKER PRIMARY
    }

    /**
    * @description setPrimaryContactCountTest - Test method for the OpportunityHelper.setPrimaryContactCount method
    */
    public static testmethod void setPrimaryContactCountTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setPrimaryContactCount', true);

        Test.startTest();

        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';  
        testAccounts[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
        testAccounts[0].mrr_Active_MRR__c = 100.00;                     
        insert testAccounts;

        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', false, 2);  
        testContacts[0].LastName = 'Smith';  
        testContacts[1].LastName = 'Roberts';           
        insert testContacts;

        // CREATE TEST OPPS
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].Type = 'Existing Business';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[1].AccountId = testAccounts[0].Id;
        testOpportunities[1].StageName = '0 - Qualification';
        testOpportunities[1].Type = 'Renewal';
        testOpportunities[1].CloseDate = Date.today();
        insert testOpportunities;

        ///// TEST ONLY FOR METHOD CODE COVERAGE
        ///// QUEUEABLE CODE WILL BE COVERED BY Queueable_UpdateOppPrimaryCountTest
        ///// THE ACTUAL COUNT LOGIC WILL BE COVERED BY AccountContactUtilitiesTest

        Test.stopTest();
    }

    /**
    * @description populateSalesforceAcct - Test method for the OpportunityHelper.populateSalesforceAcct method
    */ 
    public static testmethod void testPopulateSalesforceAcct() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','populateSalesforceAcct', true);

        List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 1);
        insert testAccounts;

        List<Salesforce_Account__c> testSalesforceAccounts = TestingUtility.createSObjectList('Salesforce_Account__c', false, 2);
        testSalesforceAccounts[0].Account__c = testAccounts[0].Id;
        testSalesforceAccounts[1].Account__c = testAccounts[0].Id;
        insert testSalesforceAccounts[0]; // INSERT ONLY ONE RECORD

        List<Opportunity> testOpps = TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[1].AccountId = testAccounts[0].Id;

        Test.startTest();

        insert testOpps[0];

        // REFRESH FIRST OPP RECORD, TEST THAT THE OPP IS LINKED TO THE ONLY SALESFORCE ACCOUNT
        testOpps[0] = [SELECT Id, Salesforce_Account__c FROM Opportunity WHERE Id = :testOpps[0].Id];
        System.assert(testOpps[0].Salesforce_Account__c == testSalesforceAccounts[0].Id);

        // INSERT SECOND SALESFORCE ACCOUNT RECORD
        insert testSalesforceAccounts[1]; // INSERT ONLY ONE RECORD

        // INSERT SECOND OPPORTUNITY AND TEST THAT ITS LINKED TO THE SECOND SALESFORCE ACCOUNT RECORD
        insert testOpps[1];
        testOpps[1] = [SELECT Id, Salesforce_Account__c FROM Opportunity WHERE Id = :testOpps[1].Id];
        System.assert(testOpps[1].Salesforce_Account__c == testSalesforceAccounts[1].Id);

        Test.stopTest();
    }

    /**
    * @description testCreateAssetsFromLineItems - Test method for the OpportunityHelper.createAssetsFromLineItems method
    */ 
    public static testmethod void testCreateAssetsFromLineItems() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','createAssetsFromLineItems', true);

        Account testAccount = new Account();
        testAccount.Name = 'test account';
        insert testAccount;

        Opportunity opp = new Opportunity();
        opp.Name = 'PS Opp';
        opp.AccountId = testAccount.Id;
        opp.Type = 'New Business';
        opp.LeadSource = 'Inbound';
        opp.StageName = '0 - Qualification';
        opp.CloseDate = System.today();
        insert opp;

        Product2 prod = new Product2();
        prod.Name = 'TestProduct';
        prod.ProductCode = 'TP1';
        prod.LOB__c = 'Services';
        prod.FY16_Revenue_Type__c = 'Non-Recurring';
        insert prod;

        Product2 prod2 = new Product2();
        prod2.Name = 'TestProduct 2';
        prod2.ProductCode = 'TP2';
        prod2.FY16_Revenue_Type__c = 'Recurring';
        insert prod2;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry entry = new PricebookEntry(Product2Id = prod.Id, Pricebook2Id = pricebookId, UnitPrice = 200, IsActive = true);
        insert entry;
        PricebookEntry entry2 = new PricebookEntry(Product2Id = prod2.Id, Pricebook2Id = pricebookId, UnitPrice = 100, IsActive = true);
        insert entry2;

        Test.startTest();

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.PricebookEntryId = entry.Id;
        oli.OpportunityId = opp.Id;
        oli.UnitPrice = 20.00;
        oli.Quantity = 1;
        oli.ServiceDate = System.today();
        olis.add(oli);

        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2.PricebookEntryId = entry2.Id;
        oli2.OpportunityId = opp.Id;
        oli2.UnitPrice = 2000.00;
        oli2.Quantity = 1;
        oli2.ServiceDate = System.today();
        oli2.Product_End_Date__c = System.today().addMonths(12);
        olis.add(oli2);
        insert olis;

        opp.Sales_Ops_Approved__c = true;
        update opp;

        // CHECK FOR NEW ASSET
        List<Asset> newAssets = [SELECT Id, Name, Quantity, Price, Product2Id, OLI_Id__c FROM Asset WHERE Related_Oppty__c = :opp.Id];
        System.assert(newAssets != null && newAssets.size() == 2);
        for(Asset asset : newAssets){
            if(asset.Product2Id == prod.Id && asset.OLI_ID__c == oli.Id){
                System.assert(asset.Name == prod.Name);
                System.assert(asset.Quantity == oli.Quantity);
                System.assert(asset.Price == oli.UnitPrice);
            }
            else if(asset.Product2Id == prod2.Id && asset.OLI_ID__c == oli2.Id){
                System.assert(asset.Name == prod2.Name);
                System.assert(asset.Quantity == oli2.Quantity);
                System.assert(asset.Price == oli2.UnitPrice);
            }
        }

        Test.stopTest();
    }

    /**
    * @description testUpdateReferringPartnerFields - Test method for the OpportunityHelper.updateReferringPartnerFields method
    */ 
    public static testmethod void testUpdateReferringPartnerFields(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','updateReferringPartnerFields', true);

        // CREATE TEST USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User apacTeamUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', 
        FirstName = 'Lead', LastName = 'Manager', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Team_2__c = 'APAC - CS');
        insert apacTeamUser;

        // CREATE TEST ACCOUNTS
        Account testAccount1 = new Account(Name = 'Test Opp Account');
        Account testAccount2 = new Account(Name = 'Test Partner Account');
        Account testAccount3 = new Account(Name = 'Test Partner Team Account', OwnerId = apacTeamUser.Id);
        insert new List<Account>{ testAccount1, testAccount2, testAccount3 };

        // SET ACCOUNT ID FOR CUSTOM METADATA
        TestPartnerAccountId = testAccount2.Id;

        Test.startTest();

        // CREATE TEST OPP
        Opportunity opp = new Opportunity();
        opp.Name = 'PS Opp';
        opp.AccountId = testAccount1.Id;
        opp.Type = 'New Business';
        opp.StageName = '0 - Qualification';
        opp.CloseDate = Date.today();//.addDays(60);
        opp.Customer_Implementation_Type__c = 'Self';
        opp.Referring_Partner_Primary__c = testAccount2.Id;
        insert opp;

        // TEST FOR CORRECT PARTNER REP
        opp = [SELECT Id, Referring_Partner_Primary__c, Partner_Rep__c, Team_2__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(opp != null);
        System.assert(opp.Partner_Rep__c == 'Account Test Partner');

        // UPDATE OPP
        opp.Team_2__c = 'APAC - CS';
        opp.Referring_Partner_Primary__c = testAccount3.Id;
        update opp;

        // TEST FOR CORRECT PARTNER REP
        opp = [SELECT Id, Referring_Partner_Primary__c, Partner_Rep__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(opp != null);

        // CLOSE WIN OPP AND SAVE
        opp.StageName = 'Closed Won'; // WILL RECOPY THE TEAM FROM THE OWNER ON CLOSE WON
        update opp;

        // TEST FOR CORRECT PARTNER REP
        opp = [SELECT Id, Referring_Partner_Primary__c, Partner_Rep__c FROM Opportunity WHERE Id = :opp.Id];
        System.assert(opp != null);
        System.assert(opp.Partner_Rep__c == 'Unmanaged');

        Test.stopTest();
    }

    /**
    * @description testSetAmendmentCurrentMRR - Test method for the OpportunityHelper.setAmendmentCurrentMRR method
    */ 
    public static testmethod void testSetAmendmentCurrentMRR(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setAmendmentCurrentMRR', true);

        // TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account');
        insert testAccount;

        // TEST OPP
        Opportunity testOpp = (Opportunity)TestingUtility.createSObject('Opportunity', false, 1);
        testOpp.AccountId = testAccount.Id;
        testOpp.Type = 'New Business';
        insert testOpp;       

        // TEST PRODUCT
        Product2 testProduct = (Product2)TestingUtility.createSObject('Product2');
        testProduct.Name = 'Test Product';
        testProduct.Family = 'Conga Composer Licenses';
        testProduct.ProductCode = 'TP1';
        testProduct.Product_Line__c = 'Conga Composer';
        testProduct.FY16_Revenue_Type__c = 'Recurring';
        insert testProduct;

        // TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract');
        testContract.AccountId = testAccount.Id;
        testContract.Status = 'Draft';
        testContract.StartDate = Date.today().addDays(30);
        testContract.ContractTerm = 12;
        testContract.SBQQ__Opportunity__c = testOpp.Id;
        insert testContract;

        // TEST SUBSCRIPTION
        SBQQ__Subscription__c testSubscription = (SBQQ__Subscription__c)TestingUtility.createSObject('SBQQ__Subscription__c');
        testSubscription.SBQQ__Account__c = testAccount.Id;
        testSubscription.SBQQ__Contract__c = testContract.Id;
        testSubscription.SBQQ__Product__c = testProduct.Id;
        testSubscription.SBQQ__SubscriptionStartDate__c = System.today();
        testSubscription.SBQQ__SubscriptionEndDate__c = System.today().addDays(180);
        testSubscription.SBQQ__Quantity__c = 5;
        testSubscription.SBQQ__NetPrice__c = 350;
        insert testSubscription;

        Test.startTest();

        // NEW TEST AMENDMENT OPP
        Opportunity testAmendOpp = (Opportunity)TestingUtility.createSObject('Opportunity', false, 1);
        testAmendOpp.AccountId = testAccount.Id;
        testAmendOpp.Type = 'Existing Business';
        testAmendOpp.SBQQ__AmendedContract__c = testContract.Id;
        insert testAmendOpp; 

        Test.stopTest();

        // TEST FOR CORRECT DATA
        testAmendOpp = [SELECT Id, Current_Composer_Ave_MRR__c FROM Opportunity WHERE Id = :testAmendOpp.Id];
        System.assert(testAmendOpp.Current_Composer_Ave_MRR__c > 0);
    }

    /**
    * @description updateOnboardingSpecialistTest - Test method for the updateOnboardingSpecialist method
    */
    public static testmethod void updateOnboardingSpecialistTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','updateOnboardingSpecialist', true);

        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUserEMEA = new User(Alias = 'sales1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Sales', LastName = 'Person', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', Team_2__c = 'EMEA - CS', Geo__c = 'EMEA',
        UserName = 'sales1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert salesUserEMEA;

        User salesUserUS = new User(Alias = 'sales3', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Sales', LastName = 'Person3',
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', Team_2__c = 'Sales', Geo__c = 'AMER',
        UserName = 'sales3' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Mid Commercial');
        insert salesUserUS;

        // SET METADATA ONBOARDING SPECIALIST IDS
        OnboardingSpecialistId1 = salesUserEMEA.Id; 
        OnboardingSpecialistId2 = salesUserUS.Id;
        OnboardingSpecialistId3 = '00550000006ukCOAAY'; // DANIEL

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].BillingPostalCode = '36450';
        testAccounts[0].BillingCountry = 'United States';
        insert testAccounts;

        Test.startTest();

        // CREATE TEST OPPORTUNITY
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].Name = 'Test Opp 1';
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].OwnerId = salesUserEMEA.Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[1].Name = 'Test Opp 2';
        testOpportunities[1].AccountId = testAccounts[0].Id;
        testOpportunities[1].OwnerId = salesUserUS.Id;
        testOpportunities[1].StageName = '0 - Qualification';
        testOpportunities[1].CloseDate = Date.today();
        insert testOpportunities;

        // TEST FOR CORRECT Onboarding_SpecialistId__c
        testOpportunities = [SELECT Id, Onboarding_SpecialistId__c, Opportunity_Booking_Stamp__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities.size() == 2);
        System.assert(testOpportunities[0].Onboarding_SpecialistId__c == salesUserEMEA.Id); // EMEA TEAM
        System.assert(testOpportunities[1].Onboarding_SpecialistId__c == salesUserUS.Id); // ACCOUNT ZIP CODE    

        // MAKE QUALIFYING CHANGES TO OPPS
        testOpportunities[1].Onboarding_Specialist_OverrideId__c = OnboardingSpecialistId3;
        update testOpportunities;

        // TEST FOR CORRECT Onboarding_SpecialistId__c, 
        testOpportunities = [SELECT Id, Onboarding_SpecialistId__c, Opportunity_Booking_Stamp__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[1].Onboarding_SpecialistId__c == OnboardingSpecialistId3); // DEFAULT TO DANIEL

        Test.stopTest();
    }

    /**
    * @author jcdiaz@systemyc.com
    * @date 2019-03-28
    * @description Unit test for OpportunityHelper.setTeamStampFields method.
    */
    private static testmethod void setTeamStampFieldsInsertTest1() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setTeamStampFields', true);

        // GET TEST GEOS
        List<TM_Geo__c> testGeos = [SELECT Id FROM TM_Geo__c WHERE Name = 'AMER'];
        System.assert(testGeos.size() == 1);

        // GET TEST REGIONS
        List<TM_Region__c> testRegions = [SELECT Id FROM TM_Region__c WHERE Name = 'South West'];
        System.assert(testRegions.size() == 1);

        // GET TEST TERRITORIES
        List<TM_Territory__c> testTerritories = [SELECT Id FROM TM_Territory__c WHERE TM_RegionId__c IN :testRegions];
        System.assert(testTerritories.size() == 1);

        // GET TEST SEGMENTS
        List<TM_Segment__c> testSegments = [SELECT Id FROM TM_Segment__c];
        System.assert(testSegments.size() == 3);

        // create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com',
                                  EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                                  Team__c = 'US Corporate Sales', Segment__c = 'Mid Commercial');
        User salesUser2 = new User(Alias = 'admin2', Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person2', UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com',
                                   EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                                   Segment__c = 'Enterprise', Geo__c = 'EMEA', Team_2__c = 'Sales');
        insert new List<User>{ salesUser, salesUser2 };

        // create test account
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].TM_GeoId__c = testGeos[0].Id; // NA
        testAccounts[0].TM_RegionId__c = testRegions[0].Id; // South West
        testAccounts[0].TM_Segment_TerritoryId__c = testTerritories[0].Id; // California 1
        testAccounts[0].TM_SegmentId__c = testSegments[0].Id; // Enterprise
        testAccounts[0].BillingCountry = 'Spain';
        insert testAccounts;

        testAccounts[0].TM_Territory_ManagerId__c = salesUser2.Id;
        testAccounts[0].Customer_Success_Manager__c = salesUser.Id;
        update testAccounts;

        Test.startTest();

        // create test opportunity
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].OwnerId = salesUser.Id;
        testOpportunities[0].Bookings_OwnerId__c = salesUser.Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        insert testOpportunities;

        Opportunity testOpportunity = [SELECT Opportunity_Owner_Geo_Stamp__c, Team_2__c, Region_2__c, Territory__c, Opportunity_Segment_Stamp__c, CS_Division__c, 
                                              TM_Territory_ManagerId__c, Customer_Success_Manager__c, Opportunity_Booking_Stamp__c
                                       FROM Opportunity WHERE Id = :testOpportunities[0].Id LIMIT 1];
        System.assertEquals('EMEA', testOpportunity.Opportunity_Owner_Geo_Stamp__c);
        System.assertEquals('Sales', testOpportunity.Team_2__c);
        System.assertEquals('South West', testOpportunity.Region_2__c); 
        System.assertEquals('California 1', testOpportunity.Territory__c);
        System.assertEquals('Enterprise', testOpportunity.Opportunity_Segment_Stamp__c);
        System.assertEquals(salesUser2.Id, testOpportunity.TM_Territory_ManagerId__c);
        System.assertEquals('EMEA - ENTERPRISE - Sales', testOpportunity.Opportunity_Booking_Stamp__c);

        Test.stopTest();
    }

    /**
    * @author jcdiaz@systemyc.com
    * @date 2019-03-28
    * @description Unit test for OpportunityHelper.setTeamStampFields method.
    */
    @isTest
    private static void setTeamStampFieldsInsertTest2() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setTeamStampFields', true);

        // GET TEST GEOS
        List<TM_Geo__c> testGeos = [SELECT Id FROM TM_Geo__c WHERE Name = 'AMER'];
        System.assert(testGeos.size() == 1);

        // GET TEST REGIONS
        List<TM_Region__c> testRegions = [SELECT Id FROM TM_Region__c WHERE Name = 'South West'];
        System.assert(testRegions.size() == 1);

        // GET TEST TERRITORIES
        List<TM_Territory__c> testTerritories = [SELECT Id FROM TM_Territory__c WHERE TM_RegionId__c IN :testRegions];
        System.assert(testTerritories.size() == 1);

        // GET TEST SEGMENTS
        List<TM_Segment__c> testSegments = [SELECT Id FROM TM_Segment__c];
        System.assert(testSegments.size() == 3);

        // create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User']; 
        User salesUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com',
                                  EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', 
                                  Segment__c = 'Enterprise', Geo__c = 'EMEA', Team_2__c = 'Sales');

        User accountingUser = new User(Alias = 'admin2', Email = 'salesforce@conga.com', FirstName = 'Accounting', LastName = 'Person', UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', 
                                       EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', 
                                       Segment__c = 'Mid Commercial', Geo__c = 'APAC', Team_2__c = 'Accounting');
        insert new List<User>{ salesUser, accountingUser };

        // create test account
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].TM_GeoId__c = testGeos[0].Id; // South West        
        testAccounts[0].TM_RegionId__c = testRegions[0].Id; // South West
        testAccounts[0].TM_Segment_TerritoryId__c = testTerritories[0].Id; // California 1
        testAccounts[0].TM_SegmentId__c = testSegments[1].Id; // Mid Commercial
        testAccounts[0].BillingCountry = 'Spain';
        insert testAccounts;

        testAccounts[0].TM_Territory_ManagerId__c = accountingUser.Id;
        testAccounts[0].Customer_Success_Manager__c = salesUser.Id;
        update testAccounts;

        Test.startTest();

        // create test opportunity
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].OwnerId = accountingUser.Id;
        testOpportunities[0].Bookings_OwnerId__c = accountingUser.Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        insert testOpportunities;

        Opportunity testOpportunity = [SELECT Opportunity_Owner_Geo_Stamp__c, Team_2__c, Region_2__c, Territory__c, Opportunity_Segment_Stamp__c, CS_Division__c,
                                              TM_Territory_ManagerId__c, Customer_Success_ManagerId__c, Opportunity_Booking_Stamp__c 
                                       FROM Opportunity WHERE Id = :testOpportunities[0].Id LIMIT 1];
        System.assertEquals('APAC', testOpportunity.Opportunity_Owner_Geo_Stamp__c);
        System.assertEquals('Accounting', testOpportunity.Team_2__c);
        System.assertEquals('South West', testOpportunity.Region_2__c); 
        System.assertEquals('California 1', testOpportunity.Territory__c);
        System.assertEquals('Mid Commercial', testOpportunity.Opportunity_Segment_Stamp__c);
        System.assertEquals(accountingUser.Id, testOpportunity.TM_Territory_ManagerId__c);
        System.assertEquals('Accounting', testOpportunity.Opportunity_Booking_Stamp__c);

        Test.stopTest();
    }  


    /**
    * @author jcdiaz@systemyc.com
    * @date 2019-04-01
    * @description Unit test for OpportunityHelper.setTeamStampFields method.
    */
    @isTest
    private static void setTeamStampFieldsUpdateTest1() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setTeamStampFields', true);

        // GET TEST GEOS
        List<TM_Geo__c> testGeos = [SELECT Id FROM TM_Geo__c WHERE Name = 'AMER'];
        System.assert(testGeos.size() == 1);        

        // GET TEST REGIONS
        List<TM_Region__c> testRegions = [SELECT Id FROM TM_Region__c WHERE Name = 'South West'];
        System.assert(testRegions.size() == 1);

        // GET TEST TERRITORIES
        List<TM_Territory__c> testTerritories = [SELECT Id FROM TM_Territory__c WHERE TM_RegionId__c IN :testRegions];
        System.assert(testTerritories.size() == 1);

        // GET TEST SEGMENTS
        List<TM_Segment__c> testSegments = [SELECT Id FROM TM_Segment__c];
        System.assert(testSegments.size() == 3);

        // create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser1 = new User(Alias = 'sales1', Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person 1', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', 
                                   EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                                   Segment__c = 'Enterprise', Geo__c = 'EMEA', Team_2__c = 'Sales');
        User salesUser2 = new User(Alias = 'sales2', Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person 2', UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', 
                                   EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', 
                                   Segment__c = 'Growth', Geo__c = 'APAC', Team_2__c = 'Sales');      
        User accountingUser = new User(Alias = 'acc1', Email = 'salesforce@conga.com', FirstName = 'Accounting', LastName = 'Person', UserName = 'testUser3' + UserInfo.getOrganizationId() + '@testorg.com', 
                                       EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', 
                                       Segment__c = 'Mid Commercial', Geo__c = 'APAC', Team_2__c = 'Accounting');
        insert new List<User>{ salesUser1, salesUser2, accountingUser };

        // create test account
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].TM_GeoId__c = testGeos[0].Id; // South West        
        testAccounts[0].TM_RegionId__c = testRegions[0].Id; // South West
        testAccounts[0].TM_Segment_TerritoryId__c = testTerritories[0].Id; // California 1
        testAccounts[0].TM_SegmentId__c = testSegments[2].Id; // Growth
        testAccounts[0].BillingCountry = 'Spain';
        insert testAccounts;

        testAccounts[0].TM_Territory_ManagerId__c = accountingUser.Id;
        testAccounts[0].Customer_Success_Manager__c = salesUser1.Id;
        update testAccounts;

        Test.startTest();

        // create test opportunity
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].Bookings_OwnerId__c = accountingUser.Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        insert testOpportunities;        

        testOpportunities[0].Bookings_OwnerId__c = salesUser2.Id;
        testOpportunities[0].StageName = 'Closed Won';
        update testOpportunities;

        Opportunity testOpportunity = [SELECT Opportunity_Owner_Geo_Stamp__c, Team_2__c, Region_2__c, Territory__c, Opportunity_Segment_Stamp__c, CS_Division__c, 
                                              TM_Territory_ManagerId__c, Customer_Success_ManagerId__c, Opportunity_Booking_Stamp__c, Type, Sales_Ops_Approved__c
                                       FROM Opportunity WHERE Id = :testOpportunities[0].Id LIMIT 1];
        System.assertEquals('APAC', testOpportunity.Opportunity_Owner_Geo_Stamp__c);
        System.assertEquals('Sales', testOpportunity.Team_2__c);
        System.assertEquals('South West', testOpportunity.Region_2__c); 
        System.assertEquals('California 1', testOpportunity.Territory__c);
        System.assertEquals('Growth', testOpportunity.Opportunity_Segment_Stamp__c);
        System.assertEquals(accountingUser.Id, testOpportunity.TM_Territory_ManagerId__c);
        System.assertEquals('APAC - COMMERCIAL - Sales', testOpportunity.Opportunity_Booking_Stamp__c);

        Test.stopTest();
    }

    /**
    * @author jcdiaz@systemyc.com
    * @date 2019-04-01
    * @description Unit test for OpportunityHelper.setTeamStampFields method.
    */
    @isTest
    private static void setTeamStampFieldsUpdateTest2() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setTeamStampFields', true);

        // GET TEST GEOS
        List<TM_Geo__c> testGeos = [SELECT Id FROM TM_Geo__c WHERE Name = 'AMER'];
        System.assert(testGeos.size() == 1);        

        // GET TEST REGIONS
        List<TM_Region__c> testRegions = [SELECT Id FROM TM_Region__c WHERE Name = 'South West'];
        System.assert(testRegions.size() == 1);

        // GET TEST TERRITORIES
        List<TM_Territory__c> testTerritories = [SELECT Id FROM TM_Territory__c WHERE TM_RegionId__c IN :testRegions];
        System.assert(testTerritories.size() == 1);

        // GET TEST SEGMENTS
        List<TM_Segment__c> testSegments = [SELECT Id FROM TM_Segment__c];
        System.assert(testSegments.size() == 3);

        // create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser1 = new User(Alias = 'sales1', Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person 1', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', 
                                   EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', 
                                   Segment__c = 'Enterprise', Geo__c = 'EMEA', Team_2__c = 'Sales');
        User salesUser2 = new User(Alias = 'sales2', Email = 'salesforce@conga.com', FirstName = 'Sales', LastName = 'Person 2', UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', 
                                   EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', 
                                   Segment__c = 'Other', Geo__c = 'APAC', Team_2__c = 'Sales');
        insert new List<User>{ salesUser1, salesUser2 };

        // create test account
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].TM_GeoId__c = testGeos[0].Id; // South West        
        testAccounts[0].TM_RegionId__c = testRegions[0].Id; // South West
        testAccounts[0].TM_Segment_TerritoryId__c = testTerritories[0].Id; // California 1
        testAccounts[0].TM_SegmentId__c = testSegments[0].Id; // Enterprise
        testAccounts[0].BillingCountry = 'Spain';
        insert testAccounts;

        testAccounts[0].TM_Territory_ManagerId__c = salesUser1.Id;
        testAccounts[0].Customer_Success_Manager__c = salesUser1.Id;
        update testAccounts;

        Test.startTest();

        // create test opportunity
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].Bookings_OwnerId__c = salesUser2.Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        insert testOpportunities;

        testOpportunities[0].StageName = 'Closed Won';
        testOpportunities[0].Bookings_OwnerId__c = salesUser1.Id;
        update testOpportunities;

        Opportunity testOpportunity = [SELECT Opportunity_Owner_Geo_Stamp__c, Team_2__c, Region_2__c, Territory__c, Opportunity_Segment_Stamp__c, CS_Division__c,
                                              TM_Territory_ManagerId__c, Customer_Success_ManagerId__c, Opportunity_Booking_Stamp__c
                                       FROM Opportunity WHERE Id = :testOpportunities[0].Id LIMIT 1];

        // check that field values for stamp fields didn't change.
        System.assertEquals('EMEA', testOpportunity.Opportunity_Owner_Geo_Stamp__c);
        System.assertEquals('Sales', testOpportunity.Team_2__c);
        System.assertEquals('South West', testOpportunity.Region_2__c); 
        System.assertEquals('California 1', testOpportunity.Territory__c);
        System.assertEquals('Enterprise', testOpportunity.Opportunity_Segment_Stamp__c);
        System.assertEquals(salesUser1.Id, testOpportunity.TM_Territory_ManagerId__c);
        System.assertEquals('EMEA - ENTERPRISE - Sales', testOpportunity.Opportunity_Booking_Stamp__c);

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20190429
    * @description setConvertedOppChannelSourceTest - Test for the setConvertedOppChannelSource trigger method
    */
    public static testmethod void setConvertedOppChannelSourceTest() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setConvertedOppChannelSource', true);

        // CREATE A TEST LEADS
        Lead testLead = new Lead(LastName = 'Test1', Company = 'Test1 ABC', Product_Interest__c = 'Conga Batch', LeadSource = 'Advertisement', 
                                  Channel_Source_2__c = 'Digital', Country = 'United States');
        insert testLead;

        // GET A CONVERTED LEAD STATUS
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];

        Test.startTest();

        // SET UP CONVERSION
        Database.LeadConvert lead1Convert = new Database.LeadConvert();
        lead1Convert.setLeadId(testLead.Id);
        lead1Convert.setConvertedStatus(convertStatus.MasterLabel);

        // CONVERT AND CHECK FOR SUCCESS
        Database.LeadConvertResult leadResult = Database.convertLead(lead1Convert);
        System.assert(leadResult.isSuccess());

        // GET OPPS AND TEST FOR CORRECT DATA
        List<Opportunity> testOpps = [SELECT Id, Oppty_Channel_Source_2__c FROM Opportunity WHERE Id = :leadResult.getOpportunityId()];
        System.assert(testOpps.size() == 1);
        System.assert(testOpps[0].Oppty_Channel_Source_2__c == testLead.Channel_Source_2__c);

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20200727
    * @description setOppProductInterestTest - Test for the setOppProductInterest trigger method
    */
    public static testmethod void setOppProductInterestTest() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','setOppProductInterest', true);

        // GET LEAD PRODUCT INTEREST TO OPP PRODUCT INTEREST MAPPING METEDATA
        Map<String, String> leadProdToOppProdMappings = new Map<String, String>();
        for(Lead_Opp_Product_Interest_Mappings__mdt mapping : [SELECT Lead_Product_Interest__c, Opp_Product_Interest__c FROM Lead_Opp_Product_Interest_Mappings__mdt]){
            leadProdToOppProdMappings.put(mapping.Lead_Product_Interest__c, mapping.Opp_Product_Interest__c);
        }
        System.assert(!leadProdToOppProdMappings.isEmpty());

        // CREATE A TEST LEADS
        Lead testLead = new Lead(LastName = 'Test1', Company = 'Test1 ABC', Product_Interest__c = 'Conga Batch', Country = 'United States');
        insert testLead;

        // GET A CONVERTED LEAD STATUS
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];

        Test.startTest();

        // SET UP CONVERSION
        Database.LeadConvert lead1Convert = new Database.LeadConvert();
        lead1Convert.setLeadId(testLead.Id);
        lead1Convert.setConvertedStatus(convertStatus.MasterLabel);

        // CONVERT AND CHECK FOR SUCCESS
        Database.LeadConvertResult leadResult = Database.convertLead(lead1Convert);
        System.assert(leadResult.isSuccess());

        // GET OPPS AND TEST FOR CORRECT DATA
        List<Opportunity> testOpps = [SELECT Id, Product_of_Interest__c FROM Opportunity WHERE Id = :leadResult.getOpportunityId()];
        System.assert(testOpps.size() == 1);
        System.debug(leadProdToOppProdMappings.get('Conga Batch'));
        System.debug(testOpps[0].Product_of_Interest__c);
        System.assert(testOpps[0].Product_of_Interest__c == leadProdToOppProdMappings.get('Conga Batch'));

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20190709
    * @description updatePartnerExpertiseScoreTest - Test for the updatePartnerExpertiseScore trigger method
    */
    public static testmethod void updatePartnerExpertiseScoreTest() {
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','updatePartnerExpertiseScore', true);

        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id FROM PricebookEntry];      
        System.assert(!testPricebookEntries.isEmpty());

        // CREATE TEST ACCOUNTS
        Id partnerRecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 5);
        // THREE STAR PARTNER       
        testAccounts[1].RecordTypeId = partnerRecordTypeId;
        testAccounts[1].Partner_Expert__c = 'Conga Grid;Conga Automation;Conga Composer';
        testAccounts[1].Partner_Specialist__c = 'Conga Collaborate';
        testAccounts[1].Partner_Certified__c = 'Conga Automation';
        // TWO STAR PARTNER
        testAccounts[2].RecordTypeId = partnerRecordTypeId;
        testAccounts[2].Partner_Expert__c = 'Conga Composer;Conga AI';
        testAccounts[2].Partner_Specialist__c = 'Conga Collaborate;Conga Grid';
        testAccounts[2].Partner_Certified__c = 'Conga Automation';
        // ONE STAR PARNER
        testAccounts[3].RecordTypeId = partnerRecordTypeId;
        testAccounts[3].Partner_Expert__c = 'Conga Grid;Conga Services;Conga Support';
        testAccounts[3].Partner_Specialist__c = 'Conga AI';
        testAccounts[3].Partner_Certified__c = 'Conga Composer';
        // NO STAR PARTNER
        testAccounts[4].RecordTypeId = partnerRecordTypeId;
        testAccounts[4].Partner_Expert__c = 'Conga Services;Conga Support';
        testAccounts[4].Partner_Specialist__c = 'Conga Automation';
        testAccounts[4].Partner_Certified__c = 'Conga Courier';
        insert testAccounts;

        // TEST OPP
        List<Opportunity> testOpps = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 6);
        testOpps[0].Name = 'No Line Items Opp';
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[1].Name = 'No Implementation Partner Opp';
        testOpps[1].AccountId = testAccounts[0].Id;
        testOpps[2].Name = 'Three Star Partner Opp';
        testOpps[2].AccountId = testAccounts[0].Id;
        testOpps[3].Name = 'Two Star Partner Opp';
        testOpps[3].AccountId = testAccounts[0].Id;
        testOpps[4].Name = 'One Star Partner Opp';
        testOpps[4].AccountId = testAccounts[0].Id;
        testOpps[5].Name = 'No Star Partner Opp';
        testOpps[5].AccountId = testAccounts[0].Id;    
        insert testOpps;

        Test.startTest();       

        // ENTRY 0 - GRID
        // ENTRY 1 - COMPOSER
        // ENTRY 2 - AI

        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', false, 11);
        testOppItems[0].OpportunityId = testOpps[1].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[0].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[0].Product_End_Date__c = Date.newInstance(2018, 12, 31);

        testOppItems[1].OpportunityId = testOpps[1].Id;
        testOppItems[1].Quantity = 5;
        testOppItems[1].UnitPrice = 500;
        testOppItems[1].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[1].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[1].Product_End_Date__c = Date.newInstance(2019, 12, 30);

        testOppItems[2].OpportunityId = testOpps[2].Id;
        testOppItems[2].Quantity = 5;
        testOppItems[2].UnitPrice = 500;
        testOppItems[2].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[2].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[2].Product_End_Date__c = Date.newInstance(2019, 12, 30);

        testOppItems[3].OpportunityId = testOpps[2].Id;
        testOppItems[3].Quantity = 5;
        testOppItems[3].UnitPrice = 500;
        testOppItems[3].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[3].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[3].Product_End_Date__c = Date.newInstance(2019, 12, 30);

        testOppItems[4].OpportunityId = testOpps[3].Id;
        testOppItems[4].Quantity = 5;
        testOppItems[4].UnitPrice = 500;
        testOppItems[4].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[4].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[4].Product_End_Date__c = Date.newInstance(2019, 12, 30);

        testOppItems[5].OpportunityId = testOpps[3].Id;
        testOppItems[5].Quantity = 5;
        testOppItems[5].UnitPrice = 500;
        testOppItems[5].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[5].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[5].Product_End_Date__c = Date.newInstance(2019, 12, 30);
        
        testOppItems[6].OpportunityId = testOpps[4].Id;
        testOppItems[6].Quantity = 5;
        testOppItems[6].UnitPrice = 500;
        testOppItems[6].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[6].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[6].Product_End_Date__c = Date.newInstance(2019, 12, 30);

        testOppItems[7].OpportunityId = testOpps[4].Id;
        testOppItems[7].Quantity = 5;
        testOppItems[7].UnitPrice = 500;
        testOppItems[7].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[7].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[7].Product_End_Date__c = Date.newInstance(2019, 12, 30);
        
        testOppItems[8].OpportunityId = testOpps[4].Id;
        testOppItems[8].Quantity = 15;
        testOppItems[8].UnitPrice = 375;
        testOppItems[8].PricebookEntryId = testPricebookEntries[2].Id;
        testOppItems[8].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[8].Product_End_Date__c = Date.newInstance(2019, 12, 30);

        testOppItems[9].OpportunityId = testOpps[5].Id;
        testOppItems[9].Quantity = 3;
        testOppItems[9].UnitPrice = 150;
        testOppItems[9].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[9].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[9].Product_End_Date__c = Date.newInstance(2019, 12, 30);

        testOppItems[10].OpportunityId = testOpps[5].Id;
        testOppItems[10].Quantity = 6;
        testOppItems[10].UnitPrice = 675;
        testOppItems[10].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[10].ServiceDate = Date.newInstance(2018, 1, 1);
        testOppItems[10].Product_End_Date__c = Date.newInstance(2019, 12, 30);
        insert testOppItems;

        testOpps[0].ImplementationPartnerPrimary__c = testAccounts[1].Id; // OPP WITHOUT LINE ITEMS
        testOpps[1].ImplementationPartnerPrimary__c = null; // OPP WITH LINE ITEMS, BUT NO PRIMARY IMPLEMENTATION PARTNER
        testOpps[2].ImplementationPartnerPrimary__c = testAccounts[1].Id; // OPP WITH ITEMS
        testOpps[3].ImplementationPartnerPrimary__c = testAccounts[2].Id; // OPP WITH ITEMS
        testOpps[4].ImplementationPartnerPrimary__c = testAccounts[3].Id; // OPP WITH ITEMS
        testOpps[5].ImplementationPartnerPrimary__c = testAccounts[4].Id; // OPP WITH ITEMS        
        update testOpps; 

        // RELOAD OPPS AND TEST FOR CORRECT DATA
        testOpps = [SELECT Id, Partner_Expertise_Score_Text__c FROM Opportunity WHERE Id IN :testOpps];
        System.assert(testOpps.size() == 6);
        System.assert(String.isBlank(testOpps[0].Partner_Expertise_Score_Text__c));
        System.assert(String.isBlank(testOpps[1].Partner_Expertise_Score_Text__c));
        System.assert(testOpps[2].Partner_Expertise_Score_Text__c == 'Master');
        System.assert(testOpps[3].Partner_Expertise_Score_Text__c == 'Specialist');
        System.assert(testOpps[4].Partner_Expertise_Score_Text__c == 'Certified');
        System.assert(testOpps[5].Partner_Expertise_Score_Text__c == 'Uncertified');

        Test.stopTest();
    }

    /**
    * @description updateChildQuoteOwnersTest - Test method for the OpportunityHelper.updateChildQuoteOwners method
    */
    private static testmethod void updateChildQuoteOwnersTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','updateChildQuoteOwners', true);

        // CREATE TEST SALES USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', 
        FirstName = 'Sales', LastName = 'User', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpportunities[0].Name = 'Normal Opp';
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        insert testOpportunities;

        // CREATE TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = (List<SBQQ__Quote__c>)TestingUtility.createSObjectList('SBQQ__Quote__c', false, 1);
        testQuotes[0].SBQQ__Account__c = testAccounts[0].Id;
        testQuotes[0].SBQQ__Opportunity2__c = testOpportunities[0].Id;
        testQuotes[0].SBQQ__Primary__c = true;
        insert testQuotes;

        Test.startTest();

        // UPDATE OPP OWNER
        testOpportunities[0].OwnerId = salesUser.Id;
        update testOpportunities;

        // REFRESH QUOTE AND TEST FOR CORRECT DATA
        testQuotes = [SELECT Id, OwnerId FROM SBQQ__Quote__c WHERE Id IN :testQuotes];
        System.assert(testQuotes[0].OwnerId == salesUser.Id);

        Test.stopTest();
    }

    ////////////////////////// NEW VERSION OF THE PURCHASE ORDER REQUIRED SYNC CODE TO USE WHEN TESTED //////////////////////////
    /**
    * @description updatePurchaseOrderRequiredTest_ContractToOpp - Test method for the OpportunityHelper.updatePurchaseOrderRequired method
    */
    private static testmethod void updatePurchaseOrderRequiredTest_ContractToOpp(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','updatePurchaseOrderRequired', true);

        // CREATE TEST ACCOUNTS
        Account testAccount = (Account)TestingUtility.createSObject('Account', false, 1);
        insert testAccount;

        // TEST CONTRACT
        List<Contract> testContracts = (List<Contract>)TestingUtility.createSObjectList('Contract', false, 3);
        for(Contract testContract : testContracts){
            testContract.AccountId = testAccount.Id;
            testContract.Status = 'Draft';
            testContract.StartDate = Date.today().addDays(30);
            testContract.ContractTerm = 12;
            testContract.Purchase_Order_Required__c = true;
        }
        insert testContracts;

        Test.startTest();

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        for(Opportunity opp : testOpportunities){
            opp.AccountId = testAccount.Id;
            opp.StageName = '0 - Qualification';
            opp.CloseDate = Date.today();
        }
        testOpportunities[0].Name = 'Normal Amend Opp';
        testOpportunities[0].Type = 'Existing Business';
        testOpportunities[0].ContractId = testContracts[0].Id;
        testOpportunities[0].SBQQ__AmendedContract__c = testContracts[1].Id;

        testOpportunities[1].Name = 'Renewal Opp';
        testOpportunities[1].Type = 'Renewal';
        testOpportunities[1].ContractId = testContracts[0].Id;
        testOpportunities[1].SBQQ__RenewedContract__c = testContracts[2].Id;
        insert testOpportunities;

        // REFRESH OPPS AND TEST FOR CORRECT DATA
        testOpportunities = [SELECT Id, Purchase_Order_Required__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].Purchase_Order_Required__c == true);
        System.assert(testOpportunities[1].Purchase_Order_Required__c == true);        

        Test.stopTest();
    }

    ////////////////////////// NEW VERSION OF THE PURCHASE ORDER REQUIRED SYNC CODE TO USE WHEN TESTED //////////////////////////
    /**
    * @description updatePurchaseOrderRequiredTest_OppToContract - Test method for the OpportunityHelper.updatePurchaseOrderRequired method
    */
    private static testmethod void updatePurchaseOrderRequiredTest_OppToContract(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','updatePurchaseOrderRequired', true);

        // CREATE TEST ACCOUNTS
        Account testAccount = (Account)TestingUtility.createSObject('Account', false, 1);
        insert testAccount;

        // TEST CONTRACT
        List<Contract> testContracts = (List<Contract>)TestingUtility.createSObjectList('Contract', false, 3);
        for(Contract testContract : testContracts){
            testContract.AccountId = testAccount.Id;
            testContract.Status = 'Draft';
            testContract.StartDate = Date.today().addDays(30);
            testContract.ContractTerm = 12;
        }
        insert testContracts;

        Test.startTest();

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        for(Opportunity opp : testOpportunities){
            opp.AccountId = testAccount.Id;
            opp.StageName = '0 - Qualification';
            opp.CloseDate = Date.today();
        }
        testOpportunities[0].Name = 'Normal Amend Opp';
        testOpportunities[0].Type = 'Existing Business';
        testOpportunities[0].ContractId = testContracts[0].Id;
        testOpportunities[0].SBQQ__AmendedContract__c = testContracts[1].Id;

        testOpportunities[1].Name = 'Renewal Opp';
        testOpportunities[1].Type = 'Renewal';
        testOpportunities[1].ContractId = testContracts[0].Id;
        testOpportunities[1].SBQQ__RenewedContract__c = testContracts[2].Id;
        insert testOpportunities;

        // UPDATE OPPS
        testOpportunities[0].Purchase_Order_Required__c = true;
        testOpportunities[1].Purchase_Order_Required__c = true;
        update testOpportunities;

        // REFRESH CONTRACTS AND TEST FOR CORRECT DATA
        testContracts = [SELECT Id, Purchase_Order_Required__c FROM Contract WHERE Id IN :testContracts];
        System.assert(testContracts[0].Purchase_Order_Required__c == true);
        System.assert(testContracts[1].Purchase_Order_Required__c == true);
        System.assert(testContracts[2].Purchase_Order_Required__c == true);

        Test.stopTest();
    }

    ////////////////////////// OLD VERSION OF THE PURCHASE ORDER REQUIRED SYNC CODE. ABOVE METHOD IS THE NEW ONE TO USE WHEN TESTED //////////////////////////
    /**
    * @description copyPORequiredToParentContractTest - Test method for the OpportunityHelper.copyPORequiredToParentContract method
    */
    //private static testmethod void copyPORequiredToParentContractTest(){
    //    // ENSURE TRIGGER METHOD IS ENABLED
    //    TriggerHelper.TemporaryOverride('OpportunityHelper','copyPORequiredToParentContract', true);

    //    // CREATE TEST ACCOUNTS
    //    Account testAccount = (Account)TestingUtility.createSObject('Account', false, 1);
    //    insert testAccount;

    //    // TEST CONTRACT
    //    List<Contract> testContracts = (List<Contract>)TestingUtility.createSObjectList('Contract', false, 3);
    //    for(Contract testContract : testContracts){
    //        testContract.AccountId = testAccount.Id;
    //        testContract.Status = 'Draft';
    //        testContract.StartDate = Date.today().addDays(30);
    //        testContract.ContractTerm = 12;
    //    }
    //    insert testContracts;

    //    Test.startTest();

    //    // CREATE TEST OPPORTUNITIES
    //    List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
    //    for(Opportunity opp : testOpportunities){
    //        opp.AccountId = testAccount.Id;
    //        opp.StageName = '0 - Qualification';
    //        opp.CloseDate = Date.today();
    //    }
    //    testOpportunities[0].Name = 'Normal Amend Opp';
    //    testOpportunities[0].Type = 'Existing Business';
    //    testOpportunities[0].ContractId = testContracts[0].Id;
    //    testOpportunities[0].SBQQ__AmendedContract__c = testContracts[1].Id;

    //    testOpportunities[1].Name = 'Renewal Opp';
    //    testOpportunities[1].Type = 'Renewal';
    //    testOpportunities[1].ContractId = testContracts[0].Id;
    //    testOpportunities[1].SBQQ__RenewedContract__c = testContracts[2].Id;
    //    insert testOpportunities;

    //    // MAKE APPLICABLE CHANGE
    //    testOpportunities[0].Purchase_Order_Required__c = true;
    //    testOpportunities[1].Purchase_Order_Required__c = true;
    //    update testOpportunities;

    //    // REFRESH CONTRACTS AND TEST FOR CORRECT DATA
    //    testContracts = [SELECT Id, Purchase_Order_Required__c FROM Contract WHERE Id IN :testContracts];
    //    System.assert(testContracts[0].Purchase_Order_Required__c == true);
    //    System.assert(testContracts[1].Purchase_Order_Required__c == true);
    //    System.assert(testContracts[2].Purchase_Order_Required__c == true);

    //    Test.stopTest();
    //}

    /**
    * @description servicesCommissionRollupTest - Test method for the OpportunityHelper.servicesCommissionRollup method
    */
    private static testmethod void servicesCommissionRollupTest(){
        // ENSURE TRIGGER METHOD IS ENABLED
        TriggerHelper.TemporaryOverride('OpportunityHelper','servicesCommissionRollup', true);

        //// TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 5);
        testProducts[0].Name = 'Test Prod 1';
        testProducts[0].ProductCode = 'TP1';
        testProducts[0].FY16_Revenue_Type__c = 'Non-recurring';
        testProducts[0].Family = 'Professional Services';
        //
        testProducts[1].Name = 'Test Prod 2';
        testProducts[1].ProductCode = 'TP2';
        testProducts[1].FY16_Revenue_Type__c = 'Non-recurring';
        testProducts[1].Family = 'Novatus Contracts';
        //
        testProducts[2].Name = 'Test Prod 3';
        testProducts[2].ProductCode = 'TP3';
        testProducts[2].FY16_Revenue_Type__c = 'Non-recurring';
        testProducts[2].Family = 'Consulting';
        //
        testProducts[3].Name = 'Test Prod 4';
        testProducts[3].ProductCode = 'TP4';
        testProducts[3].FY16_Revenue_Type__c = 'Non-recurring';
        testProducts[3].Family = 'Support';
        //
        testProducts[4].Name = 'Test Prod 5';
        testProducts[4].ProductCode = 'TP5';
        testProducts[4].FY16_Revenue_Type__c = 'Non-recurring';
        testProducts[4].Family = 'Conga Service-Support-Training';
        insert testProducts;

        //// TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', false, 5);
        testPricebookEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[0].Product2Id = testProducts[0].Id;
        testPricebookEntries[0].IsActive = true;
        testPricebookEntries[0].UnitPrice = 200.00;
        //
        testPricebookEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[1].Product2Id = testProducts[1].Id;
        testPricebookEntries[1].IsActive = true;
        testPricebookEntries[1].UnitPrice = 500.00;
        //
        testPricebookEntries[2].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[2].Product2Id = testProducts[2].Id;
        testPricebookEntries[2].IsActive = true;
        testPricebookEntries[2].UnitPrice = 350.00;
        //
        testPricebookEntries[3].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[3].Product2Id = testProducts[3].Id;
        testPricebookEntries[3].IsActive = true;
        testPricebookEntries[3].UnitPrice = 750.00;
        //
        testPricebookEntries[4].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[4].Product2Id = testProducts[4].Id;
        testPricebookEntries[4].IsActive = true;
        testPricebookEntries[4].UnitPrice = 1000.00;
        insert testPricebookEntries;

        // CREATE TEST ACCOUNTS
        Account testAccount = (Account)TestingUtility.createSObject('Account', false, 1);
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].AccountId = testAccount.Id;
        testOpportunities[0].StageName = '0 - Qualification';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Name = 'Test Opp';
        testOpportunities[0].Type = 'Existing Business';

        testOpportunities[1].AccountId = testAccount.Id;
        testOpportunities[1].StageName = '0 - Qualification';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Name = 'Test Opp 2';
        testOpportunities[1].Type = 'Existing Business';
        insert testOpportunities;

        // CREATE TEST OPPORTUNITY ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', false, 5);
        testOppItems[0].OpportunityId = testOpportunities[0].Id;
        testOppItems[0].Quantity = 3;
        testOppItems[0].UnitPrice = 200;
        testOppItems[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOppItems[0].ServiceDate = Date.newInstance(2018, 1, 1);
        //
        testOppItems[1].OpportunityId = testOpportunities[0].Id;
        testOppItems[1].Quantity = 5;
        testOppItems[1].UnitPrice = 500;
        testOppItems[1].PricebookEntryId = testPricebookEntries[1].Id;
        testOppItems[1].ServiceDate = Date.newInstance(2018, 1, 1);
        //
        testOppItems[2].OpportunityId = testOpportunities[1].Id;
        testOppItems[2].Quantity = 5;
        testOppItems[2].UnitPrice = 250;
        testOppItems[2].PricebookEntryId = testPricebookEntries[2].Id;
        testOppItems[2].ServiceDate = Date.newInstance(2018, 1, 1);
        //
        testOppItems[3].OpportunityId = testOpportunities[1].Id;
        testOppItems[3].Quantity = 5;
        testOppItems[3].UnitPrice = 750;
        testOppItems[3].PricebookEntryId = testPricebookEntries[3].Id;
        testOppItems[3].ServiceDate = Date.newInstance(2018, 1, 1);
        //
        testOppItems[4].OpportunityId = testOpportunities[1].Id;
        testOppItems[4].Quantity = 5;
        testOppItems[4].UnitPrice = 1000;
        testOppItems[4].PricebookEntryId = testPricebookEntries[4].Id;
        testOppItems[4].ServiceDate = Date.newInstance(2018, 1, 1);
        insert testOppItems;

        Test.startTest();

        // CLOSE WIN OPPS
        testOpportunities[0].StageName = 'Closed Won';
        testOpportunities[1].StageName = 'Closed Won';
        update testOpportunities;

        // UPDATE OPPS AND CHECK FOR CORRECT DATA
        testOpportunities = [SELECT Id, Commissionable_Services_Bookings__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].Commissionable_Services_Bookings__c == 3100);
        System.assert(testOpportunities[1].Commissionable_Services_Bookings__c == 10000);

        Test.stopTest();
    }


}