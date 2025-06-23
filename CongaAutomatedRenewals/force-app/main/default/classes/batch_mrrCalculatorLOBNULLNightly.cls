/** 
* @author BSI, BSpencer
* @date 20160714
* @version 1.00
* @description batch_mrrCalculatorLOBNULLNightly -
*/
global class batch_mrrCalculatorLOBNULLNightly implements Database.Batchable<sObject> {

    /**
    * @description start - Batchable start method. Define scope
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //String query = 'SELECT Id, mrr_Active_MRR__c, mrr_Data_MRR__c, mrr_DocMerge_MRR__c, mrr_Contracts_mrr__c, mrr_Services_MRR__c, mrr_Reseller_mrr__c, mrr_eSignature_MRR__c, ';
        // 	   query += 'mrr_Workflow_MRR__c FROM Account WHERE mrr_Active_MRR__c = null OR mrr_Data_MRR__c = null OR mrr_DocMerge_MRR__c = null OR mrr_Contracts_mrr__c = null OR ';
        // 	   query += 'mrr_Reseller_mrr__c = null OR mrr_Services_MRR__c = null OR mrr_eSignature_MRR__c = null';
        	   
        return Database.getQueryLocator([SELECT Id, mrr_Active_MRR__c, mrr_Data_MRR__c, mrr_DocMerge_MRR__c, mrr_Contracts_mrr__c, mrr_Services_MRR__c, mrr_Reseller_mrr__c, mrr_eSignature_MRR__c, 
        										mrr_Workflow_MRR__c 
        								 FROM Account WHERE mrr_Active_MRR__c = null OR mrr_Data_MRR__c = null OR mrr_DocMerge_MRR__c = null OR mrr_Contracts_mrr__c = null 
        								 OR mrr_Reseller_mrr__c = null OR mrr_Services_MRR__c = null OR mrr_eSignature_MRR__c = null]);
    }

    /**
    * @description execute - Batchable execute method. Perform logic on scope
    */
    global void execute(Database.BatchableContext bc, List<Account> accts) {
        List<Account> acctsToUpdate = new List<Account>();
        for (Account a : accts){
            if (a.mrr_Active_MRR__c == null){
                a.mrr_Active_MRR__c = 0;
            }

            if (a.mrr_Data_MRR__c == null){
                a.mrr_Data_MRR__c = 0;
            }

            if (a.mrr_DocMerge_MRR__c == null){
                a.mrr_DocMerge_MRR__c = 0;
            }

            if (a.mrr_Contracts_MRR__c == null){
                a.mrr_Contracts_MRR__c = 0;
            }

            if (a.mrr_Reseller_MRR__c == null){
                a.mrr_Reseller_MRR__c = 0;
            }

            if (a.mrr_Services_MRR__c == null){
                a.mrr_Services_MRR__c = 0;
            }
            
            if (a.mrr_eSignature_MRR__c == null){
                a.mrr_eSignature_MRR__c = 0;
            } 

            if (a.mrr_Workflow_MRR__c == null){
                a.mrr_Workflow_MRR__c = 0;
            }            

            acctsToUpdate.add(a);
        }


        /*Using partial processing with error handling so that end users are not interrupted by a record update failing. Send errors to Bethany (future team email? future error log object to store in SF?)*/
        Database.saveResult[] acctResults = Database.update(acctsToUpdate, false);
        SystemIssueLogHelper.CheckForDatabaseErrors(acctResults, 'batch_mrrCalculatorLOBNULLNightly', 'execute', true);

        //String subject = 'Error Updating records in batch_mrrCalculatorLOBNULLNightly class';
        //List<String> toAddresses = new List<String>{'bspencer@appextremes.com'};
        //String body = '';
        //String fromAddress = 'bspencer@appextremes.com';
        
        //for (Database.saveResult res : acctResults)
        //{
        //    if (!res.isSuccess())
        //    {
        //        body += 'Id = ' + res.getId() + '\n\n' + res.getErrors() + '\n\n';
        //        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        //        email.setTargetObjectId('0035000002QPtPY');
        //        email.setReplyTo(fromAddress);
        //        email.setSubject(subject);
        //        email.setPlainTextBody(body);
        //        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        //    }
        //}
    }

    /** 
    * @description finish - Batchable finish method. Start batch_mrrCalculatorLOBNULLNightly batch class
    */
    global void finish(Database.BatchableContext bc) {
        // NO FINISH LOGIC
    }


}