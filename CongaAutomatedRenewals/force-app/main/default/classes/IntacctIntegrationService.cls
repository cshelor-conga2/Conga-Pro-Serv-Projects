/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IntacctIntegrationService - Tests implemented in IntacctIntegrationServiceTest
*/
public class IntacctIntegrationService {
    private static final Integer HTTP_TIMEOUT = 60000;
    private static Boolean syncingTimeCardEntries = false;
    private static Boolean syncingProjects = false;
    private static Boolean syncingMilestones = false;

    /************************ GENERIC METHODS ***********************/

    /**
    * @description getSettings - 
    * @return IntacctDataModel.IntacctSettings
    */
    public static IntacctDataModel.IntacctSettings getSettings() {
        Intacct_Integration_Settings__c customSetting = Intacct_Integration_Settings__c.getInstance();
        if(customSetting == null || String.isBlank(customSetting.Company_Id__c) ||
           String.isBlank(customSetting.Sender_Id__c) || String.isBlank(customSetting.Sender_Password__c) || 
           String.isBlank(customSetting.User_Id__c) || String.isBlank(customSetting.User_Password__c)) {
               throw new IntacctException(String.format(label.INTACCT_Error_Settings, new String[] {}));
        }

        IntacctDataModel.IntacctSettings settings = new IntacctDataModel.IntacctSettings();
        settings.CompanyId = customSetting.Company_Id__c;
        settings.SenderId = customSetting.Sender_Id__c;
        settings.SenderPassword = customSetting.Sender_Password__c;
        settings.UserId = customSetting.User_Id__c;
        settings.UserPassword = customSetting.User_Password__c;
        settings.EndpointUrl = customSetting.Endpoint_URL__c;
        settings.Log = customSetting.Generate_Log__c;
        settings.LogSuccess = customSetting.Log_Success_Requests__c;
        return settings;
    }

    @TestVisible
    private static IntacctDataModel.IntacctSession cachedSession;

    /**
    * @description getSession - 
    * @return IntacctDataModel.IntacctSession
    */
    public static IntacctDataModel.IntacctSession getSession() {
        return getSession(null);
    }

    /**
    * @description getSession - 
    * @param Intacct_Integration_Log__c log
    * @return IntacctDataModel.IntacctSession
    */
    public static IntacctDataModel.IntacctSession getSession(Intacct_Integration_Log__c log) {
        if(cachedSession != null) return cachedSession;

		IntacctDataModel.IntacctSettings settings = getSettings();
        IntacctDataModel.ApiRequest apiRequest = new IntacctDataModel.ApiRequest(settings);
        List<String> requests = new List<String>();
        List<String> responses = new List<String>();

        String response = makeHttpCall(settings, apiRequest, requests, responses);

        IntacctDataModel.ApiResponse apiResponse = new IntacctDataModel.ApiResponse(response);
        if(!apiResponse.IsSuccess) {
            log.Request__c = String.join(requests, '\n\n');
            log.Response__c = String.join(responses, '\n\n');
            throw IntacctException.buildException(apiResponse.Error);
        }
        cachedSession = apiResponse.Session;

        return apiResponse.Session;
    }


    /************************ STATUS PROMISES ***********************/

    /**
    * @description class SetStatusPending - 
    */
    @TestVisible
    private class SetStatusPending implements Promise.Deferred {
        private SObject intacctObject;

        /**
        * @description resolve - 
        * @param Object incomingObject
        * @return Object
        */
        public Object resolve(Object incomingObject) {
            //System.debug('setting status of ' + incomingObject + ' to "In Process"');

            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;
            this.intacctObject = (SObject)ios.intacctObject;

            intacctObject.put('Intacct_Sync_Status__c','In Process');
            intacctObject.put('Intacct_Sync_Errors__c',null);
            update intacctObject;

            return ios;
        }
    }

    /**
    * @description class SetStatusCompleted - 
    */
    @TestVisible
    private class SetStatusCompleted implements Promise.Deferred {
        private SObject intacctObject;

        /**
        * @description resolve - 
        * @param Object incomingObject
        * @return Object
        */
        public Object resolve(Object incomingObject) {
            //System.debug('setting status of ' + incomingObject + ' to "OK"');

            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;
            this.intacctObject = (SObject)ios.intacctObject;

            intacctObject.put('Intacct_Sync_Status__c','OK');
            intacctObject.put('Intacct_Sync_Errors__c',null);
            update intacctObject;

            return ios;
        }
    }

    /**
    * @description class SetStatusError - 
    */
    @TestVisible private class SetStatusError implements Promise.Error {
        private SObject intacctObject;
        private Intacct_Integration_Log__c log;

        /**
        * @description error - 
        * @param Exception e
        * @param Object incomingObject
        * @return Object
        */
        public Object error(Exception e, Object incomingObject) {
            //System.debug('setting status of ' + incomingObject + ' to "Error"');
            //System.debug(e.getMessage() + '\n' + e.getStackTraceString());

            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;

            this.intacctObject = ios.intacctObject;

            intacctObject.put('Intacct_Sync_Status__c','Error');
            intacctObject.put('Intacct_Sync_Errors__c',e.getMessage() + '\n' + e.getStackTraceString());
            update intacctObject;

            log = ios.log;
            log.Error__c = e.getMessage() + '\n' + e.getStackTraceString();
            log.Status__c = 'Error';
            saveLog(log);

            return ios;
        }
    }

    /**
    * @description upsertIntacctObjects - 
    * @param List<SObject> intacctObjects
    * @param Promise.Deferred syncPromise
    * @return void
    */
    private static void upsertIntacctObjects(List<SObject> intacctObjects, Promise.Deferred syncPromise) {
        for(SObject intacctObject : intacctObjects) {
            try {
                new Promise(new SetStatusPending())
                    .then(syncPromise)
                    //.then(new SetStatusCompleted())
                    .error(new SetStatusError())
                    .execute(new IntacctObjectSync(intacctObject));
            }
            catch(Exception e) {
                SystemIssueLogHelper.LogException('IntacctIntegrationService', 'upsertIntacctObjects', intacctObjects, e, true);
                System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            }
        }
    }

    /**
    * @description syncIntacctObjects - 
    * @param List<SObject> intacctObjects
    * @param Promise.Deferred syncPromise
    * @return void
    */
    private static void syncIntacctObjects(List<SObject> intacctObjects, Promise.Deferred syncPromise) {  
        if(intacctObjects.isEmpty()) return;

        List<SObject> intactObjectsToSync = new List<SObject>();
        for(SObject intacctObject : intacctObjects) {
            if((Boolean)intacctObject.get('Intacct_Sync__c')) {
                intactObjectsToSync.add(intacctObject);
            }
        }

        if(!intactObjectsToSync.isEmpty()) upsertIntacctObjects(intactObjectsToSync, syncPromise);
    }


