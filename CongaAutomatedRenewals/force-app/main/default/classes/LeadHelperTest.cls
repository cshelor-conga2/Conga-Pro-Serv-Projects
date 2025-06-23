/**
* @author Conga Services
* @date 20180615
* @version 1.00
* @description LeadHelperTest - LeadHelperTest test class for the LeadHelper class
*/
@isTest
public class LeadHelperTest {
    // LMA LEAD PACKAGE CAMPAIGN MAPPING TEST METADATA
    public static Id TestCampaignId {get;set;}
    public static Id TestCampaignId2 {get;set;}
    public static List<LMA_Lead_Package_Campaign__mdt> LeadPackageCampaignsTestMeta {
    get {
            Map<String, Object> meta1FieldValues = new Map<String, Object>{
                'Package__c' => 'Conga Composer',
                'AppExchange_Type__c' => 'Install',
                'CampaignId__c' => TestCampaignId
            };
            LMA_Lead_Package_Campaign__mdt customTestMeta1 = (LMA_Lead_Package_Campaign__mdt)TestingUtility.createTestMeta('LMA_Lead_Package_Campaign__mdt', meta1FieldValues);

            Map<String, Object> meta2FieldValues = new Map<String, Object>{
                'Package__c' => 'Conga Composer',
                'AppExchange_Type__c' => 'Demo',
                'CampaignId__c' => TestCampaignId
            };
            LMA_Lead_Package_Campaign__mdt customTestMeta2 = (LMA_Lead_Package_Campaign__mdt)TestingUtility.createTestMeta('LMA_Lead_Package_Campaign__mdt', meta2FieldValues);

            Map<String, Object> meta3FieldValues = new Map<String, Object>{
                'Package__c' => 'Conga Grid',
                'AppExchange_Type__c' => 'Install',
                'CampaignId__c' => TestCampaignId2
            };
            LMA_Lead_Package_Campaign__mdt customTestMeta3 = (LMA_Lead_Package_Campaign__mdt)TestingUtility.createTestMeta('LMA_Lead_Package_Campaign__mdt', meta3FieldValues);
            LeadPackageCampaignsTestMeta = new List<LMA_Lead_Package_Campaign__mdt>{ customTestMeta1, customTestMeta2, customTestMeta3 };
        return LeadPackageCampaignsTestMeta;
    } set; }

    // LEAD MQL QUALIFICATION SETTINGS TEST METADATA
    public static Id MQLQueueId {get;set;}
    public static Lead_MQL_Qualification_Settings__mdt MQLSettingsTestMeta {
    get {
            Map<String, Object> meta1FieldValues = new Map<String, Object>{
                'MQL_QueueId__c' => MQLQueueId,
                'Qualifying_Statuses__c' => 'Prospect\r\nOpen\r\nNurture\r\nRe-Engaged',
                'Ignored_Queues__c' => ''
            };
            Lead_MQL_Qualification_Settings__mdt customTestMeta1 = (Lead_MQL_Qualification_Settings__mdt)TestingUtility.createTestMeta('Lead_MQL_Qualification_Settings__mdt', meta1FieldValues);
            MQLSettingsTestMeta =  customTestMeta1;
        return MQLSettingsTestMeta;
    } set; }

    // PARTNER COMMUNITY LEAD SETTINGS TEST METADATA
    public static Partner_Community_Lead_Settings__mdt ParterCommunityLeadSettingsTestMeta {
    get {
            Map<String, Object> metaFieldValues = new Map<String, Object>{
                'Qualifying_Partner_Profiles__c' => '00eM0000000EB6mIAG - Conga Partner Community Login User HOTFIX\r\n00e1T000001QX3IQAW - Conga Partner Community Login User PROD\r\n00e2F000000IVGgQAO - Conga Partner Community Login User FULL\r\n00eK0000000JAiTIAW - Conga Partner Community Login User CODE',
                'Partner_Campaign_Id__c' => TestCampaignId,
                'Member_Status__c' => 'Responded',
                'Lead_Owner_Id__c' => '00G50000001CXjnEAG'
            };
            Partner_Community_Lead_Settings__mdt customTestMeta = (Partner_Community_Lead_Settings__mdt)TestingUtility.createTestMeta('Partner_Community_Lead_Settings__mdt', metaFieldValues);
            ParterCommunityLeadSettingsTestMeta = customTestMeta;
        return ParterCommunityLeadSettingsTestMeta;
    } set; }


    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setupTestData(){
    /*
        // TEST D&B INDUSTRY RECORDS
        DNB_Industry__c dnb1 = new DNB_Industry__c(Name = 'DNB1', NAICS_Description__c = 'Test1', NAICS_Code__c = '327910', SIC4_Description__c = 'Test1', SIC4_Code__c = '1234', Industry__c = 'Manufacturing');
        DNB_Industry__c dnb2 = new DNB_Industry__c(Name = 'DNB2', NAICS_Description__c = 'Test2', NAICS_Code__c = '327910', SIC4_Description__c = 'Test2', SIC4_Code__c = '5678', Industry__c = 'Manufacturing');
        DNB_Industry__c dnb3 = new DNB_Industry__c(Name = 'DNB3', NAICS_Description__c = 'Test3', NAICS_Code__c = '922140', SIC4_Description__c = 'Test3', SIC4_Code__c = '2468', Industry__c = 'Services and Consulting');
        insert new List<DNB_Industry__c>{ dnb1, dnb2, dnb3 };

        // GET LEAD MANAGER USER
        List<User> leadManager = [SELECT Id FROM User WHERE FirstName = 'Lead' AND LastName = 'Manager' LIMIT 1];
        System.assert(leadManager.size() == 1);

        // CREATE CUSTOM SETTING
        LMA_Lead_Owner_Round_Robin__c testSetting = new LMA_Lead_Owner_Round_Robin__c(Name = 'TestSetting', Lead_Owner_Id__c = leadManager[0].Id, Round_Robin_Number__c = 0);
        insert testSetting;

        // CREATE TEST CAMPAIGNS
        Campaign campaign1 = new Campaign(Name = 'Test Campaign 1', IsActive = TRUE, Product_Interest__c = 'Conga Composer');
        Campaign campaign2 = new Campaign(Name = 'Test Campaign 2', IsActive = TRUE, Product_Interest__c = 'Conga Composer');
        Campaign campaign3 = new Campaign(Name = 'Test Campaign 3', IsActive = TRUE, Product_Interest__c = 'Conga ActionGrid');
        Campaign inactiveCampaign = new Campaign(Name = 'Test Campaign 4', IsActive = FALSE, Product_Interest__c = 'Conga ActionGrid');
        insert new List<Campaign>{campaign1, campaign2, campaign3, inactiveCampaign};

        // TEST COUNTRY RECORDS 
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'AMER');
        Country_Territory__c newZealand = new Country_Territory__c(Name = 'New Zealand', Two_Letter_Code__c = 'NZ', Three_Letter_Code__c = 'NZL', Geo__c = 'APAC');
        insert new List<Country_Territory__c>{ unitedStates, newZealand };
   */
    }
  
