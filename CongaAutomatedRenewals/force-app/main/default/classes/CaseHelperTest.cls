/**
* @author Conga Services
* @date 20180718
* @version 1.00
* @description CaseHelperTest - Test class for the CaseHelper class
*/
@isTest
public with sharing class CaseHelperTest {

    /**
    * @description Setup data for testing
    */
    @testSetup 
    public static void setup() {
        Map<String, Id> acctRecordTypes = UtilityClass.getRecordTypesForObject('Account');
        Map<String, Id> caseRecordTypes = UtilityClass.getRecordTypesForObject('Case');

        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 3);
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].RecordTypeId = acctRecordTypes.get('Business_Account');
        testAccounts[0].mrr_Active_MRR__c = 100.00;
        testAccounts[0].Support_Level__c = 'Premium';
        //
        testAccounts[1].Name = 'Winterfell Inc.';
        testAccounts[1].RecordTypeId = acctRecordTypes.get('Business_Account');
        testAccounts[1].mrr_Active_MRR__c = 100.00;
        //
        testAccounts[2].Name = 'Test Partner Account';
        testAccounts[2].RecordTypeId = acctRecordTypes.get('Partner_Account');
        insert testAccounts;

        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 2);
        testContacts[0].AccountId = testAccounts[0].Id;
        testContacts[0].FirstName = 'John';
        testContacts[0].LastName = 'Smith';
        testContacts[0].Email = 'testcontact@mailinator.com';
        //
        testContacts[1].AccountId = testAccounts[2].Id;
        testContacts[1].FirstName = 'Partner';
        testContacts[1].LastName = 'Contact';       
        insert testContacts;


        List<Case> testCases = (List<Case>)TestingUtility.createSObjectList('Case', true, 6);
        for(Case newCase : testCases){
            newCase.RecordTypeId = caseRecordTypes.get('Standard');
            newCase.Status = 'New';
        }
        testCases[0].ContactId = testContacts[0].Id;
        testCases[0].AccountId = testAccounts[0].Id;
        testCases[0].Origin = 'Chat';
        //
        testCases[1].ContactId = testContacts[0].Id;
        testCases[1].AccountId = testAccounts[0].Id;
        //
        testCases[2].ContactId = testContacts[0].Id;
        testCases[2].AccountId = testAccounts[0].Id;
        testCases[2].Created_by_Partner_Contact__c = testContacts[1].Id; // PARTNER ACCOUNT TESTING, CASE WITH A PARTNER CONTACT
        //
        testCases[3].ContactId = testContacts[0].Id;
        testCases[3].AccountId = testAccounts[1].Id;
        testCases[3].Partner_AccountId__c = testAccounts[2].Id; // PARTNER ACCOUNT TESTING, CASE WITH A PARTNER ACCOUNT, BUT NO LINKED PARTNER DATA
        //
        testCases[4].ContactId = testContacts[0].Id; // PARTNER ACCOUNT TESTING, CASE WITH A CONTACT THAT BELONGS TO A PARTNER ACCOUNT
        testCases[4].AccountId = testAccounts[0].Id;
        //
        testCases[5].ContactId = testContacts[0].Id;
        testCases[5].AccountId = testAccounts[0].Id; // PARTNER ACCOUNT TESTING, CASE WITH A PARTNER ACCOUNT
        insert testCases;

        // MODIFY CASE STATUS TO CREATE A JOURNAL FOR THIS CASE
        TriggerHelper.TemporaryOverride('CaseHelper','creatingCaseJournals', true);
        testCases[2].Status = 'Working';
        update testCases[2];
    }

    /**
    * @description Test updatePartnerAccount happy path of code
    */
    public static testmethod void updatePartnerAccountTest(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 3);

        // GET TEST CONTACTS
        List<Contact> testContacts = [SELECT Id, AccountId FROM Contact];
        System.assert(testContacts.size() == 2);

        Test.startTest();

        // GET TEST CASES AND CHECK FOR CORRECT DATA
        List<Case> testCases = [SELECT Id, Partner_AccountId__c, Created_by_Partner_Contact__c, Created_by_Partner_Contact__r.AccountId FROM Case];
        System.assert(testCases.size() == 6);
        System.assert(testCases[2].Partner_AccountId__c == testCases[2].Created_by_Partner_Contact__r.AccountId); // PARTNER ACCOUNT SHOULD MATCH PARTNER CONTACT'S ACCOUNT
        System.assert(testCases[3].Partner_AccountId__c == null); // SHOULD NOW BE BLANK BECAUSE THERE IS NO LINKED PARTNER CONTACT OR ACCOUNT

        // UPDATE CASES
        testCases[4].ContactId = testContacts[1].Id; // CASE WITH A CONTACT THAT BELONGS TO A PARTNER ACCOUNT
        testCases[4].AccountId = testAccounts[0].Id;
        //
        testCases[5].ContactId = testContacts[0].Id;
        testCases[5].AccountId = testAccounts[2].Id; // CASE WITH A PARTNER ACCOUNT
        update testCases;

        // RELOAD TEST CASES AND CHECK FOR CORRECT DATA
        testCases = [SELECT Id, Partner_AccountId__c, ContactId, Contact.AccountId, AccountId FROM Case];
        System.assert(testCases.size() == 6);
        System.assert(testCases[4].Partner_AccountId__c == testCases[4].Contact.AccountId); // PARTNER ACCOUNT SHOULD MATCH PARENT CONTACT'S ACCOUNT
        System.assert(testCases[5].Partner_AccountId__c == testCases[5].AccountId); // PARTNER ACCOUNT SHOULD MATCH CASE'S PARENT ACCOUNT
    }

    /**
    * @description Test updatePartnerAccount exception handling
    */
    public static testmethod void updatePartnerAccountTest_Exception(){
        Test.startTest();

        // ATTEMPT EXECUTION OF CODE WITH NULL PARAMETERS
        CaseHelper.updatePartnerAccount(NULL, NULL);

        // ATTEMPT EXECUTION OF CODE WITH EMPTY LIST PARAMETERS
        CaseHelper.updatePartnerAccount(new List<Case>(), new Map<Id, Case>());

        Test.stopTest();
    }

    /**
    * @description Test FPRCalc happy path of code
    */
    public static testmethod void fprCalcTest(){
        // GET TEST CASES
        List<Case> testCases = [SELECT Id FROM Case];
        System.assert(testCases.size() == 6);

        // GET DEFAULT BUSINESS HOURS
        List<BusinessHours> defaultHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
        System.assert(defaultHours != null);
        System.assert(defaultHours.size() == 1);

        // ADD NECESSARY DATA TO CASES
        testCases[0].FPR__c = Date.today().addDays(7);
        testCases[0].BusinessHoursId = defaultHours[0].Id;
        testCases[0].Date_Time_Assigned__c = null;
        testCases[0].Time_to_Assignment_Hours__c = null;
        testCases[1].FPR__c = Date.today().addDays(14);
        testCases[1].BusinessHoursId = defaultHours[0].Id;
        testCases[1].Date_Time_Assigned__c = Date.today().addDays(3);

        // UPDATE CASES, EXECUTE TRIGGER
        Test.startTest();
        update testCases;

        // UPDATE CASE LIST
        testCases = [SELECT Id, Time_to_FPR_Business_Hours__c, Time_to_Assignment_Hours__c FROM Case WHERE Id IN :testCases];
        System.assert(testCases.size() == 6);
        System.assert(testCases[0].Time_to_FPR_Business_Hours__c != null);
        System.assert(testCases[0].Time_to_Assignment_Hours__c == null); // Date_Time_Assigned__c WAS NOT POPULATED
        System.assert(testCases[1].Time_to_FPR_Business_Hours__c != null);
        System.assert(testCases[1].Time_to_Assignment_Hours__c != null);
    }

    /**
    * @description Test FPRCalc exception handling
    */
    public static testmethod void fprCalcTest_Exception(){
        Test.startTest();

        // ATTEMPT EXECUTION OF CODE WITH NULL PARAMETERS
        CaseHelper.FPRCalc(null);

        // ATTEMPT EXECUTION OF CODE WITH EMPTY LIST PARAMETERS
        CaseHelper.FPRCalc(new List<Case>());

        Test.stopTest();
    }

    /**
    * @description Test Billable Time Rollup happy path of code
    */
    public static testmethod void billTimeRollupTest(){
        // GET TEST CASES
        List<Case> testCases = [SELECT Id FROM Case];
        System.assert(testCases.size() == 6);

        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 3);

        String closeStatus = [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true LIMIT 1].MasterLabel;
        Product2 prod = new Product2();
        prod.Name = 'Basic Support';
        prod.ProductCode = 'tstcde1';
        insert prod;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Account__c = testAccounts[0].Id;
        sub.SBQQ__Product__c = prod.Id;
        sub.SBQQ__Quantity__c = 5;
        sub.SBQQ__SubscriptionStartDate__c = Date.today().addDays(-30);
        sub.SBQQ__SubscriptionEndDate__c = Date.today().addDays(30);
        insert sub;

        Test.startTest();

        // ADD NECESSARY DATA TO CASES AND UPDATE TO EXECUTE TRIGGER
        testCases[0].Billable_Time_Hours__c = 5;
        testCases[0].Status = closeStatus;
        testCases[3].Billable_Time_Hours__c = 5;
        testCases[3].Status = closeStatus;
        update testCases;

        ////////// PRIMARY LOGIC IN BillableTimeRollupHelper WILL BE TESTED BY ITS OWN TEST CLASS. THIS CODE ONLY COVERS THE billableTimeRollup TRIGGER METHOD

        Test.stopTest();
    }

    /**
    * @description Test updateWorkingDates trigger method.
    */
    public static testmethod void apxtQueueUpdatesTest(){
        // GET TEST CASES
        List<Case> testCases = [SELECT Id FROM Case WHERE Origin = 'Chat'];
        System.assert(testCases.size() == 1);

        Test.startTest();

        // UPDATE CASE STATUS TO "WORKING"
        testCases[0].Status = 'Working';
        update testCases;

        // UPDATE CASE STATUS FROM "WORKING" TO SOMETHING ELSE
        testCases[0].Status = 'Waiting on Customer';
        update testCases;

        // UPDATE CASE STATUS TO "WORKING"
        testCases[0].Status = 'Working';
        update testCases;

        // UPDATE CASE OWNER TO THE APXT CASE MANAGER
        testCases[0].OwnerId = CaseHelper.APXTCaseManagerQueueId;
        update testCases;

        // REFRESH CASE RECORD AND TEST FOR CORRECT DATA
        testCases = [SELECT Id, Status, Origin, Working_Start__c, Working_Stop__c FROM Case WHERE Id IN :testCases];
        System.assert(testCases[0].Status == 'New');
        System.assert(testCases[0].Origin == 'Chat to Phone');
        System.assert(testCases[0].Working_Start__c != null);
        System.assert(testCases[0].Working_Stop__c != null);

        Test.stopTest();
    }

    /**
    * @description Test updateWorkingDates trigger method.
    */
    public static testmethod void updateWorkingDatesTest(){
        // GET TEST CASES
        List<Case> testCases = [SELECT Id FROM Case WHERE Status = 'New' LIMIT 1];
        System.assert(testCases.size() == 1);

        Test.startTest();

        // UPDATE CASE STATUS TO "WORKING"
        testCases[0].Status = 'Working';
        update testCases;

        // REFRESH CASE RECORD AND TEST FOR CORRECT DATA
        testCases = [SELECT Id, Status, Working_Start__c, Working_Stop__c FROM Case WHERE Id IN :testCases];
        System.assert(testCases[0].Status == 'Working');
        System.assert(testCases[0].Working_Start__c != null);
        System.assert(testCases[0].Working_Stop__c == null);

        // UPDATE CASE STATUS FROM "WORKING" TO SOMETHING ELSE
        testCases[0].Status = 'Waiting on Customer';
        update testCases;

        // REFRESH CASE RECORD AND TEST FOR CORRECT DATA
        testCases = [SELECT Id, Status, Working_Start__c, Working_Stop__c FROM Case WHERE Id IN :testCases];
        System.assert(testCases[0].Status == 'Waiting on Customer');
        System.assert(testCases[0].Working_Start__c != null);
        System.assert(testCases[0].Working_Stop__c != null);

        Test.stopTest();
    }

    /**
    * @description Test updateWorkingDates trigger method bad parameter handling.
    */
    public static testmethod void updateWorkingDatesTest_Exceptions(){
        Test.startTest();

        // ATTEMPT EXECUTION OF CODE WITH NULL PARAMETERS
        CaseHelper.updateWorkingDates(null, null);

        // ATTEMPT EXECUTION OF CODE WITH EMPTY PARAMETERS
        CaseHelper.updateWorkingDates(new List<Case>(), new Map<Id, Case>());

        Test.stopTest();
    }

    /**
    * @description Test createCaseTimeEntry trigger method.
    */
    public static testmethod void createCaseTimeEntryTest(){
        // CREATE TEST CUSTOMER SUCCESS USER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Success'];
        User tcsUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', 
        FirstName = 'Customer', LastName = 'Success', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com');
        insert tcsUser;

        // GET TEST CASES
        List<Case> testCases = [SELECT Id, OwnerId FROM Case WHERE Origin = 'Chat'];
        System.assert(testCases.size() == 1);

        Test.startTest();

        System.runAs(tcsUser){
            // CHECK THAT THERE ARE NO TIME ENTRIES YET
            List<Case_Time_Entry__c> testEntries = [SELECT Id FROM Case_Time_Entry__c WHERE CaseId__c IN :testCases];
            System.assert(testEntries.isEmpty());

            // UPDATE CASE STATUS TO "WORKING" AND THEN FROM WORKING TO CREATE A TIME ENTRY
            testCases[0].Status = 'Working';
            update testCases;
            testCases[0].Status = 'Waiting on Customer';
            update testCases;

            // CHECK THAT IS NOW ONE ENTRY AND IT HAS THE CORRECT DATA
            testEntries = [SELECT Id, EmployeeId__c, EmployeeId__r.Name, Type__c, Start_Date_Time__c, End_Date_Time__c FROM Case_Time_Entry__c WHERE CaseId__c IN :testCases];
            System.assert(testEntries.size() == 1);
            System.assert(testEntries[0].EmployeeId__c == testCases[0].OwnerId);
            System.assert(testEntries[0].Type__c == 'Chat');
            System.assert(testEntries[0].Start_Date_Time__c != null);
            System.assert(testEntries[0].End_Date_Time__c != null);

            TriggerHelper.TemporaryOverride('CaseHelper', 'createCaseTimeEntry', true);

            testCases[0].Status = 'Working';
            update testCases;
            testCases[0].OwnerId = CaseHelper.APXTCaseManagerQueueId;
            testCases[0].Origin = 'Chat to Phone';
            testCases[0].Status = 'New';
            update testCases;

            // CHECK FOR TWO TIME ENTRIES, BOTH OF THE CHAT TYPE
            testEntries = [SELECT Id, EmployeeId__c, Type__c, Start_Date_Time__c, End_Date_Time__c FROM Case_Time_Entry__c WHERE CaseId__c IN :testCases];
            System.assert(testEntries.size() == 2);
            System.assert(testEntries[0].EmployeeId__c != testCases[0].OwnerId); // OWNER OF CASE IS NOW A QUEUE
            System.assert(testEntries[0].Type__c == 'Chat');
            System.assert(testEntries[1].EmployeeId__c != testCases[0].OwnerId); // OWNER OF CASE IS NOW A QUEUE
            System.assert(testEntries[1].Type__c == 'Chat');

            TriggerHelper.TemporaryOverride('CaseHelper','createCaseTimeEntry', true);

            // UPDATE CASE STATUS TO "WORKING" AND THEN FROM WORKING TO CREATE A THIRD TIME ENTRY, IT SHOULD BE A STANDARD TYPE
            testCases[0].Status = 'Working';
            testCases[0].OwnerId = tcsUser.Id;
            update testCases;
            testCases[0].Status = 'Waiting on Customer';
            update testCases;

            // CHECK FOR THREE TIME ENTRIES, TWO OF CHAT TYPE, ONE OF STANDARD
            testEntries = [SELECT Id, EmployeeId__c, Type__c, Start_Date_Time__c, End_Date_Time__c FROM Case_Time_Entry__c WHERE CaseId__c IN :testCases];
            System.assert(testEntries.size() == 3);
            System.assert(testEntries[0].EmployeeId__c != testCases[0].OwnerId);
            System.assert(testEntries[0].Type__c == 'Chat');
            System.assert(testEntries[1].EmployeeId__c != testCases[0].OwnerId); // OWNER OF CASE IS NOW A QUEUE
            System.assert(testEntries[1].Type__c == 'Chat');
            System.assert(testEntries[2].EmployeeId__c == tcsUser.Id);
            System.assert(testEntries[2].Type__c == 'Standard');
        }

        Test.stopTest();
    }

    /**
    * @description Test createCaseTimeEntry trigger method bad parameter handling.
    */
    public static testmethod void createCaseTimeEntryTest_Exceptions(){
        Test.startTest();

        // ATTEMPT EXECUTION OF CODE WITH NULL PARAMETERS
        CaseHelper.createCaseTimeEntry(null, null);

        // ATTEMPT EXECUTION OF CODE WITH EMPTY PARAMETERS
        CaseHelper.createCaseTimeEntry(new List<Case>(), new Map<Id, Case>());

        Test.stopTest();
    }

    /**
    * @description sendCaseToVictorOpsTest - Test method for the CaseHelper.sendCaseToVictorOps method
    */
    public static testmethod void sendCaseToVictorOpsTest(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        System.assert(testAccounts.size() == 3);

        // GET TEST CONTACTS
        List<Contact> testContacts = [SELECT Id, Name, Email FROM Contact];
        System.assert(testContacts.size() == 2);

        Test.startTest();

        // SET TEST HTTP MOCK
        Test.setMock(HttpCalloutMock.class, new VictorOpsTimeLineTest.VictorOpsHTTPCalloutMock()); 

        // CREATE TEST CASE
        List<Case> testCases = (List<Case>)TestingUtility.createSObjectList('Case', false, 1);
        testCases[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Case').get('Standard');
        testCases[0].ContactId = testContacts[0].Id;
        testCases[0].AccountId = testAccounts[0].Id;
        testCases[0].Subject = 'Test Case for Victor Ops';
        testCases[0].Description = 'Test Description for Victor Ops';
        testCases[0].Reason = 'Test Description for Victor Ops';
        testCases[0].Status = 'New';
        testCases[0].Product__c = 'Composer 8';
        insert testCases;

        Test.stopTest();

        // CHECK FOR LOGGED ERRORS, THERE SHOULD BE NONE
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.isEmpty());

        //////////////////// PRIMARY VICTOR OPS LOGIC WILL BE TESTED BY IT OWN TEST METHOD IN VictorOpsTimeLineTest /////////////////////////
    }

    /**
    * @description validateEmailToCaseTest_CaseInsertOk - 
    */
    public static testmethod void validateEmailToCaseTest_CaseInsertOk() {
        Case newCase = new Case(SuppliedEmail = 'test@test.com', OwnerId = UserInfo.getUserId(), Subject = 'testing');

        Test.startTest();

        insert newCase;

        Test.stopTest();

        System.assertNotEquals(null, newCase.Id);
    } 

    /**
    * @description validateEmailToCaseTest_RejectedBySender - 
    */
    public static testmethod void validateEmailToCaseTest_RejectedBySender() {
        CaseHelper.EmailToCaseValidationMetadata settings = CaseHelper.EmailToCaseValidationSettings;
        System.assert(settings != null);
        System.assertEquals(true, settings.Enabled);
        System.assertEquals(false, settings.QueueIds.isEmpty());
        System.assertEquals(false, settings.FromKeywords.isEmpty());
        System.assertEquals(false, settings.SubjectKeywords.isEmpty());

        Id queueId = new List<Id>(settings.QueueIds)[0];
        String emailSender = new List<String>(settings.FromKeywords)[0];
        String emailSubject = new List<String>(settings.SubjectKeywords)[0];

        Case newCase = new Case(OwnerId = queueId, SuppliedEmail = (emailSender.startsWith('@') ? 'test' + emailSender : emailSender), Subject = emailSubject, Origin = 'Email');

        Test.startTest();

        Database.SaveResult insertResult = Database.insert(newCase, false);

        Test.stopTest();

        System.assertEquals(false, insertResult.isSuccess());
        List<Database.Error> errors = insertResult.getErrors();
        System.assertEquals(1, errors.size());
        System.assertEquals(true, errors[0].getMessage().containsIgnoreCase(emailSender));
    }

    /**
    * @description validateEmailToCaseTest_RejectedBySubject - 
    */
    public static testmethod void validateEmailToCaseTest_RejectedBySubject() {
        CaseHelper.EmailToCaseValidationMetadata settings = CaseHelper.EmailToCaseValidationSettings;
        System.assert(settings != null);
        System.assertEquals(true, settings.Enabled);
        System.assertEquals(false, settings.QueueIds.isEmpty());
        System.assertEquals(false, settings.FromKeywords.isEmpty());
        System.assertEquals(false, settings.SubjectKeywords.isEmpty());

        Id queueId = new List<Id>(settings.QueueIds)[0];
        String emailSubject = new List<String>(settings.SubjectKeywords)[0];

        Case newCase = new Case(OwnerId = queueId, SuppliedEmail = 'test@mailinator.com', Subject = emailSubject, Origin = 'Email');

        Test.startTest();

        Database.SaveResult insertResult = Database.insert(newCase, false);

        Test.stopTest();

        System.assertEquals(false, insertResult.isSuccess());
        List<Database.Error> errors = insertResult.getErrors();
        System.assertEquals(1, errors.size());
        System.assertEquals(true, errors[0].getMessage().containsIgnoreCase(emailSubject));
    }


}