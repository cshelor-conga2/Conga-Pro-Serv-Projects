/**
* @author Redpoint
* @date 20170928
* @version 1.00
* @description ServiceOrderTrigger  - Update related opportunity when a new service order is created. 
* @note Decided not to use the framework at this time - not much work being done in this trigger
*/
trigger ServiceOrderTrigger on CHANNEL_ORDERS__Service_Order__c (after insert) {

	// TriggerDispatcher.execute(CHANNEL_ORDERS__Service_Order__c.sObjectType, Trigger.new, Trigger.old, 
	// Trigger.newMap, Trigger.oldMap);

	if(Trigger.isAfter){
		List<Id> oppIdsToUpdate = new List<Id>();
		List<Opportunity> oppsToUpdate = new List<Opportunity>();
		List<OpportunityLineItem> lineItemsToUpdate = new List<OpportunityLineItem>();

		for(CHANNEL_ORDERS__Service_Order__c so : Trigger.new){
			if(so.CHANNEL_ORDERS__Related_Opportunity__c != null){
				oppIdsToUpdate.add(so.CHANNEL_ORDERS__Related_Opportunity__c);
			}
		}
	
		if(!oppIdsToUpdate.isEmpty()){
			oppsToUpdate = 	[SELECT Id, Service_Order_Created__c, 
								(SELECT Id, COA_Entered__c FROM OpportunityLineItems) 
							 FROM Opportunity WHERE Id IN: oppIdsToUpdate
							];
		}

		for(Opportunity o : oppsToUpdate){
			o.Service_Order_Created__c = TRUE;
			for(OpportunityLineItem oli : o.OpportunityLineItems){
				oli.COA_Entered__c = Date.today();
				lineItemsToUpdate.add(oli);
			}
		}

		if(!oppsToUpdate.isEmpty()) update oppsToUpdate;
		if(!lineItemsToUpdate.isEmpty()) update lineItemsToUpdate;
	}


}