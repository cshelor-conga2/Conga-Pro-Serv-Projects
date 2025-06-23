/**
* @author MMarkam
* @date 20100714
* @version 1.00
* @description SiteLoginController - An apex page controller that exposes the site login functionality
*/
global class SiteLoginController {
    global String username {get; set;}
    global String password {get; set;}

    /**
    * @description SiteLoginController - Constructor
    */
    global SiteLoginController (){

    }
    
    /**
    * @description login - 
    * @return PageReference
    */
    global PageReference login() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        return Site.login(username, password, startUrl);
    }


}