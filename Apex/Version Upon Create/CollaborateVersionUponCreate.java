public class CollaborateVersionUponCreate {
    @future (callout=true)
    public static void createVersion(String document_id){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        tinderbox__TinderBox__c cs = tinderbox__TinderBox__c.getOrgDefaults();
        request.setEndpoint('https://' + cs.tinderbox__Company_URL__c + '/api/v2/proposals/' + document_id + '/versions?api_key=f1e2ae706ddb429257cfddc2c389b10263bd8540');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'Application/JSON');
        request.setHeader('Accept', 'Application/JSON');
        request.setBody('{"version": {"message": "New Version"}}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug(response.getBody());
        }
    }  
}