    /**
    * @description class IntacctObjectSync
    */
    @TestVisible
    private class IntacctObjectSync {
        public SObject intacctObject {get; private set;}
        public Intacct_Integration_Log__c log {get; private set;}

        /**
        * @description IntacctObjectSync - Constructor
        * @param SObject intacctObject
        */
        public IntacctObjectSync(SObject intacctObject) {
            this.intacctObject = intacctObject;
            log = new Intacct_Integration_Log__c(
                Object__c = intacctObject.getSObjectType().getDescribe().name,
                Object_Id__c = intacctObject.Id
            );
        }
    }

    /**
    * @description saveLog - 
    * @param Intacct_Integration_Log__c log
    * @return void
    */
    private static void saveLog(Intacct_Integration_Log__c log) {
        IntacctDataModel.IntacctSettings settings = getSettings();

        if(!settings.Log) return;
        if(!settings.LogSuccess && log.Status__c != 'Error') return;

        insert log;
    }

    /************************ PROJECTS ***********************/

    /**
    * @description class SyncProjectWithIntacct
    */
    @TestVisible
    private class SyncProjectWithIntacct implements Promise.Deferred {
        private PS_Project__c project;
        private Intacct_Integration_Log__c log;

        /**
        * @description resolve - 
        * @param Object incomingObject
        * @return Object
        */
        public Object resolve(Object incomingObject) {
            //System.debug('syncing ' + incomingObject);
            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;

            this.project = (PS_Project__c)ios.intacctObject;
            this.log = ios.log;

            if(upsertProject(project, log)) {
                update project;
                update project.Milestones__r;
            }

            saveLog(log);
            return ios;
        }
    }

    /**
    * @description syncProjects - 
    * @param Set<Id> projectIds
    * @return void
    */
    public static void syncProjects(Set<Id> projectIds) {
        if(syncingProjects || syncingMilestones || syncingTimeCardEntries) return;
        syncingProjects = true;

        if(projectIds.isEmpty()) return;

        List<PS_Project__c> projects = selectProjectsById(projectIds);

        syncIntacctObjects(projects, new SyncProjectWithIntacct());
    }

    /**
    * @description upsertProject - 
    * @param PS_Project__c project
    * @param Intacct_Integration_Log__c log
    * @return Boolean
    */
    private static Boolean upsertProject(PS_Project__c project, Intacct_Integration_Log__c log) {
        List<String> requests = new List<String>();
        List<String> responses = new List<String>();

		IntacctDataModel.IntacctSettings settings = getSettings();
		IntacctDataModel.IntacctSession session = getSession(log);

        IntacctDataModel.Project intacctProject = new IntacctDataModel.Project(project);
        IntacctDataModel.Operation operation = String.isBlank(project.Intacct_Id__c) ? (IntacctDataModel.Operation)new IntacctDataModel.CreateOperation(intacctProject) : (IntacctDataModel.Operation)new IntacctDataModel.UpdateOperation(intacctProject);
        IntacctDataModel.FunctionRequest functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

        String response = makeHttpCall(settings, functionRequest, requests, responses);

        IntacctDataModel.Project intacctProjectNew = new IntacctDataModel.Project(response);
        if(!intacctProjectNew.IsSuccess) {
            log.Request__c = String.join(requests, '\n\n');
            log.Response__c = String.join(responses, '\n\n');
            throw IntacctException.buildException(intacctProjectNew.Error);
        }

        Boolean modified = intacctProjectNew.fillFields(project);

        // sync project resources
        Set<Id> items = new Set<Id>();
        for(Milestone__c milestone : project.Milestones__r) {
            if(!milestone.Intacct_Sync__c || milestone.ProductId__c == null) continue;
            if(String.isBlank(milestone.Intacct_Resource_Id__c) && items.contains(milestone.ProductId__c)) continue; // sync only one product
            items.add(milestone.ProductId__c);

            IntacctDataModel.ProjectResource intacctProjectResource = new IntacctDataModel.ProjectResource(milestone);
            operation = String.isBlank(milestone.Intacct_Resource_Id__c) ? (IntacctDataModel.Operation)new IntacctDataModel.CreateOperation(intacctProjectResource) : (IntacctDataModel.Operation)new IntacctDataModel.UpdateOperation(intacctProjectResource);
            functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

            response = makeHttpCall(settings, functionRequest, requests, responses);

            IntacctDataModel.ProjectResource intacctProjectResourceNew = new IntacctDataModel.ProjectResource(response);
            if(!intacctProjectResourceNew.IsSuccess) {
                // log.Request__c = String.join(requests, '\n\n');
                // log.Response__c = String.join(responses, '\n\n');
                // throw IntacctException.buildException(intacctProjectResourceNew.Error);
            }

            Boolean resourceModified = intacctProjectResourceNew.fillFields(milestone);
            if(!modified && resourceModified) modified = true;
        }

        log.Request__c = String.join(requests, '\n\n');
        log.Response__c = String.join(responses, '\n\n');

        return modified;
    }


    /************************ MILESTONES ***********************/

    /**
    * @description class SyncMilestoneWithIntacct - 
    */
    @TestVisible
    private class SyncMilestoneWithIntacct implements Promise.Deferred {
        private Milestone__c milestone;
        private Intacct_Integration_Log__c log;

        /**
        * @description resolve - 
        * @param Object incomingObject
        * @return Object
        */
        public Object resolve(Object incomingObject) {
            //System.debug('syncing' + incomingObject);

            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;
            this.milestone = (Milestone__c)ios.intacctObject;
            this.log = ios.log;

            if(upsertMilestone(milestone, log)) {
                update milestone;
            }

            saveLog(log);
            return ios;
        }
    }

    /**
    * @description syncMilestones - 
    * @param Set<Id> milestoneIds
    * @return void
    */
    public static void syncMilestones(Set<Id> milestoneIds) {
        if(syncingMilestones || syncingTimeCardEntries) return;
        syncingMilestones = true;

        if(milestoneIds.isEmpty()) return;
        List<Milestone__c> milestones = selectMilestonesById(milestoneIds);

        syncIntacctObjects(milestones, new SyncMilestoneWithIntacct());
    }

