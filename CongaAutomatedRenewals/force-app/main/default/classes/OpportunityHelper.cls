/**
* @author Conga Services
* @date 20160524
* @version 1.00
* @description OpportunityHelper - Custom functionality for the Opportunity object 
*/
global without sharing class OpportunityHelper {
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// STATIC VARIABLES //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // TERRITORY MANAGEMENT TEAM MEMBER ROLE NAME CONSTANTS
    public static final String TMROLENAME = TerritoryManagementHelper.TMROLENAME;
    public static final String CLMROLENAME = TerritoryManagementHelper.CLMROLENAME;
    public static final String CSMROLENAME = TerritoryManagementHelper.CSMROLENAME;
    public static final String RMROLENAME = TerritoryManagementHelper.RMROLENAME;
    public static final String BDRROLENAME = TerritoryManagementHelper.BDRROLENAME;
    public static final String SDRROLENAME = TerritoryManagementHelper.SDRROLENAME;
    public static final String SEROLENAME = TerritoryManagementHelper.SEROLENAME;

    // OPP RECORD TYPES
    public static Map<String, Map<String, Id>> RecordTypes {
    get {
        if(RecordTypes == null){
            RecordTypes = UtilityClass.getRecordTypesForObjects(new List<String>{ 'Opportunity', 'PS_Project__c', 'Asset' });
        }
        return RecordTypes;
    } set; }

    // OPP CHILD ITEMS
    public static Set<Id> OppIds {get; set;}
    private static Map<Id, List<OpportunityLineItem>> OppItemsByOppId {
    get {
        if(OppItemsByOppId == null){
            OppItemsByOppId = new Map<Id, List<OpportunityLineItem>>();
            for(OpportunityLineItem oppItem : [SELECT Id, OpportunityId, Product2Id, Product2.Name, Product2.Hourly_Rate__c, Product2.LOB__c, Product2.FY16_Revenue_Type__c,
                                               Product2.Product_Line__c, Quantity, UnitPrice, Product2.Hours__c, PricebookEntryId, PricebookEntry.Pricebook2Id 
                                               FROM OpportunityLineItem WHERE OpportunityId IN :OppIds]){
                if(!OppItemsByOppId.containsKey(oppItem.OpportunityId)){
                    OppItemsByOppId.put(oppItem.OpportunityId, new List<OpportunityLineItem>());
                }
                OppItemsByOppId.get(oppItem.OpportunityId).add(oppItem);
            }
        }
        return OppItemsByOppId;
    } set; }

    // OPP PARTNER AUTOMATION SETTINGS METADATA
    private static Opp_Partner_Automation_Settings__mdt OppPartnerAutomationSettings {
    get {
        if(OppPartnerAutomationSettings == null){
            if(Test.isRunningTest()){
               OppPartnerAutomationSettings = OpportunityHelperTest.OppPartnerAutomationTestMeta;
               return OppPartnerAutomationSettings;
            }
            OppPartnerAutomationSettings = [SELECT Primary_Partner_Req_Stages__c, Primary_Partner_Req_Product_Lines__c, Add_Products_Qualifying_for_PS_Project__c,
                                                   Conga_Partner_Account_Id__c
                                            FROM Opp_Partner_Automation_Settings__mdt LIMIT 1];
        }
        return OppPartnerAutomationSettings;
    } set; }
    
    // OPP PARTNER REP MAPPING METADATA
    private static List<Opp_Partner_Rep_Mapping__mdt> OppPartnerRepMappings {
    get {
        if(OppPartnerRepMappings == null){
            if(Test.isRunningTest()){
                OppPartnerRepMappings = OpportunityHelperTest.OppPartnerRepMappingTestMeta;
                return OppPartnerRepMappings;
            }
            OppPartnerRepMappings = [SELECT AccountId__c, Team__c, Partner_Rep__c FROM Opp_Partner_Rep_Mapping__mdt];
        }
        return OppPartnerRepMappings;
    } set; }

    // OPP PARTNER REP MAPPING METADATA
    private static List<Opportunity_Onboarding_Specialists__mdt> OppOnboardingSpecialists {
    get {
        if(OppOnboardingSpecialists == null){
            if(Test.isRunningTest()){
                OppOnboardingSpecialists = OpportunityHelperTest.OppOnboardingSpecialistsTestMeta;
                return OppOnboardingSpecialists;
            }
            OppOnboardingSpecialists = [SELECT Onboarding_Specialist__c, Team__c, Default__c, US_Zip_Start__c, US_Zip_End__c FROM Opportunity_Onboarding_Specialists__mdt
                                        ORDER BY MasterLabel];
        }
        return OppOnboardingSpecialists;
    } set; }

    // OPPORTUNITY CLOSED WON STATUSES
    private static Set<String> ClosedWonStatuses {
    get {
        if(ClosedWonStatuses == null){
            ClosedWonStatuses = new Set<String>();
            for(OpportunityStage stage : [SELECT Id, ApiName FROM OpportunityStage WHERE IsClosed = true AND IsWon = true AND IsActive = true]){
                ClosedWonStatuses.add(stage.ApiName);
            }
        }
        return ClosedWonStatuses;
    } set; }

    // OPPORTUNITY OPEN STATUSES
    private static Set<String> OpenStatuses {
    get {
        if(OpenStatuses == null){
            OpenStatuses = new Set<String>();
            for(OpportunityStage stage : [SELECT Id, ApiName FROM OpportunityStage WHERE IsClosed = false AND IsActive = true]){
                OpenStatuses.add(stage.ApiName);
            }
        }
        return OpenStatuses;
    } set; }

    // OPPORTUNITY PARENT ACCOUNTS MAP AND ID SET
    public static Set<Id> ParentAccountIds {get; set;}
    private static Map<Id, Account> ParentAccountsMap {
    get {
        if(ParentAccountsMap == null){
            ParentAccountsMap = new Map<Id, Account>();
            for(Account account : [SELECT Id, Name, OwnerId, Customer_likely_to__c, Owner.Role_Stamp__c, Owner.Region__c, Owner.Team__c, TM_Territory_ManagerId__c,
                                          BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                          ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                                    FROM Account WHERE Id IN :ParentAccountIds]){
                ParentAccountsMap.put(account.Id, account);
            }
        }
        return ParentAccountsMap;
    } set; }

    // OPPORTUNITY PARENT SALESFORCE ACCOUNTS MAP AND ID SET
    public static Set<Id> ParentSalesforceAccountIds {get; set;}
    private static Map<Id, Salesforce_Account__c> ParentSalesforceAccountsMap {
    get {
        if(ParentSalesforceAccountsMap == null){
            ParentSalesforceAccountsMap = new Map<Id, Salesforce_Account__c>();
            for(Salesforce_Account__c acct : [SELECT Id, Name, Salesforce_AE_Email__c, Salesforce_AE_First_Name__c, Salesforce_AE_Last_Name__c, Salesforce_AE_Phone_Number__c, 
                                              Salesforce_SE_Email__c, Salesforce_SE_First_Name__c, Salesforce_SE_Last_Name__c, Salesforce_SE_Manager__c, Salesforce_SE_Phone_Number__c,
                                              Salesforce_AE_RVP_Lookup__c, Salesforce_AE_RVP_Lookup__r.FirstName, Salesforce_AE_RVP_Lookup__r.LastName, Salesforce_AE_RVP_Lookup__r.Email
                                              FROM Salesforce_Account__c WHERE Id IN :ParentSalesforceAccountIds]){
                ParentSalesforceAccountsMap.put(acct.Id, acct);
            }
        }
        return ParentSalesforceAccountsMap;
    } set; }

    // OPPORTUNITY PARENT CONTRACTS MAP AND ID SET
    public static Set<Id> PrimaryImplementationPartnerIds {get; set;}
    private static Map<Id, Account> PrimaryImplementationPartnerMap {
    get {
        if(PrimaryImplementationPartnerMap == null){
            PrimaryImplementationPartnerMap = new Map<Id, Account>();
            for(Account account : [SELECT Id, Active_Partner_Profile__c, Active_Partner_Profile__r.Total_Revenue_All_Time__c, Owner_Full_Name__c,
                                           Active_Partner_Profile__r.of_Conga_implementations_done__c
                                    FROM Account WHERE Id IN :PrimaryImplementationPartnerIds]){
                PrimaryImplementationPartnerMap.put(account.Id, account);
            }
        }
        return PrimaryImplementationPartnerMap;
    } set; }

    // OPPORTUNITY PARENT CONTRACTS MAP AND ID SET
    public static Set<Id> ParentContractIds {get; set;}
    private static Map<Id, Contract> ParentContractsMap {
    get {
        if(ParentContractsMap == null){
            ParentContractsMap = new Map<Id, Contract>();
            for(Contract contract : [SELECT Id, ContractNumber, Entity_Code__c, Legacy_Billing_Frequency__c, Legacy_Payment_Method__c, Purchase_Order_Required__c
                                     FROM Contract WHERE Id IN :ParentContractIds]){
                ParentContractsMap.put(contract.Id, contract);
            }
        }
        return ParentContractsMap;
    } set; }

    // OPPORTUNITY PARENT LEAD MAP AND ID SET
    public static Set<Id> ParentLeadIds {get; set;}
    private static Map<Id, Lead> ParentLeadsMap {
    get {
        if(ParentLeadsMap == null){
            ParentLeadsMap = new Map<Id, Lead>();
            for(Lead lead : [SELECT Id, Channel_Source_2__c, Product_Interest__c FROM Lead WHERE Id IN :ParentLeadIds]){
                ParentLeadsMap.put(lead.Id, lead);
            }
        }
        return ParentLeadsMap;
    } set; }

    // OPPORTUNITY USERS MAP AND ID SET
    public static Set<Id> OppUserIds {get; set;}
    @testVisible
    private static Map<Id, User> OppUsersMap {
    get {
        if(OppUsersMap == null){
            OppUsersMap = new Map<Id, User>([SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id IN :OppUserIds]);
        }
        return OppUsersMap;
    } set; }


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// TRIGGER / HELPER METHODS /////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * @author eredding
    * @description opportunityFieldUpdates - Code replacements for various Opportunity Process Builder Field Updates
    *                                          ***** EXECUTED FROM BEFORE INSERT AND BEFORE UPDATE TRIGGERS *****
    * @param List<Opportunity> newOrUpdatedOpps - New or Updated Opportunity records
    * @param Map<Id,Opportunity> outdatedOpps - Outdated Opportunity records
    * @return void
    */
    public static void opportunityFieldUpdates(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','opportunityFieldUpdates')){ // MASTER CONTROL

                // MAKE QUALIFYING CHANGES
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;

                    //// POPULATE SDR__c WHEN CREATED BY AN SDR OR BDR
                    if(outdatedOpp == null && newOrUpdatedOpp.SDR__c == null && OppUsersMap.containsKey(UserInfo.getUserId())){
                        String currentUserRole = OppUsersMap.get(UserInfo.getUserId()).UserRole.Name;
                        if(currentUserRole.contains('Business Development Representative') || currentUserRole.contains('Sales Development Representative')){
                            newOrUpdatedOpp.SDR__c = UserInfo.getUserId();
                        }
                    }

                    //// RENEWAL OPP "MRR NNMRR REPORTDATE OVERRIDE" STAMP
                    if(outdatedOpp != null && newOrUpdatedOpp.Type == 'Renewal' && newOrUpdatedOpp.StageName != outdatedOpp.StageName){
                        if(newOrUpdatedOpp.StageName == 'Closed Lost' && newOrUpdatedOpp.MRR_Sub_Start__c != null && newOrUpdatedOpp.MRR_Sub_Start__c <= Date.today().addDays(-1)){
                            newOrUpdatedOpp.MRR_NNMRR_REPORTDATE_OVERRIDE__c = Date.today();
                        }
                        else if(outdatedOpp.StageName == 'Closed Lost' && newOrUpdatedOpp.MRR_NNMRR_REPORTDATE_OVERRIDE__c != null){
                            newOrUpdatedOpp.MRR_NNMRR_REPORTDATE_OVERRIDE__c = null;
                        }
                    }

                    //// BOOKINGS DATE FORMULA TO CODE CONVERSION
                    if(outdatedOpp == null || (outdatedOpp != null && (newOrUpdatedOpp.Bookings_Date_Apex__c != outdatedOpp.Bookings_Date_Apex__c ||
                                                                       newOrUpdatedOpp.Bookings_Date_Override__c != outdatedOpp.Bookings_Date_Override__c ||
                                                                       newOrUpdatedOpp.MRR_Sub_Start__c != outdatedOpp.MRR_Sub_Start__c ||
                                                                       newOrUpdatedOpp.Type != outdatedOpp.Type ||
                                                                       newOrUpdatedOpp.Net_New_MRR__c != outdatedOpp.Net_New_MRR__c ||
                                                                       newOrUpdatedOpp.CloseDate != outdatedOpp.CloseDate))){

                        // IF A QUALIFIED CHANGE IS MADE UPDATE Bookings_Date_Apex__c FIELD
                        if(newOrUpdatedOpp.Bookings_Date_Override__c != null){
                            newOrUpdatedOpp.Bookings_Date_Apex__c = newOrUpdatedOpp.Bookings_Date_Override__c;
                        }
                        else if(newOrUpdatedOpp.Type == 'New Business' || newOrUpdatedOpp.Type == 'Existing Business'){
                            newOrUpdatedOpp.Bookings_Date_Apex__c = newOrUpdatedOpp.CloseDate; 
                        }
                        else if(newOrUpdatedOpp.Type == 'Renewal' && !newOrUpdatedOpp.IsClosed){
                            newOrUpdatedOpp.Bookings_Date_Apex__c = newOrUpdatedOpp.MRR_Sub_Start__c; 
                        }
                        else if(newOrUpdatedOpp.Type == 'Renewal' && newOrUpdatedOpp.Net_New_MRR__c <= 0 && newOrUpdatedOpp.MRR_Sub_Start__c != null){
                            // GET THE LAST DAY OF THE MRR_Sub_Start__c MONTH
                            Date subStartLastDay = Date.newInstance(newOrUpdatedOpp.MRR_Sub_Start__c.year(), newOrUpdatedOpp.MRR_Sub_Start__c.month()+1, 1).addDays(-1);
                            
                            if(UtilityClass.getDistanceBetweenDates(subStartLastDay, newOrUpdatedOpp.CloseDate, UtilityClass.Interval.Days, 0) <= 30){
                                newOrUpdatedOpp.Bookings_Date_Apex__c = newOrUpdatedOpp.MRR_Sub_Start__c; 
                            }
                        }
                        else{
                            newOrUpdatedOpp.Bookings_Date_Apex__c = newOrUpdatedOpp.CloseDate;
                        }
                    }

                    //// PROCESS BUILDER: Oppty set "Contracted" - Created or Edited
                    if(TriggerHelper.DoExecute('OpportunityHelper','PBOpptySetContracted')){
                        // Sales Ops Approved = True
                        if(newOrUpdatedOpp.Sales_Ops_Approved__c && newOrUpdatedOpp.SBQQ__PrimaryQuote__c != null && newOrUpdatedOpp.Sub_Type__c != 'Forecasting Opportunity' &&
                            (outdatedOpp == null || (outdatedOpp != null && (newOrUpdatedOpp.Sales_Ops_Approved__c != outdatedOpp.Sales_Ops_Approved__c ||
                                                                            newOrUpdatedOpp.SBQQ__PrimaryQuote__c != outdatedOpp.SBQQ__PrimaryQuote__c)))){
                            newOrUpdatedOpp.SBQQ__Contracted__c = true;
                        }     
                    }

                    //// PROCESS BUILDER: Last Won/Lost Deal Date Updates - Edited Only since PB used IsChanged operator
                    if(TriggerHelper.DoExecute('OpportunityHelper','PBLastWonLostDealDateUpdates') && outdatedOpp != null){
                        // Stage is Changed and Won
                        if(newOrUpdatedOpp.StageName == 'Closed Won' && (newOrUpdatedOpp.StageName != outdatedOpp.StageName || newOrUpdatedOpp.CloseDate != outdatedOpp.CloseDate)){

                            // Sales Ops Approved = Not Reviewed - No Criteria
                            if(true){
                                newOrUpdatedOpp.Sales_Ops_Approved_Status__c = 'Not Reviewed';
                            }  
                        }
                    }

                    //// PROCESS BUILDER: OPPORTUNITY: Update Salesforce Contact Info v5 - Edited Only since PB used IsChanged operator
                    if(TriggerHelper.DoExecute('OpportunityHelper','PBUpdateSalesforceContactInfo') && outdatedOpp != null){

                        // Salesforce Account Populated or Changed
                        if(newOrUpdatedOpp.Salesforce_Account__c != null && newOrUpdatedOpp.Salesforce_Account__c != outdatedOpp.Salesforce_Account__c){
                            Salesforce_Account__c parentSalesforceAccount = ParentSalesforceAccountsMap.get(newOrUpdatedOpp.Salesforce_Account__c);

                            // NEW CORE FIELDS
                            newOrUpdatedOpp.Salesforce_Core_AE__c = parentSalesforceAccount.Salesforce_AE_First_Name__c + ' ' + parentSalesforceAccount.Salesforce_AE_Last_Name__c;
                            newOrUpdatedOpp.Salesforce_Core_SE__c = parentSalesforceAccount.Salesforce_SE_First_Name__c + ' ' + parentSalesforceAccount.Salesforce_SE_Last_Name__c;

                            // ORIGINAL FIELDS
                            newOrUpdatedOpp.Salesforce_AE_Email__c = parentSalesforceAccount.Salesforce_AE_Email__c;
                            newOrUpdatedOpp.Salesforce_AE_First_Name__c = parentSalesforceAccount.Salesforce_AE_First_Name__c;
                            newOrUpdatedOpp.Salesforce_AE_Last_Name__c = parentSalesforceAccount.Salesforce_AE_Last_Name__c;
                            newOrUpdatedOpp.Salesforce_AE_Phone_Number__c = parentSalesforceAccount.Salesforce_AE_Phone_Number__c;
                            newOrUpdatedOpp.Salesforce_SE_Email__c = parentSalesforceAccount.Salesforce_SE_Email__c;
                            newOrUpdatedOpp.Salesforce_SE_First_Name__c = parentSalesforceAccount.Salesforce_SE_First_Name__c;
                            newOrUpdatedOpp.Salesforce_SE_Last_Name__c = parentSalesforceAccount.Salesforce_SE_Last_Name__c;
                            newOrUpdatedOpp.Salesforce_SE_Manager__c = parentSalesforceAccount.Salesforce_SE_Manager__c;
                            newOrUpdatedOpp.Salesforce_SE_Phone_Number__c = parentSalesforceAccount.Salesforce_SE_Phone_Number__c;
                            newOrUpdatedOpp.Salesforce_Account_Text__c = parentSalesforceAccount.Name;

                            if(parentSalesforceAccount.Salesforce_AE_RVP_Lookup__c != null){
                                newOrUpdatedOpp.SF_AE_RVP_Email__c = parentSalesforceAccount.Salesforce_AE_RVP_Lookup__r.Email;
                                newOrUpdatedOpp.Salesforce_AE_RVP__c = parentSalesforceAccount.Salesforce_AE_RVP_Lookup__r.FirstName + ' ' + parentSalesforceAccount.Salesforce_AE_RVP_Lookup__r.LastName;
                            }
                            else{
                                newOrUpdatedOpp.SF_AE_RVP_Email__c = null;
                                newOrUpdatedOpp.Salesforce_AE_RVP__c = null;
                            }
                        }

                        // AE Posture Changed
                        if(newOrUpdatedOpp.Salesforce_AE_Posture__c != outdatedOpp.Salesforce_AE_Posture__c){

                            ////////////////////// ECS EREDDING 20200720 - DEPRECATED, FUNCTIONALITY NO LONGER IN USE //////////////////////
                            // Update AE Attached and First Touch
                            //if(outdatedOpp.Salesforce_AE_Posture__c == 'None - Not Engaged'){
                            //    newOrUpdatedOpp.AE_Attached__c = true;
                            //    newOrUpdatedOpp.AE_First_Touch__c = Date.today();                                  
                            //}

                            // Update AE Posture Date
                            newOrUpdatedOpp.Salesforce_AE_Posture_Date_Change__c = String.isNotBlank(newOrUpdatedOpp.Salesforce_AE_Posture__c) ? Date.today() : null;
                        }

                        // Salesforce Account NOT Populated
                        if(newOrUpdatedOpp.Salesforce_Account__c == null && newOrUpdatedOpp.Salesforce_Account__c != outdatedOpp.Salesforce_Account__c){
                            // NEW CORE FIELDS
                            newOrUpdatedOpp.Salesforce_Core_AE__c = null;
                            newOrUpdatedOpp.Salesforce_Core_SE__c = null;

                            // ORIGINAL FIELDS
                            newOrUpdatedOpp.Salesforce_AE_Email__c = null;
                            newOrUpdatedOpp.Salesforce_AE_First_Name__c = null;
                            newOrUpdatedOpp.Salesforce_AE_Last_Name__c = null;
                            newOrUpdatedOpp.Salesforce_AE_Phone_Number__c = null;
                            newOrUpdatedOpp.Salesforce_SE_Email__c = null;
                            newOrUpdatedOpp.Salesforce_SE_First_Name__c = null;
                            newOrUpdatedOpp.Salesforce_SE_Last_Name__c = null;
                            newOrUpdatedOpp.Salesforce_SE_Manager__c = null;
                            newOrUpdatedOpp.Salesforce_SE_Phone_Number__c = null;
                            newOrUpdatedOpp.SF_AE_RVP_Email__c = null;
                            newOrUpdatedOpp.Salesforce_AE_RVP__c = null;
                            newOrUpdatedOpp.Salesforce_Account_Text__c = null;
                        }
                    }

                    //// PROCESS BUILDER: createAssetFromLineItem - Created and Edited
                    if(TriggerHelper.DoExecute('OpportunityHelper','PBCreateAssetsFromLineItems')){
                        
                        // Sales Ops Approved Status
                        if(newOrUpdatedOpp.Sales_Ops_Approved_Status__c != null && newOrUpdatedOpp.Sales_Ops_Approved__c){

                            // Sales Ops Approved Status = Approved - No Criteria
                            if(true){
                                newOrUpdatedOpp.Sales_Ops_Approved_Status__c = 'Approved';
                            }  
                        }
                    }

                    //// PROCESS BUILDER: OPPORTUNITY: On Create - Create Only
                    if(TriggerHelper.DoExecute('OpportunityHelper','PBOnCreate') && outdatedOpp == null){

                        // Opp Initializer - No Criteria
                        if(true){
                            Account parentAccount = ParentAccountsMap.get(newOrUpdatedOpp.AccountId);
                            Contract parentAmendedContract = ParentContractsMap.get(newOrUpdatedOpp.SBQQ__AmendedContract__c);
                            
                            // CPQ Renew Opp
                            if(newOrUpdatedOpp.Name.contains('Renewal') && newOrUpdatedOpp.SBQQ__Renewal__c){
                                newOrUpdatedOpp.LeadSource = 'Renewal';
                                newOrUpdatedOpp.Name = parentAccount.Name.left(50) + ' Renewal ' + (newOrUpdatedOpp.CloseDate != null ? String.valueOf(newOrUpdatedOpp.CloseDate) : '');
                                //newOrUpdatedOpp.Opportunity_Owner_Role_Stamp__c = parentAccount.Owner.Role_Stamp__c + ' - ' + parentAccount.Owner.Region__c; //// ER 20190826 FIELD DEPRECATED
                                //newOrUpdatedOpp.OwnerId = parentAccount.OwnerId; //// ER 20200117 REPLACED BY TM AND TEAMS CODE
                                //newOrUpdatedOpp.Team__c = parentAccount.Owner.Team__c; //// ER 20190826 FIELD DEPRECATED
                                newOrUpdatedOpp.Type = 'Renewal';
                            }

                            // CPQ Amend Opp
                            if(parentAccount != null && newOrUpdatedOpp.Name.contains('Amendment') && newOrUpdatedOpp.SBQQ__AmendedContract__c != null){
                                newOrUpdatedOpp.Name = (parentAccount.Name.left(40) + ' Amend ' + parentAmendedContract.ContractNumber + (newOrUpdatedOpp.CloseDate != null ? '-' + String.valueOf(newOrUpdatedOpp.CloseDate) : '')).left(80);
                                newOrUpdatedOpp.Type = 'Existing Business';
                            }

                            // Default - New Business
                            if(newOrUpdatedOpp.Type == null){
                                newOrUpdatedOpp.Type = 'New Business';
                            }
                        }

                        // Opp Created via Lead Conversion
                        if(newOrUpdatedOpp.Lead_Opp_Conversion__c && newOrUpdatedOpp.Entity_Code__c == null){
                            newOrUpdatedOpp.Entity_Code__c = 'Conga';
                        }

                        // Amend Contract
                        if(newOrUpdatedOpp.SBQQ__AmendedContract__c != null && ParentContractsMap.containsKey(newOrUpdatedOpp.SBQQ__AmendedContract__c)){
                            Contract parentAmendedContract = ParentContractsMap.get(newOrUpdatedOpp.SBQQ__AmendedContract__c);

                            // Update Oppty Fields
                            newOrUpdatedOpp.Entity_Code__c = String.isNotBlank(parentAmendedContract.Entity_Code__c) ? parentAmendedContract.Entity_Code__c : 'Conga';
                            newOrUpdatedOpp.Legacy_Billing_Frequency__c = parentAmendedContract.Legacy_Billing_Frequency__c;
                            newOrUpdatedOpp.Legacy_Payment_Method__c = parentAmendedContract.Legacy_Payment_Method__c;
                        }
                    }

                    //// PROCESS BUILDER: OPPORTUNITY: On Create or Edit - Created or Edited
                    if(TriggerHelper.DoExecute('OpportunityHelper','PBOnCreateOrEdit')){

                        // SE Assigned Changed
                        if(outdatedOpp != null && newOrUpdatedOpp.SE_Assigned2__c != outdatedOpp.SE_Assigned2__c){
                            // Update SE Assigned Date
                            newOrUpdatedOpp.SE_Assigned_Date__c = String.isNotBlank(newOrUpdatedOpp.SE_Assigned2__c) ? Date.today() : null;
                        }

                        // Set Probability Dates
                        if(outdatedOpp == null || newOrUpdatedOpp.Probability != outdatedOpp.Probability || newOrUpdatedOpp.X15_Date__c != outdatedOpp.X15_Date__c ||
                                                  newOrUpdatedOpp.X35_Date__c != outdatedOpp.X35_Date__c || newOrUpdatedOpp.X50_Date__c != outdatedOpp.X50_Date__c ||
                                                  newOrUpdatedOpp.X75_Date__c != outdatedOpp.X75_Date__c || newOrUpdatedOpp.X90_Date__c != outdatedOpp.X90_Date__c){
                            // Set Date - 15%
                            if(newOrUpdatedOpp.Probability >= 15 && newOrUpdatedOpp.X15_Date__c == null){
                                newOrUpdatedOpp.X15_Date__c = Date.today();
                            }

                            // Set Date - 35%
                            if(newOrUpdatedOpp.Probability >= 35 && newOrUpdatedOpp.X35_Date__c == null){
                                newOrUpdatedOpp.X35_Date__c = Date.today();
                            }

                            // Set Date - 50%
                            if(newOrUpdatedOpp.Probability >= 50 && newOrUpdatedOpp.X50_Date__c == null){
                                newOrUpdatedOpp.X50_Date__c = Date.today();
                            }

                            // Set Date - 75%
                            if(newOrUpdatedOpp.Probability >= 75 && newOrUpdatedOpp.X75_Date__c == null){
                                newOrUpdatedOpp.X75_Date__c = Date.today();
                            }

                            // Set Date - 90%
                            if(newOrUpdatedOpp.Probability >= 90 && newOrUpdatedOpp.X90_Date__c == null){
                                newOrUpdatedOpp.X90_Date__c = Date.today();
                            }
                        }

                        // Payment Connect Updates
                        if(newOrUpdatedOpp.pymt__Paid_Off__c && newOrUpdatedOpp.Date_Paid__c == null && (newOrUpdatedOpp.Type_of_Credit_Card__c == 'Discover' || 
                                                                                                         newOrUpdatedOpp.Type_of_Credit_Card__c == 'MasterCard' || 
                                                                                                         newOrUpdatedOpp.Type_of_Credit_Card__c == 'Visa' || 
                                                                                                         newOrUpdatedOpp.Type_of_Credit_Card__c == 'Amex')){
                            // Updates for all - No Criteria
                            if(true){
                                newOrUpdatedOpp.Amount_Paid__c = UtilityClass.replaceNull(newOrUpdatedOpp.Amount, 0.00) + 
                                                                 UtilityClass.replaceNull(newOrUpdatedOpp.pymt__Shipping__c, 0.00) + 
                                                                 UtilityClass.replaceNull(newOrUpdatedOpp.pymt__Tax__c, 0.00);

                                newOrUpdatedOpp.Date_Paid__c = Date.today();
                                newOrUpdatedOpp.StageName = 'Closed Won';
                            }

                            // Updates for AMEX
                            if(newOrUpdatedOpp.Type_of_Credit_Card__c == 'Amex'){
                                newOrUpdatedOpp.Payment_Method__c = 'AMEX';
                            }

                            // Updates for Discover, MC, Visa
                            if(newOrUpdatedOpp.Type_of_Credit_Card__c != 'Amex'){
                                newOrUpdatedOpp.Payment_Method__c = 'Visa/MC/Discover';
                            }
                        }

                        // Oppty Owner Changed
                        if(OppUsersMap.containsKey(newOrUpdatedOpp.OwnerId) && OppUsersMap.get(newOrUpdatedOpp.OwnerId).UserRole != null &&
                            (outdatedOpp == null || newOrUpdatedOpp.OwnerId != outdatedOpp.OwnerId)){

                            String oppOwnerRole = OppUsersMap.get(newOrUpdatedOpp.OwnerId).UserRole.Name;
                            newOrUpdatedOpp.Lead_Gen_Source__c = (oppOwnerRole.contains('Outbound') ? 'Outbound' : 
                                                                  oppOwnerRole.contains('Inbound') ? 'Inbound' : 
                                                                  oppOwnerRole.contains('Territory Manager') ? 'Territory Manager' : 
                                                                  oppOwnerRole.contains('Customer Success') ? 'Customer Success' : 
                                                                  oppOwnerRole.contains('Inside Sales') ? 'Inside Sales' : 'Other');
                        }

                        // Closed Won Indirect
                        Map<String, Id> oppRecordTypes = RecordTypes.get('Opportunity');                        
                        if(newOrUpdatedOpp.StageName == 'Closed Won' && newOrUpdatedOpp.RecordTypeId == oppRecordTypes.get('Indirect') &&
                            newOrUpdatedOpp.Billing_Party__c != null){

                            Account parentAccount = ParentAccountsMap.get(newOrUpdatedOpp.AccountId);
                            Account parentBillingParty = ParentAccountsMap.get(newOrUpdatedOpp.Billing_Party__c);

                            // BillingAddressOverride
                            if(parentAccount != null && parentBillingParty != null && newOrUpdatedOpp.Billing_Address_Override__c == null){
                                newOrUpdatedOpp.Billing_Address_Override__c = parentAccount.Name + '\r\nC/O ' + parentBillingParty.Name + '\r\n' + parentBillingParty.BillingStreet + '\r\n' + 
                                                                              parentBillingParty.BillingCity + ',' + parentBillingParty.BillingState + ' ' + parentBillingParty.BillingPostalCode + 
                                                                              '\r\n' + parentBillingParty.BillingCountry;
                            }
                        }

                        // CONSULTING PARTNER PRIMARY FIELD POPULATION/UPDATES
                        if(outdatedOpp == null || newOrUpdatedOpp.ImplementationPartnerPrimary__c != outdatedOpp.ImplementationPartnerPrimary__c){
                            Account impPartnerPrimary = PrimaryImplementationPartnerMap.get(newOrUpdatedOpp.ImplementationPartnerPrimary__c);

                            if(newOrUpdatedOpp.ImplementationPartnerPrimary__c != null && impPartnerPrimary != null){
                                newOrUpdatedOpp.Consulting_Partner_Account_Owner__c = impPartnerPrimary.Owner_Full_Name__c;
                            }
                            else{
                                newOrUpdatedOpp.Consulting_Partner_Account_Owner__c = null;
                            }
                        }

                        // Partner Lifetime Referred Revenue/Deals
                        if(outdatedOpp != null && newOrUpdatedOpp.ImplementationPartnerPrimary__c != null && 
                           newOrUpdatedOpp.ImplementationPartnerPrimary__c != outdatedOpp.ImplementationPartnerPrimary__c){

                            Account impPartnerPrimary = PrimaryImplementationPartnerMap.get(newOrUpdatedOpp.ImplementationPartnerPrimary__c);    
                            if(impPartnerPrimary != null && impPartnerPrimary.Active_Partner_Profile__c != null &&
                                (impPartnerPrimary.Active_Partner_Profile__r.Total_Revenue_All_Time__c != null || impPartnerPrimary.Active_Partner_Profile__r.of_Conga_implementations_done__c != null)){

                                // POPULATE Partner Lifetime Referred Revenue AND Partner Lifetime Referred Deals
                                newOrUpdatedOpp.Partner_Lifetime_Referred_Revenue__c = impPartnerPrimary.Active_Partner_Profile__r.Total_Revenue_All_Time__c;
                                newOrUpdatedOpp.Partner_Lifetime_Referred_Deals__c = impPartnerPrimary.Active_Partner_Profile__r.of_Conga_implementations_done__c;
                            }
                        }

                        // POPULATE PROJECT ADDRESS FIELDS - USED FOR CONGA SIGN WRITEBACK
                        if(outdatedOpp == null || newOrUpdatedOpp.AccountId != outdatedOpp.AccountId){
                            Account parentAccount = ParentAccountsMap.get(newOrUpdatedOpp.AccountId);
                            if(parentAccount != null){
                                // PROJECT BILLING ADDRESS FIELDS
                                newOrUpdatedOpp.Project_Billing_Street__c = parentAccount.BillingStreet != null ? parentAccount.BillingStreet.replace('\r', '').replace('\n', '. ') : null;
                                newOrUpdatedOpp.Project_Billing_City__c = parentAccount.BillingCity;
                                newOrUpdatedOpp.Project_Billing_State__c = parentAccount.BillingState;
                                newOrUpdatedOpp.Project_Billing_Postal_Code__c = parentAccount.BillingPostalCode;

                                // PROJECT SHIPING ADDRESS FIELDS
                                newOrUpdatedOpp.Project_Shipping_Street__c = parentAccount.ShippingStreet != null ? parentAccount.ShippingStreet.replace('\r', '').replace('\n', '. ') : null;
                                newOrUpdatedOpp.Project_Shipping_City__c = parentAccount.ShippingCity;
                                newOrUpdatedOpp.Project_Shipping_State__c = parentAccount.ShippingState;
                                newOrUpdatedOpp.Project_Shipping_Postal_Code__c = parentAccount.ShippingPostalCode;
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'opportunityFieldUpdates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'opportunityFieldUpdates', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190725
    * @description updateBookingsOwner - Updates the Booking Owner stamp on new Opps or updated Opps with qualifying changes
    *                                     --- EXECUTED BY OPPORTUNITY BEFORE INSERT and BEFORE UPDATE TRIGGER ---
    * @param List<Opportunity> newOrUpdatedOpps - List of new or updated Opportunities
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunities
    * @return void
    */
    public static void updateBookingsOwner(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','updateBookingsOwner') && newOrUpdatedOpps != null){

                // UPDATE QUALIFYING OPPS                
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                    if(outdatedOpp == null || newOrUpdatedOpp.Type != outdatedOpp.Type || newOrUpdatedOpp.LeadSource != outdatedOpp.LeadSource || newOrUpdatedOpp.OwnerId != outdatedOpp.OwnerId ||
                       newOrUpdatedOpp.TM_Territory_ManagerId__c != outdatedOpp.TM_Territory_ManagerId__c || newOrUpdatedOpp.Net_New_MRR__c != outdatedOpp.Net_New_MRR__c){
                        
                        // IF A QUALIFIED CHANGE IS MADE UPDATE the Bookings_OwnerId__c FIELD
                        if(newOrUpdatedOpp.Type == 'Renewal' && newOrUpdatedOpp.LeadSource == 'Territory Manager' && newOrUpdatedOpp.Net_New_MRR__c > 0){
                            newOrUpdatedOpp.Bookings_OwnerId__c = newOrUpdatedOpp.TM_Territory_ManagerId__c;
                        }
                        else{
                            newOrUpdatedOpp.Bookings_OwnerId__c = newOrUpdatedOpp.OwnerId;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'updateBookingsOwner');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityHelper', 'updateBookingsOwner', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190909
    * @description validateOwnershipChanges - 
    *                             --- EXECUTED BY OPPORTUNITY BEFORE UPDATE TRIGGER ---
    * @param List<Opportunity> updatedOpps - List of updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunity records 
    * @return void
    */
    public static void validateOwnershipChanges(List<Opportunity> updatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','validateOwnershipChanges') && updatedOpps != null && outdatedOpps != null){
                
                // TURN OFF THIS TRIGGER METHOD SO IT ONLY FIRES ONCE WITHIN A TRANSACTION
                if(!Test.isRunningTest()){
                    TriggerHelper.TemporaryOverride('OpportunityHelper','validateOwnershipChanges', false);
                }

                // GET PARENT USERS FROM QUALIFYING OPPS
                Set<Id> parentUserIds = new Set<Id>();
                for(Opportunity updatedOpp : updatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(updatedOpp.Id) : null;
                    if(outdatedOpp != null && (updatedOpp.OwnerId != outdatedOpp.OwnerId ||
                                               updatedOpp.TM_Territory_ManagerId__c != outdatedOpp.TM_Territory_ManagerId__c ||
                                               updatedOpp.Customer_Success_ManagerId__c != outdatedOpp.Customer_Success_ManagerId__c)){
                        parentUserIds.add(updatedOpp.OwnerId);
                        parentUserIds.add(outdatedOpp.OwnerId);
                        parentUserIds.add(updatedOpp.TM_Territory_ManagerId__c);
                        parentUserIds.add(outdatedOpp.TM_Territory_ManagerId__c);
                        parentUserIds.add(updatedOpp.Customer_Success_ManagerId__c);
                        parentUserIds.add(outdatedOpp.Customer_Success_ManagerId__c);
                    }
                }

                // REMOVE ANY NULLS FROM SET
                parentUserIds.remove(null);

                if(!parentUserIds.isEmpty()){
                    // GET PROFILE, ROLE, AND USER EXEMPTIONS
                    Set<Id> exemptOwnerChangeIds = new Set<Id>();
                    Set<Id> exemptTMChangeIds = new Set<Id>();
                    Set<Id> exemptCSMChangeIds = new Set<Id>();
                    List<Ownership_Validation_Exemptions_Opps__mdt> exemptionMetadata = [SELECT Owner_Changes_Exempt_Profiles__c, Owner_Changes_Exempt_Roles__c, Owner_Changes_Exempt_Users__c,
                                                                                                 TM_Changes_Exempt_Profiles__c, TM_Changes_Exempt_Roles__c, TM_Changes_Exempt_Users__c,
                                                                                                 CSM_Changes_Exempt_Profiles__c, CSM_Changes_Exempt_Roles__c, CSM_Changes_Exempt_Users__c
                                                                                          FROM Ownership_Validation_Exemptions_Opps__mdt LIMIT 1];

                    if(!exemptionMetadata.isEmpty()){
                        String ownerExemptions = UtilityClass.replaceNull(exemptionMetadata[0].Owner_Changes_Exempt_Profiles__c, '') + '\r\n' +
                                                 UtilityClass.replaceNull(exemptionMetadata[0].Owner_Changes_Exempt_Roles__c, '') + '\r\n' +
                                                 UtilityClass.replaceNull(exemptionMetadata[0].Owner_Changes_Exempt_Users__c, '');
                        String territoryManagerExemptions = UtilityClass.replaceNull(exemptionMetadata[0].TM_Changes_Exempt_Profiles__c, '') + '\r\n' +
                                                            UtilityClass.replaceNull(exemptionMetadata[0].TM_Changes_Exempt_Roles__c, '') + '\r\n' +
                                                            UtilityClass.replaceNull(exemptionMetadata[0].TM_Changes_Exempt_Users__c, '');
                        String customerSuccessManagerExemptions = UtilityClass.replaceNull(exemptionMetadata[0].CSM_Changes_Exempt_Profiles__c, '') + '\r\n' +
                                                                  UtilityClass.replaceNull(exemptionMetadata[0].CSM_Changes_Exempt_Roles__c, '') + '\r\n' +
                                                                  UtilityClass.replaceNull(exemptionMetadata[0].CSM_Changes_Exempt_Users__c, '');

                        // PROFILE EXEMPTIONS
                        for(String ownerExemptionEntry : ownerExemptions.replace('\r','').split('\n')){
                            String exemptId = ownerExemptionEntry.left(18);
                            if(UtilityClass.validateId(exemptId)){
                                exemptOwnerChangeIds.add(exemptId);
                            }
                        }

                        // ROLE EXEMPTIONS
                        for(String territoryManagerExemptionEntry : territoryManagerExemptions.replace('\r','').split('\n')){
                            String exemptId = territoryManagerExemptionEntry.left(18);
                            if(UtilityClass.validateId(exemptId)){
                                exemptTMChangeIds.add(exemptId);
                            }
                        }

                        // USER EXEMPTIONS
                        for(String customerSuccessExemptionEntry : customerSuccessManagerExemptions.replace('\r','').split('\n')){
                            String exemptId = customerSuccessExemptionEntry.left(18);
                            if(UtilityClass.validateId(exemptId)){
                                exemptCSMChangeIds.add(exemptId);
                            }
                        }
                    }
                    
                    // GET PARENT USERS
                    Map<Id, User> parentUsers = new Map<Id, User>([SELECT Id, ManagerId FROM User WHERE Id IN :parentUserIds]);

                    // ERROR MESSAGE
                    String errorMessage = ' Please reach out to Sales Ops for Account Owner, Customer Success Manager or Territory Manager field changes.';

                    // VALIDATE OPP OWNERSHIP CHANGES
                    for(Opportunity updatedOpp : updatedOpps){
                        Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(updatedOpp.Id) : null;
                        if(outdatedOpp != null){
                            Id userProfileId = UserInfo.getProfileId();
                            Id userRoleId = UserInfo.getUserRoleId();
                            Id userId = UserInfo.getUserId();

                            // BLOCK IF OWNER CHANGE NOT ALLOWED
                            if(updatedOpp.OwnerId != outdatedOpp.OwnerId &&
                                userId != outdatedOpp.OwnerId && userId != parentUsers.get(outdatedOpp.OwnerId).ManagerId &&                     
                                !exemptOwnerChangeIds.contains(userProfileId) && !exemptOwnerChangeIds.contains(userRoleId) && !exemptOwnerChangeIds.contains(userId)){
                                
                                updatedOpp.addError(errorMessage);
                            }

                            // BLOCK IF TM TERRITORY MANAGER CHANGE NOT ALLOWED
                            if(outdatedOpp.TM_Territory_ManagerId__c != null && updatedOpp.TM_Territory_ManagerId__c != outdatedOpp.TM_Territory_ManagerId__c && 
                                userId != outdatedOpp.TM_Territory_ManagerId__c && userId != parentUsers.get(outdatedOpp.TM_Territory_ManagerId__c).ManagerId &&                     
                                !exemptTMChangeIds.contains(userProfileId) && !exemptTMChangeIds.contains(userRoleId) && !exemptTMChangeIds.contains(userId)){

                                updatedOpp.addError(errorMessage);
                            }

                            // BLOCK IF CUSTOMER SUCCESS MANAGER CHANGE NOT ALLOWED
                            if(outdatedOpp.Customer_Success_ManagerId__c != null && updatedOpp.Customer_Success_ManagerId__c != outdatedOpp.Customer_Success_ManagerId__c && 
                                userId != outdatedOpp.Customer_Success_ManagerId__c && userId != parentUsers.get(outdatedOpp.Customer_Success_ManagerId__c).ManagerId &&                     
                                !exemptCSMChangeIds.contains(userProfileId) && !exemptCSMChangeIds.contains(userRoleId) && !exemptCSMChangeIds.contains(userId)){

                                updatedOpp.addError(errorMessage);
                            }                                
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'validateOwnershipChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'validateOwnershipChanges', updatedOpps, ex, true);
        }
    }

  /**
    * @author ECS, ERedding
    * @date 20191028
    * @description validateStageChanges - Validates specific opp stage changes
    *                                       --- EXECUTED BY OPPORTUNITY BEFORE UPDATE TRIGGER ---
    * @param List<Opportunity> updatedOpps - List of updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunity records 
    * @return void
    */
    public static void validateStageChanges(List<Opportunity> updatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','validateStageChanges') && updatedOpps != null && outdatedOpps != null && OppPartnerAutomationSettings != null){
                Set<String> applicableStages = new Set<String>(OppPartnerAutomationSettings.Primary_Partner_Req_Stages__c.replace('\r','').split('\n'));

                // GET QUALIFYING OPPS
                List<Opportunity> qualifyingOpps = new List<Opportunity>();
                for(Opportunity updatedOpp : updatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(updatedOpp.Id) : null;
                    if(outdatedOpp != null && updatedOpp.ImplementationPartnerPrimary__c == null && updatedOpp.StageName != outdatedOpp.StageName && applicableStages.contains(updatedOpp.StageName) &&
                        (updatedOpp.Type == 'New Business' || updatedOpp.Cross_Sell_Ave_MRR_Total__c > 0)){
                        qualifyingOpps.add(updatedOpp);
                    }
                }

                if(!qualifyingOpps.isEmpty()){

                    // GET CHILD ITEMS
                    Map<Id, List<OpportunityLineItem>> oppItemsByOppId = new Map<Id, List<OpportunityLineItem>>();
                    for(OpportunityLineItem oppItem : [SELECT Id, OpportunityId, Product_LineFx__c FROM OpportunityLineItem WHERE OpportunityId IN :qualifyingOpps]){
                        if(!oppItemsByOppId.containsKey(oppItem.OpportunityId)){
                            oppItemsByOppId.put(oppItem.OpportunityId, new List<OpportunityLineItem>());
                        }
                        oppItemsByOppId.get(oppItem.OpportunityId).add(oppItem);
                    }

                    Set<String> applicableProductLines = new Set<String>(OppPartnerAutomationSettings.Primary_Partner_Req_Product_Lines__c.replace('\r','').split('\n'));

                    // CHECK IF STAGE CHANGE IS VALID
                    if(!oppItemsByOppId.isEmpty()){
                        for(Opportunity updatedOpp : qualifyingOpps){
                            if(oppItemsByOppId.containsKey(updatedOpp.Id)){
                                for(OpportunityLineItem oppItem : oppItemsByOppId.get(updatedOpp.Id)){
                                    if(oppItem.Product_LineFx__c != null && applicableProductLines.contains(oppItem.Product_LineFx__c)){
                                        updatedOpp.ImplementationPartnerPrimary__c.addError('Implementation Partner - Primary is required for this Opportunity.');
                                    }
                                }
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'validateStageChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'validateStageChanges', updatedOpps, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20200117
    * @description setUpOpportunityTeam - Sets up a new Opportunity's team by copying the memebers from the parent Account
    *                                   --- EXECUTED BY OPPORTUNITY AFTER INSERT TRIGGER ---
    * @param List<Opportunity> newOrUpdatedOpps - List of new or updated Opportunity records
    * @return void
    */
    public static void setUpOpportunityTeam(List<Opportunity> newOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','setUpOpportunityTeam') && newOpps != null){
                // GET ACOCUNT IDS FROM OPPS
                Set<Id> parentAccountIds = new Set<Id>();
                for(Opportunity newOpp : newOpps){
                    parentAccountIds.add(newOpp.AccountId);
                }

                // POPULATE ACCOUNT TEAM MEMBERS BY ACCOUNT MAP
                Map<Id, List<AccountTeamMember>> teamMembersByAcct = new Map<Id, List<AccountTeamMember>>();
                for(AccountTeamMember acctMember : [SELECT Id, AccountId, TeamMemberRole, UserId FROM AccountTeamMember
                                                    WHERE AccountId IN :parentAccountIds ORDER BY CreatedDate DESC]){
                    if(!teamMembersByAcct.containsKey(acctMember.AccountId)){
                        teamMembersByAcct.put(acctMember.AccountId, new List<AccountTeamMember>());
                    }
                    teamMembersByAcct.get(acctMember.AccountId).add(acctMember);
                }

                // POPULATE OPPORTUNITY OPP OWNER MEMBERS BY OPPORTUNITY MAP
                Map<Id, OpportunityTeamMember> oppOwnerMembersByOpp = new Map<Id, OpportunityTeamMember>();
                for(OpportunityTeamMember oppMember : [SELECT Id, OpportunityId, TeamMemberRole, UserId FROM OpportunityTeamMember 
                                                        WHERE TeamMemberRole = 'Opportunity Owner' AND OpportunityId IN :newOpps]){
                    oppOwnerMembersByOpp.put(oppMember.OpportunityId, oppMember);
                }

                List<OpportunityTeamMember> oppsTMsToCreate = new List<OpportunityTeamMember>();
                Map<Id, OpportunityTeamMember> oppsTMsToUpdate = new Map<Id, OpportunityTeamMember>();
                for(Opportunity newOpp : newOpps){

                    // GET PARENT ACCOUNT TEAM MEMBERS 
                    Id acctTMMemberId;
                    Id acctCLMMemberId;
                    Id acctCSMMemberId;
                    Id acctRMMemberId;
                    if(teamMembersByAcct.containsKey(newOpp.AccountId)){
                        for(AccountTeamMember acctMember : teamMembersByAcct.get(newOpp.AccountId)){
                            if(acctMember.TeamMemberRole == TMROLENAME && acctTMMemberId == null){
                                acctTMMemberId = acctMember.UserId;
                            }
                            if(acctMember.TeamMemberRole == CLMROLENAME && acctCLMMemberId == null){
                                acctCLMMemberId = acctMember.UserId;
                            }

                            if(acctMember.TeamMemberRole == CSMROLENAME && acctCSMMemberId == null){
                                acctCSMMemberId = acctMember.UserId;
                            }

                            if(acctMember.TeamMemberRole == RMROLENAME && acctRMMemberId == null){
                                acctRMMemberId = acctMember.UserId;
                            }
                        }
                    }

                    // GET OPP OWNER MEMBER
                    OpportunityTeamMember oppOwnerMember = (oppOwnerMembersByOpp.containsKey(newOpp.Id) ? oppOwnerMembersByOpp.get(newOpp.Id) : null);

                    // CREATE TM MEMBER
                    if(acctTMMemberId != null){
                        // UPDATE OPP OWNER MEMBER IF IT EXISTS AND USER MATCHES THE TM
                        if(oppOwnerMember != null && oppOwnerMember.UserId == acctTMMemberId){
                            oppOwnerMember.TeamMemberRole = TMROLENAME;
                            oppsTMsToUpdate.put(oppOwnerMember.Id, oppOwnerMember);
                        }
                        // ELSE JUST CREATE A NEW TM MEMBER
                        else{
                            oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = newOpp.Id, UserId = acctTMMemberId, TeamMemberRole = TMROLENAME));                                               
                        }
                    }
                    
                    // CREATE CLM MEMBER
                    if(acctCLMMemberId != null){
                        // UPDATE OPP OWNER MEMBER IF IT EXISTS AND USER MATCHES THE CLM
                        if(oppOwnerMember != null && oppOwnerMember.UserId == acctCLMMemberId){
                            oppOwnerMember.TeamMemberRole = CLMROLENAME;
                            oppsTMsToUpdate.put(oppOwnerMember.Id, oppOwnerMember);
                        }
                        // ELSE JUST CREATE A NEW TM MEMBER
                        else{
                            oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = newOpp.Id, UserId = acctCLMMemberId, TeamMemberRole = CLMROLENAME));
                        }
                    }

                    // CREATE SDR/BDR MEMBER
                    if(newOpp.SDR__c != null && OppUsersMap.containsKey(newOpp.CreatedById)){
                        if(OppUsersMap.get(newOpp.CreatedById).UserRole.Name.contains('Business Development Representative')){
                            oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = newOpp.Id, UserId = newOpp.SDR__c, TeamMemberRole = BDRROLENAME));
                        }
                        else if(OppUsersMap.get(newOpp.CreatedById).UserRole.Name.contains('Sales Development Representative')){
                            oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = newOpp.Id, UserId = newOpp.SDR__c, TeamMemberRole = SDRROLENAME)); 
                        }
                    }

                    // CREATE SE MEMBER
                    if(newOpp.SE_Assigned__c != null){
                        oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = newOpp.Id, UserId = newOpp.SE_Assigned__c, TeamMemberRole = SEROLENAME));
                    }

                    // RENEWAL OPP MEMBERS
                    if(newOpp.Type == 'Renewal' || newOpp.Type == 'Existing Business'){

                        // CREATE CSM MEMBER
                        if(acctCSMMemberId != null){
                            // UPDATE OPP OWNER MEMBER IF IT EXISTS AND USER MATCHES THE TM
                            if(oppOwnerMember != null && oppOwnerMember.UserId == acctCSMMemberId){
                                oppOwnerMember.TeamMemberRole = CSMROLENAME;
                                oppsTMsToUpdate.put(oppOwnerMember.Id, oppOwnerMember);
                            }
                            // ELSE JUST CREATE A NEW TM MEMBER
                            else{
                                oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = newOpp.Id, UserId = acctCSMMemberId, TeamMemberRole = CSMROLENAME));                                               
                            }
                        }
                        
                        // CREATE RM MEMBER
                        if(acctRMMemberId != null){
                            // UPDATE OPP OWNER MEMBER IF IT EXISTS AND USER MATCHES THE CLM
                            if(oppOwnerMember != null && oppOwnerMember.UserId == acctRMMemberId){
                                oppOwnerMember.TeamMemberRole = RMROLENAME;
                                oppsTMsToUpdate.put(oppOwnerMember.Id, oppOwnerMember);
                            }
                            // ELSE JUST CREATE A NEW TM MEMBER
                            else{
                                oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = newOpp.Id, UserId = acctRMMemberId, TeamMemberRole = RMROLENAME));                                               
                            }
                        }
                    }
                }

                // SAVE OPPORTUNITY TEAM CHANGES - UPDATE
                if(!oppsTMsToUpdate.isEmpty()){
                    Database.SaveResult[] updateOppTMResults = Database.update(oppsTMsToUpdate.values(), false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(updateOppTMResults, 'OpportunityHelper', 'setUpOpportunityTeam', false);
                }

                // SAVE OPPORTUNITY TEAM CHANGES - CREATE
                if(!oppsTMsToCreate.isEmpty()){
                    Database.SaveResult[] createOppTMResults = Database.insert(oppsTMsToCreate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(createOppTMResults, 'OpportunityHelper', 'setUpOpportunityTeam', false);
                }

                // SAVE LOGGED ERRORS
                SystemIssueLogHelper.UpsertExceptions();

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'setUpOpportunityTeam');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'setUpOpportunityTeam', newOpps, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20191209
    * @description updateOpportunityTeams - Updates an Opportunity's Team Members based on whether the TM, CSM, SDR, or SE Assigned has changed
    *                                       --- EXECUTED BY OPPORTUNITY AFTER UPDATE TRIGGER ---
    * @param List<Opportunity> newOrUpdatedOpps - List of new or updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunity records 
    * @return void
    */
    public static void updateOppTeamsFromLookups(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','updateOppTeamsFromLookups') && newOrUpdatedOpps != null && outdatedOpps != null){

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                /////////////////////////// TEMPORARILY COPIES LOOKUP FIELDS CHANGES TO TEAMS - WILL BE DEPRECATED WITH LOOKUPS //////////////////////////
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                // GET IDS OF ACCOUNTS WITH QUALIFYING CHANGES
                List<Opportunity> qualifiedOpps = new List<Opportunity>();
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                    if((newOrUpdatedOpp.TM_Territory_ManagerId__c != null && newOrUpdatedOpp.TM_Territory_ManagerId__c != outdatedOpp.TM_Territory_ManagerId__c) ||
                       (newOrUpdatedOpp.Customer_Success_ManagerId__c != null && newOrUpdatedOpp.Customer_Success_ManagerId__c != outdatedOpp.Customer_Success_ManagerId__c) ||
                       (newOrUpdatedOpp.SDR__c != null && newOrUpdatedOpp.SDR__c != outdatedOpp.SDR__c) ||
                       (newOrUpdatedOpp.SE_Assigned__c != null && newOrUpdatedOpp.SE_Assigned__c != outdatedOpp.SE_Assigned__c)){
                        qualifiedOpps.add(newOrUpdatedOpp);
                    }
                }

                if(!qualifiedOpps.isEmpty()){

                    // ORGANIZE DATA AND GET ACCOUNT IDS FROM QUALIFYING RECORDS
                    Map<Id, List<OpportunityTeamMember>> teamMembersByOpp = new Map<Id, List<OpportunityTeamMember>>();
                    for(OpportunityTeamMember oppMember : [SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN :qualifiedOpps]){
                        if(!teamMembersByOpp.containsKey(oppMember.OpportunityId)){
                            teamMembersByOpp.put(oppMember.OpportunityId, new List<OpportunityTeamMember>());
                        }
                        teamMembersByOpp.get(oppMember.OpportunityId).add(oppMember);
                    }

                    List<OpportunityTeamMember> oppMembersToCreate = new List<OpportunityTeamMember>();
                    List<OpportunityTeamMember> oppMembersToDelete = new List<OpportunityTeamMember>();
                    for(Opportunity qualifiedOpp : qualifiedOpps){
                        Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(qualifiedOpp.Id) : null;

                        // GET USERS FROM OPPORTUNITY MEMBERS
                        OpportunityTeamMember oppTMMember;
                        OpportunityTeamMember oppCSMMember;
                        OpportunityTeamMember oppBDRMember;
                        OpportunityTeamMember oppSDRMember;
                        OpportunityTeamMember oppSEMember;
                        if(teamMembersByOpp.containsKey(qualifiedOpp.Id)){
                            for(OpportunityTeamMember member : teamMembersByOpp.get(qualifiedOpp.Id)){
                                if(member.TeamMemberRole == TMROLENAME && oppTMMember == null){
                                    oppTMMember = member;
                                }
                                if(member.TeamMemberRole == CSMROLENAME && oppCSMMember == null){
                                    oppCSMMember = member;
                                }
                                if(member.TeamMemberRole == BDRROLENAME && oppBDRMember == null){
                                    oppBDRMember = member;
                                }
                                if(member.TeamMemberRole == SDRROLENAME && oppSDRMember == null){
                                    oppSDRMember = member;
                                }
                                if(member.TeamMemberRole == SEROLENAME && oppSEMember == null){
                                    oppSEMember = member;
                                }                            
                            }
                        }

                        /////////////////////////////////////////////////////////////////////////////
                        /////////////////////////// TM CHANGE UPDATES ///////////////////////////////
                        /////////////////////////////////////////////////////////////////////////////
                        if(qualifiedOpp.TM_Territory_ManagerId__c != null && !qualifiedOpp.TM_Manager_Hold__c && qualifiedOpp.TM_Territory_ManagerId__c != outdatedOpp.TM_Territory_ManagerId__c){
                            if(String.isNotBlank(TMROLENAME) && (oppTMMember == null || oppTMMember.UserId != qualifiedOpp.TM_Territory_ManagerId__c)){
                                oppMembersToCreate.add(new OpportunityTeamMember(OpportunityId = qualifiedOpp.Id, UserId = qualifiedOpp.TM_Territory_ManagerId__c, TeamMemberRole = TMROLENAME));
                                
                                if(oppTMMember != null && !qualifiedOpp.IsSplit){
                                    // DELETE OLD MEMBER, NO LONGER VALID
                                    oppMembersToDelete.add(oppTMMember);
                                }
                            }
                        }

                        /////////////////////////////////////////////////////////////////////////////
                        /////////////////////////// CSM CHANGE UPDATES //////////////////////////////
                        /////////////////////////////////////////////////////////////////////////////
                        if(qualifiedOpp.Customer_Success_ManagerId__c != null && !qualifiedOpp.CSM_Manager_Hold__c  && qualifiedOpp.Customer_Success_ManagerId__c != outdatedOpp.Customer_Success_ManagerId__c){
                            if(String.isNotBlank(CSMROLENAME) && (qualifiedOpp.Type == 'Renewal' || qualifiedOpp.Type == 'Existing Business') && 
                                                                 (oppCSMMember == null || oppCSMMember.UserId != qualifiedOpp.Customer_Success_ManagerId__c)){

                                oppMembersToCreate.add(new OpportunityTeamMember(OpportunityId = qualifiedOpp.Id, UserId = qualifiedOpp.Customer_Success_ManagerId__c, TeamMemberRole = CSMROLENAME));
                                
                                if(oppCSMMember != null && !qualifiedOpp.IsSplit){
                                    // DELETE OLD MEMBER, NO LONGER VALID
                                    oppMembersToDelete.add(oppCSMMember);
                                }
                            }
                        }

                        /////////////////////////////////////////////////////////////////////////////
                        /////////////////////////// BDR/SDR CHANGE UPDATES //////////////////////////
                        /////////////////////////////////////////////////////////////////////////////
                        if(qualifiedOpp.SDR__c != null && qualifiedOpp.SDR__c != outdatedOpp.SDR__c && OppUsersMap.containsKey(qualifiedOpp.SDR__c)){
                            User sdrLookupUser = OppUsersMap.get(qualifiedOpp.SDR__c);

                            // BDR DOES NOT EXIST YET OR IS CHANGED, CREATE MEMBER, AND DELETE SDR IF IT EXISTS
                            if(String.isNotBlank(BDRROLENAME) && (oppBDRMember == null || oppBDRMember.UserId != qualifiedOpp.SDR__c) && 
                                sdrLookupUser.UserRole.Name.contains('Business Development Representative')){

                                oppMembersToCreate.add(new OpportunityTeamMember(OpportunityId = qualifiedOpp.Id, UserId = qualifiedOpp.SDR__c, TeamMemberRole = BDRROLENAME));
                                if(!qualifiedOpp.IsSplit){
                                    if(oppBDRMember != null){
                                        // DELETE OLD MEMBER, NO LONGER VALID
                                        oppMembersToDelete.add(oppBDRMember);  
                                    }

                                    if(oppSDRMember != null){
                                        // DELETE SDR MEMBER, BDR AND SDR SHOULD NOT EXIST TOGETHER
                                        oppMembersToDelete.add(oppSDRMember);
                                    }
                                }                      
                            }

                            // SDR DOES NOT EXIST YET OR IS CHANGED, CREATE MEMBER, AND DELETE BDR IF IT EXISTS
                            if(String.isNotBlank(SDRROLENAME) && (oppSDRMember == null || oppSDRMember.UserId != qualifiedOpp.SDR__c) && 
                                sdrLookupUser.UserRole.Name.contains('Sales Development Representative')){

                                oppMembersToCreate.add(new OpportunityTeamMember(OpportunityId = qualifiedOpp.Id, UserId = qualifiedOpp.SDR__c, TeamMemberRole = SDRROLENAME));
                                if(!qualifiedOpp.IsSplit){
                                    if(oppSDRMember != null){
                                        // DELETE OLD MEMBER, NO LONGER VALID
                                        oppMembersToDelete.add(oppSDRMember);  
                                    }

                                    if(oppBDRMember != null){
                                        // DELETE SDR MEMBER, BDR AND SDR SHOULD NOT EXIST TOGETHER
                                        oppMembersToDelete.add(oppBDRMember);
                                    }
                                }   
                            }
                        }

                        /////////////////////////////////////////////////////////////////////////////
                        /////////////////////////// SE CHANGE UPDATES //////////////////////////////
                        /////////////////////////////////////////////////////////////////////////////
                        if(qualifiedOpp.SE_Assigned__c != null && qualifiedOpp.SE_Assigned__c != outdatedOpp.SE_Assigned__c){
                            if(String.isNotBlank(SEROLENAME) && (oppSEMember == null || oppSEMember.UserId != qualifiedOpp.SE_Assigned__c)){
                                oppMembersToCreate.add(new OpportunityTeamMember(OpportunityId = qualifiedOpp.Id, UserId = qualifiedOpp.SE_Assigned__c, TeamMemberRole = SEROLENAME));
                                
                                if(oppSEMember != null && !qualifiedOpp.IsSplit){
                                    // DELETE OLD MEMBER, NO LONGER VALID
                                    oppMembersToDelete.add(oppSEMember);                          
                                }
                            }
                        }
                    }

                    // DELETE INVALID ACCOUNT TEAM MEMBERS
                    if(!oppMembersToDelete.isEmpty()){
                        Database.DeleteResult[] oppTMDeleteResults = Database.delete(oppMembersToDelete, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(oppTMDeleteResults, 'OpportunityHelper', 'updateOppTeamsFromLookups', false);
                    }

                    // CREATE ACCOUNT TEAM MEMBERS
                    if(!oppMembersToCreate.isEmpty()){
                        Database.SaveResult[] oppTMCreateResults = Database.insert(oppMembersToCreate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(oppTMCreateResults, 'OpportunityHelper', 'updateOppTeamsFromLookups', false);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'updateOppTeamsFromLookups');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'updateOppTeamsFromLookups', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190816
    * @description calculateCSForecast - An APEX version of the CS_Forecast__c formula field calculation
    *                             --- EXECUTED BY OPPORTUNITY BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<Opportunity> newOrUpdatedOpps - List of new or updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunity records 
    * @return void
    */
    public static void calculateCSForecast(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','calculateCSForecast') && newOrUpdatedOpps != null){
                
                List<Opportunity> qualifiedOpps = new List<Opportunity>();
                Set<Id> parentAccountIds = new Set<Id>();
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                    if(outdatedOpp == null || (!newOrUpdatedOpp.IsClosed && (newOrUpdatedOpp.Type != outdatedOpp.Type || 
                                                                             newOrUpdatedOpp.CS_Forecast__c != outdatedOpp.CS_Forecast__c ||
                                                                             newOrUpdatedOpp.CS_Forecast_Override__c != outdatedOpp.CS_Forecast_Override__c ||
                                                                             newOrUpdatedOpp.CS_Forecast_Apex__c != outdatedOpp.CS_Forecast_Apex__c ||
                                                                             newOrUpdatedOpp.Current_AI_Ave_MRR__c != outdatedOpp.Current_AI_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Automation_Ave_MRR__c != outdatedOpp.Current_Automation_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Collaborate_Ave_MRR__c != outdatedOpp.Current_Collaborate_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Composer_Ave_MRR__c != outdatedOpp.Current_Composer_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Contracts_Ave_MRR__c != outdatedOpp.Current_Contracts_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Contracts_for_SF_Ave_MRR__c != outdatedOpp.Current_Contracts_for_SF_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Courier_Ave_MRR__c != outdatedOpp.Current_Courier_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Grid_Ave_MRR__c != outdatedOpp.Current_Grid_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Orchestrate_Ave_MRR__c != outdatedOpp.Current_Orchestrate_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Other_Ave_MRR__c != outdatedOpp.Current_Other_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Product_Bundles_Ave_MRR__c != outdatedOpp.Current_Product_Bundles_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Services_Ave_MRR__c != outdatedOpp.Current_Services_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Sign_Ave_MRR__c != outdatedOpp.Current_Sign_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Support_Ave_MRR__c != outdatedOpp.Current_Support_Ave_MRR__c ||
                                                                             newOrUpdatedOpp.Current_Training_Ave_MRR__c != outdatedOpp.Current_Training_Ave_MRR__c))){
                        qualifiedOpps.add(newOrUpdatedOpp);
                        parentAccountIds.add(newOrUpdatedOpp.AccountId);
                    }
                }
                
                // PROCESS QUALIFIED OPPS
                if(!qualifiedOpps.isEmpty()){

                    // GET PARENT ACCOUNTS
                    Map<Id, Account> parentAccountsMap = new Map<Id, Account>([SELECT Id, Customer_likely_to__c FROM Account WHERE Id IN :parentAccountIds]);

                    for(Opportunity qualifiedOpp : qualifiedOpps){
                        // CALCULATE CURRENT AVE MRR TOTAL SINCE WE CANNOT RELY ON A FORMULA FIELD IN A BEFORE TRIGGER
                        Decimal currentAveMRRTotal = UtilityClass.replaceNull(qualifiedOpp.Current_AI_Ave_MRR__c, 0) + UtilityClass.replaceNull(qualifiedOpp.Current_Automation_Ave_MRR__c, 0) + 
                                                     UtilityClass.replaceNull(qualifiedOpp.Current_Collaborate_Ave_MRR__c, 0) + UtilityClass.replaceNull(qualifiedOpp.Current_Composer_Ave_MRR__c, 0) + 
                                                     UtilityClass.replaceNull(qualifiedOpp.Current_Contracts_Ave_MRR__c, 0) + UtilityClass.replaceNull(qualifiedOpp.Current_Contracts_for_SF_Ave_MRR__c, 0) +
                                                     UtilityClass.replaceNull(qualifiedOpp.Current_Courier_Ave_MRR__c, 0) + UtilityClass.replaceNull(qualifiedOpp.Current_Grid_Ave_MRR__c, 0) + 
                                                     UtilityClass.replaceNull(qualifiedOpp.Current_Orchestrate_Ave_MRR__c, 0) + UtilityClass.replaceNull(qualifiedOpp.Current_Other_Ave_MRR__c, 0) +
                                                     UtilityClass.replaceNull(qualifiedOpp.Current_Product_Bundles_Ave_MRR__c, 0) + UtilityClass.replaceNull(qualifiedOpp.Current_Services_Ave_MRR__c, 0) +
                                                     UtilityClass.replaceNull(qualifiedOpp.Current_Sign_Ave_MRR__c, 0) + UtilityClass.replaceNull(qualifiedOpp.Current_Support_Ave_MRR__c, 0) + 
                                                     UtilityClass.replaceNull(qualifiedOpp.Current_Training_Ave_MRR__c, 0);

                        // DEFAULT TO 0.00
                        qualifiedOpp.CS_Forecast_Apex__c = 0.00;

                        // IF A QUALIFIED CHANGE IS MADE UPDATE CS_Forecast_Apex__c FIELD
                        if(qualifiedOpp.Type == 'Renewal'){
                            if(qualifiedOpp.CS_Forecast_Override__c != null){
                                qualifiedOpp.CS_Forecast_Apex__c = qualifiedOpp.CS_Forecast_Override__c;
                            }
                            else if(parentAccountsMap.containsKey(qualifiedOpp.AccountId)){
                                switch on parentAccountsMap.get(qualifiedOpp.AccountId).Customer_likely_to__c {
                                    when 'Churn - no chance to save' {
                                        qualifiedOpp.CS_Forecast_Apex__c = currentAveMRRTotal * -1;
                                    }
                                    when 'Churn - potential to save' {
                                        qualifiedOpp.CS_Forecast_Apex__c = (currentAveMRRTotal * 0.7) * -1;
                                    }
                                    when 'Downsell' {
                                        qualifiedOpp.CS_Forecast_Apex__c = (currentAveMRRTotal * 0.15) * -1;
                                    }
                                    when 'Renew at current level' {
                                        qualifiedOpp.CS_Forecast_Apex__c = (currentAveMRRTotal * 0.05) * -1;
                                    }
                                    when else {
                                        // DO NOTHING, KEEP 0 DEFAULT
                                    }                                    
                                }
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'calculateCSForecast');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'calculateCSForecast', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @author Conga Services, ahafez, eredding
    * @description Creates Project record when Opportunity is Closed/Won
    *              ksears - updates for onboarding project creation - 1/3/2019
    *              eredding - Code reworked to improve efficiency
    * @param Map<Id,Opportunity> newOpps - Update Opp records
    * @param Map<Id,Opportunity> outdatedOpps - Outdated Opp records
    * @return void
    */
    public static void createProjectRecord(Map<Id,Opportunity> newOpps, Map<Id,Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','createProjectRecord') && newOpps != null && outdatedOpps != null){

                // GET QUALIFIED OPPS
                Map<Id, Opportunity> oppsToProcess = new Map<Id, Opportunity>();
                for(Opportunity opp : newOpps.values()){
                    Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(opp.Id) : null;
                    if(outdatedOpp != null && opp.IsClosed && opp.IsWon && !outdatedOpp.IsClosed && !outdatedOpp.IsWon && opp.Sub_Type__c != 'Forecasting Opportunity'){
                        oppsToProcess.put(opp.Id, opp);
                    }
                }

                if(!oppsToProcess.isEmpty()){
                    // ADD OPP IDS TO STATIC SET
                    OppIds.addAll(oppsToProcess.keySet());

                    // GET ADDITIONAL PRODUCTS THAT QUALIFY FOR PS PROJECTS FROM CUSTOM METADATA
                    Set<Id> additionalProducts = new Set<Id>();    
                    if(OppPartnerAutomationSettings != null){
                        if(OppPartnerAutomationSettings.Add_Products_Qualifying_for_PS_Project__c != null){
                            for(String additionalProdEntry : OppPartnerAutomationSettings.Add_Products_Qualifying_for_PS_Project__c.replace('\r','').split('\n')){
                                String additionalProdId = additionalProdEntry.left(18);
                                if(UtilityClass.validateId(additionalProdId)){
                                    additionalProducts.add(additionalProdId);
                                }
                            }
                        }
                    }

                    // CREATE SETS OF OPPS IDS FOR OPPS THAT QUALIFY FOR PRO SERV PROJECTS AND OPPS THAT QUALIFY FOR ONBOARDING PROJECTS
                    Set<Id> oppsQualifyingForProServ = new Set<Id>();
                    Set<Id> oppsQualifyingForOnboarding = new Set<Id>();
                    for(Id oppId : oppsToProcess.keySet()){
                        if(OppItemsByOppId.containsKey(oppId)){
                            for(OpportunityLineItem oppItem : OppItemsByOppId.get(oppId)){
                                
                                // PRO SERV QUALIFICATION
                                if((oppItem.Product2.FY16_Revenue_Type__c == 'Non-recurring' && oppItem.Product2.LOB__c == 'Services') || additionalProducts.contains(oppItem.Product2Id)){
                                    oppsQualifyingForProServ.add(oppId);
                                }

                                // ONBOARDING QUALIFICATION
                                if(!oppItem.Product2.Name.contains('Batch') && !oppItem.Product2.Name.contains('Trigger') && oppItem.Product2.Product_Line__c != 'Conga Support'){
                                    oppsQualifyingForOnboarding.add(oppId);
                                }
                            }
                        }
                    }

                    if(Trigger.isBefore && OppPartnerAutomationSettings.Conga_Partner_Account_Id__c != null){ // BEFORE UPDATE = IMPLEMENTATION PARTNER UPDATES
                        for(Opportunity opp : oppsToProcess.values()){
                            if(oppsQualifyingForProServ.contains(opp.Id) && opp.Type != 'Renewal'){
                                // SET OPP PARTNER DATA
                                if(opp.ImplementationPartnerPrimary__c != null && opp.ImplementationPartnerPrimary__c != OppPartnerAutomationSettings.Conga_Partner_Account_Id__c){
                                    opp.ImplementationPartnerSecondary__c = OppPartnerAutomationSettings.Conga_Partner_Account_Id__c;
                                }
                                else{
                                    opp.ImplementationPartnerPrimary__c = OppPartnerAutomationSettings.Conga_Partner_Account_Id__c;
                                }
                            }
                        }
                    }
                    else if(Trigger.isAfter){ // AFTER UPDATE = PROJECT CREATION
                        TriggerHelper.TemporaryOverride('OpportunityHelper','createProjectRecord', false); // DISABLE SO A 2ND EXECUTION DOESNT OCCUR DURING THE SAME TRANSACTION

                        // GET RECORD TYPE IDS
                        Map<String, Id> projectRecordTypes = RecordTypes.get('PS_Project__c');
                        Id proServProjectRT = projectRecordTypes.get('PS_Project');
                        Id onboardingProjectRT = projectRecordTypes.get('Onboarding');
                        Id partnerProjectRT = projectRecordTypes.get('Partner');

                        // GET IMPLEMENTATION PARTNER IDS
                        Set<Id> impPartnerIds = new Set<Id>();
                        for(Opportunity opp : oppsToProcess.values()){
                            if(oppsQualifyingForProServ.contains(opp.Id)){
                                impPartnerIds.add(opp.ImplementationPartnerPrimary__c);
                            }
                        }

                        // GET IMPLEMENTATION PARTNERS
                        Map<Id, Account> impPartners = new Map<Id, Account>();
                        for(Account partnerAccount : [SELECT Id, OwnerId FROM Account WHERE Id IN :impPartnerIds]){
                            impPartners.put(partnerAccount.Id, partnerAccount);
                        }

                        // CHECK FOR EXISTING PROJECTS
                        Set<Id> oppsWithPSProject = new Set<Id>();
                        Set<Id> oppsWithOBProject = new Set<Id>();
                        for(PS_Project__c proj : [SELECT Id, RecordTypeId, OpportunityId__c FROM PS_Project__c WHERE OpportunityId__c = :oppsToProcess.keySet()]){
                            if(proj.RecordTypeId == proServProjectRT || proj.RecordTypeId == partnerProjectRT){
                                oppsWithPSProject.add(proj.OpportunityId__c);
                            }
                            else if(proj.RecordTypeId == onboardingProjectRT){
                                oppsWithOBProject.add(proj.OpportunityId__c);
                            }
                        }

                        // REMOVE OPPS FROM oppsToProcess THAT ALREADY HAVE BOTH PROJECTS
                        for(Id oppId : oppsToProcess.keySet()){
                            if(oppsWithPSProject.contains(oppId) && oppsWithOBProject.contains(oppId)){
                                oppsToProcess.remove(oppId);
                            }
                        }

                        Map<String,Id> queueMap = new Map<String,Id>();
                        for(Group g : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN ('Provisioning Team', 'Professional Services Queue')]){
                            queueMap.put(g.Name, g.Id);
                        }

                        // GET OPP CONTACT ROLES
                        Map<Id, List<OpportunityContactRole>> oppContactRolesByOppId = new Map<Id, List<OpportunityContactRole>>();
                        for(OpportunityContactRole oppRole : [SELECT Id, OpportunityId, Role, ContactId, IsPrimary FROM OpportunityContactRole WHERE OpportunityId IN :oppsToProcess.keySet()]){
                            if(!oppContactRolesByOppId.containsKey(oppRole.OpportunityId)){
                                oppContactRolesByOppId.put(oppRole.OpportunityId, new List<OpportunityContactRole>());
                            }
                            oppContactRolesByOppId.get(oppRole.OpportunityId).add(oppRole);
                        }

                        // GET PRIMARY SR FROM CLOSED WON OPPS
                        Map<Id, Support_Request__c> primarySRByOpp = new Map<Id, Support_Request__c>();
                        for(Support_Request__c sr : [SELECT Id, Salesforce_Opportunity_Record__c, Product_s__c, Project_Agreement_Type__c, Invoice_Type__c, Billing_Type__c,
                                                            Payment_Terms__c,
                                                            (SELECT Id, ProjectId__c FROM Milestones__r)
                                                     FROM Support_Request__c WHERE Salesforce_Opportunity_Record__c IN :oppsToProcess.keySet() AND Primary__c = true]){
                            primarySRByOpp.put(sr.Salesforce_Opportunity_Record__c, sr);
                        }

                        // PROCESS OPPS
                        List<PS_Project__c> newProjects = new List<PS_Project__c>();
                        for(Opportunity opp : oppsToProcess.values()){
                            Account impPartnerPrimary = impPartners.containsKey(opp.ImplementationPartnerPrimary__c) ? impPartners.get(opp.ImplementationPartnerPrimary__c) : null;

                            // CREATE PS PROJECT IF THERE IS A SERVICES LINE ITEM AND IT DOESNT ALREADY EXIST AND THE OPP IS NOT A RENEWAL
                            if(!oppsWithPSProject.contains(opp.Id) && oppsQualifyingForProServ.contains(opp.Id) && opp.Type != 'Renewal' && opp.ImplementationPartnerPrimary__c != null){
                                PS_Project__c newProj = new PS_Project__c();
                                newProj.Name = opp.Name;
                                newProj.AccountId__c = opp.AccountId;
                                newProj.OpportunityId__c = opp.Id;
                                newProj.Execution__c = opp.CloseDate;
                                newProj.RecordTypeId = (opp.ImplementationPartnerPrimary__c == OppPartnerAutomationSettings.Conga_Partner_Account_Id__c ? proServProjectRT : partnerProjectRT);
                                newProj.Partner_Company_Name_Engaged__c = opp.ImplementationPartnerPrimary__c;
                                newProj.OwnerId = (newProj.RecordTypeId == partnerProjectRT && impPartnerPrimary != null ? impPartnerPrimary.OwnerId : null);
                                newProj.Conga_Collaborate_Template__c = 'Welcome Kit';
 
                                // GET DATA FROM PS SUPPORT REQUEST
                                if(primarySRByOpp.containsKey(opp.Id)){
                                    Support_Request__c parentSR = primarySRByOpp.get(opp.Id);
                                    newProj.Agreement_Type__c = parentSR.Project_Agreement_Type__c;
                                    newProj.Invoice_Type__c = parentSR.Invoice_Type__c;
                                    newProj.Billing_Type__c = parentSR.Billing_Type__c;
                                    newProj.Payment_Terms__c = parentSR.Payment_Terms__c;
                                    newProj.Product_s__c = parentSR.Product_s__c;
                                }

                                // DEFAULT OWNER TO PRO SERV QUEUE IF NOT ALREADY SET
                                if(newProj.RecordTypeId == proServProjectRT && queueMap.containsKey('Professional Services Queue')){
                                    newProj.OwnerId = queueMap.get('Professional Services Queue');
                                }

                                newProjects.add(newProj);
                            }

                            // CREATE ONBOARDING PROJECT IF THERE ARE QUALIFYING ITEMS, NEW BUSINESS OR CROSS SELL, AND NO RESELLER
                            if(!oppsWithOBProject.contains(opp.Id) && opp.Sub_Type__c != 'Cancellation' && opp.Sub_Type__c != 'Adjustment' && opp.Reseller__c == null && 
                                oppsQualifyingForOnboarding.contains(opp.Id) && (opp.Type == 'New Business' || opp.Cross_Sell_Ave_MRR_Total__c > 0)){

                                PS_Project__c newProj2 = new PS_Project__c();
                                newProj2.Name = opp.Name;
                                newProj2.AccountId__c = opp.AccountId;
                                newProj2.OpportunityId__c = opp.Id;
                                newProj2.Execution__c = opp.CloseDate;
                                newProj2.RecordTypeId = onboardingProjectRT;
                                newProj2.Project_Type__c = 'Onboarding'; 

                                if(opp.Type == 'New Business'){ 
                                    newProj2.Onboarding_Project_Type__c = 'New Business'; 
                                } 

                                if(opp.Cross_Sell_Ave_MRR_Total__c > 0){ 
                                    newProj2.Onboarding_Project_Type__c = 'Cross Sell'; 
                                } 

                                if(opp.Onboarding_Specialist_ID__c != null){
                                    newProj2.OwnerId = opp.Onboarding_Specialist_ID__c;
                                }
                                else if(queueMap.containsKey('Provisioning Team')){
                                    newProj2.OwnerId = queueMap.get('Provisioning Team');
                                }

                                newProjects.add(newProj2);
                            }
                        }

                        Map<Id, Id> oppPSProjMap = new Map<Id, Id>();
                        Map<Id, Id> oppOnboardProjMap = new Map<Id, Id>();
                        Map<Id, PS_Project__c> newProjectsMap = new Map<Id,PS_Project__c>();
                        if(!newProjects.isEmpty()){
                            Database.saveResult[] newProjectResults = Database.insert(newProjects, true);
                            SystemIssueLogHelper.CheckForDatabaseErrors(newProjectResults, 'OpportunityHelper', 'createProjectRecord', false);

                            for(PS_Project__c newProject : newProjects){
                                if(newProject.Id != null){
                                    newProjectsMap.put(newProject.Id, newProject);
                                    if(newProject.RecordTypeId == proServProjectRT || newProject.RecordTypeId == partnerProjectRT){
                                        oppPSProjMap.put(newProject.OpportunityId__c, newProject.Id);
                                    }
                                    else{
                                        oppOnboardProjMap.put(newProject.OpportunityId__c, newProject.Id);
                                    }
                                }
                            }

                            // CREATE MILESTONES FROM OPP LINE ITEMS ON NEW PS PROJECTS
                            List<Milestone__c> milestonesToUpdate = new List<Milestone__c>();
                            //List<Milestone__c> newMilestones = new List<Milestone__c>();
                            List<Project_Team__c> newTeams = new List<Project_Team__c>();
                            for(Opportunity opp : oppsToProcess.values()){

                                ////// NEW MILESTONE CREATION //////
                                if(oppPSProjMap.containsKey(opp.Id) && primarySRByOpp.containsKey(opp.Id) && !primarySRByOpp.get(opp.Id).Milestones__r.isEmpty()){
                                    for(Milestone__c milestone : primarySRByOpp.get(opp.Id).Milestones__r){
                                        milestone.PricebookId__c = opp.Pricebook2Id;
                                        milestone.ProjectId__c = oppPSProjMap.get(opp.Id);
                                        milestonesToUpdate.add(milestone);
                                    }
                                }

                                ////// OLD MILESTONE CREATION //////
                                //if(oppPSProjMap.containsKey(opp.Id) && OppItemsByOppId.containsKey(opp.Id)){
                                //    for(OpportunityLineItem oli : OppItemsByOppId.get(opp.Id)){
                                //        if(oli.Product2.FY16_Revenue_Type__c == 'Non-recurring' && oli.Product2.LOB__c == 'Services'){
                                //            Milestone__c newMile = new Milestone__c();
                                //            newMile.ProductId__c = oli.Product2Id;
                                //            newMile.PricebookId__c = oli.PricebookEntry.Pricebook2Id;
                                //            newMile.Name = oli.Product2.Name;
                                //            newMile.ProjectId__c = oppPSProjMap.get(opp.Id);

                                //            if(oli.Product2.Hours__c == null){
                                //                newMile.Hours_Currently_Budgeted__c = oli.Quantity;
                                //            }
                                //            else{
                                //                newMile.Hours_Currently_Budgeted__c = oli.Product2.Hours__c;
                                //            }

                                //            if(oli.Product2.Hourly_Rate__c == null){
                                //                newMile.Effective_Hourly_Rate__c = oli.UnitPrice;
                                //            }
                                //            else{
                                //                newMile.Effective_Hourly_Rate__c = oli.Product2.Hourly_Rate__c;
                                //            }

                                //            newMilestones.add(newMile);
                                //        }
                                //    }
                                //}

                                // CREATE NEW PROJECT TEAMS FROM OPP CONTACT ROLES
                                if(oppContactRolesByOppId.containsKey(opp.Id)){
                                    for(OpportunityContactRole ocr : oppContactRolesByOppId.get(opp.Id)){
                                        // FOR PS PROJECT
                                        if(oppPSProjMap.containsKey(opp.Id)){
                                            Project_Team__c newTeam = new Project_Team__c();
                                            newTeam.Contact__c = ocr.ContactId;
                                            newTeam.Role__c = ocr.Role;
                                            newTeam.IsPrimary__c = ocr.IsPrimary;
                                            newTeam.Project__c = oppPSProjMap.get(opp.Id);
                                            newTeams.add(newTeam);
                                        }

                                        // FOR ONBOARDING PROJECT
                                        if(oppOnboardProjMap.containsKey(opp.Id)){
                                            Project_Team__c newTeam = new Project_Team__c();
                                            newTeam.Contact__c = ocr.ContactId;
                                            newTeam.Role__c = ocr.IsPrimary ? 'Project Owner' : ocr.Role;
                                            newTeam.IsPrimary__c = ocr.IsPrimary;
                                            newTeam.Project__c = oppOnboardProjMap.get(opp.Id);
                                            newTeams.add(newTeam);
                                        }
                                    }
                                }
                            }

                            //if(!newMilestones.isEmpty()){
                            //    Database.saveResult[] insertResults = Database.insert(newMilestones, true);
                            //    SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'OpportunityHelper', 'createProjectRecord', false);
                            //}

                            if(!milestonesToUpdate.isEmpty()){
                                Database.saveResult[] updateResults = Database.update(milestonesToUpdate, true);
                                SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'OpportunityHelper', 'createProjectRecord', false);
                            }

                            Map<Id, List<Project_Team__c>> newTeamMembersByProject = new Map<Id, List<Project_Team__c>>();
                            if(!newTeams.isEmpty()){
                                Database.saveResult[] newTeamResults = Database.insert(newTeams, true);
                                SystemIssueLogHelper.CheckForDatabaseErrors(newTeamResults, 'OpportunityHelper', 'createProjectRecord', false);

                                for(Project_Team__c newTeamMember : newTeams){
                                    if(newTeamMember.Id != null){
                                        if(!newTeamMembersByProject.containsKey(newTeamMember.Project__c)){
                                            newTeamMembersByProject.put(newTeamMember.Project__c, new List<Project_Team__c>());
                                        }
                                        newTeamMembersByProject.get(newTeamMember.Project__c).add(newTeamMember);
                                    }
                                }
                            }
                            
                            // LINK NEW ONBOARDING PROJECTS TO THEIR PARENT PS PROJECTS AND SET NECESSARY FIELDS
                            Map<Id, PS_Project__c> projectUpdateMap = new Map<Id, PS_Project__c>();
                            for(PS_Project__c newOBProject  : newProjectsMap.values()){
                                if(newOBProject.RecordTypeId == onboardingProjectRT){
                                    if(oppPSProjMap.containsKey(newOBProject.OpportunityId__c)){
                                        newOBProject.Parent_PS_Project__c = oppPSProjMap.get(newOBProject.OpportunityId__c);
                                        newOBProject.Onboarding_Completion__c = 'On Hold- PS Completion';
                                        newOBProject.Onboarding_Follow_Up_Date__c = Date.Today().addDays(56);
                                    }
                                    else{
                                        if(newOBProject.Onboarding_Project_Type__c == 'Cross Sell'){
                                            newOBProject.Onboarding_Completion__c = 'Verify Cross Sell';
                                        }
                                        else{
                                            newOBProject.Onboarding_Completion__c = 'Scheduling Email Sent'; 
                                        }
                                    }
                                    projectUpdateMap.put(newOBProject.Id, newOBProject);
                                }
                            }

                            // UPDATE NEW PROJECTS WITH SURVEY CONTACT FROM PROJECT OWNER TEAM MEMBER
                            for(PS_Project__c newProject : newProjectsMap.values()){
                                if(newTeamMembersByProject.containsKey(newProject.Id)){
                                    for(Project_Team__c teamMember : newTeamMembersByProject.get(newProject.Id)){
                                        if(teamMember.IsPrimary__c){
                                            if(projectUpdateMap.containsKey(newProject.Id)){
                                                projectUpdateMap.get(newProject.Id).Survey_ContactId__c = teamMember.Contact__c;
                                            }
                                            else{
                                                newProject.Survey_ContactId__c = teamMember.Contact__c;
                                                projectUpdateMap.put(newProject.Id, newProject);
                                            }
                                            break;
                                        }
                                    }
                                }
                            }

                            // UPDATE PROJECTS
                            if(!projectUpdateMap.isEmpty()){
                                Database.saveResult[] updateProjectResults = Database.update(projectUpdateMap.values(), true);
                                SystemIssueLogHelper.CheckForDatabaseErrors(updateProjectResults, 'OpportunityHelper', 'createProjectRecord', false);
                            }

                            // LOG ANY ERRORS
                            SystemIssueLogHelper.UpsertExceptions();
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'createProjectRecord');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'createProjectRecord', newOpps, ex, true);
        }
    }
    
    /**
    * @author ECS, ERedding
    * @date 20190701
    * @description getPrimaryContactFromAcct - Populates the Primary Contact on new New Business or Renewal Opportunities from contacts related to the parent Account
    *                                           --- EXECUTED BY OPPORTUNITY BEFORE INSERT TRIGGER ---
    * @param List<Opportunity> newOpps - New Opportunity records
    * @return void
    */
    public static void getPrimaryContactFromAcct(List<Opportunity> newOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','getPrimaryContactFromAcct') && newOpps != null){

                // GET QUALIFIED OPPS AND PARENT ACCOUNT IDS
                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                Set<Id> accountIds = new Set<Id>();
                for(Opportunity newOpp : newOpps){
                    if(newOpp.Primary_Contact__c == null && (newOpp.Type == 'Existing Business' || newOpp.Type == 'Renewal')){
                        oppsToUpdate.add(newOpp);
                        accountIds.add(newOpp.AccountId);
                    }
                }

                if(!accountIds.isEmpty()){

                    // GET CHILD CONTACTS FROM PARENT ACCCOUNTS AND CATEGORIZE
                    Map<Id, Map<String, Id>> categorizedContactsByAccount = new Map<Id, Map<String, Id>>();
                    //////// GET FIRST CONTACT
                    for(AccountContactRelation relation : [SELECT AccountId, ContactId, IsPrimary__c, Roles FROM AccountContactRelation
                                                            WHERE AccountId IN :accountIds ORDER BY Contact.LastName LIMIT 10000]){

                        if(!categorizedContactsByAccount.containsKey(relation.AccountId)){
                            categorizedContactsByAccount.put(relation.AccountId, new Map<String, Id>{ 'FirstContact' => relation.ContactId });
                        }

                        // STOP LOOP IF FIRST CONTACTS HAVE BEEN ADDED FOR ALL ACCOUNTS
                        if(categorizedContactsByAccount.size() == accountIds.size()){
                            break;
                        }
                    }
                    //////// GET PRIMARY CONTACTS, FIRST DECISION MAKER PRIMARY CONTACT, AND FIRST ADMIN PRIMARY CONTACT
                    for(AccountContactRelation relation : [SELECT AccountId, ContactId, IsPrimary__c, Roles FROM AccountContactRelation
                                                            WHERE AccountId IN :accountIds AND (IsPrimary__c = true OR Roles != null)]){

                        if(!categorizedContactsByAccount.containsKey(relation.AccountId)){
                            categorizedContactsByAccount.put(relation.AccountId, new Map<String, Id>());
                        }

                        Map<String, Id> categorizedContacts = categorizedContactsByAccount.get(relation.AccountId);
                        if(categorizedContacts != null){
                            // GET FIRST PRIMARY CONTACT
                            if(!categorizedContacts.containsKey('FirstPrimary') && relation.IsPrimary__c){
                                categorizedContactsByAccount.get(relation.AccountId).put('FirstPrimary', relation.ContactId);
                            }

                            // GET SECOND PRIMARY CONTACT
                            if(categorizedContacts.containsKey('FirstPrimary') && !categorizedContacts.containsKey('SecondPrimary') &&
                                categorizedContacts.get('FirstPrimary') != relation.ContactId && relation.IsPrimary__c){

                                categorizedContactsByAccount.get(relation.AccountId).put('SecondPrimary', relation.ContactId);
                            }
                                
                            // GET FIRST DECISION MAKER PRIMARY CONTACT
                            if(!categorizedContacts.containsKey('FirstDecisionMakerPrimary') && relation.IsPrimary__c && relation.Roles != null && relation.Roles.contains('Decision Maker')){
                                categorizedContactsByAccount.get(relation.AccountId).put('FirstDecisionMakerPrimary', relation.ContactId);
                            }

                            // GET FIRST ADMIN PRIMARY CONTACT
                            if(!categorizedContacts.containsKey('FirstAdminPrimary') && relation.IsPrimary__c && relation.Roles != null && relation.Roles.contains('Admin')){
                                categorizedContactsByAccount.get(relation.AccountId).put('FirstAdminPrimary', relation.ContactId);
                            }
                        }
                    }
                        
                    for(Opportunity newOpp : oppsToUpdate){
                        // GET CATEGORIED CONTACTS FOR OPP AND SET PRIMARY CONTACT
                        Map<String, Id> categorizedContacts = categorizedContactsByAccount.get(newOpp.AccountId);
                        if(categorizedContacts != null){

                            if(categorizedContacts.containsKey('SecondPrimary')){
                                // MORE THAN ONE PRIMARY FOUND, CONSIDER ROLES

                                if(categorizedContacts.containsKey('FirstDecisionMakerPrimary')){
                                    // USE DECISION MAKER
                                    newOpp.Primary_Contact__c = categorizedContacts.get('FirstDecisionMakerPrimary');
                                }
                                else if(categorizedContacts.containsKey('FirstAdminPrimary')){
                                    // USE ADMIN
                                    newOpp.Primary_Contact__c = categorizedContacts.get('FirstAdminPrimary');
                                }
                                else{
                                    // USE FIRST PRIMARY FOUND
                                    newOpp.Primary_Contact__c = categorizedContacts.get('FirstPrimary');
                                }
                            }
                            else if(categorizedContacts.containsKey('FirstPrimary') && !categorizedContacts.containsKey('SecondPrimary')){
                                // ONLY ONE PRIMARY FOUND
                                newOpp.Primary_Contact__c = categorizedContacts.get('FirstPrimary');
                            }
                            else{
                                // NO PRIMARY FOUND, USE FIRST CONTACT SORTED BY LAST NAME
                                newOpp.Primary_Contact__c = categorizedContacts.get('FirstContact');
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'getPrimaryContactFromAcct');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'getPrimaryContactFromAcct', newOpps, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190702
    * @description copyPrimaryContactToRoles - Takes a new Opportunity's Primary Contact and makes a Opp Contact Role from it
    *                                           --- EXECUTED BY OPPORTUNITY AFTER INSERT TRIGGER ---
    * @param List<Opportunity> newOpps - New Opportunity records
    * @return void
    */
    public static void copyPrimaryContactToRoles(List<Opportunity> newOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','copyPrimaryContactToRoles') && newOpps != null){

                // GET QUALIFIED OPPS AND CONTACT IDS
                List<Opportunity> qualifiedOpps = new List<Opportunity>();
                Set<Id> contactIds = new Set<Id>();
                for(Opportunity newOpp : newOpps){
                    if(newOpp.Primary_Contact__c != null){
                        qualifiedOpps.add(newOpp);
                        contactIds.add(newOpp.Primary_Contact__c);
                    }
                }

                if(!contactIds.isEmpty()){
                    // GET ACCOUNT CONTACT RELATION RECORDS
                    Map<Id, AccountContactRelation> accountContacts = new Map<Id, AccountContactRelation>();
                    for(AccountContactRelation relation : [SELECT ContactId, IsPrimary__c, Roles FROM AccountContactRelation WHERE ContactId IN :contactIds]){
                        accountContacts.put(relation.ContactId, relation);
                    }

                    if(!accountContacts.isEmpty()){
                        // CREATE OPP CONTACT ROLES FOR EACH OPP
                        List<OpportunityContactRole> contactRolesToCreate = new List<OpportunityContactRole>();
                        for(Opportunity opp : qualifiedOpps){
                            if(accountContacts.containsKey(opp.Primary_Contact__c)){
                                AccountContactRelation contact = accountContacts.get(opp.Primary_Contact__c);

                                List<String> rolesList = new List<String>();
                                if(contact.Roles != null){
                                    rolesList = contact.Roles.split(';');
                                    rolesList.sort();
                                }
                                Set<String> rolesSet = new Set<String>(rolesList);
                                String role = rolesSet.contains('Decision Maker') ? 'Decision Maker' : rolesSet.contains('Admin') ? 'Admin' : !rolesSet.isEmpty() ? rolesList[0] : null;
                                contactRolesToCreate.add(new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contact.ContactId, IsPrimary = true, Role = role));
                            }
                        }

                        if(!contactRolesToCreate.isEmpty()){
                            Database.saveResult[] contactRoleResults = Database.insert(contactRolesToCreate, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(contactRoleResults, 'OpportunityHelper', 'copyPrimaryContactToRoles', true);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'copyPrimaryContactToRoles');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'copyPrimaryContactToRoles', newOpps, ex, true);
        }
    }
    
    /**
    * @author ECS, ERedding
    * @date 20190701
    * @description setPrimaryContactCount - Executes an update of Opp Primary Contact counts using Queueable_UpdateOppPrimaryCount queueable
    *                                         --- EXECUTED FROM OPPORTUNITY AFTER INSERT TRIGGER ---
    * @param List<Opportunity> newOpps - List of new Opportunity records
    * @return void
    */
    public static void setPrimaryContactCount(List<Opportunity> newOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','setPrimaryContactCount') && newOpps != null){

                // GET IDS OF QUALIFYING PARENT OPP RECORDS
                Set<Id> oppIds = new Set<Id>();
                for(Opportunity newOpp : newOpps){
                    oppIds.add(newOpp.Id);
                }

                // ENQUEUE UPDATE
                if(!oppIds.isEmpty()){
                    System.enqueueJob(new Queueable_UpdateOppPrimaryCount(oppIds));
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'setPrimaryContactCount');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'setPrimaryContactCount', newOpps, ex, true);
        } 
    }

    /**
    * @author Conga Services
    * @date 20180621
    * @description populateSalesforceAcct - Populates the Salesforce_Account__c field on a new Opp with its parent Account's child Salesforce Account record Id.
    *                                       If there are more than one Salesforce Account records, the latest modified one will be used.
    *                                       --- EXECUTED BY OPPORTUNITY BEFORE INSERT TRIGGER ---
    * @param Map<Id, Opportunity> newOpps - Updated Opportunity records
    * @return void
    */
    public static void populateSalesforceAcct(List<Opportunity> newOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','populateSalesforceAcct') && newOpps != null){

                // GET PARENT ACCOUNT IDS
                Set<Id> accountIds = new Set<Id>();
                for(Opportunity opp : newOpps){
                    accountIds.add(opp.AccountId);
                }

                if(!accountIds.isEmpty()){
                    // GET PARENT ACCOUNT RECORDS AND CHILD SALESFORCE ACCOUNTS
                    Map<Id, Account> parentAccountMap = new Map<Id, Account>();
                    for(Account acct : [SELECT Id, (SELECT Id FROM Salesforce_Accounts__r ORDER BY LastModifiedDate DESC) FROM Account WHERE Id IN :accountIds]){
                        parentAccountMap.put(acct.Id, acct);
                    }

                    // POPULATE SALESFORCE ACCOUNT ON EACH OPPORTUNITY
                    for(Opportunity newOpp : newOpps){
                        if(newOpp.Salesforce_Account__c == null && parentAccountMap.containsKey(newOpp.AccountId) && !parentAccountMap.get(newOpp.AccountId).Salesforce_Accounts__r.isEmpty()){
                            newOpp.Salesforce_Account__c = parentAccountMap.get(newOpp.AccountId).Salesforce_Accounts__r[0].Id;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'populateSalesforceAcct');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'populateSalesforceAcct', newOpps, ex, true);
        }         
    }

    /**
    * @author Conga Services
    * @date 20181001
    * @description createAssetsFromLineItems - Creates the necessary assets from an Opp's Line Items when the Opp has been approved by Sales Ops
    *                                            --- CONVERTED FROM invocable_createAssetFromLineItem. EXECUTED BY OPPORTUNITY AFTER UPDATE TRIGGER ---
    * @param List<Opportunity> updatedOpps - Updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Outdated Opportunity records
    * @return void
    */
    public static void createAssetsFromLineItems(List<Opportunity> updatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','createAssetsFromLineItems') && updatedOpps != null && outdatedOpps != null){

                // GET QUALIFIYING OPPORTUNITIES
                Set<Id> qualifyingOppIds = new Set<Id>();
                for(Opportunity updatedOpp : updatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(updatedOpp.Id) : null;
                    if(updatedOpp.Sales_Ops_Approved__c == TRUE && updatedOpp.Sales_Ops_Approved__c != outdatedOpp.Sales_Ops_Approved__c && updatedOpp.Entity_Code__c != 'CRMC'
                       && updatedOpp.Sub_Type__c != 'Forecasting Opportunity'){
                        // OPP WAS APPROVED AND THE ENTITY IS NOT CRMC, OPP QUALIFIES
                        qualifyingOppIds.add(updatedOpp.Id);
                    }
                }

                if(!qualifyingOppIds.isEmpty()){
                    /*Only get line items that do not have assets already created*/
                    List<OpportunityLineItem> oppItems = [SELECT Id, Asset__c, Opportunity.AccountId, PricebookEntry.Product2.Name, ServiceDate, UnitPrice, Quantity, Product_End_Date__c, 
                                                          PricebookEntry.Product2.FY16_Revenue_Type__c, PricebookEntry.Product2Id, Product_MRR_2__c, OpportunityId, 
                                                          Opportunity.Salesforce_Org__c, Opportunity.Salesforce_Account__c, Opportunity.Billing_Party__c 
                                                          FROM OpportunityLineItem WHERE OpportunityId IN :qualifyingOppIds AND Asset__c = null];

                    Map<String, Id> assetRecordTypes = RecordTypes.get('Asset');
                    List<Asset> assetsToInsert = new List<Asset>();
                    if(!oppItems.isEmpty()){
                        for(OpportunityLineItem oppItem : oppItems){
                            // CREATE A NEW ASSET
                            Asset oliAsset = new Asset(
                                AccountId = oppItem.Opportunity.AccountId,
                                Name = oppItem.PricebookEntry.Product2.Name,
                                Product2Id = oppItem.PricebookEntry.Product2Id,
                                Quantity = oppItem.Quantity,
                                Price = oppItem.UnitPrice,
                                RecordTypeId = assetRecordTypes.get('Standard'),
                                Start_Date__c =  oppItem.ServiceDate,
                                End_Date__c = oppItem.Product_End_Date__c,
                                OLI_Id__c = oppItem.Id,
                                mrr_Asset_MRR__c = oppItem.Product_MRR_2__c,
                                Related_Oppty__c = oppItem.OpportunityId,
                                Salesforce_Org__c = oppItem.Opportunity.Salesforce_Org__c,
                                Salesforce_Account__c = oppItem.Opportunity.Salesforce_Account__c,
                                Billing_Party__c = oppItem.Opportunity.Billing_Party__c
                            );

                            /*Asset type is dependent upon the revenue type of the related product*/
                            if (oppItem.PricebookEntry.Product2.FY16_Revenue_Type__c == 'Recurring'){
                                oliAsset.Type__c = 'Subscription';
                            }
                            else if (oppItem.PricebookEntry.Product2.FY16_Revenue_Type__c == 'Non-Recurring'){
                                oliAsset.Type__c = 'Consumable';
                            }

                            assetsToInsert.add(oliAsset);
                        }

                        //SAVE ANY NEW ASSETS TO THE DATABASE
                        if(!assetsToInsert.isEmpty()){
                            Database.saveResult[] assetResults = Database.insert(assetsToInsert, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(assetResults, 'OpportunityHelper', 'createAssetsFromLineItems', true);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'createAssetsFromLineItems');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'createAssetsFromLineItems', updatedOpps, ex, true);
        }
    }

    /**
    * @author Conga Services
    * @date 20181009
    * @description updateReferringPartnerFields - Populates/Updates the Referring_Partner_Primary__c and Partner_Rep__c fields based on the parent Account's RVPE__RVAccount__c.
    *                                             Custom Metadata is used to map Referring_Partner_Primary__c accounts to the appropriate Partner Reps.
    *                                             CONVERTED FROM PopulateReferringPartnerDealRegviaPortal TRIGGER AND Set Partner Rep field on Oppty PROCESS. 
    *                                             --- EXECUTED BY OPPORTUNITY BEFORE INSERT AND BEFORE UPDATE TRIGGER ---
    * @param List<Opportunity> newOrUpdatedOpps - New or updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Outdated Opportunity records
    * @return void
    */
    public static void updateReferringPartnerFields(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','updateReferringPartnerFields') && newOrUpdatedOpps != null){

                ///////////////////// 20200717 ECS EREDDING - DEPRECATED, IMPARTNER REMOVED FROM ORG /////////////////////
                // GET OPPORTUNITIES AND RV ACCOUNT IDS FOR OPPS THAT QUALIFY FOR A Referring_Partner_Primary__c UPDATE
                //List<Opportunity> referringPartnersToUpdate = new List<Opportunity>();
                //Set<Id> rvAccountIds = new Set<Id>();              
                //for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                //    Opportunity outdatedOpp = outdatedOpps != null && outdatedOpps.containsKey(newOrUpdatedOpp.Id) ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                //    if(newOrUpdatedOpp.RVPE__RVAccount__c != null && (outdatedOpp == null || newOrUpdatedOpp.RVPE__RVAccount__c != outdatedOpp.RVPE__RVAccount__c)){
                //        // NEW OPP WITH RVPE__RVAccount__c OR CHANGED RVPE__RVAccount__c, OPP QUALIFIES
                //        referringPartnersToUpdate.add(newOrUpdatedOpp);
                //        //rvAccountIds.add(newOrUpdatedOpp.RVPE__RVAccount__c);
                //    }
                //}
                // PROCESS RVPE__RVAccount__c UPDATES
                //if(!referringPartnersToUpdate.isEmpty()){
                    // GET RV ACCOUNTS FOR QUALIFIED OPPS
                    //Map<Id, RVPE__RVAccount__c> rvAccountMap = new Map<Id, RVPE__RVAccount__c>([SELECT Id, RVPE__SFAccount__c FROM RVPE__RVAccount__c 
                    //                                                                            WHERE Id IN :rvAccountIds AND RVPE__SFAccount__c != null LIMIT 5000]);

                    //for(Opportunity opp : referringPartnersToUpdate){
                    //    // UPDATE OPP'S Referring_Partner_Primary__c IF APPLICABLE
                    //    if(rvAccountMap.containsKey(opp.RVPE__RVAccount__c) && opp.Referring_Partner_Primary__c != rvAccountMap.get(opp.RVPE__RVAccount__c).RVPE__SFAccount__c){
                    //        opp.Referring_Partner_Primary__c = rvAccountMap.get(opp.RVPE__RVAccount__c).RVPE__SFAccount__c;
                    //    }
                    //}
                //}
                /////////////////////

                // GET OPPORTUNITIES QUALIFIED FOR Partner_Rep__c UPDATE
                List<Opportunity> partnerRepsToUpdate = new List<Opportunity>();
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null && outdatedOpps.containsKey(newOrUpdatedOpp.Id) ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                    if(newOrUpdatedOpp.Referring_Partner_Primary__c != null && (outdatedOpp == null || 
                                                                                newOrUpdatedOpp.Referring_Partner_Primary__c != outdatedOpp.Referring_Partner_Primary__c ||
                                                                                newOrUpdatedOpp.Team_2__c != outdatedOpp.Team_2__c ||
                                                                                (ClosedWonStatuses.contains(newOrUpdatedOpp.StageName) && !ClosedWonStatuses.contains(outdatedOpp.StageName)))){
                        // NEW OPP WITH Referring_Partner_Primary__c, OR CHANGED Referring_Partner_Primary__c, OR CHANGED Team_2__c, OR OPP HAS BEEN CLOSED WON
                        partnerRepsToUpdate.add(newOrUpdatedOpp);
                    }
                }

                // PROCESS Partner_Rep__c UPDATES
                if(!partnerRepsToUpdate.isEmpty()){

                    // GET CUSTOM METADATA MAPPINGS
                    Map<Id, String> partnerRepByAccountId = new Map<Id, String>();
                    Map<String, String> partnerRepByTeam = new Map<String, String>();
                    for(Opp_Partner_Rep_Mapping__mdt partnerMap : OppPartnerRepMappings){
                        if(String.isNotBlank(partnerMap.AccountId__c)){
                            partnerRepByAccountId.put(partnerMap.AccountId__c, partnerMap.Partner_Rep__c); // MAPPING SPECIFIES AN ACCOUNT ID
                        }
                        else if(String.isNotBlank(partnerMap.Team__c)){
                            partnerRepByTeam.put(partnerMap.Team__c, partnerMap.Partner_Rep__c); // MAPPING SPECIFIES A TEAM
                        }
                    }

                    for(Opportunity opp : partnerRepsToUpdate){
                        if(partnerRepByTeam.containsKey(opp.Team_2__c)){
                            opp.Partner_Rep__c = partnerRepByTeam.get(opp.Team_2__c); // SET Partner_Rep__c BASED ON TEAM
                        }
                        else if(partnerRepByAccountId.containsKey(opp.Referring_Partner_Primary__c)){
                            opp.Partner_Rep__c = partnerRepByAccountId.get(opp.Referring_Partner_Primary__c); // SET Partner_Rep__c BASED ON ACCOUNT ID
                        }
                        else{
                            opp.Partner_Rep__c = 'Unmanaged'; // NO MAPPING FOUND, SET TO UNMANAGED
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'updateReferringPartnerFields');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'updateReferringPartnerFields', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @author Conga Services
    * @date 20181107
    * @description setAmendmentCurrentMRR - Populates and updates the Current MRR fields on Amendment Opportunities
    *                                             --- EXECUTED BY OPPORTUNITY BEFORE INSERT AND BEFORE UPDATE TRIGGER ---
    * @param List<Opportunity> newOrUpdatedOpps - New or updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Outdated Opportunity records   
    * @return void
    */
    public static void setAmendmentCurrentMRR(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','setAmendmentCurrentMRR') && newOrUpdatedOpps != null){

                // GET CONTRACT IDS FROM QUALIFYING OPPORTUNITIES
                Set<Id> contractIds = new Set<Id>();
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                    if(newOrUpdatedOpp.SBQQ__AmendedContract__c != null && (outdatedOpp == null || newOrUpdatedOpp.SBQQ__AmendedContract__c != outdatedOpp.SBQQ__AmendedContract__c)){
                        contractIds.add(newOrUpdatedOpp.SBQQ__AmendedContract__c);
                    }
                }

                if(!contractIds.isEmpty()){
                    // GET OPP AVERAGE MRR FIELD MAPPING
                    Map<String, String> productLineToFieldMap = new Map<String, String>();
                    for(Opp_Average_MRR_Mapping__mdt meta : [SELECT FieldId__r.QualifiedAPIName, Product_Line__c FROM Opp_Average_MRR_Mapping__mdt WHERE ObjectId__r.QualifiedAPIName = 'Opportunity']){
                        productLineToFieldMap.put(meta.Product_Line__c, meta.FieldId__r.QualifiedAPIName);
                    }
  
                    // GET CURRENT MRR BY CONTRACT AND PRODUCT LINE
                    Map<Id, Map<String, Decimal>> currentMRRMap = new Map<Id, Map<String, Decimal>>();
                    for(AggregateResult result : [SELECT SBQQ__Contract__c, SBQQ__Product__r.Product_Line__c, SUM(Average_MRRFx__c) mrr FROM SBQQ__Subscription__c
                                                  WHERE SBQQ__Contract__c IN :contractIds AND SBQQ__Product__r.Product_Line__c IN :productLineToFieldMap.keySet()
                                                  GROUP BY SBQQ__Contract__c, SBQQ__Product__r.Product_Line__c]){
                        
                        Id contractId = (Id)result.get('SBQQ__Contract__c');
                        String productLine = (String)result.get('Product_Line__c');
                        Decimal mrr = (Decimal)result.get('mrr');
                        if(!currentMRRMap.containsKey(contractId)){
                            currentMRRMap.put(contractId, new Map<String, Decimal>());
                        }
                        currentMRRMap.get(contractId).put(productLine, mrr);
                    }

                    // LOOP OVER EACH NEW OR UPDATED AMENDED OPP AND SET CURRENT MRR
                    for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                        if(currentMRRMap.containsKey(newOrUpdatedOpp.SBQQ__AmendedContract__c)){                   
                            for(String productLine : currentMRRMap.get(newOrUpdatedOpp.SBQQ__AmendedContract__c).keySet()){
                                if(productLineToFieldMap.containsKey(productLine)){
                                    newOrUpdatedOpp.put(productLineToFieldMap.get(productLine), currentMRRMap.get(newOrUpdatedOpp.SBQQ__AmendedContract__c).get(productLine));
                                }
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'setAmendmentCurrentMRR');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'setAmendmentCurrentMRR', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20190322
    * @description updateOnboardingSpecialist -
    *                             --- EXECUTED BY OPPORTUNITY BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<Opportunity> newOrUpdatedOpps - List of new or updated Opportunity records
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunity records 
    * @return void
    */
    public static void updateOnboardingSpecialist(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps, Map<Id, Account> parentAccounts){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','updateOnboardingSpecialist') && newOrUpdatedOpps != null){

                // UPDATE QUALIFIED OPPS
                List<Opportunity> qualifiedOpps = new List<Opportunity>();
                Set<Id> parentAccountIds = new Set<Id>();
                if(parentAccounts == null){ // METHOD CALLED FROM OPP TRIGGER, QUALIFY OPPS
                    for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                        Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                        if(outdatedOpp == null || (outdatedOpp != null && (newOrUpdatedOpp.Opportunity_Booking_Stamp__c != outdatedOpp.Opportunity_Booking_Stamp__c || 
                                                                           newOrUpdatedOpp.Onboarding_Specialist_OverrideId__c != outdatedOpp.Onboarding_Specialist_OverrideId__c ||
                                                                           newOrUpdatedOpp.Onboarding_SpecialistId__c != outdatedOpp.Onboarding_SpecialistId__c))){
                            qualifiedOpps.add(newOrUpdatedOpp);
                            parentAccountIds.add(newOrUpdatedOpp.AccountId); // PARENT ACCOUNT MAY BE NEEDED FOR ZIP CODE DATA
                        }
                    }
                }
                else if(!parentAccounts.isEmpty()){ // METHOD CALLED FROM ACCOUNT TRIGGER, OPPS ALREADY QUALIFIED
                    qualifiedOpps.addAll(newOrUpdatedOpps);
                }

                if(!qualifiedOpps.isEmpty()){

                    // GET PARENT ACCOUNTS
                    Map<Id, Account> relatedParentAccountsMap = null;
                    if(!parentAccountIds.isEmpty() && parentAccounts == null){
                        relatedParentAccountsMap = new Map<Id, Account>([SELECT Id, BillingPostalCode, BillingCountry FROM Account WHERE Id IN :parentAccountIds AND BillingPostalCode != null]);
                    }
                    else if(parentAccounts != null){
                        relatedParentAccountsMap = parentAccounts;
                    }

                    // GET OPPORTUNITY ONBOARDING SPECIALISTS CUSTOM METADATA
                    Id defaultSpecialistId = null;
                    Id danielSpecialistId = null;
                    List<Opportunity_Onboarding_Specialists__mdt> specialists = new List<Opportunity_Onboarding_Specialists__mdt>();
                    for(Opportunity_Onboarding_Specialists__mdt specialist : OppOnboardingSpecialists){
                        specialists.add(specialist);

                        // SET DEFAULT IF FOUND
                        if(specialist.Default__c){
                            defaultSpecialistId = specialist.Onboarding_Specialist__c;
                        }

                        // SET DANIEL IF FOUND
                        if(specialist.Onboarding_Specialist__c == '00550000006ukCOAAY'){
                            danielSpecialistId = specialist.Onboarding_Specialist__c;
                        }
                    }

                    // PROCESS QUALIFIED OPPS
                    for(Opportunity newOrUpdatedOpp : qualifiedOpps){
                        Account parentAccount = relatedParentAccountsMap != null ? relatedParentAccountsMap.get(newOrUpdatedOpp.AccountId) : null;
                        newOrUpdatedOpp.Onboarding_SpecialistId__c = null;

                        if(newOrUpdatedOpp.Onboarding_Specialist_OverrideId__c != null){

                            // OVERRIDE ADDED, USE SPECIFIED USER
                            newOrUpdatedOpp.Onboarding_SpecialistId__c = newOrUpdatedOpp.Onboarding_Specialist_OverrideId__c;
                        }
                        else{
                            // NO OVERRIDE, ASSIGN USING CUSTOM METADATA

                            // ATTEMPT MATCHING TO A TEAM
                            for(Opportunity_Onboarding_Specialists__mdt specialist : specialists){
                                if(String.isNotBlank(newOrUpdatedOpp.Opportunity_Booking_Stamp__c) && String.isNotBlank(specialist.Team__c) && 
                                   newOrUpdatedOpp.Opportunity_Booking_Stamp__c.startsWith(specialist.Team__c)){
                                    newOrUpdatedOpp.Onboarding_SpecialistId__c = specialist.Onboarding_Specialist__c == 'None' ? null : specialist.Onboarding_Specialist__c;
                                    break;
                                }
                            }

                            // ATTEMPT MATCHING TO A ZIP CODE IF A TEAM MATCH WAS NOT MADE
                            if(newOrUpdatedOpp.Onboarding_SpecialistId__c == null){
                                for(Opportunity_Onboarding_Specialists__mdt specialist : specialists){
                                    if(parentAccount != null && parentAccount.BillingPostalCode.left(2).isNumeric() && parentAccount.BillingCountry == 'United States' && String.isNotBlank(specialist.US_Zip_Start__c) && String.isNotBlank(specialist.US_Zip_End__c)){
                                        Integer shortAcctPostalCode = parentAccount.BillingPostalCode.left(1) == '0' ? 0 : Integer.valueof(parentAccount.BillingPostalCode.left(2));
                                        Integer specialistZipCodeStart = specialist.US_Zip_Start__c.left(1) == '0' ? 0 : Integer.valueof(specialist.US_Zip_Start__c);
                                        Integer specialistZipCodeEnd = Integer.valueof(specialist.US_Zip_End__c);

                                        // CHECK IF ACCOUNT ZIP FALLS WITHIN SPECIALIST ZIP RANGE
                                        if(shortAcctPostalCode >= specialistZipCodeStart && shortAcctPostalCode <= specialistZipCodeEnd){
                                            newOrUpdatedOpp.Onboarding_SpecialistId__c = specialist.Onboarding_Specialist__c;
                                            break;
                                        }
                                    }
                                }
                            }
                        }

                        // IF NO SPECIALIST IS ASSIGNED YET, ASSIGN A DEFAULT
                        if(newOrUpdatedOpp.Onboarding_SpecialistId__c == null){
                            if(String.isNotBlank(newOrUpdatedOpp.Opportunity_Booking_Stamp__c) && newOrUpdatedOpp.Opportunity_Booking_Stamp__c.startsWith('AMER')){
                                newOrUpdatedOpp.Onboarding_SpecialistId__c = danielSpecialistId; // NA BOOKING STAMP, DEFAULT TO DANIEL
                            }
                            else{
                                newOrUpdatedOpp.Onboarding_SpecialistId__c = defaultSpecialistId; // ANYTHING ELSE, USE METADATA DEFAULT
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'updateOnboardingSpecialist');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityHelper', 'updateOnboardingSpecialist', newOrUpdatedOpps, ex, true);
        }
    }

    /**
    * @author jcdiaz@systemyc.com
    * @date 2019-03-28
    * @description setTeamStampFields - Populates team stamp fields until it's Closed Won or Closed Lost.
    * @param List<Opportunity> newOrUpdatedOpps - New Opportunity records
    * @param List<Opportunity> outdatedOpps - Old Opportunity records
    * @return void
    */
    public static void setTeamStampFields(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','setTeamStampFields') && newOrUpdatedOpps != null) {

                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                Set<Id> opportunityAccountIds = new Set<Id>();
                Set<Id> opportunityOwnerUserIds = new Set<Id>();

                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps) {
                    Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                    
                    // FIRE WHEN CREATED, WHEN THE OWNER IS CHANGED, OR THE OPP IS CLOSED
                    if(outdatedOpps == null || newOrUpdatedOpp.Bookings_OwnerId__c != outdatedOpp.Bookings_OwnerId__c || ((newOrUpdatedOpp.StageName == 'Closed Won' || newOrUpdatedOpp.StageName == 'Closed Lost') &&
                                                                                                                            outdatedOpp.StageName != 'Closed Won' && outdatedOpp.StageName != 'Closed Lost')){
                        oppsToUpdate.add(newOrUpdatedOpp);
                        opportunityAccountIds.add(newOrUpdatedOpp.AccountId);
                        opportunityAccountIds.add(newOrUpdatedOpp.Billing_Party__c);
                        opportunityOwnerUserIds.add(newOrUpdatedOpp.OwnerId);
                        opportunityOwnerUserIds.add(newOrUpdatedOpp.Bookings_OwnerId__c);
                    }
                }

                if(!oppsToUpdate.isEmpty()) {
                    // GET OPP RECORD TYPES
                    Map<String, Id> oppRecordTypes = RecordTypes.get('Opportunity');

                    Map<Id,Account> oppAccountsMap = new Map<Id, Account>([SELECT Id, RecordType.DeveloperName, TM_RegionId__r.Name, TM_Segment_TerritoryId__r.Name,
                                                                                  CS_Division_Stamp__c, TM_Territory_ManagerId__c, Customer_Success_Manager__c,
                                                                                  Customer_Success_Manager__r.Name, TM_Territory_ManagerId__r.Segment__c, TM_SegmentId__c, 
                                                                                  TM_SegmentId__r.Name, Active_Partner_Profile__c,
                                                                                  (SELECT Id, Composer_Adoption_Score__c FROM Adoption_Scores__r ORDER BY CreatedDate DESC LIMIT 1)
                                                                           FROM Account WHERE Id IN :opportunityAccountIds]);

                    Map<Id,User> oppOwnersMap = new Map<Id,User>([SELECT Id, Geo__c, Team_2__c, Segment__c FROM User WHERE Id IN :opportunityOwnerUserIds]);
                    for(Opportunity oppToUpdate : oppsToUpdate) {
                        Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(oppToUpdate.Id) : null;
                        Account oppAccount = oppAccountsMap.get(oppToUpdate.AccountId);
                        Account billingParty = oppAccountsMap.get(oppToUpdate.Billing_Party__c);
                        User oppBookingsOwner = oppOwnersMap.get(oppToUpdate.Bookings_OwnerId__c);

                        // STAMP RESELLER ON INDIRECT OPPS ONLY WHEN CLOSED WON
                        if(outdatedOpp != null && oppToUpdate.RecordTypeId == oppRecordTypes.get('Indirect') && oppToUpdate.StageName == 'Closed Won' && outdatedOpp.StageName != 'Closed Won' &&
                            billingParty != null && billingParty.RecordType.DeveloperName == 'Partner_Account'){
                           oppToUpdate.Reseller__c = billingParty.Active_Partner_Profile__c;
                        }

                        // STAMP ADOPTION SCORE FOR RENEWALS AND AMENDMENTS ONLY WHEN CLOSED WON
                        if(outdatedOpp != null && oppToUpdate.StageName == 'Closed Won' && outdatedOpp.StageName != 'Closed Won' && 
                            (oppToUpdate.Type == 'Existing Business' || oppToUpdate.Type == 'Renewal') && !oppAccount.Adoption_Scores__r.isEmpty()){
                           oppToUpdate.Composer_Adoption_Score_Stamp__c = oppAccount.Adoption_Scores__r[0].Composer_Adoption_Score__c;
                        }

                        // Opportunity Owner Geo Stamp
                        oppToUpdate.Opportunity_Owner_Geo_Stamp__c = (oppBookingsOwner != null ? oppBookingsOwner.Geo__c : null);

                        // Opportunity Owner Team Stamp
                        oppToUpdate.Team_2__c = (oppBookingsOwner != null ? oppBookingsOwner.Team_2__c : null);

                        // Opportunity Region
                        oppToUpdate.Region_2__c = (oppAccount != null ? oppAccount.TM_RegionId__r.Name : null);

                        // Opportunity Territory
                        oppToUpdate.Territory__c = (oppAccount != null ? oppAccount.TM_Segment_TerritoryId__r.Name : null);

                        // Opportunity Segment Stamp
                        String oppOwnerSegment = oppBookingsOwner != null ? oppBookingsOwner.Segment__c : null;
                        String oppAccountTerritoryManagerSegment = oppAccount == null || oppAccount.TM_Territory_ManagerId__r == null ? null : oppAccount.TM_Territory_ManagerId__r.Segment__c;
                        String oppAccountSegment = oppAccount == null || oppAccount.TM_SegmentId__c == null ? 'Other' : oppAccount.TM_SegmentId__r.Name;
                        
                        ///////// OLD VERSION
                        //if(oppToUpdate.Team_2__c == 'Sales'){
                        //    oppToUpdate.Opportunity_Segment_Stamp__c = oppOwnerSegment;
                        //}
                        //else{
                        //    oppToUpdate.Opportunity_Segment_Stamp__c = String.isBlank(oppAccountTerritoryManagerSegment) ? oppAccountSegment.replace('NA ', '').replace('APAC ', '').replace('EMEA ', '') : oppAccountTerritoryManagerSegment;
                        //}    

                        ///////// NEW VERSION TO REPLACE OLD ONCE APPROVED
                        if(oppBookingsOwner != null && oppBookingsOwner.Geo__c != null && oppBookingsOwner.Geo__c != 'AMER'){
                            oppToUpdate.Opportunity_Segment_Stamp__c = oppAccountSegment.replace('AMER ', '').replace('APAC ', '').replace('EMEA ', '');
                        }
                        else if(oppBookingsOwner != null && oppToUpdate.Team_2__c == 'Sales'){
                            oppToUpdate.Opportunity_Segment_Stamp__c = oppBookingsOwner.Segment__c;
                        }
                        else{
                            oppToUpdate.Opportunity_Segment_Stamp__c = String.isBlank(oppAccountTerritoryManagerSegment) ? oppAccountSegment.replace('AMER ', '').replace('APAC ', '').replace('EMEA ', '') : oppAccountTerritoryManagerSegment;
                        }

                        // CS Division
                        if(oppToUpdate.Type != 'New Business'){
                            oppToUpdate.CS_Division__c = oppAccount != null ? oppAccount.CS_Division_Stamp__c : null;
                        }

                        // Opportunity Booking Stamp
                        if(oppToUpdate.Team_2__c != 'Sales' && oppToUpdate.Team_2__c != 'Customer Success'){
                            oppToUpdate.Opportunity_Booking_Stamp__c = oppToUpdate.Team_2__c;
                        }
                        else if(oppToUpdate.Team_2__c == 'Sales' || oppToUpdate.Team_2__c == 'Customer Success'){
                            if(oppToUpdate.Opportunity_Segment_Stamp__c == 'Growth' || oppToUpdate.Opportunity_Segment_Stamp__c == 'Mid Commercial' || oppToUpdate.Opportunity_Segment_Stamp__c == 'General Commercial') {
                                
                                ////// OLD VERSION
                                //oppToUpdate.Opportunity_Booking_Stamp__c = String.Format('{0} - CORPORATE - {1}', new List<String>{ oppToUpdate.Opportunity_Owner_Geo_Stamp__c, oppToUpdate.Team_2__c });
                                
                                ////// NEW VERSION TO REPLACE OLD ONCE APPROVED
                                oppToUpdate.Opportunity_Booking_Stamp__c = String.Format('{0} - COMMERCIAL - {1}', new List<String>{ oppToUpdate.Opportunity_Owner_Geo_Stamp__c, oppToUpdate.Team_2__c });
                            }
                            else if(oppToUpdate.Opportunity_Segment_Stamp__c == 'Enterprise') {
                                oppToUpdate.Opportunity_Booking_Stamp__c = String.Format('{0} - ENTERPRISE - {1}', new List<String>{ oppToUpdate.Opportunity_Owner_Geo_Stamp__c, oppToUpdate.Team_2__c });
                            }
                            else if(oppToUpdate.Opportunity_Segment_Stamp__c == 'Other') {
                                oppToUpdate.Opportunity_Booking_Stamp__c = String.Format('{0} - OTHER - {1}', new List<String>{ oppToUpdate.Opportunity_Owner_Geo_Stamp__c, oppToUpdate.Team_2__c });
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'setTeamStampFields');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityHelper', 'setTeamStampFields', newOrUpdatedOpps, ex, true);  
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190429
    * @description setConvertedOppChannelSource - Populates the Oppty_Channel_Source_2__c field of a New Business Opportunity created from a converted Lead
    *                                            --- EXECUTED BY OPPORTUNITY BEFORE INSERT TRIGGER ---
    * @param List<Opportunity> newOpps - Map of new Opportunities
    * @return void
    */
    public static void setConvertedOppChannelSource(List<Opportunity> newOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','setConvertedOppChannelSource') && newOpps != null){

                // GET IDS OF CONVERTED LEADS
                List<Opportunity> qualifiedOpps = new List<Opportunity>();
                for(Opportunity newOpp : newOpps){
                    if(String.isNotBlank(newOpp.Lead_Opp_Conversion_Lead_Id__c) && newOpp.Type == 'New Business'){
                        qualifiedOpps.add(newOpp);
                    }
                }

                if(!qualifiedOpps.isEmpty()){

                    // UPDATE OPPS
                    for(Opportunity qualifiedOpp : qualifiedOpps){
                        Lead parentLead = ParentLeadsMap.get(qualifiedOpp.Lead_Opp_Conversion_Lead_Id__c);
                        if(parentLead != null){
                            qualifiedOpp.Channel_Source_2__c = parentLead.Channel_Source_2__c; /// IN CASE LEAD FIELD MAPPINGS ARE NOT SET
                            qualifiedOpp.Oppty_Channel_Source_2__c = parentLead.Channel_Source_2__c;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'setConvertedOppChannelSource');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityHelper', 'setConvertedOppChannelSource', newOpps, ex, true);
        }
    }

    /**
    * @author CoE, ERedding
    * @date 20200727
    * @description setOppProductInterest - Populates the Product_of_Interest__c field of a New Business Opportunity created from a converted Lead
    *                                        --- EXECUTED BY OPPORTUNITY BEFORE INSERT TRIGGER ---
    * @param List<Opportunity> newOpps - Map of new Opportunities
    * @return void
    */
    public static void setOppProductInterest(List<Opportunity> newOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','setOppProductInterest') && newOpps != null){

                // GET IDS OF CONVERTED LEADS
                List<Opportunity> qualifiedOpps = new List<Opportunity>();
                for(Opportunity newOpp : newOpps){
                    if(String.isNotBlank(newOpp.Lead_Opp_Conversion_Lead_Id__c) && (newOpp.Type == 'New Business' || newOpp.Type == 'Existing Business')){
                        qualifiedOpps.add(newOpp);
                    }
                }

                if(!qualifiedOpps.isEmpty()){
                    Map<String, String> leadProdToOppProdMappings = new Map<String, String>();
                    for(Lead_Opp_Product_Interest_Mappings__mdt mapping : [SELECT Lead_Product_Interest__c, Opp_Product_Interest__c FROM Lead_Opp_Product_Interest_Mappings__mdt]){
                        leadProdToOppProdMappings.put(mapping.Lead_Product_Interest__c, mapping.Opp_Product_Interest__c);
                    }

                    if(!leadProdToOppProdMappings.isEmpty()){
                        // UPDATE OPPS
                        for(Opportunity qualifiedOpp : qualifiedOpps){
                            Lead parentLead = ParentLeadsMap.get(qualifiedOpp.Lead_Opp_Conversion_Lead_Id__c);
                            if(parentLead != null && String.isNotBlank(parentLead.Product_Interest__c) && leadProdToOppProdMappings.containsKey(parentLead.Product_Interest__c)){
                                qualifiedOpp.Product_of_Interest__c = leadProdToOppProdMappings.get(parentLead.Product_Interest__c);
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'setOppProductInterest');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityHelper', 'setOppProductInterest', newOpps, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190709
    * @description updatePartnerExpertiseScore - Calculates an Opportunity's partner expertise score
    *                                            --- EXECUTED BY OPPORTUNITY BEFORE UPDATE TRIGGER ---
    * @param List<Opportunity> updatedOpps - List of updated Opportunities
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunities       
    * @return void
    */
    public static void updatePartnerExpertiseScore(List<Opportunity> updatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','updatePartnerExpertiseScore') && updatedOpps != null){

                // GET QUALIFIED OPPS
                List<Opportunity> qualifiedOpps = new List<Opportunity>();
                Set<Id> implementationPartnerIds = new Set<Id>();
                for(Opportunity updatedOpp : updatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(updatedOpp.Id) : null;
                    if(outdatedOpp == null || updatedOpp.ImplementationPartnerPrimary__c != outdatedOpp.ImplementationPartnerPrimary__c || 
                                              updatedOpp.ImplementationPartnerSecondary__c != outdatedOpp.ImplementationPartnerSecondary__c){
                        qualifiedOpps.add(updatedOpp);
                        implementationPartnerIds.add(updatedOpp.ImplementationPartnerPrimary__c);
                        implementationPartnerIds.add(updatedOpp.ImplementationPartnerSecondary__c);
                    }
                }

                if(!qualifiedOpps.isEmpty()){

                    // GET CUSTOM METADATA SETTINGS
                    Set<String> scoreApplicableLines = new Set<String>();
                    Set<String> chatterApplicableLines = new Set<String>();
                    Set<Id> chatterRecipients = new Set<Id>();
                    List<Partner_Expertise_Settings__mdt> settingsMetadata = [SELECT Product_Lines_for_Scoring__c, Product_Lines_for_Chatter_Notifications__c, Chatter_Notification_Recipients__c
                                                                              FROM Partner_Expertise_Settings__mdt LIMIT 1];

                    if(!settingsMetadata.isEmpty() && String.isNotEmpty(settingsMetadata[0].Product_Lines_for_Scoring__c)){
                        scoreApplicableLines = new Set<String>(settingsMetadata[0].Product_Lines_for_Scoring__c.replace('\r','').split('\n'));
                        chatterApplicableLines = new Set<String>(settingsMetadata[0].Product_Lines_for_Chatter_Notifications__c.replace('\r','').split('\n'));
                        
                        for(String chatterRecipient : settingsMetadata[0].Chatter_Notification_Recipients__c.replace('\r','').split('\n')){
                            String chatterRecipientId = chatterRecipient.left(18);
                            if(UtilityClass.validateId(chatterRecipientId)){
                                chatterRecipients.add(chatterRecipientId);
                            }
                        }
                    }

                    // GET PARENT ACCOUNTS
                    Map<Id, Account> implementationPartners = new Map<Id, Account>([SELECT Id, Partner_Certified__c, Partner_Specialist__c, Partner_Expert__c FROM Account 
                                                                                    WHERE Id IN :implementationPartnerIds]);

                    // CALCULATE FUTURE MRR FROM OPP ITEMS
                    Map<Id, Map<String, Decimal>> futureMRRRollupMap = new Map<Id, Map<String, Decimal>>();
                    Set<Id> oppsQualifyingForChatter = new Set<Id>();
                    for(OpportunityLineItem oppItem : [SELECT OpportunityId, Average_MRRFx__c, Product_LineFx__c, Revenue_TypeFx__c, MRR_Override__c, Service_Event_MRR__c, UnitPrice,
                                                              Quantity, Full_Years__c, Full_Years_Ceiling__c, Product_End_Date__c, ServiceDate, Leap_Year_Day__c, MRR_Proration__c
                                                       FROM OpportunityLineItem WHERE OpportunityId IN :qualifiedOpps]){

                        if(chatterApplicableLines.contains(oppItem.Product_LineFx__c)){
                            oppsQualifyingForChatter.add(oppItem.OpportunityId);
                        }

                        // DETERMINE FUTURE MRR OF QUALIFYING PRODUCT LINES BY GROUPING AVERAGE MRR CALCULATIONS BY OPPORTUNITY AND PRODUCT LINE
                        if(scoreApplicableLines.contains(oppItem.Product_LineFx__c)){
                            if(!futureMRRRollupMap.containsKey(oppItem.OpportunityId)){
                                futureMRRRollupMap.put(oppItem.OpportunityId, new Map<String, Decimal>());
                            }                        

                            if(futureMRRRollupMap.get(oppItem.OpportunityId).containsKey(oppItem.Product_LineFx__c)){
                                if(futureMRRRollupMap.get(oppItem.OpportunityId).get(oppItem.Product_LineFx__c) == null && oppItem.Average_MRRFx__c != null){
                                    futureMRRRollupMap.get(oppItem.OpportunityId).put(oppItem.Product_LineFx__c, oppItem.Average_MRRFx__c);
                                }
                                else if(futureMRRRollupMap.get(oppItem.OpportunityId).get(oppItem.Product_LineFx__c) != null && oppItem.Average_MRRFx__c != null){
                                    futureMRRRollupMap.get(oppItem.OpportunityId).put(oppItem.Product_LineFx__c, futureMRRRollupMap.get(oppItem.OpportunityId).get(oppItem.Product_LineFx__c) + oppItem.Average_MRRFx__c);
                                }
                            }
                            else{
                                futureMRRRollupMap.get(oppItem.OpportunityId).put(oppItem.Product_LineFx__c, oppItem.Average_MRRFx__c);
                            }
                        }
                    }

                    // UPDATE OPPS
                    for(Opportunity updatedOpp : qualifiedOpps){
                        Opportunity outdatedOpp = outdatedOpps != null  ? outdatedOpps.get(updatedOpp.Id) : null;
                        Map<Integer, String> ratingMap = new Map<Integer, String>{ null => '', 0 => 'Uncertified', 1 => 'Certified', 2 => 'Specialist', 3 => 'Master'};
                        Integer primaryScore;
                        Integer secondaryScore;

                        if(futureMRRRollupMap.containsKey(updatedOpp.Id) && (updatedOpp.ImplementationPartnerPrimary__c != null || updatedOpp.ImplementationPartnerSecondary__c != null)){
                            Account primaryImpPartner = implementationPartners != null ? implementationPartners.get(updatedOpp.ImplementationPartnerPrimary__c) : null;
                            Account secondaryImpPartner = implementationPartners != null ? implementationPartners.get(updatedOpp.ImplementationPartnerSecondary__c) : null;

                            if(primaryImpPartner != null || secondaryImpPartner != null){
                                String primaryMaster = primaryImpPartner != null ? UtilityClass.replaceNull(primaryImpPartner.Partner_Expert__c, '') : '';                                
                                String primarySpecialist = primaryImpPartner != null ? UtilityClass.replaceNull(primaryImpPartner.Partner_Specialist__c, '') : '';
                                String primaryCertified = primaryImpPartner != null ? UtilityClass.replaceNull(primaryImpPartner.Partner_Certified__c, '') : '';
                                String secondaryMaster = secondaryImpPartner != null ? UtilityClass.replaceNull(secondaryImpPartner.Partner_Expert__c, '') : '';                                
                                String secondarySpecialist = secondaryImpPartner != null ? UtilityClass.replaceNull(secondaryImpPartner.Partner_Specialist__c, '') : '';
                                String secondaryCertified = secondaryImpPartner != null ? UtilityClass.replaceNull(secondaryImpPartner.Partner_Certified__c, '') : '';

                                for(String productLine : futureMRRRollupMap.get(updatedOpp.Id).keySet()){
                                    if(futureMRRRollupMap.get(updatedOpp.Id).get(productLine) != null && futureMRRRollupMap.get(updatedOpp.Id).get(productLine) > 0){

                                        //// 0 = NO STARS, 1 = ONE STAR, 2 = TWO STARS, 3 = THREE STARS
                                        // ORDER OF CERTIFICATION = CERTIFIED --> SPECIALIST --> MASTER (Expert)

                                        // DETERMINE LOWEST SCORE FOR PRIMARY IMPLREMENTATION PARTNER
                                        if(primaryScore != 0){ // IF SCORE IS NOT 0 (NO STARS) THEN KEEP EVALUATING

                                            if(primaryScore == null && primaryMaster.contains(productLine)){
                                                primaryScore = 3;
                                            }
                                            else if((primaryScore == null || primaryScore == 3) && (!primaryMaster.contains(productLine) && primarySpecialist.contains(productLine))){
                                                primaryScore = 2;
                                            }                                            
                                            else if((primaryScore == null || primaryScore == 3 || primaryScore == 2) && (!primarySpecialist.contains(productLine) && primaryCertified.contains(productLine))){
                                                primaryScore = 1;
                                            }
                                            else if(!primaryMaster.contains(productLine) && !primarySpecialist.contains(productLine) && !primaryCertified.contains(productLine)){
                                                primaryScore = 0;
                                            }
                                        }

                                        // DETERMINE LOWEST SCORE FOR SECONDARY IMPLREMENTATION PARTNER
                                        if(secondaryScore != 0){ // IF SCORE IS NOT 0 (NO STARS) THEN KEEP EVALUATING

                                            if(secondaryScore == null && secondaryMaster.contains(productLine)){
                                                secondaryScore = 3;
                                            }
                                            else if((secondaryScore == null || secondaryScore == 3) && (!secondaryMaster.contains(productLine) && secondarySpecialist.contains(productLine))){
                                                secondaryScore = 2;
                                            }                                            
                                            else if((secondaryScore == null || secondaryScore == 3 || secondaryScore == 2) && (!secondarySpecialist.contains(productLine) && secondaryCertified.contains(productLine))){
                                                secondaryScore = 1;
                                            }
                                            else if(!secondaryMaster.contains(productLine) && !secondarySpecialist.contains(productLine) && !secondaryCertified.contains(productLine)){
                                                secondaryScore = 0;
                                            }                                            
                                        }
                                    }
                                }
                            }
                        }

                        // UPDATE SCORE
                        if(primaryScore > secondaryScore || primaryScore == secondaryScore){
                            updatedOpp.Partner_Expertise_Score_Text__c = ratingMap.get(primaryScore);
                        }
                        else if(primaryScore < secondaryScore){
                            updatedOpp.Partner_Expertise_Score_Text__c = ratingMap.get(secondaryScore);
                        }

                        // CREATE CHATTER NOTIFICATION IF PARTNER RECEIVED A RED SCORE AND OPP QUALIFIES FOR A CHATTER POST
                        if(updatedOpp.Partner_Expertise_Score_Text__c == 'Uncertified' && oppsQualifyingForChatter.contains(updatedOpp.Id) && !chatterRecipients.isEmpty() && !Test.isRunningTest()){
                            // CREATE PARENT MESSAGE BODY
                            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

                            // CREATE MENTION SEGMENTS AND ADD TO MESSAGE BODY
                            for(Id recipientId : chatterRecipients){
                                ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
                                mentionSegmentInput.Id = recipientId;
                                messageBodyInput.messageSegments.add(mentionSegmentInput);
                            }

                            // CREATE TEXT SEGMENT AND ADD TO MESSAGE BODY
                            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                            textSegmentInput.text = ' This opportunity has received a Partner Expertise score of Not Certified. Please review.';
                            messageBodyInput.messageSegments.add(textSegmentInput);

                            // CREATE CHATTER POST USING MESSAGE BODY
                            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                            feedItemInput.body = messageBodyInput;
                            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                            feedItemInput.subjectId = updatedOpp.Id;
                            ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'updatePartnerExpertiseScore');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityHelper', 'updatePartnerExpertiseScore', updatedOpps, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190821
    * @description updateChildQuoteOwners - Copies an Opp's new owner down to its primary SBQQ Quote
    *                                            --- EXECUTED BY OPPORTUNITY AFTER UPDATE TRIGGER ---
    * @param Map<Id, Opportunity> updatedOpps - Map of updated Opportunities
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunities       
    * @return void
    */
    public static void updateChildQuoteOwners(Map<Id, Opportunity> updatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','updateChildQuoteOwners') && updatedOpps != null){

                Set<Id> qualifiedOpps = new Set<Id>();
                for(Opportunity updatedOpp : updatedOpps.values()){
                    Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(updatedOpp.Id) : null;
                    if(outdatedOpp != null && updatedOpp.OwnerId != outdatedOpp.OwnerId){
                        qualifiedOpps.add(updatedOpp.Id);
                    }
                }

                if(!qualifiedOpps.isEmpty()){
                    // GET CHILD QUOTES AND UPDATE
                    List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
                    for(SBQQ__Quote__c quote : [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :qualifiedOpps AND SBQQ__Primary__c = true]){
                        quote.OwnerId = updatedOpps.get(quote.SBQQ__Opportunity2__c).OwnerId;
                        quotesToUpdate.add(quote);
                    }

                    if(!quotesToUpdate.isEmpty()){
                        Database.saveResult[] quoteResults = Database.update(quotesToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(quoteResults, 'OpportunityHelper', 'updateChildQuoteOwners', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'updateChildQuoteOwners');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityHelper', 'updateChildQuoteOwners', updatedOpps, ex, true);
        }
    }

    ////////////////////////// NEW VERSION OF THE PURCHASE ORDER REQUIRED SYNC CODE TO USE WHEN TESTED //////////////////////////
    /**
    * @author ECS, ERedding
    * @date 20190909
    * @description updatePurchaseOrderRequired - Copies the false to true change of the PO Required field to the parent contract
    *                                                 ****** EXECUTED BY OPPORTUNITY BEFORE INSERT AND AFTER UPDATE TRIGGERS ******
    * @param List<Opportunity> newOrUpdatedOpps - List of updated Opportunities
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunities
    * @return void
    */
    public static void updatePurchaseOrderRequired(List<Opportunity> newOrUpdatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','updatePurchaseOrderRequired') && newOrUpdatedOpps != null){

                // GET QUALIFYING OPPORTUNITIES
                Set<Id> parentContractsIds = new Set<Id>();
                for(Opportunity newOrUpdatedOpp : newOrUpdatedOpps){
                    Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(newOrUpdatedOpp.Id) : null;
                
                    // AMENDMENT CONTRACT
                    if(newOrUpdatedOpp.Name.contains('Amend') && newOrUpdatedOpp.Type == 'Existing Business' && newOrUpdatedOpp.SBQQ__AmendedContract__c != null){
                        Contract parentAmendedContract = ParentContractsMap.get(newOrUpdatedOpp.SBQQ__AmendedContract__c);

                        // NEW OPP, SET PURCHASE ORDER REQUIRED FROM PARENT AMENDED CONTRACT
                        if(outdatedOpp == null && parentAmendedContract != null && parentAmendedContract.Purchase_Order_Required__c){
                            newOrUpdatedOpp.Purchase_Order_Required__c = true;
                        }
                        // OPP UPDATED, ADD PARENT CONTRACT IDS TO SET
                        else if(newOrUpdatedOpp.Purchase_Order_Required__c && newOrUpdatedOpp.Purchase_Order_Required__c != outdatedOpp.Purchase_Order_Required__c){
                            // ADD PARENT CONTRACTS
                            parentContractsIds.add(newOrUpdatedOpp.ContractId);
                            parentContractsIds.add(newOrUpdatedOpp.SBQQ__AmendedContract__c);
                        }
                    }
                    // RENEWAL CONTRACT
                    else if(newOrUpdatedOpp.Type == 'Renewal' && newOrUpdatedOpp.SBQQ__RenewedContract__c != null){
                        Contract parentRenewedContract = ParentContractsMap.get(newOrUpdatedOpp.SBQQ__RenewedContract__c);

                        // NEW OPP, SET PURCHASE ORDER REQUIRED FROM PARENT RENEWED CONTRACT
                        if(outdatedOpp == null && parentRenewedContract != null && parentRenewedContract.Purchase_Order_Required__c){
                            newOrUpdatedOpp.Purchase_Order_Required__c = true;
                        }
                        // OPP UPDATED, ADD PARENT CONTRACT IDS TO SET
                        else if(newOrUpdatedOpp.Purchase_Order_Required__c && newOrUpdatedOpp.Purchase_Order_Required__c != outdatedOpp.Purchase_Order_Required__C){
                            // ADD PARENT CONTRACTS
                            parentContractsIds.add(newOrUpdatedOpp.ContractId);
                            parentContractsIds.add(newOrUpdatedOpp.SBQQ__RenewedContract__c);
                        }
                    }
                }

                // UPDATE PARENT CONTRACTS WHERE NECESSARY
                if(!parentContractsIds.isEmpty()){

                    List<Contract> contractsToUpdate = new List<Contract>();
                    for(Id parentContractId : parentContractsIds){
                        if(ParentContractsMap.containsKey(parentContractId) && ParentContractsMap.get(parentContractId).Purchase_Order_Required__C == false){
                            contractsToUpdate.add(new Contract(Id = parentContractId, Purchase_Order_Required__C = true));
                        }
                    }

                    if(!contractsToUpdate.isEmpty()){
                        Database.saveResult[] contractResults = Database.update(contractsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(contractResults, 'OpportunityHelper', 'updatePurchaseOrderRequired', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'updatePurchaseOrderRequired');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityHelper', 'updatePurchaseOrderRequired', newOrUpdatedOpps, ex, true);
        }
    }


    ////////////////////////// OLD VERSION OF THE PURCHASE ORDER REQUIRED SYNC CODE. ABOVE METHOD IS THE NEW ONE TO USE WHEN TESTED //////////////////////////
    /**
    * @author ECS, ERedding
    * @date 20190909
    * @description copyPORequiredToParentContract - Copies the false to true change of the PO Required field to the parent contract
    *                                            --- EXECUTED BY OPPORTUNITY AFTER UPDATE TRIGGER ---
    * @param List<Opportunity> updatedOpps - List of updated Opportunities
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunities
    * @return void
    */
    //public static void copyPORequiredToParentContract(List<Opportunity> updatedOpps, Map<Id, Opportunity> outdatedOpps){
    //    try{
    //        if(TriggerHelper.DoExecute('OpportunityHelper','copyPORequiredToParentContract') && updatedOpps != null){
    //            Set<Id> parentContractIds = new Set<Id>();
    //            for(Opportunity updatedOpp : updatedOpps){
    //                Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(updatedOpp.Id) : null;
    //                if(outdatedOpp != null && updatedOpp.Purchase_Order_Required__c && updatedOpp.Purchase_Order_Required__c != outdatedOpp.Purchase_Order_Required__c){
    //                    // ALWAYS UPDATE MASTER CONTRACT
    //                    parentContractIds.add(updatedOpp.ContractId);

    //                    // AMENDMENT CONTRACT
    //                    if(updatedOpp.Name.contains('Amend') && updatedOpp.Type == 'Existing Business' && updatedOpp.SBQQ__AmendedContract__c != null){
    //                        parentContractIds.add(updatedOpp.SBQQ__AmendedContract__c);
    //                    }

    //                    // RENEWAL CONTRACT
    //                    if(updatedOpp.Type == 'Renewal' && updatedOpp.SBQQ__RenewedContract__c != null){
    //                        parentContractIds.add(updatedOpp.SBQQ__RenewedContract__c);
    //                    }
    //                }
    //            }

    //            if(!parentContractIds.isEmpty()){
    //                // GET PARENT CONTRACTS AND UPDATE
    //                List<Contract> contractsToUpdate = new List<Contract>();
    //                for(Contract parentContract : [SELECT Id FROM Contract WHERE Id IN :parentContractIds AND Purchase_Order_Required__c = false]){
    //                    parentContract.Purchase_Order_Required__c = true;
    //                    contractsToUpdate.add(parentContract);
    //                }

    //                if(!contractsToUpdate.isEmpty()){
    //                    Database.saveResult[] contractResults = Database.update(contractsToUpdate, false);
    //                    SystemIssueLogHelper.CheckForDatabaseErrors(contractResults, 'OpportunityHelper', 'copyPORequiredToParentContract', true);
    //                }
    //            }

    //            // END AUDIT IF ONE IS STARTED
    //            TriggerHelper.EndExecute('OpportunityHelper', 'copyPORequiredToParentContract');
    //        }
    //    }
    //    catch(Exception ex) {
    //        SystemIssueLogHelper.LogException('OpportunityHelper', 'copyPORequiredToParentContract', updatedOpps, ex, true);
    //    }
    //}

    /**
    * @author ECS, ERedding
    * @date 20191025
    * @description servicesCommissionRollup - Calculates the amount of Commissionable Services Bookings on Closed Won Opportunities
    *                                            --- EXECUTED BY OPPORTUNITY BEFORE UPDATE TRIGGER ---
    * @param Map<Id, Opportunity> updatedOpps - Map of updated Opportunities
    * @param Map<Id, Opportunity> outdatedOpps - Map of outdated Opportunities
    * @return void
    */
    public static void servicesCommissionRollup(Map<Id, Opportunity> updatedOpps, Map<Id, Opportunity> outdatedOpps){
        try{
            if(TriggerHelper.DoExecute('OpportunityHelper','servicesCommissionRollup') && updatedOpps != null){
                Set<Id> parentOppIds = new Set<Id>();
                for(Opportunity updatedOpp : updatedOpps.values()){
                    Opportunity outdatedOpp = outdatedOpps != null ? outdatedOpps.get(updatedOpp.Id) : null;
                    if(outdatedOpp != null && updatedOpp.StageName == 'Closed Won' && outdatedOpp.StageName != 'Closed Won'){
                        parentOppIds.add(updatedOpp.Id);
                    }
                }

                if(!parentOppIds.isEmpty()){
                    // APPLICABLE PRODUCT FAMILIES
                    Set<String> families = new Set<String>{ 'Professional Services', 'Novatus Contracts', 'Consulting', 'Support', 'Conga Service-Support-Training' };

                    // GET ROLLUP CHILD OPP ITEMS AND UPDATE PARENTS
                    for(AggregateResult result : [SELECT OpportunityId, SUM(TotalPrice) total FROM OpportunityLineItem 
                                                  WHERE OpportunityId IN :parentOppIds AND Product_Family__c IN :families AND Product_MRR_2__c = null
                                                  AND Opportunity_Billing_Frequency__c != 'Consolidated - Annual'
                                                  GROUP BY OpportunityId]){

                        Id opportunityId = (Id)result.get('OpportunityId');
                        Decimal total = (Decimal)result.get('total');

                        if(updatedOpps.containsKey(opportunityId)){
                            updatedOpps.get(opportunityId).Commissionable_Services_Bookings__c = total;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityHelper', 'servicesCommissionRollup');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityHelper', 'servicesCommissionRollup', updatedOpps, ex, true);
        }
    }


}