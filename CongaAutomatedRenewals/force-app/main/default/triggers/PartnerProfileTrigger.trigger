/**
* @author ECS, ERedding
* @date 20190603
* @version 1.00
* @description Any Platform trigger event for the Partner_Profile__c sobject
*/ 
trigger PartnerProfileTrigger on Partner_Profile__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
	TriggerFactory.createTriggerDispatcher(Partner_Profile__c.sObjectType);
}