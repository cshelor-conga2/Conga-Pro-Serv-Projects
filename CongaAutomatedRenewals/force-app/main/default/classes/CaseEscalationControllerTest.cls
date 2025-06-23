@isTest
private class CaseEscalationControllerTest {
    @testSetup
    private static void setup() {
        
    }
    
    @isTest
    private static void testSettings() {        
        Test.startTest();                
        
        CaseEscalationController.Settings settings = CaseEscalationController.getSettings();
        
        Test.stopTest();
    }

    @isTest
    private static void testVariables() {        
        Test.startTest();                
        
        String info = CaseEscalationController.getCongaSessionVariables();
        
        Test.stopTest();
        
        System.assertEquals('session&server', info);
    }
    
    @isTest
    private static void testEscalate() {        
        Case c = new Case(Status= 'New');
        insert c;
        
        Test.startTest();                
        
        Boolean success = CaseEscalationController.escalateCase(c.Id);
        
        Test.stopTest();
        
        c = [select Id,Status from Case where Id = :c.Id];
        
        System.assertEquals(true, success);
        System.assertEquals('Escalated to Tier 3', c.Status);
    }
}