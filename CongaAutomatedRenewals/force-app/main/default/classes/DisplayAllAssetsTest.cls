/**
* @author ECS, ERedding
* @date 20190516
* @version 1.00
* @description DisplayAllAssetsTest  - Test class for the DisplayAllAssets class
*/
@isTest
public with sharing class DisplayAllAssetsTest {
	
	/**
	* @description controllerTest - Test DisplayAllAssets controller initialization
	*/
	public static testMethod void controllerTest() {
		// CREATE TEST ACCOUNT
		Account testAccount = (Account)TestingUtility.createSObject('Account', true, 1); 
		insert testAccount;

		// CREATE TEST CASE
		Case testCase = (Case)TestingUtility.createSObject('Case', true, 1);
		testCase.AccountId = testAccount.Id;
		insert testCase;

		Test.startTest();

		ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
		ApexPages.currentPage().getParameters().put('id', testCase.Id);
		DisplayAllAssets cn = new DisplayAllAssets(sc);
		System.assert(cn.AccountInfo != null);
		System.assert(cn.AccountInfo.Id != null);

		Test.stopTest();
	}


}