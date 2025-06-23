/**
* @author ECS, ERedding
* @date 20190717
* @version 1.00
* @description BatchableSch_CampaignReportingTest  - Test class for the BatchableSch_CampaignReporting class
*/
@isTest
public with sharing class BatchableSch_CampaignReportingTest {

// Richa

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        insert testAccounts;

        // TEST PRODUCT
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 1);    
        testProducts[0].Name = 'Rev Schedule Prod';
        testProducts[0].ProductCode = 'RSP1';   
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[0].Family = 'ActionGrid';
        testProducts[0].Product_Line__c = 'Conga Grid';
        insert testProducts;

        // TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPBEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', false, 1);
        testPBEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPBEntries[0].Product2Id = testProducts[0].Id;
        testPBEntries[0].IsActive = TRUE;
        testPBEntries[0].UnitPrice = 200.00;
        insert testPBEntries;

/*
        // CREATE TEST GRAND PARENT CAMPAIGN
        Campaign grandParentCampaign = new Campaign(Name = 'Grand Parent Campaign 1', IsActive = TRUE, Product_Interest__c = 'Conga ActionGrid');
        insert grandParentCampaign;

        // CREATE TEST CAMPAIGNS
        Campaign parentCampaign = new Campaign(Name = 'Parent Campaign 1', IsActive = TRUE, ParentId = grandParentCampaign.Id, Product_Interest__c = 'Conga ActionGrid');
        insert parentCampaign;


        Campaign standAlone = new Campaign(Name = 'Standalone Campaign 1', IsActive = TRUE, Product_Interest__c = 'Conga Composer');
        Campaign childCampaign = new Campaign(Name = 'Child Campaign 1', IsActive = TRUE, Product_Interest__c = 'Conga ActionGrid', ParentId = parentCampaign.Id);
        insert new List<Campaign>{ standAlone, childCampaign };


        // CREATE TEST LEADS
        List<Lead> testLeads = (List<Lead>)TestingUtility.createSObjectList('Lead', false, 5);
        for(Integer i = 0; i < testLeads.size(); i++){
            testLeads[i].LastName = i + 'TestLead' + i;
            testLeads[i].Company = i + 'TestCompany' + i;
            testLeads[i].CreatedDate = Date.today().addDays(-(i + 5));
            testLeads[i].Country = 'United States';
        }
        insert testLeads;

        // CREATE TEST MEMBERS
        List<CampaignMember> testMembers = (List<CampaignMember>)TestingUtility.createSObjectList('CampaignMember', false, 5);
        for(Integer i = 0; i < testMembers.size(); i++){
            testMembers[i].LeadId = testLeads[i].Id;
            testMembers[i].CreatedDate = testLeads[i].CreatedDate;
        }
        testMembers[0].CampaignId = parentCampaign.Id;
        testMembers[1].CampaignId = standAlone.Id;
        testMembers[2].CampaignId = standAlone.Id;
        testMembers[3].CampaignId = childCampaign.Id;
        testMembers[4].CampaignId = childCampaign.Id;
        insert testMembers;
 

        // CREATE TEST OPPS
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 3);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].CreatedDate = Date.today().addDays(-10);
        testOpportunities[0].CampaignId = parentCampaign.Id;
        testOpportunities[1].AccountId = testAccounts[0].Id;
        testOpportunities[1].CreatedDate = Date.today().addDays(-10);
        testOpportunities[1].CampaignId = standAlone.Id;
        testOpportunities[2].AccountId = testAccounts[0].Id;
        testOpportunities[2].CreatedDate = Date.today().addDays(-10);
        testOpportunities[2].CampaignId = childCampaign.Id;
        insert testOpportunities;

        // CREATE TEST OPP ITEMS
        List<OpportunityLineItem> testOppItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', false, 3);
        testOppItems[0].OpportunityId = testOpportunities[0].Id;
        testOppItems[0].Quantity = 250;
        testOppItems[0].UnitPrice = 75;
        testOppItems[0].PricebookEntryId = testPBEntries[0].Id;
        testOppItems[0].ServiceDate = Date.today();
        testOppItems[0].Product_End_Date__c = Date.today().addDays(365);

        testOppItems[1].OpportunityId = testOpportunities[1].Id;
        testOppItems[1].Quantity = 45;
        testOppItems[1].UnitPrice = 1500;
        testOppItems[1].PricebookEntryId = testPBEntries[0].Id;
        testOppItems[1].ServiceDate = Date.today();
        testOppItems[1].Product_End_Date__c = Date.today().addDays(365);

        testOppItems[2].OpportunityId = testOpportunities[2].Id;
        testOppItems[2].Quantity = 350;
        testOppItems[2].UnitPrice = 35;
        testOppItems[2].PricebookEntryId = testPBEntries[0].Id;
        testOppItems[2].ServiceDate = Date.today();
        testOppItems[2].Product_End_Date__c = Date.today().addDays(365);
        insert testOppItems;
        */
    }
    
    /**
    * @description batchableTest - Test the batchable portion of BatchableSch_CampaignReporting
    */
    /*public static testMethod void batchableTest() {
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(!testAccounts.isEmpty());

        // GET TEST OPP
        List<Opportunity> testOpportunities = [SELECT Id, CreatedDate, CloseDate, Total_MRR_UpsellFx__c, Future_Ave_MRR_TotalFx__c FROM Opportunity];
        System.assert(!testOpportunities.isEmpty());

        // GET TEST LEADS
        List<Lead> testLeads = [SELECT Id, CreatedDate FROM Lead];
        System.assert(!testLeads.isEmpty());

        // CLOSE OPP
        testOpportunities[0].StageName = 'Closed Won';
        testOpportunities[0].CloseDate = testOpportunities[0].CreatedDate.date().addDays(30);
        update testOpportunities; 

        Test.startTest();

        // CONVERT LEADS
        for(Integer i = 0; i < testLeads.size(); i++){
            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(testLeads[i].Id);
            lc.setAccountId(testAccounts[0].Id);
            lc.setOpportunityId(testOpportunities[0].Id);
            lc.setConvertedStatus('Converted');
            Database.LeadConvertResult lcr = Database.convertLead(lc);
        }

        // EXECUTE BATCH CLASS
        BatchableSch_CampaignReporting batchClass = new BatchableSch_CampaignReporting();
        Database.executeBatch(batchClass, 5);

        Test.stopTest();

        // GET TEST CAMPAIGNS AND TEST FOR CORRECT DATA
        List<Campaign> testCampaigns = [SELECT Id, Name, Average_Days_to_Opportunity__c, Average_Days_to_Close__c, Future_Avg_MRR_in_Campaign__c, Future_Avg_MRR_in_Hierarchy__c, 
                                               Total_Won_MRR_in_Campaign__c, Total_Won_MRR_in_Hierarchy__c
                                        FROM Campaign];
        System.assert(!testCampaigns.isEmpty());

        // GRAND PARENT CAMPAIGN
        System.assert(testCampaigns[0].Average_Days_to_Opportunity__c == 7.75);
        System.assert(testCampaigns[0].Average_Days_to_Close__c == 26.75);
        System.assert(testCampaigns[0].Future_Avg_MRR_in_Campaign__c == 0.00);
        System.assert(testCampaigns[0].Future_Avg_MRR_in_Hierarchy__c == 2576.27);
        System.assert(testCampaigns[0].Total_Won_MRR_in_Campaign__c == 0.00);
        System.assert(testCampaigns[0].Total_Won_MRR_in_Hierarchy__c == 1558.23);
        // PARENT CAMPAIGN
        System.assert(testCampaigns[1].Average_Days_to_Opportunity__c == 7.75);
        System.assert(testCampaigns[1].Average_Days_to_Close__c == 26.75);
        System.assert(testCampaigns[1].Future_Avg_MRR_in_Campaign__c == 1558.23);
        System.assert(testCampaigns[1].Future_Avg_MRR_in_Hierarchy__c == 2576.27);
        System.assert(testCampaigns[1].Total_Won_MRR_in_Campaign__c == 1558.23);
        System.assert(testCampaigns[1].Total_Won_MRR_in_Hierarchy__c == 1558.23);
        // CHILD CAMPAIGN
        System.assert(testCampaigns[3].Average_Days_to_Opportunity__c == 9.5);
        System.assert(testCampaigns[3].Average_Days_to_Close__c == 28.5);
        System.assert(testCampaigns[3].Future_Avg_MRR_in_Campaign__c == 1018.04);
        System.assert(testCampaigns[3].Future_Avg_MRR_in_Hierarchy__c == 1018.04);
        System.assert(testCampaigns[3].Total_Won_MRR_in_Campaign__c == 0.00);
        System.assert(testCampaigns[3].Total_Won_MRR_in_Hierarchy__c == 0.00);
        // STANDALONE CAMPAIGN  
        System.assert(testCampaigns[2].Average_Days_to_Opportunity__c == 7.5);
        System.assert(testCampaigns[2].Average_Days_to_Close__c == 26.50);
        System.assert(testCampaigns[2].Future_Avg_MRR_in_Campaign__c == 5609.63);
        System.assert(testCampaigns[2].Future_Avg_MRR_in_Hierarchy__c == 5609.63);
        System.assert(testCampaigns[2].Total_Won_MRR_in_Campaign__c == 0.00);
        System.assert(testCampaigns[2].Total_Won_MRR_in_Hierarchy__c == 0.00);
    } */

    /**
    * @description schedulableTest - Test the schedulable portion of BatchableSch_CampaignReporting
    */
   /* public static testMethod void schedulableTest() {
        Test.startTest();

        // TEST SCHEDULE BATCH CLASS FOR CODE COVERAGE
        BatchableSch_CampaignReporting batchClass = new BatchableSch_CampaignReporting();
        System.schedule('TestCampaignReportingSchedule', '0 0 0 1 1 ? 2025', batchClass);

        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType IN ('ScheduledApex') AND ApexClass.Name = 'BatchableSch_CampaignReporting'];
        System.assert(!jobs.isEmpty());
    }*/
}