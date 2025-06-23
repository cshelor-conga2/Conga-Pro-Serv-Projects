// @author: Joseph Markey
'use strict';
(function($) {
    // global namespace
    window.APP_TEAM_ASSIGNMENTS = {
        NgAppTeamAssignments: angular.module('NgAppTeamAssignments', ['ngSanitize'])
    }

    // native JavaScript
    function showAlert(msg) {
        $('span#alert-error-message').text(msg);
        $('div#alert-error').fadeIn();
    }

    function hideAlert() {
        $('div#alert-error').hide();
    }

    function decodeCharacters(str) {
        if(str) {
            return str.replace(/amp;/g, '').replace(/lt;/g, '<').replace(/gt;/g, '>').replace(/&&/g, '&').replace(/&quot;/g, "'").replace(/&</,'<').replace(/&>/,'>').replace(/%20/g,' ').replace(/%22/g, '&#39;"').replace(/&#39;/, "'").replace(/&#39;/, "'");
        }
    }

    // constructor function Assignment__c() defines the Assignment__c sObject
    function Assignment__c(pId, pOwnerId, pPriority, pStatus) {
        this.Id = pId;
        this.OwnerId = pOwnerId;
        this.Priority__c = pPriority;
        this.Status__c = pStatus;
    }

    function removeAssignments() {
        $('ul#sortable-assignments>li').remove();
    }

    // AngularJS
    APP_TEAM_ASSIGNMENTS.NgAppTeamAssignments.controller('ControllerTeamAssignments', ['$scope', function($scope) {
        // declare and initialize $scope variables
        $scope.currentYear = new Date().getFullYear();
        $scope.openAssignments = [];
        $scope.teamMembers = [];
        $scope.owners = [];
        $scope.projectManagers = [];
        $scope.levelOfEffort = [];
        $scope.ownerData = {};
        $scope.ownerData.model = '';
        $scope.projectManagersData = {};
        $scope.projectManagersData.model = '';
        $scope.levelOfEffortData = {};
        $scope.startUl = {};
        $scope.levelOfEffortData.model = '';
        $scope.selectedOwnerId = '';
        $scope.isOverflowAssignment = false;


        $scope.assignmentRecordTypes = {};
        $scope.userType = document.getElementById("userType").value;
        $scope.assignmentRecordTypes.model = $scope.userType;

        // $scope functions
        $scope.getAssignmentRecordTypes = function() {
            $('i#fa-loader-tickets').show();
            TeamAssignmentsUtilities.getAssignmentRecordTypes(
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.assignmentRecordTypes = result;
                        $scope.assignmentRecordTypes = {
                            model: $scope.userType,
                            availableOptions: $scope.assignmentRecordTypes
                        };
                        $('i#fa-loader-tickets').hide();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        };
        $scope.getAssignmentRecordTypes(); // immediately invoke

        // $scope functions
        // $scope.getOwners = function() {
        //     $('i#fa-loader-tickets').show();
        //     TeamAssignmentsUtilities.getOwners(
        //         function(result, event) {
        //             if(event.type==='exception') {
        //                 showAlert(event.message);
        //             }else if(event.status) {
        //                 $scope.owners = result;
        //                 $scope.ownerData = {
        //                     model: '',
        //                     availableOptions: $scope.owners

        //                 };
        //                 $scope.projectManagers = result;
        //                 $scope.projectManagersData = {
        //                     model: '',
        //                     availableOptions: $scope.projectManagers
        //                 };
        //                 $('i#fa-loader-tickets').hide();
        //             }else {
        //                 showAlert(event.message);
        //             }
        //         },
        //         {buffer: false, escape: true}
        //     );
        // };
        // $scope.getOwners(); // immediately invoke        

        $scope.getLevelOfEffort = function() {
            $('i#fa-loader-tickets').show();
            TeamAssignmentsUtilities.getLevelOfEffort(
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.levelOfEffort = result;
                        $scope.levelOfEffortData = {
                            model: '',
                            availableOptions: $scope.levelOfEffort
                        };
                        $('i#fa-loader-tickets').hide();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        };
        $scope.getLevelOfEffort(); // immediately invoke

        $scope.initializeSortable = function() {
            $('ul#sortable-assignments, ul.child-connected-sortable').sortable({
                connectWith: '.connectedSortable',
                placeholder: 'ui-state-highlight',
                start: function(event, ui) {
                    // determine which list the assignment record was taken from (source list: $scope.startUl)
                    $scope.startAssignmentId = $(ui.item).find('span.assignment-id').text();
                    $scope.startUl = $(ui.item).parent();
                },
                stop: function(event, ui) {
                    var assignmentId = '';
                    var currentAssignmentId = '';
                    var assignmentsArr = [];
                    $scope.selectedOwnerId = '';
                    var status = '';
                    // determine which list the assignment record was dropped on
                    var $ul = $(ui.item).parent();
                    if($ul.is('ul#sortable-assignments')) {
                        status = 'Backlog';
                        $ul.find('li').each(function(i) {
                            var $this = $(this);
                            assignmentId = $this.find('span.assignment-id').text();
                            $scope.selectedOwnerId = $this.find('span.owner-id').text();
                            assignmentsArr.push(new Assignment__c(assignmentId, $scope.selectedOwnerId, (i+1), status));
                        });
                    } else {
                        currentAssignmentId = ui.item.attr('data-id');
                        // update all Assignment__c records within the list dropped on (target)
                        $ul.find('li').each(function(i) {
                            var $this = $(this);
                            assignmentId = $this.find('span.assignment-id').text();
                            $scope.selectedOwnerId = $this.parent('ul.child-connected-sortable').prev('div.team-member-parent-container').find('span.new-owner-id').text();
                            if(assignmentId === currentAssignmentId){
                                status = 'Under Review';
                            }
                            else{
                                for(let i=0; i<$scope.teamMembers.length; i++){
                                    if($scope.teamMembers[i].thisUser.Id === $scope.selectedOwnerId){
                                        for(let j=0; j<$scope.teamMembers[i].assignments.length; j++){
                                            if(assignmentId === $scope.teamMembers[i].assignments[j].Id){
                                                status = $scope.teamMembers[i].assignments[j].Status__c;
                                            }
                                        }
                                        break;
                                    }
                                }
                            }
                            assignmentsArr.push(new Assignment__c(assignmentId, $scope.selectedOwnerId, (i+1), status));
                        });
                        // only update the source list if the start and stop ul elements are different and the source list is not ul#sortable-assignments
                        if(!$scope.startUl.is($ul) && !$scope.startUl.is('ul#sortable-assignments')) {
                            // update all Assignment__c records within the list the assignment record was taken from (source list: $scope.startUl)
                            $scope.startUl.find('li').each(function(i) {
                                var $this = $(this);
                                assignmentId = $this.find('span.assignment-id').text();
                                $scope.selectedOwnerId = $this.parent('ul.child-connected-sortable').prev('div.team-member-parent-container').find('span.new-owner-id').text();
                                // prevent duplicate Assignment__c records
                                assignmentsArr.push(new Assignment__c(assignmentId, $scope.selectedOwnerId, (i+1)));
                            });
                        }
                    }
                    $('div#mask, i#fa-loader-assignments').show();
                    TeamAssignmentsUtilities.updateAssignments(assignmentsArr,
                        function(result, event) {
                            if(event.type==='exception') {
                                showAlert(event.message);
                            }else if(event.status) {
                                $('div#mask, i#fa-loader-assignments').hide();
                                removeAssignments();
                                $scope.getOpenAssignments();
                                $scope.getAssignmentsByTeamMember();
                                setTimeout(function(){
                                    $scope.expandLast($(`div[data-id="${$scope.selectedOwnerId}"]`));
                                },1000);
                            }else {
                                showAlert(event.message);
                            }
                        },
                        {buffer: false, escape: true}
                    );
                }
            }).disableSelection();
        };

        $scope.getOpenAssignments = function() {
            $('i#fa-loader-assignments').show();
            TeamAssignmentsUtilities.getOpenAssignments($scope.assignmentRecordTypes.model, $scope.levelOfEffortData.model, $scope.isOverflowAssignment,
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.openAssignments = result;
                        $scope.$apply();
                        $('i#fa-loader-assignments').hide();
                        $scope.initializeSortable();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        };
        $scope.getOpenAssignments();

        $scope.getAssignmentsByTeamMember = function() {
            $('i#fa-loader-team-members').show();
            TeamAssignmentsUtilities.getAssignmentsByTeamMember(
                function(result, event) {
                    if(event.type==='exception') {
                        showAlert(event.message);
                    }else if(event.status) {
                        $scope.teamMembers = result;
                        $scope.$apply();
                        $('i#fa-loader-team-members').hide();
                        $scope.initializeSortable();
                    }else {
                        showAlert(event.message);
                    }
                },
                {buffer: false, escape: true}
            );
        };
        $scope.getAssignmentsByTeamMember();

        // $scope.selectOwner = function() {
        //     $scope.getOpenAssignments();
        // };

        $scope.selectStatus = function() {
            $scope.getOpenAssignments();
        };

        // $scope.selectProjectManager = function() {
        //     $scope.getOpenAssignments();
        // };

        $scope.selectOverflow = function() {
            $scope.getOpenAssignments();
        };

        $scope.selectAssignmentRecordTypes = function() {
            $scope.getOpenAssignments();
        };        

        $scope.clearFilters = function() {
            // $scope.ownerData.model = '';
            // $scope.projectManagersData.model = '';
            $scope.levelOfEffortData.model = '';
            $scope.assignmentRecordTypes.model = '';
            $scope.isOverflowAssignment = false;
            $scope.getOpenAssignments();
        };

        $scope.backToSalesforce = function() {
            window.location.href = '\\';
        };

        $scope.getLevelOfEffortClass = function(pLevelofEffort) {
            var strClass = '';
            if(pLevelofEffort==='Low') {
                strClass = 'text-info';
            } else if(pLevelofEffort==='Medium') {
                strClass = 'text-warning';
            } else if(pLevelofEffort==='High') {
                strClass = 'text-danger';
            }

            return strClass;
        };

        $scope.getStatusClass = function(pStatus) {
            var strClass = '';
            if(pStatus==='Under Review') {
                strClass = 'text-success';
            } else if(pStatus==='Backlog') {
                strClass = 'text-danger';
            }

            return strClass;
        };

        $scope.expandLast = function(pParentDiv){
            console.log(pParentDiv);
            pParentDiv.click();
            // $(this).next('ul.child-connected-sortable').find('li.team-member-children-container').stop().slideToggle('fast');
        }

        // prevent jQuery sortable bug (using $watch()) that prevents the sortable library from initializing after a user searches in the "Search Team Members" input text and then clears out the search
        $scope.$watch('searchTeamMembers', function(newValue, oldValue) {
            if(!newValue) {
                $scope.initializeSortable();
            }
        });
        // end AngularJS
    }]);

    // jQuery
    $('a#back-to-top').on('click', function(event) {
        event.preventDefault();
        $('html, body').animate({scrollTop: $('html').offset().top},'slow');
    });

    $('button#close-alert-error').on('click', function() {
        hideAlert();
    });

    $(document).on('click', 'div.team-member-parent-container', function() {
        $(this).next('ul.child-connected-sortable').find('li.team-member-children-container').stop().slideToggle('fast');
    });
}(jQuery));