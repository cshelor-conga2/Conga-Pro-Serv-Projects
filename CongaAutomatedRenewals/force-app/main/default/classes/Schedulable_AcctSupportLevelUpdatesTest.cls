/**
* @author Conga Services
* @date 20180828
* @version 1.00
* @description Schedulable_AcctSupportLevelUpdatesTest  - Test class for the Schedulable_AcctSupportLevelUpdates class
*/
@isTest
public without sharing class Schedulable_AcctSupportLevelUpdatesTest {

    // CREATE TEST META
    public static Map<Id, String> TestSupportLevelAssetMetaMap { 
    get {
        if(TestSupportLevelAssetMetaMap == null){
            List<Product2> testProducts = [SELECT Id, Name, ProductCode FROM Product2];
            return TestSupportLevelAssetMetaMap = Schedulable_AcctSupportLevelUpdatesTest.createTestMeta(testProducts[0].Id, 'Basic', testProducts[1].Id, 'Premium');
        }
        return TestSupportLevelAssetMetaMap;
    } set; }    

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        TriggerHelper.OverrideAllSettings(true, false); // DISABLE ALL OTHER TRIGGERS

        List<Account> testAccount = TestingUtility.createSObjectList('Account', true, 1);
        testAccount[0].Support_Level__c = '';
        insert testAccount;

        List<Product2> testProducts = TestingUtility.createSObjectList('Product2', true, 2);
        testProducts[0].Name = 'Basic Support';
        testProducts[0].ProductCode = 'Basic';
        testProducts[1].Name = 'Premium Support';
        testProducts[1].ProductCode = 'Premium';
        insert testProducts;

        List<Salesforce_Org__c> testSalesforceOrg = TestingUtility.createSObjectList('Salesforce_Org__c', true, 1);
        testSalesforceOrg[0].Account__c = testAccount[0].Id;
        testSalesforceOrg[0].Org_Type__c = 'Production';
        testSalesforceOrg[0].Conga_Account_Suspension_Date__c = null;
        insert testSalesforceOrg;

        TriggerHelper.OverrideAllSettings(false, false); // REENABLE TRIGGERS
    }

    /**
    * @description AcctSupportLevelUpdatesTest1_FirstAsset - Test functionality on an Account's first asset
    */
    public static testMethod void AcctSupportLevelUpdatesTest1_FirstAsset() {
        // GET TEST ACCOUNT
        List<Account> testAccount = [SELECT Id FROM Account];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id, Name, ProductCode FROM Product2];
        System.assert(testProducts != null);
        System.assert(testProducts.size() == 2);

        // CREATE THE ACCOUNTS FIRST SUPPORT SUB
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount[0].Id, SBQQ__Product__c = testProducts[0].Id, SBQQ__Quantity__c = 1,
                                    SBQQ__SubscriptionStartDate__c = Date.today().addDays(-10), SBQQ__SubscriptionEndDate__c = Date.today().addDays(180));
        insert testSub;

        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        subList = [SELECT Id, SBQQ__Account__c, SBQQ__Account__r.Support_Level__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Subscription__c];

        // EXECUTE SCHEDUABLE
        Schedulable_AcctSupportLevelUpdates testSch = new Schedulable_AcctSupportLevelUpdates();

        Test.startTest();
        System.schedule('Schedulable_AcctSupportLevelUpdatesTest', '0 0 23 * * ?', testSch);
        testSch.execute(null, subList);
        Test.stopTest();

        // GET FOR CORRECTLY UPDATED ACCOUNT SUPPORT LEVEL FIELD
        testAccount = [SELECT Id, Support_Level__c FROM Account WHERE Id IN :testAccount];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        System.assert(testAccount[0].Support_Level__c == 'Basic');
    }
    
    /**
    * @description AcctSupportLevelUpdatesTest2_ReplacementAsset - Test functionality on an Account's new asset replacing an expiring one.
    */
    public static testMethod void AcctSupportLevelUpdatesTest2_ReplacementAsset() {
        // GET TEST ACCOUNT
        List<Account> testAccount = [SELECT Id FROM Account];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        testAccount[0].Support_Level__c = 'Basic';
        update testAccount;

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id, Name, ProductCode FROM Product2];
        System.assert(testProducts != null);
        System.assert(testProducts.size() == 2);

        // CREATE THE ACCOUNTS FIRST SUPPORT SUB
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount[0].Id, SBQQ__Product__c = testProducts[0].Id, SBQQ__Quantity__c = 1,
                                    SBQQ__SubscriptionStartDate__c = Date.today().addDays(-180), SBQQ__SubscriptionEndDate__c = Date.today().addDays(-11));
        
        SBQQ__Subscription__c testSub2 = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount[0].Id, SBQQ__Product__c = testProducts[1].Id, SBQQ__Quantity__c = 1,
                                    SBQQ__SubscriptionStartDate__c = Date.today().addDays(-10), SBQQ__SubscriptionEndDate__c = Date.today().addDays(180));                              
        insert new List<SBQQ__Subscription__c>{testSub,testSub2};

        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        subList = [SELECT Id, SBQQ__Account__c, SBQQ__Account__r.Support_Level__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Subscription__c];   

        // EXECUTE SCHEDUABLE
        Schedulable_AcctSupportLevelUpdates testSch = new Schedulable_AcctSupportLevelUpdates();

        Test.startTest();
        System.schedule('Schedulable_AcctSupportLevelUpdatesTest', '0 0 0 1 1 ? 2025', testSch);
        testSch.execute(null, subList);
        Test.stopTest();

        // GET FOR CORRECTLY UPDATED ACCOUNT SUPPORT LEVEL FIELD
        testAccount = [SELECT Id, Support_Level__c FROM Account WHERE Id IN :testAccount];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        System.assert(testAccount[0].Support_Level__c == 'Premium');
    }

    /**
    * @description AcctSupportLevelUpdatesTest4_ExpiredAsset - Test functionality on an Account whose support asset is not expired
    */
    public static testMethod void AcctSupportLevelUpdatesTest4_ExpiredAsset() {
        // GET TEST ACCOUNT
        List<Account> testAccount = [SELECT Id FROM Account];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        testAccount[0].Support_Level__c = 'Premium';
        update testAccount;

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id, Name, ProductCode FROM Product2];
        System.assert(testProducts != null);
        System.assert(testProducts.size() == 2);

        // CREATE THE ACCOUNTS FIRST SUPPORT SUB
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount[0].Id, SBQQ__Product__c = testProducts[1].Id, SBQQ__Quantity__c = 1,
                                    SBQQ__SubscriptionStartDate__c = Date.today().addDays(-180), SBQQ__SubscriptionEndDate__c = Date.today().addDays(-2));
        insert testSub;

        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        subList = [SELECT Id, SBQQ__Account__c, SBQQ__Account__r.Support_Level__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Subscription__c];
        
        // EXECUTE SCHEDUABLE
        Schedulable_AcctSupportLevelUpdates testSch = new Schedulable_AcctSupportLevelUpdates();

        Test.startTest();
        System.schedule('Schedulable_AcctSupportLevelUpdatesTest', '0 0 0 1 1 ? 2025', testSch);
        testSch.execute(null, subList);
        Test.stopTest();

        // GET FOR CORRECTLY UPDATED ACCOUNT SUPPORT LEVEL FIELD
        testAccount = [SELECT Id, Support_Level__c FROM Account WHERE Id IN :testAccount];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        System.assert(testAccount[0].Support_Level__c == 'Basic');
    }

    /**
    * @description AcctSupportLevelUpdatesTest5_SuspendedSFOrg - Test functionality on an Account who has an active support asset but its Production SF Org is suspended
    */
    public static testMethod void AcctSupportLevelUpdatesTest5_SuspendedSFOrg() {
        // GET TEST ACCOUNT
        List<Account> testAccount = [SELECT Id FROM Account];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        testAccount[0].Support_Level__c = 'Basic';
        update testAccount;

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id, Name, ProductCode FROM Product2];
        System.assert(testProducts != null);
        System.assert(testProducts.size() == 2);

        // GET SALESFORCE ORG
        List<Salesforce_Org__c> testSFOrg = [SELECT Id, Conga_Account_Suspension_Date__c FROM Salesforce_Org__c];
        System.assert(testSFOrg != null && testSFOrg.size() == 1);
        System.assert(testSFOrg[0].Conga_Account_Suspension_Date__c == null);
        testSFOrg[0].Conga_Account_Suspension_Date__c = Date.today().addDays(5);
        update testSFOrg;
        
        // CREATE THE ACCOUNTS FIRST SUPPORT SUB
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount[0].Id, SBQQ__Product__c = testProducts[0].Id, SBQQ__Quantity__c = 1,
                                    SBQQ__SubscriptionStartDate__c = Date.today().addDays(-180), SBQQ__SubscriptionEndDate__c = Date.today().addDays(15));
        insert testSub;

        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        subList = [SELECT Id, SBQQ__Account__c, SBQQ__Account__r.Support_Level__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Subscription__c];
        
        // EXECUTE SCHEDUABLE
        Schedulable_AcctSupportLevelUpdates testSch = new Schedulable_AcctSupportLevelUpdates();

        Test.startTest();
        System.schedule('Schedulable_AcctSupportLevelUpdatesTest', '0 0 0 1 1 ? 2025', testSch);
        testSch.execute(null, subList);
        Test.stopTest();

        // GET FOR CORRECTLY UPDATED ACCOUNT SUPPORT LEVEL FIELD
        testAccount = [SELECT Id, Support_Level__c FROM Account WHERE Id IN :testAccount];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        System.assert(String.isBlank(testAccount[0].Support_Level__c));
    }

    /**
    * @description AcctSupportLevelUpdatesTest2_Yesterday - Test functionality for yesterday
    */
    public static testMethod void AcctSupportLevelUpdatesTest2_Yesterday() {
        // GET TEST ACCOUNT
        List<Account> testAccount = [SELECT Id FROM Account];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        testAccount[0].Support_Level__c = 'Premium';
        update testAccount;

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id, Name, ProductCode FROM Product2];
        System.assert(testProducts != null);
        System.assert(testProducts.size() == 2);

        // CREATE THE ACCOUNTS FIRST SUPPORT SUB
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount[0].Id, SBQQ__Product__c = testProducts[1].Id, SBQQ__Quantity__c = 1,
                                    SBQQ__SubscriptionStartDate__c = Date.today().addDays(-180), SBQQ__SubscriptionEndDate__c = Date.today().addDays(-1));
        insert testSub;

        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        subList = [SELECT Id, SBQQ__Account__c, SBQQ__Account__r.Support_Level__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Subscription__c];             

        // EXECUTE SCHEDUABLE
        Schedulable_AcctSupportLevelUpdates testSch = new Schedulable_AcctSupportLevelUpdates();

        Test.startTest();
        System.schedule('Schedulable_AcctSupportLevelUpdatesTest', '0 0 23 * * ?', testSch);
        testSch.execute(null, subList);
        Test.stopTest();

        // GET FOR CORRECTLY UPDATED ACCOUNT SUPPORT LEVEL FIELD
        testAccount = [SELECT Id, Support_Level__c FROM Account WHERE Id IN :testAccount];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);
        System.assert(testAccount[0].Support_Level__c == 'Basic');
    }   


    /**
    * @description AcctSupportLevelUpdatesTest6_NoMetadata - Test No Metadata
    */
    public static testMethod void AcctSupportLevelUpdatesTest6_NoMetadata() {
        // GET TEST ACCOUNT
        List<Account> testAccount = [SELECT Id FROM Account];
        System.assert(testAccount != null);
        System.assert(testAccount.size() == 1);

        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id, Name, ProductCode FROM Product2];
        System.assert(testProducts != null);
        System.assert(testProducts.size() == 2);

        // GET SALESFORCE ORG
        List<Salesforce_Org__c> testSFOrg = [SELECT Id, Conga_Account_Suspension_Date__c FROM Salesforce_Org__c];
        System.assert(testSFOrg != null && testSFOrg.size() == 1);
        System.assert(testSFOrg[0].Conga_Account_Suspension_Date__c == null);
        testSFOrg[0].Conga_Account_Suspension_Date__c = Date.today().addDays(5);
        update testSFOrg;
        
        // CREATE THE ACCOUNTS FIRST SUPPORT SUB
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount[0].Id, SBQQ__Product__c = testProducts[0].Id, SBQQ__Quantity__c = 1,
                                    SBQQ__SubscriptionStartDate__c = Date.today().addDays(-180), SBQQ__SubscriptionEndDate__c = Date.today().addDays(15));
        insert testSub;

        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        subList = [SELECT Id, SBQQ__Account__c, SBQQ__Account__r.Support_Level__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c FROM SBQQ__Subscription__c];   
        
        // EXECUTE SCHEDUABLE
        TestSupportLevelAssetMetaMap = new Map<Id, String>();
        Schedulable_AcctSupportLevelUpdates testSch = new Schedulable_AcctSupportLevelUpdates();

        Test.startTest();
        System.schedule('Schedulable_AcctSupportLevelUpdatesTest', '0 0 0 1 1 ? 2025', testSch);
        testSch.execute(null, subList);
        Test.stopTest();
    }   

    /**
    * @description createTestMeta - Helper method for creating test custom metadata values
    */
    public static Map<Id, String> createTestMeta(Id pProduct2Id1, String pSupportLevel1, Id pProduct2Id2, String pSupportLevel2){
        Account_Support_Level_Asset_Product__mdt metaSetting1 = new Account_Support_Level_Asset_Product__mdt();
        Map<String, Object> metaSetting1Fields = (Map<String, Object>)JSON.deserializeUntyped(JSON.serializePretty(metaSetting1));
        metaSetting1Fields.put(Account_Support_Level_Asset_Product__mdt.Product_RecordId__c.getDescribe().getName(), pProduct2Id1);     
        metaSetting1Fields.put(Account_Support_Level_Asset_Product__mdt.Support_Level__c.getDescribe().getName(), pSupportLevel1);
        metaSetting1 = (Account_Support_Level_Asset_Product__mdt) JSON.deserialize(JSON.serialize(metaSetting1Fields), Account_Support_Level_Asset_Product__mdt.class);

        Account_Support_Level_Asset_Product__mdt metaSetting2 = new Account_Support_Level_Asset_Product__mdt();
        Map<String, Object> metaSetting2Fields = (Map<String, Object>)JSON.deserializeUntyped(JSON.serializePretty(metaSetting2));
        metaSetting2Fields.put(Account_Support_Level_Asset_Product__mdt.Product_RecordId__c.getDescribe().getName(), pProduct2Id2);     
        metaSetting2Fields.put(Account_Support_Level_Asset_Product__mdt.Support_Level__c.getDescribe().getName(), pSupportLevel2);
        metaSetting2 = (Account_Support_Level_Asset_Product__mdt) JSON.deserialize(JSON.serialize(metaSetting2Fields), Account_Support_Level_Asset_Product__mdt.class);

        return new Map<Id, String>{ metaSetting1.Product_RecordId__c => metaSetting1.Support_Level__c, metaSetting2.Product_RecordId__c => metaSetting2.Support_Level__c};
    }


}