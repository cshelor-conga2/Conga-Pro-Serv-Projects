/**
* @author ECS, ERedding
* @date 20190417
* @version 1.00
* @description CaseTimeEntryHelperTest  - Test class for the CaseTimeEntryHelper class
*/
@isTest
public with sharing class CaseTimeEntryHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 2);
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].mrr_Active_MRR__c = 100.00;     
        testAccounts[1].Name = 'Winterfell Inc.';
        testAccounts[1].mrr_Active_MRR__c = 100.00;
        insert testAccounts;

        // CREATE TEST CONTACTS
        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 1);
        testContacts[0].AccountId = testAccounts[0].Id;
        insert testContacts;

        // GET CASE STANDARD RECORD TYPE
        Id standardRT = UtilityClass.getRecordTypesForObject('Case').get('Standard');

        // CREATE TEST CASES
        List<Case> testCases = (List<Case>)TestingUtility.createSObjectList('Case', true, 1);
        testCases[0].RecordTypeId = standardRT;
        testCases[0].ContactId = testContacts[0].Id;
        testCases[0].AccountId = testAccounts[0].Id;
        testCases[0].Status = 'New';
        insert testCases;
    }
    
    
    /**
    * @description testMethod1 - Test calculateTotalHours trigger method
    */
    public static testMethod void calculateTotalHoursTest() {
        // GET TEST CASES
        List<Case> testCases = [SELECT Id FROM Case];
        System.assert(testCases.size() == 1);

        Test.startTest();

        // CREATE TEST CASE TIME ENTRIES
        List<Case_Time_Entry__c> testCaseTimeEntries = (List<Case_Time_Entry__c>)TestingUtility.createSObjectList('Case_Time_Entry__c', true, 2);
        testCaseTimeEntries[0].CaseId__c = testCases[0].Id;
        testCaseTimeEntries[0].EmployeeId__c = UserInfo.getUserId();
        testCaseTimeEntries[0].Start_Date_Time__c = Datetime.newInstanceGmt(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour(), 0, 0);
        testCaseTimeEntries[0].End_Date_Time__c = Datetime.newInstanceGmt(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour(), 30, 0);
        testCaseTimeEntries[1].CaseId__c = testCases[0].Id;
        testCaseTimeEntries[1].EmployeeId__c = UserInfo.getUserId();
        testCaseTimeEntries[1].Start_Date_Time__c = Datetime.newInstanceGmt(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour(), 0, 0);
        testCaseTimeEntries[1].End_Date_Time__c = Datetime.newInstanceGmt(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour() + 1, 30, 0);
        insert testCaseTimeEntries;

        // REFRESH ENTRY RECORDS AND TEST FOR CORRECT DATA
        testCaseTimeEntries = [SELECT Id, Total_Hours__c, End_Date_Time__c FROM Case_Time_Entry__c WHERE Id IN :testCaseTimeEntries];
        System.assert(testCaseTimeEntries[0].Total_Hours__c == 0.50);
        System.assert(testCaseTimeEntries[1].Total_Hours__c == 1.50);

        // MAKE CHANGES AND UPDATE
        testCaseTimeEntries[0].End_Date_Time__c = testCaseTimeEntries[0].End_Date_Time__c.addMinutes(15);
        testCaseTimeEntries[1].End_Date_Time__c = testCaseTimeEntries[1].End_Date_Time__c.addHours(1);
        update testCaseTimeEntries;

        // REFRESH ENTRY RECORDS AND TEST FOR CORRECT DATA
        testCaseTimeEntries = [SELECT Id, Total_Hours__c FROM Case_Time_Entry__c WHERE Id IN :testCaseTimeEntries];
        System.assert(testCaseTimeEntries[0].Total_Hours__c == 0.75);
        System.assert(testCaseTimeEntries[1].Total_Hours__c == 2.50);

        Test.stopTest();
    }

    /**
    * @description testMethod1 - Test calculateTotalHours trigger method's bad parameter handling
    */
    public static testMethod void calculateTotalHoursTest_Exception() {
        Test.startTest();

        // ATTEMPT EXECUTION OF CODE WITH NULL PARAMETERS
        CaseTimeEntryHelper.calculateTotalHours(null, null);

        // ATTEMPT EXECUTION OF CODE WITH EMPTY LIST PARAMETERS
        CaseTimeEntryHelper.calculateTotalHours(new List<Case_Time_Entry__c>(), new Map<Id, Case_Time_Entry__c>());

        Test.stopTest();
    }


}