/**
* @author ECS, ERedding
* @date 20190515
* @version 1.00
* @description ForgotPasswordControllerTest  - Test class for the ForgotPasswordController class
*/
@isTest
public with sharing class ForgotPasswordControllerTest {

	/**
    * @description testForgotPasswordController
    */
  	 public static testMethod void testForgotPasswordController(){
    	// Instantiate a new controller with all parameters in the page
    	ForgotPasswordController controller = new ForgotPasswordController();
    	controller.username = 'test@salesforce.com';
    	System.assertEquals(controller.forgotPassword(),null);
    }


}