    /**
    * @description upsertMilestone - 
    * @param Milestone__c milestone
    * @param Intacct_Integration_Log__c log
    * @return Boolean    
    */
    private static Boolean upsertMilestone(Milestone__c milestone, Intacct_Integration_Log__c log) {
        List<String> requests = new List<String>();
        List<String> responses = new List<String>();

		IntacctDataModel.IntacctSettings settings = getSettings();
		IntacctDataModel.IntacctSession session = getSession(log);

        // sync as a Task
        IntacctDataModel.Milestone intacctMilestone = new IntacctDataModel.Milestone(milestone);
        IntacctDataModel.Operation operation = String.isBlank(milestone.Intacct_Id__c) ? (IntacctDataModel.Operation)new IntacctDataModel.CreateOperation(intacctMilestone) : (IntacctDataModel.Operation)new IntacctDataModel.UpdateOperation(intacctMilestone);
        IntacctDataModel.FunctionRequest functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

        String response = makeHttpCall(settings, functionRequest, requests, responses);

        IntacctDataModel.Milestone intacctMilestoneNew = new IntacctDataModel.Milestone(response);
        if(!intacctMilestoneNew.IsSuccess) {
            log.Request__c = String.join(requests, '\n\n');
            log.Response__c = String.join(responses, '\n\n');
            throw IntacctException.buildException(intacctMilestoneNew.Error);
        }
        Boolean taskModified = intacctMilestoneNew.fillFields(milestone);

        // sync as a Project Resource
        Map<String,Milestone__c> projectResourceIdToMilestoneMap = new Map<String,Milestone__c>();
        List<Milestone__c> milestones = selectMilestonesByProjectId(milestone.ProjectId__c);
        for(Milestone__c existingMilestone : milestones) {
            if(existingMilestone.Id == milestone.Id) continue;
            if(String.isNotBlank(existingMilestone.Intacct_Resource_Id__c)) {
                projectResourceIdToMilestoneMap.put(existingMilestone.Intacct_Resource_Id__c,existingMilestone);
            }
        }

        IntacctDataModel.ProjectResource intacctProjectResource = new IntacctDataModel.ProjectResource(milestone);
        operation = String.isBlank(milestone.Intacct_Resource_Id__c) ? (IntacctDataModel.Operation)new IntacctDataModel.CreateOperation(intacctProjectResource) : (IntacctDataModel.Operation)new IntacctDataModel.UpdateOperation(intacctProjectResource);
        functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

        response = makeHttpCall(settings, functionRequest, requests, responses);

        IntacctDataModel.ProjectResource intacctProjectResourceNew = new IntacctDataModel.ProjectResource(response);
        if(!intacctProjectResourceNew.IsSuccess) {
            log.Request__c = String.join(requests, '\n\n');
            log.Response__c = String.join(responses, '\n\n');
            throw IntacctException.buildException(intacctProjectResourceNew.Error);
        }

        Boolean resourceModified = false;
        if(!projectResourceIdToMilestoneMap.containsKey(intacctProjectResourceNew.Id)) { // update the resource Id only if not exists already. Intacct only has one resource per product
            resourceModified = intacctProjectResourceNew.fillFields(milestone);
        }

        log.Request__c = String.join(requests, '\n\n');
        log.Response__c = String.join(responses, '\n\n');

        return taskModified || resourceModified;
    }


    /************************ TIME CARD ENTRIES ***********************/

    /**
    * @description class SetTimeCardStatusPending
    */
    @TestVisible
    private class SetTimeCardStatusPending implements Promise.Deferred {
        private Time_Card_Header__c timeCardHeader;
        private Intacct_Integration_Log__c log;

        /**
        * @description resolve - 
        * @param Object incomingObject
        * @return Object
        */
        public Object resolve(Object incomingObject) {
            //System.debug('setting status of ' + incomingObject + ' to "In Process"');

            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;

            this.timeCardHeader = (Time_Card_Header__c)ios.intacctObject;
            this.log = ios.log;

            timeCardHeader.Intacct_Sync_Status__c = 'In Process';
            timeCardHeader.Intacct_Sync_Errors__c = null;
            update timeCardHeader;

            for(Time_Card_Entry__c timeCardEntry : timeCardHeader.Time_Card_Entries__r) {
                timeCardEntry.Intacct_Sync_Status__c = 'In Process';
                timeCardEntry.Intacct_Sync_Errors__c = null;
            }
            update timeCardHeader.Time_Card_Entries__r;
            return ios;
        }
    }

    /**
    * @description class SetTimeCardStatusError
    */
    @TestVisible
    private class SetTimeCardStatusError implements Promise.Error {
        private Time_Card_Header__c timeCardHeader;
        private Intacct_Integration_Log__c log;

        /**
        * @description error - 
        * @param Exception e
        * @param Object incomingObject
        * @return Object
        */
        public Object error(Exception e, Object incomingObject) {
            //System.debug('setting status of ' + incomingObject + ' to "Error"');

            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;
            this.timeCardHeader = (Time_Card_Header__c)ios.intacctObject;

            timeCardHeader.Intacct_Sync_Status__c = 'Error';
            timeCardHeader.Intacct_Sync_Errors__c = e.getMessage() + '\n' + e.getStackTraceString();
            update timeCardHeader;

            for(Time_Card_Entry__c timeCardEntry : timeCardHeader.Time_Card_Entries__r) {
                timeCardEntry.Intacct_Sync_Status__c = 'Error';
                timeCardEntry.Intacct_Sync_Errors__c = timeCardHeader.Intacct_Sync_Errors__c;
            }
            update timeCardHeader.Time_Card_Entries__r;

            log = ios.log;
            log.Error__c = e.getMessage() + '\n' + e.getStackTraceString();
            log.Status__c = 'Error';
            saveLog(log);

            return ios;
        }
    }

    /**
    * @description class SyncTimeCardHeadersWithIntacct
    */
    @TestVisible
    private class SyncTimeCardHeadersWithIntacct implements Promise.Deferred {
        private Time_Card_Header__c timeCardHeader;
        private Intacct_Integration_Log__c log;

        /**
        * @description resolve - 
        * @param Object incomingObject
        * @return Object
        */
        public Object resolve(Object incomingObject) {
            //System.debug('syncing ' + incomingObject);

            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;
            this.timeCardHeader = (Time_Card_Header__c)ios.intacctObject;
            this.log = ios.log;

            if(upsertTimeCardHeader(timeCardHeader, log)) {
                update timeCardHeader;
                update timeCardHeader.Time_Card_Entries__r;
            }

            saveLog(log);
            return ios;
        }
    }

