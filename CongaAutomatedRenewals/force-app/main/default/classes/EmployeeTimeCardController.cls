/**
* @author Conga, ROcwieja
* @date 20160909
* @version 1.00
* @description Describes the EmployeeTimeCardController class 
*/
public with sharing class EmployeeTimeCardController {
    public static final String projectRecordTypeNameForSupportRequest = 'BSI_Project_Internal';
    public static final String supportRequestRecordTypeName = 'Salesforce_Support_Request';
    public static final String provisioningSupportRequestRecordTypeName = 'Provisioning_Request';
    public static final String supportRequestCatchAllProjectName = 'General Support Request Project';
    public static final String supportRequestCatchAllMilestoneName = 'General Support Request Milestone';
    public static final String provisioningSupportRequestCatchAllProjectName = 'Provisioning Team Support Request Project';
    public static final String provisioningSupportRequestCatchAllMilestoneName = 'Provisioning Team Support Request Milestone';
    public PS_Project__c project {get; private set;}
    public Support_Request__c supportRequest {get; private set;}


    /**
    * @description EmployeeTimeCardController - Constructor
    */
    public EmployeeTimeCardController(){
        Id projectId = ApexPages.currentPage().getParameters().get('projectId');

        if(projectId != null){
            this.project = [SELECT Id,Name,Is_Active__c FROM PS_Project__c WHERE Id = :projectId];
        }

        Id supportRequestId = ApexPages.currentPage().getParameters().get('supportRequestId');

        if(supportRequestId != null){
            this.supportRequest = [SELECT Id,Name,BSI_Project__c,BSI_Project__r.Name FROM Support_Request__c WHERE Id = :supportRequestId];
        }
        else {
            supportRequestId = ApexPages.currentPage().getParameters().get('srId');
            if(supportRequestId != null){
                this.supportRequest = [SELECT Id,Name,BSI_Project__c,BSI_Project__r.Name FROM Support_Request__c WHERE Id = :supportRequestId];
            }
        }
    }

    /**
    * @description getTimeEntryTypes -
    * @return List<String>
    */
    @RemoteAction
    public static List<String> getTimeEntryTypes() {
        List<String> timeEntryTypes = new List<String>();

        Schema.DescribeFieldResult fieldResult = User.Default_Time_Card_Entry_Setting__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();        
        for(Schema.PicklistEntry f : ple) {
            timeEntryTypes.add(f.getValue());
        }

        return timeEntryTypes;
    }

    /**
    * @description getSupportRequestStatuses - 
    * @return List<String>
    */
    @RemoteAction
    public static List<String> getSupportRequestStatuses() {
        List<String> supportRequestStatuses = new List<String>();
        supportRequestStatuses.add('');

        Schema.DescribeFieldResult fieldResult = Support_Request__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();        
        for(Schema.PicklistEntry f : ple) {
            supportRequestStatuses.add(f.getValue());
        }

        return supportRequestStatuses;
    }

    /**
    * @description getUser - 
    * @return User
    */
    @RemoteAction
    public static User getUser() {
        return [SELECT Id, FirstName, LastName,Default_Time_Card_Entry_Setting__c, Team__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0];
    }

    /**
    * @description getCurrentPeriod - 
    * @return List<Period__c>
    */
    @RemoteAction
    public static List<Period__c> getCurrentPeriod() {
        return [SELECT Id, Name, End_Date__c, Start_Date__c FROM Period__c WHERE Type__c = 'Week' AND Start_Date__c <= :Date.Today() AND End_Date__c >= :Date.Today() ORDER BY Name ASC LIMIT 1];
    }

    /**
    * @description getPreviousPeriod - 
    * @param Period__c pPeriod
    * @return List<Period__c>
    */
    @RemoteAction
    public static List<Period__c> getPreviousPeriod(Period__c pPeriod) {
        String pPeriodName = getPeriodName(pPeriod.Start_Date__c.addDays(-7));
        return [SELECT Id, Name, End_Date__c, Start_Date__c FROM Period__c WHERE Type__c = 'Week' and End_Date__c < :pPeriod.Start_Date__c ORDER BY End_Date__c DESC LIMIT 1];
    }

    /**
    * @description getNextPeriod -
    * @param Period__c pPeriod
    * @return List<Period__c>
    */
    @RemoteAction
    public static List<Period__c> getNextPeriod(Period__c pPeriod) {
        String pPeriodName = getPeriodName(pPeriod.End_Date__c.addDays(1));
        return [SELECT Id, Name, End_Date__c, Start_Date__c FROM Period__c WHERE Type__c = 'Week' and Start_Date__c > :pPeriod.End_Date__c ORDER BY Start_Date__c ASC LIMIT 1];
    }

    /**
    * @description getPeriodName -
    * @param Date pDate
    * @return String
    */
    public static String getPeriodName(Date pDate){
        DateTime vDateTime = DateTime.newInstance(pDate.year(), pDate.month(), pdate.day());
        Integer weekNumber = Integer.valueOf(vDateTime.format('w'));
        String weekNumberText = string.valueOf(weekNumber).leftPad(2,'0');
        return String.format('{0}-W{1}', new String[] { String.valueOf(pDate.toStartOfWeek().year()) , weekNumberText });
    }

    /**
    * @description getProject - 
    * @param Id pProjectId
    * @return PS_Project__c
    */
    @RemoteAction
    public static PS_Project__c getProject(Id pProjectId) {
        List<PS_Project__c> projects = [select Id, Name, Is_Active__c FROM PS_Project__c where Id = :pProjectId];
        if(projects.isEmpty()) return null;
        
        return projects[0];
    }

    /**
    * @description getProjects - 
    * @param Boolean pIsActive
    * @param String pProjectType
    * @return List<PS_Project__c>
    */
    @RemoteAction
    public static List<PS_Project__c> getProjects(Boolean pIsActive, String pProjectType) {
        String strSoql = 'SELECT Id, Name, Is_Active__c FROM PS_Project__c ';
        if(pIsActive) {
            strSoql += ' WHERE Is_Active__c = true';        
        }
        if(String.isNotBlank(pProjectType)) {
            if(!strSoql.contains('WHERE')) strSoql += ' WHERE ';
            else strSoql += ' AND ';
            
            if(pProjectType == 'Internal Project') strSoql += ' RecordType.DeveloperName = :projectRecordTypeNameForSupportRequest';
            else strSoql += ' RecordType.DeveloperName != :projectRecordTypeNameForSupportRequest';
        }
        strSoql += ' AND Id IN (SELECT ProjectId__c FROM Milestone__c) ORDER BY Name ASC';
        return database.query(strSoql);
    }

    /**
    * @description getSupportRequest - 
    * @param String pSupportRequestId
    * @return Support_Request__c
    */
    @RemoteAction
    public static Support_Request__c getSupportRequest(String pSupportRequestId) {
        List<Support_Request__c> srs = [SELECT Id, Name, BSI_Project__c,BSI_Project__r.Name, BSI_Project__r.Is_Active__c, Status__c FROM Support_Request__c WHERE Id = :pSupportRequestId];
        if(srs.isEmpty()) return null;
        
        return srs[0];
    }

    /**
    * @description getSupportRequests - 
    * @param String pStatus
    * @return List<Support_Request__c>
    */
    @RemoteAction
    public static List<Support_Request__c> getSupportRequests(String pStatus) {
        String strSoql = 'SELECT Id, Name, IsClosedFx__c, BSI_Project__c,BSI_Project__r.Name, BSI_Project__r.Is_Active__c, Status__c FROM Support_Request__c WHERE (RecordType.DeveloperName = :supportRequestRecordTypeName OR RecordType.DeveloperName = :provisioningSupportRequestRecordTypeName)';
        if(!String.isBlank(pStatus)) {
            strSoql += ' AND Status__c = :pStatus';        
        }
        else {
            strSoql += ' AND IsClosedFx__c = false';        
        }
        strSoql += ' ORDER BY Name ASC';

        return database.query(strSoql);
    }

    /**
    * @description getProjectForSupportRequest - 
    * @param Id pSupportRequestId
    * @return PS_Project__c
    */
    @RemoteAction
    public static PS_Project__c getProjectForSupportRequest(Id pSupportRequestId) {
        List<Support_Request__c> srs = [select Id, BSI_Project__c, RecordType.DeveloperName, BSI_Project__r.Name, BSI_Project__r.Is_Active__c from Support_Request__c where Id = :pSupportRequestId];
        String milestoneName;
        if(srs.isEmpty()) return null;
        Support_Request__c sr = srs[0];

        PS_Project__c project = null;

        if(sr.BSI_Project__c != null) {
            project = sr.BSI_Project__r;
        }
        else {
            if(sr.RecordType.DeveloperName == supportRequestRecordTypeName){
                List<PS_Project__c> projects = [select Id, Name, Is_Active__c from PS_Project__c where Name = :supportRequestCatchAllProjectName limit 1];
                if(projects.isEmpty()) {
                    List<RecordType> recordTypes = [select Id,DeveloperName from RecordType where SObjectType = 'PS_Project__c' and DeveloperName = :projectRecordTypeNameForSupportRequest];
                    System.assertEquals(1, recordTypes.size(), String.format('There is no record type "{0}" for object PS_Project__c', new String[] { projectRecordTypeNameForSupportRequest }));

                    project = new PS_Project__c(
                        Name = supportRequestCatchAllProjectName,
                        RecordTypeId = recordTypes[0].Id,
                        Is_Active__c = true
                    );
                    insert project; 

                }
                else {
                    project = projects[0];
                }
                milestoneName = supportRequestCatchAllMilestoneName;
                sr.BSI_Project__c = project.Id;           
                update sr;
            }

            if(sr.RecordType.DeveloperName == provisioningSupportRequestRecordTypeName){
                List<PS_Project__c> projects = [select Id, Name, Is_Active__c from PS_Project__c where Name = :provisioningSupportRequestCatchAllProjectName limit 1];
                if(projects.isEmpty()) {
                    List<RecordType> recordTypes = [select Id,DeveloperName from RecordType where SObjectType = 'PS_Project__c' and DeveloperName = :provisioningSupportRequestRecordTypeName];
                    System.assertEquals(1, recordTypes.size(), String.format('There is no record type "{0}" for object PS_Project__c', new String[] { provisioningSupportRequestRecordTypeName }));

                    project = new PS_Project__c(
                        Name = provisioningSupportRequestCatchAllProjectName,
                        RecordTypeId = recordTypes[0].Id,
                        Is_Active__c = true
                    );
                    insert project; 

                }
                else {
                    project = projects[0];
                }
                milestoneName = provisioningSupportRequestCatchAllMilestoneName;
                sr.BSI_Project__c = project.Id;           
                update sr;
            }
        }

        List<Milestone__c> milestones = [SELECT Id, Name, Hours_RemainingFx__c FROM Milestone__c WHERE ProjectId__c = :project.Id AND IsActive__c = true  ORDER BY CreatedDate DESC];
        if(milestones.isEmpty() && String.isNotBlank(milestoneName)) {
            insert new Milestone__c(
                Name = supportRequestCatchAllMilestoneName,
                ProjectId__c = project.Id,
                IsActive__c = true,
                Hours_Currently_Budgeted__c = 10
            );
        }

        return project;
    }

    /**
    * @description getMilestones - 
    * @param Id pProjectId
    * @return List<Milestone__c>
    */
    @RemoteAction
    public static List<Milestone__c> getMilestones(Id pProjectId) {
        return [SELECT Id, Name, Hours_RemainingFx__c, ProjectId__c FROM Milestone__c WHERE ProjectId__c = :pProjectId AND IsActive__c = true  ORDER BY CreatedDate DESC];
    }

    /**
    * @description getAssignments - 
    * @param Id pMilestoneId
    * @return List<Assignment__c>
    */
    @RemoteAction
    public static List<Assignment__c> getAssignments(Id pMilestoneId) {
        return [SELECT Id, Name, Subject__c FROM Assignment__c WHERE MilestoneId__c = :pMilestoneId AND Status__c != 'Complete' AND Status__c != 'Cancelled' ORDER BY Name ASC];
    }

    /**
    * @description getTimeCardHeader - 
    * @param Id pUserId
    * @param Id pPeriodId
    * @return Time_Card_Header__c
    */
    @RemoteAction
    public static Time_Card_Header__c getTimeCardHeader(Id pUserId, Id pPeriodId) {
        if(String.isBlank(pUserId)) {
            pUserId = UserInfo.getUserId();
        }

        List<Time_Card_Header__c> o = [SELECT Id, UserId__c, PeriodId__c, Status__c FROM Time_Card_Header__c WHERE UserId__c = :pUserId AND PeriodId__c = :pPeriodId LIMIT 1];
        if(o.size()>0) {
            return o[0];
        } else {
            Time_Card_Header__c t = new Time_Card_Header__c(
                UserId__c = pUserId,
                PeriodId__c = pPeriodId,
                Status__c = 'Open'
            );
            insert t;

            return t;
        }
    }


    /**
    * @description getTimeCardEntries - 
    * @param Id pUserId
    * @param Id pTimeCardHeaderId
    * @param Id pPeriodId    
    * @return List<Time_Card_Entry__c>
    */
    @RemoteAction
    public static List<Time_Card_Entry__c> getTimeCardEntries(Id pUserId, Id pTimeCardHeaderId, Id pPeriodId) {
        List<Time_Card_Entry__c> tce = new List<Time_Card_Entry__c>();
        if(String.isBlank(pUserId)) {
            pUserId = UserInfo.getUserId();
        }

        return [
            SELECT Id, Name, Date_Entered__c,  Day_of_the_Week__c, EmployeeId__c, Hours_Entered__c, Internal_Comments__c, AssignmentId__c, AssignmentId__r.Name, AssignmentId__r.Subject__c, MilestoneId__c, MilestoneId__r.Name, Notes__c, ProjectId__c, ProjectId__r.RecordType.DeveloperName, ProjectId__r.Name, ProjectId__r.Is_Active__c, Support_RequestId__c, Support_RequestId__r.Name, Time_Card_HeaderId__c
            FROM Time_Card_Entry__c
            WHERE EmployeeId__c = :pUserId
                AND Time_Card_HeaderId__c = :pTimeCardHeaderId AND Time_Card_HeaderId__r.PeriodId__c = :pPeriodId 
            ORDER BY Name ASC
            LIMIT 10000
        ];
    }


    /**
    * @description createTimeCardEntry - 
    * @param Time_Card_Entry__c pNewTimeCardEntry
    * @return Time_Card_Entry__c
    */
    @RemoteAction
    public static Time_Card_Entry__c createTimeCardEntry(Time_Card_Entry__c pNewTimeCardEntry){
        //Id pUserId, Id pProjectId, Id pMilestoneId, Id pSupportRequestId, Id pTimeCardHeaderId, String pNotes, Decimal pHoursEntered, String pInternalComments, String pSelectedDate, Period__c pPeriod, Id pAccountId, Id pAssignmentId) {
        //if(String.isBlank(pUserId)) {
        //    pUserId = UserInfo.getUserId();
        //}
        //Date selectedDate = Date.parse(pSelectedDate);
        //if(selectedDate<pPeriod.Start_Date__c || selectedDate>pPeriod.End_Date__c) {
        //    return null;
        //} else {
        //    Time_Card_Entry__c t = new Time_Card_Entry__c(
        //        AccountId__c = pAccountId,
        //        Date_Entered__c = selectedDate,
        //        EmployeeId__c = pUserId,
        //        Hours_Entered__c = pHoursEntered,
        //        Internal_Comments__c = pInternalComments,
        //        MilestoneId__c = pMilestoneId,
        //        Support_RequestId__c = pSupportRequestId,
        //        Notes__c = pNotes,
        //        ProjectId__c = pProjectId,
        //        Time_Card_HeaderId__c = pTimeCardHeaderId,
        //        AssignmentId__c = pAssignmentId
        //    );
        //    insert t;

        //    return t;
        //}
        if(String.isBlank(pNewTimeCardEntry.EmployeeId__c)) {
            pNewTimeCardEntry.EmployeeId__c = UserInfo.getUserId();
        }
        insert pNewTimeCardEntry;
        return pNewTimeCardEntry;
    }

    /**
    * @description updateTimeCardEntry - 
    * @param Time_Card_Entry__c pTimeCardEntry
    * @return Time_Card_Entry__c
    */
    @RemoteAction
    public static Time_Card_Entry__c updateTimeCardEntry(Time_Card_Entry__c pTimeCardEntry) {
        System.debug('Date entered: ' + pTimeCardEntry.Date_Entered__c);
        if(pTimeCardEntry.ProjectId__r.Is_Active__c) {
            update pTimeCardEntry;
        }
        
        return pTimeCardEntry;
    }

    /**
    * @description updatePeriodNotes - 
    * @param List<Time_Card_Entry__c> pTimeCardEntries
    * @return List<Time_Card_Entry__c>
    */
    @RemoteAction
    public static List<Time_Card_Entry__c> updatePeriodNotes(List<Time_Card_Entry__c> pTimeCardEntries) {
        update pTimeCardEntries;
        return pTimeCardEntries;
    }

    /**
    * @description deleteTimeCardEntry - 
    * @param Id pTimeCardEntryId
    * @return void
    */
    @RemoteAction
    public static void deleteTimeCardEntry(Id pTimeCardEntryId) {
        delete [SELECT Id FROM Time_Card_Entry__c WHERE Id = :pTimeCardEntryId LIMIT 1];
    }

    /**
    * @description cloneTimeCardEntry - 
    * @param Id pTimeCardEntryId
    * @return Time_Card_Entry__c
    */
    @RemoteAction
    public static Time_Card_Entry__c cloneTimeCardEntry(Id pTimeCardEntryId) {
        Time_Card_Entry__c tce = [SELECT Id, Name, Date_Entered__c, Day_of_the_Week__c, EmployeeId__c, Hours_Entered__c, Internal_Comments__c, AssignmentId__c, AssignmentId__r.Name, AssignmentId__r.Subject__c, MilestoneId__c, MilestoneId__r.Name, Notes__c, ProjectId__c, ProjectId__r.Name, ProjectId__r.Is_Active__c, Support_RequestId__c, Support_RequestId__r.Name, Time_Card_HeaderId__c FROM Time_Card_Entry__c WHERE Id = :pTimeCardEntryId LIMIT 1];        Time_Card_Entry__c tceClone = tce.clone(false, false, false, false);
        insert tceClone;

        return tceClone;
    }

    /**
    * @description completeWeek - 
    * @param Time_Card_Entry__c pTimeCardEntry
    * @return void
    */
    @RemoteAction
    public static void completeWeek(Time_Card_Entry__c pTimeCardEntry) {
        List<Time_Card_Entry__c> tceClones = new List<Time_Card_Entry__c>();
        for(Integer i=0; i<4; i++) {
            Time_Card_Entry__c tceClone = pTimeCardEntry.clone(false, false, false, false);
            tceClone.Date_Entered__c = tceClone.Date_Entered__c.addDays(i+1);
            tceClones.add(tceClone);
        }
        insert tceClones;
    }

    /**
    * @description submitForApproval - 
    * @param Time_Card_Header__c pTimeCardHeader
    * @return Time_Card_Header__c
    */
    @RemoteAction
    public static Time_Card_Header__c submitForApproval(Time_Card_Header__c pTimeCardHeader) {
        update pTimeCardHeader;
        return pTimeCardHeader;
    }

    /**
    * @description searchEmployees - 
    * @param String pInput
    * @return List<User>
    */
    @RemoteAction
    public static List<User> searchEmployees(String pInput) {
        String inputClean = '%'+String.escapeSingleQuotes(pInput)+'%';
        return [SELECT Id, Name FROM User WHERE Name LIKE :inputClean ORDER BY Name ASC LIMIT 20];
    }
    
    /**
    * @description searchPeriods - 
    * @param String pInput
    * @return List<Period__c>
    */
    @RemoteAction
    public static List<Period__c> searchPeriods(String pInput) {
        String inputClean = '%'+String.escapeSingleQuotes(pInput)+'%';
        return [SELECT Id, Name, End_Date__c, Start_Date__c FROM Period__c WHERE Name LIKE :inputClean ORDER BY Name ASC LIMIT 20];
    }

    /**
    * @description searchAccounts - 
    * @param String pInput
    * @return List<Account>
    */
    @RemoteAction
    public static List<Account> searchAccounts(String pInput) {
        String inputClean = '%'+String.escapeSingleQuotes(pInput)+'%';
        return [SELECT Id, Name FROM Account WHERE Name LIKE :inputClean ORDER BY Name ASC LIMIT 20];
    }


}