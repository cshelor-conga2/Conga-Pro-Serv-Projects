/**
* @author Giovanni Modica
* @date 20180724
* @version 1.00
* @description Test class for EmailMessageTrigger, EmailMessageHelper and EmailMessageAfertInsertHandler.
*/
@isTest
private class EmailMessageHelperTest{

    @testSetup 
    public static void setup() {
        RecordType recordType = [select Id from RecordType where DeveloperName = 'Draft' and SObjectType = 'SBQQ__Quote__c']; //'0125000000021ec'
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>();
        testQuotes.add(new SBQQ__Quote__c(SBQQ__Status__c = EmailMessageHelper.rejectedStatus, RecordTypeId = recordType.Id));
        testQuotes.add(new SBQQ__Quote__c(SBQQ__Status__c = EmailMessageHelper.negotiationCustomerStatus, RecordTypeId = recordType.Id));       
        insert testQuotes;
    }

    /**
    * @description testEmailInsertionWithQualifiedQuoteToField - 
    */
    public static testmethod void testEmailInsertionWithQualifiedQuoteToField() {
        SBQQ__Quote__c qualifiedQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Status__c = :EmailMessageHelper.negotiationCustomerStatus];
        
        Test.startTest();

        EmailMessage message = new EmailMessage();
        message.RelatedToId = qualifiedQuote.Id;
        message.Incoming = true;
        message.ToAddress = 'gmodica@na1mail.congacontracts.com';
        message.Subject = 'RE: test message';
        insert message;

        Test.stopTest();

        qualifiedQuote = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :message.RelatedToId];      
        System.assertEquals(EmailMessageHelper.negotiationLegalStatus, qualifiedQuote.SBQQ__Status__c);
    }
    
    /**
    * @description testEmailInsertionWithQualifiedQuoteCcField - 
    */
    public static testmethod void testEmailInsertionWithQualifiedQuoteCcField() {
        SBQQ__Quote__c qualifiedQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Status__c = :EmailMessageHelper.negotiationCustomerStatus];
        
        Test.startTest();
        
        EmailMessage message = new EmailMessage();
        message.RelatedToId = qualifiedQuote.Id;
        message.Incoming = true;
        message.ToAddress = 'gmodica@getconga.com';
        message.CcAddress = 'gmodica@na1mail.congacontracts.com';
        message.Subject = 'RE: test message';
        insert message;
        
        Test.stopTest();
        
        qualifiedQuote = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :message.RelatedToId];
        System.assertEquals(EmailMessageHelper.negotiationLegalStatus, qualifiedQuote.SBQQ__Status__c);
    }
    
    /**
    * @description testEmailInsertionWithoutQualifiedQuote - 
    */
    public static testmethod void testEmailInsertionWithoutQualifiedQuote() {
        SBQQ__Quote__c unqualifiedQuote = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Status__c = :EmailMessageHelper.rejectedStatus];
        Test.startTest();               
        EmailMessage message = new EmailMessage();
        message.RelatedToId = unqualifiedQuote.Id;
        message.Incoming = false; //changed to force unqualification.
        message.ToAddress = 'gmodica@na1mail.congacontracts.com';
        message.Subject = 'RE: test message';
        insert message;
        Test.stopTest();                
        unqualifiedQuote = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :message.RelatedToId];        
        System.assertEquals(EmailMessageHelper.rejectedStatus, unqualifiedQuote.SBQQ__Status__c);       
    }
    
    /**
    * @description testEmailInsertionWithoutQuote - 
    */
    public static testmethod void testEmailInsertionWithoutQuote() {
        Test.startTest();

        EmailMessage message = new EmailMessage();
        message.ToAddress = 'gmodica@systemyc.com';
        message.Subject = 'Test Message';
        insert message;

        Test.stopTest();
        
        List<EmailMessage> messages = [SELECT Id FROM EmailMessage WHERE ToAddress = 'gmodica@systemyc.com'];
        System.assertEquals(1, messages.size());
    }


}