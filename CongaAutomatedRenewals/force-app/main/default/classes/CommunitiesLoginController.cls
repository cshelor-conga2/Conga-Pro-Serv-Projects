/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description CommunitiesLoginController - An apex page controller that exposes the site login functionality
*/
global with sharing class CommunitiesLoginController {
	
	/**
	* @description Constructor
	*/
    global CommunitiesLoginController () {

    }
    
    /**
	* @description forwardToAuthPage - Code we will invoke on page load.
	* @return PageReference
	*/
    global PageReference forwardToAuthPage() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        String displayType = System.currentPageReference().getParameters().get('display');
        return Network.forwardToAuthPage(startUrl, displayType);
    }


}