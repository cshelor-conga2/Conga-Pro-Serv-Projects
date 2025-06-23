/** 
* @author ECS, ERedding
* @date 20200331
* @version 1.00
* @description BatchableSch_ContractBurdenedMRR - Batchable/Schedulable class for calculating Burdened MRR on Contracts
*/
public class BatchableSch_ContractBurdenedMRR implements Database.Batchable<sObject>, Schedulable{
    private Set<Id> AccountIds {get; set;}

    /** 
    * @description BatchableSch_ContractBurdenedMRR - Constructor WITH parameters
    * @param Set<Id> contractIds - Ids of Contracts to process
    */
    public BatchableSch_ContractBurdenedMRR(Set<Id> accountIds){
        this.AccountIds = accountIds;
    }

      /** 
    * @description BatchableSch_ContractBurdenedMRR - Constructor WITHOUT parameters
    */
    public BatchableSch_ContractBurdenedMRR(){
        this.AccountIds = new Set<Id>();
    }  
	/** 
	* @description Scheduable execute method
	*/
   	public void execute(SchedulableContext context) {
   		if(Test.isRunningTest()){
   			Database.executeBatch(this, 4);
   		}
   		else{
   			Database.executeBatch(this, 1);
   		}	
	}
	
	/** 
	* @description Batchable start method
	*/	
	public Database.QueryLocator start(Database.BatchableContext context) {
        if(AccountIds.isEmpty()){
        	// GET ACCOUNTS IDS FROM CONTRACTS WITH SUBSCRIPTIONS THAT WERE RECENTLY CREATED, MODIFIED, STARTED, OR ENDED
        	for(SBQQ__Subscription__c sub : [SELECT SBQQ__Contract__r.AccountId FROM SBQQ__Subscription__c 
        									 WHERE SBQQ__Contract__r.Contract_Type__c = 'Customer Subscription'
        									 AND (CreatedDate = LAST_N_DAYS:2 OR LastModifiedDate = LAST_N_DAYS:2
        							 		 OR SBQQ__StartDate__c = LAST_N_DAYS:2 OR SBQQ__EndDate__c = LAST_N_DAYS:2)]){
        		AccountIds.add(sub.SBQQ__Contract__r.AccountId);
        	}

        	// SEARCH FOR ACCOUNTS TO PROCESS
        	for(Contract contract : [SELECT Id, AccountId FROM Contract WHERE Contract_Type__c = 'Customer Subscription' AND (StartDate = LAST_N_DAYS:2 OR EndDate = LAST_N_DAYS:2)]){
        		AccountIds.add(contract.AccountId);
        	}
        }

        return Database.getQueryLocator([SELECT Id, Burdened_MRR__c FROM Account WHERE Id IN :AccountIds]);
	}
	
