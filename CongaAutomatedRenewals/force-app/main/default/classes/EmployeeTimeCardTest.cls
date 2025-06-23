/**
* @author Systemyc
* @version 1.00
* @description test class for EmployeeTimeCardController class.
*/
@isTest
private class EmployeeTimeCardTest {

    //helper methods
    private static Id insertPeriod(Date pDate)
    {
        Date startDate = pDate.toStartOfWeek();
        Period__c period = new Period__c(
            Name = getPeriodName(pDate),
            Start_Date__c = startDate,
            End_Date__c = startDate.AddDays(6) ,            
            Type__c = 'Week'
        );
        insert period;
        return period.Id;
    }

    private static string getPeriodName(Date pDate)
    {
        return EmployeeTimeCardController.getPeriodName(pDate);
    }
    
    @testSetup 
    static void setup() {

        //insert test periods        
        Id currentPeriodId = insertPeriod(Date.today()); //current period        
        Id previousPeriodId = insertPeriod(Date.today().addDays(-7)); //previous period       
        Id nextPeriodId = insertPeriod(Date.today().addDays(7)); //next period

        //insert client project
        RecordType clientRecordType = [SELECT id FROM RecordType WHERE Id = :Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('PS Project').getRecordTypeId()];
        RecordType recordType = [SELECT id FROM RecordType WHERE DeveloperName = :EmployeeTimeCardController.projectRecordTypeNameForSupportRequest LIMIT 1];
        system.assert(recordType <> null);
        PS_Project__c clientProject = new PS_Project__c(
            Name = 'Client Project 1',
            Is_Active__c = true,
            RecordType = clientRecordType
        );
        insert clientProject;

        //insert 'General Support Request Project'
        PS_Project__c generalSupportRequestProject = new PS_Project__c(
            Name = EmployeeTimeCardController.supportRequestCatchAllProjectName,
            Is_Active__c = true,
            RecordType = recordType
        );
        insert generalSupportRequestProject;    

        //insert milestone for client project
        Milestone__c clientMilestone = new Milestone__c(
            Name = 'Test Milestone 1',
            ProjectId__c = clientProject.Id,
            IsActive__c = true
        );
        insert clientMilestone;

        //insert milestone for internal project
        Milestone__c bsiMilestone = new Milestone__c(
            Name = 'Test Milestone 2',
            ProjectId__c = generalSupportRequestProject.Id,
            IsActive__c = true
        );
        insert bsiMilestone;
        
        //insert support requests 
        Support_Request__c supportRequest = new Support_Request__c(
            BSI_Project__c = generalSupportRequestProject.Id
        );
        insert supportRequest; 

        Support_Request__c supportRequestWithoutProject = new Support_Request__c(
            BSI_Project__c = null
        );
        insert supportRequestWithoutProject;

        //insert assignment
        Assignment__c assignment = new Assignment__c(
            Subject__c = 'Test Assignment',
            ProjectId__c = clientProject.Id,
            MilestoneId__c = clientMilestone.Id
        );
        insert assignment;

        //insert time card header
        Time_Card_Header__c timeCardHeader = new Time_Card_Header__c(
            UserId__c = UserInfo.getUserId(),
            PeriodId__c = currentPeriodId,
            Status__c = 'Open'
        );
        insert timeCardHeader;
        
        //insert time card entry for client project
        Time_Card_Entry__c clientProjectTimeCardEntry = new Time_Card_Entry__c(
            EmployeeId__c = UserInfo.getUserId(),
            Hours_Entered__c = 1.0,
            Internal_Comments__c = 'Internal Comments (CP)',
            MilestoneId__c = clientMilestone.Id,
            Support_RequestId__c = null,
            Notes__c = 'Notes (CP)',
            ProjectId__c = clientProject.Id,
            Time_Card_HeaderId__c = timeCardHeader.Id,
            Date_Entered__c = system.now().Date()
        );
        insert clientProjectTimeCardEntry;      

        //insert time card entry for support request 
        Time_Card_Entry__c supportRequestTimeCardEntry = new Time_Card_Entry__c(
            EmployeeId__c = UserInfo.getUserId(),
            Hours_Entered__c = 2.0,
            Internal_Comments__c = 'Internal Comments (SR)',
            MilestoneId__c = clientMilestone.Id,
            Support_RequestId__c = supportRequest.Id,
            Notes__c = 'Notes (SR)',
            Time_Card_HeaderId__c = timeCardHeader.Id,
            Date_Entered__c = system.now().Date()
        );
        insert supportRequestTimeCardEntry;            

        //insert test account
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;
    }

