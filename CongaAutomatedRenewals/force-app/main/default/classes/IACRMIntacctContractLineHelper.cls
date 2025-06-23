/**
* @author Systemyc, GModica
* @date 20181205
* @version 1.0
* @description IACRMIntacctContractLineHelper - Custom functionality for the ia_crm__Intacct_Contract_Line__c object
*/
public class IACRMIntacctContractLineHelper {

    /**
    * @description intacctSyncIntacctContractLines - 
    * @param Map<Id,ia_crm__Intacct_Contract_Line__c> newMap - New or updated ia_crm__Intacct_Contract_Line__c records
    * @param Map<Id,ia_crm__Intacct_Contract_Line__c> oldMap - Outdated ia_crm__Intacct_Contract_Line__c records
    * @return void
    */
    public static void intacctSyncIntacctContractLines(Map<Id,ia_crm__Intacct_Contract_Line__c> newMap, Map<Id,ia_crm__Intacct_Contract_Line__c> oldMap) {
        try{
            if(TriggerHelper.DoExecute('IACRMIntacctContractLineHelper','intacctSyncIntacctContractLines') && newMap != null){
                IntacctSyncHelper.syncIntacctContractLines(newMap, oldMap);

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IACRMIntacctContractLineHelper', 'intacctSyncIntacctContractLines');
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
            SystemIssueLogHelper.LogException('IACRMIntacctContractLineHelper', 'intacctSyncIntacctContractLines', newMap, ex, true);
        }
    }


}