    /**
    * @description syncTimeCardEntries - 
    * @param Set<Id> timeCardEntryIds
    * @return void
    */
    public static void syncTimeCardEntries(Set<Id> timeCardEntryIds) {
        syncingTimeCardEntries = true;

        if(timeCardEntryIds.isEmpty()) return;
        List<Time_Card_Entry__c> timeCardEntries = selectTimeCardEntriesById(timeCardEntryIds);

        List<Time_Card_Header__c> timeCardHeaders = getTimeCardHeadersByEntries(timeCardEntries);
        if(timeCardHeaders.isEmpty()) return;

        for(Time_Card_Header__c timeCardHeader : timeCardHeaders) {
            try {
                new Promise(new SetTimeCardStatusPending())
                    .then(new SyncTimeCardHeadersWithIntacct())
                    .error(new SetTimeCardStatusError())
                    .execute(new IntacctObjectSync(timeCardHeader));
            }
            catch(Exception e) {
                SystemIssueLogHelper.LogException('IntacctIntegrationService', 'syncTimeCardEntries', timeCardEntryIds, e, true);
                System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            }
        }

        syncingTimeCardEntries = false;
    }

    /*
     * @description
     */
    public static void syncTimeCardHeaders(Set<Id> timeCardHeaderIds) {
        syncingTimeCardEntries = true;

        if(timeCardHeaderIds.isEmpty()) return;
        List<Time_Card_Header__c> timeCardHeaders = selectTimeCardHeadersById(timeCardHeaderIds);
        if(timeCardHeaders.isEmpty()) return;

        for(Time_Card_Header__c timeCardHeader : timeCardHeaders) {
            try {
                new Promise(new SetTimeCardStatusPending())
                    .then(new SyncTimeCardHeadersWithIntacct())
                    .error(new SetTimeCardStatusError())
                    .execute(new IntacctObjectSync(timeCardHeader));
            }
            catch(Exception e) {
                SystemIssueLogHelper.LogException('IntacctIntegrationService', 'syncTimeCardHeaders', timeCardHeaderIds, e, true);
                System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            }
        }

        syncingTimeCardEntries = false;
    }

    /**
    * @description upsertTimeCardHeader - 
    * @param Time_Card_Header__c timeCardHeader
    * @param Intacct_Integration_Log__c log
    * @return Boolean
    */
    private static Boolean upsertTimeCardHeader(Time_Card_Header__c timeCardHeader, Intacct_Integration_Log__c log) {
        List<String> requests = new List<String>();
        List<String> responses = new List<String>();

		IntacctDataModel.IntacctSettings settings = getSettings();
		IntacctDataModel.IntacctSession session = getSession(log);

        IntacctDataModel.TimeCardHeader intacctTimeCardHeader = new IntacctDataModel.TimeCardHeader(timeCardHeader);
        if(intacctTimeCardHeader.TimeCardEntries.isEmpty()) {
            timeCardHeader.Intacct_Sync_Status__c = 'OK';
            timeCardHeader.Intacct_Sync_Errors__c = null;
            return true;
        }

        IntacctDataModel.Operation operation = String.isBlank(TimeCardHeader.Intacct_Id__c) ? (IntacctDataModel.Operation)new IntacctDataModel.CreateOperation(intacctTimeCardHeader) : (IntacctDataModel.Operation)new IntacctDataModel.UpdateOperation(intacctTimeCardHeader);
        IntacctDataModel.FunctionRequest functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

        String response = makeHttpCall(settings, functionRequest, requests, responses);
        log.Request__c = String.join(requests, '\n\n');
        log.Response__c = String.join(responses, '\n\n');

        IntacctDataModel.TimeCardHeader intacctTimeCardHeaderNew = new IntacctDataModel.TimeCardHeader(response);
        if(!intacctTimeCardHeaderNew.IsSuccess) {
            throw IntacctException.buildException(intacctTimeCardHeaderNew.Error);
        }

        return intacctTimeCardHeaderNew.fillFields(timeCardHeader);
    }

    /**
    * @description getTimeSheetEntryId - 
    * @param String timeSheetId
    * @param Id timeCardEntryId
    * @return String
    */
    public static String getTimeSheetEntryId(String timeSheetId, Id timeCardEntryId) {
		IntacctDataModel.IntacctSettings settings = getSettings();
		IntacctDataModel.IntacctSession session = getSession();

        IntacctDataModel.TimeSheetEntryQuery intacctTimeSheetEntryQuery = new IntacctDataModel.TimeSheetEntryQuery(timeSheetId, timeCardEntryId);
        IntacctDataModel.Operation operation = (IntacctDataModel.Operation)new IntacctDataModel.QueryOperation(intacctTimeSheetEntryQuery);
        IntacctDataModel.FunctionRequest functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

        String response = makeHttpCall(settings, functionRequest);

        IntacctDataModel.TimeSheetEntryQueryResponse intacctTimeSheetEntryQueryResponse = new IntacctDataModel.TimeSheetEntryQueryResponse(response);
        if(!intacctTimeSheetEntryQueryResponse.IsSuccess) {
            throw IntacctException.buildException(intacctTimeSheetEntryQueryResponse.Error);
        }

        return intacctTimeSheetEntryQueryResponse.Id;
    }

    private static Map<String,String> revenueDivisionsCache = new Map<String,String>();

    /**
    * @description getRevenueDivisionId - 
    * @param String revenueDivisionName
    * @return String
    */
    public static String getRevenueDivisionId(String revenueDivisionName) {
        if(revenueDivisionsCache.containsKey(revenueDivisionName)) return revenueDivisionsCache.get(revenueDivisionName);

        String revenueDivisionCode = '';

		IntacctDataModel.IntacctSettings settings = getSettings();
		IntacctDataModel.IntacctSession session = getSession();

        IntacctDataModel.RevenueDivisionQuery intacctRevenueDivisionQuery = new IntacctDataModel.RevenueDivisionQuery(revenueDivisionName);
        IntacctDataModel.Operation operation = (IntacctDataModel.Operation)new IntacctDataModel.QueryOperation(intacctRevenueDivisionQuery);
        IntacctDataModel.FunctionRequest functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

        String response = makeHttpCall(settings, functionRequest);

        IntacctDataModel.RevenueDivisionResponse intacctRevenueDivisionResponse = new IntacctDataModel.RevenueDivisionResponse(response);
        if(intacctRevenueDivisionResponse.IsSuccess) {
            revenueDivisionCode = intacctRevenueDivisionResponse.Id;

            revenueDivisionsCache.put(revenueDivisionName, revenueDivisionCode);
        }

        return revenueDivisionCode;
    }

    /************************ INTACCT CONTRACT LINES ***********************/

    /**
    * @description class SyncContractLineWithIntacct - 
    */
    @TestVisible
    private class SyncContractLineWithIntacct implements Promise.Deferred {
        private ia_crm__Intacct_Contract_Line__c contractLine;
        private Intacct_Integration_Log__c log;

