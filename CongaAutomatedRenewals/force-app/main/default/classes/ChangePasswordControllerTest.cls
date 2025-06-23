/**
* @author Conga Services, ERedding
* @date 20190513
* @version 1.00
* @description ChangePasswordControllerTest - Test class for the ChangePasswordController class
*/
@isTest
public with sharing class ChangePasswordControllerTest {

    /**
    * @description testChangePasswordController - Test the changePassword method
    */
    public static testMethod void testChangePasswordController() {

        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        
        System.assertEquals(controller.changePassword(), null);                           
    }


}