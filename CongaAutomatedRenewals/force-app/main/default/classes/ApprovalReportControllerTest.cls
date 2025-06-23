/**
 * @File Name          : ApprovalReportControllerTest.cls
 * @Description        : 
 * @Author             : MS Simplus August
 * @Group              : 
 * @Last Modified By   : MS Simplus August
 * @Last Modified On   : 21/11/2019, 2:48:14 am
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    21/11/2019   MS Simplus August     Initial Version
**/
@isTest
private class ApprovalReportControllerTest{
    static testmethod void testSingleApproval() {
        
        Account testAcct = new Account(Name='Test Account - QACT', Type='Prospect', Website='www.test.org', BillingStreet='100 Main St', 
                                       BillingCity='Anywhere', BillingCountry='United States', BillingState='California', BillingPostalCode = '94001');
        insert testAcct;
        Opportunity testOppty = new Opportunity(Name='Test Opportunity - QACT', AccountId=testAcct.Id, StageName='0 - Cloudera Target Account (Idle)', Type='NEW',
                                                CloseDate=Date.today().addDays(30));
        insert testOppty;
        SBQQ__Quote__c sbq = new SBQQ__Quote__c( SBQQ__Opportunity2__c = testOppty.Id);
        insert sbq;
        
        List<sbaa__Approval__c> listOfApprovals = new List<sbaa__Approval__c>();
        for (Integer index = 0; index < 5; index ++) {
            sbaa__Approval__c approval = new sbaa__Approval__c(sbaa__status__c = 'Requested',sbaa__ApprovalStep__c=1,sbaa__RecordField__c='Quote__c',Quote__c=sbq.Id,sbaa__AssignedTo__c=UserInfo.getUserId());
            listOfApprovals.add(approval);
        }
        
        insert listOfApprovals;

        PageReference pageRef = Page.ApprovalReport;
        
        Test.startTest();
        Test.setCurrentPage(pageRef);
        ApprovalReportController acr = new ApprovalReportController();
        ApprovalReportController.lightningApprovals();
        Test.stopTest();           
        System.assert(ApprovalReportController.allPendingApprovals != null );
        System.assert(ApprovalReportController.allPendingApprovals.size() != 0);
        System.assertEquals(ApprovalReportController.allPendingApprovals.size(), 10);
        
    }
    static testMethod void checkApproved() {
        Account testAcct = new Account(Name='Test Account - QACT', Type='Prospect', Website='www.test.org', BillingStreet='100 Main St', 
                                       BillingCity='Anywhere', BillingCountry='United States', BillingState='California', BillingPostalCode = '94001');
        insert testAcct;
        Opportunity testOppty = new Opportunity(Name='Test Opportunity - QACT', AccountId=testAcct.Id, StageName='0 - Cloudera Target Account (Idle)', Type='NEW',
                                                CloseDate=Date.today().addDays(30));
        insert testOppty;
        SBQQ__Quote__c sbq = new SBQQ__Quote__c( SBQQ__Opportunity2__c = testOppty.Id);
        insert sbq;
        
        List<sbaa__Approval__c> listOfApprovals = new List<sbaa__Approval__c>();
        for (Integer index = 0; index < 5; index ++) {
            sbaa__Approval__c approval = new sbaa__Approval__c(sbaa__status__c = 'Requested',sbaa__ApprovalStep__c=1,sbaa__RecordField__c='Quote__c',Quote__c=sbq.Id,sbaa__AssignedTo__c=UserInfo.getUserId());
            listOfApprovals.add(approval);
        }
        
        insert listOfApprovals;
        Id getId = listOfApprovals[0].Id;
        
		PageReference pageRef = Page.ApprovalReport;  
        
        List<sbaa__Approval__c> getApprovalList = new List<sbaa__Approval__c>();
        getApprovalList = [SELECT Id, sbaa__Status__c FROM sbaa__Approval__c WHERE Id =: getId];

        Test.startTest();
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',getId);
       	ApexPages.StandardController sc = new ApexPages.standardController(getApprovalList[0]);
        ApprovalReportController arc = new ApprovalReportController(sc);
        ApprovalReportController.recordInApproval = getId;
        arc.isApproved();
        Test.stopTest();      
    }
    
