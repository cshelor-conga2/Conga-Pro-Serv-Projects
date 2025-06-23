/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @description OrderPaymentTrigger - Any Platform trigger event for the Order_Payment__c sobject
*/ 
trigger OrderPaymentTrigger on Order_Payment__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Order_Payment__c.sObjectType);
}