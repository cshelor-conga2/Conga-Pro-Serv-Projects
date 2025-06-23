/**
* @author Conga Services, ERedding
* @date 20181206
* @version 1.00
* @description SBQQQuoteLineGroupHelper - Custom functionality for the SBQQ__QuoteLineGroup__c object
*/
public with sharing class SBQQQuoteLineGroupHelper {

    /**
    * @date 20181029
    * @description updateQuoteLineOppItemDates - Determines if there are applicable Quote Line Group changes that require child Quote Line updates
    * @param List<SBQQ__QuoteLineGroup__c> updatedQuoteLineGroups - List of updated Quote Line Group records
    * @param Map<Id, SBQQ__QuoteLineGroup__c> outdatedQuoteLineGroups - Map of outdated Quote Line Group records
    * @return void
    */
    public static void updateQuoteLineOppItemDates(List<SBQQ__QuoteLineGroup__c> updatedQuoteLineGroups, Map<Id, SBQQ__QuoteLineGroup__c> outdatedQuoteLineGroups){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteLineGroupHelper','updateQuoteLineOppItemDates') && updatedQuoteLineGroups != null){
                // GET IDS OF QUOTES WITH QUALIFYING CHANGES
                Set<Id> qualifiedQuoteGroupIds = new Set<Id>();
                for(SBQQ__QuoteLineGroup__c updatedGroup : updatedQuoteLineGroups){
                    SBQQ__QuoteLineGroup__c outdatedGroup = outdatedQuoteLineGroups != null ? outdatedQuoteLineGroups.get(updatedGroup.Id) : null;
                    
                    if(outdatedGroup != null && (updatedGroup.SBQQ__StartDate__c != outdatedGroup.SBQQ__StartDate__c ||
                                                 updatedGroup.SBQQ__EndDate__c != outdatedGroup.SBQQ__EndDate__c ||
                                                 updatedGroup.SBQQ__SubscriptionTerm__c != outdatedGroup.SBQQ__SubscriptionTerm__c)){
                        // QUALIFIED CHANGE OCCURED, ADD ID TO SET
                        qualifiedQuoteGroupIds.add(updatedGroup.Id);
                    }

                    if(!qualifiedQuoteGroupIds.isEmpty()){
                        // GET SBQQ Quote Lines RECORDS WHOSE OPP ITEM DATES WILL NEED TO BE UPDATED
                        List<SBQQ__QuoteLine__c> quoteLinesToProcess = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Group__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                                                                        Opp_Item_Start_Date__c, Opp_Item_End_Date__c
                                                                        FROM SBQQ__QuoteLine__c WHERE SBQQ__Group__c IN :qualifiedQuoteGroupIds];

                        // CALCULATE DATES
                        quoteLinesToProcess = SBQQQuoteLineHelper.calculateOppItemStartEndDates(quoteLinesToProcess);

                        // SAVE UPDATED RECORDS
                        if(quoteLinesToProcess != null && !quoteLinesToProcess.isEmpty()){
                            //TriggerHelper.TemporaryOveride('SBQQQuoteLine.updateOppItemStartEndDates', false); // NO NEED FOR METHOD TO RUN, DATES ALREADY CALCULATED
                            Database.saveResult[] quoteLineResults = Database.update(quoteLinesToProcess, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(quoteLineResults, 'SBQQQuoteLineGroupHelper', 'updateQuoteLineOppItemDates', true);  
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteLineGroupHelper','updateQuoteLineOppItemDates');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteLineGroupHelper', 'updateQuoteLineOppItemDates', updatedQuoteLineGroups, ex, true);
        } 
    }


}