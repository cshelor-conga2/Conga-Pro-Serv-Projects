/**
* @author Conga Services, KSears
* @date 20181220
* @version 1.00
* @description CIG_Prod_Rollup_Test  - Test class for the CIG_Prod_Rollup class
*/
@isTest
public with sharing class CIG_Prod_Rollup_Test {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        //Create Salesforce Orgs
        List<Salesforce_Org__c> testOrgs = TestingUtility.createSObjectList('Salesforce_Org__c', true, 1);
        insert testOrgs;
        //Create Assets
        List<Asset> testAssets = TestingUtility.createSObjectList('Asset', true, 2);
        testAssets[0].Salesforce_Org__c = testOrgs[0].Id;
        testAssets[0].Name = 'Conga Invoice Generation for Salesforce Billing';
        testAssets[0].Quantity = 5;
        testAssets[0].Start_Date__c = Date.Today().addDays(-5);
        testAssets[0].End_Date__c = Date.Today().addDays(5);
        testAssets[1].Salesforce_Org__c = testOrgs[0].Id;
        testAssets[1].Name = 'Service Events for Conga Invoice Generation for Salesforce Billing';
        testAssets[1].Quantity = 50;
        testAssets[1].Start_Date__c = Date.Today().addDays(-5);
        testAssets[1].End_Date__c = Date.Today().addDays(5);
        insert testAssets;
        //Create Usage History 2's
        List<Conga_Usage_History2__c> testUsages = TestingUtility.createSObjectList('Conga_Usage_History2__c', true, 2);
        testUsages[0].Salesforce_Org__c = testOrgs[0].Id;
        testUsages[0].Type__c = 'CSFB';
        testUsages[0].Month__c = Date.Today();
        testUsages[0].Total_Composer_Successes__c = 15;
        testUsages[1].Salesforce_Org__c = testOrgs[0].Id;
        testUsages[1].Type__c = 'CSFB';
        testUsages[1].Month__c = Date.Today();
        testUsages[1].Total_Composer_Successes__c = 15;
        insert testUsages;
    }   
    
    /**
    * @description testMethod1 - Test batch sched class
    */
    public static testMethod void testMethod1() {

        //Create Salesforce Orgs
        List<Salesforce_Org__c> testOrgs = TestingUtility.createSObjectList('Salesforce_Org__c', true, 2);
        testOrgs[0].Asset_Start_Date__c = Date.Today().addDays(-5);
        testOrgs[0].Asset_End_Date__c = Date.Today().addDays(5);
        testOrgs[1].Asset_Start_Date__c = Date.Today().addDays(-55);
        testOrgs[1].Asset_End_Date__c = Date.Today().addDays(-45);
        insert testOrgs;
        //Create Assets
        List<Asset> testAssets = TestingUtility.createSObjectList('Asset', true, 2);
        testAssets[0].Salesforce_Org__c = testOrgs[0].Id;
        testAssets[0].Name = 'Test1';
        testAssets[0].Quantity = 5;
        testAssets[1].Salesforce_Org__c = testOrgs[1].Id;
        testAssets[1].Name = 'Test2';
        testAssets[1].Quantity = 50;
        insert testAssets;
        //Create Usage History 2's
        List<Conga_Usage_History2__c> testUsages = TestingUtility.createSObjectList('Conga_Usage_History2__c', true, 2);
        testUsages[0].Salesforce_Org__c = testOrgs[0].Id;
        testUsages[0].Type__c = 'CSFB';
        testUsages[0].Month__c = Date.Today();
        testUsages[0].Total_Composer_Successes__c = 15;
        testUsages[1].Salesforce_Org__c = testOrgs[1].Id;
        testUsages[1].Type__c = 'CSFB';
        testUsages[1].Month__c = Date.Today().addDays(-50);
        testUsages[1].Total_Composer_Successes__c = 15;
        insert testUsages;      
        Test.StartTest();
        

            Batchable_CIG_Prod_Rollup sh1 = new Batchable_CIG_Prod_Rollup();
            String sch = '0 0 23 * * ?'; 
            System.schedule('Test Sched', sch, sh1); 

            //update for dates:
            //CIG_Prod_Rollup.RollupUseage((List<Salesforce_Org__c>)[SELECT Id, Account__c, Allowed_Usage__c, Asset_Start_Date__c, Asset_End_Date__c, Monthly_Total_Success__c, Total_Success__c FROM Salesforce_Org__c]);

        Test.stopTest();
    }


}