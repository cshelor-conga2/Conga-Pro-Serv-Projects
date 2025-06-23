/**
* @author ECS, ERedding
* @date 20190906
* @version 1.00
* @description BatchableSch_MQLQualificationTest - Test class for the BatchableSch_MQLQualification class
*/
@isTest
public with sharing class BatchableSch_MQLQualificationTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setupTestData(){
        // GET LEAD MANAGER USER
        List<User> leadManager = [SELECT Id FROM User WHERE FirstName = 'Lead' AND LastName = 'Manager' LIMIT 1];
        System.assert(leadManager.size() == 1);

        // CREATE CUSTOM SETTING
        LMA_Lead_Owner_Round_Robin__c testSetting = new LMA_Lead_Owner_Round_Robin__c(Name = 'TestSetting', Lead_Owner_Id__c = leadManager[0].Id, Round_Robin_Number__c = 0);
        insert testSetting;
    }

    /**
    * @description executeTest - Test the Batchable portion of the Batchable/Schedulable class
    */
    public static testMethod void batachableTest(){
        // GET MQL QUEUE
        List<Group> mqlQueue = [SELECT Id FROM Group WHERE DeveloperName = 'MQL_Queue' AND Type = 'Queue' LIMIT 1];
        System.assert(mqlQueue.size() == 1, 'No MQL Queue has been created in the Org');
        LeadHelperTest.MQLQueueId = mqlQueue[0].Id;

        // CREATE TEST LEAD
        Lead testLead = new Lead(LastName = 'TestLead1', Company = 'Acme', LeadSource = 'AppExchange', Status = 'New', OwnerId = mqlQueue[0].Id);
        Lead testLead2 = new Lead(LastName = 'TestLead2', Company = 'Acme', LeadSource = 'AppExchange', Status = 'Open', OwnerId = mqlQueue[0].Id);
        insert new List<Lead>{ testLead, testLead2 };

        // UPDATE LEAD OWNER TO CURRENT USER AND CHANGE THE STATUS TO AN MQL APPLICABLE ONE 
        testLead.OwnerId = UserInfo.getUserId();
        testLead.Status = 'Prospect';
        update testLead;

        Test.startTest();

        BatchableSch_MQLQualification batchClass = new BatchableSch_MQLQualification();
        Database.executeBatch(batchClass, 20);

        Test.stopTest();

        ///////// LEAD HISTORY RECORDS ARE NOT CREATED DURING TESTS SO "SEND BACK TO MQL QUEUE" AND "MERGED LEAD" PARTS OF CLASS CANNOT BE TESTED ////////

        // TEST THAT LEAD #2 WAS GIVEN AN ENGAGIO VALUE
        testLead2 = [SElECT Id, engagio__EngagementMinutesLast3Months__c FROM Lead WHERE Id = :testLead2.Id];
        System.assert(testLead2.engagio__EngagementMinutesLast3Months__c == 10);
    }

    /**
    * @description schedulableTest - Test the Schedulable portion of the Batchable/Schedulable class
    */
    public static testMethod void schedulableTest(){
        Test.startTest();        

        System.schedule('mqlQualificationTest', '0 0 0 1 1 ? 2025', new BatchableSch_MQLQualification());

        Test.stopTest();
    }


}