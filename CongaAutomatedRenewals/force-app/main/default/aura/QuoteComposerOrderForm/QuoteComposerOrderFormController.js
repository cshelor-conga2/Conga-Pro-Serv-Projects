({
	doInit : function(component, event, helper) {
		window.setTimeout($A.getCallback(function() {
			helper.openComposer(component, $A.getCallback(function() {
				$A.get("e.force:closeQuickAction").fire();
			}));
		}), 500);
	}
})