    /**
    * @description leadFieldUpdatesTest
    */  
   /* public static testMethod void leadFieldUpdatesTest(){
        // CREATE TCS USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Success'];
        User tcsUser = new User(Alias = 'tcs1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', Geo__c = 'NA', 
        FirstName = 'TCS', LastName = 'Person', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'tcsUser1' + UserInfo.getOrganizationId() + '@testorg.com');
        insert tcsUser;

        // GET LEAD MANAGER USER
        List<User> leadManager = [SELECT Id, FirstName, LastName, Email, Phone, Title FROM User WHERE FirstName = 'Lead' AND LastName = 'Manager' LIMIT 1];
        System.assert(leadManager.size() == 1);

        // GET CURRENT USER
        List<User> currentUser = [SELECT Id, FirstName, LastName, Email, Phone, Title, Region__c FROM User WHERE Id = :UserInfo.getUserId()];
        System.assert(currentUser.size() == 1);

        // GET BUSINESS HOURS BY NAME
        Map<String, Id> bizHoursByName = new Map<String, Id>();
        for(BusinessHours bizHours : [SELECT Id, Name FROM BusinessHours]){
            bizHoursByName.put(bizHours.Name, bizHours.Id);
        }
        System.assert(bizHoursByName.size() == 3);

        Test.startTest();

        ///////// TEST LEAD INSERTS
        // Conga Lead
        Lead testLead1 = new Lead(LastName = 'TestLead1', Company = 'Conga', LeadSource = 'AppExchange', Status = 'New');
        insert testLead1;
        // Created By TCS Lead
        Lead testLead2 = new Lead(LastName = 'TestLead1', Company = 'Acme', Country = 'United States', LeadSource = 'TCS Referral', RecordTypeId = UtilityClass.getRecordTypesForObject('Lead').get('Standard_Record_Type'));
        System.runAs(tcsUser){
            insert testLead2;
        }

        List<Lead> testLeads = [SELECT Id, OwnerId, Owner_First_Name__c, OwnerLastName__c, OwnerEmail__c, OwnerPhone__c, OwnerTitle__c, Status, Lead_Status_Reason__c 
                                FROM Lead WHERE Id = :testLead1.Id OR Id = :testLead2.Id];
        System.assert(testLeads.size() == 2);
        System.assert(testLeads[0].Lead_Status_Reason__c == 'Researcher (Consultant/Analyst)');
        System.assert(testLeads[0].Status == 'Disqualified');
        System.assert(testLeads[0].Owner_First_Name__c == currentUser[0].FirstName);
        System.assert(testLeads[0].OwnerLastName__c == currentUser[0].LastName);
        System.assert(testLeads[0].OwnerEmail__c == currentUser[0].Email);
        System.assert(testLeads[0].OwnerPhone__c == currentUser[0].Phone);
        System.assert(testLeads[0].OwnerTitle__c == currentUser[0].Title);
        System.assert(testLeads[1].OwnerId == leadManager[0].Id);
        System.assert(testLeads[1].Owner_First_Name__c == leadManager[0].FirstName);
        System.assert(testLeads[1].OwnerLastName__c == leadManager[0].LastName);
        System.assert(testLeads[1].OwnerEmail__c == leadManager[0].Email);
        System.assert(testLeads[1].OwnerPhone__c == leadManager[0].Phone);
        System.assert(testLeads[1].OwnerTitle__c == leadManager[0].Title);

        ////////// TEST LEAD UPDATES
        testLead1.Status = 'In Process';
        testLead1.Lead_Status_Reason__c = null;
        testLead2.LeadSource = 'ZoomInfo';
        testLead2.OwnerId = UserInfo.getUserId();
        testLead2.Business_Hours__c = bizHoursByName.get('Default');
        update new List<Lead>{ testLead1, testLead2 };

        testLeads = [SELECT Id, LeadSource, Owner_First_Name__c, OwnerLastName__c, OwnerEmail__c, OwnerPhone__c, OwnerTitle__c, FPR__c, Time_To_First_User_Hours__c,
                            First_User_Date__c, Status_Last_Changed__c, Lead_Status_Updated__c, Owner_Region__c, Reporting_Closed_Lead_Count__c, Reporting_Opty_Created_Lead_Count__c
                     FROM Lead WHERE Id IN :testLeads];
        System.assert(testLeads[0].Status_Last_Changed__c != null);
        System.assert(testLeads[0].Lead_Status_Updated__c != null);
        System.assert(testLeads[0].Owner_Region__c == currentUser[0].Region__c);
        System.assert(testLeads[1].LeadSource == 'Prospecting');
        System.assert(testLeads[1].Time_To_First_User_Hours__c != null);
        System.assert(testLeads[1].First_User_Date__c != null);
        System.assert(testLeads[1].Owner_First_Name__c == currentUser[0].FirstName);
        System.assert(testLeads[1].OwnerLastName__c == currentUser[0].LastName);
        System.assert(testLeads[1].OwnerEmail__c == currentUser[0].Email);
        System.assert(testLeads[1].OwnerPhone__c == currentUser[0].Phone);
        System.assert(testLeads[1].OwnerTitle__c == currentUser[0].Title);


        /////////// TEST LEAD CONVERSION
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(testLeads[1].Id);
        leadConvert.setConvertedStatus('Converted');
        Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConvert);
        System.assert(leadConvertResult.isSuccess());

        testLeads = [SELECT Id, Reporting_Closed_Lead_Count__c, Reporting_Opty_Created_Lead_Count__c FROM Lead WHERE Id IN :testLeads];
        System.assert(testLeads[1].Reporting_Closed_Lead_Count__c == 1);
        System.assert(testLeads[1].Reporting_Opty_Created_Lead_Count__c == 1);

        Test.stopTest();
    }*/