    static testMethod void checkRejected() {
        Account testAcct = new Account(Name='Test Account - QACT', Type='Prospect', Website='www.test.org', BillingStreet='100 Main St', 
                                       BillingCity='Anywhere', BillingCountry='United States', BillingState='California', BillingPostalCode = '94001');
        insert testAcct;
        Opportunity testOppty = new Opportunity(Name='Test Opportunity - QACT', AccountId=testAcct.Id, StageName='0 - Cloudera Target Account (Idle)', Type='NEW',
                                                CloseDate=Date.today().addDays(30));
        insert testOppty;
        SBQQ__Quote__c sbq = new SBQQ__Quote__c( SBQQ__Opportunity2__c = testOppty.Id);
        insert sbq;
        
        List<sbaa__Approval__c> listOfApprovals = new List<sbaa__Approval__c>();
        for (Integer index = 0; index < 5; index ++) {
            sbaa__Approval__c approval = new sbaa__Approval__c(sbaa__status__c = 'Requested',sbaa__ApprovalStep__c=1,sbaa__RecordField__c='Quote__c',Quote__c=sbq.Id,sbaa__AssignedTo__c=UserInfo.getUserId());
            listOfApprovals.add(approval);
        }
        
        insert listOfApprovals;
        Id getId = listOfApprovals[1].Id;
        
		PageReference pageRef = Page.ApprovalReport;  
        
        List<sbaa__Approval__c> getApprovalList = new List<sbaa__Approval__c>();
        getApprovalList = [SELECT Id, sbaa__Status__c FROM sbaa__Approval__c WHERE Id =: getId];
      
        Test.startTest();
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',getId);
       	ApexPages.StandardController sc = new ApexPages.standardController(getApprovalList[0]);
        ApprovalReportController arc = new ApprovalReportController(sc);
        ApprovalReportController.recordInApproval = getId;
        arc.isRejected();
        Test.stopTest();             
    }
    
    static testmethod  void checkGroupsApproval() {
        
        Account testAcct = new Account(Name='Test Account - QACT', Type='Prospect', Website='www.test.org', BillingStreet='100 Main St', 
                                       BillingCity='Anywhere', BillingCountry='United States', BillingState='California', BillingPostalCode = '94001');
        insert testAcct;
        Opportunity testOppty = new Opportunity(Name='Test Opportunity - QACT', AccountId=testAcct.Id, StageName='0 - Cloudera Target Account (Idle)', Type='NEW',
                                                CloseDate=Date.today().addDays(30));
        insert testOppty;
        SBQQ__Quote__c sbq = new SBQQ__Quote__c( SBQQ__Opportunity2__c = testOppty.Id);
        insert sbq;
        
        
        Group test = new Group(Name = 'Test Group');
        insert test;
        User user = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.RunAs(user)
        {
            GroupMember groupMember = new GroupMember();
            groupMember.GroupId = test.Id;
            groupMember.UserOrGroupId = UserInfo.getUserId();
            insert groupMember;
        }     
        
        sbaa__Approver__c approver = new sbaa__Approver__c(Name = 'testApprover', sbaa__GroupId__c= test.Id);
        insert approver;
        
        List<sbaa__Approval__c> listOfApprovals = new List<sbaa__Approval__c>();
        for (Integer index = 0; index < 5; index ++) {
            sbaa__Approval__c approval = new sbaa__Approval__c(sbaa__status__c = 'Requested',sbaa__ApprovalStep__c=1,sbaa__RecordField__c='Quote__c',Quote__c=sbq.Id,sbaa__AssignedGroupId__c= test.Id);
            listOfApprovals.add(approval);
        }
        insert listOfApprovals;
        PageReference pageRef = Page.ApprovalReport;
        
        System.Test.StartTest(); 
        System.Test.setCurrentPage(pageRef);
        ApprovalReportController acr = new ApprovalReportController();
        ApprovalReportController.lightningApprovals();
        System.Test.stopTest();
        System.assert(ApprovalReportController.allPendingApprovals != null );
        System.assert(ApprovalReportController.allPendingApprovals.size() != 0);
        System.assertEquals(ApprovalReportController.allPendingApprovals.size(), 10);
        
    }    
    
    
    
}