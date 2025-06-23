/**
* @author ECS, ERedding
* @date 20190731
* @version 1.00
* @description TINDERBOXDocumentHelperTest - Test class for the TINDERBOXDocumentHelper class
*/
@isTest
public with sharing class TINDERBOXDocumentHelperTest {

    public static Octiv_Auto_Add_Recipients_Settings__mdt AutoAddRecipientSettingsTestMeta {
    get {
            Map<String, Object> meta1FieldValues = new Map<String, Object>{ 
                'API_Key__c' => '7093244d7c7a91f5d677905a07fb8194e7b2fb52',
                'Document_Endpoint__c' => 'https://getconga-sandbox.octiv.com/api/v2/proposals/{0}?api_key={1}',
                'Recipients_Endpoint__c' => 'https://getconga-sandbox.octiv.com/api/v2/proposals/{0}/recipients?api_key={1}',
                'Emails_Endpoint__c' => 'https://getconga-sandbox.octiv.com/api/v2/proposals/{0}/emails?api_key={1}',
                'Auto_Add_Signer_Templates__c' => 'Conga Sales Order Form',
                'Auto_Add_Recipient_Templates__c' => 'Conga Sales Order Form',
                'Auto_Email_Templates__c' => 'Conga Sales Order Form',
                'Email_Body__c' => 'Test Email Body'
            };
            Octiv_Auto_Add_Recipients_Settings__mdt customTestMeta1 = (Octiv_Auto_Add_Recipients_Settings__mdt)TestingUtility.createTestMeta('Octiv_Auto_Add_Recipients_Settings__mdt', meta1FieldValues);
            AutoAddRecipientSettingsTestMeta = customTestMeta1;
        return AutoAddRecipientSettingsTestMeta;
    } set; }
    
    /**
    * @description setup - Create test data
    * @return void
    */
    @testSetup
    public static void setup(){
        //// TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', true, 2);    
        testProducts[0].Name = 'Rev Schedule Prod';
        testProducts[0].ProductCode = 'RSP1';   
        testProducts[0].RevenueScheduleType = 'Repeat';
        testProducts[0].RevenueInstallmentPeriod = 'Monthly';
        testProducts[0].NumberOfRevenueInstallments = 12;
        testProducts[0].CanUseRevenueSchedule = true;
        testProducts[1].Name = 'Rev Schedule Prod';
        testProducts[1].ProductCode = 'RSP2';
        testProducts[1].RevenueScheduleType = 'Repeat';
        testProducts[1].RevenueInstallmentPeriod = 'Monthly';
        testProducts[1].NumberOfRevenueInstallments = 12;
        testProducts[1].CanUseRevenueSchedule = true;
        insert testProducts;

        //// TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', true, 2);
        testPricebookEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[0].Product2Id = testProducts[0].Id;
        testPricebookEntries[0].IsActive = TRUE;
        testPricebookEntries[0].UnitPrice = 200.00;
        testPricebookEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[1].Product2Id = testProducts[1].Id;
        testPricebookEntries[1].IsActive = TRUE;
        testPricebookEntries[1].UnitPrice = 500.00;
        insert testPricebookEntries;

        //// TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account');
        insert testAccount;

        //// TEST CONTACTS
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', true, 3);
        testContacts[0].AccountId = testAccount.Id;
        testContacts[0].FirstName = 'Test1';
        testContacts[0].LastName = 'Contact1';
        testContacts[0].Email = 'testcontact1@mailinator.com';
        testContacts[1].AccountId = testAccount.Id;
        testContacts[1].FirstName = 'Test2';
        testContacts[1].LastName = 'Contact2';
        testContacts[1].Email = 'testcontact2@mailinator.com';
        testContacts[2].AccountId = testAccount.Id;
        testContacts[2].FirstName = 'Test3';
        testContacts[2].LastName = 'Contact2';
        testContacts[2].Email = 'primaryContact@mailinator.com';
        insert testContacts;

        //// TEST OPPORTUNITY
        Opportunity testOpportunity = (Opportunity)TestingUtility.createSObject('Opportunity');
        testOpportunity.Name = 'Test Opp';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.CloseDate = Date.today();
        insert testOpportunity;

        //// TEST OPP CONTACT ROLES
        List<OpportunityContactRole> testOppContactRoles = TestingUtility.createSObjectList('OpportunityContactRole', true, 2);
        testOppContactRoles[0].ContactId = testContacts[0].Id;
        testOppContactRoles[0].OpportunityId = testOpportunity.Id;
        testOppContactRoles[1].ContactId = testContacts[1].Id;
        testOppContactRoles[1].OpportunityId = testOpportunity.Id;
        insert testOppContactRoles;

        //// TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', true, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__PrimaryContact__c = testContacts[2].Id;
        testQuotes[0].SBQQ__Opportunity2__c = testOpportunity.Id;
        testQuotes[0].SBQQ__StartDate__c = Date.newInstance(2018, 1, 1);
        testQuotes[0].SBQQ__EndDate__c = Date.newInstance(2019, 12, 31);
        insert testQuotes;
    }

    /**
    * @description autoAddRecipientsAndEmailTest - Test method for the TINDERBOXDocumentHelper.autoAddRecipientsAndEmail method
    */
    public static testmethod void autoAddRecipientsAndEmailTest(){
        // GET OCTIV AUTO ADD SIGNER SETTINGS
        Octiv_Auto_Add_Recipients_Settings__mdt settings = TINDERBOXDocumentHelper.AutoAddRecipientSettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.API_Key__c));
        System.assert(String.isNotBlank(settings.Document_Endpoint__c));
        System.assert(String.isNotBlank(settings.Recipients_Endpoint__c));
        System.assert(String.isNotBlank(settings.Emails_Endpoint__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Signer_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Recipient_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Email_Templates__c));       

        // GET TEST OPPORTUNITY
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity];
        System.assert(testOpps.size() == 1);

        // GET TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = [SELECT Id FROM SBQQ__Quote__c];
        System.assert(testQuotes.size() == 1);

        // GET APPLICABLE TEMPLATES
        List<String> qualifyingTemplates = settings.Auto_Add_Signer_Templates__c.replace('\r','').split('\n');

        // CREATE STRING.FORMAT PARAMETER LIST
        List<String> stringFormatParams = new List<String>{'1234567', settings.API_Key__c};

        // SETUP HTTP MOCK RESPONSES USING MULTI MOCK
        TestingUtility.MultiRequestMock multiMockTests = new TestingUtility.MultiRequestMock();
        multiMockTests.addCalloutMockClass(String.format(settings.Document_Endpoint__c, stringFormatParams), 'GET', new OctivGetDocumentHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'POST', new OctivPostRecipientHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'GET', new OctivGetRecipientHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Emails_Endpoint__c, stringFormatParams), 'POST', new OctivPostEmailsHTTPMock());    

        // SET MOCK RESPONSES
        Test.setMock(HttpCalloutMock.class, multiMockTests);

        Test.startTest();

        // CREATE TEST OCTIVE DOCUMENT
        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Octiv Document';
        testDoc.tinderbox__Template_Name__c = qualifyingTemplates[0];
        testDoc.Quote__c = testQuotes[0].Id;
        testDoc.tinderbox__TinderBoxId__c = '1234567';
        insert testDoc;

        Test.stopTest();

        // CHECK FOR LOGGED ERRORS, THERE SHOULD BE NONE
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.isEmpty());
    }

    /**
    * @description autoAddRecipientsAndEmail_GetDocErrorTest - Test handling of errors received from Get Document callout
    */
    public static testmethod void autoAddRecipientsAndEmail_GetDocErrorTest(){
        // GET OCTIV AUTO ADD SIGNER SETTINGS
        Octiv_Auto_Add_Recipients_Settings__mdt settings = TINDERBOXDocumentHelper.AutoAddRecipientSettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.API_Key__c));
        System.assert(String.isNotBlank(settings.Document_Endpoint__c));
        System.assert(String.isNotBlank(settings.Recipients_Endpoint__c));
        System.assert(String.isNotBlank(settings.Emails_Endpoint__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Signer_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Recipient_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Email_Templates__c));       

        // GET TEST OPPORTUNITY
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity];
        System.assert(testOpps.size() == 1);

        // GET APPLICABLE TEMPLATES
        List<String> qualifyingTemplates = settings.Auto_Add_Signer_Templates__c.replace('\r','').split('\n');

        // CREATE STRING.FORMAT PARAMETER LIST
        List<String> stringFormatParams = new List<String>{'1234567', settings.API_Key__c};

        // SETUP HTTP MOCK RESPONSES USING MULTI MOCK, USE ERROR RESPONSE FOR GET DOCUMENT CALLOUT
        TestingUtility.MultiRequestMock multiMockTests = new TestingUtility.MultiRequestMock();
        multiMockTests.addCalloutMockClass(String.format(settings.Document_Endpoint__c, stringFormatParams), 'GET', new OctivErrorHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'POST', new OctivPostRecipientHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'GET', new OctivGetRecipientHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Emails_Endpoint__c, stringFormatParams), 'POST', new OctivPostEmailsHTTPMock()); 

        // SET MOCK RESPONSES
        Test.setMock(HttpCalloutMock.class, multiMockTests);

        Test.startTest();

        // CREATE TEST OCTIVE DOCUMENT
        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Octiv Document';
        testDoc.tinderbox__Template_Name__c = qualifyingTemplates[0];
        testDoc.tinderbox__TinderBoxId__c = '1234567';
        insert testDoc;

        Test.stopTest();

        // CHECK FOR LOGGED ERRORS, THERE SHOULD BE TWO
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.size() == 1);
    }

    /**
    * @description autoAddRecipientsAndEmail_PostRecipErrorTest - Test handling of errors received from POST Recipient callout
    */
    public static testmethod void autoAddRecipientsAndEmail_PostRecipErrorTest(){
        // GET OCTIV AUTO ADD SIGNER SETTINGS
        Octiv_Auto_Add_Recipients_Settings__mdt settings = TINDERBOXDocumentHelper.AutoAddRecipientSettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.API_Key__c));
        System.assert(String.isNotBlank(settings.Document_Endpoint__c));
        System.assert(String.isNotBlank(settings.Recipients_Endpoint__c));
        System.assert(String.isNotBlank(settings.Emails_Endpoint__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Signer_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Recipient_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Email_Templates__c));       

        // GET TEST OPPORTUNITY
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity];
        System.assert(testOpps.size() == 1);

        // GET APPLICABLE TEMPLATES
        List<String> qualifyingTemplates = settings.Auto_Add_Signer_Templates__c.replace('\r','').split('\n');

        // CREATE STRING.FORMAT PARAMETER LIST
        List<String> stringFormatParams = new List<String>{'1234567', settings.API_Key__c};

        // SETUP HTTP MOCK RESPONSES USING MULTI MOCK, USE ERROR RESPONSE FOR POST RECIPIENTS CALLOUT
        TestingUtility.MultiRequestMock multiMockTests = new TestingUtility.MultiRequestMock();
        multiMockTests.addCalloutMockClass(String.format(settings.Document_Endpoint__c, stringFormatParams), 'GET', new OctivGetDocumentHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'POST', new OctivErrorHTTPMock());        
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'GET', new OctivGetRecipientHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Emails_Endpoint__c, stringFormatParams), 'POST', new OctivPostEmailsHTTPMock()); 

        // SET MOCK RESPONSES
        Test.setMock(HttpCalloutMock.class, multiMockTests);

        Test.startTest();

        // CREATE TEST OCTIVE DOCUMENT
        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Octiv Document';
        testDoc.tinderbox__Template_Name__c = qualifyingTemplates[0];
        testDoc.tinderbox__TinderBoxId__c = '1234567';
        insert testDoc;

        Test.stopTest();

        // CHECK FOR LOGGED ERRORS, THERE SHOULD BE TWO
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.size() == 1);
    }

    /**
    * @description autoAddRecipientsAndEmail_GetRecipErrorTest - Test handling of errors received from Get Recipient callout
    */
    public static testmethod void autoAddRecipientsAndEmail_GetRecipErrorTest(){
        // GET OCTIV AUTO ADD SIGNER SETTINGS
        Octiv_Auto_Add_Recipients_Settings__mdt settings = TINDERBOXDocumentHelper.AutoAddRecipientSettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.API_Key__c));
        System.assert(String.isNotBlank(settings.Document_Endpoint__c));
        System.assert(String.isNotBlank(settings.Recipients_Endpoint__c));
        System.assert(String.isNotBlank(settings.Emails_Endpoint__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Signer_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Recipient_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Email_Templates__c));       

        // GET TEST OPPORTUNITY
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity];
        System.assert(testOpps.size() == 1);

        // GET APPLICABLE TEMPLATES
        List<String> qualifyingTemplates = settings.Auto_Add_Signer_Templates__c.replace('\r','').split('\n');

        // CREATE STRING.FORMAT PARAMETER LIST
        List<String> stringFormatParams = new List<String>{'1234567', settings.API_Key__c};

        // SETUP HTTP MOCK RESPONSES USING MULTI MOCK, USE ERROR RESPONSE FOR GET RECIPIENTS CALLOUT
        TestingUtility.MultiRequestMock multiMockTests = new TestingUtility.MultiRequestMock();
        multiMockTests.addCalloutMockClass(String.format(settings.Document_Endpoint__c, stringFormatParams), 'GET', new OctivGetDocumentHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'POST', new OctivGetRecipientHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'GET', new OctivErrorHTTPMock());        
        multiMockTests.addCalloutMockClass(String.format(settings.Emails_Endpoint__c, stringFormatParams), 'POST', new OctivPostEmailsHTTPMock()); 

        // SET MOCK RESPONSES
        Test.setMock(HttpCalloutMock.class, multiMockTests);

        Test.startTest();

        // CREATE TEST OCTIVE DOCUMENT
        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Octiv Document';
        testDoc.tinderbox__Template_Name__c = qualifyingTemplates[0];
        testDoc.tinderbox__TinderBoxId__c = '1234567';
        insert testDoc;

        Test.stopTest();

        // CHECK FOR LOGGED ERRORS, THERE SHOULD BE TWO
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.size() == 1);
    }

    /**
    * @description autoAddRecipientsAndEmail_PostEmailErrorTest - Test handling of errors received from Post Email callout
    */
    public static testmethod void autoAddRecipientsAndEmail_PostEmailErrorTest(){
        // GET OCTIV AUTO ADD SIGNER SETTINGS
        Octiv_Auto_Add_Recipients_Settings__mdt settings = TINDERBOXDocumentHelper.AutoAddRecipientSettings;
        System.assert(settings != null);
        System.assert(String.isNotBlank(settings.API_Key__c));
        System.assert(String.isNotBlank(settings.Document_Endpoint__c));
        System.assert(String.isNotBlank(settings.Recipients_Endpoint__c));
        System.assert(String.isNotBlank(settings.Emails_Endpoint__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Signer_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Add_Recipient_Templates__c));
        System.assert(String.isNotBlank(settings.Auto_Email_Templates__c));       

        // GET TEST OPPORTUNITY
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity];
        System.assert(testOpps.size() == 1);

        // GET APPLICABLE TEMPLATES
        List<String> qualifyingTemplates = settings.Auto_Add_Signer_Templates__c.replace('\r','').split('\n');

        // CREATE STRING.FORMAT PARAMETER LIST
        List<String> stringFormatParams = new List<String>{'1234567', settings.API_Key__c};

        // SETUP HTTP MOCK RESPONSES USING MULTI MOCK, USE ERROR RESPONSE FOR POST EMAILS CALLOUT
        TestingUtility.MultiRequestMock multiMockTests = new TestingUtility.MultiRequestMock();
        multiMockTests.addCalloutMockClass(String.format(settings.Document_Endpoint__c, stringFormatParams), 'GET', new OctivGetDocumentHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'POST', new OctivGetRecipientHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Recipients_Endpoint__c, stringFormatParams), 'GET', new OctivPostRecipientHTTPMock());
        multiMockTests.addCalloutMockClass(String.format(settings.Emails_Endpoint__c, stringFormatParams), 'POST', new OctivErrorHTTPMock());

        // SET MOCK RESPONSES
        Test.setMock(HttpCalloutMock.class, multiMockTests);

        Test.startTest();

        // CREATE TEST OCTIVE DOCUMENT
        tinderbox__Document__c testDoc = new tinderbox__Document__c();
        testDoc.Name = 'Test Octiv Document';
        testDoc.tinderbox__Template_Name__c = qualifyingTemplates[0];
        testDoc.tinderbox__TinderBoxId__c = '1234567';
        insert testDoc;

        Test.stopTest();

        // CHECK FOR LOGGED ERRORS, THERE SHOULD BE TWO
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.size() == 1);
    }

    /**
    * @description OctivGetDocumentHTTPMock - HTTP Mock class for testing the TINDERBOXDocumentHelper.autoAddRecipientsAndEmail method GET Document call out
    */
    public class OctivGetDocumentHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');
            
            //////// BUILD JSON MOCK RESPONSE BODY ////////
            String body = '{"proposal":{';
                      body += '"id":1234567,';
                      body += '"name":"Test Octiv Doc",';
                      body += '"status":0,';
                      body += '"user_id":406924,';
                      body += '"created_at":"2019-06-19T13:34:43.000-04:00",';
                      body += '"updated_at":"2019-06-19T13:34:47.000-04:00",';
                      body += '"description":"",';
                      body += '"value":null,';
                      body += '"client":"",';
                      body += '"category_id":null,';
                      body += '"allow_downloads":true,';
                      body += '"password":null,';
                      body += '"published_at":null,';
                      body += '"last_viewed_at":null,';
                      body += '"views":0,';
                      body += '"downloads":0,';
                      body += '"closed_call_to_action_response_id":null,';
                      body += '"closed_at":null,';
                      body += '"archived":false,';
                      body += '"expires_at":null,';
                      body += '"visibility":1,';
                      body += '"template_id":62721,';
                      body += '"ext_integration_id":"a3O2h0000008PhI",';
                      body += '"allow_decline":false,';
                      body += '"allow_accept":true,';
                      body += '"enable_coverpage":false,';
                      body += '"enable_access_code":false,';
                      body += '"enable_redlining":false,';
                      body += '"variable_data":{';
                         body += '"Quote__c_Name":"Q-125013",';
                         body += '"Quote__c_Conga_Collaborate_Template__c":"Signable Renewal Order Form",';
                         body += '"Quote__c_Collaborate_Document_Name__c":"Test Octiv Document",';
                         body += '"Quote__c_PrimaryContact__r_LastName":"User",';
                         body += '"Quote__c_PrimaryContact__r_FirstName":"Test",';
                         body += '"Quote__c_PrimaryContact__r_Name":"Test User",';
                         body += '"Quote__c_PrimaryContact__r_Phone":"",';
                         body += '"Quote__c_PrimaryContact__r_Email":"test.user@getconga.com",';
                         body += '"Quote__c_Owner_Manager_Email__c":"test.user@getconga.com",';
                         body += '"Quote__c_Owner_Manager_First_Name__c":"Test",';
                         body += '"Quote__c_Owner_Manager_Last_Name__c":"User",';
                         body += '"SBQQ__LineItems__r":[';
                            body += '{"attributes":{"type":"SBQQ__QuoteLine__c","url":"/services/data/v36.0/sobjects/SBQQ__QuoteLine__c/a3K2h0000008WP8EAM"},';
                               body += '"Id":"a3K2h0000008WP8EAM",';
                               body += '"SBQQ__ProductFamily__c":"Data and Process Automation",';
                               body += '"SBQQ__ProductName__c":"Conga Grid License",';
                               body += '"SBQQ__Product__c":"01t50000005At8oAAC",';
                               body += '"SBQQ__Quantity__c":10.0,';
                               body += '"SBQQ__Quote__c":"a3O2h0000008PhIEAU",';
                               body += '"SBQQ__EffectiveEndDate__c":"2021-06-17",';
                               body += '"SBQQ__EffectiveStartDate__c":"2020-06-18",';
                               body += '"SBQQ__ListPrice__c":216.0';
                            body += '},';
                            body += '{"attributes":{"type":"SBQQ__QuoteLine__c","url":"/services/data/v36.0/sobjects/SBQQ__QuoteLine__c/a3K2h0000008WP9EAM"},';
                               body += '"Id":"a3K2h0000008WP9EAM",';
                               body += '"SBQQ__ProductFamily__c":"DocGen",';
                               body += '"SBQQ__ProductName__c":"Conga Composer - Enterprise Edition",';
                               body += '"SBQQ__Product__c":"01t50000005At6sAAC",';
                               body += '"SBQQ__Quantity__c":10.0,';
                               body += '"SBQQ__Quote__c":"a3O2h0000008PhIEAU",';
                               body += '"SBQQ__EffectiveEndDate__c":"2021-06-17",';
                               body += '"SBQQ__EffectiveStartDate__c":"2020-06-18",';
                               body += '"SBQQ__ListPrice__c":360.0';
                            body += '}';
                         body += '],';
                         body += '"ManagedClauses__r":[]';
                      body += '},';
                      body += '"enable_public_redlining":false,';
                      body += '"deleted_at":null,';
                      body += '"esignable":"conga_sign",';
                      body += '"metadata":{"download_types":["pdf","docx"],"skin_id":10585,"placeholder_data":{},"ext_integration_type":"SBQQ__Quote__c"},';
                      body += '"enable_post_acceptance":false,';
                      body += '"slug":"signable-renewal-order-form-for-360-rail-services-a485fadb-403b-429d-b5b1-b16bab20c863",';
                      body += '"media_id":null,';
                      body += '"reference_id":"a7s2h0000004Cc6AAE",';
                      body += '"view_version":4,';
                      body += '"signature_page":false,';
                      body += '"require_all_signers_for_acceptance":false,';
                      body += '"enable_print_table_of_contents":false,';
                      body += '"signature_block_id":null,';
                      body += '"document_class_id":null,';
                      body += '"metadata_template_id":null,';
                      body += '"metadata_field_values":{}';
                   body += '}';
                body += '}';

            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
    * @description OctivGetRecipientHTTPMock - HTTP Mock class for testing the TINDERBOXDocumentHelper.autoAddRecipientsAndEmail method GET Recipient call outs
    */
    public class OctivGetRecipientHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');

            ////// BUILD RESPONSE BODY FOR HTTP 'GET' //////
            String body = '[{"recipient":{';
                        body += '"id": 1488182,';
                        body += '"proposal_id": 3920782,';
                        body += '"proposal_email_id": null,';
                        body += '"email_address": "laurwils@gmail.com",';
                        body += '"first_name": "Mac",';
                        body += '"last_name": "Armstrong",';
                        body += '"access_code": null,';
                        body += '"signer": false,';
                        body += '"uuid": "ae437239-6caf-4175-8668-b6edeb63b2e3",';
                        body += '"created_at": "2019-07-23T21:15:25.000-04:00",';
                        body += '"updated_at": "2019-07-23T21:15:25.000-04:00",';
                        body += '"deleted_at": null,';
                        body += '"signer_position": null,';
                        body += '"closed_call_to_action_response_id": null,';
                        body += '"post_acceptance_forms": false,';
                        body += '"add_recipients": false,';
                        body += '"proposal_type": "Proposal",';
                        body += '"add_collaborators": false,';
                        body += '"parent_recipient_id": null,';
                        body += '"redliner": false,';
                        body += '"user_id": 572464,';
                        body += '"public": false,';
                        body += '"status_message": "Waiting on email status"';
                   body += '}},';
                        body += '{"recipient":{';
                        body += '"id": 1488183,';
                        body += '"proposal_id": 3920782,';
                        body += '"proposal_email_id": null,';
                        body += '"email_address": "laurwils+ava@gmail.com",'; //
                        body += '"first_name": "Ava",';
                        body += '"last_name": "Armstrong",';
                        body += '"access_code": null,';
                        body += '"signer": false,';
                        body += '"uuid": "ae437239-6caf-4175-8668-b6edeb63b2e3",';
                        body += '"created_at": "2019-07-23T21:15:25.000-04:00",';
                        body += '"updated_at": "2019-07-23T21:15:25.000-04:00",';
                        body += '"deleted_at": null,';
                        body += '"signer_position": null,';
                        body += '"closed_call_to_action_response_id": null,';
                        body += '"post_acceptance_forms": false,';
                        body += '"add_recipients": false,';
                        body += '"proposal_type": "Proposal",';
                        body += '"add_collaborators": false,';
                        body += '"parent_recipient_id": null,';
                        body += '"redliner": false,';
                        body += '"user_id": 572467,';
                        body += '"public": false,';
                        body += '"status_message": "Waiting on email status"';
                    body += '}}]';

            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
    * @description OctivPostRecipientHTTPMock - HTTP Mock class for testing the TINDERBOXDocumentHelper.autoAddRecipientsAndEmail method POST Recipient call outs
    */
    public class OctivPostRecipientHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');

            ////// BUILD RESPONSE BODY FOR HTTP 'POST' //////
            String body = '{"recipient":{';
                  body += '"type":"proposal/recipient",';
                  body += '"id":1442085,';
                  body += '"first_name":"Test",';
                  body += '"last_name":"User",';
                  body += '"email_address":"test.user@mailinator.com",';
                  body += '"signer":true,';
                  body += '"signer_position":2,';
                  body += '"email_id":null,';
                  body += '"status_message":"Waiting on email status",';
                  body += '"variables":{';
                     body += '"recipient_first_name":"Test",';
                     body += '"recipient_last_name":"User",';
                     body += '"recipient_name":"Test User",';
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

    /**
    * @description OctivPostEmailsHTTPMock - HTTP Mock class for testing the TINDERBOXDocumentHelper.autoAddRecipientsAndEmail method POST Emails call out
    */
    public class OctivPostEmailsHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');

            //////// BUILD JSON MOCK RESPONSE BODY ////////
            String body = '{"email": {';
                    body += '"type": "proposal/email",';
                    body += '"id": 819837,';
                    body += '"subject": "Q-117000",';
                    body += '"message": "Dear {{recipient_first_name}},<br /><br />Thank you for taking the time to review this document. I look forward to following up after you have time to review these materials.<br /><br />Sincerely,<br />{{proposal_owner}}<br />{{proposal_owner_email}}",';
                    body += '"created_at": "2019-07-31T14:40:29.000-04:00",';
                    body += '"document": {"id": 3920782,"type": "document"},';
                    body += '"from": "\"Octiv Support\" <laura.armstrong+lauratest@octiv.com>"';
            body += '}}';

            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
    * @description OctivErrorHTTPMock - HTTP Mock class for testing TINDERBOXDocumentHelper.autoAddRecipientsAndEmail method error handling
    */
    public class OctivErrorHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            
            String body = '{"test": {"id": 1442085}}';
            
            res.setBody(body);
            res.setStatusCode(404);
            return res;
        }
    }


}