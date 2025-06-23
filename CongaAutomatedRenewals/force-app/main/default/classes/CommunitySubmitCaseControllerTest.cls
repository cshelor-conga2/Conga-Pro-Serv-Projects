/**
* @author ECS, ERedding
* @date 20200811
* @description CommunitySubmitCaseControllerTest - Test class for the CommunitySubmitCaseController class
*/
@isTest
public with sharing class CommunitySubmitCaseControllerTest {

	/**
	* @description testGetUserInfo - Test getUserInfo method
	*/
	public static testMethod void testGetUserInfo() {
		Test.startTest();

		User queriedUser = CommunitySubmitCaseController.getUserInfo(UserInfo.getUserId());

		Test.stopTest();

		System.assert(queriedUser != null);
		System.assert(queriedUser.Id == UserInfo.getUserId());
	}
	
	/**
	* @description testGetUserInfo_NotUserFound - Test getUserInfo method with a fake User Id
	*/
	public static testMethod void testGetUserInfo_NotUserFound() {
		Test.startTest();

		User queriedUser = CommunitySubmitCaseController.getUserInfo('0055000000ABCGHIJK');

		Test.stopTest();

		System.assert(queriedUser != null);
		System.assert(queriedUser.Id == '0055000000ABCGHIJK');
		System.assert(queriedUser.ContactId == null);
	}	
	
}