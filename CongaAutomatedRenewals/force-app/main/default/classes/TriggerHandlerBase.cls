/**
* @author ECS, ERedding
* @date 20200605
* @version 2.00
* @description This class implements the ITriggerHandler to provide virtual methods for the interface methods
*               so that the trigger handlers need to implement only the method that they have to.
*/
public virtual class TriggerHandlerBase implements ITriggerHandler {

    /** 
    * @description beforeInsertMainEntry - Called for the first time in the BEFORE INSERT execution context.
    * @description beforeInsertInProgressEntry - Called for the subsequent times in the BEFORE INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public virtual void beforeInsertMainEntry(TriggerParameters tp) { }
    public virtual void beforeInsertRecursiveEntry(TriggerParameters tp) { }

    /** 
    * @description beforeUpdateMainEntry - Called for the first time in the BEFORE UPDATE execution context.
    * @description beforeUpdateInProgressEntry - Called for the subsequent times in the BEFORE UPDATE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public virtual void beforeUpdateMainEntry(TriggerParameters tp) { }
    public virtual void beforeUpdateRecursiveEntry(TriggerParameters tp) { }

    /** 
    * @description beforeDeleteMainEntry - Called for the first time in the BEFORE DELETE execution context.
    * @description beforeDeleteInProgressEntry - Called for the subsequent times in the BEFORE DELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public virtual void beforeDeleteMainEntry(TriggerParameters tp) { }
    public virtual void beforeDeleteRecursiveEntry(TriggerParameters tp) { }

    /** 
    * @description afterInsertMainEntry - Called for the first time in the AFTER INSERT execution context.
    * @description afterInsertInProgressEntry - Called for the subsequent times in the AFTER INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public virtual void afterInsertMainEntry(TriggerParameters tp) { }
    public virtual void afterInsertRecursiveEntry(TriggerParameters tp) { }

    /** 
    * @description afterUpdateMainEntry - Called for the first time in the AFTER UPDATE execution context.
    * @description afterUpdateInProgressEntry - Called for the subsequent times in the AFTER UPDATE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public virtual void afterUpdateMainEntry(TriggerParameters tp) { }
    public virtual void afterUpdateRecursiveEntry(TriggerParameters tp) { }

    /** 
    * @description afterDeleteMainEntry - Called for the first time in the AFTER DELETE execution context.
    * @description afterDeleteInProgressEntry - Called for the subsequent times in the AFTER DELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public virtual void afterDeleteMainEntry(TriggerParameters tp){ }
    public virtual void afterDeleteRecursiveEntry(TriggerParameters tp) { }

    /** 
    * @description afterUndeleteMainEntry - Called for the first time in the AFTER UNDELETE execution context.
    * @description afterUndeleteInProgressEntry - Called for the subsequent times in the AFTER UNDELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public virtual void afterUndeleteMainEntry(TriggerParameters tp) { }
    public virtual void afterUndeleteRecursiveEntry(TriggerParameters tp) { }


}