    /**
    * @description updateLeadIndustryTest - Test updateLeadIndustry trigger method
    */
    /* public static testMethod void updateLeadIndustryTest(){
        // GET TEST DNB INDUSTRY RECORDS
        List<DNB_Industry__c> dnbIndustries = [SELECT Id, Industry__c FROM DNB_Industry__c];
        System.assert(dnbIndustries.size() == 3);

        // CREATE TEST ACCOUNTS
        List<Lead> testLeads = TestingUtility.createSObjectList('Lead', true, 3);
        testLeads[0].LastName = 'Smith';
        testLeads[0].Company = 'Test Account ABC';
        testLeads[1].LastName = 'Doe';
        testLeads[1].Company = 'Test Account DEF';
        testLeads[2].LastName = 'Wilfred';
        testLeads[2].Company = 'Test Account GHI';
        insert testLeads;

        // CREATE TEST PARENT D&B RECORDS
        List<DNBoptimizer__DnBCompanyRecord__c> testParentDNBRecords = TestingUtility.createSObjectList('DNBoptimizer__DnBCompanyRecord__c', true, 3);
        testParentDNBRecords[0].DNBoptimizer__BusinessName__c = 'Test Account ABC';
        testParentDNBRecords[0].DNBoptimizer__NAICSCode1__c = '327910';
        testParentDNBRecords[0].DNBoptimizer__SIC4Code1__c = '1234';
        //
        testParentDNBRecords[1].DNBoptimizer__BusinessName__c = 'Test Account DEF';
        testParentDNBRecords[1].DNBoptimizer__NAICSCode1__c = '327910';
        testParentDNBRecords[1].DNBoptimizer__SIC4Code1__c = '5678';
        //
        testParentDNBRecords[2].DNBoptimizer__BusinessName__c = 'Test Account GHI';
        testParentDNBRecords[2].DNBoptimizer__NAICSCode1__c = '922140';
        testParentDNBRecords[2].DNBoptimizer__SIC4Code1__c = '2468';
        insert testParentDNBRecords;

        Test.startTest();

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testLeads = [SELECT Id, Industry FROM Lead WHERE Id IN :testLeads];
        System.assert(String.isBlank(testLeads[0].Industry));
        System.assert(String.isBlank(testLeads[1].Industry));
        System.assert(String.isBlank(testLeads[2].Industry));

        // ASSIGN PARENT D&B RECORDS TO ACCOUNTS
        testLeads[0].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[0].Id;
        testLeads[1].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[1].Id;
        testLeads[2].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[2].Id;
        update testLeads;

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testLeads = [SELECT Id, Industry FROM Lead WHERE Id IN :testLeads];
        System.assert(testLeads[0].Industry == dnbIndustries[0].Industry__c);
        System.assert(testLeads[1].Industry == dnbIndustries[1].Industry__c);
        System.assert(testLeads[2].Industry == dnbIndustries[2].Industry__c);

        // CHANGE ASSIGNMENTS
        testLeads[0].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[2].Id;
        testLeads[1].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[0].Id;
        testLeads[2].DNBoptimizer__DnBCompanyRecord__c = null;
        update testLeads;

        // REFRESH ACCOUNTS AND CHECK THAT INDUSTRIES DID NOT CHANGE
        testLeads = [SELECT Id, Industry FROM Lead WHERE Id IN :testLeads];
        System.assert(testLeads[0].Industry == dnbIndustries[0].Industry__c);
        System.assert(testLeads[1].Industry == dnbIndustries[1].Industry__c);
        System.assert(testLeads[2].Industry == dnbIndustries[2].Industry__c);

        Test.stopTest();
    } */

