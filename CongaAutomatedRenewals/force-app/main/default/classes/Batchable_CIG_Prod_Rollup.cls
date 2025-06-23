/** 
* @author Conga Services
* @date 20181220
* @version 1.00
* @description Batchable_CIG_Prod_Rollup
*/
public class Batchable_CIG_Prod_Rollup implements Database.Batchable<sObject>, Schedulable{
    String query; 

    /** 
    * @description Constructor
    */
    public Batchable_CIG_Prod_Rollup() {
        query = 'SELECT Id, Account__c, Allowed_Usage__c, Asset_Start_Date__c, Asset_End_Date__c, Monthly_Total_Success__c, Total_Success__c FROM Salesforce_Org__c';
    }
    
    /** 
    * @description Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this); // DEFAULT CHUNK SIZE OF 200
        // OR Database.executeBatch(this, 50); // SPECIFY CHUNK SIZE OF 50
    }

    /** 
    * @description Batchable start method
    */  
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
        // OR return Database.getQueryLocator([SELECT fields FROM object WHERE condition]);
    }
    
    /** 
    * @description Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<sObject> scope) {
        CIG_Prod_Rollup.RollupUseage((List<Salesforce_Org__c>)scope);
    }
    
    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}