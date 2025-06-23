/**
* @author Conga Services, KSears
* @date 20190305
* @version 1.00
* @description ConvertSupportRequestTest - Test Class Convert Support Request
*/
@isTest
public class ConvertSupportRequestTest {

    /** 
    * @description testHappyPath
    */  
    public static testmethod void testHappyPath() {
        String srId = ApexPages.currentPage().getParameters().get('id'); 
        Support_Request__c sr = new Support_Request__c();
        sr.Subject__c = 'Test Subject';
        insert sr;

        Product2 prod = new Product2();
        prod.Name = 'ProServe Hour';
        prod.ProductCode = 'Test';
        insert prod;

        Pricebook2 pb = new Pricebook2();
        pb.Name = '2018-2019 Pricebook';
        insert pb;

        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);
        ApexPages.currentPage().getParameters().put('Id', sr.Id);
        Test.startTest();

        ConvertSupportRequest controller = new ConvertSupportRequest(stdController);
        PageReference result = controller.autoRun();

        Test.stopTest();
    }

    /** 
    * @description testNoId
    */  
    public static testmethod void testNoId() {
        String srId = ApexPages.currentPage().getParameters().get('id'); 
        Support_Request__c sr = new Support_Request__c();
        sr.Subject__c = 'Test Subject';
        insert sr;

        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();

        ConvertSupportRequest controller = new ConvertSupportRequest(stdController);
        PageReference result = controller.autoRun();

        Test.stopTest();
    }
    
    /** 
    * @description testHasProject
    */  
    public static testmethod void testHasProject() {
        String srId = ApexPages.currentPage().getParameters().get('id'); 
        Id recordTypeId = Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('BSI Project (Internal)').getRecordTypeId();

        PS_Project__c bsp = new PS_Project__c();
        bsp.Name = 'Test Proj';
        bsp.RecordTypeId = RecordTypeId;
        insert bsp;

        Support_Request__c sr = new Support_Request__c();
        sr.Subject__c = 'Test Subject';
        sr.BSI_Project__c = bsp.Id;
        insert sr;

        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);
        ApexPages.currentPage().getParameters().put('Id', sr.Id);

        Test.startTest();

        ConvertSupportRequest controller = new ConvertSupportRequest(stdController);
        PageReference result = controller.autoRun();

        Test.stopTest();
    }


}