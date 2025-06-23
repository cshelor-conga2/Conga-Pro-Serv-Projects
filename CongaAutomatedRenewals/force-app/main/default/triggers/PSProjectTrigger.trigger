/**
* @author Conga Services, GModica
* @date 20181205
* @version 1.0
* @description Any Platform trigger event for the PS_Project__c sobject
*/ 
trigger PSProjectTrigger on PS_Project__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(PS_Project__c.sObjectType);
}