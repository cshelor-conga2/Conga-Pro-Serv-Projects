({
    getSettings : function(component, onSuccess, onError) {
        var action = component.get("c.getSettings");
        
        this.executeAction(component, action, function(settings) {
            component.set("v.settings", settings);            
        });
    },
    
	openOutage : function(component) {
        var caseId = component.get("v.recordId");
        var settings = component.get("v.settings");
        var email = settings.email;
        var outageTemplateId = settings.outageTemplateId;
        
		var outageURL = "/_ui/core/email/author/EmailAuthor?p3_lkid=" + caseId + "&retURL=%2F" + caseId + "&p24=" + email + "&template_id=" + outageTemplateId;
        window.open(outageURL, "Escalate", "width=1500,height=1500,menubar=0");
	},
    
    escalateCase : function(component, onSuccess, onError) {
        var recordId = component.get("v.recordId");
        
        var action = component.get("c.escalateCase");
        action.setParams({
            caseId : recordId
        });
        
        this.executeAction(component, action, onSuccess, onError);
    },
    
	openComposer : function(component, onSuccess, onError) {
        var caseId = component.get("v.recordId");
        var settings = component.get("v.settings");
        var email = settings.email;
        var CETID = settings.CETID;
        var templateGroup = settings.templateGroup;
        
        var action = component.get("c.getCongaSessionVariables");        
        this.executeAction(component, action, function(variables) {
            var congaUrl = "/apex/APXTConga4__Conga_Composer?serverUrl={!API.Partner_Server_URL_370}" + variables + 
                "&Id=" + caseId +
                "&TemplateGroup=" + templateGroup + 
                "&LiveEditEnable=1" +
                "&LiveEditVisible=1" +
                "&EmailAdditionalTo=" + email +
                "&CETID=" + CETID +
                "&SC0=1" +
                "&SC1=Attachments" +
                "&UF0=1" +
                "&TemplateID=+" +
                "&MFTS0=Status" +
                "&MFTSValue0=Escalated to Tier 3";
            window.open(congaUrl, "Conga", "width=700,height=450,menubar=0" );
            if(onSuccess) onSuccess();
        }, onError);
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