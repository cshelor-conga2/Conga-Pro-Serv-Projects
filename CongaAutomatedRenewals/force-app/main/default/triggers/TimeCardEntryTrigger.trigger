/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @param TimeCardEntryTrigger - All events trigger for the Time_Card_Entry__c sobject 
*/ 
trigger TimeCardEntryTrigger on Time_Card_Entry__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Time_Card_Entry__c.sObjectType);
}