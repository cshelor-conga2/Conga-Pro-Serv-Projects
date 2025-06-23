/**
* @author Conga Services, ERedding
* @date 20190110
* @version 1.00
* @description StateAndCountryValidation - Class with various methods used to validate user entered States/Provinces and Countries/Territories
*/
public class StateAndCountryValidation {

    /////////////////////// *********************** STATIC CLASS VARIABLES ************************ ////////////////////////

    //// COUNTRIES/TERRITORIES BY THEIR CLEANED NAME
    private static Map<String, String> FullCountryNamesByCleanName {
    get {
        if(FullCountryNamesByCleanName == null){ StateAndCountryValidation.loadCountries(); }
        return FullCountryNamesByCleanName;
    } set; }
    //// COUNTRIES/TERRITORIES BY THEIR CLEANED ALTERNATE NAME
    private static Map<String, String> FullCountryNamesByCleanAltName {
    get {
        if(FullCountryNamesByCleanAltName == null){ StateAndCountryValidation.loadCountries(); }
        return FullCountryNamesByCleanAltName;
    } set; }    
    //// COUNTRIES/TERRITORIES BY THEIR TWO LETTER CODE
    private static Map<String, String> FullCountryNamesByCleanTwoLetterCode {
    get { 
        if(FullCountryNamesByCleanTwoLetterCode == null){ StateAndCountryValidation.loadCountries(); }
        return FullCountryNamesByCleanTwoLetterCode;
    } set; }
    //// COUNTRIES/TERRITORIES BY THEIR THREE LETTER CODE
    private static Map<String, String> FullCountryNamesByCleanThreeLetterCode {
    get { 
        if(FullCountryNamesByCleanThreeLetterCode == null){  StateAndCountryValidation.loadCountries(); }
        return FullCountryNamesByCleanThreeLetterCode;
    } set; }
    //// COUNTRIES/TERRITORIES BY THEIR ALTERNATE TWO LETTER CODE
    private static Map<String, String> FullCountryNamesByCleanAltTwoLetterCode {
    get { 
        if(FullCountryNamesByCleanAltTwoLetterCode == null){ StateAndCountryValidation.loadCountries(); }
        return FullCountryNamesByCleanAltTwoLetterCode;
    } set; }
    //// COUNTRIES/TERRITORIES BY THEIR ALTERNATE THREE LETTER CODE
    private static Map<String, String> FullCountryNamesByCleanAltThreeLetterCode {
    get {
        if(FullCountryNamesByCleanAltThreeLetterCode == null){ StateAndCountryValidation.loadCountries(); }
        return FullCountryNamesByCleanAltThreeLetterCode;
    } set; }
    //// COUNTRY/TERRITORY TWO LETTER CODES BY THEIR FULL NAME
    public static Map<String, String> CountryTwoLetterCodeByFullName {
    get {
        if(CountryTwoLetterCodeByFullName == null){ StateAndCountryValidation.loadCountries(); }
        return CountryTwoLetterCodeByFullName;
    } set; }
    //// COUNTRY/TERRITORY THREE LETTER CODES BY THEIR FULL NAME
    public static Map<String, String> CountryThreeLetterCodeByFullName {
    get {
        if(CountryThreeLetterCodeByFullName == null){ StateAndCountryValidation.loadCountries(); }
        return CountryThreeLetterCodeByFullName;
    } set; }
    //// COUNTRY GEO BY COUNTRY FULL NAME
    public static Map<String, String> GeoByFullCountryName {
    get {
        if(GeoByFullCountryName == null){ StateAndCountryValidation.loadCountries(); }
        return GeoByFullCountryName;
    } set; }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////
    //// STATES/PROVINCE FULL NAMES BY THEIR CLEAN COUNTRY NAME AND CLEAN STATE CODE
    private static Map<String, Map<String, String>> FullStatesNamesByCleanCountryNameAndCleanCode {
    get {
        if(FullStatesNamesByCleanCountryNameAndCleanCode == null){ StateAndCountryValidation.loadStates();}
        return FullStatesNamesByCleanCountryNameAndCleanCode;
    } set; }
    //// STATES/PROVINCE FULL NAMES BY THEIR CLEAN COUNTRY NAME AND CLEAN ALTERNATE STATE CODE
    private static Map<String, Map<String, String>> FullStatesNamesByCleanCountryNameAndCleanAltCode {
    get {
        if(FullStatesNamesByCleanCountryNameAndCleanAltCode == null){ StateAndCountryValidation.loadStates(); }
        return FullStatesNamesByCleanCountryNameAndCleanAltCode;
    } set; }
    //// STATES/PROVINCE FULL NAMES BY THEIR CLEAN COUNTRY NAME AND CLEAN STATE NAME
    private static Map<String, Map<String, String>> FullStatesNamesByCleanCountryNameAndCleanStateName {
    get {
        if(FullStatesNamesByCleanCountryNameAndCleanStateName == null){ StateAndCountryValidation.loadStates(); }
        return FullStatesNamesByCleanCountryNameAndCleanStateName;
    } set; }
    //// STATES/PROVINCE FULL NAMES BY THEIR CLEAN COUNTRY NAME AND CLEAN STATE FULL ISO CODE
    private static Map<String, Map<String, String>> FullStatesNamesByCleanCountryNameAndCleanStateFullISO {
    get {
        if(FullStatesNamesByCleanCountryNameAndCleanStateFullISO == null){ StateAndCountryValidation.loadStates(); }
        return FullStatesNamesByCleanCountryNameAndCleanStateFullISO;
    } set; }
    //// STATES/PROVINCE FULL NAMES BY THEIR CLEAN COUNTRY NAME AND CLEAN STATE ENGLISH NAME
    private static Map<String, Map<String, String>> FullStatesNamesByCleanCountryNameAndCleanStateEnglishName {
    get {
        if(FullStatesNamesByCleanCountryNameAndCleanStateEnglishName == null){ StateAndCountryValidation.loadStates(); }
        return FullStatesNamesByCleanCountryNameAndCleanStateEnglishName;
    } set; }
    //// STATE/PROVINCE CODES BY THEIR COUNTRY FULL NAME AND STATE FULL NAME
    public static Map<String, Map<String, String>> StateCodesByCountryFullNameAndStateFullName {
    get {
        if(StateCodesByCountryFullNameAndStateFullName == null){ StateAndCountryValidation.loadStates(); }
        return StateCodesByCountryFullNameAndStateFullName;
    } set; }


