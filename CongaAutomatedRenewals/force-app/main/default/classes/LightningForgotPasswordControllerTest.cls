/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description LightningForgotPasswordControllerTest - Test class for the LightningForgotPasswordController class
*/
@isTest
public with sharing class LightningForgotPasswordControllerTest {

	/**
	* @description testLightningForgotPasswordControllerInvalidUserName - Verifies that ForgotPasswordController handles invalid usernames appropriately
	*/
	static testmethod void testLightningForgotPasswordControllerInvalidUserName() {
		System.assertEquals(LightningForgotPasswordController.forgotPassword('fakeUser', 'http://a.com'), Label.Site.invalid_email);
		System.assertEquals(LightningForgotPasswordController.forgotPassword(null, 'http://a.com'), Label.Site.invalid_email);
		System.assertEquals(LightningForgotPasswordController.forgotPassword('a', '/home/home.jsp'), Label.Site.invalid_email);
	}

	/**
	* @description testLightningForgotPasswordControllerWithNullCheckEmailRef - Verifies that null checkEmailRef url throws proper exception.
	*/
	static testmethod void testLightningForgotPasswordControllerWithNullCheckEmailRef() {
		System.assertEquals(LightningForgotPasswordController.forgotPassword('a', null), 'Argument 1 cannot be null');
		System.assertEquals(LightningForgotPasswordController.forgotPassword('a@salesforce.com', null), 'Argument 1 cannot be null');
	}

	/**
	* @description LightningForgotPasswordControllerInstantiation - Verifies that LightningForgotPasswordController object is instantiated correctly.
	*/
	static testmethod void LightningForgotPasswordControllerInstantiation() {
		LightningForgotPasswordController controller = new LightningForgotPasswordController();
		System.assertNotEquals(controller, null);
		LightningForgotPasswordController.setExperienceId('TestId');
	}


}