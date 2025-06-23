/**
* @author Conga Services
* @date 20181019
* @version 1.0
* @param Any platform trigger event for the Contact object
*/
trigger ContactTrigger on Contact (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Contact.sObjectType);

    ///////////////// CONGA SERVICES ER 20181019 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
	//TriggerDispatcher.execute(Contact.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    //if(trigger.isBefore){
    //    if(trigger.isUpdate){
    //    	ContactHelper.addCampaignMembers(trigger.newMap);
    //    }
    //}


}