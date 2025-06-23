/** 
* @author ECS, ERedding
* @date 20200223
* @version 1.00
* @description BatchableSch_AccountCurrentPartner - Batchable/Schedulable class for update accounts with data that reflects their latest project partner
*/
public class BatchableSch_AccountCurrentPartner implements Database.Batchable<sObject>, Schedulable{
    private Set<Id> AccountIds {get;set;}

    /** 
    * @description BatchableSch_AccountCurrentReseller - Constructor
    */
    public BatchableSch_AccountCurrentPartner() {
    }

    /** 
    * @description BatchableSch_AccountCurrentReseller - Constructor with parameters
    * @param List<Account> accountsToProcess
    */
    public BatchableSch_AccountCurrentPartner(Set<Id> accountIds) {
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
        // GET PROJECT RECORD TYPES
        Map<String, Id> projectRTs = UtilityCLass.getRecordTypesForObject('PS_Project__c');

        if(AccountIds != null && !AccountIds.isEmpty()){
            // USE PROVIDED ACCOUNTS
            return [SELECT Id, Name, Current_Implementation_PartnerId__c,
                    (SELECT Id, Partner_Company_Name_Engaged__c FROM Projects__r 
                     WHERE Is_Active__c = true AND (RecordTypeId = :projectRTs.get('PS_Project') OR RecordTypeId = :projectRTs.get('Partner')) ORDER BY CreatedDate DESC)
                    FROM Account WHERE Id IN :AccountIds];
        }
        else{
            // GET ACCOUNTS WITH PROJECTS THAT WERE RECENTLY CREATED OR MODIFIED
            List<Account> qualifyingAccounts = new List<Account>();
            for(Account qualifyingAccount : [SELECT Id, Name, Current_Implementation_PartnerId__c,
                                              (SELECT Id, Partner_Company_Name_Engaged__c FROM Projects__r 
                                               WHERE Is_Active__c = true AND (RecordTypeId = :projectRTs.get('PS_Project') OR RecordTypeId = :projectRTs.get('Partner')) ORDER BY CreatedDate DESC)
                                              FROM Account 
                                              WHERE Id IN (SELECT AccountId__c FROM PS_Project__c WHERE CreatedDate = LAST_N_DAYS:2 OR LastModifiedDate = LAST_N_DAYS:2)]){
                qualifyingAccounts.add(qualifyingAccount);
            }
            return qualifyingAccounts;
        }
    }
    
    /** 
    * @description execute - Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<Account> scope) {
        try{
            if(!scope.isEmpty()){

                // FOR EACH ACCOUNT, CHECK THE PROJECTS AND UPDATE Current_Implementation_PartnerId__c IF NECESSARY
                List<Account> accountsToUpdate = new List<Account>();
                for(Account account : scope){

                    // UPDATE Current_Implementation_PartnerId__c
                    if(!account.Projects__r.isEmpty() && account.Projects__r[0].Partner_Company_Name_Engaged__c != account.Current_Implementation_PartnerId__c){
                        account.Current_Implementation_PartnerId__c = account.Projects__r[0].Partner_Company_Name_Engaged__c;
                        accountsToUpdate.add(account);
                    }
                    // CLEAR Current_Implementation_PartnerId__c
                    else if(account.Projects__r.isEmpty() && account.Current_Implementation_PartnerId__c != null){
                        account.Current_Implementation_PartnerId__c = null;
                        accountsToUpdate.add(account);
                    }
                }

                if(!accountsToUpdate.isEmpty()){
                    Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'BatchableSch_AccountCurrentPartner', 'execute', true);
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AccountCurrentPartner', 'execute', scope, ex, true);
        }
    }
    
    /** 
    * @description finish - Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}