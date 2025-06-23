public class addPagesUponCreate {
    @future (callout=true)
      
    public static void addPages(String quote_id, String document_id) {
        String api_key = '1c8a8cfce177cc885dbb1f25abefaedd63196d5c';

        // Map to hold the section name and ID values
        Map<String, String> sections = new Map<String, String>();
        List<SBQ_Quote_Line__c> productList = [SELECT Content_Id__c FROM SBQ_Quote_Line__c WHERE SBQ_Quote__c = :quote_id];
        String page_name;
        String page_body;
        System.debug(productList);
        List<String> contentIdList = new List<String>();
        for (Integer i = 0; i < productList.size(); i++) {
            contentIdList.add(productList[i].Content_ID__c);
        }
        System.debug(contentIdList);
        Http http = new Http();
        // First request to pull correct section ID to add the page
        HttpRequest request = new HttpRequest();
        tinderbox__TinderBox__c cs = tinderbox__TinderBox__c.getOrgDefaults();
        request.setEndpoint('https://' + cs.tinderbox__Company_URL__c + '/api/v2/proposals/' + document_id + '/sections?api_key=' + api_key);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'Application/JSON');
        request.setHeader('Accept', 'Application/JSON');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug(response.getBody());
            // JSON Parser to put section names + IDs into a Map
            JSONParser parser = JSON.createParser(response.getBody()); 
            while (parser.nextToken() != null) { 
                if (parser.getText() == 'id') {
                    parser.nextToken();
                    string section_id = parser.getText();
                    parser.nextToken();
                    parser.nextToken();
                    string section_name = parser.getText();
                    // Add section name and ID to Map created earlier
                    sections.put(section_name, section_id);
                }
            }
        }

        // Get the ID of the section we want to pages to be inserted in
        string content_section_id = sections.get('Repeatable');
        // Loop through the content IDs (that correspond with products on the Quote) to first retrieve content page body and name. 
        // using the second API call. Then add the pages to the document with a third API call
        for (Integer i = 0; i < contentIdList.size(); i++) { 
            Http http2 = new Http();
            HttpRequest request2 = new HttpRequest();
            tinderbox__TinderBox__c cs2 = tinderbox__TinderBox__c.getOrgDefaults();
            request2.setEndpoint('https://' + cs2.tinderbox__Company_URL__c + '/api/v2/contents/' + contentIdList[i] + '?api_key=' + api_key);
            request2.setMethod('GET');
            request2.setHeader('Content-Type', 'Application/JSON');
            request2.setHeader('Accept', 'Application/JSON');
            HttpResponse response2 = http.send(request2);
        // Parse the JSON response
            if (response2.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' +
                    response2.getStatusCode() + ' ' + response2.getStatus());
            } else {
                System.debug(response2.getBody());
                JSONParser parser2 = JSON.createParser(response2.getBody());
                while (parser2.nextToken() != null) {
                    if (parser2.getText() == 'name'){
                        parser2.nextToken();
                        page_name = parser2.getText(); 
                        parser2.nextToken();
                        parser2.nextToken();
                        page_body = parser2.getText();
                    }        
                }
            }
            // Remove newline characters and escape quotes so they don't get stripped   
            page_body = page_body.replace('\n',''); 
            page_body = page_body.replace('"','\\"');

            // JSON payload for adding content page to the proposal
            string jsonpayload = '{\"section_id\": ' + content_section_id + ', \"page\": {\"name\": \"' + page_name +'\", \"body\": \"' + page_body + '\"}}'; 
            system.debug(jsonpayload);

            Http http3 = new Http();
            // Third request to add the page using the section id, page name, and body retrieved in the 1st and 2nd calls
            HttpRequest request3 = new HttpRequest(); 
            tinderbox__TinderBox__c cs3 = tinderbox__TinderBox__c.getOrgDefaults();
            request3.setEndpoint('https://' + cs3.tinderbox__Company_URL__c + '/api/v2/proposals/' + document_id + '/pages?api_key=' + api_key);
            system.debug(request3.getEndpoint());
            request3.setMethod('POST');
            request3.setHeader('Content-Type', 'Application/JSON');
            request3.setHeader('Accept', 'Application/JSON');
            request3.setBody(jsonpayload);
            HttpResponse response3 = http.send(request3);
            // Parse the JSON response
            if (response3.getStatusCode() != 201) {
                System.debug('The status code returned was not expected: ' +
                    response3.getStatusCode() + ' ' + response3.getStatus());
            } else {
                System.debug(response3.getBody());
            }
        }
    }
}