/**
* @author Jereriah Manning
* @date 20180215
* @version 1.00
* @description PPUpdateTestsNew2018 - Created for Conga Partner Team
*/
@isTest
private class PPUpdateTestsNew2018{

    /**
    * @description testPPUpdateClasses - 
    */
    static testMethod void testPPUpdateClasses(){
        Id pricebookId = Test.getStandardPricebookId();
      
        AVA_SFCORE__TaxNowSetting__c testTaxSetting = new AVA_SFCORE__TaxNowSetting__c(
            Name = 'AvaTax',
            AVA_SFCORE__Active_Setting__c = TRUE,
            AVA_SFCORE__TriggerLimit__c = 0,
            AVA_SFCORE__Service_URL__c = 'https://development.avalara.net/',
            AVA_SFCORE__Origin_Street__c = '390 Interlocken Crescent Suite 500',
            AVA_SFCORE__Origin_City__c = 'Broomfield',
            AVA_SFCORE__Origin_State__c = 'CO',
            AVA_SFCORE__Origin_Postal_Code__c = '80021',
            AVA_SFCORE__Origin_Country__c = 'US',
            AVA_SFCORE__Enable_Tax_Calculation__c = FALSE, 
            AVA_SFCORE__Enable_Address_Validation__c = FALSE,
            AVA_SFCORE__Automatic_Tax_Calculation__c = FALSE
        );
        insert testTaxSetting;      
      
        List<Account> acctsToAdd = new List<Account>();
        Account a = new Account();
        a.Name = 'Test Partner Account';
        a.recordtypeid = '01250000000Dysv';
        a.billingCity = 'Boulder';
        acctsToAdd.add(a);
                  
        Account a2 = new Account();
        a2.Name = 'Test Customer Account';
        a2.recordtypeid = '01250000000Du0B';
        a2.billingCity = 'Denver';
        acctsToAdd.add(a2);             
        Database.insert(acctsToAdd);              
          
        List<Contact> contactsToAdd = new List<Contact>();        
        Contact c1 = new Contact();
        c1.FirstName = 'Test1';
        c1.LastName = 'Contact1';
        c1.Email = 'TestContact1@TPA.com';
        c1.Title = 'Title Here';
        c1.AccountId = a.Id;
        contactsToAdd.add(c1);
                  
        Contact c2 = new Contact();
        c2.FirstName = 'Test2';
        c2.LastName = 'Contact2';
        c2.Email = 'TestContact2@TPA2.com';
        c2.Title = 'Title Here';          
        contactsToAdd.add(c2);
        Database.insert(contactsToAdd);
        
        Certification__c cert1 = new Certification__c();
        cert1.Certification__c = 'Composer Level 1';
        cert1.Contact__c = c1.Id;
        cert1.Type__c = 'Partner';
        cert1.Date_Certified__c = (System.Today()-1);
        Database.insert(cert1);
        
        List<Case> casesToAdd = new List<Case>();
        Case case1 = new Case();
        case1.Subject = 'Internal Case';
        case1.Type = 'Partner';
        case1.Product__c = 'Conga Composer 8';
        case1.RecordTypeId = '01250000000DzMY';
        case1.Status = 'Closed';
        case1.contactId = c1.Id;
        case1.accountId = a.Id;
        casesToAdd.add(case1);
                    
        Case case4 = new Case();
        case4.Subject = 'Internal Case';
        case4.Type = 'Partner';
        case4.Product__c = 'Conga Composer 8';
        case4.RecordTypeId = '01250000000DzMY';
        case4.Status = 'Closed';
        case4.contactId = c1.Id;
        case4.accountId = a.Id;
        case4.Time_Spent_Hours__c = 2.15;                
        casesToAdd.add(case4);                    
                    
        Case case2 = new Case();
        case2.Subject = 'Customer Case';
        case2.Type = 'Partner';
        case2.Product__c = 'Conga Composer 8';
        case2.RecordTypeId = '01250000000DzMY';
        case2.Status = 'Closed';
        case2.contactId = c2.Id;
        case2.accountId = a2.Id;
        casesToAdd.add(case2);
                    
        Case case3 = new Case();
        case3.Subject = 'Customer Case';
        case3.Type = 'Partner';
        case3.Product__c = 'Conga Composer 8';
        case3.RecordTypeId = '01250000000DzMY';
        case3.Status = 'Closed';
        case3.contactId = c2.Id;
        case3.accountId = a2.Id;
        case3.Time_Spent_Hours__c = 1.78;
        casesToAdd.add(case3);
        Database.insert(casesToAdd);

        List<Product2> testProds = new List<Product2>();
        Product2 CMprod = new Product2(Name = 'CM Product', ProductCode = 'CMP', Family = 'Conga Composer Licenses');
        testProds.add(CMprod);
        Product2 AGprod = new Product2(Name = 'AG Product', ProductCode = 'AGP', Family = 'ActionGrid');
        testProds.add(AGprod);
        Product2 CCprod = new Product2(Name = 'Contracts Product', ProductCode = 'CP', Family = 'Conga Contracts');
        testProds.add(CCprod);
        Product2 Courierprod = new Product2(Name = 'Courier Product', ProductCode = 'CRP', Family = 'Conga Courier');
        testProds.add(Courierprod);
        Product2 Novatusprod = new Product2(Name = 'Novatus Product', ProductCode = 'NP', Family = 'Novatus Contracts');
        testProds.add(Novatusprod);
        Product2 Automationprod = new Product2(Name = 'CN/WF Product', ProductCode = 'CNWFP', Family = 'Conga Conductor-Workflow');
        testProds.add(Automationprod);
        Product2 CongaSignprod = new Product2(Name = 'Conga Sign Product', ProductCode = 'CSP', Family = 'Conga Sign');
        testProds.add(CongaSignprod);
        Database.insert(testProds);
        
        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        PricebookEntry cmsp = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = CMprod.Id, UnitPrice = 268, IsActive = true);
        pbEntries.add(cmsp);
        PricebookEntry agsp = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = AGprod.Id, UnitPrice = 268, IsActive = true);
        pbEntries.add(agsp);
        PricebookEntry ccsp = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = CCprod.Id, UnitPrice = 768, IsActive = true);
        pbEntries.add(ccsp);
        PricebookEntry courierSP = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = Courierprod.Id, UnitPrice = 30, IsActive = true);
        pbEntries.add(courierSP);
        PricebookEntry automationSP = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = Automationprod.Id, UnitPrice = 1.50, IsActive = true);
        pbEntries.add(automationSP);
        PricebookEntry novatusSP = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = Novatusprod.Id, UnitPrice = 1268, IsActive = true);
        pbEntries.add(novatusSP);        
        PricebookEntry cssp = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = CongaSignprod.Id, UnitPrice = 2044, IsActive = true);
        pbEntries.add(cssp);                                                                                                     
        Database.insert(pbEntries);              
      
        // Test Opp that will include products from all families        
        Opportunity o1 = new Opportunity();
        o1.AccountId = a.Id;
        o1.Amount = 1;
        o1.Name = 'Test Opp';
        o1.StageName = 'Prospecting';
        o1.CloseDate = date.Today();
        o1.Referring_Partner_Primary__c = a.Id;
        Database.insert(o1);
      
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        OpportunityLineItem cmoli = new OpportunityLineItem(PricebookEntryId = cmsp.Id, Quantity = 10, OpportunityId = o1.Id, UnitPrice = 268);
        olis.add(cmoli);
        OpportunityLineItem agoli = new OpportunityLineItem(PricebookEntryId = agsp.Id, Quantity = 10, OpportunityId = o1.Id, UnitPrice = 268);
        olis.add(agoli);
        OpportunityLineItem courierOLI = new OpportunityLineItem(PricebookEntryId = CourierSP.Id, Quantity = 360, OpportunityId = o1.Id, UnitPrice = 5);
        olis.add(courierOLI);
        OpportunityLineItem contractsOLI = new OpportunityLineItem(PricebookEntryId = ccsp.Id, Quantity = 5, OpportunityId = o1.Id, UnitPrice = 768);
        olis.add(contractsOLI);
        OpportunityLineItem cnwfoli = new OpportunityLineItem(PricebookEntryId = AutomationSP.Id, Quantity = 6000, OpportunityId = o1.Id, UnitPrice = .75);
        olis.add(cnwfoli);
        OpportunityLineItem novatusOLI = new OpportunityLineItem(PricebookEntryId = NovatusSP.Id, Quantity = 10, OpportunityId = o1.Id, UnitPrice = 1268);
        olis.add(novatusOLI);
        OpportunityLineItem congaSignOLI = new OpportunityLineItem(PricebookEntryId = cssp.Id, Quantity = 5, OpportunityId = o1.Id, UnitPrice = 34.75);
        olis.add(congaSignOLI);
        Database.insert(olis);
      
        Test.startTest();

        // Close the deal now that products are added
        o1.StageName = 'Closed Won';
        Database.update(o1);
         
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        // Test Opp without products      
        Opportunity o2 = new Opportunity();
        o2.AccountId = a.Id;
        o2.Amount = 1;
        o2.Name = 'Test Opp 2';
        o2.StageName = 'Closed Won';
        o2.CloseDate = date.Today();
        o2.Referring_Partner_Primary__c = a.Id;
        oppsToInsert.add(o2);

        //No products on this Opp and in Last Fiscal Year
        Opportunity o3 = new Opportunity();
        o3.AccountId = a.Id;
        o3.Amount = 1;
        o3.Name = 'Test Opp';
        o3.StageName = 'Closed Won';
        o3.CloseDate = date.Today()-366;
        o3.Referring_Partner_Primary__c = a.Id;
        oppsToInsert.add(o3);
        Database.insert(oppsToInsert);
                        
        Partner_Profile__c pp = new Partner_Profile__c();
        pp.Account__c = a.Id;
        pp.RecordTypeId = '01250000000RYCc';
        Database.insert(pp);          
      
        PPOtherDataUpdaterToBatch ppodutb = new PPOtherDataUpdaterToBatch();
        PPDealCountUpdaterToBatch ppdcutb = new PPDealCountUpdaterToBatch();
        PPRevenueUpdaterToBatch pprutb = new PPRevenueUpdaterToBatch();
        PPProductMixDataToBatch pppmdtb = new PPProductMixDataToBatch();
        PPCaseDataToBatch ppcdtb = new PPCaseDataToBatch();
          
        PPOtherDataUpdaterToBatch.doCount();
        PPDealCountUpdaterToBatch.doCount();
        PPRevenueUpdaterToBatch.doCount();
        PPProductMixDataToBatch.doCount();
        PPCaseDataToBatch.doCount();

        Test.stopTest();
    }


}