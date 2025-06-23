/**
* @author Conga Services
* @date 20181030
* @version 1.00
* @description ContractHelperTest - Test class for the ContractHelper class
*/
@isTest
public class ContractHelperTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account', false);
        insert testAccount;

        // TEST OPP
        List<Opportunity> testOpportunities = TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].AccountId = testAccount.Id;
        testOpportunities[0].Type = 'New Business';
        testOpportunities[0].Purchase_Order_Required__c = true;
        testOpportunities[1].AccountId = testAccount.Id;
        testOpportunities[1].Type = 'Renewal';
        insert testOpportunities;

        // TEST PRODUCT
        Product2 testProduct = (Product2)TestingUtility.createSObject('Product2', false);
        testProduct.Name = 'Test Product';
        testProduct.ProductCode = 'TP1';
        insert testProduct;

        // TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.Status = 'Draft';
        testContract.AccountId = testAccount.Id;
        testContract.StartDate = Date.today().addDays(30);
        testContract.ContractTerm = 12;
        testContract.SBQQ__Opportunity__c = testOpportunities[0].Id;
        insert testContract;

        // TEST SUBSCRIPTION
        SBQQ__Subscription__c testSubscription = (SBQQ__Subscription__c)TestingUtility.createSObject('SBQQ__Subscription__c', false);
        testSubscription.SBQQ__Contract__c = testContract.Id;
        insert testSubscription;
    }
    
    /**
    * @description contractFieldUpdatesTest - Test method for the contractFieldUpdates method
    */
    private static testmethod void contractFieldUpdatesTest(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        System.assert(testAccounts.size() == 1);

        // GET TEST OPPS
        List<Opportunity> testOpportunities = [SELECT Id, RecordTypeId, Customer_Org_Id__c FROM Opportunity];
        System.assert(!testOpportunities.isEmpty());

          // TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', false, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Quote';
        testQuotes[0].SBQQ__StartDate__c = Date.today().addDays(30);
        testQuotes[0].SBQQ__EndDate__c = Date.today().addMonths(12);
        testQuotes[0].SBQQ__Opportunity2__c = testOpportunities[0].Id;
        insert testQuotes;

        Test.startTest();

        // TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.AccountId = testAccounts[0].Id;
        testContract.StartDate = Date.today().addDays(30);
        testContract.ContractTerm = 12;
        testContract.Contract_Type__c = 'Master Subscription';
        testContract.SBQQ__Quote__c = testQuotes[0].Id;
        testContract.SBQQ__Opportunity__c = testOpportunities[0].Id;
        testContract.RecordTypeId = UtilityClass.getRecordTypesForObject('Contract').get('Customer_Subscription');
        insert testContract;

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContract = [SELECT Id, Name, SBQQ__AmendmentOpportunityRecordTypeId__c, SBQQ__RenewalOpportunityRecordTypeId__c, Customer_Org_Id__c, SBQQ__RenewalOpportunityStage__c,
                               Contract_Type__c
                        FROM Contract WHERE Id = :testContract.Id];

        System.assert(testContract.Name.contains(testAccounts[0].Name));
        System.assert(testContract.SBQQ__AmendmentOpportunityRecordTypeId__c == testOpportunities[0].RecordTypeId);
        System.assert(testContract.SBQQ__RenewalOpportunityRecordTypeId__c == testOpportunities[0].RecordTypeId);
        System.assert(testContract.Customer_Org_Id__c == testOpportunities[0].Customer_Org_Id__c);
        System.assert(testContract.SBQQ__RenewalOpportunityStage__c == 'Pending Renewal');
        System.assert(testContract.Contract_Type__c == 'Customer Subscription');

        Test.stopTest();
    }

    /**
    * @description testContractForecastQueueable - Test method for the contractForecastQueueable method
    */
    //private static testmethod void testContractForecastQueueable(){
    //    // GET TEST ACCOUNTS
    //    List<Account> testAccounts = [SELECT Id, Name FROM Account];
    //    System.assert(testAccounts.size() == 1);

    //    // GET TEST OPPS
    //    List<Opportunity> testOpportunities = [SELECT Id, RecordTypeId, Customer_Org_Id__c FROM Opportunity];
    //    System.assert(!testOpportunities.isEmpty());

    //      // TEST QUOTE
    //    List<SBQQ__Quote__c> testQuotes = TestingUtility.createSObjectList('SBQQ__Quote__c', false, 1);
    //    testQuotes[0].SBQQ__Status__c = 'Draft';
    //    testQuotes[0].SBQQ__Type__c = 'Quote';
    //    testQuotes[0].SBQQ__StartDate__c = Date.today().addDays(30);
    //    testQuotes[0].SBQQ__EndDate__c = Date.today().addMonths(12);
    //    testQuotes[0].SBQQ__Opportunity2__c = testOpportunities[0].Id;
    //    insert testQuotes;

    //    Test.startTest();

    //    // TEST CONTRACT
    //    Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
    //    testContract.AccountId = testAccounts[0].Id;
    //    testContract.StartDate = Date.today().addDays(30);
    //    testContract.ContractTerm = 12;
    //    testContract.Contract_Type__c = 'Master Subscription';
    //    testContract.SBQQ__Quote__c = testQuotes[0].Id;
    //    testContract.SBQQ__Opportunity__c = testOpportunities[0].Id;
    //    testContract.RecordTypeId = UtilityClass.getRecordTypesForObject('Contract').get('Customer_Subscription');
    //    insert testContract;

    //    Test.stopTest();

    //    // REFRESH CONTRACT AND TEST FOR CORRECT DATA
    //    testContract = [SELECT Id, Name, SBQQ__RenewalForecast__c FROM Contract WHERE Id = :testContract.Id];
    //    System.assert(testContract.SBQQ__RenewalForecast__c == true);
    //}

    /**
    * @description setPORequiredTest - Test setPORequired method
    */
    public static testMethod void setPORequiredTest() {
        // GET TEST ACCOUNT
        Account testAccount = [SELECT Id FROM Account];

        // GET TEST NEW BUSINESS OPP
        Opportunity testOpp = [SELECT Id, Purchase_Order_Required__c FROM Opportunity WHERE Type = 'New Business'];
        
        // CREATE TEST CONTRACT
        Contract testContract = (Contract)TestingUtility.createSObject('Contract', false);
        testContract.AccountId = testAccount.Id;
        testContract.Status = 'Draft';
        testContract.StartDate = Date.today().addDays(30);
        testContract.ContractTerm = 12;
        testContract.SBQQ__Opportunity__c = testOpp.Id;
        testContract.SBQQ__RenewalOpportunity__c = testOpp.Id;
        
        Test.startTest();

        // TEST PULL DOWN
        insert testContract;

        // REFRESH CONTRACT AND TEST FOR CORRECT DATA
        testContract = [SELECT Id, Purchase_Order_Required__c FROM Contract WHERE Id = :testContract.Id];
        System.assert(testContract.Purchase_Order_Required__c == true);

        // TEST PUSH UP
        testContract.Purchase_Order_Required__c = false;
        update testContract;

        // REFRESH OPPORTUNITY AND TEST FOR CORRECT DATA
        testOpp = [SELECT Id, Purchase_Order_Required__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assert(testOpp.Purchase_Order_Required__c == false);

        Test.stopTest();
    }
    
    /**
    * @description recalculateOppCurrentMRRTest - Test recalculateOppCurrentMRR method
    */
    public static testMethod void recalculateOppCurrentMRRTest() {
        // GET TEST CONTRACT
        Contract testContract = [SELECT Id, SBQQ__RenewalOpportunity__c FROM Contract];
        testContract.SBQQ__RenewalOpportunity__c = null;
        update testContract;

        // GET TEST RENEWAL OPP
        Opportunity testRenewalOpp = [SELECT Id FROM Opportunity WHERE Type = 'Renewal' LIMIT 1];

        Test.startTest();

        // SET RENEWAL OPP AND PERFORM DML TO COVER recalculateOppCurrentMRR CODE. FULL CALCULATION TESTS ARE DONE IN SUBSCRIPTION TEST CODE
        testContract.SBQQ__RenewalOpportunity__c = testRenewalOpp.Id;
        update testContract;

        Test.stopTest();
    }
    
    /**
    * @description recalculateOppCurrentMRRTest_Exceptions - Test recalculateOppCurrentMRR with bad parameters
    */
    public static testMethod void recalculateOppCurrentMRRTest_Exceptions() {
        Test.startTest();

        // EXECUTE METHOD WITH EMPTY PARAMETERS
        ContractHelper.recalculateOppCurrentMRR(new Map<Id, Contract>(), new Map<Id, Contract>());
        // EXECUTE METHOD WITH NULL PARAMETERS
        ContractHelper.recalculateOppCurrentMRR(null, null);

        Test.stopTest();
    }


}