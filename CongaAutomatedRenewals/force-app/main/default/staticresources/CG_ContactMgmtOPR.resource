crmc.require(["KendoPopup", "sfdc"], function(popup,sfdc){
   crmc.addCustomAction({
      "itemId":"CG_ContactMgmtOPR",
      //"isBatchAddItem":true,
      "isAvailable": function(context){
            var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
            var isAccessible = context.objectDescribe.name == "OpportunityContactRole" && context.selectedRows.length == 1 ;
            return isAccessible && isEnabled;
      },
      "getLabel": function(context){
           return kendo.format("Contact Management OPR");
      },
      "click": function(context){
       
       var ids = [];

       context.selectedRows.map(function(row){
        ids.push(row.Id);
       });

       var data = sfdc.query("SELECT Id, Contact.AccountId FROM "+context.objectDescribe.name+" WHERE Id IN('" + ids.join("','") + "')");

        if(context.objectDescribe.name == "OpportunityContactRole"){
               window.open("https://getconga--full--c.cs36.visual.force.com/apex/AccountContactTable?accountId=" + data[0].Contact.AccountId);
        }

        else{
               popup.popup('Please select record','Please select record for Contact Management');
        }

      }
   }); 
});