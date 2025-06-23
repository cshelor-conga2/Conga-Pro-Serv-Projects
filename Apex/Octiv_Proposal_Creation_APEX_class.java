// Creates a Collab doc using the API
// NOTE: You MUST set up the remote site settings in Salesforce to allow it to communicate with the desired endpoint

public class Collaborate_Proposal_Create_API {
    @future (callout=true)
    public static void makePostCallout(currentRecordId) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint("https://sheep.octiv.com/api/v2/proposals?api_key=1c8a8cfce177cc885dbb1f25abefaedd63196d5c");
        request.setMethod("POST");
		request.setHeader("Content-Type", "Application/JSON");
        request.setHeader("Accept", "Application/JSON");

        // setBody takes the json payload that defines document data
        request.setBody('{"squash_variables":"false","proposal":{"name":"Test Creating Through Apex, SF, and the API","description":"API Created","value":250000,"password":"","archived":0,"visibility":0,"template_id":"33204","variable_data":{"var":"value"},"ext_integration_id":"' + currentRecordId + '","workgroup_ids":[],"metadata_template_id":"","metadata_field_values":{"metadata_field_id":"my_value","metadata_field_name":"my_value"}}}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            System.debug("The status code returned was not expected: " +
                response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug(response.getBody());
        }
    }  
}