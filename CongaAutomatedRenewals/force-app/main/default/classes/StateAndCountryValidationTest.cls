/**
* @author Conga Services, ERedding
* @date 20190117
* @version 1.00
* @description StateAndCountryValidationTest  - Test class for the StateAndCountryValidation class
*/
@isTest
public with sharing class StateAndCountryValidationTest {

    /**
    * @description setup - Create test data
    */
    @testSetup
    public static void setup() {
        // TEST COUNTRY RECORDS 
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'AMER');
        Country_Territory__c argentina = new Country_Territory__c(Name = 'Argentina', Two_Letter_Code__c = 'AR', Three_Letter_Code__c = 'ARG', Geo__c = 'AMER');
        Country_Territory__c russianFederation = new Country_Territory__c(Name = 'Russian Federation', Two_Letter_Code__c = 'RU', Three_Letter_Code__c = 'RUS', Geo__c = 'EMEA');
        Country_Territory__c germany = new Country_Territory__c(Name = 'Germany', Two_Letter_Code__c = 'DE', Three_Letter_Code__c = 'DEU', Geo__c = 'EMEA');
        Country_Territory__c unitedKingdom = new Country_Territory__c(Name = 'United Kingdom', Alternate_Name__c = 'Great Britian', Two_Letter_Code__c = 'GB', Three_Letter_Code__c = 'GBR', 
                                                                      Alternate_Two_Letter_Code__c = 'UK', Alternate_Three_Letter_Code__c = 'UKK', Geo__c = 'EMEA');
        insert new List<Country_Territory__c>{ unitedStates, argentina, russianFederation, germany, unitedKingdom };

        // TEST STATE RECORDS
        State_Province__c colorado = new State_Province__c(Name = 'Colorado', Code__c = 'CO', Country_TerritoryId__c = unitedStates.Id, English_Name__c = 'Colorado');
        State_Province__c california = new State_Province__c(Name = 'California', Code__c = 'CA', Country_TerritoryId__c = unitedStates.Id, English_Name__c = 'California');
        State_Province__c rheinland = new State_Province__c(Name = 'Rheinland-Pfalz', Code__c = 'RP', Country_TerritoryId__c = germany.Id, English_Name__c = 'Rhineland-Palatinate');
        State_Province__c ukTestState = new State_Province__c(Name = 'UK Test State', Code__c = 'ABC', Alternate_Code__c = 'UK2', Country_TerritoryId__c = unitedKingdom.Id, English_Name__c = 'UK Test State');
        insert new List<State_Province__c>{ colorado, california, rheinland, ukTestState };
    }

    /**
    * @description countryValidationTest - Test Country validation code
    */
    public static testMethod void countryValidationTest() {
        Test.startTest();

        // TEST COUNTRY isValidCountry METHOD
        Boolean isValidCountryResult1 = StateAndCountryValidation.isValidCountry('United States');
        Boolean isValidCountryResult2 = StateAndCountryValidation.isValidCountry('US');
        Boolean isValidCountryResult3 = StateAndCountryValidation.isValidCountry('USA');                
        Boolean isValidCountryResult4 = StateAndCountryValidation.isValidCountry('United Stes');
        Boolean isValidCountryResult5 = StateAndCountryValidation.isValidCountry('GB');
        Boolean isValidCountryResult6 = StateAndCountryValidation.isValidCountry('UK');
        Boolean isValidCountryResult7 = StateAndCountryValidation.isValidCountry('Great Britian');
        System.assert(isValidCountryResult1);
        System.assert(isValidCountryResult2);
        System.assert(isValidCountryResult3);
        System.assert(!isValidCountryResult4);
        System.assert(isValidCountryResult5);
        System.assert(isValidCountryResult6);
        System.assert(isValidCountryResult7);

        // TEST COUNTRY getValidCountry METHOD
        String getValidCountryResult1 = StateAndCountryValidation.getValidCountry('Russian Federation');
        String getValidCountryResult2 = StateAndCountryValidation.getValidCountry('Russia');
        String getValidCountryResult3 = StateAndCountryValidation.getValidCountry('Great Britian');
        System.assert(getValidCountryResult1 == 'Russian Federation');
        System.assert(getValidCountryResult2 == null);
        System.assert(getValidCountryResult3 == 'United Kingdom');

        // TEST COUNTRY getCountryFuzzyMatches METHOD
        String getCountryFuzzyMatchesResult1 = StateAndCountryValidation.getCountryFuzzyMatches('U');
        String getCountryFuzzyMatchesResult2 = StateAndCountryValidation.getCountryFuzzyMatches('USE');
        String getCountryFuzzyMatchesResult3 = StateAndCountryValidation.getCountryFuzzyMatches('XXXXX');
        String getCountryFuzzyMatchesResult4 = StateAndCountryValidation.getCountryFuzzyMatches('Russia');
        String getCountryFuzzyMatchesResult5 = StateAndCountryValidation.getCountryFuzzyMatches('Argintina');
        String getCountryFuzzyMatchesResult6 = StateAndCountryValidation.getCountryFuzzyMatches('Great Brit');
        System.assert(getCountryFuzzyMatchesResult1.contains('United States'));
        System.assert(getCountryFuzzyMatchesResult2.contains('United States'));
        System.assert(getCountryFuzzyMatchesResult3.contains('No Possible Matches Found')); 
        System.assert(getCountryFuzzyMatchesResult4.contains('Russian Federation'));
        System.assert(getCountryFuzzyMatchesResult5.contains('Argentina'));
        System.assert(getCountryFuzzyMatchesResult6.contains('United Kingdom'));

        System.assert(StateAndCountryValidation.CountryTwoLetterCodeByFullName.get('United States') == 'US');
        System.assert(StateAndCountryValidation.CountryThreeLetterCodeByFullName.get('United Kingdom') == 'GBR');

        Test.stopTest();
    }
    
    /**
    * @description stateValidationTest - Test State validation code
    */
    public static testMethod void stateValidationTest() {
        Test.startTest();

        // TEST STATE isValidState METHOD
        Boolean isValidStateResult1 = StateAndCountryValidation.isValidState('United States', 'Colorado');
        Boolean isValidStateResult2 = StateAndCountryValidation.isValidState('United States', 'Clorado');
        Boolean isValidStateResult3 = StateAndCountryValidation.isValidState('United Kingdom', 'UK Test State');
        Boolean isValidStateResult4 = StateAndCountryValidation.isValidState('United Kingdom', 'ABC');
        System.assert(isValidStateResult1);
        System.assert(!isValidStateResult2);
        System.assert(isValidStateResult3);
        System.assert(isValidStateResult4);

        // TEST STATE getValidState METHOD
        String getValidStateResult1 = StateAndCountryValidation.getValidState('United States', 'CO');
        String getValidStateResult2 = StateAndCountryValidation.getValidState('United States', 'CU');
        String getValidStateResult3 = StateAndCountryValidation.getValidState('United States', 'US-CO');
        String getValidStateResult4 = StateAndCountryValidation.getValidState('Germany', 'Rheinland-Pfalz'); // GERMAN TRANSLATION
        String getValidStateResult5 = StateAndCountryValidation.getValidState('Germany', 'Rhineland-Palatinate'); // ENGLISH TRANSLATION
        String getValidStateResult6 = StateAndCountryValidation.getValidState('United Kingdom', 'UK2');
        System.assert(getValidStateResult1 == 'Colorado');
        System.assert(getValidStateResult2 == null);
        System.assert(getValidStateResult3 == 'Colorado');
        System.assert(getValidStateResult4 == 'Rheinland-Pfalz'); // GERMAN TRANSLATION
        System.assert(getValidStateResult5 == 'Rheinland-Pfalz'); // GERMAN TRANSLATION
        System.assert(getValidStateResult6 == 'UK Test State');

        // TEST STATE getStateFuzzyMatches METHOD
        String getStateFuzzyMatchesResult1 = StateAndCountryValidation.getStateFuzzyMatches('United State', 'Colorado');
        String getStateFuzzyMatchesResult2 = StateAndCountryValidation.getStateFuzzyMatches('United States', 'ABCDEFG');
        String getStateFuzzyMatchesResult3 = StateAndCountryValidation.getStateFuzzyMatches('United States', 'Clorado');
        String getStateFuzzyMatchesResult4 = StateAndCountryValidation.getStateFuzzyMatches('United States', 'CU'); 
        String getStateFuzzyMatchesResult5 = StateAndCountryValidation.getStateFuzzyMatches('Germany', 'Rhineland-Pala'); // ENGLISH TRANSLATION
        String getStateFuzzyMatchesResult6 = StateAndCountryValidation.getStateFuzzyMatches('Germany', 'Rheinland-Pfal'); // GERMAN TRANSLATION
        String getStateFuzzyMatchesResult7 = StateAndCountryValidation.getStateFuzzyMatches('United Kingdom', 'UK Tes');
        String getStateFuzzyMatchesResult8 = StateAndCountryValidation.getStateFuzzyMatches('United Kingdom', 'UK2');
        String getStateFuzzyMatchesResult9 = StateAndCountryValidation.getStateFuzzyMatches('United Kingdom', 'GB-ABC');
        System.assert(getStateFuzzyMatchesResult1 == null);
        System.assert(getStateFuzzyMatchesResult2.contains('No Possible Matches Found'));
        System.assert(getStateFuzzyMatchesResult3.contains('Colorado'));
        System.assert(getStateFuzzyMatchesResult4.contains('Colorado'));
        System.assert(getStateFuzzyMatchesResult5.contains('Rheinland-Pfalz')); // GERMAN TRANSLATION
        System.assert(getStateFuzzyMatchesResult6.contains('Rheinland-Pfalz')); // GERMAN TRANSLATION
        System.assert(getStateFuzzyMatchesResult7.contains('UK Test State'));
        System.assert(getStateFuzzyMatchesResult8.contains('UK Test State'));
        System.assert(getStateFuzzyMatchesResult9.contains('UK Test State'));


        System.assert(StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.get('United States').get('Colorado') == 'CO');

        Test.stopTest();
    }

    /**
    * @description validateStateAndCountryTest - Test validateStateAndCountry trigger method
    */
    public static testMethod void validateRecordStateCountryPairsTest(){
        Test.startTest();

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account', BillingState = 'CO', BillingCountry = 'USA', ShippingState = 'CA', ShippingCountry = 'USA');

        // GET STATE AND COUNTRY FIELDS NAMES
        Map<String,String> countryStateFieldPairs = new Map<String,String>{ Account.BillingCountry.getDescribe().getName() => Account.BillingState.getDescribe().getName(), 
                                                                            Account.ShippingCountry.getDescribe().getName() => Account.ShippingState.getDescribe().getName() };

        StateAndCountryValidation.validateRecordCountryStatePairs(testAccount, countryStateFieldPairs);
        System.assert(testAccount.BillingState == 'Colorado');
        System.assert(testAccount.BillingCountry == 'United States');
        System.assert(testAccount.ShippingState == 'California');
        System.assert(testAccount.ShippingCountry == 'United States');

        // MAKE INVALID CHANGES AND UPDATE, EACH UPDATE SHOULD CAUSE A TRIGGER ERROR TO OCCUR
        try{
            testAccount.BillingState = 'Colorad';
            StateAndCountryValidation.validateRecordCountryStatePairs(testAccount, countryStateFieldPairs);
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('State'));
        }
        ////
        try{
            testAccount.BillingState = 'Colorado';
            testAccount.BillingCountry = 'United Stat';
            StateAndCountryValidation.validateRecordCountryStatePairs(testAccount, countryStateFieldPairs);
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('Country'));
        }
        ////
        try{
            testAccount.BillingState = 'Colorado';
            testAccount.BillingCountry = 'United States';
            testAccount.ShippingState = 'Californ';
            StateAndCountryValidation.validateRecordCountryStatePairs(testAccount, countryStateFieldPairs);   
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('State'));
        }
        ////
        try{
            testAccount.BillingState = 'Colorado';
            testAccount.BillingCountry = 'United States';
            testAccount.ShippingState = 'California';
            testAccount.ShippingCountry = 'United Stat';
            StateAndCountryValidation.validateRecordCountryStatePairs(testAccount, countryStateFieldPairs);
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('Country'));
        }

        Test.stopTest();
    }

    /**
    * @description noCountryDataTest - Test Country validation code when there are no valid countries created
    */
    public static testMethod void noCountryDataTest() {
        // GET TEST COUNTRIES
        List<Country_Territory__c> testCountries = [SELECT Id FROM Country_Territory__c];
        delete testCountries;

        Test.startTest();

        // TEST COUNTRY isValidCountry METHOD, WITHOUT ANY VALID COUNTRIES, ALL VALUES WILL BE ACCEPTED
        Boolean isValidCountryResult1 = StateAndCountryValidation.isValidCountry('United Stes');
        Boolean isValidCountryResult2 = StateAndCountryValidation.isValidCountry('U');
        System.assert(isValidCountryResult1);
        System.assert(isValidCountryResult2);

        // TEST COUNTRY getValidCountry METHOD, WITHOUT ANY VALID COUNTRIES, ALL VALUES WILL BE ACCEPTED
        String getValidCountryResult1 = StateAndCountryValidation.getValidCountry('Russian Federation');
        String getValidCountryResult2 = StateAndCountryValidation.getValidCountry('Russia');
        System.assert(getValidCountryResult1 == 'Russian Federation');
        System.assert(getValidCountryResult2 == 'Russia');

        // CREATE A VALIDATION COUNTRY
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'AMER');
        insert unitedStates;
        StateAndCountryValidation.loadCountries(); // FORCE RELOAD

        // TEST COUNTRY isValidCountry METHOD, BAD VALUES WILL NOW BE VALIDATED AND REJECTED
        Boolean isValidCountryResult = StateAndCountryValidation.isValidCountry('United State');
        System.assert(!isValidCountryResult);

        // TEST COUNTRY getValidCountry METHOD
        String getValidCountryResult = StateAndCountryValidation.getValidCountry('Russia');
        System.assert(getValidCountryResult == null);

        Test.stopTest();
    }

    /**
    * @description noStateDataTest - Test State validation code when there are no valid states created for a specific Country
    */
    public static testMethod void noStateDataTest() {
        // GET UNITED STATES COUNTRY
        List<Country_Territory__c> unitedStates = [SELECT Id FROM Country_Territory__c WHERE Name = 'United States'];
        System.assert(!unitedStates.isEmpty());

        // GET STATE RECORDS
        List<State_Province__c> testStates = [SELECT Id FROM State_Province__c];
        delete testStates;

        Test.startTest();

        // TEST STATE isValidState METHOD, WITHOUT ANY VALID STATES FOR THE COUNTRY, ALL STATE VALUES WILL BE ACCEPTED
        Boolean isValidStateResult1 = StateAndCountryValidation.isValidState('United States', 'Corado');
        Boolean isValidStateResult2 = StateAndCountryValidation.isValidState('United States', 'Clorado');
        System.assert(isValidStateResult1);
        System.assert(isValidStateResult2);

        // TEST STATE getValidState METHOD, WITHOUT ANY VALID STATES FOR THE COUNTRY, ALL STATE VALUES WILL BE ACCEPTED
        String getValidStateResult1 = StateAndCountryValidation.getValidState('United States', 'CX');
        String getValidStateResult2 = StateAndCountryValidation.getValidState('United States', 'CU');
        System.assert(getValidStateResult1 == 'CX');
        System.assert(getValidStateResult2 == 'CU');

        // CREATE A VALIDATION STATE
        State_Province__c colorado = new State_Province__c(Name = 'Colorado', Code__c = 'CO', Country_TerritoryId__c = unitedStates[0].Id, English_Name__c = 'Colorado');
        insert colorado;
        StateAndCountryValidation.loadStates(); // FORCE RELOAD

        // TEST COUNTRY isValidCountry METHOD, BAD VALUES WILL NOW BE VALIDATED AND REJECTED
        Boolean isValidStateResult = StateAndCountryValidation.isValidState('United States', 'Corado');
        System.assert(!isValidStateResult);

        // TEST COUNTRY getValidCountry METHOD
        String getValidStateResult = StateAndCountryValidation.getValidState('United States', 'CX');
        System.assert(getValidStateResult == null);

        Test.stopTest();
    }


}