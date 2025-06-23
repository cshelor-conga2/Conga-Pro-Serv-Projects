/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description LiveAgentUtilitiesTest - Test class for the LiveAgentUtilities class
*/
@isTest
public with sharing class LiveAgentUtilitiesTest {

	/**
	* @description test_getContactIdCurrentUser - 
	* @return void
	*/
	static testmethod void test_getContactIdCurrentUser() {
		// Implement test code
		User testUser = [SELECT ContactId, Name FROM User where Id =: UserInfo.getUserId()];
		Contact con = LiveAgentUtilities.getContact(testUser.ContactId);
		if(con != null){
			System.assertEquals(testUser.ContactId, con.Id);
		}
	}


}