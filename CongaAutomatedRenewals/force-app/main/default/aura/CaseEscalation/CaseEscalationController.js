({
    doInit : function(component, event, helper) {
         helper.getSettings(component);  
	},
    
	doContinueForSeverity : function(component, event, helper) {
        if(component.get("v.severityFilled") == "yes") {
        	component.set("v.showSystemOutageQuestion",true);     
        }
        else {
        	component.set("v.showUpdateSeverity",true);            
        }
		component.set("v.showSeverityQuestion",false);               
	},
    
	doContinueForSystemOutage : function(component, event, helper) {
        if(component.get("v.systemOutage") == "yes") {
            helper.openOutage(component);
            helper.escalateCase(component, function(result) {
                $A.get('e.force:refreshView').fire();
            });
        }
        else {
            helper.openComposer(component);
        }
		component.set("v.showSystemOutageQuestion",false);               
        component.set("v.showFinish",true);
	},
    
	doBackForSystemOutage : function(component, event, helper) {
		component.set("v.showSeverityQuestion",true);
        component.set("v.showSystemOutageQuestion",false);
	},
    
	doReset : function(component, event, helper) {
		component.set("v.showSeverityQuestion",true);
        component.set("v.showSystemOutageQuestion",false);
        component.set("v.showUpdateSeverity",false);
        component.set("v.showFinish",false);
	}    
})