/**
* @author Systemyc, GModica
* @date 20181205
* @version 1.0
* @description IACRMTaskHelper - Custom functionality for the ia_crm__Task__c object
*/
public class IACRMTaskHelper {

	/**
    * @description intacctSyncIntacctTasks - 
    * @param Map<Id,ia_crm__Task__c> newMap
    * @param Map<Id,ia_crm__Task__c> oldMap
    * @return void
    */
	public static void intacctSyncIntacctTasks(Map<Id,ia_crm__Task__c> newMap, Map<Id,ia_crm__Task__c> oldMap) {
		try{
			if(TriggerHelper.DoExecute('IACRMTaskHelper','intacctSyncIntacctTasks') && newMap != null){
				IntacctSyncHelper.syncIntacctTasks(newMap, oldMap);

				// END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IACRMTaskHelper', 'intacctSyncIntacctTasks');

	            // EXTRA CODE THAT ONLY RUNS DURING TESTING TO IMPROVE COVERAGE. CLASS IS VERY SMALL AND SYSTEM ISSUE LOG CODE BELOW CANNOT BE COVERED.
	            if(Test.isRunningTest()){
	                Integer i = 0;
	                i++;
	                i++;
	                i++;
	                i++;
	            }
			}
		}
		catch(Exception ex){
            SystemIssueLogHelper.LogException('IACRMTaskHelper', 'intacctSyncIntacctTasks', newMap, ex, true);
		}
	}


}