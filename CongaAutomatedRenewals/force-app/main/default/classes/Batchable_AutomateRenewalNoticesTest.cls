/** 
* @author Conga Services
* @date 
* @version 1.00
* @description Batchable_AutomateRenewalNoticesTest - Test class for the Batchable_AutomateRenewalNotices class
*/
@isTest
public class Batchable_AutomateRenewalNoticesTest {
    
    /**
    * @description setup - Create test data
    * @return void
    */
    @testSetup
    public static void setup(){
        Account testAccount = new Account(Name = 'Test Account 1');
        insert testAccount;

        // CREATE TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.AccountId = testAccount.Id;
        testContract.Status = 'Draft';
        testContract.StartDate = Date.today().addDays(45);
        testContract.ContractTerm = 12;
        insert testContract;

        // TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = new List<Opportunity>();
        testOpportunities.add(new Opportunity(
            Name = 'Test Opportunity 75 days', 
            AccountId = testAccount.Id, 
            StageName = 'Qualify', 
            Type = 'Renewal', 
            ForecastCategoryName = 'Best Case', 
            CloseDate = Date.today(),
            LeadSource = 'Advertisement',
            Automate_Renewal__c = true, 
            MRR_Sub_Start__c = Date.today().addDays(75)));
        testOpportunities.add(new Opportunity(
            Name = 'Test Opportunity 60 days', 
            AccountId = testAccount.Id, 
            StageName = 'Qualify', 
            Type = 'Renewal', 
            ForecastCategoryName = 'Best Case', 
            CloseDate = Date.today(),
            LeadSource = 'Advertisement',
            Automate_Renewal__c = true,
            MRR_Sub_Start__c = Date.today().addDays(60)));
        insert testOpportunities;

        // TEST QUOTES
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c testQuoteForSeventyFiveDaysQuote = new SBQQ__Quote__c(SBQQ__Type__c = 'Quote 75', SBQQ__Opportunity2__c = testOpportunities[0].Id, SBQQ__Status__c = 'Approved',
                                                                             Automatic_Renewal_Notice__c = 'Triggered', Conga_Collaborate_Template__c = 'Renewal Notice');        
        testQuotes.add(testQuoteForSeventyFiveDaysQuote);

        SBQQ__Quote__c testQuoteForSixtyDaysOpp = new SBQQ__Quote__c(SBQQ__Type__c = 'Quote 60', SBQQ__Opportunity2__c = testOpportunities[1].Id, SBQQ__Status__c = 'Approved',
                                                                     Automatic_Renewal_Notice__c = 'Triggered', Conga_Collaborate_Template__c = 'Signable Renewal Order Form');
        testQuotes.add(testQuoteForSixtyDaysOpp);
        insert testQuotes;

        // UPDATE OPPS
        testOpportunities[0].SBQQ__PrimaryQuote__c = testQuoteForSeventyFiveDaysQuote.Id;
        testOpportunities[1].SBQQ__PrimaryQuote__c = testQuoteForSixtyDaysOpp.Id;
        update testOpportunities;
    }

    /**
    * @description renewalCalloutTest - Test renewalCallout
    * @return void
    */
    public static testmethod void renewalCalloutTest() {
        List<SBQQ__Quote__c> testQuotes = [SELECT Id, OwnerId FROM SBQQ__Quote__c WHERE Automatic_Renewal_Notice__c = 'Triggered' 
                                                                                  AND Conga_Collaborate_Template__c != null 
                                                                                  AND (Days_Before_Opp_MRR_Sub_Start__c = 75 OR Days_Before_Opp_MRR_Sub_Start__c = 60)];
        System.assert(!testQuotes.isEmpty());

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new RenewalNoticeHTTPCalloutMock());
        Batchable_AutomateRenewalNotices batchClass = new Batchable_AutomateRenewalNotices();

        batchClass.start(null);
        batchClass.execute(null, testQuotes);
        batchClass.finish(null);

        Test.stopTest();

        // CHECK THAT ERRORS -WERE NOT- LOGGED
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(errors.isEmpty());
    }

    /**
    * @description renewalCalloutHTTPFailureTest - Test renewalCallout
    * @return void
    */
    public static testmethod void renewalCalloutHTTPFailureTest() {
        List<SBQQ__Quote__c> testQuotes = [SELECT Id, OwnerId FROM SBQQ__Quote__c WHERE Automatic_Renewal_Notice__c = 'Triggered' 
                                                                                  AND Conga_Collaborate_Template__c != null 
                                                                                  AND (Days_Before_Opp_MRR_Sub_Start__c = 75 OR Days_Before_Opp_MRR_Sub_Start__c = 60)];
        System.assert(!testQuotes.isEmpty());

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new RenewalNoticeHTTPCalloutHTTPErrorMock());
        Batchable_AutomateRenewalNotices batchClass = new Batchable_AutomateRenewalNotices();

        batchClass.start(null);
        batchClass.execute(null, testQuotes);
        batchClass.finish(null);

        Test.stopTest();

        // CHECK THAT ERRORS -WERE- LOGGED
        List<System_Issue_Log__c> errors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(!errors.isEmpty());
    }


    ///////////////////////////// HTTP MOCKS ////////////////////////////////  
    

    /**
    * @description RenewalNoticeHTTPCalloutMock - HTTP Mock class for testing the BatchableSch_AutomateRenewalsHelper.renewalCallout POST callout
    */
    public class RenewalNoticeHTTPCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml; charset=character encoding');
            
            //////// BUILD XML MOCK RESPONSE BODY ////////
            String body = '<soapenv:Envelope>';
                     body =+ '<soapenv:Body>';
                        body =+ '<notificationsResponse>';
                           body =+ '<Ack>true</Ack>';
                        body =+ '</notificationsResponse>';
                     body =+ '</soapenv:Body>';
                    body =+ '</soapenv:Envelope>';

            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
    * @description RenewalNoticeHTTPCalloutHTTPErrorMock - HTTP Mock class for testing the BatchableSch_AutomateRenewalsHelper.renewalCallout POST callout
    */
    public class RenewalNoticeHTTPCalloutHTTPErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Atext/xml; charset=character encoding');

            //////// BUILD XML MOCK RESPONSE BODY ////////
            String body = '<soapenv:Envelope>';
                     body =+ '<soapenv:Body>';
                        body =+ '<notificationsResponse>';
                           body =+ '<Ack>true</Ack>';
                        body =+ '</notificationsResponse>';
                     body =+ '</soapenv:Body>';
                    body =+ '</soapenv:Envelope>';
                    
            res.setBody(body);
            res.setStatusCode(400);
            return res;
        }
    }


}