/**
* @author Conga Services, eredding
* @date 20180806
* @version 1.00
* @description Schedulable_ProcessSignUpRequestsTest - Test class for the Schedulable_ProcessSignUpRequests schedulable class
*/
@isTest
public with sharing class Schedulable_ProcessSignUpRequestsTest {
    
    /**
    * @description setup - Setup test data
    */
    @testSetup
    public static void setup() {
        String orgId = UserInfo.getOrganizationId().substring(0,15);

        // TEST LEAD
        Lead testLead = new Lead(Status = 'Working', LastName = 'Test', Company = 'Test Company');
        insert testLead;

        // TEST PACKAGE
        sfLma__Package__c testPackage1 = new sfLma__Package__c(Name = 'Conga Composer', sfLma__Latest_Version__c = '1.0');
        sfLma__Package__c testPackage2 = new sfLma__Package__c(Name = 'Conga Courier', sfLma__Latest_Version__c = '1.0');
        insert new List<sfLma__Package__c> { testPackage1, testPackage2 };

        // TEST PACKAGE VERSION
        sfLma__Package_Version__c testPackageVersion1 = new sfLma__Package_Version__c(Name = '1.0', sfLma__Package__c = testPackage1.Id, sfLma__Version__c = '1.0');
        sfLma__Package_Version__c testPackageVersion2 = new sfLma__Package_Version__c(Name = '1.0', sfLma__Package__c = testPackage2.Id, sfLma__Version__c = '1.0');
        insert new List<sfLma__Package_Version__c> { testPackageVersion1, testPackageVersion2 };

        sfLma__License__c testLicense1 = new sfLma__License__c(sfLma__Install_Date__c = Date.today().addDays(-1), SfLma__Subscriber_Org_ID__c = orgId, sfLma__Lead__c = testLead.Id, 
                                                               SfLma__Package__c = testPackage1.Id, sfLma__Status__c = 'Active', sfLma__Seats__c = 5);
        sfLma__License__c testLicense2 = new sfLma__License__c(sfLma__Install_Date__c = Date.today().addDays(-1), SfLma__Subscriber_Org_ID__c = orgId, sfLma__Lead__c = testLead.Id, 
                                                               SfLma__Package__c = testPackage2.Id, sfLma__Status__c = 'Active', sfLma__Seats__c = 5);
        insert new List<sfLma__License__c> { testLicense1, testLicense2 };
        
        // TEST SALESFORCE ORG
        Salesforce_Org__c testOrg = new Salesforce_Org__c(Name = 'Test Org', Conga_Activation_Date__c = DateTime.now().addDays(30), Org_Id__c = orgId, Salesforce_Account_Id__c = orgId);
        insert testOrg;
    }

    /**
    * @description processSignUpRequestsTest1 - Test schedulable with records to update
    */
    public static testMethod void processSignUpRequestsTest1(){
        String orgId = UserInfo.getOrganizationId().substring(0,15);
        Date ninetyDaysOut = Date.today().addDays(90);

        // CREATE TEST SIGNUP REQUEST
        Signup_Request__c testRequest = new Signup_Request__c(Name = '000106', Company__c = 'Blue Cube', Created_Org_Id__c = orgId, Status__c = 'Success');
        insert testRequest;

        // SCHEDULE CODE AND STOP TEST TO EXECUTE
        Test.startTest();
        System.schedule('ProcessSignUpRequests', '0 0 0 1 1 ? 2025', new Schedulable_ProcessSignUpRequests());
        Test.stopTest();

        // TEST LICENSES FOR CORRECT DATA
        List<sfLma__License__c> licenses = [SELECT Id, sfLma__Expiration__c FROM sfLma__License__c WHERE sfLma__Subscriber_Org_ID__c = :orgId];
        System.assert(licenses.size() == 2);
        System.assert(licenses[0].sfLma__Expiration__c == ninetyDaysOut);
        System.assert(licenses[1].sfLma__Expiration__c == ninetyDaysOut);

        // TEST SALESFORCE ORG FOR CORRECT DATA
        List<Salesforce_Org__c> salesforceOrgs = [SELECT Id, Conga_Trial_Expiration_Date__c, Courier_Trial_Expiration_Date__c, Conga_Conductor_Authorized__c, Conga_Workflow_Authorized__c, Courier_Enabled__c 
                                                  FROM Salesforce_Org__c WHERE Salesforce_Org_Id_15__c = :orgId];
        System.assert(salesforceOrgs.size() == 1);
        System.assert(salesforceOrgs[0].Conga_Trial_Expiration_Date__c == ninetyDaysOut);
        System.assert(salesforceOrgs[0].Courier_Trial_Expiration_Date__c == ninetyDaysOut);
        System.assert(salesforceOrgs[0].Conga_Conductor_Authorized__c == true);
        System.assert(salesforceOrgs[0].Conga_Workflow_Authorized__c == true);
        System.assert(salesforceOrgs[0].Courier_Enabled__c == true);
    }


    /**
    * @description processSignUpRequestsTest2 - Test schedulable without records to update
    */
    public static testMethod void processSignUpRequestsTest2(){
        String orgId = UserInfo.getOrganizationId().substring(0,15);
        Date ninetyDaysOut = Date.today().addDays(90);

        // UPDATE TEST LICENSES
        List<sfLma__License__c> licenses = [SELECT Id, sfLma__Expiration__c FROM sfLma__License__c WHERE sfLma__Subscriber_Org_ID__c = :orgId];
        System.assert(licenses.size() == 2);
        licenses[0].sfLma__Expiration__c = ninetyDaysOut;
        licenses[1].sfLma__Expiration__c = ninetyDaysOut;
        update licenses;

        // UPDATE TEST SALESFORCE ORG
        List<Salesforce_Org__c> salesforceOrgs = [SELECT Id, Conga_Trial_Expiration_Date__c, Courier_Trial_Expiration_Date__c FROM Salesforce_Org__c WHERE Salesforce_Org_Id_15__c = :orgId];
        System.assert(salesforceOrgs.size() == 1);
        salesforceOrgs[0].Conga_Trial_Expiration_Date__c = ninetyDaysOut;
        salesforceOrgs[0].Courier_Trial_Expiration_Date__c = ninetyDaysOut;
        update salesforceOrgs;

        // CREATE TEST SIGNUP REQUEST
        Signup_Request__c testRequest = new Signup_Request__c(Name = '000106', Company__c = 'Blue Cube', Created_Org_Id__c = orgId, Status__c = 'Success');
        insert testRequest;

        // SCHEDULE CODE AND STOP TEST TO EXECUTE
        Test.startTest();
        System.schedule('ProcessSignUpRequests', '0 0 0 1 1 ? 2025', new Schedulable_ProcessSignUpRequests());
        Test.stopTest();
    }


}