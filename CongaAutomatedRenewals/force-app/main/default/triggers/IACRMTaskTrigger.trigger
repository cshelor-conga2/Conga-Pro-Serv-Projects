/**
* @author Conga Services
* @date 20181205
* @version 1.0
* @description IACRMTaskTrigger - All events trigger for the ia_crm__Task__c sobject 
*/ 
trigger IACRMTaskTrigger on ia_crm__Task__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(ia_crm__Task__c.sObjectType);
}