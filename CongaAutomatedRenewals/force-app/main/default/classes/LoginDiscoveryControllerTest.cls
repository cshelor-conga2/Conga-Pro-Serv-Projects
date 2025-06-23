@isTest
private class LoginDiscoveryControllerTest {
    private static String identifierEmail = 'giovanni.modica@getconga.com';
    private static String identifierPhone = '+1 (123) 4567890';
    
    @testSetup
    private static void setup() {
        
    }
    
    @isTest
    private static void test() {        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(FirstName = 'Giovanni', 
                              LastName = 'Modica', 
                              Email = identifierEmail, 
                              Username = 'gmodica@conga.logindiscovery.test.com',
                              EmailEncodingKey = 'ISO-8859-1',
                              Alias = 'gmodicat',
                              MobilePhone = identifierPhone,
                              TimeZoneSidKey = 'America/Los_Angeles',
                              LocaleSidKey = 'en_US',
                              LanguageLocaleKey = 'en_US',
                              ProfileId = p.Id,
                              IsActive = true);
        insert testUser;
        
        Test.startTest();
        
        LoginDiscoveryController controller = new LoginDiscoveryController();
        controller.email = identifierEmail;
        controller.startUrl = '/';
        PageReference page = controller.submit();
        
        Test.stopTest();
        
        System.assertEquals(null, controller.showError);
    }
    
    @isTest
    private static void testError() {
        Test.startTest();
        
        LoginDiscoveryController controller = new LoginDiscoveryController();
        controller.email = identifierEmail;
        controller.startUrl = '/';
        PageReference page = controller.submit();
        
        Test.stopTest();
        
        System.assertEquals(true, controller.showError);
    }
}