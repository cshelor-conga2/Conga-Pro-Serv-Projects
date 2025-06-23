/**
* @author ECS, ERedding
* @date 20200611
* @version 1.00
* @description SBQQSubscriptionTriggerHandler - Trigger handler class for the SBQQ__Subscription__c object
*/
public class SBQQSubscriptionTriggerHandler extends TriggerHandlerBase{

    //////////////////////////////////////// BEFORE INSERT ////////////////////////////////////////
    /** 
    * @description beforeInsertMainEntry - Called for the first time in the BEFORE INSERT execution context.
    * @description beforeInsertRecursiveEntry - Called for the subsequent times in the BEFORE INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void beforeInsertMainEntry(TriggerParameters tp) {
        SBQQSubscriptionHelper.setUpliftPercentage((List<SBQQ__Subscription__c>)tp.newList);
        SBQQSubscriptionHelper.updateLeapYearFlag((List<SBQQ__Subscription__c>)tp.newList, null);

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
        SBQQSubscriptionHelper.updateLeapYearFlag((List<SBQQ__Subscription__c>)tp.newList, (Map<Id, SBQQ__Subscription__c>)tp.oldMap);

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
        SBQQSubscriptionHelper.calculateTotalDiscount((List<SBQQ__Subscription__c>)tp.newList, null);
        SBQQSubscriptionHelper.calculateOppCurrentAverageMRR((List<SBQQ__Subscription__c>)tp.newList, new Map<Id, SBQQ__Subscription__c>());
        SBQQSubscriptionHelper.calculateMRR((Map<Id, SBQQ__Subscription__c>)tp.newMap, null);

        SBQQSubscriptionHelper.updateAccountCSDivision((List<SBQQ__Subscription__c>)tp.newList); // MUST HAPPEN AFTER calculateMRR

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
        SBQQSubscriptionHelper.calculateOppCurrentAverageMRR((List<SBQQ__Subscription__c>)tp.newList, (Map<Id, SBQQ__Subscription__c>)tp.oldMap);
        SBQQSubscriptionHelper.calculateMRR((Map<Id, SBQQ__Subscription__c>)tp.newMap, (Map<Id, SBQQ__Subscription__c>)tp.oldMap);
        SBQQSubscriptionHelper.calculateTotalDiscount((List<SBQQ__Subscription__c>)tp.newList, (Map<Id, SBQQ__Subscription__c>)tp.oldMap);
        SBQQSubscriptionHelper.updateParentContractDates((List<SBQQ__Subscription__c>)tp.newList, (Map<Id, SBQQ__Subscription__c>)tp.oldMap);

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
        SBQQSubscriptionHelper.calculateTotalDiscount(null, (Map<Id, SBQQ__Subscription__c>)tp.oldMap);
        
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