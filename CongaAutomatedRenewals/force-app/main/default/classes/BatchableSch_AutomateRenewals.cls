/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Combination Batchable and Scheduled class to select Opportunity records to send renewals outbound
* messages.
*
* Record selection occurs over Opportunity records, but only 100 days outbound message is sent for 
* this object. For 75 and 60 days, outbound messages are sent from related primary quote.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Juan Díaz   <jcdiaz@systemyc.com>
* @modifiedBy
* @maintainedBy
* @version        1.0
* @created        2019-05-22
* @modified       
* @systemLayer    Batchable, Schedulable
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0            jcdiaz@systemyc.com
* 2019-05-22      Initial version.
* v2.0            eredding@getconga.com
* 2019-06-13      Updated version merging AutomateRenewalsBatch and AutomateRenewalsSched into one
*                 combo Batchable/Schedulable class
* v3.0            eredding@getconga.com
* 2019-07-09      Added functionality for retrieving and closing renewal Opportunities that are
*                 eligible for auto closure
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class BatchableSch_AutomateRenewals implements Database.Batchable<sObject>, Schedulable {

    /**
    * @description execute - Schedulable start method
    * @param Database.SchedulableContext sc
    * @return void
    */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 5);
    }

    /**
    * @description start - Batchable start method
    * @param Database.BatchableContext bc
    * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // GET QUOTE APPROVED RECORD TYPE ID
        Id quoteApprovedRT = UtilityClass.getRecordTypesForObject('SBQQ__Quote__c').get('Approved');

        return Database.getQueryLocator([
            SELECT Id, Name, SBQQ__PrimaryQuote__c, Days_Before_MRR_Sub_Start__c
            FROM Opportunity
            WHERE Type = 'Renewal' AND Automate_Renewal__c = true AND IsClosed = false AND Sub_Type__c != 'Forecasting Opportunity'
            AND (Days_Before_MRR_Sub_Start__c = 100 
                OR ((Days_Before_MRR_Sub_Start__c = 75 OR Days_Before_MRR_Sub_Start__c = 60) AND SBQQ__PrimaryQuote__r.RecordTypeId = :quoteApprovedRT)
                OR (Days_Before_MRR_Sub_Start__c = 45 AND Purchase_Order_Required__c != true AND Customer_Org_Id__c != null AND Account.Account_Delinquent_Flag__c = ''
                    AND Account.Legal_Hold_Flag__c = '' AND Account.BillingContact__c != null AND SBQQ__PrimaryQuote__c != null AND SBQQ__PrimaryQuote__r.Renewal_Requires_Signature__c = false 
                    AND SBQQ__RenewedContract__r.Auto_Renew_Term__c != '0' AND SBQQ__RenewedContract__r.Auto_Renew__c != 'No'))
            ]);
    }

    /**
    * @description execute - Batchable execute method
    * @param Database.BatchableContext bc
    * @param List<Opportunity> scope
    * @return void
    */
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        try{
            if(!scope.isEmpty()){
                List<Opportunity> renewalOppsForAutoNotice = new List<Opportunity>();
                List<Opportunity> renewalOppsForAutoClose = new List<Opportunity>();        
                for(Opportunity opp : scope){
                    if(opp.Days_Before_MRR_Sub_Start__c == 45){
                        renewalOppsForAutoClose.add(opp);
                    }
                    else{
                        renewalOppsForAutoNotice.add(opp);
                    }
                }

                // PROCESS AUTO CLOSE RENEWAL OPPS 
                BatchableSch_AutomateRenewalsHelper.processAutoCloseRenewalOpps(renewalOppsForAutoClose);
                // PROCESS AUTO NOTICE RENEWAL OPPS
                BatchableSch_AutomateRenewalsHelper.processAutoNoticeRenewalOpps(renewalOppsForAutoNotice);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AutomateRenewals', 'execute', scope, ex, true);
        }
    }

    /**
    * @description finish - Batchable finish method
    * @param Database.BatchableContext bc
    * @return void
    */                                                                
    public void finish(Database.BatchableContext bc){
        // RUN BATCH CLASS FOR CREATING COLLABORATE DOCUMENTS ON QUALIFIED QUOTES
        if(!Test.isRunningTest()){
            Database.executeBatch(new Batchable_AutomateRenewalNotices(), 1);
        }
    }


}