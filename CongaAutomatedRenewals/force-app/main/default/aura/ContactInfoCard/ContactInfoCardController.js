({
  init : function(component, event, helper) {
      var userAction = component.get("c.getUser");
    userAction.setCallback(this, function(data) {
        component.set("v.currentUserId", data.getReturnValue().Id);
    });
    $A.enqueueAction(userAction);
   },
    toggleMode : function(component, event, helper) {
        component.set("v.editMode", !component.get("v.editMode"));
    },
    handleEvent: function(component, event, helper) {
    // refresh Component A here
    var editMode = event.getParam("editMode");
    component.set("v.editMode", editMode);
}
})