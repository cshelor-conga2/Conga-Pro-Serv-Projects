/**
* @author Conga Services
* @date 20181024
* @version 1.00
* @description SBQQSubscriptionTrigger - Any Platform trigger event for the SBQQ__Subscription__c sobject
*/ 
trigger SBQQSubscriptionTrigger on SBQQ__Subscription__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(SBQQ__Subscription__c.sObjectType);

    ////////////// CONGA SERVICES ER 20181024 - OLD TRIGGER FACTORY DEPRECATED
    //TriggerDispatcher.execute(SBQQ__Subscription__c.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap); // OLD TRIGGER FACTORY
}