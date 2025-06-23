@IsTest
public class QuoteLinesFilteredControllerTest {
    @testSetup static void setup(){
        
        //Create Account
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        //Create Contact
        Contact con = new Contact(LastName = 'Test',
                                  AccountId = acc.Id,
                                  Phone = '555');
        insert con;
        
        //Create Opportunity
        Opportunity opp = new Opportunity(Name = 'Test',
                                          AccountId = acc.Id,
                                          StageName = 'Prospecting',
                                          CloseDate = date.today()+ 365);
        insert opp;
        
        //Create Product
        Product2 prod = new Product2(Name = 'Test',
                                     ProductCode = 'TEST',
                                     Family = 'Test',
                                     Description = 'Description Test');
        insert prod;
        
        // Get Standard Pricebook ID
        Id standardPBID = Test.getStandardPricebookId();
        
        //Create Pricebook Entry
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = prod.Id,
                                                Pricebook2Id = standardPBID,
                                                UnitPrice = 999);
        insert pbe;
        
        //Create Quote
        SBQQ__Quote__c qt = new SBQQ__Quote__c(SBQQ__StartDate__c = date.today(),
                                               SBQQ__EndDate__c = date.today()+ 365,
                                               SBQQ__Opportunity2__c = opp.Id,
                                               SBQQ__Account__c = acc.Id,
                                               SBQQ__PrimaryContact__c = con.Id,
                                               SBQQ__SalesRep__c = UserInfo.getUserId());
        insert qt;
        
        //Create Quoteline Item
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, 
                                                        SBQQ__Product__c = prod.Id, 
                                                        SBQQ__Dimension__c = null);
        insert qli;
    }
    
    @isTest
    public static void testQLFC() {
        Test.startTest();
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__Quote__r.Id 
                                        FROM SBQQ__QuoteLine__c
                                        LIMIT 1 ];
        QuoteLinesFilteredController ctrlr = new QuoteLinesFilteredController();
        ctrlr.objId = quoteLine.SBQQ__Quote__r.Id;
        ctrlr.getQuoteLineList();
        Test.stopTest();
    }
}