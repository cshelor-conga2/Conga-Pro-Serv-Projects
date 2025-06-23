/**
* @author Conga Services
* @date 20181019
* @version 1.0
* @description LeadTrigger - All events trigger for the Lead sobject 
*/
trigger LeadTrigger on Lead (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Lead.sObjectType);


    ///////////////// CONGA SERVICES ER 20181019 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
    //if(Trigger.isBefore && Trigger.isUpdate){
        //TriggerDispatcher.execute(Lead.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        //LeadTriggerHelper.LeadBeforeUpdate(Trigger.newMap);
    //}
    //if(Trigger.isAfter){
        //TriggerDispatcher.execute(Lead.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    //}
}