/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description CommunitiesLoginControllerTest - Test class for the CommunitiesLoginController class
*/
@isTest
global with sharing class CommunitiesLoginControllerTest {

    /**
    * @description testCommunitiesLoginController
    */
    global testmethod static void testCommunitiesLoginController() {
        CommunitiesLoginController controller = new CommunitiesLoginController();
        System.assertEquals(null, controller.forwardToAuthPage());   
    }


}