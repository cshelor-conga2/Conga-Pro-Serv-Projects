crmc.require(["KendoEntry", "KendoPopup", "sfdc", "CustomSettings"], function(kendoEntry, kendoPopup, sfdc, customSettings) {
  //https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_packagelicense.htm
  crmc.addCustomAction({
    "itemID": "AG_BatchAdd_License",
    "isBatchAddItem": true,
    "isAvailable": function (context) {
      var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
      var isAccessible = context.objectDescribe.name == "User";
      var multipleSelected = context.selectedRows && context.selectedRows.length > 0;
      return isAccessible && isEnabled && multipleSelected;
    },
    "getLabel": function (context) {
      return "AG License";
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
      //ActionGrid Package License record.
      var ag = sfdc.query("SELECT Id, AllowedLicenses,UsedLicenses,NamespacePrefix,Status FROM PackageLicense WHERE NamespacePrefix = 'CRMC_PP'");
      //The amount of allowed licenses.
      var allowedLicenses = parseInt(ag[0].AllowedLicenses);
      //The amount of used licenses.
      var usedLicenses = parseInt(ag[0].UsedLicenses);
      //Check if there are any free Licenses.
      if(allowedLicenses > usedLicenses){
        //Get a list of the current licensed users within the selection.
        var licensedUsers = sfdc.query(kendo.format("SELECT Id, UserId FROM UserPackageLicense WHERE PackageLicenseId = '{0}' AND UserId IN('" + userIds.join("','") + "')" , ag[0].Id));
        //Number of free licenses.
        var free = (allowedLicenses - usedLicenses);
        //Number of unlicensed users in selection.
        var unLicensedUsers = (userIds.length - licensedUsers.length);
         //Users without a license? Will there be enough open licenses to assign to the selected unlicensed users.
        if(unLicensedUsers > 0 && unLicensedUsers <= free){
          //list of new record definitions.
          var records = [];
          //Check if a specific user has a license.
          var hasLicense = function(userId){
            for (var i = 0; i < licensedUsers.length; i++) {
              if(licensedUsers[i].UserId == userId) return true;
            }
            return false;
          };

          //Loop though the selected records.
          for (var i = 0; i < userIds.length; i++) {
            //Does the user have a license?
            if(!hasLicense(userIds[i])){
              //Create the license record definition.
              var userPackageLicense = new sforce.SObject('UserPackageLicense');
              userPackageLicense.UserId = userIds[i];
              userPackageLicense.PackageLicenseId = ag[0].Id;
              records.push(userPackageLicense);
            }
          }
          //Results function.
          var onFinish = function(results) {
            var recordIds = [];
            var message = ["<ul> Success: "];
            var success = 0;
            var errors = ["<ul> Errors:", "</br>"];
            for (var i = 0; i < results.length; i++) {
              var result = results[i];
              if (result.success == "true"){ 
                success++; 
                recordIds.push(result.id);
              }
              else if(result.errors && result.errors.message !== undefined) errors.push(result.errors.message+"</br>");
              else{
                errors.push("<li>"+result+"</li>");
              }
            }
            message[0] = message[0] + success;
            message.push("</ul>");
            message.push("<ul> Already Converted: " + licensedUsers.length + "</ul>");
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

          //Create the license records.
          sfdc.batchInsert(records, onFinish);
        }
        else{
          var body = "";
          if(unLicensedUsers === 0) body = "All Selected users have a license.";
          else body = "Selected users without a license exceeds the availability of unssigned licenses.";
          kendoPopup.popupWithButtons("Available: " + ag[0].AllowedLicenses + ", Selected w/out License: " + unLicensedUsers, body, [{label: "Ok"}], {width: 400});
        }
      }
      else{
        kendoPopup.popupWithButtons("Warning: Out of Licenses", "Please get more licenses or remove some users.", [{label: "Ok"}]);//{width: 900}
      }
    }
  });
});