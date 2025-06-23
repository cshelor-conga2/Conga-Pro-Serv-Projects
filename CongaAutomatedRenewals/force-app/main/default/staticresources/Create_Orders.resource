crmc.require(["sfdc"], function(sfdc) {
    crmc.addCustomAction({
  "itemID": "Batch_Process_Orders_From_Projects",
  "isAvailable": function (context) {
    // This function is called before the action item is displayed and returns a boolean if the item should be displayed
    // By default determine availability based on Feature Security for this action
     var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
      // Only allow batch adding from Accounts object for now
      var isProject = context.objectDescribe.name == "PS_Project__c";
      var multipleSelected = context.selectedRows && context.selectedRows.length > 0;
      return isProject && isEnabled && multipleSelected;
  },
  "getLabel": function (context) {
    // This function returns the display label of the action item and is called before the item is shown
    return "Create Order(s)";
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
    var ids = [];
      // Show a prompt that contains the fields in FIELDSETNAME
         // For every selected row
    context.selectedRows.map(function(row) {
      ids.push(row.Id);
    });
    //window.open("/apex/Project_List_Create_Order?projectRecordIds=" + ids.join('%2c'));
    sfdc.navigateToVFPage("c", "Project_List_Create_Order", {projectRecordIds:ids.join(',')});

  }
});});