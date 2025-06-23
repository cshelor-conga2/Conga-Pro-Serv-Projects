/**
* @author Conga Services, DNelson, ERedding
* @date 20180911
* @version 1.00
* @description BatchableSch_AutoRenewContractsTest - Test class for the BatchableSch_AutoRenewContracts class
*/
@isTest
public with sharing class BatchableSch_AutoRenewContractsTest {

    /**
    * @description contractQualifiedTest_Batchable - Tests the batchable functionality of the BatchableSch_AutoRenewContracts class
    */
    public static testmethod void contractQualifiedTest_Batchable() {
        String query = 'SELECT Id, SBQQ__RenewalOpportunity__c,SBQQ__RenewalQuoted__c, RecordTypeId, EndDate FROM Contract WHERE SBQQ__RenewalOpportunity__c != null AND RecordTypeId = :CustomerSubscriptionRTId AND EndDate = :ninetyDays';

        Account testAccount = new Account();      
        testAccount.Name = 'Test Account';
        testAccount.BillingStreet = '123 Test St';
        testAccount.BillingCity = 'New Haven';
        testAccount.BillingState = 'CT';
        testAccount.BillingPostalCode = '06608';
        testAccount.BillingCountry = 'United States';
        insert testAccount;

        Contract testContract = new Contract (
            AccountId = testAccount.Id,
            Name = 'Test Contract',
            Status = 'Draft',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(90),
            SBQQ__RenewalQuoted__c = false
        );
        insert testContract;
        System.assert(testContract.Id != null, 'The test contract did not insert');        

        Contract testContractTwo = new Contract (
            AccountId = testAccount.Id,
            Name = 'Test Contract',
            Status = 'Draft',
            StartDate = Date.today().addDays(-90),
            EndDate = Date.today().addDays(-1),
            SBQQ__RenewalQuoted__c = false
        );
        insert testContractTwo;

        List<Contract> cots = new List<Contract>();
        cots.add(testContract);
        cots.add(testContractTwo);

        Test.startTest();
        BatchableSch_AutoRenewContracts b_uc = new BatchableSch_AutoRenewContracts();
        Database.QueryLocator ql = b_uc.start(null);
        b_uc.execute(null, cots);
        b_uc.finish(null);
        Test.stopTest(); 
    }

    /**
    * @description contractQualifiedTest_Schedulable - Tests the schedulable functionality of the BatchableSch_AutoRenewContracts class
    */
    public static testmethod void contractQualifiedTest_Schedulable() {
        // INSTANTIATE THE Schedulable_AcctSupportLevelUpdates CLASS
        BatchableSch_AutoRenewContracts testSch = new BatchableSch_AutoRenewContracts();

        // EXECUTE SCHEDUABLE
        Test.startTest();
        System.schedule('BatchableSch_AutoRenewContracts', '0 0 0 1 1 ? 2025', testSch);
        Test.stopTest();
    }


}