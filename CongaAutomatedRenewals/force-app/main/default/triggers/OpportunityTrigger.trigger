/**
 * @author Conga Services
 * @date 20181022
 * @description OpportunityTrigger - Any Platform trigger event for the Opportunity sobject
*/ 
trigger OpportunityTrigger on Opportunity (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Opportunity.sObjectType);
}