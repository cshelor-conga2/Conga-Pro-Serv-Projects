/**
* @author ECS, ERedding
* @date 20190627
* @version 1.00
* @param Any Platform trigger event for the Customer_Success__c sobject
*/ 
trigger CustomerSuccessTrigger on Customer_Success__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
	TriggerFactory.createTriggerDispatcher(Customer_Success__c.sObjectType);
}