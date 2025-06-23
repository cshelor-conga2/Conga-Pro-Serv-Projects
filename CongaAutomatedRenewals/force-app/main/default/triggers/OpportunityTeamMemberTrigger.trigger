/**
 * @author ECS, ERedding
 * @date 20191030
 * @version 1.00
 * @param Any Platform trigger event for the OpportunityTeamMember sobject
*/ 
trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
	TriggerFactory.createTriggerDispatcher(OpportunityTeamMember.sObjectType);
}