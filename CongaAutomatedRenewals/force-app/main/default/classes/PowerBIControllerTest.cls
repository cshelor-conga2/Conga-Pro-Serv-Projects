/**
* @author CoE, ERedding, https://powerbi.microsoft.com/en-us/blog/embedding-a-power-bi-report-into-salesforce/
* @author OAuth controller borrowed heavily from http://blog.deadlypenguin.com/blog/2016/07/05/oauth-flow-for-service-users-in-salesforce/
* @date 20200908
* @description PowerBIControllerTest - Test class for the PowerBIController class
*/
@isTest
public class PowerBIControllerTest {
	
    // POWERBI OAUTH SETTINGS TEST METADATA
    public static PowerBI_OAuth_Settings__mdt PowerBIOAuthSettingsTestMeta {
    get {
            Map<String, Object> metaFieldValues = new Map<String, Object>{
            	'Name' => 'PowerBI OAuth Settings',
            	'Client_Id__c' => 'clientId',
            	'Client_Secret__c' => 'clientSecret',
            	'Authorization_URL__c' => 'https://login.windows.net/common/oauth2/authorize',
            	'Access_Token_URL__c' => 'https://login.microsoftonline.com/common/oauth2/token',
            	'Resource_URI__c' => 'https://analysis.windows.net/powerbi/api'
            };
            PowerBI_OAuth_Settings__mdt customTestMeta = (PowerBI_OAuth_Settings__mdt)TestingUtility.createTestMeta('PowerBI_OAuth_Settings__mdt', metaFieldValues);
            PowerBIOAuthSettingsTestMeta =  customTestMeta;
        return PowerBIOAuthSettingsTestMeta;
    } set; }


	public static testMethod void createController(){		
		PowerBIController controller = new PowerBIController();

		Test.startTest();

		System.assertNotEquals(controller, null);
		System.assertNotEquals(controller.PBIAccess_token, null);
		System.assertNotEquals(controller.PBIRefresh_token, null);
		System.assertNotEquals(controller.PBIExpires_on, null);
		System.assertEquals(controller.getHasToken(), false);

		controller.PBIAccess_token =  'testToken';
		System.assertEquals(controller.getHasToken(), false);

		Test.stopTest();
	} 

	public static testMethod void getValidateResultReturnsNotNull(){
		PowerBIController pbicontroller = new PowerBIController();

		pbicontroller.ValidateResult = 'testResult';
		System.assertEquals('testResult', pbicontroller.getValidateResult());		
	}
	
	public static testMethod void getAuthURLReturnSuccess(){
		PowerBIController controller = new PowerBIController();

		Test.setCurrentPage(Page.PBIReportTemplate);
		String authUrl = controller.getAuthUrl();
		
		System.assertEquals(authUrl.contains('https://login.windows.net/common/oauth2/authorize?'), true);
	}
	
	public static testMethod void redirectOnCallbackCreatesCookies(){
		PowerBIController controller = new PowerBIController();

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new PBIReportHTTPResponseMock());
		
		PowerBIControllerTest.getAuthURLReturnSuccess();
		PageReference pageRef = new PageReference('https://c.eu11.visual.force.com/apex/Report?code=testCode');
		Test.setCurrentPage(pageRef);
		controller.IsCallback = true;

		PageReference ref = controller.redirectOnCallback(pageRef);
		
		String accessCookie = controller.PBIAccess_token;
		String refreshCookie =  controller.PBIRefresh_token;
		
		System.assertEquals('accessCookieToken',accessCookie);
		System.assertEquals('refreshCookieToken',refreshCookie);

		Test.stopTest();
	}

    public static testMethod void refreshToken(){
    	PowerBIController controller = new PowerBIController();

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new PBIReportHTTPResponseMock());
		
		PowerBIControllerTest.getAuthURLReturnSuccess();
		PageReference pageRef = new PageReference('https://c.eu11.visual.force.com/apex/Report?code=testCode');
		Test.setCurrentPage(pageRef);
		controller.IsCallback = true;

		controller.refreshAccessToken(pageRef);
		
		String accessCookie = controller.PBIAccess_token;
		String refreshCookie =  controller.PBIRefresh_token;
		
		System.assertEquals('accessCookieToken', accessCookie);
		System.assertEquals('refreshCookieToken', refreshCookie);
		Test.stopTest();
	}

    /**
    * @description PBIReportHTTPResponseMock - HTTP Mock class for testing the PowerBIController controller
    */
    public class PBIReportHTTPResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            //////// BUILD JSON MOCK RESPONSE BODY ////////
		    String body = '{';
		    		body += '"token_type":"Bearer",';
			   		body += '"scope":"Content.Create Dashboard.Read.All Data.Alter_Any Dataset.Read.All Dataset.ReadWrite.All Group.Read Group.Read.All Metadata.View_Any Report.Read.All",';
				    body += '"expires_in":"3599",';
				    body += '"ext_expires_in":"0",';
				    body += '"expires_on":"1482242395",';
				    body += '"not_before":"1482238495",';
				    body += '"resource":"https://analysis.windows.net/powerbi/api",';
				    body += '"access_token":"accessCookieToken",';
				    body += '"refresh_token":"refreshCookieToken",';
					body += '"id_token":"idToken"';
					body += '}';

            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }


}