/**
* @author Conga Services
* @date 20181022
* @version 1.0
* @description This class extends the TriggerDispatcherBase to provide the dispatching functionality for the trigger actions
*               on the object. The event handlers support allowing and preventing actions for reentrant scenarios.
*               This is controlled by the flag isBeforeXxxxx and isAfterXxxxx member variables. These variables need to be set
*               to true before invoking the handlers and set to false after the invocation of the handlers. Resetting is MUST
*               as otherwise unit tests MAY fail. The actual actions should be placed in the handlers (in a separate class).
*/
public class OpportunityLineItemDispatcher extends TriggerDispatcherBase {
    private static OpportunityLineItemTriggerHandler TriggerHandler = new OpportunityLineItemTriggerHandler();
    private static Boolean IsBeforeInsertProcessing = false;
    private static Boolean IsBeforeUpdateProcessing = false;
    private static Boolean IsBeforeDeleteProcessing = false;
    private static Boolean IsAfterInsertProcessing = false;
    private static Boolean IsAfterUpdateProcessing = false;
    private static Boolean IsAfterDeleteProcessing = false;
    private static Boolean IsAfterUndeleteProcessing = false;
    
    /**
    * @return void
    * @description This method is called prior to execution of all before trigger events for this dispatcher. If you want
    *               to load any lookup data or cache the data, then this is the place that you need
    *               to put your code.  (example record type retrival and other SOQL calls)
    */
    public virtual override void bulkBefore(TriggerParameters tp){

        // MARK STARTING DISPATCHER FOR AUDITING
        ApexAuditHelper.StartingDispatcher = 'OpportunityLineItemDispatcher';
    }
    
