crmc.require(["KendoPopup", "sfdc"], function(popup,sfdc){
   crmc.addCustomAction({
      "itemId":"AG_Salesloft_CM",
      //"isBatchAddItem":true,
      "isAvailable": function(context){
            var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
            var isAccessible = context.objectDescribe.name == "CampaignMember" ;
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

       var data = sfdc.query("SELECT Id, ContactId FROM "+ context.objectDescribe.name +" WHERE Id IN('" + ids.join("','") + "')");
       var finalIds = [];
       data.map(function(rows){
           finalIds.push(rows.ContactId);
       });
       
       var urlIds = finalIds.join(",");

        if(context.objectDescribe.name == "CampaignMember"){
               window.open("https://app.salesloft.com/app/import/crm?contact=" + urlIds );
        }
        else{
               popup.popup('Please select records','Please select records to import to Salesloft');
        }

      }
   }); 
});