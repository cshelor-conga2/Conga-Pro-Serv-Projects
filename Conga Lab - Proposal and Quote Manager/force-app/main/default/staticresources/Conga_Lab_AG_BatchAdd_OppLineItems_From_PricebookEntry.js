crmc.require(["KendoEntry", "KendoPopup", "ListButton", "sfdc", "GridBase"], function(prompt, popup, navigate, sfdc, gridFactory) {

/**
    * @author Conga
    * @description Batch create OpportunityLineItems from Products.
    * @version 1.00
*/

/**
    *   "ITEM_ID" Is the ID that uniquely identifies our Action item.
    *   "CONTEXT_OBJECT" Is the context object that your action is based on.
    *   "CREATE_OBJECT" Is the name of the object that you are batch creating and/or updating.
    *   "SINGULAR_NAME" Is the singular label text of CREATE_OBJECT.
    *   "PLURAL_NAME" Is the plural version of the SINGULAR_NAME.

*/
var ITEM_ID = "AG_BatchAdd_OppLineItems_From_PricebookEntry";
var CONTEXT_OBJECT = "PricebookEntry";
var CREATE_OBJECT = "OpportunityLineItem";
var SINGULAR_NAME = "Opp Product";
var PLURAL_NAME = "Opp Products";

/** Language strings.*/
var TEXT_BATCH_ADD_OBJECT = "Batch Add" + PLURAL_NAME;
var TEXT_ERROR = "There was an error: ";
var TEXT_MESSAGE = "Added {0} " + PLURAL_NAME;
var TEXT_BATCH_ADD_RESULTS = "Batch Add Results";
var TEXT_YES = "Yes";
var TEXT_NO = "No";
var TEXT_OK = "OK";

//////////////////////////////////////
/**
    * Custom action core code below.
*/
//////////////////////////////////////


crmc.addCustomAction({
    
    "itemID": ITEM_ID,
    
    "isBatchAddItem": true,
    
     isToolbarAvailable: function(context) {
      // This function determines if this item can be displayed in the Toolbar as a button
      var showOnToolbar = false;
      // Only allow the button from the CONTEXT_OBJECT object for now, in this case CONTEXT_OBJECT = "Account"
      var isAccessible = context.objectDescribe.name == CONTEXT_OBJECT;
      //purposefully not using the isAccessible because I don't want it to show on the Menu but do want to show it on the toolbar, thus in Settings it is Disabled so Line 83 fails it
      // var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
     
    return showOnToolbar && isAccessible ;
    },
    
    "isAvailable": function (context) {  
        var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
        var isAccessible = context.objectDescribe.name == CONTEXT_OBJECT;
        var multipleSelected = context.selectedRows && context.selectedRows.length > 0;
        return isAccessible && isEnabled && multipleSelected;
    },
    
    "getLabel": function (context) {
        return kendo.format(PLURAL_NAME + " ({0}) ", context.selectedRows.length);
    },
    
    "click": function (context) {
        var success = 0;
        var failCount = 0;
        var failed = ["<ul>"];
        var records = [];
        var recordIds = [];
        var onfailure = function(error) {
            alert(TEXT_ERROR + (error.message || error.faultstring));
        };
         var onsuccess = function(results){
            function ShowErrors(){
                popup.popupWithButtons("Errors", failed.join(""), [{label: "Ok"}], {width: 900});
            }
            for (var i = 0; i < results.length; i++) {
                if(results[i].success && results[i].success == "true"){
                    success++;
                    recordIds.push(results[i].id);
                }
                else{
                    failCount++;
                    if(results[i].errors !== undefined && results[i].errors.message !== undefined){
                        failed.push("<li>"+results[i].errors.message+"</li>");
                    }
                    else{
                        failed.push("<li>"+results[i]+"</li>");
                    }
                }
            }
            failed.push("</ul>");

            if(recordIds.length > 0) {
               var message = kendo.format(TEXT_MESSAGE, success);
               var buttons = [{
                    label: TEXT_OK,
                    click: function(){
                        if(failCount>0){
                            ShowErrors();
                        }
                        else {
                            Object.each(gridFactory.instances, function(grid) {
                                if (grid.settings.pageInfo.objectName == "OpportunityLineItem") {
                                  grid.refresh();
                                }
                            });
                        }
                     }
                }];
                popup.popupWithButtons(TEXT_BATCH_ADD_RESULTS, message, buttons);
            }
            else{
                ShowErrors();
            }
        }
        var process = function(){
            sforce.connection.create(records, {
                onSuccess: onsuccess,
                onFailure: onfailure
            });
        };
        prompt.entry("Batch Add Products",
            [{name: "Quantity", label: "Quantity", type: "double", precision: 0, required: true}],
            {width: 350, objectName: "Opportunity"},
            null,
            function(selectedValues) {
                var quantity = selectedValues.Quantity.value;
                var opportunityId = window.OPPORTUNITY.Id; 
                if (context.selectedRows[0].UnitPrice === undefined)
                  {
                      context.selectedRows = sfdc.query("SELECT Id, UnitPrice FROM PricebookEntry WHERE Id in ('" +
                          context.selectedRows.map(function(r){return r.Id;}).join("','") + "')");
                  }

                  context.selectedRows.map(function(row) {
                          var record = new sforce.SObject(CREATE_OBJECT);
                          record.PricebookEntryId = row.Id;
                          record.TotalPrice = quantity * row.UnitPrice;
                          record.Quantity = quantity;
                          record.OpportunityId = opportunityId;
                          records.push(record);  
                  });

                  if(context.selectedRows.length > 200){
                      sfdc.batchInsert(records, onsuccess);

                  } else {
                      process();
                  }
            }
        );
    }
});
});