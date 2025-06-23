({
	onInit : function(component, event, helper) {
        var name = "startURL";
        name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
        var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
        var results = regex.exec(location.search);
        var startURL = results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
        console.log("startURL: " + startURL);
        component.set("v.startURL",startURL);
	},
    
    onLinkClicked : function(component, event, helper) {
        console.log('here');
        var loginDiscoveryUrl = "/partners/apex/LoginDiscovery";
        
        var startURL = component.get("v.startURL");
        if(startURL) {
            loginDiscoveryUrl += "?startURL=" + startURL;
        }
        window.location = loginDiscoveryUrl;
        /*var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": loginDiscoveryUrl
        });
        urlEvent.fire();*/
    }
})