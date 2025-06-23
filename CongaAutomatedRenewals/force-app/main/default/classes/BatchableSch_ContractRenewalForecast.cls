/** 
* @author ECS, ERedding
* @date 20200107
* @version 1.00
* @description BatchableSch_ContractRenewalForecast - Batchable/Schedulable class for updating Contracts by flagging them for renewal AFTER other processing is complete
*/
public class BatchableSch_ContractRenewalForecast implements Database.Batchable<sObject>, Schedulable{
    private final Set<Id> ContractIds;

    /**
    * @description BatchableSch_ContractRenewalForecast - Constructor with Parameter
    */
    public BatchableSch_ContractRenewalForecast(Set<Id> pContractIds) {
        ContractIds = pContractIds;
    }

    /**
    * @description BatchableSch_ContractRenewalForecast - Constructor no  Parameters
    */
    public BatchableSch_ContractRenewalForecast() {
    }

    /** 
    * @description Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this, 1);
    }

    /**
    * @description Batchable start method
    */
    public Database.QueryLocator start(Database.BatchableContext context) {
        // GET CONTRACT CUSTOMER SUBSCRIPTION RECORD TYPE
        Id customerSubRTId = UtilityClass.getRecordTypesForObject('Contract').get('Customer_Subscription');

        if(ContractIds == null || ContractIds.isEmpty()){
            Datetime fifteenAgo = Datetime.now().addMinutes(-15); // GET DATE TIME VALUE THAT IS 15 MINUTES AGO
            return Database.getQueryLocator([SELECT Id FROM Contract WHERE CreatedDate >= :fifteenAgo AND RecordTypeId = :customerSubRTId AND SBQQ__RenewalForecast__c = false]);
        }
        else{
            return Database.getQueryLocator([SELECT Id FROM Contract WHERE Id IN :ContractIds AND RecordTypeId = :customerSubRTId AND SBQQ__RenewalForecast__c = false]);
        }
    }

    /**
    * @description execute - Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<Contract> scope){
        try{
            if(scope != null && !scope.isEmpty()){

                // UPDATE CONTRACTS
                for(Contract contract : scope){ 
                    contract.SBQQ__RenewalForecast__c = true;
                }

                Database.saveResult[] contractResults = Database.update(scope, false);
                SystemIssueLogHelper.CheckForDatabaseErrors(contractResults, 'BatchableSch_ContractRenewalForecast', 'execute', true);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_ContractRenewalForecast', 'execute', scope, ex, true);
        }
    }

    /**
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}