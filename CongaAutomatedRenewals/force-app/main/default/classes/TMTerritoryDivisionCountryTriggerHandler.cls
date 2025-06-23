/**
* @author ECS, ERedding
* @date 20200611
* @version 1.00
* @description TMTerritoryDivisionCountryTriggerHandler - Trigger handler class for the TM_Territory_Division_Country__c object
*/
public class TMTerritoryDivisionCountryTriggerHandler extends TriggerHandlerBase{

	//////////////////////////////////////// BEFORE INSERT ////////////////////////////////////////
    /** 
    * @description beforeInsertMainEntry - Called for the first time in the BEFORE INSERT execution context.
    * @description beforeInsertRecursiveEntry - Called for the subsequent times in the BEFORE INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void beforeInsertMainEntry(TriggerParameters tp) { 
        TMTerritoryDivisionCountryHelper.checkForExistingUse((List<TM_Territory_Division_Country__c>)tp.newList);
        TMTerritoryDivisionCountryHelper.checkForChildStates((List<TM_Territory_Division_Country__c>)tp.newList);

    }
    //public override void beforeInsertRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }



    //////////////////////////////////////// BEFORE UPDATE ////////////////////////////////////////
    /** 
    * @description beforeUpdateMainEntry - Called for the first time in the BEFORE UPDATE execution context.
    * @description beforeUpdateRecursiveEntry - Called for the subsequent times in the BEFORE UPDATE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void beforeUpdateMainEntry(TriggerParameters tp) { 
        TMTerritoryDivisionCountryHelper.checkForExistingUse((List<TM_Territory_Division_Country__c>)tp.newList);
        TMTerritoryDivisionCountryHelper.checkForChildStates((List<TM_Territory_Division_Country__c>)tp.newList);

     }
    //public override void beforeUpdateRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }



    //////////////////////////////////////// BEFORE DELETE ////////////////////////////////////////
    /** 
    * @description beforeDeleteMainEntry - Called for the first time in the BEFORE DELETE execution context.
    * @description beforeDeleteRecursiveEntry - Called for the subsequent times in the BEFORE DELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    //public override void beforeDeleteMainEntry(TriggerParameters tp) { NOT IMPLEMENTED }
    //public override void beforeDeleteRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }



	//////////////////////////////////////// AFTER INSERT ////////////////////////////////////////
    /** 
    * @description afterInsertMainEntry - Called for the first time in the AFTER INSERT execution context.
    * @description afterInsertRecursiveEntry - Called for the subsequent times in the AFTER INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    //public override void afterInsertMainEntry(TriggerParameters tp) { NOT IMPLEMENTED }
    //public override void afterInsertRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }



    //////////////////////////////////////// AFTER UPDATE ////////////////////////////////////////
    /** 
    * @description afterUpdateMainEntry - Called for the first time in the AFTER UPDATE execution context.
    * @description afterUpdateRecursiveEntry - Called for the subsequent times in the AFTER UPDATE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    //public override void afterUpdateMainEntry(TriggerParameters tp) { NOT IMPLEMENTED }
    //public override void afterUpdateRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }



    //////////////////////////////////////// AFTER DELETE ////////////////////////////////////////
    /** 
    * @description afterDeleteMainEntry - Called for the first time in the AFTER DELETE execution context.
    * @description afterDeleteRecursiveEntry - Called for the subsequent times in the AFTER DELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    //public override void afterDeleteMainEntry(TriggerParameters tp) { NOT IMPLEMENTED }
    //public override void afterDeleteRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }



    //////////////////////////////////////// AFTER UNDELETE ////////////////////////////////////////
    /** 
    * @description afterUndeleteMainEntry - Called for the first time in the AFTER UNDELETE execution context.
    * @description afterUndeleteRecursiveEntry - Called for the subsequent times in the AFTER UNDELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    //public override void afterUndeleteMainEntry(TriggerParameters tp) { NOT IMPLEMENTED }
    //public override void afterUndeleteRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }


}