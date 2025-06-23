/**
* @author ECS, ERedding
* @date 20190627
* @version 1.00
* @description CustomerSuccessHelperTest  - Test class for the CustomerSuccessHelper class
*/
@isTest
public with sharing class CustomerSuccessHelperTest {

	/**
	* @description updateXCareCheckboxTest - Test for the updateXCareCheckbox trigger method
	*/
	public static testMethod void updateXCareCheckboxTest() {
		// CREATE TEST CUSTOMER SUCCESS RECORDS
		List<Customer_Success__c> testCSRecords = (List<Customer_Success__c>)TestingUtility.createSObjectList('Customer_Success__c', false, 2);
		testCSRecords[0].X_Care__c = false;
		testCSRecords[1].X_Care__c = false;
		insert testCSRecords;

		// CREATE TEST ACCOUNTS
		List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
		testAccounts[0].CS_Division_Stamp__c = 'Division 4';
		testAccounts[0].Customer_Success__c = testCSRecords[0].Id;
		testAccounts[1].CS_Division_Stamp__c = 'Division 5';
		testAccounts[1].Customer_Success__c = testCSRecords[1].Id;
		insert testAccounts;	

		Test.startTest();

		// MAKE QUALIFYING UPDATES TO CS RECORDS
		//// TOTAL Customer_Health_Total__c OF 3
		testCSRecords[0].Customer_Likely_To__c = 'Downsell';
		testCSRecords[0].License_Utilization__c = '<40%';
		//// TOTAL Customer_Health_Total__c OF 7
		testCSRecords[1].Customer_Likely_To__c = 'Renew at current level';
		testCSRecords[1].License_Utilization__c = '40-70%';
		update testCSRecords;

		// RELOAD RECORDS AND TEST FOR CORRECT DATA
		testCSRecords = [SELECT Id, X_Care__c FROM Customer_Success__c WHERE Id IN :testCSRecords];
		System.assert(testCSRecords[0].X_Care__c == true); // Customer_Health_Total__c IS 3, X CARE WILL BE CHECKED
		System.assert(testCSRecords[1].X_Care__c == false); // Customer_Health_Total__c IS 7, X CARE WILL NOT BE CHECKED

		// MAKE QUALIFYING UPDATES TO CS RECORDS
		//// TOTAL Customer_Health_Total__c OF 5
		testCSRecords[0].Customer_Likely_To__c = 'Downsell';
		testCSRecords[0].License_Utilization__c = '40-70%';
		//// TOTAL Customer_Health_Total__c OF 4
		testCSRecords[1].Customer_Likely_To__c = 'Churn - potential to save';
		testCSRecords[1].License_Utilization__c = '40-70%';
		update testCSRecords;

		// RELOAD RECORDS AND TEST FOR CORRECT DATA
		testCSRecords = [SELECT Id, X_Care__c FROM Customer_Success__c WHERE Id IN :testCSRecords];
		System.assert(testCSRecords[0].X_Care__c == false); // Customer_Health_Total__c IS 5, X CARE WILL NOT BE CHECKED
		System.assert(testCSRecords[1].X_Care__c == true); // Customer_Health_Total__c IS 4, X CARE WILL BE CHECKED

		Test.stopTest();
	}


}