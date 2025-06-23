/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_ia_crm_Sales_InvoiceTrigger on ia_crm__Sales_Invoice__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(ia_crm__Sales_Invoice__c.SObjectType);
}