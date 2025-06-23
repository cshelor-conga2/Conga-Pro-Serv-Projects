/**
* @author ECS, ERedding
* @date 20190524
* @version 1.00
* @description SiteRegisterControllerTest - Test class for the SiteRegisterController class
*/
@isTest
public with sharing class SiteRegisterControllerTest {

    // Test method to bring this class's test coverage over the required 75%
    static testMethod void testRegistration() {
    	Test.startTest();

        SiteRegisterController controller = new SiteRegisterController();
        controller.username = 'test@force.com';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);    
        
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null);  

        Test.stopTest();
    }


}