/**
* @author GTM, ERedding
* @date 20201005
* @version 1.00
* @description Batchable_AppAnalyticsQueryReqDMLTest  - Test class for the Batchable_AppAnalyticsQueryRequestsDML class
*/
@isTest
public class Batchable_AppAnalyticsQueryReqDMLTest  {

    // CREATE FAKE AppAnalyticsQueryRequest RECORDS
    public static List<AppAnalyticsQueryRequest> FakeRequests {
    get {
        Map<String, Object> fakeFieldValues1 = new Map<String, Object>{
            'Id' => '',
            'DataType' => 'PackageUsageSummary',
            'RequestState' => 'Pending',
            'OrganizationIds' => '00D3h00000ABCDE'
        };
        AppAnalyticsQueryRequest fakeRequest1 = (AppAnalyticsQueryRequest)TestingUtility.createTestMeta('AppAnalyticsQueryRequest', fakeFieldValues1);
        //
        Map<String, Object> fakeFieldValues2 = new Map<String, Object>{
            'Id' => '',
            'DataType' => 'PackageUsageSummary',
            'RequestState' => 'Pending',
            'OrganizationIds' => '00D3h00000ABCDE'
        };
        AppAnalyticsQueryRequest fakeRequest2 = (AppAnalyticsQueryRequest)TestingUtility.createTestMeta('AppAnalyticsQueryRequest', fakeFieldValues2);
        //
        Map<String, Object> fakeFieldValues3 = new Map<String, Object>{
            'Id' => '',
            'DataType' => 'PackageUsageSummary',
            'RequestState' => 'Pending',
            'OrganizationIds' => '00D3h00000ABCDE'
        };
        AppAnalyticsQueryRequest fakeRequest3 = (AppAnalyticsQueryRequest)TestingUtility.createTestMeta('AppAnalyticsQueryRequest', fakeFieldValues3);
        return new List<AppAnalyticsQueryRequest>{ fakeRequest1, fakeRequest2, fakeRequest3 };
    } set; }

    /**
    * @description batchableTest - Test Happy Path of code
    */
    public static testMethod void batchableTest() {
        List<AppAnalyticsQueryRequest> fakeRequests = FakeRequests;
        System.assert(fakeRequests != null);
        System.assert(fakeRequests.size() == 3);

        Test.startTest();
    
        Batchable_AppAnalyticsQueryRequestsDML batchProcess = new Batchable_AppAnalyticsQueryRequestsDML(fakeRequests);
        Database.executeBatch(batchProcess);

        Test.stopTest();

        /////////// FURTHER TESTING NOT POSSIBLE SINCE AppAnalyticsQueryRequest RECORDS CANNOT BE CREATED IN A NON-LMO ORG. TESTS ARE ONLY FOR CODE COVERAGE /////////
    }
    
    /**
    * @description batchableTest_BadParams - Test bad param handling
    */
    public static testMethod void batchableTest_BadParams() {
        Test.startTest();
    
        Batchable_AppAnalyticsQueryRequestsDML batchProcess1 = new Batchable_AppAnalyticsQueryRequestsDML(new List<AppAnalyticsQueryRequest>());
        Database.executeBatch(batchProcess1);

        Batchable_AppAnalyticsQueryRequestsDML batchProcess2 = new Batchable_AppAnalyticsQueryRequestsDML(null);
        Database.executeBatch(batchProcess2);

        Test.stopTest();

        /////////// FURTHER TESTING NOT POSSIBLE SINCE AppAnalyticsQueryRequest RECORDS CANNOT BE CREATED IN A NON-LMO ORG. TESTS ARE ONLY FOR CODE COVERAGE /////////        
    }


}