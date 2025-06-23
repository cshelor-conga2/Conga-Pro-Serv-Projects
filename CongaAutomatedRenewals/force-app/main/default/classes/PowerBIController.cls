/**
* @author CoE, ERedding, https://powerbi.microsoft.com/en-us/blog/embedding-a-power-bi-report-into-salesforce/
* @author OAuth controller borrowed heavily from http://blog.deadlypenguin.com/blog/2016/07/05/oauth-flow-for-service-users-in-salesforce/
* @date 20200908
* @description PowerBIController - Controller for visualforce embedded PowerBI Reports
*/
public class PowerBIController {
    public String AccessToken;
    public String RefreshToken;
    public String ExpiresOn;
    public String ValidateResult;    

    @TestVisible
    private Boolean IsCallback;

    // POWERBI OAUTH SETTINGS
    private PowerBI_OAuth_Settings__mdt OAuthSettings {
    get {
        if(OAuthSettings == null){
	    	if(Test.isRunningTest()){
	    		OAuthSettings = PowerBIControllerTest.PowerBIOAuthSettingsTestMeta;
	    	}
	    	else{
	    		OAuthSettings = [SELECT Access_Token_URL__c, Authorization_URL__c, Client_Id__c, Client_Secret__c, Resource_URI__c FROM PowerBI_OAuth_Settings__mdt LIMIT 1];
	    	}	
        }
        return OAuthSettings;
    } set; }


    public String PBIAccess_Token { 
    get {
        Cookie pbi_AccessToken = ApexPages.currentPage().getCookies().get('pbi_AccessToken');
        if(pbi_AccessToken == null)
            this.AccessToken = '';
        else
            this.AccessToken = pbi_AccessToken.getValue();
        
        return this.AccessToken;
    } set; }
        
    public String PBIRefresh_Token { 
    get {
        Cookie pbi_RefreshToken = ApexPages.currentPage().getCookies().get('pbi_RefreshToken');
        if(pbi_RefreshToken == null)
            this.RefreshToken = '';
        else
            this.RefreshToken = pbi_RefreshToken.getValue();
        
        return this.RefreshToken;
    } set; }
        
    public String PBIExpires_On { 
    get {
        Cookie pbi_ExpiresOn = ApexPages.currentPage().getCookies().get('pbi_ExpiresOn');
        if(pbi_ExpiresOn == null)
            this.ExpiresOn = '';
        else
            this.ExpiresOn = pbi_ExpiresOn.getValue();
        
        return this.ExpiresOn;
    } set; }

    /**
    * Generic constructor
    */
    public PowerBIController() {
    	this.IsCallback = ApexPages.currentPage().getParameters().containsKey('code');              
        if(OAuthSettings != null) {
            Cookie pbi_AccessToken = ApexPages.currentPage().getCookies().get('pbi_AccessToken');
            Cookie pbi_RefreshToken = ApexPages.currentPage().getCookies().get('pbi_RefreshToken');
            Cookie pbi_ExpiresOn = ApexPages.currentPage().getCookies().get('pbi_ExpiresOn');
         
         if(pbi_AccessToken == null)
             this.AccessToken = '';
         else
            this.AccessToken = pbi_AccessToken.getValue();
            
         if(pbi_RefreshToken == null)
             this.RefreshToken= '';
         else
            this.RefreshToken = pbi_RefreshToken.getValue();
            
         if(pbi_ExpiresOn == null)
             this.ExpiresOn = '';
         else
             this.ExpiresOn = pbi_ExpiresOn.getValue();
        }
    }

    public String getValidateResult(){
        return ValidateResult;
    }

    /**
    * If the access token is set
    *
    * @return If the access token is set
    */
    public Boolean getHasToken() {
          Boolean check;
         if(PBIaccess_token == null)
              check = false;
           else 
              check = PBIaccess_token.length()>0;
          return check;
    }


    /** The JSON result from a successful oauth call */
    public class OAuthResult {
        /** The access token */
        public String access_token {get; set;}

        /** The refresh token */
        public String refresh_token {get; set;}
        
        /** The token expiry date*/
        public String expires_on {get;set;}
    }

