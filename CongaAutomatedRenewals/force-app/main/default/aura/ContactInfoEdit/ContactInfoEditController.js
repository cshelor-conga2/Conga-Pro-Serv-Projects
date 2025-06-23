({
    refreshComponent:function(component,event,helper){
    	var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": "Success.",
            "message": "Your information has been updated.",
            "type": "success"
        });
        // Update the UI: show toast
        resultsToast.fire();
        var event = component.getEvent("contactInfoEvent");
		event.setParam("editMode", false );
		event.fire();
        // $A.get('e.force:refreshView').fire();
    },
    createError: function(component,event,helper){
    	var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": "Error.",
            "message": "There was an error updating your information.",
            "type": "error"
        });
        // Update the UI: show toast
        resultsToast.fire();
    }
})