        /**
        * @description resolve - 
        * @param Object incomingObject
        * @return Object
        */
        public Object resolve(Object incomingObject) {
            //System.debug('syncing ' + incomingObject);

            IntacctObjectSync ios = (IntacctObjectSync)incomingObject;
            this.contractLine = (ia_crm__Intacct_Contract_Line__c)ios.intacctObject;
            this.log = ios.log;

            if(upsertContractLine(contractLine, log)) {
                update contractLine;
            }

            saveLog(log);
            return contractLine;
        }
    }

    /**
    * @description syncIntacctContractLines - 
    * @param Set<Id> contractLineIds
    * @return void
    */
    public static void syncIntacctContractLines(Set<Id> contractLineIds) {
        Map<Id,List<ia_crm__Intacct_Contract_Line__c>> opportunityIdTocontractLinesMap = getContractLines(contractLineIds);

        // get the milestones
        Set<Id> opportunityIds = opportunityIdTocontractLinesMap.keySet();
        Map<Id,List<Milestone__c>> opportunityIdToMilestonesMap = getMilestones(opportunityIds);

        // update project and milestone on contrat lines
        List<ia_crm__Intacct_Contract_Line__c> contractLinesToSendToIntacct = new List<ia_crm__Intacct_Contract_Line__c>();
        for(Id opportunityId : opportunityIds) {
            List<ia_crm__Intacct_Contract_Line__c> contractLines = opportunityIdTocontractLinesMap.get(opportunityId);
            List<Milestone__c> milestones = opportunityIdToMilestonesMap.get(opportunityId);
            if(milestones == null) continue;

            for(ia_crm__Intacct_Contract_Line__c contractLine : contractLines) {
                for(Milestone__c milestone : milestones) {
                    if(contractLine.ia_crm__Item__c == milestone.ProductId__c) {
                        contractLine.ProjectId__c = milestone.ProjectId__c;
                        contractLine.ProjectId__r = milestone.ProjectId__r;
                        contractLine.MilestoneId__c = milestone.Id;
                        contractLinesToSendToIntacct.add(contractLine);
                        break;
                    }
                }
            }

        }

        // send update to Intacct
        for(ia_crm__Intacct_Contract_Line__c contractLine : contractLinesToSendToIntacct) {
            new Promise(new SetStatusPending())
                	.then(new SyncContractLineWithIntacct())
                	.error(new SetStatusError())
                    .execute(new IntacctObjectSync(contractLine));
        }
    }

    /**
    * @description upsertContractLine - 
    * @param ia_crm__Intacct_Contract_Line__c contractLine
    * @param Intacct_Integration_Log__c log
    * @return Boolean
    */
    private static Boolean upsertContractLine(ia_crm__Intacct_Contract_Line__c contractLine, Intacct_Integration_Log__c log) {
        IntacctDataModel.IntacctSettings settings = getSettings();
		IntacctDataModel.IntacctSession session = getSession(log);

        IntacctDataModel.ContractLine intacctContractLine = new IntacctDataModel.ContractLine(contractLine);
        IntacctDataModel.Operation operation = (IntacctDataModel.Operation)new IntacctDataModel.UpdateOperation(intacctContractLine);
        IntacctDataModel.FunctionRequest functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

        List<String> requests = new List<String>();
        List<String> responses = new List<String>();

        String response = makeHttpCall(settings, functionRequest, requests, responses);

        log.Request__c = String.join(requests, '\n\n');
        log.Response__c = String.join(responses, '\n\n');

        IntacctDataModel.ContractLine intacctContractLineNew = new IntacctDataModel.ContractLine(response);
        if(!intacctContractLineNew.IsSuccess) {
            throw IntacctException.buildException(intacctContractLineNew.Error);
        }

        return intacctContractLineNew.fillFields(contractLine);
    }

    /**
    * @description getContractLineId - 
    * @param String contractId
    * @param String lineNumber
    * @return String
    */
    public static String getContractLineId(String contractId, String lineNumber) {
        IntacctDataModel.IntacctSettings settings = getSettings();
		IntacctDataModel.IntacctSession session = getSession();

        IntacctDataModel.ContractLineQuery intacctContractLineQuery = new IntacctDataModel.ContractLineQuery(contractId, lineNumber);
        IntacctDataModel.Operation operation = (IntacctDataModel.Operation)new IntacctDataModel.QueryOperation(intacctContractLineQuery);
        IntacctDataModel.FunctionRequest functionRequest = new IntacctDataModel.FunctionRequest(settings, session, operation);

        String response = makeHttpCall(settings, functionRequest);

        IntacctDataModel.ContractLineQueryResponse intacctContractLineQueryResponse = new IntacctDataModel.ContractLineQueryResponse(response);
        if(!intacctContractLineQueryResponse.IsSuccess) {
            throw IntacctException.buildException(intacctContractLineQueryResponse.Error);
        }

        return intacctContractLineQueryResponse.Id;
    }



    /************************ INTACCT PROJECT ***********************/

