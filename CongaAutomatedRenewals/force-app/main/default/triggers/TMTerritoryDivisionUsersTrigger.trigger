/**
* @author ECS, ERedding
* @date 20200124
* @version 1.00
* @param Any Platform trigger event for the TM_Territory_Division_Users__c sobject
*/ 
trigger TMTerritoryDivisionUsersTrigger on TM_Territory_Division_Users__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
	TriggerFactory.createTriggerDispatcher(TM_Territory_Division_Users__c.sObjectType);
}