/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description CommunitiesSelfRegControllerTest - Test class for the CommunitiesSelfRegController class
*/
@isTest
global with sharing class CommunitiesSelfRegControllerTest {

    /**
    * @description testCommunitiesSelfRegController
    */
    global testmethod static void testCommunitiesSelfRegController() {
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        controller.firstName = 'FirstName';
        controller.lastName = 'LastName';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);    
        
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null);  
    }


}