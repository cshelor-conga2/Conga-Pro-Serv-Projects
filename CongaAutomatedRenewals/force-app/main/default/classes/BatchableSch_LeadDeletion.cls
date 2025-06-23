/** 
* @author ECS, ERedding
* @author Systemyc, GModica
* @date 20190513
* @version 1.00
* @description BatchableSch_LeadDeletion - Combination batchable and schedulable class for deleting qualifying leads
*/
public class BatchableSch_LeadDeletion implements Database.Batchable<sObject>, Schedulable{
        
    /** 
    * @description Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this); // DEFAULT CHUNK SIZE OF 200
    }
    
    /** 
    * @description Batchable start method
    */  
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Lead WHERE Id = null';

        List<Lead_Automation_Settings__mdt> settings = [SELECT Delete_Leads_with_Status__c,Delete_Leads_with_Company_containing__c FROM Lead_Automation_Settings__mdt 
                                                        WHERE MasterLabel = 'Standard'];
        
        if(!settings.isEmpty()){

            Lead_Automation_Settings__mdt setting = settings[0];

            if(!String.isBlank(setting.Delete_Leads_with_Status__c) || !String.isBlank(setting.Delete_Leads_with_Company_containing__c)) {
                query = 'SELECT Id FROM Lead WHERE IsConverted = false AND ({0})';
                
                List<String> conditions = new List<String>();
                if(!String.isBlank(setting.Delete_Leads_with_Status__c)) {
                    List<String> values = new List<String>();
                    for(String value : String.escapeSingleQuotes(setting.Delete_Leads_with_Status__c).split(',')) { 
                        values.add('\'' + value.trim() + '\'');
                    }
                    
                    if(values.size() == 1) {
                        conditions.add('Status = ' + values[0]);
                    }
                    else if(values.size() > 0) {
                        conditions.add('Status in (' + String.join(values, ',') + ')');
                    }

                }

                if(!String.isBlank(setting.Delete_Leads_with_Company_containing__c)) {
                    conditions.add('Company like \'%' + String.escapeSingleQuotes(setting.Delete_Leads_with_Company_containing__c) + '%\'');
                }

                String conditionsText = String.join(conditions, ' or ');
                query = String.format(query, new String[] { conditionsText });
            }
        }

        return Database.getQueryLocator(query);
    }
    
    /** 
    * @description Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<sObject> scope) {
        Database.DeleteResult[] deleteResults = Database.delete(scope, false);
        SystemIssueLogHelper.CheckForDatabaseErrors(deleteResults, 'BatchableSch_LeadDeletion', 'execute', true);
    }
    
    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // NO FINISH LOGIC
    }


}