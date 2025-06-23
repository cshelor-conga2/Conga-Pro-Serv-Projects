/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description CommunitiesLandingController - Test class for the CommunitiesLandingController class
*/
@isTest
public with sharing class CommunitiesLandingControllerTest {

    /**
    * @description testCommunitiesLandingController
    */
    public testmethod static void testCommunitiesLandingController() {

        // Instantiate a new controller with all parameters in the page
        CommunitiesLandingController controller = new CommunitiesLandingController();
        PageReference pageRef = controller.forwardToStartPage();

        //PageRef is either null or an empty object in test context
        if(pageRef != null){
            String url = pageRef.getUrl();
            if(url != null){
                System.assertEquals(true, String.isEmpty(url));
                //show up in perforce
            }
        }
    }


}