/**
* @author Conga Services, ERedding
* @date 20171201
* @description Test class for the ChattoPhoneCaseController class
*/
@isTest
public with sharing class ChattoPhoneCaseControllerTest {

     /**
     * @description Test Happy Path of code
     */
     public static testMethod void ChattoPhoneCaseControllerTest() {
          // CREATE INITIAL CASE
          Case initialCase = new Case(Subject = 'Test Subject', Status = 'New');
          insert initialCase;

          // INITIALIZE CONTROLLER, TEST FOR CORRECT CLASS VARIABLES
          Test.setCurrentPage(Page.ChattoPhoneCasePage);
          Test.StartTest();

          ApexPages.StandardController stdController = new ApexPages.StandardController(initialCase);
          ChattoPhoneCaseController controller = new ChattoPhoneCaseController(stdController);
          System.assert(controller.InitialCase != null, 'Initial Case not loaded');
          System.assert(controller.DummyCase != null, 'Dummy Case not initialized');

          // SET STATUS, TEST CREATION OF A CHAT TO PHONE CASE
          controller.DummyCase.Status = 'Working';
          controller.CreateChatToPhoneCase();
          System.assert(controller.NewCase != null, 'New case not created');          
          List<Case> newCase = [SELECT Id, Status FROM Case WHERE Id = :controller.NewCase.Id];
          System.assert(newCase.size() == 1, 'New Case not found');
          System.assert(newCase[0].Status == 'Working', 'New case has an incorrect status');

          //CHECK INITIAL CASE
          List<Case> initialCaseWithParent = [SELECT Id, ParentId FROM Case WHERE ParentId = :controller.NewCase.Id];
          System.assert(initialCaseWithParent.size() == 1, 'Intial Case parent not correct');
          System.assert(initialCaseWithParent[0].ParentId == controller.NewCase.Id, 'Intial Case parent not correct');
          System.assert(ApexPages.hasMessages() == false, 'Page error thrown'); // NO ERRORS SHOULD BE DISPLAYED
          
          Test.StopTest();
     }

     /**
     * @description Test Exception Handling
     */
     public static testMethod void ChattoPhoneCaseControllerTest_Exceptions() {
          // CREATE INITIAL CASE
          Case initialCase = new Case(Subject = 'Test Subject', Status = 'Closed');
          insert initialCase;

          // INITIALIZE CONTROLLER, TEST FOR CORRECT CLASS VARIABLES
          Test.setCurrentPage(Page.ChattoPhoneCasePage);
          Test.StartTest();

          ApexPages.StandardController stdController = new ApexPages.StandardController(initialCase);

          // TRY INITIALIZING WITH A NULL STANDARD CONTROLLER
          ChattoPhoneCaseController controllerTest1 = new ChattoPhoneCaseController(null);

          // INITIALIZE WITH A VALID STANDARD CONTROLLER BUT A CLOSED CASE
          ChattoPhoneCaseController controllerTest2 = new ChattoPhoneCaseController(stdController);

          System.assert(ApexPages.hasMessages(), 'Error not displayed to user and should have been.'); // ERROR SHOULD BE DISPLAYED TO USER

          Test.stopTest();
     }


}