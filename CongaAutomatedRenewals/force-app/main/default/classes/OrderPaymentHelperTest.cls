/** 
* @author Conga Services
* @date 20181023
* @version 1.0
* @description OrderPaymentHelperTest - Test class for the OrderPaymentHelper class
*/
@isTest
public with sharing class OrderPaymentHelperTest {

    /**
    * @description rollUpAppliedTest - Test rollUpApplied Happy Path of code
    */
    public static testMethod void rollUpAppliedTest(){
        RecordType inv = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true AND DeveloperName = 'Invoice'];
        RecordType creditMemo = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND IsActive = true AND DeveloperName = 'Credit_Memo'];
        Id pbId = Test.getStandardPricebookId();

        AVA_SFCORE__TaxNowSetting__c testTaxSetting = new AVA_SFCORE__TaxNowSetting__c(
            Name = 'AvaTax',
            AVA_SFCORE__Active_Setting__c = TRUE,
            AVA_SFCORE__TriggerLimit__c = 0,
            AVA_SFCORE__Service_URL__c = 'https://development.avalara.net/',
            AVA_SFCORE__Origin_Street__c = '385 Interlocken Crescent Suite 600',
            AVA_SFCORE__Origin_City__c = 'Broomfield',
            AVA_SFCORE__Origin_State__c = 'CO',
            AVA_SFCORE__Origin_Postal_Code__c = '80021',
            AVA_SFCORE__Origin_Country__c = 'US',
            AVA_SFCORE__Enable_Tax_Calculation__c = FALSE, 
            AVA_SFCORE__Enable_Address_Validation__c = FALSE,
            AVA_SFCORE__Automatic_Tax_Calculation__c = FALSE
        );
        insert testTaxSetting;

        Account a = new Account();
        a.Name = 'Test Account';
        insert a;

        Product2 p2 = new Product2();
        p2.Name = 'Test Product';
        p2.ProductCode = 'TP';
        insert p2;

        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pbId;
        pbe.Product2Id = p2.Id;
        pbe.IsActive = true;
        pbe.UnitPrice = 1000;
        insert pbe;

        Order invoice = new Order();
        invoice.RecordTypeId = inv.Id;
        invoice.EffectiveDate = System.today();
        invoice.AccountId = a.Id;
        invoice.Status = 'Draft';
        invoice.Pricebook2Id = pbId;
        insert invoice;

        Order cMemo = new Order();
        cMemo.RecordTypeId = creditMemo.Id;
        cMemo.EffectiveDate = System.today();
        cMemo.AccountId = a.Id;
        cMemo.Status = 'Draft';
        cMemo.Pricebook2Id = pbId;
        insert cMemo;

        OrderItem oi = new OrderItem();
        oi.PricebookEntryId = pbe.Id;
        oi.OrderId = invoice.Id;
        oi.Quantity = 5;
        oi.UnitPrice = pbe.UnitPrice;
        oi.Product_Start_Date__c = Date.today();
        oi.Product_End_Date__c = Date.today().addYears(1);
        insert oi;

        OrderItem oi2 = new OrderItem();
        oi2.PricebookEntryId = pbe.Id;
        oi2.OrderId = cMemo.Id;
        oi2.Quantity = 5;
        oi2.UnitPrice = pbe.UnitPrice;
        oi2.Product_Start_Date__c = Date.today();
        oi2.Product_End_Date__c = Date.today().addYears(1);
        insert oi2;

        Test.startTest();

        Order_Payment__c payment = new Order_Payment__c();
        payment.InvoiceId__c = invoice.Id;
        payment.Credit_MemoId__c = cMemo.Id;
        payment.Amount_Applied__c = 4000;
        insert payment;

        Order_Payment__c payment2 = new Order_Payment__c();
        payment2.InvoiceId__c = invoice.Id;
        payment2.Credit_MemoId__c = cMemo.Id;
        payment2.Amount_Applied__c = 2000;
        insert payment2;

        List<Order> ords = [SELECT Id, Amount_Applied_CM__c FROM Order WHERE Id = :cMemo.Id];
        System.assert(ords.size() == 1);
        System.assert(ords[0].Amount_Applied_CM__c == 6000);

        payment2.Amount_Applied__c = 4000;
        update payment2;
        ords = [SELECT Id, Amount_Applied_CM__c FROM Order WHERE Id = :cMemo.Id];
        System.assert(ords.size() == 1);
        System.assert(ords[0].Amount_Applied_CM__c == 8000); 

        Test.stopTest();
    }


}