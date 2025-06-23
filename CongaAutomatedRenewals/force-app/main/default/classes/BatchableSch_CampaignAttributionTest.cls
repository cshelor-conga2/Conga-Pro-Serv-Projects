/**
* @author ECS, ERedding
* @date 20200131
* @version 1.00
* @description BatchableSch_CampaignAttributionTest  - Test class for the BatchableSch_CampaignAttribution class
*/
@isTest
public with sharing class BatchableSch_CampaignAttributionTest {

    // CAMPAIGN ATTRIBUTION GROUP TEST METADATA
    public static List<Campaign_Attribution_Criteria_Group__mdt> CriteriaGroupTestMeta {
    get {
            Map<String, Object> meta1FieldValues = new Map<String, Object>{ 
                'Is_Active__c' => true,
                'Campaign_Id__c' => TMTestCampaignId,
                'Inactivity_Theshold__c' => 90
            };
            Map<String, Object> meta2FieldValues = new Map<String, Object>{ 
                'Is_Active__c' => true,
                'Campaign_Id__c' => PartnerTestCampaignId,
                'Inactivity_Theshold__c' => 90
            };
            Map<String, Object> meta3FieldValues = new Map<String, Object>{ 
                'Is_Active__c' => true,
                'Campaign_Id__c' => CSMTestCampaignId,
                'Inactivity_Theshold__c' => 90
            };
            Map<String, Object> meta4FieldValues = new Map<String, Object>{ 
                'Is_Active__c' => true,
                'Campaign_Id__c' => RMTestCampaignId,
                'Inactivity_Theshold__c' => 90
            };
            Campaign_Attribution_Criteria_Group__mdt customTestMeta1 = (Campaign_Attribution_Criteria_Group__mdt)TestingUtility.createTestMeta('Campaign_Attribution_Criteria_Group__mdt', meta1FieldValues);
            Campaign_Attribution_Criteria_Group__mdt customTestMeta2 = (Campaign_Attribution_Criteria_Group__mdt)TestingUtility.createTestMeta('Campaign_Attribution_Criteria_Group__mdt', meta2FieldValues);
            Campaign_Attribution_Criteria_Group__mdt customTestMeta3 = (Campaign_Attribution_Criteria_Group__mdt)TestingUtility.createTestMeta('Campaign_Attribution_Criteria_Group__mdt', meta3FieldValues);
            Campaign_Attribution_Criteria_Group__mdt customTestMeta4 = (Campaign_Attribution_Criteria_Group__mdt)TestingUtility.createTestMeta('Campaign_Attribution_Criteria_Group__mdt', meta4FieldValues);
            CriteriaGroupTestMeta = new List<Campaign_Attribution_Criteria_Group__mdt>{ customTestMeta1, customTestMeta2, customTestMeta3, customTestMeta4 };
        return CriteriaGroupTestMeta;
    } set; }

	public static Id TMTestCampaignId {get; set;}
	public static Id PartnerTestCampaignId {get; set;}
	public static Id CSMTestCampaignId {get; set;}
	public static Id RMTestCampaignId {get; set;}

    /**
    * @description setup - Setup data used in testing
    */  
    @testSetup
    public static void setup() {
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User testTMUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'TM', LastName = 'User', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Attribution_Department__c = 'TM');
        insert testTMUser;
        //
        User testPartnerUser = new User(Alias = 'admin2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Partner', LastName = 'User',
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', Attribution_Department__c = 'Partner');
        insert testPartnerUser;
        //
        User testCSMUser = new User(Alias = 'admin3', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'CSM', LastName = 'User',
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser3' + UserInfo.getOrganizationId() + '@testorg.com', Attribution_Department__c = 'CSM');
        insert testCSMUser;
        //
        User testSDRUser = new User(Alias = 'admin4', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'SDR', LastName = 'User',
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser4' + UserInfo.getOrganizationId() + '@testorg.com', Attribution_Department__c = 'SDR');
        insert testSDRUser;

    	// TEST CAMPAIGNS
        List<Campaign> testCampaigns = TestingUtility.createSObjectList('Campaign', false, 4);
        testCampaigns[0].Name = 'TM Campaign';
        testCampaigns[1].Name = 'Partner Campaign';
        testCampaigns[2].Name = 'CSM Campaign';
        testCampaigns[3].Name = 'SDR Campaign';      
        insert testCampaigns;

        // CREATE TEST LEADS
        List<Lead> testLeads = TestingUtility.createSObjectList('Lead', false, 8);
        testLeads[0].OwnerId = testTMUser.Id;
        testLeads[1].OwnerId = testTMUser.Id;
        testLeads[2].OwnerId = testPartnerUser.Id;
        testLeads[3].OwnerId = testPartnerUser.Id;
        testLeads[4].OwnerId = testCSMUser.Id;
        testLeads[5].OwnerId = testCSMUser.Id;
        testLeads[6].OwnerId = testSDRUser.Id;
        testLeads[7].OwnerId = testSDRUser.Id;
        insert testLeads;
    }

    /**
    * @description batchableTest - Tests batchable and primary logic
    */
    public static testmethod void batchableTest() {
    	// GET TEST CAMPAIGNS
    	List<Campaign> testCampaigns = [SELECT Id, Name FROM Campaign];
    	System.assert(testCampaigns.size() == 4);

    	// SET CAMPAIGN IDS
    	TMTestCampaignId = testCampaigns[0].Id;
    	PartnerTestCampaignId = testCampaigns[1].Id;
    	CSMTestCampaignId = testCampaigns[2].Id;
    	RMTestCampaignId = testCampaigns[3].Id;

    	// GET TEST LEADS
    	List<Lead> testLeads = [SELECT Id FROM Lead];
    	System.assert(testLeads.size() == 8);

    	// GET METADATA SETTINGS
    	Integer tmThreshold = 90;
    	Integer partnerThreshold = 90;
    	Integer csmThreshold = 90;
    	Integer rmThreshold = 90;
		for(Campaign_Attribution_Criteria_Group__mdt criteriaGroup : CriteriaGroupTestMeta){
			if(criteriaGroup.DeveloperName == 'TMs'){
				tmThreshold = Integer.valueOf(criteriaGroup.Inactivity_Theshold__c);
			}
			else if(criteriaGroup.DeveloperName == 'Partners'){
				partnerThreshold = Integer.valueOf(criteriaGroup.Inactivity_Theshold__c);
			}
			else if(criteriaGroup.DeveloperName == 'CSMs'){
				csmThreshold = Integer.valueOf(criteriaGroup.Inactivity_Theshold__c);
			}
			else if(criteriaGroup.DeveloperName == 'SDRs'){
				rmThreshold = Integer.valueOf(criteriaGroup.Inactivity_Theshold__c);
			}
		}

		// CREATE TEST CAMPAIGN MEMBERS
		List<CampaignMember> testMembers = TestingUtility.createSObjectList('CampaignMember', false, 8);
		testMembers[0].CampaignId = TMTestCampaignId;
		testMembers[0].LeadId = testLeads[0].Id;
		testMembers[0].Status = 'Responded';
		testMembers[0].Last_Attribution_Activity__c = DateTime.now().addDays(-(tmThreshold - 25)); // NOT PAST THE THRESHOLD
		//
		testMembers[1].CampaignId = TMTestCampaignId;
		testMembers[1].LeadId = testLeads[1].Id;
		testMembers[1].Status = 'Responded';
		testMembers[1].Last_Attribution_Activity__c = DateTime.now().addDays(-(tmThreshold + 5)); // PAST THRESHOLD, WILL BE DELETED
		//
		testMembers[2].CampaignId = PartnerTestCampaignId;
		testMembers[2].LeadId = testLeads[2].Id;
		testMembers[2].Status = 'Responded';
		testMembers[2].Last_Attribution_Activity__c = DateTime.now().addDays(-(partnerThreshold - 5)); // NOT PAST THE THRESHOLD
		//
		testMembers[3].CampaignId = PartnerTestCampaignId;
		testMembers[3].LeadId = testLeads[3].Id;
		testMembers[3].Status = 'Responded';
		testMembers[3].Last_Attribution_Activity__c = DateTime.now().addDays(-(partnerThreshold + 1)); // PAST THRESHOLD, WILL BE DELETED
		//
		testMembers[4].CampaignId = CSMTestCampaignId;
		testMembers[4].LeadId = testLeads[4].Id;
		testMembers[4].Status = 'Responded';
		testMembers[4].Last_Attribution_Activity__c = DateTime.now().addDays(-(csmThreshold)); // NOT PAST THE THRESHOLD
		//
		testMembers[5].CampaignId = CSMTestCampaignId;
		testMembers[5].LeadId = testLeads[5].Id;
		testMembers[5].Status = 'Responded';
		testMembers[5].Last_Attribution_Activity__c = DateTime.now().addDays(-(csmThreshold + 60)); // PAST THRESHOLD, WILL BE DELETED
		//
		testMembers[6].CampaignId = RMTestCampaignId;
		testMembers[6].LeadId = testLeads[6].Id;
		testMembers[6].Status = 'Responded';
		testMembers[6].Last_Attribution_Activity__c = DateTime.now().addDays(-(rmThreshold - 3)); // NOT PAST THE THRESHOLD
		//
		testMembers[7].CampaignId = RMTestCampaignId;
		testMembers[7].LeadId = testLeads[7].Id;
		testMembers[7].Status = 'Responded';
		testMembers[7].Last_Attribution_Activity__c = DateTime.now().addDays(-(rmThreshold + 90)); // PAST THRESHOLD, WILL BE DELETED
		insert testMembers;

		// GET TEST MEMBERS
    	testMembers = [SELECT Id FROM CampaignMember WHERE Id IN :testMembers];
    	System.assert(testMembers.size() == 8);

    	Test.startTest();

    	Database.executeBatch(new BatchableSch_CampaignAttribution(), 50);

    	Test.stopTest();

		// GET TEST MEMBERS
    	testMembers = [SELECT Id FROM CampaignMember WHERE Id IN :testMembers];
    	System.assert(testMembers.size() == 4);
    }

    /**
    * @description schedulableTest - Tests schedulable execute method
    */
    public static testmethod void schedulableTest() {
    	// GET TEST CAMPAIGNS
    	List<Campaign> testCampaigns = [SELECT Id, Name FROM Campaign];
    	System.assert(testCampaigns.size() == 4);

        Test.startTest();

        BatchableSch_CampaignAttribution scheduled = new BatchableSch_CampaignAttribution();
        System.schedule('Campaign Attribution Test', '0 0 22 * * ?', scheduled);

        Test.stopTest();
    }


}