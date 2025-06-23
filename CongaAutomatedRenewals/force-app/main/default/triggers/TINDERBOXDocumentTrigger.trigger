/**
* @author ECS, ERedding
* @date 20190612
* @version 1.0
* @param Any platform trigger event for the tinderbox__Document__c object
*/ 
trigger TINDERBOXDocumentTrigger on tinderbox__Document__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(tinderbox__Document__c.sObjectType);
}