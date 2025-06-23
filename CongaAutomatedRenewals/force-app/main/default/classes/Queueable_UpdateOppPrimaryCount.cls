/**
* @author ECS, ERedding
* @date 20190701
* @version 1.00
* @description Queueable_UpdateOppPrimaryCount - Queueable class for updating the Primary Contact count field on Opportunities
*/
public with sharing class Queueable_UpdateOppPrimaryCount implements Queueable {
    public Set<Id> OppIds {get; set;}

    /**
    * @description Queueable_UpdateOppPrimaryCount - Constructor
    * @param Set<Id> opportunityIds - Ids of Opportunities to process
    */
    public Queueable_UpdateOppPrimaryCount(Set<Id> opportunityIds){
        this.OppIds = opportunityIds;
    }

    /**
    * @description execute - Queueable execute method
    */
    public void execute(QueueableContext context){
        try{
            if(!OppIds.isEmpty()){
                AccountContactUtilities.updateCountOfPrimaryContact(OppIds);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('Queueable_UpdateOppPrimaryCount', 'execute', OppIds, ex, true);
        }
    }


}