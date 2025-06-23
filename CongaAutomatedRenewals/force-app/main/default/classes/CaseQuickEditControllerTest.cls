/**
* @author ECS, ERedding
* @date 20190524
* @version 1.00
* @description CaseQuickEditControllerTest  - Test class for the CaseQuickEditController class
*/
@isTest
public with sharing class CaseQuickEditControllerTest {

    /**
    * @description testCaseQuickEditController - 
    */
    public static testMethod void testCaseQuickEditController() {
        // CREATE TEST CASE
        Case initialCase = new Case(Subject = 'Test Subject', Status = 'New');
        insert initialCase;

        Test.startTest();

        // Instantiate a new controller with all parameters in the page
        ApexPages.StandardController stdController = new ApexPages.StandardController(initialCase);
        CaseQuickEditController controller = new CaseQuickEditController(stdController);
        controller.backToCase();           
        
        Test.stopTest();

        System.assert(controller.CurrentCase != null);                           
    }


}