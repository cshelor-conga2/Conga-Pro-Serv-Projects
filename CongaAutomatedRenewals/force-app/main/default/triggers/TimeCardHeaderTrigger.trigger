/**
* @author Conga Services
* @date 20181205
* @version 1.0
* @param TimeCardHeaderTrigger - All events trigger for the Time_Card_Header__c sobject 
*/
trigger TimeCardHeaderTrigger on Time_Card_Header__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Time_Card_Header__c.sObjectType);
}