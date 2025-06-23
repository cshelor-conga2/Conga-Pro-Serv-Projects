/**
* @author JManning, BSpencer
* @date 20151202
* @version 1.00
* @description BulkUtilizationCodeTEST - Test class for the CreateMonthlyBulkUtilizationRecords2 class
*/
@isTest
private class BulkUtilizationCodeTEST{               
    
    /**
    * @description testUpdateCongaUsageEstablishingPartner - 
    */    
    static testMethod void testUpdateCongaUsageEstablishingPartner(){       
        // Create and Format date as necessary depending upon the month and day of Today [The day the test class runs]
        // Needed to create a Conga Usage record in Last Month [Month__c]

        Integer ThisYearInt = System.Today().Year();
        Integer ThisMonthInt = System.Today().Month();
        //Integer ThisDayInt = System.Today().Day();
        
        {
            if(ThisMonthInt == 1){
                ThisYearInt = ThisYearInt - 1;
                //ThisMonthInt = 12;
            }
        }
        
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
        
        Account partnerAccount = new Account();
            partnerAccount.Name = 'Test Partner Account';
            partnerAccount.RecordTypeID = '01250000000Dysv';
            partnerAccount.Type = 'Partner - ISV/Wholesale';
            Database.insert(partnerAccount);
                
        Account regularAccount = new Account();
            regularAccount.Name = 'Test Customer Account';
            regularAccount.RecordTypeID = '01250000000Du0B';
            regularAccount.Type = 'Customer';
            regularAccount.Establishing_Partner__c = partnerAccount.Id;
            Database.insert(regularAccount);   
        
        Salesforce_Org__c SFOrg = new Salesforce_Org__c();
            SFOrg.Name = 'Test Customer Account';
            SFOrg.Account__c = regularAccount.Id;
            //SMH: added below line to increase coverage to 100%
            SFOrg.Establishing_Partner__c = partnerAccount.Id;
            SFOrg.Org_Type__c = 'Production';
            Database.insert(SFOrg);
                
        Conga_Usage_History2__c cuh2 = new Conga_Usage_History2__c();            
            cuh2.Name = 'CUH2 Record';
            if(System.Today().Month() == 1)
            {
                cuh2.Month__c = Date.valueOf(ThisYearInt + '-12-01 00:00:00');
            }
            else
            {
                cuh2.Month__c = Date.valueOf(ThisYearInt + '-' + (ThisMonthInt - 1) + '-01 00:00:00');            
            }
            cuh2.Salesforce_Org__c = SFOrg.Id;
            cuh2.Account_For_BLU_Report__c = regularAccount.Id;
            cuh2.Establishing_Partner__c = partnerAccount.Id;
            Database.insert(cuh2);
                //System.debug('******************* cuh2: ' + cuh2);                
                
        /*
        Case testCase = new Case();
            testCase.AccountId = regularAccount.Id;
            testCase.Status = 'Closed';
            if(System.Today().Month() == 1)
            {
                testCase.closedDate = Date.valueOf(ThisYearInt + '-12-01 00:00:00');
            }
            else
            {
                testCase.closedDate = Date.valueOf(ThisYearInt + '-' + (ThisMonthInt - 1) + '-01 00:00:00');            
            } 
                database.insert(testCase);
        */               
                
        /*
        Conga_Usage_History__c cuh = new Conga_Usage_History__c();
            cuh.Name = 'CUH Record';

            if(System.Today().Month() == 1)
            {
                cuh.Month__c = Date.valueOf(ThisYearInt + '-12-01 00:00:00');
            }
            else
            {
                cuh.Month__c = Date.valueOf(ThisYearInt + '-' + (ThisMonthInt - 1) + '-01 00:00:00');            
            }
            cuh.Account__c = regularAccount.Id;
                database.insert(cuh);
                System.debug('******************* cuh: ' + cuh);
        */
        
        Partner_Profile__c pp = new Partner_Profile__c();
        pp.Account__c = partnerAccount.Id;
        Database.insert(pp);
            
        Test.startTest();

        UpdateCongaUsageEstablishingPartner2 ucuep = new UpdateCongaUsageEstablishingPartner2();
        UpdateCongaUsageEstablishingPartner2.updateCongaUsageHistoryRecords();
        CreateMonthlyBulkUtilizationRecords2 cmbur = new CreateMonthlyBulkUtilizationRecords2();

        Test.stopTest();
    }

