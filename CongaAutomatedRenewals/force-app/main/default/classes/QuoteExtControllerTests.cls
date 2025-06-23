@isTest
private class QuoteExtControllerTests {
    
    testMethod static void testSubmit() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', quote.ApprovalStatus__c);
    }
    
    testMethod static void testRecall() {
        // CREATE TEST SALES USER MANAGER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'sales2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8',
        FirstName = 'Sales', LastName = 'Person2', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser2' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(OwnerId = salesUser.Id);
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', quote.ApprovalStatus__c);
    }
}