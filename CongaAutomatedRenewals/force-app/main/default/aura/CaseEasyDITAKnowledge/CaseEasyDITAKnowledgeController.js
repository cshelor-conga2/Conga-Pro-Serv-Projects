({
    init : function(component, event, helper) {
        helper.loadArticlesFromCase(component);
    },

    handleLinkToCaseClick : function(component, event, helper) {
        var linkToCaseButton = event.getSource();
        var article = linkToCaseButton.get('v.value');

        helper.attachArticleToCase(component, article);
    },

    handleRemoveFromCaseClick : function(component, event, helper) {
        var linkToCaseButton = event.getSource();
        var article = linkToCaseButton.get('v.value');

        helper.removeArticleFromCase(component, article);    
    },

    handleSearchClicked : function(component, event, helper) {
        helper.loadArticlesFromSearchTerm(component);
    },

    handleSearchKeyUp : function(component, event, helper) {
        const KEYCODE_ENTER = 13;
        
        var keyCode = event.which || event.keyCode || 0;

        if (keyCode == KEYCODE_ENTER) {
            helper.loadArticlesFromSearchTerm(component);
        }
    }
})