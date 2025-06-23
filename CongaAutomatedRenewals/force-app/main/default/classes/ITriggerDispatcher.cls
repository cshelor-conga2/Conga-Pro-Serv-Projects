/**
* @author Conga Services
* @date 20170509
* @version 1.00 
* @description Defines the interface for the trigger dispatching architecture.
*/
public interface ITriggerDispatcher {

    /** 
    * @description bulkBefore - Called by the trigger framework to carry out bulk operations BEFORE trigger handlers are executed. 
    * @param TriggerParameters tp - Contains trigger execution parameters
    * @return void
    */
    void bulkBefore(TriggerParameters tp);
    
    /** 
    * @description bulkAfter - Called by the trigger framework to carry out bulk operations AFTER trigger handlers are executed.
    * @param TriggerParameters tp - Contains trigger execution parameters
    * @return void
    */
    void bulkAfter(TriggerParameters tp);

    /** 
    * @description andFinally - Called by the trigger framework to carry out FINAL actions AFTER ALL trigger handlers are executed.
    * @return void
    */
    void andFinally();
    
    /**
    * @description Called by the trigger framework to carry out the actions before the records are inserted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting inserted.
    * @return void
    */
    void beforeInsert(TriggerParameters tp);
    
    /**
    * @description Called by the trigger framework to carry out the actions before the records are updated.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting updated.
    * @return void
    */
    void beforeUpdate(TriggerParameters tp);
    
    /** 
    * @description Called by the trigger framework to carry out the actions before the records are deleted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting deleted.    
    * @return void 
    */
    void beforeDelete(TriggerParameters tp);
    
    /** 
    * @description Called by the trigger framework to carry out the actions after the records are inserted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that got inserted.
    * @return void
    */
    void afterInsert(TriggerParameters tp);
    
    /** 
    * @description Called by the trigger framework to carry out the actions after the records are updated.
    * @param TriggerParameters Contains the trigger parameters which includes the records that got updated.
    * @return void
    */
    void afterUpdate(TriggerParameters tp);
    
    /** 
    * @description Called by the trigger framework to carry out the actions after the records got deleted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that got deleted.
    * @return void
    */
    void afterDelete(TriggerParameters tp);
    
    /** 
    * @description Called by the trigger framework to carry out the actions after the records are undeleted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that got undeleted.
    * @return void
    */
    void afterUndelete(TriggerParameters tp);

}