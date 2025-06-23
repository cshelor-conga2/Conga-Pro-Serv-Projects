/**
* @author Conga Services
* @date 20181205
* @version 1.0
* @description ProjectTeamTrigger - All events trigger for the Project_Team__c sobject 
*/ 
trigger ProjectTeamTrigger on Project_Team__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Project_Team__c.sObjectType);
}