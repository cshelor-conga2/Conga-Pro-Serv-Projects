/** 
* @author ECS, ERedding
* @date 20190620
* @version 1.00
* @description BatchableSch_AccountTypeCalculator - Schedulable Batch class for update Account Types based on the Account's Assets
*/
public class BatchableSch_AccountTypeCalculator implements Database.Batchable<sObject>, Schedulable{
    private final Set<Id> ACCOUNTIDS {get;set;}
    private final Map<String, Map<String, Id>> RECORDTYPES = UtilityClass.getRecordTypesForObjects(new List<String>{ 'Account', 'Contract' });

    /** 
    * @description BatchableSch_AccountTypeCalculator - Constructor
    */
    public BatchableSch_AccountTypeCalculator() {
    }

    /** 
    * @description BatchableSch_AccountTypeCalculator - Constructor with parameters
    * @param List<Account> accountsToProcess
    */
    public BatchableSch_AccountTypeCalculator(Set<Id> accountIds) {
    	this.ACCOUNTIDS = accountIds;
    }

    /** 
    * @description execute - Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this, (Test.isRunningTest() ? 15 : 1));
    }
    
    /** 
    * @description start - Batchable start method
    */  
    public List<Account> start(Database.BatchableContext context) {
        // GET ACCOUNT RECORD TYPES
        Id businessAccountRT = RECORDTYPES.get('Account').get('Business_Account');
        Id partnerAccountRT = RECORDTYPES.get('Account').get('Partner_Account');

    	if(ACCOUNTIDS != null && !ACCOUNTIDS.isEmpty()){
    		// USE PROVIDED ACCOUNTS
    		return [SELECT Id, RecordTypeId, Type FROM Account WHERE Id IN :ACCOUNTIDS AND Override_Type_Automation__c = false];
    	}
    	else{
    		// USE ACCOUNTS FOUND THROUGH QUERIES
	        Map<Id, Account> qualifyingAccounts = new Map<Id, Account>();

            //////////////////////// GET CUSTOMER ACCOUNTS TO PROCESS
	        // GET CUSTOMER ACCOUNTS FROM ASSETS THAT WERE RECENTLY CREATED OR MODIFIED OR RECENTLY STARTED OR ENDED
	        for(Asset recentAsset : [SELECT Id, AccountId, Account.RecordTypeId, Account.Type FROM Asset 
                                     WHERE Account.RecordTypeId = :businessAccountRT
                                     AND (CreatedDate = LAST_N_DAYS:3 OR LastModifiedDate = LAST_N_DAYS:3 OR Start_Date__c = LAST_N_DAYS:3 OR End_Date__c = LAST_N_DAYS:3)]){
	            qualifyingAccounts.put(recentAsset.AccountId, recentAsset.Account);
	        }

	        // GET CUSTOMER ACCOUNTS THAT HAVE NO ASSETS AND ARE NOT FLAGGED AS PROSPECT
	        for(Account account : [SELECT Id, RecordTypeId, Type FROM Account
                                   WHERE Id NOT IN (SELECT AccountId FROM Asset) 
                                   AND RecordTypeId = :businessAccountRT AND Type != 'Prospect' AND Override_Type_Automation__c = false]){
	            qualifyingAccounts.put(account.Id, account);
	        }

            // GET CUSTOMER ACCOUNTS THAT HAVE RECENTLY CREATED OR MODIFIED RENEWAL OR FORECAST OPPS
            for(Opportunity renewalOpp : [SELECT Id, AccountId, Account.RecordTypeId, Account.Type FROM Opportunity 
                                          WHERE Account.RecordTypeId = :businessAccountRT
                                          AND (Type = 'Renewal' OR Sub_Type__c = 'Forecasting Opportunity') 
                                          AND (CreatedDate = LAST_N_DAYS:3 OR LastModifiedDate = LAST_N_DAYS:3 OR (MRR_Sub_Start__c < LAST_N_DAYS:90
                                                                                                                   AND MRR_Sub_Start__c = LAST_N_DAYS:93))]){
                qualifyingAccounts.put(renewalOpp.AccountId, renewalOpp.Account);
            }
            ////////////////////////


            //////////////////////// GET PARTNER ACCOUNTS TO PROCESS
            for(Contract recentContract : [SELECT Id, AccountId, Account.RecordTypeId, Account.Type FROM Contract
                                           WHERE Account.RecordTypeId = :partnerAccountRT
                                           AND (CreatedDate = LAST_N_DAYS:3 OR LastModifiedDate = LAST_N_DAYS:3 OR StartDate = LAST_N_DAYS:3 OR EndDate = LAST_N_DAYS:3)]){
                qualifyingAccounts.put(recentContract.AccountId, recentContract.Account);
            }

            // GET ACCOUNTS THAT HAVE NO CONTRACTS AND ARE NOT FLAGGED AS PROSPECTIVE PARTNER
            for(Account account : [SELECT Id, RecordTypeId, Type FROM Account 
                                   WHERE Id NOT IN (SELECT AccountId FROM Contract WHERE Status = 'Activated' OR Status = 'Expired')
                                   AND Override_Type_Automation__c = false
                                   AND RecordTypeId = :partnerAccountRT AND Type != 'Prospective Partner']){
                qualifyingAccounts.put(account.Id, account);
            }
            ////////////////////////

	        return qualifyingAccounts.values();
    	}
    }
    
