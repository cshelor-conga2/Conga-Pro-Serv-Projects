/**
* @author ECS, ERedding
* @date 20190625
* @version 1.00
* @description Schedulable_AutoCloseCasesTest - Test class for the Schedulable_AutoCloseCases class
*/
@isTest
public with sharing class Schedulable_AutoCloseCasesTest {

    /**
    * @description AutoCloseCasesTest - Test Schedulable Auto Close Cases functionality
    */
    public static testMethod void AutoCloseCasesTest() {
        Id csOnDemandRTId = UtilityClass.getRecordTypesForObject('Case').get('CS_On_Demand');

        // CREATE TEST CASES
        List<Case> testCases = TestingUtility.createSObjectList('Case', true, 4);
        testCases[0].Status = 'New';
        testCases[1].Status = 'New';
        testCases[2].Status = 'New';
        testCases[3].Status = 'New';
        testCases[3].RecordTypeId = csOnDemandRTId;
        insert testCases;

        // UPDATE CASE STATUSES TO PENDING CLOSURE
        testCases[1].Status = 'Pending Closure';
        testCases[2].Status = 'Pending Closure';
        testCases[3].Status = 'Pending Closure';
        update testCases;

        Test.startTest();

        List<Case> qualifyingCase = [SELECT Id FROM Case WHERE Status = 'Pending Closure' AND RecordTypeId != :csOnDemandRTId];
        System.assert(qualifyingCase.size() == 2);

        // EXECUTE SCHEDULABLE
        System.schedule('SchedulableAutoCloseCasesTest', '0 0 0 1 1 ? 2025', new Schedulable_AutoCloseCases());

        Test.stopTest();

        // SINCE TEST CODE CANNOT CREATE HISTORY RECORDS, CASES WILL NOT BE UPDATED
        testCases = [SElECT Id, Status FROM Case WHERE Id IN :testCases];
        System.assert(testCases.size() == 4);
        System.assert(testCases[0].Status == 'New');
        System.assert(testCases[1].Status == 'Pending Closure');
        System.assert(testCases[2].Status == 'Pending Closure');
        System.assert(testCases[3].Status == 'Pending Closure');
    }


}