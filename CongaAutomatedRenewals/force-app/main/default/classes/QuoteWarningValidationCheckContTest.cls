@isTest
public class QuoteWarningValidationCheckContTest {
    
    @testSetup
    static void setupTestData() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        Id quoteRecTypeId = Schema.SObjectType.SBQQ__Quote__c .getRecordTypeInfosByName().get('Draft').getRecordTypeId();
        
        Id UserRId = [SELECT Id FROM UserRole WHERE Name like :'CFO'].Id;
        Id UserRId2 = [SELECT Id FROM UserRole WHERE Name like :'Renewals Manager'].Id;
        Id pId = [SELECT Id FROM profile WHERE Name like :'Conga CS User'].Id;
        Id pId2 = [SELECT Id FROM profile WHERE Name like :'Conga Sales User'].Id;
        List<User> userList = new List<User>();
        
       /*  Profile p;
        List<Profile> listProfile = [SELECT Id FROM profile WHERE Name like :'Conga CS User'];
        if(listProfile.size() > 0) 
          p = listProfile[0]; */
        //creating the user
        User testUser = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                                emailencodingkey='UTF-8', lastname='Test', languagelocalekey='en_US',
                                localesidkey='en_US', profileid = pId, timezonesidkey='America/Los_Angeles',
                                username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true,
                                Extension='1234', CompanyName = 'test Company', UserRoleId = UserRId);
        userList.add(testUser);
        User testUser2 = new User(alias = 'testUse2', email='standarduser' + Math.random()  + '@testorg.com',
                                emailencodingkey='UTF-8', lastname='Test', languagelocalekey='en_US',
                                localesidkey='en_US', profileid = pId2, timezonesidkey='America/Los_Angeles',
                                username='teststandarduser2' + Math.random() + '@testorg.com', IsActive=true,
                                Extension='1234', CompanyName = 'test Company', UserRoleId = UserRId2);
        userList.add(testUser2);

        insert userList;
        testUser = [SELECT Id FROM User WHERE alias = 'testUser' LIMIT 1];

        System.runAs(testUser){
            Account accRec = new Account();
            accRec.Name = 'test account';
            accRec.RecordTypeId = accRecordTypeId;
            accRec.Industry = 'Manufacturing';
            insert accRec;
            
            Contact primaryCon = new Contact();
            primaryCon.LastName = 'TESTLAST';
            primaryCon.AccountId = accRec.Id;
            insert primaryCon;
            
            Opportunity oppRec = new Opportunity();
            oppRec.Name = 'Test Opportunity 1';
            oppRec.AccountId = accRec.Id;
            oppRec.Type = 'New Business';
            oppRec.Sub_Type__c = 'Standard';
            oppRec.StageName = 'Qualify';
            oppRec.CloseDate = date.today();
            oppRec.LeadSource = 'Prospecting';
            oppRec.Channel_Source_2__c = 'Prospecting';
            oppRec.Oppty_Channel_Source_2__c = 'Digital';
            
            insert oppRec;
            
            //Create Product
            Product2 product = new Product2(Name = 'Test Product', Family = 'Support',
                                        isActive = true,
                                        ProductCode = 'TEST Product Code');
            insert product;
            
            //Create the PricebookEntry
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = product.Id,
                UnitPrice = 1500,
                IsActive = true
            );
            insert pbe;
            
            SBQQ__Quote__c quoteRec = new SBQQ__Quote__c ();
            quoteRec.RecordTypeId = quoteRecTypeId;
            quoteRec.SBQQ__PaymentTerms__c = 'Net 15';
            quoteRec.Terms__c = 'Net 15';
            quoteRec.Approval_Request_Notes__c = NULL;
            quoteRec.SBQQ__Opportunity2__c = oppRec.id;
            quoteRec.Managed_Clauses__c = 0;
            quoteRec.SBQQ__OrderGroupID__c = 'quoteRec';
            insert quoteRec;
            
            SBQQ__Quote__c validQuoteRec = new SBQQ__Quote__c ();
            validQuoteRec.RecordTypeId = quoteRecTypeId;
            validQuoteRec.Terms__c = 'Net 30';
            validQuoteRec.SBQQ__Primary__c = TRUE;
            validQuoteRec.Auto_Renew__c = '1';
            validQuoteRec.Non_Payment_Late_Charge__c = 1;
            validQuoteRec.Expiration_Warning__c = 30;
            validQuoteRec.Managed_Clauses__c = 0;
            validQuoteRec.SBQQ__Type__c = 'Quote';
            validQuoteRec.SBQQ__PrimaryContact__c = primaryCon.Id;
            validQuoteRec.Approval_Request_Notes__c = 'TEST';
            validQuoteRec.OwnerId = testUser.Id;
            validQuoteRec.SBQQ__OrderGroupID__c = 'validQuoteRec';
            insert validQuoteRec;

            SBQQ__Quote__c quoteOverallSub = new SBQQ__Quote__c ();
            quoteOverallSub.SBQQ__Account__c = accRec.id;
            quoteOverallSub.RecordTypeId = quoteRecTypeId;
            quoteOverallSub.SBQQ__Type__c = 'Quote';
            quoteOverallSub.New_Products_Discount__c = 20;
            quoteOverallSub.Discount_Reason__c = NULL;
            quoteOverallSub.Terms__c = 'Net 15';
            quoteOverallSub.Approval_Request_Notes__c = NULL;
            quoteOverallSub.SBQQ__Opportunity2__c = oppRec.id;
            quoteOverallSub.Managed_Clauses__c = 0;
            quoteOverallSub.SBQQ__OrderGroupID__c = 'quoteOverallSub';
            insert quoteOverallSub;
        }
        
    }
    
    static testMethod void quoteWarningValCheckTest(){
        List<SBQQ__Quote__c> testQuoteRec = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__OrderGroupID__c = 'quoteRec'];
        System.assert(testQuoteRec.size() == 1);

        User testUser = [SELECT Id, alias FROM User WHERE alias = 'testUser' LIMIT 1];
        System.runAs(testUser){
            test.startTest();
            Test.setCurrentPage(Page.QuoteWarningValidationCheck);
            QuoteWarningValidationCheckController controller = new QuoteWarningValidationCheckController(new ApexPages.StandardController(testQuoteRec[0]));
            controller.checkQuote();
            QuoteWarningValidationCheckController.checkQuote(testQuoteRec[0].Id);
            test.stopTest();    
        }     
    }
    
    static testMethod void quoteIsValidCheckTest(){
        List<SBQQ__Quote__c> testValidQuoteRec = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__OrderGroupID__c = 'validQuoteRec'];
        System.assert(testValidQuoteRec.size() == 1);

        User testUser = [SELECT Id, alias FROM User WHERE alias = 'testUser' LIMIT 1];
        System.runAs(testUser){
            Test.startTest();

            Test.setCurrentPage(Page.QuoteWarningValidationCheck);
            QuoteWarningValidationCheckController controller = new QuoteWarningValidationCheckController(new ApexPages.StandardController(testValidQuoteRec[0]));
            controller.checkQuote();
            QuoteWarningValidationCheckController.checkQuote(testValidQuoteRec[0].Id);
            QuoteWarningValidationCheckController.quoteApprovalStatus(testValidQuoteRec[0].Id);
            try{
                QuoteWarningValidationCheckController.onSubmit(testValidQuoteRec[0].Id);
            } catch (Exception e){

            }

            try{
                QuoteWarningValidationCheckController.onRecall(testValidQuoteRec[0].Id);
            }
            catch (Exception e){

            }

            Test.stopTest();    
        }
    }

    static testMethod void recallOwnershipChangeTest(){
        List<SBQQ__Quote__c> testValidQuoteRec = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__OrderGroupID__c = 'validQuoteRec'];
        System.assert(testValidQuoteRec.size() == 1);

        Test.startTest();

        Test.setCurrentPage(Page.QuoteWarningValidationCheck);
        QuoteWarningValidationCheckController controller = new QuoteWarningValidationCheckController(new ApexPages.StandardController(testValidQuoteRec[0]));
        controller.checkQuote();
        QuoteWarningValidationCheckController.checkQuote(testValidQuoteRec[0].Id);
        QuoteWarningValidationCheckController.quoteApprovalStatus(testValidQuoteRec[0].Id);

        try{
            QuoteWarningValidationCheckController.onRecall(testValidQuoteRec[0].Id);
        }
        catch (Exception e){

        }

        Test.stopTest();    
    }

    static testMethod void quoteOwnerNotSubmitter(){
        List<SBQQ__Quote__c> testQuoteRec = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__OrderGroupID__c = 'quoteRec'];
        System.assert(testQuoteRec.size() == 1);

        User testUser2 = [SELECT Id, alias FROM User WHERE alias = 'testUse2' LIMIT 1];
        System.runAs(testUser2){
            Test.startTest();

            testQuoteRec[0].OwnerId = testUser2.Id;
            update testQuoteRec[0];
            System.assertEquals('testUse2', testUser2.Alias);

            Test.setCurrentPage(Page.QuoteWarningValidationCheck);
            QuoteWarningValidationCheckController controller = new QuoteWarningValidationCheckController(new ApexPages.StandardController(testQuoteRec[0]));
            controller.checkQuote();
            QuoteWarningValidationCheckController.checkQuote(testQuoteRec[0].Id);

            Test.stopTest();    
        }
    }

    static testMethod void quoteOverallSub(){
        List<SBQQ__Quote__c> testQuoteOverallSub = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__OrderGroupID__c = 'quoteOverallSub'];
        System.assert(testQuoteOverallSub.size() == 1);

        User testUser = [SELECT Id, alias FROM User WHERE alias = 'testUser' LIMIT 1];
        System.runAs(testUser){
            Test.startTest();

            Test.setCurrentPage(Page.QuoteWarningValidationCheck);
            QuoteWarningValidationCheckController controller = new QuoteWarningValidationCheckController(new ApexPages.StandardController(testQuoteOverallSub[0]));
            controller.checkQuote();
            QuoteWarningValidationCheckController.checkQuote(testQuoteOverallSub[0].Id);

            Test.stopTest();    
        } 
    }
    
    
    
}