    /**
    * @description This method is called prior to execution of an after trigger event.
    */
    public virtual override void bulkAfter(TriggerParameters tp){
        // SAVE UPDATED OPP ITEMS
        if(!OpportunityLineItemHelper.OppLineItemsToUpdate.isEmpty()){
            Map<Id, OpportunityLineItem> oppItemsToUpdate = OpportunityLineItemHelper.OppLineItemsToUpdate.deepClone();
            OpportunityLineItemHelper.OppLineItemsToUpdate.clear();

            TriggerHelper.TemporaryOverride('OpportunityLineItemHelper','updateParentOppMRRDates', false); // NO NEED FOR CODE TO RUN, OPPS WILL BE UPDATED BELOW
            TriggerHelper.TemporaryOverride('OpportunityLineItemHelper','overwriteCPQBlockPricingChanges', false); // CODE WILL TRIGGER ITSELF TO RUN, BLOCK RECURSION

            Database.saveResult[] oppItemResults = Database.update(oppItemsToUpdate.values(), false);
            SystemIssueLogHelper.CheckForDatabaseErrors(oppItemResults, 'OpportunityLineItemDispatcher', 'bulkAfter', true);

            TriggerHelper.TemporaryOverride('OpportunityLineItemHelper','updateParentOppMRRDates', true); // REENABLE
            TriggerHelper.TemporaryOverride('OpportunityLineItemHelper','overwriteCPQBlockPricingChanges', true); // REENABLE
        }

        // SAVE UPDATED PARENT OPPS
        if(!OpportunityLineItemHelper.ParentOppsToUpdate.isEmpty()){
            Map<Id, Opportunity> parentOppsToUpdate = OpportunityLineItemHelper.ParentOppsToUpdate.deepClone();
            OpportunityLineItemHelper.ParentOppsToUpdate.clear();

            Database.saveResult[] oppResults = Database.update(parentOppsToUpdate.values(), false);
            SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'OpportunityLineItemDispatcher', 'bulkAfter', true);
        }
    }
    
    /**
    * @description This method is called at the end of everything
    */
    public virtual override void andFinally(){ 

        // COMMIT AUDITS TO DATABASE
        ApexAuditHelper.saveAudits('OpportunityLineItemDispatcher');      
    }
    
    /**
    * @description beforeInsert - Called by the trigger framework to carry out the actions before the records are inserted. If there is an
    *               existing call running on the same context, the rentrant call will utilize the handler that was created
    *               in the original call.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting inserted.
    * @return void
    */
    public virtual override void beforeInsert(TriggerParameters tp) {
        if(!IsBeforeInsertProcessing) {
            IsBeforeInsertProcessing = true;
            execute(TriggerHandler, tp, TriggerParameters.TriggerEvent.beforeInsert);
            IsBeforeInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);
    }

    /**
    * @description beforeUpdate - Called by the trigger framework to carry out the actions before the records are updated. If there is an
    *               existing call running on the same context, the rentrant call will utilize the handler that was created
    *               in the original call.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting updated.
    * @return void
    */
    public virtual override void beforeUpdate(TriggerParameters tp) {
        if(!IsBeforeUpdateProcessing) {
            IsBeforeUpdateProcessing = true;
            execute(TriggerHandler, tp, TriggerParameters.TriggerEvent.beforeUpdate);
            IsBeforeUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeUpdate);
    }
    
    /**
    * @description beforeDelete - Called by the trigger framework to carry out the actions before the records are deleted. If there is an
    *               existing call running on the same context, the rentrant call will utilize the handler that was created
    *               in the original call.
    * @param TriggerParameters Contains the trigger parameters which includes the records that is getting updated.
    * @return void
    */
    /*public virtual override void beforeDelete(TriggerParameters tp) {
        if(!isBeforeDeleteProcessing) {
            isBeforeDeleteProcessing = true;
            //execute(new OpportunityLineItemBeforeDelete(), tp, TriggerParameters.TriggerEvent.beforeDelete);
            isBeforeDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.beforeDelete);
    }*/
    
    /**
    * @description afterInsert - Called by the trigger framework to carry out the actions after the record(s) are created. If there is an
    *               existing call running on the same context, the rentrant call will utilize the handler that was created
    *               in the original call.
    * @param TriggerParameters Contains the trigger parameters which includes the record(s) that got created.
    * @return void
    */
    public virtual override void afterInsert(TriggerParameters tp) {
        if(!IsAfterInsertProcessing) {
            IsAfterInsertProcessing = true;
            execute(TriggerHandler, tp, TriggerParameters.TriggerEvent.afterInsert);
            IsAfterInsertProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);
    }

    /**
    * @description afterUpdate - Called by the trigger framework to carry out the actions after the records are updated. If there is an
    *               existing call running on the same context, the rentrant call will utilize the handler that was created
    *               in the original call.
    * @param TriggerParameters Contains the trigger parameters which includes the record(s) that got updated.
    * @return void  
    */
    public virtual override void afterUpdate(TriggerParameters tp) {
        if(!IsAfterUpdateProcessing) {
            IsAfterUpdateProcessing = true;
            execute(TriggerHandler, tp, TriggerParameters.TriggerEvent.afterUpdate);
            IsAfterUpdateProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUpdate);
    }
    
    /**
    * @description afterDelete - Called by the trigger framework to carry out the actions after the records are deleted. If there is an
    *               existing call running on the same context, the rentrant call will utilize the handler that was created
    *               in the original call.
    * @param TriggerParameters Contains the trigger parameters which includes the record(s) that got updated.
    * @return void  
    */
    public virtual override void afterDelete(TriggerParameters tp) {
        if(!IsAfterDeleteProcessing) {
            IsAfterDeleteProcessing = true;
            execute(TriggerHandler, tp, TriggerParameters.TriggerEvent.afterDelete);
            IsAfterDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterDelete);
    }
    
    /**
    * @description afterUnDelete - Called by the trigger framework to carry out the actions after the records are undeleted. If there is an
    *               existing call running on the same context, the rentrant call will utilize the handler that was created
    *               in the original call.
    * @param TriggerParameters Contains the trigger parameters which includes the record(s) that got updated.
    * @return void  
    */
    /*public virtual override void afterUnDelete(TriggerParameters tp) {
        if(!isAfterUnDeleteProcessing) {
            isAfterUnDeleteProcessing = true;
            //execute(new OpportunityLineItemAfterUnDelete(), tp, TriggerParameters.TriggerEvent.afterUnDelete);
            isAfterUnDeleteProcessing = false;
        }
        else execute(null, tp, TriggerParameters.TriggerEvent.afterUnDelete);
    }*/


}