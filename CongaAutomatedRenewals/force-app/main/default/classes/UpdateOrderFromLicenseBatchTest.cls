/**
* @author Conga Services
* @date 20190605
* @version 1.00
* @description UpdateOrderFromLicenseBatchTest  - Test class for the UpdateOrderFromLicenseBatch class
*/
@isTest
public with sharing class UpdateOrderFromLicenseBatchTest {

	/**
	* @description setup - Test data setup method
	*/
	@testSetup
	public static void setup(){
		Id rAcctTypeId;
		for(RecordType rt : [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE IsActive = true AND SobjectType IN ('Account','Case')]){
		 	if(rt.SobjectType == 'Account' && rt.DeveloperName == 'Business_Account' && rAcctTypeId == null){
		 		rAcctTypeId = rt.Id;
			}
		}

		SfLma__Package__c pack = new SfLma__Package__c();
		pack.Name = 'Test Package';
		insert pack;

		sfLma__License__c license = new sfLma__License__c();
		license.CreatedDate = Date.Today(); 
		license.SfLma__Package__c = pack.Id;
		license.SfLma__Subscriber_Org_ID__c = '00D2g0000001234';
		insert license;

		List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);
		testAccounts[0].Name = 'Winterfell Inc.';
		testAccounts[0].RecordTypeId = rAcctTypeId;
		testAccounts[0].mrr_Active_MRR__c = 100.00;
		insert testAccounts;

        List<Opportunity> testOpp = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', true, 1);
        testOpp[0].AccountId = testAccounts[0].Id;
        testOpp[0].Customer_Org_Id__c = '00D2g0000001234';
        insert testOpp;

		Order order = new Order();
		order.RecordTypeId = UtilityClass.getRecordTypesForObject('Order').get('Invoice');
		order.AccountId = testAccounts[0].Id;
        order.OpportunityId = testOpp[0].Id;
        order.Status = 'Draft';
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.EffectiveDate = Date.today();
        order.Type = 'New Business';
        insert order;
	}
	
	
	/**
	* @description testMethod1 - Test Happy Path of code
	*/
	public static testMethod void testMethod1() {
		Test.startTest();

		UpdateOrderFromLicenseBatch sh1 = new UpdateOrderFromLicenseBatch();
        String sch = '0 0 23 * * ?';
        System.schedule('Test Sched', sch, sh1);
        Database.executeBatch(sh1);

		Test.stopTest();

		// GET TEST PACKAGE
		List<SfLma__Package__c> testPackages = [SELECT Id, Name FROM SfLma__Package__c];
		System.assert(testPackages.size() == 1);

		// GET TEST ORDER AND CHECK FOR CORRECT DATA
		List<Order> testOrders = [SELECT Id, Package_Installs__c, Most_Recent_Install_Date_Time__c, Most_Recent_Package_Install__c, Customer_org_id__c FROM Order];
		System.assert(testOrders.size() == 1);
		System.assert(testOrders[0].Customer_org_id__c == '00D2g0000001234');
		System.assert(testOrders[0].Package_Installs__c == testPackages[0].Name);
		System.assert(testOrders[0].Most_Recent_Install_Date_Time__c != null);
		System.assert(testOrders[0].Most_Recent_Package_Install__c == testPackages[0].Name);
	}


}