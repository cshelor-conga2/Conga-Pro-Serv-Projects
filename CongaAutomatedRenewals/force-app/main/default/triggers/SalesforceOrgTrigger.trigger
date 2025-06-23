/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @description SalesforceOrgTrigger - All events trigger for the Salesforce_Org__c sobject 
*/ 
trigger SalesforceOrgTrigger on Salesforce_Org__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Salesforce_Org__c.sObjectType);
}