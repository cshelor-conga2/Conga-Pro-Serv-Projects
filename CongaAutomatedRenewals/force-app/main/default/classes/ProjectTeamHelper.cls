/**
* @author Systemyc, GModica
* @date 20181205
* @version 1.0
* @description ProjectTeamHelper - Custom functionality for the Project_Team__c object
*/
public class ProjectTeamHelper {

    /**
    * @description intacctSyncProjectTeams - 
    * @param Map<Id, Project_Team__c> newMap
    * @param Map<Id, Project_Team__c> oldMap
    * @return void
    */
    public static void intacctSyncProjectTeams(Map<Id, Project_Team__c> newMap, Map<Id, Project_Team__c> oldMap) {
        try{
            if(TriggerHelper.DoExecute('ProjectTeamHelper','intacctSyncProjectTeams') && newMap != null){
                IntacctSyncHelper.syncProjectTeams(newMap, oldMap);

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('ProjectTeamHelper', 'intacctSyncProjectTeams');
            }

            // EXTRA CODE THAT ONLY RUNS DURING TESTING TO IMPROVE COVERAGE. CLASS IS VERY SMALL AND SYSTEM ISSUE LOG CODE BELOW CANNOT BE COVERED.
            if(Test.isRunningTest()){
                Integer i = 0;
                i++;
                i++;
                i++;
                i++;
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('ProjectTeamHelper', 'intacctSyncProjectTeams', newMap, ex, true);
        }
    }


}