    /**
    * @description updateBusinessHoursTest - Test for the updateBusinessHours trigger method
    */  
    /* public static testMethod void updateBusinessHoursTest(){
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User naGeoUser = new User(Alias = 'naUser', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', Geo__c = 'AMER', 
        FirstName = 'AMER', LastName = 'User', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'naGeoUser' + UserInfo.getOrganizationId() + '@testorg.com');
        User apacGeoUser = new User(Alias = 'apacUser', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', Geo__c = 'APAC',
        FirstName = 'APAC', LastName = 'User', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'apacGeoUser' + UserInfo.getOrganizationId() + '@testorg.com');
        User emeaGeoUser = new User(Alias = 'emeaUser', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', Geo__c = 'EMEA',
        FirstName = 'EMEA', LastName = 'User', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'emeaGeoUser' + UserInfo.getOrganizationId() + '@testorg.com');
        insert new List<User>{ naGeoUser, apacGeoUser, emeaGeoUser };

        // GET BUSINESS HOURS BY NAME
        Map<String, Id> bizHoursByName = new Map<String, Id>();
        for(BusinessHours bizHours : [SELECT Id, Name FROM BusinessHours]){
            bizHoursByName.put(bizHours.Name, bizHours.Id);
        }
        System.assert(bizHoursByName.size() == 3);

        Test.startTest();

        // CREATE TEST LEADS
        Lead testLead1 = new Lead(LastName = 'AMER', Company = 'Test', Status = 'New', OwnerId = naGeoUser.Id);
        Lead testLead2 = new Lead(LastName = 'APAC', Company = 'Test', Status = 'New', OwnerId = apacGeoUser.Id);
        Lead testLead3 = new Lead(LastName = 'EMEA', Company = 'Test', Status = 'New', OwnerId = emeaGeoUser.Id);
        insert new List<Lead>{ testLead1, testLead2, testLead3 };

        // RELOAD LEADS AND TEST FOR CORRECT BIZ HOURS
        List<Lead> testLeads = [SELECT Id, Business_Hours__c FROM Lead WHERE Id = :testLead1.Id OR Id = :testLead2.Id OR Id = :testLead3.Id];
        System.assert(testLeads.size() == 3);
        System.assert(testLeads[0].Business_Hours__c == bizHoursByName.get('Default'));
        System.assert(testLeads[1].Business_Hours__c == bizHoursByName.get('APAC Business Hours'));
        System.assert(testLeads[2].Business_Hours__c == bizHoursByName.get('EMEA Business Hours'));

        // SWITCH OWNERS
        testLeads[0].OwnerId = apacGeoUser.Id;
        testLeads[1].OwnerId = emeaGeoUser.Id;
        testLeads[2].OwnerId = naGeoUser.Id;
        update testLeads;

        // RELOAD LEADS AND TEST FOR CORRECT BIZ HOURS
        testLeads = [SELECT Id, Business_Hours__c FROM Lead WHERE Id = :testLead1.Id OR Id = :testLead2.Id OR Id = :testLead3.Id];
        System.assert(testLeads[0].Business_Hours__c == bizHoursByName.get('APAC Business Hours'));
        System.assert(testLeads[1].Business_Hours__c == bizHoursByName.get('EMEA Business Hours'));
        System.assert(testLeads[2].Business_Hours__c == bizHoursByName.get('Default'));

        Test.stopTest();
    } */

    /**
    * @description processMQLQualificationTest - Test for the processMQLQualification trigger method
    */  
   /* public static testMethod void processMQLQualificationTest(){
        // GET MQL QUEUE 
        List<Group> mqlQueue = [SELECT Id FROM Group WHERE DeveloperName = 'MQL_Queue' AND Type = 'Queue' LIMIT 1];
        System.assert(mqlQueue.size() == 1, 'No MQL Queue has been created in the Org');
        MQLQueueId = mqlQueue[0].Id;

        Test.startTest();

        // CREATE TEST LEAD
        Lead testLead = new Lead(LastName = 'TestLead1', Title = 'Director', Company = 'Acme', LeadSource = 'AppExchange', Status = 'Open');
        insert testLead;

        // RELOAD LEAD AND TEST FOR CORRECT DATA
        testLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLead.Id LIMIT 1];
        System.assert(testLead.OwnerId == mqlQueue[0].Id);

        // CHANGE LEAD SO IT QUALIFIES FOR AN MQL GROUP
        testLead.Account_Rank__c = 'C';
        testLead.engagio__EngagementMinutesLast3Months__c = 5;
        update testLead;

        // RELOAD LEAD AND TEST FOR CORRECT DATA
        testLead = [SELECT Id, OwnerId, MQL_Date_Stamp__c FROM Lead WHERE Id = :testLead.Id LIMIT 1];
        System.assert(testLead.OwnerId != mqlQueue[0].Id);
        System.assert(testLead.MQL_Date_Stamp__c != null);

        // CHECK FOR NEW MQL QUALIFICATION RECORD
        List<MQL_Qualification__c> qualificationRecords = [SELECT Id, Lead_Title__c, Date_Time__c, Group__c, Engagement_Minutes__c FROM MQL_Qualification__c WHERE LeadId__c = :testLead.Id];
        System.assert(qualificationRecords.size() == 1);
        System.assert(qualificationRecords[0].Lead_Title__c == 'Director');
        System.assert(qualificationRecords[0].Date_Time__c != null);
        System.assert(qualificationRecords[0].Group__c == 'Group 2');
        System.assert(qualificationRecords[0].Engagement_Minutes__c == 5);

        // CHANGE LEAD SO IT QUALIFIES FOR GROUP 2 AGAIN
        testLead.engagio__EngagementMinutesLast3Months__c = 6;
        update testLead;

        // CHECK FOR NEW MQL QUALIFICATION RECORD
        qualificationRecords = [SELECT Id FROM MQL_Qualification__c WHERE LeadId__c = :testLead.Id];
        System.assert(qualificationRecords.size() == 1);

        // CHANGE LEAD SO IT QUALIFIES FOR GROUP 3
        testLead.Account_Rank__c = 'D';
        testLead.engagio__EngagementMinutesLast3Months__c = 10;
        update testLead;

        // CHECK FOR NEW MQL QUALIFICATION RECORD
        qualificationRecords = [SELECT Id, Lead_Title__c, Date_Time__c, Group__c, Engagement_Minutes__c FROM MQL_Qualification__c WHERE LeadId__c = :testLead.Id];
        System.assert(qualificationRecords.size() == 2);
        System.assert(qualificationRecords[1].Lead_Title__c == 'Director');
        System.assert(qualificationRecords[1].Date_Time__c != null);
        System.assert(qualificationRecords[1].Group__c == 'Group 3');
        System.assert(qualificationRecords[1].Engagement_Minutes__c == 10);

        Test.stopTest();
    } */

