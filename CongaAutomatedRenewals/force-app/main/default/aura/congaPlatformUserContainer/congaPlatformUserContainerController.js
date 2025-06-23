({
    serverCall :  function(component, event, helper) {
        helper.serverCallHelper(component, event, helper);
    },

    //THIS FUNCTION IS USED TO SELECT AND DE-SELECT ALL CHECKBOX.
    selectAll : function(component, event, helper) {
        
        var checkboxContent = component.find("checkbox");
        var checkboxContentval = checkboxContent.get("v.value");
        var CompleteWrap = component.get("v.contacts");
        for(var i=0; i < CompleteWrap.length; i++){     
            CompleteWrap[i].IsChecked = checkboxContentval;
        }
        component.set("v.contacts", CompleteWrap);
	},
	
	handleCreateUsers: function(component, event, helper) {
		var contactArr = component.get("v.contacts");
		console.log('contactArr',contactArr);
        var usersToCreate = [];
        contactArr.forEach(element => {
			if (element.IsChecked) {
                usersToCreate.push(element);
            }
		});
		console.log('usersToCreate',usersToCreate);
        component.set("v.usersToCreate", usersToCreate);
        helper.saveHelper(component, event, helper);
    },

    handleCancel: function(component, event, helper) {
        var context = component.get("v.userContext");
        if(context != undefined) {
            if(context == 'Theme4t' || context == 'Theme4d') {
                $A.get("e.force:closeQuickAction").fire();
            } else {
                var recordId = component.get("v.recordId");
                window.location.assign('/'+recordId);
            }
        } else {
            $A.get("e.force:closeQuickAction").fire();
        }
	},
	
	radioChangeHandler: function(component, event, helper) {
		console.log('event',event);		
		var contact = event.getSource().get("v.value");
		var contactArr = component.get("v.contacts");
        contactArr.forEach(element => {
			if (element.ContactId == contact.ContactId) {
				element.IsChecked = true;
            } else {
				element.IsChecked = false;
			}
		});
		component.set("v.contacts",contactArr);
	}
})