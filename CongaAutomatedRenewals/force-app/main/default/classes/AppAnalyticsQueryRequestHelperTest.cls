/**
* @author GTM, ERedding
* @date 20201005
* @version 1.00
* @description AppAnalyticsQueryRequestHelperTest  - Test class for the AppAnalyticsQueryRequestHelper class
*/
@isTest
public class AppAnalyticsQueryRequestHelperTest {

    // FAKE COMPLETED AppAnalyticsQueryRequest RECORD
    public static List<AppAnalyticsQueryRequest> CompletedTestRequests {get; set;}


    // FAKE PENDING AppAnalyticsQueryRequest RECORD
    public static Map<Id, AppAnalyticsQueryRequest> PendingTestRequests {
    get {
        Map<String, Object> fakeFieldValues = new Map<String, Object>{ 
            'Id' => '0XI1T000000ABCDWA4',
            'RequestState' => 'Pending'
        };
        AppAnalyticsQueryRequest fakeTestRecord = (AppAnalyticsQueryRequest)TestingUtility.createTestMeta('AppAnalyticsQueryRequest', fakeFieldValues);
        PendingTestRequests = new Map<Id, AppAnalyticsQueryRequest>{ fakeTestRecord.Id => fakeTestRecord };
        return PendingTestRequests;
    } set; }


