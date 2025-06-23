/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_APXT_Redlining_Managed_Cla5kTrigger on APXT_Redlining__Managed_Clause__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(APXT_Redlining__Managed_Clause__c.SObjectType);
}