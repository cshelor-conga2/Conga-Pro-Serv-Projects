/**
* @author ECS, ERedding
* @date 20190603
* @version 1.00
* @description PopUpWindowControllerTest  - Test class for the PopUpWindowController class
*/
@isTest
public with sharing class PopUpWindowControllerTest {

	/**
	* @description setup - Test data setup method
	*/
	@testSetup
	public static void setup(){
		// CREATE TEST ACCOUNT
		Account testAccount = (Account)TestingUtility.createSObject('Account');
		insert testAccount;

		// CREATE TEST CONTACT
		Contact testContact = (Contact)TestingUtility.createSObject('Contact');
		insert testContact;	

		// CREATE TEST CASES
		Case testCase = (Case)TestingUtility.createSObject('Case');
        testCase.ContactId = testContact.Id;
        testCase.AccountId = testAccount.Id;
        testCase.Status = 'Working';
		insert testCase;
	}
	
	/**
	* @description testController - Test controller methods
	*/
	public static testMethod void testController() {
		// GET TEST CASE
		List<Case> testCases = [SELECT Id FROM Case];
		System.assert(testCases.size() == 1);

		PageReference vfPage = Page.PopUpWindowPage;
		vfPage.getParameters().put('cId', testCases[0].Id);
		Test.setCurrentPage(vfPage);

		ApexPages.StandardController sc = new ApexPages.StandardController(testCases[0]);
		PopUpWindowController ctrl = new PopUpWindowController();
		ctrl = new PopUpWindowController(sc);

		Test.startTest();

		Boolean status = PopUpWindowController.checkStatus(testCases[0].Id);
		System.assert(status);

		// UPDATE CASE AND CHECK FOR CORRECT DATA
		ctrl.updateStatus();
		testCases = [SELECT Id, Status FROM Case];
		System.assert(testCases[0].Status == 'On Hold');

		Test.stopTest();
	}


}