/**
* @author Conga Services
* @date 20181205
* @version 1.0
* @description MilestoneTrigger - All events trigger for the Milestone__c sobject 
*/ 
trigger MilestoneTrigger on Milestone__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Milestone__c.sObjectType);
}