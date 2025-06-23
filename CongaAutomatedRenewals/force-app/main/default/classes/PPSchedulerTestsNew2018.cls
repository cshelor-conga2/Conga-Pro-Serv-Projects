/**
* @author Jereriah Manning
* @date 201800215
* @version 1.00
* @description PPSchedulerTestsNew2018 - Created for Conga Partner Team
*/
@isTest
private class PPSchedulerTestsNew2018{

    /**
    * @description testPPScheduleClasses - 
    */  
    static testMethod void testPPScheduleClasses(){        
        Test.startTest();
        
        // Schedule the test REVENUE job
        String jobIdRevnue = System.schedule('testRevnueScheduler', PPRevUpdateScheduler.CRON_EXP, new PPRevUpdateScheduler());
        PPRevUpdateScheduler.scheduleIt();
        
        // Schedule the test COUNT job
        String jobIdCount = System.schedule('testCountScheduler', PPCountUpdateScheduler.CRON_EXP2, new PPCountUpdateScheduler());
        PPCountUpdateScheduler.scheduleIt();        

        // Schedule the test OTHER job
        String jobIdOther = System.schedule('testOtherScheduler', PPOtherUpdateScheduler.CRON_EXP3, new PPOtherUpdateScheduler());      
        PPOtherUpdateScheduler.scheduleIt();  
            
        // Schedule the test PRODUCT MIX job
        String jobIdOProductMix = System.schedule('testProductMixScheduler', PPProductMixDataScheduler.CRON_EXP4, new PPProductMixDataScheduler());      
        PPProductMixDataScheduler.scheduleIt();  
        
        // Schedule the test CASE job
        String jobIdCaseData = System.schedule('testCasecheduler', PPCaseUpdaterScheduler.CRON_EXP5, new PPCaseUpdaterScheduler());      
        PPCaseUpdaterScheduler.scheduleIt();             
            
        Test.stopTest();
    }

}