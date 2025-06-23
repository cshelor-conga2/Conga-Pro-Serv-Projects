/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180512
* @version 1.0
* @description IntacctSyncHelper - 
*/
public class IntacctSyncHelper {
    @TestVisible
    private static Boolean syncingIntacctProjects = false;

    // this must be set to true from test classes. This is to avoid running these triggers on tests performed by other modules
    @TestVisible
    private static Boolean runOnTest = false;

    @TestVisible
    private static Boolean errorOnTest = true;

    /**
    * @description syncProjects - 
    * @param Map<Id, PS_Project__c> newMap
    * @param Map<Id, PS_Project__c> oldMap
    * @return void
    */
    public static void syncProjects(Map<Id, PS_Project__c> newMap, Map<Id, PS_Project__c> oldMap) {
        if(Test.isRunningTest() && newMap.isEmpty() && errorOnTest) throw new IntacctException('Test Error');

        if(UserInfo.getUserId() == getIntacctIntegrationUserId()) return;

        if(Test.isRunningTest() && !runOnTest) return;

        Set<Id> projectIds = new Set<Id>();
        for(Id projectId : newMap.keySet()) {
            PS_Project__c newProject = newMap.get(projectId);
            PS_Project__c oldProject = oldMap != null ? oldMap.get(projectId) : null;

            if(!newProject.Intacct_Sync__c) continue;

            if(oldProject == null) { // this is an insert
                projectIds.add(projectId);
            }
            else {
                //System.debug('changing Project from '  + oldProject.Intacct_Sync_Status__c + ' to ' + newProject.Intacct_Sync_Status__c);
                if((oldProject.Intacct_Sync_Status__c == 'In Process' && oldProject.Intacct_Sync_Status__c != newProject.Intacct_Sync_Status__c) || 
                   (newProject.Intacct_Sync_Status__c == 'In Process' && oldProject.Intacct_Sync_Status__c != null)) {
                    //System.debug('skipping');
                    // There's a status change from a running state, so ignore the update
                    continue;
                }
                //System.debug('syncing');
                projectIds.add(projectId);
            }
        }

        //System.debug('Syncing projects: ' + projectIds);
        IntacctIntegrationService.syncProjects(projectIds);
    }

    /**
    * @description syncProjectTeams - 
    * @param Map<Id, Project_Team__c> newMap
    * @param Map<Id, Project_Team__c> oldMap
    * @return void
    */
    public static void syncProjectTeams(Map<Id, Project_Team__c> newMap, Map<Id, Project_Team__c> oldMap) {
        if(Test.isRunningTest() && newMap.isEmpty() && errorOnTest) throw new IntacctException('Test Error');
        if(UserInfo.getUserId() == getIntacctIntegrationUserId()) return;
        if(Test.isRunningTest() && !runOnTest) return;

        Set<Id> projectIds = new Set<Id>();
        for(Id projectTeamId : newMap.keySet()) {
            Project_Team__c newProjectTeam = newMap.get(projectTeamId);
            Project_Team__c oldProjectTeam = oldMap != null ? oldMap.get(projectTeamId) : null;

            if(newProjectTeam.Project__c == null) continue;

            if((oldProjectTeam == null && (newProjectTeam.Role__c == 'Project Owner' || newProjectTeam.Role__c == 'Billing Contact')) ||
               (oldProjectTeam != null && (newProjectTeam.Role__c == 'Project Owner' || newProjectTeam.Role__c == 'Billing Contact') && newProjectTeam.Role__c != oldProjectTeam.Role__c)) {
                projectIds.add(newProjectTeam.Project__c);
            }
        }

        if(!projectIds.isEmpty()) {
            //System.debug('Syncing projects: ' + projectIds);
            IntacctIntegrationService.syncProjects(projectIds);
        }
    }

    /**
    * @description syncMilestones - 
    * @param Map<Id, Milestone__c> newMap
    * @param Map<Id, Milestone__c> oldMap
    * @return void
    */
    public static void syncMilestones(Map<Id, Milestone__c> newMap, Map<Id, Milestone__c> oldMap) {
        if(Test.isRunningTest() && newMap.isEmpty() && errorOnTest) throw new IntacctException('Test Error');
        if(UserInfo.getUserId() == getIntacctIntegrationUserId()) return;
        if(Test.isRunningTest() && !runOnTest) return;

        Set<Id> milestoneIds = new Set<Id>();
        for(Id milestoneId : newMap.keySet()) {
            Milestone__c newMilestone = newMap.get(milestoneId);
            Milestone__c oldMilestone = oldMap != null ? oldMap.get(milestoneId) : null;

            if(!newMilestone.Intacct_Sync__c) continue;

            if(oldMilestone == null) { // this is an insert
                milestoneIds.add(milestoneId);
            }
            else {
                //System.debug('changing Milestone from '  + oldMilestone.Intacct_Sync_Status__c + ' to ' + newMilestone.Intacct_Sync_Status__c);
                if((oldMilestone.Intacct_Sync_Status__c == 'In Process' && oldMilestone.Intacct_Sync_Status__c != newMilestone.Intacct_Sync_Status__c) || 
                   (newMilestone.Intacct_Sync_Status__c == 'In Process' && oldMilestone.Intacct_Sync_Status__c != null)) {
                    //System.debug('skipping');
                    // There's a status change from a running state, so ignore the update
                    continue;
                }
                //System.debug('syncing');
                milestoneIds.add(milestoneId);
            }
        }

        //System.debug('Syncing milestones: ' + milestoneIds);

        IntacctIntegrationService.syncMilestones(milestoneIds);
    }

