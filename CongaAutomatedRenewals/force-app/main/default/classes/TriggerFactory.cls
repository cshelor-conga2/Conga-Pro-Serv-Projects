/**
* @author Conga Services
* @date 20170509
* @version 1.00
* @description This factory creates the correct dispatcher and dispatches the trigger event(s) to the appropriate 
*              event handler(s). The dispatchers are automatically created using the Type API, hence dispatcher 
*              registration is not required for each dispatchers.
*/
public class TriggerFactory{

    /**
    * @description Add an "object name to class name mapping" if the object name is long and would result in a dispatcher class name over 40 characters in length.
    */
    private static Map<String, String> LongObjectNameDispatchers = new Map<String, String>{
        'ObjectName' => 'ClassName' // EXAMPLE
    };

    /**
    * @description Creates the appropriate dispatcher and dispatches the trigger event to the dispatcher's event handler method.
    * @param Schema.sObjectType Object type to process (SObject.sObjectType)
    * @return void
    */
    public static void createTriggerDispatcher(Schema.sObjectType soType){
        // GET DISPATCHER
        ITriggerDispatcher dispatcher = getTriggerDispatcher(soType);
        if (dispatcher == null){
            throw new TriggerException('No Trigger dispatcher registered for SObject Type: ' + soType);
        }

        // EXECUTE DISPATCHER
        execute(dispatcher);
    }

    /** 
    * @description Dispatches to the dispatcher's event handlers.
    * @param ITriggerDispatcher A Trigger dispatcher that dispatches to the appropriate handlers
    * @return void
    */
    @testVisible
    private static void execute(ITriggerDispatcher dispatcher){
        TriggerParameters tp = new TriggerParameters(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap,
                                    Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, 
                                    Trigger.isUndelete, Trigger.isExecuting);

        // HANDLE BEFORE TRIGGER EXECUTION
        if(Trigger.isBefore){

            // BULKIFICATION LOGIC AS TRIGGER EXECUTION STARTS
            dispatcher.bulkBefore(tp);

            // RUN BEFORE TRIGGER
            if(Trigger.isDelete)
                dispatcher.beforeDelete(tp);
            else if (Trigger.isInsert)
                dispatcher.beforeInsert(tp);
            else if (Trigger.isUpdate)
                dispatcher.beforeUpdate(tp);
        }
        // HANDLE AFTER TRIGGER EXECUTION
        else{

            // RUN AFTER TRIGGER
            if (Trigger.isDelete)
                dispatcher.afterDelete(tp);
            else if (Trigger.isInsert)
                dispatcher.afterInsert(tp);
            else if (Trigger.isUpdate)
                dispatcher.afterUpdate(tp);
            else if (Trigger.isUndelete)
                dispatcher.afterUndelete(tp);

            // BULKIFICATION LOGIC AS TRIGGER EXECUTION ENDS
            dispatcher.bulkAfter(tp);

            // FINAL LOGIC
            dispatcher.andFinally();          
        }
    }

    /**
    * @description Gets the appropriate dispatcher based on the SObject. It constructs the instance of the dispatcher dynamically using the Type API
    *              OR from the LongObjectNameDispatchers map if the object name is long and would result in a class name over 40 characters in length.
    *              The name of the dispatcher has to follow this format: <SObjectName>Dispatcher. 
    *              For e.g. for the Feedback__c object, the dispatcher has to be named as FeedbackDispatcher.
    * @param Schema.sObjectType Object type to create the dispatcher
    * @return ITriggerDispatcher A trigger dispatcher if one exists or null.
    */
    @testVisible
    private static ITriggerDispatcher getTriggerDispatcher(Schema.sObjectType soType){
        String objectName = soType.getDescribe().getName();

        // GET DISPATCHER NAAME FROM LONG OBJECT DISPATCHER MAP -OR- BUILD THE NAME DYNAMICALLY
        String dispatcherTypeName;
        if(LongObjectNameDispatchers.containsKey(objectName)){
            dispatcherTypeName = LongObjectNameDispatchers.get(objectName);
        }
        else{
            dispatcherTypeName = objectName;
            dispatcherTypeName = dispatcherTypeName.removeEnd('__e'); // event objects
            dispatcherTypeName = dispatcherTypeName.removeEnd('__c'); // custom objects
            dispatcherTypeName = dispatcherTypeName.replace('__', ''); // for namespace
            dispatcherTypeName = dispatcherTypeName.replace('_', '');
            dispatcherTypeName = dispatcherTypeName + 'Dispatcher';            
        }

        // GET DISPATCHER
        Type obType = Type.forName(dispatcherTypeName);
        ITriggerDispatcher dispatcher = (obType == null) ? null : (ITriggerDispatcher)obType.newInstance();
        return dispatcher;
    }


}