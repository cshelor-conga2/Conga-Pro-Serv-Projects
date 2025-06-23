({
	serverCallHelper : function(component, event, helper) {  
    	return new Promise($A.getCallback(function (resolve, reject) {
			var recordId = component.get("v.recordId");
			var action = component.get('c.getContactList');
			action.setStorable();
			
			action.setParams({
				pAccountId : recordId
			});

			action.setCallback(this,function(a){
				if (a.getState() === 'SUCCESS') {
					component.set("v.contacts", a.getReturnValue());
					resolve(a.getReturnValue());
				}
			});
			var assetAction = component.get('c.getAssetList');
			assetAction.setStorable();
			
			assetAction.setParams({
				pAccountId : recordId
			});

			assetAction.setCallback(this,function(a){
				if (a.getState() === 'SUCCESS') {
					component.set("v.assets", a.getReturnValue());
				}
			});
			$A.enqueueAction(action); 
			$A.enqueueAction(assetAction);
		}));
    },

    saveHelper : function(component, event, helper){
		component.set("v.isSaving", true);
		var usersToCreate = component.get("v.usersToCreate");
		var assetsToCreate = component.get("v.assets");
		var recordId = component.get("v.recordId");
		var context = component.get("v.userContext");
		var resultsToast = $A.get("e.force:showToast");
		if(usersToCreate.length > 0 && assetsToCreate.length > 0){
			resultsToast.setParams({
                "mode": "dismissible", 
                "duration": 3000, 
				"title": "",
				"message": "The new Conga Account and Users are being created!",
				"type": "info"
			});
			// $A.get("e.force:closeQuickAction").fire();
			resultsToast.fire();
			var action = component.get('c.createCongaAccount');
			//action.setStorable();
			action.setParams({
				pAccountId: recordId,
				pUsersToCreate: usersToCreate,
				pAssets: assetsToCreate
			});
			action.setCallback(this,function(a){
				if (a.getReturnValue() === 'SUCCESS' && a.getState() === 'SUCCESS') {
					// SUCCESS! PREPARE A TOAST UI MESSAGE
					var resultsToast = $A.get("e.force:showToast");
					resultsToast.setParams({
                        "mode": "sticky",
						"title": "Success",
						"message": "The new Conga Account and Users have been created!",
						"type": "success"
					});
					if(context != undefined) {
						if(context == 'Theme4t' || context == 'Theme4d') {
							$A.get("e.force:closeQuickAction").fire();
						} else {
							var recordId = component.get("v.recordId");
							window.location.assign('/'+recordId);
							alert('Success');
						}
					} else {
						$A.get("e.force:closeQuickAction").fire();
					}
					resultsToast.fire();
					component.set("v.isSaving", false);
				}
				else if (a.getState() === "INCOMPLETE") {
					console.log("User is offline, device doesn't support drafts.");
					component.set("v.isSaving", false);
					component.set("v.usersToCreate",[]); //JCDIAZ - 2020/04/06
				}
				else if (a.getReturnValue() == 'ERROR' && a.getState() === "SUCCESS") {
					component.set("v.usersToCreate",[]); //JCDIAZ - 2020/04/06					
					var errors = a.getError();
					if (errors) {
						if (errors[0] && errors[0].message) {
							var resultsToast = $A.get("e.force:showToast");
							resultsToast.setParams({
                                "mode": "dismissible", 
                                "duration": 8000,   
								"title": "Error",
								"message": 'An error occurred creating the Account and Users.',
								"type": "error"
							});
							resultsToast.fire();
							component.set("v.isSaving", false);
						}
					}
				}
				else if (a.getState() === "ERROR") {
					component.set("v.usersToCreate",[]); //JCDIAZ - 2020/04/06					
					var errors = a.getError();
					if (errors) {
						if (errors[0] && errors[0].message) {
							var resultsToast = $A.get("e.force:showToast");
							resultsToast.setParams({
                                "mode": "dismissible", 
                                "duration": 8000,                           
								"title": "Error",
								"message": errors[0].message,
								"type": "error"
							});
							resultsToast.fire();
							component.set("v.isSaving", false);
						}
					}
				}
				else {
					component.set("v.usersToCreate",[]); //JCDIAZ - 2020/04/06					
					console.log('Unknown problem, state: ' + a.getState() + ', error: ' + a.getError());
					component.set("v.isSaving", false);
				}
			});
			$A.enqueueAction(action); 
		} else if (usersToCreate.length === 0) {
			var resultsToast = $A.get("e.force:showToast");
			resultsToast.setParams({
                "mode": "dismissible", 
                "duration": 5000, 
				"title": "Error",
				"message": "You have not selected any Contacts to create as Conga Users.",
				"type" : "error"
			});
			resultsToast.fire();
			component.set("v.isSaving", false);
		} else if (assetsToCreate.length === 0) {
			var resultsToast = $A.get("e.force:showToast");
			resultsToast.setParams({
                "mode": "dismissible", 
                "duration": 5000,                
				"title": "Error",
				"message": "You do not have any valid Conga AI products assoicated to this Account.",
				"type" : "error"
			});
			resultsToast.fire();
			component.set("v.isSaving", false);
		}

    },
})