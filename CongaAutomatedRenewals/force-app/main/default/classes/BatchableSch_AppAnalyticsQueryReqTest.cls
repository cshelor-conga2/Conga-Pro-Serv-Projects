/**
* @author GTM, ERedding
* @date 20201005
* @version 1.00
* @description BatchableSch_AppAnalyticsQueryReqTest  - Test class for the BatchableSch_AppAnalyticsQueryRequests class
*/
@isTest
public class BatchableSch_AppAnalyticsQueryReqTest {

    /**
    * @description setupTestData - Test data setup method
    */
    @testSetup
    public static void setupTestData(){
        // TEST PACKAGES
        sfLma__Package__c testPackages1 = new sfLma__Package__c(Name = 'Apttus Proposal Management', sfLma__Latest_Version__c = '1.0', sfLma__Package_ID__c = '03350000000ABCDEFG');
        sfLma__Package__c testPackages2 = new sfLma__Package__c(Name = 'Apttus Contract Management', sfLma__Latest_Version__c = '1.0', sfLma__Package_ID__c = '03350000000GFEDCBA');
        insert new List<sfLma__Package__c>{ testPackages1, testPackages2 };

        // TEST PACKAGE VERSIONS
        sfLma__Package_Version__c testVersion1 = new sfLma__Package_Version__c(Name = '1.0', sfLma__Package__c = testPackages1.Id, sfLma__Version__c = '1.0');
        sfLma__Package_Version__c testVersion2 = new sfLma__Package_Version__c(Name = '1.0', sfLma__Package__c = testPackages2.Id, sfLma__Version__c = '1.0');
        insert new List<sfLma__Package_Version__c>{ testVersion1, testVersion2 };

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // CREATE TEST LICENSES
        sfLma__License__c testLicense1 = new sfLma__License__c(sfLma__Account__c = testAccount.Id, sfLma__Package_Version__c = testVersion1.Id,
                                                                sfLma__Subscriber_Org_ID__c = '00D3h000003T4Hs', sfLma__Status__c = 'Active');
        //
        sfLma__License__c testLicense2 = new sfLma__License__c(sfLma__Account__c = testAccount.Id, sfLma__Package_Version__c = testVersion1.Id,
                                                                sfLma__Subscriber_Org_ID__c = '00D1U000001ALyQ', sfLma__Status__c = 'Active');
        //
        sfLma__License__c testLicense3 = new sfLma__License__c(sfLma__Account__c = testAccount.Id, sfLma__Package_Version__c = testVersion2.Id,
                                                                sfLma__Subscriber_Org_ID__c = '00D3h000003T4Hs', sfLma__Status__c = 'Active');
        //
        sfLma__License__c testLicense4 = new sfLma__License__c(sfLma__Account__c = testAccount.Id, sfLma__Package_Version__c = testVersion2.Id,
                                                                sfLma__Subscriber_Org_ID__c = '00D1U000001ALyQ', sfLma__Status__c = 'Active');
        insert new List<sfLma__License__c>{ testLicense1, testLicense2, testLicense3, testLicense4 };
    }
    
    
    /**
    * @description testMethod1 - Test Happy Path of code
    */
    public static testMethod void batchableTest1_NoParams() {
        Test.startTest();
    
        BatchableSch_AppAnalyticsQueryRequests batchProcess = new BatchableSch_AppAnalyticsQueryRequests();
        Database.executeBatch(batchProcess);

        Test.stopTest();

        /////////// FURTHER TESTING NOT POSSIBLE SINCE AppAnalyticsQueryRequest RECORDS CANNOT BE CREATED IN A NON-LMO ORG. TESTS ARE ONLY FOR CODE COVERAGE /////////
    }
    
    /**
    * @description testMethod2 - Test Exceptions To code
    */
    public static testMethod void batchableTest_WithParams() {
        // GET SUBSCRIBER ORG IDS
        Set<String> testOrgIds = new Set<String>();
        Set<String> testPackageIds = new Set<String>();
        for(sfLma__License__c testLicense : [SELECT Id, sfLma__Subscriber_Org_ID__c, sfLma__Package__r.sfLma__Package_ID__c FROM sfLma__License__c]){
            testOrgIds.add(testLicense.sfLma__Subscriber_Org_ID__c);
            testPackageIds.add(testLicense.sfLma__Package__r.sfLma__Package_ID__c);
        }

        Test.startTest();
    
        BatchableSch_AppAnalyticsQueryRequests batchProcess = new BatchableSch_AppAnalyticsQueryRequests();
        batchProcess.SubscriberOrgIDs = testOrgIds;
        batchProcess.PackageIDs = testPackageIds;

        Database.executeBatch(batchProcess);

        Test.stopTest();

        /////////// FURTHER TESTING NOT POSSIBLE SINCE AppAnalyticsQueryRequest RECORDS CANNOT BE CREATED IN A NON-LMO ORG. TESTS ARE ONLY FOR CODE COVERAGE /////////        
    }
    
    /**
    * @description testMethod2 - Test Exceptions To code
    */
    public static testMethod void batchableTest_WithOnlyOrgParam() {
        // GET SUBSCRIBER ORG IDS
        Set<String> testOrgIds = new Set<String>();
        for(sfLma__License__c testLicense : [SELECT Id, sfLma__Subscriber_Org_ID__c, sfLma__Package__r.sfLma__Package_ID__c FROM sfLma__License__c]){
            testOrgIds.add(testLicense.sfLma__Subscriber_Org_ID__c);
        }

        Test.startTest();
    
        BatchableSch_AppAnalyticsQueryRequests batchProcess = new BatchableSch_AppAnalyticsQueryRequests();
        batchProcess.SubscriberOrgIDs = testOrgIds;

        Database.executeBatch(batchProcess);

        Test.stopTest();

        /////////// FURTHER TESTING NOT POSSIBLE SINCE AppAnalyticsQueryRequest RECORDS CANNOT BE CREATED IN A NON-LMO ORG. TESTS ARE ONLY FOR CODE COVERAGE /////////        
    }

    /**
    * @description testMethod2 - Test Exceptions To code
    */
    public static testMethod void batchableTest_WithOnlyPackageParam() {
        // GET SUBSCRIBER ORG IDS
        Set<String> testPackageIds = new Set<String>();
        for(sfLma__License__c testLicense : [SELECT Id, sfLma__Subscriber_Org_ID__c, sfLma__Package__r.sfLma__Package_ID__c FROM sfLma__License__c]){
            testPackageIds.add(testLicense.sfLma__Package__r.sfLma__Package_ID__c);
        }

        Test.startTest();
    
        BatchableSch_AppAnalyticsQueryRequests batchProcess = new BatchableSch_AppAnalyticsQueryRequests();
        batchProcess.PackageIDs = testPackageIds;

        Database.executeBatch(batchProcess);

        Test.stopTest();

        /////////// FURTHER TESTING NOT POSSIBLE SINCE AppAnalyticsQueryRequest RECORDS CANNOT BE CREATED IN A NON-LMO ORG. TESTS ARE ONLY FOR CODE COVERAGE /////////        
    }
    
    /**
    * @description testMethod3 - Test With base user
    */
    public static testMethod void schedulableTest() {
        Test.startTest();

        BatchableSch_AppAnalyticsQueryRequests scheduled = new BatchableSch_AppAnalyticsQueryRequests();
        System.schedule('AppAnalytics Query Request Test', '0 0 22 * * ?', scheduled);

        Test.stopTest();
    }


}