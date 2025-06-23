/**
* @author ECS, ERedding
* @date 20200102
* @version 1.00
* @description CongaGridEventHelperTest - Test class for the CongaGridEventHelper class
*/
@isTest
public with sharing class CongaGridEventHelperTest {

    /**
    * @description testValidEvent - Test Method 1
    */   
    public static testmethod void testValidEvent() {
        Conga_Grid_Event__e event = new Conga_Grid_Event__e(ExportNumber__c = 10000, ExportType__c = 'test', ViewName__c = 'testView');
        
        Test.startTest();

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();
        
        System.assertEquals(true, sr.isSuccess());
    }


}