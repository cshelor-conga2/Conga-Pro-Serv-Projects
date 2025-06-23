public class ApprovalsTableController {
    
    public Id objId {get; set;}
    
    public List<sbaa__Approval__c > getApprovalsList() {
        return [SELECT sbaa__Rule__r.Name, sbaa__Approver__r.Name,sbaa__ApprovalStep__c,sbaa__Status__c,sbaa__ApprovedBy__c, sbaa__CommentsLong__c
                FROM sbaa__Approval__c  
                WHERE Quote__c  = :objId];
    }

}