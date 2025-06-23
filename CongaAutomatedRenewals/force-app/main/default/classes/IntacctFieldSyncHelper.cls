/**
* @author Conga Services, ERedding
* @date 20181121
* @version 1.00
* @description IntacctFieldSyncHelper - Trigger helper methods for all SObjects involved in the SF => Intacct Integration
*/
public without sharing class IntacctFieldSyncHelper {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// STATIC VARIABLES //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // RECORD TYPES
    private static Map<String, Map<String, Id>> RecordTypes {
    get {
        if(RecordTypes == null){
            RecordTypes = UtilityClass.getRecordTypesForObjects(new List<String>{ 'Contract', 'Opportunity'});
        }
        return RecordTypes;
    } set; }

    // CONGA TERM VALUE TO INTACCT TERM RECORD MAPPINGS
    private static Map<String, Id> IntacctTermMappings {
    get {
        if(IntacctTermMappings == null){
            IntacctTermMappings = new Map<String, Id>();
            for(ia_crm__AR_Terms__c intacctTerm : [SELECT Id, Conga_Term__c FROM ia_crm__AR_Terms__c WHERE ia_crm__Status__c = true AND Conga_Term__c != null]){
                IntacctTermMappings.put(intacctTerm.Conga_Term__c, intacctTerm.Id);
            }
        }
        return IntacctTermMappings;
    } set; }

    // INTACCT EMPLOYEES BY EMPLOYEE INTACCT ID MAP
    private static Map<String, ia_crm__Employees__c> IntacctEmployeesByIntacctID {
    get {
        if(IntacctEmployeesByIntacctID == null){
            IntacctEmployeesByIntacctID = new Map<String, ia_crm__Employees__c>();
            for(ia_crm__Employees__c intacctEmployee : [SELECT Id, ia_crm__Employee_ID__c, ia_crm__Department__c FROM ia_crm__Employees__c]){
                IntacctEmployeesByIntacctID.put(intacctEmployee.ia_crm__Employee_ID__c, intacctEmployee);
            }
        }
        return IntacctEmployeesByIntacctID;
    } set; }

    // INTACCT EMPLOYEES BY ID MAP
    private static Map<String, ia_crm__Employees__c> IntacctEmployeesById {
    get {
        if(IntacctEmployeesById == null){
            IntacctEmployeesById = new Map<String, ia_crm__Employees__c> ();
            for(ia_crm__Employees__c intacctEmployee : IntacctEmployeesByIntacctID.values()){
                IntacctEmployeesById.put(intacctEmployee.Id, intacctEmployee);
            }
        }
        return IntacctEmployeesById;
    } set; }

    // INTACCT ENTITY BY NAME MAP
    private static Map<String, ia_crm__Intacct_Entity__c> IntacctEntitiesByEntityID {
    get {
        if(IntacctEntitiesByEntityID == null){
            IntacctEntitiesByEntityID = new Map<String, ia_crm__Intacct_Entity__c>();
            for(ia_crm__Intacct_Entity__c intacctEntity : [SELECT Id, Name, ia_crm__Intacct_Entity_ID__c FROM ia_crm__Intacct_Entity__c]){
                IntacctEntitiesByEntityID.put(intacctEntity.ia_crm__Intacct_Entity_ID__c, intacctEntity);
            }
        }
        return IntacctEntitiesByEntityID;
    } set; }

    // PRODUCT BY ID MAP
    private static Set<Id> ParentProductIds = new Set<Id>();
    private static Map<Id, Product2> ParentProductsById {
    get {
        if(ParentProductsById == null){
            ParentProductsById = new Map<Id, Product2>();
            for(Product2 product : [SELECT Id, ia_crm__Flat_fixed_amount_frequency__c, ia_crm__Billing_method__c, ia_crm__Billing_Template__c
                                    FROM Product2 WHERE Id IN :ParentProductIds]){
                ParentProductsById.put(product.Id, product);
            }
        }
        return ParentProductsById;
    } set; }

    // USER BY ID MAP
    private static Map<Id, User> UsersById {
    get {
        if(UsersById == null){
            UsersById = new Map<Id, User>([SELECT Id, Department, Intacct_Entity_Id__c, Intacct_Id__c FROM User WHERE Profile.UserLicense.Name = 'Salesforce' AND IsActive = true]);
        }
        return UsersById;
    } set; }



    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// STATIC METHODS ///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * @description processAccountFieldChanges - Helper method for handling Account Before trigger logic for Intacct Integration fields
    *                                            --- EXECUTED BY ACCOUNT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<Account> newOrUpdatedAccounts - New or updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void processAccountBeforeChanges(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processAccountBeforeChanges') && newOrUpdatedAccounts != null){
                for(Account newOrUpdatedAcct : newOrUpdatedAccounts){
                    Account outdatedAcct = outdatedAccounts != null && !outdatedAccounts.isEmpty() ? outdatedAccounts.get(newOrUpdatedAcct.Id) : null;

                    // BILLING CONTACT, NEW ACCOUNT OR FIELD IS CHANGED
                    if(outdatedAccounts == null || (outdatedAcct != null && newOrUpdatedAcct.BillingContact__c != outdatedAcct.BillingContact__c)){
                        newOrUpdatedAcct.ia_crm__Bill_to_Contact__c = newOrUpdatedAcct.BillingContact__c;
                        newOrUpdatedAcct.ia_crm__Ship_to_Contact__c = newOrUpdatedAcct.BillingContact__c;
                    }

                    // OWNER, NEW ACCOUNT OR FIELD IS CHANGED
                    if(outdatedAccounts == null || (outdatedAcct != null && newOrUpdatedAcct.OwnerId != outdatedAcct.OwnerId)){
                        if(UsersById.containsKey(newOrUpdatedAcct.OwnerId) && IntacctEmployeesByIntacctID.containsKey(UsersById.get(newOrUpdatedAcct.OwnerId).Intacct_Id__c)){
                            newOrUpdatedAcct.ia_crm__Sales_rep__c = UsersById.get(newOrUpdatedAcct.OwnerId).Intacct_Id__c;
                            newOrUpdatedAcct.ia_crm__SalesRep__c = IntacctEmployeesByIntacctID.get(UsersById.get(newOrUpdatedAcct.OwnerId).Intacct_Id__c).Id;
                        }
                    }  
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processAccountBeforeChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processAccountBeforeChanges', newOrUpdatedAccounts, ex, true);
        }
    }

   /**
    * @description processAccountAfterChanges - Helper method for handling Account After trigger logic for Intacct Integration fields
    *                                            --- EXECUTED BY ACCOUNT AFTER INSERT AND AFTER UPDATE TRIGGERS ---
    * @param List<Account> newOrUpdatedAccounts - New or updated Account records
    * @param Map<Id, Account> outdatedAccounts - Outdated Account records
    * @return void
    */
    public static void processAccountAfterChanges(List<Account> newOrUpdatedAccounts, Map<Id, Account> outdatedAccounts) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processAccountAfterChanges') && newOrUpdatedAccounts != null){

                // CHECK ACCOUNT FOR CHANGES THAT REQUIRE CHILD CONTACT, OPP, OR OPP ITEM UPDATES
                Set<Id> accountsForOppUpdate = new Set<Id>();
                Set<Id> accountsForOppItemUpdate = new Set<Id>();
                Set<Id> accountsForContactUpdate = new Set<Id>();
                for(Account newOrUpdatedAcct : newOrUpdatedAccounts){
                    Account outdatedAcct = outdatedAccounts != null && !outdatedAccounts.isEmpty() ? outdatedAccounts.get(newOrUpdatedAcct.Id) : null;

                    if(outdatedAcct != null && (newOrUpdatedAcct.BillingStreet != outdatedAcct.BillingStreet || newOrUpdatedAcct.BillingCity != outdatedAcct.BillingCity ||
                                                newOrUpdatedAcct.BillingState != outdatedAcct.BillingState || newOrUpdatedAcct.BillingPostalCode != outdatedAcct.BillingPostalCode ||
                                                newOrUpdatedAcct.BillingCountry != outdatedAcct.BillingCountry)){
                        accountsForContactUpdate.add(newOrUpdatedAcct.Id);
                    }

                    if(outdatedAcct != null && (newOrUpdatedAcct.ia_crm__Bill_to_Contact__c != outdatedAcct.ia_crm__Bill_to_Contact__c || 
                                                newOrUpdatedAcct.ia_crm__Ship_to_Contact__c != outdatedAcct.ia_crm__Ship_to_Contact__c)){
                        accountsForOppUpdate.add(newOrUpdatedAcct.Id);
                    }

                    if(outdatedAcct != null && newOrUpdatedAcct.ia_crm__SalesRep__c != outdatedAcct.ia_crm__SalesRep__c){
                        accountsForOppUpdate.add(newOrUpdatedAcct.Id);
                        accountsForOppItemUpdate.add(newOrUpdatedAcct.Id);
                    }
                }

                // POPULATE MAP OF CHILD CONTACTS
                Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
                if(!accountsForContactUpdate.isEmpty()){
                    for(Contact contact : [SELECT Id, AccountId, ia_crm__Sync_With_Intacct__c FROM Contact 
                                           WHERE AccountId IN :accountsForContactUpdate AND ia_crm__Intacct_Contact_ID__c != null]){
                        if(!contactsByAccountId.containsKey(contact.AccountId)){
                            contactsByAccountId.put(contact.AccountId, new List<Contact>());
                        }
                        contactsByAccountId.get(contact.AccountId).add(contact);
                    }
                }

                // POPULATE MAP OF CHILD OPPS
                Map<Id, Set<Opportunity>> oppsByAccountId = new Map<Id, Set<Opportunity>>();
                if(!accountsForOppUpdate.isEmpty()){
                    for(Opportunity opp : [SELECT Id, AccountId, ia_crm__Bill_to__c, ia_crm__Ship_to__c, Billing_Party__c, RecordTypeId FROM Opportunity 
                                           WHERE IsClosed = false AND (AccountId IN :accountsForOppUpdate OR Billing_Party__c IN :accountsForOppUpdate)]){

                        if(!oppsByAccountId.containsKey(opp.AccountId)){
                            oppsByAccountId.put(opp.AccountId, new Set<Opportunity>());
                        }
                        oppsByAccountId.get(opp.AccountId).add(opp);

                        if(!oppsByAccountId.containsKey(opp.Billing_Party__c)){
                            oppsByAccountId.put(opp.Billing_Party__c, new Set<Opportunity>());
                        }
                        oppsByAccountId.get(opp.Billing_Party__c).add(opp);
                    }
                }

                // POPULATE MAP OF CHILD OPP ITEMS
                Map<Id, List<OpportunityLineItem>> oppItemsByAccountId = new Map<Id, List<OpportunityLineItem>>();
                if(!accountsForOppItemUpdate.isEmpty()){
                    for(OpportunityLineItem oppItem : [SELECT Id, Opportunity.AccountId FROM OpportunityLineItem 
                                                       WHERE Opportunity.AccountId IN :accountsForOppItemUpdate AND Opportunity.IsClosed = false]){
                        if(!oppItemsByAccountId.containsKey(oppItem.Opportunity.AccountId)){
                            oppItemsByAccountId.put(oppItem.Opportunity.AccountId, new List<OpportunityLineItem>());
                        }
                        oppItemsByAccountId.get(oppItem.Opportunity.AccountId).add(oppItem);
                    }
                }

                // PROCESS CHANGES
                List<Contact> contactsToUpdate = new List<Contact>();
                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                List<OpportunityLineItem> oppItemsToUpdate = new List<OpportunityLineItem>();
                for(Account newOrUpdatedAcct : newOrUpdatedAccounts){
                    Account outdatedAcct = outdatedAccounts != null && !outdatedAccounts.isEmpty() ? outdatedAccounts.get(newOrUpdatedAcct.Id) : null;
                    if(outdatedAcct != null){

                        // UPDATE CONTACTS
                        if(contactsByAccountId.containsKey(newOrUpdatedAcct.Id)){
                            for(Contact contact : contactsByAccountId.get(newOrUpdatedAcct.Id)){
                                contact.ia_crm__Sync_With_Intacct__c = true;
                                contactsToUpdate.add(contact);
                            }
                        }

                        // UPDATE OPPORTUNITIES
                        if(oppsByAccountId.containsKey(newOrUpdatedAcct.Id)){
                            for(Opportunity opp : oppsByAccountId.get(newOrUpdatedAcct.Id)){
                                Boolean changeMade = false;

                                // INTACCT BILL TO CONTACT
                                if(newOrUpdatedAcct.ia_crm__Bill_to_Contact__c != outdatedAcct.ia_crm__Bill_to_Contact__c){
                                    if((opp.RecordTypeId == RecordTypes.get('Opportunity').get('Direct') && opp.AccountId == newOrUpdatedAcct.Id) || 
                                       (opp.RecordTypeId == RecordTypes.get('Opportunity').get('Indirect') && opp.Billing_Party__c == newOrUpdatedAcct.Id)){
                                        opp.ia_crm__Bill_to__c = newOrUpdatedAcct.ia_crm__Bill_to_Contact__c;
                                        changeMade = true;
                                    }
                                }

                                // INTACCT SHIP TO CONTACT
                                if(newOrUpdatedAcct.ia_crm__Ship_to_Contact__c != outdatedAcct.ia_crm__Ship_to_Contact__c){
                                    if((opp.RecordTypeId == RecordTypes.get('Opportunity').get('Direct') && opp.AccountId == newOrUpdatedAcct.Id) || 
                                       (opp.RecordTypeId == RecordTypes.get('Opportunity').get('Indirect') && opp.Billing_Party__c == newOrUpdatedAcct.Id)){
                                        opp.ia_crm__Ship_to__c = newOrUpdatedAcct.ia_crm__Ship_to_Contact__c;
                                        changeMade = true;
                                    }
                                }

                                // INTACCT SALES REP
                                if(newOrUpdatedAcct.ia_crm__SalesRep__c != outdatedAcct.ia_crm__SalesRep__c && IntacctEmployeesById.containsKey(newOrUpdatedAcct.ia_crm__SalesRep__c)){
                                    opp.ia_crm__Department__c = IntacctEmployeesById.get(newOrUpdatedAcct.ia_crm__SalesRep__c).ia_crm__Department__c;
                                    changeMade = true;
                                }

                                // QUEUE OPP FOR UPDATE IF CHANGES WERE MADE
                                if(changeMade){
                                    oppsToUpdate.add(opp);
                                }
                            }
                        }

                        // UPDATE OPPORTUNITY LINE ITEMS
                        if(oppItemsByAccountId.containsKey(newOrUpdatedAcct.Id)){
                            for(OpportunityLineItem oppItem : oppItemsByAccountId.get(newOrUpdatedAcct.Id)){
                                Boolean changeMade = false;

                                // INTACCT SALES REP
                                if(newOrUpdatedAcct.ia_crm__SalesRep__c != outdatedAcct.ia_crm__SalesRep__c){
                                    oppItem.ia_crm__Employee__c = newOrUpdatedAcct.ia_crm__SalesRep__c;
                                    changeMade = true;
                                }

                                // QUEUE OPP ITEM FOR UPDATE IF CHANGES WERE MADE
                                if(changeMade){
                                    oppItemsToUpdate.add(oppItem);
                                }
                            }
                        }
                    }
                }

                // SAVE UPDATED CONTACTS
                if(!contactsToUpdate.isEmpty()){
                    Database.saveResult[] contactResults = Database.update(contactsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(contactResults, 'IntacctFieldSyncHelper', 'processAccountAfterChanges', false);
                }

                // SAVE UPDATED OPPORTUNITIES
                if(!oppsToUpdate.isEmpty()){
                    Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'IntacctFieldSyncHelper', 'processAccountAfterChanges', false);
                }

                // SAVE UPDATED OPPORTUNITY ITEMS
                if(!oppItemsToUpdate.isEmpty()){
                    Database.saveResult[] oppItemsResults = Database.update(oppItemsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppItemsResults, 'IntacctFieldSyncHelper', 'processAccountAfterChanges', false);
                }

                // SAVE ANY LOGGED ERRORS
                SystemIssueLogHelper.UpsertExceptions();

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processAccountAfterChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processAccountAfterChanges', newOrUpdatedAccounts, ex, true);
        }
    }

    /**
    * @description processContactBeforeChanges - Helper method for handling Contact Before trigger logic for Intacct Integration fields
    *                                            --- EXECUTED BY CONTACT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<Contact> newOrUpdatedContacts - New or updated Contact records
    * @param Map<Id, Contact> outdatedContacts - Outdated Contact records
    * @return void
    */
    public static void processContactBeforeChanges(List<Contact> newOrUpdatedContacts, Map<Id, Contact> outdatedContacts) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processContactBeforeChanges') && newOrUpdatedContacts != null && !newOrUpdatedContacts.isEmpty()){

                // GET PARENT ACCOUNT IDS FROM NEW CONTACTS
                Set<Id> parentAccountIds = new Set<Id>();
                for(Contact newOrUpdatedCont : newOrUpdatedContacts){
                    Contact outdatedCont = outdatedContacts != null ? outdatedContacts.get(newOrUpdatedCont.Id) : null;
                    if(outdatedCont == null){
                        parentAccountIds.add(newOrUpdatedCont.AccountId);
                    }
                }

                // GET PARENT ACCOUNTS
                Map<Id, Account> parentAccounts = new Map<Id, Account>();
                if(!parentAccountIds.isEmpty()){
                    parentAccounts = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :parentAccountIds]);
                }

                // PROCESS CHANGES
                for(Contact newOrUpdatedCont : newOrUpdatedContacts){
                    Contact outdatedCont = outdatedContacts != null ? outdatedContacts.get(newOrUpdatedCont.Id) : null;

                    // BEFORE INSERT, POPULATE ia_crm__Intacct_Contact_ID__c
                    if(outdatedCont == null && parentAccounts.containsKey(newOrUpdatedCont.AccountId)){
                        String fullname = (UtilityClass.replaceNull(newOrUpdatedCont.FirstName, '') + ' ' + newOrUpdatedCont.LastName + '_' + parentAccounts.get(newOrUpdatedCont.AccountId).Name).trim();
                        newOrUpdatedCont.ia_crm__Intacct_Contact_ID__c = fullname;  
                    }

                    // BEFORE UPDATE, CHECK FOR APPLICABLE FIELD CHANGES AND FLAG CONTACT FOR SYNC IF NECESSARY                  
                    if(outdatedCont != null && (newOrUpdatedCont.FirstName != outdatedCont.FirstName || newOrUpdatedCont.LastName != outdatedCont.LastName || 
                                                newOrUpdatedCont.Email != outdatedCont.Email || newOrUpdatedCont.Phone != outdatedCont.Phone)){
                        newOrUpdatedCont.ia_crm__Sync_With_Intacct__c = true;
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processContactBeforeChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processContactBeforeChanges', newOrUpdatedContacts, ex, true);
        }
    }
    
    /**
    * @description processContractBeforeChanges - Helper method for handling Contract Before trigger logic for Intacct Integration fields
    *                                               --- EXECUTED BY CONTRACT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<Contract> newOrUpdatedContracts - New or updated Contract records
    * @param Map<Id, Contract> outdatedContracts - Outdated Contract records
    * @return void
    */
    public static void processContractBeforeChanges(List<Contract> newOrUpdatedContracts, Map<Id, Contract> outdatedContracts) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processContractBeforeChanges') && newOrUpdatedContracts != null && !newOrUpdatedContracts.isEmpty()){

                // GET PARENTS OPP IDS OF NEW CONTRACTS OR CONTRACTS WITH APPLICABLE CHANGES
                Set<Id> parentOppIds = new Set<Id>();
                for(Contract newOrUpdatedContract : newOrUpdatedContracts){
                    Contract outdatedContract = outdatedContracts != null && !outdatedContracts.isEmpty() ? outdatedContracts.get(newOrUpdatedContract.Id) : null;

                    // CREATE MAP OF PARENT OPPORTUNITIES IF APPLICABLE AND THE MAP WAS NOT YET CREATED.
                    if(outdatedContract == null || (outdatedContract != null && newOrUpdatedContract.Payment_Terms_non_Net_30__c != outdatedContract.Payment_Terms_non_Net_30__c)){
                        parentOppIds.add(newOrUpdatedContract.SBQQ__Opportunity__c);
                        parentOppIds.add(newOrUpdatedContract.SBQQ__RenewalOpportunity__c);
                    }
                }

                // GET PARENT OPP RECORDS
                Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>([SELECT Id, Sales_Ops_Approved__c, Type, Payment_Terms__c, ContractId, SBQQ__AmendedContract__c, 
                                                                          SBQQ__RenewedContract__c, RecordTypeId, ia_crm__Bill_to__c, ia_crm__Ship_to__c, ia_crm__Intacct_Entity__c, 
                                                                          Entity_Code__c, Additional_Provisions__c FROM Opportunity WHERE Id IN :parentOppIds]);

                for(Contract newOrUpdatedContract : newOrUpdatedContracts){
                    Contract outdatedContract = outdatedContracts != null && !outdatedContracts.isEmpty() ? outdatedContracts.get(newOrUpdatedContract.Id) : null;

                    // BEFORE INSERT CHANGES
                    if(outdatedContract == null && oppsById.containsKey(newOrUpdatedContract.SBQQ__Opportunity__c)){
                        Opportunity parentOpp = oppsById.get(newOrUpdatedContract.SBQQ__Opportunity__c);

                        // END CUSTOMER, IF PARENT OPPORTUNITY IS INDIRECT
                        if(parentOpp.RecordTypeId == RecordTypes.get('Opportunity').get('Indirect')){
                            newOrUpdatedContract.ia_crm__End_Customer__c = newOrUpdatedContract.AccountId;
                        }

                        // BILL IN ADVANCE
                        newOrUpdatedContract.ia_crm__Bill_in_advance__c = 1;

                        // BILL IN ADVANCE TERM
                        newOrUpdatedContract.ia_crm__Bill_in_advance_term__c = 'months';

                        // BILL TO
                        newOrUpdatedContract.ia_crm__Bill_to__c = parentOpp.ia_crm__Bill_to__c;

                        // SHIP TO
                        newOrUpdatedContract.ia_crm__Ship_to__c = parentOpp.ia_crm__Ship_to__c;

                        // INTACCT ENTITY
                        newOrUpdatedContract.ia_crm__Intacct_Entity__c = parentOpp.ia_crm__Intacct_Entity__c;

                        // ENTITY CODE
                        newOrUpdatedContract.Entity_Code__c = parentOpp.Entity_Code__c;

                        // ADDITIONAL PROVISIONS
                        newOrUpdatedContract.Additional_Provisions__c = parentOpp.Additional_Provisions__c;

                        // SBQQ RENEWED CONTRACT
                        if(parentOpp.Type == 'Renewal'){
                            newOrUpdatedContract.ia_crm__Renewed_Contract__c = parentOpp.SBQQ__RenewedContract__c;
                        }
                    }

                    // BEFORE INSERT OR UPDATE CHANGES, PAYMENT TERMS
                    if(outdatedContract == null || (outdatedContract != null && newOrUpdatedContract.Payment_Terms_non_Net_30__c != outdatedContract.Payment_Terms_non_Net_30__c)){
                        if(IntacctTermMappings.containsKey(newOrUpdatedContract.Payment_Terms_non_Net_30__c)){
                            newOrUpdatedContract.ia_crm__Term__c = IntacctTermMappings.get(newOrUpdatedContract.Payment_Terms_non_Net_30__c);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processContractBeforeChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processContractBeforeChanges', newOrUpdatedContracts, ex, true);
        }
    }  


    /**
    * @description processContractAfterChanges - Helper method for handling Contract After trigger logic for Intacct Integration fields
    *                                               --- EXECUTED BY CONTRACT AFTER INSERT AND AFTER UPDATE TRIGGERS ---
    * @param List<Contract> newOrUpdatedContracts - New or updated Contract records
    * @param Map<Id, Contract> outdatedContracts - Outdated Contract records
    * @return void    
    */
    public static void processContractAfterChanges(List<Contract> newOrUpdatedContracts, Map<Id, Contract> outdatedContracts) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processContractAfterChanges') && newOrUpdatedContracts != null){

                // GET PARENTS OPP IDS OF NEW CONTRACTS OR CONTRACTS WITH APPLICABLE CHANGES
                Set<Id> parentOppIds = new Set<Id>();
                for(Contract newOrUpdatedContract : newOrUpdatedContracts){
                    Contract outdatedContract = outdatedContracts != null && !outdatedContracts.isEmpty() ? outdatedContracts.get(newOrUpdatedContract.Id) : null;

                    // CREATE MAP OF PARENT OPPORTUNITIES IF APPLICABLE AND THE MAP WAS NOT YET CREATED.
                    if(outdatedContract == null || (outdatedContract != null && (newOrUpdatedContract.Payment_Terms_non_Net_30__c != outdatedContract.Payment_Terms_non_Net_30__c || 
                                                                                 newOrUpdatedContract.SBQQ__Opportunity__c != outdatedContract.SBQQ__Opportunity__c))){
                        parentOppIds.add(newOrUpdatedContract.SBQQ__Opportunity__c);
                        parentOppIds.add(newOrUpdatedContract.SBQQ__RenewalOpportunity__c);
                    }
                }

                // GET PARENT OPP RECORDS
                Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>([SELECT Id, Sales_Ops_Approved__c, Type, Payment_Terms__c, ContractId, SBQQ__AmendedContract__c, 
                                                                          SBQQ__RenewedContract__c, RecordTypeId, ia_crm__Bill_to__c, ia_crm__Ship_to__c, ia_crm__Intacct_Entity__c, 
                                                                          Entity_Code__c, Additional_Provisions__c FROM Opportunity WHERE Id IN :parentOppIds]);

                // PROCESS NEW OR CHANGED CONTRACTS
                Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
                for(Contract newOrUpdatedContract : newOrUpdatedContracts){

                    Contract outdatedContract = outdatedContracts != null && !outdatedContracts.isEmpty() ? outdatedContracts.get(newOrUpdatedContract.Id) : null;
                    Opportunity parentOpp = !oppsById.isEmpty() && oppsById.containsKey(newOrUpdatedContract.SBQQ__Opportunity__c) ? oppsById.get(newOrUpdatedContract.SBQQ__Opportunity__c) : null;
                    Boolean parentOppChanged = false;
                    
                    if(parentOpp != null){

                        // OPPORTUNITY CONTRACT, NEW CONTRACT OR CONTRACT WITH APPLICABLE CHANGE
                        if(outdatedContract == null && parentOpp.Sales_Ops_Approved__c && (parentOpp.Type == 'New Business' || parentOpp.Type == 'Renewal')){
                            if(newOrUpdatedContract.RecordTypeId == RecordTypes.get('Contract').get('Customer_Subscription')){
                                parentOpp.ContractId = newOrUpdatedContract.Id;
                                parentOppChanged = true;
                            }
                        }
                        else if(outdatedContract == null && parentOpp.Type == 'Existing Business'){
                            parentOpp.ContractId = parentOpp.SBQQ__AmendedContract__c != null ? parentOpp.SBQQ__AmendedContract__c : newOrUpdatedContract.Id;
                            parentOppChanged = true;
                        }
                        else if(outdatedContract != null && newOrUpdatedContract.SBQQ__Opportunity__c != outdatedContract.SBQQ__Opportunity__c){
                            if(newOrUpdatedContract.RecordTypeId == RecordTypes.get('Contract').get('Customer_Subscription')){
                                parentOpp.ContractId = newOrUpdatedContract.Id;
                                parentOppChanged = true;
                            }
                        }

                        // PAYMENT TERMS, NEW CONTRACT OR APPLICABLE FIELD IS CHANGED
                        if(outdatedContract == null || (outdatedContract != null && newOrUpdatedContract.Payment_Terms_non_Net_30__c != outdatedContract.Payment_Terms_non_Net_30__c)){
                            if(IntacctTermMappings.containsKey(newOrUpdatedContract.Payment_Terms_non_Net_30__c)){
                                parentOpp.Payment_Terms__c = newOrUpdatedContract.Payment_Terms_non_Net_30__c;
                                parentOppChanged = true;
                            }
                        }

                        // ADD PARENT OPP TO UPDATE QUEUE IF IT WAS CHANGED
                        if(parentOppChanged){
                            oppsToUpdate.put(parentOpp.Id, parentOpp);
                        }
                    }
                }                

                // SAVE UPDATED OPPORTUNITIES
                if(!oppsToUpdate.isEmpty()){
                    Database.saveResult[] oppResults = Database.update(oppsToUpdate.values(), false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'IntacctFieldSyncHelper', 'processContractAfterChanges', true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processContractAfterChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processContractAfterChanges', newOrUpdatedContracts, ex, true);
        }
    }  

    /**
    * @description processOpportunityBeforeChanges - Helper method for handling Intacct field mappings for the Opportunity object 
    *                                                 --- EXECUTED BY OPPORTUNITY BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<Opportunity> newOrUpdatedOpps - New or updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Outdated Opportunity records
    * @return void      
    */
    public static void processOpportunityBeforeChanges(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processOpportunityBeforeChanges') && newOrUpdatedOpps != null){

                // GET PARENT ACCOUNT IDS FROM QUALIFYING OPPS
                Set<Id> parentAcctIds = new Set<Id>();
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null && !outdatedOpps.isEmpty() ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;

                    // GET ACCOUNT IDS FROM OPPS WITH QUALIFYING CHANGES 
                    if(outdatedOpp == null || newOrUpdatedOpp.Billing_Party__c != outdatedOpp.Billing_Party__c){
                        parentAcctIds.add(newOrUpdatedOpp.AccountId);
                        parentAcctIds.add(newOrUpdatedOpp.Billing_Party__c);
                    }
                }

                // GET PARENT ACCOUNTS
                Map<Id, Account> accountsById = new Map<Id, Account>();
                if(!parentAcctIds.isEmpty()){
                    accountsById = new Map<Id, Account>([SELECT Id, ia_crm__Bill_to_Contact__c, ia_crm__Ship_to_Contact__c FROM Account WHERE Id IN :parentAcctIds]);
                }

                // PROCESS OPPORTUNITY CHANGES
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null && !outdatedOpps.isEmpty() ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;

                    if(!newOrUpdatedOpp.IsClosed){
                        // UPDATES FOR ONLY OPEN OPPS

                        // BILL TO AND SHIP, NEW OPPS ONLY
                        if(outdatedOpp == null && newOrUpdatedOpp.RecordTypeId == RecordTypes.get('Opportunity').get('Direct') && accountsById.containsKey(newOrUpdatedOpp.AccountId)){
                            newOrUpdatedOpp.ia_crm__Bill_to__c = accountsById.get(newOrUpdatedOpp.AccountId).ia_crm__Bill_to_Contact__c;
                            newOrUpdatedOpp.ia_crm__Ship_to__c = accountsById.get(newOrUpdatedOpp.AccountId).ia_crm__Ship_to_Contact__c;
                        }

                        // BILLING PARTY, NEW OPPS OR WHEN APPLICABLE FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.Billing_Party__c != outdatedOpp.Billing_Party__c)){
                            newOrUpdatedOpp.ia_crm__Bill_to_Account__c = newOrUpdatedOpp.Billing_Party__c;

                            if(newOrUpdatedOpp.RecordTypeId == RecordTypes.get('Opportunity').get('Indirect') && newOrUpdatedOpp.Billing_Party__c != null && accountsById.containsKey(newOrUpdatedOpp.Billing_Party__c)){
                                newOrUpdatedOpp.ia_crm__Bill_to__c = accountsById.get(newOrUpdatedOpp.Billing_Party__c).ia_crm__Bill_to_Contact__c;
                                newOrUpdatedOpp.ia_crm__Ship_to__c = accountsById.get(newOrUpdatedOpp.Billing_Party__c).ia_crm__Ship_to_Contact__c;
                            }
                        }

                        // ENTITY CODE, NEW OPPS OR WHEN APPLICABLE FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.Entity_Code__c != outdatedOpp.Entity_Code__c)){
                            // SET OCTIV INTACCT ENTITY 
                            if(newOrUpdatedOpp.Entity_Code__c == 'Octiv' && IntacctEntitiesByEntityID.containsKey('OCTIV')){
                                newOrUpdatedOpp.ia_crm__Intacct_Entity__c = IntacctEntitiesByEntityID.get('OCTIV').Id;
                                newOrUpdatedOpp.ia_crm__Intacct_Location__c = IntacctEntitiesByEntityID.get('OCTIV').Id;
                            }
                            // SET TO ALLC FOR ALL ENTITIES THAT ARE NOT OCTIV
                            else if(newOrUpdatedOpp.Entity_Code__c != 'Octiv' && IntacctEntitiesByEntityID.containsKey('ALLC')){
                                newOrUpdatedOpp.ia_crm__Intacct_Entity__c = IntacctEntitiesByEntityID.get('ALLC').Id;
                                newOrUpdatedOpp.ia_crm__Intacct_Location__c = IntacctEntitiesByEntityID.get('ALLC').Id;
                            }
                        }

                        // PAYMENT TERMS, NEW OPPS OR WHEN APPLICABLE FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.Payment_Terms__c != outdatedOpp.Payment_Terms__c)){
                            if(IntacctTermMappings.containsKey(newOrUpdatedOpp.Payment_Terms__c)){
                                newOrUpdatedOpp.ia_crm__Term__c = IntacctTermMappings.get(newOrUpdatedOpp.Payment_Terms__c);
                            }
                        }

                        // MRR SUB START, NEW OPPS OR WHEN APPLICABLE FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.MRR_Sub_Start__c != outdatedOpp.MRR_Sub_Start__c)){
                            newOrUpdatedOpp.ia_crm__Start_Date__c = newOrUpdatedOpp.MRR_Sub_Start__c;
                        }

                        // MRR SUB END, NEW OPPS OR WHEN APPLICABLE FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.MRR_Sub_End__c != outdatedOpp.MRR_Sub_End__c)){
                            newOrUpdatedOpp.ia_crm__End_Date__c = newOrUpdatedOpp.MRR_Sub_End__c;
                        }
                    }
                    else{
                        // ONLY FOR CLOSED OPPS

                        // SBQQ AMENDED CONTRACT, ONLY WHEN Sales_Ops_Approved__c IS CHANGED TO TRUE AND OPP TYPE IS EXISTING BUSINESS
                        if(outdatedOpp != null && newOrUpdatedOpp.Type == 'Existing Business' && newOrUpdatedOpp.Sales_Ops_Approved__c == true && 
                           newOrUpdatedOpp.Sales_Ops_Approved__c != outdatedOpp.Sales_Ops_Approved__c){
                            newOrUpdatedOpp.ContractId = newOrUpdatedOpp.SBQQ__AmendedContract__c != null ? newOrUpdatedOpp.SBQQ__AmendedContract__c : newOrUpdatedOpp.ContractId;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processOpportunityBeforeChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processOpportunityBeforeChanges', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @description processOpportunityAfterChanges - Helper method for handling Intacct field mappings for the Opportunity object 
    *                                                 --- EXECUTED BY OPPORTUNITY AFTER INSERT AND AFTER UPDATE TRIGGERS ---
    * @param List<Opportunity> newOrUpdatedOpps - New or updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Outdated Opportunity records
    * @return void
    */
    public static void processOpportunityAfterChanges(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processOpportunityAfterChanges') && newOrUpdatedOpps != null){

                Set<Id> contractsToUpdateIds = new Set<Id>();
                Set<Id> oppsWithOppItemsToUpdateIds = new Set<Id>();
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null && !outdatedOpps.isEmpty() ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;

                    // CONTRACT UPDATES ARE NECESSARY IF OPP IS NEW OR HAS APPLICABLE CHANGES
                    if(outdatedOpp == null || (outdatedOpp != null && (newOrUpdatedOpp.Accounting_Approved__c != outdatedOpp.Accounting_Approved__c ||
                                               newOrUpdatedOpp.Entity_Code__c != outdatedOpp.Entity_Code__c ||
                                               newOrUpdatedOpp.Additional_Provisions__c != outdatedOpp.Additional_Provisions__c ||
                                               newOrUpdatedOpp.SBQQ__RenewedContract__c != outdatedOpp.SBQQ__RenewedContract__c ||
                                               newOrUpdatedOpp.ia_crm__Bill_to__c != outdatedOpp.ia_crm__Bill_to__c ||
                                               newOrUpdatedOpp.ia_crm__Ship_to__c != outdatedOpp.ia_crm__Ship_to__c ||
                                               newOrUpdatedOpp.ia_crm__Intacct_Entity__c != outdatedOpp.ia_crm__Intacct_Entity__c))){

                        contractsToUpdateIds.add(newOrUpdatedOpp.ContractId);
                    }

                    // OPP ITEM UPDATES ARE NECESSARY IF OPP HAS BEEN CLOSED
                    if(outdatedOpp != null && newOrUpdatedOpp.IsClosed && newOrUpdatedOpp.IsClosed != outdatedOpp.IsClosed){
                        oppsWithOppItemsToUpdateIds.add(newOrUpdatedOpp.Id);
                    }
                }

                // GET PARENT CONTRACTS
                Map<Id, Contract> contractsById = new Map<Id, Contract>();
                if(!contractsToUpdateIds.isEmpty()){
                    contractsById = new Map<Id, Contract>([SELECT Id, Additional_Provisions__c, Entity_Code__c, ia_crm__Sync_With_Intacct__c, ia_crm__Renewed_Contract__c 
                                                           FROM Contract WHERE Id IN :contractsToUpdateIds]);
                }

                // GET CHILD OPP ITEMS
                Map<Id, List<OpportunityLineItem>> oppItemsByOpportunityId = new Map<Id, List<OpportunityLineItem>>();
                if(!oppsWithOppItemsToUpdateIds.isEmpty()){
                    for(OpportunityLineItem oppItem : [SELECT Id, ia_crm__Billing_Method__c, UnitPrice, Quantity, OpportunityId, Opportunity.Account.ia_crm__SalesRep__c, 
                                                           ia_crm__Project__r.ia_crm__Begin_Date__c FROM OpportunityLineItem WHERE OpportunityId IN :oppsWithOppItemsToUpdateIds]){
                            if(!oppItemsByOpportunityId.containsKey(oppItem.OpportunityId)){
                                oppItemsByOpportunityId.put(oppItem.OpportunityId, new List<OpportunityLineItem>());
                            }
                            oppItemsByOpportunityId.get(oppItem.OpportunityId).add(oppItem);
                    }  
                }

                // PROCESS UPDATES
                List<Contract> contractsToUpdate = new List<Contract>();
                List<OpportunityLineItem> oppItemsToUpdate = new List<OpportunityLineItem>();
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){

                    Opportunity outdatedOpp = outdatedOpps != null && !outdatedOpps.isEmpty() ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                    Contract parentContract = !contractsById.isEmpty() && contractsById.containsKey(newOrUpdatedOpp.ContractId) ? contractsById.get(newOrUpdatedOpp.ContractId) : null;
                    Boolean parentContractChanged = false;

                    if(parentContract != null){
                        // BILL TO, WHEN PARENT CONTRACT EXISTS, ON INSERT OR FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.ia_crm__Bill_to__c != outdatedOpp.ia_crm__Bill_to__c)){
                            parentContract.ia_crm__Bill_to__c = newOrUpdatedOpp.ia_crm__Bill_to__c;
                            parentContractChanged = true;
                        }

                        // SHIP TO, WHEN PARENT CONTRACT EXISTS, ON INSERT OR FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.ia_crm__Ship_to__c != outdatedOpp.ia_crm__Ship_to__c)){
                            parentContract.ia_crm__Ship_to__c = newOrUpdatedOpp.ia_crm__Ship_to__c;
                            parentContractChanged = true;
                        }

                        // INTACCT ENTITY, WHEN PARENT CONTRACT EXISTS, ON INSERT OR FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.ia_crm__Intacct_Entity__c != outdatedOpp.ia_crm__Intacct_Entity__c)){
                            parentContract.ia_crm__Intacct_Entity__c = newOrUpdatedOpp.ia_crm__Intacct_Entity__c;
                            parentContractChanged = true;
                        }

                        // ACCOUNTING APPROVED, WHEN PARENT CONTRACT EXISTS, ON INSERT OR FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.Accounting_Approved__c != outdatedOpp.Accounting_Approved__c)){
                            parentContract.ia_crm__Sync_With_Intacct__c = true;
                            parentContractChanged = true;
                        }

                        // ENTITY CODE, WHEN PARENT CONTRACT EXISTS, ON INSERT OR FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.Entity_Code__c != outdatedOpp.Entity_Code__c)){
                            parentContract.Entity_Code__c = newOrUpdatedOpp.Entity_Code__c;
                            parentContractChanged = true;
                        }

                        // ADDITIONAL PROVISIONS, WHEN PARENT CONTRACT EXISTS, ON INSERT OR FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.Additional_Provisions__c != outdatedOpp.Additional_Provisions__c)){
                            parentContract.Additional_Provisions__c = newOrUpdatedOpp.Additional_Provisions__c;
                            parentContractChanged = true;
                        }

                        // SBQQ RENEWED CONTRACT, WHEN PARENT CONTRACT EXISTS, ON INSERT OR FIELD IS CHANGED
                        if(outdatedOpp == null || (outdatedOpp != null && newOrUpdatedOpp.SBQQ__RenewedContract__c != outdatedOpp.SBQQ__RenewedContract__c)){
                            parentContract.ia_crm__Renewed_Contract__c = newOrUpdatedOpp.SBQQ__RenewedContract__c;
                            parentContractChanged = true;
                        }

                        // ADD PARENT CONTRACT TO UPDATE QUEUE IF IT WAS CHANGED
                        if(parentContractChanged){
                            contractsToUpdate.add(parentContract);
                        }
                    }

                    // PROCESS CHANGES THAT CAN ONLY HAPPEN AFTER AN UPDATE AND WHEN THE OPP HAS BEEN CLOSED WON
                    if(outdatedOpp != null && newOrUpdatedOpp.IsClosed && newOrUpdatedOpp.IsClosed != outdatedOpp.IsClosed){
                        if(oppItemsByOpportunityId.containsKey(newOrUpdatedOpp.Id)){
                            for(OpportunityLineItem oppItem : oppItemsByOpportunityId.get(newOrUpdatedOpp.Id)){

                                // INTACCT ENTITY
                                oppItem.ia_crm__Intacct_Entity__c = newOrUpdatedOpp.ia_crm__Intacct_Entity__c;

                                // INTACCT LOCATION
                                oppItem.ia_crm__Intacct_Location__c = newOrUpdatedOpp.ia_crm__Intacct_Location__c;

                                // INTACCT DEPARTMENT
                                oppItem.ia_crm__Department__c = newOrUpdatedOpp.ia_crm__Department__c;

                                // INTACCT EMPLOYEE
                                oppItem.ia_crm__Employee__c = oppItem.Opportunity.Account.ia_crm__SalesRep__c;

                                // INTACCT SHIP TO
                                oppItem.ia_crm__Ship_to_Contact__c = newOrUpdatedOpp.ia_crm__Ship_to__c;

                                // INTACCT AMOUNT
                                if(oppItem.ia_crm__Billing_Method__c == 'Fixed price'){
                                    oppItem.ia_crm__Amount__c = oppItem.UnitPrice * oppItem.Quantity;
                                }
                                else if(oppItem.ia_crm__Billing_Method__c == 'Project T&M'){
                                    oppItem.ia_crm__Amount__c = 0;
                                }

                                // ADD OPP LINE ITEM TO UPDATE QUEUE IF IT WAS CHANGED
                                oppItemsToUpdate.add(oppItem);
                            }
                        }
                    }
                }

                // SAVE UPDATED CONTRACTS
                if(!contractsToUpdate.isEmpty()){
                    Database.saveResult[] contractResults = Database.update(contractsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(contractResults, 'IntacctFieldSyncHelper', 'processOpportunityAfterChanges', false);
                }

                // SAVE UPDATED OPPORTUNITY ITEMS
                if(!oppItemsToUpdate.isEmpty()){
                    Database.saveResult[] oppItemsResults = Database.update(oppItemsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppItemsResults, 'IntacctFieldSyncHelper', 'processOpportunityAfterChanges', false);
                }

                // SAVE ANY ERRORS THAT WERE LOGGED
                SystemIssueLogHelper.UpsertExceptions();

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processOpportunityAfterChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processOpportunityAfterChanges', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @description processOppItemBeforeChanges - Helper method for handling Intacct field mappings for the OpportunityLineItem object 
    *                                                 --- EXECUTED BY OPPORTUNITY LINE ITEM BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<OpportunityLineItem> newOrUpdatedOppItems - New or updated OpportunityLineItem records
    * @param Map<Id, OpportunityLineItem> outdatedOppItems - Outdated OpportunityLineItem records
    * @return void
    */
    public static void processOppItemBeforeChanges(List<OpportunityLineItem> newOrUpdatedOppItems, Map<Id, OpportunityLineItem> outdatedOppItems) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processOppItemBeforeChanges') && newOrUpdatedOppItems != null){

                // GET PARENT PRODUCT IDS
                for(OpportunityLineItem newOrUpdatedOppItem : newOrUpdatedOppItems){
                    ParentProductIds.add(newOrUpdatedOppItem.Product2Id);
                }

                // PROCESS CHANGES
                for(OpportunityLineItem newOrUpdatedOppItem : newOrUpdatedOppItems){
                    OpportunityLineItem outdatedOppItem = outdatedOppItems != null ? outdatedOppItems.get(newOrUpdatedOppItem.Id) : null;

                    // INTACCT START DATE AND BILLING START DATE, NEW OPP ITEM OR APPLICABLE FIELD IS CHANGED
                    if(outdatedOppItem == null || (outdatedOppItem != null && newOrUpdatedOppItem.ServiceDate != null && newOrUpdatedOppItem.ServiceDate != outdatedOppItem.ServiceDate)){
                        newOrUpdatedOppItem.ia_crm__Start_Date__c = newOrUpdatedOppItem.ServiceDate;
                        newOrUpdatedOppItem.ia_crm__Billing_Start_Date__c = newOrUpdatedOppItem.ServiceDate;
                    }

                    // INTACCT END DATE, INTACCT BILLING END DATE, INTACCT SERVICE END DATE, NEW OPP ITEM OR APPLICABLE FIELD IS CHANGED
                    if(outdatedOppItem == null || (outdatedOppItem != null && newOrUpdatedOppItem.Product_End_Date__c != outdatedOppItem.Product_End_Date__c)){
                        Date productEndDate = null;

                        // DERIVE DATE FROM Product_End_Date__c IF ITS POPULATED. OTHERWISE USE ServiceDate AND ADD 12 MONTHS
                        if(newOrUpdatedOppItem.Product_End_Date__c != null){
                            productEndDate = newOrUpdatedOppItem.Product_End_Date__c;
                        }
                        else if(newOrUpdatedOppItem.ServiceDate != null){
                            productEndDate = newOrUpdatedOppItem.ServiceDate.addMonths(12);
                        }

                        if(productEndDate != null){
                            newOrUpdatedOppItem.ia_crm__End_Date__c = productEndDate;
                            newOrUpdatedOppItem.ia_crm__Billing_End_Date__c = productEndDate;
                            newOrUpdatedOppItem.ia_crm__Service_End_Date__c = productEndDate;
                        }
                    }

                    // INTACCT FLAT/FIXED AMOUNT FREQUECY, INTACCT BILLING METHOD, NEW OPP ITEM ONLY
                    if(outdatedOppItem == null && ParentProductsById.containsKey(newOrUpdatedOppItem.Product2Id)){
                        Product2 parentProduct = ParentProductsById.get(newOrUpdatedOppItem.Product2Id);
                        newOrUpdatedOppItem.ia_crm__Contract_Line_Save_Cancel_He__c = parentProduct.ia_crm__Flat_fixed_amount_frequency__c;
                        newOrUpdatedOppItem.ia_crm__Billing_Method__c = parentProduct.ia_crm__Billing_method__c;
                        newOrUpdatedOppItem.ia_crm__Billing_Template__c = parentProduct.ia_crm__Billing_Template__c;
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processOppItemBeforeChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processOppItemBeforeChanges', newOrUpdatedOppItems, ex, true);
        }
    }

    /**
    * @description processSalesInvoiceBeforeChanges - Helper method for handling ia_crm__Sales_Invoice__c Before trigger logic for Intacct Integration fields
    *                                                 --- EXECUTED BY IACRM SALES INVOICE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<ia_crm__Sales_Invoice__c> newOrUpdatedSalesInvoices - New or updated ia_crm__Sales_Invoice__c records
    * @param Map<Id, ia_crm__Sales_Invoice__c> outdatedSalesInvoices - Outdated ia_crm__Sales_Invoice__c records
    * @return void
    */
    public static void processSalesInvoiceBeforeChanges(List<ia_crm__Sales_Invoice__c> newOrUpdatedSalesInvoices, Map<Id, ia_crm__Sales_Invoice__c> outdatedSalesInvoices) {
        try{
            if(TriggerHelper.DoExecute('IntacctFieldSyncHelper','processSalesInvoiceBeforeChanges') && newOrUpdatedSalesInvoices != null && !newOrUpdatedSalesInvoices.isEmpty()){
                
                // GET PARENT PS PROJECT, OPPORTUNITY, AND ACCOUNT IDS WHERE APPLICABLE
                Set<Id> parentAccountIds = new Set<Id>();
                Set<Id> psProjectIds = new Set<Id>();
                Set<Id> parentOppIds = new Set<Id>();

                for(ia_crm__Sales_Invoice__c newOrUpdatedSalesInvoice : newOrUpdatedSalesInvoices){
                    ia_crm__Sales_Invoice__c outdatedSalesInvoice = outdatedSalesInvoices != null ? outdatedSalesInvoices.get(newOrUpdatedSalesInvoice.Id) : null;

                    // ON INSERT ONLY, GET ACCOUNT AND BILLING PARTY IDS
                    if(outdatedSalesInvoice == null){
                        parentAccountIds.add(newOrUpdatedSalesInvoice.ia_crm__Account__c);
                    }  

                    // ON INSERT OR PS_Project__c HAS CHANGED, GET PS PROJECT ID
                    if(outdatedSalesInvoice == null || (outdatedSalesInvoice != null && newOrUpdatedSalesInvoice.PS_Project__c != outdatedSalesInvoice.PS_Project__c)){
                        psProjectIds.add(newOrUpdatedSalesInvoice.PS_Project__c);
                    }

                    // ON INSERT OR ia_crm__Opportunity__c HAS CHANGED, GET OPPORTUNITY ID
                    if(outdatedSalesInvoice == null || (outdatedSalesInvoice != null && newOrUpdatedSalesInvoice.ia_crm__Opportunity__c != outdatedSalesInvoice.ia_crm__Opportunity__c)){
                        parentOppIds.add(newOrUpdatedSalesInvoice.ia_crm__Opportunity__c);
                    }
                }

                // REMOVE ANY NULLS FROM SETS
                parentAccountIds.remove(null);
                psProjectIds.remove(null);
                parentOppIds.remove(null);

                // GET PARENT ACCOUNTS
                Map<Id, Account> parentAccounts = new Map<Id, Account>();
                if(!parentAccountIds.isEmpty()){
                    parentAccounts = new Map<Id, Account>([SELECT Id, BillingContact__c FROM Account WHERE Id IN :parentAccountIds]);
                }

                // GET PARENT PS PROJECTS
                Map<Id, PS_Project__c> parentPSProjects = new Map<Id, PS_Project__c>();
                Set<String> intacctProjectExternalIDs = new Set<String>();
                if(!psProjectIds.isEmpty()){
                    parentPSProjects = new Map<Id, PS_Project__c>([SELECT Id, Billing_Additional_Emails__c, Intacct_Project_Id__c, OpportunityId__c,  OpportunityId__r.ia_crm__Bill_to__c,
                                                                   OpportunityId__r.ia_crm__Bill_to_Account__c, OpportunityId__r.Entity_Code__c FROM PS_Project__c WHERE Id IN :psProjectIds]);
                    
                    // GET INTACCT PROJECT EXTERNAL IDS FROM PS PROJECTS
                    for(PS_Project__c psProject : parentPSProjects.values()){
                        if(String.isNotBlank(psProject.Intacct_Project_Id__c)){
                            intacctProjectExternalIDs.add(psProject.Intacct_Project_Id__c);
                        }
                    }
                }

                // GET PARENT OPPORTUNITIES
                Map<Id, Opportunity> parentOpps = new Map<Id, Opportunity>();
                if(!parentOppIds.isEmpty()){
                    parentOpps = new Map<Id, Opportunity>([SELECT Id, StageName, RecordTypeId, ContractId, AccountId, Account.Name, Billing_Address_Override__c, Billing_Party__c,
                                                           Billing_Party__r.BillingContact__c, AdditionalInvoiceRecipients__c, Contract.ia_crm__Intacct_Contract__c 
                                                           FROM Opportunity WHERE Id IN :parentOppIds]);
                }

                // GET INTACCT PROJECTS
                Map<String, Id> intacctProjectsByExternalID = new Map<String, Id>();
                if(!intacctProjectExternalIDs.isEmpty()){
                    for(ia_crm__Project__c intacctProject : [SELECT Id, ia_crm__Project_ID__c FROM ia_crm__Project__c WHERE ia_crm__Project_ID__c IN :intacctProjectExternalIDs]){
                        intacctProjectsByExternalID.put(intacctProject.ia_crm__Project_ID__c, intacctProject.Id);
                    }
                }

                // PROCESS CHANGES
                for(ia_crm__Sales_Invoice__c newOrUpdatedSalesInvoice : newOrUpdatedSalesInvoices){
                    ia_crm__Sales_Invoice__c outdatedSalesInv = outdatedSalesInvoices != null ? outdatedSalesInvoices.get(newOrUpdatedSalesInvoice.Id) : null;

                    Account parentAccount = parentAccounts != null ? parentAccounts.get(newOrUpdatedSalesInvoice.ia_crm__Account__c) : null;
                    PS_Project__c parentPSProject = parentPSProjects != null ? parentPSProjects.get(newOrUpdatedSalesInvoice.PS_Project__c) : null;
                    Opportunity parentOpp = parentOpps != null ? parentOpps.get(newOrUpdatedSalesInvoice.ia_crm__Opportunity__c) : null;

                    // POPULATE ORDER TYPE FROM DOCUMENT TYPE WHEN APPLICABLE, ON INSERT ONLY
                    if(outdatedSalesInv == null && String.isNotBlank(newOrUpdatedSalesInvoice.ia_crm__Document_Type__c) && String.isBlank(newOrUpdatedSalesInvoice.Order_Type__c)){
                        if(newOrUpdatedSalesInvoice.ia_crm__Document_Type__c == 'Contract Invoice' && String.isNotBlank(newOrUpdatedSalesInvoice.Opportunity_Type__c)){
                            // CONTRACT INVOICE
                            newOrUpdatedSalesInvoice.Order_Type__c = newOrUpdatedSalesInvoice.Opportunity_Type__c;
                        }
                        else if(newOrUpdatedSalesInvoice.ia_crm__Document_Type__c == 'Sales Invoice'){
                            // SALES INVOICE
                            newOrUpdatedSalesInvoice.Order_Type__c = 'Services';
                        }
                    }

                    // BILL TO ACCOUNT AND BILL TO CONTACT, ON INSERT ONLY
                    if(outdatedSalesInv == null && parentAccount != null && parentOpp != null && parentOpp.StageName == 'Closed Won'){
                        // DIRECT OPP
                        if(parentOpp.RecordTypeId == UtilityClass.getRecordTypesForObject('Opportunity').get('Direct') && parentAccount.BillingContact__c != null){
                            newOrUpdatedSalesInvoice.Bill_To__c = parentAccount.BillingContact__c;
                        }

                        // INDIRECT OPP
                        if(parentOpp.RecordTypeId == UtilityClass.getRecordTypesForObject('Opportunity').get('Indirect') && parentOpp.Billing_Party__c != null && parentOpp.Billing_Party__r.BillingContact__c != null){
                            newOrUpdatedSalesInvoice.Bill_To_Account__c = parentOpp.Billing_Party__c;
                            newOrUpdatedSalesInvoice.Bill_To__c = parentOpp.Billing_Party__r.BillingContact__c;
                        }
                    }

                    // POPULATE ADDITIONAL INVOICE RECIPIENTS, ON INSERT ONLY
                    if(outdatedSalesInv == null && String.isNotBlank(newOrUpdatedSalesInvoice.ia_crm__Document_Type__c)){
                        if(newOrUpdatedSalesInvoice.ia_crm__Document_Type__c == 'Contract Invoice' && parentOpp != null){
                            newOrUpdatedSalesInvoice.Additional_Invoice_Recipients__c = parentOpp.AdditionalInvoiceRecipients__c;  
                        }
                        else if(newOrUpdatedSalesInvoice.ia_crm__Document_Type__c == 'Sales Invoice' && parentPSProject != null){
                            newOrUpdatedSalesInvoice.Additional_Invoice_Recipients__c = parentPSProject.Billing_Additional_Emails__c;  
                        }
                    }

                    // POPULATE BILLING ADDRESS OVERRIDE, ON INSERT ONLY
                    if(outdatedSalesInv == null && parentOpp != null && parentOpp.StageName == 'Closed Won'){
                            newOrUpdatedSalesInvoice.Billing_Address_Override__c = parentOpp.Billing_Address_Override__c;
                    }

                    // UPDATE FIELDS ON INSERT OR PS_Project__c IS CHANGED
                    if(parentPSProject != null && (outdatedSalesInv == null || (newOrUpdatedSalesInvoice.PS_Project__c != outdatedSalesInv.PS_Project__c))){
                        // INTACCT PROJECT
                        newOrUpdatedSalesInvoice.ia_crm__Project__c = intacctProjectsByExternalID.get(parentPSProject.Intacct_Project_Id__c);

                        if(parentPSProject.OpportunityId__c != null){
                            // BILL TO                            
                            //newOrUpdatedSalesInvoice.Bill_To__c = parentPSProject.OpportunityId__r.ia_crm__Bill_to__c;
                            // BILL TO ACCOUNT
                            //newOrUpdatedSalesInvoice.Bill_To_Account__c = parentPSProject.OpportunityId__r.ia_crm__Bill_to_Account__c;
                            // ENTITY CODE
                            newOrUpdatedSalesInvoice.Entity_Code__c = parentPSProject.OpportunityId__r.Entity_Code__c;
                        }
                    }

                    // UPDATE CONTRACT AND INTACCT CONTRACT, ON INSERT OR FIELD IS CHANGED
                    if(parentOpp != null && (outdatedSalesInv == null || (newOrUpdatedSalesInvoice.ia_crm__Opportunity__c != outdatedSalesInv.ia_crm__Opportunity__c))){
                        newOrUpdatedSalesInvoice.ia_crm__Contract__c = parentOpp.ContractId;
                        newOrUpdatedSalesInvoice.Intacct_Contract__c = parentOpp.Contract.ia_crm__Intacct_Contract__c;
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IntacctFieldSyncHelper','processSalesInvoiceBeforeChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IntacctFieldSyncHelper', 'processSalesInvoiceBeforeChanges', newOrUpdatedSalesInvoices, ex, true);
        }        
    }


}