    /**
    * @description processNewPartnerCommunityLeadTest - Test for the processNewPartnerCommunityLead trigger method
    */  
    /* public static testMethod void processNewPartnerCommunityLeadTest(){
        // CREATE TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account', false);
        testAccount.RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');
        insert testAccount;

        // CREATE TEST CONTACT
        Contact testPartnerContact = (Contact)TestingUtility.createSObject('Contact', false);
        testPartnerContact.AccountId = testAccount.Id;
        insert testPartnerContact;

        // CREATE TEST PARTNER COMMUNITY USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Partner Community Login User'];
        User partnerCommUser = new User(Alias = 'partner1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', 
        FirstName = 'Partner', LastName = 'Person1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'partner1' + UserInfo.getOrganizationId() + '@testorg.com', ContactId = testPartnerContact.Id);
        insert partnerCommUser;

        // GET TEST CAMPAIGNS
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign 1'];
        System.assert(!testCampaigns.isEmpty());
        TestCampaignId = testCampaigns[0].Id;

        Test.startTest();

        Partner_Community_Lead_Settings__mdt testMeta = ParterCommunityLeadSettingsTestMeta;
        Lead testLead = new Lead(LastName = 'TestLead1', Title = 'Director', Company = 'Acme', LeadSource = 'AppExchange', Status = 'Open');
        System.runAs(partnerCommUser){
            // CREATE TEST LEAD
            insert testLead;
        }

        // RELOAD LEAD AND TEST FOR CORRECT DATA
        testLead = [SELECT Id, CreatedById, OwnerId, Partner__c FROM Lead WHERE Id = :testLead.Id];
        System.assert(testLead.CreatedById == partnerCommUser.Id);
        System.assert(testLead.OwnerId == testMeta.Lead_Owner_Id__c);
        System.assert(testLead.Partner__c == testAccount.Id);

        // CHECK FOR CORRECT CAMPAIGN MEMBER
        List<CampaignMember> members = [SELECT Id, LeadId, Status FROM CampaignMember WHERE CampaignId = :TestCampaignId LIMIT 1];
        System.assert(!members.isEmpty());
        System.assert(members[0].LeadId == testLead.Id);
        System.assert(members[0].Status == testMeta.Member_Status__c);

        Test.stopTest();
    } */

    /**
    * @description addCampaignMembersTest
    */  
    /* public static testMethod void addCampaignMembersTest(){
        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign 1'];
        System.assert(testCampaigns.size() == 1);

        Lead lead = new Lead(LastName = 'Test', Email = 'Test@test.com', Company = 'Test Company');
        insert lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, lead.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id];
        System.assertEquals(TRUE, members.isEmpty());
        
        Test.startTest();

        lead.SF_Campaign_ID__c = testCampaigns[0].Id;
        update lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id =: lead.Id];
        System.assertNotEquals(null, lead.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id, lead.SF_Campaign_ID__c);
        
        members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id];
        System.assertEquals(FALSE, members.isEmpty());
        System.assertEquals(1, members.size());
        System.assertEquals(lead.Id, members[0].LeadId);
        System.assertEquals(testCampaigns[0].Id, members[0].CampaignId);

        Test.stopTest();
    }*/

    /**
    * @description addCampaignMembersTest_Existing
    */  
    /*public static testMethod void addCampaignMembersTest_Existing(){
        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign 1'];
        System.assert(testCampaigns.size() == 1);

        // CREATE TEST LEAD AND ENSURE IT DOES NOT YET HAVE A VALUE IN SF_Campaign_ID__c
        Lead lead = new Lead(LastName = 'Test', Email = 'Test@test.com', Company = 'Test Company');
        insert lead;
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assert(lead.SF_Campaign_ID__c == null);

        CampaignMember existingMember = new CampaignMember(LeadId = lead.Id, CampaignId = testCampaigns[0].Id, Status = 'Sent');
        insert existingMember;

        Test.startTest();

        lead.SF_Campaign_ID__c = testCampaigns[0].Id;
        update lead;

        // TEST FOR PROPERLY UPDATED LEAD
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id =: lead.Id];
        System.assertNotEquals(null, lead.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id, lead.SF_Campaign_ID__c);

        // TEST THAT ONLY ONE MEMBER EXISTS, ANOTHER SHOULD NOT HAVE BEEN CREATED
        List<CampaignMember> members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id];
        System.assertEquals(false, members.isEmpty());
        System.assertEquals(1, members.size());
        System.assertEquals(lead.Id, members[0].LeadId);
        System.assertEquals(testCampaigns[0].Id, members[0].CampaignId);  

        Test.stopTest(); 
    } */

