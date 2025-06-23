/**
* @author ECS, ERedding
* @date 20200121
* @version 1.00
* @description BatchableSch_AccountCurrentResellerTest  - Test class for the BatchableSch_AccountCurrentReseller class
*/
@isTest
public with sharing class BatchableSch_AccountCurrentResellerTest {

    /**
    * @description setup - Setup data used in testing
    */  
    @testSetup
    public static void setup() {
        TriggerHelper.TemporaryOverride('AccountHelper','processSegmentAndDivisionChanges', false); // DISABLE TRIGGER SO IT DOESNT FIRE WHEN ACCOUNTS ARE CREATED
        TriggerHelper.TemporaryOverride('AssetHelper','calculateAccountType', false); // DISABLE TRIGGER SO IT DOESNT FIRE WHEN ASSETS ARE CREATED

        // CREATE TEST ACCOUNTS
        Account a1 = new Account(Name = 'Account 1', Type = 'Customer'); // NO ASSETS, NO OPPS, NO RESELLER
        Account a2 = new Account(Name = 'Account 2', Type = 'Customer'); // NO ASSETS, NO OPPS, HAS RESELLER
        Account a3 = new Account(Name = 'Account 3', Type = 'Customer'); // HAS ACTIVE ASSET, NO OPPS, NO RESELLER
        Account a4 = new Account(Name = 'Account 4', Type = 'Customer'); // HAS ACTIVE ASSET, NO OPPS, DIFFERENT RESELLER
        Account a5 = new Account(Name = 'Account 5', Type = 'Customer'); // HAS EXPIRED ASSET AND CLOSED WON OPP, NO RESELLER
        Account a6 = new Account(Name = 'Account 6', Type = 'Customer'); // HAS EXPIRED ASSET AND CLOSED WON OPP, DIFFERENT RESELLER
        Account a7 = new Account(Name = 'Account 7', Type = 'Customer'); // HAS ACTIVE ASSET AND CLOSED WON OPP, NO RESELLER
        insert new List<Account>{ a1, a2, a3, a4, a5, a6, a7 };

    	// CREATE TEST PARTNER PROFILES
    	Map<String, Id> partnerProfileRTs = UtilityClass.getRecordTypesForObject('Partner_Profile__c');
    	List<Partner_Profile__c> testPartnerProfiles = TestingUtility.createSObjectList('Partner_Profile__c', false, 9);
    	//// ASSET RESELLERS
    	testPartnerProfiles[0].Account__c = a3.Id;
    	testPartnerProfiles[0].RecordTypeId = partnerProfileRTs.get('OEM_Partner');
    	//
    	testPartnerProfiles[1].Account__c = a4.Id;
    	testPartnerProfiles[1].RecordTypeId = partnerProfileRTs.get('OEM_Partner');
    	//
    	testPartnerProfiles[2].Account__c = a7.Id;
    	testPartnerProfiles[2].RecordTypeId = partnerProfileRTs.get('OEM_Partner');
    	
    	//// OPPORTUNITY RESELLERS
    	testPartnerProfiles[3].Account__c = a5.Id;
    	testPartnerProfiles[3].RecordTypeId = partnerProfileRTs.get('Reseller_ISV_Partner');
    	//
    	testPartnerProfiles[4].Account__c = a6.Id;
    	testPartnerProfiles[4].RecordTypeId = partnerProfileRTs.get('Reseller_ISV_Partner');
    	//
    	testPartnerProfiles[5].Account__c = a7.Id;
    	testPartnerProfiles[5].RecordTypeId = partnerProfileRTs.get('Reseller_ISV_Partner');

    	//// ACCOUNT RESELLERS
    	testPartnerProfiles[6].Account__c = a2.Id;
    	testPartnerProfiles[6].RecordTypeId = partnerProfileRTs.get('OEM_Partner');
    	//
    	testPartnerProfiles[7].Account__c = a4.Id;
    	testPartnerProfiles[7].RecordTypeId = partnerProfileRTs.get('Reseller_ISV_Partner');
    	//
    	testPartnerProfiles[8].Account__c = a6.Id;
    	testPartnerProfiles[8].RecordTypeId = partnerProfileRTs.get('OEM_Partner');
    	insert testPartnerProfiles;

    	// SET CURRENT RESELLERS ON ACCOUNTS
    	a2.Current_Reseller__c = testPartnerProfiles[6].Id;
    	a4.Current_Reseller__c = testPartnerProfiles[7].Id;
    	a6.Current_Reseller__c = testPartnerProfiles[8].Id;
    	update new List<Account>{ a2, a4, a6 };

        // CREATE TEST PRODUCT
        Product2 tp = new Product2(Name = 'Test Product', ProductCode = 'TP');
        insert tp;

        // CREATE TEST OPPS
        List<Opportunity> testOpps = TestingUtility.createSObjectList('Opportunity', false, 3);
        testOpps[0].AccountId = a5.Id;
        testOpps[0].Type = 'New Business';
        testOpps[0].StageName = 'Closed Won';
        testOpps[0].CloseDate = Date.today();
        testOpps[0].Reseller__c = testPartnerProfiles[3].Id;
        //
        testOpps[1].AccountId = a6.Id;
        testOpps[1].Type = 'Existing Business';
        testOpps[1].StageName = 'Closed Won';
        testOpps[1].CloseDate = Date.today();
        testOpps[1].Reseller__c = testPartnerProfiles[4].Id;
        //
        testOpps[2].AccountId = a7.Id;
        testOpps[2].Type = 'Renewal';
        testOpps[2].StageName = 'Closed Won'; 
        testOpps[2].CloseDate = Date.today();
        testOpps[2].Reseller__c = testPartnerProfiles[5].Id;
        insert testOpps;

        // CREATE TEST ASSETS USING STANDARD RECORD TYPE
        Id stdRTId = UtilityClass.getRecordTypesForObject('Asset').get('Standard');
        Date activeStart = Date.newInstance(Date.today().year(), 1, 1);
        Date activeEnd = Date.newInstance(Date.today().year(), 12, 31);
        Date expiredStart = Date.newInstance(Date.today().year()-1, 1, 1);
        Date expiredEnd = Date.newInstance(Date.today().year()-1, 12, 31);

        List<Asset> testAssets = TestingUtility.createSObjectList('Asset', false, 5);
        for(Asset asset : testAssets){
            asset.Product2Id = tp.Id;
            asset.Type__c = 'Subscription';
            asset.RecordTypeId = stdRTId;
        }

        //// ACCOUNT 3, HAS ACTIVE ASSET, NO OPPS, NO RESELLER
        testAssets[0].AccountId = a3.Id;
        testAssets[0].Quantity = 10;
        testAssets[0].Start_Date__c = activeStart;
        testAssets[0].End_Date__c = activeEnd;
        testAssets[0].Reseller__c = testPartnerProfiles[0].Id;
        //// ACCOUNT 4, HAS ACTIVE ASSET, NO OPPS, DIFFERENT RESELLER
        testAssets[1].AccountId = a4.Id;
        testAssets[1].Quantity = 10;
        testAssets[1].Start_Date__c = activeStart;
        testAssets[1].End_Date__c = activeEnd;
        testAssets[1].Reseller__c = testPartnerProfiles[1].Id;
        //// ACCOUNT 5, HAS EXPIRED ASSET AND CLOSED WON OPP, NO RESELLER
        testAssets[2].AccountId = a5.Id;
        testAssets[2].Quantity = 10;
        testAssets[2].Start_Date__c = expiredStart;
        testAssets[2].End_Date__c = expiredEnd;
        //// ACCOUNT 6, HAS EXPIRED ASSET AND CLOSED WON OPP, DIFFERENT RESELLER
        testAssets[3].AccountId = a6.Id;
        testAssets[3].Quantity = 10;
        testAssets[3].Start_Date__c = expiredStart;
        testAssets[3].End_Date__c = expiredEnd;
        //// ACCOUNT 7, HAS ACTIVE ASSET AND CLOSED WON OPP, NO RESELLER
		testAssets[4].AccountId = a7.Id;
		testAssets[4].Quantity = 10;
		testAssets[4].Start_Date__c = activeStart;
		testAssets[4].End_Date__c = activeEnd;
		testAssets[4].Reseller__c = testPartnerProfiles[2].Id;
        insert testAssets;
    }

    /**
    * @description accountCurrentResellerTest_NoParams - Tests batchable and primary logic using constructor without parameters
    */   
    public static testmethod void accountCurrentResellerTest_NoParams() {
    	// GET TEST PARTNER PROFILES
    	List<Partner_Profile__c> testPartnerProfiles = [SELECT Id FROM Partner_Profile__c];
    	System.assert(testPartnerProfiles.size() == 9);

        Test.startTest();
    
        BatchableSch_AccountCurrentReseller batchProcess = new BatchableSch_AccountCurrentReseller();
        Database.executeBatch(batchProcess, 10);

        Test.stopTest();

        // Account a1 = NO ASSETS, NO OPPS, NO RESELLER
        // Account a2 = NO ASSETS, NO OPPS, HAS RESELLER
        // Account a3 = HAS ACTIVE ASSET, NO OPPS, NO RESELLER
        // Account a4 = HAS ACTIVE ASSET, NO OPPS, DIFFERENT RESELLER
        // Account a5 = HAS EXPIRED ASSET AND CLOSED WON OPP, NO RESELLER
        // Account a6 = HAS EXPIRED ASSET AND CLOSED WON OPP, DIFFERENT RESELLER
        // Account a7 = HAS ACTIVE ASSET AND CLOSED WON OPP, NO RESELLER

        // GET ACCOUNTS AND CHECK FOR CORRECT DATA
        List<Account> testAccounts = [SELECT Id, Current_Reseller__c FROM Account];
        System.assert(testAccounts.size() == 7);
        System.assert(testAccounts[0].Current_Reseller__c == null);
        System.assert(testAccounts[1].Current_Reseller__c == null);
        System.assert(testAccounts[2].Current_Reseller__c == testPartnerProfiles[0].Id);
        System.assert(testAccounts[3].Current_Reseller__c == testPartnerProfiles[1].Id);
        System.assert(testAccounts[4].Current_Reseller__c == testPartnerProfiles[3].Id);
        System.assert(testAccounts[5].Current_Reseller__c == testPartnerProfiles[4].Id);
        System.assert(testAccounts[6].Current_Reseller__c == testPartnerProfiles[2].Id);
    }

    /**
    * @description accountCurrentResellerTest_WithParams - Tests batchable and primary logic using constructor with parameters
    */   
    public static testmethod void accountCurrentResellerTest_WithParams() {
    	// GET TEST PARTNER PROFILES
    	List<Partner_Profile__c> testPartnerProfiles = [SELECT Id FROM Partner_Profile__c];
    	System.assert(testPartnerProfiles.size() == 9);

    	// CREATE SET OF ACCOUNT IDS
    	Set<Id> testAccountIds = new Set<Id>();
        for(Account acct : [SELECT Id, Type FROM Account]){
            testAccountIds.add(acct.Id);
        }
        System.assert(testAccountIds.size() == 7);

        Test.startTest();
    
        BatchableSch_AccountCurrentReseller batchProcess = new BatchableSch_AccountCurrentReseller(testAccountIds);
        Database.executeBatch(batchProcess, 10);

        Test.stopTest();

        // GET ACCOUNTS AND CHECK FOR CORRECT DATA
        List<Account> testAccounts = [SELECT Id, Current_Reseller__c FROM Account];
        System.assert(testAccounts.size() == 7);
        System.assert(testAccounts[0].Current_Reseller__c == null);
        System.assert(testAccounts[1].Current_Reseller__c == null);
        System.assert(testAccounts[2].Current_Reseller__c == testPartnerProfiles[0].Id);
        System.assert(testAccounts[3].Current_Reseller__c == testPartnerProfiles[1].Id);
        System.assert(testAccounts[4].Current_Reseller__c == testPartnerProfiles[3].Id);
        System.assert(testAccounts[5].Current_Reseller__c == testPartnerProfiles[4].Id);
        System.assert(testAccounts[6].Current_Reseller__c == testPartnerProfiles[2].Id);
    }

    /**
    * @description schedulableTest - Tests schedulable execute method
    */
    public static testmethod void schedulableTest() {
        Test.startTest();

        BatchableSch_AccountCurrentReseller scheduled = new BatchableSch_AccountCurrentReseller();
        System.schedule('Update Account Type Test', '0 0 22 * * ?', scheduled);

        Test.stopTest();
    }


}