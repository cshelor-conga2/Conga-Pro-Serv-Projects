/**
* @author jmevorah
* @date 20170801
* @version 1.00
* @description SBQQQuoteHelper - Custom functionality for the SBQQ__Quote__c object
*/
public class SBQQQuoteHelper {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// STATIC VARIABLES //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // CHILD QUOTE LINE UPDATE QUEUE
    public static Map<Id, SBQQ__QuoteLine__c> ChildQuoteLinesToUpdate {
    get {
        if(ChildQuoteLinesToUpdate == null){
            ChildQuoteLinesToUpdate = new Map<Id, SBQQ__QuoteLine__c>();
        }
        return ChildQuoteLinesToUpdate;
    } set; }


    // RECORD TYPES
    @testVisible
    private static Map<String, Map<String, Id>> RecordTypes {
    get {
        if(RecordTypes == null){
            RecordTypes = UtilityClass.getRecordTypesForObjects(new List<String>{ 'SBQQ__Quote__c', 'SBQQ__QuoteLine__c', 'Opportunity' });
        }
        return RecordTypes;
    } set; }

    // OPPORTUNITY PARENT ACCOUNTS MAP AND ID SET
    public static Set<Id> ParentAccountIds {get; set;}
    private static Map<Id, Account> ParentAccountsMap {
    get {
        if(ParentAccountsMap == null){
            ParentAccountsMap = new Map<Id, Account>();
            for(Account account : [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, OwnerId, Owner.Role_Stamp__c, Owner.Region__c,
                                   BillingContact__c, BillingContact__r.Email, BillingContact__r.FirstName, BillingContact__r.LastName, BillingContact__r.Phone,
                                   Billing_Party__c, Billing_Party__r.BillingContact__r.Email, Billing_Party__r.BillingContact__r.FirstName,  Billing_Party__r.BillingContact__r.LastName,
                                   Billing_Party__r.BillingContact__r.Phone,
                                   MSA_Contract__c, MSA_Contract__r.Auto_Renew_Term__c, MSA_Contract__r.Expiration_Warning__c, MSA_Contract__r.Payment_Terms_non_Net_30__c, 
                                   MSA_Contract__r.Non_Payment_Late_Charge__c
                                   FROM Account WHERE Id IN :ParentAccountIds]){
                ParentAccountsMap.put(account.Id, account);
            }
        }
        return ParentAccountsMap;
    } set; }

    // OPPORTUNITY PARENT SALESFORCE ACCOUNTS MAP AND ID SET
    public static Set<Id> ParentOpportunityIds {get; set;}
    private static Map<Id, Opportunity> ParentOpportunitiesMap {
    get {
        if(ParentOpportunitiesMap == null){
            ParentOpportunitiesMap = new Map<Id, Opportunity>();
            for(Opportunity opp : [SELECT Id, Name, Type, Primary_Contact__c, RecordTypeId, OwnerId, Automate_Renewal__c,
                                   SBQQ__AmendedContract__c, SBQQ__AmendedContract__r.Auto_Renew_Term__c, SBQQ__AmendedContract__r.Expiration_Warning__c, 
                                   SBQQ__AmendedContract__r.Payment_Terms_non_Net_30__c, SBQQ__AmendedContract__r.Non_Payment_Late_Charge__c,
                                   SBQQ__RenewedContract__c, SBQQ__RenewedContract__r.Auto_Renew_Term__c, SBQQ__RenewedContract__r.Expiration_Warning__c, 
                                   SBQQ__RenewedContract__r.Payment_Terms_non_Net_30__c, SBQQ__RenewedContract__r.Non_Payment_Late_Charge__c, 
                                   SBQQ__RenewedContract__r.Overall_Subscription_Discount__c
                                   FROM Opportunity WHERE Id IN :ParentOpportunityIds]){
                ParentOpportunitiesMap.put(opp.Id, opp);

                // ADD CONTRACT IDS TO PARENT CONTRACT ID MAP
                ParentContractIds.add(opp.SBQQ__AmendedContract__c);
                ParentContractIds.add(opp.SBQQ__RenewedContract__c);
            }
        }
        return ParentOpportunitiesMap;
    } set; }

