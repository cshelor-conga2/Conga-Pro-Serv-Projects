/**
* @author ECS, ERedding
* @date 20200107
* @version 1.00
* @description SBQQQuoteBulkReassignExt - 
*/
public with sharing class SBQQQuoteBulkReassignExt {
    private Id QuoteId { get; set; }

    // QUOTE RECALL SETTINGS METADATA
    private Set<Id> PermittedIds {
    get {
        if(PermittedIds == null){
            PermittedIds = new Set<Id>();
            List<Quote_Button_Settings__mdt> quoteRecallSettings = [SELECT Permitted_Ids_for_Bulk_Reassign__c FROM Quote_Button_Settings__mdt LIMIT 1];
            if(!quoteRecallSettings.isEmpty() && String.isNotBlank(quoteRecallSettings[0].Permitted_Ids_for_Bulk_Reassign__c)){
                for(String profileEntry : quoteRecallSettings[0].Permitted_Ids_for_Bulk_Reassign__c.replace('\r','').split('\n')){
                    String profileId = profileEntry.left(18);
                    if(UtilityClass.validateId(profileId)){
                        PermittedIds.add(profileId);
                    }
                }
            }
        }
        return PermittedIds;
    } set; }

    /**
    * @description SBQQQuoteBulkReassignExt - Constructor 
    */
    public SBQQQuoteBulkReassignExt(ApexPages.StandardController controller){
        if(controller != null && controller.getRecord() != null){
            QuoteId = controller.getId();
        }
    }
    
    /**
    * @description bulkReassign - Method to reassign all approvals belonging to a quote to the user who clicked the Bulk Reassign button
    * @return PageReference
    */
    public PageReference bulkReassign(){
        try{
            if(PermittedIds.contains(UserInfo.getProfileId()) || PermittedIds.contains(UserInfo.getUserRoleId()) || PermittedIds.contains(UserInfo.getUserId())){
                if(QuoteId != null){
                    // GET ADVANCE APPROVAL RECORDS BELONGING TO THE QUOTE
                    List<sbaa__Approval__c> approvalsToUpdate = [SELECT Id FROM sbaa__Approval__c WHERE Quote__c = :QuoteId AND sbaa__Status__c IN ('Assigned', 'Requested')];

                    if(!approvalsToUpdate.isEmpty()){
                        // SET ASSIGNED TO ON APPROVAL RECORDS              
                        for(sbaa__Approval__c approval : approvalsToUpdate){
                            approval.sbaa__AssignedTo__c = UserInfo.getUserId();
                        }

                        // SAVE
                        Database.saveResult[] approvalResults = Database.update(approvalsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(approvalResults, 'SBQQQuoteBulkReassignExt', 'bulkReassign', true);
                    }
                }

                return new PageReference('/' + QuoteId);
            }
            else{
                // PROFILE NOT ALLOWED, RETURN ERROR
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'You do not have permission to bulk reassign.'));
            }
            return null;        
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteBulkReassignExt', 'bulkReassign', QuoteId, ex, true);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'An error occurred while trying to bulk reassign: ' + ex.getMessage()));
            return null;
        }
    }

    /**
    * @description returnToQuote - Method that redirects back to the quote
    * @return PageReference
    */
    public PageReference returnToQuote(){
        return new PageReference('/' + QuoteId);
    }


}