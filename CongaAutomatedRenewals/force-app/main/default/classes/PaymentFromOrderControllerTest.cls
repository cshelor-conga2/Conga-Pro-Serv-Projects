/**
* @author ECS, ERedding
* @date 20190603
* @version 1.00
* @description PaymentFromOrderControllerTest  - Test class for the PaymentFromOrderController class
*/
@isTest
public with sharing class PaymentFromOrderControllerTest {

	/**
	* @description setup - Test data setup method
	*/
	@testSetup
	public static void setup(){
        Account testAcct = new Account();
        testAcct.Name = 'Test Account';
        testAcct.BillingStreet = '123 Main';
        testAcct.BillingCity = 'Broomfield';
        testAcct.BillingState = 'CO';
        testAcct.BillingPostalCode = '80021';
        testAcct.BillingCountry = 'US';
        insert testAcct;

        Opportunity testOpp = (Opportunity)TestingUtility.createSObject('Opportunity', true, 1);
        testOpp.AccountId = testAcct.Id;
        insert testOpp;

        Order invoice = new Order();
        invoice.RecordTypeId = UtilityClass.getRecordTypesForObject('Order').get('Invoice');
        invoice.EffectiveDate = System.today();
        invoice.AccountId = testAcct.Id;
        invoice.OpportunityId = testOpp.Id;
        invoice.Status = 'Draft';
        invoice.Pricebook2Id = Test.getStandardPricebookId();
        insert invoice;
	}
	
	/**
	* @description testController - Test controller methods
	*/
	public static testMethod void testController() {
		// GET TEST CASE
		List<Order> testOrders = [SELECT Id FROM Order];
		System.assert(testOrders.size() == 1);

		PageReference vfPage = Page.PaymentFromOrderPage;
		vfPage.getParameters().put('id', testOrders[0].Id);
		Test.setCurrentPage(vfPage);

		ApexPages.StandardSetController sc = new ApexPages.StandardSetController(testOrders);
		PaymentFromOrderController ctrl = new PaymentFromOrderController(sc);

		Test.startTest();

		ctrl.AutoRun();
		List<Order_Payment__c> payments = [SELECT Id, InvoiceId__c FROM Order_Payment__c];
		System.assert(payments.size() == 1);
		System.assert(payments[0].InvoiceId__c == testOrders[0].Id);

		Test.stopTest();
	}


}