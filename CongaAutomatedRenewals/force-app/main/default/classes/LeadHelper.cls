/**
* @author Conga Services
* @date 20180615
* @version 1.00
* @description LeadHelper - Various custom functionality for the Lead object. Includes trigger methoods
*/
public without sharing class LeadHelper {

    // LMA LEAD PACKAGE CAMPAIGN MAPPING METADATA
    @testVisible
    private static List<LMA_Lead_Package_Campaign__mdt> LeadPackageCampaigns {
    get {
        if(Test.isRunningTest()){
            LeadPackageCampaigns = LeadHelperTest.LeadPackageCampaignsTestMeta;
        }
        else if(LeadPackageCampaigns == null){
            LeadPackageCampaigns = [SELECT Label, Package__c, AppExchange_Type__c, CampaignId__c FROM LMA_Lead_Package_Campaign__mdt];
        }
        return LeadPackageCampaigns;
    } set; }

    // LEAD PARENT OWNER MAP AND ID SET
    public static Set<Id> OwnerIds {get; set;}
    private static Map<Id, User> OwnerMap {
    get {
        if(OwnerMap == null){
            OwnerMap = new Map<Id, User>();
            for(User user : [SELECT Id, FirstName, LastName, Email, Phone, Title, Region__c FROM User WHERE Id IN :OwnerIds]){
                OwnerMap.put(user.Id, user);
            }
        }
        return OwnerMap;
    } set; }


    ///////////////////// 20200717 ECS EREDDING - DEPRECATED, IMPARTNER REMOVED FROM ORG /////////////////////
    // LEAD PARENTRV MEMBER MAP AND ID SET
    //public static Set<Id> ParentRVMemberIds {get; set;}
    //private static Map<Id, rvpe__RVMember__c> ParentRVMemberMap {
    //get {
    //    if(ParentRVMemberMap == null){
    //        ParentRVMemberMap = new Map<Id, rvpe__RVMember__c>();
    //        for(rvpe__RVMember__c rvMember : [SELECT Id, rvpe__Email__c FROM rvpe__RVMember__c WHERE Id IN :ParentRVMemberIds]){
    //            ParentRVMemberMap.put(rvMember.Id, rvMember);
    //        }
    //    }
    //    return ParentRVMemberMap;
    //} set; }

    // LEAD MQL QUALIFICATION SETTINGS METADATA
    public static Lead_MQL_Qualification_Settings__mdt MQLSettings {
    get {
        if(Test.isRunningTest()){
            MQLSettings = LeadHelperTest.MQLSettingsTestMeta;
        }
        else if(MQLSettings == null){
            for(Lead_MQL_Qualification_Settings__mdt settings : [SELECT MQL_QueueId__c, Qualifying_Statuses__c, Ignored_Queues__c FROM Lead_MQL_Qualification_Settings__mdt]){
                settings.Qualifying_Statuses__c = UtilityClass.replaceNull(settings.Qualifying_Statuses__c, '');
                settings.Ignored_Queues__c = UtilityClass.replaceNull(settings.Ignored_Queues__c, '');                
                MQLSettings = settings;
                break;
            }
        }
        return MQLSettings;
    } set; }

    // PARTNER COMMUNITY LEAD SETTINGS METADATA
    public static Partner_Community_Lead_Settings__mdt ParterCommunityLeadSettings {
    get {
        if(Test.isRunningTest()){
            ParterCommunityLeadSettings = LeadHelperTest.ParterCommunityLeadSettingsTestMeta;
        }
        else if(ParterCommunityLeadSettings == null){
            for(Partner_Community_Lead_Settings__mdt settings : [SELECT Qualifying_Partner_Profiles__c, Partner_Campaign_Id__c, Lead_Owner_Id__c, Member_Status__c
                                                                 FROM Partner_Community_Lead_Settings__mdt]){
                ParterCommunityLeadSettings = settings;
                break;
            }
        }
        return ParterCommunityLeadSettings;
    } set; }

    // PARTNER COMMUNITY PROFILE IDS
    public static Set<Id> PartnerCommunityProfileIds {
    get {
        PartnerCommunityProfileIds = new Set<Id>();
        if(ParterCommunityLeadSettings != null && String.isNotBlank(ParterCommunityLeadSettings.Qualifying_Partner_Profiles__c)){
            for(String profileEntry : ParterCommunityLeadSettings.Qualifying_Partner_Profiles__c.replace('\r','').split('\n')){
                String profileId = profileEntry.left(18);
                if(UtilityClass.validateId(profileId)){
                    PartnerCommunityProfileIds.add(profileId);
                }
            }
        }   
        return PartnerCommunityProfileIds;
    } set; }

    // LEAD PARENT PARTNER COMMUNITY OWNER MAP
    private static Set<Id> PartnerCommLeadOwnerIds {get; set;}
    private static Map<Id, User> PartnerCommLeadOwnerMap {
    get {
        if(PartnerCommLeadOwnerMap == null){
            PartnerCommLeadOwnerMap = new Map<Id, User>();
            for(User user : [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id IN :PartnerCommLeadOwnerIds AND ProfileId IN :PartnerCommunityProfileIds]){
                PartnerCommLeadOwnerMap.put(user.Id, user);
            }
        }
        return PartnerCommLeadOwnerMap;
    } set; }

    /**
    * @author ECS, ERedding
    * @date 20190903
    * @description leadFieldUpdates - Code replacements for various Lead Process Builder Field Updates
    *                                 ******** EXECUTED FROM BEFORE INSERT AND BEFORE UPDATE TRIGGERS *******
    * @param List<Lead> newOrUpdatedLeads - New or Updated Lead records
    * @param Map<Id,Lead> outdatedLeads - Outdated Lead records
    * @return void
    */
    public static void leadFieldUpdates(List<Lead> newOrUpdatedLeads, Map<Id,Lead> outdatedLeads){
        try{
            if(TriggerHelper.DoExecute('LeadHelper','leadFieldUpdates') && newOrUpdatedLeads != null){ // MASTER CONTROL
                Id customerSuccessProfileId = '00e50000001A02qAAC';
                Id leadManagerId = '00550000005l3V7AAI';

                // GET IDS OF PARENT RECORDS
                OwnerIds = new Set<Id>();
                //ParentRVMemberIds = new Set<Id>();                
                for(Lead newOrUpdatedLead : newOrUpdatedLeads){
                    OwnerIds.add(newOrUpdatedLead.OwnerId);
                    OwnerIds.add(leadManagerId);
                    //ParentRVMemberIds.add(newOrUpdatedLead.rvpe__RVMember__c);
                }

                // MAKE QUALIFYING CHANGES
                for(Lead newOrUpdatedLead : newOrUpdatedLeads){
                    Lead outdatedLead = outdatedLeads != null  ? outdatedLeads.get(newOrUpdatedLead.Id) : null;

                    //// PROCESS BUILDER: LEAD: On Create - Create Only
                    if(TriggerHelper.DoExecute('LeadHelper','PBOnCreate') && outdatedLead == null){

                        // Company is Conga or Blue Cube
                        if(newOrUpdatedLead.LeadSource == 'AppExchange' && (newOrUpdatedLead.Company == 'Blue Cube' || newOrUpdatedLead.Company == 'Conga')){
                            // Disqualify Lead
                            newOrUpdatedLead.Lead_Status_Reason__c = 'Researcher (Consultant/Analyst)';
                            newOrUpdatedLead.Status = 'Disqualified';
                        }

                        // Set Custom CreatedDate - No Entry Criteria ///////////// ECS ER 20200225 DEPRECATED, NO LONGER NEEDED
                        //if(true){
                        //    // Set CreatedDate into Custom Field
                        //    newOrUpdatedLead.CreatedDate_for_Lead_Merge__c = DateTime.now();
                        //}

                        // Lead Created by TCS                    
                        if(newOrUpdatedLead.LeadSource == 'TCS Referral' && newOrUpdatedLead.RecordTypeId == UtilityClass.getRecordTypesForObject('Lead').get('Standard_Record_Type') && UserInfo.getProfileId() == customerSuccessProfileId){
                            newOrUpdatedLead.OwnerId = leadManagerId;
                        }
                    }

                    //// PROCESS BUILDER: LEAD: On Create or Edit - Created or Edited
                    if(TriggerHelper.DoExecute('LeadHelper','PBOnCreateOrEdit')){

                        // Record owner change - User AND Record owner change - Queue
                        if((outdatedLead == null || newOrUpdatedLead.OwnerId != outdatedLead.OwnerId)){
                            // User
                            if(String.valueOf(newOrUpdatedLead.OwnerId).startsWith('005') && OwnerMap.containsKey(newOrUpdatedLead.OwnerId)){   
                                User leadOwner = OwnerMap.get(newOrUpdatedLead.OwnerId);
                                newOrUpdatedLead.Owner_First_Name__c = leadOwner.FirstName;
                                newOrUpdatedLead.OwnerLastName__c = leadOwner.LastName;
                                newOrUpdatedLead.OwnerEmail__c = leadOwner.Email;
                                newOrUpdatedLead.OwnerPhone__c = leadOwner.Phone;
                                newOrUpdatedLead.OwnerTitle__c = leadOwner.Title;
                            }
                            // Queue
                            else if(String.valueOf(newOrUpdatedLead.OwnerId).startsWith('00G')){
                                newOrUpdatedLead.Owner_First_Name__c = null;
                                newOrUpdatedLead.OwnerLastName__c = null;
                                newOrUpdatedLead.OwnerEmail__c = null;
                                newOrUpdatedLead.OwnerPhone__c = null;
                                newOrUpdatedLead.OwnerTitle__c = null;
                            }
                        }

                        // FPR Timestamp ///////////// ECS ER 20200225 DEPRECATED, NO LONGER NEEDED
                        //if(newOrUpdatedLead.FPR__c == null && newOrUpdatedLead.Completed_Activities__c > 0 && 
                        //    (outdatedLead == null || newOrUpdatedLead.FPR__c != outdatedLead.FPR__c || newOrUpdatedLead.Completed_Activities__c != outdatedLead.Completed_Activities__c)){
                        //    // Set FPR
                        //    newOrUpdatedLead.FPR__c = DateTime.now();
                        //}

                        // Lead is Being Worked
                        if(newOrUpdatedLead.Status != 'New' && newOrUpdatedLead.Lead_Status_Updated__c == null && 
                            (outdatedLead == null || newOrUpdatedLead.Status != outdatedLead.Status || newOrUpdatedLead.Lead_Status_Updated__c != outdatedLead.Lead_Status_Updated__c)){

                            // Set Fields
                            newOrUpdatedLead.Lead_Status_Updated__c = DateTime.now();
                            if(String.valueOf(newOrUpdatedLead.OwnerId).startsWith('005') && OwnerMap.containsKey(newOrUpdatedLead.OwnerId)){
                                newOrUpdatedLead.Owner_Region__c = OwnerMap.get(newOrUpdatedLead.OwnerId).Region__c;
                            }
                        }

                        ///////////////////// 20200717 ECS EREDDING - DEPRECATED, IMPARTNER REMOVED FROM ORG /////////////////////
                        // RV Member Changed to Not Null
                        //if(newOrUpdatedLead.rvpe__RVMember__c != null && ParentRVMemberMap.containsKey(newOrUpdatedLead.rvpe__RVMember__c) && (outdatedLead == null || outdatedLead.rvpe__RVMember__c == null)){
                        //    // Set RV Member Email
                        //    newOrUpdatedLead.RV_Member_email__c = ParentRVMemberMap.get(newOrUpdatedLead.rvpe__RVMember__c).rvpe__Email__c;
                        //}

                        // Lead Source ZoomInfo - SR~8310
                        if(newOrUpdatedLead.LeadSource == 'ZoomInfo' && (outdatedLead == null || newOrUpdatedLead.LeadSource != outdatedLead.LeadSource)){
                            // Set Lead Source to Prospecting
                            newOrUpdatedLead.LeadSource = 'Prospecting';
                        }

                        // Update Reporting Counts
                        if(outdatedLead != null && (newOrUpdatedLead.Status == 'Converted' || newOrUpdatedLead.Status == 'Converted - No Opportunity') && newOrUpdatedLead.Status != outdatedLead.Status){
                            // Update Closed Leads Count
                            newOrUpdatedLead.Reporting_Closed_Lead_Count__c = 1;

                            // Update Opty Created Lead Count
                            if(newOrUpdatedLead.Status == 'Converted'){
                                newOrUpdatedLead.Reporting_Opty_Created_Lead_Count__c = 1;
                            }
                        }
                    }

                    // LEAD TIME TO FIRST USER IF LEAD MEETS CRITERIA - NOT CONVERTED FROM A PROCESS BUILDER
                    if(outdatedLead != null && newOrUpdatedLead.First_User_Date__c == null && newOrUpdatedLead.OwnerId != outdatedLead.OwnerId &&
                        newOrUpdatedLead.OwnerId != leadManagerId && String.valueOf(newOrUpdatedLead.OwnerId).startsWith('005')){

                        newOrUpdatedLead.Time_To_First_User_Hours__c = UtilityClass.getDistanceBetweenDates(newOrUpdatedLead.CreatedDate, DateTime.now(), UtilityClass.Interval.Hours, 2);
                        newOrUpdatedLead.First_User_Date__c = DateTime.now();
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper','leadFieldUpdates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'leadFieldUpdates', newOrUpdatedLeads, ex, true);
        }
    }

    /**
    * @description updateLeadIndustry - Updates the Lead's industry using D&B data once the lead is linked to its parent D&B record
    *                                       --- EXECUTED BY LEAD BEFORE UPDATE TRIGGER ---       
    * @param List<Lead> updatedLeads - Updated Lead records
    * @param Map<Id, Lead> outdatedLeads - Outdated Lead records
    * @return void
    */
    public static void updateLeadIndustry(List<Lead> updatedLeads, Map<Id, Lead> outdatedLeads){
        try{
            if(TriggerHelper.DoExecute('LeadHelper','updateLeadIndustry') && updatedLeads != null){
                // GET ACCCOUNTS WITH QUALIFYING CHANGES
                List<Lead> qualifiedLeads = new List<Lead>();
                Set<Id> parentDBRecordIds = new Set<Id>();
                for(Lead updatedLead : updatedLeads){
                    Lead outdatedLead = outdatedLeads != null ? outdatedLeads.get(updatedLead.Id) : null;
                    if(outdatedLead != null && updatedLead.DNBoptimizer__DnBCompanyRecord__c != null && outdatedLead.DNBoptimizer__DnBCompanyRecord__c == null){
                        // QUALIFIES IF THE LEAD'S DNBoptimizer__DnBCompanyRecord__c IS NOT EMPTY AND IS CHANGED
                        qualifiedLeads.add(updatedLead);
                        parentDBRecordIds.add(updatedLead.DNBoptimizer__DnBCompanyRecord__c);
                    }
                }

                // PROCESS QUALIFIED LEADS
                if(!qualifiedLeads.isEmpty()){

                    // GET PARENT D&B RECORDS
                    Set<String> naicsCodes = new Set<String>();
                    Set<String> sic4Codes = new Set<String>();
                    Map<Id, DNBoptimizer__DnBCompanyRecord__c> parentDBRecords = new Map<Id, DNBoptimizer__DnBCompanyRecord__c>();
                    for(DNBoptimizer__DnBCompanyRecord__c parentDNB : [SELECT Id, DNBoptimizer__NAICSCode1__c, DNBoptimizer__SIC4Code1__c FROM DNBoptimizer__DnBCompanyRecord__c
                                                                       WHERE Id IN :parentDBRecordIds]){
                        parentDBRecords.put(parentDNB.Id, parentDNB);
                        naicsCodes.add(parentDNB.DNBoptimizer__NAICSCode1__c);
                        sic4Codes.add(parentDNB.DNBoptimizer__SIC4Code1__c);
                    }
                   
                    // GET D&B INDUSTRY DATA
                    List<DNB_Industry__c> dnbIndustries = [SELECT Id, NAICS_Code__c, SIC4_Code__c, Industry__c FROM DNB_Industry__c
                                                            WHERE NAICS_Code__c IN :naicsCodes AND SIC4_Code__c IN :sic4Codes];

                    // UPDATE LEADS
                    for(Lead qualifiedLead : qualifiedLeads){
                        if(parentDBRecords.containsKey(qualifiedLead.DNBoptimizer__DnBCompanyRecord__c)){
                            DNBoptimizer__DnBCompanyRecord__c parentDBRecord = parentDBRecords.get(qualifiedLead.DNBoptimizer__DnBCompanyRecord__c);

                            for(DNB_Industry__c dnbIndustry : dnbIndustries){
                                if(parentDBRecord.DNBoptimizer__NAICSCode1__c == dnbIndustry.NAICS_Code__c && parentDBRecord.DNBoptimizer__SIC4Code1__c == dnbIndustry.SIC4_Code__c){
                                    qualifiedLead.Industry = dnbIndustry.Industry__c;
                                }
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper', 'updateLeadIndustry');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'updateLeadIndustry', updatedLeads, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20200310
    * @param List<Lead> newOrUpdatedLeads - New or updated lead records
    * @param Map<Id, Lead> outdatedLeads - Outdated lead records
    * @description processMQLQualification - Lead trigger method that moves leads through the MQL Qualification process.
    *                                         ***** EXECUTE BY LEAD BEFORE INSERT AND BEFORE UPDATE TRIGGERS *****
    * @return void
    */  
    public static void updateBusinessHours(List<Lead> newOrUpdatedLeads, Map<Id, Lead> outdatedLeads){
        try{
            if(TriggerHelper.DoExecute('LeadHelper','updateBusinessHours') && newOrUpdatedLeads != null){
                // GET QUALIFIED LEADS
                List<Lead> qualifiedLeads = new List<Lead>();
                Set<Id> ownerIds = new Set<Id>();
                for(Lead newOrUpdatedLead : newOrUpdatedLeads){
                    Lead outdatedLead = outdatedLeads != null ? outdatedLeads.get(newOrUpdatedLead.Id) : null;
                    if(!newOrUpdatedLead.IsConverted && (outdatedLead == null || (newOrUpdatedLead.OwnerId != outdatedLead.OwnerId && String.valueOf(newOrUpdatedLead.OwnerId).startsWith('005')))){
                        qualifiedLeads.add(newOrUpdatedLead);
                        ownerIds.add(newOrUpdatedLead.OwnerId);
                    }
                }

                if(!qualifiedLeads.isEmpty()){
                    // GET USERS TO IGNORE
                    Map<Id, User> validLeadUsers = new Map<Id, User>([SELECT Id, Geo__c FROM User WHERE Id IN :ownerIds AND LastName != 'Integration' AND Full_Name__c != 'Tyler Hinkle']);

                    // GET BUSINESS HOURS BY NAME
                    Map<String, Id> bizHoursByName = new Map<String, Id>();
                    for(BusinessHours bizHours : [SELECT Id, Name FROM BusinessHours]){
                        bizHoursByName.put(bizHours.Name, bizHours.Id);
                    }

                    // PROCESS LEADS
                    for(Lead qualifiedLead : qualifiedLeads){
                        if(validLeadUsers.containsKey(qualifiedLead.OwnerId)){ // VALID USER, NOT AN INTEGRATION USER OR TYLER HINKLE
                            User leadOwner = validLeadUsers.get(qualifiedLead.OwnerId);

                            // AMER GEO
                            if(leadOwner.Geo__c == 'AMER'){
                                qualifiedLead.Business_Hours__c = bizHoursByName.get('Default');
                            }
                            // APAC GEO
                            else if(leadOwner.Geo__c == 'APAC'){
                                qualifiedLead.Business_Hours__c = bizHoursByName.get('APAC Business Hours');
                            }
                            // EMEA GEO
                            else if(leadOwner.Geo__c == 'EMEA'){
                                qualifiedLead.Business_Hours__c = bizHoursByName.get('EMEA Business Hours');
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper','updateBusinessHours');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'updateBusinessHours', newOrUpdatedLeads, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190827
    * @param List<Lead> newOrUpdatedLeads - New or updated lead records
    * @param Map<Id, Lead> outdatedLeads - Outdated lead records
    * @description processMQLQualification - Lead trigger method that moves leads through the MQL Qualification process.
    *                                         ***** EXECUTE BY LEAD BEFORE INSERT AND BEFORE UPDATE TRIGGERS *****
    * @return void
    */  
    public static void processMQLQualification(List<Lead> newOrUpdatedLeads, Map<Id, Lead> outdatedLeads){
        try{
            if(TriggerHelper.DoExecute('LeadHelper','processMQLQualification') && newOrUpdatedLeads != null && MQLSettings != null){

                // GET MQL QUALIFICATION SETTINGS
                Set<String> leadStatuses = new Set<String>( MQLSettings.Qualifying_Statuses__c.replace('\r','').split('\n'));
                Set<String> ignoredQueueIds = new Set<String>( MQLSettings.Ignored_Queues__c.replace('\r','').split('\n'));
                Id mqlQueueId = MQLSettings.MQL_QueueId__c;

                // GET QUALIFIED LEADS FOR UPDATE
                List<Lead> qualifiedLeads = new List<Lead>();
                Set<Id> leadOwnerIds = new Set<Id>();
                for(Lead newOrUpdatedLead : newOrUpdatedLeads){
                    Lead outdatedLead = outdatedLeads != null ? outdatedLeads.get(newOrUpdatedLead.Id) : null;
                    if(!ignoredQueueIds.contains(newOrUpdatedLead.OwnerId) && leadStatuses.contains(newOrUpdatedLead.Status) && 
                            (outdatedLead == null || newOrUpdatedLead.Account_Rank__c != outdatedLead.Account_Rank__c ||
                                                     newOrUpdatedLead.engagio__EngagementMinutesLast3Months__c != outdatedLead.engagio__EngagementMinutesLast3Months__c)){

                        qualifiedLeads.add(newOrUpdatedLead); // NEW LEAD WITH VALID STATUS -OR- EXISTING LEAD WITH VALID STATUS WHERE RANK OR ENGAGEMENT MINUTES CHANGED
                        leadOwnerIds.add(newOrUpdatedLead.OwnerId);
                    }
                }

                // PROCESS QUALIFIED LEADS
                if(!qualifiedLeads.isEmpty()){

                    // GET USER ASSIGNED TO ROUND ROBIN 0 IN THE LMA_Lead_Owner_Round_Robin__c CUSTOM SETTINGS
                    Id roundRobinZeroOwnerId = null;
                    for(LMA_Lead_Owner_Round_Robin__c roundRobinOwner : [SELECT Lead_Owner_Id__c FROM LMA_Lead_Owner_Round_Robin__c WHERE Round_Robin_Number__c = 0]){
                        roundRobinZeroOwnerId = roundRobinOwner.Lead_Owner_Id__c;
                        break;
                    }

                    if(roundRobinZeroOwnerId != null && mqlQueueId != null){
                        // GET THE MOST RECENTLY CREATED MQL ENTRY GROUP FOR EACH LEAD
                        Map<Id, String> recentGroupsByLead = new Map<Id, String>();
                        for(MQL_Qualification__c mql : [SELECT LeadId__c, Group__c FROM MQL_Qualification__c WHERE LeadId__c IN :qualifiedLeads ORDER BY Date_Time__c DESC]){
                            if(!recentGroupsByLead.containsKey(mql.LeadId__c)){
                                recentGroupsByLead.put(mql.LeadId__c, mql.Group__c);
                            }
                        }

                        // GET LEAD OWNER NAMES, USERS AND QUEUES
                        Map<Id, String> leadOwnerNames = new Map<Id, String>();
                        for(User user : [SELECT Id, Name FROM User WHERE Id IN :leadOwnerIds AND ProfileId NOT IN :PartnerCommunityProfileIds]){
                            leadOwnerNames.put(user.Id, user.Name);
                        }
                        for(Group queue : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN :leadOwnerIds]){
                             leadOwnerNames.put(queue.Id, queue.Name);
                        }

                        // PROCESS LEADS
                        List<MQL_Qualification__c> mqlQualificationsToCreate = new List<MQL_Qualification__c>();
                        for(Lead lead : qualifiedLeads){
                            if(lead.OwnerId == null || leadOwnerNames.containsKey(lead.OwnerId)){
                                if(lead.Id == null){
                                    // FORCE NEW LEAD TO MQL QUEUE IF IT IS NOT AN EMEA NO CONTACT LEAD
                                    if(lead.Region__c != 'EMEA' || (lead.Region__c == 'EMEA' && (String.isNotBlank(lead.Phone) || String.isNotBlank(lead.Email)))){
                                        lead.OwnerId = mqlQueueId;
                                    }
                                }
                                else{
                                    String mintigoRank = lead.Account_Rank__c;
                                    Decimal engagioMinutes = lead.engagio__EngagementMinutesLast3Months__c;
                                    String mqlGroup;

                                    // CALCULATE MQL GROUP
                                    if((mintigoRank == 'A' || mintigoRank == 'B') && engagioMinutes > 0){
                                        mqlGroup = 'Group 1';
                                    }
                                    else if(mintigoRank == 'C' && engagioMinutes > 4){
                                        mqlGroup = 'Group 2';
                                    }
                                    else if(mintigoRank == 'D' && engagioMinutes > 9){
                                        mqlGroup = 'Group 3';
                                    }
                                    else if(mintigoRank == 'F' && engagioMinutes > 14){
                                        mqlGroup = 'Group 4';
                                    }
                                    else if(String.isBlank(mintigoRank) && engagioMinutes > 0){
                                        mqlGroup = 'Group 5';
                                    }

                                    if(String.isNotBlank(mqlGroup) && (!recentGroupsByLead.containsKey(lead.Id) || recentGroupsByLead.get(lead.Id) != mqlGroup)){
                                        // SET LEAD MQL DATE STAMP IF NULL
                                        if(lead.MQL_Date_Stamp__c == null){
                                            lead.MQL_Date_Stamp__c = Date.today();
                                        }

                                        // CREATE NEW MQL QUALIFICATION ENTRY
                                        mqlQualificationsToCreate.add(new MQL_Qualification__c(LeadId__c = lead.Id,
                                                                                               Lead_Title__c = lead.Title,
                                                                                               Date_Time__c = DateTime.now(),
                                                                                               Group__c = mqlGroup,
                                                                                               Rank__c = mintigoRank,
                                                                                               Engagement_Minutes__c = engagioMinutes,
                                                                                               Lead_Owner__c = (leadOwnerNames.containsKey(lead.OwnerId) ? leadOwnerNames.get(lead.OwnerId) : null)
                                                                                               ));

                                        // IF LEAD IS IN THE MQL QUEUE CHANGE OWNER TO "LEAD MANAGER" TO FORCE IT THROUGH THE ASSIGNMENT PROCESS
                                        if(lead.OwnerId == mqlQueueId){
                                            lead.OwnerId = roundRobinZeroOwnerId;
                                        }
                                    }
                                }
                            }
                        }

                        if(!mqlQualificationsToCreate.isEmpty()){
                            Database.SaveResult[] insertResults = Database.insert(mqlQualificationsToCreate, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'LeadHelper', 'processMQLQualification', true);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper','processMQLQualification');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'processMQLQualification', newOrUpdatedLeads, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20200114
    * @param List<Lead> newLeads - New lead records
    * @description processNewPartnerCommunityLead - Lead trigger method that makes specific updates and creates campaign members for Leads created by Partner Community users
    *                                                 ***** EXECUTE BY LEAD BEFORE INSERT AND AFTER INSERT TRIGGER *****
    * @return void
    */  
    public static void processNewPartnerCommunityLead(List<Lead> newLeads){
        try{
            if(TriggerHelper.DoExecute('LeadHelper','processNewPartnerCommunityLead') && newLeads != null && PartnerCommunityProfileIds != null && ParterCommunityLeadSettings != null){
                // GET LEAD OWNER IDS
                PartnerCommLeadOwnerIds = new Set<Id>();
                for(Lead newLead : newLeads){
                    PartnerCommLeadOwnerIds.add(newLead.OwnerId);
                }

                if(!PartnerCommLeadOwnerMap.isEmpty()){
                    // GET PARTNER COMMUNITY SETTINGS
                    Id partnerCampaignId = ParterCommunityLeadSettings.Partner_Campaign_Id__c;
                    Id leadOwnerId = ParterCommunityLeadSettings.Lead_Owner_Id__c;
                    String memberStatus = ParterCommunityLeadSettings.Member_Status__c;
 
                    // PROCESS LEADS
                    List<CampaignMember> membersToCreate = new List<CampaignMember>();
                    for(Lead newLead : newLeads){
                        if(newLead.Id == null && PartnerCommLeadOwnerMap.containsKey(newLead.OwnerId)){
                            // BEFORE INSERT ACTIONS

                            // UPDATE LEAD
                            User partnerCommUser = PartnerCommLeadOwnerMap.get(newLead.OwnerId);                            
                            newLead.Partner__c = partnerCommUser.Contact.AccountId;
                            newLead.OwnerId = leadOwnerId;

                        }
                        else if(newLead.Id != null && newLead.OwnerId == leadOwnerId){
                            // AFTER INSERT ACTIONS

                            // CREATE CAMPAIGN MEMBER
                            CampaignMember newMember = new CampaignMember(CampaignId = partnerCampaignId, LeadId = newLead.Id, Status = memberStatus);
                            membersToCreate.add(newMember);
                        }
                    }

                    // CREATE NEW MEMBERS
                    if(!membersToCreate.isEmpty()){
                        Database.SaveResult[] insertResults = Database.insert(membersToCreate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'LeadHelper', 'processNewPartnerCommunityLead', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper','processNewPartnerCommunityLead');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'processNewPartnerCommunityLead', newLeads, ex, true);
        }
    }

    /**
    * @author Conga Services
    * @date 20180626
    * @param List<Lead> updatedLeads
    * @param Map<Id, Lead> outdatedLeads
    * @description updateLeadRegionByCountry - Set's region based on country. If country is null or corresponding region is not found, null is assigned as region.
    *                                          EXECUTED BY LEAD BEFORE INSERT AND BEFORE UPDATE TRIGGERS
    * @return void
    */  
    public static void updateLeadRegionByCountry(List<Lead> updatedLeads, Map<Id, Lead> outdatedLeads){
        try{
            if(TriggerHelper.DoExecute('LeadHelper','updateLeadRegionByCountry') && updatedLeads != null){
                // GET QUALIFIED LEADS FOR UPDATE
                List<Lead> qualifiedLeads = new List<Lead>();
                for(Lead updatedLead : updatedLeads){
                    Lead outdatedLead = outdatedLeads != null ? outdatedLeads.get(updatedLead.Id) : null;
                    if((outdatedLead == null && updatedLead.Country != null) || (outdatedLeads != null && updatedLead.Country != outdatedLead.Country)){
                        qualifiedLeads.add(updatedLead); // NEW LEAD WITH A COUNTRY OR UPDATED LEAD WITH A CHANGED COUNTRY
                    }
                }

                // PROCESS QUALIFIED LEADS
                if(!qualifiedLeads.isEmpty()){
                    for(Lead lead : qualifiedLeads){
                        String validatedCountry = StateAndCountryValidation.getValidCountry(lead.Country);
                        lead.Region__c = String.isNotBlank(validatedCountry) ? StateAndCountryValidation.GeoByFullCountryName.get(validatedCountry) : null;
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper','updateLeadRegionByCountry');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'updateLeadRegionByCountry', updatedLeads, ex, true);
        }
    }

    /**
    * @author Conga Services
    * @date 20180919
    * @description addCampaignMembers - Updates a Lead's campaigns through its campaign members. Uses the Campaign Id or Ids specified in the SF_Campaign_ID__c field and the Campaign Id
    *                                   from the LMA_Lead_Package_Campaign__mdt record matching to the Lead's Package__c and AppExchange_Type__c field values.
    * @param List<Lead> newOrUpdatedLeads - Map of updated Leads
    * @param Map<Id,Lead> outdatedLeads - Map of outdated Leads 
    * @return void
    */  
    public static void addCampaignMembers(List<Lead> newOrUpdatedLeads, Map<Id,Lead> outdatedLeads){
        try{
            if(TriggerHelper.DoExecute('LeadHelper','addCampaignMembers') && newOrUpdatedLeads != null){    
                // GET QUALIFIED LEADS
                List<Lead> qualifiedLeads = new List<Lead>();
                for(Lead updatedLead : newOrUpdatedLeads){
                    Lead outdatedLead = outdatedLeads != null ? outdatedLeads.get(updatedLead.Id) : null;
                    if(outdatedLead == null || (String.isNotBlank(updatedLead.SF_Campaign_ID__c) && updatedLead.SF_Campaign_ID__c != outdatedLead.SF_Campaign_ID__c)){
                        qualifiedLeads.add(updatedLead);
                    }
                }

                if(!qualifiedLeads.isEmpty()){
                    // GET LEAD PACKAGE TO CAMPAIGN MAPPING FROM CUSTOM METADATA
                    Map<String, Map<String, Id>> packageToCampaignMapping = new Map<String, Map<String, Id>>();
                    for(LMA_Lead_Package_Campaign__mdt mappingMeta : LeadPackageCampaigns){
                        if(mappingMeta.CampaignId__c != null && (mappingMeta.CampaignId__c.length() == 15 || mappingMeta.CampaignId__c.length() == 18)){
                            if(!packageToCampaignMapping.containsKey(mappingMeta.Package__c)){
                                packageToCampaignMapping.put(mappingMeta.Package__c, new Map<String, Id>());
                                packageToCampaignMapping.get(mappingMeta.Package__c).put(mappingMeta.AppExchange_Type__c, Id.valueOf(mappingMeta.CampaignId__c));
                            }
                            else if(packageToCampaignMapping.containsKey(mappingMeta.Package__c) && !packageToCampaignMapping.get(mappingMeta.Package__c).containsKey(mappingMeta.AppExchange_Type__c)){
                                packageToCampaignMapping.get(mappingMeta.Package__c).put(mappingMeta.AppExchange_Type__c, Id.valueOf(mappingMeta.CampaignId__c));
                            }
                        }
                        else{
                            // INVALID ID, LOG AS SYSTEM ISSUE
                            SystemIssueLogHelper.LogException('LeadHelper', 'addCampaignMembers', qualifiedLeads, 'LMA_Lead_Package_Campaign__mdt has an invalid Id of: ' + mappingMeta.CampaignId__c, false);
                        }
                    }

                    // LOOP OVER LEADS, GET APPLICABLE CAMPAIGN IDS FROM EACH
                    Map<Id,Set<Id>> leadCampaignIdsMap = new Map<Id,Set<Id>>();
                    Set<Id> pardotCampaignIds = new Set<Id>();
                    Set<Id> licenseCampaignIds = new Set<Id>();
                    for(Lead lead : qualifiedLeads){
                        Lead outdatedLead = outdatedLeads != null ? outdatedLeads.get(lead.Id) : null;

                        // GET CAMPAIGN IDS FROM SF_Campaign_ID__c FIELD
                        if(String.isNotBlank(lead.SF_Campaign_ID__c) && (outdatedLead == null || lead.SF_Campaign_ID__c != outdatedLead.SF_Campaign_ID__c)){
                            for(String campaignId : lead.SF_Campaign_ID__c.replace(' ', '').split('[,;:]')){
                                if(UtilityClass.validateId(campaignId)){
                                    pardotCampaignIds.add((Id)campaignId);
                                    if(!leadCampaignIdsMap.containsKey(lead.Id)){
                                        leadCampaignIdsMap.put(lead.Id, new Set<Id>());
                                    }
                                    leadCampaignIdsMap.get(lead.Id).add((Id)campaignId);
                                }
                                else{
                                    SystemIssueLogHelper.LogException('LeadHelper', 'addCampaignMembers', lead.Id, 'Invalid SF Campaign ID: ' + campaignId, false);     
                                }
                            }
                        }
                    }

                    // LOOP OVER ANY LICENSES THAT EXIST ON THE LEADS AND ADD APPLICABLE CAMPAIGN FOR EACH PRODUCT PACKAGE
                    for(sfLma__License__c license : [SELECT Id, sfLma__Lead__c, sfLma__Lead__r.AppExchange_Type__c, sfLma__Package_Version__r.sfLma__Package__r.Name 
                                                     FROM sfLma__License__c WHERE sfLma__Lead__c IN :qualifiedLeads AND sfLma__Lead__r.Status <> 'Invalid']){

                        String packageName = license.sfLma__Package_Version__r.sfLma__Package__r.Name;
                        String appExchangeType = license.sfLma__Lead__r.AppExchange_Type__c;
                        if(packageToCampaignMapping.containsKey(packageName) && packageToCampaignMapping.get(packageName).containsKey(appExchangeType)){
                            licenseCampaignIds.add(packageToCampaignMapping.get(packageName).get(appExchangeType));
                            if(!leadCampaignIdsMap.containsKey(license.sfLma__Lead__c)){
                                leadCampaignIdsMap.put(license.sfLma__Lead__c, new Set<Id>());
                            }
                            leadCampaignIdsMap.get(license.sfLma__Lead__c).add(packageToCampaignMapping.get(packageName).get(appExchangeType)); 
                        }
                        else{
                            SystemIssueLogHelper.LogException('LeadHelper', 'addCampaignMembers', license.sfLma__Lead__c, 'No campaign mapping found for Package: ' + packageName + ', App Exchange Type: ' + appExchangeType, false);
                        }
                    }

                    // GET CAMPAIGN DATA
                    Set<Id> activeCampaignIds = new Set<Id>();
                    for(Campaign campaign : [SELECT Id, Name FROM Campaign WHERE IsActive = TRUE AND (Id IN :pardotCampaignIds OR Id IN :licenseCampaignIds)]){
                        activeCampaignIds.add(campaign.Id);
                    }

                    if(!leadCampaignIdsMap.isEmpty() && !activeCampaignIds.isEmpty()){
                        // GET EXISTING MEMBERSHIPS FOR THE LEADS AND CAMPAIGNS IN QUESTION
                        Map<Id,Set<Id>> leadExistingMembershipsMap = new Map<Id,Set<Id>>();
                        for(CampaignMember member : [SELECT Id, CampaignId, LeadId FROM CampaignMember WHERE LeadId IN :leadCampaignIdsMap.keySet() AND CampaignId IN :activeCampaignIds]){
                            if(!leadExistingMembershipsMap.containsKey(member.LeadId)){
                                leadExistingMembershipsMap.put(member.LeadId, new Set<Id>());
                            }
                            leadExistingMembershipsMap.get(member.LeadId).add(member.CampaignId);
                        }

                        // LOOP THROUGH LEADS AND CREATE MEMBERSHIPS FOR EACH CAMPAIGN THE LEAD IS NOT ALREADY A MEMBER OF
                        List<CampaignMember> newMembersToInsert = new List<CampaignMember>();
                        for(Id leadId : leadCampaignIdsMap.keySet()){
                            for(Id campaignId : leadCampaignIdsMap.get(leadId)){
                                if(activeCampaignIds.contains(campaignId) && (!leadExistingMembershipsMap.containsKey(leadId) || 
                                                                              (leadExistingMembershipsMap.containsKey(leadId) && !leadExistingMembershipsMap.get(leadId).contains(campaignId)))){
                                    String memberStatus = licenseCampaignIds.contains(campaignId) ? 'Installed' : null;
                                    newMembersToInsert.add(new CampaignMember(LeadId = leadId, CampaignId = campaignId, Status = memberStatus));
                                }
                            }
                        }

                        // COMMIT NEW MEMBERS TO THE DATABASE
                        if(!newMembersToInsert.isEmpty()){
                            Database.SaveResult[] insertResults = Database.insert(newMembersToInsert, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'LeadHelper', 'addCampaignMembers', false);
                        }
                    }
                }

                // SAVE ANY LOGGED ERRORS
                SystemIssueLogHelper.UpsertExceptions();

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper','addCampaignMembers');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'addCampaignMembers', newOrUpdatedLeads, ex, true);
        }
    }

    /**
    * @author Conga Services
    * @date 20180626
    * @param List<Lead> updatedLeads - Map of updated Leads
    * @param Map<Id,Lead> outdatedLeads - Map of outdated Leads 
    * @description updateTimetoFPRCalc - Calculates/Recalculates the Time to FPR Business Hours value every time the Business_Hours__c or FPR__c fields change.
    *                                     ---- EXECUTED BY LEAD BEFORE UPDATE TRIGGER ----
    * @return void
    */  
    public static void updateTimetoFPRCalc(List<Lead> updatedLeads, Map<Id,Lead> outdatedLeads){
        try{       
            if(TriggerHelper.DoExecute('LeadHelper','updateTimetoFPRCalc') && updatedLeads != null && outdatedLeads != null){
                // GET QUALIFIED LEADS FOR UPDATE
                for(Lead updatedLead : updatedLeads){
                    Lead outdatedLead = outdatedLeads != null ? outdatedLeads.get(updatedLead.Id) : null;
                    if(outdatedLead != null && updatedLead.FPR__c != null && (updatedLead.FPR__c != outdatedLead.FPR__c || updatedLead.Business_Hours__c != outdatedLead.Business_Hours__c)){
                        
                        // CALCULATE TIME TO FPR HOURS IF FPR IS POPULATED OR CHANGED
                        if(updatedLead.FPR__c != outdatedLead.FPR__c){
                            //updatedLead.Time_to_FPR_Business_Hours__c = ((Double)(BusinessHours.diff(updatedLead.Business_Hours__c, updatedLead.CreatedDate, updatedLead.FPR__c)) / 3600000); // HOURS
                            updatedLead.Time_to_FPR_Hours__c = UtilityClass.getDistanceBetweenDates(updatedLead.CreatedDate, updatedLead.FPR__c, UtilityClass.Interval.Hours, 2); // HOURS                            
                        }

                        // CALCULATE FIRST USER TO FPR IF FPR OR BUSINESS HOURS ARE POPULATED OR CHANGED
                        if(updatedLead.First_User_Date__c != null && updatedLead.Business_Hours__c != null){
                            updatedLead.First_User_to_FPR_Business_Hours__c = ((Double)(BusinessHours.diff(updatedLead.Business_Hours__c, 
                                                                                                            updatedLead.First_User_Date__c, 
                                                                                                            updatedLead.FPR__c)) / 3600000); // HOURS
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper','updateTimetoFPRCalc');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'updateTimetoFPRCalc', updatedLeads, ex, true);
        } 
    }

    /**
    * @author Conga Services
    * @date 20180917
    * @param List<Lead> updatedLeads - List of updated Leads
    * @param Map<Id,Lead> outdatedLeads - Map of outdated Leads     
    * @description updateLeadSourceAppExchangeType - Updates a Lead's LeadSource and App Exchange Type depending on what the initial LeadSource value is.
    *                                                 --- EXECUTED BY LEAD BEFORE INSERT AND BEFORE UPDATE TRIGGER HANDLERS ---
    * @return void
    */  
    public static void updateLeadSourceAppExchangeType(List<Lead> updatedLeads, Map<Id,Lead> outdatedLeads){
        try{
            if(TriggerHelper.DoExecute('LeadHelper','updateLeadSourceAppExchangeType') && updatedLeads != null){
                // GET QUALIFIED LEADS FOR UPDATE
                List<Lead> leadsToUpdate = new List<Lead>();
                for(Lead lead : updatedLeads){
                    Lead outdatedLead = outdatedLeads != null ? outdatedLeads.get(lead.Id) : null;

                    // UPDATE LEAD APPEXCHANGE TYPE IF APPLICABLE
                    if(!String.isBlank(lead.LeadSource) && (outdatedLead == null || lead.LeadSource != outdatedLead.LeadSource)){
                        if(lead.LeadSource.contains('SFDC-') || lead.LeadSource.contains('Package Installation') || lead.LeadSource == 'Overlay' || lead.LeadSource == 'Site'){

                            // SET APP EXCHANGE TYPE IF BLANK
                            if(String.isBlank(lead.AppExchange_Type__c) && (lead.LeadSource.contains('SFDC-DM') || lead.LeadSource.contains('SFDC-dup-DM'))){
                                lead.AppExchange_Type__c = 'Demo';
                                lead.Lead_Source_Detail__c = 'Demo';
                            }
                            else if(String.isBlank(lead.AppExchange_Type__c)  && (lead.LeadSource.contains('Package Installation') || lead.LeadSource.contains('SFDC-IN') || lead.LeadSource.contains('SFDC-dup-IN'))){
                                lead.AppExchange_Type__c = 'Install';
                                lead.Lead_Source_Detail__c = 'Install';
                            }

                            // SET LEADSOURCE TO APPEXCHANGE REGARDLESS IF APPEXCHANGE TYPE WAS CHANGED OR NOT
                            lead.LeadSource = 'AppExchange';
                            lead.Channel_Source_2__c = 'Digital';
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('LeadHelper','updateLeadSourceAppExchangeType');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('LeadHelper', 'updateLeadSourceAppExchangeType', updatedLeads, ex, true);
        }
    }


}