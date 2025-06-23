public with sharing class CaseEasyDITAKnowledgeController {
    public static final String CASE_ID_NULL_VALIDATION_MSG = 'The case id is required.';

    @AuraEnabled
    public static SearchEasyDITAResponse searchEasyDITAUsingCase(Id caseId) {
        if (caseId == null) {
            return new SearchEasyDITAResponse(CASE_ID_NULL_VALIDATION_MSG);
        }

        Case caseRecord = 
        [SELECT Id,
                Subject
           FROM Case
          WHERE Id = :caseId];
        
        return searchEasyDITA(caseId, caseRecord.Subject);
    }
    
    @AuraEnabled(cacheable=false)
    public static SearchEasyDITAResponse searchEasyDITA(Id caseId, String searchTerm) {
        SearchEasyDITAResponse response = new SearchEasyDITAResponse();
        response.SearchTerm = searchTerm;

        if (caseId == null) {
            return new SearchEasyDITAResponse(CASE_ID_NULL_VALIDATION_MSG);
        }
        
        if (String.isBlank(searchTerm) || searchTerm.length() == 1) {
            return response;
        }
        
        EasyDITAAPIClient client = new EasyDITAAPIClient();
        EasyDITAAPIClient.SearchContentResponse searchAPIResponse = client.searchContent(searchTerm);
        
        response = new SearchEasyDITAResponse(searchAPIResponse);
        response.SearchTerm = searchTerm;
        
        List<Case_Easy_DITA_Article__c> caseEasyDITAArticles = getCaseEasyDITAArticlesByCaseId(caseId);

        for (Article article : response.Articles) {
            for (Case_Easy_DITA_Article__c caseArticle : caseEasyDITAArticles) {
                if (article.Url == caseArticle.Easy_DITA_Article__r.Url__c) {
                    article.IsLinkedToCase = true;
                    break;
                }
            }
        }
        
        return response;
    }
    
    @AuraEnabled
    public static void linkArticleToCase(Id caseId, Article article) {
        Easy_Dita_Article__c edArticle = getEasyDITAArticleByURL(article);

        system.debug('  linkArticleToCase::edArticle: ' + edArticle);

        if (edArticle == null) {
            edArticle = insertEasyDITAArticle(article);
        }

        Case_Easy_DITA_Article__c caseEasyDITAArticleToInsert = new Case_Easy_DITA_Article__c(
            Case__c = caseId,
            Easy_Dita_Article__c = edArticle.Id
        );

        insert caseEasyDITAArticleToInsert;
    }
    
    @AuraEnabled
    public static void unlinkArticleFromCase(Id caseId, Article article) {
        String articleUrlToUse = getArticleURL(article);

        List<Case_Easy_DITA_Article__c> caseEasyDITAArticlesToDelete =
        [SELECT Id
           FROM Case_Easy_DITA_Article__c
          WHERE Case__c = :caseId
            AND Easy_Dita_Article__r.Url__c = :articleUrlToUse];

        delete caseEasyDITAArticlesToDelete;
    }
    
    private static Easy_Dita_Article__c getEasyDITAArticleByURL(Article article) {
        String articleUrlToUse = getArticleURL(article);

        List<Easy_Dita_Article__c> easyDITAArticles =
        [SELECT Id,
                Title__c,
                Url__c
           FROM Easy_Dita_Article__c
          WHERE Url__c = :articleUrlToUse];

        if (easyDITAArticles.size() > 0) {
            return easyDITAArticles[0];
        }

        return null;
    }

    @testVisible
    private static Easy_DITA_Article__c insertEasyDITAArticle(Article article) {
        Easy_DITA_Article__c newArticle = new Easy_DITA_Article__c(
            Title__c = article.Title,
            URL__c = getArticleURL(article)
        );

        insert newArticle;

        return newArticle;
    }

    private static String getArticleURL(Article article) {
        Integer urlFieldLength = Schema.SObjectType.Easy_DITA_Article__c.Fields.URL__c.Length;
        Integer urlValueLength = article.Url.length();
        Integer lengthToUse = Math.min(urlFieldLength, urlValueLength);

        return article.Url.substring(0, lengthToUse);
    }

    private static List<Case_Easy_DITA_Article__c> getCaseEasyDITAArticlesByCaseId(Id caseId) {
        return
        [SELECT Id,
                Name,
                Easy_DITA_Article__r.Title__c,
                Easy_DITA_Article__r.Url__c
           FROM Case_Easy_DITA_Article__c
          WHERE Case__c = :caseId];
    }
    
    public class SearchEasyDITAResponse {
        @AuraEnabled
        public List<Article> Articles { get; set; }
        
        @AuraEnabled
        public Integer TotalResults { get; set; }
        
        @AuraEnabled
        public String SearchTerm { get; set; }
        
        @AuraEnabled
        public Boolean Success { get; set; }
        
        @AuraEnabled
        public String ErrorMessage { get; set; }
        
        public SearchEasyDITAResponse() {
            Articles = new List<Article>();
            Success = true;
            ErrorMessage = '';
            SearchTerm = '';
            this.TotalResults = 0;
        }

        public SearchEasyDITAResponse(String errorMessage) {
            Success = false;
            this.ErrorMessage = errorMessage;
            this.TotalResults = 0;
        }
        
        public SearchEasyDITAResponse(EasyDITAAPIClient.SearchContentResponse searchAPIResponse) {
            this();

            TotalResults = searchAPIResponse.TotalResults;
            Success = searchAPIResponse.Success;
            ErrorMessage = searchAPIResponse.ErrorMessage;
            
            for (EasyDITAArticle edArticle : searchAPIResponse.Articles) {
                Articles.add(new Article( edArticle ));
            }
        }
    }
    
    public class Article {
        @AuraEnabled
        public String Title { get; set; }
        
        @AuraEnabled
        public String Description { get; set; }
        
        @AuraEnabled
        public String Url { get; set; }
        
        @AuraEnabled
        public Boolean IsLinkedToCase { get; set; }
        
        public Article() {
            IsLinkedToCase = false;
        }
        
        public Article(EasyDITAArticle edArticle) {
            Title = edArticle.Title;
            Description = edArticle.Description;
            Url = edArticle.Url;
            IsLinkedToCase = false;
        }
    }
}