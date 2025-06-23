/**
* @author ECS, ERedding
* @date 20200102
* @version 1.0
* @param After Insert trigger event for the Conga_Grid_Event__e sobject
*/ 
trigger CongaGridEventTrigger on Conga_Grid_Event__e (after insert) {
    TriggerFactory.createTriggerDispatcher(Conga_Grid_Event__e.sObjectType); 
}