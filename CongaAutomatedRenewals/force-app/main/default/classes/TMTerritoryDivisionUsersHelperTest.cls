/**
* @author ECS, ERedding
* @date 20200124
* @version 1.00
* @description TMTerritoryDivisionUsersHelperTest - Test class for the TMTerritoryDivisionUsersHelper class
*/
@isTest
public with sharing class TMTerritoryDivisionUsersHelperTest{

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User tm1 = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Terr', LastName = 'Person1', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise', Team__c = 'Sales');
        insert tm1;
        User tm2 = new User(Alias = 'admin2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Terr', LastName = 'Person2',
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Mid Commercial', Team__c = 'Customer Success');
        insert tm2;

        // CREATE TEST GEO
        TM_Geo__c na = new TM_Geo__c(Name = 'NA', Is_Active__c = true);
        insert new List<TM_Geo__c>{ na };

        // CREATE TEST REGION
        TM_Region__c southWest = new TM_Region__c(Name = 'South West', Is_Active__c = true, TM_GeoId__c = na.Id);
        insert new List<TM_Region__c>{ southWest };

        // CREATE TEST TERRITORIES
        TM_Territory__c terr1 = new TM_Territory__c(Name = 'California 1', Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);
        TM_Territory__c terr2 = new TM_Territory__c(Name = 'California 2', Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);        
        insert new List<TM_Territory__c>{ terr1, terr2 };       

        // CREATE TEST DIVISIONS
        TM_Division__c division1A = new TM_Division__c(Name = 'Division 1A', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 1A', Minimum_MRR__c = 0, Maximum_MRR__c = 200);
        TM_Division__c division1B = new TM_Division__c(Name = 'Division 1B', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 1B', Minimum_MRR__c = 201, Maximum_MRR__c = 500);
        insert new List<TM_Division__c>{ division1A, division1B };

        // CREATE TEST TERRITORY DIVISIONS
        TM_Territory_Division__c division1ATerr = new TM_Territory_Division__c(Name = 'Division 1A', TM_TerritoryId__c = terr1.Id, TM_DivisionId__c = division1A.Id);
        TM_Territory_Division__c division1BTerr = new TM_Territory_Division__c(Name = 'Division 1B', TM_TerritoryId__c = terr2.Id, TM_DivisionId__c = division1B.Id);
        insert new List<TM_Territory_Division__c>{ division1ATerr, division1BTerr }; 
    }
    
    /**
    * @description processUserChangesTest - Test processUserChanges trigger method
    */
    public static testMethod void processUserChangesTest() {
        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE FirstName = 'Terr'];
        System.assert(testUsers.size() == 2);

        // GET TEST DIVISIONS
        List<TM_Territory_Division__c> testTerrDivisions = [SELECT Id FROM TM_Territory_Division__c];
        System.assert(testTerrDivisions.size() == 2);

        // CREATE TEST DIVISION USERS
        List<TM_Territory_Division_Users__c> terrDivisionUsers = TestingUtility.createSObjectList('TM_Territory_Division_Users__c', false, 2);
        terrDivisionUsers[0].TM_Territory_DivisionId__c = testTerrDivisions[0].Id;
        terrDivisionUsers[1].TM_Territory_DivisionId__c = testTerrDivisions[1].Id;
        insert terrDivisionUsers;

        Test.startTest();

        // CHANGE DIVISIONS AND UPDATE
        terrDivisionUsers[0].Assigned_CSM_UserId__c = testUsers[0].Id;
        terrDivisionUsers[0].Assigned_RM_UserId__c = UserInfo.getUserId();
        terrDivisionUsers[1].Assigned_CSM_UserId__c = testUsers[1].Id;
        terrDivisionUsers[1].Assigned_RM_UserId__c = UserInfo.getUserId();
        update terrDivisionUsers;

        Test.stopTest();

        // NO ASSERTS AS THERE IS NO LOGIC TO TEST. CHANGED DIVISIONS ARE PROCESSED BY TerritoryManagementHelper AND BatchableTerritoryManagement
        // WHICH HAVE THEIR OWN TEST CLASSES
    }

    /**
    * @description processUserChangesTest_Exceptions - Test Exceptions To code
    */
    public static testMethod void processUserChangesTest_Exceptions() {
        Test.startTest();

        // ENSURE THE METHOD CAN HANDLE BAD/ABSENT INCOMING DATA
        TMTerritoryDivisionUsersHelper.processUserChanges(null, null);
        TMTerritoryDivisionUsersHelper.processUserChanges(new List<TM_Territory_Division_Users__c>(), new Map<Id, TM_Territory_Division_Users__c>());
        TMTerritoryDivisionUsersHelper.processUserChanges(null, new Map<Id, TM_Territory_Division_Users__c>());
        TMTerritoryDivisionUsersHelper.processUserChanges(new List<TM_Territory_Division_Users__c>(), null);

        Test.stopTest();
    }


}