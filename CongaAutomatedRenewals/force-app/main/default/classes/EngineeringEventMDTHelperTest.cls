/**
* @author Mark Brundege
* @date 20200416
* @version 1.00
* @description EngineeringEventMDTHelperTest - Test class for the EngineeringEventMDTHelper class
*/
@isTest
public with sharing class EngineeringEventMDTHelperTest {
    
    @isTest static void GetEngineeringEventSettinsReturnsExpectedDataForSalesforceOrg () {
        List<Engineering_Event_Setting__mdt> settings = EngineeringEventMDTHelper.getEngineeringEventSettings('Salesforce_Org__c');
        //System.debug('obtained ' + settings.size() + ' settings for Salesforce_Org__c');
        //System.debug(settings);
        System.assert(settings.size() > 50);
    }
    
    @isTest static void CreateFieldListFromEventSettingsReturnsFields () {
        List<Engineering_Event_Setting__mdt> settings = EngineeringEventMDTHelper.getEngineeringEventSettings('Salesforce_Org__c');
        List<string> fieldList = EngineeringEventMDTHelper.createFieldListFromEventSettings(settings);
        System.assert(settings.size() == fieldList.size());
    }
    
    @isTest static void GetEngineeringApiSettingsReturnsApiSettings () {
        List<Engineering_Event_API_Setting__mdt> apiSettings = EngineeringEventMDTHelper.getEngineeringAPISettings();
        System.assert(apiSettings.size() > 0);
    }
    
    @isTest static void SetEngineeringEventSettingsSetsProvided () {
        List<Engineering_Event_Setting__mdt> inputSettings = new List<Engineering_Event_Setting__mdt>();
        Engineering_Event_Setting__mdt setting1 = new Engineering_Event_Setting__mdt(
            Object_Name__c = 'test1',
            Field_Name__c = 'testfield1',
            API_Name__c = 'testfield1__c',
            Is_External_Id__c = false
        );
        Engineering_Event_Setting__mdt setting2 = new Engineering_Event_Setting__mdt(
            Object_Name__c = 'test2',
            Field_Name__c = 'testfield2',
            API_Name__c = 'testfield2__c',
            Is_External_Id__c = false
        );
        inputSettings.add(setting1);
        inputSettings.add(setting2);
        EngineeringEventMDTHelper.setEngineeringEventSettings('testobj', inputSettings);
        List<Engineering_Event_Setting__mdt> outputSettings = EngineeringEventMDTHelper.getEngineeringEventSettings('testobj');
        System.assert(inputSettings.size() == outputSettings.size());
    }
    
    @isTest static void SetEngineeringEventApiSettingsSetsProvided () {
        List<Engineering_Event_API_Setting__mdt> inputSettings = new List<Engineering_Event_API_Setting__mdt>();
        Engineering_Event_API_Setting__mdt setting1 = new Engineering_Event_API_Setting__mdt(
            DeveloperName = 'dev1',
            Value__c = 'val1'
        );
        Engineering_Event_API_Setting__mdt setting2 = new Engineering_Event_API_Setting__mdt(
            DeveloperName = 'dev2',
            Value__c = 'val2'
        );
        inputSettings.add(setting1);
        inputSettings.add(setting2);
        EngineeringEventMDTHelper.setEngineeringAPISettings(inputSettings);
        List<Engineering_Event_API_Setting__mdt> outputSettings = EngineeringEventMDTHelper.getEngineeringAPISettings();
        System.assert(inputSettings.size() == outputSettings.size());
    }

}