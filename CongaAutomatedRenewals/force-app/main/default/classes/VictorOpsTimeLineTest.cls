/**
* @author ECS, ERedding
* @date 20200330
* @version 1.00
* @description VictorOpsTimeLineTest - Test class for the VictorOpsTimeLine class
*/
@isTest
public with sharing class VictorOpsTimeLineTest {

    /**
    * @description setup - Create test data
    * @return void
    */
    @testSetup
    public static void setup(){
    	// TEST ACCOUNTS
		List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);
		testAccounts[0].Name = 'VictorOps Test Account';
		insert testAccounts;

		// TEST CONTACTS
		List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 1);
		testContacts[0].AccountId = testAccounts[0].Id;
		testContacts[0].FirstName = 'John';
		testContacts[0].LastName = 'Smith';
		testContacts[0].Email = 'jsmith@mailinator.com';
		insert testContacts;
    }

    /**
    * @description caseToVictorTest - Test method for the VictorOpsTimeLine.caseToVictor method
    */
    public static testmethod void caseToVictorTest(){
		// GET TEST ACCOUNTS
		List<Account> testAccounts = [SELECT Id, Name FROM Account];
		System.assert(testAccounts.size() == 1);

		// GET TEST CONTACTS
		List<Contact> testContacts = [SELECT Id, Name, Email FROM Contact];
		System.assert(testContacts.size() == 1);

        // CREATE TEST CASE
        TriggerHelper.TemporaryOverride('CaseHelper','sendCaseToVictorOps', false); // DISABLE TRIGGER METHOD, THIS TEST METHOD WILL LAUNCH THE CODE   
		List<Case> testCases = (List<Case>)TestingUtility.createSObjectList('Case', false, 1);
		testCases[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Case').get('Standard');
		testCases[0].ContactId = testContacts[0].Id;
		testCases[0].AccountId = testAccounts[0].Id;
		testCases[0].Subject = 'Test Case for Victor Ops';
		testCases[0].Description = 'Test Description for Victor Ops';
		testCases[0].Reason = 'Test Description for Victor Ops';
		testCases[0].Product__c = 'Composer 8';
        testCases[0].Status = 'New';
		insert testCases;

		// SET TEST HTTP MOCK
       	Test.setMock(HttpCalloutMock.class, new VictorOpsHTTPCalloutMock()); 

        Test.startTest();

        // REFRESH CASE
        testCases = [SELECT Id, CaseNumber, Subject, Description, Reason, Product__c FROM Case WHERE Id IN :testCases];

        VictorOpsTimeLine.caseToVictor(false, testCases[0].CaseNumber, testCases[0].Subject, testContacts[0].Name, testAccounts[0].Name, testCases[0].Product__c,
        							   testCases[0].Description, testCases[0].Reason, testContacts[0].Email, testCases[0].Id);

        Test.stopTest();

        // CHECK FOR LOGGED ERRORS, THERE SHOULD BE NONE
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.isEmpty());
    }

    /**
    * @description caseToVictorTest_Error - Test method for the VictorOpsTimeLine.caseToVictor method error handling
    */
    public static testmethod void caseToVictorTest_Error(){
		// GET TEST ACCOUNTS
		List<Account> testAccounts = [SELECT Id, Name FROM Account];
		System.assert(testAccounts.size() == 1);

		// GET TEST CONTACTS
		List<Contact> testContacts = [SELECT Id, Name, Email FROM Contact];
		System.assert(testContacts.size() == 1);

        // CREATE TEST CASE
        TriggerHelper.TemporaryOverride('CaseHelper','sendCaseToVictorOps', false); // DISABLE TRIGGER METHOD, THIS TEST METHOD WILL LAUNCH THE CODE   
		List<Case> testCases = (List<Case>)TestingUtility.createSObjectList('Case', false, 1);
		testCases[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Case').get('Standard');
		testCases[0].ContactId = testContacts[0].Id;
		testCases[0].AccountId = testAccounts[0].Id;
		testCases[0].Subject = 'Test Case for Victor Ops';
		testCases[0].Description = 'Test Description for Victor Ops';
		testCases[0].Reason = 'Test Description for Victor Ops';
        testCases[0].Product__c = 'Composer 8';
		testCases[0].Status = 'New';
		insert testCases;

		// SET TEST HTTP MOCK
       	Test.setMock(HttpCalloutMock.class, new VictorOpsHTTPCalloutMockError()); 

        Test.startTest();

        // REFRESH CASE
        testCases = [SELECT Id, CaseNumber, Subject, Description, Reason, Product__c FROM Case WHERE Id IN :testCases];

        VictorOpsTimeLine.caseToVictor(false, testCases[0].CaseNumber, testCases[0].Subject, testContacts[0].Name, testAccounts[0].Name, testCases[0].Product__c,
        							   testCases[0].Description, testCases[0].Reason, testContacts[0].Email, testCases[0].Id);

        Test.stopTest();

        // CHECK FOR LOGGED ERRORS, THERE SHOULD BE TWO
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.size() == 1);
    }



    /**
    * @description VictorOpsHTTPCalloutMock - HTTP Mock class for testing VictorOpsTimeLine.caseToVictor method
    */
    public class VictorOpsHTTPCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String body = '{OK}';
            
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
    * @description VictorOpsHTTPCalloutMock - HTTP Mock class for testing VictorOpsTimeLine.caseToVictor method
    */
    public class VictorOpsHTTPCalloutMockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String body = '{ERROR}';
            
            res.setBody(body);
            res.setStatusCode(400);
            return res;
        }
    }


}