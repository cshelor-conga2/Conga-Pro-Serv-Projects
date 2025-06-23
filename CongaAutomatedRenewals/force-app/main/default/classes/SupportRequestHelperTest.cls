/**
* @author rbernier, eredding
* @date 20180719
* @description SupportRequestHelperTest - Test class for the SupportRequestHelper class
*/
@isTest
private class SupportRequestHelperTest {

    /**
    * @description setup - Setup test data
    */
    @testSetup
    static void setup(){
        // CREATE TEST ACCOUNTS
        Account testAccount1 = new Account(Name = 'Test', BillingStreet = '390 Interlocken Crescent Suite 500', BillingCity = 'Broomfield', BillingState = 'Colorado', 
                                            BillingPostalCode = '80021', BillingCountry = 'United States');
        insert new List<Account>{ testAccount1 };

        // GET OPP RECORD TYPES
        Map<String, RecordType> opportunityRecordTypeByNameMap = new Map<String,RecordType>();
        for(RecordType recordType : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Opportunity']) {
            opportunityRecordTypeByNameMap.put(recordType.DeveloperName, recordType);
        }
        System.assertNotEquals(null, opportunityRecordTypeByNameMap.get('Direct'), 'Opportunity RecordType "Direct" does not exist');

        // CREATE TEST OPPORTUNITIES
        Opportunity testOpp1 = new Opportunity(Name = 'Direct', AccountId = testAccount1.Id, StageName = 'Qualify', CloseDate = Date.today(), Type = 'New Business',
                                                LeadSource = 'Advertisement', RecordTypeId = opportunityRecordTypeByNameMap.get('Direct').Id, PriceBook2Id = Test.getStandardPricebookId());
        insert new List<Opportunity>{ testOpp1 };

        // CREATE TEST PROJECTS
        PS_Project__c testProject1 = new PS_Project__c(Name = 'Project 1', Is_Active__c = true, AccountId__c = testAccount1.Id, OpportunityId__c = testOpp1.Id);
        PS_Project__c testProject2 = new PS_Project__c(Name = 'Project 2', Is_Active__c = true, AccountId__c = testAccount1.Id, OpportunityId__c = testOpp1.Id);
        insert new List<PS_Project__c>{ testProject1, testProject2 };

        // CREATE TEST MILESTONES
        Milestone__c testMilestone1 = new Milestone__c(Name = 'M1', ProjectId__c = testProject1.Id, PricebookId__c = Test.getStandardPricebookId(), IsActive__c = true, 
                                                        Is_Billable__c = true, Hours_Currently_Budgeted__c = 10, Value_Hourly_Rate__c = 100, Effective_Hourly_Rate__c = 100);
        Milestone__c testMilestone2 = new Milestone__c(Name = 'M2', ProjectId__c = testProject1.Id, PricebookId__c = Test.getStandardPricebookId(), IsActive__c = true,
                                                        Is_Billable__c = true, Hours_Currently_Budgeted__c = 10, Value_Hourly_Rate__c = 100, Effective_Hourly_Rate__c = 100);
        Milestone__c testMilestone3 = new Milestone__c(Name = 'M3', ProjectId__c = testProject2.Id, PricebookId__c = Test.getStandardPricebookId(), IsActive__c = true,
                                                        Is_Billable__c = true, Hours_Currently_Budgeted__c = 10, Value_Hourly_Rate__c = 100, Effective_Hourly_Rate__c = 100);
        insert new List<Milestone__c>{ testMilestone1, testMilestone2, testMilestone3 };

        // CREATE TEST ASSIGNMENTS
        Assignment__c testAssignment1 = new Assignment__c(ProjectId__c = testProject1.Id, MilestoneId__c = testMilestone1.Id);
        insert new List<Assignment__c>{ testAssignment1 };

        // GET SUPPORT REQUESTS RECORD TYPES
        Map<String,RecordType> supportRequestRecordTypeByNameMap = new Map<String,RecordType>();
        for(RecordType recordType : [SELECT Id,DeveloperName FROM RecordType WHERE SObjectType = 'Support_Request__c']) {
            supportRequestRecordTypeByNameMap.put(recordType.DeveloperName,recordType);
        }
        System.assertNotEquals(null, supportRequestRecordTypeByNameMap.get('Salesforce_Support_Request'),'Support_Request__c RecordType "Salesforce_Support_Request" does not exist');

        // CREATE TEST SUPPORT REQUESTS
        Support_Request__c testSR1 = new Support_Request__c(BSI_Project__c = testProject1.Id, Assignment__c = testAssignment1.Id, RecordTypeId = supportRequestRecordTypeByNameMap.get('Salesforce_Support_Request').Id);
        insert new List<Support_Request__c>{ testSR1 };

        // CREATE TEST TIME CARD ENTRIES
        Time_Card_Entry__c testTimeCardEntry1 = new Time_Card_Entry__c(MilestoneId__c = testMilestone1.Id, ProjectId__c = testProject1.Id , Support_RequestId__c = testSR1.Id,
                                                                        Hours_Entered__c = 1, Notes__c = 'Note', EmployeeId__c = UserInfo.getUserId());
        Time_Card_Entry__c testTimeCardEntry2 = new Time_Card_Entry__c(MilestoneId__c = testMilestone2.Id, ProjectId__c = testProject1.Id , Support_RequestId__c = testSR1.Id,
                                                                        Hours_Entered__c = 1, Notes__c = 'Note', EmployeeId__c = UserInfo.getUserId());
        insert new List<Time_Card_Entry__c>{ testTimeCardEntry1, testTimeCardEntry2 };
    }

