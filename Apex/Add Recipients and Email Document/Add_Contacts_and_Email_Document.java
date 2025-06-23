/**
* @author Neal Hennessy
* @Description Custom functionality to add contacts and email Collaborate documents from the 401k custom object
*/

public class Collaborate401kExtension {

    @testVisible
    private static Collaborate_API_Setting__mdt AutoAddRecipientSettings {
    get {
        if(AutoAddRecipientSettings == null){
            List<Collaborate_API_Setting__mdt> settings = [select api_key__c, collaborate_api_endpoint__c from Collaborate_API_Setting__mdt LIMIT 1];
            if(!settings.isEmpty()){
                AutoAddRecipientSettings = settings[0];
            }
        }
        return AutoAddRecipientSettings;
    } set; }

    @future(callout=true)

    //method to find qualifying contacts and add them to the newly created 401k document
    public static void autoAdd401kRecipients(string proposalID, string templateName, string X401k_id) {
        
        
        String api_key = AutoAddRecipientSettings.api_key__c;
        string endpoint = AutoAddRecipientSettings.collaborate_api_endpoint__c;
        String api_endpoint = endpoint + proposalID + '/recipients?api_key=' + api_key;
        //list to store added recipients
        List<Contact> addedRecipients = new List<Contact>();
        
        //check for appropriate template name
        if(templateName == '401k Welcome Kit'){
            //query for qualifying contacts
            for (Contact c : [select FirstName, LastName, Email from Contact where X401k__c = :X401k_id
            and X401k_Welcome_Kit_Recipient__c = true and Received_Conga_401k_Welcome_Kit__c = false]){
                
                // Http request to add recipients
                Http http = new Http();
                HttpRequest addRecipients = new HttpRequest();
                addRecipients.setEndpoint(api_endpoint);
                addRecipients.setMethod('POST');
                addRecipients.setHeader('Content-Type', 'Application/JSON');
                
                // Build JSON body for recipient
                String recipientBody = '{"recipient": {"first_name": "' + c.firstName + '" ,"last_name": "' + c.lastName + '"';
                       recipientBody += ' ,"email_address": "' + c.email + '"';
                       recipientBody += ' ,"signer": false';
                       recipientBody += '}}';
                addRecipients.setBody(recipientBody);
                
                HttpResponse recipientResponse = http.send(addRecipients);
                
                
                
                if (recipientResponse.getStatusCode() != 200 & recipientResponse.getStatusCode() != 201 & recipientResponse.getStatusCode() != 202){
                    String errorMessage = 'The status code returned was not expected: ' + recipientResponse.getStatusCode() + ' ' + recipientResponse.getStatus();
                    system.debug(errorMessage);
                }
                else{
                
                    // add recipient to list if successfully added
                    addedRecipients.add(c);
                    system.debug('Recipient added' + addedRecipients);
                }
            }
            
            //update added recipients contact records as having received the welcome kit
            for (Contact c : addedRecipients){
                
                c.Received_Conga_401k_Welcome_Kit__c = true;
                update c;
            }
           
        }
    }
}