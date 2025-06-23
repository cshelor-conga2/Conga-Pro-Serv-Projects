@isTest
public with sharing class CaseEasyDITAKnowledgeControllerTest {
    private static final String DEFAULT_CASE_SUBJECT = 'Salesforce Test Case';

    static Case DefaultCase = null;

    @testSetup
    static void setup(){
        Account someAccount = new Account(Name = 'Test Account');
        insert someAccount;

        Contact someContact = new Contact(
            LastName = 'Test Contact',
            AccountId = someAccount.Id
        );

        insert someContact;

        Case defaultCase = new Case(
            ContactId = someContact.Id,
            AccountId = someAccount.Id,
            Subject = DEFAULT_CASE_SUBJECT
        );

        insert defaultCase;

        Easy_DITA_API_Settings__c easyDitaAPISettings = new Easy_DITA_API_Settings__c(
            API_Domain__c = 'example.com',
            Content_Article_Base_URL__c = 'example.com',
            Org_Id__c = 'conga',
            Root_Map_Id__c = 'abca0193819',
            Search_Results_Limit__c = 25,
            Token__c = 'TokenABC123'
        );

        insert easyDitaAPISettings;
    }

    @isTest
    static void linkArticleToCase_noArticleInDatabase_expectEasyDITAArticleCreatedAndLinkedToCaseTest() {
        loadDefaults();
        CaseEasyDITAKnowledgeController.Article article = createDefaultArticle();

        CaseEasyDITAKnowledgeController.linkArticleToCase(DefaultCase.Id, article);

        assertArticleLinkedToDefaultCase(article);
    }

    @isTest
    static void linkArticleToCase_articleInDatabase_expectExistingEasyDITAArticleLinkedToCaseTest() {
        loadDefaults();
        CaseEasyDITAKnowledgeController.Article article = createDefaultArticle();
        Easy_DITA_Article__c insertedEDArticle = CaseEasyDITAKnowledgeController.insertEasyDITAArticle(article);

        system.assert(insertedEDArticle != null, 'The inserted Easy DITA article is null.');
        system.assert(insertedEDArticle.Id != null, 'The Easy DITA article was not inserted.');

        CaseEasyDITAKnowledgeController.linkArticleToCase(DefaultCase.Id, article);

        Easy_Dita_Article__c edArticle = getEasyDitaArticleByUrl(article.Url);

        system.assert(edArticle != null, 'The easy dita article was not inserted.');
        system.assertEquals(insertedEDArticle.Id, edArticle.Id, 'A new easy dita article was inserted instead of using the existing one.');

        system.assertEquals(1, edArticle.Case_Easy_DITA_Articles__r.size(), 'The easy dita article was not linked to a case.');

        Case_Easy_DITA_Article__c caseArticle = edArticle.Case_Easy_DITA_Articles__r[0];

        system.assertEquals(DefaultCase.Id, caseArticle.Case__c, 'The article was not linked to the expected case.');
    }

    @isTest
    static void unlinkArticleFromCase_articleNotLinkedToCase_expectNoErrorsTest() {
        loadDefaults();
        CaseEasyDITAKnowledgeController.Article article = createDefaultArticle();
        Easy_DITA_Article__c insertedEDArticle = CaseEasyDITAKnowledgeController.insertEasyDITAArticle(article);

        String errorMsg = '';

        try {
            CaseEasyDITAKnowledgeController.unlinkArticleFromCase(DefaultCase.Id, article);
        }
        catch (Exception ex) {
            errorMsg = ex.getMessage();
        }

        system.assert(String.isBlank(errorMsg), 'There should be no error from unlinking an article that is not linked to a case. Error: ' + errorMsg);
    }

    @isTest
    static void unlinkArticleFromCase_articleLinkedToExistingCase_expectCaseEasyDITAArticleDeletedTest() {
        loadDefaults();
        CaseEasyDITAKnowledgeController.Article article = createDefaultArticle();
        Easy_DITA_Article__c insertedEDArticle = CaseEasyDITAKnowledgeController.insertEasyDITAArticle(article);

        CaseEasyDITAKnowledgeController.linkArticleToCase(DefaultCase.Id, article);

        assertArticleLinkedToDefaultCase(article);

        CaseEasyDITAKnowledgeController.unlinkArticleFromCase(DefaultCase.Id, article);

        assertArticleUnlinkedFromCase(article);
    }

    @isTest
    static void searchEasyDITAUsingCase_caseIdNull_expectCaseIDNullValidationMessageTest() {
        Id nullCaseId = null;

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response =
            CaseEasyDITAKnowledgeController.searchEasyDITAUsingCase(nullCaseId);

        assertErrorResponse(response, CaseEasyDITAKnowledgeController.CASE_ID_NULL_VALIDATION_MSG);
    }

    @isTest
    static void searchEasyDITAUsingCase_caseSubjectSearchedButNoResults_expectSuccessfulResponseWithNoResultsTest() {
        Test.setMock(HttpCalloutMock.class, new SearchSuccessNoResultsResponseMock());
        loadDefaults();

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response = searchUsingCase(DefaultCase.Id);

        assertSuccessResponse(response, 0);
    }

    @isTest
    static void searchEasyDITAUsingCase_caseSubjectSearchedWithResults_expectSuccessfulResponseWithResultsTest() {
        Test.setMock(HttpCalloutMock.class, new SearchSuccessResponseMock());
        loadDefaults();

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response = searchUsingCase(DefaultCase.Id);

        assertSuccessResponse(response, 4);
    }

    @isTest
    static void searchEasyDITAUsingCase_caseSubjectSearchedWithError_expectErrorResponseWithErrorMessageTest() {
        String errorMsg = 'Some Error';

        Test.setMock(HttpCalloutMock.class, new SearchErrorResponseMock(errorMsg));
        loadDefaults();

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response = searchUsingCase(DefaultCase.Id);

        assertErrorResponse(response, errorMsg);
    }

    @isTest
    static void searchEasyDITA_SearchedButNoResults_expectSuccessfulResponseWithNoResultsTest() {
        Test.setMock(HttpCalloutMock.class, new SearchSuccessNoResultsResponseMock());
        loadDefaults();

        String searchTerm = 'Test';

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response = searchUsingTerm(DefaultCase.Id, searchTerm);

        assertSuccessResponse(response, 0);
    }

    @isTest
    static void searchEasyDITA_SearchedWithResults_expectSuccessfulResponseWithResultsTest() {
        Test.setMock(HttpCalloutMock.class, new SearchSuccessResponseMock());
        loadDefaults();

        String searchTerm = 'Test';

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response = searchUsingTerm(DefaultCase.Id, searchTerm);

        assertSuccessResponse(response, 4);
    }

    @isTest
    static void searchEasyDITA_SearchedWithError_expectErrorResponseWithErrorMessageTest() {
        String errorMsg = 'Some Error';

        Test.setMock(HttpCalloutMock.class, new SearchErrorResponseMock(errorMsg));
        loadDefaults();

        String searchTerm = 'Test';

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response = searchUsingTerm(DefaultCase.Id, searchTerm);

        assertErrorResponse(response, errorMsg);
    }

    @isTest
    static void searchEasyDITA_SearchedWithNullCaseId_expectErrorResponseWithCaseIdNullErrorMessageTest() {
        Id nullCaseId = null;
        String searchTerm = 'Test';

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response = searchUsingTerm(nullCaseId, searchTerm);

        assertErrorResponse(response, CaseEasyDITAKnowledgeController.CASE_ID_NULL_VALIDATION_MSG);
    }

    @isTest
    static void searchEasyDITA_SearchedWithBlankSearchTerm_expectSuccessResponseWithNoResultsTest() {
        loadDefaults();

        String blankSearchTerm = '';

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response = searchUsingTerm(DefaultCase.Id, blankSearchTerm);

        assertSuccessResponse(response, 0);
    }

    static CaseEasyDITAKnowledgeController.SearchEasyDITAResponse searchUsingCase(Id caseId) {
        // Have to wrap with startTest and stopTest to prevent uncommitted
        // pending work error.
        Test.startTest();

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response =
            CaseEasyDITAKnowledgeController.searchEasyDITAUsingCase(caseId);

        Test.stopTest();

        return response;
    }

    static CaseEasyDITAKnowledgeController.SearchEasyDITAResponse searchUsingTerm(Id caseId, String searchTerm) {
        // Have to wrap with startTest and stopTest to prevent uncommitted
        // pending work error.
        Test.startTest();

        CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response =
            CaseEasyDITAKnowledgeController.searchEasyDITA(caseId, searchTerm);

        Test.stopTest();

        return response;
    }

    static void loadDefaults() {
        DefaultCase = getDefaultCase();
    }

    static Case getDefaultCase() {
        return
        [SELECT Id,
                Subject
           FROM Case
        LIMIT 1];
    }

    static CaseEasyDITAKnowledgeController.Article createDefaultArticle() {
        CaseEasyDITAKnowledgeController.Article defaultArticle = new CaseEasyDITAKnowledgeController.Article();
        defaultArticle.Description = 'Default Description';
        defaultArticle.Title = 'Default Title';
        defaultArticle.Url = 'https://example.com/helpful-article';

        return defaultArticle;
    }

    static Easy_Dita_Article__c getEasyDitaArticleByUrl(String articleUrl) {
        return
        [SELECT Id,
                Name,
                Title__c,
                Url__c,
                (SELECT Id,
                        Name,
                        Case__c
                   FROM Case_Easy_DITA_Articles__r)
           FROM Easy_Dita_Article__c
          WHERE Url__c = :articleUrl
        LIMIT 1];
    }

    static void assertArticleLinkedToDefaultCase(CaseEasyDITAKnowledgeController.Article article) {
        Easy_Dita_Article__c edArticle = getEasyDitaArticleByUrl(article.Url);

        system.assert(edArticle != null, 'The easy dita article was not inserted.');
        system.assertEquals(1, edArticle.Case_Easy_DITA_Articles__r.size(), 'The easy dita article was not linked to a case.');

        Case_Easy_DITA_Article__c caseArticle = edArticle.Case_Easy_DITA_Articles__r[0];

        system.assertEquals(DefaultCase.Id, caseArticle.Case__c, 'The article was not linked to the expected case.');
    }

    static void assertArticleUnlinkedFromCase(CaseEasyDITAKnowledgeController.Article article) {
        Easy_Dita_Article__c edArticle = getEasyDitaArticleByUrl(article.Url);

        system.assert(edArticle != null, 'The easy dita article was not found.');
        Boolean articleLinkedToCase = false;

        for (Case_Easy_DITA_Article__c caseArticle : edArticle.Case_Easy_DITA_Articles__r) {
            if (caseArticle.Case__c == DefaultCase.Id) {
                articleLinkedToCase = true;
                break;
            }
        }

        system.assertEquals(false, articleLinkedToCase, 'The article was not unlinked from the default case.');
    }

    static void assertErrorResponse(CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response, String expectedError) {
        system.assert(response != null, 'The search easy DITA response is null.');
        system.assertEquals(false, response.Success, 'The search easy DITA response is successful when it should not be.');
        system.assert(response.ErrorMessage.containsIgnoreCase(expectedError), 'The search error response is not the expected one. Expected: ' + expectedError + '  Actual: ' + response.ErrorMessage);
    }

    static void assertSuccessResponse(CaseEasyDITAKnowledgeController.SearchEasyDITAResponse response, Integer expectedNumResults) {
        system.assert(response != null, 'The search easy DITA response is null.');
        system.assertEquals(true, response.Success, 'The search easy DITA response is not successful when it should be. Error: ' + response.ErrorMessage);
        system.assertEquals(expectedNumResults, response.TotalResults, 'The TotalResults is not the expected one.');
        system.assert(response.Articles != null, 'The articles are null.');
        system.assertEquals(expectedNumResults, response.Articles.size(), 'The expected number articles were not found.');
    }

    public class SearchSuccessResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);

            String fourResultsBody = '{"hits":[{"title":"Requirements and Setup-Troubleshooting1- Set up your Printer2- Download and Install Java/QZ3- Test your Setup with Realm Check-InTroubleshootingMiscellaneous Info","href":"check-in/requirements-and-setup-troubleshooting1--set-up-your-printer2--download-and-install-javaqz3--test-your-setup-with-realm-check-introubleshootingmiscellaneous-info","shortDescription":"","breadcrumbs":[{"title":"todo-title","href":"","shortDescription":""},{"title":"Check-In","href":"check-in","shortDescription":""},{"title":"Requirements and Setup-Troubleshooting1- Set up your Printer2- Download and Install Java/QZ3- Test your Setup with Realm Check-InTroubleshootingMiscellaneous Info","href":"check-in/requirements-and-setup-troubleshooting1--set-up-your-printer2--download-and-install-javaqz3--test-your-setup-with-realm-check-introubleshootingmiscellaneous-info","shortDescription":""}],"highlights":["<div class=\'searchResultHighlight\'>We also recommend you\\n                perform this setup several hours or days ahead of your first check-in event, giving\\n                you time to <b>test</b> it out. </div>"]},{"title":"Print Payroll Checks","href":"payroll/payroll-runs/print-payroll-checks","shortDescription":"","breadcrumbs":[{"title":"todo-title","href":"","shortDescription":""},{"title":"Payroll","href":"payroll","shortDescription":""},{"title":"Payroll Runs","href":"payroll/payroll-runs","shortDescription":""},{"title":"Print Payroll Checks","href":"payroll/payroll-runs/print-payroll-checks","shortDescription":""}],"highlights":[]},{"title":"Badge Print Troubleshooting","href":"check-in/badge-print-troubleshooting","shortDescription":"","breadcrumbs":[{"title":"todo-title","href":"","shortDescription":""},{"title":"Check-In","href":"check-in","shortDescription":""},{"title":"Badge Print Troubleshooting","href":"check-in/badge-print-troubleshooting","shortDescription":""}],"highlights":["<div class=\'searchResultHighlight\'>See if you can print a <b>test</b> page from the print queue to the\\n                                        label printer. </div>"]},{"title":"Add ProfilesInfo about military profilesThe DirectoryField Information","href":"manage-profiles/add-profilesinfo-about-military-profilesthe-directoryfield-information","shortDescription":"","breadcrumbs":[{"title":"todo-title","href":"","shortDescription":""},{"title":"Manage Profiles","href":"manage-profiles","shortDescription":""},{"title":"Add ProfilesInfo about military profilesThe DirectoryField Information","href":"manage-profiles/add-profilesinfo-about-military-profilesthe-directoryfield-information","shortDescription":""}],"highlights":["<div class=\'searchResultHighlight\'>You can see\\n                        the parser work by running this <b>test</b>: Enter the name Mr. </div>"]}],"totalResults":4}';
            response.setBody(fourResultsBody);

            return response;
        }
    }

    public class SearchSuccessNoResultsResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);

            String fourResultsBody = '{"hits":[], "totalResults":0 }';
            response.setBody(fourResultsBody);

            return response;
        }
    }

    public class SearchErrorResponseMock implements HttpCalloutMock {
        String ErrorToUse = '';

        public SearchErrorResponseMock(String error) {
            ErrorToUse = error;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            response.setBody(ErrorToUse);

            return response;
        }
    }
}