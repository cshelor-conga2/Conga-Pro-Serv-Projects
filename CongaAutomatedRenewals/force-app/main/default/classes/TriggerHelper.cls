/**
* @author Conga Services
* @date 20170509
* @version 2.00, Modified to use Custom Metadata instead of a Custom Setting
* @version 3.00, Modified to use additional Custom Metadata fields and enable Apex performance auditing
* @description This class utilizes the Trigger_Factory_Control__mdt custom metadata to determine what trigger functionality should be executed
*/
public class TriggerHelper {
    private static Boolean OVERRIDE_TRIGGERHELPER = false;
    private static Boolean OVERRIDE_TRIGGERHELPER_VALUE = true;
    public static Map<String, Boolean> CachedTriggerControls {get;set;}
    public static Map<String, Boolean> CachedAuditControls {get;set;}

    /**
    * @description InitializeCache -  Loads trigger settings from Trigger_Factory_Control__mdt custom metadata 
    * @return void
    */
    private static void InitializeCache(){
        if(CachedTriggerControls == null || CachedAuditControls == null){
            CachedTriggerControls = new Map<String, Boolean>();
            CachedAuditControls = new Map<String, Boolean>();
            for(Trigger_Factory_Control__mdt control : [SELECT Label, Class_Name__c, Method_Name__c, Enabled__c, Enable_Auditing__c FROM Trigger_Factory_Control__mdt]){
                CachedTriggerControls.put((control.Class_Name__c + '.' + control.Method_Name__c), control.Enabled__c);
                CachedAuditControls.put((control.Class_Name__c + '.' + control.Method_Name__c), control.Enable_Auditing__c);
            }
        }
    }

    /**
    * @description DoExecute - Compare trigger method key to cached trigger settings and allow or block execution
    * @param className - The name of the Apex Class containing the Method being executed
    * @param methodName - The name of the Apex Method being executed   
    * @return Boolean if to execute code
    */
    //// NEWER VERSION
    public static Boolean DoExecute(String className, String methodName){
        if(OVERRIDE_TRIGGERHELPER){return OVERRIDE_TRIGGERHELPER_VALUE;}
        InitializeCache();
        String key = className + '.' + methodName;
        if(CachedTriggerControls.containsKey(key) && CachedTriggerControls.get(key)){
            if(CachedAuditControls.containsKey(key) && CachedAuditControls.get(key)){
                ApexAuditHelper.startAudit(className, methodName);
            }
            return true;
        }
        return false;
    }
    //// OLDER VERSION FOR BACK COMPATIBILITY
    //public static Boolean DoExecute(String key){
    //    if(OVERRIDE_TRIGGERHELPER){return OVERRIDE_TRIGGERHELPER_VALUE;}
    //    InitializeCache();
    //    if(CachedTriggerControls.containsKey(key)){
    //        return CachedTriggerControls.get(key);
    //    }
    //    return false;
    //}

    /**
    * @description EndExecute - Method that performs logic that needs to occurs after a trigger method is done executing.
    * @param className - The name of the Apex Class containing the Method being executed
    * @param methodName - The name of the Apex Method being executed
    * @return void
    */
    public static void EndExecute(String className, String methodName){
        InitializeCache();
        String key = className + '.' + methodName;

        if(CachedAuditControls.containsKey(key) && CachedAuditControls.get(key)){
            ApexAuditHelper.stopAudit(className, methodName);
        }
    }

    /**
    * @description TemporaryOverride - Override the custom setting value for within the scope of the execution context    
    * @param key - the key of the name on the CS_Trigger_Setting__c table
    * @param value - the value to overide the setting with within the execution context
    * @return void
    */
    //// NEWER VERSION
    public static void TemporaryOverride(String className, String methodName, Boolean value){
        InitializeCache();
        CachedTriggerControls.put((className + '.' + methodName), value);
    }
    //// OLDER VERSION FOR BACK COMPATIBILITY
    //public static void TemporaryOveride(String key, Boolean value){
    //    InitializeCache();
    //    CachedTriggerControls.put(key, value);
    //}

    /**
    * @description OverrideAllSettings - Override all custom setting values - USEFUL FOR TESTING UTILITY WHEN ALL TRIGGER FUNCTIONALITY NEEDS TO BE DISABLED
    * @param pTurnOverrideOn - turn overriding all Trigger Setting values on/off
    * @param pValueToOverrideWith - when pTurnOverrideOn is true the value to return when DoExecute is called
    * @return void
    */
    public static void OverrideAllSettings(Boolean pTurnOverrideOn, Boolean pValueToOverrideWith){
        OVERRIDE_TRIGGERHELPER = pTurnOverrideOn;
        OVERRIDE_TRIGGERHELPER_VALUE = pValueToOverrideWith;
    } 
    //public static void OverideAllSettings(Boolean pTurnOverrideOn, Boolean pValueToOverideWith){
    //    OVERRIDE_TRIGGERHELPER = pTurnOverrideOn;
    //    OVERRIDE_TRIGGERHELPER_VALUE = pValueToOverideWith;
    //} 


}