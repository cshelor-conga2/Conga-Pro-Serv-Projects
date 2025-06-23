/**
* @author Systemyc, GModica, 20190214
* @author ECS, ERedding
* @date 20190701
* @version 1.00
* @description BatchableSch_OppCountOfPrimaryTest - Test class for the BatchableSch_OppCountOfPrimary class
*/
@isTest
public with sharing class BatchableSch_OppCountOfPrimaryTest {

    /**
    * @description setup - 
    */  
    @testSetup
    static void setup(){
        Account a1 = new Account(Name = 'Test Account');
        insert new List<Account> {a1};

        Contact c1 = new Contact(FirstName = 'Test 1', LastName = 'Contact 1', AccountId = a1.Id);
        Contact c2 = new Contact(FirstName = 'Test 2', LastName = 'Contact 2', AccountId = a1.Id);
        insert new List<Contact> {c1, c2};

        Opportunity o1 = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = a1.Id,
            Type = 'Renewal',
            LeadSource = 'Event',
            StageName = 'Qualify',
            CloseDate = Date.today()
        );
        insert new List<Opportunity> {o1};

        List<String> roleValues = getActiveOpportunityContactRoleValues();
        System.assertEquals(false, roleValues.isEmpty());

        List<OpportunityContactRole> oppContactRoles = new List<OpportunityContactRole>();
        oppContactRoles.add(new OpportunityContactRole(ContactId = c1.Id, OpportunityId = o1.Id, Role = roleValues[0]));
        oppContactRoles.add(new OpportunityContactRole(ContactId = c2.Id, OpportunityId = o1.Id, Role = roleValues[0]));
        if(roleValues.size() > 1) {
            oppContactRoles.add(new OpportunityContactRole(ContactId = c1.Id, OpportunityId = o1.Id, Role = roleValues[1]));
            oppContactRoles.add(new OpportunityContactRole(ContactId = c2.Id, OpportunityId = o1.Id, Role = roleValues[1]));
        }
        insert oppContactRoles;
    }

    /**
    * @description testBatch - 
    */  
    static testmethod void testBatch() {
        Test.startTest();
        BatchableSch_OppCountOfPrimary ocp = new BatchableSch_OppCountOfPrimary();
        Id batchId = Database.executeBatch(ocp);
        Test.stopTest();

        List<Opportunity> opportunities = [SELECT CountofPrimaryContact__c FROM Opportunity];
        System.assertEquals(1, opportunities.size());
        System.assertEquals(2, opportunities[0].CountofPrimaryContact__c);
    }

    /**
    * @description testBatchCustomQuery - 
    */  
    static testmethod void testBatchCustomQuery() {
        Test.startTest();
        BatchableSch_OppCountOfPrimary ocp = new BatchableSch_OppCountOfPrimary('SELECT Id FROM Opportunity WHERE IsClosed = false AND Type IN (\'Renewal\',\'Existing Business\')');
        Id batchId = Database.executeBatch(ocp);
        Test.stopTest();

        List<Opportunity> opportunities = [SELECT CountofPrimaryContact__c FROM Opportunity];
        System.assertEquals(1, opportunities.size());
        System.assertEquals(2, opportunities[0].CountofPrimaryContact__c);
    }


    /**
    * @description schedulableTest - 
    */  
    private static testmethod void schedulableTest(){
        // This test runs a scheduled job at midnight Sept. 3rd. next year
        String nextYear = String.valueOf(Date.today().year() + 1);
        String cronExp = '0 0 0 3 9 ? ' + nextYear;
    
        Test.startTest();
        // Schedule the test job        
        String jobId = System.schedule('BatchableSch_OppCountOfPrimarySchTest', cronExp, new BatchableSch_OppCountOfPrimary());
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

    /**
    * @description getActiveOpportunityContactRoleValues - 
    * @return List<String>
    */  
    private static List<String> getActiveOpportunityContactRoleValues() {
        List<String> picklistValues = new List<String>();
        for (Schema.PicklistEntry ple : OpportunityContactRole.Role.getDescribe().getPicklistValues()) {
            if (ple.isActive()) picklistValues.add(ple.getValue());
        }       
        return picklistValues;
    }


}