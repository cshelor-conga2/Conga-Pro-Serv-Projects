/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IntacctMilestoneSyncBatch - Test class for the IntacctMilestoneSyncBatch class
*/
@isTest
private class IntacctMilestoneSyncBatchTest {

    /**
    * @description setup - 
    */
    @testSetup
    private static void setup() {
        PS_Project__c project = IntacctIntegrationServiceTest.insertTestProject();
        Milestone__c milestone = IntacctIntegrationServiceTest.insertTestMilestone(project.Id);
    }

    /**
    * @description testBatch - 
    * @return void
    */
    private static testmethod void testBatch() {
        Test.startTest();

        DataBase.executeBatch(new IntacctMilestoneSyncBatch());

        Test.stopTest();
    }


}