    /**
    * @description syncIntacctProjects - 
    * @param Set<Id> projectIds
    * @return void
    */
    public static void syncIntacctProjects(Set<Id> projectIds) {
        List<ia_crm__Project__c> projects = selectIntacctProjectsByIds(projectIds);
        Map<Id,List<ia_crm__Task__c>> intacctProjectIdToTasks = getIntacctTasks(projectIds);

        // get matching PS Projects
        Set<String> intacctIds = new Set<String>();
        for(ia_crm__Project__c project : projects) {
            if(project.ia_crm__Project_ID__c != null) intacctIds.add(project.ia_crm__Project_ID__c);
        }
        Map<String,PS_Project__c> psProjects = getProjectsByIntacctId(intacctIds);

        // set the opportunity
        List<ia_crm__Project__c> projectsToUpdate = new List<ia_crm__Project__c>();
        for(ia_crm__Project__c project : projects) {
            if(project.ia_crm__Opportunity__c == null && psProjects.containsKey(project.ia_crm__Project_ID__c)) {
                PS_Project__c psProject = psProjects.get(project.ia_crm__Project_ID__c);
                Boolean isDirty = false;
                if(project.ia_crm__Opportunity__c != psProject.OpportunityId__c) {
                    project.ia_crm__Opportunity__c = psProject.OpportunityId__c;
                    isDirty = true;
                }
                if(project.PS_Project__c != psProject.Id) {
                    project.PS_Project__c = psProject.Id;
                    isDirty = true;
                }
                if(isDirty) projectsToUpdate.add(project);
            }
        }

        Set<Id> opportunityIds = new Set<Id>();
        for(ia_crm__Project__c project : projects) {
            if(project.ia_crm__Opportunity__c != null) opportunityIds.add(project.ia_crm__Opportunity__c);
        }

        Map<Id,List<OpportunityLineItem>> opportunityIdToOpportunityLineItemsMap = getOpportunityLineItemsByOpportunityIds(opportunityIds);
        Map<Id,List<Milestone__c>> opportunityIdToMilestonesMap = getMilestones(opportunityIds);
        Map<Id,OpportunityLineItem> updatedOpportunityLineItems = new Map<Id,OpportunityLineItem>();

        for(ia_crm__Project__c project : projects) {
            List<ia_crm__Task__c> tasks = intacctProjectIdToTasks.get(project.Id);

            if(project.ia_crm__Opportunity__c == null) continue;
            List<OpportunityLineItem> opportunityLineItems = opportunityIdToOpportunityLineItemsMap.get(project.ia_crm__Opportunity__c);
            if(opportunityLineItems == null || opportunityLineItems.isEmpty()) continue;
            List<Milestone__c> milestones = opportunityIdToMilestonesMap.get(project.ia_crm__Opportunity__c);
            if(milestones == null || milestones.isEmpty()) continue;

            for(OpportunityLineItem oli : opportunityLineItems) {
                for(Milestone__c milestone : milestones) {
                    if(oli.Product2Id == milestone.ProductId__c && milestone.ProjectId__r.Intacct_Project_Id__c == project.ia_crm__Project_ID__c) {
                        if(oli.ia_crm__Project__c != project.Id) {
                            oli.ia_crm__Project__c = project.Id;
                            oli.PS_Project__c = project.PS_Project__c;
                            // oli.ia_crm__Contract_Line_Save_Cancel_He__c = null;
                            // oli.ia_crm__Billing_Method__c = 'Project time & materials';
                            // oli.ia_crm__Billing_Template__c = null;
                            updatedOpportunityLineItems.put(oli.Id, oli);
                        }

                        ia_crm__Task__c taskForMilestone = null;
                        if(tasks != null) {
                            for(ia_crm__Task__c task : tasks) {
                                if(task.Name == milestone.Name) {
                                    taskForMilestone = task;
                                    break;
                                }
                            }
                        }
                        if(taskForMilestone != null && oli.ia_crm__Task__c != taskForMilestone.Id) {
                            oli.ia_crm__Task__c = taskForMilestone.Id;
                            updatedOpportunityLineItems.put(oli.Id, oli);
                        }
                    }
                }
            }
        }

        if(!projectsToUpdate.isEmpty()) update projectsToUpdate;
        if(!updatedOpportunityLineItems.isEmpty()) update updatedOpportunityLineItems.values();
    }



    /************************ PRIVATE METHODS ***********************/

    /**
    * @description makeHttpCall - 
    * @param IntacctDataModel.IntacctSettings settings
    * @param IntacctDataModel.Request intacctRequest
    * @return String
    */
    private static String makeHttpCall(IntacctDataModel.IntacctSettings settings, IntacctDataModel.Request intacctRequest) {
        List<String> requests = new List<String>();
        List<String> responses = new List<String>();
        return makeHttpCall(settings, intacctRequest, requests, responses);
    }

    /**
    * @description makeHttpCall - 
    * @param IntacctDataModel.IntacctSettings settings
    * @param IntacctDataModel.Request intacctRequest
    * @param List<String> requests
    * @param List<String> responses
    * @return String
    */
    private static String makeHttpCall(IntacctDataModel.IntacctSettings settings, IntacctDataModel.Request intacctRequest, List<String> requests, List<String> responses) {    
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(settings.EndpointUrl);
        request.setHeader('Content-Type','text/xml');
        request.setTimeout(HTTP_TIMEOUT);

        String body = intacctRequest.toXML();
        requests.add(body);
        //System.debug('Sending Intacct Request: ' + body);
    	request.setBody(body);

        HttpResponse response = http.send(request);

        String intacctResponse = response.getBody();
        responses.add(intacctResponse);
        //System.debug('Receiving Intacct Response: ' + response.getStatusCode() + ',' + response.getStatus());
		//System.debug('Receiving Intacct Response: ' + intacctResponse);

        if(response.getStatusCode() != 200) {
            throw new IntacctException(String.format(label.INTACCT_Error_Http, new String[] { String.valueOf(response.getStatusCode()), response.getStatus() }));
        }

    	return intacctResponse;
    }

    /************************ ADVANCED SELECTORS ***********************/

    /**
    * @description makeHttpCall - 
    * @param IntacctDataModel.IntacctSettings settings
    * @param IntacctDataModel.Request intacctRequest
    * @return String
    */
    private static List<Time_Card_Header__c> getTimeCardHeadersByEntries(List<Time_Card_Entry__c> timeCardEntries) {

        Set<Id> timeCardHeaderIds = new Set<Id>();
        for(Time_Card_Entry__c timeCardEntry : timeCardEntries) {
            if(timeCardEntry.Intacct_Sync__c && timeCardEntry.Time_Card_HeaderId__c != null) {
                timeCardHeaderIds.add(timeCardEntry.Time_Card_HeaderId__c);
            }
        }

        List<Time_Card_Header__c> timeCardHeaders = selectTimeCardHeadersById(timeCardHeaderIds);

        return timeCardHeaders;
    }

    /**
    * @description getContractLines - 
    * @param Set<Id> contractLineIds)
    * @return Map<Id,List<ia_crm__Intacct_Contract_Line__c>>
    */
    private static Map<Id,List<ia_crm__Intacct_Contract_Line__c>> getContractLines(Set<Id> contractLineIds) {
        Map<Id,List<ia_crm__Intacct_Contract_Line__c>> opportunityIdTocontractLinesMap = new Map<Id,List<ia_crm__Intacct_Contract_Line__c>>();

        List<ia_crm__Intacct_Contract_Line__c> contractLines = selectContractLinesByIds(contractLineIds);
        for(ia_crm__Intacct_Contract_Line__c contractLine : contractLines) {
            if(!opportunityIdTocontractLinesMap.containsKey(contractLine.ia_crm__Opportunity__c)) opportunityIdTocontractLinesMap.put(contractLine.ia_crm__Opportunity__c, new List<ia_crm__Intacct_Contract_Line__c>());
            opportunityIdTocontractLinesMap.get(contractLine.ia_crm__Opportunity__c).add(contractLine);
        }

        return opportunityIdTocontractLinesMap;
    }

