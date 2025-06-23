/**
* @author CRMCulture
* @date 20171204
* @version 1.00
* @description OrderCreditMemoControllerTest - Test class for the OrderCreditMemoController clas
*/
@isTest
private class OrderCreditMemoControllerTest {

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        Id rAcctTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].RecordTypeId = rAcctTypeId;
        testAccounts[0].mrr_Active_MRR__c = 100.00;
        insert testAccounts;

        SBQQ__Quote__c testQuote = (SBQQ__Quote__c)TestingUtility.createSObject('SBQQ__Quote__c', false, 1);
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;

        List<Opportunity> testOpps = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].SBQQ__PrimaryQuote__c = testQuote.Id;
        insert testOpps;

        List<PS_Project__c> testProjects = (List<PS_Project__c>)TestingUtility.createSObjectList('PS_Project__c', false, 1);
        testProjects[0].AccountId__c = testAccounts[0].Id;
        testProjects[0].Name = 'Sample Project';
        testProjects[0].Rate__c = 1.0;
        testProjects[0].Is_Active__c = true;
        insert testProjects;

        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 2);
        testProducts[0].Name = 'prod1';
        testProducts[0].ProductCode = 'prod1';          
        testProducts[0].LOB__c = 'Services';
        testProducts[0].FY16_Revenue_Type__c = 'Non-Recurring';
        testProducts[1].Name = 'prod2';
        testProducts[1].ProductCode = 'prod2';          
        insert testProducts;

        Id rOrdTypeId = UtilityClass.getRecordTypesForObject('Order').get('Invoice');
        List<Order> testOrders = (List<Order>)TestingUtility.createSObjectList('Order', false, 1);
        testOrders[0].AccountId = testAccounts[0].Id;
        testOrders[0].QB_Invoice_Line_Item_Aggregate_XML__c = null;
        testOrders[0].Pricebook2Id = Test.getStandardPricebookId();
        testOrders[0].EffectiveDate = Date.today();
        testOrders[0].Status = 'Draft';
        testOrders[0].OpportunityId = testOpps[0].Id;
        testOrders[0].RecordTypeId = rOrdTypeId;
        insert testOrders;

        List<PricebookEntry> testPricebookEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', false, 2);
        testPricebookEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[0].Product2Id = testProducts[0].Id;
        testPricebookEntries[0].IsActive = TRUE;
        testPricebookEntries[0].UnitPrice = 1.00;
        testPricebookEntries[1].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[1].Product2Id = testProducts[1].Id;
        testPricebookEntries[1].IsActive = TRUE;
        testPricebookEntries[1].UnitPrice = 1.00;
        insert testPricebookEntries;

        List<OrderItem> testOrderDetails = (List<OrderItem>)TestingUtility.createSObjectList('OrderItem', false, 2);
        testOrderDetails[0].OrderId = testOrders[0].Id;
        testOrderDetails[0].PricebookEntryId = testPricebookEntries[0].Id;
        testOrderDetails[0].ProjectId__c = testProjects[0].Id;
        testOrderDetails[0].Quantity = 1;
        testOrderDetails[0].UnitPrice = 1.00;
        testOrderDetails[1].OrderId = testOrders[0].Id;
        testOrderDetails[1].PricebookEntryId = testPricebookEntries[1].Id;
        testOrderDetails[1].ProjectId__c = testProjects[0].Id;
        testOrderDetails[1].Quantity = 1;
        testOrderDetails[1].UnitPrice = 1.00;
        insert testOrderDetails;
    }

    /**
    * @description testOrderCreditMemo - 
    */
    static testmethod void testOrderCreditMemo() {
        // GET TEST ORDER
        List<Order> testOrders = [SELECT Id FROM Order];
        System.assert(testOrders.size() == 1);

        // Implement test code
        ApexPages.StandardController sc = new ApexPages.StandardController(testOrders[0]);
        OrderCreditMemoController cntrl = new OrderCreditMemoController(sc);

        Test.startTest();

        PageReference pageAutoRun = cntrl.AutoRun();

        Test.stopTest();
    }


}