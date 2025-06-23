/**
* @author ECS, ERedding
* @date 20200113
* @version 1.00
* @description Batchable_BulkDMLProcessorTest  - Test class for the [Name of class being tested] class
*/
@isTest
public with sharing class Batchable_BulkDMLProcessorTest {

	/**
	* @description dmlInsertTest - Test the insert functionality of the Batchable_BulkDMLProcessor batch class
	*/
	public static testMethod void dmlInsertTest() {
		// CREATE TEST ACCOUNTS
    	List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 10);

		Test.startTest();

		// INSERT THEM USING BULK PROCESSOR
		Batchable_BulkDMLProcessor bulkProcessor = new Batchable_BulkDMLProcessor(testAccounts, 'Insert');
		Database.executeBatch(bulkProcessor, 15);

		Test.stopTest();

		// TEST THAT ACCOUNTS WERE CREATED
		testAccounts = [SELECT Id, Name FROM Account];
		System.assert(testAccounts.size() == 10);
	}
	
	/**
	* @description dmlUpdateTest - Test the update functionality of the Batchable_BulkDMLProcessor batch class
	*/
	public static testMethod void dmlUpdateTest() {
		// CREATE TEST ACCOUNT
    	List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 10);
    	insert testAccounts;

		// UPDATE TEST ACCOUNTS
		testAccounts[0].Name = 'Test Bulk Account 1';
		testAccounts[1].Name = 'Test Bulk Account 2';
		testAccounts[2].Name = 'Test Bulk Account 3';
		testAccounts[3].Name = 'Test Bulk Account 4';
		testAccounts[4].Name = 'Test Bulk Account 5';
		testAccounts[5].Name = 'Test Bulk Account 6';
		testAccounts[6].Name = 'Test Bulk Account 7';
		testAccounts[7].Name = 'Test Bulk Account 8';
		testAccounts[8].Name = 'Test Bulk Account 9';
		testAccounts[9].Name = 'Test Bulk Account 10';

		Test.startTest();

		// UPDATE THEM USING BULK PROCESSOR
		Batchable_BulkDMLProcessor bulkProcessor = new Batchable_BulkDMLProcessor(testAccounts, 'Update');
		Database.executeBatch(bulkProcessor, 15);

		Test.stopTest();

		// TEST THAT ACCOUNTS WERE UPDATED
		testAccounts = [SELECT Id, Name FROM Account WHERE Id IN :testAccounts];
		System.assert(testAccounts.size() == 10);
		System.assert(testAccounts[0].Name == 'Test Bulk Account 1');
		System.assert(testAccounts[1].Name == 'Test Bulk Account 2');
		System.assert(testAccounts[2].Name == 'Test Bulk Account 3');
		System.assert(testAccounts[3].Name == 'Test Bulk Account 4');
		System.assert(testAccounts[4].Name == 'Test Bulk Account 5');
		System.assert(testAccounts[5].Name == 'Test Bulk Account 6');
		System.assert(testAccounts[6].Name == 'Test Bulk Account 7');
		System.assert(testAccounts[7].Name == 'Test Bulk Account 8');
		System.assert(testAccounts[8].Name == 'Test Bulk Account 9');
		System.assert(testAccounts[9].Name == 'Test Bulk Account 10');
	}
	
	/**
	* @description dmlDeleteTest - Test the delete functionality of the Batchable_BulkDMLProcessor batch class
	*/
	public static testMethod void dmlDeleteTest() {
		// CREATE TEST ACCOUNT
    	List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 10);
    	insert testAccounts;

		// CHECK THAT ACCOUNTS WHERE CREATED
    	testAccounts = [SELECT Id, Name FROM Account WHERE Id IN :testAccounts];
		System.assert(testAccounts.size() == 10);

		Test.startTest();

		// UPDATE THEM USING BULK PROCESSOR
		Batchable_BulkDMLProcessor bulkProcessor = new Batchable_BulkDMLProcessor(testAccounts, 'Delete');
		Database.executeBatch(bulkProcessor, 15);

		Test.stopTest();

		// TEST THAT ACCOUNTS WERE UPDATED
		testAccounts = [SELECT Id, Name FROM Account];
		System.assert(testAccounts.size() == 0);
	}

	/**
	* @description invalidDMLTest - Test Batchable_BulkDMLProcessor batch class handling of an invalid DML type
	*/
	public static testMethod void invalidDMLTest() {
		// CREATE TEST ACCOUNT
    	List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 10);
    	insert testAccounts;

		Test.startTest();

		// UPDATE THEM USING BULK PROCESSOR
		Batchable_BulkDMLProcessor bulkProcessor = new Batchable_BulkDMLProcessor(testAccounts, 'Invalid');
		String jobId = Database.executeBatch(bulkProcessor, 15);

		Test.stopTest();

		// CHECK THAT JOB WAS CANCELLED
		List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];
		System.assert(!batchJobs.isEmpty());
		System.assert(batchJobs[0].Status == 'Aborted');
	}


}