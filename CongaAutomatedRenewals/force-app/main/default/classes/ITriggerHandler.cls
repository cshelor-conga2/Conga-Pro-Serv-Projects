/**
* @author ECS, ERedding
* @date 20200605
* @version 2.00
* @description Defines the interface for trigger handlers. Logic for the first time events are placed under the MainEntry 
*               method and the logic for the recursive events occurring on the same transaction (reentrant) are placed under 
*               the RecursiveEntry method.
*/
public interface ITriggerHandler {

    /** 
    * @description beforeInsertMainEntry - Called for the first time in the BEFORE INSERT execution context.
    * @description beforeInsertInProgressEntry - Called for the subsequent times in the BEFORE INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    */
    void beforeInsertMainEntry(TriggerParameters tp);
    void beforeInsertRecursiveEntry(TriggerParameters tp);

    /** 
    * @description beforeUpdateMainEntry - Called for the first time in the BEFORE UPDATE execution context.
    * @description beforeUpdateInProgressEntry - Called for the subsequent times in the BEFORE UPDATE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    */
    void beforeUpdateMainEntry(TriggerParameters tp);
    void beforeUpdateRecursiveEntry(TriggerParameters tp);

    /** 
    * @description beforeDeleteMainEntry - Called for the first time in the BEFORE DELETE execution context.
    * @description beforeDeleteInProgressEntry - Called for the subsequent times in the BEFORE DELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    */
    void beforeDeleteMainEntry(TriggerParameters tp);
    void beforeDeleteRecursiveEntry(TriggerParameters tp);

    /** 
    * @description afterInsertMainEntry - Called for the first time in the AFTER INSERT execution context.
    * @description afterInsertInProgressEntry - Called for the subsequent times in the AFTER INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    */
    void afterInsertMainEntry(TriggerParameters tp);
    void afterInsertRecursiveEntry(TriggerParameters tp);

    /** 
    * @description afterUpdateMainEntry - Called for the first time in the AFTER UPDATE execution context.
    * @description afterUpdateInProgressEntry - Called for the subsequent times in the AFTER UPDATE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    */
    void afterUpdateMainEntry(TriggerParameters tp);
    void afterUpdateRecursiveEntry(TriggerParameters tp);

    /** 
    * @description afterDeleteMainEntry - Called for the first time in the AFTER DELETE execution context.
    * @description afterDeleteInProgressEntry - Called for the subsequent times in the AFTER DELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    */
    void afterDeleteMainEntry(TriggerParameters tp);
    void afterDeleteRecursiveEntry(TriggerParameters tp);

    /** 
    * @description afterUndeleteMainEntry - Called for the first time in the AFTER UNDELETE execution context.
    * @description afterUndeleteInProgressEntry - Called for the subsequent times in the AFTER UNDELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    */
    void afterUndeleteMainEntry(TriggerParameters tp);
    void afterUndeleteRecursiveEntry(TriggerParameters tp);

}