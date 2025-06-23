/**
* @author ECS, ERedding
* @date 20190430
* @version 1.00
* @description TMTerritorySegmentStateHelperTest - Test class for the TMTerrSegmentStateHelper class
*/
@isTest
public with sharing class TMTerritorySegmentStateHelperTest {

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
        State_Province__c mexicoCity = new State_Province__c(Name = 'Ciudad de Mexico', English_Name__c = 'Mexico City', Code__c = 'CMX', Country_TerritoryId__c = mexico.Id);
        insert new List<State_Province__c>{ colorado, mexicoCity };

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

        // CREATE TEST TERRITORY STATE
        TM_Territory_Segment_State__c terr1Segment1Colo = new TM_Territory_Segment_State__c(TM_Territory_SegmentId__c = terr1Segment1.Id, State_ProvinceId__c = colorado.Id);
        insert new List<TM_Territory_Segment_State__c>{ terr1Segment1Colo };     
    }

    /**
    * @description checkForUseOnAnotherTerritoryTest - Test checkForExistingUse trigger method
    */
    public static testMethod void checkForExistingUseTest() {
        // GET TEST STATES
        List<State_Province__c> testStates = [SELECT Id, Name FROM State_Province__c];
        System.assert(testStates.size() == 2);  

        // GET TEST TERRITORY SEGMENTS
        List<TM_Territory_Segment__c> testTerrSegments = [SELECT Id, Name FROM TM_Territory_Segment__c];
        System.assert(testTerrSegments.size() == 2);

        Test.startTest();

        // TRY ADDING COLORADO TO A TERRITORY SEGMENT IT ALREADY EXISTS ON
        TM_Territory_Segment_State__c terrSeg1State = new TM_Territory_Segment_State__c(TM_Territory_SegmentId__c = testTerrSegments[0].Id, State_ProvinceId__c = testStates[0].Id);
        Database.saveResult insertResult = Database.insert(terrSeg1State , false);

        // RECORD SHOULD BE REJECTED AND HAVE AN ERROR
        System.assert(insertResult != null);
        System.assert(insertResult.isSuccess() == false);
        System.assert(insertResult.getErrors().isEmpty() == false);
        System.assert(insertResult.getErrors()[0].getMessage().contains('This State is already used') == true);

        // CHANGE STATE TO MEXICO CITY AND THEN TRY CHANGING BACK TO COLORADO
        terrSeg1State.State_ProvinceId__c = testStates[1].Id;
        insert terrSeg1State;
        terrSeg1State.State_ProvinceId__c = testStates[0].Id;
        Database.saveResult updateResult = Database.update(terrSeg1State, false);
        
        // RECORD SHOULD BE AGAIN BE REJECTED AND HAVE AN ERROR
        System.assert(updateResult != null);
        System.assert(updateResult.isSuccess() == false);
        System.assert(updateResult.getErrors().isEmpty() == false);
        System.assert(updateResult.getErrors()[0].getMessage().contains('This State is already used') == true);

        Test.stopTest();
    }
    
    /**
    * @description checkForUseOnAnotherTerritoryTest_Exceptions - Test checkForExistingUse trigger method bad parameter handling
    */
    public static testMethod void checkForUseOnAnotherTerritoryTest_Exceptions() {
        Test.startTest();

        TMTerritorySegmentStateHelper.checkForExistingUse(null);
        TMTerritorySegmentStateHelper.checkForExistingUse(new List<TM_Territory_Segment_State__c>());

        Test.stopTest();
    }    

    /**
    * @description checkForParentCountriesTest - Test checkForParentCountriesTest trigger method
    */
    public static testMethod void checkForParentCountriesTest() {
        // GET TEST COUNTRIES
        List<Country_Territory__c> testCountries = [SELECT Id, Name FROM Country_Territory__c];
        System.assert(testCountries.size() == 2);  

        // GET TEST STATES
        List<State_Province__c> testStates = [SELECT Id, Name FROM State_Province__c];
        System.assert(testStates.size() == 2);  

        // GET TEST TERRITORY SEGMENTS
        List<TM_Territory_Segment__c> testTerrSegments = [SELECT Id, Name FROM TM_Territory_Segment__c];
        System.assert(testTerrSegments.size() == 2);

        // CREATE TEST TERRITORY SEGMENT COUNTRY
        TM_Territory_Segment_Country__c terrSeg1USA = new TM_Territory_Segment_Country__c(TM_Territory_SegmentId__c = testTerrSegments[1].Id, Country_TerritoryId__c = testCountries[0].Id);
        insert terrSeg1USA;
        
        Test.startTest();

        // TRY ADDING COLORADO WHEN UNITED STATES ALREADY EXISTS ON THE TERRITORY
        TM_Territory_Segment_State__c terrDiv1State = new TM_Territory_Segment_State__c(TM_Territory_SegmentId__c = testTerrSegments[1].Id, State_ProvinceId__c = testStates[0].Id);
        Database.saveResult insertResult = Database.insert(terrDiv1State, false);

        // RECORD SHOULD BE REJECTED AND HAVE AN ERROR
        System.assert(insertResult != null);
        System.assert(insertResult.isSuccess() == false);
        System.assert(insertResult.getErrors().isEmpty() == false);
        System.assert(insertResult.getErrors()[0].getMessage().contains('A State cannot be added') == true);

        // CHANGE TO MEXICO CITY THEN TRY CHANGING BACK TO COLORADO
        terrDiv1State.State_ProvinceId__c = testStates[1].Id;
        insert terrDiv1State;
        terrDiv1State.State_ProvinceId__c = testStates[0].Id;
        Database.saveResult updateResult = Database.update(terrDiv1State, false);
        
        // RECORD SHOULD BE AGAIN BE REJECTED AND HAVE AN ERROR
        System.assert(updateResult != null);
        System.assert(updateResult.isSuccess() == false);
        System.assert(updateResult.getErrors().isEmpty() == false);
        System.assert(updateResult.getErrors()[0].getMessage().contains('A State cannot be added') == true);

        Test.stopTest();
    }
    
    /**
    * @description checkForParentCountriesTestTest_Exceptions - Test checkForParentCountriesTest trigger method bad parameter handling
    */
    public static testMethod void checkForParentCountriesTestTest_Exceptions() {
        Test.startTest();

        TMTerritorySegmentStateHelper.checkForParentCountries(null);
        TMTerritorySegmentStateHelper.checkForParentCountries(new List<TM_Territory_Segment_State__c>());

        Test.stopTest();
    }



}