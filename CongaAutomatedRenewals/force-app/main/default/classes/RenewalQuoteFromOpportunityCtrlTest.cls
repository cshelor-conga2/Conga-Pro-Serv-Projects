/**
* @author Stas Daszkiewicz
* @date 20190107
* @version 1.0
* @description RenewalQuoteFromOpportunityCtrlTest - Test class for the RenewalQuoteFromOpportunityController class
*/
@isTest
private class RenewalQuoteFromOpportunityCtrlTest {
    
    /**
    * @description noRenewalContract - 
    */
    static testmethod void noRenewalContract() {
        //CREATE ACCOUNT TEST RECORD
        Account account1 = new Account();
        account1.Name = 'Test Account 1';
        account1.Type = 'Prospect';
        insert account1;
        
        //CREATE A CONTRACT TEST RECORD
        Contract contract1 = new Contract();
        contract1.AccountId = account1.Id;
        contract1.Name = 'Test Contract 1';
        contract1.Status = 'Draft';
        contract1.StartDate = Date.Today();
        contract1.ContractTerm = 24;
        contract1.SBQQ__RenewalQuoted__c = TRUE;
        insert contract1;

        contract1.Status = 'Activated';
        update contract1;
        
        //CREATE AN OPPORTUNITY TEST RECORD
        Opportunity opportunity1 = new Opportunity();
        opportunity1.Name = 'Simplus Test Account Renewal 1';
        opportunity1.AccountId = account1.Id;
        opportunity1.CloseDate = date.newInstance(1990, 11, 21);
        opportunity1.SBQQ__Renewal__c = TRUE;
        opportunity1.LeadSource = 'Renewal';
        opportunity1.StageName = 'Pending Renewal';
        opportunity1.ForecastCategoryName = 'Omitted';
        opportunity1.CloseDate = date.newInstance(2020, 11, 1);
        opportunity1.SBQQ__RenewedContract__c = contract1.Id;
        insert opportunity1;
        
        
        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.standardController(new Opportunity());
        RenewalQuoteFromOpportunityController renewQuote = new RenewalQuoteFromOpportunityController(sc);
        
        if(contract1.SBQQ__RenewalQuoted__c = TRUE) {
            RenewalQuoteFromOpportunityController.generateRenewalQuote(opportunity1.Id);
        }
        
        if(opportunity1.SBQQ__Renewal__c = TRUE) {
            RenewalQuoteFromOpportunityController.generateRenewalQuote(opportunity1.Id);
        }

        Test.stopTest();
    }
    
    /**
    * @description noRenewalContract2 - 
    */
    static testmethod void noRenewalContract2() {
        //CREATE ACCOUNT TEST RECORD
        Account account1 = new Account();
        account1.Name = 'Test Account 1';
        account1.Type = 'Prospect';
        insert account1;
        
        //CREATE A CONTRACT TEST RECORD
        Contract contract1 = new Contract();
        contract1.AccountId = account1.Id;
        contract1.Name = 'Test Contract 1';
        contract1.Status = 'Draft';
        contract1.StartDate = Date.Today();
        contract1.ContractTerm = 24;
        contract1.SBQQ__RenewalQuoted__c = FALSE;
        insert contract1;

        contract1.Status = 'Activated';
        update contract1;
        
        //CREATE AN OPPORTUNITY TEST RECORD
        Opportunity opportunity1 = new Opportunity();
        opportunity1.Name = 'Simplus Test Account Renewal 1';
        opportunity1.AccountId = account1.Id;
        opportunity1.CloseDate = date.newInstance(1990, 11, 21);
        opportunity1.SBQQ__Renewal__c = TRUE;
        opportunity1.LeadSource = 'Renewal';
        opportunity1.StageName = 'Pending Renewal';
        opportunity1.ForecastCategoryName = 'Omitted';
        opportunity1.CloseDate = date.newInstance(2020, 11, 1);
        opportunity1.SBQQ__RenewedContract__c = contract1.Id;
        insert opportunity1;
        
        
        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.standardController(new Opportunity());
        RenewalQuoteFromOpportunityController renewQuote = new RenewalQuoteFromOpportunityController(sc);
        
        if(!contract1.SBQQ__RenewalQuoted__c) {
            RenewalQuoteFromOpportunityController.generateRenewalQuote(opportunity1.Id);
        }
        
        if(opportunity1.SBQQ__Renewal__c = TRUE) {
            RenewalQuoteFromOpportunityController.generateRenewalQuote(opportunity1.Id);
        }

        Test.stopTest();
    }
    
    /**
    * @description noRenewedContract - 
    */
    static testmethod void noRenewedContract() {
        //CREATE ACCOUNT TEST RECORD
        Account account1 = new Account();
        account1.Name = 'Test Account 1';
        account1.Type = 'Prospect';
        insert account1;
        
        //CREATE A CONTRACT TEST RECORD
        Contract contract1 = new Contract();
        contract1.AccountId = account1.Id;
        contract1.Name = 'Test Contract 1';
        contract1.Status = 'Draft';
        contract1.StartDate = Date.Today();
        contract1.ContractTerm = 24;
        contract1.SBQQ__RenewalQuoted__c = TRUE;
        insert contract1;
        
        contract1.Status = 'Activated';
        update contract1;
        
        //CREATE AN OPPORTUNITY TEST RECORD
        Opportunity opportunity1 = new Opportunity();
        opportunity1.Name = 'Simplus Test Account Renewal 1';
        opportunity1.AccountId = account1.Id;
        opportunity1.CloseDate = date.newInstance(1990, 11, 21);
        opportunity1.Type = 'Existing';
        opportunity1.LeadSource = 'Renewal';
        opportunity1.StageName = 'Pending Renewal';
        opportunity1.ForecastCategoryName = 'Omitted';
        opportunity1.CloseDate = date.newInstance(2020, 11, 1);
        opportunity1.SBQQ__RenewedContract__c = null;
        insert opportunity1;
        
        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.standardController(new Opportunity());
        RenewalQuoteFromOpportunityController renewQuote = new RenewalQuoteFromOpportunityController(sc);
        
        if(contract1.SBQQ__RenewalQuoted__c = TRUE && opportunity1.Type == 'Renewal' && opportunity1.SBQQ__RenewedContract__c != null) {
            RenewalQuoteFromOpportunityController.generateRenewalQuote(opportunity1.Id);
        }

        Test.stopTest();
    }


}