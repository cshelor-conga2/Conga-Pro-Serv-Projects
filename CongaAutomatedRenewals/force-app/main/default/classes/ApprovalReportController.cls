/**
 * @File Name          : ApprovalReportController.cls
 * @Description        : 
 * @Author             : MS Simplus August
 * @Group              : 
 * @Last Modified By   : MS Simplus August
 * @Last Modified On   : 19/11/2019, 3:41:15 am
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    12/11/2019   MS Simplus August     Initial Version
**/
public without sharing class ApprovalReportController {

    public ApprovalReportController(ApexPages.StandardController controller) {

    }

    public static List<sbaa__Approval__c> approvals;
    public static Set<sbaa__Approval__c> setApprovalsForSingleUsers = new Set<sbaa__Approval__c>();
    public static List<sbaa__Approval__c> listApprovalsForProcessing = new List<sbaa__Approval__c>();
    public static List<sbaa__Approval__c> listApprovalsForGroups = new List<sbaa__Approval__c>();
    @AuraEnabled public static List<PendingApprovals> allPendingApprovals {get; set;}
    public static Id recordInApproval {get; set;}
    
    @AuraEnabled
    public static List<PendingApprovals> lightningApprovals(){
        approvals = new List<sbaa__Approval__c>();
        getApprovalsForCurrentUser();    
        getApprovalsForGroupUser();    
        setApprovalsForSingleUsers.addAll(listApprovalsForGroups);
        listApprovalsForProcessing.addAll(setApprovalsForSingleUsers);
        //PendingApprovals appWrapper = new PendingApprovals();
        allPendingApprovals = PendingApprovals.processApprovalWrapper(listApprovalsForProcessing);
        System.debug('allPendingApprovals--  lightningApprovals '+allPendingApprovals);   
        return allPendingApprovals;
    }
    public ApprovalReportController() {
        approvals = new List<sbaa__Approval__c>();
        getApprovalsForCurrentUser();    
        getApprovalsForGroupUser();    
        setApprovalsForSingleUsers.addAll(listApprovalsForGroups);
        listApprovalsForProcessing.addAll(setApprovalsForSingleUsers);
        //PendingApprovals appWrapper = new PendingApprovals();
        allPendingApprovals = PendingApprovals.processApprovalWrapper(listApprovalsForProcessing);
    }

    /**
     * Methods for CommandLink Function
     * */

    public PageReference isApproved() {
        approvals = [SELECT Id, sbaa__Status__c FROM sbaa__Approval__c WHERE Id =: recordInApproval];
        List<sbaa__Approval__c> approvalList = new List<sbaa__Approval__c>();
        for(sbaa__Approval__c apprv : approvals) {
            apprv.sbaa__Status__c = 'Approved';
            approvalList.add(apprv);
        }
        update approvalList;
        PageReference tempPage = ApexPages.currentPage();            
        tempPage.setRedirect(true);
        return tempPage;
       
    }
    public PageReference isRejected() {
        approvals = [SELECT Id, sbaa__Status__c FROM sbaa__Approval__c WHERE Id =: recordInApproval];
        List<sbaa__Approval__c> approvalList = new List<sbaa__Approval__c>();
        for(sbaa__Approval__c apprv : approvals) {
            apprv.sbaa__Status__c = 'Rejected';
            approvalList.add(apprv);
        }
        update approvalList;
        PageReference tempPage = ApexPages.currentPage();            
        tempPage.setRedirect(true);
        return tempPage;
    }
    /*
    public PageReference isRejected() {

        return null;
    }
    public PageReference isReassigned() {

        return null;
    }
    */

    /**
     * This method populates the pending Approvals of current logged in user. 
    **/
    
    public static void getApprovalsForCurrentUser() {
        approvals = [SELECT Id, Name,
                     sbaa__Actions__c,
                     sbaa__Approver__c,
                     sbaa__Approver__r.Name,
                     sbaa__RecordField__c,
                     Quote__r.SBQQ__Account__c,
                     Quote__r.SBQQ__Account__r.Name,
                     sbaa__AssignedTo__c,
                     sbaa__AssignedToMe__c,
                     sbaa__AssignedGroupId__c,
                     CreatedById,
                     CreatedDate,
                     Quote__c,
                     Quote__r.Name,
                     Quote__r.SBQQ__Opportunity2__c,
                     Quote__r.SBQQ__Opportunity2__r.Name,
                     Quote__r.Approval_Request_Notes__c,
                     Quote__r.Overall_Subscription_Discount__c,
                     Quote__r.New_Products_Discount__c,
                     sbaa__Rule__c,
                     sbaa__Rule__r.Name,
                     sbaa__AssignedTo__r.Name 
                     FROM sbaa__Approval__c 
                     WHERE (sbaa__AssignedToMe__c = true or sbaa__AssignedGroupId__c != null) 
                        AND sbaa__Status__c = 'Requested' 
                        AND sbaa__Archived__c = false 
                        AND Quote__c!=null];        
        
        for (sbaa__Approval__c approval : approvals) {
            if (approval.sbaa__AssignedToMe__c == true) {
                setApprovalsForSingleUsers.add(approval);
                System.debug('Inside Current User');
            }
        }
        
    }
    
    /**
     * This method populates the pending Approvals of current logged in user with respect to user being part of public group. 
    **/
    public static void getApprovalsForGroupUser() {
        Map<Id,Set<Id>> mapOfGroupIdWithUserId =  new Map<Id,Set<Id>>();
        List<Id> groupID = new List<Id>();
             
        for (sbaa__Approval__c approvals : approvals) {
            if (approvals.sbaa__AssignedGroupId__c != null) {
                groupID.add(approvals.sbaa__AssignedGroupId__c);
            }
        }
        system.debug('groupID---'+groupID);
        List<GroupMember> groupMembers = 
        [Select Id, group.type, UserOrGroupId From GroupMember where group.id In : groupID];
        system.debug('groupMembers---'+groupMembers);
        for(GroupMember member : groupMembers) {    
            if (!mapOfGroupIdWithUserId.containsKey(member.group.id)) {
                mapOfGroupIdWithUserId.put(member.group.id , new Set<Id> {member.UserOrGroupId} );
            } else {
                Set<Id> members = mapOfGroupIdWithUserId.get(member.group.id);
                members.add(member.UserOrGroupId);
                mapOfGroupIdWithUserId.put(member.group.id , members);
            }
        }
                        
        for (sbaa__Approval__c groupApproval : approvals) {
            if (groupApproval.sbaa__AssignedGroupId__c != null) {
                Set<Id> usersId = mapOfGroupIdWithUserId.get(groupApproval.sbaa__AssignedGroupId__c);
                system.debug('usersId--'+usersId);
                if (usersId != null
                 && !usersId.Isempty() 
                 && usersId.contains(UserInfo.getUserId())) {
                    listApprovalsForGroups.add(groupApproval );
                    System.debug('Inside Group');
                } 
            }
        }
        
    }
    
    
        
}