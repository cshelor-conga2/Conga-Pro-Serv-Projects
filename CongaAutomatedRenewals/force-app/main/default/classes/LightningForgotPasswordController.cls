/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description LightningForgotPasswordController - 
*/
global class LightningForgotPasswordController {

    /**
    * @description LightningForgotPasswordController - Constructor
    */
    public LightningForgotPasswordController() {
    }

    /**
    * @description forgotPassword - 
    * @param String username
    * @param String checkEmailUrl
    * @return String
    */
    @AuraEnabled
    public static String forgotPassword(String username, String checkEmailUrl) {
        try {
            Site.forgotPassword(username);
            ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
            if(!Site.isValidUsername(username)) {
                return Label.Site.invalid_email;
            }
            aura.redirect(checkEmailRef);
            return null;
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }

    /**
    * @description setExperienceId - 
    * @param String expId
    * @return String
    */
    @AuraEnabled
    global static String setExperienceId(String expId) {    
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);               
            }
            return null; 
        }
        catch (Exception ex) {
            return ex.getMessage();            
        }        
    }


}