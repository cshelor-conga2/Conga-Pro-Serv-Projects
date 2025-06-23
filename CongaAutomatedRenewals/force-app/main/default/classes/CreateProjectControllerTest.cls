/**
* @author CongaServices, KSears
* @date 20170228
* @version 1.00
* @description CreateProjectControllerTest - Test class for the CreateProjectController class
*/
@isTest
private class CreateProjectControllerTest {

    /**
    * @description setup - Setup test data
    */  
    @testSetup
    public static void setup() {
        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 2);  
        testAccounts[0].Name = 'Winterfell Inc.';  
        testAccounts[0].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
        testAccounts[1].Name = 'Winterfell Inc.2';  
        testAccounts[1].RecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
        insert testAccounts;

        List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 2);
        testContacts[0].AccountId = testAccounts[0].Id;
        testContacts[0].FirstName = 'Test';
        testContacts[0].LastName = 'User';
        testContacts[1].AccountId = testAccounts[1].Id;
        insert testContacts;

        // CREATE TEST QUOTE
        SBQQ__Quote__c testQuote = (SBQQ__Quote__c)TestingUtility.createSObject('SBQQ__Quote__c', true, 1);
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;

        // CREATE TEST OPPS
        List<Opportunity> testOpps = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', true, 3);
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].SBQQ__PrimaryQuote__c = testQuote.Id;
        testOpps[1].AccountId = testAccounts[1].Id;
        testOpps[2].StageName = 'Closed Won';
        testOpps[2].Sales_Ops_Status__c = 'Closed Won';
        testOpps[2].CloseDate = Date.today();
        insert testOpps;

        List<OpportunityContactRole> testOppContactRoles = (List<OpportunityContactRole>)TestingUtility.createSObjectList('OpportunityContactRole', true, 2);
        testOppContactRoles[0].ContactId = testContacts[0].Id;
        testOppContactRoles[0].OpportunityId = testOpps[0].Id;
        testOppContactRoles[0].Role = 'Technical Buyer';
        testOppContactRoles[1].ContactId = testContacts[1].Id;
        testOppContactRoles[1].OpportunityId = testOpps[1].Id;
        testOppContactRoles[1].Role = 'Administrator';
        insert testOppContactRoles;

        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', true, 2);
        testProducts[0].Name = 'prod1';
        testProducts[0].ProductCode = 'prod1';          
        testProducts[0].LOB__c = 'Services';
        testProducts[0].FY16_Revenue_Type__c = 'Non-Recurring';
        testProducts[0].Family = 'Professional Services';
        testProducts[1].Name = 'prod2';
        testProducts[1].ProductCode = 'prod2';
        testProducts[1].LOB__c = 'Services';
        testProducts[1].FY16_Revenue_Type__c = 'Non-Recurring';
        testProducts[1].Family = 'Professional Services';
        insert testProducts;

        List<PricebookEntry> testPBEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', true, 2);
        testPBEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPBEntries[0].Product2Id = testProducts[0].Id;
        testPBEntries[0].IsActive = TRUE;
        testPBEntries[0].UnitPrice = 1.00;
        testPBEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testPBEntries[1].Product2Id = testProducts[1].Id;
        testPBEntries[1].IsActive = TRUE;
        testPBEntries[1].UnitPrice = 1.00;
        insert testPBEntries;

        List<OpportunityLineItem> testOppLineItems = (List<OpportunityLineItem>)TestingUtility.createSObjectList('OpportunityLineItem', true, 3);
        testOppLineItems[0].OpportunityId = testOpps[0].Id;
        testOppLineItems[0].Quantity = 3;
        testOppLineItems[0].UnitPrice = 200;
        testOppLineItems[0].PricebookEntryId = testPBEntries[0].Id;
        testOppLineItems[0].ServiceDate = Date.today();
        testOppLineItems[1].OpportunityId = testOpps[0].Id;
        testOppLineItems[1].Quantity = 5;
        testOppLineItems[1].UnitPrice = 500;
        testOppLineItems[1].PricebookEntryId = testPBEntries[1].Id;
        testOppLineItems[1].ServiceDate = Date.today();
        testOppLineItems[2].OpportunityId = testOpps[1].Id;
        testOppLineItems[2].Quantity = 3;
        testOppLineItems[2].UnitPrice = 200;
        testOppLineItems[2].PricebookEntryId = testPBEntries[1].Id;
        testOppLineItems[2].ServiceDate = Date.today();
        insert testOppLineItems;
    }

    /**
    * @description test_method_one - 
    */  
    public static testmethod void test_method_one() {
        // GET TEST OPPORTUNITY
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity LIMIT 1];
        System.assert(testOpps.size() == 1);

        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(testOpps[0]);
        CreateProjectController cn = new CreateProjectController(sc);
        cn.AutoRun();

        Test.stopTest();
    }

    /**
    * @description test_method_two - 
    */  
    public static testmethod void test_method_two() {
        Test.startTest();

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController([SELECT Id FROM Opportunity]);
        sc.setselected([SELECT Id FROM Opportunity]);
        CreateProjectController cn = new CreateProjectController(sc);
        cn.AutoRun();

        Test.stopTest();        
    }

    /**
    * @description test_method_three - 
    */  
    public static testmethod void test_method_three() {
        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(new Opportunity());
        CreateProjectController cn = new CreateProjectController(sc);
        cn.AutoRun();

        Test.stopTest();
    }


}