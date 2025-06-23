/**
 * @author Conga Services, GModica
 * @date 20181205
 * @version 1.0
 * @description IACRMProjectTrigger - All events trigger for the ia_crm__Project__c sobject 
*/ 
trigger IACRMProjectTrigger on ia_crm__Project__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(ia_crm__Project__c.sObjectType);
}