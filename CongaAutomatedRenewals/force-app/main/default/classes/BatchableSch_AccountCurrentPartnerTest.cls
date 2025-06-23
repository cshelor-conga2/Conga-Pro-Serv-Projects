/**
* @author ECS, ERedding
* @date 20200223
* @version 1.00
* @description BatchableSch_AccountCurrentPartnerTest - Test class for the BatchableSch_AccountCurrentPartner class
*/
@isTest
public with sharing class BatchableSch_AccountCurrentPartnerTest {

    /**
    * @description setup - Setup data used in testing
    */  
    @testSetup
    public static void setup() {
    	// GET ACCOUNT RECORD TYPES
    	Map<String, Id> accountRTs = UtilityClass.getRecordTypesForObject('Account');

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', false, 4);
        testAccounts[0].Name = 'Partner Account';
        testAccounts[0].Type = 'Partner';
        testAccounts[0].RecordTypeId = accountRTs.get('Partner_Account');
        //
        testAccounts[1].Name = 'Conga Pro Serv Account';
        testAccounts[1].Type = 'Partner';
        testAccounts[1].RecordTypeId = accountRTs.get('Partner_Account');
        //
        testAccounts[2].Name = 'Test Account ABCD';
        testAccounts[2].Type = 'Customer';
        testAccounts[2].RecordTypeId = accountRTs.get('Business_Account');
        //
        testAccounts[3].Name = 'Test Account EFGH';
        testAccounts[3].Type = 'Customer';
        testAccounts[3].RecordTypeId = accountRTs.get('Business_Account');
        insert testAccounts;

        // SET CURRENT PARTNER ON AN ACCOUNT
        testAccounts[3].Current_Implementation_PartnerId__c = testAccounts[1].Id;
        update testAccounts[3];
    
    	// GET PROJECT RECORD TYPES
    	Map<String, Id> projectRTs = UtilityClass.getRecordTypesForObject('PS_Project__c');

    	// CREATE TEST PROJECTS
        List<PS_Project__c> testProjects = TestingUtility.createSObjectList('PS_Project__c', false, 3);
        testProjects[0].AccountId__c = testAccounts[2].Id;
       	testProjects[0].RecordTypeId = projectRTs.get('PS_Project');
		testProjects[0].Partner_Company_Name_Engaged__c = testAccounts[1].Id;
       	testProjects[0].Is_Active__c = true;
       	testProjects[0].CreatedDate = Date.today().addDays(-1);
       	//
       	testProjects[1].AccountId__c = testAccounts[2].Id;
       	testProjects[1].RecordTypeId = projectRTs.get('Partner');
       	testProjects[1].Partner_Company_Name_Engaged__c = testAccounts[0].Id;
       	testProjects[1].Is_Active__c = true;
       	//
       	testProjects[2].AccountId__c = testAccounts[3].Id;
       	testProjects[2].RecordTypeId = projectRTs.get('PS_Project');
       	testProjects[2].Partner_Company_Name_Engaged__c = testAccounts[1].Id;
       	testProjects[2].Is_Active__c = false;
       	insert testProjects;
	}

    /**
    * @description accountCurrentPartnerTest_NoParams - Tests batchable and primary logic using constructor without parameters
    */   
    public static testmethod void accountCurrentPartnerTest_NoParams() {
    	// GET TEST ACCOUNTS
    	List<Account> testAccounts = [SELECT Id, Type, Current_Implementation_PartnerId__c FROM Account];
    	System.assert(testAccounts.size() == 4);
    	System.assert(testAccounts[0].Type == 'Partner');
    	System.assert(testAccounts[1].Type == 'Partner');
    	System.assert(testAccounts[2].Current_Implementation_PartnerId__c == null);
    	System.assert(testAccounts[3].Current_Implementation_PartnerId__c != null);

        Test.startTest();
    
        BatchableSch_AccountCurrentPartner batchProcess = new BatchableSch_AccountCurrentPartner();
        Database.executeBatch(batchProcess, 10);

        Test.stopTest();

        // RELOAD ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, Name, Type, Current_Implementation_PartnerId__c FROM Account];
    	System.assert(testAccounts.size() == 4);
    	System.assert(testAccounts[2].Current_Implementation_PartnerId__c == testAccounts[0].Id);
    	System.assert(testAccounts[3].Current_Implementation_PartnerId__c == null);
    }

    /**
    * @description accountCurrentPartnerTest_WithParams - Tests batchable and primary logic using constructor with parameters
    */   
    public static testmethod void accountCurrentPartnerTest_WithParams() {
    	// GET TEST ACCOUNTS
    	List<Account> testAccounts = [SELECT Id, Type, Current_Implementation_PartnerId__c FROM Account];
    	System.assert(testAccounts.size() == 4);
    	System.assert(testAccounts[0].Type == 'Partner');
    	System.assert(testAccounts[1].Type == 'Partner');
    	System.assert(testAccounts[2].Current_Implementation_PartnerId__c == null);
    	System.assert(testAccounts[3].Current_Implementation_PartnerId__c != null);

    	// CREATE SET OF ACCOUNT IDS
    	Set<Id> testAccountIds = new Set<Id>{ testAccounts[2].Id, testAccounts[3].Id };

        Test.startTest();
    
        BatchableSch_AccountCurrentPartner batchProcess = new BatchableSch_AccountCurrentPartner(testAccountIds);
        Database.executeBatch(batchProcess, 10);

        Test.stopTest();

        // RELOAD ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, Type, Current_Implementation_PartnerId__c FROM Account];
    	System.assert(testAccounts.size() == 4);
    	System.assert(testAccounts[2].Current_Implementation_PartnerId__c == testAccounts[0].Id);
    	System.assert(testAccounts[3].Current_Implementation_PartnerId__c == null);
    }

    /**
    * @description schedulableTest - Tests schedulable execute method
    */
    public static testmethod void schedulableTest() {
        Test.startTest();

        BatchableSch_AccountCurrentPartner scheduled = new BatchableSch_AccountCurrentPartner();
        System.schedule('Update Account Current Partner Test', '0 0 22 * * ?', scheduled);

        Test.stopTest();
    }


}