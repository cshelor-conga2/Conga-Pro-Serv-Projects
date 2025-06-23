/** 
* @author ECS, KSears, ERedding
* @date 20190201
* @version 1.00
* @description Batchable_BillableTimeRollup - Batchable class to roll up Subscription Billable time to parent Accounts
*/
public class Batchable_BillableTimeRollup implements Database.Batchable<sObject>, Schedulable {

    // ACCOUNT SUPPORT LEVEL TO ASSET PRODUCT MAPPING METADATA
    // private static List<Account_Support_Level_Asset_Product__mdt> SupportAssetProductMappingMeta {
    // get {
    //     if(SupportAssetProductMappingMeta == null){
    //         if(Test.isRunningTest()){
    //             SupportAssetProductMappingMeta = Batchable_BillableTimeRollupTest.SupportAssetProductMappingTestMeta;
    //             return SupportAssetProductMappingMeta;
    //         }
    //         SupportAssetProductMappingMeta = [SElECT Product_RecordId__c FROM Account_Support_Level_Asset_Product__mdt];
    //     }
    //     return SupportAssetProductMappingMeta;
    // } set; }

    /** 
    * @description Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this, 1);
    }
    
    /**
    * @description Batchable execute method
    */
    public Database.QueryLocator start(Database.BatchableContext context) {
        // GET SUPPORT ASSET PRODUCT IDS
        // Set<Id> supportAssetProductIds = new Set<Id>();
        // for(Account_Support_Level_Asset_Product__mdt supportProduct : SupportAssetProductMappingMeta){
        //  supportAssetProductIds.add(supportProduct.Product_RecordId__c);
        // }

        //SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Account__c FROM SBQQ__Subscription__c
        //WHERE (SBQQ__ProductName__c = \'Basic Support\' OR SBQQ__ProductName__c = \'Enhanced Support\' OR SBQQ__ProductName__c = \'Premium Support\'

        Set<Id> accountsToUpdate = new Set<Id>();
        for(SBQQ__Subscription__c sub : [SELECT Id, SBQQ__Account__c FROM SBQQ__Subscription__c WHERE SBQQ__Account__c != null 
                                         AND (CreatedDate = TODAY OR LastModifiedDate = TODAY OR SBQQ__StartDate__c = LAST_N_DAYS:3 OR SBQQ__EndDate__c = LAST_N_DAYS:3)]){
            accountsToUpdate.add(sub.SBQQ__Account__c);
        }

        return Database.getQueryLocator([SELECT Id FROM Account WHERE Id IN :accountsToUpdate]);
    }

    /** 
    * @description Logic to be performed on scope
    */
    public void execute(Database.BatchableContext context, List<Account> scope) {
        Map<Id, Account> accMap = new Map<Id, Account>(scope);         
        if(!accMap.isEmpty()){
            BillableTimeRollupHelper.billableTimeRollup(accMap);
        }
    }
    
    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}