/**
* @author Conga Services, KSears, ERedding
* @date 20190201
* @version 1.00
* @description BillableTimeRollupHelper - 
*/
public with sharing class BillableTimeRollupHelper {

    /**
    * @description billableTimeRollup - Updates Billable Time Current Subscription field
    * @param Map<Id, Account> accountsToUpdate - Accounts on which to update Billable Time fields
    * @return void
    */ 
    public static void billableTimeRollup(Map<Id, Account> accountsToUpdate){
         try{
            // GET DATES FROM THE LATEST CURRENT SUBSCRIPTION PER ACCOUNT
            Map<Id, SBQQ__Subscription__c> latestSubsByAcct = new Map<Id, SBQQ__Subscription__c>();
            for(SBQQ__Subscription__c sub : [SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Account__c FROM SBQQ__Subscription__c 
                                             WHERE SBQQ__Account__c IN :accountsToUpdate.keySet() AND SBQQ__StartDate__c <= TODAY AND SBQQ__EndDate__c >= TODAY
                                             ORDER BY CreatedDate DESC]){
                if(!latestSubsByAcct.containsKey(sub.SBQQ__Account__c)){
                    latestSubsByAcct.put(sub.SBQQ__Account__c, sub);
                }
            }

            // UPDATE ACCOUNTS WITH SUBSCRIPTION DATE DATA AND ADD TO UPDATE QUEUE
            for(Account acc : accountsToUpdate.values()){
                acc.Subscription_Term_Start_Date__c = null;
                acc.Subscription_Term_End_Date__c = null;
                acc.Billable_Time_Current_Subscription__c = 0;
                acc.Billable_Time_Non_Current_Subscription__c = 0;

                if(latestSubsByAcct.containsKey(acc.Id)){
                    acc.Subscription_Term_Start_Date__c = latestSubsByAcct.get(acc.Id).SBQQ__StartDate__c;
                    acc.Subscription_Term_End_Date__c = latestSubsByAcct.get(acc.Id).SBQQ__EndDate__c;
                }
            }

            Set<Id> caseIds = new Set<Id>();
            Set<Id> caseIdsNonSub = new Set<Id>();
            for(Case ca : [SELECT Id, ClosedDate, AccountId FROM Case WHERE AccountId IN :accountsToUpdate.keySet() AND IsClosed = true]){
                if(latestSubsByAcct.containsKey(ca.AccountId) && ca.ClosedDate >= latestSubsByAcct.get(ca.AccountId).SBQQ__StartDate__c && 
                                                                 ca.ClosedDate <= latestSubsByAcct.get(ca.AccountId).SBQQ__EndDate__c){
                    caseIds.add(ca.Id);
                }
                else{
                    caseIdsNonSub.add(ca.Id);
                }
            }

            // for the subscription dates
            AggregateResult[] groupedResults = [SELECT AccountId, SUM(Billable_Time_Hours__c) total FROM Case WHERE Id IN :caseIds GROUP BY AccountId];
            for(AggregateResult ar : groupedResults){
                Id accountId = (Id)ar.get('AccountId');
                if(accountsToUpdate.containsKey(accountId)){
                    accountsToUpdate.get(accountId).Billable_Time_Current_Subscription__c = (Decimal)ar.get('total');
                }
            }
            
            // for everything else with closed cases
            AggregateResult[] groupedResults2  = [SELECT AccountId, SUM(Billable_Time_Hours__c) total FROM Case WHERE Id IN :caseIdsNonSub GROUP BY AccountId];
            for(AggregateResult ar : groupedResults2){
                Id accountId = (Id)ar.get('AccountId');
                if(accountsToUpdate.containsKey(accountId)){
                    accountsToUpdate.get(accountId).Billable_Time_Non_Current_Subscription__c = (Decimal)ar.get('total');
                }
            }

            // SAVE ACCOUNTS AND LOG ANY ERRORS
            Database.SaveResult[] updateResults = Database.update(accountsToUpdate.values(), false);
            SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'BillableTimeRollupHelper', 'billableTimeRollup', true);
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('BillableTimeRollupHelper', 'billableTimeRollup', accountsToUpdate, ex, true);
        }
    }


}