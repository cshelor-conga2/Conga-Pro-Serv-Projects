/**
* @author Conga Services, ERedding
* @date 20181221
* @version 1.00
* @description Task Helper Class
*/
public without sharing class TaskHelper {

    /**
    * @description processCampaignAttribution - 
    */
    public static void processCampaignAttribution(List<Task> newTasks) {
        try{
            if(TriggerHelper.DoExecute('TaskHelper','processCampaignAttribution') && newTasks != null){

                // GET USERS FROM TASKS
                Set<Id> taskOwnerIds = new Set<Id>();
                for(Task task : newTasks){
                    taskOwnerIds.add(task.OwnerId);
                }

                // GET USER DATA
                Set<Id> attributionUsers = new Set<Id>();
                for(User user : [SELECT Id FROM User WHERE Id IN :taskOwnerIds AND Attribution_Department__c != null]){
                    attributionUsers.add(user.Id);
                }

                // QUALIFY NEW TASKS AND SPLIT INTO DEPARTMENTS
                List<Task> qualifyingTasks = new List<Task>();
                for(Task task : newTasks){
                    if(attributionUsers.contains(task.OwnerId)){
                        qualifyingTasks.add(task);
                    }
                }

                if(!qualifyingTasks.isEmpty() && !Test.isRunningTest()){
                    CampaignAttributionHelper.evaluateTasks(qualifyingTasks);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TaskHelper', 'processCampaignAttribution');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TaskHelper', 'processCampaignAttribution', newTasks, ex, true);
        }
    }

    /**
    * @description setParentOppStageStamp - 
    */
    public static void setParentOppStageStamp(List<Task> newTasks) {
        try{
            if(TriggerHelper.DoExecute('TaskHelper','setParentOppStageStamp') && newTasks != null){

                // GET QUALIFYING TASKS
                Set<Id> parentOppIds = new Set<Id>();
                for(Task newTask : newTasks){
                    if(newTask.WhatId != null && ((String)newTask.WhatId).left(3) == '006'){
                        parentOppIds.add(newTask.WhatId);
                    }
                }

                if(!parentOppIds.isEmpty()){

                    // GET PARENT OPPS
                    Map<Id, Opportunity> parentOpps = new Map<Id, Opportunity>([SELECT Id, StageName FROM Opportunity WHERE Id IN :parentOppIds]);

                    // UPDATE NEW TASKS
                    for(Task newTask : newTasks){
                        if(parentOpps.containsKey(newTask.WhatId)){
                            newTask.Opportunity_Stage__c = parentOpps.get(newTask.WhatId).StageName;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TaskHelper', 'setParentOppStageStamp');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TaskHelper', 'setParentOppStageStamp', newTasks, ex, true);
        }
    }

    /**
    * @description updateTaskParentRecordStats - 
    */
    public static void updateTaskParentRecordStats(List<Task> newOrUpdatedTasks, Map<Id, Task> outdatedOrDeletedTasks) {
        try{
            if(TriggerHelper.DoExecute('TaskHelper','updateTaskParentRecordStats') && (newOrUpdatedTasks != null || outdatedOrDeletedTasks != null)){
                Set<Id> qualifiedTasks = new Set<Id>();
                Set<Id> deletedTasksIds = new Set<Id>();

                // TRIGGER IS AFTER INSERT OR UPDATE
                if(newOrUpdatedTasks != null && !newOrUpdatedTasks.isEmpty()){
                    for(Task newOrUpdatedTask : newOrUpdatedTasks){
                        Task outdatedTask = outdatedOrDeletedTasks != null ? outdatedOrDeletedTasks.get(newOrUpdatedTask.Id) : null;
                        if((newOrUpdatedTask.IsClosed && outdatedTask == null) || (outdatedTask != null && (newOrUpdatedTask.Status != outdatedTask.Status || 
                                                                             (newOrUpdatedTask.Status == 'Completed' && newOrUpdatedTask.ActivityDate != outdatedTask.ActivityDate)))){
                            // TASK QUALIFIES IF NEW AND IS CLOSED, OR STATUS IS CHANGED, OR STATUS = COMPLETED AND THE ACTIVITY DATE CHANGES
                            qualifiedTasks.add(newOrUpdatedTask.Id);
                        }
                    }
                }
                // TRIGGER IS BEFORE DELETE
                else if((newOrUpdatedTasks == null || newOrUpdatedTasks.isEmpty()) && outdatedOrDeletedTasks != null && !outdatedOrDeletedTasks.isEmpty()){
                    for(Task deletedTask : outdatedOrDeletedTasks.values()){
                        if(deletedTask.IsClosed){
                            // DELETED TASKS QUALIFY IF THEY WERE CLOSED
                            qualifiedTasks.add(deletedTask.Id);
                            deletedTasksIds.add(deletedTask.Id);
                        }
                    }
                }

                if(!qualifiedTasks.isEmpty()){
                    List<Task> qualifiedTaskData = [SELECT Id, What.Type, Who.Type, WhatId, WhoId, ActivityDate, CreatedDate
                                                    FROM Task WHERE Id IN :qualifiedTasks AND Lead_Source_Activity__c != true];

                    Set<Id> casesToUpdateIds = new Set<Id>();
                    Set<Id> leadsToUpdateIds = new Set<Id>();
                    Set<Id> allIds = new Set<Id>();
                    for(Task task : qualifiedTaskData){
                        // GET CASE WHAT IDS
                        if(task.WhatId != null && task.What.Type == 'Case'){
                            casesToUpdateIds.add(task.WhatId);
                            allIds.add(task.WhatId);
                        }
                        // GET LEAD WHO IDS
                        if(task.WhoId != null && task.Who.Type == 'Lead'){
                            leadsToUpdateIds.add(task.WhoId);
                            allIds.add(task.WhoId);
                        }
                    }

                    if(!allIds.isEmpty()){

                        // GET CASE TASK COUNTS
                        Map<Id, Integer> caseTaskCountResults = new Map<Id, Integer>();
                        if(!casesToUpdateIds.isEmpty()){
                            // SET DEFAULTS OF ZERO
                            for(Id caseId : casesToUpdateIds){
                                caseTaskCountResults.put(caseId, 0);
                            }

                            // GET COUNTS
                            for(AggregateResult result : [SELECT WhatId, COUNT(Id) taskCount FROM Task WHERE WhatId IN :casesToUpdateIds AND IsCLosed = true AND Lead_Source_Activity__c = false
                                                          AND Id NOT IN :deletedTasksIds GROUP BY WhatId]){
                                Id whatId = (Id)result.get('WhatId');
                                Integer count = (Integer)result.get('taskCount');
                                caseTaskCountResults.put(whatId, count);
                            }
                        }

                        // GET LEAD TASK COUNTS
                        Map<Id, Integer> leadTaskCountResults = new Map<Id, Integer>();
                        if(!leadsToUpdateIds.isEmpty()){
                            // SET DEFAULTS OF ZERO
                            for(Id leadId : leadsToUpdateIds){
                                leadTaskCountResults.put(leadId, 0);
                            }

                            // GET COUNTS
                            for(AggregateResult result : [SELECT WhoId, COUNT(Id) taskCount FROM Task WHERE WhoId IN :leadsToUpdateIds AND IsCLosed = true AND Lead_Source_Activity__c = false
                                                          AND Id NOT IN :deletedTasksIds GROUP BY WhoId]){
                                Id whoId = (Id)result.get('WhoId');
                                Integer count = (Integer)result.get('taskCount');
                                leadTaskCountResults.put(whoId, count);
                            }
                        }

                        Set<Id> sdrBdrUserIds = new Set<Id>();
                        for(User sdrBdrUser : [SELECT Id FROM User WHERE UserRole.Name LIKE 'Business Development Representative%'
                                                                   OR UserRole.Name LIKE 'Sales Development Representative%']){
                            sdrBdrUserIds.add(sdrBdrUser.Id);
                        }

                        // CREATE MAX ACTIVITY DATES MAP AND ADD NULL DEFAULTS
                        Map<Id, Date> maxDatesByWhatOrWhoId = new Map<Id, Date>();
                        for(Id whoOrWhatId : allIds){
                            maxDatesByWhatOrWhoId.put(whoOrWhatId, null);
                        }
                        Map<Id, Datetime> minSdrBdrDatesByLeadId = new Map<Id, Datetime>();

                        // GET MAX ACTIVITY DATES
                        for(Task task : [SELECT OwnerId, WhatId, WhoId, ActivityDate, CompletedDateTime FROM Task WHERE Id NOT IN :deletedTasksIds AND (WhatId IN :casesToUpdateIds OR WhoId IN :leadsToUpdateIds)]){
                            // ADD CASE DATE IF NULL DEFAULT IS IN PLACE OR DATE IN MAP IS EARLIER THAN DATE ON TASK
                            if(maxDatesByWhatOrWhoId.containsKey(task.WhatId) && (maxDatesByWhatOrWhoId.get(task.WhatId) == null || 
                                                                                  maxDatesByWhatOrWhoId.get(task.WhatId) < task.ActivityDate)){
                                maxDatesByWhatOrWhoId.put(task.WhatId, task.ActivityDate);
                            }

                            // ADD LEAD MAX DATE IF NULL DEFAULT IS IN PLACE OR DATE IN MAP IS EARLIER THAN DATE ON TASK
                            if(maxDatesByWhatOrWhoId.containsKey(task.WhoId) && (maxDatesByWhatOrWhoId.get(task.WhoId) == null || 
                                                                                  maxDatesByWhatOrWhoId.get(task.WhoId) < task.ActivityDate)){
                                maxDatesByWhatOrWhoId.put(task.WhoId, task.ActivityDate);
                            }

                            // ADD LEAD MIN BDR/SDR DATE
                            if(task.CompletedDateTime != null && sdrBdrUserIds.contains(task.OwnerId) && 
                                (!minSdrBdrDatesByLeadId.containsKey(task.WhoId) || minSdrBdrDatesByLeadId.get(task.WhoId) > task.CompletedDateTime)){
                                minSdrBdrDatesByLeadId.put(task.WhoId, task.CompletedDateTime);
                            }
                        }

                        // PROCESS CASES AND UPDATE AS NECESSARY
                        List<Case> casesToUpdate = new List<Case>();
                        if(!casesToUpdateIds.isEmpty()){
                            // GET CASE DATA
                            Map<Id, Case> caseData = new Map<Id, Case>([SELECT Id, BusinessHoursId FROM Case WHERE Id IN :casesToUpdateIds]);

                            // UPDATE CASES WHERE NECESSARY 
                            for(Case caseToUpdate : caseData.values()){
                                if(caseTaskCountResults.containsKey(caseToUpdate.Id) || maxDatesByWhatOrWhoId.containsKey(caseToUpdate.Id)){
                                    if(caseTaskCountResults.containsKey(caseToUpdate.Id)){
                                        caseToUpdate.Completed_Activities__c = caseTaskCountResults.get(caseToUpdate.Id);
                                    }
                                    else{
                                        // IF THERE IS NO AGGREGATE THEN THERE ARE NO APPLICABLE TASKS FOR THE CASE
                                        caseToUpdate.Completed_Activities__c = 0;
                                    }

                                    if(maxDatesByWhatOrWhoId.containsKey(caseToUpdate.Id)){
                                        caseToUpdate.Last_Activity__c = maxDatesByWhatOrWhoId.get(caseToUpdate.Id);
                                    }
                                    casesToUpdate.add(caseToUpdate);
                                }
                            }
                        }

                        // PROCESS LEADS AND UPDATE AS NECESSARY
                        List<Lead> leadsToUpdate = new List<Lead>();
                        if(!leadsToUpdateIds.isEmpty()){
                            // GET LEAD DATA
                            Map<Id, Lead> leadData = new Map<Id, Lead>([SELECT Id, FPR__c FROM Lead WHERE Id IN :leadsToUpdateIds]);

                            // UPDATE LEADS WHERE NECESSARY
                            for(Lead leadToUpdate : leadData.values()){
                                if(leadTaskCountResults.containsKey(leadToUpdate.Id) || maxDatesByWhatOrWhoId.containsKey(leadToUpdate.Id) || minSdrBdrDatesByLeadId.containsKey(leadToUpdate.Id)){

                                    if(leadTaskCountResults.containsKey(leadToUpdate.Id)){
                                        leadToUpdate.Completed_Activities__c = leadTaskCountResults.get(leadToUpdate.Id);
                                    }
                                    else{
                                        // IF THERE IS NO AGGREGATE THEN THERE ARE NO APPLICABLE TASKS FOR THE LEAD
                                        leadToUpdate.Completed_Activities__c = 0;
                                    }

                                    if(maxDatesByWhatOrWhoId.containsKey(leadToUpdate.Id)){
                                        leadToUpdate.Last_Activity_Date__c = maxDatesByWhatOrWhoId.get(leadToUpdate.Id);
                                    }

                                    if(minSdrBdrDatesByLeadId.containsKey(leadToUpdate.Id) && leadToUpdate.FPR__c == null){
                                        leadToUpdate.FPR__c = minSdrBdrDatesByLeadId.get(leadToUpdate.Id);
                                    }
                                    leadsToUpdate.add(leadToUpdate);
                                }
                            }
                        }

                        // SAVE CASES
                        if(!casesToUpdate.isEmpty()){
                            Database.saveResult[] caseResults = Database.update(casesToUpdate, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(caseResults, 'TaskHelper', 'updateTaskParentRecordStats', false);
                        }

                        // SAVE LEADS
                        if(!leadsToUpdate.isEmpty()){
                            Database.saveResult[] leadResults = Database.update(leadsToUpdate, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(leadResults, 'TaskHelper', 'updateTaskParentRecordStats', false); 
                        }

                        // SAVE ANY LOGGED ERRORS
                        SystemIssueLogHelper.UpsertExceptions();
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TaskHelper', 'updateTaskParentRecordStats');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TaskHelper', 'updateTaskParentRecordStats', newOrUpdatedTasks, ex, true);
        }
    }


}