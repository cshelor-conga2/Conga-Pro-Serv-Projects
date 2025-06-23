/**
* @author Conga Services
* @date 20190212
* @version 1.00
* @description UpdateOppFromLicenseBatchTest  - Test class for the UpdateOppFromLicenseBatch class
*/
@isTest
public with sharing class UpdateOppFromLicenseBatchTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        Id rAcctTypeId;
        for(RecordType rt : [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE IsActive = true AND SobjectType IN ('Account','Case')]){
            if(rt.SobjectType == 'Account' && rt.DeveloperName == 'Business_Account' && rAcctTypeId == null){
                rAcctTypeId = rt.Id;
            }
        }

        SfLma__Package__c pack = new SfLma__Package__c();
        pack.Name = 'test';
        insert pack;

        sfLma__License__c license = new sfLma__License__c();
        license.CreatedDate = Date.Today(); 
        license.SfLma__Package__c = pack.Id;
        license.SfLma__Subscriber_Org_ID__c = '0x0000000000000001';
        insert license;

        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].RecordTypeId = rAcctTypeId;
        testAccounts[0].mrr_Active_MRR__c = 100.00;
        insert testAccounts;

        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 1);
        testContacts[0].AccountId = testAccounts[0].Id;
        insert testContacts;

        Opportunity opp = new Opportunity();
        opp.Name = 'Onboarding Opp';
        opp.AccountId = testAccounts[0].Id;
        opp.Type = 'New Business';
        opp.LeadSource = 'Inbound';
        opp.StageName = 'Qualify';
        opp.StageName = 'Closed Won';
        opp.CloseDate = System.today();
        opp.Customer_Org_Id__c  = '0x0000000000000001';
        opp.Sales_Ops_Approved__c = true;
        opp.Sales_Ops_Status__c = 'Synced with Intacct';
        opp.Customer_Implementation_Type__c = 'Conga PS';
        opp.Primary_Contact__c = testContacts[0].Id;
        opp.CountofPrimaryContact__c = 1;
        insert opp;
    }
    
    
    /**
    * @description testMethod1 - Test Happy Path of code
    */
    public static testMethod void testMethod1() {
        Test.startTest();

        UpdateOppFromLicenseBatch sh1 = new UpdateOppFromLicenseBatch();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Sched', sch, sh1);

        Test.stopTest();
    }


}