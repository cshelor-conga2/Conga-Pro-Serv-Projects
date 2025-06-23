/**
* @author ECS, ERedding
* @author Systemyc, GModica
* @date 20190513
* @version 1.00
* @description BatchableSch_LeadDeletionTest  - Test class for the BatchableSch_LeadDeletion class
*/
@isTest
public with sharing class BatchableSch_LeadDeletionTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    static void setup() {
        Lead l1 = new Lead(LastName = 'Lead 1', Company = 'Conga', Status = 'Invalid'); // in prod, this status is converted to "Disqualified" so do not check for this on the test as it will fail
        Lead l2 = new Lead(LastName = 'Lead 1', Company = 'Supreme Tech', Status = 'Prospect');
        Lead l3 = new Lead(LastName = 'Lead 3', Company = 'Microsoft', Status = 'Prospect');        
        insert new Lead[] { l1, l2, l3 };
    }
    
    /**
    * @description testBatchExecution - Test batachable portion of Batchable/Schedulable class
    */
    public static testmethod void testBatchExecution() {
        System.assertEquals(3, [SELECT count() FROM Lead]);

        Test.startTest();

        BatchableSch_LeadDeletion b = new BatchableSch_LeadDeletion();
        Database.executebatch(b);

        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Lead WHERE Company = 'Supreme Tech']);
        System.assertEquals(0, [SELECT count() FROM Lead WHERE Status = 'Invalid']);
    }
    
    
    /**
    * @description testScheduleExecution - Test schedulable portion of Batchable/Schedulable class
    */ 
    public static testmethod void testScheduleExecution() {
        Test.startTest();

        String CRON_EXP = '0 0 0 1 1 ? 2025';  
        String jobId = System.schedule('testScheduledApex', CRON_EXP, new BatchableSch_LeadDeletion());

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        Test.stopTest();

        System.assertEquals(CRON_EXP, ct.CronExpression); 
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2025-01-01 00:00:00', String.valueOf(ct.NextFireTime));                        
    }


}