/**
* @author ECS ERedding
* @date 20191002
* @version 1.00
* @description Batchable_AutomateRenewalNotices - Batch class for automating the create of renewal notices through Collaborate. Replaces the Outbound Message that is currently used.
*/
public class Batchable_AutomateRenewalNotices implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private final Collaborate_Renewal_Notice_Settings__mdt AutoRenewalNoticeSettings;
    private final String OrganizationId;
    private final String SessionId;
    private final String EnterpriseUrl;
    private final String PartnerUrl;

    /** 
    * @description Batchable_AutomateRenewalNotices - Constructor
    */
    public Batchable_AutomateRenewalNotices(){
        // GET SETTINGS FROM CUSTOM METADATA
        for(Collaborate_Renewal_Notice_Settings__mdt settings : [SELECT Endpoint__c, Number_of_Attempts__c FROM Collaborate_Renewal_Notice_Settings__mdt LIMIT 1]){
            AutoRenewalNoticeSettings = settings;
            break;
        }

        // SET VARIABLES
        OrganizationId = UserInfo.getOrganizationId();
        SessionId = UserInfo.getSessionId();
        EnterpriseUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/c/46.0/' + UserInfo.getOrganizationId();
        PartnerUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/46.0/' + UserInfo.getOrganizationId();
    }

    /** 
    * @description Batchable start method
    */  
    public Database.QueryLocator start(Database.BatchableContext context) {
        if(AutoRenewalNoticeSettings != null && String.isNotBlank(AutoRenewalNoticeSettings.Endpoint__c) && AutoRenewalNoticeSettings.Number_of_Attempts__c > 0
            && String.isNotBlank(OrganizationId) && String.isNotBlank(SessionId) && String.isNotBlank(EnterpriseUrl) && String.isNotBlank(PartnerUrl)){

            return Database.getQueryLocator([SELECT Id, OwnerId FROM SBQQ__Quote__c WHERE Automatic_Renewal_Notice__c = 'Triggered' 
                                                                                    AND Conga_Collaborate_Template__c != null 
                                                                                    AND (Days_Before_Opp_MRR_Sub_Start__c = 75 OR Days_Before_Opp_MRR_Sub_Start__c = 60)]);
        }
        else{
            SystemIssueLogHelper.LogException('Batchable_AutomateRenewalNotices', 'start', null, 'Collaborate Renewal Notice Settings are missing, incorrect, or no attempts are allowed.', true);
            return Database.getQueryLocator([SELECT Id FROM SBQQ__Quote__c WHERE Id = null]);
        }
    }

    /** 
    * @description Logic to be performed on scope
    */
    public void execute(Database.BatchableContext context, List<SBQQ__Quote__c> scope) {
        try{
            // GENERATE AND SEND HTTP CALL FOR EACH QUOTE
            for(SBQQ__Quote__c quote : scope){

                Http http = new Http();
                for(Integer tryCount = 1; tryCount <= AutoRenewalNoticeSettings.Number_of_Attempts__c; tryCount++){
                    HttpRequest createRenewalNoticeDocumentRequest = new HttpRequest();
                    createRenewalNoticeDocumentRequest.setEndpoint(AutoRenewalNoticeSettings.Endpoint__c);
                    createRenewalNoticeDocumentRequest.setMethod('POST');
                    createRenewalNoticeDocumentRequest.setHeader('Content-Type', 'text/xml; charset=utf-8');
                    createRenewalNoticeDocumentRequest.setTimeout(20000);
                    createRenewalNoticeDocumentRequest.setBody(BatchableSch_AutomateRenewalsHelper.renewalCalloutXML(OrganizationId, SessionId, EnterpriseUrl, PartnerUrl, quote.Id, quote.OwnerId));
                    
                    HttpResponse createRenewalNoticeDocumentResponse = http.send(createRenewalNoticeDocumentRequest);
                    if(createRenewalNoticeDocumentResponse.getStatusCode() != 200 && createRenewalNoticeDocumentResponse.getStatusCode() != 201){
                        // NOT SUCCESSFUL, LOG ERROR 
                        String httpErrorInfo = createRenewalNoticeDocumentResponse.getStatusCode() + ' ' + createRenewalNoticeDocumentResponse.getStatus() + ' - ' + createRenewalNoticeDocumentResponse.getBody();
                        String errorMessage = 'Quote Renewal Notice document could not be created. HTTP Error: ' + httpErrorInfo;
                        SystemIssueLogHelper.LogException('Batchable_AutomateRenewalNotices', 'execute', quote.Id, errorMessage, false);
                    }
                    else{
                        // SUCCESSFUL, BREAK OUT OF RETRY LOOP
                        break;
                    }
                }
            }

            // SAVE ANY LOGGED ERRORS
            SystemIssueLogHelper.UpsertExceptions();
        }
        catch(Exception ex){ 
            SystemIssueLogHelper.LogException('Batchable_AutomateRenewalNotices', 'execute', scope, ex, true);
        }
    }
    
    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
    }


}