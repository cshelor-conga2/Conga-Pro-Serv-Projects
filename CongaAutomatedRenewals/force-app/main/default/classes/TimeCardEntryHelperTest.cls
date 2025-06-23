/** 
* @author Conga Services, eredding
* @date 20180719
* @version 1.00
* @description TimeCardEntryHelperTest - Test class for the TimeCardEntryHelper class
*/
@isTest
private class TimeCardEntryHelperTest {

    /**
    * @description setup - Setup test data
    */
    @testSetup
    static void setup(){
        Account testAccount = (Account)TestingUtility.createSObject('Account', true, 1);
        testAccount.Name = 'Winterfell Inc.';
        insert testAccount;

        PS_Project__c testProject = (PS_Project__c)TestingUtility.createSObject('PS_Project__c', true, 1);
        testProject.AccountId__c = testAccount.Id;
        testProject.Name = 'Sample Project';
        testProject.Rate__c = 1.0;
        testProject.Is_Active__c = true;
        insert testProject;

        Product2 testProduct = (Product2)TestingUtility.createSObject('Product2', true, 1);
        testProduct.Name = 'prod1';
        testProduct.ProductCode = 'pd1';
        testProduct.LOB__c = 'Services';
        testProduct.FY16_Revenue_Type__c = 'Non-Recurring';
        insert testProduct;

        Milestone__c testMilestone = (Milestone__c)TestingUtility.createSObject('Milestone__c', true, 1);
        testMilestone.Name = 'Sample Milestone 1';
        testMilestone.ProjectId__c = testProject.Id;
        testMilestone.IsActive__c = true;
        testMilestone.Is_Billable__c = true;
        testMilestone.PricebookId__c = Test.getStandardPricebookId();
        testMilestone.Effective_Hourly_Rate__c = 5;
        testMilestone.ProductId__c = testProduct.Id;
        insert testMilestone;
    }

    /**
    * @description rollUpWeeklyHours_TestInsert
    */  
    static testmethod void rollUpWeeklyHours_TestInsert() {
        // GET TEST PROJECTS
        List<PS_Project__c> testProjects = [SELECT Id FROM PS_Project__c];
        System.assert(testProjects.size() == 1);

        // GET TEST MILESTONES
        List<Milestone__c> testMilestones = [SELECT Id FROM Milestone__c];
        System.assert(testMilestones.size() == 1);

        Date thisWeekStart = Date.today().toStartofWeek();
        Date lastWeekStart = thisWeekStart.addDays(-7);

        // CREATE TEST TIME CARD ENTRIES
        Time_Card_Entry__c tce1 = new Time_Card_Entry__c();
        tce1.Notes__c = 'Notes';
        tce1.ProjectId__c = testProjects[0].Id;
        tce1.MilestoneId__c = testMilestones[0].Id;
        tce1.Hours_Entered__c = 8;
        tce1.Date_Entered__c = lastWeekStart.addDays(2);

        Time_Card_Entry__c tce2 = new Time_Card_Entry__c();
        tce2.Notes__c = 'Notes';
        tce2.ProjectId__c = testProjects[0].Id;
        tce2.MilestoneId__c = testMilestones[0].Id;
        tce2.Hours_Entered__c = 4;
        tce2.Date_Entered__c = thisWeekStart.addDays(2);

        Test.startTest();

        insert new List<Time_Card_Entry__c>{ tce1, tce2 };

        // TEST THAT HOURS WERE CALCULATED FROM NEW ENTRY
        testMilestones = [SELECT Id, Hours_This_Week__c, Hours_Last_Week__c FROM Milestone__c WHERE Id IN :testMilestones];
        System.assert(testMilestones.size() == 1);
        System.assert(testMilestones[0].Hours_Last_Week__c == 8);
        System.assert(testMilestones[0].Hours_This_Week__c == 4);

        Test.stopTest();        
    }

