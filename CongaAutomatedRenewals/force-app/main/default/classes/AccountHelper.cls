/**
* @author ECS, ERedding
* @date 20180703
* @version 1.00
* @description AccountHelper - Contains custom functionality for the Account object including helper methods and trigger methods
*/
public with sharing class AccountHelper {

    // TERRITORY MANAGEMENT TEAM MEMBER ROLE NAME CONSTANTS
    public static final String TMROLENAME = TerritoryManagementHelper.TMROLENAME;
    public static final String CLMROLENAME = TerritoryManagementHelper.CLMROLENAME;      
    public static final String CSMROLENAME = TerritoryManagementHelper.CSMROLENAME;
    public static final String RMROLENAME = TerritoryManagementHelper.RMROLENAME;

    // PARENT D&B RECORDS
    public static Set<Id> ParentDNBRecordIds = new Set<Id>();
    public static Map<Id, DNBoptimizer__DnBCompanyRecord__c> ParentDNBRecords {
    get {
        if(ParentDNBRecords == null || ParentDNBRecords.isEmpty()){
            ParentDNBRecords = new Map<Id, DNBoptimizer__DnBCompanyRecord__c>([SELECT Id, DNBoptimizer__NAICSCode1__c, DNBoptimizer__SIC4Code1__c,  DNBoptimizer__PrimaryStreetAddress__c,
                                                                               DNBoptimizer__PrimaryStreetAddress2__c, DNBoptimizer__PrimaryCityName__c, DNBoptimizer__PrimaryPostalCode__c,
                                                                               DNBoptimizer__PrimaryStateProvinceName__c, DNBoptimizer__PrimaryStateProvinceAbbreviation_ISO__c,
                                                                               DNBoptimizer__PrimaryCountryCode__c, DNBoptimizer__PrimaryCountryCode_ISO__c
                                                                               FROM DNBoptimizer__DnBCompanyRecord__c
                                                                               WHERE Id IN :ParentDNBRecordIds]);
        }
        return ParentDNBRecords;
    } set; }


    // APTTUS INTEGRATION CUSTOM METADATA
    public static Set<String> ApttusIntegrationSyncedAccountFields {
    get {
        if(ApttusIntegrationSyncedAccountFields == null){
            ApttusIntegrationSyncedAccountFields = new Set<String>();
            for(Apttus_Integration_Synced_Fields__mdt syncedAccountField : [SELECT Synced_Field__r.QualifiedApiName FROM Apttus_Integration_Synced_Fields__mdt
                                                                            WHERE Synced_Object__r.QualifiedApiName = 'Account' AND Is_Active__c = true]){
                ApttusIntegrationSyncedAccountFields.add(syncedAccountField.Synced_Field__r.QualifiedApiName);
            }
        }
        return ApttusIntegrationSyncedAccountFields;
    } set; }



    /**
    * @author ECS, ERedding
    * @date 20191017
    * @description territoryManagerSync - TEMPORARY CODE TO KEEP THE TM_Territory_ManagerId__c FIELD IN SYNC WITH THE Territory_Manager__c FIELD UNTIL ITS DEPRECATED
    *                                        **** EXECUTED BY BEFORE INSERT AND BEFORE UPDATE TRIGGERS ****
    */
    public static void territoryManagerSync(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            /////////////////////////// TEMPORARY CODE TO SYNC TERRITORY MANAGER FIELDS UNTIL THE FIELDS ARE DEPRECATED ////////////////////////////
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            for(Account newOrUpdatedAccount : newOrUpdatedAccounts){
                Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAccount.Id) : null;
                if(newOrUpdatedAccount.Territory_Manager__c != null && (outdatedAccount == null || newOrUpdatedAccount.Territory_Manager__c != outdatedAccount.Territory_Manager__c)){
                    newOrUpdatedAccount.TM_Territory_ManagerId__c = newOrUpdatedAccount.Territory_Manager__c;
                }
                else if(newOrUpdatedAccount.TM_Territory_ManagerId__c != null && (outdatedAccount == null || newOrUpdatedAccount.TM_Territory_ManagerId__c != outdatedAccount.TM_Territory_ManagerId__c)){
                    newOrUpdatedAccount.Territory_Manager__c = newOrUpdatedAccount.TM_Territory_ManagerId__c;
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'territoryManagerSync', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @description updateTerritoryManagementFields - Updates Territory Management fields on new and updated Accounts
    *                                                 --- EXECUTED BY ACCOUNT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<Account> newOrUpdatedAccounts - New or Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void updateTerritoryManagementFields(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','updateTerritoryManagementFields') && newOrUpdatedAccounts != null){
                // GET IDS OF ACCOUNTS WITH QUALIFYING CHANGES
                List<Account> qualifiedAccounts = new List<Account>();
                for(Account newOrUpdatedAccount : newOrUpdatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAccount.Id) : null;
                    if(newOrUpdatedAccount.ShippingCountry != null){
                        if(outdatedAccount == null){
                            // NEW ACCOUNT
                            qualifiedAccounts.add(newOrUpdatedAccount);
                        }
                        else if(outdatedAccount != null && newOrUpdatedAccount.TM_SegmentId__c == null && newOrUpdatedAccount.TM_Segment_TerritoryId__c == null && 
                                newOrUpdatedAccount.TM_DivisionId__c == null && newOrUpdatedAccount.TM_Division_TerritoryId__c == null && 
                                (newOrUpdatedAccount.NumberOfEmployees != outdatedAccount.NumberOfEmployees ||
                                 newOrUpdatedAccount.AnnualRevenue != outdatedAccount.AnnualRevenue ||   
                                 newOrUpdatedAccount.Burdened_MRR__c != outdatedAccount.Burdened_MRR__c ||
                                 newOrUpdatedAccount.ShippingPostalCode != outdatedAccount.ShippingPostalCode ||
                                 newOrUpdatedAccount.ShippingState != outdatedAccount.ShippingState ||
                                 newOrUpdatedAccount.ShippingCountry != outdatedAccount.ShippingCountry)){
                            // MODIFIED ACCOUNT THAT DOES NOT HAVE ANY TM DATA ON IT YET
                            qualifiedAccounts.add(newOrUpdatedAccount);
                        }
                        else if(outdatedAccount != null && ((newOrUpdatedAccount.TM_SegmentId__c != null && newOrUpdatedAccount.TM_Segment_TerritoryId__c == null) || 
                                                            (newOrUpdatedAccount.TM_DivisionId__c != null && newOrUpdatedAccount.TM_Division_TerritoryId__c == null)) &&
                                  (newOrUpdatedAccount.ShippingCountry != outdatedAccount.ShippingCountry ||
                                    (newOrUpdatedAccount.ShippingState != null && newOrUpdatedAccount.ShippingState != outdatedAccount.ShippingState) ||
                                    (newOrUpdatedAccount.ShippingPostalCode != null && newOrUpdatedAccount.ShippingPostalCode != outdatedAccount.ShippingPostalCode))){
                            // SEGMENT IS POPULATED BUT SEGMENT TERRITORY IS NOT --OR-- DIVISION IS POPULATED BUT DIVISION TERRITORY IS NOT 
                            // -- AND --
                            // SHIPPING COUNTRY IS CHANGED -OR- SHIPPING STATE IS CHANGED AND NOT BLANK -OR- SHIPPING POSTAL CODE IS CHANGED AND NOT BLANK
                            qualifiedAccounts.add(newOrUpdatedAccount);
                        }
                        else if(outdatedAccount != null && 
                                (newOrUpdatedAccount.TM_SegmentId__c == null && ((newOrUpdatedAccount.NumberOfEmployees != null && newOrUpdatedAccount.NumberOfEmployees != outdatedAccount.NumberOfEmployees) ||
                                                                                 (newOrUpdatedAccount.AnnualRevenue != null && newOrUpdatedAccount.AnnualRevenue != outdatedAccount.AnnualRevenue))) ||
                                (newOrUpdatedAccount.TM_DivisionId__c == null && newOrUpdatedAccount.Burdened_MRR__c != null && newOrUpdatedAccount.Burdened_MRR__c != outdatedAccount.Burdened_MRR__c)){
                            // SEGMENT IS NULL AND NUMBER OF EMPLOYEES WAS CHANGED
                            // -OR-
                            // DIVISION IS NULL AND BURDENED MRR WAS CHANGED
                            qualifiedAccounts.add(newOrUpdatedAccount);
                        }
                        else if(outdatedAccount != null &&
                                ((newOrUpdatedAccount.TM_SegmentId__c != null && newOrUpdatedAccount.TM_SegmentId__c != outdatedAccount.TM_SegmentId__c) ||
                                 (newOrUpdatedAccount.TM_DivisionId__c != null && newOrUpdatedAccount.TM_DivisionId__c != outdatedAccount.TM_DivisionId__c))){
                            // SEGMENT WAS MODIFIED DIRECTLY -OR- DIVISION WAS MODIFIED DIRECTLY
                            qualifiedAccounts.add(newOrUpdatedAccount);
                        }
                    }
                    else{
                        if(newOrUpdatedAccount.TM_Segment_TerritoryId__c != null && (outdatedAccount == null || outdatedAccount.TM_Segment_TerritoryId__c == null)){
                            // SEGMENT TERRITORY WAS POPULATED DIRECTLY
                            qualifiedAccounts.add(newOrUpdatedAccount);
                        }
                    }
                }

                if(!qualifiedAccounts.isEmpty()){

                    // GET COUNTRIES AND STATES FROM QUALIFIED ACCOUNTS
                    Set<String> acctCountries = new Set<String>();
                    Set<String> acctStates = new Set<String>();
                    for(Account acct : qualifiedAccounts){
                        if(String.isNotBlank(acct.ShippingCountry)){
                            acctCountries.add(acct.ShippingCountry);
                        }
                        if(String.isNotBlank(acct.ShippingState)){
                            acctStates.add(acct.ShippingState);
                        }
                    }

                    // GET GEOS BY COUNTRY
                    Map<String, String> geosByCountryName = new Map<String, String>();
                    for(Country_Territory__c country : [SELECT Name, Geo__c FROM Country_Territory__c WHERE Name IN :acctCountries]){
                        geosByCountryName.put(country.Name, country.Geo__c.toLowerCase());
                    }

                    if(!geosByCountryName.isEmpty()){
                        Map<Id, TM_Territory__c> territoriesById = new Map<Id, TM_Territory__c>();
                        for(TM_Territory__c territory : [SELECT Id, Name, TM_RegionId__c, TM_RegionId__r.TM_GeoId__c FROM TM_Territory__c
                                                         WHERE Is_Active_for_Segments__c = true OR Is_Active_for_Divisions__c = true]){
                            territoriesById.put(territory.Id, territory);
                        }

                        // GET SEGMENTS AND RELATED DATA
                        Set<Id> segmentIds = new Set<Id>();
                        Map<String, List<TM_Segment__c>> segmentsByGeoName = new Map<String, List<TM_Segment__c>>();
                        for(TM_Segment__c segment : [SELECT Id, Name, TM_GeoId__r.Name, Minimum_Employees__c, Maximum_Employees__c, Minimum_Annual_Revenue__c, Maximum_Annual_Revenue__c 
                                                     FROM TM_Segment__c WHERE TM_GeoId__r.Name IN :geosByCountryName.values() AND Is_Active__c = true]){
                            String geoName = segment.TM_GeoId__r.Name.toLowerCase();
                            // ADD SEGMENT ID TO SET
                            segmentIds.add(segment.Id);

                            // POPULATE SEGMENTS BY GEO NAME MAP
                            if(!segmentsByGeoName.containsKey(geoName)){
                                segmentsByGeoName.put(geoName, new List<TM_Segment__c>());
                            }
                            segmentsByGeoName.get(geoName).add(segment);
                        }

                        // GET DIVISIONS AND RELATED DATA
                        Set<Id> divisionIds = new Set<Id>();
                        Map<String, List<TM_Division__c>> divisionsByGeoName = new Map<String, List<TM_Division__c>>();
                        for(TM_Division__c division : [SELECT Id, Name, TM_GeoId__r.Name, Minimum_MRR__c, Maximum_MRR__c FROM TM_Division__c
                                                       WHERE TM_GeoId__r.Name IN :geosByCountryName.values() AND Is_Active__c = true]){
                            String geoName = division.TM_GeoId__r.Name.toLowerCase();
                            // ADD DIVISION ID TO SET
                            divisionIds.add(division.Id);

                            // POPULATE DIVISIONS BY GEO NAME MAP
                            if(!divisionsByGeoName.containsKey(geoName)){
                                divisionsByGeoName.put(geoName, new List<TM_Division__c>());
                            }
                            divisionsByGeoName.get(geoName).add(division);
                        }

                        // GET TERRITORY STATE AND COUNTRY DATA
                        Map<Id, Map<String, TM_Territory_Segment__c>> terrSegBySegmentAndCountry = new Map<Id, Map<String, TM_Territory_Segment__c>>();
                        Map<Id, Map<String, List<TM_Territory_Segment_State__c>>> terrSegStatesBySegmentAndState = new Map<Id, Map<String, List<TM_Territory_Segment_State__c>>>();                    
                        Map<Id, Map<String, TM_Territory_Division__c>> terrDivByDivisionAndCountry = new Map<Id, Map<String, TM_Territory_Division__c>>();
                        Map<Id, Map<String, List<TM_Territory_Division_State__c>>> terrDivStatesByDivisionAndState = new Map<Id, Map<String, List<TM_Territory_Division_State__c>>>();
                        ////////// SEGMENT COUNTRIES
                        for(TM_Territory_Segment_Country__c terrSegCountry : [SELECT Id, Country_TerritoryId__r.Name, TM_Territory_SegmentId__c,
                                                                                     TM_Territory_SegmentId__r.TM_SegmentId__c, TM_Territory_SegmentId__r.TM_TerritoryId__c,
                                                                                     TM_Territory_SegmentId__r.TM_TerritoryId__r.TM_RegionId__c, 
                                                                                     TM_Territory_SegmentId__r.TM_TerritoryId__r.TM_RegionId__r.TM_GeoId__c
                                                                              FROM TM_Territory_Segment_Country__c WHERE Country_TerritoryId__r.Name IN :acctCountries
                                                                                                                   AND TM_Territory_SegmentId__r.TM_SegmentId__c IN :segmentIds]){
                            if(!terrSegBySegmentAndCountry.containsKey(terrSegCountry.TM_Territory_SegmentId__r.TM_SegmentId__c)){
                                terrSegBySegmentAndCountry.put(terrSegCountry.TM_Territory_SegmentId__r.TM_SegmentId__c, new Map<String, TM_Territory_Segment__c>());
                            }
                            terrSegBySegmentAndCountry.get(terrSegCountry.TM_Territory_SegmentId__r.TM_SegmentId__c).put(terrSegCountry.Country_TerritoryId__r.Name, terrSegCountry.TM_Territory_SegmentId__r);
                        }
                        ////////// SEGMENT STATES
                        for(TM_Territory_Segment_State__c terrSegState : [SELECT Id, State_ProvinceId__r.Name, Applicable_Postal_Codes__c, TM_Territory_SegmentId__c,
                                                                                 TM_Territory_SegmentId__r.TM_SegmentId__c, TM_Territory_SegmentId__r.TM_TerritoryId__c,
                                                                                 TM_Territory_SegmentId__r.TM_TerritoryId__r.TM_RegionId__c, 
                                                                                 TM_Territory_SegmentId__r.TM_TerritoryId__r.TM_RegionId__r.TM_GeoId__c
                                                                           FROM TM_Territory_Segment_State__c WHERE State_ProvinceId__r.Name IN :acctStates
                                                                                                              AND TM_Territory_SegmentId__r.TM_SegmentId__c IN :segmentIds]){
                            if(!terrSegStatesBySegmentAndState.containsKey(terrSegState.TM_Territory_SegmentId__r.TM_SegmentId__c)){
                                // ADD SEGMENT AND STATE
                                terrSegStatesBySegmentAndState.put(terrSegState.TM_Territory_SegmentId__r.TM_SegmentId__c, new Map<String, List<TM_Territory_Segment_State__c>>());
                                terrSegStatesBySegmentAndState.get(terrSegState.TM_Territory_SegmentId__r.TM_SegmentId__c).put(terrSegState.State_ProvinceId__r.Name, new List<TM_Territory_Segment_State__c>());
                            }
                            else if(!terrSegStatesBySegmentAndState.get(terrSegState.TM_Territory_SegmentId__r.TM_SegmentId__c).containsKey(terrSegState.State_ProvinceId__r.Name)){
                                // SEGMENT ALREADY ADDED, ADD ONLY STATE
                                terrSegStatesBySegmentAndState.get(terrSegState.TM_Territory_SegmentId__r.TM_SegmentId__c).put(terrSegState.State_ProvinceId__r.Name, new List<TM_Territory_Segment_State__c>());                                                                 
                            }
                            terrSegStatesBySegmentAndState.get(terrSegState.TM_Territory_SegmentId__r.TM_SegmentId__c).get(terrSegState.State_ProvinceId__r.Name).add(terrSegState);
                        }


                        ////////// DIVISION COUNTRIES
                        for(TM_Territory_Division_Country__c terrDivCountry : [SELECT Id, Country_TerritoryId__r.Name, TM_Territory_DivisionId__c,
                                                                                      TM_Territory_DivisionId__r.TM_DivisionId__c, TM_Territory_DivisionId__r.TM_TerritoryId__c
                                                                               FROM TM_Territory_Division_Country__c WHERE Country_TerritoryId__r.Name IN :acctCountries
                                                                                                                     AND TM_Territory_DivisionId__r.TM_DivisionId__c IN :divisionIds]){
                            if(!terrDivByDivisionAndCountry.containsKey(terrDivCountry.TM_Territory_DivisionId__r.TM_DivisionId__c)){
                                terrDivByDivisionAndCountry.put(terrDivCountry.TM_Territory_DivisionId__r.TM_DivisionId__c, new Map<String, TM_Territory_Division__c>());
                            }
                            terrDivByDivisionAndCountry.get(terrDivCountry.TM_Territory_DivisionId__r.TM_DivisionId__c).put(terrDivCountry.Country_TerritoryId__r.Name, terrDivCountry.TM_Territory_DivisionId__r);
                        }
                        ////////// DIVISION STATES
                        for(TM_Territory_Division_State__c terrDivState : [SELECT Id, State_ProvinceId__r.Name, Applicable_Postal_Codes__c, TM_Territory_DivisionId__c,
                                                                                  TM_Territory_DivisionId__r.TM_DivisionId__c, TM_Territory_DivisionId__r.TM_TerritoryId__c
                                                                           FROM TM_Territory_Division_State__c WHERE State_ProvinceId__r.Name IN :acctStates
                                                                                                               AND TM_Territory_DivisionId__r.TM_DivisionId__c IN :divisionIds]){
                            if(!terrDivStatesByDivisionAndState.containsKey(terrDivState.TM_Territory_DivisionId__r.TM_DivisionId__c)){
                                // ADD DIVISION AND STATE
                                terrDivStatesByDivisionAndState.put(terrDivState.TM_Territory_DivisionId__r.TM_DivisionId__c, new Map<String, List<TM_Territory_Division_State__c>>());
                                terrDivStatesByDivisionAndState.get(terrDivState.TM_Territory_DivisionId__r.TM_DivisionId__c).put(terrDivState.State_ProvinceId__r.Name, new List<TM_Territory_Division_State__c>());
                            }
                            else if(!terrDivStatesByDivisionAndState.get(terrDivState.TM_Territory_DivisionId__r.TM_DivisionId__c).containsKey(terrDivState.State_ProvinceId__r.Name)){
                                // DIVISION ALREADY ADDED, ADD ONLY STATE
                                terrDivStatesByDivisionAndState.get(terrDivState.TM_Territory_DivisionId__r.TM_DivisionId__c).put(terrDivState.State_ProvinceId__r.Name, new List<TM_Territory_Division_State__c>());                                                                 
                            }
                            terrDivStatesByDivisionAndState.get(terrDivState.TM_Territory_DivisionId__r.TM_DivisionId__c).get(terrDivState.State_ProvinceId__r.Name).add(terrDivState);
                        }

                        // PROCESS QUALIFIED ACCOUNTS
                        for(Account qualifiedAcct : qualifiedAccounts){
                            Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(qualifiedAcct.Id) : null;
                            String acctGeo = geosByCountryName != null ? geosByCountryName.get(qualifiedAcct.ShippingCountry) : null;
                            List<TM_Segment__c> segmentsForGeo = segmentsByGeoName.containsKey(acctGeo) ? segmentsByGeoName.get(acctGeo) : new List<TM_Segment__c>();
                            List<TM_Division__c> divisionsForGeo = divisionsByGeoName.containsKey(acctGeo) ? divisionsByGeoName.get(acctGeo) : new List<TM_Division__c>();

                            // FIND MATCHING SEGMENT USING ANNUAL REVENUE OR EMPLOYEE COUNT IF ACCOUNT DOES NOT ALREADY HAVE ONE
                            if(qualifiedAcct.TM_SegmentId__c == null){
                                for(TM_Segment__c segment : segmentsForGeo){

                                    // FIND MATCH USING EMPLOYEE COUNT IF AVAILABLE
                                    if(qualifiedAcct.NumberOfEmployees != null && segment.Minimum_Employees__c != null && segment.Maximum_Employees__c != null){
                                    if(qualifiedAcct.NumberOfEmployees >= segment.Minimum_Employees__c && qualifiedAcct.NumberOfEmployees <= segment.Maximum_Employees__c){
                                            // SEGMENT MATCHES EMPLOYEE COUNT, USE SEGMENT BUT CONTINUE LOOP IN CASE THERE IS A BETTER MATCH USING ANNUAL REVENUE
                                            qualifiedAcct.TM_SegmentId__c = segment.Id;
                                        }
                                    }

                                    // FIND MATCH USING ANNUAL REVENUE IF AVAILABLE
                                    if(qualifiedAcct.AnnualRevenue != null && segment.Minimum_Annual_Revenue__c != null && segment.Maximum_Annual_Revenue__c != null){
                                        if(qualifiedAcct.AnnualRevenue >= segment.Minimum_Annual_Revenue__c && qualifiedAcct.AnnualRevenue <= segment.Maximum_Annual_Revenue__c){
                                            // SEGMENT MATCHES ANNUAL REVENUE WHICH HAS PRECEDENCE, USE SEGMENT AND STOP LOOP
                                        qualifiedAcct.TM_SegmentId__c = segment.Id;
                                        break;
                                    }  
                                }
                            }
                            }

                            // FIND MATCHING DIVSION USING BURDENED MRR IF ACCOUNT DOES NOT ALREADY HAVE ONE
                            if(qualifiedAcct.TM_DivisionId__c == null && qualifiedAcct.Burdened_MRR__c != null){
                                for(TM_Division__c division : divisionsForGeo){
                                    if(qualifiedAcct.Burdened_MRR__c >= division.Minimum_MRR__c && qualifiedAcct.Burdened_MRR__c <= division.Maximum_MRR__c){
                                        qualifiedAcct.TM_DivisionId__c = division.Id;
                                        break;
                                    }
                                }
                            }

                            // FIND MATCHING SEGMENT TERRITORY USING STATES AND COUNTRIES IF THE ACCOUNT DOES NOT ALREADY HAVE ONE
                            if(qualifiedAcct.TM_Segment_TerritoryId__c == null && qualifiedAcct.TM_SegmentId__c != null){
                                Map<String, TM_Territory_Segment__c> terrSegmentsByCountry = terrSegBySegmentAndCountry.containsKey(qualifiedAcct.TM_SegmentId__c) ? 
                                                                                             terrSegBySegmentAndCountry.get(qualifiedAcct.TM_SegmentId__c) : 
                                                                                             new Map<String, TM_Territory_Segment__c>();

                                Map<String, List<TM_Territory_Segment_State__c>> terrSegmentsByState = terrSegStatesBySegmentAndState.containsKey(qualifiedAcct.TM_SegmentId__c) ? 
                                                                                                       terrSegStatesBySegmentAndState.get(qualifiedAcct.TM_SegmentId__c) : 
                                                                                                       new Map<String, List<TM_Territory_Segment_State__c>>();

                                if(terrSegmentsByState.containsKey(qualifiedAcct.ShippingState) && terrSegmentsByState.get(qualifiedAcct.ShippingState).size() == 1){
                                    // ONE TERRITORY FOUND USING STATE
                                    qualifiedAcct.TM_Segment_TerritoryId__c = terrSegmentsByState.get(qualifiedAcct.ShippingState)[0].TM_Territory_SegmentId__r.TM_TerritoryId__c;
                                }
                                else if(terrSegmentsByState.containsKey(qualifiedAcct.ShippingState) && terrSegmentsByState.get(qualifiedAcct.ShippingState).size() > 1){
                                    // MULTIPLE TERRITORIES FOUND USING STATE, NARROW DOWN USING POSTAL CODE
                                    if(String.isNotBlank(qualifiedAcct.ShippingPostalCode)){
                                        for(TM_Territory_Segment_State__c terrSegmentState : terrSegmentsByState.get(qualifiedAcct.ShippingState)){
                                            if(String.isNotBlank(terrSegmentState.Applicable_Postal_Codes__c) &&
                                               terrSegmentState.Applicable_Postal_Codes__c.contains(qualifiedAcct.ShippingPostalCode.left(5))){  // USE FIRST 5 OF U.S. POSTAL CODE
                                                
                                                qualifiedAcct.TM_Segment_TerritoryId__c = terrSegmentState.TM_Territory_SegmentId__r.TM_TerritoryId__c;
                                                break;
                                            }
                                        }

                                        // USE THE FIRST TERRITORY IF NONE OF FOUND TERRITORIES HAD ZIP CODE DATA
                                        if(qualifiedAcct.TM_Segment_TerritoryId__c == null){
                                            qualifiedAcct.TM_Segment_TerritoryId__c = terrSegmentsByState.get(qualifiedAcct.ShippingState)[0].TM_Territory_SegmentId__r.TM_TerritoryId__c;
                                        }
                                    }
                                }
                                else if(terrSegmentsByCountry.containsKey(qualifiedAcct.ShippingCountry)){
                                    // ONE TERRITORY FOUND USING COUNTRY
                                    qualifiedAcct.TM_Segment_TerritoryId__c = terrSegmentsByCountry.get(qualifiedAcct.ShippingCountry).TM_TerritoryId__c;
                                }
                            }

                            // FIND MATCHING DIVISION TERRITORY USING STATES AND COUNTRIES IF THE ACCOUNT DOES NOT ALREADY HAVE ONE
                            if(qualifiedAcct.TM_Division_TerritoryId__c == null && qualifiedAcct.TM_DivisionId__c != null){
                                Map<String, TM_Territory_Division__c> terrDivisionsByCountry = terrDivByDivisionAndCountry.containsKey(qualifiedAcct.TM_DivisionId__c) ? 
                                                                                               terrDivByDivisionAndCountry.get(qualifiedAcct.TM_DivisionId__c) : 
                                                                                               new Map<String, TM_Territory_Division__c>();
                                Map<String, List<TM_Territory_Division_State__c>> terrDivisionsByState = terrDivStatesByDivisionAndState.containsKey(qualifiedAcct.TM_DivisionId__c) ? 
                                                                                                         terrDivStatesByDivisionAndState.get(qualifiedAcct.TM_DivisionId__c) : 
                                                                                                         new Map<String, List<TM_Territory_Division_State__c>>();

                                if(terrDivisionsByState.containsKey(qualifiedAcct.ShippingState) && terrDivisionsByState.get(qualifiedAcct.ShippingState).size() == 1){
                                    // ONE TERRITORY DIVISION FOUND USING STATE
                                    qualifiedAcct.TM_Division_TerritoryId__c = terrDivisionsByState.get(qualifiedAcct.ShippingState)[0].TM_Territory_DivisionId__r.TM_TerritoryId__c;
                                }
                                else if(terrDivisionsByState.containsKey(qualifiedAcct.ShippingState) && terrDivisionsByState.get(qualifiedAcct.ShippingState).size() > 1){
                                    // MULTIPLE TERRITORY DIVISIONS FOUND USING STATE, NARROW DOWN USING POSTAL CODE
                                    if(String.isNotBlank(qualifiedAcct.ShippingPostalCode)){
                                        for(TM_Territory_Division_State__c terrDivisionState : terrDivisionsByState.get(qualifiedAcct.ShippingState)){
                                            if(terrDivisionState.Applicable_Postal_Codes__c.contains(qualifiedAcct.ShippingPostalCode.left(5))){ // USE FIRST 5 OF U.S. POSTAL CODE
                                                qualifiedAcct.TM_Division_TerritoryId__c = terrDivisionState.TM_Territory_DivisionId__r.TM_TerritoryId__c;
                                                break;
                                            }
                                        }
                                    }
                                }
                                else if(terrDivisionsByCountry.containsKey(qualifiedAcct.ShippingCountry)){
                                    // ONE TERRITORY FOUND USING COUNTRY
                                    qualifiedAcct.TM_Division_TerritoryId__c = terrDivisionsByCountry.get(qualifiedAcct.ShippingCountry).TM_TerritoryId__c;
                                }
                            }

                            // UPDATE ACCOUNT GEO AND REGION FROM SEGMENT TERRITORY IF IT WAS UPDATED
                            if(qualifiedAcct.TM_Segment_TerritoryId__c != null && territoriesById.containsKey(qualifiedAcct.TM_Segment_TerritoryId__c)){
                                qualifiedAcct.TM_GeoId__c = territoriesById.get(qualifiedAcct.TM_Segment_TerritoryId__c).TM_RegionId__r.TM_GeoId__c;
                                qualifiedAcct.TM_RegionId__c = territoriesById.get(qualifiedAcct.TM_Segment_TerritoryId__c).TM_RegionId__c;
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'updateTerritoryManagementFields');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'updateTerritoryManagementFields', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @description processSegmentAndDivisionChanges - Updates account team members when Territory Segment and/or Territory Division are changed
    *                                                   --- EXECUTED BY ACCOUNT AFTER INSERT AND AFTER UPDATE TRIGGERS ---       
    * @param List<Account> newOrUpdatedAccounts - New or Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void processSegmentAndDivisionChanges(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','processSegmentAndDivisionChanges') && newOrUpdatedAccounts != null){
                // GET ACCCOUNTS WITH QUALIFYING CHANGES
                List<Account> qualifiedAccounts = new List<Account>();
                Set<Id> segmentIds = new Set<Id>();
                Set<Id> divsionIds = new Set<Id>();
                Set<Id> segmentTerritoryIds = new Set<Id>();
                Set<Id> divsionTerritoryIds = new Set<Id>();
                for(Account newOrUpdatedAccount : newOrUpdatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAccount.Id) : null;
                    if((newOrUpdatedAccount.TM_Segment_TerritoryId__c != null && newOrUpdatedAccount.TM_SegmentId__c != null && 
                         (outdatedAccount == null || newOrUpdatedAccount.TM_Segment_TerritoryId__c != outdatedAccount.TM_Segment_TerritoryId__c || 
                                                     newOrUpdatedAccount.TM_SegmentId__c != outdatedAccount.TM_SegmentId__c)) ||
                       (newOrUpdatedAccount.TM_Division_TerritoryId__c != null && newOrUpdatedAccount.TM_DivisionId__c != null && 
                         (outdatedAccount == null || newOrUpdatedAccount.TM_Division_TerritoryId__c != outdatedAccount.TM_Division_TerritoryId__c|| 
                                                     newOrUpdatedAccount.TM_DivisionId__c != outdatedAccount.TM_DivisionId__c))){
                        qualifiedAccounts.add(newOrUpdatedAccount);
                        segmentIds.add(newOrUpdatedAccount.TM_SegmentId__c);
                        divsionIds.add(newOrUpdatedAccount.TM_DivisionId__c);
                        segmentTerritoryIds.add(newOrUpdatedAccount.TM_Segment_TerritoryId__c);
                        divsionTerritoryIds.add(newOrUpdatedAccount.TM_Division_TerritoryId__c);
                    }
                }

                // REMOVE NULLS FROM SETS
                segmentIds.remove(null);
                divsionIds.remove(null);
                segmentTerritoryIds.remove(null);
                divsionTerritoryIds.remove(null);

                if(!qualifiedAccounts.isEmpty()){

                    // GET TERRITORY SEGMENT DATA
                    Map<Id, Map<Id, TM_Territory_Segment__c>> terrSegBySegAndTerr = new Map<Id, Map<Id, TM_Territory_Segment__c>>();
                    Map<Id, Map<Id, TM_Territory_Segment_Users__c>> noMatchSegmentUsersBySegAndTerr = new Map<Id, Map<Id, TM_Territory_Segment_Users__c>>();
                    if(!segmentTerritoryIds.isEmpty() && !segmentIds.isEmpty()){
                        for(TM_Territory_Segment__c terrSegment : [SELECT Id, TM_TerritoryId__c, TM_SegmentId__c,
                                                                   (SELECT Applicable_Industries__c, Assigned_TM_UserId__c, Assigned_CLM_UserId__c FROM TerritorySegmentUsers__r)
                                                                   FROM TM_Territory_Segment__c WHERE TM_TerritoryId__c IN :segmentTerritoryIds AND TM_SegmentId__c IN :segmentIds]){
                            if(!terrSegBySegAndTerr.containsKey(terrSegment.TM_SegmentId__c)){
                                terrSegBySegAndTerr.put(terrSegment.TM_SegmentId__c, new Map<Id, TM_Territory_Segment__c>());
                            }
                            terrSegBySegAndTerr.get(terrSegment.TM_SegmentId__c).put(terrSegment.TM_TerritoryId__c, terrSegment);

                            // FIND TERRITORY SEGMENT USERS RECORD THAT HAS THE -- BLANK INDUSTRY -- PICKLIST VALUE
                            for(TM_Territory_Segment_Users__c terrSegmentUsers : terrSegment.TerritorySegmentUsers__r){
                                if(terrSegmentUsers.Applicable_Industries__c.contains('None')){
                                    noMatchSegmentUsersBySegAndTerr.put(terrSegment.Id, new Map<Id, TM_Territory_Segment_Users__c>());
                                    noMatchSegmentUsersBySegAndTerr.get(terrSegment.Id).put(terrSegment.TM_TerritoryId__c, terrSegmentUsers);
                                    break;
                                }
                            }
                        }
                    }

                    // GET TERRITORY DIVISION DATA
                    Map<Id, Map<Id, TM_Territory_Division__c>> terrDivByDivAndTerr = new Map<Id, Map<Id, TM_Territory_Division__c>>();
                    if(!divsionTerritoryIds.isEmpty() && !divsionIds.isEmpty()){
                        for(TM_Territory_Division__c terrDivision : [SELECT Id, TM_TerritoryId__c, TM_DivisionId__c,
                                                                     (SELECT Assigned_CSM_UserId__c, Assigned_RM_UserId__c FROM TerritoryDivisionUsers__r)
                                                                     FROM TM_Territory_Division__c WHERE TM_TerritoryId__c IN :divsionTerritoryIds AND TM_DivisionId__c IN :divsionIds]){
                            if(!terrDivByDivAndTerr.containsKey(terrDivision.TM_DivisionId__c)){
                                terrDivByDivAndTerr.put(terrDivision.TM_DivisionId__c, new Map<Id, TM_Territory_Division__c>());
                            }
                            terrDivByDivAndTerr.get(terrDivision.TM_DivisionId__c).put(terrDivision.TM_TerritoryId__c, terrDivision);
                        }
                    }

                    // ORGANIZE DATA AND GET ACCOUNT IDS FROM QUALIFYING RECORDS
                    Map<Id, List<AccountTeamMember>> teamMembersByAccount = new Map<Id, List<AccountTeamMember>>();
                    for(AccountTeamMember accountMember : [SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :qualifiedAccounts]){
                        if(!teamMembersByAccount.containsKey(accountMember.AccountId)){
                            teamMembersByAccount.put(accountMember.AccountId, new List<AccountTeamMember>());
                        }
                        teamMembersByAccount.get(accountMember.AccountId).add(accountMember);
                    }

                    for(Account acct : qualifiedAccounts){
                        Account outdatedAcct = outdatedAccounts != null ? outdatedAccounts.get(acct.Id) : null;
                        String accountIndustry = (String.isBlank(acct.Industry) ? 'None' : acct.Industry);

                        // GET TERRITORY SEGMENT RECORD MATCHING THE ACCOUNT'S SEGMENT AND TERRITORY
                        TM_Territory_Segment_Users__c matchingTerrSegmentUsers;
                        if(terrSegBySegAndTerr.containsKey(acct.TM_SegmentId__c) && terrSegBySegAndTerr.get(acct.TM_SegmentId__c).containsKey(acct.TM_Segment_TerritoryId__c)){
                            for(TM_Territory_Segment_Users__c terrSegmentUsers :  terrSegBySegAndTerr.get(acct.TM_SegmentId__c).get(acct.TM_Segment_TerritoryId__c).TerritorySegmentUsers__r){
                                if(terrSegmentUsers.Applicable_Industries__c.contains(accountIndustry)){
                                    matchingTerrSegmentUsers = terrSegmentUsers;
                                    break;
                                }
                            }

                            // GET NO MATCH USERS IF NO INDUSTRY MATCH COULD BE MADE
                            if(matchingTerrSegmentUsers == null && noMatchSegmentUsersBySegAndTerr.containsKey(acct.TM_SegmentId__c) && 
                                                                   noMatchSegmentUsersBySegAndTerr.get(acct.TM_SegmentId__c).containsKey(acct.TM_Segment_TerritoryId__c)){
                                matchingTerrSegmentUsers = noMatchSegmentUsersBySegAndTerr.get(acct.TM_SegmentId__c).get(acct.TM_Segment_TerritoryId__c);
                            }
                        }

                        // GET THE TERRITORY SEGMENT USERS RECORD THAT MATCHES TO THE ACCOUNT. CURRENTLY NO ADDITIONAL CRITERIA FOR DIVISIONS SO JUST USE THE FIRST ONE
                        TM_Territory_Division_Users__c matchingTerrDivisionUsers;
                        if(terrDivByDivAndTerr.containsKey(acct.TM_DivisionId__c) && terrDivByDivAndTerr.get(acct.TM_DivisionId__c).containsKey(acct.TM_Division_TerritoryId__c)){
                            for(TM_Territory_Division_Users__c terrDivisionUsers : terrDivByDivAndTerr.get(acct.TM_DivisionId__c).get(acct.TM_Division_TerritoryId__c).TerritoryDivisionUsers__r){
                                matchingTerrDivisionUsers = terrDivisionUsers;
                                break;
                            }
                        }

                        // GET USERS FROM ACCOUNT MEMBERS
                        AccountTeamMember acctTMMember;
                        AccountTeamMember acctCLMMember;
                        AccountTeamMember acctCSMMember;
                        AccountTeamMember acctRMMember;
                        if(teamMembersByAccount.containsKey(acct.Id)){
                            for(AccountTeamMember member : teamMembersByAccount.get(acct.Id)){
                                if(member.TeamMemberRole == TMROLENAME && acctTMMember == null){
                                    acctTMMember = member;
                                }
                                if(member.TeamMemberRole == CLMROLENAME && acctCLMMember == null){
                                    acctCLMMember = member;
                                }
                                if(member.TeamMemberRole == CSMROLENAME && acctCSMMember == null){
                                    acctCSMMember = member;
                                }
                                if(member.TeamMemberRole == RMROLENAME && acctRMMember == null){
                                    acctRMMember = member;
                                }
                            }
                        }

                        // GET ACCOUNT CUSTOMER TYPES
                        Set<String> acctCustomerTypes = new Set<String>{ TerritoryManagementHelper.CUSTOMERTYPE, TerritoryManagementHelper.CUSTOMERPASTDUETYPE };

                        List<AccountTeamMember> accountMembersToCreate = new List<AccountTeamMember>();
                        List<AccountTeamMember> accountMembersToDelete = new List<AccountTeamMember>();
                        //////////////////////////////////////////////////////////////
                        ///////////////////// TM AND CLM UPDATES /////////////////////
                        //////////////////////////////////////////////////////////////
                        if(acct.TM_Segment_TerritoryId__c != null && acct.TM_SegmentId__c != null && matchingTerrSegmentUsers != null &&
                            (outdatedAcct == null || acct.TM_Segment_TerritoryId__c != outdatedAcct.TM_Segment_TerritoryId__c || acct.TM_SegmentId__c != outdatedAcct.TM_SegmentId__c)){
                            
                            //// TM MEMBER
                            if(!acct.TM_Manager_Hold__c && matchingTerrSegmentUsers.Assigned_TM_UserId__c != null && (acctTMMember == null || acctTMMember.UserId != matchingTerrSegmentUsers.Assigned_TM_UserId__c)){
                                accountMembersToCreate.add(new AccountTeamMember(AccountId = acct.Id, UserId = matchingTerrSegmentUsers.Assigned_TM_UserId__c, TeamMemberRole = TMROLENAME));
                                if(acctTMMember != null){
                                    accountMembersToDelete.add(acctTMMember); // DELETE OLD MEMBER, NO LONGER VALID
                                }
                            }

                            //// CLM MEMBER
                            if(matchingTerrSegmentUsers.Assigned_CLM_UserId__c != null && (acctCLMMember == null || acctCLMMember.UserId != matchingTerrSegmentUsers.Assigned_CLM_UserId__c)){
                                accountMembersToCreate.add(new AccountTeamMember(AccountId = acct.Id, UserId = matchingTerrSegmentUsers.Assigned_CLM_UserId__c, TeamMemberRole = CLMROLENAME));
                                if(acctCLMMember != null){
                                    accountMembersToDelete.add(acctCLMMember); // DELETE OLD MEMBER, NO LONGER VALID
                                }
                            }
                        }

                        //////////////////////////////////////////////////////////////                              
                        ///////////////////// CSM AND RM UPDATES /////////////////////
                        //////////////////////////////////////////////////////////////  
                        if(acct.TM_Division_TerritoryId__c != null && acct.TM_DivisionId__c != null && matchingTerrDivisionUsers != null && acctCustomerTypes.contains(acct.Type) &&
                            (outdatedAcct == null || acct.TM_Division_TerritoryId__c != outdatedAcct.TM_Division_TerritoryId__c || acct.TM_DivisionId__c != outdatedAcct.TM_DivisionId__c)){
                            
                            //// CSM MEMBER
                            if(!acct.CSM_Manager_Hold__c && matchingTerrDivisionUsers.Assigned_CSM_UserId__c != null && (acctCSMMember == null || acctCSMMember.UserId != matchingTerrDivisionUsers.Assigned_CSM_UserId__c)){
                                accountMembersToCreate.add(new AccountTeamMember(AccountId = acct.Id, UserId = matchingTerrDivisionUsers.Assigned_CSM_UserId__c, TeamMemberRole = CSMROLENAME));
                                if(acctCSMMember != null){
                                    accountMembersToDelete.add(acctCSMMember); // DELETE OLD MEMBER, NO LONGER VALID
                                }
                            }

                            //// RM MEMBER
                            if(!acct.RM_Manager_Hold__c && matchingTerrDivisionUsers.Assigned_RM_UserId__c != null && (acctRMMember == null || acctRMMember.UserId != matchingTerrDivisionUsers.Assigned_RM_UserId__c)){
                                accountMembersToCreate.add(new AccountTeamMember(AccountId = acct.Id, UserId = matchingTerrDivisionUsers.Assigned_RM_UserId__c, TeamMemberRole = RMROLENAME));
                                if(acctRMMember != null){
                                    accountMembersToDelete.add(acctRMMember); // DELETE OLD MEMBER, NO LONGER VALID
                                }
                            }
                        }

                        // DELETE INVALID ACCOUNT TEAM MEMBERS
                        if(!accountMembersToDelete.isEmpty()){
                            Database.DeleteResult[] accountTMDeleteResults = Database.delete(accountMembersToDelete, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(accountTMDeleteResults, 'AccountHelper', 'processSegmentAndDivisionChanges', false);
                        }

                        // CREATE ACCOUNT TEAM MEMBERS
                        if(!accountMembersToCreate.isEmpty()){
                            Database.SaveResult[] accountTMCreateResults = Database.insert(accountMembersToCreate, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(accountTMCreateResults, 'AccountHelper', 'processSegmentAndDivisionChanges', false);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'processSegmentAndDivisionChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'processSegmentAndDivisionChanges', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20191017
    * @description updateAcctTeamsFromLookups - Updates Account Owners based on whether they are new or have had their TM or CSM changed
    *                                   --- EXECUTED BY ACCOUNT AFTER UPDATE TRIGGER ---
    * @param List<Account> newOrUpdatedAccounts - List of new or updated Account records
    * @param Map<Id, Account> outdatedAccounts - Map of outdated Account records 
    * @return void
    */
    public static void updateAcctTeamsFromLookups(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','updateAcctTeamsFromLookups') && newOrUpdatedAccounts != null && outdatedAccounts != null){
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                /////////////////////////// TEMPORARILY COPIES LOOKUP FIELDS CHANGES TO TEAMS - WILL BE DEPRECATED WITH LOOKUPS //////////////////////////
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                // GET IDS OF ACCOUNTS WITH QUALIFYING CHANGES
                List<Account> qualifiedAccounts = new List<Account>();
                for(Account newOrUpdatedAccount : newOrUpdatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAccount.Id) : null;
                    if((newOrUpdatedAccount.TM_Territory_ManagerId__c != null && newOrUpdatedAccount.TM_Territory_ManagerId__c != outdatedAccount.TM_Territory_ManagerId__c) ||
                       (newOrUpdatedAccount.Customer_Success_Manager__c != null && newOrUpdatedAccount.Customer_Success_Manager__c != outdatedAccount.Customer_Success_Manager__c) ||
                       (newOrUpdatedAccount.TM_Renewals_ManagerId__c != null && newOrUpdatedAccount.TM_Renewals_ManagerId__c != outdatedAccount.TM_Renewals_ManagerId__c)){
                        qualifiedAccounts.add(newOrUpdatedAccount);
                    }
                }

                if(!qualifiedAccounts.isEmpty()){

                    // GET ACCOUNT CUSTOMER TYPES
                    Set<String> acctCustomerTypes = new Set<String>{ TerritoryManagementHelper.CUSTOMERTYPE, TerritoryManagementHelper.CUSTOMERPASTDUETYPE };

                    // ORGANIZE DATA AND GET ACCOUNT IDS FROM QUALIFYING RECORDS
                    Map<Id, List<AccountTeamMember>> teamMembersByAccount = new Map<Id, List<AccountTeamMember>>();
                    for(AccountTeamMember accountMember : [SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :qualifiedAccounts]){
                        if(!teamMembersByAccount.containsKey(accountMember.AccountId)){
                            teamMembersByAccount.put(accountMember.AccountId, new List<AccountTeamMember>());
                        }
                        teamMembersByAccount.get(accountMember.AccountId).add(accountMember);
                    }

                    List<AccountTeamMember> accountMembersToCreate = new List<AccountTeamMember>();
                    List<AccountTeamMember> accountMembersToDelete = new List<AccountTeamMember>();
                    for(Account qualifyingAccount : qualifiedAccounts){
                        Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(qualifyingAccount.Id) : null;

                        // GET USERS FROM ACCOUNT MEMBERS
                        AccountTeamMember acctTMMember;
                        AccountTeamMember acctCSMMember;
                        AccountTeamMember acctRMMember;
                        if(teamMembersByAccount.containsKey(qualifyingAccount.Id)){
                            for(AccountTeamMember member : teamMembersByAccount.get(qualifyingAccount.Id)){
                                if(member.TeamMemberRole == TMROLENAME && acctTMMember == null){
                                    acctTMMember = member;
                                }
                                if(member.TeamMemberRole == CSMROLENAME && acctCSMMember == null){
                                    acctCSMMember = member;
                                }
                                if(member.TeamMemberRole == RMROLENAME && acctRMMember == null){
                                    acctRMMember = member;
                                }
                            }
                        }

                        /////////////////////////////////////////////////////////////////////////////
                        /////////////////////////// TM CHANGE UPDATES ///////////////////////////////
                        ///////////////////////////////////////////////////////////////////////////// 
                        if(qualifyingAccount.TM_Territory_ManagerId__c != null && !qualifyingAccount.TM_Manager_Hold__c && qualifyingAccount.TM_Territory_ManagerId__c != outdatedAccount.TM_Territory_ManagerId__c){
                            if(acctTMMember == null || acctTMMember.UserId != qualifyingAccount.TM_Territory_ManagerId__c){
                                accountMembersToCreate.add(new AccountTeamMember(AccountId = qualifyingAccount.Id, UserId = qualifyingAccount.TM_Territory_ManagerId__c, TeamMemberRole = TMROLENAME));
                                
                                if(acctTMMember != null){
                                    // DELETE OLD MEMBER, NO LONGER VALID
                                    accountMembersToDelete.add(acctTMMember);
                                }
                            }
                        }

                        /////////////////////////////////////////////////////////////////////////////                              
                        /////////////////////////// CSM CHANGE UPDATES //////////////////////////////
                        /////////////////////////////////////////////////////////////////////////////  
                        if(qualifyingAccount.Customer_Success_Manager__c != null && !qualifyingAccount.CSM_Manager_Hold__c && qualifyingAccount.Customer_Success_Manager__c != outdatedAccount.Customer_Success_Manager__c){
                            if(acctCustomerTypes.contains(qualifyingAccount.Type) && (acctCSMMember == null || acctCSMMember.UserId != qualifyingAccount.Customer_Success_Manager__c)){
                                accountMembersToCreate.add(new AccountTeamMember(AccountId = qualifyingAccount.Id, UserId = qualifyingAccount.Customer_Success_Manager__c, TeamMemberRole = CSMROLENAME));
                                
                                if(acctCSMMember != null){
                                    // DELETE OLD MEMBER, NO LONGER VALID
                                    accountMembersToDelete.add(acctCSMMember);
                                }
                            }
                        }

                        /////////////////////////////////////////////////////////////////////////////                              
                        /////////////////////////// RM CHANGE UPDATES //////////////////////////////
                        /////////////////////////////////////////////////////////////////////////////  
                        if(qualifyingAccount.TM_Renewals_ManagerId__c != null && !qualifyingAccount.RM_Manager_Hold__c && qualifyingAccount.TM_Renewals_ManagerId__c != outdatedAccount.TM_Renewals_ManagerId__c){
                            if(acctCustomerTypes.contains(qualifyingAccount.Type) && (acctRMMember == null || acctRMMember.UserId != qualifyingAccount.TM_Renewals_ManagerId__c)){
                                accountMembersToCreate.add(new AccountTeamMember(AccountId = qualifyingAccount.Id, UserId = qualifyingAccount.TM_Renewals_ManagerId__c, TeamMemberRole = RMROLENAME));
                                
                                if(acctRMMember != null){
                                    // DELETE OLD MEMBER, NO LONGER VALID
                                    accountMembersToDelete.add(acctRMMember);
                                }
                            }
                        }
                    }

                    // DELETE INVALID ACCOUNT TEAM MEMBERS
                    if(!accountMembersToDelete.isEmpty()){
                        Database.DeleteResult[] accountTMDeleteResults = Database.delete(accountMembersToDelete, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(accountTMDeleteResults, 'AccountHelper', 'updateAcctTeamsFromLookups', false);
                    }

                    // CREATE ACCOUNT TEAM MEMBERS
                    if(!accountMembersToCreate.isEmpty()){
                        Database.SaveResult[] accountTMCreateResults = Database.insert(accountMembersToCreate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(accountTMCreateResults, 'AccountHelper', 'updateAcctTeamsFromLookups', false);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'updateAcctTeamsFromLookups');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'updateAcctTeamsFromLookups', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190911
    * @description validateOwnershipChanges - 
    *                             --- EXECUTED BY ACCOUNT BEFORE UPDATE TRIGGER ---
    * @param List<Account> updatedAccounts - List of updated Account records
    * @param Map<Id, Account> outdatedAccounts - Map of outdated Account records 
    * @return void
    */
    public static void validateOwnershipChanges(List<Account> updatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','validateOwnershipChanges') && updatedAccounts != null && outdatedAccounts != null){
                
                // TURN OFF THIS TRIGGER METHOD SO IT ONLY FIRES ONCE WITHIN A TRANSACTION
                if(!Test.isRunningTest()){
                    TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);
                }

                // GET PARENT USERS FROM QUALIFYING OPPS
                Set<Id> parentUserIds = new Set<Id>();
                for(Account updatedAccount : updatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null  ? outdatedAccounts.get(updatedAccount.Id) : null;
                    if(outdatedAccount != null && (updatedAccount.OwnerId != outdatedAccount.OwnerId ||
                                               updatedAccount.TM_Territory_ManagerId__c != outdatedAccount.TM_Territory_ManagerId__c ||
                                               updatedAccount.Territory_Manager__c != outdatedAccount.Territory_Manager__c ||
                                               updatedAccount.Customer_Success_Manager__c != outdatedAccount.Customer_Success_Manager__c)){
                        parentUserIds.add(updatedAccount.OwnerId);
                        parentUserIds.add(outdatedAccount.OwnerId);
                        parentUserIds.add(updatedAccount.TM_Territory_ManagerId__c);
                        parentUserIds.add(outdatedAccount.TM_Territory_ManagerId__c);
                        parentUserIds.add(updatedAccount.Territory_Manager__c);
                        parentUserIds.add(outdatedAccount.Territory_Manager__c);
                        parentUserIds.add(updatedAccount.Customer_Success_Manager__c);
                        parentUserIds.add(outdatedAccount.Customer_Success_Manager__c);
                    }
                }

                // REMOVE ANY NULLS FROM SET
                parentUserIds.remove(null);

                if(!parentUserIds.isEmpty()){
                    Ownership_Validation_Exemptions_Accts__mdt exemptionMetadata;
                    if(Test.isRunningTest()){
                        exemptionMetadata = AccountHelperTest.TestAcctValidationExceptions;
                    }
                    else{
                        for(Ownership_Validation_Exemptions_Accts__mdt metadata : [SELECT Owner_Changes_Exempt_Profiles__c, Owner_Changes_Exempt_Roles__c, Owner_Changes_Exempt_Users__c,
                                                                                   TM_Changes_Exempt_Profiles__c, TM_Changes_Exempt_Roles__c, TM_Changes_Exempt_Users__c,
                                                                                   CSM_Changes_Exempt_Profiles__c, CSM_Changes_Exempt_Roles__c, CSM_Changes_Exempt_Users__c
                                                                                   FROM Ownership_Validation_Exemptions_Accts__mdt LIMIT 1]){
                            exemptionMetadata = metadata;
                            break;
                        }
                    }

                    // GET PROFILE, ROLE, AND USER EXEMPTIONS
                    Set<Id> exemptOwnerChangeIds = new Set<Id>();
                    Set<Id> exemptTMChangeIds = new Set<Id>();
                    Set<Id> exemptCSMChangeIds = new Set<Id>();
                    if(exemptionMetadata != null){
                        String ownerExemptions = UtilityClass.replaceNull(exemptionMetadata.Owner_Changes_Exempt_Profiles__c, '') + '\r\n' +
                                                 UtilityClass.replaceNull(exemptionMetadata.Owner_Changes_Exempt_Roles__c, '') + '\r\n' +
                                                 UtilityClass.replaceNull(exemptionMetadata.Owner_Changes_Exempt_Users__c, '');
                        String territoryManagerExemptions = UtilityClass.replaceNull(exemptionMetadata.TM_Changes_Exempt_Profiles__c, '') + '\r\n' +
                                                            UtilityClass.replaceNull(exemptionMetadata.TM_Changes_Exempt_Roles__c, '') + '\r\n' +
                                                            UtilityClass.replaceNull(exemptionMetadata.TM_Changes_Exempt_Users__c, '');
                        String customerSuccessManagerExemptions = UtilityClass.replaceNull(exemptionMetadata.CSM_Changes_Exempt_Profiles__c, '') + '\r\n' +
                                                                  UtilityClass.replaceNull(exemptionMetadata.CSM_Changes_Exempt_Roles__c, '') + '\r\n' +
                                                                  UtilityClass.replaceNull(exemptionMetadata.CSM_Changes_Exempt_Users__c, '');

                        // PROFILE EXEMPTIONS
                        for(String ownerExemptionEntry : ownerExemptions.replace('\r','').split('\n')){
                            String exemptId = ownerExemptionEntry.left(18);
                            if(UtilityClass.validateId(exemptId)){
                                exemptOwnerChangeIds.add(exemptId);
                            }
                        }

                        // ROLE EXEMPTIONS
                        for(String territoryManagerExemptionEntry : territoryManagerExemptions.replace('\r','').split('\n')){
                            String exemptId = territoryManagerExemptionEntry.left(18);
                            if(UtilityClass.validateId(exemptId)){
                                exemptTMChangeIds.add(exemptId);
                            }
                        }

                        // USER EXEMPTIONS
                        for(String customerSuccessExemptionEntry : customerSuccessManagerExemptions.replace('\r','').split('\n')){
                            String exemptId = customerSuccessExemptionEntry.left(18);
                            if(UtilityClass.validateId(exemptId)){
                                exemptCSMChangeIds.add(exemptId);
                            }
                        }
                    }
                    
                    // GET PARENT USERS
                    Map<Id, User> parentUsers = new Map<Id, User>([SELECT Id, ManagerId FROM User WHERE Id IN :parentUserIds]);

                    // ERROR MESSAGE
                    String errorMessage = ' Please reach out to Sales Ops for Account Owner, Customer Success Manager or Territory Manager field changes.';

                    // VALIDATE OPP OWNERSHIP CHANGES
                    for(Account updatedAccount : updatedAccounts){
                        Account outdatedAccount = outdatedAccounts != null  ? outdatedAccounts.get(updatedAccount.Id) : null;
                        if(outdatedAccount != null){
                            Id userProfileId = UserInfo.getProfileId();
                            Id userRoleId = UserInfo.getUserRoleId();
                            Id userId = UserInfo.getUserId();

                            // BLOCK IF OWNER CHANGE NOT ALLOWED
                            if(updatedAccount.OwnerId != outdatedAccount.OwnerId &&
                                /*userId != outdatedAccount.OwnerId && userId != parentUsers.get(outdatedAccount.OwnerId).ManagerId && */                 
                                !exemptOwnerChangeIds.contains(userProfileId) && !exemptOwnerChangeIds.contains(userRoleId) && !exemptOwnerChangeIds.contains(userId)){
                                
                                updatedAccount.addError(errorMessage);
                            }

                            // BLOCK IF TM TERRITORY MANAGER CHANGE NOT ALLOWED
                            if(outdatedAccount.TM_Territory_ManagerId__c != null && updatedAccount.TM_Territory_ManagerId__c != outdatedAccount.TM_Territory_ManagerId__c && 
                                /* userId != outdatedAccount.TM_Territory_ManagerId__c && userId != parentUsers.get(outdatedAccount.TM_Territory_ManagerId__c).ManagerId && */                     
                                !exemptTMChangeIds.contains(userProfileId) && !exemptTMChangeIds.contains(userRoleId) && !exemptTMChangeIds.contains(userId)){

                                updatedAccount.addError(errorMessage);
                            }

                            // BLOCK IF TERRITORY MANAGER CHANGE NOT ALLOWED
                            if(outdatedAccount.Territory_Manager__c != null && updatedAccount.Territory_Manager__c != outdatedAccount.Territory_Manager__c && 
                                /* userId != outdatedAccount.Territory_Manager__c && userId != parentUsers.get(outdatedAccount.Territory_Manager__c).ManagerId && */                     
                                !exemptTMChangeIds.contains(userProfileId) && !exemptTMChangeIds.contains(userRoleId) && !exemptTMChangeIds.contains(userId)){

                                updatedAccount.addError(errorMessage);
                            }

                            // BLOCK IF CUSTOMER SUCCESS MANAGER CHANGE NOT ALLOWED
                            if(outdatedAccount.Customer_Success_Manager__c != null && updatedAccount.Customer_Success_Manager__c != outdatedAccount.Customer_Success_Manager__c && 
                                userId != outdatedAccount.Customer_Success_Manager__c && userId != parentUsers.get(outdatedAccount.Customer_Success_Manager__c).ManagerId &&              
                                !exemptCSMChangeIds.contains(userProfileId) && !exemptCSMChangeIds.contains(userRoleId) && !exemptCSMChangeIds.contains(userId)){

                                updatedAccount.addError(errorMessage);
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'validateOwnershipChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'validateOwnershipChanges', updatedAccounts, ex, true);
        }
    }

    /**
    * @date 20200922
    * @description setApttusIntegrationStatuses - Sets the appropriate Apttus Integration Status values when various updates are made to an account
    *                                       --- EXECUTED BY ACCOUNT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---       
    * @param List<Account> newOrUpdatedAccounts - Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void setApttusIntegrationStatuses(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','setApttusIntegrationStatuses') && newOrUpdatedAccounts != null && UserInfo.getUserId() != '0051T000009Ct4iQAC'){// APTTUS INTEGRATION USER

                //// PROCESS ACCOUNTS
                for(Account newOrUpdatedAcct : newOrUpdatedAccounts){
                    Account outdatedAcct = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAcct.Id) : null;

                    // ACCOUNT IS NEW
                    if(outdatedAcct == null){
                        newOrUpdatedAcct.A1_Integration_Status__c = 'Eligible';
                    }
                    // ACCOUNT WAS CHANGED, CHECK SYNCED FIELDS FOR CHANGES
                    else if(outdatedAcct != null && ApttusIntegrationSyncedAccountFields != null){
                        for(String accountField : ApttusIntegrationSyncedAccountFields){

                            // NOT A COMPOUND FIELD, COMPARE FIELD TO FIELD
                            if(String.isNotBlank(newOrUpdatedAcct.A1_Account_ID__c) && newOrUpdatedAcct.get(accountField) != outdatedAcct.get(accountField)){
                                newOrUpdatedAcct.A1_Integration_Status__c = 'Eligible';
                                break;
                            }

                            // CANNOT REFERENCE A COMPOUND FIELD'S PARTS IN CUSTOM METADATA SO CHECK THE INNER FIELDS MANUALLY
                            if(accountField == 'BillingAddress' &&
                                (newOrUpdatedAcct.BillingStreet != outdatedAcct.BillingStreet || newOrUpdatedAcct.BillingCity != outdatedAcct.BillingCity ||
                                 newOrUpdatedAcct.BillingState != outdatedAcct.BillingState || newOrUpdatedAcct.BillingPostalCode != outdatedAcct.BillingPostalCode || 
                                 newOrUpdatedAcct.BillingCountry != outdatedAcct.BillingCountry)){

                                newOrUpdatedAcct.A1_Billing_Integration_Status__c = 'Eligible';
                                continue;
                            }
                            else if(accountField == 'ShippingAddress' &&
                                    (newOrUpdatedAcct.ShippingStreet != outdatedAcct.ShippingStreet || newOrUpdatedAcct.ShippingCity != outdatedAcct.ShippingCity ||
                                     newOrUpdatedAcct.ShippingState != outdatedAcct.ShippingState || newOrUpdatedAcct.ShippingPostalCode != outdatedAcct.ShippingPostalCode || 
                                     newOrUpdatedAcct.ShippingCountry != outdatedAcct.ShippingCountry)){

                                newOrUpdatedAcct.A1_Shipping_Integration_Status__c = 'Eligible';
                                continue;
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'setApttusIntegrationStatuses');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'setApttusIntegrationStatuses', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @date 20200922
    * @description setApttusIntegrationOwner - Sets the appropriate Account Owner matching the A1 Org using the email address provided by the integration
    *                                           --- EXECUTED BY ACCOUNT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---       
    * @param List<Account> newOrUpdatedAccounts - Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void setApttusIntegrationOwner(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','setApttusIntegrationOwner') && newOrUpdatedAccounts != null && (UserInfo.getUserId() == '0051T000009Ct4iQAC' || Test.isRunningTest())){
                                                                                                                                    // APTTUS INTEGRATION USER -OR- RUNNING TEST

                // GET A1 OWNER EMAIL ADDRESSES FROM ACCOUNTS
                List<Account> qualifyingAccounts = new List<Account>();
                Set<String> ownerEmails = new Set<String>();
                for(Account newOrUpdatedAcct : newOrUpdatedAccounts){
                    Account outdatedAcct = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAcct.Id) : null;
                    if(String.isNotBlank(newOrUpdatedAcct.A1_Owner_Email__c) && (outdatedAcct == null || newOrUpdatedAcct.A1_Owner_Email__c != outdatedAcct.A1_Owner_Email__c)){
                        qualifyingAccounts.add(newOrUpdatedAcct);
                        ownerEmails.add(newOrUpdatedAcct.A1_Owner_Email__c);
                    }
                }

                if(!ownerEmails.isEmpty()){

                    // GET USERS MATCHING EMAIL ADDRESSES
                    Map<String, Id> usersByEmail = new Map<String, Id>();
                    for(User user : [SELECT Id, Email FROM User WHERE Email IN :ownerEmails AND Profile.UserLicense.Name = 'Salesforce']){
                        usersByEmail.put(user.Email, user.Id);
                    }

                    // PROCESS ACCOUNTS
                    for(Account qualifyingAcct : qualifyingAccounts){
                        qualifyingAcct.OwnerId = usersByEmail.containsKey(qualifyingAcct.A1_Owner_Email__c) ? usersByEmail.get(qualifyingAcct.A1_Owner_Email__c) : UserInfo.getUserId();
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'setApttusIntegrationOwner');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'setApttusIntegrationOwner', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @description updateShippingAddress - Copies Billing Address data into Shipping Address if blank
    *                                       --- EXECUTED BY ACCOUNT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---       
    * @param List<Account> newOrUpdatedAccounts - Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void updateShippingAddress(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','updateShippingAddress') && newOrUpdatedAccounts != null){
                // GET ACCCOUNTS WITH QUALIFYING CHANGES
                List<Account> qualifiedAccounts = new List<Account>();
                for(Account newOrUpdatedAccount : newOrUpdatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAccount.Id) : null;

                    // ACCOUNT IS UPDATED, PARENT DNB RECORD ADDED OR CHANGED
                    if(outdatedAccount != null && newOrUpdatedAccount.DNBoptimizer__DnBCompanyRecord__c != null && 
                                                  newOrUpdatedAccount.DNBoptimizer__DnBCompanyRecord__c != outdatedAccount.DNBoptimizer__DnBCompanyRecord__c){
                        
                        qualifiedAccounts.add(newOrUpdatedAccount);
                        ParentDNBRecordIds.add(newOrUpdatedAccount.DNBoptimizer__DnBCompanyRecord__c);
                    }
                    else if(newOrUpdatedAccount.ShippingStreet == null && newOrUpdatedAccount.ShippingCity == null){
                        
                        // ACCOUNT IS NEW, SHIPPING IS NULL, BILLING DATA EXISTS
                        if(newOrUpdatedAccount.BillingCountry != null && outdatedAccount == null){
                            qualifiedAccounts.add(newOrUpdatedAccount);
                        }
                        // ACCOUNT IS UPDATED, SHIPPING IS NULL, BILLING ADDRESS DATA ADDED
                        else if(newOrUpdatedAccount.BillingCountry != null && outdatedAccount != null && (newOrUpdatedAccount.BillingStreet != outdatedAccount.BillingStreet ||
                                                                                                          newOrUpdatedAccount.BillingCity != outdatedAccount.BillingCity ||
                                                                                                          newOrUpdatedAccount.BillingPostalCode != outdatedAccount.BillingPostalCode ||
                                                                                                          newOrUpdatedAccount.BillingState != outdatedAccount.BillingState ||
                                                                                                          newOrUpdatedAccount.BillingCountry != outdatedAccount.BillingCountry)){
                            qualifiedAccounts.add(newOrUpdatedAccount);
                        }
                    }
                }

                // PROCESS QUALIFIED RECORDS
                if(!qualifiedAccounts.isEmpty()){
                    for(Account qualifiedAccount : qualifiedAccounts){

                        // GET DATA FROM DNB RECORD AND UPDATE ACCOUNT
                        if(ParentDNBRecords.containsKey(qualifiedAccount.DNBoptimizer__DnBCompanyRecord__c)){
                            DNBoptimizer__DnBCompanyRecord__c parentDBRecord = ParentDNBRecords.get(qualifiedAccount.DNBoptimizer__DnBCompanyRecord__c);
                            if(String.isNotBlank(parentDBRecord.DNBoptimizer__PrimaryStreetAddress__c) && String.isBlank(parentDBRecord.DNBoptimizer__PrimaryStreetAddress2__c)){
                                qualifiedAccount.ShippingStreet = parentDBRecord.DNBoptimizer__PrimaryStreetAddress__c;
                            }
                            else if(String.isNotBlank(parentDBRecord.DNBoptimizer__PrimaryStreetAddress__c) && String.isNotBlank(parentDBRecord.DNBoptimizer__PrimaryStreetAddress2__c)){
                                qualifiedAccount.ShippingStreet = parentDBRecord.DNBoptimizer__PrimaryStreetAddress__c + '\r\n' + parentDBRecord.DNBoptimizer__PrimaryStreetAddress2__c;
                            }
                            qualifiedAccount.ShippingCity = parentDBRecord.DNBoptimizer__PrimaryCityName__c;
                            qualifiedAccount.ShippingPostalCode = parentDBRecord.DNBoptimizer__PrimaryPostalCode__c;
                            qualifiedAccount.ShippingState = parentDBRecord.DNBoptimizer__PrimaryStateProvinceName__c;
                            qualifiedAccount.ShippingCountry = parentDBRecord.DNBoptimizer__PrimaryCountryCode_ISO__c;
                        }
                        // POPULATE SHIPPING FROM BILLING FIELDS
                        else{
                            qualifiedAccount.ShippingStreet = qualifiedAccount.BillingStreet;
                            qualifiedAccount.ShippingCity = qualifiedAccount.BillingCity;
                            qualifiedAccount.ShippingPostalCode = qualifiedAccount.BillingPostalCode;
                            qualifiedAccount.ShippingState = qualifiedAccount.BillingState;
                            qualifiedAccount.ShippingCountry = qualifiedAccount.BillingCountry;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'updateShippingAddress');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'updateShippingAddress', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @description updateAccountIndustry - Updates the Account's industry using D&B data once the account is linked to its parent D&B record
    *                                       --- EXECUTED BY ACCOUNT BEFORE UPDATE TRIGGER ---       
    * @param List<Account> updatedAccounts - Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void updateAccountIndustry(List<Account> updatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','updateAccountIndustry') && updatedAccounts != null){
                // GET ACCCOUNTS WITH QUALIFYING CHANGES
                List<Account> qualifiedAccounts = new List<Account>();
                for(Account updatedAccount : updatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(updatedAccount.Id) : null;
                    if(outdatedAccount != null && updatedAccount.DNBoptimizer__DnBCompanyRecord__c != null && outdatedAccount.DNBoptimizer__DnBCompanyRecord__c == null){
                        // QUALIFIES IF THE ACCOUNT'S DNBoptimizer__DnBCompanyRecord__c IS NOT EMPTY AND IS CHANGED
                        qualifiedAccounts.add(updatedAccount);
                        ParentDNBRecordIds.add(updatedAccount.DNBoptimizer__DnBCompanyRecord__c);
                    }
                }

                // PROCESS QUALIFIED ACCOUNTS
                if(!qualifiedAccounts.isEmpty()){

                    // GET PARENT D&B RECORDS
                    Set<String> naicsCodes = new Set<String>();
                    Set<String> sic4Codes = new Set<String>();
                    for(DNBoptimizer__DnBCompanyRecord__c parentDNB : ParentDNBRecords.values()){
                        naicsCodes.add(parentDNB.DNBoptimizer__NAICSCode1__c);
                        sic4Codes.add(parentDNB.DNBoptimizer__SIC4Code1__c);
                    }
                   
                    // GET D&B INDUSTRY DATA
                    List<DNB_Industry__c> dnbIndustries = [SELECT Id, NAICS_Code__c, SIC4_Code__c, Industry__c FROM DNB_Industry__c
                                                            WHERE NAICS_Code__c IN :naicsCodes AND SIC4_Code__c IN :sic4Codes];

                    // UPDATE ACCOUNTS
                    for(Account qualifiedAccount : qualifiedAccounts){
                        if(ParentDNBRecords.containsKey(qualifiedAccount.DNBoptimizer__DnBCompanyRecord__c)){
                            DNBoptimizer__DnBCompanyRecord__c parentDBRecord = ParentDNBRecords.get(qualifiedAccount.DNBoptimizer__DnBCompanyRecord__c);

                            for(DNB_Industry__c dnbIndustry : dnbIndustries){
                                if(parentDBRecord.DNBoptimizer__NAICSCode1__c == dnbIndustry.NAICS_Code__c && parentDBRecord.DNBoptimizer__SIC4Code1__c == dnbIndustry.SIC4_Code__c){
                                    qualifiedAccount.Industry = dnbIndustry.Industry__c;
                                }
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'updateAccountIndustry');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'updateAccountIndustry', updatedAccounts, ex, true);
        }
    }

    /**
    * @description copyCSDivisionStampChangesToOpps - Copies updated CD Division values to applicable child Opportunities
    *                                       --- EXECUTED BY ACCOUNT AFTER UPDATE TRIGGER ---       
    * @param List<Account> updatedAccounts - Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void copyCSDivisionStampChangesToOpps(List<Account> updatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','copyCSDivisionStampChangesToOpps') && updatedAccounts != null){
                // GET ACCCOUNTS WITH QUALIFYING CHANGES
                Map<Id, Account> qualifiedAccounts = new Map<Id, Account>();
                for(Account updatedAccount : updatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(updatedAccount.Id) : null;
                    if(outdatedAccount != null && String.isNotBlank(updatedAccount.CS_Division_Stamp__c) && updatedAccount.CS_Division_Stamp__c != outdatedAccount.CS_Division_Stamp__c){
                        // QUALIFIES IF THE ACCOUNT'S CS_Division_Stamp__c IS NOT EMPTY AND IS CHANGED
                        qualifiedAccounts.put(updatedAccount.Id, updatedAccount);
                    }
                }

                // GET OPPS THAT NEED TO BE UPDATED
                if(!qualifiedAccounts.isEmpty()){
                    List<Opportunity> oppsToUpdate = new List<Opportunity>();

                    // GET OPEN OPPS
                    for(Opportunity opp : [SELECT Id, AccountId, CS_Division__c FROM Opportunity WHERE AccountId IN :qualifiedAccounts.keySet() AND IsClosed = false]){
                        if(qualifiedAccounts.get(opp.AccountId).CS_Division_Stamp__c != opp.CS_Division__c){
                            oppsToUpdate.add(new Opportunity(Id = opp.Id, CS_Division__c = qualifiedAccounts.get(opp.AccountId).CS_Division_Stamp__c));
                        }
                    }

                    // GET THE LATEST CLOSED WON IF ANY
                    for(Opportunity opp : [SELECT Id, AccountId, CS_Division__c FROM Opportunity WHERE AccountId IN :qualifiedAccounts.keySet() AND 
                                           IsClosed = true AND IsWon = true AND Type = 'New Business' AND CS_Division__c = null ORDER BY CloseDate DESC LIMIT 1]){
                        if(qualifiedAccounts.get(opp.AccountId).CS_Division_Stamp__c != opp.CS_Division__c){
                            oppsToUpdate.add(new Opportunity(Id = opp.Id, CS_Division__c = qualifiedAccounts.get(opp.AccountId).CS_Division_Stamp__c));
                        }
                    }

                    if(!oppsToUpdate.isEmpty()){
                        // SAVE UPDATED OPPS
                        Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'AccountHelper', 'copyCSDivisionStampChangesToOpps', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'copyCSDivisionStampChangesToOpps');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'copyCSDivisionStampChangesToOpps', updatedAccounts, ex, true);
        }
    }

    /**
    * @description updateOppOnboardingSpecialist - Updates the Onboarding Specialist of open child opps 
    *                                               --- EXECUTED BY BEFORE INSERT AND BEFORE UPDATE ACCOUNT TRIGGERS ---    
    * @param List<Account> newOrUpdatedAccounts - New or Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void updateOppOnboardingSpecialist(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','updateOppOnboardingSpecialist') && newOrUpdatedAccounts != null && !newOrUpdatedAccounts.isEmpty()){
                // GET IDS OF ACCOUNTS WITH QUALIFYING CHANGES
                Map<Id, Account> qualifiedAccounts = new Map<Id, Account>();
                for(Account newOrUpdatedAccount : newOrUpdatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAccount.Id) : null;
                    if(outdatedAccount != null && newOrUpdatedAccount.BillingPostalCode != null && newOrUpdatedAccount.BillingPostalCode != outdatedAccount.BillingPostalCode){
                        qualifiedAccounts.put(newOrUpdatedAccount.Id, newOrUpdatedAccount);
                    }
                }

                if(!qualifiedAccounts.isEmpty()){

                    // GET OPPS THAT NEED TO BE UPDATED
                    List<Opportunity> oppsToUpdate = [SELECT Id, AccountId, Onboarding_SpecialistId__c, Onboarding_Specialist_OverrideId__c, Opportunity_Booking_Stamp__c FROM Opportunity
                                                      WHERE AccountId IN :qualifiedAccounts.keySet() AND IsClosed = false AND Opportunity_Booking_Stamp__c LIKE 'AMER%'];

                    if(!oppsToUpdate.isEmpty()){
                        // PASS TO OPP TRIGGER METHOD AS NEW OPPS TO FORCE UPDATE
                        OpportunityHelper.updateOnboardingSpecialist(oppsToUpdate, null, qualifiedAccounts);

                        // SAVE UPDATED OPPS
                        Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'AccountHelper', 'updateOppOnboardingSpecialist', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'updateOppOnboardingSpecialist');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'updateOppOnboardingSpecialist', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190627
    * @description updateSubscriptionUpliftData - Updates an Account's Active and Future subscriptions when the Renewal Pricing Method is changed to or from Uplift
    *                                               --- EXECUTED BY ACCOUNT AFTER UPDATE TRIGGER ---
    * @param List<Account> updatedAccounts - Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void updateSubscriptionUpliftData(List<Account> updatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','updateSubscriptionUpliftData') && updatedAccounts != null){

                // GET ACCOUNTS WITH QUALIFYING CHANGES
                Map<Id, Account> qualifiedAccounts = new Map<Id, Account>();
                for(Account updatedAccount : updatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(updatedAccount.Id) : null;
                    if(outdatedAccount != null && updatedAccount.SBQQ__RenewalPricingMethod__c != outdatedAccount.SBQQ__RenewalPricingMethod__c && 
                        (updatedAccount.SBQQ__RenewalPricingMethod__c == 'Uplift' || outdatedAccount.SBQQ__RenewalPricingMethod__c == 'Uplift')){

                        // QUALIFIES IF THE ACCOUNT'S Renewal Pricing Method IS CHANGED
                        qualifiedAccounts.put(updatedAccount.Id, updatedAccount);
                    }
                }

                if(!qualifiedAccounts.isEmpty()){
                    // GET ACTIVE AND FUTURE SUBSCRIPTIONS TO UPDATE
                    List<SBQQ__Subscription__c> subscriptionsToUpdate = new List<SBQQ__Subscription__c>();
                    List<SBQQ__Subscription__c> subscriptionsToUplift = new List<SBQQ__Subscription__c>();
                    for(SBQQ__Subscription__c subscription : [SELECT Id, SBQQ__Account__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__QuoteLine__c, SBQQ__ListPrice__c, SBQQ__CustomerPrice__c
                                                              FROM SBQQ__Subscription__c
                                                              WHERE SBQQ__Account__c IN :qualifiedAccounts.keySet()
                                                              AND ((SBQQ__StartDate__c <= TODAY AND SBQQ__EndDate__c >= TODAY) OR SBQQ__StartDate__c > TODAY)]){
                        
                        Account parentAccount = qualifiedAccounts.get(subscription.SBQQ__Account__c);
                        if(parentAccount != null && parentAccount.SBQQ__RenewalPricingMethod__c == 'Uplift'){
                            // ACCOUNT RENEWAL PRICING METHOD CHANGED TO UPLIFT, ADD SUBSCRIPTION TO UPLIFT QUEUE
                            subscriptionsToUplift.add(subscription);
                        }
                        else if(parentAccount != null && parentAccount.SBQQ__RenewalPricingMethod__c != 'Uplift'){
                            // ACCOUNT RENEWAL PRICING METHOD CHANGED FROM UPLIFT, REMOVE UPLIFT RATE FROM SUBSCRIPTION AND ADD TO UPDATE QUEUE
                            subscription.SBQQ__RenewalUpliftRate__C = null;
                            subscriptionsToUpdate.add(subscription);
                        }
                    }

                    if(!subscriptionsToUplift.isEmpty()){
                        // UPDATE WITH UPLIFT DATA USING SUBSCRIPTION setUpliftPercentage METHOD THEN ADD TO UPDATE QUEUE
                        SBQQSubscriptionHelper.setUpliftPercentage(subscriptionsToUplift);
                        subscriptionsToUpdate.addAll(subscriptionsToUplift);
                    }

                    if(!subscriptionsToUpdate.isEmpty()){
                        // SAVE UPDATED SUBSCRIPTIONS
                        Database.saveResult[] subResults = Database.update(subscriptionsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(subResults, 'AccountHelper', 'updateSubscriptionUpliftData', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'updateSubscriptionUpliftData');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AccountHelper', 'updateSubscriptionUpliftData', updatedAccounts, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20200325
    * @description updateOppPartnerExpertiseScore - Executes the OpportunityHelper.updatePartnerExpertiseScore method to recalculate partner expertise scores on open opps
    *                                                 --- EXECUTED BY ACCOUNT AFTER UPDATE TRIGGER ---
    * @param List<Account> updatedAccounts - List of updated Accounts
    * @param Map<Id, Account> outdatedAccounts - Map of outdated Accounts
    * @return void
    */
    public static void updateOppPartnerExpertiseScore(List<Account> updatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper', 'updateOppPartnerExpertiseScore') && updatedAccounts != null){

                // GET IDS OF QUALIFYING ACCOUNTS
                Set<Id> parentAccountIds = new Set<Id>();
                for(Account updatedAccount : updatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(updatedAccount.Id) : null;
                    if(outdatedAccount != null && (updatedAccount.Partner_Expert__c != outdatedAccount.Partner_Expert__c || 
                                                   updatedAccount.Partner_Specialist__c != outdatedAccount.Partner_Specialist__c || 
                                                   updatedAccount.Partner_Certified__c != outdatedAccount.Partner_Certified__c)){
                        parentAccountIds.add(updatedAccount.Id);
                    }
                }

                // GET OPEN OPPS
                List<Opportunity> oppsToUpdate = [SELECT Id, ImplementationPartnerPrimary__c, ImplementationPartnerSecondary__c FROM Opportunity 
                                                  WHERE AccountId IN :parentAccountIds AND IsCLosed = false
                                                  AND (ImplementationPartnerPrimary__c != null OR ImplementationPartnerSecondary__c != null)];

                if(!oppsToUpdate.isEmpty()){
                    // UPDATE OPPS
                    OpportunityHelper.updatePartnerExpertiseScore(oppsToUpdate, null);

                    // SAVE CHANGES
                    Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'AccountHelper', 'updateOppPartnerExpertiseScore', true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'updateOppPartnerExpertiseScore');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('AccountHelper', 'updateOppPartnerExpertiseScore', updatedAccounts, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20200512
    * @description updateOppCSForecast - Executes the OpportunityHelper.updateOppCSForecast method to recalculate CS Forecast values on open opps renewal opps
    *                                     --- EXECUTED BY ACCOUNT AFTER UPDATE TRIGGER ---
    * @param List<Account> updatedAccounts - List of updated Accounts
    * @param Map<Id, Account> outdatedAccounts - Map of outdated Accounts
    * @return void
    */
    public static void updateOppCSForecast(List<Account> updatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','updateOppCSForecast') && updatedAccounts != null){

                // GET IDS OF QUALIFYING ACCOUNTS
                Set<Id> parentAccountIds = new Set<Id>();
                for(Account updatedAccount : updatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(updatedAccount.Id) : null;
                    if(outdatedAccount != null && updatedAccount.Customer_likely_to__c != outdatedAccount.Customer_likely_to__c){
                        parentAccountIds.add(updatedAccount.Id);
                    }
                }

                if(!parentAccountIds.isEmpty()){

                    // GET OPEN OPPS
                    List<Opportunity> oppsToUpdate = [SELECT Id, AccountId, Type, CS_Forecast__c, CS_Forecast_Override__c, CS_Forecast_Apex__c, Current_AI_Ave_MRR__c, 
                                                             Current_Automation_Ave_MRR__c, Current_Collaborate_Ave_MRR__c, Current_Composer_Ave_MRR__c, Current_Contracts_Ave_MRR__c, 
                                                             Current_Contracts_for_SF_Ave_MRR__c, Current_Courier_Ave_MRR__c, Current_Grid_Ave_MRR__c, Current_Orchestrate_Ave_MRR__c, 
                                                             Current_Other_Ave_MRR__c, Current_Product_Bundles_Ave_MRR__c, Current_Services_Ave_MRR__c, Current_Sign_Ave_MRR__c, 
                                                             Current_Support_Ave_MRR__c, Current_Training_Ave_MRR__c
                                                      FROM Opportunity 
                                                      WHERE AccountId IN :parentAccountIds AND IsCLosed = false AND Type = 'Renewal'];

                    // UPDATE OPPS
                    OpportunityHelper.calculateCSForecast(oppsToUpdate, null);

                    // SAVE CHANGES
                    Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'AccountHelper', 'updateOppCSForecast', true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'updateOppCSForecast');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('AccountHelper', 'updateOppCSForecast', updatedAccounts, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20210114
    * @description partnerAccountOwnerChange - Updates the Consulting Partner Account Owner field on child opportunities linked through the ImplementationPartnerPrimary__c lookup
    *                                           --- EXECUTED BY ACCOUNT AFTER UPDATE TRIGGER ---
    * @param List<Account> updatedAccounts - List of updated Accounts
    * @param Map<Id, Account> outdatedAccounts - Map of outdated Accounts
    * @return void
    */
    public static void partnerAccountOwnerChange(List<Account> updatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','partnerAccountOwnerChange') && updatedAccounts != null && outdatedAccounts != null){
                // GET ACCOUNT RECORD TYPES
                Id partnerAccountRT = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');

                // GET IDS OF QUALIFYING ACCOUNTS
                Set<Id> partnerAccountIds = new Set<Id>();
                for(Account updatedAccount : updatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(updatedAccount.Id) : null;
                    if(outdatedAccount != null && updatedAccount.OwnerId != outdatedAccount.OwnerId && updatedAccount.RecordTypeId == partnerAccountRT){
                        partnerAccountIds.add(updatedAccount.Id);
                    }
                }

                if(!partnerAccountIds.isEmpty()){

                    // GET OPEN OPPS
                    List<Opportunity> oppsToUpdate = new List<Opportunity>();
                    for(Opportunity opp : [SELECT Id, ImplementationPartnerPrimary__c, ImplementationPartnerPrimary__r.Owner.Full_Name__c, 
                                                  Consulting_Partner_Account_Owner__c 
                                           FROM Opportunity        
                                           WHERE ImplementationPartnerPrimary__c != null AND ImplementationPartnerPrimary__c IN :partnerAccountIds AND IsClosed = false]){
                        if(opp.Consulting_Partner_Account_Owner__c != opp.ImplementationPartnerPrimary__r.Owner.Full_Name__c){
                            opp.Consulting_Partner_Account_Owner__c = opp.ImplementationPartnerPrimary__r.Owner.Full_Name__c;
                            oppsToUpdate.add(opp);
                        }
                    }

                    // SAVE OPP CHANGES
                    if(!oppsToUpdate.isEmpty()){
                        Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'AccountHelper', 'partnerAccountOwnerChange', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'partnerAccountOwnerChange');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('AccountHelper', 'partnerAccountOwnerChange', updatedAccounts, ex, true);
        }
    }

    /**
    * @description validateStateAndCountry - Validate State and Country values on Billing and Shipping addresses
    *                                          --- EXECUTED BY BEFORE INSERT AND BEFORE UPDATE ACCOUNT TRIGGERS ---
    * @param List<Account> newOrUpdatedAccounts - New or Updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void validateStateAndCountry(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts){
        try{
            if(TriggerHelper.DoExecute('AccountHelper','validateStateAndCountry') && newOrUpdatedAccounts != null && !newOrUpdatedAccounts.isEmpty()){
                // GET ACCOUNTS WITH QUALIFYING CHANGES
                List<Account> qualifiedAccounts = new List<Account>();
                for(Account newOrUpdatedAccount : newOrUpdatedAccounts){
                    Account outdatedAccount = outdatedAccounts != null ? outdatedAccounts.get(newOrUpdatedAccount.Id) : null;
                    if(outdatedAccount == null || (outdatedAccount != null && (newOrUpdatedAccount.BillingState != outdatedAccount.BillingState || 
                                                                               newOrUpdatedAccount.BillingCountry != outdatedAccount.BillingCountry ||
                                                                               newOrUpdatedAccount.ShippingState != outdatedAccount.ShippingState ||
                                                                               newOrUpdatedAccount.ShippingCountry != outdatedAccount.ShippingCountry))){
                        qualifiedAccounts.add(newOrUpdatedAccount);
                    }
                }

                if(!qualifiedAccounts.isEmpty()){
                    // GET STATE AND COUNTRY FIELDS NAMES
                    Map<String,String> countryStateFieldPairs = new Map<String,String>{ Account.BillingCountry.getDescribe().getName() => Account.BillingState.getDescribe().getName(), 
                                                                                        Account.ShippingCountry.getDescribe().getName() => Account.ShippingState.getDescribe().getName() };
                    for(Account acct : qualifiedAccounts){
                        StateAndCountryValidation.validateRecordCountryStatePairs(acct, countryStateFieldPairs);

                        // SET COUNTRY AND STATE NAME/CODE FIELDS FOR ACCOUNT
                        acct.Billing_Country_Code__c = StateAndCountryValidation.CountryTwoLetterCodeByFullName.get(acct.BillingCountry);
                        acct.Shipping_Country_Code__c = StateAndCountryValidation.CountryTwoLetterCodeByFullName.get(acct.ShippingCountry);

                        if(StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.containsKey(acct.BillingCountry)){
                            acct.Billing_State_Code__c =  StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.get(acct.BillingCountry).get(acct.BillingState);
                        }

                        if(StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.containsKey(acct.ShippingCountry)){
                            acct.Shipping_State_Code__c = StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.get(acct.ShippingCountry).get(acct.ShippingState);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountHelper', 'validateStateAndCountry');
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('AccountHelper', 'validateStateAndCountry', newOrUpdatedAccounts, ex, true);
        }
    }


}