@isTest
global class addFilesExtensionTestClass {

	//@testSetup
	public static testmethod void addFilesTest() {

		//Get Collab api settings
        Collaborate_API_Setting__mdt settings = addFilesExtension.APISettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.api_key__c));
        System.assert(String.isNotBlank(settings.api_endpoint__c));
       
        String api_key = settings.api_key__c;
        String endpoint = settings.api_endpoint__c;
        String api_endpoint = endpoint + '/medias?api_key=' + api_key;


		Test.setMock(HttpCalloutMock.class, new CollaborateCreateFileHTTPMock());

        Opportunity testOppty = new Opportunity();
        testOppty.Name = 'Test Collaborate Document';
        testOppty.StageName = 'Closed Won';
        testOppty.CloseDate = Date.newInstance(2019,12,25);
        insert testOppty; 

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
            );
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = testOppty.Id,
            ContentDocumentId = documents[0].Id,
            shareType = 'V'
            );
        insert cdl;

        Test.startTest();
       
        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Collaborate Document';
        testDoc.tinderbox__TinderBoxId__c = '1234567';
        testDoc.tinderbox__Opportunity__c = testOppty.Id;
        system.debug(testDoc.tinderbox__Opportunity__c);
        insert testDoc;
       
        Test.stopTest();
       

	}

	public static testmethod void addFilesErrorTest(){
        //Get Collab api settings
        Collaborate_API_Setting__mdt settings = addFilesExtension.APISettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.API_Key__c));
        System.assert(String.isNotBlank(settings.api_endpoint__c));
       
        String api_key = settings.api_key__c;
        String endpoint = settings.api_endpoint__c;
        String api_endpoint = endpoint + '/medias?api_key=' + api_key;
       
        Test.setMock(HttpCalloutMock.class, new CollaborateCreateFileErrorHTTPMock());
       
        Opportunity testOppty = new Opportunity();
        testOppty.Name = 'Test Collaborate Document';
        testOppty.StageName = 'Closed Won';
        testOppty.CloseDate = Date.newInstance(2019,12,25);
        insert testOppty; 

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
            );
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = testOppty.Id,
            ContentDocumentId = documents[0].Id,
            shareType = 'V'
            );
        insert cdl;

        Test.startTest();

        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Collaborate Document';
        testDoc.tinderbox__Template_Name__c = 'Test Collaborate Template';
        testDoc.tinderbox__TinderBoxId__c = '1234567';
        testDoc.tinderbox__Opportunity__c = testOppty.Id;
        system.debug(testDoc.tinderbox__TinderBoxId__c);
        system.debug(testDoc.tinderbox__Opportunity__c);
        insert testDoc;
       
        Test.stopTest();
       
    }
 
    global class CollaborateCreateFileHTTPMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');
 
            ////// BUILD RESPONSE BODY FOR HTTP 'POST' //////
            String body = '{"media":{';
                  body += '"id":790211,';
                  body += '"name":"API Test",';
                  body += '"document_file_name":"API_Test",';
                  body += '"document_content_type":"application/pdf",';
                  body += '"document_file_size":50648';
               body += '}';
            body += '}';
       
            res.setBody(body);
            res.setStatusCode(201);
            return res;
        }
    }
   
    public class CollaborateCreateFileErrorHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');
           
            String body = '{"test": {"document": "new document"}}';
           
            res.setBody(body);
            res.setStatusCode(404);
            return res;
        }
    }	
}