/**
* @author Conga Services, ERedding
* @date 20180905
* @version 1.00
* @description IntacctFieldSyncHelperTest - Test class for the IntacctFieldSyncHelper class
*/
@isTest
public class IntacctFieldSyncHelperTest {

    /**
    * @description setup - Setup test data
    */
    @testSetup
    public static void setup() {
        // CREATE TEST INTACCT AR TERMS
        ia_crm__AR_Terms__c terms1 = new ia_crm__AR_Terms__c(Name = 'N30', ia_crm__Status__c = true, Conga_Term__c = 'Net 30');
        ia_crm__AR_Terms__c terms2 = new ia_crm__AR_Terms__c(Name = 'N60', ia_crm__Status__c = true, Conga_Term__c = 'Net 60');
        insert new List<ia_crm__AR_Terms__c>{ terms1, terms2 };

        // CREATE TEST INTACCT ENTITIES
        ia_crm__Intacct_Entity__c entity1 = new ia_crm__Intacct_Entity__c(Name = 'AppExtremes , Inc DBA Conga', ia_crm__Intacct_Entity_ID__c = 'ALLC', ia_crm__Entity_Type__c = 'Entity', 
                                                                          ia_crm__Base_Currency__c = 'USD', ia_crm__Status__c = true);
        ia_crm__Intacct_Entity__c entity2 = new ia_crm__Intacct_Entity__c(Name = 'Octiv', ia_crm__Intacct_Entity_ID__c = 'OCTIV', ia_crm__Entity_Type__c = 'Entity', 
                                                                          ia_crm__Base_Currency__c = 'USD', ia_crm__Status__c = true);
        insert new List<ia_crm__Intacct_Entity__c>{ entity1, entity2 };

        // CREATE TEST INTACCT DEPARTMENT       
        ia_crm__Department__c department1 = new ia_crm__Department__c(Name = 'Department 1', ia_crm__Department_ID__c = '100');
        ia_crm__Department__c department2 = new ia_crm__Department__c(Name = 'Department 2', ia_crm__Department_ID__c = '200');
        insert new List<ia_crm__Department__c>{ department1, department2 };

        // CREATE TEST INTACCT DEPARTMENT       
        ia_crm__Billing_Template__c template1 = new ia_crm__Billing_Template__c(Name = 'OneTime', ia_crm__Status__c = true, ia_crm__Description__c = 'OneTime billing');
        insert template1;

        // CREATE TEST INTACCT EMPLOYEE
        ia_crm__Employees__c employee1 = new ia_crm__Employees__c(Name = 'Test User1', ia_crm__Employee_ID__c = 'tuser1', ia_crm__Department__c = department1.Id, ia_crm__Status__c = true);
        ia_crm__Employees__c employee2 = new ia_crm__Employees__c(Name = 'Test User2', ia_crm__Employee_ID__c = 'tuser2', ia_crm__Department__c = department2.Id, ia_crm__Status__c = true);
        insert new List<ia_crm__Employees__c>{ employee1, employee2 };

        // CREATE TEST USERS
        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = new User(Alias = 'tuser1', Email='salesforce@CongaServicesTestEmail.com', EmailEncodingKey='UTF-8', LastName='User1', LanguageLocaleKey='en_US',
                                  LocaleSidKey='en_US', ProfileId = sysAdmin.Id, TimeZoneSidKey='America/Los_Angeles',
                                  UserName='testUser1' + UserInfo.getOrganizationId() +  '@testorg' + UserInfo.getOrganizationId() +  '.com',
                                  Department = 'Department 1', Intacct_Entity_Id__c = 'ALLC', Intacct_Id__c = 'tuser1');
        User testUser2 = new User(Alias = 'tuser2', Email='salesforce@CongaServicesTestEmail.com', EmailEncodingKey='UTF-8', LastName='User2', LanguageLocaleKey='en_US',
                                  LocaleSidKey='en_US', ProfileId = sysAdmin.Id, TimeZoneSidKey='America/Los_Angeles', 
                                  UserName='testUser2' + UserInfo.getOrganizationId() +  '@testorg' + UserInfo.getOrganizationId() +  '.com',
                                  Department = 'Department 2', Intacct_Entity_Id__c = 'ALLC', Intacct_Id__c = 'tuser2');
        insert new List<User>{ testUser1, testUser2 };

        // CREATE TEST PRODUCT 
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'testProd', IsActive = true, Family = 'Support', ia_crm__Flat_fixed_amount_frequency__c = 'One-time',
                                            ia_crm__Billing_method__c = 'Fixed price', ia_crm__Billing_Template__c = template1.Id);
        insert testProduct;

