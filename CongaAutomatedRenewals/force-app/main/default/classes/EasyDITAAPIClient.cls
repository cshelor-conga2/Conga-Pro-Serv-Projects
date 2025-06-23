public with sharing class EasyDITAAPIClient {
    private static final Integer OK_STATUS_CODE = 200;
    
    private Easy_DITA_API_Settings__c getAPISettings() {
        return Easy_DITA_API_Settings__c.getOrgDefaults();
    }
    
    public SearchContentResponse searchContent(String searchTerm) {
        SearchContentResponse response = new SearchContentResponse();

        try {
            HttpRequest searchRequest = buildSearchRequest(searchTerm);
            HttpResponse searchResponse = new Http().send(searchRequest);
            
            response = new SearchContentResponse(searchResponse, getAPISettings());
        }
        catch (Exception ex) {
            response.Success = false;
            response.ErrorMessage = ex.getMessage();
        }

        return response;
    }
    
    private HttpRequest buildSearchRequest(String searchTerm) {
        Easy_DITA_API_Settings__c apiSettings = getAPISettings();
        
        String endpoint = 'https://' + apiSettings.API_Domain__c + '/org/' + apiSettings.Org_Id__c + '/env/latest/map/' + apiSettings.Root_Map_Id__c
                          + '/search?token=' + apiSettings.Token__c;
        
        HttpRequest searchRequest = new HttpRequest();
        searchRequest.setMethod('POST');
        searchRequest.setEndpoint(endpoint);
        searchRequest.setHeader('Content-Type', 'text/plain');
        
        Integer resultsLimit = (Integer) apiSettings.Search_Results_Limit__c - 1;
        
        String body = '{ "queryString":"' + searchTerm + '" , "startOffset": 0, "endOffset": ' + resultsLimit + ' }';
        searchRequest.setBody(body);

        system.debug('  search request body: ' + body);
        
        return searchRequest;
    }
    
    public class SearchContentResponse {
        @AuraEnabled
        public Boolean Success { get; set; }
        
        @AuraEnabled
        public String ErrorMessage { get; set; }
        
        @AuraEnabled
        public List<EasyDITAArticle> Articles { get; set; }

        @AuraEnabled
        public Integer TotalResults { get; set; }

        public SearchContentResponse() {
            Articles = new List<EasyDITAArticle>();
            Success = true;
            ErrorMessage = '';
        }

        public SearchContentResponse(HttpResponse response, Easy_DITA_API_Settings__c apiSettings) {
            this();

            if (response.getStatusCode() == OK_STATUS_CODE) {
                parseResponse(response, apiSettings);
            }
            else {
                Success = false;
                ErrorMessage = response.getBody() + ' Error Code: ' + response.getStatusCode();
            }
        }

        private void parseResponse(HttpResponse response, Easy_DITA_API_Settings__c apiSettings) {
            String responseBody = response.getBody();
            
            system.debug('  responseBody: ' + responseBody);
            
            Map<String, Object> rMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            TotalResults = (Integer) rMap.get('totalResults');
            
            List<Object> hitsList = (List<Object>) rMap.get('hits');
            
            system.debug('  hitsList: ' + hitsList);
            
            if (hitsList == null) {
                return;
            }
            
            for (Object hitObj : hitsList) {
                Map<String, Object> hitMap = (Map<String, Object>) hitObj;

                EasyDITAARticle ditaArticle = new EasyDITAArticle();
                ditaArticle.Title = (String) hitMap.get('title');
                ditaArticle.Url = apiSettings.Content_Article_Base_URL__c + '/' + (String) hitMap.get('href');
                ditaArticle.Description = (String) hitMap.get('shortDescription');

                Articles.add(ditaArticle);
            }
            
            /*
               Example Response: 
               {
                   "hits": [
                       {
				            "title": "Requirements and Setup-Troubleshooting1- Set up your Printer2- Download and Install Java/QZ3- Test your Setup with Realm Check-InTroubleshootingMiscellaneous Info",
				            "href": "check-in/requirements-and-setup-troubleshooting1--set-up-your-printer2--download-and-install-javaqz3--test-your-setup-with-realm-check-introubleshootingmiscellaneous-info",
				            "shortDescription": "",
				            "breadcrumbs": [{
				                    "title": "todo-title",
				                    "href": "",
				                    "shortDescription": ""
				                }, {
				                    "title": "Check-In",
				                    "href": "check-in",
				                    "shortDescription": ""
				                }, {
				                    "title": "Requirements and Setup-Troubleshooting1- Set up your Printer2- Download and Install Java/QZ3- Test your Setup with Realm Check-InTroubleshootingMiscellaneous Info",
				                    "href": "check-in/requirements-and-setup-troubleshooting1--set-up-your-printer2--download-and-install-javaqz3--test-your-setup-with-realm-check-introubleshootingmiscellaneous-info",
				                    "shortDescription": ""
				                }
				            ],
				            "highlights": ["<div class='searchResultHighlight'>We also recommend you\n                perform this setup several hours or days ahead of your first check-in event, giving\n                you time to <b>test</b> it out. </div>"]
				        }, {
				            "title": "Print Payroll Checks",
				            "href": "payroll/payroll-runs/print-payroll-checks",
				            "shortDescription": "",
				            "breadcrumbs": [{
				                    "title": "todo-title",
				                    "href": "",
				                    "shortDescription": ""
				                }, {
				                    "title": "Payroll",
				                    "href": "payroll",
				                    "shortDescription": ""
				                }, {
				                    "title": "Payroll Runs",
				                    "href": "payroll/payroll-runs",
				                    "shortDescription": ""
				                }, {
				                    "title": "Print Payroll Checks",
				                    "href": "payroll/payroll-runs/print-payroll-checks",
				                    "shortDescription": ""
				                }
				            ],
				            "highlights": ["<div class='searchResultHighlight'>employee\n     pay\n   \n  \n \n  \n         \n             Before you begin:\n    <b>Test</b> and adjust your payroll check\n    alignment under your payroll settings.\n   \n             </div>"]
				        }
                   ],
                   "totalResults": 2
               }
            */
        }
    }
}