/**
* @author Conga Services
* @date 20170509
* @version 1.00
* @description This class holds the trigger parameters.
*/
public class TriggerParameters {

    /**
    * @description A enum that represents the trigger event.
    */
    public Enum TriggerEvent { beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete }
    
    public TriggerEvent tEvent;
    public List<SObject> oldList { get; private set; }
    public List<SObject> newList { get; private set; }
    public Map<Id, SObject> oldMap { get; private set; }
    public Map<Id, SObject> newMap { get; private set; }
    public String triggerObject { get; private set; }
    public Boolean isExecuting { get; private set; }
    
    /** 
    * @description Constructs the TriggerParameter object.
    * @param List<SObject> pNewList - A list of new or updated records
    * @param List<SObject> pOldList - A list of outdated records
    * @param Map<Id, SObject> pNewMap - A map of updated records
    * @param Map<Id, SObject> pOldMap - A map of outdated records
    * @param Boolean pIsBefore - A flag to indicate 'isBefore' event.
    * @param Boolean pIsAfter - A flag to indicate 'isAfter' event.
    * @param Boolean pIsInsert - A flag to indicate 'isInsert' event.
    * @param Boolean pIsUpdate - A flag to indicate 'isUpdate' event.
    * @param Boolean pIsDelete - A flag to indicate 'isDelete' event.
    * @param Boolean pIsUndelete - A flag to indicate 'isUnDelete' event.
    * @param Boolean pIsExecuting - A flag to indicate 'isExecuting'.
    */
    public TriggerParameters(List<SObject> pNewList, List<SObject> pOldList, Map<Id, SObject> pNewMap, Map<Id, SObject> pOldMap,
                             Boolean pIsBefore, Boolean pIsAfter, Boolean pIsInsert, Boolean pIsUpdate, Boolean pIsDelete, Boolean pIsUndelete, Boolean pIsExecuting){
        this.newList = pNewList;        
        this.oldList = pOldList;
        this.newMap = pNewMap;
        this.oldMap = pOldMap;
        this.triggerObject = UtilityClass.getSObjectTypeName((this.oldList != null && this.oldList.size() > 0) ? this.oldList[0] : this.newList[0]);
        if (pIsBefore & pIsInsert) tEvent = TriggerEvent.beforeInsert;
        else if (pIsBefore && pIsUpdate) tEvent = TriggerEvent.beforeUpdate;
        else if (pIsBefore && pIsDelete) tEvent = TriggerEvent.beforeDelete;
        else if (pIsAfter && pIsInsert) tEvent = TriggerEvent.afterInsert;
        else if (pIsAfter && pIsUpdate) tEvent = TriggerEvent.afterUpdate;
        else if (pIsAfter && pIsDelete) tEvent = TriggerEvent.afterDelete;
        else if (pIsAfter && pIsUndelete) tEvent = TriggerEvent.afterUndelete;
        isExecuting = pIsExecuting;
    }


}