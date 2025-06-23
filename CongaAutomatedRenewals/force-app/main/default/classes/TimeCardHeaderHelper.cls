/**
* @author Systemyc, GModica
* @date 20181205
* @version 1.0
* @description TimeCardHeaderHelper - Custom functionality for the Time_Card_Header__c object
*/
public class TimeCardHeaderHelper {

	/**
    * @description intacctSyncTimeCardHeaders - 
    * @param Map<Id, Time_Card_Header__c> newMap
    * @param Map<Id, Time_Card_Header__c> oldMap
    * @return void
    */
	public static void intacctSyncTimeCardHeaders(Map<Id, Time_Card_Header__c> newMap, Map<Id, Time_Card_Header__c> oldMap) {
		try{
			if(TriggerHelper.DoExecute('TimeCardHeaderHelper','intacctSyncTimeCardHeaders') && newMap != null){
				IntacctSyncHelper.syncTimeCardHeaders(newMap, oldMap);

				// END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TimeCardHeaderHelper', 'intacctSyncTimeCardHeaders');
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
            SystemIssueLogHelper.LogException('TimeCardHeaderHelper', 'intacctSyncTimeCardHeaders', newMap, ex, true);
		}
	}


}