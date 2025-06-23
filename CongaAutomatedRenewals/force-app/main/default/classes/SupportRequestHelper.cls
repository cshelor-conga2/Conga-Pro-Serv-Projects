/**
* @author rbernier, eredding
* @date 20180306
* @version 1.00
* @description SupportRequestHelper - Custom functionality for the Support_Request__c object 
*/
public with sharing class SupportRequestHelper {

    /**
    * @description syncTimeCardEntries - 
    * @param List<Support_Request__c> updatedSRs - Updated Support_Request__c records
    * @param Map<Id, Support_Request__c> outdatedSRs - Outdated Support_Request__c records
    * @return void
    */
    public static void syncTimeCardEntries(List<Support_Request__c> updatedSRs, Map<Id, Support_Request__c> outdatedSRs){ 
        try{           
            if(TriggerHelper.DoExecute('SupportRequestHelper','syncTimeCardEntries') && updatedSRs != null){
                // GET LIST OF QUALIFIED SUPPORT REQUESTS AND POPULATE ID SETS
                Set<Id> supportRequestIds = new Set<Id>();
                Set<Id> projectIds = new Set<Id>();
                Set<Id> assignmentIds = new Set<Id>();
                Map<Id, Support_Request__c> qualifiedSupportRequestsMap = new Map<Id, Support_Request__c>();
                for(Support_Request__c sr : updatedSRs){
                    if(sr.BSI_Project__c != null && sr.BSI_Project__c != outdatedSRs.get(sr.Id).BSI_Project__c) {
                        qualifiedSupportRequestsMap.put(sr.Id, sr);
                        supportRequestIds.add(sr.Id);
                        if(sr.BSI_Project__c != null){
                            projectIds.add(sr.BSI_Project__c);
                        }
                        if(sr.Assignment__c != null){
                            assignmentIds.add(sr.Assignment__c);
                        }
                    }
                }

                // GET RELATED PROJECTS
                Map<Id, PS_Project__c> projectsMap = new Map<Id, PS_Project__c>([SELECT Id, Name,
                                                                                    (SELECT Id, Name FROM Milestones__r ORDER BY CreatedDate DESC) 
                                                                                FROM PS_Project__c WHERE Id IN :projectIds]);

                // GET TIME CARD ENTRIES
                List<Time_Card_Entry__c> timeCardEntries = [SELECT Id, Name, MilestoneId__c, ProjectId__c, Support_RequestId__c
                                                            FROM Time_Card_Entry__c WHERE Support_RequestId__c IN :supportRequestIds];

                // PROCESS TIME CARD ENTRIES
                List<Time_Card_Entry__c> timeCardEntriesToUpdate = new List<Time_Card_Entry__c>();
                for(Time_Card_Entry__c timeCardEntry : timeCardEntries){
                    if(timeCardEntry.Support_RequestId__c == null || !qualifiedSupportRequestsMap.containsKey(timeCardEntry.Support_RequestId__c) || 
                        qualifiedSupportRequestsMap.get(timeCardEntry.Support_RequestId__c).BSI_Project__c == null){
                        continue;
                    }

                    PS_Project__c project;
                    if(!projectsMap.containsKey(qualifiedSupportRequestsMap.get(timeCardEntry.Support_RequestId__c).BSI_Project__c) || 
                        projectsMap.get(qualifiedSupportRequestsMap.get(timeCardEntry.Support_RequestId__c).BSI_Project__c).Milestones__r.isEmpty()){
                        continue;
                    }
                    else{
                        project = projectsMap.get(qualifiedSupportRequestsMap.get(timeCardEntry.Support_RequestId__c).BSI_Project__c);
                    }
                    
                    Milestone__c milestone = project.Milestones__r[0]; // since the query ordered by most recent, the first one will be the one to use
                    if(timeCardEntry.ProjectId__c != project.Id || timeCardEntry.MilestoneId__c != milestone.Id){
                        timeCardEntry.ProjectId__c = project.Id;
                        timeCardEntry.MilestoneId__c = milestone.Id;
                        timeCardEntriesToUpdate.add(timeCardEntry);
                    }
                }

                // GET RELATED ASSIGNMENTS
                Map<Id, Assignment__c> assignmentsMap = new Map<Id, Assignment__c>([SELECT Id, Name, ProjectId__c, MilestoneId__c FROM Assignment__c WHERE Id IN :assignmentIds]);
                
                // PROCESS ASSIGNMENTS
                List<Assignment__c> assignmentsToUpdate = new List<Assignment__c>();
                for(Support_Request__c supportRequest : qualifiedSupportRequestsMap.values()){
                    Assignment__c assignment;
                    if(supportRequest.Assignment__c == null || !assignmentsMap.containsKey(supportRequest.Assignment__c)){
                        continue;
                    }
                    else{
                        assignment = assignmentsMap.get(supportRequest.Assignment__c);
                    }

                    PS_Project__c project;
                    if(!projectsMap.containsKey(supportRequest.BSI_Project__c) || projectsMap.get(supportRequest.BSI_Project__c).Milestones__r.isEmpty()){
                        continue;
                    }
                    else{
                        project = projectsMap.get(supportRequest.BSI_Project__c);
                    }

                    Milestone__c milestone = project.Milestones__r[0]; // since the query ordered by most recent, the first one will be the one to use
                    if(assignment.ProjectId__c != project.Id || assignment.MilestoneId__c != milestone.Id) {
                        assignment.ProjectId__c = project.Id;
                        assignment.MilestoneId__c = milestone.Id;
                        assignmentsToUpdate.add(assignment);
                    }
                }

                // UPDATE RECORDS
                Savepoint sp = Database.setSavePoint();
                try {
                    if(!timeCardEntriesToUpdate.isEmpty()){
                        update timeCardEntriesToUpdate;
                    }
                    if(!assignmentsToUpdate.isEmpty()){
                        update assignmentsToUpdate;
                    }
                } 
                catch(Exception ex) {
                    Database.rollback(sp);
                    SystemIssueLogHelper.LogException('SupportRequestHelper', 'syncTimeCardEntries', qualifiedSupportRequestsMap.values(), ex, true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SupportRequestHelper', 'syncTimeCardEntries');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SupportRequestHelper', 'syncTimeCardEntries', updatedSRs, ex, true);
        }
    }


}