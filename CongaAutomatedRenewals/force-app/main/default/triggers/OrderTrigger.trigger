/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @description OrderTrigger - Any Platform trigger event for the Order sobject
*/
trigger OrderTrigger on Order (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Order.sObjectType);

    ///////////////// CONGA SERVICES ER 20181023 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
    //TriggerDispatcher.execute(Order.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
}