/**
* @author ECS, ERedding
* @date 20200605
* @version 1.00
* @description AccountTriggerHandler - Trigger handler for the Contact object
*/
public class AccountTriggerHandler extends TriggerHandlerBase{

	//////////////////////////////////////// BEFORE INSERT ////////////////////////////////////////
    /** 
    * @description beforeInsertMainEntry - Called for the first time in the BEFORE INSERT execution context.
    * @description beforeInsertRecursiveEntry - Called for the subsequent times in the BEFORE INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void beforeInsertMainEntry(TriggerParameters tp) {
        AccountHelper.updateShippingAddress((List<Account>)tp.newList, null);        
        AccountHelper.validateStateAndCountry((List<Account>)tp.newList, null); // MUST OCCUR AFTER updateShippingAddress TO ENSURE GOOD STATE AND COUNTRY DATA

        AccountHelper.updateTerritoryManagementFields((List<Account>)tp.newList, null);
        AccountHelper.territoryManagerSync((List<Account>)tp.newList, null);

        // SET OWNER AND/OR FLAG FOR APTTUS SYNC IF APPLICABLE
        AccountHelper.setApttusIntegrationOwner((List<Account>)tp.newList, null); 
        AccountHelper.setApttusIntegrationStatuses((List<Account>)tp.newList, null);   

        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processAccountBeforeChanges((List<Account>)tp.newList, null);
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
        AccountHelper.updateShippingAddress((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);
        AccountHelper.updateAccountIndustry((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);
        AccountHelper.validateStateAndCountry((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap); // MUST OCCUR AFTER updateShippingAddress TO ENSURE GOOD STATE AND COUNTRY DATA

        AccountHelper.updateTerritoryManagementFields((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);
        AccountHelper.validateOwnershipChanges((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);
        AccountHelper.territoryManagerSync((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);

        // FLAG FOR APTTUS SYNC IF APPLICABLE
        AccountHelper.setApttusIntegrationOwner((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap); 
        AccountHelper.setApttusIntegrationStatuses((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);   

        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processAccountBeforeChanges((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);      
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
		AccountHelper.processSegmentAndDivisionChanges((List<Account>)tp.newList, null);
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
        AccountHelper.processSegmentAndDivisionChanges((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);        
        AccountHelper.updateAcctTeamsFromLookups((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);

        AccountHelper.updateOppOnboardingSpecialist((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);
        AccountHelper.copyCSDivisionStampChangesToOpps((List<Account>)tp.newList, (Map<Id,Account>)tp.oldMap);
        AccountHelper.partnerAccountOwnerChange((List<Account>)tp.newList, (Map<Id,Account>)tp.oldMap);
        AccountHelper.updateSubscriptionUpliftData((List<Account>)tp.newList, (Map<Id,Account>)tp.oldMap);
        AccountHelper.updateOppPartnerExpertiseScore((List<Account>)tp.newList, (Map<Id,Account>)tp.oldMap);
        AccountHelper.updateOppCSForecast((List<Account>)tp.newList, (Map<Id,Account>)tp.oldMap);


        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processAccountAfterChanges((List<Account>)tp.newList, (Map<Id, Account>)tp.oldMap);
    }
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