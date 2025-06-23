/**
* @author ECS, ERedding
* @date 20200218
* @version 1.00
* @description TMTerritoryDivisionCountryHelper - Custom functionality for the TM_Territory_Division_Country__c custom object
*/
public with sharing class TMTerritoryDivisionCountryHelper  {

    /**
    * @description checkForExistingUse - 
    * @param List<TM_Territory_Division_Country__c> checkForExistingUse
    * @return void
    */
    public static void checkForExistingUse(List<TM_Territory_Division_Country__c> newOrUpdatedTDCs){
        try{        
            if(TriggerHelper.DoExecute('TMTerritoryDivisionCountryHelper','checkForExistingUse') && newOrUpdatedTDCs != null){
                // GET TERRITORY DIVISION IDS
                Set<Id> territoryDivisionIds = new Set<Id>();
                for(TM_Territory_Division_Country__c terrDivisionCountry : newOrUpdatedTDCs){
                    territoryDivisionIds.add(terrDivisionCountry.TM_Territory_DivisionId__c);
                }
                
                // CHECK FOR OTHER TERRITORIES ALREADY USING THE COUNTRIES
                if(!territoryDivisionIds.isEmpty()){
                    for(TM_Territory_Division_Country__c existingTerrDivisionCountry : [SELECT Id, Name, TM_Territory_DivisionId__c, Country_TerritoryId__c 
                                                                                        FROM TM_Territory_Division_Country__c 
                                                                                        WHERE TM_Territory_DivisionId__c IN :territoryDivisionIds]){
                        for(TM_Territory_Division_Country__c newOrUpdatedTDC : newOrUpdatedTDCs){
                            if(newOrUpdatedTDC.TM_Territory_DivisionId__c == existingTerrDivisionCountry.TM_Territory_DivisionId__c &&
                               newOrUpdatedTDC.Country_TerritoryId__c == existingTerrDivisionCountry.Country_TerritoryId__c){
                                newOrUpdatedTDC.addError('This Country is already used on another Territory Segment record: ' + existingTerrDivisionCountry.Name);
                            }
                            //else if(newOrUpdatedTerrCountry.Country_TerritoryId__c == usedTerrCountry.Country_TerritoryId__c && newOrUpdatedTerrCountry.TM_TerritoryId__c == usedTerrCountry.TM_TerritoryId__c){
                            //    newOrUpdatedTerrCountry.addError('This Country is already added to this Territory');
                            //}
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritoryDivisionCountryHelper', 'checkForExistingUse');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritoryDivisionCountryHelper', 'checkForExistingUse', newOrUpdatedTDCs, ex, true);
        }
    }

    /**
    * @description checkForChildStates - 
    * @param List<TM_Territory_Division_Country__c> newOrUpdatedTDCs
    * @return void
    */
    public static void checkForChildStates(List<TM_Territory_Division_Country__c> newOrUpdatedTDCs){
        try{        
            if(TriggerHelper.DoExecute('TMTerritoryDivisionCountryHelper','checkForChildStates') && newOrUpdatedTDCs != null){
                // GET TERRITORY DIVISION IDS
                Set<Id> territoryDivisionIds = new Set<Id>();
                for(TM_Territory_Division_Country__c terrDivisionCountry : newOrUpdatedTDCs){
                    territoryDivisionIds.add(terrDivisionCountry.TM_Territory_DivisionId__c);
                }
                
                // GET TERRITORY DIVISION STATES AND COMPARE AGAINST TERRITORY DIVISION COUNTRIES
                if(!territoryDivisionIds.isEmpty()){
                    for(TM_Territory_Division_State__c terrDivisionState : [SELECT Id, TM_Territory_DivisionId__c, State_ProvinceId__r.Country_TerritoryId__c
                                                                            FROM TM_Territory_Division_State__c 
                                                                            WHERE TM_Territory_DivisionId__c IN :territoryDivisionIds]){
                        
                        for(TM_Territory_Division_Country__c newOrUpdatedTDC : newOrUpdatedTDCs){
                            if(terrDivisionState.TM_Territory_DivisionId__c == newOrUpdatedTDC.TM_Territory_DivisionId__c &&
                                terrDivisionState.State_ProvinceId__r.Country_TerritoryId__c == newOrUpdatedTDC.Country_TerritoryId__c){
                                newOrUpdatedTDC.addError('A Country cannot be added to a Territory Division if any of its States are already listed.');
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritoryDivisionCountryHelper', 'checkForChildStates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritoryDivisionCountryHelper', 'checkForChildStates', newOrUpdatedTDCs, ex, true);
        }
    }


}