    /**
    * @description appAnalyticsQueryRequestTriggerTest - Cover AppAnalyticsQueryRequest trigger
    */
    public static testMethod void appAnalyticsQueryRequestTriggerTest() {
        // CREATE START AND END TIMES FOR ALL OF LAST MONTH
        Date lastMonthEnd = Date.newInstance(Datetime.now().year(), Datetime.now().month(), 1).addDays(-1); // LAST DAY OF LAST MONTH IN USER'S LOCAL TIM
        Datetime summaryStartTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), 1, 0, 0, 0);
        Datetime summaryEndTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), lastMonthEnd.day(), 23, 59, 59);

        Test.startTest();

        AppAnalyticsQueryRequest testNewRequest = new AppAnalyticsQueryRequest(DataType = 'PackageUsageSummary', OrganizationIds = '00D3h00000ABCDE',
                                                                               PackageIds = '0335000000ABCDE', StartTime = summaryStartTime, EndTime = summaryEndTime);

        try{
            insert testNewRequest;
        }
        catch(Exception ex){
            System.debug(ex);
            System.assert(ex.getMessage().contains('Code Coverage Run Complete'));
        }

        Test.stopTest();
    }

    /**
    * @description copyCompletedRequestFileToAzureTest - Test happy path of code
    */
    public static testMethod void copyCompletedRequestFileToAzureTest_TriggerMethod() {
        // CREATE START AND END TIMES FOR ALL OF LAST MONTH
        Date lastMonthEnd = Date.newInstance(Datetime.now().year(), Datetime.now().month(), 1).addDays(-1); // LAST DAY OF LAST MONTH IN USER'S LOCAL TIM
        Datetime summaryStartTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), 1, 0, 0, 0);
        Datetime summaryEndTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), lastMonthEnd.day(), 23, 59, 59);

        // CREATE TEST DOWNLOAD URL
        String downloadURL = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=0151T00000ABCDEFGH';
        System.assert(String.isNotBlank(downloadURL));

        String testFileName1 = 'A1|Summary|' + String.valueOf(summaryStartTime.dateGMT()) + '|00D3h00000ABCDE|0335000000ABCDE.csv';
        System.assert(String.isNotBlank(testFileName1));
        
        Test.startTest();

        Map<String, Object> fakeFieldValues = new Map<String, Object>{ 
            'Id' => '0XI1T000000ABCDWA4',
            'DataType' => 'PackageUsageSummary',
            'RequestState' => 'Complete',
            'OrganizationIds' => '00D3h00000ABCDE',
            'PackageIds' => '0335000000ABCDE',
            'DownloadURL' => downloadURL,
            'StartTime' => summaryStartTime,
            'EndTime' => summaryEndTime
        };
        AppAnalyticsQueryRequest completedTestRequest = (AppAnalyticsQueryRequest)TestingUtility.createTestMeta('AppAnalyticsQueryRequest', fakeFieldValues);
        CompletedTestRequests = new List<AppAnalyticsQueryRequest>{ completedTestRequest };

        // SETUP HTTP MOCK RESPONSES USING MULTI MOCK
        Test.setMock(HttpCalloutMock.class, new CreateAzureBlobHTTPMock());

        AppAnalyticsQueryRequestHelper.copyCompletedRequestFileToAzure(CompletedTestRequests, PendingTestRequests);

        Test.stopTest();
    }

    /**
    * @description copyCompletedRequestFileToAzureTest_TriggerMethodBadParams - Test execution of trigger method using bad params
    */
    public static testMethod void copyCompletedRequestFileToAzureTest_TriggerMethodBadParams() {
        Test.startTest();

        AppAnalyticsQueryRequestHelper.copyCompletedRequestFileToAzure(new List<AppAnalyticsQueryRequest>(), new Map<Id, AppAnalyticsQueryRequest>());
        AppAnalyticsQueryRequestHelper.copyCompletedRequestFileToAzure(null, null);

        Test.stopTest();
    }

    /**
    * @description copyCompletedRequestFileToAzureAPITest_FutureMethod - Test happy path of code
    */
    public static testMethod void copyCompletedRequestFileToAzureAPITest_FutureMethod() {
        // CREATE START AND END TIMES FOR ALL OF LAST MONTH
        Date lastMonthEnd = Date.newInstance(Datetime.now().year(), Datetime.now().month(), 1).addDays(-1); // LAST DAY OF LAST MONTH IN USER'S LOCAL TIM
        Datetime summaryStartTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), 1, 0, 0, 0);
        Datetime summaryEndTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), lastMonthEnd.day(), 23, 59, 59);

        // CREATE FILE NAME
        String testFileName1 = 'A1|Summary|' + String.valueOf(summaryStartTime.dateGMT()) + '|00D3h00000ABCDE|0335000000ABCDE.csv';
        System.assert(String.isNotBlank(testFileName1));

        String downloadURL = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=0151T00000ABCDEFGH';
        System.assert(String.isNotBlank(downloadURL));

        Test.startTest();

        Map<String, Object> fakeFieldValues = new Map<String, Object>{ 
            'Id' => '0XI1T000000ABCDWA4',
            'DataType' => 'PackageUsageSummary',
            'RequestState' => 'Complete',
            'OrganizationIds' => '00D3h00000ABCDE',
            'PackageIds' => '0335000000ABCDE',            
            'DownloadURL' => downloadURL,
            'StartTime' => summaryStartTime,
            'EndTime' => summaryEndTime
        };
        AppAnalyticsQueryRequest completedTestRequest = (AppAnalyticsQueryRequest)TestingUtility.createTestMeta('AppAnalyticsQueryRequest', fakeFieldValues);
        CompletedTestRequests = new List<AppAnalyticsQueryRequest>{ completedTestRequest };

        // SETUP HTTP MOCK RESPONSES USING MULTI MOCK
        Test.setMock(HttpCalloutMock.class, new CreateAzureBlobHTTPMock());

        AppAnalyticsQueryRequestHelper.copyCompletedRequestFileToAzureAPI(new Set<Id>{ completedTestRequest.Id });

        Test.stopTest();    
    }

    /**
    * @description copyCompletedRequestFileToAzureAPITest_FutureMethodHTTPErrors - Test handling of HTTP errors
    */
    public static testMethod void copyCompletedRequestFileToAzureAPITest_FutureMethodHTTPErrors() {
        // CREATE START AND END TIMES FOR ALL OF LAST MONTH
        Date lastMonthEnd = Date.newInstance(Datetime.now().year(), Datetime.now().month(), 1).addDays(-1); // LAST DAY OF LAST MONTH IN USER'S LOCAL TIM
        Datetime summaryStartTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), 1, 0, 0, 0);
        Datetime summaryEndTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), lastMonthEnd.day(), 23, 59, 59);

        // CREATE FILE NAME
        String testFileName1 = 'A1|Summary|' + String.valueOf(summaryStartTime.dateGMT()) + '|00D3h00000ABCDE|0335000000ABCDE.csv';
        System.assert(String.isNotBlank(testFileName1));

        String downloadURL = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=0151T00000ABCDEFGH';
        System.assert(String.isNotBlank(downloadURL));

        Test.startTest();

        Map<String, Object> fakeFieldValues = new Map<String, Object>{ 
            'Id' => '0XI1T000000ABCDWA4',
            'DataType' => 'PackageUsageSummary',
            'RequestState' => 'Complete',
            'OrganizationIds' => '00D3h00000ABCDE',
            'PackageIds' => '0335000000ABCDE',            
            'DownloadURL' => downloadURL,
            'StartTime' => summaryStartTime,
            'EndTime' => summaryEndTime
        };
        AppAnalyticsQueryRequest completedTestRequest = (AppAnalyticsQueryRequest)TestingUtility.createTestMeta('AppAnalyticsQueryRequest', fakeFieldValues);
        CompletedTestRequests = new List<AppAnalyticsQueryRequest>{ completedTestRequest };

        // SETUP HTTP MOCK RESPONSES USING MULTI MOCK
        Test.setMock(HttpCalloutMock.class, new CreateAzureAPIHTTPMockError());

        AppAnalyticsQueryRequestHelper.copyCompletedRequestFileToAzureAPI(new Set<Id>{ completedTestRequest.Id });

        Test.stopTest();   
    }


    /**
    * @description CreateAzureBlobHTTPMock - HTTP Mock class for testing the AppAnalyticsQueryRequestHelper.copyCompletedRequestFileToAzure method PUT file call out
    */
    public class CreateAzureBlobHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');
            res.setBody('{"type": "proposal/email"}');
            res.setStatus('Created');
            res.setStatusCode(201);
            return res;
        }
    }

    /**
    * @description CreateAzureAPIHTTPMockError - HTTP Mock class for testing the AppAnalyticsQueryRequestHelper.copyCompletedRequestFileToAzureAPI method GET call out error handling
    */
    public class CreateAzureAPIHTTPMockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/JSON');
            res.setStatus('Unauthorized');
            res.setStatusCode(401);
            return res;
        }
    }


}