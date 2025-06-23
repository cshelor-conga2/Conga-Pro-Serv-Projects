/**
* @author Conga Services
* @date 20180703
* @version 1.00
* @description AccountHelperTest - Test class for the AccountTrigger class
*/
@isTest
public class AccountHelperTest {

    // ACCT OWNER CHANGE VALIDATION EXCEPTIONS TEST METADATA
    private static Id OwnerValidationExemptUserId {get;set;}
    private static Id OwnerValidationExemptProfileId {get;set;}
    public static Ownership_Validation_Exemptions_Accts__mdt TestAcctValidationExceptions {
    get {
        Map<String, Object> meta1FieldValues = new Map<String, Object>{ 
            'TM_Changes_Exempt_Profiles__c' => OwnerValidationExemptProfileId,
            'TM_Changes_Exempt_Roles__c' => '',
            'TM_Changes_Exempt_Users__c' => '',

            'CSM_Changes_Exempt_Profiles__c' => '',
            'CSM_Changes_Exempt_Roles__c' => '',
            'CSM_Changes_Exempt_Users__c' => '',

            'Owner_Changes_Exempt_Profiles__c' => OwnerValidationExemptProfileId,
            'Owner_Changes_Exempt_Roles__c' => '',
            'Owner_Changes_Exempt_Users__c' => OwnerValidationExemptUserId
        };
        TestAcctValidationExceptions = (Ownership_Validation_Exemptions_Accts__mdt)TestingUtility.createTestMeta('Ownership_Validation_Exemptions_Accts__mdt', meta1FieldValues);
        return TestAcctValidationExceptions;
    } set; }


