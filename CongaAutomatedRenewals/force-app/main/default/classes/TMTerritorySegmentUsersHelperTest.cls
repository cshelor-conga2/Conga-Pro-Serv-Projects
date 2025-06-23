/**
* @author ECS, ERedding
* @date 20200124
* @version 1.00
* @description TMTerritorySegmentUsersHelperTest- Test class for the TMTerritorySegmentUsersHelper class
*/
@isTest
public with sharing class TMTerritorySegmentUsersHelperTest{

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
        TM_Territory__c terr1 = new TM_Territory__c(Name = 'California 1', Is_Active_for_Segments__c = true, TM_RegionId__c = southWest.Id);
        TM_Territory__c terr2 = new TM_Territory__c(Name = 'California 2', Is_Active_for_Segments__c = true, TM_RegionId__c = southWest.Id);        
        insert new List<TM_Territory__c>{ terr1, terr2 };       

        // CREATE TEST SEGMENTS
        TM_Segment__c enterprise = new TM_Segment__c(Name = 'Enterprise', TM_GeoId__c = na.Id, Is_Active__c = true, Minimum_Employees__c = 5001, Maximum_Employees__c = 10000000);
        TM_Segment__c genCommercial = new TM_Segment__c(Name = 'Gen Commercial', TM_GeoId__c = na.Id, Is_Active__c = true, Minimum_Employees__c = 1001, Maximum_Employees__c = 5000);
        insert new List<TM_Segment__c>{ enterprise, genCommercial };

        // CREATE TEST TERRITORY SEGMENTS
        TM_Territory_Segment__c enterpriseTerr1 = new TM_Territory_Segment__c(Name = 'Enterprise', TM_TerritoryId__c = terr1.Id, TM_SegmentId__c = enterprise.Id);
        TM_Territory_Segment__c genCommercialTerr2 = new TM_Territory_Segment__c(Name = 'Gen Commercial', TM_TerritoryId__c = terr2.Id, TM_SegmentId__c = genCommercial.Id);
        insert new List<TM_Territory_Segment__c>{ enterpriseTerr1, genCommercialTerr2 };
    }
    
    /**
    * @description processUserChangesTest - Test processUserChanges trigger method
    */
    public static testMethod void processUserChangesTest() {
        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE FirstName = 'Terr'];
        System.assert(testUsers.size() == 2);

        // GET TEST SEGMENTS
        List<TM_Territory_Segment__c> testTerrSegments = [SELECT Id FROM TM_Territory_Segment__c];
        System.assert(testTerrSegments.size() == 2);

        // CREATE TEST SEGMENT USERS
        List<TM_Territory_Segment_Users__c> terrSegmentUsers = TestingUtility.createSObjectList('TM_Territory_Segment_Users__c', false, 2);
        terrSegmentUsers[0].TM_Territory_SegmentId__c = testTerrSegments[0].Id;
        terrSegmentUsers[0].Applicable_Industries__c = 'None';
        terrSegmentUsers[1].TM_Territory_SegmentId__c = testTerrSegments[1].Id;
        terrSegmentUsers[1].Applicable_Industries__c = 'None';
        insert terrSegmentUsers;

        Test.startTest();

        // ASSIGN TM USERS
        terrSegmentUsers[0].Assigned_TM_UserId__c = testUsers[0].Id;
        terrSegmentUsers[1].Assigned_TM_UserId__c = testUsers[1].Id;
        update terrSegmentUsers;

        Test.stopTest();

        // NO ASSERTS AS THERE IS NO LOGIC TO TEST. CHANGED SEGMENTS ARE PROCESSED BY TerritoryManagementHelper AND BatchableTerritoryManagement
        // WHICH HAVE THEIR OWN TEST CLASSES
    }

    /**
    * @description processUserChangesTest_Exceptions - Test Exceptions To code
    */
    public static testMethod void processUserChangesTest_Exceptions() {
        Test.startTest();

        // ENSURE THE METHOD CAN HANDLE BAD/ABSENT INCOMING DATA
        TMTerritorySegmentUsersHelper.processUserChanges(null, null);
        TMTerritorySegmentUsersHelper.processUserChanges(new List<TM_Territory_Segment_Users__c>(), new Map<Id, TM_Territory_Segment_Users__c>());
        TMTerritorySegmentUsersHelper.processUserChanges(null, new Map<Id, TM_Territory_Segment_Users__c>());
        TMTerritorySegmentUsersHelper.processUserChanges(new List<TM_Territory_Segment_Users__c>(), null);

        Test.stopTest();
    }


}