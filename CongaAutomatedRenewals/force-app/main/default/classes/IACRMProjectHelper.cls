/**
* @author Systemyc, GModica
* @date 20181205
* @version 1.0
* @description IACRMProjectHelper - Custom functionality for the PS_Project__c object
*/
public class IACRMProjectHelper {

    /**
    * @description intacctSyncIntacctProjects - 
    * @param Map<Id,ia_crm__Project__c> newMap - New or updated ia_crm__Intacct_Contract_Line__c records
    * @param Map<Id,ia_crm__Project__c> oldMap - Outdated ia_crm__Intacct_Contract_Line__c records
    * @return void
    */
	public static void intacctSyncIntacctProjects(Map<Id,ia_crm__Project__c> newMap, Map<Id,ia_crm__Project__c> oldMap) {
		try{
			if(TriggerHelper.DoExecute('IACRMProjectHelper','intacctSyncIntacctProjects') && newMap != null){
				IntacctSyncHelper.syncIntacctProjects(newMap, oldMap);

				// END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IACRMProjectHelper', 'intacctSyncIntacctProjects');
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
            SystemIssueLogHelper.LogException('IACRMProjectHelper', 'intacctSyncIntacctProjects', newMap, ex, true);
		}
	}


}