crmc.require(["KendoEntry", "KendoPopup", "sfdc", "CustomSettings"], function(kendoEntry, kendoPopup, sfdc, customSettings) {
  crmc.addCustomAction({
    "itemID": "AG_BatchAdd_PermissionSetAssignment",
    "isBatchAddItem": true,
    "isAvailable": function (context) {
      var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
      var isAccessible = context.objectDescribe.name == "User";
      var multipleSelected = context.selectedRows && context.selectedRows.length > 0;
      return isAccessible && isEnabled && multipleSelected;
    },
    "getLabel": function (context) {
      return "Permission Set";
    },
    "createSubmenuItems": function (context) {
      return [];
    },
    "click": function (context) {
      //Selected user Ids.
      var userIds = [];
      context.selectedRows.map(function(row) {
          userIds.push(row.Id);
      });

      /*
         * Define the PermissionSetAssignment objects.
         * @permissionSet {string} PermissionSet Id string..
      */
      var defineAssignment = function(permissionSet){
        //ActionGrid Users PermissionSet record.
        //var ag = sfdc.query("SELECT Id FROM PermissionSet WHERE Name = 'ActionGrid_Users' AND NamespacePrefix = 'CRMC_PP'");
        //list of new record definitions.
        var records = [];
        //Loop though the selected records.
        for (var i = 0; i < userIds.length; i++) {
          //Create the license record definition.
          var permissionSetAssignment = new sforce.SObject('PermissionSetAssignment');
          permissionSetAssignment.AssigneeId = userIds[i];
          permissionSetAssignment.PermissionSetId = permissionSet;
          records.push(permissionSetAssignment);
        }
        /*
         * Display the results.
         * @results {Object} Salesforce result Object.
        */
        var onFinish = function(results) {
          var recordIds = [];
          var message = ["<ul> Success: "];
          var success = 0;
          var dups = 0;
          var errors = ["<ul> Errors:", "</br>"];
          for (var i = 0; i < results.length; i++) {
            var result = results[i];
            if (result.success == "true"){ 
              success++; 
              recordIds.push(result.id);
            }
            else if(result.errors && result.errors.statusCode && result.errors.statusCode == "DUPLICATE_VALUE") dups++;
            else if(result.errors && result.errors.message !== undefined) errors.push(result.errors.message+"</br>");
            else{
              errors.push("<li>"+result+"</li>");
            }
          }
          message[0] = message[0] + success;
          message.push("</ul>");
          message.push("<ul> Already in Set: " + dups + "</ul>");
          if(errors.length > 2) {
            message = message.concat(errors);
            message.push("</ul>");
          }
          else message.push(errors[0] + " 0</ul>");
          console.log(message);
          var buttons = [
            {
              label: "View Records",
              click:function(){
                window.open(kendo.format("/apex/CRMC_PP__crmc_grid?object={0}&Ids={1}", 'UserPackageLicense', recordIds.join()));
              }
            },
            {
              label: "Close"
            }
          ];
          kendoPopup.popupWithButtons("Results", message.join(""), buttons);
        };
        //Create the PermissionSetAssignment records.
        sfdc.batchInsert(records, onFinish);
      };
      //Query for a list of available PermissionSet records.
      var sets = sfdc.query("SELECT Id,Label,Name,NamespacePrefix FROM PermissionSet");
      //Check if there were any PermissionSets returned.
      if(sets.length > 0){
        /*
         * Returns an Array of Javascript Objects that define a PermissionSet Picklist.
         * @return {Number} sum
        */
        var getPicklist = function(){
          //List of permission sets.
          var permissionSets = [];
          for (var i = 0; i < sets.length; i++) {
            var set = sets[i];
            var isActionGridUsers = (set.Name == "ActionGrid_Users" && set.NamespacePrefix =="CRMC_PP") ? true : false;
            var label = set.Label + " (" + set.Name + ")";
            if(set.Name != 'X' + set.Label) permissionSets.push({active: "true", defaultValue: isActionGridUsers , label: label, value: set.Id});
          }
          return permissionSets;
        };

        // Display the BatchAdd Permission Set UI.
        kendoEntry.entry("BatchAdd Permission Set",
          [ 
            {name: 'PermissionSet', label: 'Permission Set', type: "picklist", values: getPicklist(), required: false},
          ], 
          {width: 350},
          null,
          function(selectedValues) {
            defineAssignment(selectedValues.PermissionSet.value);
        });
      }
      else{
        //Alert the user that there are no available Permission Sets in the organization.
        kendoPopup.popupWithButtons("WARNING", "There are no available PermissionSet objects", [{label: "Close"}]);
      }
    }
  });
});