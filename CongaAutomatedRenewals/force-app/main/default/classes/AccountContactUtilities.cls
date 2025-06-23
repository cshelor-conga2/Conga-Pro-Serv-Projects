/**
* @author CongaServices
* @date 20180608
* @version 1.00
* @description AccountContactUtilities
*/
global with sharing class AccountContactUtilities {

    private Opportunity opportunity {get;set;}
    private Account account {get;set;}
    private Boolean valid {get;set;}

    /**
    * @description Constructor 
    */
    public AccountContactUtilities() {
        valid = true;
        String opportunityIdParameter = ApexPages.currentPage().getParameters().get('opportunityId');
        String accountIdParameter = ApexPages.currentPage().getParameters().get('accountId');
        String idParameter = ApexPages.currentPage().getParameters().get('Id');
        if(String.isNotBlank(idParameter)) {
            Id recordId = Id.valueOf(idParameter);
            if(recordId.getSobjectType().getDescribe().getName() == SObjectType.Account.name) {
                accountIdParameter = recordId;
            }
            else if(recordId.getSobjectType().getDescribe().getName() == SObjectType.Opportunity.name) {
                opportunityIdParameter = recordId;
            }
        }

        if(String.isNotBlank(opportunityIdParameter)) {
            try {
                Id opportunityId = (Id)opportunityIdParameter;
                opportunity =  selectOpportunityById(opportunityId);
                if(opportunity == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Opportunity record not found.'));
                    valid = false;
                }
            }
            catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Opportunity Id.'));
                valid = false;
            }
        }
        else if(String.isNotBlank(accountIdParameter)) {
            try {
                Id accountId = (Id)accountIdParameter;
                account =  selectAccountById(accountId);
                if(account == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account record not found.'));
                    valid = false;                    
                }
            }
            catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Account Id.'));
                valid = false;                
            }
        }
    }

    // *****************
    // Public Properties
    // *****************
    public Boolean isValid {
        get {
            return valid;
        }
    }

    public Id opportunityId {
        get {
            if(opportunity != null) return opportunity.Id;
            else return null;
        }
    }

    public Id accountId {
        get {
            if(opportunity != null) return opportunity.AccountId;
            else if(account != null) return account.Id;
            else return null;
        }
    }

    public Boolean isForOpportunityContactRoleMaintenance {
        get {
            return opportunity != null;
        }
    }

    public Boolean isForAccountContactRelationshipMaintenance {
        get {
            return opportunity == null;
        }
    }

    // ************
    // Aura Enabled
    // ************
    @AuraEnabled 
    public static String searchAccountContacts(String objectName, String fld_API_Text, String fld_API_Val, 
                                  Integer lim, String par_API_Text, String par_API_Val, String order_By_Val ){
        
        par_API_Val= '\'' + par_API_Val + '\'';
        
        String query = 'SELECT '+fld_API_Text+' ,'+fld_API_Val+
                        ' FROM '+objectName+
                        ' WHERE '+par_API_Text+  ' = ' +par_API_Val+ 
                        ' ORDER BY '+order_By_Val+   
                        ' LIMIT '+lim;
        List<sObject> sobjList = Database.query(query);
        List<ResultWrapper> lstRet = new List<ResultWrapper>();
        
        for(SObject s : sobjList){
            ResultWrapper obj = new ResultWrapper();
            obj.objName = objectName;
            obj.text = String.valueOf(s.get(fld_API_Text)) ;
            obj.val = String.valueOf(s.get(fld_API_Val))  ;
            lstRet.add(obj);
        } 
         return JSON.serialize(lstRet) ;
    }

    @AuraEnabled
    public static String saveContactRoles(String pContactRoleList){
        OpportunityContactRole[] records = (OpportunityContactRole[])JSON.deserialize(pContactRoleList, List<OpportunityContactRole>.class);
        upsert records;
        return '';
    }

    // ******************
    // Additional Classes
    // ******************
    public class ResultWrapper{
        public String objName {get;set;}
        public String text{get;set;}
        public String val{get;set;}
    }

    // **************
    // Remote Actions
    // **************
    @RemoteAction
    public static List<AccountContactRelation> getAccountContacts(Id accountId){
        return [
            SELECT 
                Id, 
                ContactId, 
                Contact.Name, 
                Contact.Email, 
                Roles, 
                Persona__c, 
                Status__c, 
                AccountId, 
                IsPrimary__c,
                Contact.Title,
                Job_Level__c
            FROM 
                AccountContactRelation
            WHERE 
                AccountId = :accountId 
                //AND Status__c NOT IN ('Do not Contact', 'No Longer at Company') // Change requested by Kelsey Briggs (2018-12-05)
                AND Status__c NOT IN ('No Longer at Company')
            ORDER BY 
                IsPrimary__c DESC
        ];
    }

    @RemoteAction
    global static List<Contact> findContacts(String pInput, Id pAccountId, List<Id> contactIds) {
        //System.debug('contactIds = ' + contactIds);
        String inputClean = '%'+String.escapeSingleQuotes(pInput)+'%';
        return [
            SELECT 
                Id, 
                Name, 
                Account.Name, 
                FirstName, 
                LastName, 
                Email, 
                Phone, 
                Title
            FROM 
                Contact
            WHERE 
                Name LIKE :inputClean
                AND AccountId != :pAccountId
                AND Id NOT IN (
                    SELECT 
                        ContactId 
                    FROM 
                        AccountContactRelation 
                    WHERE 
                    AccountId = :pAccountId
                    )
                AND AccountId != '' 
                AND Id NOT IN :contactIds
            ORDER BY Name ASC
            LIMIT 20
        ];
    }

    @RemoteAction
    public static List<OpportunityContactRole> getOpportunityContactRoles(Id opportunityId){
        List<OpportunityContactRole> result = selectOppContacRoleByOppId(opportunityId);
        //System.debug('getOpportunityContactRoles records' + JSON.serialize(result));                                              
        return result;
    }

    @RemoteAction
    public static List<OpportunityContactRole> upsertContactRoles(List<OpportunityContactRole> opportunityContactRolesToUpsert){
        //System.debug('OpportunityContactRole records to Upsert = ' + JSON.serialize(opportunityContactRolesToUpsert));
        upsert opportunityContactRolesToUpsert;
        return opportunityContactRolesToUpsert;
    }

    @RemoteAction
    public static List<OpportunityContactRole> deleteContactRoles(List<OpportunityContactRole> opportunityContactRolesToDelete){
        //System.debug('OpportunityContactRole records to Delete = ' + JSON.serialize(opportunityContactRolesToDelete));
        delete opportunityContactRolesToDelete;
        return null;
    }

    @RemoteAction
    public static List<Contact> upsertContacts(List<Contact> contactsToUpsert){
        //System.debug('Contact records to Upsert = ' + JSON.serialize(contactsToUpsert));
        upsert contactsToUpsert;
        return contactsToUpsert;
    }

    @RemoteAction
    public static List<Contact> upsertContactsAccountRelation(List<Contact> contactsToUpsert, Id accountId, List<AccountContactRelation> accountContacts){
        //System.debug('Contact records to Upsert = ' + JSON.serialize(contactsToUpsert));        
        //System.debug('AccountContactRelation records Received = ' + JSON.serialize(accountContacts));
        //System.debug('contactsToUpsert.size() = ' + contactsToUpsert.size());       
        //System.debug('accountContacts.size() = ' + accountContacts.size());
        upsert contactsToUpsert;
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : contactsToUpsert) {
            contactIds.add(c.Id);
        }

        // To update existing relationships
        List<AccountContactRelation> accountContactsToUpsert = new List<AccountContactRelation>();
        List<AccountContactRelation> acrByAccount = selectAccountContactRelationByAccountId(accountId);
        for (Integer i=0;i<contactsToUpsert.size();i++) {
            for (AccountContactRelation acr : acrByAccount) {
                if (contactsToUpsert[i].Id == acr.ContactId) {
                    acr.Roles = accountContacts[i].Roles;
                    acr.Persona__c = accountContacts[i].Persona__c;
                    acr.Status__c = accountContacts[i].Status__c;
                    acr.IsPrimary__c = accountContacts[i].IsPrimary__c;
                    acr.Job_Level__c = accountContacts[i].Job_Level__c;
                    accountContactsToUpsert.add(acr);
                }
            }
        }
        
        // To create new relationships (contacts belonging to different Account than the Opportunity)
        for (Integer i=0;i<accountContacts.size();i++) {
            if (accountContacts[i].ContactId != null && contactsToUpsert[i].AccountId != null && contactsToUpsert[i].AccountId != accountId) {
                AccountContactRelation acr = new AccountContactRelation();
                acr.ContactId = contactsToUpsert[i].Id;
                acr.AccountId = accountContacts[i].AccountId;
                acr.Roles = accountContacts[i].Roles;
                acr.Persona__c = accountContacts[i].Persona__c;
                acr.Status__c = accountContacts[i].Status__c;
                acr.IsPrimary__c = accountContacts[i].IsPrimary__c;
                acr.Job_Level__c = accountContacts[i].Job_Level__c;
                accountContactsToUpsert.add(acr);
            }
        }

        //System.debug('AccountContactRelation records to Upsert= ' + JSON.serialize(accountContactsToUpsert));        
        //System.debug('accountContactsToUpsert.size() = ' + accountContactsToUpsert.size());
        upsert accountContactsToUpsert;
        return contactsToUpsert;
    }


    @RemoteAction
    public static List<AccountContactRelation> upsertAccountContacts(List<AccountContactRelation> accountContactsToUpsert){
        upsert accountContactsToUpsert;
        return accountContactsToUpsert;
    }

    @RemoteAction 
    global static List<String> getContactRoles() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = OpportunityContactRole.Role.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple) {
            options.add(pickListVal.getLabel());
        }
        return options;
    }

    @RemoteAction
    global static List<String> getContactPersona() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = AccountContactRelation.Persona__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple) {
            options.add(pickListVal.getLabel());
        }
        return options;
    }

    @RemoteAction
    global static List<String> getContactStatus() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = AccountContactRelation.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple) {
            options.add(pickListVal.getLabel());
        }
        return options;
    }

    @RemoteAction
    global static List<String> getJobLevel() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = AccountContactRelation.Job_Level__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple) {
            options.add(pickListVal.getLabel());
        }
        return options;
    }

    @RemoteAction 
    global static List<OpportunityContactRole> processChanges(
        Id accountId, 
        List<OpportunityContactRole> opportunityContactRolesToUpsert, 
        List<Contact> contactsToUpsert, 
        List<AccountContactRelation> accountContacts, 
        List<OpportunityContactRole> opportunityContactRolesToDelete) {

        Set<Id> opportunityIds = new Set<Id>();

        Savepoint sp = Database.setSavePoint();
        try {

            if (!opportunityContactRolesToDelete.isEmpty()) {
                //System.debug('OpportunityContactRole records to Delete = ' + JSON.serialize(opportunityContactRolesToDelete));            
                for (OpportunityContactRole ocr : opportunityContactRolesToDelete) {
                    if (ocr.OpportunityId != null) opportunityIds.add(ocr.OpportunityId);
                }
                delete opportunityContactRolesToDelete;   
            }
            
            if (!opportunityContactRolesToUpsert.isEmpty()) {
                //System.debug('OpportunityContactRole records to Upsert = ' + JSON.serialize(opportunityContactRolesToUpsert));
                for (OpportunityContactRole ocr : opportunityContactRolesToUpsert) {
                    if (ocr.OpportunityId != null) opportunityIds.add(ocr.OpportunityId);
                }            
                upsert opportunityContactRolesToUpsert;
            }

            if ((!contactsToUpsert.isEmpty()) && (!accountContacts.isEmpty())) {
                List<Contact> contacts = upsertContactsAccountRelation(contactsToUpsert, accountId, accountContacts);
            }

            if (!opportunityIds.isEmpty()) {
                //System.debug('opportunityIds = ' + opportunityIds);
                updateCountOfPrimaryContact(opportunityIds);
            }

        }
        catch (Exception e) {
            Database.rollback(sp);
            throw e;
        }

        return opportunityContactRolesToUpsert;
    }

    // **************
    // Public Methods
    // **************
    public static void updateCountOfPrimaryContact(Set<Id> opportunityIds) {
        if (opportunityIds.isEmpty()) return;
        Map<Id, Set<Id>> opportunityIdToContactIdMap = new Map<Id, Set<Id>>();
        List<OpportunityContactRole> oppContactRoles = [SELECT OpportunityId, ContactId FROM OpportunityContactRole WHERE OpportunityId IN : opportunityIds];
        //System.debug('oppContactRoles.size() = ' + oppContactRoles.size());
        if (!oppContactRoles.isEmpty()) {
            for (OpportunityContactRole ocr : oppContactRoles) {
                if (!opportunityIdToContactIdMap.containsKey(ocr.OpportunityId)) opportunityIdToContactIdMap.put(ocr.OpportunityId, new Set<Id>());
                opportunityIdToContactIdMap.get(ocr.OpportunityId).add(ocr.ContactId);
            }
        }
        //List<Opportunity> opportunities = [SELECT Id, CountofPrimaryContact__c  FROM Opportunity WHERE Id IN : opportunityIdToContactIdMap.keySet()];        
        List<Opportunity> opportunities = [SELECT Id, CountofPrimaryContact__c  FROM Opportunity WHERE Id IN : opportunityIds];        
        if (opportunities.isEmpty()) return;
        for (Opportunity opp : opportunities) {
            opp.CountofPrimaryContact__c  = opportunityIdToContactIdMap.containsKey(opp.Id) ? opportunityIdToContactIdMap.get(opp.Id).size() : 0;
            //System.debug(opp.Id + ' -> ' + opp.CountofPrimaryContact__c);
        }
        update opportunities;
    }

    // *********
    // Selectors
    // *********
    private static List<AccountContactRelation> selectAccountContactRelationByAccountId(Id accountId) {
        return [
            SELECT 
                Id, 
                Roles, 
                ContactId, 
                Persona__c, 
                Status__c, 
                AccountId, 
                IsPrimary__c,
                Job_Level__c
            FROM 
                AccountContactRelation 
            WHERE 
                AccountId = :accountId
            ORDER BY 
                IsPrimary__c DESC
            ];
    }

    private static List<OpportunityContactRole> selectOppContacRoleByOppId(Id opportunityId) {
        return [
            SELECT 
                Id, 
                Contact.Name, 
                Contact.Email, 
                Role, 
                ContactId, 
                IsPrimary
            FROM 
                OpportunityContactRole
            WHERE 
                OpportunityId = :opportunityId
            /*
            ORDER BY 
                IsPrimary DESC
            */
        ];
    }

    private Opportunity selectOpportunityById(Id opportunityId) {
        return [
            SELECT
                Id,
                AccountId
            FROM 
                Opportunity
            WHERE 
                Id = :opportunityId
        ];
    }

    private Account selectAccountById(Id accountId) {
        return [
            SELECT
                Id
            FROM 
                Account
            WHERE 
            Id = :accountId
        ];
    }

}