/**
* @author Conga Services
* @date 
* @version 1.00
* @description OpportunityTeamMemberHelperTest  - Test class for the [Name of class being tested] class
*/
@isTest
public with sharing class OpportunityTeamMemberHelperTest {
	
	/**
	* @description setup - Test data setup method
	*/
	@testSetup
	public static void setup(){
        // CREATE TEST GEO
        TM_Geo__c na = new TM_Geo__c(Name = 'AMER', Is_Active__c = true);
        TM_Geo__c emea = new TM_Geo__c(Name = 'EMEA', Is_Active__c = true);
        insert new List<TM_Geo__c>{ na, emea };

		// CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 2);
        testAccounts[0].Type = 'Customer';
        testAccounts[0].TM_GeoId__c = na.Id;
        testAccounts[1].Type = 'Customer';
		testAccounts[1].TM_GeoId__c = emea.Id;  
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 3);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Type = 'New Business';
        //
        testOpportunities[1].AccountId = testAccounts[0].Id;
        testOpportunities[1].StageName = 'Qualify';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Type = 'Renewal';
        //
        testOpportunities[2].AccountId = testAccounts[1].Id;
        testOpportunities[2].StageName = 'Qualify';
        testOpportunities[2].CloseDate = Date.today();
        testOpportunities[2].Type = 'Renewal';
        insert testOpportunities;
	}

	/**
	* @description processTeamChangesTest - Test method for AccountTeamMemberHelper.processTeamChanges trigger method
	*/
	public static testMethod void processTeamChangesTest() {
        // CREATE TEST SALES USER MANAGER 1
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'sales', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8',
        FirstName = 'Sales', LastName = 'Person', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        // CREATE TEST SALES USER MANAGER 2
        User salesUser2 = new User(Alias = 'sales2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8',
        FirstName = 'Sales', LastName = 'Person2', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser2' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser2;


        // GET A SDR AND AN SE USER
        User bdrUser = [SELECT Id, Name FROM User WHERE IsActive = true AND UserRole.Name LIKE 'Business Development Representative%' LIMIT 1];
        User sdrUser = [SELECT Id, Name FROM User WHERE IsActive = true AND UserRole.Name LIKE 'Sales Development Representative%' LIMIT 1];
        User seUser = [SELECT Id, Name FROM User WHERE IsActive = true AND UserRole.Name = 'Solutions Engineer' LIMIT 1];
        System.assert(bdrUser != null);
        System.assert(sdrUser != null);
        System.assert(seUser != null);
        
        // GET TEST ACCOUNTS
        List<Opportunity> testOpps = [SELECT Id, OwnerId, TM_Territory_ManagerId__c, Customer_Success_ManagerId__c FROM Opportunity];
        System.assert(testOpps.size() == 3);

        Test.startTest();

        // CREATE TM TEAM MEMBERS
		OpportunityTeamMember opp1TM = new OpportunityTeamMember(OpportunityId = testOpps[0].Id, UserId = salesUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.TMROLENAME);
		OpportunityTeamMember opp1SE = new OpportunityTeamMember(OpportunityId = testOpps[0].Id, UserId = seUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.SEROLENAME);
		//
		OpportunityTeamMember opp2TM = new OpportunityTeamMember(OpportunityId = testOpps[1].Id, UserId = salesUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.TMROLENAME);
		OpportunityTeamMember opp2BDR = new OpportunityTeamMember(OpportunityId = testOpps[1].Id, UserId = bdrUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.BDRROLENAME);
		//
		OpportunityTeamMember opp3TM = new OpportunityTeamMember(OpportunityId = testOpps[2].Id, UserId = salesUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.TMROLENAME);
		OpportunityTeamMember opp3SDR = new OpportunityTeamMember(OpportunityId = testOpps[2].Id, UserId = sdrUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.SDRROLENAME);
		insert new List<OpportunityTeamMember>{ opp1TM, opp1SE, opp2TM, opp2BDR, opp3TM, opp3SDR };

		// REFRESH OPPORTUNITIES AND CHECK FOR CORRECT DATA
		testOpps = [SELECT Id, OwnerId, TM_Territory_ManagerId__c, Customer_Success_ManagerId__c, SDR__c, SE_Assigned__c FROM Opportunity];
		// NEW BUSINESS
		System.assert(testOpps[0].OwnerId == salesUser.Id);
		System.assert(testOpps[0].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testOpps[0].Customer_Success_ManagerId__c == null);
		System.assert(testOpps[0].SE_Assigned__c == seUser.Id);
		System.assert(testOpps[0].SDR__c == null);
		// RENEWAL
		System.assert(testOpps[1].OwnerId == UserInfo.getUserId());
		System.assert(testOpps[1].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testOpps[1].Customer_Success_ManagerId__c == null);
		System.assert(testOpps[1].SE_Assigned__c == null);		
		System.assert(testOpps[1].SDR__c == bdrUser.Id);
		// RENEWAL EMEA
		System.assert(testOpps[2].OwnerId == UserInfo.getUserId());
		System.assert(testOpps[2].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testOpps[2].Customer_Success_ManagerId__c == null);
		System.assert(testOpps[2].SE_Assigned__c == null);		
		System.assert(testOpps[2].SDR__c == sdrUser.Id);

        // CREATE CSM TEAM MEMBERS
		OpportunityTeamMember opp1CSM = new OpportunityTeamMember(OpportunityId = testOpps[0].Id, UserId = salesUser2.Id, TeamMemberRole = OpportunityTeamMemberHelper.CSMROLENAME);
		OpportunityTeamMember opp1BDR = new OpportunityTeamMember(OpportunityId = testOpps[0].Id, UserId = bdrUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.BDRROLENAME);
		//
		OpportunityTeamMember opp2CSM = new OpportunityTeamMember(OpportunityId = testOpps[1].Id, UserId = salesUser2.Id, TeamMemberRole = OpportunityTeamMemberHelper.CSMROLENAME);
		OpportunityTeamMember opp2RM = new OpportunityTeamMember(OpportunityId = testOpps[1].Id, UserId = UserInfo.getUserId(), TeamMemberRole = OpportunityTeamMemberHelper.RMROLENAME);
		OpportunityTeamMember opp2SDR = new OpportunityTeamMember(OpportunityId = testOpps[1].Id, UserId = sdrUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.SDRROLENAME);
		//
		OpportunityTeamMember opp3CSM = new OpportunityTeamMember(OpportunityId = testOpps[2].Id, UserId = salesUser2.Id, TeamMemberRole = OpportunityTeamMemberHelper.CSMROLENAME);
		OpportunityTeamMember opp3SE = new OpportunityTeamMember(OpportunityId = testOpps[2].Id, UserId = seUser.Id, TeamMemberRole = OpportunityTeamMemberHelper.SEROLENAME);
		insert new List<OpportunityTeamMember>{ opp1CSM, opp1BDR, opp2CSM, opp2RM, opp2SDR, opp3CSM, opp3SE };

		// REFRESH OPPORTUNITIES AND CHECK FOR CORRECT DATA
		testOpps = [SELECT Id, OwnerId, TM_Territory_ManagerId__c, Customer_Success_ManagerId__c, SDR__c, SE_Assigned__c FROM Opportunity];
		// NEW BUSINESS
		System.assert(testOpps[0].OwnerId == salesUser.Id);
		System.assert(testOpps[0].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testOpps[0].Customer_Success_ManagerId__c == null);
		System.assert(testOpps[0].SE_Assigned__c == seUser.Id);
		System.assert(testOpps[0].SDR__c == bdrUser.Id);
		// RENEWAL
		System.assert(testOpps[1].OwnerId == UserInfo.getUserId()); // AN RM OVERWRITES A CSM
		System.assert(testOpps[1].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testOpps[1].Customer_Success_ManagerId__c == salesUser2.Id);
		System.assert(testOpps[1].SE_Assigned__c == null);		
		System.assert(testOpps[1].SDR__c == bdrUser.Id);
		// RENEWAL EMEA WITH AN RM
		System.assert(testOpps[2].OwnerId == UserInfo.getUserId());
		System.assert(testOpps[2].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testOpps[2].Customer_Success_ManagerId__c == salesUser2.Id);
		System.assert(testOpps[2].SE_Assigned__c == seUser.Id);
		System.assert(testOpps[2].SDR__c == sdrUser.Id);

        Test.stopTest();
	}


}