    /**
    * Validates the oauth code
    *
    * @param code The code to validate
    * @param redirect_uri The URL to redirect to after successful validation
    * @return The oauth result
    */
    public OAuthResult validateCode(String code, String redirect_uri) {
    	try{
	    	if(OAuthSettings != null){
		        String client_id = OAuthSettings.Client_Id__c;
		        String client_secret = OAuthSettings.Client_Secret__c;
		        String access_token_url = OAuthSettings.Access_Token_URL__c;
		        String resource_URI = OAuthSettings.Resource_URI__c;

		        List<String> urlParams = new List<String> {
		            'grant_type=authorization_code',
		            'code=' + EncodingUtil.urlEncode(code, 'UTF-8'),
		            'client_id=' + EncodingUtil.urlEncode(client_id, 'UTF-8'),
		            'client_secret=' + EncodingUtil.urlEncode(client_secret, 'UTF-8'),
		            'redirect_uri=' + EncodingUtil.urlEncode(redirect_uri, 'UTF-8')
		        };

		        Http h = new Http();
		        HttpRequest req = new HttpRequest();
		        req.setEndpoint(access_token_url);
		        req.setMethod('POST');
		        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		        req.setHeader('Accept', 'application/json');
		        String body = String.join(urlParams, '&');
		        req.setBody(body);

		        HttpResponse res = h.send(req);
		        validateResult = res.getBody();
		        return (OAuthResult)(JSON.deserialize(res.getBody(), OAuthResult.class));
	    	}
	    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'PowerBIController.validateCode: OAuth Metadata Settings could not be found.'));
	    }
	    catch(Exception ex){
	    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
	    }
    	return null;
    }
    
    /** 
    * Gets new access token through refresh token
    *
    * @param refreshToken The refresh token
    * @return The oauth result
    */
    public PageReference refreshAccessToken() {
        return refreshAccessToken(ApexPages.currentPage());
    }
    public PageReference refreshAccessToken(PageReference location){
    	try{
	        Cookie accessToken = new Cookie('pbi_AccessToken', '', null, 0, false, 'None; Secure');
	        Cookie expiresOn = new Cookie('pbi_ExpiresOn', '', null, 0, false, 'None; Secure');
	            
	        ApexPages.currentPage().setCookies(new Cookie[]{ accessToken, expiresOn }); 
	            
	        String client_id = OAuthSettings.Client_Id__c;
	        String client_secret = OAuthSettings.Client_Secret__c;
	        String resource_URI = OAuthSettings.Resource_URI__c;
	        String access_token_url = OAuthSettings.Access_Token_URL__c;        
	        String refreshToken = this.PBIrefresh_token;

	        List<String> urlParams = new List<String> {
	            'grant_type=refresh_token',
	            'refresh_token=' + EncodingUtil.urlEncode(refreshToken, 'UTF-8'),
	            'client_id=' + EncodingUtil.urlEncode(client_id, 'UTF-8'),
	            'client_secret=' + EncodingUtil.urlEncode(client_secret, 'UTF-8'),
	            'resource=' + EncodingUtil.urlEncode(resource_URI, 'UTF-8')
	        };
	        
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        req.setEndpoint(access_token_url);
	        req.setMethod('POST');
	        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
	        req.setHeader('Accept', 'application/json');
	        String body = String.join(urlParams, '&');
	        req.setBody(body);

	        HttpResponse res = h.send(req);

	        OAuthResult result = (OAuthResult)(JSON.deserialize(res.getBody(), OAuthResult.class));
	        
	        Cookie refreshTokenCookie = new Cookie('pbi_RefreshToken', result.refresh_token, null, -1, false, 'None; Secure');        
	        accessToken = new Cookie('pbi_AccessToken', result.access_token, null, -1, false, 'None; Secure');
	        expiresOn = new Cookie('pbi_ExpiresOn', result.expires_on, null, -1, false, 'None; Secure');
	        
	        ApexPages.currentPage().setCookies(new Cookie[]{accessToken, refreshTokenCookie, expiresOn});   
	        return location;
	    }
	    catch(Exception ex){
	    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
	    }
	    return null;
    }

    /**
    * Gets the authroization URL
    *
    * @return The authorization url
    */
    public String getAuthUrl() {
        Map<String, String> urlParams = new Map<String, String> {
            'client_id' => OAuthSettings.Client_Id__c,
            'redirect_uri' => getPageUrl(),
            'resource' => OAuthSettings.Resource_URI__c,
            'response_type' => 'code'
        };
        String auth_url = OAuthSettings.Authorization_URL__c;

        PageReference ref = new PageReference(auth_url);
        ref.getParameters().putAll(urlParams);

        return ref.getUrl();
    }

    /**
    * Gets the page url
    *
    * @return The page url
    */
    @testVisible
    private String getPageUrl() {
        String host = ApexPages.currentPage().getHeaders().get('Host');
        String path = ApexPages.currentPage().getUrl().split('\\?').get(0);

        return 'https://' + host + path;
    }

    /**
    * Validates the callback code and generates the access and refresh tokens
    *
    * @param location Where to redirect to after success
    * @return null to refresh the page
    */
    public PageReference redirectOnCallback() {
        return redirectOnCallback(null);
    }
    public PageReference redirectOnCallback(PageReference location) {
    	try{
	        if(this.IsCallback){
	            String code = ApexPages.currentPage().getParameters().get('code');
	            OAuthResult result = validateCode(code, this.getPageUrl());

	            if(result != null){        
		            //Store accesstoken in cookie
		            Cookie accessToken = new Cookie('pbi_AccessToken', result.access_token, null, -1, false, 'None; Secure');
		            Cookie refreshToken = new Cookie('pbi_RefreshToken', result.refresh_token, null, -1, false, 'None; Secure');
		            Cookie expiresOn = new Cookie('pbi_ExpiresOn', result.expires_on, null, -1, false, 'None; Secure');
		            
		            ApexPages.currentPage().setCookies(new Cookie[]{accessToken, refreshToken, expiresOn}); 
		            return location;
		        }
	        }
	    }
        catch(Exception ex){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
}