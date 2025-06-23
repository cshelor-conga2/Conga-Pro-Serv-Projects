/** 
* @author Conga Services, ERedding
* @date 20180920
* @version 1.00
* @description Schedulable_LeadChangeLMAOwner - Schedulable class that finds any Leads owned by the LMA user and changes the owner to the lead default by resaving the leads.
*/
public class Schedulable_LeadChangeLMAOwner implements Schedulable {

    /** 
    * @description execute - What to execute when schedule runs.   '0 0 0/1 1/1 * ? *' = Every hour
    */
    public void execute(SchedulableContext context) {
        try{
            Set<String> ignoredStatuses = new Set<String>{ 'Disqualified', 'Partner Testing', 'Invalid' };
            Set<String> acceptableStatuses = new Set<String>{ 'New', 'Open', 'Nurture', 'Re-Engaged' };
            List<Lead> leadsOwnedByLMA = [SELECT Id, OwnerId, Status FROM Lead WHERE IsConverted = false AND Status NOT IN :ignoredStatuses
                                          AND (Owner.LastName = 'License Management App' OR  (Owner.FirstName = 'Lead' AND Owner.LastName = 'Manager')) LIMIT 100];

            // UPDATE STATUS AND LEAD STATUS REASON IF APPLICABLE
            for(Lead lead : leadsOwnedByLMA){
                if(!acceptableStatuses.contains(lead.Status)){
                    lead.Status = 'Nurture';
                    lead.Lead_Status_Reason__c = 'Unresponsive';
                }
            }

            // REFRESH RECORDS BY SIMPLY SAVING WITHOUT MAKING CHANGES
            if(!leadsOwnedByLMA.isEmpty()){
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = true;
                Database.SaveResult[] updateResults = Database.update(leadsOwnedByLMA, dmo);
                SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'Schedulable_LeadChangeLMAOwner', 'execute', true);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('Schedulable_LeadChangeLMAOwner', 'execute', null, ex, true);
        }
    }


}