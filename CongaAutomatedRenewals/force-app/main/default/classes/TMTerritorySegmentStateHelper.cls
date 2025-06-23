/**
* @author ECS, ERedding
* @date 20190424
* @version 1.00
* @description TMTerritorySegmentStateHelper - Custom functionality for the TM_Territory_Segment_State__c custom object
*/
public with sharing class TMTerritorySegmentStateHelper {

    /**
    * @description checkForExistingUse - 
    * @param List<TM_Territory_Segment_State__c> newOrUpdatedTSs
    * @return void
    */
    public static void checkForExistingUse(List<TM_Territory_Segment_State__c> newOrUpdatedTSSs){
        try{        
            if(TriggerHelper.DoExecute('TMTerritorySegmentStateHelper','checkForExistingUse') && newOrUpdatedTSSs != null){
                // GET TERRITORY SEGMENT IDS
                Set<Id> territorySegmentIds = new Set<Id>();
                for(TM_Territory_Segment_State__c newOrUpdatedTSS : newOrUpdatedTSSs){
                    territorySegmentIds.add(newOrUpdatedTSS.TM_Territory_SegmentId__c);
                }
                
                // CHECK FOR OTHER TERRITORIES ALREADY USING THE COUNTRIES
                if(!territorySegmentIds.isEmpty()){
                    for(TM_Territory_Segment_State__c usedTerrSegmentState : [SELECT Id, TM_Territory_SegmentId__c, TM_Territory_SegmentId__r.Name, State_ProvinceId__c 
                                                                              FROM TM_Territory_Segment_State__c 
                                                                              WHERE Id NOT IN :newOrUpdatedTSSs AND TM_Territory_SegmentId__c IN :territorySegmentIds]){
                        for(TM_Territory_Segment_State__c newOrUpdatedTSS : newOrUpdatedTSSs){
                            if(newOrUpdatedTSS.TM_Territory_SegmentId__c == usedTerrSegmentState.TM_Territory_SegmentId__c && 
                               newOrUpdatedTSS.State_ProvinceId__c == usedTerrSegmentState.State_ProvinceId__c){
                                newOrUpdatedTSS.addError('This State is already used on another Territory Segment record: ' + usedTerrSegmentState.TM_Territory_SegmentId__r.Name);
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritorySegmentStateHelper', 'checkForExistingUse');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritorySegmentStateHelper', 'checkForExistingUse', newOrUpdatedTSSs, ex, true);
        }
    }

    /**
    * @description checkForParentCountries - 
    * @param List<TM_Territory_Segment_State__c> newOrUpdatedTSs
    * @return void
    */
    public static void checkForParentCountries(List<TM_Territory_Segment_State__c> newOrUpdatedTSSs){
        try{        
            if(TriggerHelper.DoExecute('TMTerritorySegmentStateHelper','checkForParentCountries') && newOrUpdatedTSSs != null){

                // GET TERRITORY IDS
                Set<Id> territorySegmentIds = new Set<Id>();
                for(TM_Territory_Segment_State__c newOrUpdatedTSS : newOrUpdatedTSSs){
                    territorySegmentIds.add(newOrUpdatedTSS.TM_Territory_SegmentId__c);
                }   
                
                if(!territorySegmentIds.isEmpty()){
                    // GET COUNTRY IDS FROM COUNTRIES ALREADY LISTED ON TERRITORIES
                    Set<Id> idsOfListedCountries = new Set<Id>();
                    for(TM_Territory_Segment_Country__c terrSegmentCountry : [SELECT Country_TerritoryId__c FROM TM_Territory_Segment_Country__c WHERE TM_Territory_SegmentId__c IN :territorySegmentIds]){
                        idsOfListedCountries.add(terrSegmentCountry.Country_TerritoryId__c);
                    }

                    // GET STATE IDS FOR COUNTRIES ALREADY LISTED ON TERRITORIES
                    Set<Id> stateIdsOfListedCountries = new Set<Id>();
                    for(State_Province__c state : [SELECT Id FROM State_Province__c WHERE Country_TerritoryId__c IN :idsOfListedCountries]){
                        stateIdsOfListedCountries.add(state.Id);
                    }

                    // COMPARE TERRITORY STATES AGAINST STATES BELONGING TO EXISTING TERRITORY COUNTRIES
                    for(TM_Territory_Segment_State__c newOrUpdatedTSS : newOrUpdatedTSSs){
                        if(stateIdsOfListedCountries.contains(newOrUpdatedTSS.State_ProvinceId__c)){
                            newOrUpdatedTSS.addError('A State cannot be added to a Territory if its parent Country is already listed.');
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritorySegmentStateHelper', 'checkForParentCountries');
            }
        }   
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritorySegmentStateHelper', 'checkForParentCountries', newOrUpdatedTSSs, ex, true);
        }
    }


}