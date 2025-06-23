/**
* @author ECS, ERedding
* @date 20190522
* @version 1.00
* @description mrrCalculatorAcctAssetTest  - Test class for the mrrCalculatorAcctAsset class
*/
@isTest
public with sharing class mrrCalculatorAcctAssetTest {

    /**
    * @description setup - Setup test data
    */
    @testSetup
    public static void setup() {
        // Test Accounts
        Account testAccount1 = new Account(Name = 'Account 1', Type = 'Customer', IsPreferred__c = false);
        Account testAccount2  = new Account(Name = 'Account 2', Type = 'Customer', IsPreferred__c = false);
        insert new List<Account>{ testAccount1, testAccount2 };

        // Test Product
        Product2 testProduct1 = new Product2(Name = 'Conga Contracts for Salesforce', ProductCode = 'CCFS', IsActive = true, LOB__c = 'Contracts');
        Product2 testProduct2 = new Product2(Name = 'Professional Services', ProductCode = 'PS', IsActive = true, LOB__c = 'Services');
        Product2 testProduct3 = new Product2(Name = 'Workflow', ProductCode = 'WF', IsActive = true, LOB__c = 'Workflow');
        insert new List<Product2>{ testProduct1, testProduct2, testProduct3 };

        // Test Assets
        Asset testAsset = new Asset(Name = 'CCFS', AccountId = testAccount1.Id, Product2Id = testProduct1.Id, Quantity = 1, Start_Date__c = Date.today(),
        						    End_Date__c = Date.today().addDays(365), Type__c = 'Subscription', mrr_Asset_MRR__c = 225.00);
        Asset testAsset2 = new Asset(Name = 'ProServ', AccountId = testAccount2.Id, Product2Id = testProduct2.Id, Quantity = 1, Start_Date__c = Date.today(),
        							 End_Date__c = Date.today().addDays(365), Type__c = 'Subscription', mrr_Asset_MRR__c = 550.00);
        Asset testAsset3 = new Asset(Name = 'Workflow', AccountId = testAccount2.Id, Product2Id = testProduct3.Id, Quantity = 1, Start_Date__c = Date.today(),
        							 End_Date__c = Date.today().addDays(365), Type__c = 'Subscription', mrr_Asset_MRR__c = 75.00);
        insert new List<Asset>{ testAsset, testAsset2, testAsset3 };
	}
	
	/**
	* @description mrrCalculatorAcctAssetCalcTest - 
	*/
	public static testMethod void mrrCalculatorAcctAssetCalcTest() {
		Map<Id, Account> testAccounts = new Map<Id, Account>([SELECT Id FROM Account]);
		System.assert(testAccounts.size() == 2);

		Test.startTest();

		mrrCalculatorAcctAsset.calculateMRR(new Set<Id>(testAccounts.keySet()));

		// UPDATE ACCOUNTS AND TEST FOR CORRECT DATA
		testAccounts = new Map<Id, Account>([SELECT Id, mrr_Contracts_MRR__c, mrr_Services_MRR__c, mrr_Workflow_MRR__c FROM Account]);
		System.assert(testAccounts.values()[0].mrr_Contracts_MRR__c > 0);
		System.assert(testAccounts.values()[1].mrr_Services_MRR__c > 0);
		System.assert(testAccounts.values()[1].mrr_Workflow_MRR__c > 0);

		Test.stopTest();
	}


}