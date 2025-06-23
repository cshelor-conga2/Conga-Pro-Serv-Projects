/**
* @author ECS, ERedding
* @date 20190603
* @version 1.00
* @description PartnerProfileHelperTest - Test class for the PartnerProfileHelper class
*/
@isTest
public with sharing class PartnerProfileHelperTest {

    /**
    * @date 20200116    
    * @description updatePartnerProfileNameTest - Test updatePartnerProfileName trigger method
    */
    static testMethod void updatePartnerProfileNameTest() {
        // CREATE TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account');
        testAccount.Name = 'Test Account';
        insert testAccount;

        // GET PARTNER PROFILE RECORD TYPES
        Map<String, Id> parterProfileRecordTypes = UtilityClass.getRecordTypesForObject('Partner_Profile__c');

        Test.startTest();

        Partner_Profile__c testPartnerProfile = new Partner_Profile__c();
        testPartnerProfile.Name = 'Test Parter Profile';
        testPartnerProfile.Account__c = testAccount.Id;
        testPartnerProfile.RecordTypeId = parterProfileRecordTypes.get('SI_Partner');
        insert testPartnerProfile;
            
        // REFRESH PARTNER PROFILE AND CHECK FOR CORRECT DATA
        testPartnerProfile = [SELECT Name, RecordTypeId FROM Partner_Profile__c WHERE Id = :testPartnerProfile.Id];
        System.assert(testPartnerProfile.Name == (testAccount.Name + ' - SI Partner'));

        // CHANGE RECORD TYPE
        testPartnerProfile.RecordTypeId = parterProfileRecordTypes.get('VAR_Partner');
        update testPartnerProfile;

        // REFRESH PARTNER PROFILE AND CHECK FOR CORRECT DATA
        testPartnerProfile = [SELECT Name, RecordTypeId FROM Partner_Profile__c WHERE Id = :testPartnerProfile.Id];
        System.assert(testPartnerProfile.Name == (testAccount.Name + ' - VAR Partner'));

        Test.stopTest();
    }

    /**
    * @description updateActivePartnerProfileTest - Test updateActivePartnerProfile trigger method
    */
    static testMethod void updateActivePartnerProfileTest() {
        Account pAccount = new Account();
        Partner_Profile__c pp = new Partner_Profile__c();
        
        pAccount.Name = 'Partner Test Account';
        pAccount.RecordTypeId = '01250000000Dysv';
        pAccount.Type = 'Partner';
        pAccount.Site = 'Placeholder - Main';
        insert pAccount;
            
        pp.Account__c = pAccount.Id;
        insert pp;

        Test.startTest(); 

        update pp;

        Test.stopTest();
    
        // REFRESH ACCOUNT AND CHECK FOR CORRECT DATA
        pAccount = [SELECT Id, Active_Partner_Profile_Record_Id__c, Active_Partner_Profile__c FROM Account WHERE Id = :pAccount.Id];
        System.assert(pAccount.Active_Partner_Profile_Record_Id__c == pp.Id);
        System.assert(pAccount.Active_Partner_Profile__c == pp.Id);
    }


}