/**
* @author ECS, ERedding
* @date 20190424
* @version 1.00
* @description TMTerritorySegmentCountryHelper - Custom functionality for the TM_Territory_Segment_Country__c custom object
*/
public with sharing class TMTerritorySegmentCountryHelper {

    /**
    * @description checkForExistingUse - 
    * @param List<TM_Territory_Segment_Country__c> checkForExistingUse
    * @return void
    */
    public static void checkForExistingUse(List<TM_Territory_Segment_Country__c> newOrUpdatedTSCs){
        try{        
            if(TriggerHelper.DoExecute('TMTerritorySegmentCountryHelper','checkForExistingUse') && newOrUpdatedTSCs != null){
                // GET TERRITORY SEGMENT IDS
                Set<Id> territorySegmentIds = new Set<Id>();
                for(TM_Territory_Segment_Country__c newOrUpdatedTSC : newOrUpdatedTSCs){
                    territorySegmentIds.add(newOrUpdatedTSC.TM_Territory_SegmentId__c);
                }
                
                // CHECK FOR OTHER TERRITORIES ALREADY USING THE COUNTRIES
                if(!territorySegmentIds.isEmpty()){
                    for(TM_Territory_Segment_Country__c usedTerrSegmentCountry : [SELECT Id, TM_Territory_SegmentId__c, TM_Territory_SegmentId__r.Name, Country_TerritoryId__c 
                                                                                  FROM TM_Territory_Segment_Country__c 
                                                                                  WHERE Id NOT IN :newOrUpdatedTSCs AND TM_Territory_SegmentId__c IN :territorySegmentIds]){
                        for(TM_Territory_Segment_Country__c newOrUpdatedTSC : newOrUpdatedTSCs){
                            if(newOrUpdatedTSC.TM_Territory_SegmentId__c == usedTerrSegmentCountry.TM_Territory_SegmentId__c &&
                               newOrUpdatedTSC.Country_TerritoryId__c == usedTerrSegmentCountry.Country_TerritoryId__c){
                                newOrUpdatedTSC.addError('This Country is already used on another Territory Segment record: ' + usedTerrSegmentCountry.TM_Territory_SegmentId__r.Name);
                            }
                            //else if(newOrUpdatedTerrCountry.Country_TerritoryId__c == usedTerrCountry.Country_TerritoryId__c && newOrUpdatedTerrCountry.TM_TerritoryId__c == usedTerrCountry.TM_TerritoryId__c){
                            //    newOrUpdatedTerrCountry.addError('This Country is already added to this Territory');
                            //}
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritorySegmentCountryHelper', 'checkForExistingUse');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritorySegmentCountryHelper', 'checkForExistingUse', newOrUpdatedTSCs, ex, true);
        }
    }

    /**
    * @description checkForChildStates - 
    * @param List<TM_Territory_Segment_Country__c> newOrUpdatedTSCs
    * @return void
    */
    public static void checkForChildStates(List<TM_Territory_Segment_Country__c> newOrUpdatedTSCs){
        try{        
            if(TriggerHelper.DoExecute('TMTerritorySegmentCountryHelper','checkForChildStates') && newOrUpdatedTSCs != null){
                // GET TERRITORY SEGMENT IDS
                Set<Id> territorySegmentIds = new Set<Id>();
                for(TM_Territory_Segment_Country__c terrSegmentCountry : newOrUpdatedTSCs){
                    territorySegmentIds.add(terrSegmentCountry.TM_Territory_SegmentId__c);
                }
                
                // GET TERRITORY SEGMENT STATES AND COMPARE AGAINST TERRITORY SEGMENT COUNTRIES
                if(!territorySegmentIds.isEmpty()){
                    for(TM_Territory_Segment_State__c terrSegmentState : [SELECT Id, TM_Territory_SegmentId__c, State_ProvinceId__r.Country_TerritoryId__c
                                                                          FROM TM_Territory_Segment_State__c 
                                                                          WHERE TM_Territory_SegmentId__c IN :territorySegmentIds]){
                        
                        for(TM_Territory_Segment_Country__c newOrUpdatedTSC : newOrUpdatedTSCs){
                            if(terrSegmentState.TM_Territory_SegmentId__c == newOrUpdatedTSC.TM_Territory_SegmentId__c &&
                                terrSegmentState.State_ProvinceId__r.Country_TerritoryId__c == newOrUpdatedTSC.Country_TerritoryId__c){
                                newOrUpdatedTSC.addError('A Country cannot be added to a Territory Segment if any of its States are already listed.');
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritorySegmentCountryHelper', 'checkForChildStates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritorySegmentCountryHelper', 'checkForChildStates', newOrUpdatedTSCs, ex, true);
        }
    }


}