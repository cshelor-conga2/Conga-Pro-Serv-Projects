/**
* @author Conga Services, ERedding
* @version 1.00
* @description CampaignMemberHelperTsest - Test class for the CampaignMemberHelper class
*/
@isTest
public with sharing class CampaignMemberHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setupTestData(){
        // CREATE TEST LEAD MANAGER USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testLeadManager = new User(
            Alias = 'standt',
            Email = 'salesforce@getconga.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Lead',
            IsActive = true,
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Denver ',
            UserName = 'testUser' + UserInfo.getOrganizationId()+'@testorg.com'
        );
        insert testLeadManager;

        // CREATE CUSTOM SETTING
        LMA_Lead_Owner_Round_Robin__c testSetting = new LMA_Lead_Owner_Round_Robin__c(Name = 'TestSetting', Lead_Owner_Id__c = testLeadManager.Id, Round_Robin_Number__c = 0);
        insert testSetting;

        // CREATE TEST CAMPAIGNS
        Campaign testCampaign1 = new Campaign(Name = 'Test Campaign', IsActive = true, Product_Interest__c = 'Conga Composer');
        Campaign testCampaign2 = new Campaign(Name = 'Test Campaign 2', IsActive = true, Product_Interest__c = 'Conga ActionGrid');
        insert new List<Campaign>{ testCampaign1, testCampaign2 };

        // CREATE TEST CONTACT
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert testContact;
        
        // CREATE TEST LEAD
        Lead testLead = new Lead(Status = 'Open', LastName = 'Test', Company = 'Test Company');
        insert testLead;

        // CREATE TEST CAMPAIGN MEMBERS
        List<CampaignMember> testMembers = TestingUtility.createSObjectList('CampaignMember', false, 4);
        for(CampaignMember member : testMembers){
            member.Status = 'Sent';
        }

        testMembers[0].CampaignId = testCampaign1.Id;
        testMembers[0].ContactId = testContact.Id;
        testMembers[1].CampaignId = testCampaign2.Id;
        testMembers[1].ContactId = testContact.Id;
        testMembers[2].CampaignId = testCampaign1.Id;
        testMembers[2].LeadId = testLead.Id;
        testMembers[3].CampaignId = testCampaign2.Id;
        testMembers[3].LeadId = testLead.Id;
        insert testMembers;
    }

    /**
    * @description setMostRecentCampaignTest - Test Happy Path of code 
    */
    public static testmethod void setMostRecentCampaignTest() {
        // GET TEST MEMBERS
        List<CampaignMember> testMembers = [SELECT Id, Status FROM CampaignMember];
        System.assert(testMembers != null && testMembers.size() == 4);

        Test.startTest();

        // UPDATE MEMBERS AND TEST FOR CORRECT DATA
        testMembers[0].Status = 'Responded';
        testMembers[2].Status = 'Responded';
        update testMembers;

        testMembers = [SELECT Id, FirstRespondedDate, Campaign.Name, Contact.Most_Recent_Campaign_Date__c, Contact.Most_Recent_Campaign__c, Lead.Most_Recent_Campaign_Date__c, Lead.Most_Recent_Campaign__c
                       FROM CampaignMember];
        System.assert(testMembers != null && testMembers.size() == 4);
        System.assert(testMembers[0].Contact.Most_Recent_Campaign_Date__c == testMembers[0].FirstRespondedDate);    
        System.assert(testMembers[0].Contact.Most_Recent_Campaign__c == testMembers[0].Campaign.Name);  
        System.assert(testMembers[2].Lead.Most_Recent_Campaign_Date__c == testMembers[2].FirstRespondedDate);   
        System.assert(testMembers[2].Lead.Most_Recent_Campaign__c == testMembers[2].Campaign.Name); 

        // UPDATE NEXT SET OF MEMBERS BELONGING TO A DIFFERENT CAMPAIGN AND TEST FOR CORRECT DATA
        testMembers[1].Status = 'Responded';
        testMembers[3].Status = 'Responded';
        update testMembers;

        testMembers = [SELECT Id, FirstRespondedDate, Campaign.Name, Contact.Most_Recent_Campaign_Date__c, Contact.Most_Recent_Campaign__c, Lead.Most_Recent_Campaign_Date__c, Lead.Most_Recent_Campaign__c
                       FROM CampaignMember];
        System.assert(testMembers != null && testMembers.size() == 4);
        System.assert(testMembers[1].Contact.Most_Recent_Campaign_Date__c == testMembers[1].FirstRespondedDate);    
        System.assert(testMembers[1].Contact.Most_Recent_Campaign__c == testMembers[1].Campaign.Name);  
        System.assert(testMembers[3].Lead.Most_Recent_Campaign_Date__c == testMembers[3].FirstRespondedDate);   
        System.assert(testMembers[3].Lead.Most_Recent_Campaign__c == testMembers[3].Campaign.Name);

        Test.stopTest();
    }

    /**
    * @description setMostRecentCampaignTest_Exceptions - Test Bad Data Exception handling
    */
    public static testmethod void setMostRecentCampaignTest_Exceptions() {
        // TRY RUNNING TRIGGER METHOD WITH NULL PARAMAETERS
        CampaignMemberHelper.setMostRecentCampaign(null, null);

        // TRY RUNNING TRIGGER METHOD WITH EMPTY PARAMETERS
        CampaignMemberHelper.setMostRecentCampaign(new List<CampaignMember>(), new Map<Id, CampaignMember>());
    }

    /**
    * @description updateLeadProductInterestTest - Test with Lead that has a single Campaign Member
    */
    public static testmethod void updateLeadProductInterestTest() {
        // ENSURE TEST CUSTOM SETTING EXISTS
        List<LMA_Lead_Owner_Round_Robin__c> testSetting = [SELECT Name FROM LMA_Lead_Owner_Round_Robin__c WHERE Round_Robin_Number__c = 0];
        System.assert(testSetting != null && testSetting.size() == 1);

        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id, Product_Interest__c FROM Campaign WHERE Name = 'Test Campaign'];
        System.assert(testCampaigns != null && testCampaigns.size() == 1);

        // CREATE TEST LEAD
        Lead testLead = new Lead(Status = 'Open', LastName = 'Test123', Company = 'Test Company', Block_Product_Interest_Owner_Update__c = true);
        insert testLead;

        // CREATE TEST MEMBERS
        CampaignMember testMember = new CampaignMember(LeadId = testLead.Id, CampaignId = testCampaigns[0].Id);

        Test.startTest();

        insert testMember;
        testLead = [SELECT Id, Product_Interest__c FROM Lead WHERE Id = :testLead.Id];
        System.assert(testLead != null);
        System.assert(testLead.Product_Interest__c == testCampaigns[0].Product_Interest__c);

        Test.stopTest();
    }

    /**
    * @description updateLeadProductInterestTest_MultipleProducts - Test with Lead that has multiple Campaign Members from Campaigns with differing Product Interests
    */
    public static testmethod void updateLeadProductInterestTest_MultipleProducts() {
        // ENSURE TEST CUSTOM SETTING EXISTS
        List<LMA_Lead_Owner_Round_Robin__c> testSetting = [SELECT Name FROM LMA_Lead_Owner_Round_Robin__c WHERE Round_Robin_Number__c = 0];
        System.assert(testSetting != null && testSetting.size() == 1);

        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id, Name, Product_Interest__c FROM Campaign WHERE Name IN ('Test Campaign','Test Campaign 2')];
        System.assert(testCampaigns != null && testCampaigns.size() == 2);

        // CREATE TEST LEAD
        Lead testLead = new Lead(Status = 'Open', LastName = 'Test123', Company = 'Test Company');
        insert testLead;

        // CREATE TEST MEMBERS
        CampaignMember testMember1 = new CampaignMember(LeadId = testLead.Id, CampaignId = testCampaigns[0].Id);
        CampaignMember testMember2 = new CampaignMember(LeadId = testLead.Id, CampaignId = testCampaigns[1].Id);      

        Test.startTest();

        insert new List<CampaignMember>{ testMember1, testMember2 };
        testLead = [SELECT Id, Product_Interest__c FROM Lead WHERE Id = :testLead.Id];
        System.assert(testLead != null);
        System.assert(testLead.Product_Interest__c == 'Multiple Product');

        Test.stopTest();
    }

    /**
    * @description updateLeadProductInterestTest_Exceptions - Test Bad Data Exception handling
    */
    public static testmethod void updateLeadProductInterestTest_Exceptions() {
        // TRY RUNNING TRIGGER METHOD WITH NULL PARAMAETERS
        CampaignMemberHelper.updateLeadProductInterest(null);

        // TRY RUNNING TRIGGER METHOD WITH EMPTY PARAMETERS
        CampaignMemberHelper.updateLeadProductInterest(new List<CampaignMember>());
    }


}