({
    getColumnDefinitions: function () {
        var columnsWidths = this.getColumnWidths();
        var columns = [
            /*
            {label: 'Action', type: 'button', initialWidth: 150, typeAttributes:
                { label: { fieldName: 'actionLabel'}, title: 'Click to Edit', name: 'edit_status', iconName: 'utility:edit', disabled: {fieldName: 'actionDisabled'}, class: 'btn_next'}},
            
            {label: 'Action', fieldName: 'action', type: 'url', typeAttributes: { label: { fieldName: 'opportunityName' }, target: '_blank', tooltip: 'Click to visit website' }},
            */
            {label: 'Approval', fieldName: 'approveURL', type: 'url', initialWidth: 150, typeAttributes: { label: 'Approve', target: '_blank'}, sortable: true },
            {label: 'Reject', fieldName: 'rejectURL', type: 'url', typeAttributes: { label: 'Reject', target: '_blank'}, sortable: true },
            {label: 'Reassign', fieldName: 'reassignURL', type: 'url', typeAttributes: { label: 'Reassign', target: '_blank'}, sortable: true },
            //{label: 'Name', fieldName: 'approvalName'.Name, type: 'text', sortable: true},
            //{label: 'Name', fieldName: 'approvalURL', type: 'url', typeAttributes: { label: {fieldName: 'nameApproval'},target: '_self'}, sortable: true },
            // {label: 'Quote', fieldName: 'relatedTo', type: 'text', sortable: true},
            {label: 'Quote', fieldName: 'quoteURL', type: 'url', typeAttributes: { label: {fieldName: 'relatedTo'},target: '_blank'}, sortable: true },
            {label: 'Opportunity name', fieldName: 'opptyURL', type: 'url', typeAttributes: { label: {fieldName: 'relatedToOpportunityName'},target: '_blank'}, sortable: true },
            //{label: 'Opportunity name', fieldName: 'relatedToOpportunityName', type: 'text', sortable: true, iconName: 'standard:opportunity'},
            {label: 'Creation date', fieldName: 'creationDate', type: 'date', sortable: true, cellAttributes: { iconName: 'utility:event', iconAlternativeText: 'Close Date'  }},
            //{label: 'Approval Rule', fieldName: 'relatedToRuleName', type: 'text', sortable: true},
            {label: 'Approval Rule', fieldName: 'approvalRuleURL', type: 'url', typeAttributes: { label: {fieldName: 'relatedToRuleName'},target: '_blank'}, sortable: true },            
            {label: 'Request Notes', fieldName: 'relatedToRequestNotes', type: 'text', sortable: true},
            {label: 'Discount to be Approved-Subscriptions', fieldName: 'discountPercent', type: 'percent', sortable: true},
            {label: 'Approver', fieldName: 'assignedTo', type: 'text', sortable: true},
            /*
            {label: 'Website', fieldName: 'website', type: 'url', typeAttributes: { label: { fieldName: 'opportunityName' }, target: '_blank', tooltip: 'Click to visit website' }}
            
            {label: 'Confidence', fieldName: 'confidence', type: 'percent', sortable: true, cellAttributes:
                { iconName: { fieldName: 'confidenceDeltaIcon' }, iconLabel: { fieldName: 'confidenceDelta' }, iconPosition: 'right', iconAlternativeText: 'Percentage Confidence' }},
            {label: 'View', type: 'button', initialWidth: 135, typeAttributes: { label: 'View Details', name: 'view_details', title: 'Click to View Details'}},
            */
        ];

        if (columnsWidths.length === columns.length) {
            return columns.map(function (col, index) {
                return Object.assign(col, { initialWidth: columnsWidths[index] });
            });
        }
        return columns;
    },

    fetchData: function (cmp, fetchData, numberOfRecords) {
        var dataPromise,
            latitude,
            longitude;
            /*
            fakerLib = this.mockdataLibrary.getFakerLib();

        fetchData.address = {type : function () {
            return {
                latitude : fakerLib.address.latitude(),
                longitude : fakerLib.address.longitude()
            };
        }};*/

        fetchData.confidence =  { type : function () {
            return Math.random();
        }};

        //dataPromise = this.mockdataLibrary.lightningMockDataFaker(fetchData, numberOfRecords);

        // create a one-time use instance of the serverEcho action
        // in the server-side controller
        var lightningApprovals = cmp.get("c.lightningApprovals");
        //action.setParams({ firstName : cmp.get("v.firstName") });

        // Create a callback that is executed after 
        // the server-side action returns
        lightningApprovals.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Alert the user with the value returned 
                // from the server
                //alert("From server: " + response.getReturnValue());
                console.log("From server: " + JSON.stringify(response.getReturnValue()));
                dataPromise = response.getReturnValue();
                
                dataPromise.forEach(function(item) {
                    item['approveURL'] = '/apex/sbaa__Approve?id=' + item['approvalName'].Id;
                    item['rejectURL'] = '/apex/sbaa__Reject?id=' + item['approvalName'].Id;
                    item['reassignURL'] = '/apex/sbaa__Reassign?id=' + item['approvalName'].Id;

                    item['approvalURL'] = '/lightning/r/sbaa__Approval__c/' + item['approvalName'].Id + '/view';
                    item['quoteURL'] = '/lightning/r/SBQQ__Quote__c/' + item['relatedToId'] + '/view';
                    item['opptyURL'] = '/lightning/r/Opportunity/' + item['relatedToOpportunity'] + '/view';
                    item['approvalRuleURL'] = '/lightning/r/sbaa__ApprovalRule__c/' + item['relatedToRule'] + '/view';
                    item['nameApproval'] = item['approvalName'].Name;
                    var percentOneHundread = 100;
                    item['discountPercent'] = item['relatedToNewProductsDiscount']/percentOneHundread;

                });

                console.log("From server: dataPromise inside " + JSON.stringify(dataPromise));
                cmp.set('v.data', dataPromise);
                // You would typically fire a event here to trigger 
                // client-side notification that the server-side 
                // action is complete
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(lightningApprovals);
        console.log("From server lightningApprovals: JSON.stringify "+ JSON.stringify(lightningApprovals));
        console.log("From server lightningApprovals: "+ lightningApprovals);
        //dataPromise = lightningApprovals;
        console.log("From server JSON.stringify(dataPromise): " + JSON.stringify(dataPromise));
        console.log("From server dataPromise: " + dataPromise);
        return dataPromise;

    },
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';

        data = Object.assign([],
            data.sort(this.sortBy(fieldName, reverse ? -1 : 1))
        );
        cmp.set("v.data", data);
    },
    sortBy: function (field, reverse, primer) {
            var key = primer
                ? function(x) {
        return primer(x[field]);
        }
                    : function(x) {
        return x[field];
        };

        return function (a, b) {
            var A = key(a);
            var B = key(b);
            return reverse * ((A > B) - (B > A));
        };
    },
    
    storeColumnWidths: function (widths) {
        localStorage.setItem('datatable-in-action', JSON.stringify(widths));
    },
    resetLocalStorage: function () {
        localStorage.setItem('datatable-in-action', null);
    },
    getColumnWidths: function () {
        var widths = localStorage.getItem('datatable-in-action');

        try {
            widths = JSON.parse(widths);
        } catch(e) {
            return [];
        }
        return Array.isArray(widths) ? widths : [];
    },
    
    editRowStatus: function (cmp, row) {
        var data = cmp.get('v.data');
        data = data.map(function(rowData) {
            if (rowData.id === row.id) {
                switch(row.actionLabel) {
                    case 'Approve':
                        rowData.actionLabel = 'Complete';
                        break;
                    case 'Complete':
                        rowData.actionLabel = 'Close';
                        break;
                    case 'Close':
                        rowData.actionLabel = 'Closed';
                        rowData.actionDisabled = true;
                        break;
                    default:
                        break;
                }
            }
            return rowData;
        });
        cmp.set("v.data", data);
    },
    showRowDetails : function(row) {
        // eslint-disable-next-line no-alert
        alert("Showing opportunity " + row.opportunityName + " closing on " + row.closeDate);
    }
});