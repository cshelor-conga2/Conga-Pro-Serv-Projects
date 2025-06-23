/**
* @author Conga Services, ERedding
* @date 20181221
* @version 1.00
* @description TaskHelperTest - Test class for the TaskHelper class
*/
@isTest
public without sharing class TaskHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        Account testAccount = new Account(
            Name = 'TEST INC',
            Account_Expiration_Date_WFR__c = date.today(),
            BillingStreet = '123 Test Inc St',
            BillingCity = 'Indianapolis',
            BillingState = 'IN',
            BillingPostalCode = '46220',
            BillingCountry = 'United States',
            Conga_Subscription_Expiration_Date__c = date.today() - 1
        );
        insert testAccount;

        Case testCase = new Case(Status = 'Closed', Type = 'Customer', Origin = 'Email', Type_APXT__c = 'Setup', AccountId = testAccount.Id);
        insert testCase;

        Lead testLead = new Lead(LastName = 'Test', Status = 'Open', Company = 'Test');
        insert testLead;
    }


    /**
    * @description processCampaignAttributionTest - Test method for the TaskHelper.processCampaignAttribution trigger method
    */
    public static testMethod void processCampaignAttributionTest() {
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User tm1 = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Terr', LastName = 'Person1', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise', Team__c = 'Sales', Attribution_Department__c = 'TM');
        insert tm1;
        User tm2 = new User(Alias = 'admin2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Terr', LastName = 'Person2',
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Mid Commercial', Team__c = 'Customer Success', Attribution_Department__c = 'SDR');
        insert tm2;

        // CREATE TEST TASKS
        List<Task> testTasks = TestingUtility.createSObjectList('Task', false, 2);
        testTasks[0].OwnerId = tm1.Id;
        testTasks[0].Type = 'Email';
        testTasks[0].Subject = 'Reply:';
        //
        testTasks[1].OwnerId = tm2.Id;
        testTasks[1].Type = 'Call';
        testTasks[1].Subject = 'RE:';
        insert testTasks;

        ///// NO ASSERTS. NO LOGIC TO TEST. METHOD PASSES QUALIFYING TASKS OFF TO THE CampaignAttributionHelper WHICH WILL HAVE ITS OWN TESTS /////
    }

    /**
    * @description updateParentRecordActivityStatsTest_Lead - Test method for the TaskHelper.updateParentRecordActivityStats trigger method
    */
    public static testMethod void updateParentRecordActivityStatsTest_Lead() {
        // GET TEST LEAD
        List<Lead> testLeads = [SELECT Id FROM Lead];
        System.assert(testLeads.size() == 1);

        // CREATE TEST TASK
        Task testTask = new Task(Status = 'Not Started', WhoId = testLeads[0].Id,  Subject = 'Test', Priority = 'Normal', ActivityDate = Date.today().addDays(-3));
        insert testTask;

        Test.startTest();

        // CREATE TASK, UPDATE LEAD AND TEST FOR CORRECT DATA
        testLeads = [SELECT Id, Completed_Activities__c, Last_Activity_Date__c, FPR__c FROM Lead WHERE Id = :testLeads];
        System.assert(testLeads[0].Completed_Activities__c == null);
        System.assert(testLeads[0].Last_Activity_Date__c == null);
        System.assert(testLeads[0].FPR__c == null);

        // COMPLETE TASK AND RETEST
        testTask.Status = 'In Progress';
        update testTask;
        testLeads = [SELECT Id, Completed_Activities__c, Last_Activity_Date__c, FPR__c FROM Lead WHERE Id = :testLeads];
        System.assert(testLeads[0].Completed_Activities__c == 0);
        System.assert(testLeads[0].Last_Activity_Date__c == testTask.ActivityDate);
        System.assert(testLeads[0].FPR__c == null);

        // COMPLETE TASK AND RETEST
        testTask.Status = 'Completed';
        testTask.ActivityDate = Date.today();
        update testTask;
        testLeads = [SELECT Id, Completed_Activities__c, Last_Activity_Date__c, FPR__c FROM Lead WHERE Id = :testLeads];
        System.assert(testLeads[0].Completed_Activities__c == 1);
        System.assert(testLeads[0].Last_Activity_Date__c == testTask.ActivityDate);
        System.assert(testLeads[0].FPR__c == null);

        // DELETE TASK AND RETEST
        delete testTask;
        testLeads = [SELECT Id, Completed_Activities__c, Last_Activity_Date__c, FPR__c FROM Lead WHERE Id = :testLeads];
        System.assert(testLeads[0].Completed_Activities__c == 0);
        System.assert(testLeads[0].Last_Activity_Date__c == null);
        System.assert(testLeads[0].FPR__c == null);

        // GET BDR USER
        List<User> bdrUsers = [SELECT Id FROM User WHERE UserRole.Name LIKE 'Business Development Representative%' AND IsActive = true];
        System.assert(!bdrUsers.isEmpty());

        // HAVE AN SDR OR BDR CREATE A TASK        
        Task testTask2 = new Task(Status = 'Completed', WhoId = testLeads[0].Id,  Subject = 'Test', Priority = 'Normal', ActivityDate = Date.today().addDays(-2));
        System.runAs(bdrUsers[0]){
            // CREATE TEST TASK
            insert testTask2;
        }

        // REFRESH TASK
        testTask2 = [SELECT Id, ActivityDate, CompletedDateTime FROM Task WHERE Id = :testTask2.Id];

        testLeads = [SELECT Id, Completed_Activities__c, Last_Activity_Date__c, FPR__c FROM Lead WHERE Id = :testLeads];
        System.assert(testLeads[0].Completed_Activities__c == 1);
        System.assert(testLeads[0].Last_Activity_Date__c == testTask2.ActivityDate);
        System.assert(testLeads[0].FPR__c == testTask2.CompletedDateTime);

        Test.stopTest();
    }

    /**
    * @description setParentOppStageStampTest - Test method for the TaskHelper.setParentOppStageStamp trigger method
    */
    public static testMethod void setParentOppStageStampTest() {
        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1); 
        insert testAccounts;

        // CREATE TEST OPPORTUNITY
        List<Opportunity> testOpps = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpps[0].Name = 'Test Opp';
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].StageName = 'Qualify';
        insert testOpps;

        // CREATE TEST TASK 1
        Task testTask1 = new Task(Status = 'Not Started', WhatId = testOpps[0].Id,  Subject = 'Test Task 1', Priority = 'Normal', ActivityDate = Date.today());
        insert testTask1;

        // RELOAD TEST TASK 1 AND CHECK FOR CORRECT DATA
        testTask1 = [SELECT Id, Opportunity_Stage__c FROM Task WHERE Id = :testTask1.Id];
        System.assert(testTask1.Opportunity_Stage__c == 'Qualify');

        // CHANGE OPP STAGE
        testOpps[0].StageName = 'Solution';
        update testOpps[0];

        // CREATE TEST TASK 2
        Task testTask2 = new Task(Status = 'Not Started', WhatId = testOpps[0].Id,  Subject = 'Test Task 1', Priority = 'Normal', ActivityDate = Date.today());
        insert testTask2;

        // RELOAD TEST TASK 2 AND CHECK FOR CORRECT DATA
        testTask2 = [SELECT Id, Opportunity_Stage__c FROM Task WHERE Id = :testTask2.Id];
        System.assert(testTask2.Opportunity_Stage__c == 'Solution');
    }

    /**
    * @description updateParentRecordActivityStatsTest_Case - Test method for the TaskHelper.updateParentRecordActivityStats trigger method
    */
    public static testMethod void updateParentRecordActivityStatsTest_Case() {
        // GET TEST LEAD
        List<Case> testCases = [SELECT Id FROM Case];
        System.assert(testCases.size() == 1);

        // CREATE TEST TASK
        Task testTask = new Task(Status = 'Not Started', WhatId = testCases[0].Id,  Subject = 'Test', Priority = 'Normal', ActivityDate = Date.today().addDays(-3));

        Test.startTest();

        // CREATE TASK, UPDATE CASE AND TEST FOR CORRECT DATA
        insert testTask;
        testCases = [SELECT Id, Completed_Activities__c, Last_Activity__c FROM Case WHERE Id = :testCases];
        System.assert(testCases[0].Completed_Activities__c == null);
        System.assert(testCases[0].Last_Activity__c == null);

        // UPDATE TASK STATUS AND RETEST
        testTask.Status = 'In Progress';
        update testTask;
        testCases = [SELECT Id, Completed_Activities__c, Last_Activity__c FROM Case WHERE Id = :testCases];
        System.assert(testCases[0].Completed_Activities__c == 0);
        System.assert(testCases[0].Last_Activity__c == testTask.ActivityDate);

        // COMPLETE TASK AND RETEST
        testTask.Status = 'Completed';
        testTask.ActivityDate = Date.today();
        update testTask;
        testCases = [SELECT Id, Completed_Activities__c, Last_Activity__c FROM Case WHERE Id = :testCases];
        System.assert(testCases[0].Completed_Activities__c == 1);
        System.assert(testCases[0].Last_Activity__c == testTask.ActivityDate);

        // CREATE ANOTHER TASK THAT IS MARKED COMPLETED RIGHT AWAY. UPDATE CASE AND TEST FOR CORRECT DATA
        Task testTask2 = new Task(Status = 'Completed', WhatId = testCases[0].Id,  Subject = 'Test 2', Priority = 'Normal', ActivityDate = Date.today());
        insert testTask2;
        testCases = [SELECT Id, Completed_Activities__c, Last_Activity__c FROM Case WHERE Id = :testCases];
        System.assert(testCases[0].Completed_Activities__c == 2);
        System.assert(testCases[0].Last_Activity__c == testTask2.ActivityDate);

        // DELETE TASK AND RETEST
        delete testTask;
        testCases = [SELECT Id, Completed_Activities__c, Last_Activity__c FROM Case WHERE Id = :testCases];
        System.assert(testCases[0].Completed_Activities__c == 1);
        System.assert(testCases[0].Last_Activity__c == testTask2.ActivityDate);

        Test.stopTest();
    }


}