'use strict';
(function($) {
    // global namespace
    window.APP_CONGA_ACCOUNT_CONTACT_TABLE = {
        opportunityId: $('input#opportunityId').val(),
        accountId: $('input#accountId').val(),
        accountContactRelationshipMaintenancePage: $('input#accountContactRelationshipMaintenancePage').val(),
        opportunityContactRoleMaintenancePage: $('input#opportunityContactRoleMaintenancePage').val(),
        appAccountContactTable: angular.module('appAccountContactTable', ['ngAnimate', 'ngSanitize', 'ngTable'])
    }

    // native JavaScript
    function decodeCharacters(str) {
        return str.replace(/amp;/g, '').replace(/lt;/g, '<').replace(/gt;/g, '>').replace(/&&/g, '&').replace(/&quot;/g, "'").replace(/&</,'<').replace(/&>/,'>').replace(/%20/g,' ').replace(/%22/g, '&#39;"').replace(/&#39;/, "'").replace(/&#39;/, "'");
    }

    function showAlert(msg) {
        $('span#alert-error-message').text(msg);
        $('i#fa-loader-create-contact').hide();
        $('i#fa-loader-process-changes').hide();
        $('div#alert-error').fadeIn();
    }

    function hideAlert() {
        $('div#alert-error, div#alert-success, i#fa-loader-reservation, i#fa-loader-reservation-upcoming, i#fa-loader-update-reservation, i#fa-loader-deposited-reservation, i#fa-loader-pre-arrival').hide();
    }

    function showSuccess(msg) {
        toastr.success(msg);
    }
   
    // AngularJS
    APP_CONGA_ACCOUNT_CONTACT_TABLE.appAccountContactTable.controller('ControllerAccountContactTable', ['$scope', '$sce', '$filter','NgTableParams','ngTableEventsChannel', function($scope, $sce, $filter, NgTableParams, ngTableEventsChannel) {
        // declare and initialize $scope variables
        $scope.currentYear = new Date().getFullYear();
        $scope.accountContacts = [];
        $scope.opportunityContacts = [];
        $scope.opportunityContactRoles = [];
        $scope.contactRoles = [];
        $scope.opportunityContactRolesToUpsert = [];
        $scope.opportunityContactRolesToDelete = [];
        $scope.contactsToUpsert = [];
        $scope.contactIds = [];
        $scope.accountContactsToUpsert = [];
        $scope.contact = {
            AccountId: APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId
        };
        $scope.accountContactRelation = {};
        $scope.selectedCount = 0;
        $scope.allSelected = false;
        $scope.existingContact = false;
        $scope.emailString = '';

        $scope.contactPersona = [];
        $scope.contactStatus = [];
        $scope.contactJobLevel = [];
        $scope.sortingOrder = 'IsPrimaryAccountRelation';
        $scope.reverse = true;
        $scope.closeWindowAfterProcessing = true;
        $scope.searchText="";

        var tableEvents = [];

        function subscribeToTable(tableParams){
            var logAfterCreatedEvent = logEvent (tableEvents, "afterCreated");
            ngTableEventsChannel.onAfterCreated(logAfterCreatedEvent, $scope, $scope.tableParams);
            var logAfterReloadDataEvent = logEvent ( tableEvents, "afterReloadData");
            ngTableEventsChannel.onAfterReloadData(logAfterReloadDataEvent, $scope, $scope.tableParams);
        }

        function logEvent(list, name){
            var theList = list;
            var theName = name;
            return function() {
                setTimeout(function() {
                    $('.js-example-basic-multiple').select2();
                }, 100);
            };
        }

        $scope.$watch("tableParams", subscribeToTable);

        $scope.getContactRoles = function(){
            AccountContactUtilities.getContactRoles(
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.contactRoles = result;
                        $scope.$apply();
                        hideAlert();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        }
        $scope.getContactRoles();

        $scope.getContactPersona = function(){
            AccountContactUtilities.getContactPersona(
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.contactPersona = result;
                        $scope.$apply();
                        hideAlert();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        }
        $scope.getContactPersona();

        $scope.getContactStatus = function(){
            AccountContactUtilities.getContactStatus(
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.contactStatus = result;
                        $scope.$apply();
                        hideAlert();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        }
        $scope.getContactStatus();

        $scope.getJobLevel = function(){
            AccountContactUtilities.getJobLevel(
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.contactJobLevel = result;
                        $scope.$apply();
                        hideAlert();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        }
        $scope.getJobLevel();

        $('[data-toggle="tooltip"]').tooltip();

        // $scope functions
        $scope.getAccountContacts = function() {
            $("#myPage").addClass("loading");
            $("#spinner").removeClass("slds-hidden");
            AccountContactUtilities.getAccountContacts(APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId,
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.accountContacts = result;
                        for(let i=0;i<$scope.accountContacts.length; i++){
                            $scope.allContactRoles(
                                $scope.accountContacts[i].ContactId, 
                                $scope.accountContacts[i].Contact.Name, 
                                $scope.accountContacts[i].Contact.Title, 
                                $scope.accountContacts[i].Contact.Email, 
                                i, 
                                false, 
                                false, 
                                $scope.accountContacts[i].Role, 
                                $scope.accountContacts[i].Persona__c, 
                                $scope.accountContacts[i].Status__c,
                                $scope.accountContacts[i].IsPrimary__c,
                                $scope.accountContacts[i].Job_Level__c
                            );
                        }
                        $scope.getOpportunityContactRoles();
                        $scope.$apply();
                        hideAlert();
                    }else {
                        showAlert(event.message);
                    }
                    $("#myPage").removeClass("loading");
                    $("#spinner").addClass("slds-hidden");
                },
                {buffer: false, escape: true}
            );
        };
        $scope.getAccountContacts(); // immediately invoke $scope function $scope.getAccountContacts()

        $scope.getRolesArrayFromOpportunityContacts = function(pContactId) {
            var roles = [];
            for(let i=0; i<$scope.opportunityContacts.length; i++){
                if($scope.opportunityContacts[i].ContactId == pContactId){
                    roles.push($scope.opportunityContacts[i].Role);
                }
            }
            return roles;
        };

        $scope.getRecordFromFromAccountRelation = function(pContactId) {
            for(let i=0;i<$scope.accountContacts.length; i++){
                if($scope.accountContacts[i].ContactId == pContactId){
                    return $scope.accountContacts[i];
                }
            }
        }

        $scope.getRolesArrayFromAccountRelationRecord = function(pRecord) {
            var roles = [];
            if (pRecord.Roles) {
                var rolesArray = pRecord.Roles.split(';');
                for (let j=0;j<rolesArray.length;j++) {
                    roles.push(rolesArray[j]);
                }
            }
            return roles;
        }

        $scope.getOpportunityContactRoles = function() {
            AccountContactUtilities.getOpportunityContactRoles(APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityId,
                function(result, event) {
                    var accountContactRelationRecord = null;
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.opportunityContacts = result;
                        for(let i=0; i<$scope.opportunityContacts.length; i++){
                            for(let j=0; j<$scope.opportunityContactRoles.length; j++){
                                if($scope.opportunityContacts[i].ContactId == $scope.opportunityContactRoles[j].ContactId){
                                    if (!$scope.opportunityContactRoles[j].Selected) {
                                        $scope.opportunityContactRoles[j].Selected = true;
                                        $scope.selectedCount++;
                                        $scope.opportunityContactRoles[j].Role = $scope.getRolesArrayFromOpportunityContacts($scope.opportunityContacts[i].ContactId);
                                        $scope.opportunityContactRoles[j].Id = $scope.opportunityContacts[i].Id;
                                        $scope.opportunityContactRoles[j].Email = $scope.opportunityContacts[i].Contact.Email;
                                        accountContactRelationRecord = $scope.getRecordFromFromAccountRelation($scope.opportunityContacts[i].ContactId);
                                        if (accountContactRelationRecord != null) {
                                            $scope.opportunityContactRoles[j].Persona = accountContactRelationRecord.Persona__c;
                                            $scope.opportunityContactRoles[j].Status = accountContactRelationRecord.Status__c;
                                            $scope.opportunityContactRoles[j].IsPrimaryAccountRelation = accountContactRelationRecord.IsPrimary__c;
                                            $scope.opportunityContactRoles[j].JobLevel = accountContactRelationRecord.Job_Level__c;
                                            accountContactRelationRecord = null;
                                        }

                                    }
                                    $scope.opportunityContactRoles[j].IsPrimary = $scope.opportunityContacts[i].IsPrimary;
                                    if($scope.opportunityContactRoles[j].IsPrimary){
                                        $scope.primaryOppRoleSelected = $scope.opportunityContactRoles[j].primaryOppRoleIndex;
                                        $scope.opportunityContactRoles[j].Opp=1;
                                    }
                                }
                            }
                        }
                        for(let j=0; j<$scope.opportunityContactRoles.length; j++){
                            if (!$scope.opportunityContactRoles[j].Selected) {
                                accountContactRelationRecord = $scope.getRecordFromFromAccountRelation($scope.opportunityContactRoles[j].ContactId);
                                if (accountContactRelationRecord != null) {
                                    $scope.opportunityContactRoles[j].Role = $scope.getRolesArrayFromAccountRelationRecord(accountContactRelationRecord);
                                    $scope.opportunityContactRoles[j].Persona = accountContactRelationRecord.Persona__c;
                                    $scope.opportunityContactRoles[j].Status = accountContactRelationRecord.Status__c;
                                    $scope.opportunityContactRoles[j].IsPrimaryAccountRelation = accountContactRelationRecord.IsPrimary__c
                                    $scope.opportunityContactRoles[j].JobLevel = accountContactRelationRecord.Job_Level__c;
                                    accountContactRelationRecord = null;
                                }
                            }
                        }

                        //$scope.tableParams = new NgTableParams({count: $scope.opportunityContactRoles.length}, {dataset: $scope.opportunityContactRoles, counts: []});
                        $scope.tableParams = new NgTableParams({}, {dataset: $scope.opportunityContactRoles});

                        if($scope.selectedCount == $scope.opportunityContactRoles.length){
                            $scope.allSelected = true;
                            $('input#selectAll').prop('checked', true);
                        }
                        $scope.$apply();
                        $('.js-example-basic-multiple').select2();

                        hideAlert();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        };

        $scope.allContactRoles = function(pContactId, pContactName, pContactTitle, pContactEmail, pPrimaryOppRoleIndex, pPrimaryOppRole, pSelected, pRole, pPersona, pStatus, pPrimaryAccRel, pJobLevel){
            var oppContact = {};
            oppContact.ContactId = pContactId;
            oppContact.Name = pContactName;
            oppContact.Title = pContactTitle;
            oppContact.Email = pContactEmail;
            oppContact.primaryOppRoleIndex = pPrimaryOppRoleIndex;
            oppContact.IsPrimary = pPrimaryOppRole;
            oppContact.Selected = pSelected;
            oppContact.OpportunityId = APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityId;
            oppContact.Role = pRole;
            oppContact.Persona = pPersona;
            oppContact.Status = pStatus;
            oppContact.IsPrimaryAccountRelation = pPrimaryAccRel;
            oppContact.JobLevel = pJobLevel;
            $scope.opportunityContactRoles.push(oppContact);
        }

        $scope.selectAll = function(){
            if(!$scope.allSelected){
                for(let i=0; i<$scope.opportunityContactRoles.length; i++){
                    $scope.opportunityContactRoles[i].Selected = true;
                }
                $scope.allSelected = true;
            }
            else{
                for(let i=0; i<$scope.opportunityContactRoles.length; i++){
                    $scope.opportunityContactRoles[i].Selected = false;
                }
                $scope.allSelected = false;
            }
        }

        $scope.resetForm = function() {
            $('#contactRole').val([]);
            $('#contactRole').select2();
            
            $scope.contact.Id = null;
            $scope.contact.FirstName = null;
            $scope.contact.LastName = null;
            $scope.contact.Email = null;
            $scope.contact.Title = null;            
            $scope.roles = [];
            $scope.Persona = null;
            $scope.Status = null;
            $scope.contact.Phone = null;
            $scope.JobLevel = null;
            $('input#contact-search').val('');
            $('div#modal-create-contact').find('[autofocus]').focus();            
        }

        $scope.addContact = function(){
            $scope.contactsToUpsert = [];
            $scope.accountContactsToUpsert = [];
            $scope.resetForm();
            $('div#modal-create-contact').modal('show');
            $('#contactRole').val([]);
            $('#contactRole').select2();
        }

        $scope.selectContact = function(pSelectedContact){
            $scope.contact = pSelectedContact;
            $scope.originalEmail = pSelectedContact.Email;
            $scope.existingContact = true;
            $scope.$apply();
        }

        $scope.upsertContactsAccountRelation = function() {
            $("#myPage").addClass("loading");
            $("#spinner").removeClass("slds-hidden");
            $('#saveChangesButton', '#addNewButton').prop('disabled', true);            
            AccountContactUtilities.upsertContactsAccountRelation($scope.contactsToUpsert, APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId, $scope.accountContactsToUpsert,
                function(result, event) {
                    if(event.type==='exception') {
                        $("#modal-create-contact").removeClass("loading");
                        $("#spinner").addClass("slds-hidden");            
                        $('#saveChangesButton', '#addNewButton').prop('disabled', false);                        
                        showAlert(event.message);
                    }else if(event.status) {
                        for(let i=0; i<result.length; i++){
                            let name = result[i].FirstName + ' ' + result[i].LastName;
                            $scope.allContactRoles(
                                result[i].Id,
                                name,
                                result[i].Title,
                                result[i].Email,
                                $scope.opportunityContactRoles.length + i,
                                false,
                                true,
                                $scope.accountContactsToUpsert[i].Roles.split(';'),
                                $scope.accountContactsToUpsert[i].Persona__c,
                                $scope.accountContactsToUpsert[i].Status__c,
                                $scope.accountContactsToUpsert[i].IsPrimary__c,
                                $scope.accountContactsToUpsert[i].Job_Level__c
                            );
                            let found = false;
                            for (let j=0;j<$scope.accountContacts.length;j++) {
                                if (result[i].Id == $scope.accountContacts[j].ContactId) {
                                    found = true;
                                }
                            }
                            if (!found) {
                                $scope.accountContactsToUpsert[i].ContactId = result[i].Id;
                                $scope.accountContacts.push($scope.accountContactsToUpsert[i]);
                            }
                        }
                        $('#saveChangesButton','#addNewButton').prop('disabled', false);
                        $('div#modal-create-contact').modal('hide');
                        $scope.resetForm();
                        $scope.$apply();
                        $("#myPage").removeClass("loading");
                        $("#spinner").addClass("slds-hidden");
                        $('.js-example-basic-multiple').select2();
                        hideAlert();
                        if($scope.tableParams) $scope.tableParams.reload();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        }

        $scope.addContactToModel = function() {
            var contact = {};
            contact.FirstName = $scope.contact.FirstName;
            contact.LastName = $scope.contact.LastName;
            contact.Email = $scope.contact.Email;
            contact.Phone =  $scope.contact.Phone;
            contact.Title = $scope.contact.Title;
            $scope.accountContactRelation = {AccountId: APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId, Roles: $scope.roles.join(';'), Persona__c: $scope.Persona, Status__c: $scope.Status, Job_Level__c: $scope.JobLevel};
            if ($scope.contact.Id) {
                $scope.contactIds.push($scope.contact.Id);
                contact.Id = $scope.contact.Id;
                if ($scope.contact.AccountId == APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId) {
                    contact.AccountId = APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId;
                }
                else {
                    contact.AccountId = $scope.contact.AccountId;
                }
                $scope.accountContactRelation.ContactId = $scope.contact.Id;
            }
            else {
                contact.AccountId = APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId;
            }
            $scope.contactsToUpsert.push(contact);
            $scope.accountContactsToUpsert.push($scope.accountContactRelation);
        }

        /*****************************************************/
        /****************** insertContact *******************/
        /*****************************************************/
        $scope.insertContact = function(pAddMultiple){
            if(!$scope.contact.FirstName){
                showAlert('You must enter a First Name');
            }
            else if(!$scope.contact.LastName){
                showAlert('You must enter a Last Name');
            }
            else if(!$scope.contact.Email){
                showAlert('You must enter an Email');
            }
            else if(!$scope.roles || $scope.roles.length == 0){
                showAlert('You must select at least one Role');
            }
            else if(pAddMultiple){
                $scope.addContactToModel();
                $scope.resetForm();
            }
            else {
                $scope.addContactToModel();
                $scope.upsertContactsAccountRelation();
            }
        }

        $scope.existsOpportunityContactWithRole = function(pContactId, pRole) {
            for(let i=0;i<$scope.opportunityContacts.length;i++) {
                if ($scope.opportunityContacts[i].ContactId == pContactId && $scope.opportunityContacts[i].Role == pRole) {
                    return $scope.opportunityContacts[i].Id;
                }
            }
        }

        $scope.setDeleteArray = function(pContactId) {
            for(let i=0;i<$scope.opportunityContacts.length;i++) {
                if ($scope.opportunityContacts[i].ContactId == pContactId) {
                    $scope.opportunityContactRolesToDelete.push($scope.opportunityContacts[i]);
                }
            }
        }

        $scope.setUpsertArray = function(pOpportunityContactRoleObject) {
            let selectedRoles = pOpportunityContactRoleObject.Role;            
            if (APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityContactRoleMaintenancePage == 'true' && pOpportunityContactRoleObject.Selected) {
                for (let z=0; z<selectedRoles.length; z++) {
                    let opportunityContactRoleId = $scope.existsOpportunityContactWithRole(pOpportunityContactRoleObject.ContactId, selectedRoles[z]);
                    var upsertRecord = {};
                    upsertRecord.Role = selectedRoles[z];
                    upsertRecord.Email = pOpportunityContactRoleObject.Email;
                    upsertRecord.IsPrimary = pOpportunityContactRoleObject.IsPrimary;
                    upsertRecord.ContactId = pOpportunityContactRoleObject.ContactId;
                    upsertRecord.OpportunityId = APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityId;
                    if (opportunityContactRoleId) {
                        upsertRecord.Id = opportunityContactRoleId;
                    }
                    $scope.opportunityContactRolesToUpsert.push(upsertRecord);
                }
            }
            for (let j=0;j<$scope.accountContacts.length;j++) {
                if ($scope.accountContacts[j].ContactId == pOpportunityContactRoleObject.ContactId) {
                    if (pOpportunityContactRoleObject.Persona) {
                        $scope.accountContacts[j].Persona__c = pOpportunityContactRoleObject.Persona;
                    }
                    if (pOpportunityContactRoleObject.Status) {
                        $scope.accountContacts[j].Status__c = pOpportunityContactRoleObject.Status;
                    }
                    if (pOpportunityContactRoleObject.IsPrimaryAccountRelation) {
                        $scope.accountContacts[j].IsPrimary__c = pOpportunityContactRoleObject.IsPrimaryAccountRelation;
                    }
                    if (pOpportunityContactRoleObject.JobLevel) {
                        $scope.accountContacts[j].Job_Level__c = pOpportunityContactRoleObject.JobLevel                        
                    }
                    $scope.accountContacts[j].Roles = selectedRoles.join(';');
                    $scope.accountContactsToUpsert.push($scope.accountContacts[j]);
                    break;
                }
            }
        }

        $scope.setPartialDeleteArray = function() {
            for(let i=0;i<$scope.opportunityContacts.length;i++) {
                let found = false;
                for (let j=0;j<$scope.opportunityContactRoles.length;j++) {
                    if($scope.opportunityContactRoles[j].Role.length > 0) {
                        for(let k=0;k<$scope.opportunityContactRoles[j].Role.length;k++) {
                            if ($scope.opportunityContactRoles[j].ContactId == $scope.opportunityContacts[i].ContactId && $scope.opportunityContactRoles[j].Role[k] == $scope.opportunityContacts[i].Role) {
                                found = true;
                                break;
                            }
                        }
                    }
                }
                if (!found) {
                    $scope.opportunityContactRolesToDelete.push($scope.opportunityContacts[i]);
                }
            }
        }

        $scope.deleteOpportunityContactRolesInvalidColumns = function(opportunityContactRolesArray, rowIndex) {
            delete opportunityContactRolesArray[rowIndex].$$hashKey;
            delete opportunityContactRolesArray[rowIndex].Name;
            delete opportunityContactRolesArray[rowIndex].Selected;
            delete opportunityContactRolesArray[rowIndex].Email;
            delete opportunityContactRolesArray[rowIndex].primaryOppRoleIndex;
            delete opportunityContactRolesArray[rowIndex].Persona;
            delete opportunityContactRolesArray[rowIndex].Status;
            delete opportunityContactRolesArray[rowIndex].primaryAccContactIndex;            
            delete opportunityContactRolesArray[rowIndex].JobLevel;            
        }

        /*************************************************************************************************/
        /****************************** saveOpportunityContactRoles **************************************/
        /*************************************************************************************************/
        $scope.saveOpportunityContactRoles = function() {
            $scope.opportunityContactRolesToUpsert = [];
            $scope.opportunityContactRolesToDelete = [];
            $scope.contactsToUpsert = [];
            $scope.accountContactsToUpsert = [];
            let adminCount = 0;
            let invalidPrimary = false;
            let someSelectedRolesNull = false;
            for(let i=0; i<$scope.opportunityContactRoles.length; i++){
                if ($scope.opportunityContactRoles[i].Changed) {
                    $scope.contactsToUpsert.push({Id: $scope.opportunityContactRoles[i].ContactId, Email: $scope.opportunityContactRoles[i].Email});
                    $scope.setUpsertArray($scope.opportunityContactRoles[i]);
                }
                if(!$scope.opportunityContactRoles[i].Selected) {
                    $scope.setDeleteArray($scope.opportunityContactRoles[i].ContactId);                    
                }                
                else if ($scope.opportunityContactRoles[i].Role == '') {
                    someSelectedRolesNull = true;
                }
                if(!$scope.opportunityContactRoles[i].Selected && $scope.primaryOppRoleSelected == $scope.opportunityContactRoles[i].primaryOppRoleIndex){
                    invalidPrimary = true;
                }
                else if($scope.opportunityContactRoles[i].Selected && $scope.primaryOppRoleSelected == $scope.opportunityContactRoles[i].primaryOppRoleIndex){
                    invalidPrimary = false;
                }
            }
            if($scope.primaryOppRoleSelected == null || $scope.primaryOppRoleSelected == undefined){
                showAlert('You must select a Primary Contact.');
            }
            else if ($scope.opportunityContactRoles[$scope.primaryOppRoleSelected].Role == '') {
                showAlert('You have marked a contact as a primary but have not designated a role for that contact. Please assign a role to your primary contact.');
            }
            else if (someSelectedRolesNull) {
                showAlert('All selected records must have at least one role.');
            }            
            else if(invalidPrimary){
                showAlert('You have marked a contact as primary but have not selected it. Please select the contact to be considered as the primary contact.')
            }
            else{
                if ($scope.opportunityContactRolesToDelete.length == 0) {
                    $scope.setPartialDeleteArray();
                }
                for(let i=0; i<$scope.opportunityContactRolesToUpsert.length; i++){
                    if(i != $scope.opportunityContactRolesToUpsert.length - 1){
                    $scope.emailString += `${$scope.opportunityContactRolesToUpsert[i].Email}, `;
                    }
                    else if(i == $scope.opportunityContactRolesToUpsert.length - 1){
                        $scope.emailString += `${$scope.opportunityContactRolesToUpsert[i].Email}`;
                    }
                    if ($scope.opportunityContactRolesToUpsert[i].ContactId == $scope.opportunityContactRoles[$scope.primaryOppRoleSelected].ContactId) {
                        $scope.opportunityContactRolesToUpsert[i].IsPrimary = true;
                    }
                    else{
                        $scope.opportunityContactRolesToUpsert[i].IsPrimary = false;
                    }
                    $scope.deleteOpportunityContactRolesInvalidColumns($scope.opportunityContactRolesToUpsert, i);
                }
                for(let i=0; i<$scope.opportunityContactRolesToDelete.length; i++){
                    $scope.deleteOpportunityContactRolesInvalidColumns($scope.opportunityContactRolesToDelete, i);
                }
                $('#addContact, #submitSave').prop('disabled', true);
                $("#myPage").addClass("loading");
                $("#spinner").removeClass("slds-hidden");
                hideAlert();
                AccountContactUtilities.processChanges(APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId, $scope.opportunityContactRolesToUpsert, $scope.contactsToUpsert, $scope.accountContactsToUpsert, $scope.opportunityContactRolesToDelete, 
                    function(result, event) {
                        if(event.type==='exception') {
                            $('#addContact, #submitSave').prop('disabled', false);
                            $("#myPage").removeClass("loading");
                            $("#spinner").addClass("slds-hidden");
                            showAlert(event.message);
                        }else if(event.status) {
                            $scope.opportunityContacts = result;
                            $scope.$apply();
                            $('#addContact, #submitSave').prop('disabled', false);
                            $("#myPage").removeClass("loading");
                            $("#spinner").addClass("slds-hidden");
                            showSuccess('Successfully processed changes.');                            
                            if ($scope.closeWindowAfterProcessing) {
                                /*
                                parent.window.opener.location.href = "/" + APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityId;   
                                setTimeout(function () { window.close();}, 1500);
                                */
                                setTimeout(function () {
                                    if( (typeof sforce != 'undefined') && sforce && (!!sforce.one) ) {
                                        // Lightning navigation
                                        sforce.one.navigateToURL('/'+APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityId);
                                    }
                                    else {
                                        // Salesforce classic
                                        parent.window.opener.location.href = "/" + APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityId;   
                                        window.close();
                                    }            
                                }, 1500);
                            }
                        }else {
                            showAlert(event.message);
                        }
                    },
                    {buffer: false, escape: true}
                );
            }
        }

        /*************************************************************************************************/
        /****************************** saveAccountContactRelation **************************************/
        /*************************************************************************************************/        
        $scope.saveAccountContactRelation = function() {
            $scope.contactsToUpsert = [];
            $scope.accountContactsToUpsert = [];
            for (let i=0; i<$scope.opportunityContactRoles.length; i++) {
                if ($scope.opportunityContactRoles[i].Changed) {
                    $scope.contactsToUpsert.push({Id: $scope.opportunityContactRoles[i].ContactId, Email: $scope.opportunityContactRoles[i].Email});
                    $scope.setUpsertArray($scope.opportunityContactRoles[i]);
                }
            }
            // set primary field
            for (let j=0; j<$scope.accountContactsToUpsert.length; j++) {
                $scope.accountContactsToUpsert[j].IsPrimary__c = false;
                for (let k=0; k<$scope.opportunityContactRoles.length; k++) {
                    if ($scope.accountContactsToUpsert[j].ContactId == $scope.opportunityContactRoles[k].ContactId && $scope.opportunityContactRoles[k].IsPrimaryAccountRelation) {
                        $scope.accountContactsToUpsert[j].IsPrimary__c = true;
                    }
                }
            }
            $('#addContact, #submitSave').prop('disabled', true);
            $("#myPage").addClass("loading");
            $("#spinner").removeClass("slds-hidden");
            hideAlert();
            AccountContactUtilities.upsertContactsAccountRelation($scope.contactsToUpsert, APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId, $scope.accountContactsToUpsert,
                function(result, event) {
                    if(event.type==='exception') {
                        $('#addContact, #submitSave').prop('disabled', false);
                        $("#myPage").removeClass("loading");
                        $("#spinner").addClass("slds-hidden");
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.opportunityContacts = result;
                        $scope.$apply();
                        $('#addContact, #submitSave').prop('disabled', false);
                        $("#myPage").removeClass("loading");
                        $("#spinner").addClass("slds-hidden");
                        showSuccess('Successfully processed changes.');
                        if ($scope.closeWindowAfterProcessing) {
                            /*
                            parent.window.opener.location.href = "/" + APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId;
                            setTimeout(function () { window.close();}, 1500);
                            */
                            setTimeout(function () {
                                if( (typeof sforce != 'undefined') && sforce && (!!sforce.one) ) {
                                    // Lightning navigation
                                    sforce.one.navigateToURL('/'+APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId);
                                }
                                else {
                                    // Salesforce classic
                                    parent.window.opener.location.href = "/" + APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId;
                                    window.close();
                                }
                            }, 1500);
                        }
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        }

        /*******************************************************/
        /****************** saveContactRoles *******************/
        /*******************************************************/
        $scope.saveContactRoles = function(){            
            if (APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityContactRoleMaintenancePage == 'true') {
                $scope.saveOpportunityContactRoles();
            } else if (APP_CONGA_ACCOUNT_CONTACT_TABLE.accountContactRelationshipMaintenancePage == 'true') {
                $scope.saveAccountContactRelation();
            } else {
                showAlert('Invalid page status.');
            }
        }

        $scope.cancel = function(){
            var currentRecordId = APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityId ? APP_CONGA_ACCOUNT_CONTACT_TABLE.opportunityId : APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId;
            if( (typeof sforce != 'undefined') && sforce && (!!sforce.one) ) {
                // Lightning navigation
                sforce.one.navigateToURL('/'+currentRecordId);
            }
            else {
                // Salesforce classic
                window.close();
            }            
        }

        $scope.setAccountPrimary = function(pIndex) {  
            debugger;          
            for (let i=0;i<$scope.opportunityContactRoles.length;i++) {
                for (let j=0;j<$scope.accountContacts.length;j++) {
                    if ($scope.opportunityContactRoles[i].ContactId == $scope.accountContacts[j].ContactId) {
                        $scope.opportunityContactRoles[i].Opp = null;
                        if ($scope.accountContacts[j].IsPrimary__c) {
                            $scope.opportunityContactRoles[i].IsPrimaryAccountRelation = true;
                        } else {
                            $scope.opportunityContactRoles[i].IsPrimaryAccountRelation = false;
                        }
                        
                    }
                }
            }
            $scope.opportunityContactRoles[pIndex].IsPrimaryAccountRelation = true;
            $scope.opportunityContactRoles[pIndex].Opp = 1;
            $scope.primaryOppRoleSelected = pIndex;
            $scope.setChanged(pIndex);
        }   

        $scope.sort_by = function (newSortingOrder) {
            if ($scope.sortingOrder == newSortingOrder)
                    $scope.reverse = !$scope.reverse;
            else $scope.reverse = false;

            $scope.sortingOrder = newSortingOrder;
        };



        $scope.statusFilter = function () {
            return function(record){
                
                if ( $scope.searchText != "" && record.Status=="Departed")
                    return false;
                else
                    return true;
            }
        };



    

        $scope.setChanged = function(pIndex) {
            $scope.opportunityContactRoles[pIndex].Changed = true;
        }

        // end AngularJS
    }]);

    // jQuery

    // jQuery autocomplete
    function autoComplete($ele) {
        $ele.autocomplete({
            source: function(request, response) {
                if($ele.is('input#contact-search')) {
                    AccountContactUtilities.findContacts($ele.val(), APP_CONGA_ACCOUNT_CONTACT_TABLE.accountId, angular.element('#ControllerAccountContactTable').scope().contactIds,
                        function(result, event) {
                            if(event.type==='exception') {
                                showAlert('exception: '+event);
                            }else if(event.status) {
                                $.each(result, function() {
                                    response(result);
                                });
                            }else{
                                showAlert(event.message);
                            }
                        },
                        {buffer: false, escape: true}
                    );
                }
            },
            minLength: 2,
            focus: function(event, ui, item) {
                // focus: is the :hover function
                setTimeout(function() {
                    $ele.val(decodeCharacters(ui.item.Name));
                }, 1);
            },
            select: function(event, ui) {
                event.stopPropagation();
                if($ele.is('input#contact-search')) {
                    angular.element('#ControllerAccountContactTable').scope().selectContact(ui.item);
                }
                setTimeout(function() {
                    $ele.val(decodeCharacters(ui.item.Name));
                    $ele.val(decodeCharacters(ui.item.Account.Name));
                }, 1);
            }
        }).data('uiAutocomplete')._renderItem = function(ul, item) {
            return $('<li class="searchList form-control"></li>').data('ui-autocomplete-item', item).append('<a class="contact-list" data-id='+item.Id+'>'+item.Name+' - '+ item.Account.Name+'</a>').appendTo(ul);
        };
    }

    $('.modal').on('shown.bs.modal', function() {
        $(this).find('[autofocus]').focus();
        autoComplete($('input#contact-search'));
    });

    $('button#close-alert-error').on('click', function() {
        $('div#alert-error').fadeOut();
    });

    $('button#close-alert-success').on('click', function() {
        $('div#alert-success').fadeOut();
    });

    $('div.modal').on('hide.bs.modal', function() {
        hideAlert();
    });

    toastr.options = {
        "closeButton": false,
        "debug": false,
        "newestOnTop": false,
        "progressBar": false,
        "positionClass": "toast-top-center",
        "preventDuplicates": true,
        "onclick": null,
        "showDuration": "300",
        "hideDuration": "1000",
        "timeOut": "5000",
        "extendedTimeOut": "1000",
        "showEasing": "swing",
        "hideEasing": "linear",
        "showMethod": "fadeIn",
        "hideMethod": "fadeOut"
    };

}(jQuery));