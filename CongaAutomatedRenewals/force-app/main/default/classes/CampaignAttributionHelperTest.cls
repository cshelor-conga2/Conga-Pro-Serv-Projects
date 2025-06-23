/**
* @author ECS, ERedding
* @date 20200123
* @version 1.00
* @description CampaignAttributionHelperTest  - Test class for the CampaignAttributionHelper class
*/
@isTest
public with sharing class CampaignAttributionHelperTest {
	public static Map<String, Id> TestCampaignIdMap {get; set;}

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
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

        User chiliPiperUser = [SELECT Id FROM User WHERE CommunityNickname = 'chili'];
        chiliPiperUser.Attribution_Department__c = 'SDR';
        update chiliPiperUser;

        // TEST CAMPAIGNS
        List<Campaign> testCampaigns = TestingUtility.createSObjectList('Campaign', false, 4);
        testCampaigns[0].Name = 'TM Campaign';
        testCampaigns[1].Name = 'Partner Campaign';
        testCampaigns[2].Name = 'CSM Campaign';
        testCampaigns[3].Name = 'SDR Campaign';      
        insert testCampaigns;

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 2);
        testAccounts[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');
        testAccounts[1].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');
        insert testAccounts;

        // CREATE TEST CONTACTS
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', false, 6);
		testContacts[0].FirstName = 'Criteria';
		testContacts[0].LastName = 'Contact';
        testContacts[0].AccountId = testAccounts[0].Id;
        testContacts[0].Most_Recent_Cadence_Name__c = 'CSM Cadence SDR Prospecting';
        testContacts[0].Cadence_Stage__c = 'Closed- Converted';
        testContacts[1].AccountId = testAccounts[0].Id;
		testContacts[1].FirstName = 'Test';
		testContacts[1].LastName = 'Contact1';
        testContacts[2].AccountId = testAccounts[0].Id;
        testContacts[2].FirstName = 'Test';
		testContacts[2].LastName = 'Contact2';
        testContacts[3].AccountId = testAccounts[0].Id;
		testContacts[3].FirstName = 'Test';
		testContacts[3].LastName = 'Contact3';
        testContacts[4].AccountId = testAccounts[0].Id;
		testContacts[4].FirstName = 'Test';
		testContacts[4].LastName = 'Contact4';
        testContacts[5].AccountId = testAccounts[1].Id;
        testContacts[5].FirstName = 'Primary';
        testContacts[5].LastName = 'Contact';        
        insert testContacts;
    
        // GET NEW ACCOUNT CONTACT RELATION RECORDS AND UPDATE ONE TO BE PRIMARY
        List<AccountContactRelation> acctContacts = [SELECT Id FROM AccountContactRelation WHERE AccountId = :testAccounts[1].Id AND ContactId = :testContacts[5].Id];
        acctContacts[0].IsPrimary__c = true;
        update acctContacts;

        // CREATE TEST LEADS
        Lead testLead = (Lead)TestingUtility.createSObject('Lead', false);
        testLead.FirstName = 'Test';
        testLead.LastName = 'Lead';
        testLead.Most_Recent_Cadence_Name__c = 'Customer Cadence SDR Prospecting';
        testLead.Cadence_Stage__c = 'Replied';
        insert testLead;

        // CREATE TEST OPPORTUNITY
        Opportunity testOpportunity = (Opportunity)TestingUtility.createSObject('Opportunity', false);
        testOpportunity.Name = 'Test New Biz Opportunity';
        testOpportunity.AccountId = testAccounts[0].Id;
        testOpportunity.Type = 'New Business';
        insert testOpportunity;

        // TURN OFF THE TASK TRIGGER METHOD, TEST METHODS WILL EXECUTE THE CODE
        TriggerHelper.TemporaryOverride('TaskHelper','processCampaignAttribution', false);

        // CREATE VARIOUS TEST TASKS
        List<Task> testTasks = TestingUtility.createSObjectList('Task', false, 17);
        // WITH OWNER THAT DOES NOT HAVE AN ATTRIBUTION DEPARTMENT - DOES --NOT-- MEET CRITERIA
        testTasks[0].Type = 'Email';
        testTasks[0].Subject = 'Reply:';

        // TEST TM TASK 1 - MEETS CRITERIA
        testTasks[1].OwnerId = testTMUser.Id;
        testTasks[1].WhoId = testContacts[1].Id;
        testTasks[1].Type = 'Email';
        testTasks[1].Subject = 'RE:';
        // TEST TM TASK 2 - MEETS CRITERIA
        testTasks[2].OwnerId = testTMUser.Id;
        testTasks[2].WhoId = testContacts[2].Id;
        testTasks[2].Type = 'QBR';
        // TEST TM TASK 3 - DOES --NOT-- MEET CRITERIA
        testTasks[3].OwnerId = testTMUser.Id;
        testTasks[3].WhoId = testContacts[3].Id;
        testTasks[3].Type = 'Test';
        testTasks[3].Subject = 'Test';

        // TEST PARTNER TASK 1 - MEETS CRITERIA
        testTasks[4].OwnerId = testPartnerUser.Id;
        testTasks[4].WhatId = testAccounts[0].Id;
        testTasks[4].WhoId = testContacts[1].Id;
        testTasks[4].Subject = 'RE: Reply Email';
        testTasks[4].Description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. mutual account In lectus nunc, aliquet in Accenture pulvinar vel, gravida';
        // TEST PARTNER TASK 2 - MEETS CRITERIA
        testTasks[5].OwnerId = testCSMUser.Id; // CSM SHOULD ALSO WORK WITH THE PARTNER CRITERIA
        testTasks[5].WhatId = testAccounts[1].Id;
        testTasks[5].WhoId = testContacts[2].Id;
        testTasks[5].Subject = 'Enablement';
        testTasks[5].Description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In lectus nunc, partner aliquet in pulvinar vel, ACV gravida';
        // TEST PARTNER TASK 3 - DOES --NOT-- MEET CRITERIA
        testTasks[6].OwnerId = testPartnerUser.Id;
        testTasks[6].WhatId = testAccounts[0].Id;
        testTasks[6].WhoId = testContacts[3].Id;
        testTasks[6].Subject = 'Intro';
        testTasks[6].Description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In lectus nunc, aliquet in pulvinar vel, gravida';

        // TEST CSM TASK 1 - MEETS CRITERIA
        testTasks[7].OwnerId = testCSMUser.Id;
        testTasks[7].WhoId = testContacts[0].Id;
        testTasks[7].Subject = 'RE: Reply Email';
        testTasks[7].Description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In lectus nunc, aliquet in pulvinar vel, gravida';
        // TEST CSM TASK 2 - MEETS CRITERIA
        testTasks[8].OwnerId = testCSMUser.Id;
        testTasks[8].WhoId = testContacts[1].Id;
        testTasks[8].Type = 'Email';
        testTasks[8].Subject = 'Test';
        testTasks[8].Description = 'Lorem ipsum dolor sit amet, expand consectetur adipiscing elit. In lectus nunc, Seat aliquet in pulvinar vel, gravida';
        // TEST CSM TASK 3 - MEETS CRITERIA
        testTasks[9].OwnerId = testCSMUser.Id;
        testTasks[9].WhatId = testOpportunity.Id;
        testTasks[9].WhoId = testContacts[2].Id;
        testTasks[9].Subject = 'Test';
        testTasks[9].Description = 'Test';
        // TEST CSM TASK 4 - DOES --NOT-- MEET CRITERIA
        testTasks[10].OwnerId = testCSMUser.Id;
        testTasks[10].WhoId = testContacts[3].Id;
        testTasks[10].Type = 'Call';      
        testTasks[10].Subject = 'Test';
        testTasks[10].Description = 'Test';

        // TEST SDR TASK 1 - MEETS CRITERIA
        testTasks[11].OwnerId = testSDRUser.Id;
        testTasks[11].WhoId = testContacts[1].Id;
        testTasks[11].Type = 'Email';        
        testTasks[11].Subject = 'Reply: Email';
        // TEST SDR TASK 2 - MEETS CRITERIA
        testTasks[12].OwnerId = testSDRUser.Id;
        testTasks[12].WhoId = testContacts[2].Id;
        testTasks[12].Type = 'Connect';
        testTasks[12].Subject = 'Enablement';
        testTasks[12].Description = 'Lorem ipsum dolor sit amet, opportunity consectetur adipiscing elit. In lectus nunc, aliquet in pulvinar vel, gravida';
        // TEST SDR TASK 3 - MEETS CRITERIA
        testTasks[13].OwnerId = chiliPiperUser.Id;
        testTasks[13].CreatedById = chiliPiperUser.Id;
        testTasks[13].WhoId = testContacts[3].Id;
        testTasks[13].Subject = 'Test';
        testTasks[13].Description = 'Test';
        // TEST SDR TASK 4 - MEETS CRITERIA
        testTasks[14].OwnerId = testSDRUser.Id;
        testTasks[14].WhoId = testContacts[0].Id;
        testTasks[14].Type = 'Call';      
        testTasks[14].Subject = 'Test';
        testTasks[14].Description = 'Test';
        // TEST SDR TASK 5 - MEETS CRITERIA
        testTasks[15].OwnerId = testSDRUser.Id;
        testTasks[15].WhoId = testLead.Id;
        testTasks[15].Type = 'Call';      
        testTasks[15].Subject = 'Test';
        testTasks[15].Description = 'Test';
        // TEST SDR TASK 6 - DOES --NOT-- MEET CRITERIA
        testTasks[16].OwnerId = testSDRUser.Id;
        testTasks[16].WhoId = testContacts[4].Id;
        testTasks[16].Type = 'Call';      
        testTasks[16].Subject = 'Test';
        testTasks[16].Description = 'Test';
        insert testTasks;
    }

    /**
    * @description evaluateTasksTest - Test method for the TaskHelper.evaluateTasksTest trigger method
    */
    public static testMethod void evaluateNewTasksTest(){
    	// GET TEST CAMPAIGNS
    	TestCampaignIdMap = new Map<String, Id>();
    	Set<Id> testCampaignIds = new Set<Id>();
    	for(Campaign testCampaign : [SELECT Id, Name FROM Campaign WHERE Name LIKE '%Campaign%']){
    		testCampaignIds.add(testCampaign.Id);
    		if(testCampaign.Name == 'TM Campaign'){ TestCampaignIdMap.put('TMs', testCampaign.Id); }
    		else if(testCampaign.Name == 'Partner Campaign'){ TestCampaignIdMap.put('Partners', testCampaign.Id); }
    		else if(testCampaign.Name == 'CSM Campaign'){ TestCampaignIdMap.put('CSMs', testCampaign.Id); }
    		else if(testCampaign.Name == 'SDR Campaign'){ TestCampaignIdMap.put('SDRs', testCampaign.Id); }
    	}

        // GET TEST TASKS
        List<Task> qualifyingTasks = new List<Task>();
      	for(Task task : [SELECT Id, CreatedById, LastModifiedById, OwnerId, WhoId, WhatId, Type, Subject, Description FROM Task]){
	       qualifyingTasks.add(task);
      	}

      	// CHECK FOR CAMPAIGN MEMBERS, THERE SHOULD BE NONE
      	List<CampaignMember> newMembers = [SELECT Id FROM CampaignMember WHERE CampaignId IN :testCampaignIds];
      	System.assert(newMembers.isEmpty());

        Test.startTest();

        CampaignAttributionHelper.evaluateTasks(qualifyingTasks);

        // 2 FOR TM, 2 FOR PARTNER, 3 FOR CSM, 5 FOR SDR
      	// CHECK AGAIN FOR CAMPAIGN MEMBERS, THERE SHOULD BE 12 FOR 12 TASKS THAT MEET CRITERIA AND 1 ADDITIONAL FOR THE ACCOUNT PRIMARY CONTACT ON 1 PARTNER TASK
      	newMembers = [SELECT Id, Last_Attribution_Activity__c FROM CampaignMember WHERE CampaignId IN :testCampaignIds];
      	System.assert(newMembers.size() == 13);

      	// EVALUATE TASKS AGAIN, CAMPAIGN MEMBERS WILL GET UPDATED AND NOT CREATED
      	CampaignAttributionHelper.evaluateTasks(qualifyingTasks);

      	// CHECK AGAIN FOR CAMPAIGN MEMBERS, THERE SHOULD STILL BE 12 AND THE LAST ATTRIBUTION DATE SHOULD BE CHANGED
      	List<CampaignMember> updatedMembers = [SELECT Id, Last_Attribution_Activity__c FROM CampaignMember WHERE CampaignId IN :testCampaignIds];
      	System.assert(updatedMembers.size() == 13);
      	for(Integer i = 0; i < updatedMembers.size(); i++){
      		System.assert(newMembers[i].Last_Attribution_Activity__c != updatedMembers[i].Last_Attribution_Activity__c);
      	}

        Test.stopTest();
	}


}