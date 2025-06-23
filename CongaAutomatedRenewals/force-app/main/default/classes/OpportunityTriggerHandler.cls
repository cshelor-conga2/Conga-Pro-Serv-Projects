/**
* @author ECS, ERedding
* @date 20200611
* @version 1.00
* @description OpportunityTriggerHandler - Trigger handler class for the Opportunity object
*/
public class OpportunityTriggerHandler extends TriggerHandlerBase{

	//////////////////////////////////////// BEFORE INSERT ////////////////////////////////////////
    /** 
    * @description beforeInsertMainEntry - Called for the first time in the BEFORE INSERT execution context.
    * @description beforeInsertRecursiveEntry - Called for the subsequent times in the BEFORE INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void beforeInsertMainEntry(TriggerParameters tp) {
        OpportunityHelper.setAmendmentCurrentMRR((List<Opportunity>)tp.newList, null);
        OpportunityHelper.populateSalesforceAcct((List<Opportunity>)tp.newList);
        OpportunityHelper.updateReferringPartnerFields((List<Opportunity>)tp.newList, null);
        
        OpportunityHelper.opportunityFieldUpdates((List<Opportunity>)tp.newList, null);
        OpportunityHelper.updateBookingsOwner((List<Opportunity>)tp.newList, null); // updateBookingsOwner MUST HAPPEN AFTER opportunityFieldUpdates
        OpportunityHelper.setTeamStampFields((List<Opportunity>)tp.newList, null); // setTeamStampFields MUST HAPPEN AFTER updateBookingsOwner
        OpportunityHelper.updateOnboardingSpecialist((List<Opportunity>)tp.newList, null, null); // updateOnboardingSpecialist MUST HAPPEN AFTER setTeamStampFields

        OpportunityHelper.setConvertedOppChannelSource((List<Opportunity>)tp.newList); // setConvertedOppChannelSource MUST HAPPEN AFTER opportunityFieldUpdates
        OpportunityHelper.setOppProductInterest((List<Opportunity>)tp.newList);
        OpportunityHelper.getPrimaryContactFromAcct((List<Opportunity>)tp.newList);
        OpportunityHelper.calculateCSForecast((List<Opportunity>)tp.newList, null);
        OpportunityHelper.updatePurchaseOrderRequired((List<Opportunity>)tp.newList, null);
        //OpportunityHelper.copyPORequiredToParentContract((List<Opportunity>)tp.newList, null);

        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processOpportunityBeforeChanges((List<Opportunity>)tp.newList, null);
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
        // VALIDATION METHODS
        OpportunityHelper.validateOwnershipChanges((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap);
        OpportunityHelper.validateStageChanges((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap);

        // BUSINESS LOGIC METHODS
        OpportunityHelper.setAmendmentCurrentMRR((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap);       
        OpportunityHelper.opportunityFieldUpdates((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap);
        OpportunityHelper.updateBookingsOwner((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap); // updateBookingsOwner MUST HAPPEN AFTER opportunityFieldUpdates
        OpportunityHelper.setTeamStampFields((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap); // setTeamStampFields MUST HAPPEN AFTER updateBookingsOwner
        OpportunityHelper.updateOnboardingSpecialist((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap, null); // updateOnboardingSpecialist MUST HAPPEN AFTER setTeamStampFields    
        OpportunityHelper.createProjectRecord((Map<Id,Opportunity>)tp.newMap, (Map<Id,Opportunity>)tp.oldMap);
        
        OpportunityHelper.updateReferringPartnerFields((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap); // updateReferringPartnerFields MUST HAPPEN AFTER setTeamStampFields
        OpportunityHelper.updatePartnerExpertiseScore((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap);
        OpportunityHelper.calculateCSForecast((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap);
        OpportunityHelper.servicesCommissionRollup((Map<Id, Opportunity>)tp.newMap, (Map<Id, Opportunity>)tp.oldMap);

        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processOpportunityBeforeChanges((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap);
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
        OpportunityHelper.copyPrimaryContactToRoles((List<Opportunity>)tp.newList);      
        OpportunityHelper.setPrimaryContactCount((List<Opportunity>)tp.newList); // setPrimaryContactCount MUST HAPPEN AFTER copyPrimaryContactToRoles  

        OpportunityHelper.setUpOpportunityTeam((List<Opportunity>)tp.newList);

        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processOpportunityAfterChanges((List<Opportunity>)tp.newList, null);
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
        OpportunityHandler.coaTriggerEntryPoint((Map<Id,Opportunity>)tp.newMap);
        OpportunityHelper.createAssetsFromLineItems((List<Opportunity>)tp.newList, (Map<Id,Opportunity>)tp.oldMap);
        OpportunityHelper.createProjectRecord((Map<Id,Opportunity>)tp.newMap, (Map<Id,Opportunity>)tp.oldMap);
        OpportunityHelper.updateChildQuoteOwners((Map<Id,Opportunity>)tp.newMap, (Map<Id,Opportunity>)tp.oldMap);
        OpportunityHelper.updatePurchaseOrderRequired((List<Opportunity>)tp.newList, (Map<Id,Opportunity>)tp.oldMap);
        //OpportunityHelper.copyPORequiredToParentContract((List<Opportunity>)tp.newList, (Map<Id,Opportunity>)tp.oldMap);

        OpportunityHelper.updateOppTeamsFromLookups((List<Opportunity>)tp.newList, (Map<Id,Opportunity>)tp.oldMap);

        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processOpportunityAfterChanges((List<Opportunity>)tp.newList, (Map<Id, Opportunity>)tp.oldMap);
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