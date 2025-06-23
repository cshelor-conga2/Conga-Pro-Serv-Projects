/**
* @author Conga Services
* @date 20180615
* @version 1.00
* @description ContactHelperTest - Test methods for the ContactHelper class
*/

@isTest
private class ContactHelperTest {

    /**
    * @description setup - Create test data
    */
    @testSetup
    public static void setup() {
        Campaign campaign1 = new Campaign(Name = 'Test Campaign 1', IsActive = true, Product_Interest__c = 'Conga Composer');
        Campaign campaign2 = new Campaign(Name = 'Test Campaign 2', IsActive = true, Product_Interest__c = 'Conga Composer');
        Campaign campaign3 = new Campaign(Name = 'Test Campaign 3', IsActive = true, Product_Interest__c = 'Conga ActionGrid');
        Campaign inactiveCampaign = new Campaign(Name = 'Test Campaign 3', IsActive = false, Product_Interest__c = 'Conga Composer');
        insert new List<Campaign>{campaign1, campaign2, campaign3, inactiveCampaign};
            
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;  

        // TEST COUNTRY RECORDS 
        List<Country_Territory__c> testCountries = new List<Country_Territory__c>();
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'AMER');
        insert new List<Country_Territory__c>{ unitedStates };

        // TEST STATE RECORDS
        State_Province__c colorado = new State_Province__c(Name = 'Colorado', English_Name__c = 'Colorado', Code__c = 'CO', Country_TerritoryId__c = unitedStates.Id);
        State_Province__c california = new State_Province__c(Name = 'California', English_Name__c = 'California', Code__c = 'CA', Country_TerritoryId__c = unitedStates.Id);
        insert new List<State_Province__c>{ colorado, california };
        
    }

    /**
    * @description setApttusIntegrationStatusesTest - Test setApttusIntegrationStatuses trigger method
    */
    public static testMethod void setApttusIntegrationStatusesTest(){
        // CREATE TEST CONTACTS
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', true, 5);
        testContacts[0].FirstName = 'John';
        testContacts[0].LastName = 'Smith';
        //
        testContacts[1].FirstName = 'John';
        testContacts[1].LastName = 'Doe';
        //
        testContacts[2].FirstName = 'Jane';
        testContacts[2].LastName = 'Doe';
        //
        testContacts[3].FirstName = 'Jim';
        testContacts[3].LastName = 'Slim';
        //
        testContacts[4].FirstName = 'Tim';
        testContacts[4].LastName = 'Allen';
        insert testContacts;

        /////// TEST UPDATES
        testContacts[1].FirstName = 'Jonathan';
        testContacts[1].A1_Contact_ID__c = 'TestID1234';
        testContacts[1].A1_Integration_Status__c = null;
        //
        testContacts[2].MailingStreet = '1234 Test Rd.';
        testContacts[2].A1_Contact_ID__c = 'TestID4321';
        testContacts[2].A1_Integration_Status__c = null;
        //
        testContacts[3].OtherCity = 'Denver';
        testContacts[3].A1_Contact_ID__c = 'TestID5678';
        testContacts[3].A1_Integration_Status__c = null;     
        //
        testContacts[4].LastName = 'Williams';
        testContacts[4].A1_Contact_ID__c = null;
        testContacts[4].A1_Integration_Status__c = null;
        update new List<Contact>{ testContacts[1], testContacts[2], testContacts[3], testContacts[4] };

        // REFRESH CONTACTS AND CHECK FOR CORRECT DATA
        testContacts = [SELECT A1_Contact_ID__c, A1_Integration_Status__c FROM Contact WHERE Id IN :testContacts];
        // CONTACT 1, CREATE, BLANK STATUS, NO INTEGRATION ID
        System.assert(testContacts[0].A1_Integration_Status__c == 'Eligible');

        // CONTACT 2, UPDATE, CHANGE FIRST NAME, BLANK STATUS, INTEGRATION ID
        System.assert(testContacts[1].A1_Integration_Status__c == 'Eligible');

        // CONTACT 2, UPDATE, CHANGE MAILING ADDRESS, BLANK STATUS, INTEGRATION ID
        System.assert(testContacts[2].A1_Integration_Status__c == 'Eligible');

        // CONTACT 2, UPDATE, CHANGE OTHER ADDRESS, BLANK STATUS, INTEGRATION ID
        System.assert(testContacts[3].A1_Integration_Status__c == 'Eligible');

        // CONTACT 3, UPDATE, CHANGE LAST NAME, BLANK STATUS, NO INTEGRATION ID
        System.assert(String.isBlank(testContacts[4].A1_Integration_Status__c));
    }

    /**
    * @description setApttusIntegrationOwnerTest - Test setApttusIntegrationOwner trigger method
    */
    public static testMethod void setApttusIntegrationOwnerTest(){
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'admin1', Email = 'salesforce@conga123.com', EmailEncodingKey = 'UTF-8', FirstName = 'Sales', LastName = 'Person', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', Team__c = 'US Corporate Sales',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert salesUser;

        User salesUser2 = new User(Alias = 'admin2', Email = 'salesforce@conga456.com', EmailEncodingKey = 'UTF-8', FirstName = 'Sales', LastName = 'Person 2', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', Team__c = 'US Corporate Sales',
        UserName = 'testUser2' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert salesUser2;

        // CREATE TEST CONTACTS, TEST INSERTS
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', true, 3);
        testContacts[0].A1_Owner_Email__c = '';
        testContacts[1].A1_Owner_Email__c = 'salesforce@conga123.com';
        testContacts[2].A1_Owner_Email__c = 'salesforce@conga456.com';
        insert testContacts;

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testContacts = [SELECT Id, OwnerId, A1_Owner_Email__c FROM Contact WHERE Id IN :testContacts];
        System.assert(testContacts[0].OwnerId == UserInfo.getUserId());
        System.assert(testContacts[1].OwnerId == salesUser.Id);
        System.assert(testContacts[2].OwnerId == salesUser2.Id);

        // TEST UPDATES
        testContacts[0].A1_Owner_Email__c = 'salesforce@conga123.com';
        testContacts[1].A1_Owner_Email__c = 'salesforce@conga456.com';
        testContacts[2].A1_Owner_Email__c = '';
        update testContacts;

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testContacts = [SELECT Id, OwnerId, A1_Owner_Email__c FROM Contact WHERE Id IN :testContacts];
        System.assert(testContacts[0].OwnerId == salesUser.Id);
        System.assert(testContacts[1].OwnerId == salesUser2.Id);
        System.assert(testContacts[2].OwnerId == salesUser2.Id); // IF EMAIL IS BLANKED, CURRENT OWNER WILL REMAIN
    }

    /**
    * @description removeDepartedFromLastNameTest - Test for the removeDepartedFromLastName trigger method
    */    
    public static testMethod void removeDepartedFromLastNameTest(){
        // CREATE TEST CONTACTS
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', true, 10);
        testContacts[0].LastName = 'Smith Departed';
        testContacts[1].LastName = 'John - Departed';
        testContacts[2].LastName = 'Doe-Departed';
        testContacts[3].LastName = 'Slim - DEPARTED';
        testContacts[4].LastName = 'Allen-DEPARTED';
        testContacts[5].LastName = 'Raffi- Departed';
        testContacts[6].LastName = 'Ruggles, Departed';
        testContacts[7].LastName = 'Abbott (Departed)';
        testContacts[8].LastName = 'Frank(Departed)';
        testContacts[9].LastName = 'MugginsDeparted';
        insert testContacts;

        // REFRESH CONTACTS AND CHECK FOR CORRECT DATA
        testContacts = [SELECT LastName, Contact_Status__c FROM Contact WHERE Id IN :testContacts];
        System.assert(testContacts[0].LastName == 'Smith' && testContacts[0].Contact_Status__c == 'Departed');
        System.assert(testContacts[1].LastName == 'John' && testContacts[1].Contact_Status__c == 'Departed');
        System.assert(testContacts[2].LastName == 'Doe' && testContacts[2].Contact_Status__c == 'Departed');
        System.assert(testContacts[3].LastName == 'Slim' && testContacts[3].Contact_Status__c == 'Departed');
        System.assert(testContacts[4].LastName == 'Allen' && testContacts[4].Contact_Status__c == 'Departed');
        System.assert(testContacts[5].LastName == 'Raffi' && testContacts[5].Contact_Status__c == 'Departed');
        System.assert(testContacts[6].LastName == 'Ruggles' && testContacts[6].Contact_Status__c == 'Departed');
        System.assert(testContacts[7].LastName == 'Abbott' && testContacts[7].Contact_Status__c == 'Departed');
        System.assert(testContacts[8].LastName == 'Frank' && testContacts[8].Contact_Status__c == 'Departed');
        System.assert(testContacts[9].LastName == 'Muggins' && testContacts[9].Contact_Status__c == 'Departed');
    } 

    /**
    * @description addCampaignMembers_BaseTest - Test Method 1
    */    
     public static testMethod void addCampaignMembers_BaseTest(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccounts.size() == 1);

        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign 1'];
        System.assert(testCampaigns.size() == 1);

        Contact c = new Contact(LastName = 'Test', Email = 'Test@test.com', AccountId = testAccounts[0].Id);
        insert c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(null, c.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId =: c.Id];
        System.assertEquals(true, members.isEmpty());
        
        c.SF_Campaign_ID__c = testCampaigns[0].Id;
        update c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id =: c.Id];
        System.assertNotEquals(null, c.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id, c.SF_Campaign_ID__c);
        
        members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId =: c.Id];
        System.assertEquals(false, members.isEmpty());
        System.assertEquals(1, members.size());
        System.assertEquals(c.Id, members[0].ContactId);
        System.assertEquals(testCampaigns[0].Id, members[0].CampaignId);  
    } 

    /**
    * @description addCampaignMembersTest_MultipleCampaigns - Test Method 2
    */       
    public static testMethod void addCampaignMembersTest_MultipleCampaigns(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccounts.size() == 1);

        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE IsActive = true];
        System.assert(testCampaigns.size() == 3);

        Contact c = new Contact(LastName = 'Test', Email = 'Test@test.com', AccountId = testAccounts[0].Id);
        Insert c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id =: c.Id];
        System.assertEquals(null, c.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :c.Id];
        System.assertEquals(true, members.isEmpty());
        
        String campaignIDs = testCampaigns[0].Id + ';' + testCampaigns[1].Id + ';' + testCampaigns[2].Id;
        c.SF_Campaign_ID__c = campaignIDs;
        update c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :c.Id];
        System.assertNotEquals(null, c.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id + ';' + testCampaigns[1].Id + ';' + testCampaigns[2].Id, c.SF_Campaign_ID__c);
        
        members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :c.Id ORDER BY CampaignId];
        System.assertEquals(false, members.isEmpty());
        System.assertEquals(3, members.size());
        System.assertEquals(c.Id, members[0].ContactId);
        System.assertEquals(c.Id, members[1].ContactId);
        System.assertEquals(c.Id, members[2].ContactId);
        System.assertEquals(testCampaigns[0].Id, members[0].CampaignId);
        System.assertEquals(testCampaigns[1].Id, members[1].CampaignId);
        System.assertEquals(testCampaigns[2].Id, members[2].CampaignId);
    } 

    /**
    * @description addCampaignMembers_InactiveCampaignID - Test Method 3
    */       
    public static testMethod void addCampaignMembers_InactiveCampaignID(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccounts.size() == 1);

        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE IsActive = false];
        System.assert(testCampaigns.size() == 1);

        Contact c = new Contact(LastName = 'Test', Email = 'Test@test.com', AccountId = testAccounts[0].Id);
        insert c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(null, c.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :c.Id];
        System.assertEquals(true, members.isEmpty());
        
        c.SF_Campaign_ID__c = testCampaigns[0].Id;
        update c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :c.Id];
        System.assertNotEquals(null, c.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id, c.SF_Campaign_ID__c);
        
        members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :c.Id Order by CampaignId];
        System.assertEquals(true, members.isEmpty());
        System.assertEquals(0, members.size());
    } 

    /**
    * @description addCampaignMembers_NonExistentCampaign - Test Method 4
    */           
    public static testMethod void addCampaignMembers_NonExistentCampaign(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccounts.size() == 1);

        Contact c = new Contact(LastName = 'Test', Email = 'Test@test.com', AccountId = testAccounts[0].Id);
        insert c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(null, c.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :c.Id];
        System.assertEquals(true, members.isEmpty());
        
        c.SF_Campaign_ID__c = '7011800000XXXXX';
        update c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :c.Id];
        System.assertNotEquals(null, c.SF_Campaign_ID__c);
        System.assertEquals('7011800000XXXXX', c.SF_Campaign_ID__c);
        
        members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :c.Id ORDER BY CampaignId];
        System.assertEquals(true, members.isEmpty());
        System.assertEquals(0, members.size());
    } 

    /**
    * @description addCampaignMembers_InvalidCampaignIdTest - Test Method 5
    */           
    public static testMethod void addCampaignMembers_InvalidCampaignIdTest(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccounts.size() == 1);

        Contact c = new Contact(LastName = 'Test', Email = 'Test@test.com', AccountId = testAccounts[0].Id);
        insert c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(null, c.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :c.Id];
        System.assertEquals(true, members.isEmpty());
        
        c.SF_Campaign_ID__c = '7011800000XXXXX ()';
        update c;
        
        c = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :c.Id];
        System.assertNotEquals(null, c.SF_Campaign_ID__c);
        System.assertEquals('7011800000XXXXX ()', c.SF_Campaign_ID__c);
        
        members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :c.Id ORDER BY CampaignId];
        System.assertEquals(true, members.isEmpty());
        System.assertEquals(0, members.size());

        List<System_Issue_Log__c> loggedErrors = [SELECT Id FROM System_Issue_Log__c];
        System.assert(!loggedErrors.isEmpty());
    } 

    /**
    * @description addCampaignMembers_MultipleContactTest - Test Method 6
    */       
    public static testMethod void addCampaignMembers_MultipleContactTest(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccounts.size() == 1);

        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name IN ('Test Campaign 1', 'Test Campaign 2')];
        System.assert(testCampaigns.size() == 2);
       
        Contact con1 = new Contact(LastName = 'Test 1', Email = 'Test@test.com', AccountId = testAccounts[0].Id);
        Contact con2 = new Contact(LastName = 'Test 2', Email = 'Test@test.com', AccountId = testAccounts[0].Id);
        insert new List<Contact>{ con1, con2 };
        
        con1 = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :con1.Id];
        con2 = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :con2.Id];
        System.assertEquals(null, con1.SF_Campaign_ID__c);
        System.assertEquals(null, con2.SF_Campaign_ID__c);
        
        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :con1.Id OR LeadId = :con2.Id];
        System.assertEquals(true, members.isEmpty());
        
        con1.SF_Campaign_ID__c = testCampaigns[0].Id;
        con2.SF_Campaign_ID__c = testCampaigns[1].Id;
        update con1;
        update con2;
        
        con1 = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :con1.Id];
        con2 = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :con2.Id];
        System.assertNotEquals(null, con1.SF_Campaign_ID__c);
        System.assertNotEquals(null, con1.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id, con1.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[1].Id, con2.SF_Campaign_ID__c);
        
        members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :con1.Id OR ContactId = :con2.Id];
        System.assertEquals(false, members.isEmpty());
        System.assertEquals(2, members.size());
        System.assertEquals(con1.Id, members[0].ContactId);
        System.assertEquals(con2.Id, members[1].ContactId);
        System.assertEquals(testCampaigns[0].Id, members[0].CampaignId);
        System.assertEquals(testCampaigns[1].Id, members[1].CampaignId);
    } 

    /**
    * @description addCampaignMembers_ExistingMemberTest - Test Method 7
    */    
    public static testMethod void addCampaignMembers_ExistingMemberTest(){
        // GET TEST ACCOUNT
        List<Account> testAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        System.assert(testAccounts.size() == 1);

        // GET TEST CAMPAIGN
        List<Campaign> testCampaigns = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign 1'];
        System.assert(testCampaigns.size() == 1);

        Contact contact = new Contact(LastName = 'Test', Email = 'Test@test.com', AccountId = testAccounts[0].Id);
        insert contact;
        
        contact = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals(null, contact.SF_Campaign_ID__c);
        
        CampaignMember existingMember = new CampaignMember(ContactId = contact.Id, CampaignId = testCampaigns[0].Id, Status = 'Sent');
        insert existingMember;

        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :contact.Id];
        System.assertEquals(true, members.size() == 1);
        
        contact.SF_Campaign_ID__c = testCampaigns[0].Id;
        update contact;
        
        contact = [SELECT Id, SF_Campaign_ID__c FROM Contact WHERE Id =: contact.Id];
        System.assertNotEquals(null, contact.SF_Campaign_ID__c);
        System.assertEquals(testCampaigns[0].Id, contact.SF_Campaign_ID__c);
        
        members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId = :contact.Id];
        System.assertEquals(1, members.size());
        System.assertEquals(contact.Id, members[0].ContactId);
        System.assertEquals(testCampaigns[0].Id, members[0].CampaignId);  
    } 
    
    /**
    * @description validateStateAndCountryTest - Test validateStateAndCountry trigger method
    */
     public static testMethod void validateStateAndCountryTest(){
        Test.startTest();

        // CREATE TEST CONTACT
        List<Contact> testContacts = TestingUtility.createSObjectList('Contact', true, 1);
        testContacts[0].FirstName = 'Test';
        testContacts[0].LastName = 'Contact';
        testContacts[0].MailingState = 'CO';
        testContacts[0].MailingCountry = 'USA';
        testContacts[0].OtherState = 'CA';
        testContacts[0].OtherCountry = 'USA';
        insert testContacts;

        // TEST THAT COUNTRIES AND STATES WERE PROPERLY CONVERTED TO THEIR FULL NAMES
        testContacts = [SELECT Id, Name, MailingState, Mailing_State_Code__c, MailingCountry, Mailing_Country_Code__c,
                               OtherState, Other_State_Code__c, OtherCountry, Other_Country_Code__c
                        FROM Contact WHERE Id IN :testContacts];
        System.assert(testContacts[0].MailingState == 'Colorado');
        System.assert(testContacts[0].MailingCountry == 'United States');
        System.assert(testContacts[0].OtherState == 'California');
        System.assert(testContacts[0].OtherCountry == 'United States');
        System.assert(testContacts[0].Mailing_State_Code__c == 'CO');
        System.assert(testContacts[0].Mailing_Country_Code__c == 'US');
        System.assert(testContacts[0].Other_State_Code__c == 'CA');
        System.assert(testContacts[0].Other_Country_Code__c == 'US');

        // MAKE INVALID CHANGES AND UPDATE, EACH UPDATE SHOULD CAUSE A TRIGGER ERROR TO OCCUR
        try{
            testContacts[0].MailingState = 'Colorad';
            update testContacts;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('State'));
        }
        ////
        try{
            testContacts[0].MailingState = 'Colorado';
            testContacts[0].MailingCountry = 'United Stat';
            update testContacts;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('Country'));
        }
        ////
        try{
            testContacts[0].MailingState = 'Colorado';
            testContacts[0].MailingCountry = 'United States';
            testContacts[0].OtherState = 'Californ';
            update testContacts;     
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('State'));
        }
        ////
        try{
            testContacts[0].MailingState = 'Colorado';
            testContacts[0].MailingCountry = 'United States';
            testContacts[0].OtherState = 'California';
            testContacts[0].OtherCountry = 'United Stat';
            update testContacts;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('Country'));
        }

        Test.stopTest();
    } 


}