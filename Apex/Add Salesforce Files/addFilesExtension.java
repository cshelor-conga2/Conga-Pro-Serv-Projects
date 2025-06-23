/**
* @author Chris Shelor
* @description Version 1: extends the Collaborate/Salesforce integration to allow the latest File on the launching record to be
*       added to the document as an Attachment
*   To be added in Verson 2: ability to attach all Files and to choose whether they get created
*       as embedded pages or as attachments
**/

public class addFilesExtension {

   @testVisible
    private static Collaborate_API_Setting__mdt APISettings {
    get {
        if(APISettings == null){
            List<Collaborate_API_Setting__mdt> settings = [select api_key__c, api_endpoint__c from Collaborate_API_Setting__mdt LIMIT 1];
            if(!settings.isEmpty()){
                APISettings = settings[0];
            }
        }
        return APISettings;
    } set; } 

    @future (callout=true)

/* 
    Main function:
    1) Queries the latest SF File on the launching object (queryFile function)
    2) Creates the Content in Collaborate (createMedia function)
    3) Parses the HTTP response to get the Content Id (parseJSON function)
    4) Attaches the created Content to the created document (attachMedia function)
*/
    public static void addFiles(Id opptyId, String documentId) {
        String jsonResponse;
        String collabFileId;
        List<String> fileData;

        fileData = queryFile(opptyId);

        jsonResponse = createMedia(fileData[0],fileData[1]);

        collabFileId = parseJSON(jsonResponse);

        attachMedia(collabFileId, documentId);

    } 

/*
    Queries the ContentDocumentLink and ContentVersion objects to get the base64 encoded SF File body and the SF File title
*/
    public static List<String> queryFile(Id opptyId) {

        ContentDocumentLink file = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :opptyId ORDER BY ContentDocument.LastModifiedDate DESC LIMIT 1];
        
        String salesforceFileId = file.ContentDocumentId;

        ContentVersion fileBody = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :salesforceFileId AND IsLatest = true];

        String base64Body = EncodingUtil.base64Encode(fileBody.VersionData);
        String title = fileBody.Title;

        List<String> returnValues = new List<String>();

        returnValues.add(base64Body);
        returnValues.add(title);

        return(returnValues);
    }

/*
    Creates the HTTP call to create the file in the Collaborate Content library
*/
    public static String createMedia(String base64Body, String title){
        String fileId;
        String jsonResponse;

        Http http = new Http();
        HttpRequest mediaRequest = new HttpRequest();
//        tinderbox__TinderBox__c cs = tinderbox__TinderBox__c.getOrgDefaults();

        String api_key = APISettings.api_key__c;
        String system_endpoint = APISettings.api_endpoint__c;
        String api_endpoint = system_endpoint + '/medias?api_key=' + api_key;

        //POST base64 encoded string as a new file
        mediaRequest.setEndpoint(api_endpoint);

        System.debug(mediaRequest.getEndpoint());

        mediaRequest.setMethod('POST');
        mediaRequest.setHeader('Content-Type', 'Application/JSON');

        String body = '{"media": {"name": "' + title + '","document": "' + base64Body + '"}}';

        System.debug(body);

        mediaRequest.setBody(body);

        HttpResponse mediaResponse = http.send(mediaRequest);

        if (mediaResponse.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' +
                mediaResponse.getStatusCode() + ' ' + mediaResponse.getStatus());
        } else {
            jsonResponse = mediaResponse.getBody();
            System.debug(jsonResponse);
        }
        return jsonResponse;
        
    }

/*
    Creates the HTTP call to attach the file to the document that was just created
*/
    
    public static void attachMedia(string collabFileId, string documentId) {
        String jsonResponse;
        Http http = new Http();

        HttpRequest mediaRequest = new HttpRequest();
       // tinderbox__TinderBox__c cs = tinderbox__TinderBox__c.getOrgDefaults();

        String api_key = APISettings.api_key__c;
        String system_endpoint = APISettings.api_endpoint__c;
        String api_endpoint = system_endpoint + '/proposals/' + documentId + '/attachments?api_key=' + api_key;

        //POST base64 encoded string as a new file
        mediaRequest.setEndpoint(api_endpoint);

        System.debug(mediaRequest.getEndpoint());

        mediaRequest.setMethod('POST');
        mediaRequest.setHeader('Content-Type', 'Application/JSON');

        string body = '{"attachment": {"media_id": "' + collabFileId + '"}}';

        System.debug(body);

        mediaRequest.setBody(body);

        HttpResponse mediaResponse = http.send(mediaRequest);

        if (mediaResponse.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                mediaResponse.getStatusCode() + ' ' + mediaResponse.getStatus());
        } else {
            jsonResponse = mediaResponse.getBody();
        }
        
    }

/*
    Parses the JSON that is returned from the HTTP call to create the file as Collaborate Content
*/
    public static String parseJSON(String jsonString) {
        Integer next = 0;
        String fileId;

        JSONParser parser = JSON.createParser(jsonString);

        while (parser.nextToken() != null && next == 0) {
            if (parser.getText() == 'id') {
                parser.NextToken();
                fileId = parser.getText();
                next = 1;
            }
        }
        
        return fileId;
    }

}