    @isTest
    private static void testControllerProperties()
    {   
        //get project
        List<PS_Project__c> projects = EmployeeTimeCardController.getProjects(true, '');
        system.assert(projects.size() > 0);
        PS_Project__c project = projects[0];

        //get support request
        List<Support_Request__c> supportRequests = EmployeeTimeCardController.getSupportRequests('');
        system.assert(supportRequests.size() > 0);
        Support_Request__c supportRequest = supportRequests[0];

        test.startTest();                        
        //set page parameters
        PageReference pageRef = Page.mytimecard;
        pageRef.getParameters().put('projectId', project.Id);
        pageRef.getParameters().put('supportRequestId', supportRequest.Id);        
        Test.setCurrentPage(pageRef);          
        
        //initialize controller
        EmployeeTimeCardController controller = new EmployeeTimeCardController();        
        test.stopTest(); 

        //assertions
        system.assert(controller.project <> null);
        system.assertEquals(controller.project.Id, project.Id);
        system.assert(controller.supportRequest <> null);
        system.assertEquals(controller.supportRequest.Id, supportRequest.Id);
    }
    
    @isTest static void testControllerPropertiesWithoutServiceRequest()    
    {
        //get project
        List<PS_Project__c> projects = EmployeeTimeCardController.getProjects(true, '');
        system.assert(projects.size() > 0);
        PS_Project__c project = projects[0];

        //get support request
        List<Support_Request__c> supportRequests = EmployeeTimeCardController.getSupportRequests('');
        system.assert(supportRequests.size() > 0);
        Support_Request__c supportRequest = supportRequests[0];       

        test.startTest();                        
        //set page parameters
        PageReference pageRef = Page.mytimecard;
        pageRef.getParameters().put('projectId', project.Id);
        pageRef.getParameters().put('srId', supportRequest.Id);        
        Test.setCurrentPage(pageRef);          
        
        //initialize controller
        EmployeeTimeCardController controller = new EmployeeTimeCardController();        
        test.stopTest(); 

        //assertions
        system.assert(controller.project <> null);
        system.assertEquals(controller.project.Id, project.Id);
        system.assert(controller.supportRequest <> null);
        system.assertEquals(controller.supportRequest.Id, supportRequest.Id);             
    }

    @isTest
    private static void getTimeEntryTypesTest()
    {
        test.startTest();
        List<String> timeEntryTypes = EmployeeTimeCardController.getTimeEntryTypes();        
        test.stopTest();        

        system.assertEquals(timeEntryTypes.size(), User.Default_Time_Card_Entry_Setting__c.getDescribe().getPicklistValues().size());
    }

    @isTest
    private static void getSupportRequestStatusesTest()
    {
        test.startTest();        
        List<String> supportRequestStatuses = EmployeeTimeCardController.getSupportRequestStatuses();
        test.stopTest();                      

        system.assertEquals(supportRequestStatuses.size(), Support_Request__c.Status__c.getDescribe().getPicklistValues().size() + 1);  
    }

    @isTest
    private static void getUserTest()
    {
        test.startTest();                
        User testUser = EmployeeTimeCardController.getUser();
        if (testUser.Default_Time_Card_Entry_Setting__c <> null)
        {
            system.assert(EmployeeTimeCardController.getTimeEntryTypes().contains(testUser.Default_Time_Card_Entry_Setting__c));
        }
        test.stopTest();                              

        system.assertEquals(testUser.Id, UserInfo.getUserId());
        system.assertEquals(testUser.FirstName, UserInfo.getFirstName());
        system.assertEquals(testUser.LastName, UserInfo.getLastName());        
    }

