/**
* @author ECS, ERedding
* @date 20190830
* @version 1.00
* @description ApexAuditHelperTest - 
*/
@isTest
public without sharing class ApexAuditHelperTest {

	/**
	* @description startAuditTest - Test the startAudit method which creates a new AuditWrapper
	*/
    public static testmethod void startAuditTest() {
    	Test.startTest();

    	System.assert(ApexAuditHelper.AuditWrappers.isEmpty());

    	ApexAuditHelper.startAudit('TestClass', 'TestMethod');
    
		System.assert(!ApexAuditHelper.AuditWrappers.isEmpty());
		System.assert(ApexAuditHelper.AuditWrappers.values()[0].UniqueID == 'TestClass.TestMethod');

		Test.stopTest();
    }

	/**
	* @description stopAuditTest - Test the startAudit method which updates a new AuditWrapper with the current limit usage
	*/
    public static testmethod void stopAuditTest() {
    	Test.startTest();

    	ApexAuditHelper.startAudit('TestClass', 'TestMethod');
    	System.assert(!ApexAuditHelper.AuditWrappers.isEmpty());

    	System.assert(ApexAuditHelper.AuditWrappers.values()[0].CPUUsage != null);
    	System.assert(ApexAuditHelper.AuditWrappers.values()[0].SOQLUsage != null);
    	System.assert(ApexAuditHelper.AuditWrappers.values()[0].DMLUsage != null);

    	ApexAuditHelper.stopAudit('TestClass', 'TestMethod');

    	Test.stopTest();
    }

	/**
	* @description saveAuditsTest - Test the saveAudits method which creates/updates the necessary records
	*/
    public static testmethod void saveAuditsTest() {
    	Test.startTest();

    	ApexAuditHelper.StartingDispatcher = 'TestDispatcher';

		// START AND STOP AUDIT 1
		ApexAuditHelper.startAudit('TestClass1', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass1', 'TestMethod');

		// START AND STOP AUDIT 2
		ApexAuditHelper.startAudit('TestClass2', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass2', 'TestMethod');

		// START AND STOP AUDIT 3
		ApexAuditHelper.startAudit('TestClass3', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass3', 'TestMethod');

		// START AND STOP AUDIT 4
		ApexAuditHelper.startAudit('TestClass4', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass4', 'TestMethod');

		// START AND STOP AUDIT 5
		ApexAuditHelper.startAudit('TestClass5', 'TestMethod');
		ApexAuditHelper.startAudit('TestClass5', 'TestMethod'); // REPEATED ON PURPOSE TO TEST DUPE CATCHING
		ApexAuditHelper.stopAudit('TestClass5', 'TestMethod');

		// START AND STOP AUDIT 6
		ApexAuditHelper.startAudit('TestClass6', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass6', 'TestMethod');

		// START AND STOP AUDIT 7
		ApexAuditHelper.startAudit('TestClass7', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass7', 'TestMethod');

		// START AND STOP AUDIT 8
		ApexAuditHelper.startAudit('TestClass8', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass8', 'TestMethod');

		// START AND STOP AUDIT 9
		ApexAuditHelper.startAudit('TestClass9', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass9', 'TestMethod');
		
		// START AND STOP AUDIT 10
		ApexAuditHelper.startAudit('TestClass10', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass10', 'TestMethod');

		ApexAuditHelper.saveAudits('TestDispatcher');
		System.assert(ApexAuditHelper.StartingDispatcher == null);

    	// GET NEWLY CREATED AUDIT HEADERS AND DETAILS
    	List<Apex_Audit__c> auditHeaders = [SELECT Id, (SELECT Id FROM ApexAuditSnapshots__r) FROM Apex_Audit__c];
    	System.assert(auditHeaders.size() == 10);
    	System.assert(auditHeaders[0].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[1].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[2].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[3].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[4].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[5].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[6].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[7].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[8].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[9].ApexAuditSnapshots__r.size() == 1);

    	// SET MAX NUMBER OF DETAILS TO 1
    	auditHeaders[0].Max_Number_of_Details__c = 1;
    	auditHeaders[1].Max_Number_of_Details__c = 2;
    	update auditHeaders;

    	ApexAuditHelper.StartingDispatcher = 'TestDispatcher';

		// START AND STOP AUDIT 11, AUDIT 1 WILL BE RECYCLED
		ApexAuditHelper.startAudit('TestClass1', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass1', 'TestMethod');

		// START AND STOP AUDIT 12, AUDIT 2 WILL BE CREATED
		ApexAuditHelper.startAudit('TestClass2', 'TestMethod');
		ApexAuditHelper.stopAudit('TestClass2', 'TestMethod');

		ApexAuditHelper.saveAudits('TestDispatcher');
		System.assert(ApexAuditHelper.StartingDispatcher == null);

    	// GET NEWLY CREATED AUDIT HEADERS AND DETAILS
    	auditHeaders = [SELECT Id, (SELECT Id FROM ApexAuditSnapshots__r) FROM Apex_Audit__c];
    	System.assert(auditHeaders.size() == 10);
    	System.assert(auditHeaders[0].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[1].ApexAuditSnapshots__r.size() == 2);
    	System.assert(auditHeaders[2].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[3].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[4].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[5].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[6].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[7].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[8].ApexAuditSnapshots__r.size() == 1);
    	System.assert(auditHeaders[9].ApexAuditSnapshots__r.size() == 1);

    	Test.stopTest();
    }


}