/** 
* @author ECS, ERedding
* @date 20190905
* @version 1.00
* @description BatchableSch_AccountActiveMRR - Batchable/Schedulable class for calculating Active MRR on Accounts from related MRR Calculation records
*/
public class BatchableSch_AccountActiveMRR implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
	private Set<Id> UpdatedAccountIds;
	private String CurrentMRRQuery = 'SELECT Id, {0} FROM Account WHERE Id IN :scope';	
	private Map<String, String> ProductLineToFieldMap;

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
		UpdatedAccountIds = new Set<Id>();
        ProductLineToFieldMap = new Map<String, String>();

        // GET OPP AVERAGE MRR FIELD MAPPING
        for(Account_Active_MRR_Mapping__mdt meta : [SELECT FieldId__r.QualifiedAPIName, Product_Line__c FROM Account_Active_MRR_Mapping__mdt 
        											WHERE ObjectId__r.QualifiedAPIName = 'Account']){
            ProductLineToFieldMap.put(meta.Product_Line__c, meta.FieldId__r.QualifiedAPIName);
        }

        // GET SCOPE
        if(!ProductLineToFieldMap.isEmpty()){

	        // CREATE DYNAMIC SOQL QUERY TO GET CURRENT MRR VALUES
	        String mrrFields = '';
	        for(String mrrField : ProductLineToFieldMap.values()){
	        	mrrFields += mrrField + ',';
	        }
	        mrrFields = mrrFields.left(mrrFields.length()-1); // REMOVE TRAILING COMMA
	        CurrentMRRQuery = String.format(CurrentMRRQuery, new List<String>{ mrrFields }); // COMPLETE SOQL QUERY

        	return Database.getQueryLocator([SELECT Id FROM Account WHERE Id IN (SELECT AccountId__c FROM MRR_Calculation__c WHERE Date__c = THIS_MONTH)]);
        }
		return Database.getQueryLocator([SELECT Id FROM Account WHERE Id = null]);
	}

	/** 
	* @description Batchable execute method
	*/
   	public void execute(Database.BatchableContext context, List<Account> scope) {
		try{
			if(!scope.isEmpty()){
        		// USE DYNAMIC SOQL QUERY TO GET CURRENT MRR VALUES
		        Map<Id, Account> currentAccountMRRValues = new Map<Id, Account>((List<Account>)Database.query(CurrentMRRQuery));

				// LOOP OVER EACH AGGREGATE RESULT OF SUMMED MRR BY ACCOUNT AND PRODUCT LINE. MAP TO THE CORRECT FIELD AND QUEUE THE ACCOUNT FOR UPDATE IF AN UPDATE IS NEEDED
				Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
				for(AggregateResult agg : [SELECT AccountId__c, Product_Line__c, SUM(MRR__c) mrr FROM MRR_Calculation__c 
											WHERE AccountId__c IN :scope AND Date__c = THIS_MONTH
											AND Product_Line__c IN :productLineToFieldMap.keySet()
                                           	AND SubscriptionId__r.SBQQ__Product__r.Exclude_from_MRR__c = false 
											GROUP BY AccountId__c, Product_Line__c]){
                    
                    Id acctId = (Id)agg.get('AccountId__c');
                    String productLine = (String)agg.get('Product_Line__c');
                    Decimal mrr = (Decimal)agg.get('mrr');
                    Account currentMRR = currentAccountMRRValues.containsKey(acctId) ? currentAccountMRRValues.get(acctId) : null;

                    if(productLineToFieldMap.containsKey(productLine) && (currentMRR == null || currentMRR.get(productLineToFieldMap.get(productLine)) != mrr)){
                        if(!accountsToUpdate.containsKey(acctId)){
                            Account acct = new Account(Id = acctId);
                            accountsToUpdate.put(acctId, acct);
                        }
                        accountsToUpdate.get(acctId).put(productLineToFieldMap.get(productLine), mrr);
                    }
				}

                // UPDATE ACCOUNTS
                if(!accountsToUpdate.isEmpty()){
                    Database.saveResult[] acctResults = Database.update(accountsToUpdate.values(), false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(acctResults, 'BatchableSch_AccountActiveMRR', 'execute', true);

                    for(Database.saveResult result : acctResults){
                    	if(result.isSuccess()){
                    		UpdatedAccountIds.add(result.getId());
                    	}
                    }
                }
			}
		}
		catch(Exception ex){ 
			SystemIssueLogHelper.LogException('BatchableSch_AccountActiveMRR', 'execute', scope, ex, true);
		}
	}

	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {

		//////////// ECS EREDDING 20191105 - DEPRECATED, DIVISIONS NO LONGER DEPENDANT ON ACTIVE MRR /////////////////
		// GET ACCOUNTS WHOSE DIVISION MAY HAVE CHANGED AFTER ACTIVE MRR HAS BEEN UPDATED
		//if(TriggerHelper.DoExecute('Account.ActiveMRRTerritoryBatchable')){
		//	Map<Id, Account> updatedAccounts = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :UpdatedAccountIds AND TM_Territory_DivisionId__c != null]);
		//	Database.executeBatch(new BatchableTerritoryManagement(updatedAccounts, null, null, null, false), 1);
		//}
	}


}