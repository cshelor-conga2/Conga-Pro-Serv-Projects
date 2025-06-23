/** 
* @author ECS, ERedding
* @date 20190515
* @version 1.00
* @description batch_mrrCalculatorLOBNightlyTest - Test class for the batch_mrrCalculatorLOBNightly class
*/
@isTest 
private class batch_mrrCalculatorLOBNightlyTest{

	/** 
	* @description testCreateAssetonClosedWon
	*/
    public static testmethod void testCreateAssetonClosedWon(){
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
        System.assert(testTaxSetting.Id != null, 'The test tax setting did not insert');

        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Indianapolis',
            BillingState = 'IN',
            BillingPostalCode = '46220',
            BillingCountry = 'United States',
            Type = 'Customer',
            Sandbox_Edition__c = FALSE,
            Subscriber_Org_Type__c = 'Production',
            Billing_Partner__c = null
        );
        insert testAccount;
        System.assert(testAccount.Id != null, 'The test account did not insert');

        Account testAccount2 = new Account(
            Name = 'Account ABC',
            BillingStreet = '123 Test St',
            BillingCity = 'Indianapolis',
            BillingState = 'IN',
            BillingPostalCode = '46220',
            BillingCountry = 'United States',
            Type = 'Customer',
            Sandbox_Edition__c = FALSE,
            Subscriber_Org_Type__c = 'Production',
            Billing_Partner__c = null,
            mrr_Active_MRR__c = 50
        );
        insert testAccount2;
        System.assert(testAccount2.Id != null, 'The test account 2 did not insert');

        List<Account> testAccounts = [SELECT Id, mrr_Active_MRR__c, mrr_Data_MRR__c, mrr_DocMerge_MRR__c, mrr_Contracts_mrr__c, mrr_Services_MRR__c, mrr_Reseller_mrr__c, mrr_eSignature_MRR__c, 
        							  mrr_Workflow_MRR__c FROM Account WHERE Id =: testAccount.Id];

        batch_mrrCalculatorLOBNULLNightly b_mrrNull = new batch_mrrCalculatorLOBNULLNightly();
        Database.QueryLocator ql_NULL = b_mrrNull.start(null);
        b_mrrNull.execute(null, testAccounts);
        b_mrrNull.finish(null);

        Salesforce_Account__c sfAccount = new Salesforce_Account__c(Name = 'Test');
        insert sfAccount;
        
        Salesforce_Org__c sfOrg = new Salesforce_Org__c(Name = 'Test');
        insert sfOrg;
        
        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Test Opp',
            StageName = 'Qualify',
            CloseDate = date.today(), 
            Customer_Org_id__c = '00D500000007Fr8',
            Salesforce_Org__c = sfOrg.Id,
            Salesforce_Account__c = sfAccount.Id
        );

        insert testOpp;
        System.assert(testOpp.Id != null, 'The test opp did not insert');

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'Test',
            isActive = TRUE,
            CanUseRevenueSchedule = TRUE
            );

        insert testProduct;
        System.assert(testProduct.Id != null, 'The test product did not insert');

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry testPBE = new PricebookEntry(
            Product2Id  = testProduct.Id,
            Pricebook2Id = pricebookId,
            UnitPrice = 1,
            isActive = TRUE
            );

        insert testPBE;
        System.assert(testPBE.Id != null, 'The test price book entry did not insert');

        OpportunityLineItem testOLI = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = testPBE.Id,
            Quantity = 1,
            UnitPrice = 2.00,
            ServiceDate = date.Today(),
            Product_End_Date__c = (date.Today() + 365)
        );

        insert testOLI;
        System.assert(testOLI.Id != null, 'The test line item did not insert');
        testOLI = [SELECT Id, Quantity, ServiceDate, Product_End_Date__c, mrr_Product_MRR__c, OpportunityId, 
         			Opportunity.AccountId, Opportunity.Salesforce_Org__c, Opportunity.Salesforce_Account__c, Opportunity.Billing_Party__c, 
         			PricebookEntry.Product2.Name, PricebookEntry.Product2Id, PricebookEntry.Product2.FY16_Revenue_Type__c
 					FROM OpportunityLineItem WHERE Id = :testOLI.Id];

 		Id standardAssetRTId = UtilityClass.getRecordTypesForObject('Asset').get('Standard');
 		System.assert(standardAssetRTId != null, 'Asset Standard record type could not be found');

   		Asset testOLIAsset = new Asset(
            AccountId = testOLI.Opportunity.AccountId,
            Name = (testOLI.PricebookEntry.Product2.Name),
            Product2Id = testOLI.PricebookEntry.Product2Id,
            Quantity = testOLI.Quantity,
            RecordTypeId = standardAssetRTId,
            Start_Date__c =  testOLI.ServiceDate, 
            End_Date__c = testOLI.Product_End_Date__c,
            OLI_Id__c = testOLI.Id,
            mrr_Asset_MRR__c = testOLI.mrr_Product_MRR__c,
            Related_Oppty__c = testOLI.OpportunityId, 
            Salesforce_Org__c = testOLI.Opportunity.Salesforce_Org__c,
            Salesforce_Account__c = testOLI.Opportunity.Salesforce_Account__c, 
            Billing_Party__c = testOLI.Opportunity.Billing_Party__c
        );

        /*Asset type is dependent upon the revenue type of the related product*/
        if(testOLI.PricebookEntry.Product2.FY16_Revenue_Type__c == 'Recurring'){
            testOLIAsset.Type__c = 'Subscription';
        }

        else if (testOLI.PricebookEntry.Product2.FY16_Revenue_Type__c == 'Non-Recurring'){
            testOLIAsset.Type__c = 'Consumable';
        }
        insert testOLIAsset;

        testOpp.StageName = 'Closed Won';
        update testOpp;

        Test.startTest();

        batch_mrrCalculatorLOBNightly b_mrr = new batch_mrrCalculatorLOBNightly();
        Database.executeBatch(b_mrr, 2);

        //Database.QueryLocator ql = b_mrr.start(null);
        //b_mrr.execute(null, testAssets);
        //b_mrr.finish(null);


        //batch_mrrCalculatorLOBNULLNightly b_mrrNull2 = new batch_mrrCalculatorLOBNULLNightly();
        //Database.QueryLocator ql_NULL2 = b_mrrNull2.start(null);
        //b_mrrNull2.execute(null, testAccounts);
        //b_mrrNull2.finish(null);

       // OpportunityLineItem resultOLI = [SELECT Id, Asset__c FROM OpportunityLineItem WHERE Id = :testOLI.Id LIMIT 1];

        Test.stopTest();



    }

    /** 
    * @description testSchedulable
    */
    public static testmethod void testSchedulable(){
        sch_batch_mrrCalculatorLOBNightly schdulable = new sch_batch_mrrCalculatorLOBNightly();

        Test.startTest();

        schdulable.execute(null);
        sch_batch_mrrCalculatorLOBNightly.scheduleIt();

        Test.stopTest();
    }


}