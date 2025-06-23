/**
* @author ECS, ERedding
* @date 20190430
* @version 1.00
* @description TMTerritorySegmentCountryHelperTest - Test class for the TMTerrSegmentCountryHelper class
*/
@isTest
public with sharing class TMTerritorySegmentCountryHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // TEST COUNTRY RECORDS 
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'NA');
        Country_Territory__c mexico = new Country_Territory__c(Name = 'Mexico', Two_Letter_Code__c = 'MX', Three_Letter_Code__c = 'MEX', Geo__c = 'NA');
        insert new List<Country_Territory__c>{ unitedStates, mexico };

        // TEST STATE RECORDS
        State_Province__c colorado = new State_Province__c(Name = 'Colorado', English_Name__c = 'Colorado', Code__c = 'CO', Country_TerritoryId__c = unitedStates.Id);
        insert new List<State_Province__c>{ colorado };

        // CREATE TEST GEO
        TM_Geo__c na = new TM_Geo__c(Name = 'NA', Is_Active__c = true);
        insert new List<TM_Geo__c>{ na };

        // CREATE TEST REGION
        TM_Region__c southWest = new TM_Region__c(Name = 'South West', Is_Active__c = true, TM_GeoId__c = na.Id);
        insert new List<TM_Region__c>{ southWest };

        // CREATE TEST TERRITORIES
        TM_Territory__c terr1 = new TM_Territory__c(Name = 'West: CO/UT/AZ', Is_Active_for_Segments__c = true, TM_RegionId__c = southWest.Id);
        insert new List<TM_Territory__c>{ terr1 };

        // CREATE TEST SEGMENTS
        TM_Segment__c segment1 = new TM_Segment__c(Name = 'Enterprise', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 5000, Maximum_Employees__c = 10000);
        TM_Segment__c segment2 = new TM_Segment__c(Name = 'Growth', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 50, Maximum_Employees__c = 200);      
        insert new List<TM_Segment__c>{ segment1, segment2 };

        // CREATE TEST TERRITORY SEGMENTS
        TM_Territory_Segment__c terr1Segment1 = new TM_Territory_Segment__c(Name = 'Enterprise', TM_TerritoryId__c = terr1.Id, TM_SegmentId__c = segment1.Id);
        TM_Territory_Segment__c terr1Segment2 = new TM_Territory_Segment__c(Name = 'Growth', TM_TerritoryId__c = terr1.Id, TM_SegmentId__c = segment2.Id);      
        insert new List<TM_Territory_Segment__c>{ terr1Segment1, terr1Segment2 };

        // CREATE TEST TERRITORY COUNTRIES
        TM_Territory_Segment_Country__c terr1Segment1USA = new TM_Territory_Segment_Country__c(TM_Territory_SegmentId__c = terr1Segment1.Id, Country_TerritoryId__c = unitedStates.Id);
        insert new List<TM_Territory_Segment_Country__c>{ terr1Segment1USA };
    }

    /**
    * @description checkForExistingUseTest - Test checkForExistingUse trigger method
    */
    public static testMethod void checkForExistingUseTest() {
        // GET TEST COUNTRIES
        List<Country_Territory__c> testCountries = [SELECT Id, Name FROM Country_Territory__c]; // UNITED STATES
        System.assert(testCountries.size() == 2);   

        // GET TEST TERRITORY SEGMENTS
        List<TM_Territory_Segment__c> testTerrSegments = [SELECT Id, Name FROM TM_Territory_Segment__c];
        System.assert(testTerrSegments.size() == 2);

        Test.startTest();

        // TRY ADDING UNITED STATES A SECOND TIME TO THE SAME TERRITORY
        TM_Territory_Segment_Country__c terr1Segment1USA = new TM_Territory_Segment_Country__c(TM_Territory_SegmentId__c = testTerrSegments[0].Id, Country_TerritoryId__c = testCountries[0].Id);
        Database.saveResult insertResult = Database.insert(terr1Segment1USA, false);

        // RECORD SHOULD BE REJECTED AND HAVE AN ERROR
        System.assert(insertResult != null);
        System.assert(insertResult.isSuccess() == false);
        System.assert(insertResult.getErrors().isEmpty() == false);
        System.assert(insertResult.getErrors()[0].getMessage().contains('This Country is already used') == true);

        // TRY ADDING UNITED STATES TO ANOTHER TERRITORY SEGMENT
        TM_Territory_Segment_Country__c terr1Segment21USA = new TM_Territory_Segment_Country__c(TM_Territory_SegmentId__c = testTerrSegments[1].Id, Country_TerritoryId__c = testCountries[0].Id);
        Database.saveResult insertResult2 = Database.insert(terr1Segment21USA, false);

        // RECORD SHOULD BE SUCCESSFUL
        System.assert(insertResult2 != null);
        System.assert(insertResult2.isSuccess() == true);

        Test.stopTest();
    }
    
    /**
    * @description checkForExistingUseTest_Exceptions - Test checkForExistingUse trigger method bad parameter handling
    */
    public static testMethod void checkForExistingUseTest_Exceptions() {
        Test.startTest();

        TMTerritorySegmentCountryHelper.checkForExistingUse(null);
        TMTerritorySegmentCountryHelper.checkForExistingUse(new List<TM_Territory_Segment_Country__c>());

        Test.stopTest();
    }

    /**
    * @description checkForChildStatesTest - Test checkForChildStates trigger method
    */
    public static testMethod void checkForChildStatesTest() {
        // GET TEST COUNTRIES
        List<Country_Territory__c> testCountries = [SELECT Id, Name FROM Country_Territory__c]; // UNITED STATES
        System.assert(testCountries.size() == 2);   

        // GET TEST STATES
        List<State_Province__c> testStates = [SELECT Id, Name FROM State_Province__c]; // UNITED STATES
        System.assert(testStates.size() == 1);  

        // GET TEST TERRITORY SEGMENTS
        List<TM_Territory_Segment__c> testTerrSegments = [SELECT Id, Name FROM TM_Territory_Segment__c];
        System.assert(testTerrSegments.size() == 2);

        // CREATE TEST TERRITORY STATES
        TM_Territory_Segment_State__c testTerrSeg1Colorado = new TM_Territory_Segment_State__c(TM_Territory_SegmentId__c = testTerrSegments[1].Id, State_ProvinceId__c = testStates[0].Id);
        insert testTerrSeg1Colorado;

        Test.startTest();

        // TRY ADDING UNITED STATES WHEN COLORADO ALREADY EXISTS ON THE TERRITORY
        TM_Territory_Segment_Country__c terrSegCountry1 = new TM_Territory_Segment_Country__c(TM_Territory_SegmentId__c = testTerrSegments[1].Id, Country_TerritoryId__c = testCountries[0].Id);
        Database.saveResult insertResult = Database.insert(terrSegCountry1, false);

        // RECORD SHOULD BE REJECTED AND HAVE AN ERROR
        System.assert(insertResult != null);
        System.assert(insertResult.isSuccess() == false);
        System.assert(insertResult.getErrors().isEmpty() == false);
        System.assert(insertResult.getErrors()[0].getMessage().contains('A Country cannot be added') == true);

        // ADD MEXICO TO THE TERRITORY AND THEN TRY CHANGING TO UNITED STATES
        terrSegCountry1.Country_TerritoryId__c = testCountries[1].Id;
        insert terrSegCountry1;
        terrSegCountry1.Country_TerritoryId__c = testCountries[0].Id;
        Database.saveResult updateResult = Database.update(terrSegCountry1, false);
        
        // RECORD SHOULD BE AGAIN BE REJECTED AND HAVE AN ERROR
        System.assert(updateResult != null);
        System.assert(updateResult.isSuccess() == false);
        System.assert(updateResult.getErrors().isEmpty() == false);
        System.assert(updateResult.getErrors()[0].getMessage().contains('A Country cannot be added') == true);

        Test.stopTest();
    }
    
    /**
    * @description checkForChildStatesTest_Exceptions - Test checkForChildStates trigger method bad parameter handling
    */
    public static testMethod void checkForChildStatesTest_Exceptions() {
        Test.startTest();

        TMTerritorySegmentCountryHelper.checkForChildStates(null);
        TMTerritorySegmentCountryHelper.checkForChildStates(new List<TM_Territory_Segment_Country__c>());

        Test.stopTest();
    }


}