    /**
    * @description setup - Create test data
    */
    @testSetup
    public static void setup() {
        // TEST D&B INDUSTRY RECORDS
        DNB_Industry__c dnb1 = new DNB_Industry__c(Name = 'DNB1', NAICS_Description__c = 'Test1', NAICS_Code__c = '327910', SIC4_Description__c = 'Test1', SIC4_Code__c = '1234', Industry__c = 'Manufacturing');
        DNB_Industry__c dnb2 = new DNB_Industry__c(Name = 'DNB2', NAICS_Description__c = 'Test2', NAICS_Code__c = '327910', SIC4_Description__c = 'Test2', SIC4_Code__c = '5678', Industry__c = 'Manufacturing');
        DNB_Industry__c dnb3 = new DNB_Industry__c(Name = 'DNB3', NAICS_Description__c = 'Test3', NAICS_Code__c = '922140', SIC4_Description__c = 'Test3', SIC4_Code__c = '2468', Industry__c = 'Services and Consulting');
        insert new List<DNB_Industry__c>{ dnb1, dnb2, dnb3 };

        // TEST COUNTRY RECORDS 
        Country_Territory__c unitedStates = new Country_Territory__c(Name = 'United States', Two_Letter_Code__c = 'US', Three_Letter_Code__c = 'USA', Geo__c = 'AMER');
        Country_Territory__c newZealand = new Country_Territory__c(Name = 'New Zealand', Two_Letter_Code__c = 'NZ', Three_Letter_Code__c = 'NZL', Geo__c = 'APAC');
        Country_Territory__c cocosIslands = new Country_Territory__c(Name = 'Cocos Islands', Two_Letter_Code__c = 'CC', Three_Letter_Code__c = 'CCK', Geo__c = 'APAC');
        insert new List<Country_Territory__c>{ unitedStates, newZealand, cocosIslands };

        // TEST STATE RECORDS
        State_Province__c colorado = new State_Province__c(Name = 'Colorado', English_Name__c = 'Colorado', Code__c = 'CO', Country_TerritoryId__c = unitedStates.Id);
        State_Province__c california = new State_Province__c(Name = 'California', English_Name__c = 'California', Code__c = 'CA', Country_TerritoryId__c = unitedStates.Id);
        State_Province__c nzChatham = new State_Province__c(Name = 'Chatham Islands Territory', English_Name__c = 'Chatham Islands Territory', Code__c = 'CIT', Country_TerritoryId__c = newZealand.Id);
        insert new List<State_Province__c>{ colorado, california, nzChatham };

        // CREATE TEST GEO
        TM_Geo__c na = new TM_Geo__c(Name = 'AMER', Is_Active__c = true);
        TM_Geo__c apac = new TM_Geo__c(Name = 'APAC', Is_Active__c = true);
        insert new List<TM_Geo__c>{ na, apac };

        // CREATE TEST REGION
        TM_Region__c southWest = new TM_Region__c(Name = 'South West', Is_Active__c = true, TM_GeoId__c = na.Id);
        TM_Region__c anz = new TM_Region__c(Name = 'ANZ', Is_Active__c = true, TM_GeoId__c = apac.Id);
        insert new List<TM_Region__c>{ southWest, anz };

        // CREATE TEST TERRITORIES
        TM_Territory__c terr1 = new TM_Territory__c(Name = 'West: CA 1', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);
        TM_Territory__c terr2 = new TM_Territory__c(Name = 'West: CA 2', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);
        TM_Territory__c terr3 = new TM_Territory__c(Name = 'West: CO/UT/AZ', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = southWest.Id);
        TM_Territory__c terr4 = new TM_Territory__c(Name = 'NZ', Is_Active_for_Segments__c = true, Is_Active_for_Divisions__c = true, TM_RegionId__c = anz.Id);
        insert new List<TM_Territory__c>{ terr1, terr2, terr3, terr4 };

        // CREATE TEST SEGMENTS
        TM_Segment__c enterprise = new TM_Segment__c(Name = 'Enterprise', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 5001, Maximum_Employees__c = 10000000, 
                                                                                                                    Minimum_Annual_Revenue__c = 3000000, Maximum_Annual_Revenue__c = 100000000);
        TM_Segment__c genCommercial = new TM_Segment__c(Name = 'General Commercial', Is_Active__c = true, TM_GeoId__c = na.Id, Minimum_Employees__c = 1001, Maximum_Employees__c = 5000);
        TM_Segment__c apacEnterprise = new TM_Segment__c(Name = 'APAC Enterprise', Is_Active__c = true, TM_GeoId__c = apac.Id, Minimum_Employees__c = 2501, Maximum_Employees__c = 10000000);     
        TM_Segment__c apacCommercial = new TM_Segment__c(Name = 'APAC Commercial', Is_Active__c = true, TM_GeoId__c = apac.Id, Minimum_Employees__c = 251, Maximum_Employees__c = 2500);     
        insert new List<TM_Segment__c>{ enterprise, genCommercial, apacEnterprise, apacCommercial };

        // CREATE TEST DIVISIONS
        TM_Division__c division1A = new TM_Division__c(Name = 'Division 1A', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 1A', Minimum_MRR__c = 0, Maximum_MRR__c = 200);
        TM_Division__c division1B = new TM_Division__c(Name = 'Division 1B', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 1B', Minimum_MRR__c = 201, Maximum_MRR__c = 500);
        TM_Division__c division2 = new TM_Division__c(Name = 'Division 2', Is_Active__c = true, TM_GeoId__c = na.Id, CS_Division__c = 'Division 2', Minimum_MRR__c = 501, Maximum_MRR__c = 1000);
        TM_Division__c division3 = new TM_Division__c(Name = 'Division 3', Is_Active__c = true, TM_GeoId__c = apac.Id, CS_Division__c = 'Division 3', Minimum_MRR__c = 3001, Maximum_MRR__c = 15000);
        TM_Division__c division4 = new TM_Division__c(Name = 'Division 4', Is_Active__c = true, TM_GeoId__c = apac.Id, CS_Division__c = 'Division 4', Minimum_MRR__c = 15001, Maximum_MRR__c = 75000);
        insert new List<TM_Division__c>{ division1A, division1B, division2, division3, division4 };

        // LINK SEGMENTS TO TERRITORIES
        TM_Territory_Segment__c enterpriseTerr1 = new TM_Territory_Segment__c(Name = 'Enterprise', TM_TerritoryId__c = terr1.Id, TM_SegmentId__c = enterprise.Id);
        TM_Territory_Segment__c enterpriseTerr2 = new TM_Territory_Segment__c(Name = 'Enterprise', TM_TerritoryId__c = terr2.Id, TM_SegmentId__c = enterprise.Id);
        TM_Territory_Segment__c genCommercialTerr3 = new TM_Territory_Segment__c(Name = 'General Commercial', TM_TerritoryId__c = terr3.Id, TM_SegmentId__c = genCommercial.Id);
        TM_Territory_Segment__c apacEnterpriseTerr4 = new TM_Territory_Segment__c(Name = 'APAC Enterprise', TM_TerritoryId__c = terr4.Id, TM_SegmentId__c = apacEnterprise.Id);
        TM_Territory_Segment__c apacCommercialTerr4 = new TM_Territory_Segment__c(Name = 'APAC Commercial', TM_TerritoryId__c = terr4.Id, TM_SegmentId__c = apacCommercial.Id);
        insert new List<TM_Territory_Segment__c>{ enterpriseTerr1, enterpriseTerr2, genCommercialTerr3, apacEnterpriseTerr4, apacCommercialTerr4 };

        // LINK DIVISIONS TO TERRITORIES
        TM_Territory_Division__c division1ATerr1 = new TM_Territory_Division__c(Name = 'Division 1A', TM_TerritoryId__c = terr1.Id, TM_DivisionId__c = division1A.Id);
        TM_Territory_Division__c division1BTerr2 = new TM_Territory_Division__c(Name = 'Division 1B', TM_TerritoryId__c = terr2.Id, TM_DivisionId__c = division1B.Id);
        TM_Territory_Division__c division2Terr3 = new TM_Territory_Division__c(Name = 'Division 2', TM_TerritoryId__c = terr3.Id, TM_DivisionId__c = division2.Id);
        TM_Territory_Division__c division3Terr4 = new TM_Territory_Division__c(Name = 'Division 3', TM_TerritoryId__c = terr4.Id, TM_DivisionId__c = division3.Id);   
        TM_Territory_Division__c division4Terr4 = new TM_Territory_Division__c(Name = 'Division 4', TM_TerritoryId__c = terr4.Id, TM_DivisionId__c = division4.Id);   
        insert new List<TM_Territory_Division__c>{ division1ATerr1, division1BTerr2, division2Terr3, division3Terr4, division4Terr4 };
    
        // CREATE TEST TERRITORY SEGMENT USERS
        TM_Territory_Segment_Users__c terrSegmentUser1 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = enterpriseTerr1.Id, Applicable_Industries__c = 'None;Transportation, Distribution, and Logistics');
        TM_Territory_Segment_Users__c terrSegmentUser2 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = enterpriseTerr2.Id, Applicable_Industries__c = 'Energy, Oil, and Utilities');
        TM_Territory_Segment_Users__c terrSegmentUser3 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = genCommercialTerr3.Id, Applicable_Industries__c = 'None;Retail and Restaurants');
        TM_Territory_Segment_Users__c terrSegmentUser4 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = apacEnterpriseTerr4.Id, Applicable_Industries__c = 'Telecommunications and Communications');
        TM_Territory_Segment_Users__c terrSegmentUser5 = new TM_Territory_Segment_Users__c(TM_Territory_SegmentId__c = apacCommercialTerr4.Id, Applicable_Industries__c = 'Technology - Hardware, Software, and Services');
        insert new List<TM_Territory_Segment_Users__c>{ terrSegmentUser1, terrSegmentUser2, terrSegmentUser3, terrSegmentUser4, terrSegmentUser5 };

        // CREATE TEST TERRITORY DIVISION USERS
        TM_Territory_Division_Users__c terrDivisionUser1 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = division1ATerr1.Id);
        TM_Territory_Division_Users__c terrDivisionUser2 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = division1BTerr2.Id);
        TM_Territory_Division_Users__c terrDivisionUser3 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = division2Terr3.Id);
        TM_Territory_Division_Users__c terrDivisionUser4 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = division3Terr4.Id);
        TM_Territory_Division_Users__c terrDivisionUser5 = new TM_Territory_Division_Users__c(TM_Territory_DivisionId__c = division4Terr4.Id);
        insert new List<TM_Territory_Division_Users__c>{ terrDivisionUser1, terrDivisionUser2, terrDivisionUser3, terrDivisionUser4, terrDivisionUser5 };

        // CREATE TEST TERRITORY SEGMENT COUNTRIES
        TM_Territory_Segment_Country__c terrSegCountry1 = new TM_Territory_Segment_Country__c(TM_Territory_SegmentId__c = apacEnterpriseTerr4.Id, Country_TerritoryId__c = cocosIslands.Id);
        TM_Territory_Segment_Country__c terrSegCountry2 = new TM_Territory_Segment_Country__c(TM_Territory_SegmentId__c = apacCommercialTerr4.Id, Country_TerritoryId__c = newZealand.Id);
        insert new List<TM_Territory_Segment_Country__c>{ terrSegCountry1, terrSegCountry2 };

        // CREATE TEST TERRITORY SEGMENT STATES
        TM_Territory_Segment_State__c terrSegState1California = new TM_Territory_Segment_State__c(TM_Territory_SegmentId__c = enterpriseTerr1.Id, State_ProvinceId__c = california.Id, Applicable_Postal_Codes__c = '90223, 90456');
        TM_Territory_Segment_State__c terrSegState2California = new TM_Territory_Segment_State__c(TM_Territory_SegmentId__c = enterpriseTerr2.Id, State_ProvinceId__c = california.Id, Applicable_Postal_Codes__c = '91456, 96785');
        TM_Territory_Segment_State__c terrSegState3Colorado = new TM_Territory_Segment_State__c(TM_Territory_SegmentId__c = genCommercialTerr3.Id, State_ProvinceId__c = colorado.Id);
        TM_Territory_Segment_State__c terrSegState4Chatham = new TM_Territory_Segment_State__c(TM_Territory_SegmentId__c = apacEnterpriseTerr4.Id, State_ProvinceId__c = nzChatham.Id);
        insert new List<TM_Territory_Segment_State__c>{ terrSegState1California, terrSegState2California, terrSegState3Colorado, terrSegState4Chatham };

        // CREATE TEST TERRITORY DIVISION COUNTRIES
        TM_Territory_Division_Country__c terrDivCountry1 = new TM_Territory_Division_Country__c(TM_Territory_DivisionId__c = division3Terr4.Id, Country_TerritoryId__c = cocosIslands.Id);
        TM_Territory_Division_Country__c terrDivCountry2 = new TM_Territory_Division_Country__c(TM_Territory_DivisionId__c = division4Terr4.Id, Country_TerritoryId__c = newZealand.Id);
        insert new List<TM_Territory_Division_Country__c>{ terrDivCountry1, terrDivCountry2 };

        // CREATE TEST TERRITORY DIVISION STATES
        TM_Territory_Division_State__c terrDivState1California = new TM_Territory_Division_State__c(TM_Territory_DivisionId__c = division1ATerr1.Id, State_ProvinceId__c = california.Id, Applicable_Postal_Codes__c = '90223, 90456');
        TM_Territory_Division_State__c terrDivState2California = new TM_Territory_Division_State__c(TM_Territory_DivisionId__c = division1BTerr2.Id, State_ProvinceId__c = california.Id, Applicable_Postal_Codes__c = '91456, 96785');
        TM_Territory_Division_State__c terrDivState3Colorado = new TM_Territory_Division_State__c(TM_Territory_DivisionId__c = division2Terr3.Id, State_ProvinceId__c = colorado.Id);
        TM_Territory_Division_State__c terrDivState4Chatham = new TM_Territory_Division_State__c(TM_Territory_DivisionId__c = division3Terr4.Id, State_ProvinceId__c = nzChatham.Id);
        insert new List<TM_Territory_Division_State__c>{ terrDivState1California, terrDivState2California, terrDivState3Colorado, terrDivState4Chatham };

        // CREATE TEST PRODUCTS
        List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', false, 2);
        testProducts[0].Name = 'Test Product';
        testProducts[0].ProductCode = 'TP1';
        testProducts[0].Family = 'Conga Composer Licenses';
        testProducts[0].Product_Line__c = 'Conga Composer';
        testProducts[0].FY16_Revenue_Type__c = 'Recurring';
        testProducts[1].Name = 'Test Product 2';
        testProducts[1].ProductCode = 'TP2';
        testProducts[1].Family = 'Conga Composer Licenses';
        testProducts[1].Product_Line__c = 'Conga Composer';
        testProducts[1].FY16_Revenue_Type__c = 'Recurring';
        insert testProducts;

        // TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = (List<PricebookEntry>)TestingUtility.createSObjectList('PricebookEntry', true, 1);
        testPricebookEntries[0].Pricebook2Id = Test.getStandardPricebookId();
        testPricebookEntries[0].Product2Id = testProducts[0].Id;
        testPricebookEntries[0].IsActive = TRUE;
        testPricebookEntries[0].UnitPrice = 200.00;
        insert testPricebookEntries;
    }

    /**
    * @description updateAcctTeamsFromLookupsTest - Test method for the AccountHelper.updateAcctTeamsFromLookups method
    */
    private static testmethod void updateAcctTeamsFromLookupsTest(){
        // DISABLE OWNERSHIP VALIDATION
        TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);

        // CREATE TEST SALES USER MANAGER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'sales2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8',
        FirstName = 'Sales', LastName = 'Person2', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser2' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        Test.startTest();

        TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);
        TriggerHelper.TemporaryOverride('AccountTeamMemberHelper','processTeamChanges', false); //// WINTER '21 - TEAM IS DELETED WHEN ACCOUNT OWNER IS CHANGED

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].Type = 'Prospect';
        testAccounts[1].Type = 'Customer';
        testAccounts[2].Type = 'Customer';
        insert testAccounts;

        // NO TEAM MEMBERS SHOULD EXIST YET
        List<AccountTeamMember> teamMembers = [SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :testAccounts];
        System.assert(teamMembers.size() == 0);

        // MAKE UPDATES
        testAccounts[0].TM_Territory_ManagerId__c = UserInfo.getUserId();
        testAccounts[0].Customer_Success_Manager__c = salesUser.Id;
        testAccounts[2].TM_Territory_ManagerId__c = salesUser.Id;
        testAccounts[2].Customer_Success_Manager__c = UserInfo.getUserId();         
        update testAccounts;
     
        // GET TEAM MEMBERS AND CHECK THAT THEY WERE CREATED
        teamMembers = [SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :testAccounts];
        System.assert(teamMembers.size() == 3); // ONLY THREE, PROSPECT ACCOUNT DOES NOT GET A CSM
        for(AccountTeamMember teamMember : teamMembers){
            if(teamMember.AccountId == testAccounts[0].Id){
                System.assert(teamMember.TeamMemberRole == 'Territory Manager' && teamMember.UserId == UserInfo.getUserId());
            }
            else if(teamMember.AccountId == testAccounts[2].Id){
                if(teamMember.TeamMemberRole == 'Territory Manager'){
                    System.assert(teamMember.UserId == salesUser.Id);
                }
                else if(teamMember.TeamMemberRole == 'Customer Success Manager'){
                    System.assert(teamMember.UserId == UserInfo.getUserId()); 
                }
            }
        }

        // MAKE UPDATES
        testAccounts[0].TM_Territory_ManagerId__c = salesUser.Id;
        testAccounts[0].Customer_Success_Manager__c = UserInfo.getUserId();
        testAccounts[2].TM_Territory_ManagerId__c = UserInfo.getUserId();
        testAccounts[2].Customer_Success_Manager__c = salesUser.Id;
        update testAccounts;

        // REFRESH TEAM MEMBERS AND CHECK THAT THEY WERE UPDATED
        teamMembers = [SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :testAccounts];
        System.assert(teamMembers.size() == 3); // ONLY THREE, PROSPECT ACCOUNT DOES NOT GET A CSM
        for(AccountTeamMember teamMember : teamMembers){
            if(teamMember.AccountId == testAccounts[0].Id){
                System.assert(teamMember.TeamMemberRole == 'Territory Manager' && teamMember.UserId == salesUser.Id);
            }
            else if(teamMember.AccountId == testAccounts[2].Id){
                if(teamMember.TeamMemberRole == 'Territory Manager'){
                    System.assert(teamMember.UserId == UserInfo.getUserId());
                }
                else if(teamMember.TeamMemberRole == 'Customer Success Manager'){
                    System.assert(teamMember.UserId == salesUser.Id); 
                }
            }
        }

        Test.stopTest();
    }

    /**
    * @description updateTerritoryManagementFieldsTest_Segment - Test updateTerritoryManagementFields trigger method
    */
    public static testMethod void updateTerritoryManagementFieldsTest_Segment(){
        // GET TEST TERRITORIES
        List<TM_Territory__c> testTerritories = [SELECT Id, TM_RegionId__c, TM_RegionId__r.TM_GeoId__c FROM TM_Territory__c];
        System.assert(testTerritories.size() == 4);

        // GET TEST SEGMENTS
        List<TM_Segment__c> testSegments = [SELECT Id FROM TM_Segment__c];
        System.assert(testSegments.size() == 4);

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].Name = 'Colorado Acct - Segment';
        testAccounts[0].NumberOfEmployees = 1250;
        testAccounts[0].Industry = null;
        testAccounts[0].ShippingState = 'Colorado';
        testAccounts[0].ShippingPostalCode = '80223';
        testAccounts[0].ShippingCountry = 'United States';
        //
        testAccounts[1].Name = 'California Acct - Segment';
        testAccounts[1].NumberOfEmployees = 11000;
        testAccounts[1].AnnualRevenue = 5500000;
        testAccounts[1].Industry = 'Transportation, Distribution, and Logistics';
        testAccounts[1].ShippingState = 'California';
        testAccounts[1].ShippingPostalCode = '';
        testAccounts[1].ShippingCountry = 'United States';
        //
        testAccounts[2].Name = 'Segment Direct';
        testAccounts[2].TM_Segment_TerritoryId__c = testTerritories[1].Id; // DIRECT ASSIGNMENT
        testAccounts[2].TM_SegmentId__c = testSegments[1].Id; // DIRECT ASSIGNMENT
        insert testAccounts;

        Test.startTest();

        // UPDATE ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, TM_SegmentId__c, TM_Segment_TerritoryId__c, TM_RegionId__c, TM_GeoId__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].TM_GeoId__c == testTerritories[2].TM_RegionId__r.TM_GeoId__c);
        System.assert(testAccounts[0].TM_RegionId__c == testTerritories[2].TM_RegionId__c);
        System.assert(testAccounts[0].TM_Segment_TerritoryId__c == testTerritories[2].Id);
        System.assert(testAccounts[0].TM_SegmentId__c == testSegments[1].Id);
        // CALIFORNIA IS A SPLIT STATE AND TERRITORY WILL NOT BE PROCESSED WITHOUT A POSTAL CODE
        System.assert(testAccounts[1].TM_GeoId__c == null);
        System.assert(testAccounts[1].TM_RegionId__c == null);
        System.assert(testAccounts[1].TM_Segment_TerritoryId__c == null);
        System.assert(testAccounts[1].TM_SegmentId__c == testSegments[0].Id);
        //
        System.assert(testAccounts[2].TM_GeoId__c == testTerritories[1].TM_RegionId__r.TM_GeoId__c);
        System.assert(testAccounts[2].TM_RegionId__c == testTerritories[1].TM_RegionId__c);
        System.assert(testAccounts[2].TM_Segment_TerritoryId__c == testTerritories[1].Id);
        System.assert(testAccounts[2].TM_SegmentId__c == testSegments[1].Id);
   
        // ASSIGN A POSTAL CODE TO THE CALIFORNIA ACCOUNT AND RETEST
        testAccounts[1].ShippingPostalCode = '90456';
        update testAccounts;
        testAccounts = [SELECT Id, TM_SegmentId__c, TM_Segment_TerritoryId__c, TM_RegionId__c, TM_GeoId__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[1].TM_GeoId__c == testTerritories[0].TM_RegionId__r.TM_GeoId__c);
        System.assert(testAccounts[1].TM_RegionId__c == testTerritories[0].TM_RegionId__c);
        System.assert(testAccounts[1].TM_Segment_TerritoryId__c == testTerritories[0].Id);
        System.assert(testAccounts[1].TM_SegmentId__c == testSegments[0].Id);

        Test.stopTest();
    }

    /**
    * @description updateTerritoryManagementFieldsTest_Division - Test updateTerritoryManagementFields trigger method
    */
    public static testMethod void updateTerritoryManagementFieldsTest_Division(){
        // GET TEST TERRITORIES
        List<TM_Territory__c> testTerritories = [SELECT Id, TM_RegionId__c, TM_RegionId__r.TM_GeoId__c FROM TM_Territory__c];
        System.assert(testTerritories.size() == 4);

        // GET TEST DIVISION
        List<TM_Division__c> testDivisions = [SELECT Id FROM TM_Division__c];
        System.assert(testDivisions.size() == 5);

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].Name = 'Colorado Acct - Division';
        testAccounts[0].Burdened_MRR__c = 550;
        testAccounts[0].ShippingState = 'Colorado';
        testAccounts[0].ShippingPostalCode = '80223';
        testAccounts[0].ShippingCountry = 'United States';
        //
        testAccounts[1].Name = 'California Acct - Division';
        testAccounts[1].Burdened_MRR__c = 350;
        testAccounts[1].ShippingState = 'California';
        testAccounts[1].ShippingCountry = 'United States';
        //
        testAccounts[2].Name = 'Division Direct';
        testAccounts[2].TM_Division_TerritoryId__c = testTerritories[1].Id; // DIRECT ASSIGNMENT
        testAccounts[2].TM_DivisionId__c = testDivisions[1].Id; // DIRECT ASSIGNMENT
        insert testAccounts;

        Test.startTest();

        // UPDATE ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, TM_DivisionId__c, TM_Division_TerritoryId__c, TM_RegionId__c, TM_GeoId__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].TM_GeoId__c == null); // GEO WILL ONLY COME FROM SEGMENT
        System.assert(testAccounts[0].TM_RegionId__c == null); // REGION WILL ONLY COME FROM SEGMENT
        System.assert(testAccounts[0].TM_Division_TerritoryId__c == testTerritories[2].Id);
        System.assert(testAccounts[0].TM_DivisionId__c == testDivisions[2].Id);
        //
        System.assert(testAccounts[1].TM_GeoId__c == null);
        System.assert(testAccounts[1].TM_RegionId__c == null);
        System.assert(testAccounts[1].TM_Division_TerritoryId__c == testTerritories[1].Id); // CALIFORNIA IS NOT A SPLIT STATE ON DIVISION 1B, SO THIS GETS POPULATED
        System.assert(testAccounts[1].TM_DivisionId__c == testDivisions[1].Id);
        //
        System.assert(testAccounts[2].TM_GeoId__c == null); // GEO WILL ONLY COME FROM SEGMENT
        System.assert(testAccounts[2].TM_RegionId__c == null); // REGION WILL ONLY COME FROM SEGMENT
        System.assert(testAccounts[2].TM_Division_TerritoryId__c == testTerritories[1].Id);
        System.assert(testAccounts[2].TM_DivisionId__c == testDivisions[1].Id);

        Test.stopTest();
    }

    /**
    * @description updateTerritoryManagementFieldsTest - Test updateTerritoryManagementFields trigger method
    */
    public static testMethod void updateTerritoryManagementFieldsTest_APAC(){
        // GET TEST TERRITORIES
        List<TM_Territory__c> testTerritories = [SELECT Id, TM_RegionId__c, TM_RegionId__r.TM_GeoId__c FROM TM_Territory__c];
        System.assert(testTerritories.size() == 4);

        // GET TEST SEGMENTS
        List<TM_Segment__c> testSegments = [SELECT Id FROM TM_Segment__c];
        System.assert(testSegments.size() == 4);

         // GET TEST DIVISIONS
        List<TM_Division__c> testDivisions = [SELECT Id FROM TM_Division__c];
        System.assert(testDivisions.size() == 5);       

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].Name = 'APAC New Zealand Acct';
        testAccounts[0].NumberOfEmployees = 1500; // APAC Commercial
        testAccounts[0].Burdened_MRR__c = 15500; // APAC Division4
        testAccounts[0].ShippingState = null;
        testAccounts[0].ShippingPostalCode = null;
        testAccounts[0].ShippingCountry = 'New Zealand';
        //
        testAccounts[1].Name = 'APAC Chatham Islands Acct';
        testAccounts[1].NumberOfEmployees = 5500; // APAC Enterprise
        testAccounts[1].Burdened_MRR__c = 7500; // APAC Division3
        testAccounts[1].ShippingState = 'Chatham Islands Territory';
        testAccounts[1].ShippingPostalCode = null;
        testAccounts[1].ShippingCountry = 'New Zealand';
        //
        testAccounts[2].Name = 'APAC Cocos Islands Acct';
        testAccounts[2].NumberOfEmployees = 9000; // APAC Enterprise
        testAccounts[2].Burdened_MRR__c = 12500; // APAC Division3
        testAccounts[2].ShippingState = null;
        testAccounts[2].ShippingPostalCode = null;
        testAccounts[2].ShippingCountry = 'Cocos Islands';
        insert testAccounts;

        Test.startTest();

        // UPDATE ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, TM_SegmentId__c, TM_DivisionId__c, TM_Segment_TerritoryId__c, TM_Division_TerritoryId__c, TM_RegionId__c, TM_GeoId__c 
                        FROM Account WHERE Id IN :testAccounts];

        // NEW ZEALAND IS ON THE TERRITORY THROUGH ITS STATES
        System.assert(testAccounts[0].TM_GeoId__c == testTerritories[3].TM_RegionId__r.TM_GeoId__c);
        System.assert(testAccounts[0].TM_RegionId__c == testTerritories[3].TM_RegionId__c);
        System.assert(testAccounts[0].TM_Segment_TerritoryId__c == testTerritories[3].Id);
        System.assert(testAccounts[0].TM_SegmentId__c == testSegments[3].Id);
        System.assert(testAccounts[0].TM_Division_TerritoryId__c == testTerritories[3].Id);
        System.assert(testAccounts[0].TM_DivisionId__c == testDivisions[4].Id);
        // Chatham Islands Territory NEW ZEALAND STATE
        System.assert(testAccounts[1].TM_GeoId__c == testTerritories[3].TM_RegionId__r.TM_GeoId__c);
        System.assert(testAccounts[1].TM_RegionId__c == testTerritories[3].TM_RegionId__c);
        System.assert(testAccounts[1].TM_Segment_TerritoryId__c == testTerritories[3].Id);
        System.assert(testAccounts[1].TM_SegmentId__c == testSegments[2].Id);
        System.assert(testAccounts[1].TM_Division_TerritoryId__c == testTerritories[3].Id);
        System.assert(testAccounts[1].TM_DivisionId__c == testDivisions[3].Id);
        // COCOS ISLANDS COUNTRY
        System.assert(testAccounts[2].TM_GeoId__c == testTerritories[3].TM_RegionId__r.TM_GeoId__c);
        System.assert(testAccounts[2].TM_RegionId__c == testTerritories[3].TM_RegionId__c);
        System.assert(testAccounts[2].TM_Segment_TerritoryId__c == testTerritories[3].Id);
        System.assert(testAccounts[2].TM_SegmentId__c == testSegments[2].Id);
        System.assert(testAccounts[2].TM_Division_TerritoryId__c == testTerritories[3].Id);
        System.assert(testAccounts[2].TM_DivisionId__c == testDivisions[3].Id);       
   
        Test.stopTest();
    }

    /**
    * @description updateTerritoryManagementFieldsTest_Exceptions - Test updateTerritoryManagementFields bad/empty parameter handling
    */
    public static testMethod void updateTerritoryManagementFieldsTest_Exceptions(){
        Test.startTest();

        AccountHelper.updateTerritoryManagementFields(null, null);
        AccountHelper.updateTerritoryManagementFields(new List<Account>(), new Map<Id, Account>());

        Test.stopTest();
    }

    /**
    * @description processSegmentAndDivisionChangesTest - Test processSegmentAndDivisionChanges trigger method
    */
    public static testMethod void processSegmentAndDivisionChangesTest(){
        TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);

        // CREATE TEST SALES USER MANAGER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'sales2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8',
        FirstName = 'Sales', LastName = 'Person', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        // GET TEST TERRITORY SEGMENT USERS
        List<TM_Territory_Segment_Users__c> testTerrSegmentUsers = [SELECT Id, TM_Territory_SegmentId__c, TM_Territory_SegmentId__r.TM_TerritoryId__c, 
                                                                           TM_Territory_SegmentId__r.TM_SegmentId__c
                                                                    FROM TM_Territory_Segment_Users__c];
        System.assert(testTerrSegmentUsers.size() == 5);  
        
        // ASSIGN USERS TO TERRITORY SEGMENT USERS
        TriggerHelper.TemporaryOverride('TMTerritorySegmentUsersHelper','processUserChanges', false); // STOP TRIGGER METHOD FROM EXECUTING BATCH CLASS
        testTerrSegmentUsers[0].Assigned_TM_UserId__c = salesUser.Id;
        testTerrSegmentUsers[0].Assigned_CLM_UserId__c = UserInfo.getUserId();
        testTerrSegmentUsers[1].Assigned_TM_UserId__c = salesUser.Id;
        testTerrSegmentUsers[2].Assigned_TM_UserId__c = UserInfo.getUserId();
        testTerrSegmentUsers[3].Assigned_TM_UserId__c = salesUser.Id;
        testTerrSegmentUsers[4].Assigned_TM_UserId__c = UserInfo.getUserId();
        update testTerrSegmentUsers;

        // GET TEST TERRITORY DIVISION USERS
        List<TM_Territory_Division_Users__c> testTerrDivisionUsers = [SELECT Id, TM_Territory_DivisionId__c, TM_Territory_DivisionId__r.TM_TerritoryId__c, 
                                                                             TM_Territory_DivisionId__r.TM_DivisionId__c
                                                                      FROM TM_Territory_Division_Users__c];
        System.assert(testTerrDivisionUsers.size() == 5);

        // ASSIGN USERS TO TERRITORY DIVISION USERS
        TriggerHelper.TemporaryOverride('TMTerritoryDivisionUsersHelper','processUserChanges', false); // STOP TRIGGER METHOD FROM EXECUTING BATCH CLASS
        testTerrDivisionUsers[0].Assigned_CSM_UserId__c = salesUser.Id;
        testTerrDivisionUsers[1].Assigned_CSM_UserId__c = UserInfo.getUserId();
        testTerrDivisionUsers[2].Assigned_CSM_UserId__c = salesUser.Id;
        testTerrDivisionUsers[2].Assigned_RM_UserId__c = UserInfo.getUserId();
        testTerrDivisionUsers[3].Assigned_CSM_UserId__c = salesUser.Id;
        testTerrDivisionUsers[3].Assigned_RM_UserId__c = UserInfo.getUserId();
        testTerrDivisionUsers[4].Assigned_CSM_UserId__c = salesUser.Id;
        testTerrDivisionUsers[4].Assigned_RM_UserId__c = UserInfo.getUserId();
        update testTerrDivisionUsers;

        Test.startTest();

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].TM_Segment_TerritoryId__c = testTerrSegmentUsers[0].TM_Territory_SegmentId__r.TM_TerritoryId__c;
        testAccounts[0].TM_SegmentId__c = testTerrSegmentUsers[0].TM_Territory_SegmentId__r.TM_SegmentId__c;
        testAccounts[0].Type = 'Prospect';
        testAccounts[1].TM_Division_TerritoryId__c = testTerrDivisionUsers[1].TM_Territory_DivisionId__r.TM_TerritoryId__c;
        testAccounts[1].TM_DivisionId__c = testTerrDivisionUsers[1].TM_Territory_DivisionId__r.TM_DivisionId__c;
        testAccounts[1].Type = 'Customer';
        testAccounts[2].Type = 'Customer - Past Due';
        insert testAccounts;

        testAccounts[2].TM_Segment_TerritoryId__c = testTerrSegmentUsers[2].TM_Territory_SegmentId__r.TM_TerritoryId__c;
        testAccounts[2].TM_SegmentId__c = testTerrSegmentUsers[2].TM_Territory_SegmentId__r.TM_SegmentId__c;
        testAccounts[2].TM_Division_TerritoryId__c = testTerrDivisionUsers[2].TM_Territory_DivisionId__r.TM_TerritoryId__c;
        testAccounts[2].TM_DivisionId__c = testTerrDivisionUsers[2].TM_Territory_DivisionId__r.TM_DivisionId__c;
        update testAccounts;

        // REFRESH TEAM MEMBERS AND CHECK THAT THEY WERE UPDATED

        ///////////////// EREDDING 20210120 - SALESFORCE NOW DELETES THE ENTIRE ACCOUNT TEAM WHEN THE OWNER IS CHANGED. CANNOT RUN FULL TEST ANYMORE ///////////////////

        //List<AccountTeamMember> teamMembers = [SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :testAccounts];
        //System.assertEquals(5, teamMembers.size()); // ONLY FIVE, PROSPECT ACCOUNT SHOULD NOT GET A CSM OR RM AND THE 2ND ACCOUNT SHOULD NOT GET A CLM
        //for(AccountTeamMember teamMember : teamMembers){
        //    if(teamMember.AccountId == testAccounts[0].Id){
        //        if(teamMember.TeamMemberRole == 'Territory Manager'){
        //            System.assert(teamMember.UserId == salesUser.Id);
        //        }
        //        else if(teamMember.TeamMemberRole == 'CLM Manager'){
        //            System.assert(teamMember.UserId == UserInfo.getUserId()); 
        //        }
        //    }
        //    else if(teamMember.AccountId == testAccounts[2].Id){
        //        if(teamMember.TeamMemberRole == 'Territory Manager'){
        //            System.assert(teamMember.UserId == UserInfo.getUserId());
        //        }
        //        else if(teamMember.TeamMemberRole == 'Customer Success Manager'){
        //            System.assert(teamMember.UserId == salesUser.Id); 
        //        }
        //        else if(teamMember.TeamMemberRole == 'Renewals Manager'){
        //            System.assert(teamMember.UserId == UserInfo.getUserId()); 
        //        }
        //    }
        //}
        Test.stopTest();
    }

    /**
    * @description validateOwnershipChangesTest - Test method for the AccountHelper.validateOwnershipChanges method
    */
    private static testmethod void validateOwnershipChangesTest(){
        // CREATE TEST SALES USER MANAGER
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];

        // CREATE TEST USER
        User salesUser = new User(Alias = 'sales2', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8',
        FirstName = 'Sales', LastName = 'Person2', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, 
        TimeZoneSidKey = 'America/Los_Angeles', UserName = 'salesUser2' + UserInfo.getOrganizationId() + '@testorg.com');
        insert salesUser;

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        testAccounts[0].OwnerId = UserInfo.getUserId();
        testAccounts[0].TM_Territory_ManagerId__c = UserInfo.getUserId();     
        testAccounts[0].Customer_Success_Manager__c = UserInfo.getUserId();
        insert testAccounts;

        Id currentUserId = UserInfo.getUserId();
        Test.startTest();

        // NO CURRENT EXEMPTIONS
        System.runas(salesUser){

            // USER NOT EXEMPT FROM CHANGING OWNER
            testAccounts[0].OwnerId = salesUser.Id;
            Database.saveResult[] acctResults1 = Database.update(testAccounts, false);
            System.assert(!acctResults1.isEmpty());
            System.assert(!acctResults1[0].isSuccess());

            // USER NOT EXEMPT FROM CHANGING TM
            testAccounts[0].OwnerId = currentUserId;
            testAccounts[0].TM_Territory_ManagerId__c = salesUser.Id;
            Database.saveResult[] acctResults2 = Database.update(testAccounts, false);
            System.assert(!acctResults2.isEmpty());
            System.assert(!acctResults2[0].isSuccess());

            // USER NOT EXEMPT FROM CHANGING CSM
            testAccounts[0].TM_Territory_ManagerId__c = currentUserId;
            testAccounts[0].Customer_Success_Manager__c = salesUser.Id;
            Database.saveResult[] acctResults3 = Database.update(testAccounts, false);
            System.assert(!acctResults3.isEmpty());
            System.assert(!acctResults3[0].isSuccess());

            // EXEMPT USER ON TM AND OWNER CHANGES
            OwnerValidationExemptUserId = salesUser.Id;
            OwnerValidationExemptProfileId = salesUser.ProfileId;

            // USER NOW ALLOWED TO CHANGING OWNER
            testAccounts[0].Customer_Success_Manager__c = currentUserId;
            testAccounts[0].OwnerId = salesUser.Id;
            Database.saveResult[] acctResults4 = Database.update(testAccounts, false);
            System.assert(!acctResults4.isEmpty());
            System.assert(acctResults4[0].isSuccess());

            // USER NOW ALLOWED TO CHANGING TM
            testAccounts[0].TM_Territory_ManagerId__c = salesUser.Id;
            Database.saveResult[] acctResults5 = Database.update(testAccounts, false);
            System.assert(!acctResults5.isEmpty());
            System.assert(acctResults5[0].isSuccess());

            // USER STILL NOT EXEMPT FOR CHANGING CSM
            testAccounts[0].Customer_Success_Manager__c = salesUser.Id;    
            Database.saveResult[] acctResults6 = Database.update(testAccounts, false);
            System.assert(!acctResults6.isEmpty());
            System.assert(!acctResults6[0].isSuccess());
        }

        Test.stopTest();
    }

    /**
    * @description validateStateAndCountryTest - Test validateStateAndCountry trigger method
    */
    public static testMethod void validateStateAndCountryTest(){
        TriggerHelper.TemporaryOverride('AccountHelper', 'updateShippingAddress', false); // DISABLE METHOD SO BILLING DOES NOT OVERWRITE SHIPPING

        Test.startTest();

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', true, 1);
        testAccounts[0].Name = 'Test Account';
        testAccounts[0].BillingState = 'CO';
        testAccounts[0].BillingCountry = 'USA';
        testAccounts[0].ShippingState = 'CA';
        testAccounts[0].ShippingCountry = 'USA';
        insert testAccounts;

        // TEST THAT COUNTRIES AND STATES WERE PROPERLY CONVERTED TO THEIR FULL NAMES
        testAccounts = [SELECT Id, Name, BillingState, BillingCountry, ShippingState, ShippingCountry, 
                               Billing_State_Code__c, Billing_Country_Code__c, Shipping_State_Code__c, Shipping_Country_Code__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].BillingState == 'Colorado');
        System.assert(testAccounts[0].BillingCountry == 'United States');
        System.assert(testAccounts[0].ShippingState == 'California');
        System.assert(testAccounts[0].ShippingCountry == 'United States');
        System.assert(testAccounts[0].Billing_State_Code__c == 'CO');
        System.assert(testAccounts[0].Billing_Country_Code__c == 'US');
        System.assert(testAccounts[0].Shipping_State_Code__c == 'CA');
        System.assert(testAccounts[0].Shipping_Country_Code__c == 'US');

        // MAKE INVALID CHANGES AND UPDATE, EACH UPDATE SHOULD CAUSE A TRIGGER ERROR TO OCCUR
        try{
            testAccounts[0].BillingState = 'Colorad';
            update testAccounts;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('State'));
        }
        ////
        try{
            testAccounts[0].BillingState = 'Colorado';
            testAccounts[0].BillingCountry = 'United Stat';
            update testAccounts;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('Country'));
        }
        ////
        try{
            testAccounts[0].BillingState = 'Colorado';
            testAccounts[0].BillingCountry = 'United States';
            testAccounts[0].ShippingState = 'Californ';
            update testAccounts;     
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('State'));
        }
        ////
        try{
            testAccounts[0].BillingState = 'Colorado';
            testAccounts[0].BillingCountry = 'United States';
            testAccounts[0].ShippingState = 'California';
            testAccounts[0].ShippingCountry = 'United Stat';
            update testAccounts;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Invalid'));
            System.assert(ex.getMessage().contains('Country'));
        }

        Test.stopTest();
    }

    /**
    * @description updateAccountIndustryTest - Test updateAccountIndustry trigger method
    */
    public static testMethod void updateAccountIndustryTest(){
        // GET TEST DNB INDUSTRY RECORDS
        List<DNB_Industry__c> dnbIndustries = [SELECT Id, Industry__c FROM DNB_Industry__c];
        System.assert(dnbIndustries.size() == 3);

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', true, 3);
        testAccounts[0].Name = 'Test Account 1';
        testAccounts[1].Name = 'Test Account 2';
        testAccounts[2].Name = 'Test Account 3';
        insert testAccounts;

        // CREATE TEST PARENT D&B RECORDS
        List<DNBoptimizer__DnBCompanyRecord__c> testParentDNBRecords = TestingUtility.createSObjectList('DNBoptimizer__DnBCompanyRecord__c', true, 3);
        testParentDNBRecords[0].DNBoptimizer__BusinessName__c = 'Test Account 1';
        testParentDNBRecords[0].DNBoptimizer__NAICSCode1__c = '327910';
        testParentDNBRecords[0].DNBoptimizer__SIC4Code1__c = '1234';
        //
        testParentDNBRecords[1].DNBoptimizer__BusinessName__c = 'Test Account 2';
        testParentDNBRecords[1].DNBoptimizer__NAICSCode1__c = '327910';
        testParentDNBRecords[1].DNBoptimizer__SIC4Code1__c = '5678';
        //
        testParentDNBRecords[2].DNBoptimizer__BusinessName__c = 'Test Account 3';
        testParentDNBRecords[2].DNBoptimizer__NAICSCode1__c = '922140';
        testParentDNBRecords[2].DNBoptimizer__SIC4Code1__c = '2468';
        insert testParentDNBRecords;

        Test.startTest();

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, Industry FROM Account WHERE Id IN :testAccounts];
        System.assert(String.isBlank(testAccounts[0].Industry));
        System.assert(String.isBlank(testAccounts[1].Industry));
        System.assert(String.isBlank(testAccounts[2].Industry));

        // ASSIGN PARENT D&B RECORDS TO ACCOUNTS
        testAccounts[0].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[0].Id;
        testAccounts[1].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[1].Id;
        testAccounts[2].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[2].Id;
        update testAccounts;

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, Industry FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].Industry == dnbIndustries[0].Industry__c);
        System.assert(testAccounts[1].Industry == dnbIndustries[1].Industry__c);
        System.assert(testAccounts[2].Industry == dnbIndustries[2].Industry__c);

        // CHANGE ASSIGNMENTS
        testAccounts[0].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[2].Id;
        testAccounts[1].DNBoptimizer__DnBCompanyRecord__c = testParentDNBRecords[0].Id;
        testAccounts[2].DNBoptimizer__DnBCompanyRecord__c = null;
        update testAccounts;

        // REFRESH ACCOUNTS AND CHECK THAT INDUSTRIES DID NOT CHANGE
        testAccounts = [SELECT Id, Industry FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].Industry == dnbIndustries[0].Industry__c);
        System.assert(testAccounts[1].Industry == dnbIndustries[1].Industry__c);
        System.assert(testAccounts[2].Industry == dnbIndustries[2].Industry__c);

        Test.stopTest();
    }

    /**
    * @description setApttusIntegrationStatusesTest - Test setApttusIntegrationStatuses trigger method
    */
    public static testMethod void setApttusIntegrationStatusesTest(){
        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', true, 6);
        testAccounts[0].Name = 'Account With Ids and No Data';
        testAccounts[0].A1_Account_ID__c = 'TestID1234';
        //
        testAccounts[1].Name = 'Account With Ids and Data';        
        testAccounts[1].A1_Account_ID__c = 'TestID2468';
        testAccounts[1].BillingStreet = '1234 Test';
        testAccounts[1].ShippingCountry  = 'United States';
        //
        testAccounts[2].Name = 'Account With Partial Ids and Data';
        testAccounts[2].BillingState = 'Colorado';
        testAccounts[2].BillingCountry = 'United States';
        //
        testAccounts[3].Name = 'Account 1 For Update Test';
        testAccounts[3].A1_Account_ID__c = null;
        //
        testAccounts[4].Name = 'Account 2 For Update Test';
        testAccounts[4].A1_Account_ID__c = null;
        //
        testAccounts[5].Name = 'Account 3 For Update Test';
        testAccounts[5].A1_Account_ID__c = null;
        insert testAccounts;

        /////// TEST UPDATES
        // BLANK ACCOUNT STATUS AND ID, ADD BILLING ID AND DATA
        testAccounts[3].A1_Integration_Status__c = null;
        testAccounts[3].BillingStreet = '1234 Test';
        // BLANK ACCOUNT STATUS AND ID, ADD SHIPPING ID AND DATA
        testAccounts[4].A1_Integration_Status__c = null;
        testAccounts[4].BillingState = 'Colorado';
        testAccounts[4].BillingCountry = 'United States';
        // BLANK ACCOUNT STATUS, ADD ID AND WEBSITE DATA
        testAccounts[5].A1_Account_ID__c = 'TestID1357';
        testAccounts[5].A1_Integration_Status__c = null;
        testAccounts[5].Website = 'www.conga.com';
        update new List<Account>{ testAccounts[3], testAccounts[4], testAccounts[5] };

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT A1_Account_ID__c, A1_Integration_Status__c, A1_Billing_Integration_Status__c, A1_Shipping_Integration_Status__c 
                        FROM Account WHERE Id IN :testAccounts];
        // ACCOUNT 1, HAS IDS BUT NO DATA
        System.assert(testAccounts[0].A1_Integration_Status__c == 'Eligible');
        System.assert(String.isBlank(testAccounts[0].A1_Billing_Integration_Status__c));
        System.assert(String.isBlank(testAccounts[0].A1_Shipping_Integration_Status__c));
        // ACCOUNT 2, HAS IDS AND DATA
        System.assert(testAccounts[1].A1_Integration_Status__c == 'Eligible');
        System.assert(String.isBlank(testAccounts[1].A1_Billing_Integration_Status__c));
        System.assert(String.isBlank(testAccounts[1].A1_Shipping_Integration_Status__c));
        // ACCOUNT 3, PARTIAL IDS AND DATA
        System.assert(testAccounts[2].A1_Integration_Status__c == 'Eligible');
        System.assert(String.isBlank(testAccounts[2].A1_Shipping_Integration_Status__c));

        // ACCOUNT 4, UPDATE, BLANK ACCOUNT STATUS, ADD BILLING ID AND DATA
        System.assert(String.isBlank(testAccounts[3].A1_Integration_Status__c));
        System.assert(testAccounts[3].A1_Billing_Integration_Status__c == 'Eligible');
        // ACCOUNT 5, UPDATE, BLANK ACCOUNT STATUS, ADD SHIPPING ID AND DATA
        System.assert(String.isBlank(testAccounts[4].A1_Integration_Status__c));
        System.assert(testAccounts[4].A1_Shipping_Integration_Status__c == 'Eligible');
        // ACCOUNT 6, UPDATE, BLANK ACCOUNT STATUS, ADD WEBSITE DATA
        System.assert(testAccounts[5].A1_Integration_Status__c == 'Eligible');
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

        // CREATE TEST ACCOUNTS, TEST INSERTS
        List<Account> testAccounts = TestingUtility.createSObjectList('Account', true, 3);
        testAccounts[0].A1_Owner_Email__c = '';
        testAccounts[1].A1_Owner_Email__c = 'salesforce@conga123.com';
        testAccounts[2].A1_Owner_Email__c = 'salesforce@conga456.com';
        insert testAccounts;

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, OwnerId, A1_Owner_Email__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].OwnerId == UserInfo.getUserId());
        System.assert(testAccounts[1].OwnerId == salesUser.Id);
        System.assert(testAccounts[2].OwnerId == salesUser2.Id);

        // TEST UPDATES
        testAccounts[0].A1_Owner_Email__c = 'salesforce@conga123.com';
        testAccounts[1].A1_Owner_Email__c = 'salesforce@conga456.com';
        testAccounts[2].A1_Owner_Email__c = '';
        update testAccounts;

        // REFRESH ACCOUNTS AND CHECK FOR CORRECT DATA
        testAccounts = [SELECT Id, OwnerId, A1_Owner_Email__c FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].OwnerId == salesUser.Id);
        System.assert(testAccounts[1].OwnerId == salesUser2.Id);
        System.assert(testAccounts[2].OwnerId == salesUser2.Id); // IF EMAIL IS BLANKED, CURRENT OWNER WILL REMAIN
    }

    /**
    * @description updateShippingAddressTest - Test updateShippingAddress trigger method
    */
    public static testMethod void updateShippingAddressTest(){
        // CREATE TEST DNB RECORD
        DNBoptimizer__DnBCompanyRecord__c testDNB = new DNBoptimizer__DnBCompanyRecord__c(Name = 'DNB1');
        testDNB.DNBoptimizer__PrimaryStreetAddress__c = '390 Interlocken Crescent';
        testDNB.DNBoptimizer__PrimaryStreetAddress2__c = 'Suite 500';
        testDNB.DNBoptimizer__PrimaryCityName__c = 'Broomfield';
        testDNB.DNBoptimizer__PrimaryStateProvinceName__c = 'Colorado';        
        testDNB.DNBoptimizer__PrimaryPostalCode__c = '80223';
        testDNB.DNBoptimizer__PrimaryCountryCode_ISO__c = 'US';
        insert testDNB;

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 4);  
        testAccounts[0].Name = 'Billing Data';
        testAccounts[0].BillingStreet = '1234 Road';
        testAccounts[0].BillingCity = 'Denver';
        testAccounts[0].BillingState = 'Colorado';
        testAccounts[0].BillingPostalCode = '80020';
        testAccounts[0].BillingCountry = 'United States';
        //
        testAccounts[1].Name = 'Billing and Shipping Data';
        testAccounts[1].BillingState = 'Colorado';    
        testAccounts[1].BillingPostalCode = '80023';            
        testAccounts[1].BillingCountry = 'United States';
        testAccounts[1].ShippingState = 'California';
        testAccounts[1].ShippingPostalCode = '90345';        
        testAccounts[1].ShippingCountry = 'United States';
        //
        testAccounts[2].Name = 'No Address Data';
        //
        testAccounts[3].Name = 'Shipping Data - DNB';
        testAccounts[3].ShippingStreet = '123456 Road';
        testAccounts[3].ShippingCity = 'Denver';
        testAccounts[3].ShippingState = 'Colorado';
        testAccounts[3].ShippingPostalCode = '80020';
        testAccounts[3].ShippingCountry = 'United States';
        insert testAccounts;

        Test.startTest();

        // RELOAD ACCOUNTS AND TEST FOR CORRECT DATA
        testAccounts = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                   ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts.size() == 4);
        System.assert(testAccounts[0].ShippingStreet == testAccounts[0].BillingStreet);
        System.assert(testAccounts[0].ShippingCity == testAccounts[0].BillingCity);
        System.assert(testAccounts[0].ShippingState == testAccounts[0].BillingState);
        System.assert(testAccounts[0].ShippingPostalCode == testAccounts[0].BillingPostalCode);
        System.assert(testAccounts[0].ShippingCountry == testAccounts[0].BillingCountry);
        //
        System.assert(testAccounts[1].ShippingStreet == null);
        System.assert(testAccounts[1].ShippingCity == null);
        System.assert(testAccounts[1].ShippingState == 'Colorado');
        System.assert(testAccounts[1].ShippingPostalCode == '80023');
        System.assert(testAccounts[1].ShippingCountry == 'United States');
        //
        System.assert(testAccounts[2].ShippingStreet == null);
        System.assert(testAccounts[2].ShippingCity == null);
        System.assert(testAccounts[2].ShippingState == null);
        System.assert(testAccounts[2].ShippingPostalCode == null);
        System.assert(testAccounts[2].ShippingCountry == null);
        //
        System.assert(testAccounts[3].ShippingStreet == '123456 Road');
        System.assert(testAccounts[3].ShippingCity == 'Denver');
        System.assert(testAccounts[3].ShippingState == 'Colorado');
        System.assert(testAccounts[3].ShippingPostalCode == '80020');
        System.assert(testAccounts[3].ShippingCountry == 'United States');

        // UPDATE ACCOUNT ADDRESS
        testAccounts[0].BillingPostalCode = '80223';
        //
        testAccounts[1].BillingPostalCode = '80020';
        //
        testAccounts[2].BillingState = 'Colorado';
        testAccounts[2].BillingPostalCode = '80020';
        testAccounts[2].BillingCountry = 'United States';
        //
        testAccounts[3].DNBoptimizer__DnBCompanyRecord__c = testDNB.Id;
        update testAccounts;

        // RELOAD ACCOUNTS AND TEST FOR CORRECT DATA
        testAccounts = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                   ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry FROM Account WHERE Id IN :testAccounts];
        System.assert(testAccounts[0].ShippingStreet == testAccounts[0].BillingStreet);
        System.assert(testAccounts[0].ShippingCity == testAccounts[0].BillingCity);
        System.assert(testAccounts[0].ShippingState == testAccounts[0].BillingState);
        System.assert(testAccounts[0].ShippingPostalCode != testAccounts[0].BillingPostalCode); // SHOULD NOT EQUAL SINCE COPY ONLY HAPPENS WHEN ALL OF SHIPPING IS BLANK
        System.assert(testAccounts[0].ShippingCountry == testAccounts[0].BillingCountry);
        //
        System.assert(testAccounts[1].ShippingStreet == null);
        System.assert(testAccounts[1].ShippingCity == null);
        System.assert(testAccounts[1].ShippingState == 'Colorado');
        System.assert(testAccounts[1].ShippingPostalCode == '80020');
        System.assert(testAccounts[1].ShippingCountry == 'United States');
        //
        System.assert(testAccounts[2].ShippingStreet == null);
        System.assert(testAccounts[2].ShippingCity == null);
        System.assert(testAccounts[2].ShippingState == 'Colorado');
        System.assert(testAccounts[2].ShippingPostalCode == '80020');
        System.assert(testAccounts[2].ShippingCountry == 'United States');
        //
        System.assert(testAccounts[3].ShippingStreet == (testDNB.DNBoptimizer__PrimaryStreetAddress__c + '\r\n' + testDNB.DNBoptimizer__PrimaryStreetAddress2__c));
        System.assert(testAccounts[3].ShippingCity == testDNB.DNBoptimizer__PrimaryCityName__c);
        System.assert(testAccounts[3].ShippingState == testDNB.DNBoptimizer__PrimaryStateProvinceName__c);
        System.assert(testAccounts[3].ShippingPostalCode == testDNB.DNBoptimizer__PrimaryPostalCode__c);
        System.assert(testAccounts[3].ShippingCountry == 'United States');

        Test.stopTest();
    }

    /**
    * @description updateOppOnboardingSpecialistTest - Test updateOppOnboardingSpecialist trigger method
    */
    public static testMethod void updateOppOnboardingSpecialistTest(){
        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Sales', LastName = 'Person', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', Team__c = 'US Corporate Sales',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert salesUser;

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].BillingPostalCode = '36450';
        insert testAccounts;

        // CREATE TEST OPPORTUNITY
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', true, 1);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].OwnerId = salesUser.Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Opportunity_Booking_Stamp__c = 'AMER - ENTERPRISE - Sales';
        insert testOpportunities;

        Test.startTest();

        // COVER ACCOUNT TRIGGER METHOD CODE. MAIN OPPORTUNITY TRIGGER METHOD WILL BE FULLY TESTED WITH ITS OWN TEST CLASS
        testAccounts[0].BillingPostalCode = '37450';
        update testAccounts;

        Test.stopTest();     
    }

    /**
    * @description copyCSDivisionStampChangesToOppsTest - Test copyCSDivisionStampChangesToOpps trigger method
    */
    public static testMethod void copyCSDivisionStampChangesToOppsTest(){
        // GET TEST PRICEBOOK ENTRIES
        List<PricebookEntry> testPricebookEntries = [SELECT Id, Product2Id FROM PricebookEntry];
        System.assert(testPricebookEntries.size() == 1);

        // CREATE TEST ACCOUNT
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);  
        testAccounts[0].Name = 'Winterfell Inc.';
        testAccounts[0].CS_Division_Stamp__c = null;
        insert testAccounts;

        // CREATE TEST OPPORTUNITY
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', true, 3);
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].Type = 'New Business';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Amount = 1000;
        //
        testOpportunities[1].AccountId = testAccounts[0].Id;
        testOpportunities[1].StageName = 'Qualify';
        testOpportunities[1].Type = 'New Business';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Amount = 3000;
        //
        testOpportunities[2].AccountId = testAccounts[0].Id;
        testOpportunities[2].StageName = 'Qualify';
        testOpportunities[2].Type = 'Existing Business';
        testOpportunities[2].CloseDate = Date.today();
        testOpportunities[2].Amount = 5000;
        insert testOpportunities;

        Test.startTest();

        // CLOSE WIN OPPS WITH ITEMS
        testOpportunities[0].Sales_Ops_Approved__c = true;
        testOpportunities[0].StageName = 'Closed Won';
        testOpportunities[2].Sales_Ops_Approved__c = true;
        testOpportunities[2].StageName = 'Closed Won';
        update testOpportunities;

        // TEST THAT OPPS HAVE NO CS DIVISION YET
        testOpportunities = [SELECT Id, CS_Division__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities.size() == 3);
        System.assert(testOpportunities[0].CS_Division__c == null);
        System.assert(testOpportunities[1].CS_Division__c == null);
        System.assert(testOpportunities[2].CS_Division__c == null);

        // CHANGE CS DIVISION ON THE ACCOUNT
        testAccounts[0].CS_Division_Stamp__c = 'Division 1B';
        update testAccounts;

        // TEST THAT QUALIFYING OPPS HAVE THE CS DIVISION VALUE FROM THE PARENT ACCOUNT
        testOpportunities = [SELECT Id, CS_Division__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].CS_Division__c == 'Division 1B'); // MOST RECENTLY CLOSED NEW BUSINESS, QUALIFIES
        System.assert(testOpportunities[1].CS_Division__c == 'Division 1B'); // OPEN, QUALIFIES
        System.assert(testOpportunities[2].CS_Division__c == null); // NOT A QUALIFIED OPP, SHOULD NOT GET A VALUE

        Test.stopTest();  
    }

    /**
    * @description updateSubscriptionUpliftDataTest - Test updateSubscriptionUpliftData trigger method
    */
    public static testMethod void updateSubscriptionUpliftDataTest(){
        // GET TEST PRODUCTS
        List<Product2> testProducts = [SELECT Id FROM Product2];
        System.assert(testProducts.size() == 2);

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        testAccounts[0].Renewal_Uplift_Cap__c = 5;
        testAccounts[0].SBQQ__RenewalPricingMethod__c = 'Same';
        insert testAccounts;

        // CREATE TEST QUOTE
        List<SBQQ__Quote__c> testQuotes = (List<SBQQ__Quote__c>)TestingUtility.createSObjectList('SBQQ__Quote__c', false, 1);
        testQuotes[0].SBQQ__Status__c = 'Draft';
        testQuotes[0].SBQQ__Type__c = 'Renewal';
        testQuotes[0].SBQQ__StartDate__c = Date.today();
        testQuotes[0].SBQQ__EndDate__c = Date.today().addDays(365);
        testQuotes[0].SBQQ__Account__c = testAccounts[0].Id;
        insert testQuotes;

        // CREATE TEST CONTRACT
        List<Contract> testContracts = (List<Contract>)TestingUtility.createSObjectList('Contract', false, 1);
        testContracts[0].AccountId = testAccounts[0].Id;
        testContracts[0].Status = 'Draft';
        testContracts[0].SBQQ__Quote__c = testQuotes[0].Id;
        testContracts[0].StartDate = Date.today();
        testContracts[0].ContractTerm = 12;
        insert testContracts;

        // CREATE TEST QUOTE LINES
        List<SBQQ__QuoteLine__c> testQuoteLines = (List<SBQQ__QuoteLine__c>)TestingUtility.createSObjectList('SBQQ__QuoteLine__c', false, 5);
        // ENDING TODAY
        testQuoteLines[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[0].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[0].SBQQ__StartDate__c = Date.today().addDays(-365);
        testQuoteLines[0].SBQQ__EndDate__c = Date.today();
        testQuoteLines[0].SBQQ__Product__c = testProducts[0].Id;
        // STARTING TOMORROW
        testQuoteLines[1].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[1].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[1].SBQQ__StartDate__c = Date.today().addDays(1);
        testQuoteLines[1].SBQQ__EndDate__c = Date.today().addDays(366);
        testQuoteLines[1].SBQQ__Product__c = testProducts[1].Id;
        // CURRENT
        testQuoteLines[2].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[2].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[2].SBQQ__StartDate__c = Date.today().addDays(-180);
        testQuoteLines[2].SBQQ__EndDate__c = Date.today().addDays(185);
        testQuoteLines[2].SBQQ__Product__c = testProducts[0].Id;
        // FUTURE
        testQuoteLines[3].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[3].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[3].SBQQ__StartDate__c = Date.today().addDays(200);
        testQuoteLines[3].SBQQ__EndDate__c = Date.today().addDays(565);
        testQuoteLines[3].SBQQ__Product__c = testProducts[1].Id;
        // EXPIRED
        testQuoteLines[4].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testQuoteLines[4].SBQQ__Quote__c = testQuotes[0].Id;
        testQuoteLines[4].SBQQ__StartDate__c = Date.today().addDays(-370);
        testQuoteLines[4].SBQQ__EndDate__c = Date.today().addDays(-5);
        testQuoteLines[4].SBQQ__Product__c = testProducts[1].Id;
        insert testQuoteLines;

        // CREATE TEST SUBSCRIPTIONS
        List<SBQQ__Subscription__c> testSubscriptions = (List<SBQQ__Subscription__c>)TestingUtility.createSObjectList('SBQQ__Subscription__c', true, 5);
        // CURRENT SUBSCRIPTION ENDING TODAY
        testSubscriptions[0].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[0].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[0].SBQQ__Product__c = testProducts[0].Id;
        testSubscriptions[0].SBQQ__QuoteLine__c = testQuoteLines[0].Id;
        testSubscriptions[0].SBQQ__SubscriptionStartDate__c = testQuoteLines[0].SBQQ__StartDate__c;
        testSubscriptions[0].SBQQ__SubscriptionEndDate__c = testQuoteLines[0].SBQQ__EndDate__c;
        testSubscriptions[0].SBQQ__Quantity__c = 15;
        testSubscriptions[0].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[0].SBQQ__CustomerPrice__c = 150.00;
        // FUTURE SUBSCRIPTION STARTING TOMORROW
        testSubscriptions[1].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[1].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[1].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[1].SBQQ__QuoteLine__c = testQuoteLines[1].Id;
        testSubscriptions[1].SBQQ__SubscriptionStartDate__c = testQuoteLines[1].SBQQ__StartDate__c;
        testSubscriptions[1].SBQQ__SubscriptionEndDate__c = testQuoteLines[1].SBQQ__EndDate__c;
        testSubscriptions[1].SBQQ__Quantity__c = 15;
        testSubscriptions[1].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[1].SBQQ__CustomerPrice__c = 150.00;
        // CURRENT SUBSCRIPTION
        testSubscriptions[2].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[2].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[2].SBQQ__Product__c = testProducts[0].Id;
        testSubscriptions[2].SBQQ__QuoteLine__c = testQuoteLines[2].Id;
        testSubscriptions[2].SBQQ__SubscriptionStartDate__c = testQuoteLines[2].SBQQ__StartDate__c;
        testSubscriptions[2].SBQQ__SubscriptionEndDate__c = testQuoteLines[2].SBQQ__EndDate__c;
        testSubscriptions[2].SBQQ__Quantity__c = 15;
        testSubscriptions[2].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[2].SBQQ__CustomerPrice__c = 150.00;
        // FUTURE SUBSCRIPTION
        testSubscriptions[3].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[3].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[3].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[3].SBQQ__QuoteLine__c = testQuoteLines[3].Id;
        testSubscriptions[3].SBQQ__SubscriptionStartDate__c = testQuoteLines[3].SBQQ__StartDate__c;
        testSubscriptions[3].SBQQ__SubscriptionEndDate__c = testQuoteLines[3].SBQQ__EndDate__c;
        testSubscriptions[3].SBQQ__Quantity__c = 15;
        testSubscriptions[3].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[3].SBQQ__CustomerPrice__c = 150.00;
        // EXPIRED SUBSCRIPTION
        testSubscriptions[4].SBQQ__Account__c = testAccounts[0].Id;
        testSubscriptions[4].SBQQ__Contract__c = testContracts[0].Id;
        testSubscriptions[4].SBQQ__Product__c = testProducts[1].Id;
        testSubscriptions[4].SBQQ__QuoteLine__c = testQuoteLines[4].Id;
        testSubscriptions[4].SBQQ__SubscriptionStartDate__c = testQuoteLines[4].SBQQ__StartDate__c;
        testSubscriptions[4].SBQQ__SubscriptionEndDate__c = testQuoteLines[4].SBQQ__EndDate__c;
        testSubscriptions[4].SBQQ__Quantity__c = 15;
        testSubscriptions[4].SBQQ__ListPrice__c = 250.00;
        testSubscriptions[4].SBQQ__CustomerPrice__c = 150.00;
        insert testSubscriptions;

        Test.startTest();

        // TEST THAT SUBSCRIPTIONS DO NOT HAVE ANY RENEWAL RATES
        testSubscriptions = [SELECT Id, SBQQ__RenewalUpliftRate__c FROM SBQQ__Subscription__c WHERE Id IN :testSubscriptions];
        System.assert(testSubscriptions.size() == 5);
        System.assert(testSubscriptions[0].SBQQ__RenewalUpliftRate__c == null);
        System.assert(testSubscriptions[1].SBQQ__RenewalUpliftRate__c == null);
        System.assert(testSubscriptions[2].SBQQ__RenewalUpliftRate__c == null);
        System.assert(testSubscriptions[3].SBQQ__RenewalUpliftRate__c == null);
        System.assert(testSubscriptions[4].SBQQ__RenewalUpliftRate__c == null);

        // UPDATE ACCOUNT RENEWAL PRICING METHOD
        testAccounts[0].SBQQ__RenewalPricingMethod__c = 'Uplift';
        update testAccounts;

        // REFRESH SUBSCRIPTION LIST, TEST FOR CORRECT DATA
        testSubscriptions = [SELECT Id, SBQQ__RenewalUpliftRate__c FROM SBQQ__Subscription__c WHERE Id IN :testSubscriptions];
        System.assert(testSubscriptions[0].SBQQ__RenewalUpliftRate__c == 5.00);
        System.assert(testSubscriptions[1].SBQQ__RenewalUpliftRate__c == 5.00);
        System.assert(testSubscriptions[2].SBQQ__RenewalUpliftRate__c == 5.00);
        System.assert(testSubscriptions[3].SBQQ__RenewalUpliftRate__c == 5.00);
        System.assert(testSubscriptions[4].SBQQ__RenewalUpliftRate__c == null);

        // UPDATE ACCOUNT RENEWAL PRICING METHOD
        testAccounts[0].SBQQ__RenewalPricingMethod__c = 'List';
        update testAccounts;

        // TEST THAT SUBSCRIPTIONS DO NOT HAVE ANY RENEWAL RATES
        testSubscriptions = [SELECT Id, SBQQ__RenewalUpliftRate__c FROM SBQQ__Subscription__c WHERE Id IN :testSubscriptions];
        System.assert(testSubscriptions[0].SBQQ__RenewalUpliftRate__c == null);
        System.assert(testSubscriptions[1].SBQQ__RenewalUpliftRate__c == null);
        System.assert(testSubscriptions[2].SBQQ__RenewalUpliftRate__c == null);
        System.assert(testSubscriptions[3].SBQQ__RenewalUpliftRate__c == null);
        System.assert(testSubscriptions[4].SBQQ__RenewalUpliftRate__c == null);

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20200325
    * @description updateOppPartnerExpertiseScoreTest - Test for the updateOppPartnerExpertiseScore trigger method
    */
    public static testmethod void updateOppPartnerExpertiseScoreTest() {
        // CREATE TEST ACCOUNTS
        Id partnerRecordTypeId = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[1].RecordTypeId = partnerRecordTypeId;
        testAccounts[1].Partner_Specialist__c = 'Conga Grid;Conga Collaborate;Conga AI';
        testAccounts[1].Partner_Expert__c = 'Conga Automation;Conga Composer';
        testAccounts[2].RecordTypeId = partnerRecordTypeId;
        testAccounts[2].Partner_Specialist__c = 'Conga Collaborate;Conga AI';
        testAccounts[2].Partner_Expert__c = 'Conga Composer;Conga Automation;';
        insert testAccounts;

        // TEST OPP
        List<Opportunity> testOpps = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpps[0].AccountId = testAccounts[0].Id;
        testOpps[0].ImplementationPartnerPrimary__c = testAccounts[1].Id;
        testOpps[1].AccountId = testAccounts[0].Id;
        testOpps[1].ImplementationPartnerPrimary__c = testAccounts[2].Id;
        insert testOpps;

        Test.startTest();

        testAccounts[1].Partner_Expert__c = 'Conga Composer';
        testAccounts[2].Partner_Specialist__c = 'Conga Collaborate;Conga AI;Conga Grid';
        update testAccounts;

        ///////////// NO ASSERTS, PRIMARY CODE FOUND IN THE OPPORTUNITY HELPER CLASS WILL BE TESTED BY ITS OWN TEST CLASS //////////////

        Test.stopTest();
    }

    /**
    * @author ECS, ERedding
    * @date 20210114
    * @description partnerAccountOwnerChangeTest - Test for the partnerAccountOwnerChange trigger method
    */
    public static testmethod void partnerAccountOwnerChangeTest() {
        TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);
        
        // GET ACCOUNT RECORD TYPES
        Id partnerAccountRT = UtilityClass.getRecordTypesForObject('Account').get('Partner_Account');

        // CREATE TEST USERS
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Sales User'];
        User salesUser = new User(Alias = 'admin1', Email = 'salesforce@conga.com', EmailEncodingKey = 'UTF-8', FirstName = 'Sales', LastName = 'Person', 
        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', Team__c = 'US Corporate Sales',
        UserName = 'testUser1' + UserInfo.getOrganizationId() + '@testorg.com', Segment__c = 'Enterprise');
        insert salesUser;

        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 3);
        testAccounts[0].RecordTypeId = partnerAccountRT;
        testAccounts[1].RecordTypeId = partnerAccountRT;
        testAccounts[1].OwnerId = salesUser.Id;
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 2);
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Type = 'Renewal';
        testOpportunities[0].AccountId = testAccounts[2].Id;
        testOpportunities[0].ImplementationPartnerPrimary__c = testAccounts[0].Id;
        //
        testOpportunities[1].StageName = 'Qualify';
        testOpportunities[1].CloseDate = Date.today();
        testOpportunities[1].Type = 'Renewal';
        testOpportunities[1].AccountId = testAccounts[2].Id;
        testOpportunities[1].ImplementationPartnerPrimary__c = testAccounts[1].Id;
        insert testOpportunities;

        Test.startTest();

        // REFRESH OPPS AND TEST FOR CORRECT DATA
        testOpportunities = [SELECT Id, ImplementationPartnerPrimary__c, Consulting_Partner_Account_Owner__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assertEquals(UserInfo.getName(), testOpportunities[0].Consulting_Partner_Account_Owner__c);
        System.assertEquals((salesUser.FirstName + ' ' + salesUser.LastName), testOpportunities[1].Consulting_Partner_Account_Owner__c);
        
        // CHANGE PARTNER ACCOUNT OWNERS
        testAccounts[0].OwnerId = salesUser.Id;
        testAccounts[1].OwnerId = UserInfo.getUserId();
        update testAccounts;

        // REFRESH OPPS AND TEST FOR CORRECT DATA
        testOpportunities = [SELECT Id, ImplementationPartnerPrimary__c, Consulting_Partner_Account_Owner__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assertEquals((salesUser.FirstName + ' ' + salesUser.LastName), testOpportunities[0].Consulting_Partner_Account_Owner__c);
        System.assertEquals(UserInfo.getName(), testOpportunities[1].Consulting_Partner_Account_Owner__c);

        Test.stopTest();
    }


    /**
    * @author ECS, ERedding
    * @date 20200512
    * @description updateOppCSForecastTest - Test for the updateOppCSForecast trigger method
    */
    public static testmethod void updateOppCSForecastTest() {
        // CREATE TEST ACCOUNTS
        List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', false, 1);
        testAccounts[0].Customer_likely_to__c = 'Renew at current level';
        insert testAccounts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = (List<Opportunity>)TestingUtility.createSObjectList('Opportunity', false, 1);
        testOpportunities[0].StageName = 'Qualify';
        testOpportunities[0].CloseDate = Date.today();
        testOpportunities[0].Type = 'Renewal';
        testOpportunities[0].AccountId = testAccounts[0].Id;
        testOpportunities[0].Current_Automation_Ave_MRR__c = 154.76;
        testOpportunities[0].Current_Courier_Ave_MRR__c = 187.56;
        insert testOpportunities;

        Test.startTest();

        // REFRESH OPPS AND TEST FOR CORRECT DATA
        testOpportunities = [SELECT Id, CS_Forecast_Apex__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].CS_Forecast_Apex__c == -17.116);
        
        // UPDATE ACCOUNT
        testAccounts[0].Customer_likely_to__c = 'Churn - potential to save';
        update testAccounts;

        // REFRESH OPPS AND TEST FOR CORRECT DATA
        testOpportunities = [SELECT Id, CS_Forecast_Apex__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].CS_Forecast_Apex__c == -239.624);

        // UPDATE OPACCOUNTPS
        testAccounts[0].Customer_likely_to__c = 'Churn - no chance to save';
        update testAccounts;

        // REFRESH OPPS AND TEST FOR CORRECT DATA
        testOpportunities = [SELECT Id, CS_Forecast_Apex__c FROM Opportunity WHERE Id IN :testOpportunities];
        System.assert(testOpportunities[0].CS_Forecast_Apex__c == -342.32);

        Test.stopTest();
    }



}