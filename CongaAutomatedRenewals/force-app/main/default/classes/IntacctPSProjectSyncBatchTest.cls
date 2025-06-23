/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IntacctPSProjectSyncBatch - Test class for the IntacctPSProjectSyncBatch class
*/
@isTest
private class IntacctPSProjectSyncBatchTest {
    
    /**
    * @description setup
    */
    @testSetup
    private static void setup() {
        PS_Project__c project = IntacctIntegrationServiceTest.insertTestProject();
    }

    /**
    * @description testBatch
    * @return void
    */
    private static testmethod void testBatch() {        
        Test.startTest();

        DataBase.executeBatch(new IntacctPSProjectSyncBatch());

        Test.stopTest();
    }


}