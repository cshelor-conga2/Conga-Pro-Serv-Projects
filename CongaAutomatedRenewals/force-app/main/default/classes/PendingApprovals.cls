/**
    * Wrapper class which holds the pending approvals of a Individual Approvers and Approver Group members. 
**/
    
public class PendingApprovals{
    @AuraEnabled public sbaa__Approval__c approvalName{get; set;}
    @AuraEnabled public String relatedTo{get; set;}
    @AuraEnabled public String relatedToId{get; set;}
    @AuraEnabled public String type{get; set;}
    @AuraEnabled public String assignedTo{get; set;}
    @AuraEnabled public String groupName{get; set;}
    @AuraEnabled public String groupId{get; set;}
    @AuraEnabled public String creationDate{get; set;}
    @AuraEnabled public String relatedToAccount{get; set;}
    @AuraEnabled public String relatedToAccountName{get; set;}
    @AuraEnabled public String relatedToOpportunity{get; set;}
    @AuraEnabled public String relatedToOpportunityName{get; set;}
    @AuraEnabled public String relatedToApprover{get; set;}
    @AuraEnabled public String relatedToApproverName{get; set;}
    @AuraEnabled public String relatedToActions{get; set;}
    @AuraEnabled public String relatedToRule{get; set;}
    @AuraEnabled public String relatedToRuleName{get; set;}
    @AuraEnabled public Decimal relatedToOverallSubscriptionDiscount{get; set;}
    @AuraEnabled public Decimal relatedToNewProductsDiscount{get; set;}
    @AuraEnabled public String relatedToRequestNotes{get; set;}

    @AuraEnabled
    public static List<PendingApprovals> processApprovalWrapper(List<sbaa__Approval__c> approvals) {
        Map<Id,String> mapOfGroupIdWithName = new Map<Id,String>();
        List<String> groupIds = new List<String>();
        List<PendingApprovals> allPendingApprovals = new List<PendingApprovals>();
        
        for (sbaa__Approval__c approval : approvals) {
            if (approval.sbaa__AssignedGroupId__c != null) {
                groupIds.add(approval.sbaa__AssignedGroupId__c);
            }
        }
        
        List<Group> groupList = [select id,name from group where id In : groupIds];
        
        for (Group groups : groupList ) {
            mapOfGroupIdWithName.put(groups.Id, groups.Name);      
        }
                    
        for (sbaa__Approval__c approval : approvals) {
            PendingApprovals pendingApproval = new PendingApprovals();
            
            pendingApproval.approvalName = approval;
            pendingApproval.relatedToApprover = approval.sbaa__Approver__c;
            pendingApproval.relatedToApproverName = approval.sbaa__Approver__r.Name;
            pendingApproval.relatedToActions = approval.sbaa__Actions__c;
            pendingApproval.relatedToRule = approval.sbaa__Rule__c;
            pendingApproval.relatedToRuleName = approval.sbaa__Rule__r.Name;
            
            pendingApproval.type = 'Quote';
            
            if (approval.Quote__c != null) {
                pendingApproval.relatedTo = approval.Quote__r.Name;
                pendingApproval.relatedToId = approval.Quote__c;
                pendingApproval.relatedToAccount = approval.Quote__r.SBQQ__Account__c;
                pendingApproval.relatedToAccountName= approval.Quote__r.SBQQ__Account__r.Name;
                pendingApproval.relatedToOpportunity = approval.Quote__r.SBQQ__Opportunity2__c;
                pendingApproval.relatedToOpportunityName= approval.Quote__r.SBQQ__Opportunity2__r.Name;
                pendingApproval.relatedToOverallSubscriptionDiscount = approval.Quote__r.Overall_Subscription_Discount__c;
                pendingApproval.relatedToNewProductsDiscount = approval.Quote__r.New_Products_Discount__c;
                pendingApproval.relatedToRequestNotes = approval.Quote__r.Approval_Request_Notes__c;
            }
            
            pendingApproval.assignedTo = approval.sbaa__AssignedTo__r.Name;
            
            if (approval.sbaa__AssignedGroupId__c != null) {
                pendingApproval.groupName = mapOfGroupIdWithName.get(approval.sbaa__AssignedGroupId__c);
                pendingApproval.groupId = approval.sbaa__AssignedGroupId__c;
            }                
            pendingApproval.creationDate = approval.CreatedDate.format();
            allPendingApprovals.add(pendingApproval);                          
        }

        System.debug('allPendingApprovals-- '+allPendingApprovals);   
        return allPendingApprovals;
    }
}