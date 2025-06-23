@isTest
public class ApprovalsTableControllerTest {
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
        
        //Create Pricebook
        Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId());
        update standardPB;
        
        //Create Pricebook Entry
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = prod.Id,
                                                Pricebook2Id = standardPB.Id,
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
        
        //Create Approval
        sbaa__Approval__c app = new sbaa__Approval__c(sbaa__ApprovalStep__c = 1,
                                                      sbaa__RecordField__c = 'TEST',
                                                      Quote__c = qt.Id);
        insert app;
    }
    
    @isTest
    public static void testATC() {
        Test.startTest();
        sbaa__Approval__c approval = [SELECT Id, Quote__r.Id 
                                      FROM sbaa__Approval__c
                                      LIMIT 1 ];
        ApprovalsTableController ctrlr = new ApprovalsTableController();
        ctrlr.objId = approval.Quote__r.Id;
        ctrlr.getApprovalsList();
        Test.stopTest();
    }
}