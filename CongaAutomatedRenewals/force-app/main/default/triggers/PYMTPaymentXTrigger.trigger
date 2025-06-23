/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @description PYMTPaymentXTrigger - Any Platform trigger event for the pymt__PaymentX__c sobject
*/
trigger PYMTPaymentXTrigger on pymt__PaymentX__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(pymt__PaymentX__c.sObjectType);
}