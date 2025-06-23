/** 
* @author Conga Services
* @date 
* @version 1.00
* @description Batchable_OpportunityCOA - Batchable/scheduable class for COA creation from opportunities.
*/
public class BatchableSch_OpportunityCOA implements Database.Batchable<sObject>, Schedulable{
	
	/** 
	* @description Scheduable execute method
	*/
   	public void execute(SchedulableContext context) {
	    Database.executeBatch(this, 1); // SPECIFY CHUNK SIZE OF 50
	}
	
	/** 
	* @description Batchable start method
	*/	
	public Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator([SELECT Id, Create_Service_Order__c, Service_Order_Created__c FROM Opportunity WHERE Create_Service_Order__c = true AND Service_Order_Created__c != true]);
	}
	
	/** 
	* @description Batchable execute method
	*/
   	public void execute(Database.BatchableContext context, List<sObject> scope) {
		try{
			Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
			for(Opportunity opp : (List<Opportunity>)scope){
				oppMap.put(opp.Id,opp);
			}
        	OpportunityHandler.closedWonOpportunityPath((Map<Id,Opportunity>)oppMap);
		}
		catch(Exception ex){ 
			SystemIssueLogHelper.LogException('BatchableSch_OpportunityCOA', 'execute', scope, ex, true); // CLASS NAME, METHOD NAME, COLLECTION OF RECORDS, EXCEPTION, DML NOW
		}
	}
	
	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		// FINISH LOGIC
	}
}