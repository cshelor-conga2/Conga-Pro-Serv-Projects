public with sharing class QuoteExtController {
    
    // QUOTE RECALL SETTINGS METADATA
    private static Set<Id> PermittedIds {
    get {
        if(PermittedIds == null){
            PermittedIds = new Set<Id>();
            List<Quote_Button_Settings__mdt> quoteRecallSettings = [SELECT Permitted_Ids_for_Recall__c FROM Quote_Button_Settings__mdt LIMIT 1];
            if(!quoteRecallSettings.isEmpty() && String.isNotBlank(quoteRecallSettings[0].Permitted_Ids_for_Recall__c)){
                for(String profileEntry : quoteRecallSettings[0].Permitted_Ids_for_Recall__c.replace('\r','').split('\n')){
                    String profileId = profileEntry.left(18);
                    if(UtilityClass.validateId(profileId)){
                        PermittedIds.add(profileId);
                    }
                }
            }
        }
        return PermittedIds;
    } set; }

    private Id quoteId;
    
    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
    }

    public PageReference onSubmit() {
        if (quoteId != null) {
            SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
        }
        return new PageReference('/' + quoteId);
    }

    public PageReference onRecall() {
        // GET QUOTE RECORD
        List<SBQQ__Quote__c> quoteToRecall = [SELECT Id, OwnerId FROM SBQQ__Quote__c WHERE Id = :quoteId];

        // SWITCH QUOTE OWNERSHIP TO CURRENT USER IF THE CURRENT USER IS ALLOWED TO RECALL
        Id currentOwner;
        if(!quoteToRecall.isEmpty() && quoteToRecall[0].OwnerId != UserInfo.getUserId() && (PermittedIds.contains(UserInfo.getProfileId()) || 
                                                                                            PermittedIds.contains(UserInfo.getUserRoleId()) || 
                                                                                            PermittedIds.contains(UserInfo.getUserId()))){
            currentOwner = quoteToRecall[0].OwnerId;
            quoteToRecall[0].OwnerId = UserInfo.getUserId();
            update quoteToRecall[0];
        }

        if (quoteId != null) {
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
        }

        // SWITCH OWNERSHIP BACK
        if(!quoteToRecall.isEmpty() && currentOwner != null){
            quoteToRecall[0].OwnerId = currentOwner;
            update quoteToRecall[0];
        }

        return new PageReference('/' + quoteId);
    }
}