/**
* @author Conga Services, ERedding
* @date 20181206
* @version 1.00
* @param SBQQQuoteLineGroupTrigger - All events trigger for the SBQQ__QuoteLineGroup__c sobject
*/ 
trigger SBQQQuoteLineGroupTrigger on SBQQ__QuoteLineGroup__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(SBQQ__QuoteLineGroup__c.sObjectType);
}