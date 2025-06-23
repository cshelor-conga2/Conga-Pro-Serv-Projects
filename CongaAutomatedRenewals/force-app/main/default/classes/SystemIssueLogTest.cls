/**
* @author Conga Services
* @date 20180611
* @version 1.00
* @description SystemIssueLogTest - Test class for the SystemIssueLogHelper and SystemIssueLogWrapper classes
*/
@isTest
public with sharing class SystemIssueLogTest{

    /**
    * @description testMethod1_TestSingle - Test System Issue Logger using a single wrapper
    */
    public static testMethod void testMethod1_TestSingle() {
        Test.startTest();

        SystemIssueLogWrapper newLogWrapper = new SystemIssueLogWrapper('SystemIssueLog_Test', 'testMethod1_TestSingle', new List<Id>(), 'Exception');
        SystemIssueLogHelper.LogException(newLogWrapper, false);
        SystemIssueLogHelper.UpsertExceptions();

        List<System_Issue_Log__c> logRecords = [SELECT Id, Class_Name__c, Method_Name__c, Message__c, Record_Ids__c FROM System_Issue_Log__c];
        System.assert(logRecords.size() == 1);    

        SystemIssueLogWrapper newLogWrapper2 = new SystemIssueLogWrapper(logRecords[0]);

        Test.stopTest();
    }

    /**
    * @description testMethod2_LogMultiple - Test System Issue Logger using a list of wrappers
    */
    public static testMethod void testMethod2_LogMultiple() {
        Test.startTest();

        Lead testLead = new Lead();
        Lead testLead2 = new Lead();
        List<Lead> testLeads = new List<Lead>{ testLead, testLead2 };
  
        List<SystemIssueLogWrapper> logs = new List<SystemIssueLogWrapper>();
        Database.SaveResult sr = Database.insert(testLead, false);
        for(Database.Error err : sr.getErrors()){
            SystemIssueLogWrapper newLogWrapper = new SystemIssueLogWrapper('SystemIssueLog_Test1', 'testMethod2_LogMultiple', SystemIssueLogHelper.CreateListofIds(testLeads), err);
            SystemIssueLogWrapper newLogWrapper2 = new SystemIssueLogWrapper('SystemIssueLog_Test2', 'testMethod2_LogMultiple', SystemIssueLogHelper.CreateListofIds((List<SObject>)testLeads), err);
            logs.add(newLogWrapper);
        }

        try{
            insert testLead2;
        }
        catch(Exception ex){               
            SystemIssueLogWrapper newLogWrapper = new SystemIssueLogWrapper('SystemIssueLog_Test1', 'testMethod2_LogMultiple', SystemIssueLogHelper.CreateListofIds(new Set<Id>{ '00Q5000001L7Xbx', '00Q5000001L7Weq' }), ex);
            SystemIssueLogWrapper newLogWrapper2 = new SystemIssueLogWrapper('SystemIssueLog_Test2', 'testMethod2_LogMultiple', SystemIssueLogHelper.CreateListofIds('00Q5000001L7Xty'), ex);
            logs.add(newLogWrapper); logs.add(newLogWrapper2);
        }

        SystemIssueLogHelper.LogException(logs, false);
        SystemIssueLogHelper.UpsertExceptions();

        System.assert([SELECT Id FROM System_Issue_Log__c].size() == 3); // ONLY TWO ERRORS WILL EXIST BECAUSE OF ERROR DUPLICATE PREVENTION

        Test.stopTest();
    }

    /**
    * @description testMethod3_ImmediateUpsert - Test System Issue Logger using a single wrapper and immediate upsert
    */
    public static testMethod void testMethod3_ImmediateUpsert() {
        Test.startTest();

        SystemIssueLogWrapper newLogWrapper = new SystemIssueLogWrapper('SystemIssueLog_Test', 'testMethod3_ImmediateUpsert', new List<Id>(), 'Exception');
        SystemIssueLogHelper.LogException(newLogWrapper, true);

        System.assert([SELECT Id FROM System_Issue_Log__c].size() == 1);

        Test.stopTest();
    } 

    /**
    * @description testMethod4_ImmediateMultipleUpsert - Test System Issue Logger using multiple wrappers and immediate upsert
    */
    public static testMethod void testMethod4_ImmediateMultipleUpsert() {
        Test.startTest();

        SystemIssueLogWrapper newLogWrapper = new SystemIssueLogWrapper('SystemIssueLog_Test', 'testMethod4_ImmediateMultipleUpsert', new List<Id>{ '001i000001lLPXw', '001i000001lLPXw' }, 'Exception');
        SystemIssueLogWrapper newLogWrapper2 = new SystemIssueLogWrapper('SystemIssueLog_Test', 'testMethod4_ImmediateMultipleUpsert', new List<Id>(), 'Exception Is different');
        List<SystemIssueLogWrapper> wrappers = new List<SystemIssueLogWrapper>{ newLogWrapper, newLogWrapper2 };
        SystemIssueLogHelper.LogException(wrappers, true);

        System.assert([SELECT Id FROM System_Issue_Log__c].size() == 2);

        Test.stopTest();
    }

    /**
    * @description testMethod4_ImmediateMultipleUpsert - Test System Issue Logger using multiple wrappers and immediate upsert
    */
    public static testMethod void testMethod5_LogDatabaseResult() {
        Account testAccount = new Account(Name = 'Test Account');
        List<Account> acctList = new List<Account>();
        acctList.add(testAccount);

        Test.startTest();

        // TRY UPDATING NON EXISTENT ACCOUNT
        List<Database.SaveResult> saveResults = Database.update(acctList, false);        
        SystemIssueLogHelper.CheckForDatabaseErrors(saveResults, 'SystemIssueLogTest', 'testMethod5_LogDatabaseResult', false);

        // TRY UPSERTING NON EXISTENT ACCOUNT
        List<Database.UpsertResult> upsertResults = Database.upsert(acctList, Account.CRMC_Org_Account_ID__c, false);        
        SystemIssueLogHelper.CheckForDatabaseErrors(upsertResults, 'SystemIssueLogTest', 'testMethod5_LogDatabaseResult', false);

        // TRY UNDELETING AN EXISTING ACCOUNT
        insert acctList;         
        List<Database.UndeleteResult> undeleteResults = Database.undelete(acctList, false);
        SystemIssueLogHelper.CheckForDatabaseErrors(undeleteResults, 'SystemIssueLogTest', 'testMethod5_LogDatabaseResult', false);

        // TRY DELETING AN ALREADY DELETED ACCOUNT
        delete acctList;           
        List<Database.DeleteResult> deleteResults = Database.delete(acctList, false);
        SystemIssueLogHelper.CheckForDatabaseErrors(deleteResults, 'SystemIssueLogTest', 'testMethod5_LogDatabaseResult', false);

        // COMMIT ERRORS TO DATABASE
        SystemIssueLogHelper.UpsertExceptions();
        // TEST FOR CORRECT NUMBER OF LOGGED ERRORS
        System.assert([SELECT Id FROM System_Issue_Log__c].size() == 4);

        Test.stopTest();
    }


    /**
    * @description testMethod6_TestCatchAll - Test System Issue Logger using the simplified catch all method
    */
    public static testMethod void testMethod6_TestCatchAll() {
        String className = 'TestClassName';
        String methodName = 'TestClassMethodName';

        Account testAccount = new Account(Name = 'Test Account');
        Account testAccount2 = new Account();

        List<Account> acctList = new List<Account>{ testAccount, testAccount2 };
        Database.SaveResult[] results = Database.insert(acctList, false);

        Map<Id, SObject> sObjectMap = new Map<Id, SObject>{ testAccount.Id => testAccount };
        List<SObject> sObjectList = (List<SObject>)acctList;
        List<Id> idList = new List<Id>{ testAccount.Id };
        Set<Id> idSet = new Set<Id>{ testAccount.Id };

        Exception testEx;
        try{
            insert testAccount2;
        }
        catch(Exception ex){
            testEx = ex;
        }

        Test.startTest();

        SystemIssueLogHelper.LogException('TestClassName1', 'TestMethod1', acctList, 'Error Message', false);
        SystemIssueLogHelper.LogException('TestClassName2', 'TestMethod2', sObjectMap, testEx, false);        
        SystemIssueLogHelper.LogException('TestClassName3', 'TestMethod3', sObjectList, 'Error Message', false);
        SystemIssueLogHelper.LogException('TestClassName4', 'TestMethod4', idList, testEx, false);
        SystemIssueLogHelper.LogException('TestClassName5', 'TestMethod5', idSet, results[1].getErrors()[0], false);
        SystemIssueLogHelper.LogException('TestClassName6', 'TestMethod6', testAccount.Id, results[1].getErrors()[0], false);        
        SystemIssueLogHelper.LogException('TestClassName7', 'TestMethod7', null, null, false);
        SystemIssueLogHelper.UpsertExceptions();

        List<System_Issue_Log__c> logRecords = [SELECT Id, Class_Name__c, Method_Name__c, Message__c, Record_Ids__c, Issue_UniqueID__c FROM System_Issue_Log__c];
        System.assert(logRecords.size() == 7);    

        Test.stopTest();
    }


}