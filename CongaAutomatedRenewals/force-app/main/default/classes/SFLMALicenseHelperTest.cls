/**
* @author Conga Services, ERedding
* @date 20181218
* @version 1.00
* @description SFLMALicenseHelperTest - Test class for the SFLMALicenseHelper class
*/
@isTest
public with sharing class SFLMALicenseHelperTest {

    // TRIALFORCE EXTENSIONS SETTINGS TEST METADATA
    public static Id AllowedPackageId1 {get;set;}
    public static Id AllowedPackageId2 {get;set;}
    public static Trialforce_Extension_Settings__mdt TrialforceSettingsTestMeta {
    get {
            Map<String, Object> metaFieldValues = new Map<String, Object>{
                'Account_Name_Keywords__c' => 'supreme tech\r\nsupremetech\r\nBlue Cube',
                'Eligible_Package_Ids__c' => AllowedPackageId1 + '\r\n' + AllowedPackageId2,
                'Length_of_Extension__c' => 90
            };
            TrialforceSettingsTestMeta = (Trialforce_Extension_Settings__mdt)TestingUtility.createTestMeta('Trialforce_Extension_Settings__mdt', metaFieldValues);
        return TrialforceSettingsTestMeta;
    } set; }

    /**
    * @description setupTestData - Test data setup method
    */
    @testSetup
    public static void setupTestData(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User leadManager = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', 
        FirstName = 'Lead', LastName = 'Manager', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com');
        insert leadManager;

        // CREATE TEST CAMPAIGN
        //Campaign testCampaign = new Campaign(Name = 'Test Campaign', IsActive = true, Product_Interest__c = 'Conga Composer');
        //insert testCampaign;

        // CREATE TEST LMA_Lead_Owner_Round_Robin__c CUSTOM SETTINGS
        LMA_Lead_Owner_Round_Robin__c roundRobin1 = new LMA_Lead_Owner_Round_Robin__c(Name = 'Test User - 0', Round_Robin_Number__c = 0, Lead_Owner_Id__c = leadManager.Id);
        List<LMA_Lead_Owner_Round_Robin__c> roundRobinCustomSettings = new List<LMA_Lead_Owner_Round_Robin__c>{ roundRobin1 };
        for(Integer i = 1; i < 20; i++){
            LMA_Lead_Owner_Round_Robin__c roundRobin = new LMA_Lead_Owner_Round_Robin__c(Name = 'Test User - ' + i, Round_Robin_Number__c = i, Lead_Owner_Id__c = UserInfo.getUserId());
            roundRobinCustomSettings.add(roundRobin);
        }
        insert roundRobinCustomSettings;

        // TEST PACKAGES
        List<sfLma__Package__c> testPackages = (List<sfLma__Package__c>)TestingUtility.createSObjectList('sfLma__Package__c', false, 3);
        testPackages[0].Name = 'Conga Composer';
        testPackages[0].sfLma__Latest_Version__c = '1.0';
        testPackages[1].Name = 'Conga Grid';
        testPackages[1].sfLma__Latest_Version__c = '1.0';
        testPackages[2].Name = 'Conga Courier';
        testPackages[2].sfLma__Latest_Version__c = '1.0';
        insert testPackages;

        // TEST PACKAGE VERSION
        sfLma__Package_Version__c testPackageVersion = new sfLma__Package_Version__c(Name = '1.0', sfLma__Package__c = testPackages[0].Id, sfLma__Version__c = '1.0');
        insert testPackageVersion;

        // CREATE TEST LEADS
        Lead testLead1 = new Lead(Status = 'Open', LastName = 'Test', Company = 'Test Company', Package__c = '', OwnerId = leadManager.Id, LeadSource = 'Package Installation');
        Lead testLead2 = new Lead(Status = 'Open', LastName = 'Test2', Company = 'Test Company 2', Package__c = '', OwnerId = leadManager.Id, LeadSource = 'SFDC-DM-Test');        
        insert testLead1; insert testLead2;     
    }

    /**
    * @description invalidateSandboxRefreshLeadsTest_Insert - Test Happy Path of code 
    */
    public static testmethod void invalidateSandboxRefreshLeadsTest_Insert() {
        // CREATE TEST DATA 
        Lead testLead = new Lead(Status = 'Working', LastName = 'Test', Company = 'Test Company');
        insert testLead;
        sfLma__Package__c testPackage = new sfLma__Package__c(Name = 'Test Package');
        insert testPackage;
        String orgId = UserInfo.getOrganizationId().substring(0,15);
        sfLma__License__c testLicense = new sfLma__License__c(sfLma__Install_Date__c = Date.today().addDays(-1), SfLma__Subscriber_Org_ID__c = orgId, sfLma__Lead__c = testLead.Id, SfLma__Package__c = testPackage.Id);
        insert testLicense;
        ///////////// SETTING THE INSTALL DATE TO BEFORE THE CREATION DATE OF THE TEST LEAD CAUSES THE Install_Date_Check__c FORMULA FIELD
        ///////////// TO EVALUATE TO "Sandbox Refresh"

        Test.startTest();

        // UPDATE LEAD AND TEST FOR CORRECT DATA
        testLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assert(testLead != null);
        System.assert(testLead.Status == 'Invalid');

        Test.stopTest();
    }

    /**
    * @description invalidateSandboxRefreshLeadsTest_Exceptions - Test Exception / Bad Data handling
    */
    public static testmethod void invalidateSandboxRefreshLeadsTest_Exceptions() {
        //// TRY EXECUTING LOGIC WITH A NULL LIST
        SFLMALicenseHelper.invalidateSandboxRefreshLeads(null);

        //// TRY EXECUTING LOGIC WITH AN EMPTY LIST
        SFLMALicenseHelper.invalidateSandboxRefreshLeads(new Map<Id, sfLma__License__c>());
    }

    /**
    * @description enableFMABluecubeLicensesTest - Test method for the enableFMABluecubeLicenses trigger method
    */
    public static testmethod void enableFMABluecubeLicensesTest() {
        // GET TEST PACKAGE VERSION
        List<sfLma__Package_Version__c> testPackageVersion = [SELECT Id, sfLma__Package__c FROM sfLma__Package_Version__c];
        System.assert(!testPackageVersion.isEmpty());

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // CREATE TEST LICENSES
        List<sfLma__License__c> testLicenses = (List<sfLma__License__c>)TestingUtility.createSObjectList('sfLma__License__c', false, 2);
        testLicenses[0].sfLma__Account__c = testAccount.Id;
        testLicenses[0].sfLma__Package_Version__c = testPackageVersion[0].Id;
        testLicenses[0].sfLma__Subscriber_Org_ID__c = '00DK00000012345';
        testLicenses[1].sfLma__Account__c = testAccount.Id;
        testLicenses[1].sfLma__Package_Version__c = testPackageVersion[0].Id;
        testLicenses[1].sfLma__Subscriber_Org_ID__c = '00DK00000054321';
        insert testLicenses;

        // CREATE TEST FEATURE PARAMETER RECORD
        List<sfFma__FeatureParameter__c> testFeatureParams = (List<sfFma__FeatureParameter__c>)TestingUtility.createSObjectList('sfFma__FeatureParameter__c', false, 2);
        testFeatureParams[0].sfFma__FullName__c = 'TST__Conga';
        testFeatureParams[0].sfFma__Namespace_Prefix__c = 'TST';
        testFeatureParams[0].sfFma__IntroducedInPackageVersion__c = '1.0';
        testFeatureParams[0].sfFma__Package__c = testPackageVersion[0].sfLma__Package__c;
        testFeatureParams[1].sfFma__FullName__c = 'TST__Conga';
        testFeatureParams[1].sfFma__Namespace_Prefix__c = 'TST';
        testFeatureParams[1].sfFma__IntroducedInPackageVersion__c = '1.0';
        testFeatureParams[1].sfFma__Package__c = testPackageVersion[0].sfLma__Package__c;
        insert testFeatureParams;

        // CREATE TEST FEATURE PARAMETER BOOLEAN RECORDS
        List<sfFma__FeatureParameterBoolean__c> testBooleans = (List<sfFma__FeatureParameterBoolean__c>)TestingUtility.createSObjectList('sfFma__FeatureParameterBoolean__c', false, 4);
        testBooleans[0].sfFma__FeatureParameter__c = testFeatureParams[0].Id;
        testBooleans[0].sfFma__License__c = testLicenses[0].Id;
        testBooleans[1].sfFma__FeatureParameter__c = testFeatureParams[0].Id;
        testBooleans[1].sfFma__License__c = testLicenses[0].Id;
        testBooleans[2].sfFma__FeatureParameter__c = testFeatureParams[1].Id;
        testBooleans[2].sfFma__License__c = testLicenses[1].Id;
        testBooleans[3].sfFma__FeatureParameter__c = testFeatureParams[1].Id;
        testBooleans[3].sfFma__License__c = testLicenses[1].Id;
        insert testBooleans;

        // CREATE TEST SALESFORCE ORG
        TriggerHelper.TemporaryOverride('SalesforceOrgHelper','updateLicenseObjectWithOrg', false); // DISABLE TRIGGER, THIS TEST WILL SET THE ORG ON LICENSES
        Salesforce_Org__c testSFOrg1 = new Salesforce_Org__c(Name = 'Test Org', Account__c = testAccount.Id, Salesforce_Account_Id__c = '00DK00000012345');
        Salesforce_Org__c testSFOrg2 = new Salesforce_Org__c(Name = 'Blue Cube', Account__c = testAccount.Id, Salesforce_Account_Id__c = '00DK00000054321');
        insert new List<Salesforce_Org__c>{ testSFOrg1, testSFOrg2 };

        Test.startTest();

        testLicenses[0].Salesforce_OrgId__c = testSFOrg1.Id;
        testLicenses[0].sfLma__Status__c = 'Trial';
        testLicenses[0].sfLma__Seats__c = 5;
        testLicenses[1].Salesforce_OrgId__c = testSFOrg2.Id;
        testLicenses[1].sfLma__Status__c = 'Trial';
        testLicenses[1].sfLma__Seats__c = 5;
        update testLicenses;

        // UPDATE FEATURE PARAMETER BOOLEAN RECORDS AND TEST FOR CORRECT DATA
        testBooleans = [SELECT Id, sfFma__Value__c FROM sfFma__FeatureParameterBoolean__c WHERE Id IN :testBooleans];
        System.assert(testBooleans.size() == 4);
        System.assert(testBooleans[0].sfFma__Value__c == false); // NOT A BLUECUBE ORG, SHOULD BE FALSE
        System.assert(testBooleans[1].sfFma__Value__c == false); // NOT A BLUECUBE ORG, SHOULD BE FALSE
        System.assert(testBooleans[2].sfFma__Value__c == true); // BLUECUBE ORG, SHOULD BE TRUE
        System.assert(testBooleans[3].sfFma__Value__c == true); // BLUECUBE ORG, SHOULD BE TRUE

        Test.stopTest();
    }
    /**
    * @description enableFMABluecubeLicensesTest_Exceptions - Test Exception / Bad Data handling
    */
    public static testmethod void enableFMABluecubeLicensesTest_Exceptions() {
        Test.startTest();

        // TRY EXECUTING LOGIC WITH A NULL PARAMETERS
        sfLmaLicenseHelper.enableFMABluecubeLicenses(null, null);

        // TRY EXECUTING LOGIC WITH AN EMPTY PARAMETERS
        sfLmaLicenseHelper.enableFMABluecubeLicenses(new List<sfLma__License__c>(), new Map<Id, sfLma__License__c>());

        Test.stopTest();
    }



    /**
    * @description processNewLicensesTest - Test Happy Path of code
    */
    public static testmethod void processNewLicensesTest() {
        // GET TEST LEAD
        List<Lead> testLeads = [SELECT Id, OwnerId FROM Lead];
        System.assert(!testLeads.isEmpty() && testLeads.size() == 2);

        // GET PACKAGE VERSION
        List<sfLma__Package_Version__c> testPackageVersion = [SELECT Id FROM sfLma__Package_Version__c];
        System.assert(!testPackageVersion.isEmpty());

        Test.startTest();

        // CREATE TEST LICENSE RUNNING THE TRIGGER METHOD MANUALLY
        sfLma__License__c testLicense1 = new sfLma__License__c(sfLma__Lead__c = testLeads[0].Id, sfLma__Package_Version__c = testPackageVersion[0].Id);
        sfLma__License__c testLicense2 = new sfLma__License__c(sfLma__Lead__c = testLeads[1].Id, sfLma__Package_Version__c = testPackageVersion[0].Id);
        insert new List<sfLma__License__c>{ testLicense1, testLicense2 };

        // REFRESH TEST LEADS AND CHECK FOR CORRECT FIELD DATA
        testLeads = [SELECT Id, Package__c, AppExchange_Type__c, LeadSource, Product_Interest__c, OwnerId FROM Lead WHERE Id = :testLeads];
        System.assert(testLeads != null && testLeads.size() == 2);
        System.assert(testLeads[0].Package__c == 'Conga Composer');
        System.assert(testLeads[0].AppExchange_Type__c == 'Install');
        System.assert(testLeads[1].Package__c == 'Conga Composer');
        System.assert(testLeads[1].AppExchange_Type__c == 'Install');

        Test.stopTest();
    }

    /**
    * @description processNewLicensesTest_Exceptions - Test Exception / Bad Data handling
    */
    public static testmethod void processNewLicensesTest_Exceptions() {
        // TRY EXECUTING LOGIC WITH A NULL MAP
        sfLmaLicenseHelper.processNewLicenses(null);

        // TRY EXECUTING LOGIC WITH AN EMPTY MAP
        sfLmaLicenseHelper.processNewLicenses(new Map<Id, sfLma__License__c>());
    }

    /**
    * @description updateSFOrgComposerLicenseTest_Insert - Test creating of a license
    */
    public static testmethod void updateSFOrgComposerLicenseTest_Insert() {
        // GET PACKAGE VERSION
        List<sfLma__Package_Version__c> testPackageVersion = [SELECT Id FROM sfLma__Package_Version__c];
        System.assert(!testPackageVersion.isEmpty());

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // CREATE TEST SALESFORCE ORG
        Salesforce_Org__c testSFOrg = new Salesforce_Org__c(Account__c = testAccount.Id, Salesforce_Account_Id__c = UserInfo.getOrganizationId());
        insert testSFOrg;

        Test.startTest();

        // CREATE TEST LICENSE
        sfLma__License__c testLicense1 = new sfLma__License__c(sfLma__Account__c = testAccount.Id, 
                                                               sfLma__Status__c = 'Active',
                                                               sfLma__Seats__c = 5,
                                                               sfLma__Subscriber_Org_ID__c = UserInfo.getOrganizationId(), 
                                                               sfLma__Package_Version__c = testPackageVersion[0].Id);
        insert testLicense1;

        // CHECK FOR PROPERLY UPDATED SALESFORCE ORG
        testSFOrg = [SELECT Id, Composer_License__c FROM Salesforce_Org__c WHERE Id = :testSFOrg.Id];
        System.assert(testSFOrg != null);
        System.assert(testSFOrg.Composer_License__c == testLicense1.Id);        

        Test.stopTest();
    }

    /**
    * @description updateSFOrgComposerLicenseTest_Update - Test updating of a license
    */
    public static testmethod void updateSFOrgComposerLicenseTest_Update() {
        // GET PACKAGE VERSION
        List<sfLma__Package_Version__c> testPackageVersion = [SELECT Id FROM sfLma__Package_Version__c];
        System.assert(!testPackageVersion.isEmpty());

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // CREATE TEST SALESFORCE ORG
        Salesforce_Org__c testSFOrg = new Salesforce_Org__c(Account__c = testAccount.Id, Salesforce_Account_Id__c = UserInfo.getOrganizationId());
        insert testSFOrg;

        Test.startTest();

        // CREATE TEST LICENSE
        sfLma__License__c testLicense1 = new sfLma__License__c(sfLma__Account__c = testAccount.Id, 
                                                               sfLma__Status__c = 'Active',
                                                               sfLma__Seats__c = 5,
                                                               sfLma__Package_Version__c = testPackageVersion[0].Id);
        insert testLicense1;

        // SALESFORCE ORG SHOULD NOT BE LINKED YET
        testSFOrg = [SELECT Id, Composer_License__c FROM Salesforce_Org__c WHERE Id = :testSFOrg.Id];
        System.assert(testSFOrg != null);
        System.assert(testSFOrg.Composer_License__c == null);        

        // UPDATE LICENSE WITH ORG ID
        testLicense1.sfLma__Subscriber_Org_ID__c = UserInfo.getOrganizationId();
        testLicense1.sfLma__Seats__c = 10;
        update testLicense1;

        // SALESFORCE ORG SHOULD BE LINKED NOW
        testSFOrg = [SELECT Id, Composer_License__c FROM Salesforce_Org__c WHERE Id = :testSFOrg.Id];
        System.assert(testSFOrg != null);
        System.assert(testSFOrg.Composer_License__c == testLicense1.Id); 

        Test.stopTest();
    }

    /**
    * @description updateSFOrgComposerLicenseTest_Exceptions - Test Exception / Bad Data handling
    */
    public static testmethod void updateSFOrgComposerLicenseTest_Exceptions() {
        // TRY EXECUTING LOGIC WITH A NULL LIST
        SFLMALicenseHelper.updateSFOrgComposerLicense(null, null);

        // TRY EXECUTING LOGIC WITH AN EMPTY LIST
        SFLMALicenseHelper.updateSFOrgComposerLicense(new Map<Id, sfLma__License__c>(), new Map<Id, sfLma__License__c>());
    }

    /**
    * @description extendTrialLicenseTest - Tests the sfLma__License__c extendTrialLicense trigger method
    */
    public static testmethod void extendTrialLicenseTest() {
        // GET PACKAGE VERSION
        List<sfLma__Package__c> testPackages = [SELECT Id FROM sfLma__Package__c];
        System.assert(!testPackages.isEmpty() && testPackages.size() == 3);

        // SET ALLOWED PACKAGE IDS FOR TEST METADATA
        AllowedPackageId1 = testPackages[0].Id;
        AllowedPackageId2 = testPackages[1].Id;

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 4);
        testAccounts[0].Name = 'supreme tech Account';
        testAccounts[1].Name = 'Account supremetech';
        testAccounts[2].Name = 'Blue Cube Shapes';
        testAccounts[3].Name = 'Test Account';        
        insert testAccounts;

        Test.startTest();

        // CREATE TEST LICENSES
        List<sfLma__License__c> testLicenses = (List<sfLma__License__c>)TestingUtility.createSObjectList('sfLma__License__c', false, 4);
        for(sfLma__License__c license : testLicenses){
            license.sfLma__Status__c = 'Active';
            license.sfLma__Seats__c = 5;
            license.sfLma__Install_Date__c = Date.today();
        }
        testLicenses[0].sfLma__Package__c = testPackages[0].Id; // ALLOWED PACKAGE
        testLicenses[1].sfLma__Package__c = testPackages[1].Id; // ALLOWED PACKAGE
        testLicenses[2].sfLma__Package__c = testPackages[2].Id; // NOT ALLOWED PACKAGE
        testLicenses[3].sfLma__Package__c = testPackages[1].Id; // ALLOWED PACKAGE        
        insert testLicenses;

        // LICENSES SHOULD HAVE NO EXPIRATION CURENTLY
        testLicenses = [SELECT Id, sfLma__Expiration__c FROM sfLma__License__c WHERE Id IN :testLicenses];
        System.assert(testLicenses[0].sfLma__Expiration__c == null);
        System.assert(testLicenses[1].sfLma__Expiration__c == null);
        System.assert(testLicenses[2].sfLma__Expiration__c == null);
        System.assert(testLicenses[3].sfLma__Expiration__c == null);

        // UPDATE LICENSE ACCOUNTS
        testLicenses[0].sfLma__Account__c = testAccounts[0].Id; // ALLOWED ACCOUNT AND PACKAGE
        testLicenses[1].sfLma__Account__c = testAccounts[1].Id; // ALLOWED ACCOUNT AND PACKAGE
        testLicenses[2].sfLma__Account__c = testAccounts[2].Id; // ALLOWED ACCOUNT BUT NOT PACKAGE
        testLicenses[3].sfLma__Account__c = testAccounts[3].Id; // ALLOWED PACKAGE BUT NOT ACCOUNT
        update testLicenses;

        // RELOAD LICENSES AND CHECK FOR CORRECT DATA
        testLicenses = [SELECT Id, sfLma__Install_Date__c, sfLma__Expiration__c FROM sfLma__License__c WHERE Id IN :testLicenses];
        System.debug(testLicenses[0]);
        System.debug(testLicenses[1]);
        System.debug(testLicenses[2]);
        System.debug(testLicenses[3]);
        System.assert(testLicenses[0].sfLma__Expiration__c == testLicenses[0].sfLma__Install_Date__c.addDays(90)); // ALLOWED ACCOUNT AND PACKAGE
        System.assert(testLicenses[1].sfLma__Expiration__c == testLicenses[1].sfLma__Install_Date__c.addDays(90)); // ALLOWED ACCOUNT AND PACKAGE
        System.assert(testLicenses[2].sfLma__Expiration__c == null); // ALLOWED ACCOUNT BUT NOT PACKAGE
        System.assert(testLicenses[3].sfLma__Expiration__c == null); // ALLOWED PACKAGE BUT NOT ACCOUNT

        Test.stopTest();
    }


}