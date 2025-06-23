/**
* @author ECS, ERedding
* @date 20190524
* @version 1.00
* @description SiteLoginControllerTest - Test class for the SiteLoginController class
*/
@isTest
public with sharing class SiteLoginControllerTest {

    /**
    * @description testSiteLoginController - 
    */
    public static testmethod void testSiteLoginController() {

        Test.startTest();

        // Instantiate a new controller with all parameters in the page
        SiteLoginController controller = new SiteLoginController();
        controller.username = 'test@salesforce.com';
        controller.password = '123456';
        System.assertEquals(controller.login(), null);

        Test.stopTest();
    }


}