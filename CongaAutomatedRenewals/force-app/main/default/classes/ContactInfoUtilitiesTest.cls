/**
* @author CongaServices
* @date 20180402
* @version 1.00
* @description ContactInfoUtilitiesTest - Test class for the ContactInfoUtilities class
*/
@isTest
public with sharing class ContactInfoUtilitiesTest{

	/**
	* @description test_getCurrentUser - Test Method
	*/
	static testmethod void test_getCurrentUser(){
		// Implement test code
		User testUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
		User user = ContactInfoUtilities.getUser();
		System.assert(user != null);
	}


}