    @isTest
    private static void getCurrentPeriodTest()
    {
        test.startTest();
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        test.stopTest();        
        Integer i = periods.size();

        system.assert(i > 0);
        system.assertEquals(i, 1);
        Period__c period = periods[0];
        Date startDate = system.now().date().toStartOfWeek();
        system.assertEquals(period.Start_Date__c, startDate);
        system.assertEquals(period.End_Date__c, startDate.addDays(6));
    }

    @isTest
    private static void getPreviousPeriodTest()
    {
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);

        Date startDate = periods[0].Start_Date__c;
        Date previousPeriodStartDate = startDate.AddDays(-7);

        test.startTest();
        periods = EmployeeTimeCardController.getPreviousPeriod(periods[0]);
        test.stopTest();

        system.assert(periods.size() == 1);
        Period__c previousPeriod = periods[0];
        system.assertEquals(previousPeriod.Start_Date__c, previousPeriodStartDate);
        system.assertEquals(previousPeriod.End_Date__c, previousPeriodStartDate.AddDays(6));        
    }

    @isTest
    private static void getNextPeriodTest()
    {
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);

        Date endDate = periods[0].End_Date__c;
        Date nextPeriodStartDate = endDate.AddDays(1);

        test.startTest();
        periods = EmployeeTimeCardController.getNextPeriod(periods[0]);
        test.stopTest();

        system.assert(periods.size() == 1);
        Period__c nextPeriod = periods[0];
        system.assertEquals(nextPeriod.Start_Date__c, nextPeriodStartDate);
        system.assertEquals(nextPeriod.End_Date__c, nextPeriodStartDate.AddDays(6));        
    }

    @isTest
    private static void addClientProjectTimeCardEntryTest()
    {
        //get user
        User testUser = EmployeeTimeCardController.getUser();

        //get current period
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);       

        //get active client project
        List<PS_Project__c> clientProjects = EmployeeTimeCardController.getProjects(true, '');
        system.assert(clientProjects.size() > 0);
        Id clientProjectId = clientProjects[0].Id;

        //get project by id
        PS_Project__c project = EmployeeTimeCardController.getProject(clientProjectId);
        system.assertEquals(project.Id, clientProjectId);

        //get milestones for project
        List<Milestone__c> clientProjectMilestones = EmployeeTimeCardController.getMilestones(clientProjectId);
        system.assert(clientProjectMilestones.size() == 1);        
        Id clientProjectMilestoneId = clientProjectMilestones[0].Id;

        List<Assignment__c> assignments = EmployeeTimeCardController.getAssignments(clientProjectMilestoneId);
        system.assert(assignments.size() == 1);
        Id assignmentId = assignments[0].Id;

        //get time card header
        Time_Card_Header__c timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.getTimeCardHeader(testUser.Id, periods[0].Id);
        system.assert(timeCardHeaderForCurrentPeriod <> null);

        //create time card entry        
        test.startTest();
        Time_Card_Entry__c tce = new Time_Card_Entry__c();
        tce.Date_Entered__c =  Date.today();
        tce.EmployeeId__c = testUser.Id;
        tce.ProjectId__c = clientProjectId;
        tce.MilestoneId__c = clientProjectMilestoneId;
        tce.Notes__c = 'Notes Test';
        tce.Time_Card_HeaderId__c = timeCardHeaderForCurrentPeriod.Id;
        tce.Internal_Comments__c = 'Internal Comments Test';
        tce.Hours_Entered__c = 1.0;
        tce.AssignmentId__c = assignmentId;

        Time_Card_Entry__c timeCardEntry = EmployeeTimeCardController.createTimeCardEntry(tce);
        test.stopTest();            

        //assertions
        system.assert(timeCardEntry.Id <> null);
        system.assertEquals(timeCardEntry.Internal_Comments__c, 'Internal Comments Test');
        system.assertEquals(timeCardEntry.Hours_Entered__c, 1.0);

   }

    @isTest
    private static void addSupportRequestTimeCardEntryTest()
    {
        //get user
        User testUser = EmployeeTimeCardController.getUser();

        //get current period
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);       

        //get support requests
        List<Support_Request__c> supportRequests = EmployeeTimeCardController.getSupportRequests('New');
        system.assert(supportRequests.size() > 0);
        Id supportRequestId = supportRequests[0].Id;

        //get support request by Id
        Support_Request__c supportRequest = EmployeeTimeCardController.getSupportRequest(supportRequestId);
        system.assertEquals(supportRequestId, supportRequest.Id);

        //get project for support request
        PS_Project__c project = EmployeeTimeCardController.getProjectForSupportRequest(supportRequestId);
        system.assertEquals(project.Id, supportRequest.BSI_Project__c);       

        //get milestones for support request project
        List<Milestone__c> supportRequestMilestones = EmployeeTimeCardController.getMilestones(project.Id);
        system.assert(supportRequestMilestones.size() == 1);        
        Id supporRequestMilestoneId = supportRequestMilestones[0].Id;
        
        //get time card header
        Time_Card_Header__c timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.getTimeCardHeader(testUser.Id, periods[0].Id);
        system.assert(timeCardHeaderForCurrentPeriod <> null);

        //create time card entry

        test.startTest();
        Time_Card_Entry__c tce = new Time_Card_Entry__c();
        tce.Date_Entered__c =  Date.today();
        tce.EmployeeId__c = testUser.Id;
        tce.ProjectId__c = project.Id;
        tce.MilestoneId__c = supporRequestMilestoneId;
        tce.Notes__c = 'Notes Test';
        tce.Time_Card_HeaderId__c = timeCardHeaderForCurrentPeriod.Id;
        tce.Hours_Entered__c = 5.0; 
        // tce.Period__c = periods[0];
        Time_Card_Entry__c timeCardEntry = EmployeeTimeCardController.createTimeCardEntry(tce);
        test.stopTest();            

        //assertions
        system.assert(timeCardEntry.Id <> null);
        system.assertEquals(timeCardEntry.Notes__c, 'Notes Test');
        system.assertEquals(timeCardEntry.Hours_Entered__c, 5.0);
    }

    @isTest
    private static void timeCardEntryUpdateTest()
    {
        //get current period
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);       

        //get time card header
        Time_Card_Header__c timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.getTimeCardHeader(null, periods[0].Id);
        system.assert(timeCardHeaderForCurrentPeriod <> null);

        //get time card entries for update
        List<Time_Card_Entry__c> timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(timeCardHeaderForCurrentPeriod.UserId__c, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);
        system.assert(timeCardEntries.size() > 0);

        test.startTest();
        for (Time_Card_Entry__c timeCardEntry : timeCardEntries)
        {
            if (timeCardEntry.ProjectId__r.Is_Active__c)
            {
                //update notes
                timeCardEntry.Notes__c = 'Notes Test (Update)';
                EmployeeTimeCardController.updateTimeCardEntry(timeCardEntry);
            }
        }
        test.stopTest();

        //get active time card entries to verify update
        timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(timeCardHeaderForCurrentPeriod.UserId__c, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);
        system.assert(timeCardEntries.size() > 0);
        for (Time_Card_Entry__c timeCardEntry : timeCardEntries)
        {                    
            if (timeCardEntry.ProjectId__r.Is_Active__c)
            {
                system.assertEquals(timeCardEntry.Notes__c, 'Notes Test (Update)');        
            }
        }
    }

    @isTest
    private static void timeCardEntryBulkUpdateTest()
    {
        //get user
        User testUser = EmployeeTimeCardController.getUser();

        //get current period
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);       

        //get time card header
        Time_Card_Header__c timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.getTimeCardHeader(testUser.Id, periods[0].Id);
        system.assert(timeCardHeaderForCurrentPeriod <> null);

        //get time card entries
        List<Time_Card_Entry__c> timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(null, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);       
        
        //bulk update period notes
        for (Time_Card_Entry__c timeCardEntry : timeCardEntries)
        {
            timeCardEntry.Notes__c = 'Notes Test (Bulk Update)';
        }        

        test.startTest();                    
        timeCardEntries = EmployeeTimeCardController.updatePeriodNotes(timeCardEntries);
        test.stopTest();        

        //verify change
        for (Time_Card_Entry__c timeCardEntry : timeCardEntries)
        {
            system.assertEquals(timeCardEntry.Notes__c, 'Notes Test (Bulk Update)');
        }        
    }

    @isTest
    private static void timeCardEntryCloneTest()
    {
        //get user
        User testUser = EmployeeTimeCardController.getUser();

        //get current period
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);       

        //get time card header
        Time_Card_Header__c timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.getTimeCardHeader(testUser.Id, periods[0].Id);
        system.assert(timeCardHeaderForCurrentPeriod <> null);

        //get time card entries
        List<Time_Card_Entry__c> timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(testUser.Id, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);              
        Integer numEntries = timeCardEntries.size();        

        //Clone entries
        test.startTest();        
        List<Time_Card_Entry__c> clonedEntries = new  List<Time_Card_Entry__c>();
        Time_Card_Entry__c clonedEntry;
        for (Time_Card_Entry__c timeCardEntry : timeCardEntries)
        {
            clonedEntry = EmployeeTimeCardController.cloneTimeCardEntry(timeCardEntry.Id);
            clonedEntry.Notes__c = 'Cloned Entry';
            EmployeeTimeCardController.updateTimeCardEntry(clonedEntry);            
            clonedEntries.add(clonedEntry);
        }
        test.stopTest();                

        //check entries number
        system.assertEquals(timeCardEntries.size(), clonedEntries.size());

        //get again all entries
        timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(testUser.Id, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);

        //check entries number
        system.assertEquals(timeCardEntries.size(), numEntries*2);
    }

    @isTest
    private static void timeCardEntryDeleteTest()
    {
        //get user
        User testUser = EmployeeTimeCardController.getUser();

        //get current period
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);       

        //get time card header
        Time_Card_Header__c timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.getTimeCardHeader(testUser.Id, periods[0].Id);
        system.assert(timeCardHeaderForCurrentPeriod <> null);

        //get time card entries
        List<Time_Card_Entry__c> timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(testUser.Id, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);
        Integer entriesNumber = timeCardEntries.size();
        system.assert(entriesNumber > 0);

        //delete cloned time card entries
        Integer deletedEntriesNumber = 0;

        test.startTest();        
        for (Time_Card_Entry__c timeCardEntry : timeCardEntries)
        {
            EmployeeTimeCardController.deleteTimeCardEntry(timeCardEntry.Id);
            deletedEntriesNumber+=1;
        }
        system.assert(deletedEntriesNumber > 0);
        test.stopTest();                

        //get time card entries again (after deletion)
        timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(testUser.Id, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);

        //assertion
        system.assert(timeCardEntries.size() == (entriesNumber - deletedEntriesNumber));      
    }

    @isTest
    private static void completeWeekTest()
    {
        //get user
        User testUser = EmployeeTimeCardController.getUser();

        //get current period
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);       

        //get time card header
        Time_Card_Header__c timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.getTimeCardHeader(testUser.Id, periods[0].Id);
        system.assert(timeCardHeaderForCurrentPeriod <> null);

        //get time card entries
        List<Time_Card_Entry__c> timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(testUser.Id, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);
        Integer entriesNumber = timeCardEntries.size();
        system.assert(entriesNumber > 0);  

        test.startTest();
        for (Time_Card_Entry__c timecardEntry :timeCardEntries)    
        {
            EmployeeTimeCardController.completeWeek(timecardEntry); //this method inserts 4 time card entries
        }
        test.stopTest();                

        //get time card entries again
        timeCardEntries = EmployeeTimeCardController.getTimeCardEntries(testUser.Id, timeCardHeaderForCurrentPeriod.Id, periods[0].Id);        
        system.assert(timeCardEntries.size() == ((entriesNumber*4)+entriesNumber));
    }

    @isTest
    private static void submitForApprovalTest()
    {
        //get user
        User testUser = EmployeeTimeCardController.getUser();

        //get current period
        List<Period__c> periods = EmployeeTimeCardController.getCurrentPeriod();
        system.assert(periods.size() == 1);       

        //get time card header
        Time_Card_Header__c timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.getTimeCardHeader(testUser.Id, periods[0].Id);
        system.assert(timeCardHeaderForCurrentPeriod <> null);

        timeCardHeaderForCurrentPeriod.Status__c = 'Completed';

        //submit for approval
        test.startTest();        
        timeCardHeaderForCurrentPeriod = EmployeeTimeCardController.submitForApproval(timeCardHeaderForCurrentPeriod);
        test.stopTest();               

        system.assertEquals(timeCardHeaderForCurrentPeriod.Status__c, 'Completed');      
    }

    @isTest
    private static void searchEmployeesTest()
    {
        test.startTest();
        List<User> users = EmployeeTimeCardController.searchEmployees(UserInfo.getFirstName());
        test.stopTest();

        system.assert(users.size() > 0);
    }

    @isTest
    private static void searchPeriodsTest()
    {
        test.startTest();
        List<Period__c> currentPeriods = EmployeeTimeCardController.searchPeriods(String.valueOf(Date.Today().year()));
        List<Period__c> pastYearPeriods = EmployeeTimeCardController.searchPeriods(String.valueOf(Date.Today().year()-1));                
        test.stopTest();

        system.assert(currentPeriods.size() > 0);
        system.assert(pastYearPeriods.size() == 0);        
    }

    @isTest
    private static void searchAccountsTest()
    {
        test.startTest();
        List<Account> accounts = EmployeeTimeCardController.searchAccounts('Test');
        test.stopTest();                

        system.assert(accounts.size() > 0);
    }

    @isTest
    private static void getNotClosedSupportRequestTest()
    {
        test.startTest();
        List<Support_Request__c> supportRequests = EmployeeTimeCardController.getSupportRequests('');
        test.stopTest();

        system.assert(supportRequests.size() > 0);
        for (Support_Request__c supportRequest : supportRequests)
        {
            system.assert(supportRequest.Status__c <> 'Closed');
        }
    }

    @isTest
    private static void createProjectForSupportRequestTest()
    {        
        //delete default support request project to force creeation by method.
        delete [SELECT Id FROM PS_Project__c WHERE Name = :EmployeeTimeCardController.supportRequestCatchAllProjectName];

        List<Support_Request__c> supportRequests = EmployeeTimeCardController.getSupportRequests('');        
        
        system.assert(supportRequests.size() > 0);

        List<PS_Project__c> createdProjects = new List<PS_Project__c>();
        
        test.startTest();        
        for (Support_Request__c supportRequest : supportRequests)
        {
            if (supportRequest.BSI_Project__c == null)
            {
                createdProjects.add(EmployeeTimeCardController.getProjectForSupportRequest(supportRequest.id));
            }
        }
        test.stopTest();

        for (PS_Project__c project : createdProjects)
        {
            system.assert(project <> null);
        }
    }

    @isTest
    private static void getTimeCardHeaderForNextPeriodTest()
    {
        String periodName = getPeriodName(Date.today());
        Period__c period = [select Id, Name, End_Date__c, Start_Date__c FROM Period__c WHERE Name = :periodName ORDER BY Name ASC LIMIT 1];

        //get next period
        List<Period__c> periods = EmployeeTimeCardController.getNextPeriod(period);
        system.assert(periods.size() == 1);       

        test.startTest();
        //get time card header
        Time_Card_Header__c timeCardHeaderForNextPeriod = EmployeeTimeCardController.getTimeCardHeader(null, periods[0].Id);
        test.stopTest();        
        
        //assertion
        system.assert(timeCardHeaderForNextPeriod <> null);        
    }
}