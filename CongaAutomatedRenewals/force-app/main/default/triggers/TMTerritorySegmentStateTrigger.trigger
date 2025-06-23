/**
 * @author ECS, ERedding
 * @date 20200218
 * @version 1.00
 * @param Any Platform trigger event for the TM_Territory_Segment_State__c sobject
*/ 
trigger TMTerritorySegmentStateTrigger on TM_Territory_Segment_State__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(TM_Territory_Segment_State__c.sObjectType);
}