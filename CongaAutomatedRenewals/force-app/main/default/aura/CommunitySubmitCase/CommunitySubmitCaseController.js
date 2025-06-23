({
    openModal : function(component, event, helper) {
        document.getElementById("modaldialog").style.display = "block";
        document.getElementById("dialogbackdrop").style.display = "block";
        
        var getUserInfo = component.get('c.getUserInfo');
        getUserInfo.setParams({
            "pUserId" : $A.get("$SObjectType.CurrentUser.Id")
        });
        getUserInfo.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                component.set("v.userContactId", a.getReturnValue().ContactId);
            }
        });
        $A.enqueueAction(getUserInfo);   
    },
   
    closeModal : function(component, event, helper) {
        document.getElementById("modaldialog").style.display = "none";
        document.getElementById("dialogbackdrop").style.display = "none";
        helper.handleReset(component, event, helper);
    },
    
    handleSuccess: function(component, event, helper) {
        document.getElementById("modaldialog").style.display = "none";
        document.getElementById("dialogbackdrop").style.display = "none";       
        component.set("v.showSpinner", false);
        helper.handleReset(component, event, helper);
        
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "type": "success",
            "title": "Success",
            "message": "The case was submitted. Thank you!"
        });
        resultsToast.fire();
    },
    
    handleSubmit: function(component, event, helper) {
        component.set("v.showSpinner", true);
        event.preventDefault();
        
        var userContactId = component.get('v.userContactId');;       
       
        // ALLOW SUBMIT IF A USER CONTACT WAS FOUND       
    	if(userContactId != null){
           	var caseFields = event.getParam("fields");
           	caseFields["ContactId"] = userContactId;
           	caseFields["Origin"] = component.get("v.caseOrigin");
         	component.find("recordEditForm").submit(caseFields);
        }
        // OTHERWISE STOP SUBMIT AND INFORM USER
        else{
            component.set("v.showSpinner", false);
            try{
                throw new Error("No User Contact found for your user.");
            }
            catch(e){
                var resultsToast = $A.get("e.force:showToast");
            	resultsToast.setParams({
                    "mode": 'dismissible',
                    "duration": 15000,
                    "type": "error",
                    "title": "Error",
                    "message": "No User Contact found for your user. Only community users can use this functionality."
                });
            
                resultsToast.fire();               
            }
        }
    }
    
    
})