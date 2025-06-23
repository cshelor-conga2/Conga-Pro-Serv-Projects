/**
* @author ECS, ERedding
* @date 20190424
* @version 1.00
* @description TMTerritoryDivisionStateHelper - [Description]
*/
public with sharing class TMTerritoryDivisionStateHelper {

    /**
    * @description checkForExistingUse - 
    * @param List<TM_Territory_Division_State__c> newOrUpdatedTSs
    * @return void
    */
    public static void checkForExistingUse(List<TM_Territory_Division_State__c> newOrUpdatedTDSs){
        try{        
            if(TriggerHelper.DoExecute('TMTerritoryDivisionStateHelper','checkForExistingUse') && newOrUpdatedTDSs != null){
                // GET TERRITORY SEGMENT IDS
                Set<Id> territoryDivisionIds = new Set<Id>();
                for(TM_Territory_Division_State__c newOrUpdatedTDS : newOrUpdatedTDSs){
                    territoryDivisionIds.add(newOrUpdatedTDS.TM_Territory_DivisionId__c);
                }
                
                // CHECK FOR OTHER TERRITORIES ALREADY USING THE COUNTRIES
                if(!territoryDivisionIds.isEmpty()){
                    for(TM_Territory_Division_State__c usedTerrDivisionState : [SELECT Id, TM_Territory_DivisionId__c, TM_Territory_DivisionId__r.Name, State_ProvinceId__c 
                                                                              FROM TM_Territory_Division_State__c 
                                                                              WHERE Id NOT IN :newOrUpdatedTDSs AND TM_Territory_DivisionId__c IN :territoryDivisionIds]){
                        for(TM_Territory_Division_State__c newOrUpdatedTDS : newOrUpdatedTDSs){
                            if(newOrUpdatedTDS.TM_Territory_DivisionId__c == usedTerrDivisionState.TM_Territory_DivisionId__c && 
                               newOrUpdatedTDS.State_ProvinceId__c == usedTerrDivisionState.State_ProvinceId__c){
                                newOrUpdatedTDS.addError('This State is already used on another Territory Division record: ' + usedTerrDivisionState.TM_Territory_DivisionId__r.Name);
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritoryDivisionStateHelper', 'checkForExistingUse');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritoryDivisionStateHelper', 'checkForExistingUse', newOrUpdatedTDSs, ex, true);
        }
    }

    /**
    * @description checkForParentCountries - 
    * @param List<TM_Territory_Division_State__c> newOrUpdatedTSs
    * @return void
    */
    public static void checkForParentCountries(List<TM_Territory_Division_State__c> newOrUpdatedTDSs){
        try{        
            if(TriggerHelper.DoExecute('TMTerritoryDivisionStateHelper','checkForParentCountries') && newOrUpdatedTDSs != null){

                // GET TERRITORY IDS
                Set<Id> territoryDivisionIds = new Set<Id>();
                for(TM_Territory_Division_State__c newOrUpdatedTDS : newOrUpdatedTDSs){
                    territoryDivisionIds.add(newOrUpdatedTDS.TM_Territory_DivisionId__c);
                }   
                
                if(!territoryDivisionIds.isEmpty()){
                    // GET COUNTRY IDS FROM COUNTRIES ALREADY LISTED ON TERRITORIES
                    Set<Id> idsOfListedCountries = new Set<Id>();
                    for(TM_Territory_Division_Country__c terrDivisionCountry : [SELECT Country_TerritoryId__c FROM TM_Territory_Division_Country__c WHERE TM_Territory_DivisionId__c IN :territoryDivisionIds]){
                        idsOfListedCountries.add(terrDivisionCountry.Country_TerritoryId__c);
                    }

                    // GET STATE IDS FOR COUNTRIES ALREADY LISTED ON TERRITORIES
                    Set<Id> stateIdsOfListedCountries = new Set<Id>();
                    for(State_Province__c state : [SELECT Id FROM State_Province__c WHERE Country_TerritoryId__c IN :idsOfListedCountries]){
                        stateIdsOfListedCountries.add(state.Id);
                    }

                    // COMPARE TERRITORY STATES AGAINST STATES BELONGING TO EXISTING TERRITORY COUNTRIES
                    for(TM_Territory_Division_State__c newOrUpdatedTDS : newOrUpdatedTDSs){
                        if(stateIdsOfListedCountries.contains(newOrUpdatedTDS.State_ProvinceId__c)){
                            newOrUpdatedTDS.addError('A State cannot be added to a Territory Division if its parent Country is already listed.');
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritoryDivisionStateHelper', 'checkForParentCountries');
            }
        }   
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritoryDivisionStateHelper', 'checkForParentCountries', newOrUpdatedTDSs, ex, true);
        }
    }


}