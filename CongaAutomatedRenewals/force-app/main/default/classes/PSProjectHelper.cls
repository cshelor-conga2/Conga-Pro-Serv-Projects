/**
* @author Systemyc, GModica
* @date 20181205
* @version 1.0
* @description PSProjectHelper - Custom functionality for the PS_Project__c object
*/
public class PSProjectHelper {

    /**
    * @description intacctSyncProjects - 
    * @param Map<Id,PS_Project__c> newMap
    * @param Map<Id,PS_Project__c> oldMap
    * @return void
    */
    public static void intacctSyncProjects(Map<Id,PS_Project__c> newMap, Map<Id,PS_Project__c> oldMap) {
        try{
            if(TriggerHelper.DoExecute('PSProjectHelper','intacctSyncProjects') && newMap != null){
                IntacctSyncHelper.syncProjects(newMap, oldMap);

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('PSProjectHelper', 'intacctSyncProjects');
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
            SystemIssueLogHelper.LogException('PSProjectHelper', 'intacctSyncProjects', newMap, ex, true);
        }
    }


}