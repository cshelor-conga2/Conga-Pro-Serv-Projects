/**
* @author Mark Brundege
* @date 20200416
* @version 1.00
* @description EngineeringEventMDTHelper - 
*/
public with sharing class EngineeringEventMDTHelper {
    private static Map<String,List<Engineering_Event_Setting__mdt>> cachedEngineeringEventSettings = new Map<String,List<Engineering_Event_Setting__mdt>>();
    private static List<Engineering_Event_API_Setting__mdt> cachedEngineeringEventsAPISettings = new List<Engineering_Event_API_Setting__mdt>();

    public static List<Engineering_Event_Setting__mdt> getEngineeringEventSettings(String objectName) {
        if(!cachedEngineeringEventSettings.containsKey(objectName)){
            List<Engineering_Event_Setting__mdt> settings = new List<Engineering_Event_Setting__mdt>();
            for(Engineering_Event_Setting__mdt[] events : [SELECT Object_Name__c, Field_Name__c, API_Name__c, Is_External_Id__c 
                                                           FROM Engineering_Event_Setting__mdt where Object_Name__c = :objectName AND Is_Active__c = true]){
                settings.addAll(events);
            }
            cachedEngineeringEventSettings.put(objectName,settings);
        }
        return cachedEngineeringEventSettings.get(objectName);
    }

    public static void setEngineeringEventSettings(String objectName, List<Engineering_Event_Setting__mdt> engineeringEvents){
        List<Engineering_Event_Setting__mdt> newList = new List<Engineering_Event_Setting__mdt>(engineeringEvents);
        cachedEngineeringEventSettings.put(objectName,newList);
    }

    public static List<Engineering_Event_API_Setting__mdt> getEngineeringAPISettings(){
        if(cachedEngineeringEventsAPISettings.isEmpty()){
            for(Engineering_Event_API_Setting__mdt[] settings : [select DeveloperName, Value__c from Engineering_Event_API_Setting__mdt]){
                cachedEngineeringEventsAPISettings.addAll(settings);
            }
        }
        return cachedEngineeringEventsAPISettings;
    }

    public static void setEngineeringAPISettings(List<Engineering_Event_API_Setting__mdt> settings){
        cachedEngineeringEventsAPISettings.clear();
        cachedEngineeringEventsAPISettings.addAll(settings);
    }
    
    public static List<String> createFieldListFromEventSettings(List<Engineering_Event_Setting__mdt> settings) {
        List<String> fields = new List<String>();
        for (Engineering_Event_Setting__mdt setting : settings) {
            fields.add(setting.API_Name__c);
        }
        return fields;
    }


}