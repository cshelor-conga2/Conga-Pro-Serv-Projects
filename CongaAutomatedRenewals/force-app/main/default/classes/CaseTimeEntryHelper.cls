/**
* @author ECS, ERedding
* @date 20190417
* @version 1.00
* @description CaseTimeEntryHelper - Custom functionality for the Case_Time_Entry__c custom object
*/
public with sharing class CaseTimeEntryHelper {

    /**
    * @description calculateTotalHours - 
    *                                     --- EXECUTED BY CASE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<Case_Time_Entry__c> newOrUpdatedEntries - New or Updated Case Time Entry records
    * @param Map<Id, Case_Time_Entry__c> outdatedEntries - Outdated Case Time Entry records     
    * @return void
    */
    public static void calculateTotalHours(List<Case_Time_Entry__c> newOrUpdatedEntries, Map<Id, Case_Time_Entry__c> outdatedEntries){
        try{
            if(TriggerHelper.DoExecute('CaseTimeEntryHelper','calculateTotalHours') && newOrUpdatedEntries != null){

                // UPDATE QUALIFYING CASE TIME ENTRY RECORDS
                for(Case_Time_Entry__c newOrUpdatedEntry : newOrUpdatedEntries){
                    Case_Time_Entry__c outdatedEntry = outdatedEntries != null ? outdatedEntries.get(newOrUpdatedEntry.Id) : null;

                    if(newOrUpdatedEntry.Start_Date_Time__c != null && newOrUpdatedEntry.End_Date_Time__c != null &&
                        (outdatedEntry == null || newOrUpdatedEntry.Start_Date_Time__c != outdatedEntry.Start_Date_Time__c || 
                                                  newOrUpdatedEntry.End_Date_Time__c != outdatedEntry.End_Date_Time__c)){

                        // CALCULATE TOTAL HOURS
                        newOrUpdatedEntry.Total_Hours__c = ((Decimal.valueOf(newOrUpdatedEntry.End_Date_Time__c.getTime() - newOrUpdatedEntry.Start_Date_Time__c.getTime()))/1000/60/60).setScale(2);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseTimeEntryHelper', 'calculateTotalHours');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('CaseTimeEntryHelper', 'calculateTotalHours', newOrUpdatedEntries, ex, true);
        }
    }


}