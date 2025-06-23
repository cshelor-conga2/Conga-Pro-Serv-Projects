/**
* @author ECS, ERedding
* @date 20200605
* @version 1.00
* @description ContactTriggerHandler - Trigger handler class for the Contact object
*/
public class ContactTriggerHandler extends TriggerHandlerBase{

	//////////////////////////////////////// BEFORE INSERT ////////////////////////////////////////
    /** 
    * @description beforeInsertMainEntry - Called for the first time in the BEFORE INSERT execution context.
    * @description beforeInsertRecursiveEntry - Called for the subsequent times in the BEFORE INSERT execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    public override void beforeInsertMainEntry(TriggerParameters tp) {
        ContactHelper.removeDepartedFromLastName((List<Contact>)tp.newList);
        ContactHelper.validateStateAndCountry((List<Contact>)tp.newList, null);

        // SET OWNER AND/OR FLAG FOR APTTUS SYNC IF APPLICABLE
        ContactHelper.setApttusIntegrationOwner((List<Contact>)tp.newList, null); 
        ContactHelper.setApttusIntegrationStatuses((List<Contact>)tp.newList, null);

        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processContactBeforeChanges((List<Contact>)tp.newList, null);
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
        ContactHelper.removeDepartedFromLastName((List<Contact>)tp.newList);
        ContactHelper.validateStateAndCountry((List<Contact>)tp.newList, (Map<Id, Contact>)tp.oldMap);

        // SET OWNER AND/OR FLAG FOR APTTUS SYNC IF APPLICABLE
        ContactHelper.setApttusIntegrationOwner((List<Contact>)tp.newList, (Map<Id, Contact>)tp.oldMap); 
        ContactHelper.setApttusIntegrationStatuses((List<Contact>)tp.newList, (Map<Id, Contact>)tp.oldMap);

        // SYNC INTACCT FIELDS AFTER ALL OTHER TRIGGER LOGIC HAS EXECUTED
        IntacctFieldSyncHelper.processContactBeforeChanges((List<Contact>)tp.newList, (Map<Id, Contact>)tp.oldMap);        
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
        //ContactHelper.accountABMUpdates((List<Contact>)tp.newList, null);
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
        ContactHelper.addCampaignMembers((Map<Id, Contact>)tp.newMap, (Map<Id, Contact>)tp.oldMap);
        //ContactHelper.accountABMUpdates((List<Contact>)tp.newList, (List<Contact>)tp.oldList);
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
    * @description afterUndeleteMainEntry - Called for the first time in the AFTER DELETE execution context.
    * @description afterUndeleteRecursiveEntry - Called for the subsequent times in the AFTER DELETE execution context.
    * @param TriggerParameters - Trigger context parameters and variables
    * @return void
    */
    //public override void afterUndeleteMainEntry(TriggerParameters tp) { NOT IMPLEMENTED }
    //public override void afterUndeleteRecursiveEntry(TriggerParameters tp) { NOT IMPLEMENTED }


}