/**
* @author ECS, ERedding
* @date 20190417
* @version 1.00
* @param Any Platform trigger event for the Case_Time_Entry__c sobject
*/ 
trigger CaseTimeEntryTrigger on Case_Time_Entry__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
	TriggerFactory.createTriggerDispatcher(Case_Time_Entry__c.sObjectType);


}