/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description LightningLoginFormControllerTest - Test class for the LightningLoginFormController class
*/
@isTest
public with sharing class LightningLoginFormControllerTest {

	/**
	* @description testLoginWithInvalidCredentials - 
	* @return void
	*/	
	static testmethod void testLoginWithInvalidCredentials() {
		System.assertEquals('Argument 1 cannot be null', LightningLoginFormController.login('testUser', 'fakepwd', null));
	}

	/**
	* @description lightningLoginFormControllerInstantiation - 
	*/	
	static testmethod void lightningLoginFormControllerInstantiation() {
		LightningLoginFormController controller = new LightningLoginFormController();
		System.assertNotEquals(controller, null);
		LightningLoginFormController.setExperienceId('TestId');
	}

	/**
	* @description lightningLoginFormControllerInstantiation - 
	*/	
	static testmethod void testGetForgotPasswordUrl() {
		String passwordURL = LightningLoginFormController.getForgotPasswordUrl();
		System.assertNotEquals(null, passwordURL);
	}

	/**
	* @description testIsUsernamePasswordEnabled - 
	* @return void
	*/
	static testmethod void testIsUsernamePasswordEnabled() {
		System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
	}

	/**
	* @description testIsSelfRegistrationEnabled - 
	* @return void
	*/	
	static testmethod void testIsSelfRegistrationEnabled() {
		System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
	}

	/**
	* @description testGetSelfRegistrationURL - 
	* @return void
	*/	
	static testmethod void testGetSelfRegistrationURL() {
		System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
	}

	/**
	* @description testAuthConfig - 
	* @return void
	*/	
	static testmethod void testAuthConfig() {
		Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
		System.assertNotEquals(null, authConfig);
	}


}