/** 
* @author Conga Services
* @date 20180828
* @version 1.00
* @description Schedulable_AcctSupportLevelUpdates - Schedulabled functionality to update the Support Level field on an Account based on the existing, active Support Assets
*/
public without sharing class Schedulable_AcctSupportLevelUpdates implements Database.Batchable<sObject>, Schedulable {

    /** 
    * @description  GET REQUIRED METADATA IN A WAY THAT MAKES IT ACCESSIBLE FROM TEST CODE
    */  
    @testVisible 
    private Map<Id, String> SupportLevelAssetMetaMap { 
    get {
        if(SupportLevelAssetMetaMap == null){
            if(Test.isRunningTest()){
                SupportLevelAssetMetaMap = Schedulable_AcctSupportLevelUpdatesTest.TestSupportLevelAssetMetaMap;
            }
            else{
                SupportLevelAssetMetaMap = new Map<Id, String>();
                for(Account_Support_Level_Asset_Product__mdt meta : [SELECT Product_RecordId__c, Support_Level__c FROM Account_Support_Level_Asset_Product__mdt]){
                    SupportLevelAssetMetaMap.put(meta.Product_RecordId__c, meta.Support_Level__c);
                }
            }
        }
        return SupportLevelAssetMetaMap;
    } set; }
    
    /** 
    * @description Batchable start method
    */  
    public Database.QueryLocator start(Database.BatchableContext context) {
        if(!SupportLevelAssetMetaMap.isEmpty()){
            return Database.getQueryLocator([SELECT Id, SBQQ__Account__c, SBQQ__Account__r.Support_Level__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c
                                             FROM SBQQ__Subscription__c
                                             WHERE SBQQ__Product__c IN :SupportLevelAssetMetaMap.keySet() 
                                             AND ((SBQQ__StartDate__c <= TODAY AND SBQQ__EndDate__c >= TODAY) OR SBQQ__EndDate__c = YESTERDAY)
                                             ORDER BY SBQQ__EndDate__c DESC]);
        }
        else{
            SystemIssueLogHelper.LogException('Schedulable_AccountSupportLevelUpdates', 'start', null, 'No records found in Account_Support_Level_Asset_Product__mdt.', true);
        }
        return Database.getQueryLocator([SELECT Id FROM SBQQ__Subscription__c WHERE Id = null]);
    }

    /** 
    * @description execute - What to execute when schedule runs
    */
    public void execute(Database.BatchableContext context, List<SBQQ__Subscription__c> scope){
        try{
            // GET SOON TO BE ACTIVE/INACTIVE SUPPORT SBQQ__Subscription__c AND PARENT ACCOUNT CURRENT SUPPORT LEVEL VALUES         
            Map<Id, String> currentAccountSupportLevels = new Map<Id, String>();
            Map<Id, SBQQ__Subscription__c> activeSubByAccount = new Map<Id, SBQQ__Subscription__c>();
            Map<Id, SBQQ__Subscription__c> inactiveSubByAccount = new Map<Id, SBQQ__Subscription__c>();
            for(SBQQ__Subscription__c sub : scope){
                // GET THE ACCOUNT'S CURRENT SUPPORT LEVEL
                if(!currentAccountSupportLevels.containsKey(sub.SBQQ__Account__r.Id)){
                    currentAccountSupportLevels.put(sub.SBQQ__Account__r.Id, sub.SBQQ__Account__r.Support_Level__c);
                }
                // CHECK IF SBQQ__Subscription__c IS ACTIVE AND STORE IN MAP
                if(sub.SBQQ__StartDate__c <= Date.today() && sub.SBQQ__EndDate__c >= Date.today()){
                    if(!activeSubByAccount.containsKey(sub.SBQQ__Account__r.Id)){
                        activeSubByAccount.put(sub.SBQQ__Account__r.Id, sub);
                    }
                }
                else if(sub.SBQQ__EndDate__c == Date.today().addDays(-1)){
                    if(!inactiveSubByAccount.containsKey(sub.SBQQ__Account__r.Id)){
                        inactiveSubByAccount.put(sub.SBQQ__Account__r.Id, sub);
                    }
                }
            }

            // GET SUSPENDED PRODUCTION SALESFORCE ORGS AND THE ACCOUNTS OF THOSE ORGS
            Set<Id> accountsWithSuspendedOrgIds = new Set<Id>();
            for(Salesforce_Org__c suspendedOrg : [SELECT Id, Account__c, Account__r.Support_Level__c FROM Salesforce_Org__c 
                                                    WHERE Org_Type__c = 'Production' AND Conga_Account_Suspension_Date__c != null AND Conga_Account_Suspension_Date__c = THIS_QUARTER]){
                accountsWithSuspendedOrgIds.add(suspendedOrg.Account__c);
                if(!currentAccountSupportLevels.containsKey(suspendedOrg.Account__c)){
                    currentAccountSupportLevels.put(suspendedOrg.Account__c, suspendedOrg.Account__r.Support_Level__c);
                }
            }

            // PROCESS ACCOUNTS AND QUEUE APPLICABLE ONES FOR UPDATES
            List<Account> accountsToUpdate = new List<Account>();
            for(Id acctId : currentAccountSupportLevels.keySet()){
                String currentSupportLevel = currentAccountSupportLevels.get(acctId);

                if(accountsWithSuspendedOrgIds.contains(acctId) && String.isNotBlank(currentSupportLevel)){
                    // SALESFORCE ORG ACCOUNT IS SUSPENDED, SET SUPPORT LEVEL TO BLANK
                    accountsToUpdate.add(new Account(Id = acctId, Support_Level__c = ''));
                }
                else if((!accountsWithSuspendedOrgIds.contains(acctId) && !activeSubByAccount.containsKey(acctId) && currentSupportLevel != 'Basic') || inactiveSubByAccount.containsKey(acctId)){
                    // NO ACTIVE SUPPORT ASSET FOUND, SET SUPPORT LEVEL TO BASIC
                    accountsToUpdate.add(new Account(Id = acctId, Support_Level__c = 'Basic'));
                }
                else if(!accountsWithSuspendedOrgIds.contains(acctId) && activeSubByAccount.containsKey(acctId) && currentSupportLevel != SupportLevelAssetMetaMap.get(activeSubByAccount.get(acctId).SBQQ__Product__c)){
                    // ACTIVE SUPPORT ASSET FOUND, UPDATE SUPPORT LEVEL
                    accountsToUpdate.add(new Account(Id = acctId, Support_Level__c = SupportLevelAssetMetaMap.get(activeSubByAccount.get(acctId).SBQQ__Product__c)));
                }
            }

            // COMMIT ACCOUNT CHANGES
            if(!accountsToUpdate.isEmpty()){
                Database.saveResult[] accountResults = Database.update(accountsToUpdate, false);
                SystemIssueLogHelper.CheckForDatabaseErrors(accountResults, 'Schedulable_AccountSupportLevelUpdates', 'execute', true);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('Schedulable_AccountSupportLevelUpdates', 'execute', scope, ex, true);
        }
    }

    /** 
    * @description Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this, 5);
    }

    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}