    /**
    * @description addCampaignMembersTest_Multiple
    */      
    /*public static testMethod void addCampaignMembersTest_Multiple(){
        // GET TEST CAMPAIGNS
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name IN ('Test Campaign 1','Test Campaign 2','Test Campaign 3')];
        System.assert(testCampaigns.size() == 3);

        Lead lead = new Lead(LastName = 'Test', Email = 'Test@test.com', Company = 'Test Company');
        insert lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, lead.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id];
        System.assertEquals(TRUE, members.isEmpty());
        
        Test.startTest();

        string campIDs = testCampaigns[0].Id + ',' + testCampaigns[1].Id + ';' + testCampaigns[2].Id;
        lead.SF_Campaign_ID__c = campIDs;
        update lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, lead.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id + ',' + testCampaigns[1].Id + ';' + testCampaigns[2].Id, lead.SF_Campaign_ID__c);
        
        members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id ORDER BY CampaignId];
        System.assertEquals(FALSE, members.isEmpty());
        System.assertEquals(3, members.size());
        System.assertEquals(lead.Id, members[0].LeadId);
        System.assertEquals(lead.Id, members[1].LeadId);
        System.assertEquals(lead.Id, members[2].LeadId);
        System.assertEquals(testCampaigns[0].Id, members[0].CampaignId);
        System.assertEquals(testCampaigns[1].Id, members[1].CampaignId);
        System.assertEquals(testCampaigns[2].Id, members[2].CampaignId);

        Test.stopTest();
    } */

    /**
    * @description addCampaignMembersTest_InactiveCampaign
    */   
    /*public static testMethod void addCampaignMembersTest_InactiveCampaign(){   
        // GET TEST CAMPAIGNS
        List<Campaign> inactiveCampaigns = [SELECT Id FROM Campaign WHERE IsActive = false];
        System.assert(inactiveCampaigns.size() == 1);

        Lead lead = new Lead(LastName = 'Test', Email = 'Test@test.com', Company = 'Test Company');
        Insert lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, lead.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id];
        System.assertEquals(TRUE, members.isEmpty());
        
        Test.startTest();

        lead.SF_Campaign_ID__c = inactiveCampaigns[0].Id;
        update lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, lead.SF_Campaign_ID__c);
        System.assertEquals(inactiveCampaigns[0].Id, lead.SF_Campaign_ID__c);
        
        members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id ORDER BY CampaignId];
        System.assertEquals(TRUE, members.isEmpty());
        System.assertEquals(0, members.size());

        Test.stopTest();
    } */

    /**
    * @description addCampaignMembersTest_NonExistingCampaign
    */         
    /* public static testMethod void addCampaignMembersTest_NonExistingCampaign(){      
        Lead lead = new Lead(LastName = 'Test', Email = 'Test@test.com', Company = 'Test Company');
        Insert lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, lead.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id];
        System.assertEquals(TRUE, members.isEmpty());
        
        Test.startTest();

        lead.SF_Campaign_ID__c = '7011800000XXXXX';
        update lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, lead.SF_Campaign_ID__c);
        System.assertEquals('7011800000XXXXX', lead.SF_Campaign_ID__c);
        
        members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id ORDER BY CampaignId];
        System.assertEquals(TRUE, members.isEmpty());
        System.assertEquals(0, members.size());

        Test.stopTest();
    } */

    /**
    * @description addCampaignMembersTest_InvalidCampaignId
    */         
    /*public static testMethod void addCampaignMembersTest_InvalidCampaignId(){      
        Lead lead = new Lead(LastName = 'Test', Email = 'Test@test.com', Company = 'Test Company');
        Insert lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, lead.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id];
        System.assertEquals(TRUE, members.isEmpty());
        
        Test.startTest();

        lead.SF_Campaign_ID__c = '7011800000XXXXX ()';
        update lead;
        
        lead = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, lead.SF_Campaign_ID__c);
        System.assertEquals('7011800000XXXXX ()', lead.SF_Campaign_ID__c);
        
        members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :lead.Id ORDER BY CampaignId];
        System.assertEquals(TRUE, members.isEmpty());
        System.assertEquals(0, members.size());

        List<System_Issue_Log__c> loggedErrors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(!loggedErrors.isEmpty());

        Test.stopTest();
    } */

    /**
    * @description addCampaignMembersTest_MultipleLead
    */
    /* public static testMethod void addCampaignMembersTest_MultipleLead(){
        // GET TEST CAMPAIGNS
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name IN ('Test Campaign 1','Test Campaign 2')];
        System.assert(testCampaigns.size() == 2);

        Lead lead1 = new Lead(LastName = 'Test 1', Email = 'Test@test.com', Company = 'Test Company');
        Lead lead2 = new Lead(LastName = 'Test 2', Email = 'Test@test.com', Company = 'Test Company');
        insert new List<Lead>{lead1,lead2};
        
        lead1 = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id =: lead1.Id];
        lead2 = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id =: lead2.Id];
        System.assertEquals(null, lead1.SF_Campaign_ID__c);
        System.assertEquals(null, lead2.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId =: lead1.Id Or LeadId =: lead2.Id];
        System.assertEquals(TRUE, members.isEmpty());
        
        Test.startTest();

        lead1.SF_Campaign_ID__c = testCampaigns[0].Id;
        lead2.SF_Campaign_ID__c = testCampaigns[1].Id;
        update new List<Lead>{ lead1, lead2 };
        
        lead1 = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id =: lead1.Id];
        lead2 = [SELECT Id, SF_Campaign_ID__c FROM Lead WHERE Id =: lead2.Id];
        System.assertNotEquals(null, lead1.SF_Campaign_ID__c);
        System.assertNotEquals(null, lead2.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id, lead1.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[1].Id, lead2.SF_Campaign_ID__c);
        
        members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId =: lead1.Id OR LeadId =: lead2.Id];
        System.assertEquals(FALSE, members.isEmpty());
        System.assertEquals(2, members.size());
        System.assertEquals(lead1.Id, members[0].LeadId);
        System.assertEquals(lead2.Id, members[1].LeadId);
        System.assertEquals(testCampaigns[0].Id, members[0].CampaignId);
        System.assertEquals(testCampaigns[1].Id, members[1].CampaignId);

        Test.stopTest();
    } */

