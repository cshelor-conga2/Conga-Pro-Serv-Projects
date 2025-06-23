/**
* @author Conga Services
* @date 20181004
* @version 1.00
* @description AssetHelperTest - Test class for the AssetHelper class
*/
@isTest
public with sharing class AssetHelperTest {

	/**
	* @description setup - Setup test data
	*/
	@testSetup
	public static void setup() {
        // Test Accounts
        Account testAccount1 = new Account(Name = 'Account 1', Type = 'Prospect', IsPreferred__c = false);
        Account testAccount2  = new Account(Name = 'Account 2', Type = 'Prospect', IsPreferred__c = false);
        Account testAccount3  = new Account(Name = 'Account 3', Type = 'Customer - Former', IsPreferred__c = false);
        insert new List<Account>{ testAccount1, testAccount2, testAccount3 };

        // Test Product
        Product2 testProduct = new Product2(Name = 'Preferred Support', ProductCode = 'PS-01', IsActive = true);
        insert testProduct;

        // Test Pricebook Entry
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry testEntry = new PricebookEntry(Product2Id  = testProduct.Id, Pricebook2Id = pricebookId, UnitPrice = 1, IsActive = true);
        insert testEntry;

        // Test Opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opp', AccountId = testAccount2.Id, Type = 'New Business', LeadSource = 'Inbound', StageName = 'Qualify', CloseDate = Date.today().addDays(60));
        insert testOpportunity;

        // Test Opportunity Line Item
        OpportunityLineItem testOpportunityItem = new OpportunityLineItem(OpportunityId = testOpportunity.Id, PricebookEntryId = testEntry.Id, Quantity = 1, UnitPrice = 5);
        insert testOpportunityItem;
}

	/**
	* @description updateAccountIsPreferredTest - Test the updateAccountIsPreferred Asset trigger method
	*/
    public static testmethod void updateAccountIsPreferredTest() {
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id, IsPreferred__c FROM Account];
        System.assert(testAccounts.size() == 3);
        System.assert(testAccounts[0].IsPreferred__c == false);

        // GET TEST PRODUCT
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 1);

        Test.startTest();

        // TEST TRIGGER METHOD WITH A NEW PREFERRED SUPPORT ASSET
        Asset testAsset = new Asset(Name = 'Preferred Support', AccountId = testAccounts[0].Id, Product2Id = testProducts[0].Id, Quantity = 1, Start_Date__c = Date.today(), 
                                    End_Date__c = Date.today().addDays(365));
        Asset testAsset2 = new Asset(Name = 'Preferred Support For Conga Invoicing for Salesforce Billing', AccountId = testAccounts[1].Id, Product2Id = testProducts[0].Id, Quantity = 1, 
                                    Start_Date__c = Date.today(), End_Date__c = Date.today().addDays(365));
        insert new List<Asset>{ testAsset, testAsset2 };

        Test.stopTest();

        // TEST THAT THE ACCOUNTS IS PREFERRED FIELD IS NOW SET TO TRUE AFTER CREATING A NEW PREFERED SUPPORT ASSET
        testAccounts = [SELECT Id, IsPreferred__c FROM Account];
        System.assert(testAccounts[0].IsPreferred__c == true);
        System.assert(testAccounts[1].IsPreferred__c == true);
	}

    /**
    * @description updateAccountIsPreferredTest_Exceptions - Test the updateAccountIsPreferred Asset trigger method using empty and null parameters
    */
    public static testmethod void updateAccountIsPreferredTest_Exceptions() {
        // EXECUTE METHOD WITH EMPTY PARAMETERS
        AssetHelper.updateAccountIsPreferred(new List<Asset>());
        // EXECUTE METHOD WITH NULL PARAMETERS
        AssetHelper.updateAccountIsPreferred(null);
    }

	/**
	* @description updateOppLineItemTest - Test the updateOppLineItem Asset trigger method
	*/
    public static testmethod void updateOppLineItemTest() {
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 3);

        // GET TEST PRODUCT
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 1);

        // GET OPP ITEM
        List<OpportunityLineItem> testOppItems = [SELECT Id FROM OpportunityLineItem];
        System.assert(testOppItems.size() == 1);

        Test.startTest();

        // TEST TRIGGER METHOD WITH A NEW PREFERRED SUPPORT ASSET
        Asset testAsset = new Asset(Name = 'Test Asset', AccountId = testAccounts[0].Id, Product2Id = testProducts[0].Id, OLI_Id__c = testOppItems[0].Id, Quantity = 1, 
                                    Start_Date__c = Date.today(), End_Date__c = Date.today().addDays(365));
        insert testAsset;

        Test.stopTest();

        testOppItems = [SELECT Id, Asset__c FROM OpportunityLineItem];
        System.assert(testOppItems[0].Asset__c == testAsset.Id);
	}

    /**
    * @description updateOppLineItemTest_Exceptions - Test the updateOppLineItem Asset trigger method using empty and null parameters
    */
    public static testmethod void updateOppLineItemTest_Exceptions() {
        // EXECUTE METHOD WITH EMPTY PARAMETERS
        AssetHelper.updateOppLineItem(new List<Asset>());
        // EXECUTE METHOD WITH NULL PARAMETERS
        AssetHelper.updateOppLineItem(null);
    }

    /**
    * @description updateLeapYearFlagTest - Test the updateLeapYearFlag Asset trigger method
    */
    public static testmethod void updateLeapYearFlagTest(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 3);

        // GET TEST PRODUCT
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 1);

        // GET OPP ITEM
        List<OpportunityLineItem> testOppItems = [SELECT Id FROM OpportunityLineItem];
        System.assert(testOppItems.size() == 1);

        // TEST TRIGGER METHOD WITH A NEW PREFERRED SUPPORT ASSET
        Asset testAsset = new Asset(Name = 'Test Asset', AccountId = testAccounts[0].Id, Product2Id = testProducts[0].Id, Quantity = 1, 
                                    Start_Date__c = Date.newInstance(2018,1,1), End_Date__c = Date.newInstance(2020,2,28));
        insert testAsset;

        Test.startTest();

        testAsset = [SELECT Id, Start_Date__c, End_Date__c, Has_Leap_Year_Day__c FROM Asset WHERE Id = :testAsset.Id];
        System.assert(testAsset.Has_Leap_Year_Day__c == false); // START AND END DATES DONT YET SPAN A LEAP YEAR

        // UPDATE END DATE TO INCLUDE A FEB 29TH LEAP YEAR DAY
        testAsset.End_Date__c = Date.newInstance(2020,3,1);
        update testAsset;

        testAsset = [SELECT Id, Start_Date__c, End_Date__c, Has_Leap_Year_Day__c FROM Asset WHERE Id = :testAsset.Id];
        System.assert(testAsset.Has_Leap_Year_Day__c == true); // START AND END DATES NOW INCLUDE A FEB 29TH LEAP YEAR DAY

        // UPDATE END DATE TO INCLUDE A FEB 29TH LEAP YEAR DAY
        testAsset.End_Date__c = Date.newInstance(2030,12,31);
        update testAsset;

        testAsset = [SELECT Id, Start_Date__c, End_Date__c, Has_Leap_Year_Day__c FROM Asset WHERE Id = :testAsset.Id];
        System.assert(testAsset.Has_Leap_Year_Day__c == true); // START AND END DATES SPAN MULTIPLE LEAP YEARS

        Test.stopTest();
    }

    /**
    * @description updateLeapYearFlagTest_Exceptions - Test the updateLeapYearFlag Asset trigger method using empty and null parameters
    */
    public static testmethod void updateLeapYearFlagTest_Exceptions(){
        // EXECUTE METHOD WITH EMPTY PARAMETERS
        AssetHelper.updateLeapYearFlag(new List<Asset>(), new Map<Id, Asset>());
        // EXECUTE METHOD WITH NULL PARAMETERS
        AssetHelper.updateLeapYearFlag(null, null);
    }

    /**
    * @description calculateAccountTypeTest_InsertUpdate - Tests Insert/Update portion of the calculateAccountType method
    */   
    public static testmethod void calculateAccountTypeTest_InsertUpdate() {
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id FROM Account];
        System.assert(testAccounts.size() == 3);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 1);

        List<Asset> assets = new List<Asset>();
        // ACTIVE
        assets.add(new Asset(Name = 'Asset 1', AccountId = testAccounts[0].Id, Product2Id = testProducts[0].Id, Quantity = 1, Start_Date__c = Date.newInstance(Date.today().year(),1,1), 
                             End_Date__c = Date.newInstance(Date.today().year(),12,31), Type__c ='Subscription'));
        // EXPIRED ASSETS
        assets.add(new Asset(Name = 'Asset 2', AccountId = testAccounts[1].Id, Product2Id = testProducts[0].Id, Quantity = 1, Start_Date__c = Date.newInstance(Date.today().year()-1,1,1),
                             End_Date__c = Date.newInstance(Date.today().year()-1,12,31), Type__c = 'Subscription'));

        Test.startTest();
        insert assets;    
        Test.stopTest();

        // GET ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, Type FROM Account];
        System.assert(testAccounts[0].Type == 'Customer');
        System.assert(testAccounts[1].Type == 'Customer - Former');
    }

    /**
    * @description calculateAccountTypeTest_Delete - Tests Delete portion of the calculateAccountType method
    */   
    public static testmethod void calculateAccountTypeTest_Delete() {
        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account', Type = 'Customer');
        insert testAccount;

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 1);

        // ACTIVE
        Asset testAsset = new Asset(Name = 'Asset 1', AccountId = testAccount.Id, Product2Id = testProducts[0].Id, Quantity = 1, Start_Date__c = Date.newInstance(Date.today().year(),1,1), 
                                    End_Date__c = Date.newInstance(Date.today().year(),12,31), Type__c ='Subscription');
        insert testAsset;

        Test.startTest();
        delete testAsset;
        Test.stopTest();

        // GET ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccount = [SELECT Id, Type FROM Account WHERE Id = :testAccount.Id];
        System.assert(testAccount.Type == 'Prospect');
    }

    /**
    * @description updateCxQDateOnParentAcctTest - Test method for the AssetHelper.updateCxQDateOnParentAcct method
    */
    public static testmethod void updateCxQDateOnParentAcctTest(){
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, CxG_Asset_Start_Date__c FROM Account];      
        System.assert(testAccounts.size() == 3);
        System.assert(testAccounts[0].CxG_Asset_Start_Date__c == null);
        System.assert(testAccounts[1].CxG_Asset_Start_Date__c == null);
        System.assert(testAccounts[2].CxG_Asset_Start_Date__c == null);

        // CREATE TEST PRODUCTS
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', true, 3);
        testProducts[0].Name = 'Regular Test Product';
        testProducts[0].ProductCode = 'REG1';
        testProducts[0].IsActive = true;
        testProducts[1].Name = 'CxG Test Product 1';
        testProducts[1].ProductCode = 'CXG1';
        testProducts[1].IsActive = true;
        testProducts[2].Name = 'CxG Test Product 2';
        testProducts[2].ProductCode = 'CXG2';
        testProducts[2].IsActive = true;
        insert testProducts;

        // SET TEST PRODUCTS AS APPLICABLE CXG PRODUCTS
        AssetHelper.CXGProductIds = new Set<Id>{ testProducts[1].Id, testProducts[2].Id };

        // CREATE TEST ASSETS
        List<Asset> testAssets = (List<Asset>)TestingUtility.createSObjectList('Asset', true, 3);
        testAssets[0].Name = 'Regular Asset';
        testAssets[0].AccountId = testAccounts[2].Id;
        testAssets[0].Product2Id = testProducts[0].Id;
        testAssets[0].Start_Date__c = Date.today();
        testAssets[0].End_Date__c = Date.today().addDays(180);
        //
        testAssets[1].Name = 'CxG Asset 1';
        testAssets[1].AccountId = testAccounts[2].Id;
        testAssets[1].Product2Id = testProducts[1].Id;
        testAssets[1].Start_Date__c = Date.today();
        testAssets[1].End_Date__c = Date.today().addDays(180);
        //
        testAssets[2].Name = 'CxG Asset 2';
        testAssets[2].AccountId = testAccounts[2].Id;
        testAssets[2].Product2Id = testProducts[2].Id;
        testAssets[2].Start_Date__c = Date.today().addDays(30);
        testAssets[2].End_Date__c = Date.today().addDays(210);
        insert testAssets;

        Test.startTest();

        // RELOAD ACCOUNT AND TEST FOR CORRECT DATA
        testAccounts = [SELECT Id, CxG_Asset_Start_Date__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[2].CxG_Asset_Start_Date__c == testAssets[1].Start_Date__c);

        // DELETE ASSET AND RETEST
        delete testAssets[1];
        testAccounts = [SELECT Id, CxG_Asset_Start_Date__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[2].CxG_Asset_Start_Date__c == testAssets[2].Start_Date__c);

        // UPDATE ASSET AND RETEST
        testAssets[2].Start_Date__c = Date.today();
        update testAssets[2];
        testAccounts = [SELECT Id, CxG_Asset_Start_Date__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[2].CxG_Asset_Start_Date__c == testAssets[2].Start_Date__c);

        // DELETE REGULAR ASSET AND RETEST
        delete testAssets[0];
        testAccounts = [SELECT Id, CxG_Asset_Start_Date__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[2].CxG_Asset_Start_Date__c == testAssets[2].Start_Date__c);

        // DELETE LAST ASSET AND RETEST
        delete testAssets[2];
        testAccounts = [SELECT Id, CxG_Asset_Start_Date__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[2].CxG_Asset_Start_Date__c == null);

        Test.stopTest();
    }


}