    /** 
    * @description execute - Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<Account> scope) {
        try{
            if(!scope.isEmpty()){
                // GET RECORD TYPES
                Map<String, Id> accountRTs = RECORDTYPES.get('Account');
                Map<String, Id> contractRTs = RECORDTYPES.get('Contract');

                // GET CUSTOMER AND PARTNER ACCOUNT IDS
                Set<Id> customerIds = new Set<Id>();
                Set<Id> partnerIds = new Set<Id>();                
                for(Account acct : scope){
                    if(acct.RecordTypeId == accountRTs.get('Business_Account')){
                        customerIds.add(acct.Id);
                    }
                    else if(acct.RecordTypeId == accountRTs.get('Partner_Account')){
                        partnerIds.add(acct.Id);
                    }
                }

                ///////////////////////// GET CUSTOMER ACCOUNT DATA
                Map<Id, Set<String>> assetStatusesByAccount = new Map<Id, Set<String>>();
                Map<Id, Decimal> sumOfAssetsByAccount = new Map<Id, Decimal>();
                Set<Id> acctsWithRenewals = new Set<Id>();
                Set<Id> acctsWithOpenForecastOpps = new Set<Id>();
                Set<Id> acctsWithClosedWonForecastOpps = new Set<Id>();
                Set<Id> acctsWithClosedLostForecastOpps = new Set<Id>();
                if(!customerIds.isEmpty()){
                    // CREATE A UNIQUE SET OF ASSET ENTILEMENT STATUSES FOR EACH ACCOUNT
                    for(Asset asset : [SELECT Id, AccountId, Entitlement_Status__c FROM Asset WHERE AccountId IN :customerIds]){
                        if(!assetStatusesByAccount.containsKey(asset.AccountId)){
                            assetStatusesByAccount.put(asset.AccountId, new Set<String>());
                        }
                        assetStatusesByAccount.get(asset.AccountId).add(UtilityClass.replaceNull(asset.Entitlement_Status__c, 'Expired'));
                    }

                    // GET THE SUM OF ACTIVE ASSETS FOR EACH ACCOUNT
                    for(AggregateResult agg : [SELECT AccountId, SUM(Quantity) totalActiveQty FROM Asset WHERE AccountId IN :customerIds AND Entitlement_Status__c = 'Active' GROUP BY AccountId]){                   
                        sumOfAssetsByAccount.put((Id)agg.get('AccountId'), (Decimal)agg.get('totalActiveQty'));
                    }

                    // GET IDS OF ACCOUNTS THAT HAVE AN OPEN RENEWAL OPP WITH MRR SUB START WITHIN 90 DAYS -OR- A FORECAST OPPORTUNITY
                    for(Opportunity accountOpp : [SELECT AccountId, IsClosed, IsWon, Sub_Type__c FROM Opportunity WHERE AccountId IN :customerIds
                                                      AND ((Type = 'Renewal' AND IsClosed = false AND MRR_Sub_Start__c = LAST_90_DAYS) OR (Sub_Type__c = 'Forecasting Opportunity'))]){

                        if(accountOpp.Sub_Type__c != 'Forecasting Opportunity'){
                            acctsWithRenewals.add(accountOpp.AccountId);
                        }
                        else if(accountOpp.Sub_Type__c == 'Forecasting Opportunity'){
                            if(!accountOpp.IsClosed){
                                acctsWithOpenForecastOpps.add(accountOpp.AccountId);
                            }
                            else if(accountOpp.IsClosed && accountOpp.IsWon){
                                acctsWithClosedWonForecastOpps.add(accountOpp.AccountId);
                            }
                            else if(accountOpp.IsClosed && !accountOpp.IsWon){
                                acctsWithClosedLostForecastOpps.add(accountOpp.AccountId);
                            }
                        }
                    }
                }
                /////////////////////////


                ///////////////////////// GET PARTNER ACCOUNT DATA
                Set<Id> accountsWithActiveContracts = new Set<Id>();
                Set<Id> accountsWithExpiredContracts = new Set<Id>();
                if(!partnerIds.isEmpty()){

                    // DETERMINE WHETHER PARTNER ACCOUNTS HAVE ACTIVE AND/OR EXPIRED CONTRACTS
                    for(Contract contract : [SELECT Id, AccountId, RecordTypeId, RecordType.DeveloperName, Status FROM Contract WHERE AccountId IN :partnerIds]){
                        if(contract.RecordTypeId == contractRTs.get('SI') || contract.RecordTypeId == contractRTs.get('Reseller')){
                            if(contract.Status == 'Activated'){
                                accountsWithActiveContracts.add(contract.AccountId);
                            }

                            if(contract.Status == 'Expired'){
                                accountsWithExpiredContracts.add(contract.AccountId); 
                            }
                        }
                    }
                }
                /////////////////////////

                // FOR EACH ACCOUNT CHECK THE UNIQUE SET OF STATUSES FOR SPECIFIC VALUES AND SET ACCCOUNT TYPE
                List<Account> accountsToUpdate = new List<Account>();
                for(Account account : scope){

                    // SET TYPE IF APPLICABLE FOR CUSTOMER ACCOUNTS
                    if(customerIds.contains(account.Id)){
                        Set<String> assetStatuses = assetStatusesByAccount.containsKey(account.Id) ? assetStatusesByAccount.get(account.Id) : null;
                        Decimal totalActiveQty = sumOfAssetsByAccount.containsKey(account.Id) ? sumOfAssetsByAccount.get(account.Id) : 0;

                        // NO ASSETS, SET TYPE TO PROSPECT OR CUSTOMER IF IT HAS A CLOSED WON FORECAST OPPORTUNITY
                        if(assetStatuses == null){
                            if(account.Type != 'Customer' && acctsWithClosedWonForecastOpps.contains(account.Id)){
                                account.Type = 'Customer';
                                account.Override_Type_Automation__c = false;
                                accountsToUpdate.add(account);
                            }
                            else if(account.Type != 'Prospect' && !acctsWithClosedWonForecastOpps.contains(account.Id)){
                                account.Type = 'Prospect';
                                account.Override_Type_Automation__c = false;
                                accountsToUpdate.add(account);
                            }
                        }
                        // HAS ACTIVE AND/OR FUTURE ASSETS, SET TYPE TO CUSTOMER
                        else if(assetStatuses != null && account.Type != 'Customer' && (totalActiveQty > 0 || assetStatuses.contains('Future'))){
                            account.Type = 'Customer';
                            account.Override_Type_Automation__c = false;
                            accountsToUpdate.add(account);
                        }
                        // HAS ASSETS BUT NONE ARE ACTIVE OR ACTIVE QTY IS ZERO AND THERE ARE NO FUTURE ASSETS AND THERE IS AN OPEN RENEWAL OPP CREATED WITHIN THE LAST 90 DAYS
                        else if(assetStatuses != null && !assetStatuses.contains('Future') && account.Type != 'Customer - Past Due' && totalActiveQty == 0 && acctsWithRenewals.contains(account.Id)){
                            account.Type = 'Customer - Past Due';
                            account.Override_Type_Automation__c = false;
                            accountsToUpdate.add(account);
                        }
                        // HAS ASSETS BUT NONE ARE ACTIVE OR ACTIVE QTY IS ZERO AND THERE ARE NO FUTURE ASSETS AND THERE IS -NO- OPEN RENEWAL OPP CREATED WITHIN THE LAST 90 DAYS
                        else if(assetStatuses != null && !assetStatuses.contains('Future') && totalActiveQty == 0 && !acctsWithRenewals.contains(account.Id)){
                            if(account.Type != 'Prospect' && acctsWithOpenForecastOpps.contains(account.Id)){
                                account.Type = 'Prospect';
                                account.Override_Type_Automation__c = false;
                                accountsToUpdate.add(account);
                            }
                            else if(account.Type != 'Customer' && acctsWithClosedWonForecastOpps.contains(account.Id)){
                                account.Type = 'Customer';
                                account.Override_Type_Automation__c = false;
                                accountsToUpdate.add(account);
                            }
                            else if(account.Type != 'Customer - Former' && !acctsWithOpenForecastOpps.contains(account.Id) && !acctsWithClosedWonForecastOpps.contains(account.Id)){
                                account.Type = 'Customer - Former';
                                account.Override_Type_Automation__c = false;
                                accountsToUpdate.add(account);
                            }
                        }
                    }
                    // SET TYPE IF APPLICABLE FOR PARTNER ACCOUNTS
                    else if(partnerIds.contains(account.Id)){

                        // PARTNER HAS NO CONTRACTS
                        if(account.Type != 'Prospective Partner' && !accountsWithActiveContracts.contains(account.Id) && !accountsWithExpiredContracts.contains(account.Id)){
                            account.Type = 'Prospective Partner';
                            account.Override_Type_Automation__c = false;
                            accountsToUpdate.add(account);
                        }
                        // PARTNER HAS ACTIVE CONTRACTS
                        else if(account.Type != 'Partner' && accountsWithActiveContracts.contains(account.Id)){
                            account.Type = 'Partner';
                            account.Override_Type_Automation__c = false;
                            accountsToUpdate.add(account);
                        }
                        // PARTNER HAS ONLY EXPIRED CONTRACTS
                        else if(account.Type != 'Partner - Former' && !accountsWithActiveContracts.contains(account.Id) && accountsWithExpiredContracts.contains(account.Id)){
                            account.Type = 'Partner - Former';
                            account.Override_Type_Automation__c = false;
                            accountsToUpdate.add(account);
                        }
                    }
                }

                if(!accountsToUpdate.isEmpty()){
                    Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'BatchableSch_AccountTypeCalculator', 'execute', true);
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AccountTypeCalculator', 'execute', scope, ex, true);
        }
    }
    
    /** 
    * @description finish - Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}