	/** 
	* @description Batchable execute method
	*/
   	public void execute(Database.BatchableContext context, List<Account> scope) {
		try{
			if(!scope.isEmpty()){

				// GET CONTRACTS OF ACCOUNTS IN SCOPE
				List<Contract> contracts = [SELECT Id, AccountId, Burdened_MRR__c, StartDate, EndDate FROM Contract WHERE AccountId IN :scope AND Contract_Type__c = 'Customer Subscription'];

				// GET LATEST MONTH OF MRR FOR EACH CONTRACT FROM MRR CALCULATION RECORDS RELATED TO SUBSCRIPTIONS
                Map<Id, Date> latestMonthDateByContract = new Map<Id, Date>();
                Date startingDate = null;
                for(AggregateResult agg : [SELECT SubscriptionId__r.SBQQ__Contract__c, MAX(Date__c) latestMonth FROM MRR_Calculation__c 
                						   WHERE SubscriptionId__r.SBQQ__Contract__c IN :contracts
                						   AND SubscriptionId__r.SBQQ__Contract__r.EndDate > TODAY
                						   GROUP BY SubscriptionId__r.SBQQ__Contract__c]){
                    Integer year = ((Date)agg.get('latestMonth')).year();
                    Integer month = ((Date)agg.get('latestMonth')).month();
                    Date latestMonthDate = Date.newInstance(year, month, 1);

                    latestMonthDateByContract.put((Id)agg.get('SBQQ__Contract__c'), latestMonthDate);
                    if(startingDate == null || latestMonthDate < startingDate){
                        startingDate = latestMonthDate;
                    }
                }

                // CREATE BURDENED MRR BY ACCOUNT MAP - SET A ZERO DEFAULT
                Map<Id, Integer> burdenedMRRByContract = new Map<Id, Integer>();
                for(Contract cont : contracts){
                	burdenedMRRByContract.put(cont.Id, 0);
                }

                // CALCULATE BURDENED MRR FOR EACH CONTRACT
                for(AggregateResult agg : [SELECT SubscriptionId__r.SBQQ__Contract__c, Month__c, Year__c, SUM(MRR__c) burdenedMRR FROM MRR_Calculation__c 
                                           WHERE SubscriptionId__r.SBQQ__Contract__c IN :latestMonthDateByContract.keySet()
                                           AND Date__c >= :startingDate
                                           GROUP BY SubscriptionId__r.SBQQ__Contract__c, Month__c, Year__c]){

                    Id contractId = (Id)agg.get('SBQQ__Contract__c');
                    Integer aggYear = Integer.valueOf(agg.get('Year__c'));
                    Integer aggMonth = Integer.valueOf(agg.get('Month__c'));
                    Integer burdenedMRR = Integer.valueOf(agg.get('burdenedMRR'));

                    if(latestMonthDateByContract.containsKey(contractId) && latestMonthDateByContract.get(contractId).year() == aggYear && 
                       latestMonthDateByContract.get(contractId).month() == aggMonth){
                        // ADD CALCULATION TO MAP
                        burdenedMRRByContract.put(contractId, burdenedMRR);
                    }
                }

                // CREATE BURDENED MRR BY ACCOUNT MAP - SET A ZERO DEFAULT
                Map<Id, Integer> burdenedMRRByAccount = new Map<Id, Integer>();
                for(Account acct : scope){
                	burdenedMRRByAccount.put(acct.Id, 0);
                }

				// SET BURDENED MRR ON CONTRACTS AND CALCULATE ACCOUNT BURDENED MRR
				List<Contract> contractsToUpdate = new List<Contract>();
				for(Contract contract : contracts){
					if(burdenedMRRByContract.containsKey(contract.Id) && burdenedMRRByContract.get(contract.Id) != null){

	                    Integer calculatedBurdenedMRR = burdenedMRRByContract.get(contract.Id);
	                    if(Integer.valueOf(contract.Burdened_MRR__c) != calculatedBurdenedMRR){
	                        contract.Burdened_MRR__c = calculatedBurdenedMRR;
	                        contractsToUpdate.add(contract);
	                    }

	                    // ADD CONTRACT BURDENED MRR TO ACCOUNT BURDENED MRR IF CONTRACT IS ACTIVE TODAY
	                    if(contract.StartDate <= Date.today() && contract.EndDate >= Date.today()){
		                    burdenedMRRByAccount.put(contract.AccountId, (burdenedMRRByAccount.get(contract.AccountId) + calculatedBurdenedMRR));
		                }
	                }
				}

				// SET BURDENED MRR ON ACCOUNTS
				List<Account> accountsToUpdate = new List<Account>();
				for(Account account : scope){
					if(burdenedMRRByAccount.containsKey(account.Id) && burdenedMRRByAccount.get(account.Id) != account.Burdened_MRR__c){
						accountsToUpdate.add(new Account(Id = account.Id, Burdened_MRR__c = burdenedMRRByAccount.get(account.Id)));
					}
				}

				// UPDATE CONTRACTS
				if(!contractsToUpdate.isEmpty()){
					Database.saveResult[] contractResults = Database.update(contractsToUpdate, false);
                	SystemIssueLogHelper.CheckForDatabaseErrors(contractResults, 'BatchableSch_ContractBurdenedMRR', 'execute', true);
				}

				// UPDATE ACCOUNTS
				if(!accountsToUpdate.isEmpty()){
					Database.saveResult[] accountResults = Database.update(accountsToUpdate, false);
                	SystemIssueLogHelper.CheckForDatabaseErrors(accountResults, 'BatchableSch_ContractBurdenedMRR', 'execute', true);
				}				

				// COMMIT ANY ERRORS
				SystemIssueLogHelper.UpsertExceptions();
			}
		}
		catch(Exception ex){ 
			SystemIssueLogHelper.LogException('BatchableSch_ContractBurdenedMRR', 'execute', scope, ex, true);
		}
	}
	
	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		// NO FINISH LOGIC
	}


}