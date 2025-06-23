/**
* @author ECS, ERedding
* @date 20190424
* @version 1.00
* @description TMTerritoryDivisionStateHelperTest - [Description]
*/
@isTest
public with sharing class TMTerritoryDivisionStateHelperTest {

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
        TM_Territory__c terr1 = new TM_Territory__c(Name = 'West: CO/UT/AZ', Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);
        insert new List<TM_Territory__c>{ terr1 };

        // CREATE TEST DIVISIONS
        TM_Division__c division1 = new TM_Division__c(Name = 'Division 1A', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 1A', Minimum_MRR__c = 0, Maximum_MRR__c = 200);
        TM_Division__c division2 = new TM_Division__c(Name = 'Division 2', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 2', Minimum_MRR__c = 201, Maximum_MRR__c = 500);      
        insert new List<TM_Division__c>{ division1, division2 };

        // CREATE TEST TERRITORY DIVISIONS
        TM_Territory_Division__c terr1Division1 = new TM_Territory_Division__c(Name = 'Division 1A', TM_TerritoryId__c = terr1.Id, TM_DivisionId__c = division1.Id);
        TM_Territory_Division__c terr1Division2 = new TM_Territory_Division__c(Name = 'Division 2', TM_TerritoryId__c = terr1.Id, TM_DivisionId__c = division2.Id);      
        insert new List<TM_Territory_Division__c>{ terr1Division1, terr1Division2 };

        // CREATE TEST TERRITORY STATE
        TM_Territory_Division_State__c terr1Division1Colo = new TM_Territory_Division_State__c(TM_Territory_DivisionId__c = terr1Division1.Id, State_ProvinceId__c = colorado.Id);
        insert new List<TM_Territory_Division_State__c>{ terr1Division1Colo };
    }

    /**
    * @description checkForUseOnAnotherTerritoryTest - Test checkForExistingUse trigger method
    */
    public static testMethod void checkForExistingUseTest() {
        // GET TEST STATES
        List<State_Province__c> testStates = [SELECT Id, Name FROM State_Province__c];
        System.assert(testStates.size() == 2);  

        // GET TEST TERRITORY DIVISIONS
        List<TM_Territory_Division__c> testTerrDivisions = [SELECT Id, Name FROM TM_Territory_Division__c];
        System.assert(testTerrDivisions.size() == 2);

        Test.startTest();

        // TRY ADDING COLORADO TO A TERRITORY DIVISION IT ALREADY EXISTS ON
        TM_Territory_Division_State__c terrDiv1Colorado = new TM_Territory_Division_State__c(TM_Territory_DivisionId__c = testTerrDivisions[0].Id, State_ProvinceId__c = testStates[0].Id);
        Database.saveResult insertResult = Database.insert(terrDiv1Colorado , false);

        // RECORD SHOULD BE REJECTED AND HAVE AN ERROR
        System.assert(insertResult != null);
        System.assert(insertResult.isSuccess() == false);
        System.assert(insertResult.getErrors().isEmpty() == false);
        System.assert(insertResult.getErrors()[0].getMessage().contains('This State is already used') == true);

        // CHANGE STATE TO MEXICO CITY AND THEN TRY CHANGING BACK TO COLORADO
        terrDiv1Colorado.State_ProvinceId__c = testStates[1].Id;
        insert terrDiv1Colorado;
        terrDiv1Colorado.State_ProvinceId__c = testStates[0].Id;
        Database.saveResult updateResult = Database.update(terrDiv1Colorado, false);
        
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

        TMTerritoryDivisionStateHelper.checkForExistingUse(null);
        TMTerritoryDivisionStateHelper.checkForExistingUse(new List<TM_Territory_Division_State__c>());

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

        // GET TEST TERRITORIES
        List<TM_Territory_Division__c> testTerrDivisions = [SELECT Id, Name FROM TM_Territory_Division__c];
        System.assert(testTerrDivisions.size() == 2);

        // CREATE TEST TERRITORY DIVISION COUNTRY
        TM_Territory_Division_Country__c terrDiv1USA = new TM_Territory_Division_Country__c(TM_Territory_DivisionId__c = testTerrDivisions[1].Id, Country_TerritoryId__c = testCountries[0].Id);
        insert terrDiv1USA;
        
        Test.startTest();

        // TRY ADDING COLORADO WHEN UNITED STATES ALREADY EXISTS ON THE TERRITORY
        TM_Territory_Division_State__c terrDiv1State = new TM_Territory_Division_State__c(TM_Territory_DivisionId__c = testTerrDivisions[1].Id, State_ProvinceId__c = testStates[0].Id);
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

        TMTerritoryDivisionStateHelper.checkForParentCountries(null);
        TMTerritoryDivisionStateHelper.checkForParentCountries(new List<TM_Territory_Division_State__c>());

        Test.stopTest();
    }



}