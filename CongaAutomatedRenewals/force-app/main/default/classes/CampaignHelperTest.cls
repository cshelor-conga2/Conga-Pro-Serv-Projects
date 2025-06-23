/**
* @author CustomerZero, RJain
* @date 20210115
* @version 1.00
* @description CampaignHelperTest - Test class for the CampaignHelper class
*/
@isTest
public class CampaignHelperTest {

    /**
    * @description setup - Create test data
    */
    @testSetup
    public static void setup() {
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
    * @description setApttusIntegrationOwnerTest - Test setApttusIntegrationOwner trigger method
    */
    public static testMethod void setApttusIntegrationOwnerTest(){
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'admin1', Email = 'salesforce@conga123.com', EmailEncodingKey = 'UTF-8', FirstName = 'Sales', LastName = 'Person', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', Team__c = 'US Corporate Sales',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert salesUser;

        User salesUser2 = new User(Alias = 'admin2', Email = 'salesforce@conga456.com', EmailEncodingKey = 'UTF-8', FirstName = 'Sales', LastName = 'Person 2', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', Team__c = 'US Corporate Sales',
        UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert salesUser2;

        // CREATE TEST ACCOUNTS, TEST INSERTS
        List<Campaign> testCampaigns = TestingUtility.createSObjectList('Campaign', true, 1);
        testCampaigns[0].A1_Owner_Email__c = 'salesforce@conga456.com';
        insert testCampaigns;

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testCampaigns = [SELECT Id, OwnerId, A1_Owner_Email__c FROM Campaign WHERE Id IN :testCampaigns];
        
        // TEST UPDATES
        testCampaigns[0].A1_Owner_Email__c = 'salesforce@conga123.com';
        update testCampaigns;
   }

}