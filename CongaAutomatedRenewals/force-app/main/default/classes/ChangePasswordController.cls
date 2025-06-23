/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description ChangePasswordController - An apex page controller that exposes the change password functionality
*/
public class ChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        
    

	/**
	* @description changePassword - 
	*/
    public PageReference changePassword(){
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);    
    }
    
	/**
	* @description ChangePasswordController - 
	*/
    public ChangePasswordController(){

    }


}