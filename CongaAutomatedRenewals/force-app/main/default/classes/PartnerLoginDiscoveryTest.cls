@isTest
private class PartnerLoginDiscoveryTest {
    private static String identifierEmail = 'giovanni.modica@getconga.com';
    private static String identifierPhoneBD = '+1 1234567890';
    private static String identifierPhone = '+1 (123) 4567890';
    
	@testSetup
    private static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(FirstName = 'Giovanni', 
                              LastName = 'Modica', 
                              Email = identifierEmail, 
                              Username = 'gmodica@conga.logindiscovery.test.com',
                              EmailEncodingKey = 'ISO-8859-1',
                              Alias = 'gmodicat',
                              MobilePhone = identifierPhoneBD,
                              TimeZoneSidKey = 'America/Los_Angeles',
                              LocaleSidKey = 'en_US',
                              LanguageLocaleKey = 'en_US',
                              ProfileId = p.Id,
                              IsActive = true);
        insert testUser;
    }
    
    @isTest
    private static void testEmail() {
        Test.startTest();
        
        PageReference page = new PartnerLoginDiscovery().login(identifierEmail, '/', null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, page);
    }
    
    @isTest
    private static void testPhone() {
        Test.startTest();
        
        PageReference page = new PartnerLoginDiscovery().login(identifierPhone, '/', null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, page);
    }
}