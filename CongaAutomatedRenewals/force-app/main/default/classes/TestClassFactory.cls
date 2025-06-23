/*

Generic class for creation of test objects

Class:              TestClassFactory
Date:               03/19/2014
Version:            1
Last Updated:       03/19/2014
    *   Started
*/

@isTest
public with sharing class TestClassFactory {

    public static Contact createContact(String fName, String lName, String email)
    {
        Contact result = new Contact();
        result.FirstName = fName;
        result.LastName = lName;
        result.Email = email;
        
        return result;
    }
    
    public static Opportunity createOpportunity(String name, String stage, String salesOpsStatus, Date closeDate)
    {
        Opportunity result = new Opportunity();
        result.Name = name;
        result.StageName = stage;
        result.Sales_Ops_Status__c = salesOpsStatus;
        result.CloseDate = closeDate;

        return result;
    }
    
    public static Account createAccount(String name){
        Account a = new Account();
        a.Name = name;
        
        
        return a;
    }
    
    public static OpportunityLineItem createLineItem(Integer quantity, Decimal salesPrice, Date lineDate, Id priceBookEntryId,Id opportunityId){
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.Description = 'Test';
        oli.PricebookEntryId = priceBookEntryId;
        oli.OpportunityId = opportunityId;
        oli.ServiceDate = lineDate;
        oli.UnitPrice = salesPrice;
        oli.Quantity = quantity;
        
        return oli;
        
    }
    
    public static Product2 createProduct(String productName,String productCode){
        Product2 prod = new Product2();
        prod.Name = productName;
        prod.ProductCode = productCode;
        
        return prod;
    }
    
    public static PricebookEntry createPricebookEntry(Id productId, Id pricebookId, Decimal price){
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pricebookId;
        pbe.Product2Id = productId;
        pbe.UnitPrice = price;
        pbe.IsActive = true;
        
        return pbe;
    }

    public static CHANNEL_ORDERS__Customer__c createcustomer(Id accountId, String name, String orgId, String street, String state, String postalCode, String city, String country){
    CHANNEL_ORDERS__Customer__c customer = new CHANNEL_ORDERS__Customer__c();
        customer.CHANNEL_ORDERS__Account__c = accountId;
        customer.CHANNEL_ORDERS__Customer_Company_Name__c = name;
        customer.CHANNEL_ORDERS__Customer_Org_ID__c = orgId;
        customer.CHANNEL_ORDERS__Customer_Street__c = street;
        customer.CHANNEL_ORDERS__Customer_State__c = state;
        customer.CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = postalCode;
        customer.CHANNEL_ORDERS__Customer_City__c = city;
        customer.CHANNEL_ORDERS__Customer_Country__c = country;
        return customer;
    }

    public static CHANNEL_ORDERS__Service_Order__c createServiceOrder(Id customerId, String orgId, String status, String city, String country, String street, String state, String postalCode){
    CHANNEL_ORDERS__Service_Order__c so = new CHANNEL_ORDERS__Service_Order__c();
        so.CHANNEL_ORDERS__Customer__c = customerId;
        so.CHANNEL_ORDERS__Customer_Org_ID__c = orgId;
        so.CHANNEL_ORDERS__Service_Order_Status__c = status;
        so.CHANNEL_ORDERS__Customer_Billing_City__c = city;
        so.CHANNEL_ORDERS__Customer_Billing_Country__c = country;
        so.CHANNEL_ORDERS__Customer_Billing_Street__c = street;
        so.CHANNEL_ORDERS__Customer_Billing_State__c = state;
        so.CHANNEL_ORDERS__Customer_Billing_Zip_Postal_Code__c = postalCode;
        //so.CHANNEL_ORDERS__Customer_Name__c = a.Name;
        //so.CHANNEL_ORDERS__Related_Opportunity__c = testOpp.Id;
        //so.CHANNEL_ORDERS__Partner_Contract_Rules__c = pct.Id;
        //so.CHANNEL_ORDERS__Order_Type__c = 'Renewal';
        return so;
    }

    public static CHANNEL_ORDERS__Service_Order_Detail__c createServiceOrderDetail(Id serviceOrderId, Id partnerProductId, Id partnerContractId, Decimal quantity){
    CHANNEL_ORDERS__Service_Order_Detail__c soDetail = new CHANNEL_ORDERS__Service_Order_Detail__c();
        soDetail.CHANNEL_ORDERS__Partner_Order__c = serviceOrderId;
        soDetail.CHANNEL_ORDERS__Product_Name__c = partnerProductId;
        soDetail.CHANNEL_ORDERS__pc_Partner_Contract_Term__c = partnerContractId;
        soDetail.CHANNEL_ORDERS__Quantity__c = quantity;
        return soDetail;
    }
}