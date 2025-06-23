// author: Joseph Markey
'use strict';
(function($) {
	// global namespacegetTimeCardHeader
	window.APP_MyTimeCard = {
		AppMyTimeCard: angular.module('AppMyTimeCard', ['ngSanitize'])
	}

	// native JavaScript
	function showAlert(msg, noPeriod) {
		$('span#alert-error-message').text(msg);
		if(noPeriod) {
			$('span#alert-error-message').append(' <a href="/a1k/e?" target="_blank">Create New Period</a>');
		}
		$('div#alert-error').fadeIn();
	}

	function hideAlert() {
		$('div#alert-error, i#fa-loader-conga').hide();
	}

	function decodeCharacters(str) {
		if(str) {
			return str.replace(/amp;/g, '').replace(/lt;/g, '<').replace(/gt;/g, '>').replace(/&&/g, '&').replace(/&quot;/g, "'").replace(/&</,'<').replace(/&>/,'>').replace(/%20/g,' ').replace(/%22/g, '&#39;"').replace(/&#39;/, "'");
		}
	}

	function highlightLastRecord(id) {
        $('div#time-card-entry-container div.time-card-entry').removeClass('selected-row');
		if(id) {
			$("div#time-card-entry-container span:contains('"+id+"')").parent('div').addClass('selected-row');
		}
    }

    function highlightLastRecordProject(id) {
    	try {
			var $ul = $('ul#ul-projects');
			$ul.find('li').removeClass('selected-row');
			if(id) {
				var $ele = $ul.find("li span:contains('"+id+"')").parent('li');
				$ele.addClass('selected-row');
				$ul.animate({scrollTop:$ele.position().top-$ul.find('li').first().position().top-150}, 'fast');
			}
		}
		catch(e) {}
	}
	
	function highlightLastRecordSupportRequest(id) {
		try {
			var $ul = $('ul#ul-supportRequests');
			$ul.find('li').removeClass('selected-row');
			if(id) {
				var $ele = $ul.find("li span:contains('"+id+"')").parent('li');
				$ele.addClass('selected-row');
				$ul.animate({scrollTop:$ele.position().top-$ul.find('li').first().position().top-150}, 'fast');
			}	
		}
		catch(e) {}
    }

    function highlightLastRecordMilestone(id) {
    	try {
			var $ul = $('ul#ul-milestones');
			$ul.find('li').removeClass('selected-row');
			if(id) {
				var $ele = $ul.find("li span:contains('"+id+"')").parent('li');
				$ele.addClass('selected-row');
				if($ele.position()) {
					$ul.animate({scrollTop:$ele.position().top-$ul.find('li').first().position().top-150}, 'fast');
				}
			}
		}
		catch(e) {}
    }

    function highlightLastRecordAssignment(id){
    	try {
			var $ul = $('ul#ul-assignments');
			$ul.find('li').removeClass('selected-row');
			if(id) {
				var $ele = $ul.find("li span:contains('"+id+"')").parent('li');
				$ele.addClass('selected-row');
				if($ele.position()) {
					$ul.animate({scrollTop:$ele.position().top-$ul.find('li').first().position().top-150}, 'fast');
				}
			}
		}
		catch(e) {}
    }

	// AngularJS
	APP_MyTimeCard.AppMyTimeCard.directive('datepicker', function() {
		return {
			restrict: 'A',
			require : 'ngModel',
			link : function (scope, element, attrs, ngModelCtrl) {
				$(function(){
					element.datepicker({
						todayBtn: "linked",
						calendarWeeks: true,
						todayHighlight: true,
						toggleActive: true,
						dateFormat:'mm/dd/yy',
						autoclose: true,
						onSelect:function (date) {
							ngModelCtrl.$setViewValue(date);
							scope.$apply();
						}
					});
				});
			}
		}
	});
	

	APP_MyTimeCard.AppMyTimeCard.controller('ControllerMyTimeCard', ['$scope', '$sce', '$filter', function($scope, $sce, $filter) {
		// declare and initialize $scope variables
		$scope.currentYear = new Date().getFullYear();
		$scope.user = {};
		$scope.period = {};
		$scope.selectedProject = {};
		$scope.selectedSupportRequest = {};
		$scope.timeCardHeader = {};
		$scope.selectedTimeCardEntry = {};
		$scope.selectedMilestone = {};
		$scope.selectedAssignment = {};
		$scope.projects = [];
		$scope.supportRequests = [];
		$scope.milestones = [];
		$scope.assignments = [];
		$scope.timeCardEntries = [];
		$scope.timeCardDays = [];
		$scope.accountId = '';
		$scope.userFullName = '';
		$scope.weekNotes = '';
		$scope.selectedDate = '';
		$scope.isEditTimeCardEntry = false;
		$scope.showAccount = false;
		$scope.activeOnly = true;
		$scope.supportRequestStatus = '';
		$scope.supportRequestStatuses = [''];
		$scope.dayTotal = 0;
		$scope.periodTotal = 0;
		$scope.timeEntryType = '';
		$scope.timeEntryTypes = [];
		$scope.projectType = '';
		$scope.newTimeCardEntry = {};
		$scope.projectTypes = ['Client Project','Internal Project'];
		$scope.managedDate = '12/31/2017';

		// $scope functions
		$scope.toUTCDate = function(date) {
			var _utc = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),  date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
			return _utc;
		};
		
		$scope.millisToUTCDate = function(millis) {
			return $scope.toUTCDate(new Date(millis));
		};

		$scope.toSalesforceDate = function(date) {
			var today = new Date();
			//var _date = new Date(date.getFullYear(), date.getMonth(), date.getDate(),  today.getHours(), today.getMinutes(), today.getSeconds());
			var _date = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
			return _date;
		};

		$scope.getTimeEntryTypes = function() {
			$('i#fa-loader-get-timeEntryType').show();
			EmployeeTimeCardController.getTimeEntryTypes(
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.timeEntryTypes = result;
						$scope.$apply();
						$('i#fa-loader-get-timeEntryType').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};
		$scope.getTimeEntryTypes(); // immediatelly invoke



		$scope.getSupportRequestStatuses = function() {
			$('i#fa-loader-get-supportRequestStatuses').show();
			EmployeeTimeCardController.getSupportRequestStatuses(
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.supportRequestStatuses = result;
						$scope.$apply();
						$('i#fa-loader-get-supportRequestStatuses').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.getUser = function() {
			$('i#fa-loader-get-user').show();
			EmployeeTimeCardController.getUser(
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.user = result;
						$scope.getCurrentPeriod(false);
						$scope.userFullName = $scope.user.FirstName+' '+$scope.user.LastName;
						$scope.timeEntryType = $scope.user.Default_Time_Card_Entry_Setting__c || 'Project';
						if($scope.user.Team__c === 'Business Systems'){
							$scope.projectType = 'Internal Project';
						}else{
							$scope.projectType = 'Client Project';
						}
						$scope.$apply();
						$('i#fa-loader-get-user').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};
		$scope.getUser(); // immediately invoke

		$scope.getCurrentPeriod = function(pIsNewPeriod) {
			$('i#fa-loader-get-period').show();
			hideAlert();
			if(pIsNewPeriod) {
				// update the fullcanledar date to be aligned with the current Period__c.Start_Date__c
				var $calendar = $('div#calendar');
				$calendar.fullCalendar('gotoDate', moment($scope.period.Start_Date__c));
				$scope.getTimeCardHeader();
				$scope.$apply();
				// trigger the fullcalendar dayRender() method
				$calendar.fullCalendar('prev');
				$calendar.fullCalendar('next');
				$('i#fa-loader-get-period').hide();
			} else {
				EmployeeTimeCardController.getCurrentPeriod(
					function(result, event) {
						if(event.type === 'exception') {
							showAlert(event.message);
						}else if(event.status) {
							if(result.length>0) {
								$scope.period = result[0];
								// update the fullcanledar date to be aligned with the current Period__c.Start_Date__c
								var $calendar = $('div#calendar');
								$calendar.fullCalendar('gotoDate', moment($scope.period.Start_Date__c));
								$scope.getTimeCardHeader();
								$scope.$apply();
								// trigger the fullcalendar dayRender() method
								$calendar.fullCalendar('prev');
								$calendar.fullCalendar('next');
							} else {
								showAlert('No Current Period Found. A new Period__c record with this weeks dates needs to be created.', true);
							}
							$('i#fa-loader-get-period').hide();
						}else {
							showAlert(event.message);
						}
					}, {buffer: false, escape: true}
				);
			}
		};

		$scope.getTimeCardHeader = function() {
			$('i#fa-loader-time-card-entry').show();
			EmployeeTimeCardController.getTimeCardHeader($scope.user.Id, $scope.period.Id,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.timeCardHeader = result;
						$scope.initFullCalendar();
						// trigger the fullcalendar dayRender() method
						var $calendar = $('div#calendar');
						$calendar.fullCalendar('prev');
						$calendar.fullCalendar('next');
						$scope.getTimeCardEntries();
						$scope.$apply();
						$('i#fa-loader-time-card-entry').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.getTimeCardEntries = function(pTimeCardEntryId) {
			$('i#fa-loader-time-card-entry').show();
			EmployeeTimeCardController.getTimeCardEntries($scope.user.Id, $scope.timeCardHeader.Id, $scope.period.Id,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.timeCardEntries = result;
						var $calendar = $('div#calendar');
						// populate the fullcalendar event data
    	            	var timeCardEntryArr = [];
    	            	$scope.periodTotal = 0;
    	            	for(var i=0; i<$scope.timeCardEntries.length; i++){
    	            		if(!$scope.timeCardEntries[i].Internal_Comments__c) {
    	            			$scope.timeCardEntries[i].Internal_Comments__c = '';
    	            		}
    	            		timeCardEntryArr.push({
    	            			allDay: true,
								project: decodeCharacters($scope.timeCardEntries[i].ProjectId__r.Name),
								supportRequest: $scope.timeCardEntries[i].Support_RequestId__c ? decodeCharacters($scope.timeCardEntries[i].Support_RequestId__r.Name) : null,
    	            			milestone: decodeCharacters($scope.timeCardEntries[i].MilestoneId__r.Name),
    	            			assignment: $scope.timeCardEntries[i].AssignmentId__c ? decodeCharacters($scope.timeCardEntries[i].AssignmentId__r.Subject__c) : null,
    	            			hours: $scope.timeCardEntries[i].Hours_Entered__c,
    	            			id: $scope.timeCardEntries[i].Id,
    	            			name: $scope.timeCardEntries[i].Name,
    	            			internalcomments: $scope.timeCardEntries[i].Internal_Comments__c,
    	            			notes: decodeCharacters($scope.timeCardEntries[i].Notes__c),
    	        				start: moment.utc($scope.timeCardEntries[i].Date_Entered__c),
    	        				title: decodeCharacters($scope.timeCardEntries[i].ProjectId__r.Name)+' '+decodeCharacters($scope.timeCardEntries[i].MilestoneId__r.Name)
    	            		});
    	            		$scope.periodTotal += $scope.timeCardEntries[i].Hours_Entered__c;
    	            	}

    	            	// calculate daily totals
    	            	$('div#calendar').find('div.day-total-container').remove();
    	            	var tempObj = {};
    	            	var dataDate = '';
    	            	var compareDate = '';
						for(var i=0; i<$scope.timeCardEntries.length;i++) {
							var d = $scope.timeCardEntries[i].Date_Entered__c;
							if(!tempObj[d]) {
								tempObj[d] = [];
							}
							tempObj[d].push($scope.timeCardEntries[i]);
						}
						for(var prop in tempObj) {
							$scope.dayTotal = 0;
							for(var i=0; i<tempObj[prop].length; i++) {
								$scope.dayTotal += tempObj[prop][i].Hours_Entered__c;
								if(i===0) {
									compareDate = String(moment.utc(tempObj[prop][i].Date_Entered__c).format('YYYY-MM-DD'));
								}
							}
							// show daily total on fullCalendar date header th.fc-day-header element
							$calendar.find('th.fc-day-header[data-date="'+compareDate+'"]').append('<div class="day-total-container"><span class="day-total">Total Hours: '+$scope.dayTotal+'</span></div>');
						}
    	            	// dynamically update fullCalendar with ajax result
    	            	$calendar.fullCalendar('removeEvents');  
    	            	$calendar.fullCalendar('removeEventSource', timeCardEntryArr);
    	            	$calendar.fullCalendar('addEventSource', timeCardEntryArr);
    	            	$calendar.fullCalendar('rerenderEvents');
						$scope.$apply();
						$('i#fa-loader-time-card-entry').hide();
						if(pTimeCardEntryId) {
							highlightLastRecord(pTimeCardEntryId);
						}
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.getPreviousPeriod = function(period) {
			$('i#fa-loader-get-period').show();
			EmployeeTimeCardController.getPreviousPeriod(period,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						if(result.length>0) {
							$scope.period = result[0];
							// update the fullcalendar date to be aligned with the current Period__c.Start_Date__c
							var $calendar = $('div#calendar')
							$calendar.fullCalendar('gotoDate', moment($scope.period.Start_Date__c));
							$scope.getTimeCardHeader();
							$scope.$apply();
							// trigger the fullcalendar dayRender() method
							$calendar.fullCalendar('prev');
							$calendar.fullCalendar('next');
							hideAlert();
						}else {
							showAlert('No previous period found for: '+ period.Name +'. A new Period__c record with this weeks dates needs to be created.', true);
						}
						$('i#fa-loader-get-period').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.getNextPeriod = function(period) {			
			$('i#fa-loader-get-period').show();
			EmployeeTimeCardController.getNextPeriod(period,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						if(result.length>0) {
							$scope.period = result[0];
							var $calendar = $('div#calendar')
							// update the fullcanledar date to be aligned with the current Period__c.Start_Date__c
							$calendar.fullCalendar('gotoDate', moment($scope.period.Start_Date__c));
							$scope.getTimeCardHeader();
							$scope.$apply();
							// trigger the fullcalendar dayRender() method
							$calendar.fullCalendar('prev');
							$calendar.fullCalendar('next');
							hideAlert();
						}else {
							showAlert('No next period found for: '+ period.Name + '. A new Period__c record with this weeks dates needs to be created.', true);
						}
						$('i#fa-loader-get-period').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.addTimeCardEntry = function(pIsEdit) {
			$scope.isEditTimeCardEntry = pIsEdit;
			// clear-out values for new time card entries (not in edit)
			if(!$scope.isEditTimeCardEntry) {
				$scope.selectedTimeCardEntry.Notes__c = '';
				$scope.selectedTimeCardEntry.Internal_Comments__c = '';
				$scope.accountId = '';
				$('input#search-accounts').val('');
			}
			
			if(!$scope.isEditTimeCardEntry) {
				if($scope.timeEntryType === 'Project') {
					$scope.addTimeCardEntryForProject();
				}
				else if($scope.timeEntryType === 'Support Request') {
					$scope.addTimeCardEntryForSupportRequest();
				}
				else {
					showAlert('Time Entry Type "' + $scope.timeEntryType + '" not supported. Please contact your system administrator');
				}
			}
			else {
				if($scope.selectedTimeCardEntry.Support_RequestId__c) {
					$scope.addTimeCardEntryForSupportRequest();					
				}
				else {
					$scope.addTimeCardEntryForProject();
				}
			}
		};

		$scope.addTimeCardEntryForProject = function(fromParam) {
			$('i#fa-loader-get-projects').show();
			$('div#modal-project').modal('show');
			EmployeeTimeCardController.getProjects($scope.activeOnly, $scope.projectType,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.projects = result;
						$scope.$apply();
						if($scope.isEditTimeCardEntry || fromParam) {
							$scope.selectedProject = $scope.selectedTimeCardEntry.ProjectId__r;
							$scope.selectProject($scope.selectedProject);
						}else {
							$scope.selectedProject = {};
							$scope.selectedMilestone = {};
							$scope.selectedAssignment = {};
							$scope.selectedTimeCardEntry = {};
							// assign 1 as default value for Hours_Entered__c in edit modal
							$scope.selectedTimeCardEntry.Hours_Entered__c = 1;
							highlightLastRecordProject();
							highlightLastRecordMilestone();
							highlightLastRecordAssignment();
						}
						$scope.$apply();
						$('i#fa-loader-get-projects').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		}

		$scope.addTimeCardEntryForSupportRequest = function(fromParam) {
			$('i#fa-loader-get-supportRequests').show();
			$('div#modal-supportRequest').modal('show');

			//$scope.getSupportRequestStatuses();
			EmployeeTimeCardController.getSupportRequests($scope.supportRequestStatus,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.supportRequests = result;
						$scope.$apply();
						if($scope.isEditTimeCardEntry || fromParam) {
							$scope.selectedSupportRequest = $scope.selectedTimeCardEntry.Support_RequestId__r;
							$scope.selectSupportRequest($scope.selectedSupportRequest);
						}else {
							$scope.selectedSupportRequest = {};
							$scope.selectedMilestone = {};
							$scope.selectedTimeCardEntry = {};
							// assign 1 as default value for Hours_Entered__c in edit modal
							$scope.selectedTimeCardEntry.Hours_Entered__c = 1;
							highlightLastRecordSupportRequest();
						}
						$scope.$apply();
						$('i#fa-loader-get-supportRequests').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		}

		$scope.handleAccounts = function(pObj) {
			// account selection
			$scope.accountId = '';
			if(pObj===null) {
				$('div#project, div#milestone').removeClass('col-sm-4 col-md-4 col-lg-4').addClass('col-sm-6 col-md-6 col-lg-6');
				$scope.showAccount = false;
				$('div#account').hide();
			} else {
				if(decodeCharacters(pObj.Name)==='Sales Support & Scoping') {
					$('div#project, div#milestone').removeClass('col-sm-6 col-md-6 col-lg-6').addClass('col-sm-4 col-md-4 col-lg-4');
					$scope.showAccount = true;
					$('div#account').show();
				} else {
					$('div#project, div#milestone').removeClass('col-sm-4 col-md-4 col-lg-4').addClass('col-sm-6 col-md-6 col-lg-6');
					$scope.showAccount = false;
					$('div#account').hide();
				}
			}
		};

		$scope.handleAssignments = function(pAssignments) {
			if(pAssignments === null){
				$('div#project, div#milestone').removeClass('col-sm-4 col-md-4 col-lg-4').addClass('col-sm-6 col-md-6 col-lg-6');
				$('div#assignment').hide();
			}
			else if(pAssignments.length === 0 && !$scope.showAccount) {
				$('div#project, div#milestone').removeClass('col-sm-4 col-md-4 col-lg-4').addClass('col-sm-6 col-md-6 col-lg-6');
				$('div#assignment').hide();
			} else if(pAssignments.length === 0 && $scope.showAccount) {
				$('div#assignment').hide();
			}else if(pAssignments.length > 0) {
				$('div#project, div#milestone').removeClass('col-sm-6 col-md-6 col-lg-6').addClass('col-sm-4 col-md-4 col-lg-4');
				$('div#assignment').show();
				setTimeout(function(){
					if($scope.isEditTimeCardEntry && $scope.selectedTimeCardEntry.AssignmentId__c) {
						$scope.selectedAssignment = $scope.selectedTimeCardEntry.AssignmentId__r;
						$scope.selectAssignment($scope.selectedAssignment, true);
					}
				}, 10);
			}
		};

		$scope.selectProject = function(pProject, pIsResetMilestone) {
			$scope.selectedProject = pProject;
			$scope.selectedMilestone = {};
			$scope.selectedAssignment = {};
			$scope.handleAssignments(null);
			$scope.selectedTimeCardEntry.ProjectId__c = $scope.selectedProject.Id;
			$('i#fa-loader-get-milestones').show();
			highlightLastRecordProject($scope.selectedProject.Id);
			$scope.handleAccounts(pProject);
			EmployeeTimeCardController.getMilestones($scope.selectedProject.Id,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.milestones = result;
						$scope.$apply();
						$('i#fa-loader-get-milestones').hide();
						if(!pIsResetMilestone) {
							if($scope.isEditTimeCardEntry) {
								$scope.selectedMilestone = $scope.selectedTimeCardEntry.MilestoneId__r;
								$scope.selectMilestone($scope.selectedMilestone, true);
							}
						}
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.selectSupportRequest = function(pSupportRequest, pIsResetMilestone) {
			$scope.selectedSupportRequest = pSupportRequest;
			$scope.selectedTimeCardEntry.Support_RequestId__c = $scope.selectedSupportRequest.Id;
			highlightLastRecordSupportRequest($scope.selectedSupportRequest.Id);
			$scope.handleAccounts(pSupportRequest);
			$('i#fa-loader-get-supportRequestDetails').show();
			EmployeeTimeCardController.getProjectForSupportRequest($scope.selectedSupportRequest.Id,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.selectedProject = result;
						$scope.selectedMilestone = {};
						$scope.selectedTimeCardEntry.ProjectId__c = $scope.selectedProject.Id;
						$scope.handleAccounts($scope.selectedProject);
						EmployeeTimeCardController.getMilestones($scope.selectedProject.Id,
							function(result, event) {
								if(event.type === 'exception') {
									showAlert(event.message);
								}else if(event.status) {
									$scope.milestones = result;
									$scope.selectedMilestone = $scope.milestones[0];
									$scope.selectMilestone($scope.selectedMilestone, true);
									$scope.$apply();
									$('i#fa-loader-get-supportRequestDetails').hide();
									if(!pIsResetMilestone) {
										if($scope.isEditTimeCardEntry) {
											$scope.selectedMilestone = $scope.selectedTimeCardEntry.MilestoneId__r;
											$scope.selectMilestone($scope.selectedMilestone, true);
										}
									}
								}else {
									showAlert(event.message);
								}
							}, {buffer: false, escape: true}
						);
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);			
		};

		$scope.selectMilestone = function(pMilestone, pRequiresApply) {
			$scope.selectedMilestone = pMilestone;
			$scope.selectedTimeCardEntry.MilestoneId__c = pMilestone.Id;
			$scope.selectedAssignment = {};
			highlightLastRecordMilestone(pMilestone.Id);
			if(pRequiresApply) {
				$scope.$apply();
			}
			$scope.handleAccounts(pMilestone);
			$('i#fa-loader-get-assignments').show();
			EmployeeTimeCardController.getAssignments(pMilestone.Id,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.assignments = result;
						$scope.handleAssignments($scope.assignments);
						$scope.$apply();
						$('i#fa-loader-get-assignments').hide();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.selectAssignment = function(pAssignment, pRequiresApply) {
			$scope.selectedAssignment = pAssignment;
			$scope.selectedTimeCardEntry.AssignmentId__c = pAssignment.Id;
			highlightLastRecordAssignment(pAssignment.Id);
			if(pRequiresApply) {
				$scope.$apply();
			}
		}

		$scope.deleteTimeCardEntry = function(pTimeCardEntryId) {
			hideAlert();
			$('i#fa-loader-time-card-entry').show();
			EmployeeTimeCardController.deleteTimeCardEntry(pTimeCardEntryId,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$('i#fa-loader-time-card-entry').hide();
						$('div#modal-project').modal('hide');
						$('div#modal-supportRequest').modal('hide');
						$scope.getTimeCardEntries();
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.cloneTimeCardEntry = function(pTimeCardEntryId) {
			if(!$scope.selectedProject.Is_Active__c) {
				showAlert('Time Card Entry can not be cloned due to its\' Project '+$scope.selectedProject.Name+' having an inactive stauts.');
			} else {
				$('i#fa-loader-time-card-entry').show();
				EmployeeTimeCardController.cloneTimeCardEntry(pTimeCardEntryId,
					function(result, event) {
						if(event.type === 'exception') {
							showAlert(event.message);
						}else if(event.status) {
							$('i#fa-loader-time-card-entry').hide();
							$('div#modal-project').modal('hide');
							$scope.getTimeCardEntries(result.Id);
						}else {
							showAlert(event.message);
						}
					}, {buffer: false, escape: true}
				);
			}
		};

		$scope.isMonday = function() {
			if(!$scope.selectedTimeCardEntry.Day_of_the_Week__c.match(/Monday/gi)) { 
				return false;
			} else {
				return true;
			}
		};

		$scope.completeWeek = function() {
			if(!$scope.selectedProject.Is_Active__c) {
				showAlert('Time Card Entry can not be cloned due to its\' Project '+$scope.selectedProject.Name+' having an inactive stauts.');
			} else if(!$scope.selectedTimeCardEntry.Day_of_the_Week__c.match(/Monday/gi)) { 
				showAlert('In order to Clone X5, the Date must be Monday');
			} else {
				$('i#fa-loader-time-card-entry').show();
				$scope.updateTimeCardEntry(true);
			}
		};

		$scope.editTimeCardEntry = function(pTimeCardEntry) {
			$scope.selectedTimeCardEntry = pTimeCardEntry;
			$scope.selectedTimeCardEntry.ProjectId__r.Name = decodeCharacters($scope.selectedTimeCardEntry.ProjectId__r.Name);
			$scope.selectedTimeCardEntry.MilestoneId__r.Name = decodeCharacters($scope.selectedTimeCardEntry.MilestoneId__r.Name);
			if($scope.selectedTimeCardEntry.AssignmentId__c){
				$scope.selectedTimeCardEntry.AssignmentId__r.Subject__c = decodeCharacters($scope.selectedTimeCardEntry.AssignmentId__r.Subject__c);
			}
			$scope.selectedTimeCardEntry.Notes__c = decodeCharacters($scope.selectedTimeCardEntry.Notes__c);
			$scope.addTimeCardEntry(true);
		};

		$scope.updateTimeCardEntry = function(isCompleteWeek) {
			if(!$scope.selectedTimeCardEntry.Hours_Entered__c || $scope.selectedTimeCardEntry.Hours_Entered__c>40) {
				showAlert('Please enter a value between 0.25 and 40 hours');
				$('input#edit-hours').focus();
			} else if(!$scope.selectedTimeCardEntry.Notes__c) {
				$scope.selectedTimeCardEntry.Notes__c = '';
				if($scope.projectType == 'Client Project') showAlert('You must add Client Facing Invoice Details.');
				else if($scope.projectType == 'Internal Project') showAlert('You must add Notes.');
				$('textarea#edit-week-notes').focus();
			} 
			else if($scope.projectType == 'Internal Project' && $scope.assignments.length > 0 && $scope.user.Team__c === 'Professional Services' && !$scope.selectedAssignment.Id){
			 	showAlert('You must select the associated Assignment.');
			}else {
				if(!$scope.selectedTimeCardEntry.Internal_Comments__c) {
					$scope.selectedTimeCardEntry.Internal_Comments__c = '';
				}
				hideAlert();
				$('div#modal-project').modal('hide');
				$('div#modal-supportRequest').modal('hide');
				// create new property for and assign the AccountId__c lookup field
				$scope.selectedTimeCardEntry.AccountId__c = $scope.accountId;
				if($scope.selectedDate)
					$scope.selectedTimeCardEntry.Date_Entered__c = $scope.toSalesforceDate(new Date($scope.selectedDate)).getTime();
				var json = angular.toJson($scope.selectedTimeCardEntry);
				var tce = angular.fromJson(json);
				//console.log(tce);
				if($scope.isEditTimeCardEntry) {
					if(!$scope.selectedTimeCardEntry.ProjectId__r.Is_Active__c) {
						showAlert('Time Card Entry can not be updated due to its\' Project '+$scope.selectedTimeCardEntry.ProjectId__r.Name+' having an inactive stauts.');
						$scope.getTimeCardEntries();
					} else {
						EmployeeTimeCardController.updateTimeCardEntry(tce,
							function(result, event) {
								if(event.type === 'exception') {
									showAlert(event.message);
								}else if(event.status) {
									$scope.selectedTimeCardEntry = result;
									$('i#fa-loader-time-card-entry').hide();
									$scope.getTimeCardEntries();
									if(isCompleteWeek) {
										EmployeeTimeCardController.completeWeek(tce,
											function(result, event) {
												if(event.type === 'exception') {
													showAlert(event.message);
												}else if(event.status) {
													$('i#fa-loader-time-card-entry').hide();
													$('div#modal-project').modal('hide');
													$scope.getTimeCardEntries();
												}else {
													showAlert(event.message);
												}
											}, {buffer: false, escape: true}
										);
									}
								}else {
									showAlert(event.message);
								}
							}, {buffer: false, escape: true}
						);
					}
				} else {
					if(!$scope.selectedTimeCardEntry.Notes__c) {
						$scope.selectedTimeCardEntry.Notes__c = '';
					}
					if(!$scope.selectedTimeCardEntry.Internal_Comments__c) {
						$scope.selectedTimeCardEntry.Internal_Comments__c = '';
					}
					// var json = angular.toJson($scope.period);
					// var p = angular.fromJson(json);
					if(!$scope.selectedProject.Is_Active__c) {
						showAlert('Time Card Entry can not be created due to its\' Project '+$scope.selectedProject.Name+' having an inactive stauts.');
					} 
					if(moment.utc($scope.selectedDate).format('x') < moment.utc($scope.period.Start_Date__c).format('x') || moment.utc($scope.selectedDate).format('x') > moment.utc($scope.period.End_Date__c).format('x')){
						showAlert('Time Card Entry NOT created! You must select a Date within the current Period: '+$scope.period.Name+' ('+$filter('date')($scope.period.Start_Date__c, 'fullDate', 'utc')+' - '+$filter('date')($scope.period.End_Date__c, 'fullDate', 'utc')+')');
					}
					else {
						$scope.newTimeCardEntry.AccountId__c = $scope.accountId; 
		                $scope.newTimeCardEntry.Date_Entered__c = moment($scope.selectedDate).format('x');
		                $scope.newTimeCardEntry.EmployeeId__c = $scope.user.Id;
		                $scope.newTimeCardEntry.Hours_Entered__c = $scope.selectedTimeCardEntry.Hours_Entered__c;
		                $scope.newTimeCardEntry.Internal_Comments__c = $scope.selectedTimeCardEntry.Internal_Comments__c;
		                $scope.newTimeCardEntry.MilestoneId__c = $scope.selectedMilestone.Id;
		                $scope.newTimeCardEntry.Support_RequestId__c = $scope.selectedSupportRequest.Id || null;
		                $scope.newTimeCardEntry.Notes__c = $scope.selectedTimeCardEntry.Notes__c;
		                $scope.newTimeCardEntry.ProjectId__c = $scope.selectedProject.Id;
		                $scope.newTimeCardEntry.Time_Card_HeaderId__c = $scope.timeCardHeader.Id;
		                $scope.newTimeCardEntry.AssignmentId__c = $scope.selectedAssignment.Id || null;
						EmployeeTimeCardController.createTimeCardEntry($scope.newTimeCardEntry,
							// $scope.user.Id, $scope.selectedProject.Id, $scope.selectedMilestone.Id, $scope.selectedSupportRequest.Id || null, $scope.timeCardHeader.Id, $scope.selectedTimeCardEntry.Notes__c, $scope.selectedTimeCardEntry.Hours_Entered__c, $scope.selectedTimeCardEntry.Internal_Comments__c, $scope.selectedDate, p, $scope.accountId, $scope.selectedAssignment.Id || null,
							function(result, event) {
								if(event.type === 'exception') {
									showAlert(event.message);
								}else if(event.status) {
									$('i#fa-loader-time-card-entry').hide();
									if(result) {
										$scope.getTimeCardEntries(result.Id);
										$scope.newTimeCardEntry = {};
									} else {
										showAlert('Time Card Entry NOT created! You must select a Date within the current Period: '+$scope.period.Name+' ('+$filter('date')($scope.period.Start_Date__c, 'fullDate', 'utc')+' - '+$filter('date')($scope.period.End_Date__c, 'fullDate', 'utc')+')');
									}
								}else {
									showAlert(event.message);
								}
							}, {buffer: false, escape: true}
						);
					}
				}
				
			}
		};

		$scope.saveAndNew = function(isCompleteWeek) {
			$scope.updateTimeCardEntry();
			$scope.handleAccounts(null);
			$scope.handleAssignments(null);
			setTimeout(function() {
				$scope.addTimeCardEntry(false);
			}, 500);
		};

		$scope.updatePeriodNotes = function() {
			var isValid = true;
			for(var i=0; i<$scope.timeCardEntries.length; i++) {
				if(!$scope.timeCardEntries[i].ProjectId__r.Is_Active__c) {
					isValid = false;
				}
			}
			$('i#fa-loader-time-card-entry').show();
			// send tempArr consisting of active Time_Card_Entry__c records only
			var tempArr = [];
			for(var i=0; i<$scope.timeCardEntries.length; i++) {
	            if($scope.timeCardEntries[i].ProjectId__r.Is_Active__c) {
	            	$scope.timeCardEntries[i].Notes__c = $scope.weekNotes;
	                tempArr.push($scope.timeCardEntries[i]);
	            }
	        }
			var json = angular.toJson(tempArr);
			var tceArr = angular.fromJson(json);
			EmployeeTimeCardController.updatePeriodNotes(tceArr,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					}else if(event.status) {
						$scope.getTimeCardEntries();
						$('div#modal-week-notes').modal('hide');
					}else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
			if(!isValid) {
				showAlert('Week Notes could not be added to one or more Time Card Entrty records due to its\' Project having an inactive stauts. However, we did add your notes to the records with an active status :)');
			}
		};

		$scope.submitForApproval = function() {
			if(confirm('Are you sure you want to submit for approval? Doing so will lock your time card for this Period: '+$scope.period.Name+' ('+$filter('date')($scope.period.Start_Date__c, 'fullDate', 'utc')+' - '+$filter('date')($scope.period.End_Date__c, 'fullDate', 'utc')+')')) {
				$('i#fa-loader-time-card-entry').show();
				$scope.timeCardHeader.Status__c = 'Completed';
				var json = angular.toJson($scope.timeCardHeader);
				var tch = angular.fromJson(json);
				EmployeeTimeCardController.submitForApproval(tch,
					function(result, event) {
						if(event.type === 'exception') {
							showAlert(event.message);
						}else if(event.status) {
							$scope.timeCardHeader = result;
							$scope.getTimeCardEntries();
							var $calendar = $('div#calendar');
							// trigger the fullcalendar dayRender() method
							$calendar.fullCalendar('prev');
							$calendar.fullCalendar('next');
						}else {
							showAlert(event.message);
						}
					}, {buffer: false, escape: true}
				);
			}
		};

		$scope.addNotes = function() {
			$scope.weekNotes = '';
			$('div#modal-week-notes').modal('show');
			$('textarea#textarea-week-notes').focus();
		};

		$scope.backToSalesforce = function() {
			window.location.href = '\\';
		};

		$scope.reloadProjects = function () {
			$('i#fa-loader-get-projects').show();
			EmployeeTimeCardController.getProjects($scope.activeOnly, $scope.projectType,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					} else if(event.status) {
						$scope.projects = result;
						$scope.$apply();
						$('i#fa-loader-get-projects').hide();
					} else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		}

		$scope.reloadSupportRequests = function() {
			$('i#fa-loader-get-supportRequests').show();
			EmployeeTimeCardController.getSupportRequests($scope.supportRequestStatus,
				function(result, event) {
					if(event.type === 'exception') {
						showAlert(event.message);
					} else if(event.status) {
						$scope.supportRequests = result;
						$scope.$apply();
						$('i#fa-loader-get-supportRequests').hide();
					} else {
						showAlert(event.message);
					}
				}, {buffer: false, escape: true}
			);
		};

		$scope.changeActive = function() {
			$scope.reloadProjects();
		};

		$scope.changeProjectType = function() {
			$scope.reloadProjects();
			$scope.handleAssignments(null);
		};

		$scope.changeSupportRequestStatus = function() {
			$scope.reloadSupportRequests();
		};

		$scope.getHoursClass = function() {
			if($scope.periodTotal===40) {
				 return 'black'
			} else if($scope.periodTotal<=40) {
				return 'text-primary';
			} else if($scope.periodTotal>=40) {
				return 'text-danger';
			}
		};

		// initialize FullCalendar js{
    	$scope.initFullCalendar = function() {
	    	$('div#calendar').fullCalendar({
    	    	allDay: true,
    	    	dayClick: function(date) {
			        $scope.handleAccounts(null);
			        $scope.handleAssignments(null);
			        if($scope.timeCardHeader.Status__c!=='Open') {
    	        		showAlert('Period '+$scope.period.Name+' is locked due to Status: '+$scope.timeCardHeader.Status__c);
    	        		return;
    	        	} else {
			        	hideAlert();
			        	// var tempArr = date.format().toString().split('-');
	    	    		$scope.selectedDate = moment(date).format('L');
	    	    		$('input#edit-date').datepicker('setDate',$scope.selectedDate);
	    	    		// String(tempArr[1]+'/'+tempArr[2]+'/'+tempArr[0]);
	    	    		$('div#calendar .selected-row').removeClass('selected-row');
	    	    		$(this).addClass('selected-row');
	    	    		$scope.addTimeCardEntry(false);
			        }
    	        },
    	        defaultDate: moment(),
    	        displayEventTime: false,
    	        editable: true,
    	        eventClick: function(calEvent) {
    	        	var dt = calEvent.start;
    	        	if(dt<$scope.period.Start_Date__c || dt>$scope.period.End_Date__c) {
    	        		showAlert('You must select a Time Card Entry within the current Period: '+$scope.period.Name+' ('+$filter('date')($scope.period.Start_Date__c, 'fullDate', 'utc')+' - '+$filter('date')($scope.period.End_Date__c, 'fullDate', 'utc')+')');
    	        		return;
    	        	} else if($scope.timeCardHeader.Status__c!=='Open') {
    	        		showAlert('Time Card Entry '+calEvent.name+' is locked due to Status: '+$scope.timeCardHeader.Status__c);
    	        		return;
    	        	} else {
    	        		hideAlert();
    	        		// var tempArr = dt.format().toString().split('-');
	    	    		$scope.selectedDate = moment(dt).format('L');
	    	    		// String(tempArr[1]+'/'+tempArr[2]+'/'+tempArr[0]);
	    	    		$('input#edit-date').datepicker('setDate',$scope.selectedDate);
	    	        	$('div#calendar .selected-row').removeClass('selected-row');
	    	    		$(this).closest('td.fc-day').addClass('selected-row');
	    	    		// find the correct Time_Card_Entry__c record
	    	    		for(var i=0; i<$scope.timeCardEntries.length; i++) {
	    	    			if($scope.timeCardEntries[i].Id===calEvent.id) {
	    	    				$scope.selectedTimeCardEntry = $scope.timeCardEntries[i];
	    	    			}
	    	    		}
	    	    		if($scope.selectedTimeCardEntry.ProjectId__r.RecordType.DeveloperName === 'BSI_Project_Internal'){
			    			$scope.projectType = 'Internal Project';
			    		}
			    		else{
			    			$scope.projectType = 'Client Project';
			    		}
	    	        	$scope.editTimeCardEntry($scope.selectedTimeCardEntry);
    	        	}
    	        },
    	        eventDurationEditable: false,
    	        eventRender: function(event, element) {
    	        	if(!event.notes) {
    	        		event.notes = '';
    	        	}
					// update the fullcalendar event title element .fc-tile to be more complex HTML
					if(event.supportRequest) {
						element.find('.fc-title').empty().html(
							'<div>'+
								'<label class="label-tce label-tce-top">Support Request</label>'+
								'<div class="light-font">'+event.supportRequest+'</div>'+
							'</div>'+
							'<div>'+
								'<label class="label-tce">Hours</label><span class="light-font">'+event.hours+'</span>'+
							'</div>'+
							'<div>'+
								'<label class="label-tce">Notes</label>'+
								'<span class="light-font">'+event.notes+'</span>'+
							'</div>'
						);
						element.addClass('calendar-event-supportRequest');
					}
					else {
						element.find('.fc-title').empty().html(
							`<div>
								<label class="label-tce label-tce-top">Project</label>
								<div class="light-font">${event.project}</div>
							</div>
							<div>
								<label class="label-tce">Milestone</label>
								<div class="light-font">${event.milestone}</div>
							</div>`
						);
						if(event.assignment){
							element.find('.fc-title').append(
								`<div>
									<label class="label-tce">Assignment</label>
									<div class="light-font">${event.assignment}</div>
								</div>`
							);
						}
						element.find('.fc-title').append(
							`<div>
								<label class="label-tce">Hours</label><span class="light-font">${event.hours}</span>
							</div>
							<div>
								<label class="label-tce">Notes</label>
								<span class="light-font">${event.notes}</span>
							</div>
							<div>
								<label class="label-tce">Internal Comments</label>
								<div class="light-font">${event.internalcomments}</div>
							</div>`
						);
						element.addClass('calendar-event-project');
					}
					if($scope.timeCardHeader.Status__c!=='Open') {
						element.addClass('not-in-period');
					}
				},
    	        dayRender: function(date, cell) {
    	        	if(date<$scope.period.Start_Date__c || date>$scope.period.End_Date__c || $scope.timeCardHeader.Status__c!=='Open') {
			            cell.addClass('not-in-period');
			        } else {
			        	cell.addClass('in-period');
			        }
    	        },
    	        defaultView: 'basicWeek',
    	        eventDrop: function(event, delta, revertFunc) {
    	        	if($scope.timeCardHeader.Status__c!=='Open') {
    	        		showAlert('Time Card Entry '+event.name+' is locked due to Status: '+$scope.timeCardHeader.Status__c);
    	        		revertFunc();
    	        	} else {
    	        		// find the correct Time_Card_Entry__c record
	    	    		for(var i=0; i<$scope.timeCardEntries.length; i++) {
	    	    			if($scope.timeCardEntries[i].Id===event.id) {
	    	    				$scope.selectedTimeCardEntry = $scope.timeCardEntries[i];
	    	    			}
						}
						$scope.selectedDate = null;
				       	$scope.selectedTimeCardEntry.Date_Entered__c = new Date(event.start.format()).getTime();
				       	$scope.isEditTimeCardEntry = true;
				       	$scope.updateTimeCardEntry();
			       	}
			    },
    	        eventLimit: false,
    	        header: {
    	            left: '',
    	            center: 'title',
    	            right: ''
    	        },
    	        ignoreTimezone: true,
    	        timeFormat: 'H(:mm)',
    	        timezone: 'UTC',
    	        titleFormat: 'MMMM D YYYY',
    	        weekends: true
    	    });
		};
		
		$scope.determineParametersPassed = function() {
			var projectId = $('input#param-projectId').val();
			var supportRequestId = $('input#param-supportRequestId').val();

			if(projectId || supportRequestId) {
				$scope.selectedTimeCardEntry.Notes__c = '';
				$scope.selectedTimeCardEntry.Internal_Comments__c = '';
				$scope.accountId = '';
				$scope.selectedDate = moment().format('MM/DD/YYYY');
				$('input#search-accounts').val('');
				
				if(supportRequestId) {
					EmployeeTimeCardController.getSupportRequest(supportRequestId,
						function(result, event) {
							if(event.type === 'exception') {
								showAlert(event.message);
							} else if(event.status) {
								if(result) {
									$scope.selectedTimeCardEntry.Hours_Entered__c = 1;								
									$scope.selectedTimeCardEntry.Support_RequestId__r = result;
									$scope.selectedTimeCardEntry.ProjectId__r = result.BSI_Project__r;
									$scope.addTimeCardEntryForSupportRequest(true);
								}
								else {
									showAlert('Support Request with Id ' + supportRequestId + ' does not qualify the filter criteria, please select another support request');
									$scope.addTimeCardEntryForSupportRequest();
								}								
							} else {
								showAlert(event.message);
							}
						}, {buffer: false, escape: true}
					);
				}
				else if(projectId) {
					EmployeeTimeCardController.getProject(projectId,
						function(result, event) {
							if(event.type === 'exception') {
								showAlert(event.message);
							} else if(event.status) {
								if(result) {
									$scope.selectedTimeCardEntry.Hours_Entered__c = 1;								
									$scope.selectedMilestone = {};
									$scope.selectedAssignment = {};
									$scope.selectedTimeCardEntry.ProjectId__r = result;	
									$scope.addTimeCardEntryForProject(true);
								}
								else {
									showAlert('Project with Id ' + projectId + ' does not qualify the filter criteria, please select another project');
									$scope.addTimeCardEntryForProject();
								}
							} else {
								showAlert(event.message);
							}
						}, {buffer: false, escape: true}
					);
				}				

			}
		}
		$scope.determineParametersPassed(); // immediately invoke

 		// end AngularJS
	}]);

	// jQuery
	$('a#back-to-top').on('click', function(event){
    	event.preventDefault();
        $('html, body').animate({scrollTop: $('html').offset().top},'slow');
    });
	
	$('button#close-alert-error').on('click', function() {
		$('div#alert-error').fadeOut();
	});

	// jQuery autocomplete
	function autoComplete($ele) {
		$ele.autocomplete({
			source: function(request, response) {
				if($ele.is('input#search-employees')) {
					EmployeeTimeCardController.searchEmployees($ele.val(),
						function(result, event) {
							if(event.type==='exception') {
								console.log('exception: '+event);
							}else if(event.status) {
								$.each(result, function() {
									response(result);
								});
							}else{
								console.log(event.message);
							}
						},
						{buffer: false, escape: true}
					);
				} else if($ele.is('input#search-periods')) {
					EmployeeTimeCardController.searchPeriods($ele.val(),
						function(result, event) {
							if(event.type==='exception') {
								console.log('exception: '+event);
							}else if(event.status) {
								$.each(result, function() {
									response(result);
								});
							}else{
								console.log(event.message);
							}
						},
						{buffer: false, escape: true}
					);
				} else if($ele.is('input#search-accounts')) {
					EmployeeTimeCardController.searchAccounts($ele.val(),
						function(result, event) {
							if(event.type==='exception') {
								console.log('exception: '+event);
							}else if(event.status) {
								$.each(result, function() {
									response(result);
								});
							}else{
								console.log(event.message);
							}
						},
						{buffer: false, escape: true}
					);
				}
			},
			minLength: 2,
			select: function(event, ui) {
				event.stopPropagation();
				setTimeout(function() {
					var $body = $('body#ControllerMyTimeCard');
					if($ele.is('input#search-employees')) {
						$ele.val(ui.item.Name);
						$body.scope().user = ui.item;
						$body.scope().getCurrentPeriod(false);
						$body.scope().user.FirstName = ui.item.Name.split(' ')[0];
					} else if($ele.is('input#search-periods')) {
						$ele.val(ui.item.Name);
						// assicoate the ui.item obj back to $scope.period obj
						$body.scope().period.Id = ui.item.Id;
						$body.scope().period.Name = ui.item.Name;
						$body.scope().period.End_Date__c = ui.item.End_Date__c;
						$body.scope().period.Start_Date__c = ui.item.Start_Date__c;
						$body.scope().getCurrentPeriod(true);
					} else if($ele.is('input#search-accounts')) {
						$ele.val(ui.item.Name);
						// assign the ui.item.Id to $scope.accountId
						$body.scope().accountId = ui.item.Id;
					}
				}, 1);
			}
		}).data('uiAutocomplete')._renderItem = function(ul, item) {
			return $('<li></li>').data('ui-autocomplete-item', item).append('<a data-id='+item.Id+'>'+item.Name+'</a>').appendTo(ul);
		};
	}

	$('div#modal-project').on('hidden.bs.modal', function() {
		var $body = $('body#ControllerMyTimeCard');
		$body.scope().selectedProject = {};
		$body.scope().selectedMilestone = {};
		$body.scope().milestones = [];
		$body.scope().searchProjects = '';
		$body.scope().searchMilestones = '';
		$body.scope().selectedAssignment = {};
		$body.scope().assignments = [];
		$body.scope().searchAssignments = '';
		highlightLastRecordProject();
		highlightLastRecordMilestone();
		highlightLastRecordAssignment();
	});

	$('div#modal-project').on('shown.bs.modal', function() {
		$('input#search-projects').val('').focus();
	});

	$('div#modal-supportRequest').on('hidden.bs.modal', function() {
		var $body = $('body#ControllerMyTimeCard');
		$body.scope().selectedSupportRequest = {};
		$body.scope().selectedMilestone = {};
		$body.scope().milestones = [];
		$body.scope().searchSupportRequests = '';
		highlightLastRecordSupportRequest();
	});	

	$('div#modal-supportRequest').on('shown.bs.modal', function() {
		$('input#search-supportRequests').val('').focus();
	});

	$('div#modal-week-notes').on('shown.bs.modal', function() {
		$('textarea#textarea-week-notes').focus();
	});

	$('textarea#edit-internal-comments, textarea#edit-week-notes').on('keyup', function(){
		var textarea = $(this);
		if(textarea.val().length>=255) {
			showAlert('You have reached the maximum character limit of 255 characters.');
			textarea.val(textarea.val().substring(0, 255));
		} else {
			hideAlert();
		}
	});

	// initialize autoComplete
	autoComplete($('input#search-employees'));
	autoComplete($('input#search-periods'));
	autoComplete($('input#search-accounts'));
}(jQuery));