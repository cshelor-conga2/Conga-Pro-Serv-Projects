@isTest
public class Flow_Trigger_HandlerTest {
    @isTest
    static void testVisionContentVersionTrigger() {
        // Create a Vision__c record to get the Id prefix
        Vision__c vision = new Vision__c(Line_of_Coverage__c = 'Vision');
        insert vision;
        String visionIdPrefix = String.valueOf(vision.Id).substring(0, 3);

        // Create an Account to use as a control (should not trigger the flow)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a ContentVersion related to Vision__c (should trigger the flow)
        ContentVersion cvVision = new ContentVersion(
            Title = 'Vision File',
            PathOnClient = 'VisionFile.txt',
            VersionData = Blob.valueOf('Test data'),
            FirstPublishLocationId = vision.Id
        );

        // Create a ContentVersion related to Account (should NOT trigger the flow)
        ContentVersion cvAccount = new ContentVersion(
            Title = 'Account File',
            PathOnClient = 'AccountFile.txt',
            VersionData = Blob.valueOf('Test data'),
            FirstPublishLocationId = acc.Id
        );

        Test.startTest();
        insert new List<ContentVersion>{cvVision, cvAccount};
        Test.stopTest();

        // Optionally, assert that the ContentVersion records exist
        List<ContentVersion> cvs = [SELECT Id, FirstPublishLocationId FROM ContentVersion WHERE Id IN :new List<Id>{cvVision.Id, cvAccount.Id}];
        System.assertEquals(2, cvs.size());
    }
}