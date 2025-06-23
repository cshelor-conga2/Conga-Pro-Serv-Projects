/**
* @author Conga Services, ERedding
* @date 20180920
* @version 1.00
* @description Schedulable_LeadChangeLMAOwnerTest - Test class for the Schedulable_LeadChangeLMAOwner class
*/
@isTest
public without sharing class Schedulable_LeadChangeLMAOwnerTest {

    /** 
    * @description setupTestData 
    */
    @testSetup
    public static void setupTestData(){
        // CREATE TEST USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User testUser = new User(Alias = 'standt', Email='salesforce@mailinator.com', EmailEncodingKey='UTF-8', LastName='License Management App', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='testUser' + UserInfo.getOrganizationId() +  '@testorg' + UserInfo.getOrganizationId() +  '.com');
        insert testUser;

        // CREATE TEST LEADS
        List<Lead> testLeads = TestingUtility.createSObjectList('Lead', false, 4);
        testLeads[0].OwnerId = testUser.Id;
        testLeads[0].Status = 'New';
        testLeads[1].OwnerId = testUser.Id;
        testLeads[1].Status = 'Re-Engaged';
        testLeads[2].OwnerId = testUser.Id;
        testLeads[2].Status = 'In Process';
        testLeads[3].OwnerId = testUser.Id;
        testLeads[3].Status = 'Working';
        insert testLeads;
    }

    /**
    * @description Schedulable_LeadChangeLMAOwnerTest -  
    */
    public static testmethod void Schedulable_LeadChangeLMAOwnerTest() {
        // GET TEST USERS
        List<User> testUsers = [SELECT Id, Name FROM User WHERE LastName = 'License Management App' LIMIT 1];
        System.assert(!testUsers.isEmpty());

        Test.startTest();

        Schedulable_LeadChangeLMAOwner testSch = new Schedulable_LeadChangeLMAOwner();
        System.schedule('LMAOwnerScheduleTest', '0 0 0 1 1 ? 2025', testSch);

        Test.stopTest();

        // RELOAD LEADS AND TEST FOR CORRECT DATA
        // CANNOT TEST USER CHANGE AS LEAD ASSIGNMENT RULES DONT RUN IN A TEST
        List<Lead> testLeads = [SELECT Id, OwnerId, Status, Lead_Status_Reason__c FROM Lead];
        System.assert(testLeads.size() == 4);
        System.assert(testLeads[0].Status == 'New');
        System.assert(String.isBlank(testLeads[0].Lead_Status_Reason__c));
        //
        System.assert(testLeads[1].Status == 'Re-Engaged');
        System.assert(String.isBlank(testLeads[1].Lead_Status_Reason__c));
        //
        System.assert(testLeads[2].Status == 'Nurture');
        System.assert(testLeads[2].Lead_Status_Reason__c == 'Unresponsive');
        //
        System.assert(testLeads[3].Status == 'Nurture');
        System.assert(testLeads[3].Lead_Status_Reason__c == 'Unresponsive');
    }


}