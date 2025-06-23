/**
* @author ECS, ERedding
* @date 20180326
* @version 1.00
* @description BatchableTerritoryManagementTest  - Test class for the [Name of class being tested] class
*/
@isTest
public with sharing class BatchableTerritoryManagementTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User tm1 = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Terr', LastName = 'Person1', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert tm1;
        User tm2 = new User(Alias = 'admin2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Terr', LastName = 'Person2',
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Mid Commercial');
        insert tm2;
        User tm3 = new User(Alias = 'admin3', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Terr', LastName = 'Person3',
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser3' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Mid Commercial');
        insert tm3;      

        // CREATE TEST GEO
        TM_Geo__c na = new TM_Geo__c(Name = 'AMER', Is_Active__c = true);
        insert new List<TM_Geo__c>{ na };

        // CREATE TEST REGION
        TM_Region__c southWest = new TM_Region__c(Name = 'South West', Is_Active__c = true, TM_GeoId__c = na.Id);
        insert new List<TM_Region__c>{ southWest };

        // CREATE TEST TERRITORIES
        TM_Territory__c terr1 = new TM_Territory__c(Name = 'California 1', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);
        TM_Territory__c terr2 = new TM_Territory__c(Name = 'California 2', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);        
        insert new List<TM_Territory__c>{ terr1, terr2 };

        // CREATE TEST SEGMENTS
        TM_Segment__c enterpriseSegment = new TM_Segment__c(Name = 'Enterprise', TM_GeoId__c = na.Id, Is_Active__c = true, Minimum_Employees__c = 5001, Maximum_Employees__c = 10000000);
        TM_Segment__c genCommercialSegment = new TM_Segment__c(Name = 'General Commercial', TM_GeoId__c = na.Id, Is_Active__c = true, Minimum_Employees__c = 1001, Maximum_Employees__c = 5000);
        insert new List<TM_Segment__c>{ enterpriseSegment, genCommercialSegment };

        // CREATE TEST TERRITORY SEGMENTS
        TM_Territory_Segment__c terrSegment1 = new TM_Territory_Segment__c(Name = 'Enterprise', TM_TerritoryId__c = terr1.Id, TM_SegmentId__c = enterpriseSegment.Id);
        TM_Territory_Segment__c terrSegment2 = new TM_Territory_Segment__c(Name = 'General Commercial', TM_TerritoryId__c = terr1.Id, TM_SegmentId__c = genCommercialSegment.Id);
        TM_Territory_Segment__c terrSegment3 = new TM_Territory_Segment__c(Name = 'Enterprise', TM_TerritoryId__c = terr2.Id, TM_SegmentId__c = enterpriseSegment.Id);
        TM_Territory_Segment__c terrSegment4 = new TM_Territory_Segment__c(Name = 'General Commercial', TM_TerritoryId__c = terr2.Id, TM_SegmentId__c = genCommercialSegment.Id);
        insert new List<TM_Territory_Segment__c>{ terrSegment1, terrSegment2, terrSegment3, terrSegment4 };

        // CREATE TEST TERRITORY SEGMENT USERS
        TM_Territory_Segment_Users__c terrSegmentUser1 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = terrSegment1.Id, Applicable_Industries__c = 'None');
        TM_Territory_Segment_Users__c terrSegmentUser2 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = terrSegment2.Id, Applicable_Industries__c = 'None');
        TM_Territory_Segment_Users__c terrSegmentUser3 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = terrSegment3.Id, Applicable_Industries__c = 'None');
        TM_Territory_Segment_Users__c terrSegmentUser4 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = terrSegment4.Id, Applicable_Industries__c = 'None');
        insert new List<TM_Territory_Segment_Users__c>{ terrSegmentUser1, terrSegmentUser2, terrSegmentUser3, terrSegmentUser4 };

        // CREATE TEST DIVISIONS
        TM_Division__c division1A = new TM_Division__c(Name = 'Division 1A', TM_GeoId__c = na.Id, CS_Division__c = 'Division 1A', Is_Active__c = true, Minimum_MRR__c = 0, Maximum_MRR__c = 200);
        TM_Division__c division2 = new TM_Division__c(Name = 'Division 2', TM_GeoId__c = na.Id, CS_Division__c = 'Division 2', Is_Active__c = true, Minimum_MRR__c = 1001, Maximum_MRR__c = 3000);
        insert new List<TM_Division__c>{ division1A, division2 }; 

        // CREATE TEST TERRITORY DIVISIONS
        TM_Territory_Division__c terrDivision1A = new TM_Territory_Division__c(Name = 'Division 1A', TM_TerritoryId__c = terr1.Id, TM_DivisionId__c = division1A.Id);
        TM_Territory_Division__c terrDivision2 = new TM_Territory_Division__c(Name = 'Division 2', TM_TerritoryId__c = terr2.Id, TM_DivisionId__c = division2.Id);
        insert new List<TM_Territory_Division__c>{ terrDivision1A, terrDivision2 }; 

        // CREATE TEST TERRITORY DIVISION USERS
        TM_Territory_Division_Users__c terrDivisionUser1 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = terrDivision1A.Id);
        TM_Territory_Division_Users__c terrDivisionUser2 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = terrDivision2.Id);
        insert new List<TM_Territory_Division_Users__c>{ terrDivisionUser1, terrDivisionUser2 }; 

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].Name = 'Prospect';
        testAccounts[0].TM_GeoId__c = na.Id;
        testAccounts[0].TM_RegionId__c = southWest.Id;
        testAccounts[0].TM_Segment_TerritoryId__c = terr1.Id;
        testAccounts[0].TM_SegmentId__c = enterpriseSegment.Id;
        testAccounts[0].TM_Division_TerritoryId__c = terr1.Id;
        testAccounts[0].TM_DivisionId__c = division1A.Id;
        testAccounts[0].OwnerId = tm2.Id; // USER TWO
        testAccounts[0].Type = 'Prospect';
        //
        testAccounts[1].Name = 'Customer';
        testAccounts[1].TM_GeoId__c = na.Id;
        testAccounts[1].TM_RegionId__c = southWest.Id;
        testAccounts[1].TM_Segment_TerritoryId__c = terr2.Id;
        testAccounts[1].TM_SegmentId__c = genCommercialSegment.Id;
        testAccounts[1].TM_Division_TerritoryId__c = terr2.Id;
        testAccounts[1].TM_DivisionId__c = division2.Id;
        testAccounts[1].OwnerId = tm1.Id; // USER ONE
        testAccounts[1].Type = 'Customer';
        insert testAccounts;

        // CREATE TEAM MEMBERS FOR CUSTOMER - FORMER ACCOUNT
        AccountTeamMember acct2TM = new AccountTeamMember(AccountId = testAccounts[1].Id, UserId = tm1.Id, TeamMemberRole = 'Territory Manager');
        AccountTeamMember acct2CLM = new AccountTeamMember(AccountId = testAccounts[1].Id, UserId = tm2.Id, TeamMemberRole = 'CLM Manager');        
        AccountTeamMember acct2CSM = new AccountTeamMember(AccountId = testAccounts[1].Id, UserId = tm3.Id, TeamMemberRole = 'Customer Success Manager');
        AccountTeamMember acct2RM = new AccountTeamMember(AccountId = testAccounts[1].Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Renewals Manager');
        insert new List<AccountTeamMember>{ acct2TM, acct2CLM, acct2CSM, acct2RM };
    }

    /**
    * @description executeTest_SegmentChange -
    */
    public static testMethod void executeTest_SegmentChange(){
        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE LastName IN ('Person1', 'Person2', 'Person3')];
        System.assert(testUsers.size() == 3);

        // GET TEST ACCOUNTS AND CHECK THAT SETUP DATA IS CORRECT
        List<Account> testAccounts = [SELECT Id, OwnerId, TM_Territory_ManagerId__c FROM Account WHERE TM_Segment_TerritoryId__c != null AND TM_SegmentId__c != null];
        System.assert(testAccounts.size() == 2);
        System.assert(testAccounts[0].OwnerId == testUsers[1].Id);
        System.assert(testAccounts[0].TM_Territory_ManagerId__c == null);
        System.assert(testAccounts[1].OwnerId == testUsers[2].Id);
        System.assert(testAccounts[1].TM_Territory_ManagerId__c == testUsers[0].Id);

        // REMOVE DIVISIONS FROM ACCOUNTS SINCE CSMs CAN OVERWRITE TMs
        testAccounts[0].TM_Division_TerritoryId__c = null;
        testAccounts[1].TM_Division_TerritoryId__c = null;
        update testAccounts;

        // GET TEST SEGMENTS
        Map<Id, TM_Territory_Segment_Users__c> testTerrSegmentUsers = new Map<Id, TM_Territory_Segment_Users__c>([SELECT Id, TM_Territory_SegmentId__c 
                                                                                                                  FROM TM_Territory_Segment_Users__c]);
        System.assert(testTerrSegmentUsers.size() == 4);

        Test.startTest();

        TriggerHelper.TemporaryOverride('TMTerritorySegmentUsersHelper','processUserChanges', false); // TURN OFF, TEST METHOD WILL START BATCH JOB

        // UPDATE SEGMENTS WITH ASSIGNED USERS
        testTerrSegmentUsers.values()[0].Assigned_TM_UserId__c = testUsers[0].Id; // ACCOUNT 1, PROSPECT
        testTerrSegmentUsers.values()[3].Assigned_TM_UserId__c = testUsers[1].Id; // ACCOUNT 2, CUSTOMER
        update testTerrSegmentUsers.values();

        TerritoryManagementHelper.RolesQualifyingForUpdate.add(TerritoryManagementHelper.TMROLENAME);
        BatchableTerritoryManagement batchJob = new BatchableTerritoryManagement(testTerrSegmentUsers, null, true);
        Database.executeBatch(batchJob, 5);

        Test.stopTest();

        // GET TEAM MEMBERS AND CHECK THAT THE CORRECT ONES EXIST
        List<AccountTeamMember> teamMembers = [SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :testAccounts ORDER BY AccountId];
        System.assert(teamMembers.size() == 4); // FOUR MEMBERS, THE SYSTEM DELETED THE CLM MEMBER BECAUSE IT HAD THE SAME USER AS THE NEW TM
        for(AccountTeamMember teamMember : teamMembers){
            if(teamMember.TeamMemberRole == TerritoryManagementHelper.TMROLENAME){
                if(teamMember.AccountId == testAccounts[0].Id){
                    System.assert(teamMember.UserId == testUsers[0].Id);
                }
                else if(teamMember.AccountId == testAccounts[1].Id){
                    System.assert(teamMember.UserId == testUsers[1].Id);
                }
            }
        }
    }

    /**
    * @description executeTest_DivisionChange -
    */
    public static testMethod void executeTest_DivisionChange(){
        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE LastName IN ('Person1', 'Person2', 'Person3')];
        System.assert(testUsers.size() == 3);

        // GET TEST ACCOUNTS AND CHECK THAT SETUP DATA IS CORRECT
        List<Account> testAccounts = [SELECT Id, OwnerId, Customer_Success_Manager__c FROM Account WHERE TM_Division_TerritoryId__c != null AND TM_DivisionId__c != null];
        System.assert(testAccounts.size() == 2);
        System.assert(testAccounts[0].OwnerId == testUsers[1].Id);
        System.assert(testAccounts[0].Customer_Success_Manager__c == null);
        System.assert(testAccounts[1].OwnerId == testUsers[2].Id);
        System.assert(testAccounts[1].Customer_Success_Manager__c == testUsers[2].Id);

        // SET ACCOUNT TYPES
        testAccounts[0].Type = 'Customer';
        testAccounts[1].Type = 'Customer - Past Due';
        update testAccounts;

        // GET TEST DIVISIONS
        Map<Id, TM_Territory_Division_Users__c> testTerrDivisionUsers = new Map<Id, TM_Territory_Division_Users__c>([SELECT Id, TM_Territory_DivisionId__c
                                                                                                                     FROM TM_Territory_Division_Users__c]);
        System.assert(testTerrDivisionUsers.size() == 2);

        Test.startTest();

        TriggerHelper.TemporaryOverride('TMTerritoryDivisionUsersHelper','processUserChanges', false); // TURN OFF, TEST METHOD WILL START BATCH JOB

        // UPDATE DIVISIONS WITH ASSIGNED USERS
        testTerrDivisionUsers.values()[0].Assigned_CSM_UserId__c = testUsers[0].Id;
        testTerrDivisionUsers.values()[0].Assigned_RM_UserId__c = testUsers[1].Id;
        testTerrDivisionUsers.values()[1].Assigned_CSM_UserId__c = testUsers[0].Id; 
        testTerrDivisionUsers.values()[1].Assigned_RM_UserId__c = testUsers[1].Id;
        update testTerrDivisionUsers.values();

        TerritoryManagementHelper.RolesQualifyingForUpdate.add(TerritoryManagementHelper.CSMROLENAME);
        TerritoryManagementHelper.RolesQualifyingForUpdate.add(TerritoryManagementHelper.RMROLENAME);
        BatchableTerritoryManagement batchJob = new BatchableTerritoryManagement(null, testTerrDivisionUsers, true);
        Database.executeBatch(batchJob, 5);

        Test.stopTest();        

        // GET TEAM MEMBERS AND CHECK THAT THE CORRECT ONES EXIST
        List<AccountTeamMember> teamMembers = [SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :testAccounts];
        System.assert(teamMembers.size() == 4);
        for(AccountTeamMember teamMember : teamMembers){
            if(teamMember.AccountId == testAccounts[0].Id){
                if(teamMember.TeamMemberRole == TerritoryManagementHelper.CSMROLENAME){
                    System.assert(teamMember.UserId == testUsers[0].Id);
                }
                else if(teamMember.TeamMemberRole == TerritoryManagementHelper.RMROLENAME){
                    System.assert(teamMember.UserId == testUsers[1].Id); 
                }
            }
            else if(teamMember.AccountId == testAccounts[1].Id){
                if(teamMember.TeamMemberRole == TerritoryManagementHelper.CSMROLENAME){
                    System.assert(teamMember.UserId == testUsers[0].Id);
                }
                else if(teamMember.TeamMemberRole == TerritoryManagementHelper.RMROLENAME){
                    System.assert(teamMember.UserId == testUsers[1].Id); 
                }
            }
        }
    }


}