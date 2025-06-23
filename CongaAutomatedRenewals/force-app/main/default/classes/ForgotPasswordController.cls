/**
* @author Michael Markham
* @date 20100714
* @version 1.00
* @description An apex page controller that exposes the site forgot password functionality
*/
public class ForgotPasswordController {
    public String username {get; set;}   
       
    /**
    * @description ForgotPasswordController - Constructor
    */
    public ForgotPasswordController(){
    }

    /**
    * @description forgotPassword
    * @return PageReference
    */
    public PageReference forgotPassword() {
        Boolean success = Site.forgotPassword(username);
        PageReference pr = Page.ForgotPasswordConfirm;
        pr.setRedirect(true);
        if(success){            
            return pr;
        }
        return null;
    }


}