/**
* @author Conga Services
* @date 20170509
* @version 2.00
* @description This class implements the ITriggerDispatcher and acts as an adapter to avoid implementing all the ITriggerDispatcher methods.
*/
public virtual class TriggerDispatcherBase implements ITriggerDispatcher {
    private static ITriggerHandler iTriggerHandler;

    /** 
    * @description bulkBefore - Called by the trigger framework to carry out bulk operations BEFORE trigger handlers are executed. 
    * @param TriggerParameters tp - Contains trigger execution parameters
    * @return void
    */
    public virtual void bulkBefore(TriggerParameters tp) {}

    /** 
    * @description bulkAfter - Called by the trigger framework to carry out bulk operations AFTER trigger handlers are executed.
    * @param TriggerParameters tp - Contains trigger execution parameters
    * @return void
    */
    public virtual void bulkAfter(TriggerParameters tp) {}

    /** 
    * @description andFinally - Called by the trigger framework to carry out FINAL actions AFTER ALL trigger handlers are executed.
    * @return void
    */
    public virtual void andFinally() {}

    ////////////////////////////////////////////////////////////////

    /**
    * @description Called by the trigger framework to carry out the actions before the records are inserted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting inserted.
    * @return void
    */
    public virtual void beforeInsert(TriggerParameters tp) {}

    /**
    * @description Called by the trigger framework to carry out the actions before the records are updated.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting updated.
    * @return void
    */
    public virtual void beforeUpdate(TriggerParameters tp) {}

    /** 
    * @description Called by the trigger framework to carry out the actions before the records are deleted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting deleted.    
    * @return void 
    */
    public virtual void beforeDelete(TriggerParameters tp) {}

    /** 
    * @description Called by the trigger framework to carry out the actions after the records are inserted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that got inserted.
    * @return void
    */
    public virtual void afterInsert(TriggerParameters tp) {}

    /** 
    * @description Called by the trigger framework to carry out the actions after the records are updated.
    * @param TriggerParameters Contains the trigger parameters which includes the records that got updated.
    * @return void
    */
    public virtual void afterUpdate(TriggerParameters tp) {}

    /** 
    * @description Called by the trigger framework to carry out the actions after the records got deleted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that got deleted.
    * @return void
    */
    public virtual void afterDelete(TriggerParameters tp) {}

    /** 
    * @description Called by the trigger framework to carry out the actions after the records are undeleted.
    * @param TriggerParameters Contains the trigger parameters which includes the records that got undeleted.
    * @return void
    */
    public virtual void afterUndelete(TriggerParameters tp) {}

    ////////////////////////////////////////////////////////////////

    /**
    * @description Called by the event handlers. If this is the first call in the context, then this method will create a new
    *               instance of the appropriate handler and execute the appropriate MainEntry method. If there is an existing call running
    *               on the same context, then this method will use the existing handler instance created by the original call
    *               and execute the appropriate RecursiveEntry method.
    * @param ITriggerHandler The trigger handler instance. The dispatcher need to pass an instance of the trigger handler, such
    *                           as AccountAfterInsertTriggerHandler if this is the first call in a given context. If it is reentry,
    *                           then the dispatcher will need to pass null.
    * @param TriggerParameters The trigger parameters passed by the framework.
    * @param TriggerParameters.TriggerEvent The trigger event.
    * @return void
    */
    protected void execute(ITriggerHandler handlerInstance, TriggerParameters tp, TriggerParameters.TriggerEvent tEvent) {
        if(handlerInstance != null) {
            iTriggerHandler = handlerInstance;
            if(tEvent == TriggerParameters.TriggerEvent.beforeInsert){
                iTriggerHandler.beforeInsertMainEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.beforeUpdate){
                iTriggerHandler.beforeUpdateMainEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.beforeDelete){
                iTriggerHandler.beforeDeleteMainEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.afterInsert){
                iTriggerHandler.afterInsertMainEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.afterUpdate){
                iTriggerHandler.afterUpdateMainEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.afterDelete){
                iTriggerHandler.afterDeleteMainEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.afterUnDelete){
                iTriggerHandler.afterUndeleteMainEntry(tp);
            }
        }
        else {
            if(tEvent == TriggerParameters.TriggerEvent.beforeInsert){
                iTriggerHandler.beforeInsertRecursiveEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.beforeUpdate){
                iTriggerHandler.beforeUpdateRecursiveEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.beforeDelete){
                iTriggerHandler.beforeDeleteRecursiveEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.afterInsert){
                iTriggerHandler.afterInsertRecursiveEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.afterUpdate){
                iTriggerHandler.afterUpdateRecursiveEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.afterDelete){
                iTriggerHandler.afterDeleteRecursiveEntry(tp);
            }
            else if(tEvent == TriggerParameters.TriggerEvent.afterUnDelete){
                iTriggerHandler.afterUndeleteRecursiveEntry(tp);
            }
        }
    }


}