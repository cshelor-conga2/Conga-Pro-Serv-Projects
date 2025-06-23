crmc.require(["KendoPopup", "sfdc"], function(popup,sfdc){
   crmc.addCustomAction({
      "itemId":"CG_ContactMgmt",
      //"isBatchAddItem":true,
      "isAvailable": function(context){
            var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
            var isAccessible = context.objectDescribe.name == "Opportunity" || "Account" || "OpportunityContactRole" && context.selectedRows.length == 1 ;
            return isAccessible && isEnabled;
      },
      "getLabel": function(context){
           return kendo.format("Contact Management");
      },
      "click": function(context){
       var ids = [];

       context.selectedRows.map(function(row){
        ids.push(row.Id); 
       });
       
       var data = ids.join(",");

        if(context.objectDescribe.name == "Opportunity"){
               window.open("/apex/AccountContactTable?opportunityId=" + data, '_blank');
        }
        
        else if(context.objectDescribe.name == "Account"){
            window.open("/apex/AccountContactTable?accountId=" + data, '_blank');
        }

        else{
               popup.popup('Please select record','Please select record for Contact Management');
        }

      }
   }); 
});