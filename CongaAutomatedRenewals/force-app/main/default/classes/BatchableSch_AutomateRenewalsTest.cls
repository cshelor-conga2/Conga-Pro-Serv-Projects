/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test class for BatchableSch_AutomateRenewals and BatchableSch_AutomateRenewalsHelper classes.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Juan Díaz   <jcdiaz@systemyc.com>
* @modifiedBy
* @maintainedBy
* @version        1.0
* @created        2019-05-22
* @modified       
* @systemLayer    Tests
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0            jcdiaz@systemyc.com
* 2019-05-22      Initial version.
* v2.0            eredding@getconga.com
* 2019-06-13      Updated version merging AutomateRenewalsBatchTest, AutomateRenewalsSchedTest, 
*                 AutomateRenewalsServiceTest, and AutomateRenewalsTestHelper into one test class
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public with sharing class BatchableSch_AutomateRenewalsTest {

    /**
    * @description setup - Create test data
    * @return void
    */
    @testSetup
    public static void setup(){
        Account testAccount = new Account(Name = 'Test Account 1');
        insert testAccount;

        Contact testContact = new Contact(LastName = 'TestContact');
        insert testContact;

        testAccount.BillingContact__c = testContact.Id;
        update testAccount;

        // CREATE TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.AccountId = testAccount.Id;
        testContract.Status = 'Draft';
        testContract.StartDate = Date.today().addDays(45);
        testContract.ContractTerm = 12;
        insert testContract;

        // TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = new List<Opportunity>();
        testOpportunities.add(new Opportunity(
            Name = 'Test Opportunity 100 days', 
            AccountId = testAccount.Id, 
            StageName = 'Qualify', 
            Type = 'Renewal', 
            ForecastCategoryName = 'Best Case', 
            CloseDate = Date.today(),
            LeadSource = 'Advertisement',
            Automate_Renewal__c = true, 
            MRR_Sub_Start__c = Date.today().addDays(100)));
        testOpportunities.add(new Opportunity(
            Name = 'Test Opportunity 75 days', 
            AccountId = testAccount.Id, 
            StageName = 'Qualify', 
            Type = 'Renewal', 
            ForecastCategoryName = 'Best Case', 
            CloseDate = Date.today(),
            LeadSource = 'Advertisement',
            Automate_Renewal__c = true, 
            MRR_Sub_Start__c = Date.today().addDays(75)));
        testOpportunities.add(new Opportunity(
            Name = 'Test Opportunity 60 days', 
            AccountId = testAccount.Id, 
            StageName = 'Qualify', 
            Type = 'Renewal', 
            ForecastCategoryName = 'Best Case', 
            CloseDate = Date.today(),
            LeadSource = 'Advertisement',
            Automate_Renewal__c = true,
            MRR_Sub_Start__c = Date.today().addDays(60)));
        testOpportunities.add(new Opportunity(
            Name = 'Test Opportunity 45 days', 
            AccountId = testAccount.Id, 
            StageName = 'Qualify', 
            Type = 'Renewal', 
            ForecastCategoryName = 'Best Case', 
            CloseDate = Date.today(),
            LeadSource = 'Advertisement',
            Automate_Renewal__c = true,
            Customer_Org_Id__c = '00D123456789ABC',
            SBQQ__RenewedContract__c = testContract.Id,
            MRR_Sub_Start__c = Date.today().addDays(45)));
        insert testOpportunities;

        // GET QUOTE APPROVED RECORD TYPE ID
        Id quoteApprovedRT = UtilityClass.getRecordTypesForObject('SBQQ__Quote__c').get('Approved');

        // TEST QUOTES
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c testQuoteForSeventyFiveDaysQuote = new SBQQ__Quote__c(SBQQ__Type__c = 'Quote 75', SBQQ__Opportunity2__c = testOpportunities[1].Id, RecordTypeId = quoteApprovedRT);        
        testQuotes.add(testQuoteForSeventyFiveDaysQuote);

        SBQQ__Quote__c testQuoteForSixtyDaysOpp = new SBQQ__Quote__c(SBQQ__Type__c = 'Quote 60', SBQQ__Opportunity2__c = testOpportunities[2].Id, RecordTypeId = quoteApprovedRT);
        testQuotes.add(testQuoteForSixtyDaysOpp);

        SBQQ__Quote__c testQuoteForFortyFiveDaysOpp = new SBQQ__Quote__c(SBQQ__Type__c = 'Quote 45', SBQQ__Opportunity2__c = testOpportunities[3].Id, RecordTypeId = quoteApprovedRT);
        testQuotes.add(testQuoteForFortyFiveDaysOpp);   
        insert testQuotes;  

        // UPDATE OPPS
        testOpportunities[1].SBQQ__PrimaryQuote__c = testQuoteForSeventyFiveDaysQuote.Id;
        testOpportunities[2].SBQQ__PrimaryQuote__c = testQuoteForSixtyDaysOpp.Id;
        testOpportunities[3].SBQQ__PrimaryQuote__c = testQuoteForFortyFiveDaysOpp.Id;
        update testOpportunities;
    }


    /**
    * @description processAutoNoticeRenewalOppsTest - Test processAutoNoticeRenewalOpps method
    * @return void
    */
    public static testmethod void processAutoNoticeRenewalOppsTest() {
        // get test opportunities
        List<Opportunity> testOpportunities = [SELECT Id, Name, SBQQ__PrimaryQuote__c, Days_Before_MRR_Sub_Start__c FROM Opportunity];
        System.assertEquals(4, testOpportunities.size());

        // get object Ids for assertions
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();

        for(Opportunity opp : testOpportunities) {
            if(opp.SBQQ__PrimaryQuote__c == null && opp.Days_Before_MRR_Sub_Start__c == 100) {
                opportunityIds.add(opp.Id);
            }
            else{
                quoteIds.add(opp.SBQQ__PrimaryQuote__c);
            }
        }

        // execute test
        Test.startTest();

        Database.executeBatch(new BatchableSch_AutomateRenewals(), 5);
        
        Test.stopTest();

        // assertions
        List<Opportunity> processedOpportunities = [SELECT Id, Name, Automatic_Renewal_Notice__c FROM Opportunity WHERE Id IN :opportunityIds];
        System.assertEquals(1, processedOpportunities.size());
        System.assertEquals('Triggered', processedOpportunities[0].Automatic_Renewal_Notice__c);

        List<SBQQ__Quote__c> processedQuotes = [SELECT Id, Name, Automatic_Renewal_Notice__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds];
        System.assertEquals(3, processedQuotes.size());
        System.assertEquals('Triggered', processedQuotes[0].Automatic_Renewal_Notice__c);
    }

    /**
    * @description processAutoCloseRenewalOppsTest - Test processAutoCloseRenewalOpps method
    * @return void
    */
    public static testmethod void processAutoCloseRenewalOppsTest() {
        // GET TEST OPP
        List<Opportunity> testOpportunities = [SELECT Id FROM Opportunity WHERE Days_Before_MRR_Sub_Start__c = 45];
        System.assert(testOpportunities.size() == 1);

        Test.startTest();

        Database.executeBatch(new BatchableSch_AutomateRenewals(), 5);
        
        Test.stopTest();

        // REFRESH OPPS AND CHECK FOR CORRECT DATA
        testOpportunities = [SELECT Id, Name, StageName, CloseDate FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].StageName == 'Closed Won');
        System.assert(testOpportunities[0].CloseDate == Date.today());  
    }

    /**
    * @description schedulableTest - Test schedulable class
    * @return void
    */
    public static testmethod void schedulableTest() {
        // This test runs a scheduled job at midnight Sept. 3rd. next year
        String nextYear = String.valueOf(Date.today().year() + 1);
        String cronExp = '0 0 0 3 9 ? ' + nextYear;
    
        Test.startTest();
        
        // Schedule the test job
        String jobId = System.schedule('AutomateRenewalsSchedTest', cronExp, new BatchableSch_AutomateRenewals());
        
        Test.stopTest();
        
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId]; 

        // Verify the expressions are the same 
        System.assertEquals(cronExp, ct.CronExpression);
        
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run 
        String expectedValue = nextYear + '-09-03 00:00:00';
        System.assertEquals(expectedValue, String.valueOf(ct.NextFireTime));
    }


}