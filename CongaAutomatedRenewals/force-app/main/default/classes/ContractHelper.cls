/**
* @author Conga Services
* @date 20181022
* @version 1.00
* @description ContractHelper - Custom functionality for the Contract object
*/
public with sharing class ContractHelper {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// STATIC VARIABLES //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // PARENT OPPORTUNITY UPDATE QUEUE
    public static Map<Id, Opportunity> ParentOppsToUpdate {
    get {
        if(ParentOppsToUpdate == null){
            ParentOppsToUpdate = new Map<Id, Opportunity>();
        }
        return ParentOppsToUpdate;
    } set; }


    // PARENT ACCOUNTS MAP AND ID SET
    public static Set<Id> ParentAccountIds {get; set;}
    private static Map<Id, Account> ParentAccountsMap {
    get {
        if(ParentAccountsMap == null){
            ParentAccountsMap = new Map<Id, Account>();
            for(Account account : [SELECT Id, Name FROM Account WHERE Id IN :ParentAccountIds]){
                ParentAccountsMap.put(account.Id, account);
            }
        }
        return ParentAccountsMap;
    } set; }

    // PARENT OPPORTUNITIES MAP AND ID SET
    public static Set<Id> ParentOppIds {get; set;}
    private static Map<Id, Opportunity> ParentOppsMap {
    get {
        if(ParentOppsMap == null){
            ParentOppsMap = new Map<Id, Opportunity>();
            for(Opportunity opp : [SELECT Id, RecordTypeId, Customer_Org_Id__c FROM Opportunity WHERE Id IN :ParentOppIds]){
                ParentOppsMap.put(opp.Id, opp);
            }
        }
        return ParentOppsMap;
    } set; }

    // PARENT CONTRACTS MAP AND ID SET
    public static Set<Id> ParentQuoteIds {get; set;}
    private static Map<Id, SBQQ__Quote__c> ParentQuotesMap {
    get {
        if(ParentQuotesMap == null){
            ParentQuotesMap = new Map<Id, SBQQ__Quote__c>();
            for(SBQQ__Quote__c quote : [SELECT Id, Auto_Renew__c, Expiration_Warning__c, Non_Payment_Late_Charge__c, SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE Id IN :ParentQuoteIds]){
                ParentQuotesMap.put(quote.Id, quote);
            }
        }
        return ParentQuotesMap;
    } set; }


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// TRIGGER / HELPER METHODS /////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /**
    * @author ECS, ERedding
    * @date 20191023
    * @description contractFieldUpdates - Code replacements for various Contract Process Builder Field Updates
    *                                       ****** EXECUTED FROM CONTRACT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ******
    * @param List<Contract> newOrUpdatedContracts - New or Updated Contract records
    * @param Map<Id,Contract> outdatedContracts - Outdated Contract records
    * @return void
    */
    public static void contractFieldUpdates(List<Contract> newOrUpdatedContracts, Map<Id,Contract> outdatedContracts){
        try{
            if(TriggerHelper.DoExecute('ContractHelper','contractFieldUpdates') && newOrUpdatedContracts != null){ // MASTER CONTROL

                // GET CONTRACT CUSTOMER SUBSCRIPTION RECORD TYPE
                Id customerSubscriptionRTId = UtilityClass.getRecordTypesForObject('Contract').get('Customer_Subscription');

                // MAKE QUALIFYING CHANGES
                for(Contract newOrUpdatedContract : newOrUpdatedContracts){
                    Contract outdatedContract = outdatedContracts != null  ? outdatedContracts.get(newOrUpdatedContract.Id) : null;

                    //// PROCESS BUILDER: Contract Initializer - ON CREATE ONLY
                    if(TriggerHelper.DoExecute('ContractHelper','PBContractInitializer') && outdatedContract == null){
                        // GET PARENT OPP
                        Opportunity parentOpp = ParentOppsMap != null ? ParentOppsMap.get(newOrUpdatedContract.SBQQ__Opportunity__c) : null;

                        // Oppty Lookup Not Null
                        if(newOrUpdatedContract.RecordTypeId == customerSubscriptionRTId && newOrUpdatedContract.SBQQ__Opportunity__c != null && parentOpp != null){

                            // set renewal and amend oppty rec types
                            newOrUpdatedContract.SBQQ__AmendmentOpportunityRecordTypeId__c = parentOpp.RecordTypeId;
                            newOrUpdatedContract.SBQQ__RenewalOpportunityRecordTypeId__c = parentOpp.RecordTypeId;
                        }

                        // Record Type = customer subscription
                        if(newOrUpdatedContract.RecordTypeId == customerSubscriptionRTId){
                            // GET PARENT QUOTE
                            SBQQ__Quote__c parentQuote = ParentQuotesMap != null ? ParentQuotesMap.get(newOrUpdatedContract.SBQQ__Quote__c) : null;

                            // Set Various Fields
                            newOrUpdatedContract.Customer_Org_Id__c = parentOpp != null && String.isNotBlank(parentOpp.Customer_Org_Id__c) ? parentOpp.Customer_Org_Id__c : null;
                            newOrUpdatedContract.SBQQ__RenewalOpportunityStage__c = 'Pending Renewal';
                            //newOrUpdatedContract.SBQQ__RenewalForecast__c = true; // ER 20200103 - NOW DONE IN A QUEUEABLE IN METHOD contractForecastQueueable
                            
                            // Populate Terms
                            if(newOrUpdatedContract.SBQQ__Quote__c != null && parentQuote != null){
                                // GET PARENT ACCOUNT
                                Account parentAccount = ParentAccountsMap != null ? ParentAccountsMap.get(newOrUpdatedContract.AccountId) : null;

                                newOrUpdatedContract.Auto_Renew_Term__c = String.isNotBlank(parentQuote.Auto_Renew__c) ? parentQuote.Auto_Renew__c : '';
                                newOrUpdatedContract.Contract_Type__c = 'Customer Subscription';
                                newOrUpdatedContract.Expiration_Warning__c = parentQuote.Expiration_Warning__c == null || parentQuote.Expiration_Warning__c == 0 ? null : parentQuote.Expiration_Warning__c;
                                newOrUpdatedContract.Name = (parentAccount.Name + ' - Customer Subscription Contract' + String.valueOf(newOrUpdatedContract.StartDate)).left(80).trim();
                                newOrUpdatedContract.Non_Payment_Late_Charge__c = parentQuote.Non_Payment_Late_Charge__c == null || parentQuote.Non_Payment_Late_Charge__c == 0 ? null : parentQuote.Non_Payment_Late_Charge__c;
                                newOrUpdatedContract.Payment_Terms_non_Net_30__c = String.isNotBlank(parentQuote.SBQQ__PaymentTerms__c) ? parentQuote.SBQQ__PaymentTerms__c : '';
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('ContractHelper','contractFieldUpdates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('ContractHelper', 'contractFieldUpdates', newOrUpdatedContracts, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20191125
    * @description setPORequired - Copies the PO Required value down from the parent opp on new Contracts and up to the parent Opp on updated Contracts
    *                                ****** EXECUTED BY CONTRACT BEFORE INSERT AND AFTER UPDATE TRIGGERS ******
    * @param List<Contract> newOrUpdatedContracts - New or updated Contract records
    * @param Map<Id, Contract> outdatedContracts - Outdated Contract records
    * @return void
    */
    public static void setPORequired(List<Contract> newOrUpdatedContracts, Map<Id, Contract> outdatedContracts){
        try{
            if(TriggerHelper.DoExecute('ContractHelper','setPORequired') && newOrUpdatedContracts != null){
                Set<Id> parentOppIds = new Set<Id>();
                for(Contract newOrUpdatedContract : newOrUpdatedContracts){
                    Contract outdatedContract = outdatedContracts != null ? outdatedContracts.get(newOrUpdatedContract.Id) : null;

                    if(outdatedContract == null || newOrUpdatedContract.Purchase_Order_Required__c != outdatedContract.Purchase_Order_Required__c){
                        // NEW CONTRACT OR PO REQUIRED WAS CHANGED
                        if(newOrUpdatedContract.SBQQ__Opportunity__c != null || newOrUpdatedContract.SBQQ__RenewalOpportunity__c != null){
                            parentOppIds.add(newOrUpdatedContract.SBQQ__Opportunity__c);
                            parentOppIds.add(newOrUpdatedContract.SBQQ__RenewalOpportunity__c);  
                        }
                    }
                }

                if(!parentOppIds.isEmpty()){
                    // GET PARENT OPP RECORDS
                    Map<Id, Opportunity> parentOpps = new Map<Id, Opportunity>([SELECT Id, Purchase_Order_Required__c FROM Opportunity WHERE Id IN :parentOppIds]);
                    
                    // PULL DOWN
                    if(outdatedContracts == null || outdatedContracts.isEmpty()){
                        for(Contract newContract : newOrUpdatedContracts){
                            if(parentOpps.containsKey(newContract.SBQQ__Opportunity__c) && parentOpps.get(newContract.SBQQ__Opportunity__c).Purchase_Order_Required__c){
                                newContract.Purchase_Order_Required__c = true;
                            }
                        }
                    }
                    // PUSH UP
                    else{
                        List<Opportunity> oppsToUpdate = new List<Opportunity>();
                        for(Contract updatedContract : newOrUpdatedContracts){
                            if(parentOpps.containsKey(updatedContract.SBQQ__RenewalOpportunity__c)){
                                oppsToUpdate.add(new Opportunity(Id = updatedContract.SBQQ__RenewalOpportunity__c, Purchase_Order_Required__c = updatedContract.Purchase_Order_Required__c));
                            }
                        }

                        // QUEUE PARENT OPPORTUNITIES FOR UPDATE
                        if(!oppsToUpdate.isEmpty()){
                            for(Opportunity opp : oppsToUpdate){
                                if(ParentOppsToUpdate.containsKey(opp.Id)){
                                    ParentOppsToUpdate.get(opp.Id).Purchase_Order_Required__c = opp.Purchase_Order_Required__c;
                                }
                                else{
                                    ParentOppsToUpdate.put(opp.Id, opp); 
                                }
                            }
                        }

                        //Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                        //SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'ContractHelper', 'setPORequired', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('ContractHelper','setPORequired');
            }   
        }   
        catch(Exception ex){
            SystemIssueLogHelper.LogException('ContractHelper', 'setPORequired', newOrUpdatedContracts, ex, true);
        }       
    }

    /**
    * @author ECS, ERedding
    * @date 20191023
    * @description recalculateOppCurrentMRR - Checks for Contracts where the Renewal Opportunity has changed and sends off the related Subscriptions for Current MRR recalculation.
    * @param Map<Id, Contract> updatedContracts - Updated Contract records
    * @param Map<Id, Contract> outdatedContracts - Outdated Contract records
    * @return void
    */
    public static void recalculateOppCurrentMRR(Map<Id, Contract> updatedContracts, Map<Id, Contract> outdatedContracts){
        try{
            if(TriggerHelper.DoExecute('ContractHelper','recalculateOppCurrentMRR') && updatedContracts != null){
                Set<Id> qualifiedContractIds = new Set<Id>();
                for(Contract updatedContract : updatedContracts.values()){
                    Contract outdatedContract = outdatedContracts != null ? outdatedContracts.get(updatedContract.Id) : null;
                    if(outdatedContract != null && updatedContract.SBQQ__RenewalOpportunity__c != outdatedContract.SBQQ__RenewalOpportunity__c){
                        // RENEWAL OPP ON THE CONTRACT HAS CHANGED, CONTRACT QUALIFIES
                        qualifiedContractIds.add(updatedContract.Id);
                    }
                }

                if(!qualifiedContractIds.isEmpty()){
                    // GET ALL SUBSCRIPTIONS RELATED TO QUALIFIED CONTRACTS
                    List<SBQQ__Subscription__c> subscriptionsToProcess = [SELECT Id, SBQQ__NetPrice__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Contract__c
                                                                          FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN :qualifiedContractIds];

                    if(!subscriptionsToProcess.isEmpty()){
                        // SEND OFF SUBSCRIPTIONS TO THE SBQQSubscriptionHelper.calculateOppCurrentAverageMRR TRIGGER OVERLOAD METHOD
                        List<Opportunity> oppsToUpdate = SBQQSubscriptionHelper.calculateOppCurrentAverageMRR(subscriptionsToProcess, updatedContracts);

                        // QUEUE PARENT OPPORTUNITIES FOR UPDATE
                        if(!oppsToUpdate.isEmpty()){
                            for(Opportunity opp : oppsToUpdate){
                                if(ParentOppsToUpdate.containsKey(opp.Id)){
                                    Map<String, Object> populatedFields = opp.getPopulatedFieldsAsMap();
                                    System.debug(populatedFields);
                                    for(String fieldName : populatedFields.keySet()){
                                        ParentOppsToUpdate.get(opp.Id).put(fieldName, opp.get(fieldName));
                                    }
                                }
                                else{
                                    ParentOppsToUpdate.put(opp.Id, opp); 
                                }
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('ContractHelper','recalculateOppCurrentMRR');
            }   
        }   
        catch(Exception ex){
            SystemIssueLogHelper.LogException('ContractHelper', 'recalculateOppCurrentMRR', updatedContracts, ex, true);
        }       
    }


}