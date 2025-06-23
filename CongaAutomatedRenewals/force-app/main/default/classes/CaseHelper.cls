/**
* @author Conga Services
* @date 20160426
* @version 1.00
* @description CaseHelper - Various custom functionality for the Case object
*/
public without sharing class CaseHelper {

    // Case_Manager_APXT QUEUE ID
    public static Id APXTCaseManagerQueueId {
    get {
        if(APXTCaseManagerQueueId == null){
            for(Group queue : [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Case_Manager_APXT' LIMIT 1]){
                APXTCaseManagerQueueId = queue.Id;
            }
        }
        return APXTCaseManagerQueueId;
    } set; }

    // EMAIL TO CASE VALIDATION CUSTOM METADATA SETTINGS
    public static EmailToCaseValidationMetadata EmailToCaseValidationSettings {
    get {
        if(EmailToCaseValidationSettings == null){
            EmailToCaseValidationSettings = new EmailToCaseValidationMetadata();
            for(Email_to_Case_Validation_Settings__mdt metadata : [SELECT Validation_Enabled__c, Subject_Validation_Keywords__c, From_Validation_Keywords__c, 
                                                                          Default_Assignment_Queues__c, Default_Assignment_Profiles__c
                                                                   FROM Email_to_Case_Validation_Settings__mdt LIMIT 1]){
                // ENABLED SETTING FOR VALIDATION
                EmailToCaseValidationSettings.Enabled = metadata.Validation_Enabled__c;

                // QUEUE IDS FOR DEFAULT ASSIGNMENT
                if (!String.isBlank(metadata.Default_Assignment_Queues__c)) {
                    for(String queueEntry : metadata.Default_Assignment_Queues__c.replace('\r','').split('\n')) {
                        String queueId = queueEntry.left(18);
                        EmailToCaseValidationSettings.QueueIds.add(queueId);
                    }
                }
                // PROFILE IDS FOR DEFAULT ASSIGNMENT
                if (!String.isBlank(metadata.Default_Assignment_Profiles__c)) {
                    for(String profileEntry : metadata.Default_Assignment_Profiles__c.replace('\r','').split('\n')) {
                        String profileId = profileEntry.left(18);
                        EmailToCaseValidationSettings.ProfileIds.add(profileId);
                    }
                }
                // FROM KEYWORDS FOR VALIDATION
                if (!String.isBlank(metadata.From_Validation_Keywords__c)) {
                    for (String fromKeyword : metadata.From_Validation_Keywords__c.split(';')) {
                        EmailToCaseValidationSettings.FromKeywords.add(fromKeyword);
                    }
                }
                // SUBJECT KEYWORDS FOR VALIDATION
                if (!String.isBlank(metadata.Subject_Validation_Keywords__c)) {
                    for (String subjectKeyword : metadata.Subject_Validation_Keywords__c.split(';')) {
                        EmailToCaseValidationSettings.SubjectKeywords.add(subjectKeyword);
                    }
                }
            }
        }
        return EmailToCaseValidationSettings;
    } set; }



    /**
    * @author ECS, ERedding
    * @date 20200609
    * @description updatePartnerAccount - Updates the Partner_AccountId__c on the Case object
    * @param List<Case> newOrUpdatedCases - New or Updated Case records
    * @param Map<Id, Case> outdatedCases - Outdated Case records
    * @return void
    */
    public static void updatePartnerAccount(List<Case> newOrUpdatedCases, Map<Id, Case> outdatedCases){
        try{        
            if(TriggerHelper.DoExecute('CaseHelper','updatePartnerAccount') && newOrUpdatedCases != null){
                // GET CONTACTS WITH QUALIFYING CHANGES
                List<Case> qualifiedCases = new List<Case>();
                Set<Id> parentAccountIds = new Set<Id>();
                Set<Id> parentContactIds = new Set<Id>();
                for(Case newOrUpdatedCase : newOrUpdatedCases){
                    Case outdatedCase = outdatedCases != null ? outdatedCases.get(newOrUpdatedCase.Id) : null;
                    if(outdatedCase == null || newOrUpdatedCase.AccountId != outdatedCase.AccountId || newOrUpdatedCase.ContactId != outdatedCase.ContactId ||
                                               newOrUpdatedCase.Created_by_Partner_Contact__c != outdatedCase.Created_by_Partner_Contact__c){
                        qualifiedCases.add(newOrUpdatedCase);
                        parentAccountIds.add(newOrUpdatedCase.AccountId);
                        parentContactIds.add(newOrUpdatedCase.ContactId);
                        parentContactIds.add(newOrUpdatedCase.Created_by_Partner_Contact__c);
                    }
                }

                if(!qualifiedCases.isEmpty()){
                    // GET ACCOUNT RECORD TYPES
                    Id accountPartnerRT = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');

                    // GET PARENT ACCOUNT DATA
                    Map<Id, Account> parentAccounts = new Map<Id, Account>();
                    if(!parentAccountIds.isEmpty()){
                        parentAccounts = new Map<Id, Account>([SELECT Id, RecordTypeId FROM Account WHERE Id IN :parentAccountIds]);
                    }

                    // GET PARENT CONTACT DATA
                    Map<Id, Contact> parentContacts = new Map<Id, Contact>();
                    if(!parentContactIds.isEmpty()){
                        parentContacts = new Map<Id, Contact>([SELECT Id, AccountId, Account.RecordTypeId FROM Contact WHERE Id IN :parentContactIds]);
                    }

                    // CHECK DATA AND SET PARTNER ACCOUNT
                    for(Case qualifiedCase : qualifiedCases){

                        // CREATED BY PARTNER CONTACT ACCOUNT
                        if(qualifiedCase.Created_by_Partner_Contact__c != null && parentContacts.containsKey(qualifiedCase.Created_by_Partner_Contact__c)){
                            qualifiedCase.Partner_AccountId__c =  parentContacts.get(qualifiedCase.Created_by_Partner_Contact__c).AccountId;
                        }
                        // CONTACT ACCOUNT
                        else if(qualifiedCase.ContactId != null && parentContacts.containsKey(qualifiedCase.ContactId) && 
                                 parentContacts.get(qualifiedCase.ContactId).Account.RecordTypeId == accountPartnerRT){

                            qualifiedCase.Partner_AccountId__c = parentContacts.get(qualifiedCase.ContactId).AccountId;
                        }
                        // ACCOUNT
                        else if(qualifiedCase.AccountId != null && parentAccounts.containsKey(qualifiedCase.AccountId) && 
                                 parentAccounts.get(qualifiedCase.AccountId).RecordTypeId == accountPartnerRT){

                            qualifiedCase.Partner_AccountId__c = qualifiedCase.AccountId;
                        }
                        // NO PARTNER ACCOUNT
                        else{
                            qualifiedCase.Partner_AccountId__c = null;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper', 'updatePartnerAccount');
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('CaseHelper', 'updatePartnerAccount', newOrUpdatedCases, ex, true);
        }
    }


    /**
    * @description FPRCalc - 
    */
    public static void FPRCalc(List<Case> updatedCases){
        try{
            if(TriggerHelper.DoExecute('CaseHelper','FPRCalc') && updatedCases != null && !updatedCases.isEmpty()){
                for(Case c : updatedCases){
                    if(c.FPR__c != null && c.BusinessHoursId != null){
                        if(c.Time_to_FPR_Business_Hours__c != ((Double)(BusinessHours.diff(c.BusinessHoursId, c.CreatedDate, c.FPR__c))/3600000)){
                            c.Time_to_FPR_Business_Hours__c = ((Double)(BusinessHours.diff(c.BusinessHoursId, c.CreatedDate, c.FPR__c))/3600000);
                        }
                    }

                    if(c.Date_Time_Assigned__c != null && c.BusinessHoursId != null){
                        if(c.Time_to_Assignment_Hours__c != ((Double)(BusinessHours.diff(c.BusinessHoursId, c.CreatedDate, c.Date_Time_Assigned__c))/3600000)){
                            c.Time_to_Assignment_Hours__c = (((Double)(BusinessHours.diff(c.BusinessHoursId, c.CreatedDate, c.Date_Time_Assigned__c))/3600000));
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper', 'FPRCalc');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('CaseHelper', 'FPRCalc', updatedCases, ex, true);
        }
    }

    /**
    * @author Conga Services, KSears, ERedding
    * @description billableTimeRollup - Calls Account Helper to update Billable Time Current Subscription field  
    * @param List<Case> newOrUpdatedCases - New or Updated Case records
    * @return void
    */
    public static void billableTimeRollup(List<Case> newOrUpdatedCases){
         try{
            if(TriggerHelper.DoExecute('CaseHelper','billableTimeRollup') && newOrUpdatedCases != null && !newOrUpdatedCases.isEmpty()){
                Set<Id> accIds = new Set<Id>();
                for(Case c : newOrUpdatedCases){
                    if(c.IsClosed){
                        accIds.add(c.AccountId);
                    }
                }

                if(!accIds.isEmpty()){
                    Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Subscription_Term_Start_Date__c, Subscription_Term_End_Date__c, Billable_Time_Current_Subscription__c
                                                                    FROM Account WHERE Id IN :accIds]);
                    if(!accMap.isEmpty()){
                        BillableTimeRollupHelper.billableTimeRollup(accMap);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper', 'billableTimeRollup');
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('CaseHelper', 'billableTimeRollup', newOrUpdatedCases, ex, true);
        }
    }

    /**
    * @author Conga Services, KSears, ERedding
    * @description sendCaseToVictorOps - Calls VictorOpsTimeLine class and sends case to VictorOps.
    * @param List<Case> newCases - New Case records
    * @return void
    */
    public static void sendCaseToVictorOps(List<Case> newCases){
        try{
            if(TriggerHelper.DoExecute('CaseHelper','sendCaseToVictorOps') && newCases != null){
                TriggerHelper.TemporaryOverride('CaseHelper','sendCaseToVictorOps', FALSE); // PREVENT RECURSIVE EXECUTIONS

                // GET QUALIFYING CASES
                List<Case> qualifyingCases = new List<Case>();
                Set<Id> parentAccountIds = new Set<Id>();
                Set<Id> parentContactIds = new Set<Id>();
                for(Case newCase : newCases){
                    if(newCase.AccountId != null){
                        qualifyingCases.add(newCase);
                        parentAccountIds.add(newCase.AccountId);
                        parentContactIds.add(newCase.ContactId);
                    }                   
                }

                if(!qualifyingCases.isEmpty() && VictorOpsTimeLine.VictorOpsSettings != null){
                    // GET PARENT ACCOUNT DATA AND PARENT CONTACT DATA AND SEND CASES TO VICTOROPS IF THEY BELONG TO PREMIUM SUPPORT ACCOUNTS
                    Map<Id, Account> parentAccounts = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :parentAccountIds AND Support_Level__c = 'Premium']);
                    Map<Id, Contact> parentContacts = new Map<Id, Contact>([SELECT Id, Name, Email FROM Contact WHERE Id IN :parentContactIds]);
                    if(!parentAccounts.isEmpty()){
                        for(Case qualifyingCase : qualifyingCases){
                            if(parentAccounts.containsKey(qualifyingCase.AccountId) && parentContacts.containsKey(qualifyingCase.ContactId) && qualifyingCase.Product__c != null){
                                VictorOpsTimeLine.caseToVictor(false,
                                                               qualifyingCase.CaseNumber,
                                                               qualifyingCase.Subject,
                                                               parentContacts.get(qualifyingCase.ContactId).Name,
                                                               parentAccounts.get(qualifyingCase.AccountId).Name,
                                                               qualifyingCase.Product__c,
                                                               qualifyingCase.Description,
                                                               qualifyingCase.Reason,
                                                               UtilityClass.replaceNull(parentContacts.get(qualifyingCase.ContactId).Email, ''),
                                                               qualifyingCase.Id);
                            }
                        }
                    }
                }

                // COMMIT ANY ERRORS
                SystemIssueLogHelper.UpsertExceptions();

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper', 'sendCaseToVictorOps'); 
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('CaseHelper', 'sendCaseToVictorOps', newCases, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20191126
    * @description updateToChatToPhone - Makes various updates to Chat Case when placed into the Case_Manager_APXT queue
    *                                       --- EXECUTED BY CASE BEFORE UPDATE TRIGGER ---
    * @param List<Case> updatedCases - Updated Case records
    * @param Map<Id, Case> outdatedCases - Outdated Case records    
    * @return void
    */
    public static void apxtQueueUpdates(List<Case> updatedCases, Map<Id, Case> outdatedCases){
        try{
            if(TriggerHelper.DoExecute('CaseHelper','apxtQueueUpdates') && updatedCases != null && outdatedCases != null){
                // UPDATE QUALIFYING CASES
                for(Case updatedCase : updatedCases){
                    Case outdatedCase = outdatedCases != null ? outdatedCases.get(updatedCase.Id) : null;

                    // STATUS WAS CHANGED TO WORKING
                    if(outdatedCase != null && updatedCase.Origin == 'Chat' && updatedCase.OwnerId != outdatedCase.OwnerId){
                        
                        // UPDATE APPLICABLE CASES
                        if(APXTCaseManagerQueueId != null && updatedCase.OwnerId == APXTCaseManagerQueueId){
                            updatedCase.Status = 'New';
                            updatedCase.Origin = 'Chat to Phone';
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper', 'apxtQueueUpdates'); 
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('CaseHelper', 'apxtQueueUpdates', updatedCases, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190416
    * @description updateWorkingDates - Updates a Case's Working Start and Working End dates as the Status is change to and from "Working"
    *                                   --- EXECUTED BY CASE BEFORE UPDATE TRIGGER ---
    * @param List<Case> updatedCases - Updated Case records
    * @param Map<Id, Case> outdatedCases - Outdated Case records    
    * @return void
    */
    public static void updateWorkingDates(List<Case> updatedCases, Map<Id, Case> outdatedCases){
        try{
            if(TriggerHelper.DoExecute('CaseHelper','updateWorkingDates') && updatedCases != null && outdatedCases != null){
                // UPDATE QUALIFYING CASES
                for(Case updatedCase : updatedCases){
                    Case outdatedCase = outdatedCases != null ? outdatedCases.get(updatedCase.Id) : null;

                    // STATUS WAS CHANGED TO WORKING
                    if(outdatedCase != null && updatedCase.Status == 'Working' && updatedCase.Status != outdatedCase.Status){
                        updatedCase.Working_Start__c = Datetime.newInstance(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour(), Datetime.now().minute(), 0);
                        updatedCase.Working_Stop__c = null;
                    }

                    // STATUS WAS CHANGED FROM WORKING
                    if(outdatedCase != null && outdatedCase.Status == 'Working' && updatedCase.Status != outdatedCase.Status){
                        updatedCase.Working_Stop__c = Datetime.newInstance(Datetime.now().year(), Datetime.now().month(), Datetime.now().day(), Datetime.now().hour(), Datetime.now().minute(), 0);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper', 'updateWorkingDates');
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('CaseHelper', 'updateWorkingDates', updatedCases, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190416
    * @description createCaseTimeEntry - Creates a new Case Time Entry records for Cases where the Status has been changed from "Working"
    *                                     --- EXECUTED BY CASE AFTER UPDATE TRIGGER ---
    * @param List<Case> updatedCases - Updated Case records
    * @param Map<Id, Case> outdatedCases - Outdated Case records    
    * @return void
    */
    public static void createCaseTimeEntry(List<Case> updatedCases, Map<Id, Case> outdatedCases){
        try{
            if(TriggerHelper.DoExecute('CaseHelper','createCaseTimeEntry') && updatedCases != null && outdatedCases != null){

                // GET QUALIFYING CASES
                List<Case> casesToProcess = new List<Case>();
                for(Case updatedCase : updatedCases){
                    Case outdatedCase = outdatedCases != null ? outdatedCases.get(updatedCase.Id) : null;

                    // STATUS WAS CHANGED FROM WORKING
                    if(outdatedCase != null && outdatedCase.Status == 'Working' && updatedCase.Status != outdatedCase.Status && 
                        updatedCase.Working_Start__c != null && updatedCase.Working_Stop__c != null){
                        casesToProcess.add(updatedCase);
                    }
                }

                if(!casesToProcess.isEmpty()){
                    // GET IDS OF PROFILES THAT ARE ALLOWED TO USE THE TIME ENTRY FUNCTIONALITY
                    Set<Id> profileIds = new Set<Id>();
                    for(Profile profile : [SELECT Id FROM Profile WHERE Name IN ('Customer Success', 'System Administrator')]){
                        profileIds.add(profile.Id);
                    }

                    // ONLY CERTAIN USERS SHOULD HAVE AN ENTRY CREATED
                    if(profileIds.contains(UserInfo.getProfileId())){

                        // GET EXISTING TIME ENTRIES FOR QUALIFIED CASES AND DISQUALIFY ANY CASES WHERE THE ENTRY WAS ALREADY CREATED
                        for(Case_Time_Entry__c existingEntry : [SELECT EmployeeId__c, Start_Date_Time__c, End_Date_Time__c FROM Case_Time_Entry__c WHERE CaseId__c IN :casesToProcess]){
                            for(Integer i = 0; i < casesToProcess.size(); i++){
                                if(casesToProcess[i].OwnerId == existingEntry.EmployeeId__c && casesToProcess[i].Working_Start__c == existingEntry.Start_Date_Time__c && 
                                    casesToProcess[i].Working_Stop__c == existingEntry.End_Date_Time__c){
                                    casesToProcess.remove(i);
                                }
                            }
                        }

                        // CREATE NEW CASE TIME ENTRIES FOR QUALIFYING CASES
                        List<Case_Time_Entry__c> caseTimeEntriesToCreate = new  List<Case_Time_Entry__c>();
                        for(Case qualifiedCase : casesToProcess){
                            Case outdatedCase = outdatedCases != null ? outdatedCases.get(qualifiedCase.Id) : null;

                            // CREATE TIME ENTRY IF OWNED BY A USER 
                            Case_Time_Entry__c newEntry = new Case_Time_Entry__c();
                            newEntry.CaseId__c = qualifiedCase.Id;
                            newEntry.Start_Date_Time__c = qualifiedCase.Working_Start__c;
                            newEntry.End_Date_Time__c = qualifiedCase.Working_Stop__c;
                            
                            // SET DATA FOR CASE OWNED BY A USER
                            if(String.valueOf(qualifiedCase.OwnerId).left(3) == '005'){
                                newEntry.EmployeeId__c = qualifiedCase.OwnerId;
                                newEntry.Type__c = qualifiedCase.Origin == 'Chat' ? 'Chat' : 'Standard';

                            }
                            // SET DATA FOR A CASE JUST ASSIGNED TO THE Case_Manager_APXT QUEUE
                            else if(String.valueOf(outdatedCase.OwnerId).left(3) == '005' && qualifiedCase.OwnerId == APXTCaseManagerQueueId && qualifiedCase.Origin == 'Chat to Phone'){
                                newEntry.EmployeeId__c = outdatedCase.OwnerId;
                                newEntry.Type__c = 'Chat';
                            }

                            caseTimeEntriesToCreate.add(newEntry);  
                        }

                        // INSERT TIME ENTRIES
                        if(!caseTimeEntriesToCreate.isEmpty()){
                            TriggerHelper.TemporaryOverride('CaseHelper','createCaseTimeEntry', false); // PREVENTS DUPLICATE TIME ENTRIES
                            Database.SaveResult[] insertResults = Database.insert(caseTimeEntriesToCreate, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'CaseHelper', 'createCaseTimeEntry', true);                  
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper', 'createCaseTimeEntry');
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('CaseHelper', 'createCaseTimeEntry', updatedCases, ex, true);
        }
    }

    /**
    * @author JCDiaz, ERedding
    * @date 20190603
    * @description validateEmailToCase - Validation to avoid Case creation if certain conditions apply to incomming message.
    * @param List<Case> newCases
    * @return void
    */
    public static void validateEmailToCase(List<Case> newCases) {
        try{
            if(TriggerHelper.DoExecute('CaseHelper','validateEmailToCase') && newCases != null && EmailToCaseValidationSettings != null && EmailToCaseValidationSettings.Enabled){

                // LOOP OVER EACH NEW CASE AND VALIDATE
                for(Case newCase : newCases){
                    if(newCase.Origin == 'Email' && (String.isNotBlank(newCase.SuppliedEmail) || String.isNotBlank(newCase.Subject)) && 
                        EmailToCaseValidationSettings != null && EmailToCaseValidationSettings.Enabled){

                        // VALIDATE USING FROM KEYWORDS
                        if(String.isNotBlank(newCase.SuppliedEmail)) {
                            Boolean fromKeywordMatched = false;
                            for(String fromKeyword : EmailToCaseValidationSettings.FromKeywords) {
                                if(newCase.SuppliedEmail.containsIgnoreCase(fromKeyword)) {
                                    fromKeywordMatched = true;

                                    String errorMessage = 'Case creation rejected by custom Email-to-Case validation. Supplied Email contains: ' + fromKeyword; 
                                    newCase.addError(errorMessage);
                                    break;
                                }
                            }

                            // CONTINUE ON TO NEXT CASE IF THIS ONE IS REJECTED ON USING FROM KEYWORD
                            if(fromKeywordMatched){
                                continue;
                            }
                        }

                        // VALIDATE USING SUBJECT KEYWORDS
                        if(String.isNotBlank(newCase.Subject)) {
                            Boolean subjectKeywordMatched = false;
                            for(String subjectKeyword : EmailToCaseValidationSettings.SubjectKeywords) {
                                if(newCase.Subject.containsIgnoreCase(subjectKeyword)) {
                                    subjectKeywordMatched = true;

                                    String errorMessage = 'Case creation rejected by custom Email-to-Case validation. Subject contains: ' + subjectKeyword; 
                                    newCase.addError(errorMessage);
                                    break;
                                }
                            }

                            // CONTINUE ON TO NEXT CASE IF THIS ONE IS REJECTED ON USING SUBJECT KEYWORD
                            if(subjectKeywordMatched){
                                continue;
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper','validateEmailToCase');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('CaseHelper', 'validateEmailToCase', newCases, ex, true);
        }
    }

    /**
    * @author JCDiaz, ERedding
    * @date 20190603
    * @description doDefaultAssignment - To execute default assigment of inserted Case records.
    * @param List<Case> newCases
    * @return void
    */
    public static void doDefaultAssignment(List<Case> newCases) {
        try{
            if(TriggerHelper.DoExecute('CaseHelper','doDefaultAssignment') && newCases != null && EmailToCaseValidationSettings != null){
                // GET QUALIFYING CASES
                Set<Id> qualifyingCaseIds = new Set<Id>();
                for(Case newCase : newCases) {
                    if(EmailToCaseValidationSettings.QueueIds.contains(newCase.OwnerId) || EmailToCaseValidationSettings.ProfileIds.contains(UserInfo.getProfileId())){
                        qualifyingCaseIds.add(newCase.Id); // OWNED BY A QUEUE OR CREATED BY A USER WITH A PROFILE THAT IS LISTED IN CUSTOM METADATA FOR FORCED ASSIGNMENT
                    }
                }

                // USE DEFAULT ASSIGNMENT RULE ON QUALIFIED CASES
                if(!qualifyingCaseIds.isEmpty()){
                    List<Case> casesToForceAssignment = [SELECT Id FROM Case WHERE Id IN :qualifyingCaseIds];

                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule = true;
                    for(Case caseToForce : casesToForceAssignment){
                        caseToForce.setOptions(dmo);
                    }

                    Database.SaveResult[] caseResults = Database.update(casesToForceAssignment, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(caseResults, 'CaseHelper', 'doDefaultAssignment', true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('CaseHelper','doDefaultAssignment');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('CaseHelper', 'doDefaultAssignment', newCases, ex, true);
        }
    }

    /**
    * @description EmailToCaseValidationMetadata - Wrapper class for holding Email-to-Case Validation settings
    */
    @testVisible
    private class EmailToCaseValidationMetadata {
        public Boolean Enabled {get; set;}
        public Set<Id> QueueIds {get; set;}
        public Set<Id> ProfileIds {get; set;}
        public Set<String> FromKeywords {get; set;}
        public Set<String> SubjectKeywords {get; set;}

        /**
        * @description EmailToCaseValidationMetadata - Constructor
        */        
        public EmailToCaseValidationMetadata() {
            Enabled = false;
            QueueIds = new Set<Id>();
            ProfileIds = new Set<Id>();
            FromKeywords = new Set<String>();
            SubjectKeywords = new Set<String>();
        }
    }


}