    /**
    * @description testProjectChange - 
    */  
    static testmethod void testProjectChange() {
        Support_Request__c sr = [SELECT Id, BSI_Project__c, Assignment__c FROM Support_Request__c LIMIT 1];

        List<Time_Card_Entry__c> timeCardEntries = [SELECT Id, MilestoneId__c, MilestoneId__r.Name, ProjectId__c, ProjectId__r.Name FROM Time_Card_Entry__c WHERE Support_RequestId__c = :sr.Id ORDER BY MilestoneId__r.Name];
        System.assertEquals(2, timeCardEntries.size());
        System.assertEquals('Project 1', timeCardEntries[0].ProjectId__r.Name);
        System.assertEquals('M1', timeCardEntries[0].MilestoneId__r.Name);
        System.assertEquals('M2', timeCardEntries[1].MilestoneId__r.Name);

        Assignment__c assignment = [SELECT Id, ProjectId__c, ProjectId__r.Name, MilestoneId__c, MilestoneId__r.Name FROM Assignment__c WHERE Id = :sr.Assignment__c];
        System.assertEquals('Project 1', assignment.ProjectId__r.Name);
        System.assertEquals('M1', assignment.MilestoneId__r.Name);

        PS_Project__c project = [SELECT Id FROM PS_Project__c WHERE Name = 'Project 2'];

        test.startTest();
        sr.BSI_Project__c = project.Id;
        update sr;
        test.stopTest();

        timeCardEntries = [SELECT Id, MilestoneId__c, MilestoneId__r.Name, ProjectId__c, ProjectId__r.Name FROM Time_Card_Entry__c WHERE Support_RequestId__c = :sr.Id ORDER BY MilestoneId__r.Name];
        System.assertEquals(2, timeCardEntries.size());
        System.assertEquals('Project 2', timeCardEntries[0].ProjectId__r.Name);
        System.assertEquals('M3', timeCardEntries[0].MilestoneId__r.Name);
        System.assertEquals('M3', timeCardEntries[1].MilestoneId__r.Name);

        assignment = [SELECT Id, ProjectId__c, ProjectId__r.Name, MilestoneId__c, MilestoneId__r.Name FROM Assignment__c WHERE Id = :sr.Assignment__c];
        System.assertEquals('Project 2', assignment.ProjectId__r.Name);
        System.assertEquals('M3', assignment.MilestoneId__r.Name);
    }
    
    /**
    * @description testProjectChangeWithMostRecent
    */
    static testmethod void testProjectChangeWithMostRecent() {
        Support_Request__c sr = [SELECT Id, BSI_Project__c, Assignment__c FROM Support_Request__c LIMIT 1];
        PS_Project__c project = [SELECT Id FROM PS_Project__c WHERE Name = 'Project 2'];

        Milestone__c testMilestone4 = new Milestone__c(Name = 'M4', ProjectId__c = project.Id, PricebookId__c = Test.getStandardPricebookId(), IsActive__c = true,
                                                        Is_Billable__c = true, Hours_Currently_Budgeted__c = 10, Value_Hourly_Rate__c = 100, Effective_Hourly_Rate__c = 100);
        insert new List<Milestone__c>{ testMilestone4 };

        Test.startTest();
        sr.BSI_Project__c = project.Id;
        update sr;
        Test.stopTest();

        List<Time_Card_Entry__c> timeCardEntries = [SELECT Id, MilestoneId__c, MilestoneId__r.Name, ProjectId__c, ProjectId__r.Name FROM Time_Card_Entry__c 
                                                    WHERE Support_RequestId__c = :sr.Id ORDER BY MilestoneId__r.Name];
        System.assertEquals(2, timeCardEntries.size());
        System.assertEquals('Project 2', timeCardEntries[0].ProjectId__r.Name);
        System.assertEquals('M4', timeCardEntries[0].MilestoneId__r.Name);
        System.assertEquals('M4', timeCardEntries[1].MilestoneId__r.Name);

        Assignment__c assignment = [SELECT Id, ProjectId__c, ProjectId__r.Name, MilestoneId__c, MilestoneId__r.Name FROM Assignment__c WHERE Id = :sr.Assignment__c];
        System.assertEquals('Project 2', assignment.ProjectId__r.Name);
        System.assertEquals('M4', assignment.MilestoneId__r.Name);
    }

    /**
    * @description testProjectChangeWithMostRecent
    */
    static testmethod void testProjectChangeToNull() {
        Support_Request__c sr = [SELECT Id, BSI_Project__c, Assignment__c FROM Support_Request__c LIMIT 1];

        Test.startTest();
        sr.BSI_Project__c = null;
        update sr;
        Test.stopTest();

        // assert that no changes were made
        List<Time_Card_Entry__c> timeCardEntries = [SELECT Id, MilestoneId__c, MilestoneId__r.Name, ProjectId__c, ProjectId__r.Name FROM Time_Card_Entry__c 
                                                    WHERE Support_RequestId__c = :sr.Id order by MilestoneId__r.Name];
        System.assertEquals(2, timeCardEntries.size());
        System.assertEquals('Project 1', timeCardEntries[0].ProjectId__r.Name);
        System.assertEquals('M1', timeCardEntries[0].MilestoneId__r.Name);
        System.assertEquals('M2', timeCardEntries[1].MilestoneId__r.Name);

        Assignment__c assignment = [SELECT Id, ProjectId__c, ProjectId__r.Name, MilestoneId__c, MilestoneId__r.Name FROM Assignment__c WHERE Id = :sr.Assignment__c];
        System.assertEquals('Project 1', assignment.ProjectId__r.Name);
        System.assertEquals('M1', assignment.MilestoneId__r.Name);
    }


}