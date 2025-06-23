/**
* @author Conga Services, KSears
* @date 20190314
* @version 1.00
* @description SupportRequestWizardTest - Test class for the SupportRequestWizard and SupportRequestRedirect classes
*/
@isTest
public with sharing class SupportRequestWizardTest {

    /** 
    * @description testHappyPath1 - 
    */  
    static testmethod void testHappyPath1() {
        Support_Request__c sr = new Support_Request__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();
            SupportRequestWizardController controller = new SupportRequestWizardController(stdController);
            //Issue/Bug walkthrough
            controller.selectedType = 'Issue';
            controller.choseType();
            controller.issueBugNext();
            controller.newSR.Subject__c = 'test';
            controller.issueBugNext();
            controller.issueBugNext();
            controller.newSR.Issue__c = 'test';
            controller.issueBugNext();
            controller.issueBugNext();
            controller.newSR.Initial_Occurence__c = Date.today();
            controller.issueBugNext();
            controller.issueBugNext();
            controller.newSR.Steps_to_Reproduce__c = 'test';
            controller.issueBugNext();
            controller.issueBugNext();
            controller.newSR.Current_Workaround__c = 'test';
            controller.issueBugNext();
            controller.issueBugNext();

            controller.issueBugBack();
            controller.issueBugBack();
            controller.issueBugBack();
            controller.issueBugBack();
            controller.issueBugBack();
            controller.issueBugBack();
            controller.issueBugBack();

            //Bug (short)walkthrough
            controller.selectedType = 'Bug';
            controller.choseType();
            controller.issueBugBack();      

            //Enhancement walkthrough
            controller.selectedType = 'Enhancement';
            controller.choseType();
            controller.enhancementNext();
            controller.newSR.Subject__c  = 'test';
            controller.enhancementNext();
            controller.enhancementNext();
            controller.newSR.Issue__c = 'test';
            controller.enhancementNext();
            controller.enhancementNext();
            controller.newSR.Desired_State__c = 'test';
            controller.enhancementNext();
            controller.enhancementNext();

            controller.enhancementBack();
            controller.enhancementBack();
            controller.enhancementBack();
            controller.enhancementBack();
            controller.enhancementBack();

            //Data Upload Request walkthrough
            controller.selectedType = 'Data Upload Request';
            controller.choseType();
            controller.dataNext();
            controller.newSR.Subject__c = 'test';
            controller.dataNext();
            controller.dataNext();
            controller.newSR.Issue__c = 'test';
            controller.dataNext();
            controller.dataNext();          

            controller.dataBack();
            controller.dataBack();
            controller.dataBack();
            controller.dataBack();

        Test.stopTest();
    }

    /** 
    * @description testHappyPath2 - 
    */  
    static testmethod void testHappyPath2() {
        Support_Request__c sr = new Support_Request__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();
            SupportRequestWizardController controller = new SupportRequestWizardController(stdController);
            //Issue/Bug walkthrough to insert
            controller.selectedType = 'Issue';
            controller.choseType();
            controller.newSR.Subject__c  = 'test';
            controller.issueBugNext();
            controller.newSR.Issue__c = 'test';
            controller.issueBugNext();
            controller.newSR.Initial_Occurence__c  = Date.today();
            controller.issueBugNext();
            controller.newSR.Steps_to_Reproduce__c = 'test';
            controller.issueBugNext();
            controller.newSR.Current_Workaround__c = 'test';
            controller.issueBugNext();
            controller.submitSR();
            controller.newSR.Example_Record_Link__c = 'test';
            controller.submitSR();
            controller.pageContinue();

        Test.stopTest();
    }

    /** 
    * @description testHappyPath3 - 
    */  
    static testmethod void testHappyPath3() {
        Support_Request__c sr = new Support_Request__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();
            SupportRequestWizardController controller = new SupportRequestWizardController(stdController);
            //Enhacement walkthrough to insert
            controller.selectedType = 'Enhancement';
            controller.choseType();
            controller.newSR.Subject__c = 'test';
            controller.enhancementNext();
            controller.newSR.Issue__c = 'test';
            controller.enhancementNext();
            controller.newSR.Desired_State__c = 'test';
            controller.enhancementNext();
            controller.submitSR();
            controller.newSR.Example_Record_Link__c = 'test';
            controller.submitSR();
            controller.pageContinue();

        Test.stopTest();
    }

    /** 
    * @description testHappyPath4 - 
    */  
    static testmethod void testHappyPath4() {
        Support_Request__c sr = new Support_Request__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();
            SupportRequestWizardController controller = new SupportRequestWizardController(stdController);
            //Data Upload Request walkthrough
            controller.selectedType = 'Data Upload Request';
            controller.choseType();
            controller.newSR.Subject__c = 'test';
            controller.dataNext();
            controller.newSR.Issue__c = 'test';
            controller.dataNext();

            controller.newfile.VersionData = Blob.valueOf('populated');
            controller.newfile.PathOnClient = 'populated';
            
            controller.submitSR();
            controller.pageContinue();

        Test.stopTest();
    }

    /** 
    * @description testHappyPathRedirect1 - 
    */  
    static testmethod void testHappyPathRedirect1() {
        Support_Request__c sr = new Support_Request__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();
            SupportRequestRedirectController controller = new SupportRequestRedirectController(stdController);
            apexpages.currentpage().getparameters().put('RecordType',Schema.SObjectType.Support_Request__c.getRecordTypeInfosByName().get('Salesforce Support Request').getRecordTypeId());
            controller.redirect();
        Test.stopTest();
    }

    /** 
    * @description testHappyPathRedirect2 - 
    */  
    static testmethod void testHappyPathRedirect2() {
        Support_Request__c sr = new Support_Request__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();
            SupportRequestRedirectController controller = new SupportRequestRedirectController(stdController);
            controller.redirect();
        Test.stopTest();
    }

    /** 
    * @description testHappyPathRedirect3 - 
    */  
    static testmethod void testHappyPathRedirect3() {
        Support_Request__c sr = new Support_Request__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();
            SupportRequestRedirectController controller = new SupportRequestRedirectController(stdController);
            apexpages.currentpage().getparameters().put('RecordType',Schema.SObjectType.Support_Request__c.getRecordTypeInfosByName().get('IT Support Request').getRecordTypeId());
            controller.redirect();
        Test.stopTest();
    }


}