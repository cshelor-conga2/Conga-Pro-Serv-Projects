/**
 * @author ECS, ERedding
 * @date 20200501
 * @version 1.00
 * @param Any Platform trigger event for the AccountContactRelation sobject
*/ 
trigger AccountContactRelationTrigger on AccountContactRelation (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
	TriggerFactory.createTriggerDispatcher(AccountContactRelation.sObjectType);
}