    /**
    * @description syncTimeCardEntries - 
    * @param Map<Id, Time_Card_Entry__c> newMap
    * @param Map<Id, Time_Card_Entry__c> oldMap
    * @return void
    */
    public static void syncTimeCardEntries(Map<Id, Time_Card_Entry__c> newMap, Map<Id, Time_Card_Entry__c> oldMap) {
        if(Test.isRunningTest() && newMap.isEmpty() && errorOnTest) throw new IntacctException('Test Error');
        if(UserInfo.getUserId() == getIntacctIntegrationUserId()) return;
        if(Test.isRunningTest() && !runOnTest) return;

        Set<Id> timeCardEntryIds = new Set<Id>();
        for(Id timeCardEntryId : newMap.keySet()) {
            Time_Card_Entry__c newTimeCardEntry = newMap.get(timeCardEntryId);
            Time_Card_Entry__c oldTimeCardEntry = oldMap != null ? oldMap.get(timeCardEntryId) : null;

            if(!newTimeCardEntry.Intacct_Sync__c) continue;

            if(oldTimeCardEntry == null) { // this is an insert
                timeCardEntryIds.add(timeCardEntryId);
            }
            else {
                //System.debug('changing Time Card Entry from '  + oldTimeCardEntry.Intacct_Sync_Status__c + ' to ' + newTimeCardEntry.Intacct_Sync_Status__c);
                if((oldTimeCardEntry.Intacct_Sync_Status__c == 'In Process' && oldTimeCardEntry.Intacct_Sync_Status__c != newTimeCardEntry.Intacct_Sync_Status__c) || 
                   (newTimeCardEntry.Intacct_Sync_Status__c == 'In Process' && oldTimeCardEntry.Intacct_Sync_Status__c != null)) {
                    //System.debug('skipping');
                    // There's a status change from a running state, so ignore the update
                    continue;
                }
                //System.debug('syncing');
                timeCardEntryIds.add(timeCardEntryId);
            }
        }

        //System.debug('Syncing timeCardEntries: ' + timeCardEntryIds);

        IntacctIntegrationService.syncTimeCardEntries(timeCardEntryIds);
    }

    /**
    * @description syncTimeCardHeaders - 
    * @param Map<Id, Time_Card_Header__c> newMap
    * @param Map<Id, Time_Card_Header__c> oldMap
    * @return void
    */
    public static void syncTimeCardHeaders(Map<Id, Time_Card_Header__c> newMap, Map<Id, Time_Card_Header__c> oldMap) {
        if(Test.isRunningTest() && newMap.isEmpty() && errorOnTest) throw new IntacctException('Test Error');
        if(UserInfo.getUserId() == getIntacctIntegrationUserId()) return;
        if(Test.isRunningTest() && !runOnTest) return;

        Set<Id> timeCardHeaderIds = new Set<Id>();
        for(Id timeCardHeaderId : newMap.keySet()) {
            Time_Card_Header__c newTimeCardHeader = newMap.get(timeCardHeaderId);
            Time_Card_Header__c oldTimeCardHeader = oldMap != null ? oldMap.get(timeCardHeaderId) : null;

            if(!newTimeCardHeader.Intacct_Sync__c) continue;

            if(oldTimeCardHeader == null) { // this is an insert
                timeCardHeaderIds.add(timeCardHeaderId);
            }
            else {
                //System.debug('changing Time Card Header from '  + oldTimeCardHeader.Intacct_Sync_Status__c + ' to ' + newTimeCardHeader.Intacct_Sync_Status__c);
                if((oldTimeCardHeader.Intacct_Sync_Status__c == 'In Process' && oldTimeCardHeader.Intacct_Sync_Status__c != newTimeCardHeader.Intacct_Sync_Status__c) || 
                   (newTimeCardHeader.Intacct_Sync_Status__c == 'In Process' && oldTimeCardHeader.Intacct_Sync_Status__c != null)) {
                    //System.debug('skipping');
                    // There's a status change from a running state, so ignore the update
                    continue;
                }
                //System.debug('syncing');
                timeCardHeaderIds.add(timeCardHeaderId);
            }
        }

        //System.debug('Syncing timeCardHeaders: ' + timeCardHeaderIds);

        IntacctIntegrationService.syncTimeCardHeaders(timeCardHeaderIds);
    }

