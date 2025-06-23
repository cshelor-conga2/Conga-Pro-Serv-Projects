/**
* @author ECS, ERedding
* @date 20200218
* @version 1.00
* @description TMTerritoryDivisionCountryHelperTest - Test class for the TMTerritoryDivisionCountryHelper class
*/
@isTest
public with sharing class TMTerritoryDivisionCountryHelperTest {

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

        // CREATE TEST TERRITORY COUNTRIES
        TM_Territory_Division_Country__c terr1Division1USA = new TM_Territory_Division_Country__c(TM_Territory_DivisionId__c = terr1Division1.Id, Country_TerritoryId__c = unitedStates.Id);
        insert new List<TM_Territory_Division_Country__c>{ terr1Division1USA };
    }

    /**
    * @description checkForExistingUseTest - Test checkForExistingUse trigger method
    */
    public static testMethod void checkForExistingUseTest() {
        // GET TEST COUNTRIES
        List<Country_Territory__c> testCountries = [SELECT Id, Name FROM Country_Territory__c]; // UNITED STATES
        System.assert(testCountries.size() == 2);   

        // GET TEST TERRITORY DIVISIONS
        List<TM_Territory_Division__c> testTerrDivisions = [SELECT Id, Name FROM TM_Territory_Division__c];
        System.assert(testTerrDivisions.size() == 2);

        Test.startTest();

        // TRY ADDING UNITED STATES A SECOND TIME TO THE SAME TERRITORY
        TM_Territory_Division_Country__c terr1Division1USA = new TM_Territory_Division_Country__c(TM_Territory_DivisionId__c = testTerrDivisions[0].Id, Country_TerritoryId__c = testCountries[0].Id);
        Database.saveResult insertResult = Database.insert(terr1Division1USA, false);

        // RECORD SHOULD BE REJECTED AND HAVE AN ERROR
        System.assert(insertResult != null);
        System.assert(insertResult.isSuccess() == false);
        System.assert(insertResult.getErrors().isEmpty() == false);
        System.assert(insertResult.getErrors()[0].getMessage().contains('This Country is already used') == true);

        // TRY ADDING UNITED STATES TO ANOTHER TERRITORY SEGMENT
        TM_Territory_Division_Country__c terr1Division2USA = new TM_Territory_Division_Country__c(TM_Territory_DivisionId__c = testTerrDivisions[1].Id, Country_TerritoryId__c = testCountries[0].Id);
        Database.saveResult insertResult2 = Database.insert(terr1Division2USA, false);

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

        TMTerritoryDivisionCountryHelper.checkForExistingUse(null);
        TMTerritoryDivisionCountryHelper.checkForExistingUse(new List<TM_Territory_Division_Country__c>());

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

        // GET TEST TERRITORY DIVISIONS
        List<TM_Territory_Division__c> testTerrDivisions = [SELECT Id, Name FROM TM_Territory_Division__c];
        System.assert(testTerrDivisions.size() == 2);

        // CREATE TEST TERRITORY STATES
        TM_Territory_Division_State__c testTerrDiv1Colorado = new TM_Territory_Division_State__c(TM_Territory_DivisionId__c = testTerrDivisions[1].Id, State_ProvinceId__c = testStates[0].Id);
        insert testTerrDiv1Colorado;

        Test.startTest();

        // TRY ADDING UNITED STATES WHEN COLORADO ALREADY EXISTS ON THE TERRITORY
        TM_Territory_Division_Country__c terrDivCountry1 = new TM_Territory_Division_Country__c(TM_Territory_DivisionId__c = testTerrDivisions[1].Id, Country_TerritoryId__c = testCountries[0].Id);
        Database.saveResult insertResult = Database.insert(terrDivCountry1, false);

        // RECORD SHOULD BE REJECTED AND HAVE AN ERROR
        System.assert(insertResult != null);
        System.assert(insertResult.isSuccess() == false);
        System.assert(insertResult.getErrors().isEmpty() == false);
        System.assert(insertResult.getErrors()[0].getMessage().contains('A Country cannot be added') == true);

        // ADD MEXICO TO THE TERRITORY AND THEN TRY CHANGING TO UNITED STATES
        terrDivCountry1.Country_TerritoryId__c = testCountries[1].Id;
        insert terrDivCountry1;
        terrDivCountry1.Country_TerritoryId__c = testCountries[0].Id;
        Database.saveResult updateResult = Database.update(terrDivCountry1, false);
        
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

        TMTerritoryDivisionCountryHelper.checkForChildStates(null);
        TMTerritoryDivisionCountryHelper.checkForChildStates(new List<TM_Territory_Division_Country__c>());

        Test.stopTest();
    }


}