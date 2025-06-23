/**
 * @author Conga Services, ERedding
 * @date 20181128
 * @version 1.00
 * @description IACRMSalesInvoiceTrigger - All events trigger for the ia_crm__Sales_Invoice__c sobject 
*/ 
trigger IACRMSalesInvoiceTrigger on ia_crm__Sales_Invoice__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(ia_crm__Sales_Invoice__c.sObjectType);
}