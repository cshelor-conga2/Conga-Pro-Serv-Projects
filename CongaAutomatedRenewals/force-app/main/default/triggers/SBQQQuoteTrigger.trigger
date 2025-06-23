/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @param SalesforceOrgTrigger - All events trigger for the SBQQ__Quote__c sobject
*/ 
trigger SBQQQuoteTrigger on SBQQ__Quote__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(SBQQ__Quote__c.sObjectType);
}