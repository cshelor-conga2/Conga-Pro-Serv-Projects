/**
* @author Conga, dnelson
* @date 20180306
* @version 1.0
* @description SRControllerTest - Test class for the SRController class
*/
@isTest
private class SRControllerTest {

    /**
    * @description testNullId - 
    */
    static testmethod void testNullId() {
        Support_Request__c sr = new Support_Request__c();
        sr.Subject__c = 'Test Subject';
        sr.Assignment__c = null;
        insert sr;

        Assignment__c a = new Assignment__c();
        a.Status__c = 'Backlog';
        a.IsOverflow__c = true;
        a.Subject__c = 'Dani is the best';
        a.OwnerId = UserInfo.getUserId();
        a.Description__c = 'This is a description'; 
        insert a;

        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);

        Test.startTest();

        SRController controller = new SRController(stdController);
        PageReference result = controller.autoRun();

        Test.stopTest();
    }

    /**
    * @description testIdExists - 
    */
    static testmethod void testIdExists() {
        Support_Request__c sr = new Support_Request__c();
        sr.Subject__c = 'Test Subject';
        sr.Assignment__c = null;
        sr.BSI_Project__c = null;
        insert sr;

        Assignment__c a = new Assignment__c();
        a.Status__c = 'Backlog';
        a.IsOverflow__c = true;
        a.Subject__c = 'Dani is the best';
        a.OwnerId = UserInfo.getUserId();
        a.Description__c = 'This is a description'; 
        insert a;

        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);
        ApexPages.currentPage().getParameters().put('Id', sr.Id);

        Test.startTest();

        SRController controller = new SRController(stdController);
        PageReference result = controller.autoRun();

        Test.stopTest();

        System.assertNotEquals(null, sr.Id);
    }

    /**
    * @description testBSIProject - 
    */
    static testmethod void testBSIProject() {
        //BSI Project != null and milestone = null

        Id recordTypeId = Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('BSI Project (Internal)').getRecordTypeId();

        PS_Project__c bsp = new PS_Project__c();
        bsp.Name = 'Conga Onboarding';
        bsp.RecordTypeId = RecordTypeId;
        insert bsp;

        Support_Request__c sr = new Support_Request__c();
        sr.Subject__c = 'Test Subject';
        sr.Assignment__c = null;
        sr.BSI_Project__c = bsp.Id;
        insert sr;

        Assignment__c a = new Assignment__c();
        a.Status__c = 'Backlog';
        a.IsOverflow__c = true;
        a.Subject__c = 'Dani is the best';
        a.OwnerId = UserInfo.getUserId();
        a.Description__c = 'This is a description'; 

        insert a;

        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);
        ApexPages.currentPage().getParameters().put('Id', sr.Id);

        Test.startTest();

        SRController controller = new SRController(stdController);
        PageReference result = controller.autoRun();

        sr.Status__c = 'In Delivery Queue';
        sr.Assignment__c = a.Id;
        update sr;

        Test.stopTest();

        System.assertEquals(bsp.Id, sr.BSI_Project__c); 
    }

    /**
    * @description testMilestone - 
    */
    static testmethod void testMilestone() {
        //milestone is present

        Id recordTypeId = Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('BSI Project (Internal)').getRecordTypeId();

        PS_Project__c bsp = new PS_Project__c();
        bsp.Name = 'Conga Onboarding';
        bsp.RecordTypeId = RecordTypeId;
        insert bsp;

        Milestone__c m = new Milestone__c();
        m.Name = 'Test Milestone';
        m.ProjectId__c = bsp.Id;
        insert m;

        Support_Request__c sr = new Support_Request__c();
        sr.Subject__c = 'Test Subject';
        sr.BSI_Project__c = bsp.Id;
        insert sr;

        Assignment__c a = new Assignment__c();
        a.Status__c = 'Backlog';
        a.MilestoneId__c = m.Id;
        a.IsOverflow__c = true;
        a.Subject__c = 'Dani is the best';
        a.OwnerId = UserInfo.getUserId();
        a.Description__c = 'This is a description'; 

        insert a;

        ApexPages.StandardController stdController = new ApexPages.StandardController(sr);
        ApexPages.currentPage().getParameters().put('Id', sr.Id);

        Test.startTest();

        SRController controller = new SRController(stdController);
        PageReference result = controller.autoRun();

        sr.Status__c = 'In Delivery Queue';
        sr.Assignment__c = a.Id;
        update sr;

        Test.stopTest();

        System.assertEquals(a.MilestoneId__c, m.Id);

        List<Milestone__c> em = [SELECT Id, Name, ProjectId__c FROM Milestone__c WHERE ProjectId__c = :sr.BSI_Project__c LIMIT 1];
        System.assertEquals(1, em.size());
    }


}