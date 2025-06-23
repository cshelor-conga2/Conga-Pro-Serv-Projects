({
    loadArticlesFromCase : function(component) {
        var helper = this;
        var caseId = component.get('v.recordId');
        
        helper.showSpinner(component);
        helper.hideError(component);
        
        var searchEasyDITAUsingCaseAction = component.get("c.searchEasyDITAUsingCase");
        
        searchEasyDITAUsingCaseAction.setParams({ "caseId": caseId });
        searchEasyDITAUsingCaseAction.setCallback(this, function(response){
            var state = response.getState();
            console.log("callback state: " + state);

            if (component.isValid() && state === "SUCCESS") {
                var searchResponse = response.getReturnValue();

                if (searchResponse.Success) {
                    helper.loadSearchResults(component, searchResponse, true);
                }
                else {
                    console.log("Error loading articles from case 1: " + searchResponse.ErrorMessage);
                    helper.showError(component, 'Error searching articles from case. Please contact your administrator for assistance. Error: ' + searchResponse.ErrorMessage);
                }
            }
            else {
                var error = response.getError();
                var errorDetail = JSON.stringify(error);

                console.log("Error loading articles from case 2: " + errorDetail);
                helper.showError(component, 'Error searching articles from case. Please contact your administrator for assistance. Error: ' + errorDetail);
            }
            
            helper.hideSpinner(component);
        });
        
        $A.enqueueAction(searchEasyDITAUsingCaseAction);
    },
    
    loadArticlesFromSearchTerm : function(component) {
        var helper = this;
        var searchTerm = component.get('v.searchTerm');
        var caseId = component.get('v.recordId');
        
        helper.showSpinner(component);
        helper.hideError(component);

        var searchEasyDITAAction = component.get("c.searchEasyDITA");
        
        searchEasyDITAAction.setParams({ "searchTerm": searchTerm, "caseId": caseId });
        searchEasyDITAAction.setCallback(this, function(response){
            var state = response.getState();
            console.log("callback state: " + state);
            
            if (component.isValid() && state === "SUCCESS") {
                var searchResponse = response.getReturnValue();

                if (searchResponse.Success) {
                    helper.loadSearchResults(component, searchResponse, false);
                }
                else {
                    console.log("Error loading articles from search 1: " + searchResponse.ErrorMessage);
                    helper.showError(component, 'Error searching articles from search. Please contact your administrator for assistance. Error: ' + searchResponse.ErrorMessage);
                }

            }
            else {
                var error = response.getError();
                var errorDetail = JSON.stringify(error);

                console.log("Error loading articles from search 2: " + errorDetail);
                helper.showError(component, 'Error searching articles from search. Please contact your administrator for assistance. Error: ' + errorDetail);
            }
            
            helper.hideSpinner(component);
        });
        
        $A.enqueueAction(searchEasyDITAAction);
    },
    
    attachArticleToCase : function(component, article) {
        var helper = this;
        var caseId = component.get('v.recordId');
        
        helper.showSpinner(component);
        helper.hideError(component);
        
        var linkArticleToCaseAction = component.get("c.linkArticleToCase");

        linkArticleToCaseAction.setParams({ "article": article, "caseId": caseId });
        linkArticleToCaseAction.setCallback(this, function(response){
            var state = response.getState();
            console.log("callback state: " + state);

            if (component.isValid() && state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                
                helper.updateArticleIsLinkedToCase(component, article, true);
            }
            else {
                var error = response.getError();
                var errorDetail = JSON.stringify(error);

                console.log('Error attaching article to Case. Error: ' + errorDetail);
                helper.showError(component, 'Error attaching the article to the Case. Please contact your administrator. Error: ' + errorDetail);
            }
            
            helper.hideSpinner(component);
        });
        
        $A.enqueueAction(linkArticleToCaseAction);
    },

    removeArticleFromCase : function(component, article) {
        var helper = this;
        var caseId = component.get('v.recordId');
        
        helper.showSpinner(component);
        helper.hideError(component);
        
        var unlinkArticleFromCaseAction = component.get("c.unlinkArticleFromCase");

        unlinkArticleFromCaseAction.setParams({ "article": article, "caseId": caseId });
        unlinkArticleFromCaseAction.setCallback(this, function(response){
            var state = response.getState();
            console.log("callback state: " + state);

            if (component.isValid() && state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                
                helper.updateArticleIsLinkedToCase(component, article, false);
            }
            else {
                var error = response.getError();
                var errorDetail = JSON.stringify(error);

                console.log('Error detaching article from Case. Error: ' + errorDetail);
                helper.showError(component, 'Error removing the article from the Case. Please contact your administrator. Error: ' + errorDetail);
            }
            
            helper.hideSpinner(component);
        });
        
        $A.enqueueAction(unlinkArticleFromCaseAction);
    },
    
    loadSearchResults : function(component, searchEasyDITAResponse, shouldSetSearchTerm) {
        console.log("searchEasyDITAResponse: " + JSON.stringify(searchEasyDITAResponse));
                
        component.set("v.articles", searchEasyDITAResponse.Articles);
        
        if (shouldSetSearchTerm) {
            component.set("v.searchTerm", searchEasyDITAResponse.SearchTerm);
        }
    },
    
    updateArticleIsLinkedToCase : function(component, article, isLinkedToCase) {
        var articles = component.get('v.articles');
        
        for (let currentArticle of articles) {
            if (article.Url == currentArticle.Url) {
                currentArticle.IsLinkedToCase = isLinkedToCase;
                break;
            }
        }
        
        component.set('v.articles', articles);
    },
    
    showSpinner : function(component) {
        component.set('v.showSpinner', true);
    },
    
    hideSpinner : function(component) {
        component.set('v.showSpinner', false);
    },

    showError : function(component, error) {
        component.set('v.error', error);
    },

    hideError : function(component) {
        component.set('v.error', false);
    }
})