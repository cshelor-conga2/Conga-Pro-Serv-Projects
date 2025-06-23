/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description CommunitiesLandingController - An apex page controller that takes the user to the right start page based on credentials or lack thereof
*/
public with sharing class CommunitiesLandingController {
    
    /**
	* @description forwardToStartPage - Code we will invoke on page load.
	* @return PageReference
	*/
    public PageReference forwardToStartPage() {
        return Network.communitiesLanding();
    }
    
	/**
	* @description Constructor
	*/
    public CommunitiesLandingController() {

    }


}