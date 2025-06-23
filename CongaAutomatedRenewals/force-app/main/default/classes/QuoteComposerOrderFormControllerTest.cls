@isTest
private class QuoteComposerOrderFormControllerTest {
	@testSetup
    private static void setup() {

        List<SBQQ__Quote__c> quotes =
        new List<SBQQ__Quote__c>{new SBQQ__Quote__c(
            ApprovalStatus__c='Approved')};
        insert quotes;
    }

    @isTest
    private static void testDefaultApprover() {
        List<SBQQ__Quote__c> quote =[select Id from SBQQ__Quote__c where ApprovalStatus__c=:'Approved'];
        Test.startTest();
        string composer= QuoteComposerOrderFormController.getComposerParameters(quote[0].Id);
        Test.stopTest();
        system.assert(composer.contains('recipient2=00550000003MpGI'));
    }
    @isTest
    private static void testReplaceApprover() {
        QuoteComposerOrderFormController.testApproverId='00550000003OLL7';
        List<SBQQ__Quote__c> quote =[select Id from SBQQ__Quote__c where ApprovalStatus__c=:'Approved'];
        Test.startTest();
        string composer= QuoteComposerOrderFormController.getComposerParameters(quote[0].Id);
        Test.stopTest();
        system.assert(composer.contains('recipient2=00550000007b4sO'));
    }
}