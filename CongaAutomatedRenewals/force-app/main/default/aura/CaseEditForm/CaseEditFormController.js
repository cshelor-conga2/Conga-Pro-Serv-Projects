({
    closeModal : function(component,event, helper){
	       	document.getElementById("modaldialog").style.display = "none";
	       	document.getElementById("dialogbackdrop").style.display = "none";
   	},
   	checkValue: function(component, event, helper){
   		var preferredMethod = component.find('preferred_contact_method').get('v.value');
   		var caseSaveButton = component.find('saveCaseUpdate');
   		var otherMethod = component.find('other_contact_method').get('v.value');
   		console.log(preferredMethod);
   		console.log(otherMethod);
   		if(preferredMethod == 'Other' && (otherMethod == null || otherMethod == undefined || otherMethod == '')){
   			caseSaveButton.set("v.disabled", true);
	   		var resultsToast = $A.get("e.force:showToast");
	        resultsToast.setParams({
	            "title": "Warning.",
	            "message": "Other contact method is required.",
	            "type": "warning",
	            "duration": 8000
	        });
	        // Update the UI: show toast
	        resultsToast.fire();

       	}
       	else{
       		caseSaveButton.set("v.disabled", false);
       	}
   	}
})