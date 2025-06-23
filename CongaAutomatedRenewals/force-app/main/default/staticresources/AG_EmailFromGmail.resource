/**
    * @author CRMCulture
    * @version 1.00
    * @description Batch process emails with Gmail.
    
    * @param kendoEntry        ActionGrid helper for Kendo UI modal entry forms.
    * @param kendoPopup        ActionGrid helper for Kendo UI model message windows.
    * @param sfdc              ActionGrid helper for Salesforce REST API's
*/
crmc.require(["KendoEntry", "KendoPopup", "sfdc"], function(kendoEntry, kendoPopup, sfdc) {
    crmc.addCustomAction({
    "itemID": "EmailFromGmail",
        isAvailable: function(context) {
            var isOkContext = ["Lead", "Contact", "Opportunity", "AccountContactRole"].indexOf(context.objectDescribe.name) > -1;
            var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
            return isOkContext && isEnabled;
        },
        "getLabel": function(context) {
            return "Send Gmail";
        },
        "createSubmenuItems": function(context) {
            return [];
        },
        "click": function(context) {
                var userInfo = sfdc.getUserInfo();
                var emailList = [];
                var page = window.location.href;

                if (context.objectDescribe.name == "Lead" || context.objectDescribe.name == "Contact") {
                    context.selectedRows.map(function(row) {
                        emailList.push(row.Email);
                    });
                } 

                else if(context.objectDescribe.name == "Opportunity" || context.objectDescribe.name == "AccountContactRole"){
                    var actIds = [];
                    context.selectedRows.map(function(row) {
                        actIds.push(row.AccountId);
                    });
                    var data = sfdc.query("SELECT Contact.Email FROM AccountContactRole WHERE IsPrimary = true AND AccountId IN('" + actIds.join("','") + "')")
                    data.map(function(row){
                        emailList.push(row.Contact.Email);
                    }); 
                }
            function processURL() {
                var emailToSalesforceQuery = sfdc.query("SELECT EmailDomainName, LocalPart FROM EmailServicesAddress WHERE RunAsUserId='" + userInfo.userId + "'")

                var emailToSalesforceEmail = emailToSalesforceQuery[0].LocalPart + "@" + emailToSalesforceQuery[0].EmailDomainName;

                for (var i = 0; i < emailList.length; i++) {
                    var gmailURLpt1 = "view=cm&fs=1&tf=1&to=" + emailList[i] + "&bcc=" + emailToSalesforceEmail;
                    var encodeGmailPt1 = encodeURIComponent(gmailURLpt1);
                    var gmailURLPt2 = "http://mail.google.com/a/appextremes.com/mail?" + encodeGmailPt1;
                    // var encodeGmailPt2 = encodeURIComponent(gmailURLPt2);
                    var finalGmail = "/google/googleSplash.apexp?app=GMAIL&appURL=" + gmailURLPt2;
                    window.open(finalGmail);
                };
            }

            if (context.selectedRows.length > 5) {
                var buttons = [{
                    label: "Yes",
                    click: function() {
                        processURL();
                    }
                }, {
                    label: "No"
                }];
                kendoPopup.popupWithButtons("WARNING", "5 records are recommended because each item will show in a new tab. Do you want to continue?", buttons);
            } 
            else if(emailList.indexOf('undefined') > -1){
                kendoPopup.popup("Error","Some Opportunities Missing Primary Contacts");
            }        
            else {
                processURL();
            }
        }
    });
});

//     crmc.addCustomAction({
//         actions: [EmailFromGmail],
//         "itemID": "EmailFromGmail",
//         isAvailable: function(context) {
//             var isOkContext = ["Lead", "Contact", "Opportunity", "AccountContactRole"].indexOf(context.objectDescribe.name) > -1;
//             var isEnabled = this.featureSecurity.getSetting(context.objectDescribe.name, this.itemID) !== false;
//             return isOkContext && isEnabled;
//         },
//         "getLabel": function(context) {
//             return "Send Email...";
//         },
//         "createSubmenuItems": function(context) {
//             return this.actions;
//         },
//         "click": function(context) {}
//     });
// });
