/**
* @author Conga Services
* @date 20181024
* @version 1.00
* @description Any Platform trigger event for the SBQQ__QuoteLine__c sobject
*/ 
trigger SBQQQuoteLineTrigger on SBQQ__QuoteLine__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(SBQQ__QuoteLine__c.sObjectType);
}