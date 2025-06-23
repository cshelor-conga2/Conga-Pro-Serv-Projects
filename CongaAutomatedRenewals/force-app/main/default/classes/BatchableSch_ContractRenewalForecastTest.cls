/**
* @author ECS, ERedding
* @date 20200107
* @version 1.00
* @description BatchableSch_ContractRenewalForecastTest  - Test class for the [Name of class being tested] class
*/
@isTest
public with sharing class BatchableSch_ContractRenewalForecastTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account', false);
        insert testAccount;

        // TEST OPP
        List<Opportunity> testOpportunities = TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].AccountId = testAccount.Id;
        testOpportunities[0].Type = 'New Business';
        testOpportunities[0].Purchase_Order_Required__c = true;
        testOpportunities[1].AccountId = testAccount.Id;
        testOpportunities[1].Type = 'Renewal';
        insert testOpportunities;
    }
    
    /**
    * @description testContractForecastBatchable_NoParams - Test method for the BatchableSch_ContractRenewalForecast class using the constructor without params
    */
    private static testmethod void testContractForecastBatchable_NoParams(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        System.assert(testAccounts.size() == 1);

        // GET TEST OPPS
        List<Opportunity> testOpportunities = [SELECT Id, RecordTypeId, Customer_Org_Id__c FROM Opportunity];
        System.assert(!testOpportunities.isEmpty());

          // TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', false, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.today().addDays(30);
        testQuotes[0].SBQQ__EndDate__c = Date.today().addMonths(12);
        testQuotes[0].SBQQ__Opportunity2__c = testOpportunities[0].Id;
        insert testQuotes;

        // TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.AccountId = testAccounts[0].Id;
        testContract.StartDate = Date.today().addDays(30);
        testContract.ContractTerm = 12;
        testContract.Contract_Type__c = 'Master Subscription';
        testContract.SBQQ__Quote__c = testQuotes[0].Id;
        testContract.SBQQ__Opportunity__c = testOpportunities[0].Id;
        testContract.RecordTypeId = UtilityClass.getRecordTypesForObject('Contract').get('Customer_Subscription');
        testContract.SBQQ__RenewalForecast__c = false;
        insert testContract;

        Test.startTest();

        Database.executeBatch(new BatchableSch_ContractRenewalForecast(), 1);

        Test.stopTest();

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContract = [SELECT Id, Name, SBQQ__RenewalForecast__c FROM Contract WHERE Id = :testContract.Id];
        System.assert(testContract.SBQQ__RenewalForecast__c == true);
    }
    
    
    /**
    * @description testContractForecastBatchable_WithParams - Test method for the BatchableSch_ContractRenewalForecast class using the constructor with params
    */
    private static testmethod void testContractForecastBatchable_WithParams(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        System.assert(testAccounts.size() == 1);

        // GET TEST OPPS
        List<Opportunity> testOpportunities = [SELECT Id, RecordTypeId, Customer_Org_Id__c FROM Opportunity];
        System.assert(!testOpportunities.isEmpty());

          // TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', false, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.today().addDays(30);
        testQuotes[0].SBQQ__EndDate__c = Date.today().addMonths(12);
        testQuotes[0].SBQQ__Opportunity2__c = testOpportunities[0].Id;
        insert testQuotes;

        // TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.AccountId = testAccounts[0].Id;
        testContract.StartDate = Date.today().addDays(30);
        testContract.ContractTerm = 12;
        testContract.Contract_Type__c = 'Master Subscription';
        testContract.SBQQ__Quote__c = testQuotes[0].Id;
        testContract.SBQQ__Opportunity__c = testOpportunities[0].Id;
        testContract.RecordTypeId = UtilityClass.getRecordTypesForObject('Contract').get('Customer_Subscription');
        testContract.SBQQ__RenewalForecast__c = false;
        insert testContract;

        Test.startTest();

        Database.executeBatch(new BatchableSch_ContractRenewalForecast(new Set<Id>{ testContract.Id }), 1);

        Test.stopTest();

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContract = [SELECT Id, Name, SBQQ__RenewalForecast__c FROM Contract WHERE Id = :testContract.Id];
        System.assert(testContract.SBQQ__RenewalForecast__c == true);
    }

    /**
    * @description executeSchedulableTest - 
    */
    public static testMethod void executeSchedulableTest(){
        Test.startTest();

        BatchableSch_ContractRenewalForecast testSch = new BatchableSch_ContractRenewalForecast();
        System.schedule('BatchableSch_ContractRenewalForecast', '0 0 0 1 1 ? 2025', testSch);

        Test.stopTest();
    }


}