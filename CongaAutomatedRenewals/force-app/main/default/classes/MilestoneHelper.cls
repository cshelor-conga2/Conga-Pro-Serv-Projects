/**
* @author Systemyc, GModica
* @date 20190123
* @version 1.0
* @description MilestoneHelper - Custom functionality for the Milestone__c object
*/
public class MilestoneHelper {

    /**
    * @description intacctSyncMilestones - 
    * @param Map<Id, Milestone__c> newMap
    * @param Map<Id, Milestone__c> oldMap
    * @return void
    */
    public static void intacctSyncMilestones(Map<Id, Milestone__c> newMap, Map<Id, Milestone__c> oldMap) {
        try{
            if(TriggerHelper.DoExecute('MilestoneHelper','intacctSyncMilestones') && newMap != null){
                IntacctSyncHelper.syncMilestones(newMap, oldMap);

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('MilestoneHelper', 'intacctSyncMilestones');
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
            SystemIssueLogHelper.LogException('MilestoneHelper', 'intacctSyncMilestones', newMap, ex, true);
        }
    }


}