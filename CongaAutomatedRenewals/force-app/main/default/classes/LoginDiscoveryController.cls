public class LoginDiscoveryController {
    public LoginDiscoveryController() {
        startUrl = ApexPages.currentPage().getParameters().get('startUrl');
    }
    
    public String email {get; set;}
    @TestVisible public String startUrl {get; private set;}
    public Boolean showError {get; private set;}
    
    public PageReference submit() {
        System.debug('email: ' + email);
        try {
            return new PartnerLoginDiscovery().login(email,startUrl,new Map<String,String>());
        }
        catch(Exception e) {
            showError = true;
            System.debug(e.getMessage() + '\r\n' + e.getStackTraceString());
            return null;
        }
    }
}