crmc.addCustomAction({
  "itemID": "AG_Convert_Lead",
  "isAvailable": function (context) {
    // This function is called before the action item is displayed and returns a boolean if the item should be displayed
    // By default determine availability based on Feature Security for this action
    var multipleSelected = context.selectedRows && context.selectedRows.length > 0;
    var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
    return multipleSelected && isEnabled;
  },
  "getLabel": function (context) {
    // This function returns the display label of the action item and is called before the item is shown
    return "Convert";
  },
  "createSubmenuItems": function (context) {
    // If this function returns additional action item objects, they will appear as submenu items
    return [];
  },
  "click": function (context) {
    // This function is what is executed when the action item is clicked
    // Context object has this format:
    /* {
        selectedRows: rows selected in AG
        loadedRows: all rows loaded in AG
        objectDescribe: metadata for current custom object
        kendoGrid: kendoGrid object
    } */
    function processURL(){
        var ids = [];
        var page;
        // If related list and in iframe
        if (context.actionGrid.settings.fkValue && window.top != window) {
            page = "/" + context.actionGrid.settings.fkValue;
        }
        else{
            page = window.location.href;
        }
        context.selectedRows.map(function(row) {
            ids.push(row.Id);
        });
        for (var i = 0; i < ids.length; i++) {
            window.open("/lead/leadconvert.jsp?retURL="+ page +"&id="+ ids[i] +"&_CONFIRMATIONTOKEN=VmpFPSxNakF4Tmkwd09DMHlNbFF4TlRveU5Ub3hNeTR5T1RWYSxGZXJuVE9ldmJyUG9LRUpuSUpDajhZLE4yWTBNVEJt&common.udd.actions.ActionsUtilORIG_URI=%2Flead%2Fleadconvert.jsp", "_blank");
        };
    }
    if(context.selectedRows.length > 5){
        var buttons = [{
            label: "Yes",
            click: function() {
                processURL();
            }
        },
        {
            label: "No"
        }];
        kendoPopup.popupWithButtons("WARNING", "5 records are recommended because each item will show in a new tab. Do you want to continue?", buttons);
    }
    else{
        processURL();
    }
  }
});