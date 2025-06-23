/**
* @author Conga Services
* @date 20180619
* @version 1.0
* @description SupportRequestTrigger - All events trigger for the Support_Request__c sobject 
*/  
trigger SupportRequestTrigger on Support_Request__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete){
    TriggerFactory.createTriggerDispatcher(Support_Request__c.sObjectType);


    ///////////////// CONGA SERVICES ER 20181023 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
    //TriggerDispatcher.execute(Support_Request__c.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
}