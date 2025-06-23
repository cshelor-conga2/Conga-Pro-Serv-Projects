/**
* @author Jereriah Manning
* @date 20160531
* @version 1.00
* @description PPSignedAgrmtTEST - Created for Conga Partner Team
*/
@isTest
private class PPSignedAgrmtTEST{                   
    
    /**
    * @description testAgreementSignedPost - 
    */
    static testMethod void testAgreementSignedPost(){
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
        
        Map<String, RecordType> AcctRTMap = new Map<String, RecordType>();
        for(RecordType AcctRT : [SELECT Id, DeveloperName FROM RecordType WHERE IsActive = TRUE AND SObjectType = 'Account']){
            AcctRTMap.put(AcctRT.DeveloperName, AcctRT);   
        }
        
        Map<String, RecordType> PPRTMap = new Map<String, RecordType>();
        for(RecordType PPRT : [SELECT Id, DeveloperName FROM RecordType WHERE IsActive = TRUE AND SObjectType = 'Partner_Profile__c']){
            PPRTMap.put(PPRT.DeveloperName, PPRT);   
        }                
        
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test Account 1';
        testAccount1.BillingCountry = 'United States';
        testAccount1.RecordTypeId = AcctRTMap.get('Partner_Account').Id;
        testAccount1.Type = 'Partner';
        Database.insert(testAccount1);
            
        Partner_Profile__c PPtestRecord1 = new Partner_Profile__c();
        PPtestRecord1.Account__c = testAccount1.Id;
        PPtestRecord1.RecordTypeId = PPRTMap.get('SI_Partner').Id;
        Database.insert(PPtestRecord1);

        //Test.startTest();

        //dsfs__DocuSign_Status__c DStestRecord1 = new dsfs__DocuSign_Status__c();
        //DStestRecord1.Partner_Profile__c = PPtestRecord1.Id;
        //DStestRecord1.dsfs__Envelope_Status__c = 'Sent';
        //Database.insert(DStestRecord1);
                    
        //DStestRecord1.dsfs__Envelope_Status__c = 'Completed';
        //Database.update(DStestRecord1);     

        //Test.stopTest();  
    }

    /**
    * @description testAgreementSignedNegative - 
    */    
    static testMethod void testAgreementSignedNegative(){
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
        
        Map<String, RecordType> AcctRTMap = new Map<String, RecordType>();
        for(RecordType AcctRT : [SELECT Id, DeveloperName FROM RecordType WHERE IsActive = TRUE AND SObjectType = 'Account']){
            AcctRTMap.put(AcctRT.DeveloperName, AcctRT);   
        }
        
        Map<String, RecordType> PPRTMap = new Map<String, RecordType>();
        for(RecordType PPRT : [SELECT Id, DeveloperName FROM RecordType WHERE IsActive = TRUE AND SObjectType = 'Partner_Profile__c']){
            PPRTMap.put(PPRT.DeveloperName, PPRT);   
        }  
        
        Account testAccount2 = new Account();
        testAccount2.Name = 'Test Account 2';
        testAccount2.BillingCountry = 'United States';
        testAccount2.RecordTypeId = AcctRTMap.get('Partner_Account').Id;
        testAccount2.Type = 'Partner - NonProfit';
        Database.insert(testAccount2);
                    
        Partner_Profile__c PPtestRecord2 = new Partner_Profile__c();
        PPtestRecord2.Account__c = testAccount2.Id;
        PPtestRecord2.RecordTypeId = PPRTMap.get('Hybrid_Partner').Id;
        Database.insert(PPtestRecord2);   
                
        //Test.startTest();

        //dsfs__DocuSign_Status__c DStestRecord2 = new dsfs__DocuSign_Status__c();
        //DStestRecord2.dsfs__Envelope_Status__c = 'Sent';
        //Database.insert(DStestRecord2);
                                                    
        //DStestRecord2.dsfs__Envelope_Status__c = 'Completed';
        //Database.update(DStestRecord2);
        //Database.delete(DStestRecord2);    

        //Test.stopTest();    
    }

    /**
    * @description testAgreementSignedPostBULK - 
    */ 
    static testMethod void testAgreementSignedPostBULK(){
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
        
        Map<String, RecordType> AcctRTMap = new Map<String, RecordType>();
        for(RecordType AcctRT : [SELECT Id, DeveloperName FROM RecordType WHERE IsActive = TRUE AND SObjectType = 'Account']){
            AcctRTMap.put(AcctRT.DeveloperName, AcctRT);   
        }
        
        Map<String, RecordType> PPRTMap = new Map<String, RecordType>();
        for(RecordType pprt : [SELECT Id, DeveloperName FROM RecordType WHERE IsActive = TRUE AND SObjectType = 'Partner_Profile__c']){
            PPRTMap.put(pprt.DeveloperName, pprt);   
        }  
        
        //List<dsfs__DocuSign_Status__c> DSRecordsForBulkTest = new List<dsfs__DocuSign_Status__c>();
        
        Account testAccount3 = new Account();
        testAccount3.Name = 'Test Account 3';
        testAccount3.BillingCountry = 'United States';
        testAccount3.RecordTypeId = AcctRTMap.get('Partner_Account').Id;
        testAccount3.Type = 'Partner';
        Database.insert(testAccount3);
            
        Partner_Profile__c PPtestRecord3 = new Partner_Profile__c();
        PPtestRecord3.Account__c = testAccount3.Id;
        PPtestRecord3.RecordTypeId = PPRTMap.get('OEM_Partner').Id;
        Database.insert(PPtestRecord3);
        
        //for(Integer i = 3; i < 504; i++){
        //    dsfs__DocuSign_Status__c DStestRecord = new dsfs__DocuSign_Status__c();
        //    DStestRecord.Partner_Profile__c = PPtestRecord3.Id;
        //    DStestRecord.dsfs__Envelope_Status__c = 'Sent';
        //    DSRecordsForBulkTest.add(DStestRecord);   
        //}        
        //Database.insert(DSRecordsForBulkTest); 

        // Clear the list to do updates and not possibly double update each record
        //DSRecordsForBulkTest.clear();

        //Test.startTest();

        //for(dsfs__DocuSign_Status__c DSRecord : DSRecordsForBulkTest){
        //    DSRecord.dsfs__Envelope_Status__c = 'Completed';
        //    DSRecordsForBulkTest.add(DSRecord);    
        //}                                                       
        //Database.update(DSRecordsForBulkTest);
        
        //Test.stopTest();
    }


}