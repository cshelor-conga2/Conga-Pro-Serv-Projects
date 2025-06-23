/**
* @author ECS, ERedding
* @date 20200611
* @version 1.00
* @description SBQQQuoteLineTriggerHandler - Trigger handler class for the SBQQ__QuoteLine__c object
*/
public class SBQQQuoteLineTriggerHandler extends TriggerHandlerBase{

    //////////////////////////////////////// BEFORE INSERT ////////////////////////////////////////
    /** 
    * @description beforeInsertMainEntry - Called for the first time in the BEFORE INSERT execution context.
    * @description beforeInsertRecursiveEntry - Called for the subsequent times in the BEFORE INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void beforeInsertMainEntry(TriggerParameters tp) {
        SBQQQuoteLineHelper.copyDataFromParentProduct((List<SBQQ__QuoteLine__c>)tp.newList, null);
        SBQQQuoteLineHelper.updateNetTotal((List<SBQQ__QuoteLine__c>)tp.newList, null);
        SBQQQuoteLineHelper.updateOppItemStartEndDates((List<SBQQ__QuoteLine__c>)tp.newList, null);

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
        SBQQQuoteLineHelper.copyDataFromParentProduct((List<SBQQ__QuoteLine__c>)tp.newList, (Map<Id, SBQQ__QuoteLine__c>)tp.oldMap);
        SBQQQuoteLineHelper.updateNetTotal((List<SBQQ__QuoteLine__c>)tp.newList, (Map<Id, SBQQ__QuoteLine__c>)tp.oldMap);
        SBQQQuoteLineHelper.updateOppItemStartEndDates((List<SBQQ__QuoteLine__c>)tp.newList, (Map<Id, SBQQ__QuoteLine__c>)tp.oldMap);

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
    public override void afterInsertMainEntry(TriggerParameters tp) {
        SBQQQuoteLineHelper.calculateDiscounts((List<SBQQ__QuoteLine__c>)tp.newList, null);
        SBQQQuoteLineHelper.updateParentMRRLeapYear((List<SBQQ__QuoteLine__c>)tp.newList, null);

    }
    //public override void afterInsertRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }



    //////////////////////////////////////// AFTER UPDATE ////////////////////////////////////////
    /** 
    * @description afterUpdateMainEntry - Called for the first time in the AFTER UPDATE execution context.
    * @description afterUpdateRecursiveEntry - Called for the subsequent times in the AFTER UPDATE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void afterUpdateMainEntry(TriggerParameters tp) {
        SBQQQuoteLineHelper.calculateDiscounts((List<SBQQ__QuoteLine__c>)tp.newList, (Map<Id, SBQQ__QuoteLine__c>)tp.oldMap);
        SBQQQuoteLineHelper.updateParentMRRLeapYear((List<SBQQ__QuoteLine__c>)tp.newList, (Map<Id, SBQQ__QuoteLine__c>)tp.oldMap);
        SBQQQuoteLineHelper.updateChildOppItemDates((List<SBQQ__QuoteLine__c>)tp.newList, (Map<Id, SBQQ__QuoteLine__c>)tp.oldMap);

    }
    //public override void afterUpdateRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }



    //////////////////////////////////////// AFTER DELETE ////////////////////////////////////////
    /** 
    * @description afterDeleteMainEntry - Called for the first time in the AFTER DELETE execution context.
    * @description afterDeleteRecursiveEntry - Called for the subsequent times in the AFTER DELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void afterDeleteMainEntry(TriggerParameters tp) { 
        SBQQQuoteLineHelper.calculateDiscounts(null, (Map<Id, SBQQ__QuoteLine__c>)tp.oldMap);

    }
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