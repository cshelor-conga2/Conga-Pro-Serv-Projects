/**
* @author CRMCulture
* @date 20160524
* @version 1.00
* @description PaymentFromOrderController - Controller for the PaymentFromOrderPage VF Page
*/
public with sharing class PaymentFromOrderController {
    public List<Order> Invoices {get;set;}
    public pymt__PaymentX__c BindPmt {get;set;}
    public Order_Payment__c BindOrdPmt {get;set;}

    /**
    * @description PaymentFromOrderController - Constructor
    * @param ApexPages.StandardSetController ctrl
    */
    public PaymentFromOrderController(ApexPages.StandardSetController ctrl) {
        BindPmt = new pymt__PaymentX__c();
        BindOrdPmt = new Order_Payment__c();
        String key = ApexPages.currentPage().getParameters().get('id');
        Invoices = new List<Order>();
        Invoices = [SELECT Id,OrderNumber,Amount_DueFx__c FROM Order WHERE Id = :key];
        BindPmt.pymt__Amount__c = Invoices[0].Amount_DueFx__c;
        BindPmt.pymt__Date__c = System.today();
    }

    /**
    * @description AutoRun - 
    * @return PageReference
    */
    public PageReference AutoRun(){
        PageReference page = null;
        BindPmt.Name = Invoices[0].OrderNumber + ' ' + System.today().format();
        insert BindPmt;

        Order_Payment__c ordPay = new Order_Payment__c();
        ordPay.InvoiceId__c = Invoices[0].Id;
        ordPay.PaymentId__c = BindPmt.Id;
        ordPay.Amount_Applied__c = BindPmt.pymt__Amount__c;
        ordPay.Payment_Type__c = BindPmt.pymt__Payment_Type__c;
        ordPay.Card_Type__c = BindPmt.pymt__Card_Type__c;
        ordPay.Payment_Received_Date__c = BindPmt.pymt__Date__c;
        ordPay.Comments__c = BindOrdPmt.Comments__c;
        insert ordPay;

        page = new PageReference('/' + Invoices[0].Id);
        page.setRedirect(true);
        return page;
    }


}