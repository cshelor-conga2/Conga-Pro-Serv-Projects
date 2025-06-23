/**
* @author ECS, ERedding
* @date 20190325
* @version 1.00
* @description TerritoryManagementControllerTest - Test class for the TerritoryManagementController class
*/
@isTest
public with sharing class TerritoryManagementControllerTest {

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

        // CREATE TEST GEOS
        TM_Geo__c na = new TM_Geo__c(Name = 'NA', Is_Active__c = true);
        TM_Geo__c emea = new TM_Geo__c(Name = 'EMEA', Is_Active__c = true);
        TM_Geo__c apac = new TM_Geo__c(Name = 'APAC', Is_Active__c = true);
        insert new List<TM_Geo__c>{ na, emea, apac };

        // CREATE TEST REGIONS
        TM_Region__c northCental = new TM_Region__c(Name = 'North Cental', Is_Active__c = true, TM_GeoId__c = na.Id);
        TM_Region__c northWest = new TM_Region__c(Name = 'North West', Is_Active__c = true, TM_GeoId__c = na.Id);
        TM_Region__c southWest = new TM_Region__c(Name = 'South West', Is_Active__c = true, TM_GeoId__c = na.Id);
        insert new List<TM_Region__c>{ northCental, northWest, southWest};

        // CREATE TEST TERRITORIES
        TM_Territory__c terr1 = new TM_Territory__c(Name = 'IL/LA', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = northCental.Id);
        TM_Territory__c terr2 = new TM_Territory__c(Name = 'West Pacific Northwest', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = northWest.Id);
        TM_Territory__c terr3 = new TM_Territory__c(Name = 'California 1', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);
        insert new List<TM_Territory__c>{ terr1, terr2, terr3 };       

        // CREATE TEST SEGMENTS
        TM_Segment__c enterprise = new TM_Segment__c(Name = 'Enterprise', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 5001, Maximum_Employees__c = 10000000);
        TM_Segment__c genCommercial = new TM_Segment__c(Name = 'Gen Commercial', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 1001, Maximum_Employees__c = 5000);
        TM_Segment__c growth = new TM_Segment__c(Name = 'Growth', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 1, Maximum_Employees__c = 200);
        TM_Segment__c midCommercial = new TM_Segment__c(Name = 'Mid Commercial', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 201, Maximum_Employees__c = 1000);        
        insert new List<TM_Segment__c>{ enterprise, genCommercial, growth, midCommercial };

        TM_Territory_Segment__c enterpriseTerrSegment = new TM_Territory_Segment__c(Name = 'Enterprise', TM_TerritoryId__c = terr1.Id, TM_SegmentId__c = enterprise.Id);
        TM_Territory_Segment__c genCommercialTerrSegment = new TM_Territory_Segment__c(Name = 'Gen Commercial', TM_TerritoryId__c = terr2.Id, TM_SegmentId__c = genCommercial.Id);
        TM_Territory_Segment__c growthTerrSegment = new TM_Territory_Segment__c(Name = 'Growth', TM_TerritoryId__c = terr3.Id, TM_SegmentId__c = growth.Id);
        TM_Territory_Segment__c midCommercialTerrSegment = new TM_Territory_Segment__c(Name = 'Mid Commercial', TM_TerritoryId__c = terr3.Id, TM_SegmentId__c = midCommercial.Id);        
        insert new List<TM_Territory_Segment__c>{ enterpriseTerrSegment, genCommercialTerrSegment, growthTerrSegment, midCommercialTerrSegment };

        TM_Territory_Segment_Users__c enterpriseTSU = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = enterpriseTerrSegment.Id, Applicable_Industries__c = 'None');
        TM_Territory_Segment_Users__c genCommercialTSU = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = genCommercialTerrSegment.Id, Applicable_Industries__c = 'None');
        TM_Territory_Segment_Users__c growthTSU = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = growthTerrSegment.Id, Applicable_Industries__c = 'None');
        TM_Territory_Segment_Users__c midCommercialTSU = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = midCommercialTerrSegment.Id, Applicable_Industries__c = 'None');        
        insert new List<TM_Territory_Segment_Users__c>{ enterpriseTSU, genCommercialTSU, growthTSU, midCommercialTSU };

        TM_Division__c division1A = new TM_Division__c(Name = 'Division 1A', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 1A', Minimum_MRR__c = 0, Maximum_MRR__c = 200);
        TM_Division__c division1B = new TM_Division__c(Name = 'Division 1B', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 1B', Minimum_MRR__c = 201, Maximum_MRR__c = 500);
        TM_Division__c division2 = new TM_Division__c(Name = 'Division 2', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 2', Minimum_MRR__c = 501, Maximum_MRR__c = 1000);
        TM_Division__c division3 = new TM_Division__c(Name = 'Division 3', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 3', Minimum_MRR__c = 1001, Maximum_MRR__c = 3000);
        insert new List<TM_Division__c>{ division1A, division1B, division2, division3 };

        TM_Territory_Division__c terrDivision1A = new TM_Territory_Division__c(Name = 'Division 1A', TM_TerritoryId__c = terr1.Id, TM_DivisionId__c = division1A.Id);
        TM_Territory_Division__c terrDivision1B = new TM_Territory_Division__c(Name = 'Division 1B', TM_TerritoryId__c = terr2.Id, TM_DivisionId__c = division1B.Id);
        TM_Territory_Division__c terrDivision2 = new TM_Territory_Division__c(Name = 'Division 2', TM_TerritoryId__c = terr3.Id, TM_DivisionId__c = division2.Id);
        TM_Territory_Division__c terrDivision3 = new TM_Territory_Division__c(Name = 'Division 3', TM_TerritoryId__c = terr3.Id, TM_DivisionId__c = division3.Id);
        insert new List<TM_Territory_Division__c>{ terrDivision1A, terrDivision1B, terrDivision2, terrDivision3 };

        TM_Territory_Division_Users__c terrDivisionUsers1A = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = terrDivision1A.Id);
        TM_Territory_Division_Users__c terrDivisionUsers1B = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = terrDivision1B.Id);
        TM_Territory_Division_Users__c terrDivisionUsers2 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = terrDivision2.Id);
        TM_Territory_Division_Users__c terrDivisionUsers3 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = terrDivision3.Id);
        insert new List<TM_Territory_Division_Users__c>{ terrDivisionUsers1A, terrDivisionUsers1B, terrDivisionUsers2, terrDivisionUsers3 };
    }
    
    /**
    * @description testMethod1 - Test Happy Path of code
    */
    public static testMethod void testController() {
        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE LastName IN ('Person1', 'Person2')];
        System.assert(!testUsers.isEmpty() && testUsers.size() == 2);

        Test.startTest();

        Test.setCurrentPage(Page.TerritoryManagement);

        // INTIALIZE PAGE CONTROLLER
        TerritoryManagementController controller = new TerritoryManagementController();
        System.assert(!controller.TMUsers.isEmpty());
        System.assert(!controller.CLMUsers.isEmpty());        
        System.assert(!controller.CSMUsers.isEmpty());
        System.assert(!controller.RMUsers.isEmpty());
        System.assert(!controller.TMUserIds.isEmpty());
        System.assert(!controller.CLMUserIds.isEmpty());
        System.assert(!controller.CSMUserIds.isEmpty());
        System.assert(!controller.RMUserIds.isEmpty());
        System.assert(!controller.Geos.isEmpty());
        System.assert(controller.Regions.size() == 1);
        //System.assert(controller.Territories.size() == 1);
        System.assert(controller.TerrSegmentWrappers.isEmpty());
        System.assert(controller.TerrDivisionWrappers.isEmpty());

        // CHOOSE A GEO AND LOAD REGIONS
        controller.SelectedGeo = controller.Geos[3].getValue();
        System.debug(controller.SelectedGeo);
        controller.loadRegions();
        System.assert(!controller.Regions.isEmpty());

        // CHOOSE A REGION AND LOAD SEGMENTS AND DIVISIONS
        controller.SelectedRegion = controller.Regions[1].getValue();
        controller.loadSegments();
        controller.loadDivisions();
        System.assert(!controller.Segments.isEmpty());
        System.assert(!controller.Divisions.isEmpty());

        // CHOOSE A SEGMENT AND DIVISION AND LOAD TERRITORY SEGMENTS AND TERRITORY DIVISIONS
        controller.SelectedSegment = controller.Segments[1].getValue();
        controller.SelectedDivision = controller.Divisions[1].getValue();
        controller.loadTerritorySegments();
        controller.loadTerritoryDivisions();
        System.assert(!controller.TerrSegmentWrappers.isEmpty());
        System.assert(!controller.TerrDivisionWrappers.isEmpty());

        // CHOOSE A TERRITORY AND LOAD SEGMENTS
        //controller.SelectedTerritory = controller.Territories[1].getValue();
        //controller.loadSegments();
        //controller.loadDivisions();
        //System.assert(!controller.TerrSegmentWrappers.isEmpty());
        //System.assert(!controller.TerrDivisionWrappers.isEmpty());
        for(TerritoryManagementController.TerrSegmentWrapper wrapper : controller.TerrSegmentWrappers){
            System.assert(!wrapper.UserWrappers.isEmpty());
        }
        for(TerritoryManagementController.TerrDivisionWrapper wrapper : controller.TerrDivisionWrappers){
            System.assert(!wrapper.UserWrappers.isEmpty());
        }

        // MODIFY SEGMENT AND DIVISION REVERT
        controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId = testUsers[0].Id;
        controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId = testUsers[0].Id;
        controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId = testUsers[0].Id;
        controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId = testUsers[0].Id;
        System.assert(String.isNotBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId));
        System.assert(String.isNotBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId));
        System.assert(String.isNotBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId));
        System.assert(String.isNotBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId));
        controller.revertChanges();
        System.assert(String.isBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId));
        System.assert(String.isBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId));
        System.assert(String.isBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId));
        System.assert(String.isBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId));

        // MODIFY TERR SEGMENT USERS AND TERR DIVISION USERS AND SAVE
        controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId = testUsers[0].Id;
        controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId = testUsers[1].Id;
        controller.TerrSegmentWrappers[0].UserWrappers[0].IndustriesRecord.Applicable_Industries__c = 'Real Estate';
        controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId = testUsers[0].Id;
        controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId = testUsers[1].Id;
        System.assert(String.isNotBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId));
        System.assert(String.isNotBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId));
        System.assert(String.isNotBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId));
        System.assert(String.isNotBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId));
        controller.saveChanges();

        // CHECK SAVED TERRITORY SEGMENT USER FOR CORRECT DATA
        List<TM_Territory_Segment_Users__c> testTerrSegmentUsers = [SELECT Id, Name, Assigned_TM_UserId__c, Assigned_CLM_UserId__c, Applicable_Industries__c
                                                                    FROM TM_Territory_Segment_Users__c
                                                                    WHERE TM_Territory_SegmentId__r.TM_SegmentId__c = :controller.SelectedSegment];
        
        System.assert(testTerrSegmentUsers.size() == 1);
        System.assert(testTerrSegmentUsers[0].Assigned_TM_UserId__c == testUsers[0].Id);
        System.assert(testTerrSegmentUsers[0].Applicable_Industries__c == 'Real Estate');
        System.assert(testTerrSegmentUsers[0].Assigned_CLM_UserId__c == testUsers[1].Id);
        
        // CHECK SAVED TERRITORY DIVISION USER FOR CORRECT DATA
        List<TM_Territory_Division_Users__c> testTerrDivisionUsers = [SELECT Id, Name, Assigned_CSM_UserId__c, Assigned_RM_UserId__c
                                                                      FROM TM_Territory_Division_Users__c
                                                                      WHERE TM_Territory_DivisionId__r.TM_DivisionId__c = :controller.SelectedDivision];
        System.assert(testTerrDivisionUsers.size() == 1);
        System.assert(testTerrDivisionUsers[0].Assigned_CSM_UserId__c == testUsers[0].Id);
        System.assert(testTerrDivisionUsers[0].Assigned_RM_UserId__c == testUsers[1].Id);

        // ADD NEW TERRITORY SEGMENTS USERS
        System.assert(controller.TerrSegmentWrappers[0].UserWrappers.size() == 1);
        controller.NewEntryTSId = controller.TerrSegmentWrappers[0].RecordId;
        controller.addTSUserEntry();
        System.assert(controller.TerrSegmentWrappers[0].UserWrappers.size() == 2);
        controller.TerrSegmentWrappers[0].UserWrappers[1].SelectedTMUserId = testUsers[1].Id;
        controller.TerrSegmentWrappers[0].UserWrappers[1].IndustriesRecord.Applicable_Industries__c = 'Transportation, Distribution, and Logistics';
        controller.TerrSegmentWrappers[0].UserWrappers[1].SelectedCLMUserId = testUsers[0].Id;
        controller.saveChanges();

        // CHECK SAVED TERRITORY SEGMENT FOR CORRECT DATA
        testTerrSegmentUsers = [SELECT Id, Name, Assigned_TM_UserId__c, Assigned_CLM_UserId__c, Applicable_Industries__c
                                FROM TM_Territory_Segment_Users__c
                                WHERE TM_Territory_SegmentId__r.TM_SegmentId__c = :controller.SelectedSegment];
        System.assert(testTerrSegmentUsers.size() == 2);
        System.assert(testTerrSegmentUsers[1].Assigned_TM_UserId__c == testUsers[1].Id);
        System.assert(testTerrSegmentUsers[1].Applicable_Industries__c == 'Transportation, Distribution, and Logistics');
        System.assert(testTerrSegmentUsers[1].Assigned_CLM_UserId__c == testUsers[0].Id);

        Test.stopTest();
    }
    
    /**
    * @description testMethod2 - Test that the code can handle missing data
    */
    public static testMethod void testController_Exceptions() {
        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE LastName IN ('Person1', 'Person2')];
        System.assert(!testUsers.isEmpty() && testUsers.size() == 2);

        Test.startTest();

        Test.setCurrentPage(Page.TerritoryManagement);

        // INTIALIZE PAGE CONTROLLER
        TerritoryManagementController controller = new TerritoryManagementController();
        System.assert(!controller.TMUsers.isEmpty());
        System.assert(!controller.CLMUsers.isEmpty());       
        System.assert(!controller.CSMUsers.isEmpty());
        System.assert(!controller.RMUsers.isEmpty());
        System.assert(!controller.TMUserIds.isEmpty());
        System.assert(!controller.CLMUserIds.isEmpty());
        System.assert(!controller.CSMUserIds.isEmpty());
        System.assert(!controller.RMUserIds.isEmpty());
        System.assert(!controller.Geos.isEmpty());
        System.assert(controller.Regions.size() == 1);
        //System.assert(controller.Territories.size() == 1);
        System.assert(controller.TerrSegmentWrappers.isEmpty());
        System.assert(controller.TerrDivisionWrappers.isEmpty());

        // CHOOSE VALUES AND LOAD
        controller.SelectedGeo = controller.Geos[3].getValue();
        controller.loadRegions();
        System.assert(!controller.Regions.isEmpty());
        controller.SelectedRegion = controller.Regions[1].getValue();
        controller.loadSegments();
        controller.loadDivisions();
        System.assert(!controller.Segments.isEmpty());
        System.assert(!controller.Divisions.isEmpty());   
        controller.SelectedSegment = controller.Segments[1].getValue();
        controller.SelectedDivision = controller.Divisions[1].getValue();
        controller.loadTerritorySegments();
        controller.loadTerritoryDivisions();
        System.assert(!controller.TerrSegmentWrappers.isEmpty());
        System.assert(!controller.TerrDivisionWrappers.isEmpty());

        //controller.loadTerritories();
        //System.assert(!controller.Territories.isEmpty());
        //controller.SelectedTerritory = controller.Territories[1].getValue();
        //controller.loadSegments();
        //System.assert(!controller.TerrSegmentWrappers.isEmpty());
        ////controller.loadDivisions();
        //System.assert(!controller.TerrDivisionWrappers.isEmpty());

        // DELETE TERRITORY SEGMENT USERS AND RELOAD
        List<TM_Territory_Segment_Users__c> terrSegmentUsers = [SELECT Id FROM TM_Territory_Segment_Users__c];
        delete terrSegmentUsers;
        controller.loadTerritorySegments();
        System.assert(!controller.TerrSegmentWrappers.isEmpty() && controller.TerrSegmentWrappers[0].UserWrappers.isEmpty());

        // DELETE DIVISIONS AND RELOAD
        List<TM_Territory_Division_Users__c> terrDivisionUsers = [SELECT Id FROM TM_Territory_Division_Users__c];
        delete terrDivisionUsers;
        controller.loadTerritoryDivisions();
        System.assert(!controller.TerrDivisionWrappers.isEmpty() && controller.TerrDivisionWrappers[0].UserWrappers.isEmpty());

        // DELETE TERRITORY SEGMENT AND RELOAD
        List<TM_Territory_Segment__c> terrSegment = [SELECT Id FROM TM_Territory_Segment__c];
        delete terrSegment;
        controller.loadSegments();
        System.assert(!controller.Segments.isEmpty());

        // DELETE TERRITORY DIVISION AND RELOAD
        List<TM_Territory_Division__c> terrDivision = [SELECT Id FROM TM_Territory_Division__c];
        delete terrDivision;
        controller.loadDivisions();
        System.assert(!controller.Divisions.isEmpty());

        // DELETE TERRITORIES AND RELOAD
        //List<TM_Territory__c> territories = [SELECT Id FROM TM_Territory__c];
        //delete territories;
        //controller.loadTerritories();
        //System.assert(controller.Territories.size() == 1);

        // DELETE SEGMENTS AND DIVISIONS
        List<TM_Territory__c> territories = [SELECT Id FROM TM_Territory__c];
        List<TM_Segment__c> segments = [SELECT Id FROM TM_Segment__c];
        List<TM_Division__c> divisions = [SELECT Id FROM TM_Division__c];
        delete territories;
        delete segments;
        delete divisions;

        // DELETE REGIONS AND RELOAD
        List<TM_Region__c> regions = [SELECT Id FROM TM_Region__c];
        delete regions;
        controller.loadRegions();
        System.assert(controller.Regions.size() == 1);

        // DELETE GEOS AND RELOAD
        List<TM_Geo__c> geos = [SELECT Id FROM TM_Geo__c];
        delete geos;
        controller.loadGeos();
        System.assert(controller.Geos.size() == 1);

        Test.stopTest();
    }
    
    /**
    * @description testMethod3 - Test With base user
    */
    public static testMethod void testController_BaseUser() {
        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE LastName IN ('Person1', 'Person2')];
        System.assert(!testUsers.isEmpty() && testUsers.size() == 2);

        Test.startTest();

        System.runAs(testUsers[1]){
            Test.setCurrentPage(Page.TerritoryManagement);

            // INTIALIZE PAGE CONTROLLER
            TerritoryManagementController controller = new TerritoryManagementController();
            System.assert(!controller.TMUsers.isEmpty());
            System.assert(!controller.CLMUsers.isEmpty());            
            System.assert(!controller.CSMUsers.isEmpty());
            System.assert(!controller.RMUsers.isEmpty());
            System.assert(!controller.TMUserIds.isEmpty());
            System.assert(!controller.CLMUserIds.isEmpty());
            System.assert(!controller.CSMUserIds.isEmpty());
            System.assert(!controller.RMUserIds.isEmpty());
            System.assert(!controller.Geos.isEmpty());
            System.assert(controller.Regions.size() == 1);
            //System.assert(controller.Territories.size() == 1);
            System.assert(controller.TerrSegmentWrappers.isEmpty());
            System.assert(controller.TerrDivisionWrappers.isEmpty());

            // CHOOSE A GEO AND LOAD REGIONS
            controller.SelectedGeo = controller.Geos[3].getValue();
            controller.loadRegions();
            System.assert(!controller.Regions.isEmpty());

            // CHOOSE A REGION AND LOAD TERRITORIES
            controller.SelectedRegion = controller.Regions[1].getValue();
            controller.loadSegments();
            controller.loadDivisions();
            System.assert(!controller.Segments.isEmpty());
            System.assert(!controller.Divisions.isEmpty());
            //controller.loadTerritories();
            //System.assert(!controller.Territories.isEmpty());

            // CHOOSE A SEGMENT AND DIVISION AND LOAD TERRITORY SEGMENTS AND TERRITORY DIVISIONS
            controller.SelectedSegment = controller.Segments[1].getValue();
            controller.SelectedDivision = controller.Divisions[1].getValue();
            controller.loadTerritorySegments();
            controller.loadTerritoryDivisions();
            System.assert(!controller.TerrSegmentWrappers.isEmpty());
            System.assert(!controller.TerrDivisionWrappers.isEmpty());

            // CHOOSE A TERRITORY AND LOAD SEGMENTS
            //controller.SelectedTerritory = controller.Territories[1].getValue();
            //controller.loadSegments();
            //controller.loadDivisions();
            //System.assert(!controller.TerrSegmentWrappers.isEmpty());
            //System.assert(!controller.TerrDivisionWrappers.isEmpty());
            for(TerritoryManagementController.TerrSegmentWrapper wrapper : controller.TerrSegmentWrappers){
                System.assert(!wrapper.UserWrappers.isEmpty());
            }
            for(TerritoryManagementController.TerrDivisionWrapper wrapper : controller.TerrDivisionWrappers){
                System.assert(!wrapper.UserWrappers.isEmpty());
            }

            // MODIFY SEGMENT AND DIVISION REVERT
            controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId = testUsers[0].Id;
            controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId = testUsers[0].Id;
            controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId = testUsers[0].Id;
            controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId = testUsers[0].Id;
            System.assert(String.isNotBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId));
            System.assert(String.isNotBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId));
            System.assert(String.isNotBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId));
            System.assert(String.isNotBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId));
            controller.revertChanges();
            System.assert(String.isBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId));
            System.assert(String.isBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId));
            System.assert(String.isBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId));
            System.assert(String.isBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId));

            // MODIFY TERR SEGMENT USERS AND TERR DIVISION USERS AND SAVE
            controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId = testUsers[0].Id;
            controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId = testUsers[1].Id;
            controller.TerrSegmentWrappers[0].UserWrappers[0].IndustriesRecord.Applicable_Industries__c = 'Real Estate';
            controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId = testUsers[0].Id;
            controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId = testUsers[1].Id;
            System.assert(String.isNotBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedTMUserId));
            System.assert(String.isNotBlank(controller.TerrSegmentWrappers[0].UserWrappers[0].SelectedCLMUserId));
            System.assert(String.isNotBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedCSMUserId));
            System.assert(String.isNotBlank(controller.TerrDivisionWrappers[0].UserWrappers[0].SelectedRMUserId));
            controller.saveChanges();

            // CHECK SAVED TERRITORY SEGMENT FOR CORRECT DATA
            List<TM_Territory_Segment_Users__c> testTerrSegmentUsers = [SELECT Id, Name, Assigned_TM_UserId__c, Assigned_CLM_UserId__c, Applicable_Industries__c
                                                                        FROM TM_Territory_Segment_Users__c
                                                                        WHERE TM_Territory_SegmentId__r.TM_SegmentId__c = :controller.SelectedSegment];
            System.assert(testTerrSegmentUsers.size() == 1);
            System.assert(testTerrSegmentUsers[0].Assigned_TM_UserId__c == testUsers[0].Id);
            System.assert(testTerrSegmentUsers[0].Applicable_Industries__c == 'Real Estate');
            System.assert(testTerrSegmentUsers[0].Assigned_CLM_UserId__c == testUsers[1].Id);
            
            // CHECK SAVED TERRITORY DIVISION FOR CORRECT DATA
            List<TM_Territory_Division_Users__c> testTerrDivisionUsers = [SELECT Id, Name, Assigned_CSM_UserId__c, Assigned_RM_UserId__c
                                                                          FROM TM_Territory_Division_Users__c
                                                                          WHERE TM_Territory_DivisionId__r.TM_DivisionId__c = :controller.SelectedDivision];
            System.assert(testTerrDivisionUsers.size() == 1);
            System.assert(testTerrDivisionUsers[0].Assigned_CSM_UserId__c == testUsers[0].Id);
            System.assert(testTerrDivisionUsers[0].Assigned_RM_UserId__c == testUsers[1].Id);

            // ADD NEW TERRITORY SEGMENTS USERS
            System.assert(controller.TerrSegmentWrappers[0].UserWrappers.size() == 1);
            controller.NewEntryTSId = controller.TerrSegmentWrappers[0].RecordId;
            controller.addTSUserEntry();
            System.assert(controller.TerrSegmentWrappers[0].UserWrappers.size() == 2);
            controller.TerrSegmentWrappers[0].UserWrappers[1].SelectedTMUserId = testUsers[1].Id;
            controller.TerrSegmentWrappers[0].UserWrappers[1].IndustriesRecord.Applicable_Industries__c = 'Transportation, Distribution, and Logistics';
            controller.TerrSegmentWrappers[0].UserWrappers[1].SelectedCLMUserId = testUsers[0].Id;
            controller.saveChanges();

            // CHECK SAVED TERRITORY SEGMENT FOR CORRECT DATA
            testTerrSegmentUsers = [SELECT Id, Name, Assigned_TM_UserId__c, Assigned_CLM_UserId__c, Applicable_Industries__c
                                    FROM TM_Territory_Segment_Users__c
                                    WHERE TM_Territory_SegmentId__r.TM_SegmentId__c = :controller.SelectedSegment];
            System.assert(testTerrSegmentUsers.size() == 2);
            System.assert(testTerrSegmentUsers[1].Assigned_TM_UserId__c == testUsers[1].Id);
            System.assert(testTerrSegmentUsers[1].Applicable_Industries__c == 'Transportation, Distribution, and Logistics');
            System.assert(testTerrSegmentUsers[1].Assigned_CLM_UserId__c == testUsers[0].Id);
        }
        Test.stopTest();
    }


}