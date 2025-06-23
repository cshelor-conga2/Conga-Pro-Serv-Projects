crmc.addCustomAction({
  itemID: "AG_CreateProject",
  isAvailable: function(context) {
    // This function is called before the action item is displayed and returns a boolean if the item should be displayed
    // By default determine availability based on Feature Security for this action
    return this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;

  },
  isHeaderAvailable: function(context) {
    // This function determines if this item can be displayed from the column header menu
    return false;
  },
  isToolbarAvailable: function(context) {
    // This function determines if this item can be displayed in the Toolbar as a button
    return false;
  },
  getLabel: function(context) {
    // This function returns the display label of the action item and is called before the item is shown
    return "Create Project";
  },
  createSubmenuItems: function(context) {
    // If this function returns additional action item objects, they will appear as submenu items
    return [];
  },
  click: function(context) {
    // This function is what is executed when the action item is clicked
    // Context object has this format:
    /* {
        objectDescribe: metadata for current object
        selectedRows: rows selected in AG
        loadedRows: all rows loaded in AG
        isHeader: true if header column initiated action
        selectedColumn: if header Action, info about the column which was clicked
        kendoGrid: kendoGrid object
    } */
    var ids = [];
         context.selectedRows.map(function(row) {
             ids.push(row.Id);
         });    
    window.open("https://c.na3.visual.force.com/apex/CreateProject?id="+ids.join(","),"_blank");
  }
});