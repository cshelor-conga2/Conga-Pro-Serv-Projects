/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IntacctMilestoneSyncBatch - 
*/
global class IntacctMilestoneSyncBatch implements Database.Batchable<sObject> {
    private String query = 'SELECT Id FROM Milestone__c WHERE ProjectId__c IN (SELECT Id FROM PS_Project__c WHERE RecordType.DeveloperName = \'PS_Project\' AND Is_Active__c = true AND OpportunityId__c != null AND Billing_Type__c IN (\'Time AND Materials\') AND Name NOT IN (\'Customer Success\',\'Internal\') AND Intacct_Id__c != null AND Owner.Type = \'User\') AND Intacct_Id__c = null';

    /**
    * @description IntacctMilestoneSyncBatch - Constructor
    */
    global IntacctMilestoneSyncBatch() {
        if(Test.isRunningTest()) query = 'SELECT Id FROM Milestone__c';
    }
    
    /**
    * @description IntacctMilestoneSyncBatch - Constructor
    * @param String someQuery
    */
    global IntacctMilestoneSyncBatch(String someQuery) {
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
        List<Milestone__c> milestones = (List<Milestone__c>)scope;
        Set<Id> milestoneIds = new Map<Id,Milestone__c>(milestones).keySet();
        IntacctIntegrationService.syncMilestones(milestoneIds);
    }

    /**
    * @description finish - 
    * @param Database.BatchableContext bc
    */
    global void finish(Database.BatchableContext bc) {

    }


}