    /**
    * @description addCampaignMembersTest_LicenseCampaigns
    */
    /* public static testMethod void addCampaignMembersTest_LicenseCampaigns(){
        // GET TEST CAMPAIGNS
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name IN ('Test Campaign 1','Test Campaign 2','Test Campaign 3')];
        System.assert(testCampaigns.size() == 3);

        // TEST PACKAGE
        sfLma__Package__c testPackage1 = new sfLma__Package__c(Name = 'Conga Composer', sfLma__Latest_Version__c = '1.0');
        sfLma__Package__c testPackage2 = new sfLma__Package__c(Name = 'Conga Grid', sfLma__Latest_Version__c = '1.0');
        insert new List<sfLma__Package__c>{ testPackage1, testPackage2 };

        // TEST PACKAGE VERSION
        sfLma__Package_Version__c testPackageVersion1 = new sfLma__Package_Version__c(Name = '1.0', sfLma__Package__c = testPackage1.Id, sfLma__Version__c = '1.0');
        sfLma__Package_Version__c testPackageVersion2 = new sfLma__Package_Version__c(Name = '1.0', sfLma__Package__c = testPackage2.Id, sfLma__Version__c = '1.0');
        insert new List<sfLma__Package_Version__c>{ testPackageVersion1, testPackageVersion2 };

        Lead testLead = new Lead(LastName = 'Test', Email = 'Test@test.com', Company = 'Test Company', AppExchange_Type__c = 'Install');
        insert testLead;

        Test.startTest();

        TestCampaignId = testCampaigns[0].Id;
        TestCampaignId2 = testCampaigns[2].Id;
        sfLma__License__c testLicense1 = new sfLma__License__c(sfLma__Lead__c = testLead.Id, sfLma__Package_Version__c = testPackageVersion1.Id);
        sfLma__License__c testLicense2 = new sfLma__License__c(sfLma__Lead__c = testLead.Id, sfLma__Package_Version__c = testPackageVersion2.Id);
        insert new List<sfLma__License__c>{ testLicense1, testLicense2 };
        
        List<CampaignMember> members = [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE LeadId = :testLead.Id];
        System.assert(members != null && members.size() == 2);
        System.assert(members[0].LeadId == testLead.Id);
        System.assert(members[0].CampaignId == testCampaigns[0].Id);
        System.assert(members[1].LeadId == testLead.Id);
        System.assert(members[1].CampaignId == testCampaigns[2].Id);

        Test.stopTest();
    }*/

    /**
    * @description insertLeadWithoutCountryTest
    */ 
    /*public static testmethod void insertLeadWithoutCountryTest() {
        // Insert lead record without specifying Country__c nor Region__c
        Test.startTest();
        Lead lead = new Lead(LastName = 'Test', Company = 'Test', LeadSource = 'Inbound', Status = 'New');
        insert lead;
        Test.stopTest();

        // Test that record is insertend and that both fields are still null 
        List<Lead> leadList = [SELECT Country, Region__c FROM Lead WHERE Id = :lead.Id];
        System.assert(leadList.size() == 1);
        System.assert(leadList[0].Country == null);
        System.assert(leadList[0].Region__c == null);
    }*/

    /**
    * @date 20180626
    * @description insertLeadWithCountryTest - 
    */
    /*public static testmethod void insertLeadWithCountryTest() {
        // GET TEST COUNTRIES
        List<Country_Territory__c> testCountries = [SELECT Id, Name, Geo__c FROM Country_Territory__c WHERE Name = 'United States'];
        System.assert(testCountries.size() == 1);

        Test.startTest();

        Lead lead = new Lead(LastName = 'Test', Company = 'Test', LeadSource = 'Inbound', Status = 'New', Country = testCountries[0].Name);
        insert lead;

        Test.stopTest();

        // Recover inserted lead and check for correct values.
        List<Lead> leadList = [SELECT Country, Region__c FROM Lead WHERE Id = :lead.Id];
        System.assert(leadList.size() == 1);
        System.assert(leadList[0].Country == testCountries[0].Name);
        System.assert(leadList[0].Region__c == testCountries[0].Geo__c);
    }*/

    /**
    * @date 20180626
    * @description updateLeadWithCountryTest - 
    */
    /*public static testmethod void updateLeadWithCountryTest() {
        // GET TEST COUNTRIES
        List<Country_Territory__c> testCountries = [SELECT Id, Name, Geo__c FROM Country_Territory__c];
        System.assert(testCountries.size() == 2);

        // Get the first country of the list to lead insertion
        Lead lead = new Lead(LastName = 'Test', Company = 'Test', LeadSource = 'Inbound', Status = 'New', Country = testCountries[0].Name);
        insert lead;

        Test.startTest();

        // Recover inserted lead and change country 
        List<Lead> leadList = [SELECT Country, Region__c FROM Lead WHERE Id = :lead.Id];
        System.assert(leadList.size() == 1);
        leadList[0].Country = testCountries[1].Name;
        update leadList;

        // Recover updated record and check region change
        leadList = [SELECT Country, Region__c FROM Lead WHERE Id = :lead.Id];
        System.assert(leadList.size() == 1);
        System.assert(leadList[0].Region__c == testCountries[1].Geo__c);

        // Set country to null and update record
        leadList[0].Country = null;
        update leadList;

        Test.stopTest();

        // Check Region__c cleared after update
        leadList = [SELECT Country, Region__c FROM Lead WHERE Id = :lead.Id];
        System.assert(leadList.size() == 1);
        System.assert(leadList[0].Country == null);
        System.assert(leadList[0].Region__c == null);
    }*/
    
