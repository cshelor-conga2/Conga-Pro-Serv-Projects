({
	openComposer : function(component, onSuccess, onError) {
        var quoteId = component.get("v.recordId");
        
        var action = component.get("c.getComposerParameters");
        action.setParams({
            quoteId: quoteId
        });
        this.executeAction(component, action, $A.getCallback(function(variables) {
            var congaUrl = "https://composer.congamerge.com?" + variables;
            window.open(congaUrl, "Conga", "width=700,height=450,menubar=0" );
            if(onSuccess) onSuccess();
        }), onError);
    },
    
	executeAction : function(component, action, callback, errorCallback) {
        $A.util.removeClass(component.find("spinner"), "slds-hide");
        var $helper = this;

        action.setCallback(this, function(data) {
            var state = data.getState();
            if (component.isValid() && state === "SUCCESS") {
                if(callback) callback(data.getReturnValue());
            }
            else {

                var error = state;
                console.log(error);
                var errors = action.getError();
                console.log(errors);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        error = errors[0].message;
                    }
                }
                $helper.showToast(component, "Error!", "error", error);

                if(errorCallback) errorCallback(error);
            }

			$A.util.addClass(component.find("spinner"), "slds-hide");
        });
        $A.enqueueAction(action);
    },

    showToast: function(component, title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent) {
            toastEvent.setParams({
                "title": title,
                "type": type,
                "message": message
            });
            toastEvent.fire();
        }
        else {
            alert(error);
        }
    }
})