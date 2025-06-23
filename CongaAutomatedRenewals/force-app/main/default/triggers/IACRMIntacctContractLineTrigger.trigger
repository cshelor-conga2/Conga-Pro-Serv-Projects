/**
 * @author Conga Services, GModica
 * @date 20181205
 * @version 1.0
 * @description IACRMIntacctContractLineTrigger - All events trigger for the ia_crm__Intacct_Contract_Line__c sobject 
*/ 
trigger IACRMIntacctContractLineTrigger on ia_crm__Intacct_Contract_Line__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(ia_crm__Intacct_Contract_Line__c.sObjectType);
}