    /**
    * @description getMilestones - 
    * @param Set<Id> opportunityIds
    * @return Map<Id,List<Milestone__c>>
    */
    private static Map<Id,List<Milestone__c>> getMilestones(Set<Id> opportunityIds) {
        Map<Id,List<Milestone__c>> opportunityIdToMilestonesMap = new Map<Id,List<Milestone__c>>();

        List<Milestone__c> milestones = selectMilestonesForOpportunityIds(opportunityIds);
        for(Milestone__c m : milestones) {
            if(m.ProjectId__r.OpportunityId__c == null) continue;
            if(!opportunityIdToMilestonesMap.containsKey(m.ProjectId__r.OpportunityId__c)) opportunityIdToMilestonesMap.put(m.ProjectId__r.OpportunityId__c, new List<Milestone__c>());
            opportunityIdToMilestonesMap.get(m.ProjectId__r.OpportunityId__c).add(m);
        }

        return opportunityIdToMilestonesMap;
    }

    /**
    * @description getOpportunityLineItemsByOpportunityIds - 
    * @param Set<Id> opportunityIds
    * @return Map<Id,List<OpportunityLineItem>>
    */
    private static Map<Id,List<OpportunityLineItem>> getOpportunityLineItemsByOpportunityIds(Set<Id> opportunityIds) {
        Map<Id,List<OpportunityLineItem>> opportunityIdToOpportunityLineItems = new Map<Id,List<OpportunityLineItem>>();

        List<OpportunityLineItem> opportunityLineItems = selectOpportunityLineItemsByOpportunityIds(opportunityIds);
        for(OpportunityLineItem oli : opportunityLineItems) {
            if(!opportunityIdToOpportunityLineItems.containsKey(oli.opportunityId)) opportunityIdToOpportunityLineItems.put(oli.OpportunityId, new List<OpportunityLineItem>());
            opportunityIdToOpportunityLineItems.get(oli.OpportunityId).add(oli);
        }

        return opportunityIdToOpportunityLineItems;
    }

    /**
    * @description getProjectsByIntacctId - 
    * @param Set<String> intacctIds
    * @return Map<String, PS_Project__c>
    */
    private static Map<String,PS_Project__c> getProjectsByIntacctId(Set<String> intacctIds) {
        Map<String,PS_Project__c> intacctIdToProject = new Map<String,PS_Project__c>();

        List<PS_Project__c> projects = selectProjectsByIntacctId(intacctIds);
        for(PS_Project__c project : projects) {
            intacctIdToProject.put(project.Intacct_Project_Id__c, project);
        }

        return intacctIdToProject;
    }

    /**
    * @description getIntacctTasks - 
    * @param Set<Id> projectIds
    * @return Map<Id, List<ia_crm__Task__c>>
    */
    private static Map<Id,List<ia_crm__Task__c>> getIntacctTasks(Set<Id> projectIds) {
        Map<Id,List<ia_crm__Task__c>> intacctProjectIdToTasks = new Map<Id,List<ia_crm__Task__c>>();

        List<ia_crm__Task__c> tasks = selectIntacctTasksByProjectIds(projectIds);
        for(ia_crm__Task__c task : tasks) {
            if(!intacctProjectIdToTasks.containsKey(task.ia_crm__Project__c)) intacctProjectIdToTasks.put(task.ia_crm__Project__c, new List<ia_crm__Task__c>());
            intacctProjectIdToTasks.get(task.ia_crm__Project__c).add(task);
        }

        return intacctProjectIdToTasks;
    }

    /************************ SELECTORS ***********************/

    /**
    * @description selectProjectsById - 
    * @param Set<Id> projectIds
    * @return List<PS_Project__c>
    */
    @TestVisible
    private static List<PS_Project__c> selectProjectsById(Set<Id> projectIds) {
        return [
            SELECT
                Id,
                Name,
                Intacct_User_Id__c,
                Description__c,
                Is_Active__c,
                Intacct_Sync__c,
                Intacct_Id__c,
                Intacct_Sync_Status__c,
                Intacct_Sync_Errors__c,
                Intacct_Project_Id__c,
            	AccountId__c,
            	AccountId__r.ia_crm__IntacctID__c,
            	Execution__c,
            	Expiration_Date__c,
            	Agreement_Type__c,
            	Project_ManagerId__c,
            	Project_ManagerId__r.Intacct_Id__c,
            	Payment_Terms__c,
            	OpportunityId__c,
                OpportunityId__r.ContractId,
            	OpportunityId__r.ia_crm__Intacct_Entity_Id__c,
            	Billing_Type__c,
            	Hours_EstimatedFx__c,
                Purchase_Order__c,
                (
                    SELECT
                        Id,
                        Intacct_Sync__c,
                        Intacct_Resource_Id__c,
                        ProductId__c,
                        ProductId__r.ProductCode,
                        Effective_Hourly_Rate__c,
                        ProjectId__r.Intacct_Id__c
                    FROM
                        Milestones__r
                    ORDER BY
                        Intacct_Resource_Id__c DESC NULLS LAST
                ),
                (
                    SELECT
                        Id,
                        Contact__c,
                        Contact__r.ia_crm__Intacct_Contact_ID__c,
                        Role__c
                    FROM
                        Project_Teams__r
                )
            FROM
                PS_Project__c
            WHERE
                Id IN :projectIds
        ];
    }

    /**
    * @description selectProjectsByIntacctId - 
    * @param Set<String> intacctIds
    * @return List<PS_Project__c>
    */
    private static List<PS_Project__c> selectProjectsByIntacctId(Set<String> intacctIds) {
        return [
            SELECT
                Id,
                Name,
                Intacct_Id__c,
                Intacct_Project_Id__c,
            	OpportunityId__c
            FROM
                PS_Project__c
            WHERE
                Intacct_Project_Id__c IN :intacctIds
        ];
    }

    /**
    * @description selectMilestonesById - 
    * @param List<Milestone__c>
    * @return Set<Id> milestoneIds
    */
    @TestVisible
    private static List<Milestone__c> selectMilestonesById(Set<Id> milestoneIds) {
        return [
            SELECT
                Id,
                Name,
                ProjectId__r.Intacct_Id__c,
                ProjectId__r.Intacct_Project_Id__c,
                IsActive__c,
                Intacct_Sync__c,
                Intacct_Sync_Status__c,
                Intacct_Id__c,
            	Is_Billable__c,
            	ProductId__c,
            	ProductId__r.ProductCode,
            	Hours_Currently_Budgeted__c,
                Effective_Hourly_Rate__c,
                Intacct_Resource_Id__c
            FROM
                Milestone__c
            WHERE
                Id IN :milestoneIds
        ];
    }