        // CREATE TEST PRICEBOOK ENTRY
        PricebookEntry testEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct.Id, IsActive = true, UnitPrice = 50.00);
        insert testEntry;       

        // CREATE TEST BILLING ACCOUNT 
        Account testBillingAccount = new Account(Name = 'Test Billing Account', OwnerId = testUser1.Id);
        insert testBillingAccount;

        // CREATE TEST BILLING CONTACT
        Contact testBillingContact1 = new Contact(FirstName = 'Billing', LastName = 'Contact', AccountId = testBillingAccount.Id);
        Contact testBillingContact2 = new Contact(FirstName = 'Billing', LastName = 'Contact2', AccountId = testBillingAccount.Id);
        insert new List<Contact>{ testBillingContact1, testBillingContact2 };

        testBillingAccount.BillingContact__c = testBillingContact2.Id;
        update testBillingAccount;
    }

    /**
    * @description processAccountBeforeChangesTest - Test happy path of code for Account Before Insert/Update field syncing
    */
    public static testmethod void processAccountBeforeChangesTest() {
        // TURN OFF ACCOUNT OWNERSHIP CHANGE VALIDATION
        TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);

        // GET TEST USERS
        List<User> testUsers = [SELECT Id, Intacct_Id__c, Intacct_Entity_Id__c FROM User WHERE Alias IN ('tuser1','tuser2')];
        System.assert(testUsers.size() == 2);

        // GET TEST EMPLOYEES
        List<ia_crm__Employees__c> testEmployees = [SELECT Id, ia_crm__Employee_ID__c, ia_crm__Department__c FROM ia_crm__Employees__c WHERE ia_crm__Employee_ID__c IN ('tuser1','tuser2')];
        System.assert(testEmployees.size() == 2);

        // GET TEST BILLING CONTACT
        List<Contact> testBillingContacts = [SELECT Id FROM Contact WHERE FirstName = 'Billing'];
        System.assert(testBillingContacts.size() == 2);

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account', BillingContact__c = testBillingContacts[0].Id, OwnerId = testUsers[0].Id);

        Test.startTest();

        // SAVE ACCOUNT TO EXECUTE TRIGGER, UPDATE ACCOUNT WITH LATEST CHANGES
        insert testAccount;
        testAccount = [SELECT Id, BillingContact__c, ia_crm__Bill_to_Contact__c, ia_crm__Ship_to_Contact__c, ia_crm__SalesRep__c, ia_crm__Sales_rep__c FROM Account WHERE Id = :testAccount.Id];
        System.assert(testAccount.ia_crm__Bill_to_Contact__c == testAccount.BillingContact__c);
        System.assert(testAccount.ia_crm__Ship_to_Contact__c == testAccount.BillingContact__c);
        System.assert(testAccount.ia_crm__SalesRep__c == testEmployees[0].Id);
        System.assert(testAccount.ia_crm__Sales_rep__c == testUsers[0].Intacct_Id__c);

        testAccount.BillingContact__c = testBillingContacts[1].Id;
        testAccount.OwnerId = testUsers[1].Id;
        update testAccount;

        testAccount = [SELECT Id, BillingContact__c, ia_crm__Bill_to_Contact__c, ia_crm__Ship_to_Contact__c, ia_crm__SalesRep__c, ia_crm__Sales_rep__c FROM Account WHERE Id = :testAccount.Id];
        System.assert(testAccount.ia_crm__Bill_to_Contact__c == testAccount.BillingContact__c);
        System.assert(testAccount.ia_crm__Ship_to_Contact__c == testAccount.BillingContact__c);
        System.assert(testAccount.ia_crm__SalesRep__c == testEmployees[1].Id);
        System.assert(testAccount.ia_crm__Sales_rep__c == testUsers[1].Intacct_Id__c);

        Test.stopTest();
    }

    /**
    * @description processAccountAfterChangesTest - Test happy path of code for Account After Insert/Update field syncing
    */
    public static testmethod void processAccountAfterChangesTest() {
        // TURN OFF ACCOUNT OWNERSHIP CHANGE VALIDATION
        TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);

        // GET RECORD TYPES
        Map<String, Id> oppRecordTypes = UtilityClass.getRecordTypesForObject('Opportunity');

        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE Alias IN ('tuser1','tuser2')];
        System.assert(testUsers.size() == 2);

        // GET TEST EMPLOYEES
        List<ia_crm__Employees__c> testEmployees = [SELECT Id, ia_crm__Department__c FROM ia_crm__Employees__c WHERE ia_crm__Employee_ID__c IN ('tuser1','tuser2')];
        System.assert(testEmployees.size() == 2);

        // GET TEST PRICEBOOK ENTRY
        List<PricebookEntry> testEntry = [SELECT Id FROM PricebookEntry WHERE ProductCode = 'testProd'];
        System.assert(testEntry.size() == 1);       

        // GET TEST BILLING ACCOUNT
        List<Account> testBillingAccount = [SELECT Id FROM Account WHERE Name = 'Test Billing Account'];
        System.assert(testBillingAccount.size() == 1);

        // GET TEST BILLING CONTACT
        List<Contact> testBillingContacts = [SELECT Id FROM Contact WHERE AccountId IN :testBillingAccount];
        System.assert(testBillingContacts.size() == 2);

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account', BillingContact__c = testBillingContacts[0].Id, OwnerId = testUsers[0].Id);
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = new List<Opportunity>();
        Opportunity testOpportunity1 = new Opportunity(Name = 'Direct Opp', AccountId = testAccount.Id, Type = 'New Business', Billing_Party__c = testBillingAccount[0].Id,
                                                       RecordTypeId = oppRecordTypes.get('Direct'), StageName = 'Qualify', CloseDate = Date.today().addDays(15));
        Opportunity testOpportunity2 = new Opportunity(Name = 'Indirect Opp', AccountId = testAccount.Id, Type = 'New Business', Billing_Party__c = testBillingAccount[0].Id,
                                                       RecordTypeId = oppRecordTypes.get('Indirect'), StageName = 'Qualify', CloseDate = Date.today().addDays(15));
        testOpportunities.add(testOpportunity1); testOpportunities.add(testOpportunity2);
        insert testOpportunities;

        // CREATE TEST OPP LINE ITEMS
        List<OpportunityLineItem> testOppItems = TestingUtility.createSObjectList('OpportunityLineItem', false, 4); 
        for(OpportunityLineItem oppItem : testOppItems){
            oppItem.PricebookEntryId = testEntry[0].Id;
            oppItem.Quantity = 1;
            oppItem.UnitPrice = 50.00;
        }
        testOppItems[0].OpportunityId = testOpportunity1.Id;
        testOppItems[1].OpportunityId = testOpportunity1.Id;
        testOppItems[2].OpportunityId = testOpportunity2.Id;
        testOppItems[3].OpportunityId = testOpportunity2.Id;
        insert testOppItems;

        Test.startTest();

        testAccount.BillingContact__c = testBillingContacts[1].Id;
        testAccount.OwnerId = testUsers[1].Id;      
        update testAccount;

        testOpportunities = [SELECT Id, RecordType.DeveloperName, ia_crm__Bill_to__c, ia_crm__Ship_to__c, ia_crm__Department__c FROM Opportunity WHERE Id IN :testOpportunities];
        // TEST OPPS FOR CORRECT VALUES
        System.debug(testOpportunities[0].RecordType.DeveloperName);
        System.debug(testAccount.BillingContact__c);
        System.assert(testOpportunities[0].ia_crm__Bill_to__c == testAccount.BillingContact__c);
        System.assert(testOpportunities[0].ia_crm__Ship_to__c == testAccount.BillingContact__c);
        System.assert(testOpportunities[0].ia_crm__Department__c == testEmployees[1].ia_crm__Department__c);
        System.assert(testOpportunities[1].ia_crm__Department__c == testEmployees[1].ia_crm__Department__c);        

        testBillingAccount[0].BillingContact__c = testBillingContacts[0].Id;
        update testBillingAccount;

        testOpportunities = [SELECT Id, ia_crm__Bill_to__c, ia_crm__Ship_to__c, ia_crm__Department__c FROM Opportunity WHERE Id IN :testOpportunities];
        // TEST DIRECT OPP FOR CORRECT VALUES, BILL TO AND SHIP TO SHOULD NOT HAVE CHANGED
        System.assert(testOpportunities[0].ia_crm__Bill_to__c != testBillingAccount[0].BillingContact__c);
        System.assert(testOpportunities[0].ia_crm__Ship_to__c != testBillingAccount[0].BillingContact__c);
        // TEST INDIRECT OPP FOR CORRECT VALUES, BILL TO AND SHIP TO SHOULD HAVE CHANGED SINCE THE BILLING PARTY ACCOUNT WAS MODIFIED
        System.assert(testOpportunities[1].ia_crm__Bill_to__c == testBillingAccount[0].BillingContact__c);
        System.assert(testOpportunities[1].ia_crm__Ship_to__c == testBillingAccount[0].BillingContact__c);

        testOppItems = [SELECT Id, ia_crm__Employee__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        // TEST OPP LINE ITEMS FOR CORRECT VALUES
        System.assert(testOppItems[0].ia_crm__Employee__c == testEmployees[1].Id);
        System.assert(testOppItems[1].ia_crm__Employee__c == testEmployees[1].Id);
        System.assert(testOppItems[2].ia_crm__Employee__c == testEmployees[1].Id);
        System.assert(testOppItems[3].ia_crm__Employee__c == testEmployees[1].Id);

        Test.stopTest();
    }

    /**
    * @description processAccountFieldChangesTest_Exceptions - Test bad data and error handling for Account Field syncing
    */
    public static testmethod void processAccountFieldChangesTest_Exceptions() {
        Test.startTest();

        // TRY EXECUTING METHODS WITH NULL PARAMETERS
        IntacctFieldSyncHelper.processAccountBeforeChanges(null, null);
        IntacctFieldSyncHelper.processAccountAfterChanges(null, null);

        // TRY EXECUTING METHODS WITH EMPTY PARAMETERS
        IntacctFieldSyncHelper.processAccountBeforeChanges(new List<Account>(), new Map<Id, Account>());
        IntacctFieldSyncHelper.processAccountAfterChanges(new List<Account>(), new Map<Id, Account>());

        Test.stopTest();
    }
    
    /**
    * @description processContactBeforeChangesTest - Test happy path of code for Contact Before Insert/Update field syncing
    */
    public static testmethod void processContactBeforeChangesTest() {
        // TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // TEST CONTACT
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'contact@mailinator.com', Phone = '123-123-1234', AccountId = testAccount.Id);
        insert testContact;

        Test.startTest();

        testContact.FirstName = 'Test2';
        update testContact;
        testContact = [SELECT Id, ia_crm__Sync_With_Intacct__c FROM Contact WHERE Id = :testContact.Id];
        System.assert(testContact.ia_crm__Sync_With_Intacct__c == true);

        testContact.ia_crm__Sync_With_Intacct__c = false; 
        testContact.LastName = 'Contact2';
        update testContact;
        testContact = [SELECT Id, ia_crm__Sync_With_Intacct__c FROM Contact WHERE Id = :testContact.Id];
        System.assert(testContact.ia_crm__Sync_With_Intacct__c == true);

        testContact.ia_crm__Sync_With_Intacct__c = false; 
        testContact.Email = 'contact2@mailinator.com';
        update testContact;     
        testContact = [SELECT Id, ia_crm__Sync_With_Intacct__c FROM Contact WHERE Id = :testContact.Id];
        System.assert(testContact.ia_crm__Sync_With_Intacct__c == true);

        testContact.ia_crm__Sync_With_Intacct__c = false; 
        testContact.Phone = '456-123-1234';
        update testContact;     
        testContact = [SELECT Id, ia_crm__Sync_With_Intacct__c FROM Contact WHERE Id = :testContact.Id];
        System.assert(testContact.ia_crm__Sync_With_Intacct__c == true);

        Test.stopTest();
    }

    /**
    * @description processContactFieldChangesTest_Exceptions - Test bad data and error handling for Contact Field syncing
    */
    public static testmethod void processContactFieldChangesTest_Exceptions() {
        Test.startTest();

        // TRY EXECUTING METHOD WITH NULL PARAMETERS
        IntacctFieldSyncHelper.processContactBeforeChanges(null, null);
        
        // TRY EXECUTING METHOD WITH EMPTY PARAMETERS
        IntacctFieldSyncHelper.processContactBeforeChanges(new List<Contact>(), new Map<Id, Contact>());

        Test.stopTest();
    }

    /**
    * @description processContractBeforeChangesTest - Test happy path of code for Contract Before Insert/Update field syncing
    */
    public static testmethod void processContractBeforeChangesTest() {
        // GET RECORD TYPES
        Map<String, Map<String, Id>> recordTypes = UtilityClass.getRecordTypesForObjects(new List<String>{ 'Opportunity', 'Contract' });
        System.assert(!recordTypes.isEmpty());
        System.assert(recordTypes.containsKey('Opportunity'));
        System.assert(recordTypes.containsKey('Contract'));

        // GET INTACCT TERMS
        List<ia_crm__AR_Terms__c> intacctTerms = [SELECT Id, Name, Conga_Term__c FROM ia_crm__AR_Terms__c];
        System.assert(intacctTerms.size() == 2);

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        Opportunity testOpportunity1 = new Opportunity(Name = 'Indirect Opp', AccountId = testAccount.Id, Type = 'New Business', RecordTypeId = recordTypes.get('Opportunity').get('Indirect'),
                                                       StageName = 'Qualify', CloseDate = Date.today().addDays(15));
        insert testOpportunity1;

        Test.startTest();

        // CREATE TEST CONTRACT
        Contract testContract = new Contract(Name = 'Test Contract', RecordTypeId = recordTypes.get('Contract').get('Customer_Subscription'), AccountId = testAccount.Id, Contract_Type__c = 'Customer Subscription',
                                             StartDate = Date.today().addDays(15), ContractTerm = 24, SBQQ__Opportunity__c = testOpportunity1.Id, Payment_Terms_non_Net_30__c = 'Net 30');
        insert testContract;

        // UPDATE CONTRACT AND LOAD NECESSARY FIELDS, TEST FOR CORRECT VALUES
        testContract = [SELECT Id, AccountId, ia_crm__End_Customer__c, ia_crm__Term__c FROM Contract WHERE Id = :testContract.Id];
        System.assert(testContract.ia_crm__End_Customer__c == testContract.AccountId);
        System.assert(testContract.ia_crm__Term__c == intacctTerms[0].Id);

        Test.stopTest();
    }

    /**
    * @description processContractAfterChangesTest - Test happy path of code for Contract After Insert/Update field syncing
    */
    public static testmethod void processContractAfterChangesTest() {
        // GET RECORD TYPES
        Map<String, Map<String, Id>> recordTypes = UtilityClass.getRecordTypesForObjects(new List<String>{ 'Opportunity', 'Contract' });
        System.assert(!recordTypes.isEmpty());
        System.assert(recordTypes.containsKey('Opportunity'));
        System.assert(recordTypes.containsKey('Contract'));

        // GET INTACCT TERMS
        List<ia_crm__AR_Terms__c> intacctTerms = [SELECT Id, Name, Conga_Term__c FROM ia_crm__AR_Terms__c];
        System.assert(intacctTerms.size() == 2);

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = new List<Opportunity>();
        Opportunity testOpportunity1 = new Opportunity(Name = 'Direct Opp', AccountId = testAccount.Id, Type = 'New Business', RecordTypeId = recordTypes.get('Opportunity').get('Direct'), 
                                                        StageName = 'Qualify', CloseDate = Date.today().addDays(15), Sales_Ops_Approved__c = true);

        Opportunity testOpportunity2 = new Opportunity(Name = 'Direct Opp', AccountId = testAccount.Id, Type = 'Existing Business', RecordTypeId = recordTypes.get('Opportunity').get('Direct'),
                                                        StageName = 'Qualify', CloseDate = Date.today().addDays(15));
        testOpportunities.add(testOpportunity1); testOpportunities.add(testOpportunity2);
        insert testOpportunities;

        Test.startTest();

        // CREATE TEST CONTRACT 1
        List<Contract> testContracts = new List<Contract>();        
        Contract testContract1 = new Contract(Name = 'Test Contract 1', RecordTypeId = recordTypes.get('Contract').get('Customer_Subscription'), AccountId = testAccount.Id, Contract_Type__c = 'Customer Subscription',
                                                StartDate = Date.today().addDays(15), ContractTerm = 24, SBQQ__Opportunity__c = testOpportunity1.Id, Payment_Terms_non_Net_30__c = 'Net 30');
        // CREATE TEST CONTRACT 2
        Contract testContract2 = new Contract(Name = 'Test Contract 2', RecordTypeId = recordTypes.get('Contract').get('Customer_Subscription'), AccountId = testAccount.Id, Contract_Type__c = 'Customer Subscription',
                                                StartDate = Date.today().addDays(15), ContractTerm = 24, SBQQ__Opportunity__c = testOpportunity2.Id, Payment_Terms_non_Net_30__c = 'Net 60');
        testContracts.add(testContract1); testContracts.add(testContract2);
        insert testContracts;

        // UPDATE OPPORTUNITIES AND LOAD NECESSARY FIELDS, TEST FOR CORRECT VALUES
        testOpportunities = [SELECT Id, ContractId, Payment_Terms__c FROM Opportunity WHERE Id = :testOpportunities];
        System.assert(testOpportunities[0].ContractId == testContracts[0].Id);
        System.assert(testOpportunities[0].Payment_Terms__c == testContracts[0].Payment_Terms_non_Net_30__c);
        System.assert(testOpportunities[1].ContractId == testContracts[1].Id);
        System.assert(testOpportunities[1].Payment_Terms__c == testContracts[1].Payment_Terms_non_Net_30__c);

        // MAKE UPDATES TO THE CONTRACT, SAVE CHANGES
        testContracts[0].Payment_Terms_non_Net_30__c = 'Net 60';
        testContracts[0].SBQQ__Opportunity__c = testOpportunity2.Id;
        testContracts[1].Payment_Terms_non_Net_30__c = 'Net 30';
        testContracts[1].SBQQ__Opportunity__c = testOpportunity1.Id;
        update testContracts;

        // UPDATE OPPORTUNITIES AND TEST FOR CORRECT VALUES
        testOpportunities = [SELECT Id, ContractId, Payment_Terms__c FROM Opportunity WHERE Id = :testOpportunities];
        System.assert(testOpportunities[0].ContractId == testContracts[1].Id);
        System.assert(testOpportunities[0].Payment_Terms__c == testContracts[1].Payment_Terms_non_Net_30__c);
        System.assert(testOpportunities[1].ContractId == testContracts[0].Id);
        System.assert(testOpportunities[1].Payment_Terms__c == testContracts[0].Payment_Terms_non_Net_30__c);

        Test.stopTest();
    }

    /**
    * @description processContractFieldChangesTest_Exceptions - Test bad data and error handling for Contract Field syncing
    */
    public static testmethod void processContractFieldChangesTest_Exceptions() {
        Test.startTest();

        // TRY EXECUTING METHOD WITH NULL PARAMETERS
        IntacctFieldSyncHelper.processContractBeforeChanges(null, null);
        IntacctFieldSyncHelper.processContractAfterChanges(null, null);

        // TRY EXECUTING METHOD WITH EMPTY PARAMETERS
        IntacctFieldSyncHelper.processContractBeforeChanges(new List<Contract>(), new Map<Id, Contract>());
        IntacctFieldSyncHelper.processContractAfterChanges(new List<Contract>(), new Map<Id, Contract>());

        Test.stopTest();
    }

    /**
    * @description processOpportunityBeforeChangesTest - Test happy path of code for Opportunity Before Insert/Update field syncing
    */
    public static testmethod void processOpportunityBeforeChangesTest() {
        // GET RECORD TYPES
        Map<String, Id> oppRecordTypes = UtilityClass.getRecordTypesForObject('Opportunity');
        System.assert(!oppRecordTypes.isEmpty());

        // GET TEST INTACCT AR TERMS
        List<ia_crm__AR_Terms__c> intacctTerms = [SELECT Id, Name FROM ia_crm__AR_Terms__c];
        System.assert(intacctTerms.size() == 2);

        // GET TEST INTACCT ENTITIES
        List<ia_crm__Intacct_Entity__c> intacctEntities = [SELECT Id, ia_crm__Intacct_Entity_ID__c FROM ia_crm__Intacct_Entity__c];
        System.assert(intacctEntities.size() == 2);
        
        // GET TEST BILLING ACCOUNT, USES BILLING CONTACT 2
        List<Account> testBillingAccount = [SELECT Id, BillingContact__c FROM Account WHERE Name = 'Test Billing Account'];
        System.assert(testBillingAccount.size() == 1);

        // GET TEST BILLING CONTACTS
        List<Contact> testBillingContacts = [SELECT Id FROM Contact WHERE AccountId IN :testBillingAccount];
        System.assert(testBillingContacts.size() == 2);

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account', BillingContact__c = testBillingContacts[0].Id);
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = new List<Opportunity>();
        Opportunity testOpportunity1 = new Opportunity(Name = 'Direct Opp', AccountId = testAccount.Id, Type = 'New Business', RecordTypeId = oppRecordTypes.get('Direct'), 
                                                        StageName = 'Qualify', CloseDate = Date.today().addDays(15), Entity_Code__c = 'Conga', Billing_Party__c = testBillingAccount[0].Id,
                                                        Payment_Terms__c = 'Net 30', MRR_Sub_Start__c = Date.today(), MRR_Sub_End__c = Date.today().addDays(180));

        Opportunity testOpportunity2 = new Opportunity(Name = 'Indirect Opp', AccountId = testAccount.Id, Type = 'New Business', RecordTypeId = oppRecordTypes.get('Indirect'),
                                                        StageName = 'Qualify', CloseDate = Date.today().addDays(15), Entity_Code__c = 'Octiv', Billing_Party__c = testBillingAccount[0].Id,
                                                        Payment_Terms__c = 'Net 60', MRR_Sub_Start__c = Date.today(), MRR_Sub_End__c = Date.today().addDays(180));

        Opportunity testOpportunity3 = new Opportunity(Name = 'Direct Opp', AccountId = testAccount.Id, Type = 'New Business', RecordTypeId = oppRecordTypes.get('Direct'),
                                                        StageName = 'Closed Won', CloseDate = Date.today(), Entity_Code__c = 'Octiv', Billing_Party__c = testBillingAccount[0].Id,
                                                        Payment_Terms__c = 'Net 30', MRR_Sub_Start__c = Date.today(), MRR_Sub_End__c = Date.today().addDays(180));
        testOpportunities.add(testOpportunity1); testOpportunities.add(testOpportunity2); testOpportunities.add(testOpportunity3);

        Test.startTest();     

        insert testOpportunities;

        // GET UPDATED OPPS AND TEST FOR CORRECT VALUES
        testOpportunities = [SELECT Id, ia_crm__Bill_to__c, ia_crm__Ship_to__c, ia_crm__Bill_to_Account__c, ia_crm__Intacct_Entity__c, ia_crm__Intacct_Location__c, ia_crm__Term__c, 
                                ia_crm__Start_Date__c, ia_crm__End_Date__c FROM Opportunity WHERE Id = :testOpportunities];
        // CHECK FIELDS ON DIRECT OPP
        System.assert(testOpportunities[0].ia_crm__Bill_to__c == testAccount.BillingContact__c);
        System.assert(testOpportunities[0].ia_crm__Ship_to__c == testAccount.BillingContact__c);
        System.assert(testOpportunities[0].ia_crm__Bill_to_Account__c == testBillingAccount[0].Id);
        System.assert(testOpportunities[0].ia_crm__Intacct_Entity__c == intacctEntities[0].Id);
        System.assert(testOpportunities[0].ia_crm__Intacct_Location__c == intacctEntities[0].Id);
        System.assert(testOpportunities[0].ia_crm__Term__c == intacctTerms[0].Id);
        System.assert(testOpportunities[0].ia_crm__Start_Date__c == Date.today());
        System.assert(testOpportunities[0].ia_crm__End_Date__c == Date.today().addDays(180));
        // CHECK FIELDS ON INDIRECT OPP
        System.assert(testOpportunities[1].ia_crm__Bill_to__c == testBillingAccount[0].BillingContact__c);
        System.assert(testOpportunities[1].ia_crm__Ship_to__c == testBillingAccount[0].BillingContact__c);
        System.assert(testOpportunities[1].ia_crm__Bill_to_Account__c == testBillingAccount[0].Id);
        System.assert(testOpportunities[1].ia_crm__Intacct_Entity__c == intacctEntities[1].Id);
        System.assert(testOpportunities[1].ia_crm__Intacct_Location__c == intacctEntities[1].Id);
        System.assert(testOpportunities[1].ia_crm__Term__c == intacctTerms[1].Id);
        System.assert(testOpportunities[1].ia_crm__Start_Date__c == Date.today());
        System.assert(testOpportunities[1].ia_crm__End_Date__c == Date.today().addDays(180));
        // CHECK FIELDS ON CLOSED WON OPP
        System.assert(testOpportunities[2].ia_crm__Bill_to__c == null);
        System.assert(testOpportunities[2].ia_crm__Ship_to__c == null);
        System.assert(testOpportunities[2].ia_crm__Bill_to_Account__c == null);
        System.assert(testOpportunities[2].ia_crm__Intacct_Entity__c == null);
        System.assert(testOpportunities[2].ia_crm__Intacct_Location__c == null);
        System.assert(testOpportunities[2].ia_crm__Term__c == null);
        System.assert(testOpportunities[2].ia_crm__Start_Date__c == null);
        System.assert(testOpportunities[2].ia_crm__End_Date__c == null);

        Test.stopTest();
    }

    /**
    * @description processOpportunityAfterChangesTest - Test happy path of code for Opportunity After Insert/Update field syncing
    */
    public static testmethod void processOpportunityAfterChangesTest() {
        // TURN OFF ACCOUNT OWNERSHIP CHANGE VALIDATION
        TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);

        // GET RECORD TYPES
        Map<String, Map<String, Id>> recordTypes = UtilityClass.getRecordTypesForObjects(new List<String>{ 'Opportunity', 'Contract'});
        System.assert(!recordTypes.isEmpty());
        System.assert(recordTypes.containsKey('Opportunity'));
        System.assert(recordTypes.containsKey('Contract'));   

        // GET TEST USERS
        List<User> testUsers = [SELECT Id FROM User WHERE Alias IN ('tuser1','tuser2')];
        System.assert(testUsers.size() == 2);

        // GET TEST INTACCT DEPARTMENT       
        List<ia_crm__Department__c> intacctDepartments = [SELECT Id, Name, ia_crm__Department_ID__c FROM ia_crm__Department__c];
        System.assert(intacctDepartments.size() == 2);

        // GET TEST INTACCT ENTITIES
        List<ia_crm__Intacct_Entity__c> intacctEntities = [SELECT Id, ia_crm__Intacct_Entity_ID__c FROM ia_crm__Intacct_Entity__c];
        System.assert(intacctEntities.size() == 2);
        
        // GET TEST PRICEBOOK ENTRY
        List<PricebookEntry> testEntry = [SELECT Id FROM PricebookEntry WHERE ProductCode = 'testProd'];
        System.assert(testEntry.size() == 1);  

        // GET TEST BILLING ACCOUNT, USES BILLING CONTACT 2
        List<Account> testBillingAccount = [SELECT Id, BillingContact__c FROM Account WHERE Name = 'Test Billing Account'];
        System.assert(testBillingAccount.size() == 1);

        // GET TEST BILLING CONTACTS
        List<Contact> testBillingContacts = [SELECT Id FROM Contact WHERE AccountId IN :testBillingAccount];
        System.assert(testBillingContacts.size() == 2);

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account', BillingContact__c = testBillingContacts[0].Id);
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        Opportunity testOpportunity1 = new Opportunity(Name = 'Direct Opp', AccountId = testAccount.Id, Type = 'New Business', RecordTypeId = recordTypes.get('Opportunity').get('Direct'), 
                                                        StageName = 'Qualify', CloseDate = Date.today().addDays(15), Entity_Code__c = 'Conga', Billing_Party__c = testBillingAccount[0].Id,
                                                        Payment_Terms__c = 'Net 30', MRR_Sub_Start__c = Date.today(), MRR_Sub_End__c = Date.today().addDays(180), OwnerId = testUsers[0].Id);

        Opportunity testOpportunity2 = new Opportunity(Name = 'Indirect Opp', AccountId = testAccount.Id, Type = 'New Business', RecordTypeId = recordTypes.get('Opportunity').get('Indirect'),
                                                        StageName = 'Qualify', CloseDate = Date.today(), Entity_Code__c = 'Octiv', Billing_Party__c = testBillingAccount[0].Id,
                                                        Payment_Terms__c = 'Net 30', MRR_Sub_Start__c = Date.today(), MRR_Sub_End__c = Date.today().addDays(180), OwnerId = testUsers[1].Id);
        insert new List<Opportunity>{ testOpportunity1, testOpportunity2 };

        // CREATE TEST CONTRACT 1
        List<Contract> testContracts = new List<Contract>();        
        Contract testContract1 = new Contract(Name = 'Test Contract 1', RecordTypeId = recordTypes.get('Contract').get('Customer_Subscription'), AccountId = testAccount.Id, Contract_Type__c = 'Customer Subscription',
                                                StartDate = Date.today().addDays(15), ContractTerm = 24, SBQQ__Opportunity__c = testOpportunity1.Id, Payment_Terms_non_Net_30__c = 'Net 30');
        // CREATE TEST CONTRACT 2
        Contract testContract2 = new Contract(Name = 'Test Contract 2', RecordTypeId = recordTypes.get('Contract').get('Customer_Subscription'), AccountId = testAccount.Id, Contract_Type__c = 'Customer Subscription',
                                                StartDate = Date.today().addDays(15), ContractTerm = 24, SBQQ__Opportunity__c = testOpportunity2.Id, Payment_Terms_non_Net_30__c = 'Net 60');
        testContracts.add(testContract1); testContracts.add(testContract2);
        insert testContracts;

        // SET CONTRACTS ON TEST OPPS
        testOpportunity1.ContractId = testContract1.Id;
        testOpportunity2.ContractId = testContract2.Id;
        update new List<Opportunity>{ testOpportunity1, testOpportunity2 };

        Test.startTest();

        // CREATE TEST OPP LINE ITEMS
        List<OpportunityLineItem> testOppItems = TestingUtility.createSObjectList('OpportunityLineItem', false, 4); 
        for(OpportunityLineItem oppItem : testOppItems){    
            oppItem.PricebookEntryId = testEntry[0].Id;
            oppItem.Quantity = 1;
            oppItem.UnitPrice = 50.00;
        }
        testOppItems[0].OpportunityId = testOpportunity1.Id;
        testOppItems[1].OpportunityId = testOpportunity1.Id;
        testOppItems[2].OpportunityId = testOpportunity2.Id;
        testOppItems[3].OpportunityId = testOpportunity2.Id;
        insert testOppItems;

        // UPDATE ACCOUNT TO TRIGGER BILL TO SHIP TO UPDATES
        testAccount.BillingContact__c = testBillingContacts[1].Id;
        testAccount.OwnerId = testUsers[1].Id;
        update testAccount;

        // MAKE UPDATES TO OPPS THAT WILL TRIGGER CONTRACT AND OPP LINE ITEM UPDATES
        testOpportunity1.Entity_Code__c = 'Octiv';
        testOpportunity1.Accounting_Approved__c = true;
        testOpportunity1.Additional_Provisions__c = 'Test Text';
        testOpportunity2.Entity_Code__c = 'Conga';
        testOpportunity2.Accounting_Approved__c = true;
        testOpportunity2.Additional_Provisions__c = 'Test Text 2';
        update new List<Opportunity>{ testOpportunity1, testOpportunity2 };

        // CLOSE TEST OPP 2
        testOpportunity2.StageName = 'Closed Won';
        update testOpportunity2;

        // GET UPDATED CONTRACTS AND TEST FOR CORRECT VALUES
        testContracts = [SELECT Id, ia_crm__Bill_to__c, ia_crm__Ship_to__c, ia_crm__Intacct_Entity__c, ia_crm__Sync_With_Intacct__c, Entity_Code__c, Additional_Provisions__c
                         FROM Contract WHERE Id = :testContracts];
        System.assert(testContracts[0].ia_crm__Bill_to__c == testAccount.BillingContact__c);
        System.assert(testContracts[0].ia_crm__Ship_to__c == testAccount.BillingContact__c);
        System.assert(testContracts[0].ia_crm__Intacct_Entity__c == intacctEntities[1].Id);
        System.assert(testContracts[0].ia_crm__Sync_With_Intacct__c == true);
        System.assert(testContracts[0].Entity_Code__c == testOpportunity1.Entity_Code__c);
        System.assert(testContracts[0].Additional_Provisions__c == 'Test Text');

        System.assert(testContracts[1].ia_crm__Bill_to__c == testBillingAccount[0].BillingContact__c); // INDIRECT OPP GETS ITS BILL TO/SHIP TO FROM THE BILLING PARTY
        System.assert(testContracts[1].ia_crm__Ship_to__c == testBillingAccount[0].BillingContact__c); // INDIRECT OPP GETS ITS BILL TO/SHIP TO FROM THE BILLING PARTY
        System.assert(testContracts[1].ia_crm__Sync_With_Intacct__c == true);
        System.assert(testContracts[1].Entity_Code__c == testOpportunity2.Entity_Code__c);
        System.assert(testContracts[1].Additional_Provisions__c == 'Test Text 2');

        // GET UPDATED OPP ITEMS AND TEST FOR CORRECT VALUES
        testOppItems = [SELECT Id, ia_crm__Intacct_Entity__c, ia_crm__Intacct_Location__c, ia_crm__Department__c, ia_crm__Ship_to_Contact__c FROM OpportunityLineItem WHERE Id = :testOppItems];
        System.assert(testOppItems[0].ia_crm__Ship_to_Contact__c != testBillingAccount[0].BillingContact__c); // DOES NOT MATCH BECAUSE OPP WAS NOT CLOSED WON
        System.assert(testOppItems[0].ia_crm__Intacct_Entity__c != intacctEntities[1].Id); // DOES NOT MATCH BECAUSE OPP WAS NOT CLOSED WON
        System.assert(testOppItems[0].ia_crm__Intacct_Location__c != intacctEntities[1].Id); // DOES NOT MATCH BECAUSE OPP WAS NOT CLOSED WON
        System.assert(testOppItems[0].ia_crm__Department__c != intacctDepartments[1].Id); // DOES NOT MATCH BECAUSE OPP WAS NOT CLOSED WON

        System.assert(testOppItems[1].ia_crm__Ship_to_Contact__c != testBillingAccount[0].BillingContact__c); // DOES NOT MATCH BECAUSE OPP WAS NOT CLOSED WON
        System.assert(testOppItems[1].ia_crm__Intacct_Entity__c != intacctEntities[1].Id); // DOES NOT MATCH BECAUSE OPP WAS NOT CLOSED WON
        System.assert(testOppItems[1].ia_crm__Intacct_Location__c != intacctEntities[1].Id); // DOES NOT MATCH BECAUSE OPP WAS NOT CLOSED WON
        System.assert(testOppItems[1].ia_crm__Department__c != intacctDepartments[1].Id); // DOES NOT MATCH BECAUSE OPP WAS NOT CLOSED WON

        System.assert(testOppItems[2].ia_crm__Ship_to_Contact__c == testAccount.BillingContact__c);
        System.assert(testOppItems[2].ia_crm__Intacct_Entity__c == intacctEntities[0].Id);
        System.assert(testOppItems[2].ia_crm__Intacct_Location__c == intacctEntities[0].Id); 
        System.assert(testOppItems[2].ia_crm__Department__c == intacctDepartments[1].Id);

        System.assert(testOppItems[3].ia_crm__Ship_to_Contact__c == testAccount.BillingContact__c);
        System.assert(testOppItems[3].ia_crm__Intacct_Entity__c == intacctEntities[0].Id);
        System.assert(testOppItems[3].ia_crm__Intacct_Location__c == intacctEntities[0].Id);
        System.assert(testOppItems[3].ia_crm__Department__c == intacctDepartments[1].Id);

        Test.stopTest();
    }

    /**
    * @description processOpportunityFieldChangesTest_Exceptions - Test bad data and error handling for Opportunity Field syncing
    */
    public static testmethod void processOpportunityFieldChangesTest_Exceptions() {
        Test.startTest();

        // TRY EXECUTING METHOD WITH NULL PARAMETERS
        IntacctFieldSyncHelper.processOpportunityBeforeChanges(null, null);
        IntacctFieldSyncHelper.processOpportunityAfterChanges(null, null);
        
        // TRY EXECUTING METHOD WITH EMPTY PARAMETERS
        IntacctFieldSyncHelper.processOpportunityBeforeChanges(new List<Opportunity>(), new Map<Id, Opportunity>());
        IntacctFieldSyncHelper.processOpportunityAfterChanges(new List<Opportunity>(), new Map<Id, Opportunity>());

        Test.stopTest();
    }

    /**
    * @description processOppItemBeforeChangesTest - Test happy path of code for OpportunityLineItem Before Insert/Update field syncing
    */
    public static testmethod void processOppItemBeforeChangesTest() {
        // TURN OFF ACCOUNT OWNERSHIP CHANGE VALIDATION
        TriggerHelper.TemporaryOverride('AccountHelper','validateOwnershipChanges', false);

        // GET RECORD TYPES
        Map<String, Id> oppRecordTypes = UtilityClass.getRecordTypesForObject('Opportunity');

        // GET TEST PRICEBOOK ENTRY
        List<PricebookEntry> testEntry = [SELECT Id FROM PricebookEntry WHERE ProductCode = 'testProd'];
        System.assert(testEntry.size() == 1);       

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        Opportunity testOpportunity = new Opportunity(Name = 'Direct Opp', AccountId = testAccount.Id, Type = 'New Business',
                                                      RecordTypeId = oppRecordTypes.get('Direct'), StageName = 'Qualify', CloseDate = Date.today().addDays(15));
        insert testOpportunity;

        // CREATE TEST OPP LINE ITEMS
        List<OpportunityLineItem> testOppItems = TestingUtility.createSObjectList('OpportunityLineItem', false, 2); 
        for(OpportunityLineItem oppItem : testOppItems){    
            oppItem.OpportunityId = testOpportunity.Id;          
            oppItem.PricebookEntryId = testEntry[0].Id;
            oppItem.Quantity = 1;
            oppItem.UnitPrice = 50.00;
        }
        testOppItems[0].ServiceDate = Date.today();
        testOppItems[0].Product_End_Date__c = testOppItems[0].ServiceDate.addDays(365);
        testOppItems[1].ServiceDate = Date.today();
        testOppItems[1].Product_End_Date__c = testOppItems[1].ServiceDate.addDays(180);

        Test.startTest();

        // SAVE AND REFRESH LIST
        insert testOppItems;
        testOppItems = [SELECT Id, ServiceDate, Product_End_Date__c, ia_crm__Start_Date__c, ia_crm__End_Date__c, ia_crm__Billing_Start_Date__c, ia_crm__Billing_End_Date__c, 
                               ia_crm__Service_End_Date__c, ia_crm__Contract_Line_Save_Cancel_He__c, ia_crm__Billing_Method__c, ia_crm__Billing_Template__c, 
                               Product2.ia_crm__Flat_fixed_amount_frequency__c, Product2.ia_crm__Billing_method__c, Product2.ia_crm__Billing_Template__c
                        FROM OpportunityLineItem WHERE Id IN :testOppItems];
        // ITEM 1
        System.assert(testOppItems[0].ia_crm__Start_Date__c == testOppItems[0].ServiceDate);
        System.assert(testOppItems[0].ia_crm__End_Date__c == testOppItems[0].Product_End_Date__c);
        System.assert(testOppItems[0].ia_crm__Billing_Start_Date__c == testOppItems[0].ServiceDate);
        System.assert(testOppItems[0].ia_crm__Billing_End_Date__c == testOppItems[0].Product_End_Date__c);
        System.assert(testOppItems[0].ia_crm__Service_End_Date__c == testOppItems[0].Product_End_Date__c);
        System.assert(testOppItems[0].ia_crm__Contract_Line_Save_Cancel_He__c == testOppItems[0].Product2.ia_crm__Flat_fixed_amount_frequency__c);
        System.assert(testOppItems[0].ia_crm__Billing_Method__c == testOppItems[0].Product2.ia_crm__Billing_method__c);
        System.assert(testOppItems[0].ia_crm__Billing_Template__c == testOppItems[0].Product2.ia_crm__Billing_Template__c);

        // ITEM 2
        System.assert(testOppItems[1].ia_crm__Start_Date__c == testOppItems[1].ServiceDate);
        System.assert(testOppItems[1].ia_crm__End_Date__c == testOppItems[1].Product_End_Date__c);
        System.assert(testOppItems[1].ia_crm__Billing_Start_Date__c == testOppItems[1].ServiceDate);
        System.assert(testOppItems[1].ia_crm__Billing_End_Date__c == testOppItems[1].Product_End_Date__c);
        System.assert(testOppItems[1].ia_crm__Service_End_Date__c == testOppItems[1].Product_End_Date__c); 
        System.assert(testOppItems[1].ia_crm__Contract_Line_Save_Cancel_He__c == testOppItems[1].Product2.ia_crm__Flat_fixed_amount_frequency__c);
        System.assert(testOppItems[1].ia_crm__Billing_Method__c == testOppItems[1].Product2.ia_crm__Billing_method__c);
        System.assert(testOppItems[1].ia_crm__Billing_Template__c == testOppItems[1].Product2.ia_crm__Billing_Template__c);

        // MAKE UPDATES TO FIELDS AND SAVE
        testOppItems[0].ServiceDate = Date.today().addDays(30);
        testOppItems[0].Product_End_Date__c = testOppItems[0].ServiceDate.addDays(365);
        testOppItems[1].ServiceDate = Date.today().addDays(15);
        testOppItems[1].Product_End_Date__c = testOppItems[1].ServiceDate.addDays(180);
        update testOppItems;

        // REFRESH LIST
        testOppItems = [SELECT Id, ServiceDate, Product_End_Date__c, ia_crm__Start_Date__c, ia_crm__End_Date__c, ia_crm__Billing_Start_Date__c, ia_crm__Billing_End_Date__c, 
                        ia_crm__Service_End_Date__c FROM OpportunityLineItem WHERE Id IN :testOppItems];
        // ITEM 1
        System.assert(testOppItems[0].ia_crm__Start_Date__c == testOppItems[0].ServiceDate);
        System.assert(testOppItems[0].ia_crm__End_Date__c == testOppItems[0].Product_End_Date__c);
        System.assert(testOppItems[0].ia_crm__Billing_Start_Date__c == testOppItems[0].ServiceDate);
        System.assert(testOppItems[0].ia_crm__Billing_End_Date__c == testOppItems[0].Product_End_Date__c);
        System.assert(testOppItems[0].ia_crm__Service_End_Date__c == testOppItems[0].Product_End_Date__c);
        // ITEM 2
        System.assert(testOppItems[1].ia_crm__Start_Date__c == testOppItems[1].ServiceDate);
        System.assert(testOppItems[1].ia_crm__End_Date__c == testOppItems[1].Product_End_Date__c);
        System.assert(testOppItems[1].ia_crm__Billing_Start_Date__c == testOppItems[1].ServiceDate);
        System.assert(testOppItems[1].ia_crm__Billing_End_Date__c == testOppItems[1].Product_End_Date__c);
        System.assert(testOppItems[1].ia_crm__Service_End_Date__c == testOppItems[1].Product_End_Date__c);                 

        Test.stopTest();
    }

    /**
    * @description processOpportunityLineItemFieldChangesTest_Exceptions - Test bad data and error handling for OpportunityLineItem Field syncing
    */
    public static testmethod void processOppItemFieldChangesTest_Exceptions() {
        Test.startTest();

        // TRY EXECUTING METHOD WITH NULL PARAMETERS
        IntacctFieldSyncHelper.processOppItemBeforeChanges(null, null);
        
        // TRY EXECUTING METHOD WITH EMPTY PARAMETERS
        IntacctFieldSyncHelper.processOppItemBeforeChanges(new List<OpportunityLineItem>(), new Map<Id, OpportunityLineItem>());

        Test.stopTest();
    }

    /**
    * @description processIntacctSalesInvoiceFieldChangesTest_BeforeInsertUpdate - Test happy path of code for ia_crm__Sales_Invoice__c Before Insert/Update field syncing
    */
    public static testmethod void processSalesInvoiceBeforeChangesTest() {
        // GET RECORD TYPES
        Map<String, Id> oppRecordTypes = UtilityClass.getRecordTypesForObject('Opportunity');

        // GET TEST PRICEBOOK ENTRY
        List<PricebookEntry> testEntry = [SELECT Id FROM PricebookEntry WHERE ProductCode = 'testProd'];
        System.assert(testEntry.size() == 1);       

        // GET TEST BILLING ACCOUNT, USES BILLING CONTACT 2
        List<Account> testBillingAccount = [SELECT Id, BillingContact__c FROM Account WHERE Name = 'Test Billing Account'];
        System.assert(testBillingAccount.size() == 1);

        // CREATE TEST ACCOUNT
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // CREATE TEST INTACCT CONTRACT
        ia_crm__Intacct_Contract__c testIntacctContract = new ia_crm__Intacct_Contract__c(Name = 'Test Intacct Contract');
        insert testIntacctContract;

        // CREATE TEST CONTRACT
        List<Contract> testContracts = TestingUtility.createSObjectList('Contract', false, 2);
        testContracts[0].AccountId = testAccount.Id;
        testContracts[0].ia_crm__Intacct_Contract__c = testIntacctContract.Id;
        testContracts[1].AccountId = testAccount.Id;
        testContracts[1].ia_crm__Intacct_Contract__c = testIntacctContract.Id;
        insert testContracts;

        // CREATE TEST OPPORTUNITIES
        List<Opportunity> testOpportunities = TestingUtility.createSObjectList('Opportunity', false, 2);
        for(Opportunity testOpp : testOpportunities){
            testOpp.AccountId = testAccount.Id;
            testOpp.Entity_Code__c = 'Conga';
            testOpp.Billing_Party__c = testBillingAccount[0].Id;
            testOpp.StageName = 'Closed Won';
            testOpp.CloseDate = Date.today().addDays(15);
            testOpp.AdditionalInvoiceRecipients__c = 'testopp@mailinator.com';
        }
        testOpportunities[0].Name = 'Direct Opp';
        testOpportunities[0].Type = 'New Business';
        testOpportunities[0].RecordTypeId = oppRecordTypes.get('Direct');
        testOpportunities[0].ContractId = testContracts[0].Id;
        testOpportunities[1].Name = 'Indirect Opp';
        testOpportunities[1].Type = 'Existing Business';
        testOpportunities[1].RecordTypeId = oppRecordTypes.get('Indirect');
        testOpportunities[1].ContractId = testContracts[1].Id;
        testOpportunities[1].Billing_Address_Override__c = 'Test Address Override';
        insert testOpportunities;

        // CREATE TEST INTACCT PROJECT
        ia_crm__Project__c testIntacctProject = new ia_crm__Project__c(ia_crm__Project_ID__c = 'Test');
        insert testIntacctProject;

        // CREATE TEST PS PROJECT
        PS_Project__c testPSProject = new PS_Project__c(OpportunityId__c = testOpportunities[0].Id, Intacct_Project_Id__c = 'Test', Billing_Additional_Emails__c = 'testproject@mailinator.com');
        insert testPSProject;

        // CREATE TEST INTACCT SALES INVOICES
        List<ia_crm__Sales_Invoice__c> testSalesInvoices = TestingUtility.createSObjectList('ia_crm__Sales_Invoice__c', false, 4); 
        for(ia_crm__Sales_Invoice__c testSalesInvoice : testSalesInvoices){
            testSalesInvoice.ia_crm__Account__c = testAccount.Id;
            testSalesInvoice.PS_Project__c = testPSProject.Id;
            testSalesInvoice.Order_Type__c = '';
        }
        testSalesInvoices[0].ia_crm__Opportunity__c = testOpportunities[0].Id;
        testSalesInvoices[0].ia_crm__Document_Type__c = 'Contract Invoice';
        testSalesInvoices[0].Opportunity_Type__c = testOpportunities[0].Type;

        testSalesInvoices[1].ia_crm__Opportunity__c = testOpportunities[0].Id;
        testSalesInvoices[1].ia_crm__Document_Type__c = 'Sales Invoice';
        testSalesInvoices[1].Opportunity_Type__c = testOpportunities[0].Type;

        testSalesInvoices[2].ia_crm__Opportunity__c = testOpportunities[1].Id;
        testSalesInvoices[2].ia_crm__Document_Type__c = 'Contract Invoice'; 
        testSalesInvoices[2].Opportunity_Type__c = testOpportunities[1].Type;
        
        testSalesInvoices[3].ia_crm__Opportunity__c = testOpportunities[1].Id;
        testSalesInvoices[3].ia_crm__Document_Type__c = 'Sales Invoice';
        testSalesInvoices[3].Opportunity_Type__c = testOpportunities[1].Type;

        // REFRESH TEST OPPS
        testOpportunities = [SELECT Type, ia_crm__Bill_to__c, ia_crm__Bill_to_Account__c, Contract.ia_crm__Intacct_Contract__c, Entity_Code__c, ContractId, AdditionalInvoiceRecipients__c,
                             Billing_Party__c, Billing_Party__r.BillingContact__c, Billing_Address_Override__c
                             FROM Opportunity WHERE Id IN :testOpportunities];

        Test.startTest();

        // SAVE RECORDS AND REFRESH LIST
        insert testSalesInvoices;
        testSalesInvoices = [SELECT Id, ia_crm__Opportunity__c, ia_crm__Opportunity__r.Type, Order_Type__c, Additional_Invoice_Recipients__c, ia_crm__Project__c, Bill_To__c, Bill_To_Account__c, Entity_Code__c, ia_crm__Contract__c,
                             Intacct_Contract__c, Billing_Address_Override__c FROM ia_crm__Sales_Invoice__c WHERE Id IN :testSalesInvoices];

        // TEST SALES INVOICE 1 FOR CORRECT DATA - DIRECT CONTRACT INVOICE
        System.assert(testSalesInvoices[0].Order_Type__c == testOpportunities[0].Type);
        System.assert(testSalesInvoices[0].Additional_Invoice_Recipients__c == testOpportunities[0].AdditionalInvoiceRecipients__c);
        System.assert(testSalesInvoices[0].ia_crm__Project__c == testIntacctProject.Id);
        System.assert(testSalesInvoices[0].Bill_To__c == testAccount.BillingContact__c);
        System.assert(testSalesInvoices[0].Bill_To_Account__c == null);
        System.assert(testSalesInvoices[0].Entity_Code__c == testOpportunities[0].Entity_Code__c);
        System.assert(testSalesInvoices[0].ia_crm__Contract__c == testOpportunities[0].ContractId);
        System.assert(testSalesInvoices[0].Intacct_Contract__c == testOpportunities[0].Contract.ia_crm__Intacct_Contract__c);
        // TEST SALES INVOICE 2 FOR CORRECT DATA - DIRECT SALES INVOICE
        System.assert(testSalesInvoices[1].Order_Type__c == 'Services');
        System.assert(testSalesInvoices[1].Additional_Invoice_Recipients__c == testPSProject.Billing_Additional_Emails__c);
        System.assert(testSalesInvoices[1].ia_crm__Project__c == testIntacctProject.Id);
        System.assert(testSalesInvoices[1].Bill_To__c == testAccount.BillingContact__c);
        System.assert(testSalesInvoices[1].Bill_To_Account__c == null);
        System.assert(testSalesInvoices[1].Entity_Code__c == testOpportunities[0].Entity_Code__c);
        System.assert(testSalesInvoices[1].ia_crm__Contract__c == testOpportunities[0].ContractId);
        System.assert(testSalesInvoices[1].Intacct_Contract__c == testOpportunities[0].Contract.ia_crm__Intacct_Contract__c);
        // TEST SALES INVOICE 3 FOR CORRECT DATA - INDIRECT CONTRACT INVOICE
        System.assert(testSalesInvoices[2].Order_Type__c == testOpportunities[1].Type);
        System.assert(testSalesInvoices[2].Additional_Invoice_Recipients__c == testOpportunities[1].AdditionalInvoiceRecipients__c);
        System.assert(testSalesInvoices[2].ia_crm__Project__c == testIntacctProject.Id);
        System.assert(testSalesInvoices[2].Bill_To__c == testOpportunities[1].Billing_Party__r.BillingContact__c);
        System.assert(testSalesInvoices[2].Bill_To_Account__c == testOpportunities[1].Billing_Party__c);
        System.assert(testSalesInvoices[2].Entity_Code__c == testOpportunities[1].Entity_Code__c);
        System.assert(testSalesInvoices[2].ia_crm__Contract__c == testOpportunities[1].ContractId);
        System.assert(testSalesInvoices[2].Intacct_Contract__c == testOpportunities[1].Contract.ia_crm__Intacct_Contract__c);
        System.assert(testSalesInvoices[2].Billing_Address_Override__c == testOpportunities[1].Billing_Address_Override__c);
        // TEST SALES INVOICE 4 FOR CORRECT DATA - INDIRECT SALES INVOICE
        System.assert(testSalesInvoices[3].Order_Type__c == 'Services');
        System.assert(testSalesInvoices[3].Additional_Invoice_Recipients__c == testPSProject.Billing_Additional_Emails__c);
        System.assert(testSalesInvoices[3].ia_crm__Project__c == testIntacctProject.Id);
        System.assert(testSalesInvoices[3].Bill_To__c == testOpportunities[1].Billing_Party__r.BillingContact__c);
        System.assert(testSalesInvoices[3].Bill_To_Account__c == testOpportunities[1].Billing_Party__c);
        System.assert(testSalesInvoices[3].Entity_Code__c == testOpportunities[1].Entity_Code__c);
        System.assert(testSalesInvoices[3].ia_crm__Contract__c == testOpportunities[1].ContractId);
        System.assert(testSalesInvoices[3].Intacct_Contract__c == testOpportunities[1].Contract.ia_crm__Intacct_Contract__c);
        System.assert(testSalesInvoices[3].Billing_Address_Override__c == testOpportunities[1].Billing_Address_Override__c);

        // CHANGE OPPORTUNITIES AND SAVE
        testSalesInvoices[0].ia_crm__Opportunity__c = testOpportunities[0].Id;
        testSalesInvoices[1].ia_crm__Opportunity__c = testOpportunities[1].Id;
        update testSalesInvoices;

        Test.stopTest();
    }

    /**
    * @description processSalesInvoiceFieldChangesTest_Exceptions - Test bad data and error handling for ia_crm__Sales_Invoice__c Field syncing
    */
    public static testmethod void processSalesInvoiceFieldChangesTest_Exceptions() {
        Test.startTest();

        // TRY EXECUTING METHOD WITH NULL PARAMETERS
        IntacctFieldSyncHelper.processSalesInvoiceBeforeChanges(null, null);
        
        // TRY EXECUTING METHOD WITH EMPTY PARAMETERS
        IntacctFieldSyncHelper.processSalesInvoiceBeforeChanges(new List<ia_crm__Sales_Invoice__c>(), new Map<Id, ia_crm__Sales_Invoice__c>());

        Test.stopTest();
    }


}