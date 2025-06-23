/**
* @author ECS, ERedding
* @date 20200107
* @version 1.00
* @description SBQQQuoteBulkReassignExtTest  - Test class for the SBQQQuoteBulkReassignExt class
*/
@isTest
public with sharing class SBQQQuoteBulkReassignExtTest {

    /**
    * @description testMethod1 - Test Happy Path of code
    */
    public static testMethod void testMethod1() {
        // CREATE TEST QUOTE
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;

        // CREATE TEST APPROVALS
        sbaa__Approval__c approval1 = new sbaa__Approval__c(sbaa__Status__c = 'Assigned', Quote__c = quote.Id, sbaa__ApprovalStep__c = 1, sbaa__RecordField__c = 'Quote__c');
        sbaa__Approval__c approval2 = new sbaa__Approval__c(sbaa__Status__c = 'Requested', Quote__c = quote.Id, sbaa__ApprovalStep__c = 2, sbaa__RecordField__c = 'Quote__c');
        insert new List<sbaa__Approval__c>{ approval1, approval2 };

        Test.startTest();

        SBQQQuoteBulkReassignExt ext = new SBQQQuoteBulkReassignExt(new ApexPages.StandardController(quote));
        ext.bulkReassign();
        ext.returnToQuote();

        Test.stopTest();
        
        // TEST APPROVAL RECORDS FOR CORRECT DATA
        List<sbaa__Approval__c> quoteApprovals = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c WHERE Quote__c = :quote.Id];
        System.assert(quoteApprovals.size() == 2);
        System.assert(quoteApprovals[0].sbaa__AssignedTo__c == UserInfo.getUserId());
        System.assert(quoteApprovals[0].sbaa__AssignedTo__c == UserInfo.getUserId());
    }


}