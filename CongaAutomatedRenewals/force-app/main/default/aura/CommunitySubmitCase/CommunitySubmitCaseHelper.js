({
 	handleReset: function(component, event, helper) {
        component.find('subjectField').reset();
        component.find('descriptionField').reset();
        component.find('requestTypeField').reset();
        component.find('preferredContactMethodField').reset();
    }
})