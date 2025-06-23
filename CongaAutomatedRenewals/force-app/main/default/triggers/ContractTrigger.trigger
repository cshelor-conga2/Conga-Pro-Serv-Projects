/**
* @author Conga Services
* @date 20181019
* @version 1.0
* @param Any platform trigger event for the Contact object
*/
trigger ContractTrigger on Contract (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Contract.sObjectType);

    ///////////////// CONGA SERVICES ER 20181019 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
    //TriggerDispatcher.execute(Contract.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);


}