/**
* @author Conga Services
* @date 20180619
* @version 1.0
* @description SFLMALicenseTrigger - All events trigger for the sfLma__License__c sobject 
*/  
trigger SFLMALicenseTrigger on sfLma__License__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete){
    TriggerFactory.createTriggerDispatcher(sfLma__License__c.sObjectType);


    ///////////////// CONGA SERVICES ER 20181023 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
    //TriggerDispatcher.execute(sfLma__License__c.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
}