    /**
    * @description syncIntacctContractLines - 
    * @param Map<Id, ia_crm__Intacct_Contract_Line__c> newMap
    * @param Map<Id, ia_crm__Intacct_Contract_Line__c> oldMap
    * @return void
    */
    public static void syncIntacctContractLines(Map<Id, ia_crm__Intacct_Contract_Line__c> newMap, Map<Id, ia_crm__Intacct_Contract_Line__c> oldMap) {
        if(Test.isRunningTest() && newMap.isEmpty() && errorOnTest) throw new IntacctException('Test Error');
        if(UserInfo.getUserId() == getIntacctIntegrationUserId()) return;
        if(Test.isRunningTest() && !runOnTest) return;

        Set<Id> contractLineIds = new Set<Id>();

        for(Id contractLineId : newMap.keySet()) {
            ia_crm__Intacct_Contract_Line__c newContractLine = newMap.get(contractLineId);
            ia_crm__Intacct_Contract_Line__c oldContractLine = oldMap != null ? oldMap.get(contractLineId) : null;

            if(newContractLine.ProjectId__c != null && newContractLine.MilestoneId__c != null) {
                //System.debug('skipping');
                // There's a status change from a running state, so ignore the update
                continue;
            }

            if(oldContractLine == null) { // this is an insert
                contractLineIds.add(contractLineId);
            }
            else {
                //System.debug('changing Contract Line from '  + oldContractLine.Intacct_Sync_Status__c + ' to ' + newContractLine.Intacct_Sync_Status__c);
                if((oldContractLine.Intacct_Sync_Status__c == 'In Process' && oldContractLine.Intacct_Sync_Status__c != newContractLine.Intacct_Sync_Status__c) || 
                   (newContractLine.Intacct_Sync_Status__c == 'In Process' && oldContractLine.Intacct_Sync_Status__c != null)) {
                    //System.debug('skipping');
                    // There's a status change from a running state, so ignore the update
                    continue;
                }
                //System.debug('syncing');
                contractLineIds.add(contractLineId);
            }
        }

        //System.debug('Syncing contractLines: ' + contractLineIds);

        IntacctIntegrationService.syncIntacctContractLines(contractLineIds);
    }

    /**
    * @description syncIntacctProjects - 
    * @param Map<Id, ia_crm__Project__c> newMap
    * @param Map<Id, ia_crm__Project__c> oldMap
    * @return void
    */
    public static void syncIntacctProjects(Map<Id, ia_crm__Project__c> newMap, Map<Id, ia_crm__Project__c> oldMap) {
        if(Test.isRunningTest() && newMap.isEmpty() && errorOnTest) throw new IntacctException('Test Error');
        //if(UserInfo.getUserId() == getIntacctIntegrationUserId()) return;
        if(Test.isRunningTest() && !runOnTest) return;

        if(syncingIntacctProjects) return;
        syncingIntacctProjects = true;

        Set<Id> projectIds = new Set<Id>();

        for(Id projectId : newMap.keySet()) {
            ia_crm__Project__c newProject = newMap.get(projectId);
            ia_crm__Project__c oldProject = oldMap != null ? oldMap.get(projectId) : null;

            if(oldProject == null) { // this is an insert
                projectIds.add(projectId);
            }
            else {
                projectIds.add(projectId);
            }
        }

        //System.debug('Syncing Intacct projects: ' + projectIds);

        IntacctIntegrationService.syncIntacctProjects(projectIds);
    }

    /**
    * @description syncIntacctTasks - 
    * @param Map<Id, ia_crm__Task__c> newMap
    * @param Map<Id, ia_crm__Task__c> oldMap
    * @return void
    */
    public static void syncIntacctTasks(Map<Id, ia_crm__Task__c> newMap, Map<Id, ia_crm__Task__c> oldMap) {
        if(Test.isRunningTest() && newMap.isEmpty() && errorOnTest) throw new IntacctException('Test Error');
        //if(UserInfo.getUserId() == getIntacctIntegrationUserId()) return;
        if(Test.isRunningTest() && !runOnTest) return;

        if(syncingIntacctProjects) return;
        syncingIntacctProjects = true;

        Set<Id> projectIds = new Set<Id>();
        for(Id taskId : newMap.keySet()) {
            ia_crm__Task__c newTask = newMap.get(taskId);
            ia_crm__Task__c oldTask = oldMap != null ? oldMap.get(taskId) : null;

            if(newTask.ia_crm__Project__c == null) continue;

            if(oldTask == null) { // this is an insert
                projectIds.add(newTask.ia_crm__Project__c);
            }
            else {
                projectIds.add(newTask.ia_crm__Project__c);
            }
        }

        //System.debug('Syncing Intacct projects: ' + projectIds);
        IntacctIntegrationService.syncIntacctProjects(projectIds);
    }



    private static Id intacctIntegrationUserId;
    /**
    * @description getIntacctIntegrationUserId - 
    * @return Id
    */
    private static Id getIntacctIntegrationUserId() {
        if(intacctIntegrationUserId == null){
            List<ia_crm__Intacct_Configuration__c> intacctConfig = [SELECT Id, ia_crm__Run_Scheduled_Jobs_With__c FROM ia_crm__Intacct_Configuration__c];
            if(!intacctConfig.isEmpty()){
                intacctIntegrationUserId = intacctConfig[0].ia_crm__Run_Scheduled_Jobs_With__c;
            }
        }
        return intacctIntegrationUserId;
    }


}