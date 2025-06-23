/** 
* @author ECS, ERedding
* @date 20200121
* @version 1.00
* @description BatchableSch_AccountCurrentReseller - [Description]
*/
public class BatchableSch_AccountCurrentReseller implements Database.Batchable<sObject>, Schedulable{
	private Set<Id> AccountIds {get;set;}

    /** 
    * @description BatchableSch_AccountCurrentReseller - Constructor
    */
    public BatchableSch_AccountCurrentReseller() {
    }

    /** 
    * @description BatchableSch_AccountCurrentReseller - Constructor with parameters
    * @param List<Account> accountsToProcess
    */
    public BatchableSch_AccountCurrentReseller(Set<Id> accountIds) {
    	this.AccountIds = accountIds;
    }

    /** 
    * @description execute - Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this, 10);
    }
    
    /** 
    * @description start - Batchable start method
    */  
    public List<Account> start(Database.BatchableContext context) {
    	if(AccountIds != null && !AccountIds.isEmpty()){
    		// USE PROVIDED ACCOUNTS
    		return [SELECT Id, Current_Reseller__c FROM Account WHERE Id IN :AccountIds];
    	}
    	else{
    		// USE ACCOUNTS FOUND THROUGH QUERIES
	        Map<Id, Account> qualifyingAccounts = new Map<Id, Account>();

	        // GET ACCOUNTS WITH RESELLERS
	        for(Account account : [SELECT Id, Current_Reseller__c FROM Account WHERE Current_Reseller__c != null]){
	        	qualifyingAccounts.put(account.Id, account); 
	        }

	        // GET ACCOUNTS FROM ASSETS THAT WERE RECENTLY CREATED OR MODIFIED
	        for(Asset recentAsset : [SELECT Id, AccountId, Account.Current_Reseller__c FROM Asset WHERE Entitlement_Status__c = 'Active' AND Reseller__c != null
	        														 							  AND (CreatedDate = LAST_N_DAYS:2 OR LastModifiedDate = LAST_N_DAYS:2
                                                                          								OR Start_Date__c = LAST_N_DAYS:2 OR End_Date__c = LAST_N_DAYS:2)]){
	            qualifyingAccounts.put(recentAsset.AccountId, recentAsset.Account);    
	        }

            // GET ACCOUNTS THAT HAVE RECENTLY CLOSED WON OPPS WITH RESELLERS
            for(Opportunity closedResellerOpp : [SELECT Id, AccountId, Account.Current_Reseller__c FROM Opportunity WHERE IsClosed = true AND IsWon = true AND Reseller__c != null
              																		   								AND (CloseDate = LAST_N_DAYS:2 OR CloseDate = LAST_N_DAYS:2)]){
                qualifyingAccounts.put(closedResellerOpp.AccountId, closedResellerOpp.Account);
            }

            System.debug(qualifyingAccounts.size());
	        return qualifyingAccounts.values();
    	}
    }
    
    /** 
    * @description execute - Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<Account> scope) {
        try{
            if(!scope.isEmpty()){

                // GET RESELLERS FROM LATEST ACTIVE ASSETS
                Map<Id, Id> activeAssetResellerByAccount = new Map<Id, Id>();
                for(Asset activeResellerAsset : [SELECT Id, AccountId, Reseller__c FROM Asset 
                				   				 WHERE Entitlement_Status__c = 'Active' AND Reseller__c != null AND AccountId IN :scope ORDER BY CreatedDate DESC]){
                    if(!activeAssetResellerByAccount.containsKey(activeResellerAsset.AccountId)){
						activeAssetResellerByAccount.put(activeResellerAsset.AccountId, activeResellerAsset.Reseller__c);
                    }
                }

                // GET RESELLERS FROM LATEST CLOSED WON OPPS, RESELLER ID WILL BE NULL IF THERE IS NONE
                Map<Id, Id> closedWonOppResellerByAccount = new Map<Id, Id>();
                for(Opportunity closedWonOpp : [SELECT Id, AccountId, Reseller__c FROM Opportunity
                								WHERE IsClosed = true AND IsWon = true AND AccountId IN :scope ORDER BY CloseDate DESC]){
                    if(!closedWonOppResellerByAccount.containsKey(closedWonOpp.AccountId)){
						closedWonOppResellerByAccount.put(closedWonOpp.AccountId, closedWonOpp.Reseller__c);
                    }
                }

                // FOR EACH ACCOUNT CHECK THE UNIQUE SET OF STATUSES FOR SPECIFIC VALUES AND SET ACCCOUNT TYPE
                List<Account> accountsToUpdate = new List<Account>();
                for(Account account : scope){

                    // USE RESELLER FROM ASSETS IF AVAILABLE
                    if(activeAssetResellerByAccount.containsKey(account.Id) && account.Current_Reseller__c != activeAssetResellerByAccount.get(account.Id)){
                        account.Current_Reseller__c = activeAssetResellerByAccount.get(account.Id);
                        accountsToUpdate.add(account);
                    }
                    // USE RESELLER FROM LATEST CLOSED WON OPP IF AVAILABLE
                    else if(closedWonOppResellerByAccount.containsKey(account.Id) && closedWonOppResellerByAccount.get(account.Id) != null && account.Current_Reseller__c != closedWonOppResellerByAccount.get(account.Id)){
                        account.Current_Reseller__c = closedWonOppResellerByAccount.get(account.Id);
                        accountsToUpdate.add(account);
                    }
                    else if(!activeAssetResellerByAccount.containsKey(account.Id) && 
                    		(!closedWonOppResellerByAccount.containsKey(account.Id) || closedWonOppResellerByAccount.get(account.Id) == null) && account.Current_Reseller__c != null){
                        account.Current_Reseller__c = null;
                        accountsToUpdate.add(account);
                    }
                }

                if(!accountsToUpdate.isEmpty()){
                    Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'BatchableSch_AccountCurrentReseller', 'execute', true);
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AccountCurrentReseller', 'execute', scope, ex, true);
        }
    }
    
    /** 
    * @description finish - Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}