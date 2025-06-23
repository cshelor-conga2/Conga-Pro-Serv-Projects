/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Helper class for Automate Renewals logic.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Juan Díaz   <jcdiaz@systemyc.com>
* @modifiedBy
* @maintainedBy
* @version        1.0
* @created        2019-05-22
* @modified       
* @systemLayer    Service, Helper
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0            jcdiaz@systemyc.com
* 2019-05-22      Initial version.
* v2.0            eredding@getconga.com
* 2019-06-13      Moved code into a class whose name matches naming standards
* v3.0            eredding@getconga.com
* 2019-07-09      Added functionality for auto closing qualifying renewal opps. Renamed methods
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class BatchableSch_AutomateRenewalsHelper {

    /**
    * @description processAutoNoticeRenewalOpps - 
    * @param List<Opportunity> opportunities - List of Opportunity records qualified for a Renewal Auto Notice
    * @return void
    */
    public static void processAutoNoticeRenewalOpps(List<Opportunity> opportunities) {
        try{
            Map<Id, Opportunity> opportunitiesMap = new Map<Id,Opportunity>();
            Set<Id> quoteIds = new Set<Id>();

            for(Opportunity opp : opportunities) {
                if(opp.Days_Before_MRR_Sub_Start__c == 100) {
                    opportunitiesMap.put(opp.Id, opp);
                }
                else {
                    quoteIds.add(opp.SBQQ__PrimaryQuote__c);
                }
            }

            // Set field value to trigger workflow processing on Opportunity
            if(!opportunitiesMap.isEmpty()) {
                Boolean doUpdate = false;
                for(Id oppId : opportunitiesMap.keySet()) {
                    opportunitiesMap.get(oppId).Automatic_Renewal_Notice__c = 'Triggered';
                    doUpdate = true;
                }

                if(doUpdate){
                    Database.saveResult[] oppUpdateResults = Database.update(opportunitiesMap.values(), false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppUpdateResults, 'BatchableSch_AutomateRenewalsHelper', 'processAutoNoticeRenewalOpps', false);
                }
            }

            // Set field value to trigger workflow processing on Quote
            Set<Id> quotesToGenerateDocuments = new Set<Id>();          
            if(!quoteIds.isEmpty()) {
                Boolean doUpdate = false;
                List<SBQQ__Quote__c> qualifiedQuotes = [
                    SELECT Id, Name, Days_Before_Opp_MRR_Sub_Start__c, Conga_Collaborate_Template__c, Automatic_Renewal_Notice__c, Renewal_Requires_Signature__c
                    FROM SBQQ__Quote__c 
                    WHERE Id IN :quoteIds
                ];

                for(SBQQ__Quote__c quote : qualifiedQuotes) {
                    quote.Conga_Collaborate_Template__c = quote.Renewal_Requires_Signature__c ? 'Signable Renewal Order Form' : 'Renewal Notice';
                    quote.Automatic_Renewal_Notice__c = 'Triggered';
                    doUpdate = true;
                }

                if(doUpdate){
                    Database.saveResult[] quoteUpdateResults = Database.update(qualifiedQuotes, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(quoteUpdateResults, 'BatchableSch_AutomateRenewalsHelper', 'processAutoNoticeRenewalOpps', false);
                }
            }

            // LOG ANY ERRORS
            SystemIssueLogHelper.upsertExceptions();
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AutomateRenewalsHelper', 'processAutoNoticeRenewalOpps', opportunities, ex, true);
        }
    }

    /**
    * @description processAutoCloseRenewalOpps - Closes renewal opportunities that meet certain criteria
    * @param List<Opportunity> oppsToClose - List of Opportunity records qualified for a Renewal Auto Closing
    * @return void
    */
    public static void processAutoCloseRenewalOpps(List<Opportunity> oppsToClose) {
        try{
            if(!oppsToClose.isEmpty()){
                for(Opportunity opp : oppsToClose){
                    opp.StageName = 'Closed Won';
                    opp.CloseDate = Date.today();
                }

                Database.saveResult[] oppUpdateResults = Database.update(oppsToClose, false);
                SystemIssueLogHelper.CheckForDatabaseErrors(oppUpdateResults, 'BatchableSch_AutomateRenewalsHelper', 'processAutoCloseRenewalOpps', false);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AutomateRenewalsHelper', 'processAutoCloseRenewalOpps', oppsToClose, ex, true);
        }
    }

    /**
    * @description renewalCalloutXML - HTTP Callout XML for use by the Batchable_AutomateRenewalNotices batch class.
    * @param String pOrgId
    * @param String pSessionId
    * @param String pEnterpriseURL
    * @param String pPartnerURL
    * @param String pQuoteId
    * @param String pOwnerId
    * @return String
    */
    public static String renewalCalloutXML(String pOrgId, String pSessionId, String pEnterpriseURL, String pPartnerURL, String pQuoteId, String pOwnerId){
        try{
            String calloutBody = '<?xml version="1.0" encoding="UTF-8"?>';
                      calloutBody += '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
                           calloutBody += '<env:Body>';
                                calloutBody += '<notifications xmlns="http://soap.sforce.com/2005/09/outbound">';
                                   calloutBody += '<OrganizationId>' + pOrgId  + '</OrganizationId>';
                                   calloutBody += '<ActionId />';
                                   calloutBody += '<SessionId>' + pSessionId  + '</SessionId>';
                                   calloutBody += '<EnterpriseUrl>' + pEnterpriseURL  + '</EnterpriseUrl>';
                                   calloutBody += '<PartnerUrl>' + pPartnerURL  + '</PartnerUrl>';
                                   calloutBody += '<Notification>';
                                      calloutBody += '<Id />';
                                      calloutBody += '<sObject xsi:type="sf:SBQQ__Quote__c" xmlns:sf="urn:sobject.enterprise.soap.sforce.com">';
                                         calloutBody += '<sf:Id>' + pQuoteId  + '</sf:Id>';
                                         calloutBody += '<sf:OwnerId>' + pOwnerId  + '</sf:OwnerId>';
                                      calloutBody += '</sObject>';
                                   calloutBody += '</Notification>';
                                calloutBody += '</notifications>';
                          calloutBody += '</env:Body>';
                      calloutBody += '</env:Envelope>';

            // RETURN BODY
            return calloutBody;
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AutomateRenewalsHelper', 'renewalCalloutXML', pQuoteId, ex, true);
            return '';
        }
    }


}