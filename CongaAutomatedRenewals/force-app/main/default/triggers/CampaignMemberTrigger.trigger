/**
* @author Conga Services
* @date 20181019
* @version 1.0
* @param Any platform trigger event for the CampaignMember sobject
*/ 
trigger CampaignMemberTrigger on CampaignMember (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(CampaignMember.sObjectType);

    ///////////////// CONGA SERVICES ER 20181019 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
    //TriggerDispatcher.execute(CampaignMember.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);


}