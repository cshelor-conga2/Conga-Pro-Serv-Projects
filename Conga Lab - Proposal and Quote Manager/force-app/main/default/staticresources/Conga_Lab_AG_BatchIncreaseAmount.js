/*  
   * @author Conga
   * @version 1.00
   * @description Batch update a sales price with a discount.
*/
crmc.require(["KendoEntry", "KendoPopup", "ListButton", "sfdc"], function(prompt, popup, navigate, sfdc) {

  var TEXT_BATCH_Update_OBJECT = "Batch Update Opportunties";
  var TEXT_ERROR = "There was an error: ";
  var TEXT_MESSAGE = "Updated {0} Opportunities, would you like to refresh the page?";
  var TEXT_BATCH_UPDATE_RESULTS = "Batch Update Results";
  var TEXT_YES = "Yes";
  var TEXT_NO = "No";

  crmc.addCustomAction({
    "itemID": "AG_BatchIncreaseAmount",
    "isAvailable": function (context) {
      // This function is called before the action item is displayed and returns a boolean if the item should be displayed
      // By default determine availability based on Feature Security for this action
      var isContext = context.objectDescribe.name == "Opportunity";
      var isSelected = context.selectedRows.length >= 1;
      var isAccessable = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
      return isAccessable && isSelected && isContext;
    },
    "getLabel": function (context) {
      // This function returns the display label of the action item and is called before the item is shown
      return "Batch Increase";
    },
    "createSubmenuItems": function (context) {
      // If this function returns additional action item objects, they will appear as submenu items
      return [];
    },
    "click": function (context) {
      // This function is what is executed when the action item is clicked
      
        var ids = [];
        context.selectedRows.map(function(row) {
          ids.push(row.Id);
      });
      prompt.entry("Batch Update Opportunities",
        [{name: "DisPer", label: 'Increase Percent (%)', type: "double", required: true, precision: 0}], 
        {width: 350},
        null,

        function(selectedValues) {
          var DisPer = selectedValues["DisPer"].value;
          var recordIds = [];
          var records = [];
          var recordUpdates = [];
          var onfailure = function(error) {
              alert(TEXT_ERROR + (error.message || error.faultstring));
          };

          var onsuccess = function(results){
          var newRecordIds = [];
          var success = 0;
          var failCount = 0;
          var failed = ["<ul>"];

          function ShowErrors(){
              popup.popupWithButtons("Errors", failed.join(""), [{label: "Ok"}], {width: 900});
          }

          for (var i = 0; i < results.length; i++) {
              if(results[i].success && results[i].success == "true"){
                  success++;
                  newRecordIds.push(results[i].id);
              }
              else{
                  failCount++;
                  //Does errors exist and does it have a message.
                  if(results[i].errors !==
          undefined && results[i].errors.message !== undefined){
                      failed.push("<li>"+results[i].errors.message+"</li>");
                  }//does errors exist and does it contain an Array of errors.
                  else if(results[i].errors !== undefined && results[i].errors instanceof Array){
                      var errors = results[i].errors;
                      for (var j = 0; j < errors.length; j++) {
                        failed.push("<li>"+errors[j].message+"</li>");
                      }
                  }
                  else{
                      failed.push("<li>"+results[i]+"</li>");
                  }
              }
          }
          failed.push("</ul>");

          if (newRecordIds.length > 0) {
              var message = kendo.format(TEXT_MESSAGE, success);
              var buttons = [{
                  label: TEXT_YES,
                  click: function() {
                      context.actionGrid.refresh();
                  }
              },
              {
                  label: TEXT_NO,
                  click: function(){
                      if(failCount>0){
                          ShowErrors();
                      }
                  }
              }];
              popup.popupWithButtons(TEXT_BATCH_UPDATE_RESULTS, message, buttons);
          }
          else{
              ShowErrors();
          }
          };

          var data= sfdc.query("SELECT Id, Amount FROM Opportunity WHERE Id IN('" + ids.join("','") + "')");
          for (var i = 0; i < data.length; i++) {
            var row = data[i];
            var record = new sforce.SObject("Opportunity");
            record["Amount"] = row.Amount*(1+(DisPer/100));
            record["Id"] = row.Id;
            records.push(record);
          }
            sforce.connection.update(records, {
                  onSuccess: onsuccess,
                  onFailure: onfailure
            });
        }
      );
    }
  });
});