    // OPPORTUNITY PARENT CONTRACTS MAP AND ID SET
    public static Set<Id> ParentContractIds {get; set;}
    private static Map<Id, Contract> ParentContractsMap {
    get {
        if(ParentContractsMap == null){
            ParentContractsMap = new Map<Id, Contract>();
            for(Contract contract : [SELECT Id, Auto_Renew_Term__c, Expiration_Warning__c, Non_Payment_Late_Charge__c, Payment_Terms_non_Net_30__c FROM Contract WHERE Id IN :ParentContractIds]){
                ParentContractsMap.put(contract.Id, contract);
            }
        }
        return ParentContractsMap;
    } set; }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// TRIGGER / HELPER METHODS /////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * @author Conga Services, eredding
    * @description quoteFieldUpdates - Various On Create/Edit field updates. Also, code replacements for various SBQQ__Quote__c Process Builder field updates
    * @param List<SBQQ__Quote__c> newOrUpdatedQuotes - New or Updated SBQQ__Quote__c records
    * @param Map<Id,SBQQ__Quote__c> outdatedQuotes - Outdated SBQQ__Quote__c records
    * @return void
    */
    public static void quoteFieldUpdates(List<SBQQ__Quote__c> newOrUpdatedQuotes, Map<Id,SBQQ__Quote__c> outdatedQuotes){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteHelper','quoteFieldUpdates') && newOrUpdatedQuotes != null){ // MASTER CONTROL

                // MAKE QUALIFYING CHANGES
                for(SBQQ__Quote__c newOrUpdatedQuote : newOrUpdatedQuotes){
                    SBQQ__Quote__c outdatedQuote = outdatedQuotes != null ? outdatedQuotes.get(newOrUpdatedQuote.Id) : null;

                    // GET PARENT OPPORTUNITY
                    Opportunity parentOpportunity = ParentOpportunitiesMap.get(newOrUpdatedQuote.SBQQ__Opportunity2__c);

                    // DEFAULT OWNER FOR ALL NEW QUOTES
                    if(outdatedQuote == null && newOrUpdatedQuote.SBQQ__Opportunity2__c != null && parentOpportunity != null){
                        newOrUpdatedQuote.OwnerId = parentOpportunity.OwnerId;
                    }

                    // DEFAULT CONTRACTING METHOD FOR ALL NEW QUOTES
                    if(outdatedQuote == null){
                        newOrUpdatedQuote.SBQQ__ContractingMethod__c = 'Single Contract';
                    }

                    // RECORD TYPE AND STATUS UPDATE FOR A RENEWAL
                    if(outdatedQuote != null && parentOpportunity != null && newOrUpdatedQuote.SBQQ__Type__c == 'Renewal' && parentOpportunity.SBQQ__RenewedContract__c != null &&
                        newOrUpdatedQuote.SBQQ__CustomerAmount__c != 0 && newOrUpdatedQuote.SBQQ__CustomerAmount__c != outdatedQuote.SBQQ__CustomerAmount__c && parentOpportunity.Automate_Renewal__c &&
                        parentOpportunity.SBQQ__RenewedContract__r.Overall_Subscription_Discount__c <= newOrUpdatedQuote.Overall_Subscription_Discount__c){
                        newOrUpdatedQuote.ApprovalStatus__c = 'Approved';
                    }
                   
                    // RECORD TYPE UPDATES WITH APPROVAL STATUS CHANGES
                    if(outdatedQuote != null && newOrUpdatedQuote.ApprovalStatus__c != outdatedQuote.ApprovalStatus__c){
                        if(newOrUpdatedQuote.ApprovalStatus__c == 'Pending'){
                            newOrUpdatedQuote.RecordTypeId = RecordTypes.get('SBQQ__Quote__c').get('Pending');
                            newOrUpdatedQuote.SBQQ__Status__c = 'In Review';
                        }
                        else if(newOrUpdatedQuote.ApprovalStatus__c == 'Approved'){
                            newOrUpdatedQuote.RecordTypeId = RecordTypes.get('SBQQ__Quote__c').get('Approved');
                            newOrUpdatedQuote.SBQQ__Status__c = 'Approved';

                            // UPDATE TERMS WITH APPROVED STATUS IF APPLICABLE
                            if(newOrUpdatedQuote.SBQQ__Type__c == 'Quote' && (newOrUpdatedQuote.Non_Payment_Late_Charge__c != 1 || newOrUpdatedQuote.SBQQ__PaymentTerms__c != 'Net 30' ||
                                                           newOrUpdatedQuote.Expiration_Warning__c != 30 || newOrUpdatedQuote.Auto_Renew__c == '0')){
                                newOrUpdatedQuote.Terms__c = 'Partial - Negotiation';
                            }
                        }
                        else if(newOrUpdatedQuote.ApprovalStatus__c == 'Rejected'){
                            newOrUpdatedQuote.RecordTypeId = RecordTypes.get('SBQQ__Quote__c').get('Draft');
                            newOrUpdatedQuote.SBQQ__Status__c = 'Rejected';
                        }
                        else if(newOrUpdatedQuote.ApprovalStatus__c == 'Recalled'){
                            newOrUpdatedQuote.RecordTypeId = RecordTypes.get('SBQQ__Quote__c').get('Draft');
                            newOrUpdatedQuote.SBQQ__Status__c = 'Draft';
                        }
                    }

                    // SWITCH CONGA COLLABORATE TEMPLATE AND SET LAST APPROVED STAMP WHEN A QUOTE'S RECORD TYPE IS CHANGED TO APPROVED
                    if(outdatedQuote != null && newOrUpdatedQuote.RecordTypeId != outdatedQuote.RecordTypeId && newOrUpdatedQuote.RecordTypeId == RecordTypes.get('SBQQ__Quote__c').get('Approved')){
                        newOrUpdatedQuote.Conga_Collaborate_Template__c = 'Signable Order Form';
                        newOrUpdatedQuote.Last_Approved_Date__c = DateTime.now();
                    }

                    // RECORD TYPE FROM APPROVAL TO DRAFT UPDATES
                    if(outdatedQuote != null && newOrUpdatedQuote.RecordTypeId == RecordTypes.get('SBQQ__Quote__c').get('Draft') && 
                                                outdatedQuote.RecordTypeId == RecordTypes.get('SBQQ__Quote__c').get('Approved')){
                        newOrUpdatedQuote.SBQQ__Status__c = 'Draft';
                        newOrUpdatedQuote.ApprovalStatus__c = null;
                    }

                    // RENEWAL QUOTE AUTOMATION, ONLY ON CREATION OF A RENEWAL QUOTE
                    if(TriggerHelper.DoExecute('SBQQQuoteHelper','PBReadyRenewalQuote') && outdatedQuote == null && newOrUpdatedQuote.SBQQ__Type__c == 'Renewal'){
                        Account parentAccount = ParentAccountsMap.get(newOrUpdatedQuote.SBQQ__Account__c);

                        if(parentAccount != null){
                            newOrUpdatedQuote.OwnerId = parentAccount.OwnerId;
                        }
                    }

                    // PROCESS BUILDER: Quote Discount Change - Remove Discount Approved Status - ON EDIT ONLY
                    //////////////// DEPRECATED ////////////////
                    //if(TriggerHelper.DoExecute('SBQQQuoteHelper','PBQuoteDiscountChange') && outdatedQuote != null){

                    //    // Max Discount Is Changed - ON EDIT
                    //    if(newOrUpdatedQuote.Maximum_Discount__c != outdatedQuote.Maximum_Discount__c && newOrUpdatedQuote.Maximum_Discount__c > outdatedQuote.Maximum_Discount__c && 
                    //        newOrUpdatedQuote.Discount_Approval_Status__c != null && newOrUpdatedQuote.RecordTypeId == RecordTypes.get('SBQQ__Quote__c').get('Draft')){

                    //        // Remove Approved from Discount Approval Status
                    //        if(newOrUpdatedQuote.Discount_Approval_Status__c == 'Approved'){
                    //            newOrUpdatedQuote.Discount_Approval_Status__c = null;
                    //        }
                    //    }

                    //    // Lines Requiring Renewal Approval is Changed - ON EDIT
                    //    if(newOrUpdatedQuote.Lines_Requiring_Renewal_Approval__c != outdatedQuote.Lines_Requiring_Renewal_Approval__c && newOrUpdatedQuote.Lines_Requiring_Renewal_Approval__c > 0 && 
                    //        newOrUpdatedQuote.Discount_Approval_Status__c != null && newOrUpdatedQuote.RecordTypeId == RecordTypes.get('SBQQ__Quote__c').get('Draft')){

                    //        // Remove Approved from Discount Approval Status
                    //        if(newOrUpdatedQuote.Discount_Approval_Status__c == 'Approved'){
                    //            newOrUpdatedQuote.Discount_Approval_Status__c = null;
                    //        }
                    //    }
                    //}

                    // PROCESS BUILDER: Quote Update Bill To Fields from Account
                    if(TriggerHelper.DoExecute('SBQQQuoteHelper','PBUpdateBillToFieldsFromAccount')){
                        Account parentAccount = ParentAccountsMap.get(newOrUpdatedQuote.SBQQ__Account__c);

                        // New Direct Quote with Account Billing - CREATE ONLY
                        if(outdatedQuote == null && parentAccount != null && parentAccount.BillingContact__c != null && parentOpportunity != null && 
                            parentOpportunity.RecordTypeId == RecordTypes.get('Opportunity').get('Direct')){
                            
                            // Update Quote Bill To Fields - No Criteria
                            if(true){
                                newOrUpdatedQuote.Bill_To_Email__c = parentAccount.BillingContact__r.Email;
                                newOrUpdatedQuote.Bill_To_First_Name__c = parentAccount.BillingContact__r.FirstName;
                                newOrUpdatedQuote.Bill_To_Last_Name__c = parentAccount.BillingContact__r.LastName;
                                newOrUpdatedQuote.Bill_To_Phone__c = parentAccount.BillingContact__r.Phone;
                            }
                        }

                        // New Indirect Quote- CREATE ONLY
                        if(outdatedQuote == null && parentAccount != null && parentAccount.Billing_Party__c != null && parentAccount.Billing_Party__r.BillingContact__c != null && 
                            parentOpportunity != null && parentOpportunity.RecordTypeId == RecordTypes.get('Opportunity').get('Indirect')){
                            
                            // Update Quote Bill To - No Criteria
                            if(true){
                                newOrUpdatedQuote.Bill_To_Email__c = parentAccount.Billing_Party__r.BillingContact__r.Email;
                                newOrUpdatedQuote.Bill_To_First_Name__c = parentAccount.Billing_Party__r.BillingContact__r.FirstName;
                                newOrUpdatedQuote.Bill_To_Last_Name__c = parentAccount.Billing_Party__r.BillingContact__r.LastName;
                                newOrUpdatedQuote.Bill_To_Phone__c = parentAccount.Billing_Party__r.BillingContact__r.Phone;
                            }
                        }

                        // Renewal without Bill To Address - CREATE AND EDIT
                        if(newOrUpdatedQuote.SBQQ__Type__c == 'Renewal'){
                            
                            // Populate Bill To Fields - No Criteria
                            if(true && parentAccount != null){
                                newOrUpdatedQuote.SBQQ__BillingCity__c = parentAccount.BillingCity;
                                newOrUpdatedQuote.SBQQ__BillingCountry__c = parentAccount.BillingCountry;
                                newOrUpdatedQuote.SBQQ__BillingName__c = parentAccount.Name;
                                newOrUpdatedQuote.SBQQ__BillingPostalCode__c = parentAccount.BillingPostalCode;
                                newOrUpdatedQuote.SBQQ__BillingState__c = parentAccount.BillingState;
                                newOrUpdatedQuote.SBQQ__BillingStreet__c = parentAccount.BillingStreet;
                            }

                            // Populate Primary Contact
                            if(newOrUpdatedQuote.SBQQ__PrimaryContact__c == null && parentOpportunity != null){
                                newOrUpdatedQuote.SBQQ__PrimaryContact__c = parentOpportunity.Primary_Contact__c;
                            }
                        }
                    }

                    // PROCESS BUILDER: New Quote Term Field Mapping - Sync with Contract - CREATE ONLY
                    if(TriggerHelper.DoExecute('SBQQQuoteHelper','PBTermFieldSyncWithContract') && outdatedQuote == null && newOrUpdatedQuote.SBQQ__Opportunity2__c != null && parentOpportunity != null){
                        
                        // SET DEFAULTS
                        newOrUpdatedQuote.Auto_Renew__c = '1';
                        newOrUpdatedQuote.Expiration_Warning__c = 30;
                        newOrUpdatedQuote.Non_Payment_Late_Charge__c = 1;
                        newOrUpdatedQuote.SBQQ__PaymentTerms__c = 'Net 30';

                        // Amendment
                        if(newOrUpdatedQuote.SBQQ__Type__c == 'Amendment' && parentOpportunity.SBQQ__AmendedContract__c != null){
                            Contract parentAmendContract = ParentContractsMap.get(parentOpportunity.SBQQ__AmendedContract__c);

                            // Sync Contract Terms to Amendment - No Criteria
                            if(true){
                                newOrUpdatedQuote.Auto_Renew__c = parentAmendContract.Auto_Renew_Term__c != null ? parentAmendContract.Auto_Renew_Term__c : newOrUpdatedQuote.Auto_Renew__c;
                                newOrUpdatedQuote.Expiration_Warning__c = parentAmendContract.Expiration_Warning__c != null ? parentAmendContract.Expiration_Warning__c : newOrUpdatedQuote.Expiration_Warning__c;
                                newOrUpdatedQuote.Non_Payment_Late_Charge__c = parentAmendContract.Non_Payment_Late_Charge__c != null ? parentAmendContract.Non_Payment_Late_Charge__c : newOrUpdatedQuote.Non_Payment_Late_Charge__c;
                                newOrUpdatedQuote.SBQQ__PaymentTerms__c = String.isNotBlank(parentAmendContract.Payment_Terms_non_Net_30__c) ? parentAmendContract.Payment_Terms_non_Net_30__c : newOrUpdatedQuote.SBQQ__PaymentTerms__c;
                            }
                        }

                        // Renewal
                        if(newOrUpdatedQuote.SBQQ__Type__c == 'Renewal' && parentOpportunity.SBQQ__RenewedContract__c != null){
                            Contract parentRenewalContract = ParentContractsMap.get(parentOpportunity.SBQQ__RenewedContract__c);

                            // Sync Contract Terms for Renewal - No Criteria
                            if(true){
                                newOrUpdatedQuote.Auto_Renew__c = parentRenewalContract.Auto_Renew_Term__c != null ? parentRenewalContract.Auto_Renew_Term__c : newOrUpdatedQuote.Auto_Renew__c;
                                newOrUpdatedQuote.Expiration_Warning__c = parentRenewalContract.Expiration_Warning__c != null ? parentRenewalContract.Expiration_Warning__c : newOrUpdatedQuote.Expiration_Warning__c;
                                newOrUpdatedQuote.Non_Payment_Late_Charge__c = parentRenewalContract.Non_Payment_Late_Charge__c != null ? parentRenewalContract.Non_Payment_Late_Charge__c : newOrUpdatedQuote.Non_Payment_Late_Charge__c;
                                newOrUpdatedQuote.SBQQ__PaymentTerms__c = String.isNotBlank(parentRenewalContract.Payment_Terms_non_Net_30__c) ? parentRenewalContract.Payment_Terms_non_Net_30__c : newOrUpdatedQuote.SBQQ__PaymentTerms__c;
                            }
                        }

                        // Existing Business
                        if(newOrUpdatedQuote.SBQQ__Type__c == 'Quote' && parentOpportunity.Type == 'Existing Business' && newOrUpdatedQuote.SBQQ__Account__c != null){
                            Account parentAccount = ParentAccountsMap.get(newOrUpdatedQuote.SBQQ__Account__c);
                            
                            // Sync MSA Contract Terms - No Criteria
                            if(true && parentAccount.MSA_Contract__c != null){
                                newOrUpdatedQuote.Auto_Renew__c = parentAccount.MSA_Contract__r.Auto_Renew_Term__c != null ? parentAccount.MSA_Contract__r.Auto_Renew_Term__c : newOrUpdatedQuote.Auto_Renew__c;
                                newOrUpdatedQuote.Expiration_Warning__c = parentAccount.MSA_Contract__r.Expiration_Warning__c != null ? parentAccount.MSA_Contract__r.Expiration_Warning__c : newOrUpdatedQuote.Expiration_Warning__c;
                                newOrUpdatedQuote.Non_Payment_Late_Charge__c = parentAccount.MSA_Contract__r.Non_Payment_Late_Charge__c != null ? parentAccount.MSA_Contract__r.Non_Payment_Late_Charge__c : newOrUpdatedQuote.Non_Payment_Late_Charge__c;
                                newOrUpdatedQuote.SBQQ__PaymentTerms__c = String.isNotBlank(parentAccount.MSA_Contract__r.Payment_Terms_non_Net_30__c) ? parentAccount.MSA_Contract__r.Payment_Terms_non_Net_30__c : newOrUpdatedQuote.SBQQ__PaymentTerms__c;
                            }
                        }
                    }

                    // PROCESS BUILDER: Quote Term Approval Status Changes - EDIT ONLY
                    if(TriggerHelper.DoExecute('SBQQQuoteHelper','PBTermApprovalStatusChanges') && outdatedQuote != null){
                        
                        // Approved Quote w/ Standard MSA Terms
                        if(newOrUpdatedQuote.RecordTypeId != outdatedQuote.RecordTypeId && newOrUpdatedQuote.RecordTypeId == RecordTypes.get('SBQQ__Quote__c').get('Approved') && 
                            newOrUpdatedQuote.Auto_Renew__c == '1' && newOrUpdatedQuote.Expiration_Warning__c == 30 && newOrUpdatedQuote.Non_Payment_Late_Charge__c == 1 && 
                            newOrUpdatedQuote.SBQQ__PaymentTerms__c == 'Net 30' && (newOrUpdatedQuote.Bundle_Name__c  == 'MSA' || newOrUpdatedQuote.Bundle_Name__c == 'EMEA MSA')){

                            // Terms = Standard - No Criteria
                            if(true){
                                newOrUpdatedQuote.Terms__c = 'Standard';
                            }
                        }
                    }

                    // PROCESS BUILDER: Set Default Quote Terms by Contract/Product - EDIT ONLY
                    if(TriggerHelper.DoExecute('SBQQQuoteHelper','PBSetDefaultQuoteTerms') && outdatedQuote != null){
                        // MSA & EMEA MSA Default Terms
                        if(newOrUpdatedQuote.Bundle_Name__c != outdatedQuote.Bundle_Name__c && (newOrUpdatedQuote.Bundle_Name__c == 'EMEA MSA' || newOrUpdatedQuote.Bundle_Name__c == 'MSA') &&
                            (newOrUpdatedQuote.Expiration_Warning__c == null || newOrUpdatedQuote.SBQQ__PaymentTerms__c == 'Net 30' || newOrUpdatedQuote.Auto_Renew__c == null || 
                             newOrUpdatedQuote.Non_Payment_Late_Charge__c == null)){

                            // Auto-Renew Update
                            if(newOrUpdatedQuote.Auto_Renew__c == null){
                                newOrUpdatedQuote.Auto_Renew__c = '1';
                            }

                            // Cancellation Notice Update
                            if(newOrUpdatedQuote.Expiration_Warning__c == null){
                                newOrUpdatedQuote.Expiration_Warning__c = 30;
                            }

                            // Non-Payment Update
                            if(newOrUpdatedQuote.Non_Payment_Late_Charge__c == null){
                                newOrUpdatedQuote.Non_Payment_Late_Charge__c = 1;
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteHelper','quoteFieldUpdates');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteHelper', 'quoteFieldUpdates', newOrUpdatedQuotes, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181116
    * @description updateLeapYearFlag - Updates the Has_Leap_Year_Day__c checkbox when the SBQQ__StartDate__c or SBQQ__EndDate__c changes
    *                                    --- EXECUTED BY SBQQ QUOTE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<SBQQ__Quote__c> newOrUpdatedQuotes - List of updated Quote records
    * @param Map<Id, SBQQ__Quote__c> outdatedQuotes - Map of outdated Quote records
    * @return void
    */
    public static void updateLeapYearFlag(List<SBQQ__Quote__c> newOrUpdatedQuotes, Map<Id, SBQQ__Quote__c> outdatedQuotes){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteHelper', 'updateLeapYearFlag') && newOrUpdatedQuotes != null){
                // UPDATE QUALIFYING RECORDS
                for(SBQQ__Quote__c newOrUpdatedQuote : newOrUpdatedQuotes){
                    SBQQ__Quote__c outdatedQuote = outdatedQuotes != null ? outdatedQuotes.get(newOrUpdatedQuote.Id) : null;
                    if(outdatedQuote == null || (outdatedQuote != null && (newOrUpdatedQuote.SBQQ__StartDate__c != outdatedQuote.SBQQ__StartDate__c ||
                                                                           newOrUpdatedQuote.SBQQ__EndDate__c != outdatedQuote.SBQQ__EndDate__c))){
                        newOrUpdatedQuote.Has_Leap_Year_Day__c = UtilityClass.checkRangeForLeapYear(newOrUpdatedQuote.SBQQ__StartDate__c, newOrUpdatedQuote.SBQQ__EndDate__c);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteHelper', 'updateLeapYearFlag');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteHelper', 'updateLeapYearFlag', newOrUpdatedQuotes, ex, true);
        } 
    }

    /**
    * @author ECS, ERedding
    * @date 20191112
    * @description lockUnlockQuoteLines - Locks and Unlocks Quote Line records using record types. Determined from parent Quote Approval Status values
    *                                       --- EXECUTED BY SBQQ QUOTE AFTER UPDATE TRIGGER --- 
    * @param List<SBQQ__Quote__c> updatedQuotes - List of updated Quote records
    * @param Map<Id, SBQQ__Quote__c> outdatedQuotes - Map of outdated Quote records
    * @return void
    */
    public static void lockUnlockQuoteLines(List<SBQQ__Quote__c> updatedQuotes, Map<Id, SBQQ__Quote__c> outdatedQuotes){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteHelper', 'lockUnlockQuoteLines') && updatedQuotes != null && outdatedQuotes != null){

                // GET IDS OF QUOTES WITH QUALIFYING CHANGES
                Set<Id> qualifiedLockQuoteIds = new Set<Id>();
                Set<Id> qualifiedUnlockQuoteIds = new Set<Id>();
                for(SBQQ__Quote__c updatedQuote : updatedQuotes){
                    SBQQ__Quote__c outdatedQuote = outdatedQuotes != null ? outdatedQuotes.get(updatedQuote.Id) : null;
                    if(outdatedQuote != null && updatedQuote.RecordTypeId != outdatedQuote.RecordTypeId){
                        if(updatedQuote.RecordTypeId == RecordTypes.get('SBQQ__Quote__c').get('Pending')){
                            // LOCK QUOTE LINES
                            qualifiedLockQuoteIds.add(updatedQuote.Id);
                        }
                        else if(updatedQuote.RecordTypeId == RecordTypes.get('SBQQ__Quote__c').get('Draft')){
                            // UNLOCK QUOTE LINES
                            qualifiedUnlockQuoteIds.add(updatedQuote.Id);
                        }
                    }
                }

                List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
                if(!qualifiedLockQuoteIds.isEmpty() || !qualifiedUnlockQuoteIds.isEmpty()){

                    // GET QUOTE LINES FOR QUALIFIED PARENT QUOTES
                    Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId = new Map<Id, List<SBQQ__QuoteLine__c>>();
                    for(SBQQ__QuoteLine__c quoteLine : [SELECT Id, RecordTypeId, SBQQ__Quote__c FROM SBQQ__QuoteLine__c 
                                                        WHERE SBQQ__Quote__c IN :qualifiedLockQuoteIds OR SBQQ__Quote__c IN :qualifiedUnlockQuoteIds]){
                        if(!quoteLinesByQuoteId.containsKey(quoteLine.SBQQ__Quote__c)){
                            quoteLinesByQuoteId.put(quoteLine.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
                        }
                        quoteLinesByQuoteId.get(quoteLine.SBQQ__Quote__c).add(quoteLine);
                    }

                    // GET QUOTE LINES TO LOCK
                    if(!qualifiedLockQuoteIds.isEmpty()){
                        for(Id qualifiedLockQuoteId : qualifiedLockQuoteIds){
                            if(quoteLinesByQuoteId.containsKey(qualifiedLockQuoteId)){
                                for(SBQQ__QuoteLine__c quoteLine : quoteLinesByQuoteId.get(qualifiedLockQuoteId)){
                                    quoteLine.RecordTypeId = RecordTypes.get('SBQQ__QuoteLine__c').get('Locked');
                                    quoteLinesToUpdate.add(quoteLine);
                                }
                            }
                        }
                    }

                    // GET QUOTE LINES TO UNLOCK
                    if(!qualifiedUnlockQuoteIds.isEmpty()){
                        for(Id qualifiedUnlockQuoteId : qualifiedUnlockQuoteIds){
                            if(quoteLinesByQuoteId.containsKey(qualifiedUnlockQuoteId)){
                                for(SBQQ__QuoteLine__c quoteLine : quoteLinesByQuoteId.get(qualifiedUnlockQuoteId)){
                                    quoteLine.RecordTypeId = RecordTypes.get('SBQQ__QuoteLine__c').get('Unlocked');
                                    quoteLinesToUpdate.add(quoteLine);
                                }
                            }
                        }
                    }
                }

                // SAVE UPDATED QUOTE LINES
                if(!quoteLinesToUpdate.isEmpty()){
                    for(SBQQ__QuoteLine__c quoteLine : quoteLinesToUpdate){
                        if(ChildQuoteLinesToUpdate.containsKey(quoteLine.Id)){
                            ChildQuoteLinesToUpdate.get(quoteLine.Id).RecordTypeId = quoteLine.RecordTypeId;
                        }
                        else{
                            ChildQuoteLinesToUpdate.put(quoteLine.Id, quoteLine); 
                        }
                    }

                    //Database.saveResult[] quoteLineResults = Database.update(quoteLinesToUpdate, false);
                    //SystemIssueLogHelper.CheckForDatabaseErrors(quoteLineResults, 'SBQQQuoteHelper', 'lockUnlockQuoteLines', true);  
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteHelper', 'lockUnlockQuoteLines');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteHelper', 'lockUnlockQuoteLines', updatedQuotes, ex, true);
        } 
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181029
    * @description updateQuoteLineOppItemDates - Determines if there are applicable Quote changes that require child Quote Line updates
    *                                          --- EXECUTED BY SBQQ QUOTE AFTER UPDATE TRIGGER --- 
    * @param List<SBQQ__Quote__c> updatedQuotes - List of updated Quote records
    * @param Map<Id, SBQQ__Quote__c> outdatedQuotes - Map of outdated Quote records
    * @return void
    */
    public static void updateQuoteLineOppItemDates(List<SBQQ__Quote__c> updatedQuotes, Map<Id, SBQQ__Quote__c> outdatedQuotes){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteHelper', 'updateQuoteLineOppItemDates') && updatedQuotes != null){
                // GET IDS OF QUOTES WITH QUALIFYING CHANGES
                Set<Id> qualifiedQuoteIds = new Set<Id>();
                for(SBQQ__Quote__c updatedQuote : updatedQuotes){
                    SBQQ__Quote__c outdatedQuote = outdatedQuotes != null ? outdatedQuotes.get(updatedQuote.Id) : null;
                    if(outdatedQuote != null && (updatedQuote.SBQQ__StartDate__c != outdatedQuote.SBQQ__StartDate__c || 
                                                 updatedQuote.SBQQ__EndDate__c != outdatedQuote.SBQQ__EndDate__c ||
                                                 updatedQuote.SBQQ__SubscriptionTerm__c != outdatedQuote.SBQQ__SubscriptionTerm__c)){
                        // QUALIFIED CHANGE OCCURED, ADD ID TO SET
                        qualifiedQuoteIds.add(updatedQuote.Id);
                    }

                    if(!qualifiedQuoteIds.isEmpty()){
                        // GET SBQQ Quote Lines RECORDS WHOSE OPP ITEMS WILL NEED TO BE UPDATED
                        List<SBQQ__QuoteLine__c> quoteLinesToProcess = [SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Group__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                                                                        Opp_Item_Start_Date__c, Opp_Item_End_Date__c
                                                                        FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :qualifiedQuoteIds];

                        // CALCULATE DATES
                        quoteLinesToProcess = SBQQQuoteLineHelper.calculateOppItemStartEndDates(quoteLinesToProcess);

                        // SAVE UPDATED RECORDS
                        if(!quoteLinesToProcess.isEmpty()){
                            for(SBQQ__QuoteLine__c quoteLine : quoteLinesToProcess){
                                SBQQ__QuoteLine__c queuedRecord = ChildQuoteLinesToUpdate.get(quoteLine.Id);
                                if(queuedRecord != null){
                                    queuedRecord.Opp_Item_Start_Date__c = quoteLine.Opp_Item_Start_Date__c;
                                    queuedRecord.Opp_Item_End_Date__c = quoteLine.Opp_Item_End_Date__c;
                                    queuedRecord.Has_Leap_Year_Day__c = quoteLine.Has_Leap_Year_Day__c;
                                    queuedRecord.Subscription_Months__c = quoteLine.Subscription_Months__c;
                                    queuedRecord.Subscription_Years__c = quoteLine.Subscription_Years__c;
                                }
                                else{
                                    ChildQuoteLinesToUpdate.put(quoteLine.Id, quoteLine); 
                                }
                            }

                            //Database.saveResult[] quoteLineResults = Database.update(quoteLinesToProcess, false);
                            //SystemIssueLogHelper.CheckForDatabaseErrors(quoteLineResults, 'SBQQQuoteHelper', 'updateQuoteLineOppItemDates', true);  
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteHelper', 'updateQuoteLineOppItemDates');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteHelper', 'updateQuoteLineOppItemDates', updatedQuotes, ex, true);
        } 
    }

    /**
    * @author GTM, ERedding
    * @date 20200928
    * @description updateParentOppNoticeFields - Updates the parent opps of quotes with 60 Day Notice Status and 75 Day Notice Status values
    *                                               --- EXECUTED BY SBQQ QUOTE AFTER UPDATE TRIGGER --- 
    * @param List<SBQQ__Quote__c> updatedQuotes - List of updated Quote records
    * @param Map<Id, SBQQ__Quote__c> outdatedQuotes - Map of outdated Quote records
    * @return void
    */
    public static void updateParentOppNoticeFields(List<SBQQ__Quote__c> updatedQuotes, Map<Id, SBQQ__Quote__c> outdatedQuotes){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteHelper', 'updateParentOppNoticeFields') && updatedQuotes != null && outdatedQuotes != null){

                // GET IDS OF QUOTES WITH QUALIFYING CHANGES
                Set<Id> parentOppIds = new Set<Id>();
                for(SBQQ__Quote__c updatedQuote : updatedQuotes){
                    SBQQ__Quote__c outdatedQuote = outdatedQuotes != null ? outdatedQuotes.get(updatedQuote.Id) : null;
                    if(outdatedQuote != null && updatedQuote.SBQQ__Opportunity2__c != null && (updatedQuote.Automatic_Renewal_60_Day_Notice__c != outdatedQuote.Automatic_Renewal_60_Day_Notice__c || 
                                                                                               updatedQuote.Automatic_Renewal_75_Day_Notice__c != outdatedQuote.Automatic_Renewal_75_Day_Notice__c)){
                        // QUALIFIED CHANGE OCCURED, ADD OPP ID
                        parentOppIds.add(updatedQuote.SBQQ__Opportunity2__c);
                    }
                }

                if(!parentOppIds.isEmpty()){
                    // GET ALL QUOTES FOR QUALIFYING OPPS
                    Map<Opportunity, List<SBQQ__Quote__c>> quotesByOpp = new Map<Opportunity, List<SBQQ__Quote__c>>();
                    for(SBQQ__Quote__c quote : [SELECT Id, Automatic_Renewal_60_Day_Notice__c, Automatic_Renewal_75_Day_Notice__c, CreatedDate,
                                                SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Automatic_Renewal_60_Day_Notice__c, SBQQ__Opportunity2__r.Automatic_Renewal_75_Day_Notice__c
                                                FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :parentOppIds]){

                        if(!quotesByOpp.containsKey(quote.SBQQ__Opportunity2__r)){
                            quotesByOpp.put(quote.SBQQ__Opportunity2__r, new List<SBQQ__Quote__c>());
                        }
                        quotesByOpp.get(quote.SBQQ__Opportunity2__r).add(quote);
                    }

                    if(!quotesByOpp.isEmpty()){
                        List<Opportunity> oppsToUpdate = new List<Opportunity>();
                        for(Opportunity opp : quotesByOpp.keySet()){
                            String oppNoticeStatus60Days = '';
                            String oppNoticeStatus75Days = '';
                            for(SBQQ__Quote__c quote : quotesByOpp.get(opp)){

                                // GET THE 60 DAY STATUS FURTHEST IN THE PROGRESSION OF   CREATED --> SENT --> VIEWED
                                if(String.isBlank(oppNoticeStatus60Days) && quote.Automatic_Renewal_60_Day_Notice__c == 'Created'){
                                    oppNoticeStatus60Days = quote.Automatic_Renewal_60_Day_Notice__c;
                                }
                                else if((String.isBlank(oppNoticeStatus60Days) || oppNoticeStatus60Days == 'Created') && quote.Automatic_Renewal_60_Day_Notice__c == 'Sent'){
                                    oppNoticeStatus60Days = quote.Automatic_Renewal_60_Day_Notice__c;
                                }
                                else if((String.isBlank(oppNoticeStatus60Days) || oppNoticeStatus60Days == 'Sent') && quote.Automatic_Renewal_60_Day_Notice__c == 'Viewed'){
                                    oppNoticeStatus60Days = quote.Automatic_Renewal_60_Day_Notice__c;
                                }

                                // GET THE 75 DAY STATUS FURTHEST IN THE PROGRESSION OF   CREATED --> SENT --> VIEWED
                                if(String.isBlank(oppNoticeStatus75Days) && quote.Automatic_Renewal_75_Day_Notice__c == 'Created'){
                                    oppNoticeStatus75Days = quote.Automatic_Renewal_75_Day_Notice__c;
                                }
                                else if((String.isBlank(oppNoticeStatus75Days) || oppNoticeStatus75Days == 'Created') && quote.Automatic_Renewal_75_Day_Notice__c == 'Sent'){
                                    oppNoticeStatus75Days = quote.Automatic_Renewal_75_Day_Notice__c;
                                }
                                else if((String.isBlank(oppNoticeStatus75Days) || oppNoticeStatus75Days == 'Sent') && quote.Automatic_Renewal_75_Day_Notice__c == 'Viewed'){
                                    oppNoticeStatus75Days = quote.Automatic_Renewal_75_Day_Notice__c;
                                }
                            }

                            if(opp.Automatic_Renewal_60_Day_Notice__c != oppNoticeStatus60Days || opp.Automatic_Renewal_75_Day_Notice__c != oppNoticeStatus75Days){
                                opp.Automatic_Renewal_60_Day_Notice__c = oppNoticeStatus60Days;
                                opp.Automatic_Renewal_75_Day_Notice__c = oppNoticeStatus75Days;
                                oppsToUpdate.add(opp);
                            }
                        }

                        // UPDATE OPPS
                        if(!oppsToUpdate.isEmpty()){
                            Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'SBQQQuoteHelper', 'updateParentOppNoticeFields', true);  
                        }
                    }  
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteHelper', 'updateParentOppNoticeFields');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteHelper', 'updateParentOppNoticeFields', updatedQuotes, ex, true);
        } 
    }

    /**
    * @author Conga Services, ERedding
    * @date 20190201
    * @description validateStateAndCountry - Validate State and Country values on Billing and Shipping addresses
    *                                         --- EXECUTED BY SBQQ QUOTE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---    
    * @param List<SBQQ__Quote__c> newOrUpdatedContacts - New or Updated SBQQ__Quote records
    * @param Map<Id, SBQQ__Quote__c> outdatedContacts - Outdated SBQQ__Quote records
    * @return void
    */
    public static void validateStateAndCountry(List<SBQQ__Quote__c> newOrUpdatedQuotes, Map<Id, SBQQ__Quote__c> outdatedQuotes){
        try{      
            if(TriggerHelper.DoExecute('SBQQQuoteHelper', 'validateStateAndCountry') && newOrUpdatedQuotes != null){
                // GET QUOTES WITH QUALIFYING CHANGES
                List<SBQQ__Quote__c> qualifiedQuotes = new List<SBQQ__Quote__c>();
                for(SBQQ__Quote__c newOrUpdatedQuote : newOrUpdatedQuotes){
                    SBQQ__Quote__c outdatedQuote = outdatedQuotes != null ? outdatedQuotes.get(newOrUpdatedQuote.Id) : null;
                    if(outdatedQuote == null || (outdatedQuote != null && (newOrUpdatedQuote.SBQQ__BillingState__c != outdatedQuote.SBQQ__BillingState__c || 
                                                                           newOrUpdatedQuote.SBQQ__BillingCountry__c != outdatedQuote.SBQQ__BillingCountry__c ||
                                                                           newOrUpdatedQuote.SBQQ__ShippingState__c != outdatedQuote.SBQQ__ShippingState__c ||
                                                                           newOrUpdatedQuote.SBQQ__ShippingCountry__c != outdatedQuote.SBQQ__ShippingCountry__c))){
                        qualifiedQuotes.add(newOrUpdatedQuote);
                    }
                }

                if(!qualifiedQuotes.isEmpty()){
                    // GET QUALIFYING USER PROFILES
                    Map<Id, Profile> bypassProfiles = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Name IN ('System Administrator', 'Conga Sales Ops User')]);

                    // ONLY PERFORM VALIDATION FOR NON BYPASSED PROFILES
                    if(!bypassProfiles.containsKey(UserInfo.getProfileId())){

                        // GET STATE AND COUNTRY FIELDS NAMES
                        Map<String,String> countryStateFieldPairs = new Map<String,String>{ SBQQ__Quote__c.SBQQ__BillingCountry__c.getDescribe().getName() => 
                                                                                            SBQQ__Quote__c.SBQQ__BillingState__c.getDescribe().getName(), 
                                                                                            SBQQ__Quote__c.SBQQ__ShippingCountry__c.getDescribe().getName() => 
                                                                                            SBQQ__Quote__c.SBQQ__ShippingState__c.getDescribe().getName() };
                        for(SBQQ__Quote__c quote : qualifiedQuotes){
                            StateAndCountryValidation.validateRecordCountryStatePairs(quote, countryStateFieldPairs);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteHelper', 'validateStateAndCountry');                
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('SBQQQuoteHelper', 'validateStateAndCountry', newOrUpdatedQuotes, ex, true);
        }
    }


}