    /**
    * @description rollUpWeeklyHours_TestUpdate
    */  
    static testmethod void rollUpWeeklyHours_TestUpdate() {
        // GET TEST PROJECTS
        List<PS_Project__c> testProjects = [SELECT Id FROM PS_Project__c];
        System.assert(testProjects.size() == 1);

        // GET TEST MILESTONES
        List<Milestone__c> testMilestones = [SELECT Id FROM Milestone__c];
        System.assert(testMilestones.size() == 1);

        Date thisWeekStart = Date.today().toStartofWeek();

        // CREATE TEST TIME CARD ENTRY
        Time_Card_Entry__c tce1 = new Time_Card_Entry__c();
        tce1.Notes__c = 'Notes';
        tce1.ProjectId__c = testProjects[0].Id;
        tce1.MilestoneId__c = testMilestones[0].Id;
        tce1.Hours_Entered__c = 6;
        tce1.Date_Entered__c = thisWeekStart.addDays(2);
        insert tce1;

        Test.startTest();

         // TEST THAT HOURS WERE CALCULATED FROM NEW ENTRY
        testMilestones = [SELECT Id, Hours_This_Week__c FROM Milestone__c WHERE Id IN :testMilestones];
        System.assert(testMilestones.size() == 1);
        System.assert(testMilestones[0].Hours_This_Week__c == 6);

        // MODIFY TIME CARD ENTRY
        tce1.Hours_Entered__c = 7;
        update tce1;

        // TEST THAT HOURS WERE RECALCULATED CORRECTLY
        testMilestones = [SELECT Id, Hours_This_Week__c FROM Milestone__c WHERE Id IN :testMilestones];
        System.assert(testMilestones.size() == 1);
        System.assert(testMilestones[0].Hours_This_Week__c == 7);

        Test.stopTest();        
    }   
    
    /**
    * @description rollUpWeeklyHours_TestDelete
    */  
    static testmethod void rollUpWeeklyHours_TestDelete() {
        // GET TEST PROJECTS
        List<PS_Project__c> testProjects = [SELECT Id FROM PS_Project__c];
        System.assert(testProjects.size() == 1);

        // GET TEST MILESTONES
        List<Milestone__c> testMilestones = [SELECT Id FROM Milestone__c];
        System.assert(testMilestones.size() == 1);

        Date thisWeekStart = Date.today().toStartofWeek();
        Date lastWeekStart = thisWeekStart.addDays(-7);

        // CREATE TEST TIME CARD ENTRIES
        Time_Card_Entry__c tce1 = new Time_Card_Entry__c();
        tce1.Notes__c = 'Notes';
        tce1.ProjectId__c = testProjects[0].Id;
        tce1.MilestoneId__c = testMilestones[0].Id;
        tce1.Hours_Entered__c = 8;
        tce1.Date_Entered__c = lastWeekStart.addDays(2);

        Time_Card_Entry__c tce2 = new Time_Card_Entry__c();
        tce2.Notes__c = 'Notes';
        tce2.ProjectId__c = testProjects[0].Id;
        tce2.MilestoneId__c = testMilestones[0].Id;
        tce2.Hours_Entered__c = 4;
        tce2.Date_Entered__c = thisWeekStart.addDays(2);
        insert new List<Time_Card_Entry__c>{ tce1, tce2 };

        Test.startTest();

        // TEST THAT HOURS WERE CALCULATED FROM NEW ENTRIES
        testMilestones = [SELECT Id, Hours_This_Week__c, Hours_Last_Week__c FROM Milestone__c WHERE Id IN :testMilestones];
        System.assert(testMilestones.size() == 1);
        System.assert(testMilestones[0].Hours_Last_Week__c == 8);
        System.assert(testMilestones[0].Hours_This_Week__c == 4);

        // DELETE TIME CARD ENTRY
        delete tce2;

        // TEST THAT HOURS WERE RECALCULATED CORRECTLY
        testMilestones = [SELECT Id, Hours_This_Week__c, Hours_Last_Week__c FROM Milestone__c WHERE Id IN :testMilestones];
        System.assert(testMilestones.size() == 1);
        System.assert(testMilestones[0].Hours_Last_Week__c == 8);
        System.assert(testMilestones[0].Hours_This_Week__c == 0);

        // DELETE TIME CARD ENTRY
        delete tce1;

        // TEST THAT HOURS WERE RECALCULATED CORRECTLY
        testMilestones = [SELECT Id, Hours_This_Week__c, Hours_Last_Week__c FROM Milestone__c WHERE Id IN :testMilestones];
        System.assert(testMilestones.size() == 1);
        System.assert(testMilestones[0].Hours_Last_Week__c == 0);
        System.assert(testMilestones[0].Hours_This_Week__c == 0);

        Test.stopTest();
    }   

    /**
    * @description rollUpWeeklyHours_TestExceptions
    */  
    static testmethod void rollUpWeeklyHours_TestExceptions() {
        // TRY EXECUTING CODE WITH NULL PARAMETERS
        TimeCardEntryHelper.rollUpWeeklyHours(null);
        // TRY EXECUTING CODE WITH EMPTY PARAMETERS
        TimeCardEntryHelper.rollUpWeeklyHours(new List<Time_Card_Entry__c>());
    }


}