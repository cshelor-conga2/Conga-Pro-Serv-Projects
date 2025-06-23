/**
* @author Conga Services, eredding
* @date 20181214
* @version 1.00
* @description BatchableDelinquentOrdersTest - Test class for the BatchableDelinquentOrders schedulable batch class
*/
@isTest
public with sharing class BatchableDelinquentOrdersTest {
    
    /**
    * @description setup - Setup test data
    */
    @testSetup
    public static void setup() {
        // CREATE TEST PRODUCT AND PRICEBOOK ENTRY
        Id standardPricebookId = Test.getStandardPricebookId();     
        Product2 testProduct = (Product2)TestingUtility.createSObject('Product2', false);
        testProduct.Name = 'Test Product';
        testProduct.ProductCode = 'TP';
        insert testProduct;
        PricebookEntry testEntry = new PricebookEntry(Pricebook2Id = standardPricebookId, Product2Id = testProduct.Id, UnitPrice = 150);
        insert testEntry;

        // CREATE TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account', false);
        insert testAccount;

        // CREATE TEST ORDERS
        List<Order> testOrders = TestingUtility.createSObjectList('Order', false, 4);
        for(Order order : testOrders){
            order.Pricebook2Id = standardPricebookId;
            order.AccountId = testAccount.Id;
            order.Status = 'Draft';
            order.Billing_PartyId__c = null;
            order.Terms__c = 'Due upon Receipt';
        }
        testOrders[0].EffectiveDate = Date.today().addDays(-35);
        testOrders[0].Order_Delinquent__c = false;
        testOrders[1].EffectiveDate = Date.today().addDays(-40);
        testOrders[1].Order_Delinquent__c = false;
        testOrders[2].EffectiveDate = Date.today().addDays(-50);
        testOrders[2].Order_Delinquent__c = true;
        testOrders[3].EffectiveDate = Date.today().addDays(-60);
        testOrders[3].Order_Delinquent__c = true;
        insert testOrders;

        // CREATE TEST ORDER ITEMS
        List<OrderItem> testOrderItems = TestingUtility.createSObjectList('OrderItem', false, 4);
        for(OrderItem orderItem : testOrderItems){
            orderItem.Product2Id = testProduct.Id;
            orderItem.PricebookEntryId = testEntry.Id;
            orderItem.UnitPrice = 150;
            orderItem.Unit_Price_4__c = 150;
            orderItem.Quantity = 1;
        }
        testOrderItems[0].OrderId = testOrders[0].Id;
        testOrderItems[1].OrderId = testOrders[1].Id;
        testOrderItems[2].OrderId = testOrders[2].Id;
        testOrderItems[3].OrderId = testOrders[3].Id;
        insert testOrderItems;

        // CHANGE ORDER STATUSES
        for(Order ord : testOrders){
            ord.Status = 'Sent';
        }
        update testOrders;

        testOrders = [SELECT Id, Order_Delinquent__c FROM Order WHERE Order_Delinquent__c = false AND Status = 'Sent'];
        System.assert(testOrders.size() == 2);
        testOrders = [SELECT Id, Order_Delinquent__c FROM Order WHERE Order_Delinquent__c = true AND Status = 'Sent'];
        System.assert(testOrders.size() == 2);
    }

    /**
    * @description delinquentOrders_Test1 - Test schedulable with delinquent orders to flag
    */
    public static testMethod void delinquentOrders_Test1(){
        // GET TEST ORDERS
        List<Order> testOrders = [SELECT Id FROM Order];
        System.assert(testOrders.size() == 4);

        // SCHEDULE CODE AND STOP TEST TO EXECUTE
        Test.startTest();
        System.schedule('MarkOrdersDelinquent', '0 0 0 1 1 ? 2025', new BatchableDelinquentOrders());
        Database.executeBatch(new BatchableDelinquentOrders());
        Test.stopTest();

        List<Order> delinquentOrders = [SELECT Id FROM Order WHERE Order_Delinquent__c = true];
        System.assert(delinquentOrders.size() == 4);
    }


    /**
    * @description delinquentOrders_Test2 - Test schedulable with orders that are no longer delinquent and should be unflagged
    */
    public static testMethod void delinquentOrders_Test2(){
        // GET ALREADY DELINQUENT ORDERS
        List<Order> testOrders = [SELECT Id FROM Order WHERE Order_Delinquent__c = true];
        System.assert(testOrders.size() == 2);

        // PAY OFF ORDERS
        Order_Payment__c testPayment1 = new Order_Payment__c(InvoiceId__c = testOrders[0].Id, Payment_Received_Date__c = Date.today(), Amount_Applied__c = 150);
        Order_Payment__c testPayment2 = new Order_Payment__c(InvoiceId__c = testOrders[1].Id, Payment_Received_Date__c = Date.today(), Amount_Applied__c = 150);
        insert new List<Order_Payment__c>{ testPayment1, testPayment2 };

        // SCHEDULE CODE AND STOP TEST TO EXECUTE
        Test.startTest();
        System.schedule('MarkOrdersDelinquent', '0 0 0 1 1 ? 2025', new BatchableDelinquentOrders());
        Database.executeBatch(new BatchableDelinquentOrders());
        Test.stopTest();

        List<Order> nonDelinquentOrders = [SELECT Id FROM Order WHERE Order_Delinquent__c = false AND Id IN :testOrders];
        System.assert(nonDelinquentOrders.size() == 2);
    }


}