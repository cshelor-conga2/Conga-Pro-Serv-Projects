/** 
* @author Conga Services, ERedding
* @date 20190605
* @version 1.00
* @description BatchableSch_DelinquentSalesInvoices - Schedulable Batch class for processing sales invoices that are becoming or are no longer delinquent.
*/
public class BatchableSch_DelinquentSalesInvoices implements Database.Batchable<sObject>, Schedulable{
    
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
        return Database.getQueryLocator([SELECT Id, ia_crm__Amount_Due__c, Sales_Invoice_Delinquent__c FROM ia_crm__Sales_Invoice__c
                                         WHERE (ia_crm__Amount_Due__c > 0 AND Bill_To_Account__c = null AND ia_crm_Days_Late__c >= 30 AND Sales_Invoice_Delinquent__c = false)
                                         OR (ia_crm__Amount_Due__c <= 0 AND Sales_Invoice_Delinquent__c = true)]);
    }
    
    /**
    * @description Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<ia_crm__Sales_Invoice__c> scope) {
        try{

            // CHECK EACH ORDER AND ADD OR REMOVE DELINQUENT FLAG
            List<ia_crm__Sales_Invoice__c> salesInvoicesToUpdate = new List<ia_crm__Sales_Invoice__c>();
            for(ia_crm__Sales_Invoice__c salesInvoice : scope){
                if(salesInvoice.ia_crm__Amount_Due__c <= 0 && salesInvoice.Sales_Invoice_Delinquent__c == true){
                    // WAS DELINQUENT BUT NO LONGER IS, REMOVE DELINQUENT FLAG
                    salesInvoice.Sales_Invoice_Delinquent__c = false;
                    salesInvoicesToUpdate.add(salesInvoice);
                }
                else{
                    // IS NOW DELINQUENT, ADD DELINQUENT FLAG
                    salesInvoice.Sales_Invoice_Delinquent__c = true;
                    salesInvoicesToUpdate.add(salesInvoice);
                }
            }

            Database.SaveResult[] updateResults = Database.update(salesInvoicesToUpdate, false);
            SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'BatchableSch_DelinquentSalesInvoices', 'execute', true);
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_DelinquentSalesInvoices', 'execute', null, ex, true);
        }
    }
    
    /**
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}