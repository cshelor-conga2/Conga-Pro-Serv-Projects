/**
* @author ECS, ERedding
* @date  20191115
* @version 1.00
* @description AccountTeamMemberHelperTest  - Test class for the AccountTeamMemberHelper class
*/
@isTest
public with sharing class AccountTeamMemberHelperTest {

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
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].Type = 'Prospect';
        testAccounts[0].TM_GeoId__c = na.Id;
        testAccounts[1].Type = 'Customer';
        testAccounts[1].TM_GeoId__c = na.Id;
        testAccounts[2].Type = 'Customer';
		testAccounts[2].TM_GeoId__c = emea.Id;  
        insert testAccounts;

		// CREATE TEST CONTACTS
        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', false, 6);
    	testContacts[0].AccountId = testAccounts[0].Id;
    	testContacts[1].AccountId = testAccounts[1].Id;
    	testContacts[2].AccountId = testAccounts[1].Id;
    	testContacts[3].AccountId = testAccounts[2].Id;
    	testContacts[4].AccountId = testAccounts[2].Id;
		testContacts[5].AccountId = testAccounts[2].Id;
        insert testContacts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].AccountId = testAccounts[1].Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Type = 'New Business';
        //
        testOpportunities[1].AccountId = testAccounts[2].Id;
        testOpportunities[1].StageName = 'Qualify';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Type = 'Renewal';
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

        // CREATE TEST SALES USER MANAGER 3
        User salesUser3 = new User(Alias = 'sales3', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8',
        FirstName = 'Sales', LastName = 'Person3', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser3' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser3;

        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, OwnerId, TM_Territory_ManagerId__c, Customer_Success_Manager__c FROM Account];
        System.assert(testAccounts.size() == 3);

        Test.startTest();

        // CREATE TM TEAM MEMBERS
		AccountTeamMember acct1TM = new AccountTeamMember(AccountId = testAccounts[0].Id, UserId = salesUser.Id, TeamMemberRole = AccountTeamMemberHelper.TMROLENAME);
		AccountTeamMember acct2TM = new AccountTeamMember(AccountId = testAccounts[1].Id, UserId = salesUser.Id, TeamMemberRole = AccountTeamMemberHelper.TMROLENAME);
		AccountTeamMember acct3TM = new AccountTeamMember(AccountId = testAccounts[2].Id, UserId = salesUser.Id, TeamMemberRole = AccountTeamMemberHelper.TMROLENAME);
		AccountTeamMember acct3CLM = new AccountTeamMember(AccountId = testAccounts[2].Id, UserId = salesUser2.Id, TeamMemberRole = AccountTeamMemberHelper.CLMROLENAME);
		insert new List<AccountTeamMember>{ acct1TM, acct2TM, acct3TM, acct3CLM };

		// REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
		testAccounts = [SELECT Id, OwnerId, TM_Territory_ManagerId__c, Customer_Success_Manager__c FROM Account];
		System.assert(testAccounts[0].OwnerId == salesUser.Id);
		System.assert(testAccounts[0].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testAccounts[0].Customer_Success_Manager__c == null);
		//
		System.assert(testAccounts[1].OwnerId == UserInfo.getUserId());
		System.assert(testAccounts[1].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testAccounts[1].Customer_Success_Manager__c == null);
		//
		System.assert(testAccounts[2].OwnerId == UserInfo.getUserId());
		System.assert(testAccounts[2].TM_Territory_ManagerId__c == salesUser.Id);
		System.assert(testAccounts[2].Customer_Success_Manager__c == null);

        // GET OPP TEAM MEMBERS AND CHECK THAT THEY WERE CREATED CORRECTLY
		List<Opportunity> testOpps = [SELECT Id FROM Opportunity];
		System.assert(testOpps.size() == 2);
        List<OpportunityTeamMember> oppTeamMembers = [SELECT OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN :testOpps AND TeamMemberRole != 'Opportunity Owner'];
        System.assert(oppTeamMembers.size() == 3);
        for(OpportunityTeamMember oppTeamMember : oppTeamMembers){
            if(oppTeamMember.OpportunityId == testOpps[0].Id){
                System.assert(oppTeamMember.UserId == salesUser.Id);
            }
            else if(oppTeamMember.OpportunityId == testOpps[1].Id){
                if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.TMROLENAME){
                    System.assert(oppTeamMember.UserId == salesUser.Id);
                }          
                else if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.CLMROLENAME){
                    System.assert(oppTeamMember.UserId == salesUser2.Id); 
                }
            }
        }

        // CREATE CSM TEAM MEMBERS
		AccountTeamMember acct2CSM = new AccountTeamMember(AccountId = testAccounts[1].Id, UserId = salesUser2.Id, TeamMemberRole = AccountTeamMemberHelper.CSMROLENAME);
        AccountTeamMember acct2RM = new AccountTeamMember(AccountId = testAccounts[1].Id, UserId = salesUser.Id, TeamMemberRole = AccountTeamMemberHelper.RMROLENAME);
		AccountTeamMember acct3CSM = new AccountTeamMember(AccountId = testAccounts[2].Id, UserId = salesUser3.Id, TeamMemberRole = AccountTeamMemberHelper.CSMROLENAME);
		AccountTeamMember acct3RM = new AccountTeamMember(AccountId = testAccounts[2].Id, UserId = UserInfo.getUserId(), TeamMemberRole = AccountTeamMemberHelper.RMROLENAME);
		insert new List<AccountTeamMember>{ acct2CSM, acct2RM, acct3CSM, acct3RM };

		// REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
		testAccounts = [SELECT Id, OwnerId, TM_Territory_ManagerId__c, Customer_Success_Manager__c, TM_Renewals_ManagerId__c FROM Account];
		System.assert(testAccounts[1].OwnerId == salesUser2.Id); // OWNER WILL CHANGE TO THE CSM ON CUSTOMER ACCOUNTS
		System.assert(testAccounts[1].TM_Territory_ManagerId__c == salesUser.Id);
        System.assert(testAccounts[1].TM_Renewals_ManagerId__c == salesUser.Id);
		System.assert(testAccounts[1].Customer_Success_Manager__c == salesUser2.Id);
		//
		System.assert(testAccounts[2].OwnerId == UserInfo.getUserId()); // OWNER WILL NOT CHANGE TO THE CSM ON AN CUSTOMER EMEA ACCOUNT
		System.assert(testAccounts[2].TM_Territory_ManagerId__c == salesUser.Id);
        System.assert(testAccounts[2].TM_Renewals_ManagerId__c == UserInfo.getUserId());
		System.assert(testAccounts[2].Customer_Success_Manager__c == salesUser3.Id);

        // GET OPP TEAM MEMBERS AND CHECK THAT THEY WERE CREATED CORRECTLY
        oppTeamMembers = [SELECT OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN :testOpps AND TeamMemberRole != 'Opportunity Owner'];
        System.assert(oppTeamMembers.size() == 5);
        for(OpportunityTeamMember oppTeamMember : oppTeamMembers){
            if(oppTeamMember.OpportunityId == testOpps[0].Id){
                System.assert(oppTeamMember.UserId == salesUser.Id); // ONLY TM MEMBER EXISTS, CSM AND RM NOT ADDED TO NON-RENEWALS OPP
            }
            else if(oppTeamMember.OpportunityId == testOpps[1].Id){
                if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.TMROLENAME){
                    System.assert(oppTeamMember.UserId == salesUser.Id);
                }
                else if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.CLMROLENAME){
                    System.assert(oppTeamMember.UserId == salesUser2.Id); 
                }
                else if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.CSMROLENAME){
                    System.assert(oppTeamMember.UserId == salesUser3.Id);
                }
                else if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.RMROLENAME){
                    System.assert(oppTeamMember.UserId == UserInfo.getUserId()); 
                }
            }
        }

        // UPDATE TEAM MEMBERS BY SWITCHING ROLES
        acct2TM.TeamMemberRole = AccountTeamMemberHelper.CSMROLENAME;
        acct3TM.TeamMemberRole = AccountTeamMemberHelper.CSMROLENAME;
        acct2CSM.TeamMemberRole = AccountTeamMemberHelper.TMROLENAME;
        acct3CSM.TeamMemberRole = AccountTeamMemberHelper.TMROLENAME;
        update new List<AccountTeamMember>{ acct2TM, acct3TM, acct2CSM, acct3CSM };

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, OwnerId, TM_Territory_ManagerId__c, Customer_Success_Manager__c, TM_Renewals_ManagerId__c FROM Account];
        System.assert(testAccounts[1].OwnerId == salesUser.Id); // OWNER WILL CHANGE TO THE CSM ON CUSTOMER ACCOUNTS
        System.assert(testAccounts[1].TM_Territory_ManagerId__c == salesUser2.Id);
        System.assert(testAccounts[1].TM_Renewals_ManagerId__c == salesUser.Id);
        System.assert(testAccounts[1].Customer_Success_Manager__c == salesUser.Id);
        //
        System.assert(testAccounts[2].OwnerId == UserInfo.getUserId()); // OWNER WILL NOT CHANGE TO THE CSM ON AN CUSTOMER EMEA ACCOUNT
        System.assert(testAccounts[2].TM_Territory_ManagerId__c == salesUser3.Id);
        System.assert(testAccounts[2].TM_Renewals_ManagerId__c == UserInfo.getUserId());
        System.assert(testAccounts[2].Customer_Success_Manager__c == salesUser.Id);

        // GET OPP TEAM MEMBERS AND CHECK THAT THEY WERE CREATED CORRECTLY
        oppTeamMembers = [SELECT OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN :testOpps AND TeamMemberRole != 'Opportunity Owner'];
        System.assert(oppTeamMembers.size() == 6);
        for(OpportunityTeamMember oppTeamMember : oppTeamMembers){
            if(oppTeamMember.OpportunityId == testOpps[0].Id){
                System.assert(oppTeamMember.UserId == salesUser.Id || oppTeamMember.UserId == salesUser2.Id);
            }
            else if(oppTeamMember.OpportunityId == testOpps[1].Id){
                if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.CSMROLENAME){
                    System.assert(oppTeamMember.UserId == salesUser.Id);
                }
                else if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.CLMROLENAME){
                    System.assert(oppTeamMember.UserId == salesUser2.Id); 
                }
                else if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.TMROLENAME){
                    System.assert(oppTeamMember.UserId == salesUser3.Id);
                }
                else if(oppTeamMember.TeamMemberRole == AccountTeamMemberHelper.RMROLENAME){
                    System.assert(oppTeamMember.UserId == UserInfo.getUserId()); 
                }
            }
        }

        Test.stopTest();
	}


}