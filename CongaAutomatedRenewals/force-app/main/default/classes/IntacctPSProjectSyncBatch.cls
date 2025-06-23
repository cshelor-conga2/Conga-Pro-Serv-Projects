/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IntacctPSProjectSyncBatch - 
*/
global class IntacctPSProjectSyncBatch implements Database.Batchable<sObject> {
    private String query = 'SELECT Id FROM PS_Project__c WHERE RecordType.DeveloperName = \'PS_Project\' AND Is_Active__c = true AND OpportunityId__c != null AND Billing_Type__c IN (\'Time and Materials\') AND Name NOT IN (\'Customer Success\',\'Internal\') AND Intacct_Id__c = null AND Owner.Type = \'User\'';

    /**
    * @description IntacctMilestoneSyncBatch - Constructor
    */
    global IntacctPSProjectSyncBatch() {
        if(Test.isRunningTest()) query = 'SELECT Id FROM PS_Project__c';
    }
    
    /**
    * @description IntacctMilestoneSyncBatch - Constructor
    * @param String someQuery
    */
    global IntacctPSProjectSyncBatch(String someQuery) {
        if(String.isNotBlank(someQuery)) this.query = someQuery;
    }

    /**
    * @description start - 
    * @param Database.BatchableContext bc
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    /**
    * @description execute - 
    * @param Database.BatchableContext bc
    * @param List<sObject> scope
    */
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<PS_Project__c> projects = (List<PS_Project__c>)scope;
        Set<Id> projectIds = new Map<Id,PS_Project__c>(projects).keySet();
        IntacctIntegrationService.syncProjects(projectIds);
    }

    /**
    * @description finish - 
    * @param Database.BatchableContext bc
    */
    global void finish(Database.BatchableContext bc) {

    }


}