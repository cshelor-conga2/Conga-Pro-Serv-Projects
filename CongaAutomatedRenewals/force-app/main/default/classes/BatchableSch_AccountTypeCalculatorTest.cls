/**
* @author ECS, ERedding
* @author Systemyc, GModica
* @date 20190620
* @version 1.00
* @description BatchableSch_AccountTypeCalculatorTest  - Test class for the BatchableSch_AccountTypeCalculator class
*/
@isTest
public with sharing class BatchableSch_AccountTypeCalculatorTest {

    /**
    * @description setup - Setup data used in testing
    */  
    @testSetup
    public static void setup() {
        TriggerHelper.OverrideAllSettings(true, true);

        // GET RECORD TYPES
        Map<String, Id> accountRTs = UtilityClass.getRecordTypesForObject('Account');
        Map<String, Id> contractRTs = UtilityClass.getRecordTypesForObject('Contract');    

        // CREATE TEST ACCOUNTS
        Account a1 = new Account(Name = 'Account 1', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Customer'); // NO ASSETS
        Account a2 = new Account(Name = 'Account 2', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Prospect'); // MIX OF ASSETS WHERE TOTAL ACTIVE QTY > 0
        Account a3 = new Account(Name = 'Account 3', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Customer'); // MIX OF ASSETS WHERE TOTAL ACTIVE QTY == 0
        Account a4 = new Account(Name = 'Account 4', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Customer'); // ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, NO RENEWAL OPP
        Account a5 = new Account(Name = 'Account 5', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Prospect'); // ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP WITHIN 90 DAYS
        Account a6 = new Account(Name = 'Account 6', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Customer'); // ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP WITHIN 90 DAYS BUT CLOSED LOST
        Account a7 = new Account(Name = 'Account 7', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Customer'); // ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP OLDER THAN 90 DAYS
        Account a8 = new Account(Name = 'Account 8', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Prospect'); // ONLY FUTURE ASSETS
        Account a9 = new Account(Name = 'Account 9', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Customer'); // ONLY EXPIRED ASSETS
        Account a10 = new Account(Name = 'Account 10', RecordTypeId = accountRTs.get('Partner_Account'), Type = 'Partner'); // NO CONTRACTS
        Account a11 = new Account(Name = 'Account 11', RecordTypeId = accountRTs.get('Partner_Account'), Type = 'Partner - Former'); // ACTIVE AND EXPIRED CONTRACTS
        Account a12 = new Account(Name = 'Account 12', RecordTypeId = accountRTs.get('Partner_Account'), Type = 'Prospective Partner'); // ONLY EXPIRED CONTRACTS

        // NEW FORECASTING OPPORTUNITY TEST ACCOUNTS
        Account a13 = new Account(Name = 'Account 13', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Prospect'); // NO ASSETS, CLOSED WON FORECAST OPP 
        Account a14 = new Account(Name = 'Account 14', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Customer'); // ONLY EXPIRED ASSETS, NO RENEWAL, OPEN FORECAST OPP
        Account a15 = new Account(Name = 'Account 15', RecordTypeId = accountRTs.get('Business_Account'), Type = 'Prospect'); // ONLY EXPIRED ASSETS, NO RENEWAL, CLOSED WON FORECAST OPP
        insert new List<Account>{ a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15 };

        // CREATE TEST PRODUCT
        Product2 tp = new Product2(Name = 'Test Product', ProductCode = 'TP');
        insert tp;

        // CREATE TEST RENEWAL OPPS
        List<Opportunity> testOpps = TestingUtility.createSObjectList('Opportunity', false, 6);
        testOpps[0].AccountId = a5.Id;
        testOpps[0].Type = 'Renewal';
        testOpps[0].MRR_Sub_Start__c = Date.today().addDays(-25);
        testOpps[0].MRR_Sub_End__c = testOpps[0].MRR_Sub_Start__c.addDays(365);

        testOpps[1].AccountId = a6.Id;
        testOpps[1].Type = 'Renewal';
        testOpps[1].MRR_Sub_Start__c = Date.today().addDays(-45);
        testOpps[1].MRR_Sub_End__c = testOpps[1].MRR_Sub_Start__c.addDays(365);
        testOpps[1].CloseDate = Date.today().addDays(-5);
        testOpps[1].StageName = 'Closed Lost';
        testOpps[1].Closed_Reason__c = 'Acquired'; 

        testOpps[2].AccountId = a7.Id;
        testOpps[2].Type = 'Renewal';
        testOpps[2].MRR_Sub_Start__c = Date.today().addDays(-94);
        testOpps[2].MRR_Sub_End__c = testOpps[2].MRR_Sub_Start__c.addDays(365);

        testOpps[3].AccountId = a13.Id;
        testOpps[3].Sub_Type__c = 'Forecasting Opportunity';
        testOpps[3].CloseDate = Date.today().addDays(-5);
        testOpps[3].StageName = 'Closed Won';       

        testOpps[4].AccountId = a14.Id;
        testOpps[4].Sub_Type__c = 'Forecasting Opportunity';

        testOpps[5].AccountId = a15.Id;
        testOpps[5].Sub_Type__c = 'Forecasting Opportunity';
        testOpps[5].CloseDate = Date.today().addDays(-5);
        testOpps[5].StageName = 'Closed Won';  
        insert testOpps;

        // CREATE TEST ASSETS USING STANDARD RECORD TYPE
        Id stdRTId = UtilityClass.getRecordTypesForObject('Asset').get('Standard');
        Date activeStart = Date.newInstance(Date.today().year(), 1, 1);
        Date activeEnd = Date.newInstance(Date.today().year(), 12, 31);
        Date expiredStart = Date.newInstance(Date.today().year()-1, 1, 1);
        Date expiredEnd = Date.newInstance(Date.today().year()-1, 12, 31);
        Date futureStart = Date.newInstance(Date.today().year()+1, 1, 1);
        Date futureEnd = Date.newInstance(Date.today().year()+1, 12, 31);       

        List<Asset> testAssets = TestingUtility.createSObjectList('Asset', false, 32);
        Integer counter = 1;
        for(Asset asset : testAssets){
            asset.Name = 'Asset ' + String.valueOf(counter);
            asset.Product2Id = tp.Id;
            asset.Type__c = 'Subscription';
            asset.RecordTypeId = stdRTId;
            counter++;
        }

        ////// ACCOUNT 2, MIX OF ASSETS WHERE TOTAL ACTIVE QTY > 0
        // ACTIVE 1
        testAssets[0].AccountId = a2.Id; testAssets[0].Quantity = 10; testAssets[0].Start_Date__c = activeStart; testAssets[0].End_Date__c = activeEnd;
        // ACTIVE 2
        testAssets[1].AccountId = a2.Id; testAssets[1].Quantity = 20; testAssets[1].Start_Date__c = activeStart; testAssets[1].End_Date__c = activeEnd;
        // FUTURE
        testAssets[2].AccountId = a2.Id; testAssets[2].Quantity = 45; testAssets[2].Start_Date__c = futureStart; testAssets[2].End_Date__c = futureEnd;
        // EXPIRED
        testAssets[3].AccountId = a2.Id; testAssets[3].Quantity = 10; testAssets[3].Start_Date__c = expiredStart; testAssets[3].End_Date__c = expiredEnd;

        ////// ACCOUNT 3, MIX OF ASSETS WHERE TOTAL ACTIVE QTY == 0
        // ACTIVE 1
        testAssets[4].AccountId = a3.Id; testAssets[4].Quantity = 15; testAssets[4].Start_Date__c = activeStart; testAssets[4].End_Date__c = activeEnd;
        // ACTIVE 2
        testAssets[5].AccountId = a3.Id; testAssets[5].Quantity = -15; testAssets[5].Start_Date__c = activeStart; testAssets[5].End_Date__c = activeEnd;
        // FUTURE
        testAssets[6].AccountId = a3.Id; testAssets[6].Quantity = 10; testAssets[6].Start_Date__c = futureStart; testAssets[6].End_Date__c = futureEnd;
        // EXPIRED
        testAssets[7].AccountId = a3.Id; testAssets[7].Quantity = 45; testAssets[7].Start_Date__c = expiredStart; testAssets[7].End_Date__c = expiredEnd;

        ////// ACCOUNT 4, ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, NO RENEWAL OPP
        // ACTIVE 1
        testAssets[8].AccountId = a4.Id; testAssets[8].Quantity = 35; testAssets[8].Start_Date__c = activeStart; testAssets[8].End_Date__c = activeEnd;
        // ACTIVE 2
        testAssets[9].AccountId = a4.Id; testAssets[9].Quantity = 25; testAssets[9].Start_Date__c = activeStart; testAssets[9].End_Date__c = activeEnd;
        // ACTIVE 3
        testAssets[10].AccountId = a4.Id; testAssets[10].Quantity = -60; testAssets[10].Start_Date__c = activeStart; testAssets[10].End_Date__c = activeEnd;
        // EXPIRED 1
        testAssets[11].AccountId = a4.Id; testAssets[11].Quantity = 15; testAssets[11].Start_Date__c = expiredStart; testAssets[11].End_Date__c = expiredEnd;

        ////// ACCOUNT 5, ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP WITHIN 90 DAYS
        // ACTIVE 1
        testAssets[12].AccountId = a5.Id; testAssets[12].Quantity = 35; testAssets[12].Start_Date__c = activeStart; testAssets[12].End_Date__c = activeEnd;
        // ACTIVE 2
        testAssets[13].AccountId = a5.Id; testAssets[13].Quantity = 25; testAssets[13].Start_Date__c = activeStart; testAssets[13].End_Date__c = activeEnd;
        // ACTIVE 3
        testAssets[14].AccountId = a5.Id; testAssets[14].Quantity = -60; testAssets[14].Start_Date__c = activeStart; testAssets[14].End_Date__c = activeEnd;
        // EXPIRED 1
        testAssets[15].AccountId = a5.Id; testAssets[15].Quantity = 15; testAssets[15].Start_Date__c = expiredStart; testAssets[15].End_Date__c = expiredEnd;

        ////// ACCOUNT 6, ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP WITHIN 90 DAYS BUT CLOSED LOST
        // ACTIVE 1
        testAssets[16].AccountId = a6.Id; testAssets[16].Quantity = 35; testAssets[16].Start_Date__c = activeStart; testAssets[16].End_Date__c = activeEnd;
        // ACTIVE 2
        testAssets[17].AccountId = a6.Id; testAssets[17].Quantity = -35; testAssets[17].Start_Date__c = activeStart; testAssets[17].End_Date__c = activeEnd;
        // EXPIRED 1
        testAssets[18].AccountId = a6.Id; testAssets[18].Quantity = 60; testAssets[18].Start_Date__c = expiredStart; testAssets[18].End_Date__c = expiredEnd;
        // EXPIRED 2
        testAssets[19].AccountId = a6.Id; testAssets[19].Quantity = 15; testAssets[19].Start_Date__c = expiredStart; testAssets[19].End_Date__c = expiredEnd;

        ////// ACCOUNT 7, ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP OLDER THAN 90 DAYS
        // ACTIVE 1
        testAssets[20].AccountId = a7.Id; testAssets[20].Quantity = 35; testAssets[20].Start_Date__c = activeStart; testAssets[20].End_Date__c = activeEnd;
        // ACTIVE 2
        testAssets[21].AccountId = a7.Id; testAssets[21].Quantity = -35; testAssets[21].Start_Date__c = activeStart; testAssets[21].End_Date__c = activeEnd;
        // EXPIRED 1
        testAssets[22].AccountId = a7.Id; testAssets[22].Quantity = 60; testAssets[22].Start_Date__c = expiredStart; testAssets[22].End_Date__c = expiredEnd;
        // EXPIRED 2
        testAssets[23].AccountId = a7.Id; testAssets[23].Quantity = 15; testAssets[23].Start_Date__c = expiredStart; testAssets[23].End_Date__c = expiredEnd;

        ////// ACCOUNT 8, ONLY FUTURE ASSETS
        // FUTURE 1
        testAssets[24].AccountId = a8.Id; testAssets[24].Quantity = 25; testAssets[24].Start_Date__c = futureStart; testAssets[24].End_Date__c = futureEnd;
        // FUTURE 2
        testAssets[25].AccountId = a8.Id; testAssets[25].Quantity = 10; testAssets[25].Start_Date__c = futureStart; testAssets[25].End_Date__c = futureEnd;

        ////// ACCOUNT 9 ONLY EXPIRED ASSETS  
        // EXPIRED 1
        testAssets[26].AccountId = a9.Id; testAssets[26].Quantity = 25; testAssets[26].Start_Date__c = expiredStart; testAssets[26].End_Date__c = expiredEnd;
        // EXPIRED 2
        testAssets[27].AccountId = a9.Id; testAssets[27].Quantity = 10; testAssets[27].Start_Date__c = expiredStart; testAssets[27].End_Date__c = expiredEnd;

        ////// ACCOUNT 14 ONLY EXPIRED ASSETS  
        // EXPIRED 1
        testAssets[28].AccountId = a14.Id; testAssets[28].Quantity = 25; testAssets[28].Start_Date__c = expiredStart; testAssets[28].End_Date__c = expiredEnd;
        // EXPIRED 2
        testAssets[29].AccountId = a14.Id; testAssets[29].Quantity = 10; testAssets[29].Start_Date__c = expiredStart; testAssets[29].End_Date__c = expiredEnd;

        ////// ACCOUNT 15 ONLY EXPIRED ASSETS  
        // EXPIRED 1
        testAssets[30].AccountId = a15.Id; testAssets[30].Quantity = 25; testAssets[30].Start_Date__c = expiredStart; testAssets[30].End_Date__c = expiredEnd;
        // EXPIRED 2
        testAssets[31].AccountId = a15.Id; testAssets[31].Quantity = 10; testAssets[31].Start_Date__c = expiredStart; testAssets[31].End_Date__c = expiredEnd;
        insert testAssets;

        // CREATE TEST CONTRACTS
        List<Contract> testContracts = TestingUtility.createSObjectList('Contract', false, 4);
        testContracts[0].AccountId = a11.Id;
        testContracts[0].StartDate = activeStart;
        testContracts[0].EndDate = activeEnd;
        testContracts[0].RecordTypeId = contractRTs.get('SI');
        //
        testContracts[1].AccountId = a11.Id;
        testContracts[1].StartDate = expiredStart;
        testContracts[1].EndDate = expiredEnd;
        testContracts[1].RecordTypeId = contractRTs.get('Reseller');
        //
        testContracts[2].AccountId = a12.Id;
        testContracts[2].StartDate = expiredStart;
        testContracts[2].EndDate = expiredEnd;
        testContracts[2].RecordTypeId = contractRTs.get('SI');
        //
        testContracts[3].AccountId = a12.Id;
        testContracts[3].StartDate = expiredStart;
        testContracts[3].EndDate = expiredEnd;
        testContracts[3].RecordTypeId = contractRTs.get('Reseller');
        insert testContracts;

        // ACTIVATE OR EXPIRE
        testContracts[0].Status = 'Activated';
        testContracts[1].Status = 'Expired';
        testContracts[2].Status = 'Expired';
        testContracts[3].Status = 'Expired';
        update testContracts;

        TriggerHelper.OverrideAllSettings(false, false);
    }

    /**
    * @description calculateAccountTypeTest_NoParams - Tests batchable and primary logic using constructor without parameters
    */   
    public static testmethod void calculateAccountTypeTest_NoParams() {
        Test.startTest();
    
        BatchableSch_AccountTypeCalculator batchProcess = new BatchableSch_AccountTypeCalculator();
        Database.executeBatch(batchProcess, 15);

        Test.stopTest();

        //Account a1 = CUSTOMER, NO ASSETS
        //Account a2 = CUSTOMER, MIX OF ASSETS WHERE TOTAL ACTIVE QTY > 0
        //Account a3 = CUSTOMER, MIX OF ASSETS WHERE TOTAL ACTIVE QTY == 0
        //Account a4 = CUSTOMER, ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, NO RENEWAL OPP
        //Account a5 = CUSTOMER, ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP WITHIN 90 DAYS
        //Account a6 = CUSTOMER, ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP WITHIN 90 DAYS BUT CLOSED LOST
        //Account a7 = CUSTOMER, ACTIVE AND EXPIRED ASSETS WHERE TOTAL ACTIVE QTY == 0, RENEWAL OPP OLDER THAN 90 DAYS
        //Account a8 = CUSTOMER, ONLY FUTURE ASSETS
        //Account a9 = CUSTOMER, ONLY EXPIRED ASSETS
        //Account a10 = PARTNER, NO CONTRACTS
        //Account a11 = PARTNER, ACTIVE AND EXPIRED CONTRACTS
        //Account a12 = PARTNER, ONLY EXPIRED CONTRACTS
        //Account a13 = NO ASSETS, CLOSED WON FORECAST OPP 
        //Account a14 = ONLY EXPIRED ASSETS, NO RENEWAL, OPEN FORECAST OPP
        //Account a15 = ONLY EXPIRED ASSETS, NO RENEWAL, CLOSED WON FORECAST OPP

        // GET ACCOUNTS AND CHECK FOR CORRECT DATA
        List<Account> testAccounts = [SELECT Id, Type FROM Account];
        System.assert(testAccounts.size() == 15);
        System.assert(testAccounts[0].Type == 'Prospect');
        System.assert(testAccounts[1].Type == 'Customer');
        System.assert(testAccounts[2].Type == 'Customer');
        System.assert(testAccounts[3].Type == 'Customer - Former');
        System.assert(testAccounts[4].Type == 'Customer - Past Due');
        System.assert(testAccounts[5].Type == 'Customer - Former');
        System.assert(testAccounts[6].Type == 'Customer - Former');
        System.assert(testAccounts[7].Type == 'Customer');
        System.assert(testAccounts[8].Type == 'Customer - Former');
        System.assert(testAccounts[9].Type == 'Prospective Partner');
        System.assert(testAccounts[10].Type == 'Partner');
        System.assert(testAccounts[11].Type == 'Partner - Former');

        System.assert(testAccounts[12].Type == 'Customer');
        System.assert(testAccounts[13].Type == 'Prospect');
        System.assert(testAccounts[14].Type == 'Customer');
    }

    /**
    * @description calculateAccountTypeTest_WithParams - Tests batchable and primary logic using constructor with parameters
    */   
    public static testmethod void calculateAccountTypeTest_WithParams() {
    	Set<Id> testAccountIds = new Set<Id>();
        for(Account acct : [SELECT Id, Type FROM Account]){
            testAccountIds.add(acct.Id);
        }
        System.assert(testAccountIds.size() == 15);

        Test.startTest();
    
        BatchableSch_AccountTypeCalculator batchProcess = new BatchableSch_AccountTypeCalculator(testAccountIds);
        Database.executeBatch(batchProcess, 15);

        Test.stopTest();

        // GET ACCOUNTS AND CHECK FOR CORRECT DATA
        List<Account> testAccounts = [SELECT Id, Type FROM Account];
        System.assert(testAccounts.size() == 15);
        System.assert(testAccounts[0].Type == 'Prospect');
        System.assert(testAccounts[1].Type == 'Customer');
        System.assert(testAccounts[2].Type == 'Customer');
        System.assert(testAccounts[3].Type == 'Customer - Former');
        System.assert(testAccounts[4].Type == 'Customer - Past Due');
        System.assert(testAccounts[5].Type == 'Customer - Former');
        System.assert(testAccounts[6].Type == 'Customer - Former');
        System.assert(testAccounts[7].Type == 'Customer');
        System.assert(testAccounts[8].Type == 'Customer - Former');
        System.assert(testAccounts[9].Type == 'Prospective Partner');
        System.assert(testAccounts[10].Type == 'Partner');
        System.assert(testAccounts[11].Type == 'Partner - Former');

        System.assert(testAccounts[12].Type == 'Customer');
        System.assert(testAccounts[13].Type == 'Prospect');
        System.assert(testAccounts[14].Type == 'Customer');
    }

    /**
    * @description schedulableTest - Tests schedulable execute method
    */
    public static testmethod void schedulableTest() {
        Test.startTest();

        BatchableSch_AccountTypeCalculator scheduled = new BatchableSch_AccountTypeCalculator();
        System.schedule('Update Account Type Test', '0 0 22 * * ?', scheduled);

        Test.stopTest();
    }


}