    /**
    * @date 20180626
    * @description updateTimetoFPRCalcTest - 
    */
    /*public static testmethod void updateTimetoFPRCalcTest() {
        // CREATE A TEST LEAD
        Lead lead = new Lead(LastName = 'Test', Company = 'Test', LeadSource = 'Inbound', Status = 'New', Country = 'United States');
        insert lead;

        // GET DEFAULT BUSINESS HOURS RECORD
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE IsActive = true AND IsDefault = true];
        System.assert(businessHoursList != null);
        System.assert(!businessHoursList.isEmpty());

        Test.startTest();

        // MAKE QUALIFYING UPDATES TO THE LEAD           
        lead.Business_Hours__c = businessHoursList[0].Id;
        lead.FPR__c = Date.today().addDays(30);
        update lead;

        // TEST FOR CALCULATED TIME TO FPR BUSINESS HOURS VALUE
        List<Lead> leadList = [SELECT Id, Time_to_FPR_Hours__c FROM Lead WHERE Id = :lead.Id];
        System.assert(!leadList.isEmpty());     
        System.assert(leadList[0].Time_to_FPR_Hours__c > 0);

        // MAKE QUALIFYING UPDATES TO THE LEAD           
        lead.FPR__c = Date.today().addDays(35);
        lead.First_User_Date__c = Date.today().addDays(32);
        update lead;

        // TEST FOR CALCULATED TIME TO FPR BUSINESS HOURS VALUE
        leadList = [SELECT Id, First_User_to_FPR_Business_Hours__c FROM Lead WHERE Id = :lead.Id];
        System.assert(!leadList.isEmpty());      
        System.assert(leadList[0].First_User_to_FPR_Business_Hours__c > 0);

        Test.stopTest();
    }*/

    /**
    * @date 20180917
    * @description updateLeadSourceAppExchangeTypeTest - 
    */
    /*public static testmethod void updateLeadSourceAppExchangeTypeTest() {
        // CREATE A TEST LEAD
        List<Lead> testLeads = new List<Lead>();
        Lead testLead1 = new Lead(LastName = 'Install1', Company = 'Test', LeadSource = 'Package Installation', Status = 'New', Country = 'United States'); // LEAD SOURCE INSERT TEST
        Lead testLead2 = new Lead(LastName = 'Install2', Company = 'Test', LeadSource = 'Inbound', Status = 'New', Country = 'United States'); // LEAD SOURCE UPDATE TEST
        Lead testLead3 = new Lead(LastName = 'Demo1', Company = 'Test', LeadSource = 'SFDC-dup-DM', Status = 'New', Country = 'United States'); // LEAD SOURCE INSERT TEST
        Lead testLead4 = new Lead(LastName = 'Demo2', Company = 'Test', LeadSource = 'Inbound', Status = 'New', Country = 'United States'); // LEAD SOURCE UPDATE TEST
        Lead testLead5 = new Lead(LastName = 'Site', Company = 'Test', LeadSource = 'Site', Status = 'New', Country = 'United States'); // LEAD SOURCE INSERT TEST        
        Lead testLead6 = new Lead(LastName = 'Overlay', Company = 'Test', LeadSource = 'Overlay', Status = 'New', Country = 'United States'); // LEAD SOURCE INSERT TEST        
        testLeads.add(testLead1); testLeads.add(testLead2); testLeads.add(testLead3); testLeads.add(testLead4); testLeads.add(testLead5); testLeads.add(testLead6);

        Test.startTest();

        insert testLeads;

        testLead2.LeadSource = 'SFDC-IN';
        testLead4.LeadSource = 'SFDC-DM';
        update testLeads;

        // TEST FOR CALCULATED TIME TO FPR BUSINESS HOURS VALUE
        testLeads = [SELECT Id, LeadSource, AppExchange_Type__c, Channel_Source_2__c FROM Lead WHERE Id IN :testLeads];
        System.assert(testLeads != null && !testLeads.isEmpty() && testLeads.size() == 6);
        System.assert(testLeads[0].LeadSource == 'AppExchange' && testLeads[0].Channel_Source_2__c == 'Digital' && testLeads[0].AppExchange_Type__c == 'Install');    
        System.assert(testLeads[1].LeadSource == 'AppExchange' && testLeads[1].Channel_Source_2__c == 'Digital' && testLeads[1].AppExchange_Type__c == 'Install');    
        System.assert(testLeads[2].LeadSource == 'AppExchange' && testLeads[2].Channel_Source_2__c == 'Digital' && testLeads[2].AppExchange_Type__c == 'Demo');       
        System.assert(testLeads[3].LeadSource == 'AppExchange' && testLeads[3].Channel_Source_2__c == 'Digital' && testLeads[3].AppExchange_Type__c == 'Demo');
        System.assert(testLeads[4].LeadSource == 'AppExchange' && testLeads[4].Channel_Source_2__c == 'Digital' && String.isBlank(testLeads[4].AppExchange_Type__c));       
        System.assert(testLeads[5].LeadSource == 'AppExchange' && testLeads[5].Channel_Source_2__c == 'Digital' && String.isBlank(testLeads[5].AppExchange_Type__c));    

        Test.stopTest();
    }*/


}