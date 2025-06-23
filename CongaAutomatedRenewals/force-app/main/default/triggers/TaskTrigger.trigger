/**
* @author Conga Services, ERedding
* @date 20181221
* @version 1.00
* @param TaskTrigger - All events trigger for the Task sobject 
*/ 
trigger TaskTrigger on Task (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Task.sObjectType);
}