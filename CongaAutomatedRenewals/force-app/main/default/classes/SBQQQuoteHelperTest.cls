/**
* @author Conga Services, ERedding
* @date 20181120
* @version 1.00
* @description SBQQQuoteHelperTest - Test class for the SBQQQuoteHelper class
*/
@isTest
public with sharing class SBQQQuoteHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        TriggerHelper.OverrideAllSettings(true, false);

        //// TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 2);
        testProducts[0].Name = 'Rev Schedule Prod';
        testProducts[0].ProductCode = 'RSP1';   
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[1].Name = 'Rev Schedule Prod 2';
        testProducts[1].ProductCode = 'RSP2';
        insert testProducts;

        //// TEST BILLING PARTY ACCOUNT
        Account testBillingPartyAccount = (Account)TestingUtility.createSObject('Account', false, 1);
        testBillingPartyAccount.Name = 'Test Billing Party Account';
        insert testBillingPartyAccount;

        //// TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account', false, 1);
        testAccount.Name = 'Test Account';
        testAccount.Billing_Party__c = testBillingPartyAccount.Id;
        testAccount.BillingStreet = '123 Test Street';
        testAccount.BillingCity = 'Denver';
        testAccount.BillingState = 'Colorado';
        testAccount.BillingPostalCode = '80233';
        testAccount.BillingCountry = 'United States';
        insert testAccount;

        // TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false, 1);
        testContract.AccountId = testAccount.Id;
        testContract.Status = 'Draft';
        testContract.StartDate = Date.today().addDays(30);
        testContract.ContractTerm = 12;
        testContract.Auto_Renew_Term__c = '1';
        testContract.Expiration_Warning__c = 30;
        testContract.Non_Payment_Late_Charge__c = 0.00;
        testContract.Payment_Terms_non_Net_30__c = 'Net 30';
        insert testContract;

        //// TEST CONTACTS
        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', false, 2);    
        testContacts[0].FirstName = 'Test';
        testContacts[0].LastName = 'Contact';   
        testContacts[0].Email = 'testcontact@mailinator.com';
        testContacts[0].Phone = '(303) 321-1234';
        testContacts[1].FirstName = 'Contact';
        testContacts[1].LastName = 'Test';   
        testContacts[1].Email = 'contacttest@mailinator.com';
        testContacts[1].Phone = '(303) 321-1234';    
        insert testContacts;

        // SET MSA CONTRACT ON TEST ACCOUNT AND BILLING CONTACTS ON ACCOUNTS
        testBillingPartyAccount.BillingContact__c = testContacts[0].Id;
        testAccount.MSA_Contract__c = testContract.Id;
        testAccount.BillingContact__c = testContacts[1].Id;
        update new List<Account>{ testBillingPartyAccount, testAccount };

        // GET OPP RECORD TYPES
        Map<String, Id> oppRecordTypes = SBQQQuoteHelper.RecordTypes.get('Opportunity');

        // TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 3);
        testOpportunities[0].Name = 'Direct Opp';
        testOpportunities[0].AccountId = testAccount.Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].RecordTypeId = oppRecordTypes.get('Direct');
        testOpportunities[0].SBQQ__RenewedContract__c = testContract.Id;
        testOpportunities[0].SBQQ__AmendedContract__c = testContract.Id;
        testOpportunities[0].Type = 'Existing Business';

        testOpportunities[1].Name = 'Indirect Opp';
        testOpportunities[1].AccountId = testAccount.Id;
        testOpportunities[1].StageName = 'Qualify';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].RecordTypeId = oppRecordTypes.get('Indirect');
        testOpportunities[1].SBQQ__RenewedContract__c = testContract.Id;

        testOpportunities[2].Name = 'Direct Opp 2';
        testOpportunities[2].AccountId = testAccount.Id;
        testOpportunities[2].StageName = 'Qualify';
        testOpportunities[2].CloseDate = Date.today();
        testOpportunities[2].RecordTypeId = oppRecordTypes.get('Direct');
        testOpportunities[2].Type = 'Existing Business';
        insert testOpportunities;

        TriggerHelper.OverrideAllSettings(false, true);

        //// TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', false, 6);
        testQuotes[0].SBQQ__Account__c = testAccount.Id;
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[0].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        testQuotes[0].SBQQ__Opportunity2__c = testOpportunities[0].Id;
        testQuotes[0].SBQQ__MasterContract__c = testContract.Id;
        testQuotes[1].CreatedDate = DateTime.now().addMinutes(-5);

        testQuotes[1].SBQQ__Account__c = testAccount.Id;
        testQuotes[1].SBQQ__Status__c = 'Draft';
        testQuotes[1].SBQQ__Type__c = 'Amendment';
        testQuotes[1].SBQQ__Primary__c = true;
        testQuotes[1].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[1].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        testQuotes[1].SBQQ__Opportunity2__c = testOpportunities[0].Id;
        testQuotes[1].SBQQ__MasterContract__c = testContract.Id;
        testQuotes[1].CreatedDate = DateTime.now().addMinutes(-4);

        testQuotes[2].SBQQ__Account__c = testAccount.Id;
        testQuotes[2].SBQQ__Status__c = 'Draft';
        testQuotes[2].SBQQ__Type__c = 'Renewal';   
        testQuotes[2].SBQQ__Primary__c = true;
        testQuotes[2].SBQQ__StartDate__c = Date.newInstance(2018, 6, 1);
        testQuotes[2].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        testQuotes[2].SBQQ__Opportunity2__c = testOpportunities[1].Id;
        testQuotes[2].Expiration_Warning__c = 30;
        testQuotes[2].Auto_Renew__c = '1';
        testQuotes[2].SBQQ__PaymentTerms__c = 'Net 30';
        testQuotes[2].Non_Payment_Late_Charge__c = 1;
        testQuotes[2].Bundle_Name__c = 'MSA';
        testQuotes[2].CreatedDate = DateTime.now().addMinutes(-3);

        testQuotes[3].SBQQ__Account__c = testAccount.Id;
        testQuotes[3].SBQQ__Status__c = 'Draft';
        testQuotes[3].SBQQ__Type__c = 'Quote';
        testQuotes[3].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[3].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        testQuotes[3].SBQQ__Opportunity2__c = testOpportunities[2].Id;
        testQuotes[3].SBQQ__MasterContract__c = testContract.Id;
        testQuotes[3].CreatedDate = DateTime.now().addMinutes(-2);

        testQuotes[4].SBQQ__Account__c = testAccount.Id;
        testQuotes[4].SBQQ__Status__c = 'Draft';
        testQuotes[4].SBQQ__Type__c = 'Quote';
        testQuotes[4].SBQQ__Primary__c = true;
        testQuotes[4].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[4].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        testQuotes[4].SBQQ__Opportunity2__c = testOpportunities[2].Id;
        testQuotes[4].SBQQ__MasterContract__c = testContract.Id;
        testQuotes[4].CreatedDate = DateTime.now().addMinutes(-1);

        testQuotes[5].SBQQ__Account__c = testAccount.Id;
        testQuotes[5].SBQQ__Status__c = 'Draft';
        testQuotes[5].SBQQ__Type__c = 'Quote';
        testQuotes[5].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[5].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        testQuotes[5].SBQQ__Opportunity2__c = testOpportunities[2].Id;
        testQuotes[5].SBQQ__MasterContract__c = testContract.Id; 
        insert testQuotes;

        TriggerHelper.OverrideAllSettings(true, false);

        // TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = TestingUtility.createSObjectList('SBQQ__QuoteLine__c', false, 3);
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[0].SBQQ__Quantity__c = 75;

        testQuoteLines[1].SBQQ__Quote__c = testQuotes[1].Id;
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        testQuoteLines[1].SBQQ__Quantity__c = 15;
        testQuoteLines[1].SBQQ__StartDate__c = Date.today();
        testQuoteLines[1].SBQQ__EndDate__c =  Date.today().addDays(180);

        testQuoteLines[2].SBQQ__Quote__c = testQuotes[2].Id;
        testQuoteLines[2].SBQQ__Product__c = testProducts[0].Id;
        testQuoteLines[2].SBQQ__Quantity__c = 50;
        insert testQuoteLines;

        // TEST COUNTRY RECORDS 
        List<Country_Territory__c> testCountries = new List<Country_Territory__c>();
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'AMER');
        insert new List<Country_Territory__c>{ unitedStates };

        // TEST STATE RECORDS
        State_Province__c colorado = new State_Province__c(Name = 'Colorado', English_Name__c = 'Colorado', Code__c = 'CO', Country_TerritoryId__c = unitedStates.Id);
        State_Province__c california = new State_Province__c(Name = 'California', English_Name__c = 'California', Code__c = 'CA', Country_TerritoryId__c = unitedStates.Id);
        insert new List<State_Province__c>{ colorado, california };
    }


    /**
    * @description quoteFieldUpdatesTest - Test SBQQQuoteHelper.quoteFieldUpdates trigger method
    */
    public static testMethod void quoteFieldUpdatesTest(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id, Name, OwnerId FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccounts.size() == 1);

        // GET TEST QUOTES
        List<SBQQ__Quote__c> testQuotes = [SELECT Id, SBQQ__Opportunity2__c, OwnerId FROM SBQQ__Quote__c];
        System.assert(testQuotes.size() == 6);

        // RENEWAL QUOTE OWNER SHOULD MATCH ACCOUNT OWNER
        System.assert(testQuotes[2].OwnerId == testAccounts[0].OwnerId);

        // MAKE APPLICABLE CHANGES TO QUOTES AND UPDATE
        testQuotes[1].Terms__c = 'Full - Signature';
        testQuotes[1].Bundle_Name__c = 'MSA';
        testQuotes[1].SBQQ__PaymentTerms__c = 'Net 30';

        testQuotes[2].Discount_Approval_Status__c = 'Approved';
        testQuotes[2].Discount_Approval_Button__c = false;      
        testQuotes[2].Auto_Renew__c = '0';
        testQuotes[2].Expiration_Warning__c = 60;
        testQuotes[2].Non_Payment_Late_Charge__c = 0;
        testQuotes[2].SBQQ__PaymentTerms__c = 'Net 60';
        update testQuotes;

        Test.startTest();

        // MAKE MORE APPLICABLE CHANGES TO QUOTES AND UPDATE
        testQuotes[2].Discount_Approval_Button__c = true;
        testQuotes[2].Auto_Renew__c = '1';
        testQuotes[2].Expiration_Warning__c = 30;
        testQuotes[2].Non_Payment_Late_Charge__c = 1;
        testQuotes[2].SBQQ__PaymentTerms__c = 'Net 30';
        testQuotes[2].RecordTypeId = UtilityClass.getRecordTypesForObject('SBQQ__Quote__c').get('Approved');
        update testQuotes;

        // MAKE MORE APPLICABLE CHANGES TO QUOTES AND UPDATE
        testQuotes[2].Auto_Renew__c = null;
        testQuotes[2].Expiration_Warning__c = null;
        testQuotes[2].Non_Payment_Late_Charge__c = null;
        testQuotes[2].Bundle_Name__c = 'EMEA MSA';
        update testQuotes;

        testQuotes[1].ApprovalStatus__c = 'Rejected';
        testQuotes[2].ApprovalStatus__c = 'Recalled';
        update testQuotes;

        testQuotes[1].ApprovalStatus__c = 'Pending';
        testQuotes[2].ApprovalStatus__c = 'Approved';
        update testQuotes;

        testQuotes[2].RecordTypeId = UtilityClass.getRecordTypesForObject('SBQQ__Quote__c').get('Draft');
        update testQuotes[2];

        Test.stopTest();
    }

    /**
    * @description updateLeapYearFlagTest - Test updateLeapYearFlag trigger method
    */
    public static testMethod void updateLeapYearFlagTest(){
        // GET TEST QUOTE AND TEST FOR CORRECT LEAP YEAR VALUE
        List<SBQQ__Quote__c> testQuotes = [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, Has_Leap_Year_Day__c FROM SBQQ__Quote__c];
        System.assert(!testQuotes.isEmpty());
        System.assert(testQuotes[0].Has_Leap_Year_Day__c == false);

        Test.startTest();

        // CHANGE DATES SO THEY SPAN A LEAP YEAR DAY
        testQuotes[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[0].SBQQ__EndDate__c = Date.newInstance(2020, 12, 31);
        update testQuotes;

        // UPDATE TEST QUOTE AND TEST FOR CORRECT LEAP YEAR VALUE
        testQuotes = [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, Has_Leap_Year_Day__c FROM SBQQ__Quote__c];
        System.assert(testQuotes[0].Has_Leap_Year_Day__c == true);

        Test.stopTest();
    }

    /**
    * @description lockUnlockQuoteLinesTest - Test lockUnlockQuoteLines trigger method
    */
    public static testMethod void lockUnlockQuoteLinesTest(){
        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = [SELECT Id, ApprovalStatus__c FROM SBQQ__Quote__c];
        System.assert(testQuotes.size() == 6);

        // GET RECORD TYPES
        Map<String, Id> quoteLineRecordTypes = SBQQQuoteHelper.RecordTypes.get('SBQQ__QuoteLine__c');

        // MAKE AN APPROVAL STATUS CHANGE
        testQuotes[0].ApprovalStatus__c = 'Pending';
        testQuotes[1].ApprovalStatus__c = 'Pending';
        testQuotes[2].ApprovalStatus__c = 'Pending';
        update testQuotes;

        // GET TEST QUOTE LINES AND CHECK FOR CORRECT DATA
        List<SBQQ__QuoteLine__c> testQuoteLines = [SELECT Id, RecordTypeId FROM SBQQ__QuoteLine__c];
        System.assert(!testQuoteLines.isEmpty());
        System.assert(testQuoteLines[0].RecordTypeId == quoteLineRecordTypes.get('Locked'));
        System.assert(testQuoteLines[1].RecordTypeId == quoteLineRecordTypes.get('Locked'));
        System.assert(testQuoteLines[2].RecordTypeId == quoteLineRecordTypes.get('Locked'));

        Test.startTest();        


        // MAKE AN APPROVAL STATUS CHANGE
        testQuotes[0].ApprovalStatus__c = 'Recalled';
        testQuotes[1].ApprovalStatus__c = 'Recalled';
        testQuotes[2].ApprovalStatus__c = 'Rejected';
        update testQuotes;

        // GET TEST QUOTE LINES AND CHECK FOR CORRECT DATA
        testQuoteLines = [SELECT Id, RecordTypeId, RecordType.Name FROM SBQQ__QuoteLine__c];
        System.assert(!testQuoteLines.isEmpty());
        System.assert(testQuoteLines[0].RecordTypeId == quoteLineRecordTypes.get('Unlocked'));
        System.assert(testQuoteLines[1].RecordTypeId == quoteLineRecordTypes.get('Unlocked'));
        System.assert(testQuoteLines[2].RecordTypeId == quoteLineRecordTypes.get('Unlocked'));

        Test.stopTest();
    }

    /**
    * @description updateQuoteLineOppItemDatesTest - Test updateQuoteLineOppItemDates trigger method
    */
    public static testMethod void updateQuoteLineOppItemDatesTest(){
        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Quote__c];
        System.assert(!testQuotes.isEmpty());

        Test.startTest();

        // MAKE A DATE CHANGE AND UPDATE TO RUN LOGIC.
        testQuotes[0].SBQQ__StartDate__c = Date.today().addDays(60);
        testQuotes[0].SBQQ__EndDate__c = Date.today().addDays(180);
        testQuotes[1].SBQQ__StartDate__c = Date.today().addDays(75);
        testQuotes[1].SBQQ__EndDate__c = Date.today().addDays(160);
        update testQuotes;

        // GET TEST QUOTE LINES AND ENSURE DATES WERE UPDATED
        List<SBQQ__QuoteLine__c> testQuoteLines = [SELECT Id, SBQQ__StartDate__c, Opp_Item_Start_Date__c, Opp_Item_End_Date__c FROM SBQQ__QuoteLine__c];
        System.assert(!testQuoteLines.isEmpty());
        System.assert(testQuoteLines[0].Opp_Item_Start_Date__c == testQuotes[0].SBQQ__StartDate__c);
        System.assert(testQuoteLines[0].Opp_Item_End_Date__c == testQuotes[0].SBQQ__EndDate__c);
        System.assert(testQuoteLines[1].Opp_Item_Start_Date__c == Date.today());
        System.assert(testQuoteLines[1].Opp_Item_End_Date__c == null); // NON RECURRING PRODUCTS DO NOT GET AN END DATE

        Test.stopTest();
    }

    /**
    * @description updateParentOppNoticeFieldsTest - Test updateParentOppNoticeFields trigger method
    */
    public static testMethod void updateParentOppNoticeFieldsTest(){
        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Quote__c];
        System.assert(testQuotes.size() == 6);

        Test.startTest();

        // MAKE 60 DAY AND 75 DAY STATUS CHANGES TO QUOTES
        testQuotes[0].Automatic_Renewal_75_Day_Notice__c = 'Viewed';
        testQuotes[0].Automatic_Renewal_60_Day_Notice__c = 'Created';
        testQuotes[1].Automatic_Renewal_75_Day_Notice__c = null;
        testQuotes[1].Automatic_Renewal_60_Day_Notice__c = 'Sent';
        //
        testQuotes[2].Automatic_Renewal_75_Day_Notice__c = 'Viewed';
        testQuotes[2].Automatic_Renewal_60_Day_Notice__c = 'Created';
        //
        testQuotes[3].Automatic_Renewal_75_Day_Notice__c = 'Sent';
        testQuotes[3].Automatic_Renewal_60_Day_Notice__c = null;
        testQuotes[4].Automatic_Renewal_75_Day_Notice__c = null;
        testQuotes[4].Automatic_Renewal_60_Day_Notice__c = 'Viewed';
        testQuotes[5].Automatic_Renewal_75_Day_Notice__c = null;
        testQuotes[5].Automatic_Renewal_60_Day_Notice__c = 'Created';
        update testQuotes;

        // GET OPPORTUNITIES AND MAKE SURE THEY WERE ALL UPDATED CORRECTLY
        List<Opportunity> testOpps = [SELECT Id, Automatic_Renewal_75_Day_Notice__c, Automatic_Renewal_60_Day_Notice__c FROM Opportunity];
        System.assert(testOpps.size() == 3);
        System.assert(testOpps[0].Automatic_Renewal_75_Day_Notice__c == 'Viewed');
        System.assert(testOpps[0].Automatic_Renewal_60_Day_Notice__c == 'Sent');
        System.assert(testOpps[1].Automatic_Renewal_75_Day_Notice__c == 'Viewed');
        System.assert(testOpps[1].Automatic_Renewal_60_Day_Notice__c == 'Created');
        System.assert(testOpps[2].Automatic_Renewal_75_Day_Notice__c == 'Sent');
        System.assert(testOpps[2].Automatic_Renewal_60_Day_Notice__c == 'Viewed');

        Test.stopTest();
    }

    /**
    * @description validateStateAndCountryTest - Test validateStateAndCountry trigger method
    */
    public static testMethod void validateStateAndCountryTest(){
        // CREATE TEST USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', 
        FirstName = 'Sales', LastName = 'User', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        System.runAs(salesUser){ // VALIDATION IS BYPASSED FOR ADMINS AND CONGA SALES OPS USERS, SO RUN AS A DIFFERENT PROFILE

            // CREATE TEST QUOTE
            List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', true, 1);
            testQuotes[0].SBQQ__Status__c = 'Draft';
            testQuotes[0].SBQQ__Type__c = 'Quote';
            testQuotes[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
            testQuotes[0].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
            testQuotes[0].SBQQ__BillingState__c = 'CO';
            testQuotes[0].SBQQ__BillingCountry__c = 'USA';
            testQuotes[0].SBQQ__ShippingState__c = 'CA';
            testQuotes[0].SBQQ__ShippingCountry__c = 'USA';
            insert testQuotes;

            // TEST THAT COUNTRIES AND STATES WERE PROPERLY CONVERTED TO THEIR FULL NAMES
            testQuotes = [SELECT Id, SBQQ__BillingState__c, SBQQ__BillingCountry__c, SBQQ__ShippingState__c, SBQQ__ShippingCountry__c FROM SBQQ__Quote__c WHERE Id IN :testQuotes];
            System.assert(testQuotes[0].SBQQ__BillingState__c == 'Colorado');
            System.assert(testQuotes[0].SBQQ__BillingCountry__c == 'United States');
            System.assert(testQuotes[0].SBQQ__ShippingState__c == 'California');
            System.assert(testQuotes[0].SBQQ__ShippingCountry__c == 'United States');

            Test.startTest();

            // MAKE INVALID CHANGES AND UPDATE, EACH UPDATE SHOULD CAUSE A TRIGGER ERROR TO OCCUR
            try{
                testQuotes[0].SBQQ__BillingState__c = 'Colorad';
                update testQuotes;
            }
            catch(Exception ex){
                System.assert(ex.getMessage().contains('Invalid'));
                System.assert(ex.getMessage().contains('State'));
            }
            ////
            try{
                testQuotes[0].SBQQ__BillingState__c = 'Colorado';
                testQuotes[0].SBQQ__BillingCountry__c = 'United Stat';
                update testQuotes;
            }
            catch(Exception ex){
                System.assert(ex.getMessage().contains('Invalid'));
                System.assert(ex.getMessage().contains('Country'));
            }
            ////
            try{
                testQuotes[0].SBQQ__BillingState__c = 'Colorado';
                testQuotes[0].SBQQ__BillingCountry__c = 'United States';
                testQuotes[0].SBQQ__ShippingState__c = 'Californ';
                update testQuotes;     
            }
            catch(Exception ex){
                System.assert(ex.getMessage().contains('Invalid'));
                System.assert(ex.getMessage().contains('State'));
            }
            ////
            try{
                testQuotes[0].SBQQ__BillingState__c = 'Colorado';
                testQuotes[0].SBQQ__BillingCountry__c = 'United States';
                testQuotes[0].SBQQ__ShippingState__c = 'California';
                testQuotes[0].SBQQ__BillingCountry__c = 'United Stat';
                update testQuotes;
            }
            catch(Exception ex){
                System.assert(ex.getMessage().contains('Invalid'));
                System.assert(ex.getMessage().contains('Country'));
            }

            Test.stopTest();
        }
    }


}