    /////////////////////// *********************** STATIC METHODS ************************ ////////////////////////

    /**
    * @description loadCountries - Queries for Country data from the Country_Territory__c object and populates the proper class level static variables
    * @return void
    */
    @testVisible
    private static void loadCountries(){
        try{
            // INITIALIZE STATIC VARIABLES
            FullCountryNamesByCleanName = new Map<String, String>();
            FullCountryNamesByCleanAltName = new Map<String, String>();
            FullCountryNamesByCleanTwoLetterCode = new Map<String, String>();
            FullCountryNamesByCleanThreeLetterCode = new Map<String, String>();
            FullCountryNamesByCleanAltTwoLetterCode = new Map<String, String>();
            FullCountryNamesByCleanAltThreeLetterCode = new Map<String, String>();
            CountryTwoLetterCodeByFullName = new Map<String, String>();
            CountryThreeLetterCodeByFullName = new Map<String, String>();            
            GeoByFullCountryName = new Map<String, String>();

            // LOAD COUNTRY DATA FROM Country_Territory__c CUSTOM OBJECT
            for(Country_Territory__c country : [SELECT Name, Alternate_Name__c, Two_Letter_Code__c, Three_Letter_Code__c, Alternate_Two_Letter_Code__c, Alternate_Three_Letter_Code__c, Geo__c
                                                FROM Country_Territory__c ORDER BY Name]){

                // STRIP ALL BUT ALPHA CHARACTERS FROM NAME AND CODES AND MAKE LOWER CASE
                String cleanedCountryName = cleanString(country.Name, false);
                String cleanedCountryAltName = cleanString(country.Alternate_Name__c, false);
                String cleanedTwoLetterCode = cleanString(country.Two_Letter_Code__c, false);
                String cleanedThreeLetterCode = cleanString(country.Three_Letter_Code__c, false);
                String cleanedAlternateTwoLetterCode = cleanString(country.Alternate_Two_Letter_Code__c, false);
                String cleanedAlternateThreeLetterCode = cleanString(country.Alternate_Three_Letter_Code__c, false);               

                // POPULATE STATIC VARIABLES
                FullCountryNamesByCleanName.put(cleanedCountryName, country.Name);
                FullCountryNamesByCleanTwoLetterCode.put(cleanedTwoLetterCode, country.Name);
                FullCountryNamesByCleanThreeLetterCode.put(cleanedThreeLetterCode, country.Name);
                CountryTwoLetterCodeByFullName.put(country.Name, country.Two_Letter_Code__c);
                CountryThreeLetterCodeByFullName.put(country.Name, country.Three_Letter_Code__c);
                GeoByFullCountryName.put(country.Name, country.Geo__c);
                // ALTERNATE NAME/CODES
                if(String.isNotBlank(cleanedCountryAltName)){
                    FullCountryNamesByCleanAltName.put(cleanedCountryAltName, country.Name);
                }
                if(String.isNotBlank(cleanedAlternateTwoLetterCode)){
                    FullCountryNamesByCleanAltTwoLetterCode.put(cleanedAlternateTwoLetterCode, country.Name);
                }
                if(String.isNotBlank(cleanedAlternateThreeLetterCode)){
                    FullCountryNamesByCleanAltThreeLetterCode.put(cleanedAlternateThreeLetterCode, country.Name);
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('StateAndCountryValidation', 'loadCountries', '', ex, true);
        }
    }

    /**
    * @description loadStates - Queries for State data from the State_Province__c object and populates the proper class level static variables
    * @return void
    */
    @testVisible
    private static void loadStates(){
        try{
            // INITIALIZE STATIC VARIABLES
            FullStatesNamesByCleanCountryNameAndCleanCode = new Map<String, Map<String, String>>();
            FullStatesNamesByCleanCountryNameAndCleanAltCode = new Map<String, Map<String, String>>();
            FullStatesNamesByCleanCountryNameAndCleanStateName = new Map<String, Map<String, String>>();
            FullStatesNamesByCleanCountryNameAndCleanStateFullISO = new Map<String, Map<String, String>>();
            FullStatesNamesByCleanCountryNameAndCleanStateEnglishName = new Map<String, Map<String, String>>();  
            StateCodesByCountryFullNameAndStateFullName = new Map<String, Map<String, String>>();         

            // LOAD COUNTRY DATA FROM State_Province__c CUSTOM OBJECT
            for(State_Province__c state : [SELECT Country_TerritoryId__r.Name, Name, Code__c, Alternate_Code__c, English_Name__c, Full_ISO_CodeFx__c
                                           FROM State_Province__c ORDER BY Name]){

                // STRIP ALL BUT ALPHA CHARACTERS FROM NAME AND CODES AND MAKE LOWER CASE
                String cleanedCountryName = cleanString(state.Country_TerritoryId__r.Name, false);
                String cleanedStateName = cleanString(state.Name, false);
                String cleanedStateCode = cleanString(state.Code__c, true);
                String cleanedStateAltCode = cleanString(state.Alternate_Code__c, true);
                String cleanedStateFullIsoCode = cleanString(state.Full_ISO_CodeFx__c, true);
                String cleanedStateEnglishName = cleanString(state.English_Name__c, false);

                // POPULATE STATIC VARIABLES
                if(!FullStatesNamesByCleanCountryNameAndCleanCode.containsKey(cleanedCountryName)){
                    FullStatesNamesByCleanCountryNameAndCleanCode.put(cleanedCountryName, new Map<String, String>());
                }
                FullStatesNamesByCleanCountryNameAndCleanCode.get(cleanedCountryName).put(cleanedStateCode, state.Name);
                //             
                if(!FullStatesNamesByCleanCountryNameAndCleanStateName.containsKey(cleanedCountryName)){
                    FullStatesNamesByCleanCountryNameAndCleanStateName.put(cleanedCountryName, new Map<String, String>());
                }
                FullStatesNamesByCleanCountryNameAndCleanStateName.get(cleanedCountryName).put(cleanedStateName, state.Name);
                //
                if(!FullStatesNamesByCleanCountryNameAndCleanStateFullISO.containsKey(cleanedCountryName)){
                    FullStatesNamesByCleanCountryNameAndCleanStateFullISO.put(cleanedCountryName, new Map<String, String>());
                }
                FullStatesNamesByCleanCountryNameAndCleanStateFullISO.get(cleanedCountryName).put(cleanedStateFullIsoCode, state.Name);
                //
                if(!FullStatesNamesByCleanCountryNameAndCleanStateEnglishName.containsKey(cleanedCountryName)){
                    FullStatesNamesByCleanCountryNameAndCleanStateEnglishName.put(cleanedCountryName, new Map<String, String>());
                }
                FullStatesNamesByCleanCountryNameAndCleanStateEnglishName.get(cleanedCountryName).put(cleanedStateEnglishName, state.Name);
                // ALTERNATE CODE
                if(!FullStatesNamesByCleanCountryNameAndCleanAltCode.containsKey(cleanedCountryName)){
                    FullStatesNamesByCleanCountryNameAndCleanAltCode.put(cleanedCountryName, new Map<String, String>());
                }
                if(String.isNotBlank(cleanedStateAltCode)){
                    FullStatesNamesByCleanCountryNameAndCleanAltCode.get(cleanedCountryName).put(cleanedStateAltCode, state.Name);
                }
                //
                if(!StateCodesByCountryFullNameAndStateFullName.containsKey(state.Country_TerritoryId__r.Name)){
                    StateCodesByCountryFullNameAndStateFullName.put(state.Country_TerritoryId__r.Name, new Map<String, String>());
                }
                StateCodesByCountryFullNameAndStateFullName.get(state.Country_TerritoryId__r.Name).put(state.Name, state.Code__c);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('StateAndCountryValidation', 'loadStates', '', ex, true);
        }
    }

    /**
    * @description isValidCountry - Checks if the supplied country name or code is valid and returns true or false
    * @param String countryNameOrCode - Country string value to validate. Can be a full country name, 3 letter code, or 2 letter code.
    * @return Boolean - True if the Country/Territory is valid or blank, false if its not
    */
    public static Boolean isValidCountry(String countryNameOrCode){
        // CHECK FOR VALID COUNTRY/TERRITORY
        if(String.isBlank(countryNameOrCode) || getValidCountry(countryNameOrCode) != null){
            return true;
        }
        return false;
    }

    /**
    * @description getValidCountry - Checks if the supplied country name or code is valid and returns the full country name
    * @param String countryNameOrCode - Country string value to validate. Can be a full country name, 3 letter code, or 2 letter code.
    * @return String - Full Name of the Country/Territory if it's found to be valid
    */
    public static String getValidCountry(String countryNameOrCode){
        try{
            if(FullCountryNamesByCleanName.isEmpty()){
                return countryNameOrCode; // IF THERE ARE NO VALID COUNTRIES TO VALIDATE AGAINST, JUST ACCEPT THE USER ENTERED VALUE
            }
            else if(countryNameOrCode != null && String.isNotBlank(countryNameOrCode)){
                // CLEAN ENTERED VALUE OF ALL NON ALPHA CHARACTERS AND MAKE LOWER CASE
                String cleanCountryNameOrCode = cleanString(countryNameOrCode, false);

                // CHECK FOR VALID TWO LETTER CODE
                if(cleanCountryNameOrCode.length() == 2 && FullCountryNamesByCleanTwoLetterCode.containsKey(cleanCountryNameOrCode)){
                    return FullCountryNamesByCleanTwoLetterCode.get(cleanCountryNameOrCode);
                }

                // CHECK FOR VALID THREE LETTER CODE
                if(cleanCountryNameOrCode.length() == 3 && FullCountryNamesByCleanThreeLetterCode.containsKey(cleanCountryNameOrCode)){
                    return FullCountryNamesByCleanThreeLetterCode.get(cleanCountryNameOrCode);
                }

                // CHECK FOR VALID FULL NAME
                if(cleanCountryNameOrCode.length() >= 2 && FullCountryNamesByCleanName.containsKey(cleanCountryNameOrCode)){
                    return FullCountryNamesByCleanName.get(cleanCountryNameOrCode);
                }

                // CHECK FOR VALID ALTERNATE FULL NAME
                if(cleanCountryNameOrCode.length() >= 2 && FullCountryNamesByCleanAltName.containsKey(cleanCountryNameOrCode)){
                    return FullCountryNamesByCleanAltName.get(cleanCountryNameOrCode);
                }

                // CHECK FOR VALID ALTERNATE TWO LETTER CODE
                if(cleanCountryNameOrCode.length() == 2 && FullCountryNamesByCleanAltTwoLetterCode.containsKey(cleanCountryNameOrCode)){
                    return FullCountryNamesByCleanAltTwoLetterCode.get(cleanCountryNameOrCode);
                }

                // CHECK FOR VALID ALTERNATE THREE LETTER CODE
                if(cleanCountryNameOrCode.length() == 3 && FullCountryNamesByCleanAltThreeLetterCode.containsKey(cleanCountryNameOrCode)){
                    return FullCountryNamesByCleanAltThreeLetterCode.get(cleanCountryNameOrCode);
                }
            }
            return null;
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('StateAndCountryValidation', 'getValidCountry', '', ex, true);
            return null;
        }
    }

    /**
    * @description getCountryFuzzyMatches - Attempts to find countries that are similar to the supplied name or code
    * @param String countryNameOrCode - Country string value to validate. Can be a full country name, 3 letter code, or 2 letter code.
    * @return String - String containing a concatenated list of values similar to the entered Country name or code
    */
    public static String getCountryFuzzyMatches(String countryNameOrCode){
        try{
            if(countryNameOrCode != null && String.isNotBlank(countryNameOrCode)){
                List<String> similarValues = new List<String>();
                String cleanCountryNameOrCode = cleanString(countryNameOrCode, false);

                // GET SIMILAR COUNTRIES BY NAME
                if(cleanCountryNameOrCode.length() >= 4){
                    for(String cleanCountryName : FullCountryNamesByCleanName.keySet()){
                        if(JaroWinklerSimilarity.calculateSimilarity(cleanCountryNameOrCode, cleanCountryName) >= 0.75){
                            similarValues.add(FullCountryNamesByCleanName.get(cleanCountryName));
                        }
                    }
                }

                // GET SIMILAR COUNTRIES BY ALTERNATE NAME
                if(cleanCountryNameOrCode.length() >= 4){
                    for(String cleanCountryName : FullCountryNamesByCleanAltName.keySet()){
                        if(JaroWinklerSimilarity.calculateSimilarity(cleanCountryNameOrCode, cleanCountryName) >= 0.75){
                            similarValues.add(FullCountryNamesByCleanAltName.get(cleanCountryName));
                        }
                    }
                }

                // GET SIMILAR COUNTRIES BY TWO LETTER CODE
                if(cleanCountryNameOrCode.length() <= 3){
                    for(String cleanTwoLetterCode : FullCountryNamesByCleanTwoLetterCode.keySet()){
                        if(cleanCountryNameOrCode.getLevenshteinDistance(cleanTwoLetterCode, 1) != -1 && cleanCountryNameOrCode.left(1) == cleanTwoLetterCode.left(1)){
                            similarValues.add(FullCountryNamesByCleanTwoLetterCode.get(cleanTwoLetterCode));
                        }
                    }
                }

                // GET SIMILAR COUNTRIES BY THREE LETTER CODE
                if(cleanCountryNameOrCode.length() <= 4){
                    for(String cleanThreeLetterCode : FullCountryNamesByCleanThreeLetterCode.keySet()){
                        if(cleanCountryNameOrCode.getLevenshteinDistance(cleanThreeLetterCode, 1) != -1 && cleanCountryNameOrCode.left(1) == cleanThreeLetterCode.left(1)){
                            similarValues.add(FullCountryNamesByCleanThreeLetterCode.get(cleanThreeLetterCode));
                        }
                    }
                }

                // GET SIMILAR COUNTRIES BY ALTERNATE TWO LETTER CODE
                if(cleanCountryNameOrCode.length() <= 3){
                    for(String cleanTwoLetterCode : FullCountryNamesByCleanAltTwoLetterCode.keySet()){
                        if(cleanCountryNameOrCode.getLevenshteinDistance(cleanTwoLetterCode, 1) != -1 && cleanCountryNameOrCode.left(1) == cleanTwoLetterCode.left(1)){
                            similarValues.add(FullCountryNamesByCleanAltTwoLetterCode.get(cleanTwoLetterCode));
                        }
                    }
                }

                // GET SIMILAR COUNTRIES BY ALTERNATE THREE LETTER CODE
                if(cleanCountryNameOrCode.length() <= 4){
                    for(String cleanThreeLetterCode : FullCountryNamesByCleanAltThreeLetterCode.keySet()){
                        if(cleanCountryNameOrCode.getLevenshteinDistance(cleanThreeLetterCode, 1) != -1 && cleanCountryNameOrCode.left(1) == cleanThreeLetterCode.left(1)){
                            similarValues.add(FullCountryNamesByCleanAltThreeLetterCode.get(cleanThreeLetterCode));
                        }
                    }
                }

                // ADD 'No Possible Matches Found' TO LIST IF NO MATCHES ARE FOUND
                if(similarValues.isEmpty()){
                    similarValues.add('No Possible Matches Found');
                }
                similarValues.sort();
                return stringSetToSingleString(new Set<String>(similarValues), ' | ');
            }

            return null;
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('StateAndCountryValidation', 'getCountryFuzzyMatches', '', ex, true);
            return null;
        }
    }


    /**
    * @description isValidState - Checks if the supplied state name or code is valid and returns true or false
    * @param String stateNameOrCode - State string value to validate. Can be a full state name or 2 letter code.
    * @return Boolean - True if the State/Province is valid, false if its not
    */
    public static Boolean isValidState(String countryNameOrCode, String stateNameOrCode){
        // CHECK FOR VALID STATE/PROVINCE
        if(String.isBlank(stateNameOrCode) || getValidState(countryNameOrCode, stateNameOrCode) != null){
            return true;
        }
        return false;
    }

    /**
    * @description getValidState - Checks if the supplied state name or code is valid and returns the full state name
    * @param String stateNameOrCode - State string value to validate. Can be a full state name or 2 letter code.
    * @return String - Full Name of the State/Province if it's found to be valid
    */
    public static String getValidState(String countryNameOrCode, String stateNameOrCode){
        try{
            if(FullCountryNamesByCleanName.isEmpty()){
                return stateNameOrCode; // IF THERE ARE NO VALID COUNTRIES FROM WHICH TO GET STATE DATA, JUST RETURN THE USER ENTERED VALUE
            }
            else if(countryNameOrCode != null && String.isNotBlank(countryNameOrCode) && stateNameOrCode != null && String.isNotBlank(stateNameOrCode)){
                // STRIP ENTERED VALUE OF ALL NON ALPHA CHARACTERS AND MAKE LOWER CASE
                String cleanCountryNameOrCode = getValidCountry(countryNameOrCode) != null ? cleanString(getValidCountry(countryNameOrCode), false) : null;
                String cleanStateNameOrCode = cleanString(stateNameOrCode, true);

                if(FullStatesNamesByCleanCountryNameAndCleanStateName.isEmpty() || !FullStatesNamesByCleanCountryNameAndCleanStateName.containsKey(cleanCountryNameOrCode)){
                    return stateNameOrCode; // IF THERE IS NO STATE DATA OR THE COUNTRY DOES NOT HAVE ANY STATES, JUST RETURN THE USER ENTERED VALUE
                }
                else if(cleanCountryNameOrCode != null){ // WILL NOT BE NULL IF COUNTRY IS VALID
                    // CHECK FOR VALID STATE BY CLEAN NAME
                    if(FullStatesNamesByCleanCountryNameAndCleanStateName.get(cleanCountryNameOrCode).containsKey(cleanStateNameOrCode)){
                        return FullStatesNamesByCleanCountryNameAndCleanStateName.get(cleanCountryNameOrCode).get(cleanStateNameOrCode);
                    }

                    // CHECK FOR VALID STATE BY CLEAN CODE
                    if(FullStatesNamesByCleanCountryNameAndCleanCode.get(cleanCountryNameOrCode).containsKey(cleanStateNameOrCode)){
                        return FullStatesNamesByCleanCountryNameAndCleanCode.get(cleanCountryNameOrCode).get(cleanStateNameOrCode);
                    }

                    // CHECK FOR VALID STATE BY CLEAN FULL ISO CODE
                    if(FullStatesNamesByCleanCountryNameAndCleanStateFullISO.get(cleanCountryNameOrCode).containsKey(cleanStateNameOrCode)){
                        return FullStatesNamesByCleanCountryNameAndCleanStateFullISO.get(cleanCountryNameOrCode).get(cleanStateNameOrCode);
                    }

                    // CHECK FOR VALID STATE BY CLEAN ENGLISH NAME
                    if(FullStatesNamesByCleanCountryNameAndCleanStateEnglishName.get(cleanCountryNameOrCode).containsKey(cleanStateNameOrCode)){
                        return FullStatesNamesByCleanCountryNameAndCleanStateEnglishName.get(cleanCountryNameOrCode).get(cleanStateNameOrCode);
                    }

                    // CHECK FOR VALID STATE BY CLEAN ALTERNATE CODE
                    if(FullStatesNamesByCleanCountryNameAndCleanAltCode.get(cleanCountryNameOrCode).containsKey(cleanStateNameOrCode)){
                        return FullStatesNamesByCleanCountryNameAndCleanAltCode.get(cleanCountryNameOrCode).get(cleanStateNameOrCode);
                    }
                }
            }
            return null;
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('StateAndCountryValidation', 'getValidState', '', ex, true);
            return null;
        }
    }

    /**
    * @description getStateFuzzyMatches - Attempts to find states that are similar to the supplied name or code
    * @param String countryNameOrCode - User entered Country name or code
    * @param String stateNameOrCode - User entered State name or code
    * @return String - String containing a concatenated list of values similar to the entered State name or code
    */
    public static String getStateFuzzyMatches(String countryNameOrCode, String stateNameOrCode){
        try{
            if(countryNameOrCode != null && String.isNotBlank(countryNameOrCode) && stateNameOrCode != null && String.isNotBlank(stateNameOrCode)){
                List<String> similarValues = new List<String>();
                Set<String> alreadyUsedFullNames = new Set<String>();
                String cleanCountryNameOrCode = getValidCountry(countryNameOrCode) != null ? cleanString(getValidCountry(countryNameOrCode), false) : null;
                String cleanStateNameOrCode = cleanString(stateNameOrCode, true);

                if(cleanCountryNameOrCode != null){
                    // GET STATES NAMES AND CODES APPLICABLE TO COUNTRY
                    Set<String> cleanStateNamesForCountry = FullStatesNamesByCleanCountryNameAndCleanStateName.get(cleanCountryNameOrCode).keySet();
                    Set<String> cleanStateCodesForCountry = FullStatesNamesByCleanCountryNameAndCleanCode.get(cleanCountryNameOrCode).keySet();
                    Set<String> cleanStateAltCodesForCountry = FullStatesNamesByCleanCountryNameAndCleanAltCode.get(cleanCountryNameOrCode).keySet();
                    Set<String> cleanStateFullISOCodesForCountry = FullStatesNamesByCleanCountryNameAndCleanStateFullISO.get(cleanCountryNameOrCode).keySet();
                    Set<String> cleanStateEnglishNamesForCountry = FullStatesNamesByCleanCountryNameAndCleanStateEnglishName.get(cleanCountryNameOrCode).keySet();

                    // GET SIMILAR STATES BY NAME
                    for(String cleanStateName : cleanStateNamesForCountry){
                        if(JaroWinklerSimilarity.calculateSimilarity(cleanStateNameOrCode, cleanStateName) >= 0.70){
                            String similarName = FullStatesNamesByCleanCountryNameAndCleanStateName.get(cleanCountryNameOrCode).get(cleanStateName);
                            if(!alreadyUsedFullNames.contains(similarName)){
                                similarValues.add(similarName);
                                alreadyUsedFullNames.add(similarName);
                            }
                        }
                    }

                    // GET SIMILAR STATES BY ENGLISH NAME
                    for(String cleanStateEnglishName : cleanStateEnglishNamesForCountry){
                        if(JaroWinklerSimilarity.calculateSimilarity(cleanStateNameOrCode, cleanStateEnglishName) >= 0.70){
                            String similarName = FullStatesNamesByCleanCountryNameAndCleanStateEnglishName.get(cleanCountryNameOrCode).get(cleanStateEnglishName);
                            if(!alreadyUsedFullNames.contains(similarName)){
                                similarValues.add(similarName);
                                alreadyUsedFullNames.add(similarName);
                            }
                        }
                    }

                    // GET SIMILAR STATES BY CODE
                    if(cleanStateNameOrCode.length() <= 4){
                        for(String cleanStateCode : cleanStateCodesForCountry){
                            if(cleanStateNameOrCode.getLevenshteinDistance(cleanStateCode, 1) != -1){
                                String similarName = FullStatesNamesByCleanCountryNameAndCleanCode.get(cleanCountryNameOrCode).get(cleanStateCode);
                                if(!alreadyUsedFullNames.contains(similarName)){
                                    similarValues.add(similarName);
                                    alreadyUsedFullNames.add(similarName);
                                }
                            }
                        }
                    }

                    // GET SIMILAR STATES BY ALTERNATE CODE
                    if(cleanStateNameOrCode.length() <= 4){
                        for(String cleanAltStateCode : cleanStateAltCodesForCountry){
                            if(cleanStateNameOrCode.getLevenshteinDistance(cleanAltStateCode, 1) != -1){
                                String similarName = FullStatesNamesByCleanCountryNameAndCleanAltCode.get(cleanCountryNameOrCode).get(cleanAltStateCode);
                                if(!alreadyUsedFullNames.contains(similarName)){
                                    similarValues.add(similarName);
                                    alreadyUsedFullNames.add(similarName);
                                }
                            }
                        }
                    }

                    // GET SIMILAR STATES BY FULL ISO CODE
                    if(cleanStateNameOrCode.length() <= 5){
                        for(String cleanStateFullISOCode : cleanStateFullISOCodesForCountry){
                            if(cleanStateNameOrCode.getLevenshteinDistance(cleanStateFullISOCode, 1) != -1){
                                String similarName = FullStatesNamesByCleanCountryNameAndCleanStateFullISO.get(cleanCountryNameOrCode).get(cleanStateFullISOCode);
                                if(!alreadyUsedFullNames.contains(similarName)){
                                    similarValues.add(similarName);
                                    alreadyUsedFullNames.add(similarName);
                                }
                            }
                        }
                    }

                    // ADD 'No Possible Matches Found' TO LIST IF NO MATCHES ARE FOUND
                    if(similarValues.isEmpty()){
                        similarValues.add('No Possible Matches Found');
                    }
                    similarValues.sort();
                    return stringSetToSingleString(new Set<String>(similarValues), ' | ');
                }
            }

            return null;
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('StateAndCountryValidation', 'getStateFuzzyMatches', '', ex, true);
            return null;
        }
    }

    /**
    * @description validateRecordCountryStatePairs - Validates paired country and state fields for any sobject
    * @param SObject record - Sobject with country and state fields to validate
    * @param Map<String, String> countryStateAPINamePairs - Map containing Country field API name keys paired with State field API name values.
    * @return void
    */
    public static void validateRecordCountryStatePairs(SObject record, Map<String, String> countryStateAPINamePairs){
        Map<String, Schema.SObjectField> objectFieldMap = record.getSObjectType().getDescribe().fields.getMap();
        String invalidEntryMessage = '<br/>Invalid {0} name or code "{1}".<br/>Did you mean one of these:<br/>{2}<br/>';

        for(String countryFieldAPIName : countryStateAPINamePairs.keySet()){
            if(String.isNotBlank(countryFieldAPIName)){
                // COUNTRY DATA
                String countryFieldLabel = objectFieldMap.containsKey(countryFieldAPIName) ? objectFieldMap.get(countryFieldAPIName).getDescribe().getLabel() : null;
                String countryFieldValue = objectFieldMap.containsKey(countryFieldAPIName) ? (String)record.get(countryFieldAPIName) : null;

                // STATE DATA
                String stateFieldAPIName = countryStateAPINamePairs.get(countryFieldAPIName);
                String stateFieldLabel = objectFieldMap.containsKey(stateFieldAPIName) ? objectFieldMap.get(stateFieldAPIName).getDescribe().getLabel() : null;
                String stateFieldValue = objectFieldMap.containsKey(stateFieldAPIName) ? (String)record.get(stateFieldAPIName) : null;

                if((String.isNotBlank(countryFieldAPIName) && String.isBlank(countryFieldLabel)) || (String.isNotBlank(stateFieldAPIName) && String.isBlank(stateFieldLabel))){
                    SystemIssueLogHelper.LogException('StateAndCountryValidation', 'validateRecordCountryStatePairs', '', 'Invalid field API Name specified. Validation not performed.', true);
                }
                else{
                    // VALIDATE COUNTRY FIELD
                    if(String.isNotBlank(countryFieldValue)){
                        if(!StateAndCountryValidation.isValidCountry(countryFieldValue)){
                            String fuzzyMatches = StateAndCountryValidation.getCountryFuzzyMatches(countryFieldValue);
                            record.addError(String.format(invalidEntryMessage, new List<String>{countryFieldLabel, countryFieldValue, fuzzyMatches }), false);
                            return;
                        }
                        else{
                            // UPDATE RECORD
                            record.put(countryFieldAPIName, StateAndCountryValidation.getValidCountry(countryFieldValue));
                        }
                    }

                    // VALIDATE STATE FIELD
                    if(String.isNotBlank(stateFieldValue)){
                        if(String.isNotBlank(countryFieldValue) && !StateAndCountryValidation.isValidState(countryFieldValue, stateFieldValue)){
                            String fuzzyMatches = StateAndCountryValidation.getStateFuzzyMatches(countryFieldValue, stateFieldValue);
                            record.addError(String.format(invalidEntryMessage, new List<String>{stateFieldLabel, stateFieldValue, fuzzyMatches }), false);
                            return;
                        }
                        else if(String.isBlank(countryFieldValue)){
                            record.addError('You cannot specify a ' + stateFieldLabel + ' without a ' + countryFieldLabel, false);
                            return;
                        }
                        else{
                            // UPDATE RECORD
                            record.put(stateFieldAPIName, StateAndCountryValidation.getValidState(countryFieldValue, stateFieldValue));
                        }
                    }
                }
            }
        }   
    }

    /**
    * @description cleanString - Removes everything but letters from the supplied string
    * @param String - String to clean
    * @param Boolean - True/False that determines whether numbers are allowed in a cleaned string
    * @return String - Cleaned string
    */
    private static String cleanString(String stringToClean, Boolean allowNumbers){
        try{
            if(stringToClean != null && String.isNotBlank(stringToClean)){
                if(allowNumbers){
                    return stringToClean.replaceAll('[^A-Za-z0-9]', '').toLowerCase();
                }
                else{
                    return stringToClean.replaceAll('[^A-Za-z]', '').toLowerCase();
                }
            }
            else{
                return '';
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('StateAndCountryValidation', 'cleanString', '', ex, true);
            return null;
        }
    }

    /**
    * @description stringSetToSingleString - Converts a set of strings into a single string with each value separated by the specified delimiter
    * @param Set<String> stringSet - Set of Strings to turn into a single String
    * @param String delimiter - String value to use as a delimiter
    * @return String - Resulting single string
    */
    private static String stringSetToSingleString(Set<String> stringSet, String delimiter){
        try{
            String result = '';
            if(stringSet != null && !stringSet.isEmpty()){
                for(String value : stringSet){
                    result += value + delimiter;
                }
                result = result.left(result.length() - delimiter.length()); // REMOVE TRAILING DELIMITER
            }
            return result;
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('StateAndCountryValidation', 'stringSetToSingleString', '', ex, true);
            return null;
        }
    }


}