 /**
    * @author ActionGrid
    * @version 1.00
    * @description Use an APEX methdo to create orders from opporunity line items.
    *
    * @id AG_CreateOrdersFromLineItems     ActionGrid custom action id that is added to the name field.
    * @param sfdc              ActionGrid helper for Salesforce REST API's
*/
crmc.require(["sfdc", "KendoEntry", "KendoPopup"], function(sfdc, prompt, popup) {
    crmc.addCustomAction({
        "itemID": "AG_CreateOrdersFromLineItems",
        "isAvailable": function (context){
          var security = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
          var selected = context.selectedRows.length > 0;
          var correctObj = context.objectDescribe.name == "OpportunityLineItem";
          return security && selected && correctObj;
        },
        "getLabel": function (context){
          return "Create Order";
        },
        "createSubmenuItems": function (context){
          return [];
        },
        "InvokeApexMethod": function(className, methodName, parameters, callback) {
          var result;
          if (sforce && sforce.apex && sforce.apex.execute) {
            try{
              result = sforce.apex.execute(className, methodName, parameters);
              
            }
            catch(error){
              result = error.message;

            }
            if (typeof(callback) == "function"){
              callback(result);
            }
          }
          else {
          var that = this;
            sfdc.importScript("/soap/ajax/30.0/apex.js", function() {
              that.InvokeApexMethod(className, methodName, parameters, callback);
            });
          }
        },
        "click": function (context){
          var that = this;
          var ids = [];
            context.selectedRows.map(function(row) {
                ids.push(row.Id);
            });
          var oppLineItemIds = [];
          var selectedOppIds = [];
          var oppids = sfdc.query("SELECT OpportunityId FROM OpportunityLineitem WHERE Id IN ('" + ids.join("','") + "')");

          var onFinish = function(results){

            if (results[0].indexOf("Error") > -1){
              popup.popup("Error", results);
            }
            else {
              var orderId = results[0].split(" | ");
              window.open("/" + orderId[1], "_blank");
            }
          };
          for(var i=0; i < context.selectedRows.length; i++){
            oppLineItemIds.push(context.selectedRows[i].Id);
            if(selectedOppIds.indexOf(oppids[i].OpportunityId) < 0){
            selectedOppIds.push(oppids[i].OpportunityId);
            }
          }
          prompt.entry("Select Associated Opportunity",
            [{referenceTo: "Opportunity", name: "Opportunity", label: "Opportunity", type: "reference", required: true, filter:[{field:"Id",operator:"includes",value:selectedOppIds.join()}]}], 
            {width: 350, objectName: "OpportunityLineItem"},
            null, function(selectedValues){
              that.InvokeApexMethod("OpportunityHelper" , "CreateOrderFromLineItems", {oliIds: oppLineItemIds, oppId:selectedValues["Opportunity"].value}, onFinish);
            }
          );
        }
    });
});