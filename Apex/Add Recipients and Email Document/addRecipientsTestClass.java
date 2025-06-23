@isTest
global class Collaborate401kExtensionTest {
 
    @testSetup
    public static void setup(){
        Contact test1 = New Contact();
        test1.FirstName = 'Test1';
        test1.LastName = 'Contact1';
        test1.Email = 'testcontact1@mailinator.com';
        test1.Received_Conga_401k_Welcome_Kit__c = false;
        test1.Contact_Type__c = '401(K) Employee';
        insert test1;
    }
 
    public static testmethod void autoAdd401kRecipientsTest(){
        //Get Collab api settings
        Collaborate_API_Setting__mdt settings = Collaborate401kExtension.AutoAddRecipientSettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.API_Key__c));
        System.assert(String.isNotBlank(settings.collaborate_api_endpoint__c));
       
        String api_key = settings.api_key__c;
        String endpoint = settings.collaborate_api_endpoint__c;
        String api_endpoint = endpoint + '123456/recipients?api_key=' + api_key;
       
        Test.setMock(HttpCalloutMock.class, new CollaborateAddRecipientHTTPMock());
       
        Test.startTest();
       
        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Collaborate Document';
        testDoc.tinderbox__Template_Name__c = '401(K) Welcome Kit';
        testDoc.tinderbox__TinderBoxId__c = '123456';
        insert testDoc;
       
        Test.stopTest();
       
        List<Contact> testContacts = [select FirstName, LastName, Email from Contact where Received_Conga_401k_Welcome_Kit__c = true];
        System.assert(testContacts.isEmpty() == false);
    }
   
    public static testmethod void autoAdd401kRecipientsErrorTest(){
        //Get Collab api settings
        Collaborate_API_Setting__mdt settings = Collaborate401kExtension.AutoAddRecipientSettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.API_Key__c));
        System.assert(String.isNotBlank(settings.collaborate_api_endpoint__c));
       
        String api_key = settings.api_key__c;
        String endpoint = settings.collaborate_api_endpoint__c;
        String api_endpoint = endpoint + '123456/recipients?api_key=' + api_key;
        String expected_api_endpoint = 'https://thepayrollcompany-sandbox2.octiv.com/api/v2/proposals/123456/recipients?api_key=3f419b9fd9332a0fd3f85f03236859bde426a0b9';
        System.assertEquals(api_endpoint,expected_api_endpoint, 'The endpoint is wrong');
       
        Test.setMock(HttpCalloutMock.class, new CollaborateErrorHTTPMock());
       
        Test.startTest();
       
        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Collaborate Document';
        testDoc.tinderbox__Template_Name__c = '401k Welcome Kit';
        testDoc.tinderbox__TinderBoxId__c = '123456';
        insert testDoc;
       
        Test.stopTest();
       
        List<Contact> testContacts = [select FirstName, LastName, Email from Contact where Received_Conga_401k_Welcome_Kit__c = true];
        System.assert(testContacts.isEmpty() == true);
    }
 
    global class CollaborateAddRecipientHTTPMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');
 
            ////// BUILD RESPONSE BODY FOR HTTP 'POST' //////
            String body = '{"recipient":{';
                  body += '"type":"proposal/recipient",';
                  body += '"id":1442085,';
                  body += '"first_name":"Test1",';
                  body += '"last_name":"Contact1",';
                  body += '"email_address":"test.user@mailinator.com",';
                  body += '"signer":true,';
                  body += '"signer_position":1,';
                  body += '"email_id":null,';
                  body += '"status_message":"Waiting on email status",';
                  body += '"variables":{';
                     body += '"recipient_first_name":"Test1",';
                     body += '"recipient_last_name":"Contact1",';
                     body += '"recipient_name":"Test1 Contact1",';
                     body += '"recipient_email_address":"test.user@getconga.com",';
                     body += '"recipient_proposal_url":"https://getconga-sandbox.octiv.com/view/3812747/recipient/57fed5ad-f7eb-4462-bf11-44b7881512c0",';
                     body += '"recipient_proposal_link":"<a href=\'https://getconga-sandbox.octiv.com/view/3812747/recipient/57fed5ad-f7eb-4462-bf11-44b7881512c0\'>https://getconga-sandbox.octiv.com/view/3812747/recipient/57fed5ad-f7eb-4462-bf11-44b7881512c0</a>"';
                  body += '},';
                  body += '"current_signer":false,';
                  body += '"uuid":"57fed5ad-f7eb-4462-bf11-44b7881512c0",';
                  body += '"name":"Test User",';
                  body += '"document":{"id":3812747,"type":"document"},';
                  body += '"avatar_url":null,';
                  body += '"add_recipients":false,';
                  body += '"add_collaborators":false,';
                  body += '"email_template":"Hello {{recipient_first_name}},Below is a link to this week\'s status report, updating you on the status of your Conga Professional Services project. Please let me know what questions you may have! Thank you, {{proposal_owner}} {{proposal_owner_email}}",';
                  body += '"esignature_embed_response":"Document is pending signatures from other recipients.",';
                  body += '"accepted":null,';
                  body += '"post_acceptance_forms":false,';
                  body += '"preview_url":"/proposals/3812747/recipients/1442085/preview_email?pagemode=iframe",';
                  body += '"unique_document_url":"https://getconga-sandbox.octiv.com/view/3812747/recipient/57fed5ad-f7eb-4462-bf11-44b7881512c0",';
                  body += '"redliner":false,';
                  body += '"parent_recipient_id":null,';
                  body += '"deleted_at":null,';
                  body += '"user_id":406932';
               body += '}';
            body += '}';
       
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }
   
    public class CollaborateErrorHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');
           
            String body = '{"test": {"id": 1442085}}';
           
            res.setBody(body);
            res.setStatusCode(404);
            return res;
        }
    }
}