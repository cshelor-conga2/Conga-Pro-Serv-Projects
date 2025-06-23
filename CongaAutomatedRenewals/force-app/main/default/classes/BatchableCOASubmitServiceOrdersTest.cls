/**
* @author Conga Services
* @date 
* @version 1.00
* @description BatchableCOASubmitServiceOrdersTest  - Test class for the [Name of class being tested] class
*/
@isTest
public with sharing class BatchableCOASubmitServiceOrdersTest {
	/**
	* @description setup - Test data setup method
	*/
	@testSetup
	public static void setup(){
		// CREATE TEST COA SETTINGS
        CS_COA_Settings__c testCOACustomSetting = new CS_COA_Settings__c();
        testCOACustomSetting.Name = 'COA Setting';
        testCOACustomSetting.Default_Sales_Order_Status__c = 'Draft';
        insert testCOACustomSetting;

        // CREATE TEST ACCOUNT
        Account testAccount = (Account)TestingUtility.createSObject('Account', false);
        testAccount.Name = 'Test COA Account';
        testAccount.BillingState = 'Colorado';        
        testAccount.BillingCountry = 'United States';
        insert testAccount;

		// CREATE TEST COA CUSTOMER
        CHANNEL_ORDERS__Customer__c testCOACustomer = (CHANNEL_ORDERS__Customer__c)TestingUtility.createSObject('CHANNEL_ORDERS__Customer__c', false);
        testCOACustomer.CHANNEL_ORDERS__Account__c = testAccount.Id;
        testCOACustomer.CHANNEL_ORDERS__Customer_Company_Name__c = testAccount.Name;
        testCOACustomer.CHANNEL_ORDERS__Customer_Org_ID__c = '00D2g0000008alc'; // FAKE ID
        testCOACustomer.CHANNEL_ORDERS__Customer_State__c = 'Colorado';
        testCOACustomer.CHANNEL_ORDERS__Customer_Country__c = 'United States';
        insert testCOACustomer;

        // CREATE TEST CONTRACT TERMS
		CHANNEL_ORDERS__Partner_Contract_Terms__c testContractTerms = (CHANNEL_ORDERS__Partner_Contract_Terms__c)TestingUtility.createSObject('CHANNEL_ORDERS__Partner_Contract_Terms__c', false);
        testContractTerms.Name = 'Test Terms';
        testContractTerms.CHANNEL_ORDERS__Partner_API_Key__c = 'asasasaa';
        testContractTerms.CHANNEL_ORDERS__Partner_Contract_Term_External_ID__c = '123456abc';
        insert testContractTerms;

		// CREATE TEST PRODUCT
		CHANNEL_ORDERS__Partner_Product_Catalog__c testPartnerProduct = (CHANNEL_ORDERS__Partner_Product_Catalog__c)TestingUtility.createSObject('CHANNEL_ORDERS__Partner_Product_Catalog__c', false);
        testPartnerProduct.Name = 'Test';
        testPartnerProduct.CHANNEL_ORDERS__Product_ID__c = 'Conga Test';
        testPartnerProduct.CHANNEL_ORDERS__Partner_Contract_Terms__c = testContractTerms.Id;
        testPartnerProduct.CHANNEL_ORDERS__Pricing_Type__c = 'NPR';
        testPartnerProduct.CHANNEL_ORDERS__Partner_Application_Name__c = 'TEST';
        insert testPartnerProduct;

		// CREATE TEST SERVICE ORDER
		CHANNEL_ORDERS__Service_Order__c testServiceOrder = (CHANNEL_ORDERS__Service_Order__c)TestingUtility.createSObject('CHANNEL_ORDERS__Service_Order__c', false);
		testServiceOrder.CHANNEL_ORDERS__Created_with_new_COA__c = true;
		testServiceOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c = testContractTerms.Id;
		testServiceOrder.CHANNEL_ORDERS__Customer__c = testCOACustomer.Id;
		testServiceOrder.CHANNEL_ORDERS__Customer_Billing_State__c = 'Colorado';
		testServiceOrder.CHANNEL_ORDERS__Customer_Billing_Country__c = 'United States';
		testServiceOrder.CHANNEL_ORDERS__Customer_Shipping_State__c = 'Colorado';
		testServiceOrder.CHANNEL_ORDERS__Customer_Shipping_Country__c = 'United States';
		testServiceOrder.CHANNEL_ORDERS__Date_Partner_Received_Customer_Order__c = Date.today().addDays(-7);
		testServiceOrder.CHANNEL_ORDERS__Customer_Org_ID__c = '00D2g0000008alc'; // FAKE ID
		testServiceOrder.CHANNEL_ORDERS__I_certify__c = 'Yes';
		testServiceOrder.CHANNEL_ORDERS__Order_Type__c = 'Add-On';
		testServiceOrder.CHANNEL_ORDERS__Service_Start_Date__c = Date.today();
		testServiceOrder.CHANNEL_ORDERS__Date_Customer_Accepted_SFDC_Svc_Agrmnt__c = Date.today();
		insert testServiceOrder;

		// CREATE TEST SERVICE ORDER DETAIL
		CHANNEL_ORDERS__Service_Order_Detail__c testServiceOrderDetail = (CHANNEL_ORDERS__Service_Order_Detail__c)TestingUtility.createSObject('CHANNEL_ORDERS__Service_Order_Detail__c', false);
		testServiceOrderDetail.CHANNEL_ORDERS__Application__c = 'Test';
		testServiceOrderDetail.CHANNEL_ORDERS__Customer_Price_Per_Month__c = 250.00;
		testServiceOrderDetail.CHANNEL_ORDERS__Partner_Order__c = testServiceOrder.Id;
		testServiceOrderDetail.CHANNEL_ORDERS__Product_Line_Description__c = 'Test Product Line';
		testServiceOrderDetail.CHANNEL_ORDERS__Quantity__c = 5;
		testServiceOrderDetail.CHANNEL_ORDERS__Product_Name__c = testPartnerProduct.Id;
		testServiceOrderDetail.CHANNEL_ORDERS__pc_Partner_Contract_Term__c = testContractTerms.Id;
		insert testServiceOrderDetail;
	}
	
	/**
	* @description testMethod1 - Test Happy Path of code
	*/
	public static testMethod void testBatchable() {
		// GET TEST SERVICE ORDERS
		Map<Id, CHANNEL_ORDERS__Service_Order__c> testServiceOrders = new Map<Id, CHANNEL_ORDERS__Service_Order__c>([SELECT Id FROM CHANNEL_ORDERS__Service_Order__c]);
		System.assert(testServiceOrders.size() == 1);

		Test.startTest();

		Database.executeBatch(new BatchableCOASubmitServiceOrders(testServiceOrders.keySet()), 5);

		Test.stopTest();
	}


}