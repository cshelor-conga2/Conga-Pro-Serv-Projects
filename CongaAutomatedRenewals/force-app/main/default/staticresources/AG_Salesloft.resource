crmc.require(["KendoPopup", "sfdc"], function(popup,sfdc){
   crmc.addCustomAction({
      "itemId":"AG_Salesloft",
      //"isBatchAddItem":true,
      "isAvailable": function(context){
            var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
            var isAccessible = context.objectDescribe.name == "Contact" || context.objectDescribe.name == "Lead" ;
            return isAccessible && isEnabled;
      },
      "getLabel": function(context){
           return kendo.format("Import to Salesloft");
      },
      "click": function(context){
       var ids = [];
       context.selectedRows.map(function(row){
        ids.push(row.Id);
       });
       
       var data = ids.join(",");

        if(context.objectDescribe.name == "Lead"){
               window.open("https://app.salesloft.com/app/import/crm?lead=" + data);
        }
        else if(context.objectDescribe.name == "Contact"){
            window.open("https://app.salesloft.com/app/import/crm?contact=" + data);
        }
        else{
               popup.popup('Please select records','Please select records to import to Salesloft');
        }

      }
   }); 
});