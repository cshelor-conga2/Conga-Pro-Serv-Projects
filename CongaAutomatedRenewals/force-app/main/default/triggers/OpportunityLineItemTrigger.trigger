/**
 * @author Conga Services
 * @date 20181022
 * @description OpportunityLineItemTrigger - Any Platform trigger event for the OpportunityLineItem sobject
*/ 
trigger OpportunityLineItemTrigger on OpportunityLineItem (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(OpportunityLineItem.sObjectType);
}