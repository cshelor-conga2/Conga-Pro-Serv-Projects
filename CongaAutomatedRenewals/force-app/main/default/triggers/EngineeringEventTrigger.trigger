/**
* @author Jordan Pesusich
* @date 20200317
* @version 1.0
* @param Any platform trigger event for the Contact object
*/
trigger EngineeringEventTrigger on Engineering_Event__e (after insert) {
    TriggerFactory.createTriggerDispatcher(Engineering_Event__e.sObjectType);
}