    /**
    * @description testSchedulable1 - 
    */    
    static testMethod void testSchedulable1(){
        Test.startTest();

        CreateMonthlyBulkUtilizationsSCHEDULER schedule = new CreateMonthlyBulkUtilizationsSCHEDULER();
        schedule.execute(null);
        
        CreateMonthlyBulkUtilizationsSCHEDULER.scheduleIt();

        Test.stopTest();
    }  
    
    /**
    * @description testSchedulable2 - 
    */    
    static testMethod void testSchedulable2(){
        Test.startTest();

        UpdateCongaUsageHistoryEPSCHEDULER schedule = new UpdateCongaUsageHistoryEPSCHEDULER();
        schedule.execute(null);
        
        UpdateCongaUsageHistoryEPSCHEDULER.scheduleIt();

        Test.stopTest();
    }  



    //SMH: it seems Conga Utilization Usage History was switched from 
    //Account view to customer's Salesforce Org view
    //However, since these classes are deployed, they will lower overall 
    //test coverage for not being covered.
    //static testMethod void testOldCongaUsageHistory()
    //{
    //    /* SMH START TEST DUPLICATES FOR COVERAGE FOR NOW */

    //    // Create and Format date as necessary depending upon the month and day of Today [The day the test class runs]
    //     // Needed to create a Conga Usage record in Last Month [Month__c]

    //    Integer ThisYearInt = System.Today().Year();
    //    Integer ThisMonthInt = System.Today().Month();
    //    //Integer ThisDayInt = System.Today().Day();
        
    //    {
    //        if(ThisMonthInt == 1)
    //        {
    //            ThisYearInt = ThisYearInt - 1;
    //            //ThisMonthInt = 12;
    //        }
    //    }
        
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

    //    Insert testTaxSetting;

    //    system.assert(testTaxSetting.Id != null, 'The test tax setting did not insert');
        
    //    Account partnerAccount = new Account();
    //        partnerAccount.Name = 'Test Partner Account';
    //        partnerAccount.RecordTypeID = '01250000000Dysv';
    //        partnerAccount.Type = 'Partner - ISV/Wholesale';
    //            database.insert(partnerAccount);
                
    //    Account regularAccount = new Account();
    //        regularAccount.Name = 'Test Customer Account';
    //        regularAccount.RecordTypeID = '01250000000Du0B';
    //        regularAccount.Type = 'Customer';
    //        regularAccount.Establishing_Partner__c = partnerAccount.Id;
    //            database.insert(regularAccount);   
        
    //    Salesforce_Org__c SFOrg = new Salesforce_Org__c();
    //        SFOrg.Name = 'Test Customer Account';
    //        SFOrg.Account__c = regularAccount.Id;
    //        SFOrg.Org_Type__c = 'Production';
    //            database.insert(SFOrg);               
        
    //    Partner_Profile__c pp = new Partner_Profile__c();
    //        pp.Account__c = partnerAccount.Id;            
    //            database.insert(pp);

    //    Conga_Usage_History__c cuh = new Conga_Usage_History__c();            
    //        cuh.Name = 'CUH Record';
    //        if(System.Today().Month() == 1)
    //        {
    //            cuh.Month__c = Date.valueOf(ThisYearInt + '-12-01 00:00:00');
    //        }
    //        else
    //        {
    //            cuh.Month__c = Date.valueOf(ThisYearInt + '-' + (ThisMonthInt - 1) + '-01 00:00:00');            
    //        }
    //        cuh.Account__c = regularAccount.Id;
    //        cuh.Establishing_Partner__c = partnerAccount.Id;
    //        database.insert(cuh);
    //        System.debug('******************* cuh: ' + cuh);                  
            
    //    test.StartTest();    
    //        UpdateCongaUsageEstablishingPartner ucuepDUPE = new UpdateCongaUsageEstablishingPartner();
    //        UpdateCongaUsageEstablishingPartner.updateCongaUsageHistoryRecords();                
            
    //        CreateMonthlyBulkUtilizationRecords cmburDUPE = new CreateMonthlyBulkUtilizationRecords();
    //    test.StopTest();

    //    /* SMH END TEST DUPLICATES FOR COVERAGE FOR NOW */
    //}
    
}