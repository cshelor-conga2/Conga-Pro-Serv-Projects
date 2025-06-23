/** 
* @author BSI, BSpencer
* @date 20160714
* @version 1.00
* @description batch_mrrCalculatorLOBNightly - LOB is calculated on the Asset level. Roll-up MRR by LOB once nightly via this batch
*/
global class batch_mrrCalculatorLOBNightly implements Database.Batchable<sObject> {

    /** 
    * @description start - Batchable start method. Define scope
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //String query = 'SELECT Id, mrr_Asset_MRR__c, Entitlement_Status__c, Account.Id FROM Asset WHERE mrr_Asset_MRR__c != null';
        return Database.getQueryLocator([SELECT Id, mrr_Active_MRR__c FROM Account]);
    }

    /** 
    * @description execute - Batchable execute method. Perform logic on scope
    */
    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        // GET ASSETS FOR ACCOUNTS
        Map<Id, List<Asset>> assetsByAccount = new Map<Id, List<Asset>>();
        for(Asset asset : [SELECT AccountId, mrr_Asset_MRR__c FROM Asset WHERE AccountId IN :accounts AND mrr_Asset_MRR__c != null]){
            if(!assetsByAccount.containsKey(asset.Id)){
                assetsByAccount.put(asset.AccountId, new List<Asset>());
            }
            assetsByAccount.get(asset.AccountId).add(asset);
        }

        Set<Id> qualifyingAccountIds = new Set<Id>();

        // ACCOUNTS WITH ANY ASSETS QUALIFY FOR AN UPDATE
        qualifyingAccountIds.addAll(assetsByAccount.keySet());

        // ACCOUNTS WITH ACTIVE MRR BUT NO ASSETS QUALIFY FOR AN UPDATE
        for(Account acct : accounts){
            if(acct.mrr_Active_MRR__c > 0 && !assetsByAccount.containsKey(acct.Id)){
                qualifyingAccountIds.add(acct.Id);
            }
        }

        // EXECUTE LOGIC IF THERE ARE ACCOUNTS TO UPDATE
        if(!qualifyingAccountIds.isEmpty()){
            mrrCalculatorAcctAsset.calculateMRR(qualifyingAccountIds);
        } 
    }

    /** 
    * @description finish - Batchable finish method. Start batch_mrrCalculatorLOBNULLNightly batch class
    */
    global void finish(Database.BatchableContext bc) {
        batch_mrrCalculatorLOBNULLNightly batch = new batch_mrrCalculatorLOBNULLNightly();
        Database.executeBatch(batch, 10);
    }


}