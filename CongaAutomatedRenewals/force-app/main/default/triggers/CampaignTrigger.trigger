/**
* @author CustomerZero, ERedding
* @date 20210112
* @version 1.00
* @param Any Platform trigger event for the Campaign sobject
*/ 
trigger CampaignTrigger on Campaign (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
	TriggerFactory.createTriggerDispatcher(Campaign.sObjectType);
}