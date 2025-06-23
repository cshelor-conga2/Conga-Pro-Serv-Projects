/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description LightningForgotPasswordController - 
*/
global class LightningLoginFormController {

    /**
    * @description LightningLoginFormController - Constructor
    */
    public LightningLoginFormController() {
    }

    /**
    * @description login - 
    * @param String username
    * @param String password
    * @param String startUrl
    * @return String
    */
    @AuraEnabled
    public static String login(String username, String password, String startUrl) {
        try{
            ApexPages.PageReference lgn = Site.login(username, password, startUrl);
            aura.redirect(lgn);
            return null;
        }
        catch (Exception ex) {
            return ex.getMessage();            
        }
    }

    /**
    * @description getIsUsernamePasswordEnabled - 
    * @return Boolean
    */ 
    @AuraEnabled
    public static Boolean getIsUsernamePasswordEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getUsernamePasswordEnabled();
    }

    /**
    * @description getIsSelfRegistrationEnabled - 
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean getIsSelfRegistrationEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getSelfRegistrationEnabled();
    }

    /**
    * @description getSelfRegistrationUrl - 
    * @return String
    */
    @AuraEnabled
    public static String getSelfRegistrationUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        if(authConfig.getSelfRegistrationEnabled()) {
            return authConfig.getSelfRegistrationUrl();
        }
        return null;
    }

    /**
    * @description getForgotPasswordUrl - 
    * @return String
    */
    @AuraEnabled
    public static String getForgotPasswordUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return Test.isRunningTest() ? 'Test' : authConfig.getForgotPasswordUrl();
    }
    
    /**
    * @description getAuthConfig - 
    * @return Auth.AuthConfiguration
    */
    @testVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
    }

    /**
    * @description setExperienceId - 
    * @param String expId
    * @return String
    */
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try{
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