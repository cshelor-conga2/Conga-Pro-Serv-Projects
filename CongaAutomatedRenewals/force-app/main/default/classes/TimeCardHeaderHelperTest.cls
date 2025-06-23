/**
* @author ECS, ERedding
* @date 20190605
* @version 1.00
* @description TimeCardHeaderHelperTest - Test class for the TimeCardHeaderHelper class
*/
@isTest
public with sharing class TimeCardHeaderHelperTest {

	/**
    * @description intacctSyncTimeCardHeadersTest - 
    */	
	static testmethod void intacctSyncTimeCardHeadersTest() {
		// CREATE TEST PERIOD
		List<Period__c> testPeriods = TestingUtility.createSObjectList('Period__c', true, 1);
		testPeriods[0].Start_Date__c = Date.newInstance(2019, 6, 1);
		testPeriods[0].End_Date__c = Date.newInstance(2019, 6, 31);
		testPeriods[0].Type__c = 'Month';
		insert testPeriods;

		// CREATE TEST TIME CARD HEADERS AND INSERT TO COVER TimeCardHeaderHelper CODE.
		List<Time_Card_Header__c> testHeaders = TestingUtility.createSObjectList('Time_Card_Header__c', true, 2);
		testHeaders[0].PeriodId__c = testPeriods[0].Id;
		testHeaders[0].Status__c = 'Completed';
		testHeaders[0].UserId__c = UserInfo.getUserId();
		testHeaders[1].PeriodId__c = testPeriods[0].Id;
		testHeaders[1].Status__c = 'Open';
		testHeaders[1].UserId__c = UserInfo.getUserId();
		insert testHeaders;
	}


}