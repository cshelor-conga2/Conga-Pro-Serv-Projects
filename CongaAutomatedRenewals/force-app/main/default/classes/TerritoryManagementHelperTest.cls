/**
* @author ECS, ERedding
* @date 20190408
* @version 1.00
* @description TerritoryManagementHelperTest - Test class for the TerritoryManagementHelper class
*/
@isTest
public with sharing class TerritoryManagementHelperTest {

    /**
    * @description test1 - 
    */
    public static testMethod void test1(){
        Test.startTest();

        System.assert(String.isNotBlank(TerritoryManagementHelper.PROSPECTTYPE));
        System.assert(String.isNotBlank(TerritoryManagementHelper.CUSTOMERTYPE));
        System.assert(String.isNotBlank(TerritoryManagementHelper.CUSTOMERPASTDUETYPE));
        System.assert(String.isNotBlank(TerritoryManagementHelper.CUSTOMERFORMERTYPE));

        System.assert(String.isNotBlank(TerritoryManagementHelper.TMROLENAME));
        System.assert(String.isNotBlank(TerritoryManagementHelper.CLMROLENAME));
        System.assert(String.isNotBlank(TerritoryManagementHelper.CSMROLENAME));
        System.assert(String.isNotBlank(TerritoryManagementHelper.RMROLENAME));
        System.assert(String.isNotBlank(TerritoryManagementHelper.BDRROLENAME));
        System.assert(String.isNotBlank(TerritoryManagementHelper.SDRROLENAME));
        System.assert(String.isNotBlank(TerritoryManagementHelper.SEROLENAME));

        TerritoryManagementHelper.MadeThroughManagementPage = false;
        System.assert(TerritoryManagementHelper.MadeThroughManagementPage == false);

        Map<Id, TM_Territory_Segment_Users__c> testTerrSegmentUserMap = TerritoryManagementHelper.QualifyingTSUs;
        System.assert(testTerrSegmentUserMap != null);

        Map<Id, TM_Territory_Division_Users__c> testTerrDivisionUserMap = TerritoryManagementHelper.QualifyingTDUs;
        System.assert(testTerrDivisionUserMap != null);

        Map<String, List<String>> testRecordInfoMap = TerritoryManagementHelper.RecordUpdateInfo;
        System.assert(testRecordInfoMap != null);
        System.assert(testRecordInfoMap.containsKey('Segment'));
        System.assert(testRecordInfoMap.containsKey('Division'));

        Test.stopTest();
    }


}