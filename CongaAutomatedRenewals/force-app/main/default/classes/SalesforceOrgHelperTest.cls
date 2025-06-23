/**
* @author JPesusich, ERedding
* @date 20181023
* @version 1.0
* @description SalesforceOrgHelperTest - Test class for the SalesforceOrgHelper class
*/
@isTest
public with sharing class SalesforceOrgHelperTest {

    /**
    * @description testUpdateLicenseObjectWithOrgInsert
    */
    public static testMethod void testUpdateLicenseObjectWithOrgInsert() {
        AVA_SFCORE__TaxNowSetting__c testTaxSetting = new AVA_SFCORE__TaxNowSetting__c(
            Name = 'AvaTax',
            AVA_SFCORE__Active_Setting__c = TRUE,
            AVA_SFCORE__TriggerLimit__c = 1,
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

        Id orgId = UserInfo.getOrganizationId();
        String orgName = UserInfo.getOrganizationName();

        sfLma__License__c lic = new sfLma__License__c();
        lic.sfLma__Subscriber_Org_ID__c = orgId;
        lic.sfLma__Status__c = 'Active';
        lic.sfLma__Seats__c = -1;
        insert lic;

        List<Salesforce_Org__c> newOrgs = (List<Salesforce_Org__c>)TestingUtility.createSObjectList('Salesforce_Org__c', false, 1); 
        for(Integer i = 0; i < newOrgs.size(); i++){
            Salesforce_Org__c so = newOrgs[i];
            so.Name = orgName + '_' + i;
            so.BillingCountry__c = 'US';
            so.BillingCity__c = 'Broomfield';
            so.BillingState__c = 'CO';
            so.Conga_Activation_Date__c = DateTime.now();
            so.Org_Id__c = orgId;
            so.Salesforce_Account_Id__c = orgId;
        }

        Test.startTest();

        insert newOrgs;

        Test.stopTest();
        
        List<sfLma__License__c> lics = [select Id,Salesforce_OrgId__c from sfLma__License__c where Id = :lic.Id];
        System.assertEquals(1,lics.size(), 'Failed to create sfLma__License__c');
        System.assertEquals(lics[0].Salesforce_OrgId__c, newOrgs[0].Id,'Failed to update license record');
    }

    ///**
   // * @description testUpsertAccountRecord_Create 
   // */
    //public static testMethod void testUpsertAccountRecord_Create() {
    //    AVA_SFCORE__TaxNowSetting__c testTaxSetting = new AVA_SFCORE__TaxNowSetting__c(
    //        Name = 'AvaTax',
    //        AVA_SFCORE__Active_Setting__c = TRUE,
    //        AVA_SFCORE__TriggerLimit__c = 1,
    //        AVA_SFCORE__Service_URL__c = 'https://development.avalara.net/',
    //        AVA_SFCORE__Origin_Street__c = '385 Interlocken Crescent Suite 600',
    //        AVA_SFCORE__Origin_City__c = 'Broomfield',
    //        AVA_SFCORE__Origin_State__c = 'CO',
    //        AVA_SFCORE__Origin_Postal_Code__c = '80021',
    //        AVA_SFCORE__Origin_Country__c = 'US',
    //        AVA_SFCORE__Enable_Tax_Calculation__c = FALSE,
    //        AVA_SFCORE__Enable_Address_Validation__c = FALSE,
    //        AVA_SFCORE__Automatic_Tax_Calculation__c = FALSE
    //        );
    //    insert testTaxSetting;

    //    Test.startTest();
 
    //    Salesforce_Org__c testSalesforceOrg = new Salesforce_Org__c();
    //    testSalesforceOrg.Name = 'Test SF Org';
    //    testSalesforceOrg.BillingStreet__c = '385 Interlocken Crescent Suite 600';
    //    testSalesforceOrg.BillingCity__c = 'Broomfield';
    //    testSalesforceOrg.BillingState__c = 'CO';
    //    testSalesforceOrg.BillingCountry__c = 'United States';
    //    testSalesforceOrg.Conga_Activation_Date__c = DateTime.now();
    //    testSalesforceOrg.Gringotts_Account_Id__c = null;
    //    insert testSalesforceOrg;

    //    // REFRESH RECORD AND TEST FOR CORRECT DATA
    //    testSalesforceOrg = [SELECT Id, Name, BillingStreet__c, BillingCity__c, BillingState__c, BillingCountry__c, Account__c, Gringotts_Account_Id__c 
    //                         FROM Salesforce_Org__c WHERE Id = :testSalesforceOrg.Id];
    //    System.assert(testSalesforceOrg.Account__c != null);
    //    System.assert(testSalesforceOrg.Gringotts_Account_Id__c != null);

    //    // GET NEWLY CREATED ACCOUNT AND TEST FOR CORRECT DATA
    //    List<Account> accts = [SELECT Id, Name, BillingCity, BillingState, BillingStreet, BillingCountry FROM Account WHERE Id = :testSalesforceOrg.Account__c];
    //    System.assert(accts.size() == 1, 'Failed to create matching accounts for Salesforce_Org__c');
    //    System.assert(accts[0].Name == testSalesforceOrg.Name, 'Failed to update Name');  
    //    System.assert(accts[0].BillingStreet == testSalesforceOrg.BillingStreet__c, 'Failed to update BillingStreet');
    //    System.assert(accts[0].BillingCity == testSalesforceOrg.BillingCity__c, 'Failed to update BillingCity');
    //    System.assert(accts[0].BillingState == testSalesforceOrg.BillingState__c, 'Failed to update BillingState');    
    //    System.assert(accts[0].BillingCountry == testSalesforceOrg.BillingCountry__c, 'Failed to update BillingCountry');

    //    ///////// TEST TWO WITH AN EXISTING ACCOUNT AND POPULATED GRINGOTTS ID
    //    Account testAccount = new Account(Name = 'Test Account');
    //    insert testAccount;

    //    Salesforce_Org__c testSalesforceOrg2 = new Salesforce_Org__c();
    //    testSalesforceOrg2.Name = 'Test Salesforce Org 2';
    //    testSalesforceOrg2.BillingStreet__c = '385 Interlocken Crescent Suite 600';
    //    testSalesforceOrg2.BillingCity__c = 'Broomfield';
    //    testSalesforceOrg2.BillingState__c = 'CO';
    //    testSalesforceOrg2.BillingCountry__c = 'United States';
    //    testSalesforceOrg2.Conga_Activation_Date__c = DateTime.now();
    //    testSalesforceOrg2.Gringotts_Account_Id__c = testAccount.Id;
    //    insert testSalesforceOrg2;

    //    // REFRESH RECORD AND TEST FOR CORRECT DATA
    //    testSalesforceOrg2 = [SELECT Id, Name, Account__c, BillingStreet__c, BillingCity__c, BillingState__c, BillingCountry__c 
    //                          FROM Salesforce_Org__c WHERE Id = :testSalesforceOrg2.Id];
    //    System.assert(testSalesforceOrg2.Account__c == testAccount.Id);        

    //    // GET NEWLY CREATED ACCOUNT AND TEST FOR CORRECT DATA
    //    testAccount = [SELECT Id, Name, BillingCity, BillingState, BillingStreet, BillingCountry FROM Account WHERE Id = :testAccount.Id];
    //    System.debug(testAccount.Name);
    //    System.debug(testSalesforceOrg2.Name);
    //    System.assert(testAccount.Name == testSalesforceOrg2.Name, 'Failed to update Name');  
    //    System.assert(testAccount.BillingStreet == testSalesforceOrg2.BillingStreet__c, 'Failed to update BillingStreet');
    //    System.assert(testAccount.BillingCity == testSalesforceOrg2.BillingCity__c, 'Failed to update BillingCity');
    //    System.assert(testAccount.BillingState == testSalesforceOrg2.BillingState__c, 'Failed to update BillingState');    
    //    System.assert(testAccount.BillingCountry == testSalesforceOrg2.BillingCountry__c, 'Failed to update BillingCountry');

    //    Test.stopTest();        
    //}

    //public static testMethod void testUpsertAccountRecord_Update() {
    //    AVA_SFCORE__TaxNowSetting__c testTaxSetting = new AVA_SFCORE__TaxNowSetting__c(
    //        Name = 'AvaTax',
    //        AVA_SFCORE__Active_Setting__c = TRUE,
    //        AVA_SFCORE__TriggerLimit__c = 1,
    //        AVA_SFCORE__Service_URL__c = 'https://development.avalara.net/',
    //        AVA_SFCORE__Origin_Street__c = '385 Interlocken Crescent Suite 600',
    //        AVA_SFCORE__Origin_City__c = 'Broomfield',
    //        AVA_SFCORE__Origin_State__c = 'CO',
    //        AVA_SFCORE__Origin_Postal_Code__c = '80021',
    //        AVA_SFCORE__Origin_Country__c = 'US',
    //        AVA_SFCORE__Enable_Tax_Calculation__c = FALSE, 
    //        AVA_SFCORE__Enable_Address_Validation__c = FALSE,
    //        AVA_SFCORE__Automatic_Tax_Calculation__c = FALSE
    //        );
    //    insert testTaxSetting;

    //    Salesforce_Org__c testSalesforceOrg = new Salesforce_Org__c();
    //    testSalesforceOrg.Name = 'Test SF Org';
    //    testSalesforceOrg.BillingStreet__c = '385 Interlocken Crescent Suite 600';
    //    testSalesforceOrg.BillingCity__c = 'Broomfield';
    //    testSalesforceOrg.BillingState__c = 'CO';
    //    testSalesforceOrg.BillingCountry__c = 'United States';
    //    testSalesforceOrg.Conga_Activation_Date__c = DateTime.now();
    //    testSalesforceOrg.Gringotts_Account_Id__c = null;
    //    insert testSalesforceOrg;

    //    // REFRESH RECORD
    //    testSalesforceOrg = [SELECT Id, Name, BillingStreet__c, Account__c, Gringotts_Account_Id__c FROM Salesforce_Org__c WHERE Id = :testSalesforceOrg.Id];
    //    System.assert(testSalesforceOrg.Account__c != null);
    //    System.assert(testSalesforceOrg.Gringotts_Account_Id__c != null);

    //    Test.startTest();

    //    // UDPATE SALESFORCE ORG AND CHECK FOR PROPERLY UPDATED ACCOUNT
    //    testSalesforceOrg.BillingStreet__c = '390 Interlocken Crescent Suite 300';
    //    update testSalesforceOrg;
    //    List<Account> accts = [SELECT Id, BillingStreet FROM Account WHERE Id = :testSalesforceOrg.Account__c];
    //    System.assert(accts.size() == 1, 'Failed to create matching accounts for Salesforce_Org__c');
    //    System.assert(accts[0].BillingStreet == testSalesforceOrg.BillingStreet__c, 'Failed to update BillingStreet');

    //    Test.stopTest();
    //}


}