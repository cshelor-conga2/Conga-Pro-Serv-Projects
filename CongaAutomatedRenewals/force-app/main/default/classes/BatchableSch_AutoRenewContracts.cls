/**
* @author Conga Services, DNelson, ERedding
* @date 20180911
* @version 1.00
* @description BatchableSch_AutoRenewContracts - Flags Contracts for renewal when end date is within 110 days
*/

public class BatchableSch_AutoRenewContracts implements Database.Batchable<sObject>, Schedulable, Database.Stateful  {
    public Date autoRenewalDate;
    public Date priorDay;

    /**
    * @description start - Batchable Class start method
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // GET CONTRACT RECORDS FOR AUTO RENEW, 110 DAYS BEFORE END DATE
        autoRenewalDate = Date.today().addDays(110);
        priorDay = Date.today().addDays(-1);
        Id CustomerSubscriptionRTId = UtilityClass.getRecordTypesForObject('Contract').get('Customer_Subscription');

        return Database.getQueryLocator([SELECT Id, SBQQ__Opportunity__r.Sub_Type__c, SBQQ__RenewalOpportunity__c, SBQQ__RenewalQuoted__c, Status, RecordTypeId, EndDate
                                         FROM Contract 
                                         WHERE RecordTypeId = :CustomerSubscriptionRTId AND (EndDate = :autoRenewalDate OR EndDate = :priorDay)]);
    }

    /**
    * @description execute - Batchable Class execute method
    */
    public void execute(Database.BatchableContext bc, List<Contract> scope) {

        //CONTRACTS 110 DAYS FROM RENEWAL
        List<Contract> updateContracts = new List<Contract>();
        for(Contract cont : scope) {
            if(cont.SBQQ__Opportunity__r.Sub_Type__c != 'Forecasting Opportunity'){
                if(cont.SBQQ__RenewalQuoted__c != true && cont.EndDate == autoRenewalDate) {
                    //UPDATE QUALIFIED CONTRACTS
                    cont.SBQQ__RenewalQuoted__c = true;
                    updateContracts.add(cont);  
                }
                else if(cont.Status != 'Expired' && cont.EndDate == priorDay){
                    //UPDATE QUALIFIED CONTRACTS
                    cont.Status = 'Expired';
                    updateContracts.add(cont);  
                } 
            }
        } 
        
        //SAVE UPDATED CONTRACTS
        Database.SaveResult[] contractResults = Database.update(updateContracts, false);
        SystemIssueLogHelper.CheckForDatabaseErrors(contractResults, 'BatchableSch_AutoRenewContracts', 'execute', true);
    }
    
    /**
    * @description finish - Batchable Class finish method
    */
    public void finish(Database.BatchableContext bc) {
        // NO FINISH LOGIC
    }

    /**
    * @description execute - Schedulable Class execute method
    */
    public void execute(SchedulableContext sc){
         Database.executeBatch(new BatchableSch_AutoRenewContracts(), 1);
    }


}