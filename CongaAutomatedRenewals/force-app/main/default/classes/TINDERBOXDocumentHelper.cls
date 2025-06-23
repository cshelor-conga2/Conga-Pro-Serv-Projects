/**
* @author ECS, ERedding
* @date 20190731
* @version 1.00
* @description TINDERBOXDocumentHelper - Custom functionality for the tinderbox__Document__c object
*/
public with sharing class TINDERBOXDocumentHelper {
    
    // GET OCTIV AUTO ADD RECIPIENT SETTINGS
    @testVisible
    private static Octiv_Auto_Add_Recipients_Settings__mdt AutoAddRecipientSettings {
    get {
        if(AutoAddRecipientSettings == null){
            if(Test.isRunningTest()){
                AutoAddRecipientSettings = TINDERBOXDocumentHelperTest.AutoAddRecipientSettingsTestMeta;
            }
            else{
                List<Octiv_Auto_Add_Recipients_Settings__mdt> settings = [SELECT Id, API_Key__c, Document_Endpoint__c, Recipients_Endpoint__c, Emails_Endpoint__c, Auto_Add_Signer_Templates__c,
                                                                                 Auto_Add_Recipient_Templates__c, Auto_Email_Templates__c, Email_Body__c
                                                                          FROM Octiv_Auto_Add_Recipients_Settings__mdt LIMIT 1];
                if(!settings.isEmpty()){
                    AutoAddRecipientSettings = settings[0];
                }
            }
        }
        return AutoAddRecipientSettings;
    } set; }


    /**
    * @description autoAddRecipientsAndEmail - Creates a set of tinderbox__Document__c record ids on which to add signers to a new tinderbox__Document__c record
    *                                           ********* EXECUTED BY tinderbox__Document__c AFTER INSERT TRIGGER ********
    * @param List<tinderbox__Document__c> newDocuments
    * @return void
    */
    public static void autoAddRecipientsAndEmail(List<tinderbox__Document__c> newDocuments){
        try{
            if(TriggerHelper.DoExecute('TINDERBOXDocumentHelper','autoAddRecipientsAndEmail') && newDocuments != null){

                // GET QUALIFYING DOCUMENTS
                Set<Id> qualifiedDocIds = new Set<Id>();
                for(tinderbox__Document__c newDocument : newDocuments){
                    if(String.isNotBlank(newDocument.tinderbox__TinderBoxId__c)){
                        qualifiedDocIds.add(newDocument.Id);
                    }
                }

                // SEND QUALIFYING DOCUMENTS TO FUTURE METHOD
                if(!qualifiedDocIds.isEmpty()){
                    TINDERBOXDocumentHelper.autoAddRecipientsAndEmail(qualifiedDocIds);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TINDERBOXDocumentHelper','autoAddRecipientsAndEmail');
            }
        }   
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TINDERBOXDocumentHelper', 'autoAddRecipientsAndEmail', newDocuments, ex, true);
        }
    }
    
    /**
    * @description autoAddRecipientsAndEmail - Future method with HTTP callouts to pull contact information from created Collaborate Proposal and add appropriate signers
    * @param Set<Id> qualifiedDocIds
    * @return void
    */
    @future(callout=true)
    private static void autoAddRecipientsAndEmail(Set<Id> qualifiedDocIds){
        try{
            if(!qualifiedDocIds.isEmpty() && AutoAddRecipientSettings != null && String.isNotBlank(AutoAddRecipientSettings.API_Key__c)){
                String apiKey = AutoAddRecipientSettings.API_Key__c;
                String documentEndpoint = AutoAddRecipientSettings.Document_Endpoint__c;
                String recipientsEndpoint = AutoAddRecipientSettings.Recipients_Endpoint__c;
                String emailEndpoint = AutoAddRecipientSettings.Emails_Endpoint__c;
                Set<String> autoAddSignerTemplates = String.isNotBlank(AutoAddRecipientSettings.Auto_Add_Signer_Templates__c) ? new Set<String>(AutoAddRecipientSettings.Auto_Add_Signer_Templates__c.replace('\r','').split('\n')) : new Set<String>();
                Set<String> autoAddRecipientTemplates = String.isNotBlank(AutoAddRecipientSettings.Auto_Add_Recipient_Templates__c) ? new Set<String>(AutoAddRecipientSettings.Auto_Add_Recipient_Templates__c.replace('\r','').split('\n')) : new Set<String>();
                Set<String> autoEmailTemplates = String.isNotBlank(AutoAddRecipientSettings.Auto_Email_Templates__c) ? new Set<String>(AutoAddRecipientSettings.Auto_Email_Templates__c.replace('\r','').split('\n')) : new Set<String>();

                if(String.isNotBlank(documentEndpoint) && String.isNotBlank(recipientsEndpoint) && String.isNotBlank(emailEndpoint)){

                    // GET DOCUMENT AND RELATED DATA
                    List<tinderbox__Document__c> qualifiedTinderDocs = new List<tinderbox__Document__c>();
                    Set<Id> parentAccountIds = new Set<Id>();                    
                    Set<Id> parentOppIds = new Set<Id>();
                    //Map<Id, Contact> primaryContactsByOpp = new Map<Id, Contact>();
                    Map<Id, List<RecipientWrapper>> nonSignerRecipientsByOpp = new Map<Id, List<RecipientWrapper>>();
                    for(tinderbox__Document__c doc : [SELECT tinderbox__TinderBoxId__c, tinderbox__Template_Name__c, tinderbox__Status__c, Quote__c, Quote__r.SBQQ__Opportunity2__c,
                                                             Quote__r.SBQQ__Opportunity2__r.AccountId,
                                                             Quote__r.SBQQ__Opportunity2__r.OwnerId, Quote__r.SBQQ__Opportunity2__r.Owner.Email, Quote__r.OwnerId, Quote__r.Owner.Email, 
                                                             Quote__r.Owner.FirstName, Quote__r.Owner.LastName, Quote__r.SBQQ__PrimaryContact__c, Quote__r.SBQQ__PrimaryContact__r.Email, 
                                                             Quote__r.SBQQ__PrimaryContact__r.FirstName, Quote__r.SBQQ__PrimaryContact__r.LastName
                                                      FROM tinderbox__Document__c WHERE Id IN :qualifiedDocIds]){
                        qualifiedTinderDocs.add(doc);

                        if(doc.Quote__c != null && doc.Quote__r.SBQQ__Opportunity2__c != null){
                            parentOppIds.add(doc.Quote__r.SBQQ__Opportunity2__c);
                            parentAccountIds.add(doc.Quote__r.SBQQ__Opportunity2__r.AccountId);
                            nonSignerRecipientsByOpp.put(doc.Quote__r.SBQQ__Opportunity2__c, new List<RecipientWrapper>());
                        
                            // ADD PRIMARY CONTACT TO MAP AND AS A NON-SIGNING RECIPIENT
                            if(doc.Quote__r.SBQQ__PrimaryContact__c != null && String.isNotBlank(doc.Quote__r.SBQQ__PrimaryContact__r.Email)){
                                //primaryContactsByOpp.put(doc.Id, doc.Quote__r.SBQQ__PrimaryContact__r);
                                nonSignerRecipientsByOpp.get(doc.Quote__r.SBQQ__Opportunity2__c).add(new RecipientWrapper(doc.Quote__r.SBQQ__PrimaryContact__r.FirstName, 
                                                                                                                          doc.Quote__r.SBQQ__PrimaryContact__r.LastName, 
                                                                                                                          doc.Quote__r.SBQQ__PrimaryContact__r.Email));
                            }

                            // ADD QUOTE OWNER AS A NON-SIGNING RECIPIENT
                            //if(doc.Quote__r.OwnerId != null && String.isNotBlank(doc.Quote__r.Owner.Email)){
                            //    nonSignerRecipients.get(doc.Quote__r.SBQQ__Opportunity2__c).add(new RecipientWrapper(doc.Quote__r.Owner.FirstName, 
                            //                                                                                         doc.Quote__r.Owner.LastName, 
                            //                                                                                         doc.Quote__r.Owner.Email));
                            //}
                        }
                    }

                    // GET NON SIGNER CONTACTS FROM PARENT OPPS
                    if(!parentOppIds.isEmpty()){

                        // ADD OPP CONTACT ROLES AS NON SIGNERS
                        for(OpportunityContactRole oppContact : [SELECT OpportunityId, ContactId, Contact.FirstName, Contact.LastName, Contact.Email FROM OpportunityContactRole
                                                                 WHERE OpportunityId IN :parentOppIds]){
                            if(!nonSignerRecipientsByOpp.containsKey(oppContact.OpportunityId)){
                                nonSignerRecipientsByOpp.put(oppContact.OpportunityId, new List<RecipientWrapper>());
                            }
                            nonSignerRecipientsByOpp.get(oppContact.OpportunityId).add(new RecipientWrapper(oppContact.Contact.FirstName, oppContact.Contact.LastName, oppContact.Contact.Email));
                        }
                    }

                    // GET NON SIGNER CONTACTS FROM PARENT ACCOUNTS
                    Map<Id, List<RecipientWrapper>> nonSignerRecipientsByAcct = new Map<Id, List<RecipientWrapper>>();
                    if(!parentAccountIds.isEmpty()){

                        // GET PARENT ACCOUNT DATA
                        for(Account parentAcct : [SELECT Id, BillingContact__c, BillingContact__r.FirstName, BillingContact__r.LastName, BillingContact__r.Email,
                                                      (SELECT Contact.FirstName, Contact.LastName, Contact.Email FROM AccountContactRelations
                                                       WHERE IsPrimary__c = true AND Status__c NOT IN ('Do not Contact', 'Not reachable', 'No Longer at Company'))
                                                  FROM Account WHERE Id IN :parentAccountIds]){

                            // ADD ACCOUNT BILLING PARTY AS A NON SIGNER
                            if(parentAcct.BillingContact__c != null && String.isNotBlank(parentAcct.BillingContact__r.Email)){
                                if(!nonSignerRecipientsByAcct.containsKey(parentAcct.Id)){
                                    nonSignerRecipientsByAcct.put(parentAcct.Id, new List<RecipientWrapper>());
                                }
                                nonSignerRecipientsByAcct.get(parentAcct.Id).add(new RecipientWrapper(parentAcct.BillingContact__r.FirstName, parentAcct.BillingContact__r.LastName, parentAcct.BillingContact__r.Email));
                            }

                            // ADD ACCOUNT PRIMARY CONTACTS AS NON SIGNERS
                            if(!parentAcct.AccountContactRelations.isEmpty()){
                                for(AccountContactRelation contactRelation : parentAcct.AccountContactRelations){
                                    if(!nonSignerRecipientsByAcct.containsKey(parentAcct.Id)){
                                        nonSignerRecipientsByAcct.put(parentAcct.Id, new List<RecipientWrapper>());
                                    }
                                    nonSignerRecipientsByAcct.get(parentAcct.Id).add(new RecipientWrapper(contactRelation.Contact.FirstName, contactRelation.Contact.LastName, contactRelation.Contact.Email));
                                }
                            }
                        }
                    }

                    // PROCESS DOCUMENTS
                    Http http = new Http();
                    for(tinderbox__Document__c tinderDoc : qualifiedTinderDocs){
                        if(autoAddSignerTemplates.contains(tinderDoc.tinderbox__Template_Name__c) || autoAddRecipientTemplates.contains(tinderDoc.tinderbox__Template_Name__c) || 
                                                                                                     autoEmailTemplates.contains(tinderDoc.tinderbox__Template_Name__c)){

                            HttpRequest getDocRequest = new HttpRequest();
                            getDocRequest.setEndpoint(String.format(documentEndpoint, new List<String>{ tinderDoc.tinderbox__TinderBoxId__c, apiKey }));
                            getDocRequest.setMethod('GET');
                            getDocRequest.setHeader('Content-Type', 'Application/JSON');
                            
                            HttpResponse getDocResponse = http.send(getDocRequest);
                            if(getDocResponse.getStatusCode() != 200 && getDocResponse.getStatusCode() != 201){
                                String httpErrorInfo = getDocResponse.getStatusCode() + ' ' + getDocResponse.getStatus() + ' - ' + getDocResponse.getBody();
                                String errorMessage = 'The status code returned was not expected: ' + httpErrorInfo;
                                SystemIssueLogHelper.LogException('TINDERBOXDocumentHelper', 'autoAddRecipientsAndEmail', tinderDoc.Id, errorMessage, false);
                            }
                            else{
                                // AUTO ADD RECIPIENTS THAT -ARE- SIGNERS IF THE DOC'S TEMPLATE IS ALLOWED THIS FUNCTIONALITY
                                if(autoAddSignerTemplates.contains(tinderDoc.tinderbox__Template_Name__c)){
                                    for(Octiv_Auto_Add_Signers__mdt signer : [SELECT Id, JSON_First_Name_Token__c, JSON_Last_Name_Token__c, JSON_Email_Token__c, Signer_Position__c
                                                                              FROM Octiv_Auto_Add_Signers__mdt ORDER BY Signer_Position__c]){

                                        String firstName = getDataFromJSON(getDocResponse.getBody(), signer.JSON_First_Name_Token__c);
                                        String lastName = getDataFromJSON(getDocResponse.getBody(), signer.JSON_Last_Name_Token__c);
                                        String email = getDataFromJSON(getDocResponse.getBody(), signer.JSON_Email_Token__c);
                                        Integer signerPosition = Integer.valueOf(signer.Signer_Position__c);

                                        if(String.isNotBlank(firstName) && String.isNotBlank(lastName) && String.isNotBlank(email)){

                                            // BUILD BODY FOR A SIGNING RECIPIENT
                                            String signerRequestBody = '{"recipient": {"first_name": "' + firstName + '" ,"last_name": "' + lastName + '"';
                                                   signerRequestBody += ' ,"email_address": "' + email + '"';
                                                   signerRequestBody += ' ,"signer": true, "signer_position": ' + signerPosition;
                                                   signerRequestBody += '}}';

                                            HttpRequest setSignerRecipRequest = new HttpRequest();
                                            setSignerRecipRequest.setEndpoint(String.format(recipientsEndpoint, new List<String>{ tinderDoc.tinderbox__TinderBoxId__c, apiKey }));
                                            setSignerRecipRequest.setMethod('POST');
                                            setSignerRecipRequest.setHeader('Content-Type', 'Application/JSON');
                                            setSignerRecipRequest.setBody(signerRequestBody);

                                            HttpResponse setSignerRecipResponse = http.send(setSignerRecipRequest);
                                            if(setSignerRecipResponse.getStatusCode() != 200 && setSignerRecipResponse.getStatusCode() != 201){
                                                String httpErrorInfo = setSignerRecipResponse.getStatusCode() + ' ' + setSignerRecipResponse.getStatus() + ' - ' + setSignerRecipResponse.getBody();
                                                String errorMessage = 'The status code returned was not expected: ' + httpErrorInfo;
                                                SystemIssueLogHelper.LogException('TINDERBOXDocumentHelper', 'autoAddRecipientsAndEmail', tinderDoc.Id, errorMessage, false);
                                            }
                                        }
                                    }
                                }

                                // AUTO ADD RECIPIENTS THAT ARE -NOT- SIGNERS
                                if(autoAddRecipientTemplates.contains(tinderDoc.tinderbox__Template_Name__c) && (!nonSignerRecipientsByOpp.isEmpty() || !nonSignerRecipientsByAcct.isEmpty())){

                                    // CREATE UNIQUE MAP OF APPLICABLE NON SIGNERS FROM OPPS AND ACCOUNTS
                                    Map<String, RecipientWrapper> nonSignerRecipients = new Map<String, RecipientWrapper>();
                                    if(tinderDoc.Quote__r.SBQQ__Opportunity2__c != null){
                                        //// NON SIGNERS FROM PARENT OPPORTUNITY
                                        if(nonSignerRecipientsByOpp.containsKey(tinderDoc.Quote__r.SBQQ__Opportunity2__c)){
                                            for(RecipientWrapper recipient : nonSignerRecipientsByOpp.get(tinderDoc.Quote__r.SBQQ__Opportunity2__c)){
                                                nonSignerRecipients.put(recipient.Email, recipient);
                                            }
                                        }
                                        //// NON SIGNERS FROM PARENT ACCOUNT
                                        if(tinderDoc.Quote__r.SBQQ__Opportunity2__r.AccountId != null && nonSignerRecipientsByAcct.containsKey(tinderDoc.Quote__r.SBQQ__Opportunity2__r.AccountId)){
                                            for(RecipientWrapper recipient : nonSignerRecipientsByAcct.get(tinderDoc.Quote__r.SBQQ__Opportunity2__r.AccountId)){
                                                nonSignerRecipients.put(recipient.Email, recipient);
                                            }
                                        }
                                    }

                                    for(RecipientWrapper recipient : nonSignerRecipients.values()){
                                        if(String.isNotBlank(recipient.FirstName) && String.isNotBlank(recipient.LastName) && String.isNotBlank(recipient.Email)){

                                            // BUILD BODY FOR A NON-SIGNING RECIPIENT
                                            String nonSignerRequestBody = '{"recipient": {"first_name": "' + recipient.FirstName + '" ,"last_name": "' + recipient.LastName + '"';
                                                   nonSignerRequestBody += ' ,"email_address": "' + recipient.Email + '"';
                                                   nonSignerRequestBody += ' ,"signer": false';
                                                   nonSignerRequestBody += '}}';

                                            HttpRequest setNonSignerRecipRequest = new HttpRequest();
                                            setNonSignerRecipRequest.setEndpoint(String.format(recipientsEndpoint, new List<Object>{tinderDoc.tinderbox__TinderBoxId__c, apiKey}));
                                            setNonSignerRecipRequest.setMethod('POST');
                                            setNonSignerRecipRequest.setHeader('Content-Type', 'Application/JSON');                                           
                                            setNonSignerRecipRequest.setBody(nonSignerRequestBody);

                                            HttpResponse setNonSignerRecipResponse = http.send(setNonSignerRecipRequest);
                                            if(setNonSignerRecipResponse.getStatusCode() != 200 && setNonSignerRecipResponse.getStatusCode() != 201){
                                                String httpErrorInfo = setNonSignerRecipResponse.getStatusCode() + ' ' + setNonSignerRecipResponse.getStatus() + ' - ' + setNonSignerRecipResponse.getBody();
                                                String errorMessage = 'The status code returned was not expected: ' + httpErrorInfo;
                                                SystemIssueLogHelper.LogException('TINDERBOXDocumentHelper', 'autoAddRecipientsAndEmail', tinderDoc.Id, errorMessage, false);
                                            }
                                        }
                                    }
                                }

                                // AUTO EMAIL RECIPIENTS ON DOCUMENT
                                if(autoEmailTemplates.contains(tinderDoc.tinderbox__Template_Name__c) && String.isNotBlank(AutoAddRecipientSettings.Email_Body__c) && 
                                    tinderDoc.tinderbox__Status__c != 'Draft'){

                                    Map<String, String> recipientEmailAddressesById = getDocumentRecipients(tinderDoc.tinderbox__TinderBoxId__c, tinderDoc.Id);
                                    if(!recipientEmailAddressesById.isEmpty()){
                                        
                                        // REMOVE RECIPIENT THAT IS THE PRIMARY CONTACT FOR THE QUOTE SINCE COLLATORATE WILL AUTOMATCIALLY SEND THEM AN EMAIL
                                        //for(String recipientId : recipientEmailAddressesById.keySet()){
                                        //    if(primaryContactsByOpp.containsKey(tinderDoc.Quote__r.SBQQ__Opportunity2__c) && 
                                        //        recipientEmailAddressesById.get(recipientId) == primaryContactsByOpp.get(tinderDoc.Quote__r.SBQQ__Opportunity2__c).Email){

                                        //        recipientEmailAddressesById.remove(recipientId);
                                        //    }
                                        //}

                                        // GET EMAIL OF QUOTE'S PARENT OPPORTUNITY OWNER
                                        String oppOwnerEmail = '';
                                        if(tinderDoc.Quote__c != null && tinderDoc.Quote__r.SBQQ__Opportunity2__c != null){
                                            oppOwnerEmail = tinderDoc.Quote__r.SBQQ__Opportunity2__r.Owner.Email;
                                        }
                                        //BUILD STRING LIST OF IDS
                                        String recipientIds = '';
                                        for(String recipientId : recipientEmailAddressesById.keySet()){
                                            recipientIds += recipientId + ',';
                                        }
                                        recipientIds = recipientIds.length() != 0 ? recipientIds.left(recipientIds.length()-1) : recipientIds; // REMOVE TRAILING COMMA

                                        String sendEmailRequestBody = '{"email": {"subject": "{{proposal_name}}","message": "Dear {{recipient_first_name}},<br /><br />'; 
                                               sendEmailRequestBody += AutoAddRecipientSettings.Email_Body__c;
                                               sendEmailRequestBody += '<br /><br />Sincerely,<br />{{proposal_owner}}<br />{{proposal_owner_email}}","recipient_ids": [' + recipientIds +'],"custom_bcc_email": "' + oppOwnerEmail + '"';
                                               sendEmailRequestBody += '}}';

                                        HttpRequest sendEmailRequest = new HttpRequest();
                                        sendEmailRequest.setEndpoint(String.format(emailEndpoint, new List<Object>{tinderDoc.tinderbox__TinderBoxId__c, apiKey}));
                                        sendEmailRequest.setMethod('POST');
                                        sendEmailRequest.setHeader('Content-Type', 'Application/JSON');
                                        sendEmailRequest.setBody(sendEmailRequestBody);

                                        HttpResponse sendEmailResponse = http.send(sendEmailRequest);
                                        if(sendEmailResponse.getStatusCode() != 200 && sendEmailResponse.getStatusCode() != 201){
                                            String httpErrorInfo = sendEmailResponse.getStatusCode() + ' ' + sendEmailResponse.getStatus() + ' - ' + sendEmailResponse.getBody();
                                            String errorMessage = 'The status code returned was not expected: ' + httpErrorInfo;
                                            SystemIssueLogHelper.LogException('TINDERBOXDocumentHelper', 'autoAddRecipientsAndEmail', tinderDoc.Id, errorMessage, false);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SAVE ERRORS TO DATABASE
                    SystemIssueLogHelper.UpsertExceptions();
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TINDERBOXDocumentHelper', 'autoAddRecipientsAndEmail', qualifiedDocIds, ex, true);
        }
    }

    /**
    * @description getDocumentRecipients - 
    * @param String tinderBoxDocumentId
    * @return Map<String, String>
    */
    public static Map<String, String> getDocumentRecipients(String tinderBoxDocumentId, Id tinderBoxDocumentSFId){
        try{
            if(String.isNotBlank(tinderBoxDocumentId) && AutoAddRecipientSettings != null && String.isNotBlank(AutoAddRecipientSettings.API_Key__c)){
                Http http = new Http();            
                String apiKey = AutoAddRecipientSettings.API_Key__c;
                String recipientsEndpoint = AutoAddRecipientSettings.Recipients_Endpoint__c;

                HttpRequest getRecipientsRequest = new HttpRequest();
                getRecipientsRequest.setEndpoint(String.format(recipientsEndpoint, new List<String>{ tinderBoxDocumentId, apiKey }));
                getRecipientsRequest.setMethod('GET');
                getRecipientsRequest.setHeader('Content-Type', 'Application/JSON');

                HttpResponse getRecipientsResponse = http.send(getRecipientsRequest);
                if(getRecipientsResponse.getStatusCode() != 200 && getRecipientsResponse.getStatusCode() != 201){
                    String httpErrorInfo = getRecipientsResponse.getStatusCode() + ' ' + getRecipientsResponse.getStatus() + ' - ' + getRecipientsResponse.getBody();
                    String errorMessage = 'The status code returned was not expected: ' + httpErrorInfo;
                    SystemIssueLogHelper.LogException('TINDERBOXDocumentHelper', 'getDocumentRecipients', tinderBoxDocumentSFId, errorMessage, false);
                }
                else{
                    Map<String, String> recipientEmailAddressesById = new Map<String, String>();
                    JSONParser parser = JSON.createParser(getRecipientsResponse.getBody());
                    String recipientId = '';
                    String recipientEmail = '';
                    while(parser.nextToken() != null){
                        // RECIPIENT ID
                        if(parser.getText() == 'id'){
                            parser.nextToken();
                            recipientId = parser.getText();
                        }
                        // RECIPIENT EMAIL
                        if(parser.getText() == 'email_address'){
                            parser.nextToken();
                            recipientEmail = parser.getText();
                        }
                        // ADD TO MAP IF BOTH ID AND EMAIL WERE FOUND
                        if(String.isNotBlank(recipientId) && String.isNotBlank(recipientEmail)){
                            recipientEmailAddressesById.put(recipientId, recipientEmail);
                            recipientId = '';
                            recipientEmail = '';
                        }
                    }
                    return recipientEmailAddressesById;
                }

                // LOG ANY ERRORS
                SystemIssueLogHelper.UpsertExceptions();            
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TINDERBOXDocumentHelper', 'getDocumentRecipients', tinderBoxDocumentId, ex, true);
        }
        return new Map<String, String>();
    }


    /**
    * @description getDataFromJSON - Parses through the supplied JSON and return the value of the specified JSON token
    * @param String jsonString - JSON payload to parse
    * @param String tokenName - Name of token on which to retrieve the value
    * @return String
    */
    private static String getDataFromJSON(String jsonString, String tokenName){
        String retrievedValue;
        JSONParser parser = JSON.createParser(jsonString);
        while(parser.nextToken() != null) {
            if(parser.getText() == tokenName){
                parser.nextToken();
                retrievedValue = parser.getText();
                break;
            }        
        }
        return retrievedValue;
    }

    /**
    * @description class RecipeintWrapper - Wrapper class for holding Document Recipients
    */
    private class RecipientWrapper{
        private String FirstName;
        private String LastName;
        private String Email;

        /**
        * @description RecipientWrapper - Constructor
        * @param String pFirstName - Recipient first name
        * @param String pLastName - Recipient last name
        * @param String pEmail - Recipient email
        */
        public RecipientWrapper(String pFirstName, String pLastName, String pEmail){
            FirstName = pFirstName;
            LastName = pLastName;
            Email = pEmail;
        }
    }


}