    /**
    * @description selectMilestonesByProjectId - 
    * @param Id projectId
    * @return List<Milestone__c>
    */
    @TestVisible
    private static List<Milestone__c> selectMilestonesByProjectId(Id projectId) {
        return [
            SELECT
                Id,
                Name,
                Intacct_Resource_Id__c
            FROM
                Milestone__c
            WHERE
                ProjectId__c = :projectId
        ];
    }

    /**
    * @description selectTimeCardEntriesById - 
    * @param Set<Id> timeCardEntryIds
    * @return List<Time_Card_Entry__c>
    */
    public static List<Time_Card_Entry__c> selectTimeCardEntriesById(Set<Id> timeCardEntryIds) {
        return [
            SELECT
                Id,
                Name,
                Time_Card_HeaderId__c,
                Time_Card_HeaderId__r.Intacct_Id__c,
                Time_Card_HeaderId__r.Start_Date__c,
                Time_Card_HeaderId__r.Status__c,
                Time_Card_HeaderId__r.UserId__c,
                Time_Card_HeaderId__r.UserId__r.Intacct_Id__c,
                Time_Card_HeaderId__r.UserId__r.Intacct_Entity_Id__c,
                Time_Card_HeaderId__r.PeriodId__c,
                ProjectId__c,
                ProjectId__r.Intacct_Id__c,
                ProjectId__r.Intacct_Project_Id__c,
                MilestoneId__c,
                MilestoneId__r.Intacct_Id__c,
                Notes__c,
                Hours_Entered__c,
                Date_Entered__c,
                Intacct_Sync__c,
                Intacct_Id__c
            FROM
                Time_Card_Entry__c
            WHERE
                Id IN :timeCardEntryIds
        ];
    }

    /**
    * @description selectTimeCardHeadersById - 
    * @param Set<Id> timeCardHeaderIds
    * @return List<Time_Card_Header__c>
    */
    public static List<Time_Card_Header__c> selectTimeCardHeadersById(Set<Id> timeCardHeaderIds) {
        return [
            SELECT
                Id,
                Name,
                Intacct_Id__c,
                Intacct_Sync__c,
                Intacct_Sync_Status__c,
                Start_Date__c,
                Status__c,
                UserId__c,
                UserId__r.Intacct_Id__c,
                UserId__r.Intacct_Entity_Id__c,
                PeriodId__c,
                (
                    SELECT
                        Id,
                        Name,
                        ProjectId__c,
                        ProjectId__r.Intacct_Id__c,
                        ProjectId__r.Intacct_Project_Id__c,
                        MilestoneId__c,
                        MilestoneId__r.Intacct_Id__c,
                        MilestoneId__r.ProductId__r.LOB__c,
                        Time_Card_HeaderId__r.UserId__c,
                        Time_Card_HeaderId__r.UserId__r.Intacct_Id__c,
                        Time_Card_HeaderId__r.UserId__r.Intacct_Entity_Id__c,
                        Notes__c,
                        Hours_Entered__c,
                        Date_Entered__c,
                        Intacct_Sync__c,
                        Intacct_Sync_Status__c,
                        Intacct_Id__c,
                        ProjectId__r.OpportunityId__r.Contract.ia_crm__Intacct_Contract__r.ia_crm__Contract_ID__c
                    FROM
                        Time_Card_Entries__r
                    WHERE
                        Intacct_Sync__c = true
                )
            FROM
                Time_Card_Header__c
            WHERE
                Id IN :timeCardHeaderIds
        ];
    }

    /**
    * @description selectContractLinesByIds - 
    * @param Set<Id> contractLineIds
    * @return List<ia_crm__Intacct_Contract_Line__c>
    */
    @TestVisible
    private static List<ia_crm__Intacct_Contract_Line__c> selectContractLinesByIds(Set<Id> contractLineIds) {
        return [
            SELECT
                Id,
                Name,
                ia_crm__Line_number__c,
                ia_crm__Item__c,
                ia_crm__Opportunity__c,
                ProjectId__c,
                ProjectId__r.Intacct_Project_Id__c,
                MilestoneId__c,
                ia_crm__Intacct_Contract__c,
                ia_crm__Intacct_Contract__r.ia_crm__Contract_ID__c,
            	Intacct_Sync_Status__c,
            	Intacct_Sync_Errors__c
            FROM
                ia_crm__Intacct_Contract_Line__c
            WHERE
                Id IN :contractLineIds
            ORDER BY ia_crm__Intacct_Contract__c,ia_crm__Line_number__c
        ];
    }

    /**
    * @description selectMilestonesForOpportunityIds - 
    * @param Set<Id> opportunityIds
    * @return List<Milestone__c>
    */
    private static List<Milestone__c> selectMilestonesForOpportunityIds(Set<Id> opportunityIds) {
        return [
            SELECT
                Id,
                Name,
                ProjectId__c,
            	ProjectId__r.OpportunityId__c,
            	ProjectId__r.Intacct_Id__c,
            	ProjectId__r.Intacct_Project_Id__c,
            	ProductId__c
            FROM
                Milestone__c
            WHERE
                ProjectId__r.OpportunityId__c IN :opportunityIds
            ORDER BY ProjectId__r.OpportunityId__c
        ];
    }

    /**
    * @description selectIntacctProjectsByIds - 
    * @param Set<Id> projectIds
    * @return List<ia_crm__Project__c>
    */
    private static List<ia_crm__Project__c> selectIntacctProjectsByIds(Set<Id> projectIds) {
        return [
            SELECT
                Id,
                Name,
                ia_crm__Customer__c,
                ia_crm__Project_ID__c,
                ia_crm__Opportunity__c,
                PS_Project__c
            FROM
                ia_crm__Project__c
            WHERE
                Id IN :projectIds
        ];
    }

    /**
    * @description selectIntacctTasksByProjectIds - 
    * @param Set<Id> projectIds
    * @return List<ia_crm__Task__c>
    */
    private static List<ia_crm__Task__c> selectIntacctTasksByProjectIds(Set<Id> projectIds) {
        return [
            SELECT
                Id,
                Name,
                ia_crm__Project__c
            FROM
                ia_crm__Task__c
            WHERE
                ia_crm__Project__c IN :projectIds
        ];
    }

    /**
    * @description selectOpportunityLineItemsByOpportunityIds - 
    * @param Set<Id> opportunityIds
    * @return List<OpportunityLineItem>
    */
    private static List<OpportunityLineItem> selectOpportunityLineItemsByOpportunityIds(Set<Id> opportunityIds) {
        return [
            SELECT
                Id,
                OpportunityId,
                Product2Id,
                ia_crm__Project__c,
                ia_crm__Task__c
            FROM
                OpportunityLineItem
            WHERE
                OpportunityId IN :opportunityIds
        ];
    }


}