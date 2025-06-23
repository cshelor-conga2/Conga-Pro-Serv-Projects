/** 
* @author Conga Services, ERedding
* @date 20181214
* @version 1.00
* @description BatchableDelinquentOrders - Schedulable Batch class for process orders that are becoming delinquent or are no longer.
*/
public class BatchableDelinquentOrders implements Database.Batchable<sObject>, Schedulable{
    
    /** 
    * @description Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this, 3);
    }
    
    /** 
    * @description Batchable start method
    */  
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, Name, Amount_DueFx__c, Billing_PartyId__c, Days_Late__c, Status, Order_Delinquent__c FROM Order
                                         WHERE (Amount_DueFx__c > 0 AND Billing_PartyId__c = null AND Days_Late__c >= 30 
                                                AND Status NOT IN ('Draft','Pending','Paid','Cancelled','Credit Memo','Refund')
                                                AND Order_Delinquent__c = false)
                                         OR (Amount_DueFx__c <= 0 AND Order_Delinquent__c = true)]);
    }
    
    /** 
    * @description Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<Order> scope) {
        try{

            // CHECK EACH ORDER AND ADD OR REMOVE DELINQUENT FLAG
            List<Order> ordersToUpdate = new List<Order>();
            for(Order order : scope){
                if(order.Amount_DueFx__c <= 0 && order.Order_Delinquent__c == true){
                    // WAS DELINQUENT BUT NO LONGER IS, REMOVE DELINQUENT FLAG
                    order.Order_Delinquent__c = false;
                    ordersToUpdate.add(order);
                }
                else{
                    // IS NOW DELINQUENT, ADD DELINQUENT FLAG
                    order.Order_Delinquent__c = true;
                    ordersToUpdate.add(order);
                }
            }

            Database.SaveResult[] updateResult = Database.update(ordersToUpdate, false);
            SystemIssueLogHelper.CheckForDatabaseErrors(updateResult, 'BatchableDelinquentOrders', 'execute', true);
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableDelinquentOrders', 'execute', null, ex, true);
        }
    }
    
    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}