/**
* @author Conga Services, ahafez, eredding
* @date 20180606
* @version 1.00
* @description Class containing custom functionality related to sfLma__License__c actions
*/
public without sharing class SFLMALicenseHelper {

    // TRIALFORCE SETTINGS METADATA
    private static Trialforce_Extension_Settings__mdt TrialforceSettingsMeta {
    get {
        if(Test.isRunningTest()){
            TrialforceSettingsMeta = SFLMALicenseHelperTest.TrialforceSettingsTestMeta;
        }
        else if(TrialforceSettingsMeta == null){
            for(Trialforce_Extension_Settings__mdt settings : [SELECT Account_Name_Keywords__c, Eligible_Package_Ids__c, Length_of_Extension__c FROM Trialforce_Extension_Settings__mdt]){
                settings.Account_Name_Keywords__c = UtilityClass.replaceNull(settings.Account_Name_Keywords__c, '').toLowerCase();
                settings.Length_of_Extension__c = UtilityClass.replaceNull(settings.Length_of_Extension__c, 0);                
                TrialforceSettingsMeta = settings;
                break;
            }
        }
        return TrialforceSettingsMeta;
    } set; }

    /**
    * @author Conga Services, ERedding
    * @description invalidateSandboxRefreshLeads - sfLma__License__c object trigger method that sets related Lead's Statuses to Invalid if the license
    *                                              Install Date Check was set as 'Sandbox Refresh'
    * @param Map<Id, sfLma__License__c> newLicenses - List of new or updated sfLma__License__c records
    * @return void
    */
    public static void invalidateSandboxRefreshLeads(Map<Id, sfLma__License__c> newLicenses) {
        try{
            if(TriggerHelper.DoExecute('SFLMALicenseHelper','invalidateSandboxRefreshLeads') && newLicenses != null){
                // GET APPLICABLE LEADS
                Set<Id> leadIds = new Set<Id>();
                for(sfLma__License__c license : newLicenses.values()) {
                    if (license.Install_Date_Check__c == 'Sandbox Refresh'){
                        leadIds.add(license.sfLma__Lead__c);
                    }
                }
                leadIds.remove(null);

                // CREATE LIST OF LEADS TO UPDATE
                List<Lead> leadsToUpdate = new List<Lead>();
                if(!leadIds.isEmpty()){
                    for(Id leadId : leadIds){
                        Lead lead = new Lead(Id = leadId, Status = 'Invalid');
                        leadsToUpdate.add(lead);
                    }
             
                    if(!leadsToUpdate.isEmpty()){
                        Database.saveResult[] leadResults = Database.update(leadsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(leadResults, 'SFLMALicenseHelper', 'invalidateSandboxRefreshLeads', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SFLMALicenseHelper', 'invalidateSandboxRefreshLeads');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SFLMALicenseHelper', 'invalidateSandboxRefreshLeads', newLicenses, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20200226
    * @description enableFMABluecubeLicenses - Enables FMA Boolean records on licenses that are now linked to BlueCube Salesforce Orgs
    *                                               *** EXECUTED BY sfLma__License__c AFTER UPDATE TRIGGER ***
    * @param List<sfLma__License__c> updatedLicenses - List of updated sfLma__License__c records
    * @param Map<Id, sfLma__License__c> outdatedLicenses - List of outdated sfLma__License__c records             
    * @return void
    */
    public static void enableFMABluecubeLicenses(List<sfLma__License__c> updatedLicenses, Map<Id, sfLma__License__c> outdatedLicenses) {
        try{
            if(TriggerHelper.DoExecute('SFLMALicenseHelper','enableFMABluecubeLicenses') && updatedLicenses != null && outdatedLicenses != null){

                // GET SALESFORCE ORG IDS FROM QUALIFIED LICENSES
                Set<Id> salesforceOrgIds = new Set<Id>();
                for(sfLma__License__c updatedLicense : updatedLicenses){
                    sfLma__License__c outdatedLicense = outdatedLicenses != null  ? outdatedLicenses.get(updatedLicense.Id) : null;
                    if(outdatedLicense != null && updatedLicense.Salesforce_OrgId__c != outdatedLicense.Salesforce_OrgId__c){
                        salesforceOrgIds.add(updatedLicense.Salesforce_OrgId__c);
                    }
                }

                if(!salesforceOrgIds.isEmpty()){
                    // GET BLUECUBE SALESFORCE ORGS
                    Set<Id> bluecubeOrgIds = new Set<Id>();
                    for(Salesforce_Org__c sfOrg : [SELECT Id FROM Salesforce_Org__c WHERE Id IN :salesforceOrgIds AND (Name = 'BlueCube' OR Name = 'Blue Cube')]){
                        bluecubeOrgIds.add(sfOrg.Id);
                    }

                    // UPDATE FEATURE PARAMETER BOOLEAN RECORDS THAT BELONG TO BLUECUBE LICENSES
                    List<sfFma__FeatureParameterBoolean__c> fmaBooleansToUpdate = new List<sfFma__FeatureParameterBoolean__c>();
                    for(sfFma__FeatureParameterBoolean__c fmaBoolean : [SELECT Id FROM sfFma__FeatureParameterBoolean__c
                                                                        WHERE sfFma__License__r.Salesforce_OrgId__c IN :bluecubeOrgIds AND sfFma__Value__c = false]){
                        fmaBoolean.sfFma__Value__c = true;
                        fmaBooleansToUpdate.add(fmaBoolean);
                    }

                    // UPDATE RECORDS
                    if(!fmaBooleansToUpdate.isEmpty()){
                        Database.saveResult[] updateResults = Database.update(fmaBooleansToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'SFLMALicenseHelper', 'enableFMABluecubeLicenses', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SFLMALicenseHelper', 'enableFMABluecubeLicenses');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SFLMALicenseHelper', 'enableFMABluecubeLicenses', updatedLicenses, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20180619 
    * @description processNewLicenses - Performs various functionality for newly created sfLma__License__c records. Logic was taken from the 
    *                                    "NEW_Populate_Package_field_on_Lead_from_License" PB process.
    * @param Map<Id, sfLma__License__c> newLicenses - Map of newly created sfLma__License__c records
    * @return void
    */
    public static void processNewLicenses(Map<Id, sfLma__License__c> newLicenses) {
        try{       
            if(TriggerHelper.DoExecute('SFLMALicenseHelper','processNewLicenses') && newLicenses != null){

                // GET QUALIFIED LICENSES
                List<sfLma__License__c> licensesToProcess = [SELECT Id, sfLma__Package_Version__r.sfLma__Package__r.Name, sfLma__Lead__c, sfLma__Lead__r.Package__c,
                                                             sfLma__Lead__r.SF_Campaign_ID__c, sfLma__Lead__r.AppExchange_Type__c
                                                             FROM sfLma__License__c WHERE sfLma__Lead__c <> NULL AND sfLma__Lead__r.Status <> 'Invalid'
                                                             AND Id IN :newLicenses.keySet()];

                if(!licensesToProcess.isEmpty()){
                    // GET PARENT LEADS AND PACKAGE NAMES
                    Map<Id, Lead> parentLeads = new Map<Id, Lead>();
                    Map<Id, String> packageNamesByLeadId = new Map<Id, String>();
                    for(sfLma__License__c license : licensesToProcess){
                        parentLeads.put(license.sfLma__Lead__c, license.sfLma__Lead__r);
                        packageNamesByLeadId.put(license.sfLma__Lead__c, license.sfLma__Package_Version__r.sfLma__Package__r.Name);
                    }

                    // CONTINUE PROCESSING LEADS
                    List<Lead> leadsToUpdate = new List<Lead>();
                    for(Lead lead : parentLeads.values()){
                        Boolean leadUpdateMade = FALSE;

                        // UPDATE LEAD PACKAGE IF APPLICABLE
                        if(String.isBlank(lead.Package__c) && packageNamesByLeadId.containsKey(lead.Id)){
                            lead.Package__c = packageNamesByLeadId.get(lead.Id);
                            leadUpdateMade = TRUE;
                        }

                        // UPDATE LEAD APP EXCHANGE TYPE TO INSTALL IF NOT ALREADY INSTALL
                        if(lead.AppExchange_Type__c != 'Install'){
                            lead.AppExchange_Type__c = 'Install';
                            leadUpdateMade = TRUE;
                        }

                        // ADD LEAD TO UPDATE LIST IF A CHANGE HAS BEEN MADE
                        if(leadUpdateMade){
                            leadsToUpdate.add(lead);
                        }
                    }

                    // UPDATE LEADS
                    if(!leadsToUpdate.isEmpty()){
                        Database.SaveResult[] results = Database.update(leadsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(results, 'SFLMALicenseHelper', 'processNewLicenses', false);
                    }

                    // CALL LEAD addCampaignMembers TRIGGER METHOD TO ADD/UPDATE CAMPAIGN MEMBERS
                    LeadHelper.addCampaignMembers(parentLeads.values(), null);
                }

                // COMMIT ANY EXCEPTIONS THROWN BY DML PROCESSES
                SystemIssueLogHelper.UpsertExceptions();

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SFLMALicenseHelper', 'processNewLicenses');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SFLMALicenseHelper', 'processNewLicenses', newLicenses, ex, true);
        }
    }


    /**
    * @author Conga Services, ERedding
    * @date 20180625
    * @description populateSFOrgLicenseLookups - Trigger method that find a License's matching Salesforce Org and populates the Composer_License__c lookup.
    *                                            EXECUTED BY AN AFTER INSERT AND AFTER UPDATE TRIGGER
    * @param Map<Id, sfLma__License__c> newLicenses - Map of newly created or recently updated sfLma__License__c records
    * @param Map<Id, sfLma__License__c> outdatedLicenses - Map of outdated sfLma__License__c records
    * @return void
    */
    public static void updateSFOrgComposerLicense(Map<Id, sfLma__License__c> newLicenses, Map<Id, sfLma__License__c> outdatedLicenses) {
        try{        
            if(TriggerHelper.DoExecute('SFLMALicenseHelper','updateSFOrgComposerLicense') && newLicenses != null){
                List<sfLma__License__c> licenseData = [SELECT Id, sfLma__Status__c, sfLma__Account__c, sfLma__Seats__c, Customer_Org_ID__c, sfLma__Package__r.Name 
                                                       FROM sfLma__License__c WHERE Id IN :newLicenses.keySet() AND sfLma__Status__c = 'Active' AND sfLma__Seats__c > 0];

                // GET QUALIFIED LICENSES
                Map<String, Id> qualifiedLicensesByOrgID = new Map<String, Id>();
                Set<Id> parentAccountIds = new Set<Id>();
                for(sfLma__License__c lic : licenseData){
                    if(String.isNotBlank(lic.Customer_Org_ID__c) && lic.sfLma__Package__r.Name.contains('Composer') &&
                       ((outdatedLicenses == null || outdatedLicenses.isEmpty()) || lic.sfLma__Seats__c != outdatedLicenses.get(lic.Id).sfLma__Seats__c)){
                        qualifiedLicensesByOrgID.put(lic.Customer_Org_ID__c, lic.Id);
                        parentAccountIds.add(lic.sfLma__Account__c);
                    }
                }

                if(!qualifiedLicensesByOrgID.isEmpty()){
                    // GET SALESFORCE ORGS TO UPDATE
                    List<Salesforce_Org__c> orgsToUpdate = [SELECT Id, Salesforce_Account_Id__c FROM Salesforce_Org__c 
                                                            WHERE Account__c IN :parentAccountIds 
                                                            AND Salesforce_Account_Id__c IN :qualifiedLicensesByOrgID.keySet()];

                    // UPDATE COMPOSER LICENSE LOOKUP ON SALESFORCE ORGS
                    for(Salesforce_Org__c sfOrg : orgsToUpdate){
                        sfOrg.Composer_License__c = qualifiedLicensesByOrgID.get(sfOrg.Salesforce_Account_Id__c);
                    }

                    // COMMIT UPDATES TO DATABASE
                    if(!orgsToUpdate.isEmpty()){
                        Database.SaveResult[] results = Database.update(orgsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(results, 'SFLMALicenseHelper', 'updateSFOrgComposerLicense', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SFLMALicenseHelper', 'updateSFOrgComposerLicense'); 
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SFLMALicenseHelper', 'updateSFOrgComposerLicense', newLicenses, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190920
    * @description extendTrialLicense - 
    *                                            **** EXECUTED BY SFLMA LICENSE BEFORE UPDATE TRIGGER ***
    * @param List<sfLma__License__c> newLicenses - List of recently updated sfLma__License__c records
    * @param Map<Id, sfLma__License__c> outdatedLicenses - Map of outdated sfLma__License__c records
    * @return void
    */
    public static void extendTrialLicense(List<sfLma__License__c> updatedLicenses, Map<Id, sfLma__License__c> outdatedLicenses) {
        try{        
            if(TriggerHelper.DoExecute('SFLMALicenseHelper','extendTrialLicense') && updatedLicenses != null && outdatedLicenses != null){
               
               // GET QUALIFYING LICENSES
                List<sfLma__License__c> qualifiedLicenses = new List<sfLma__License__c>();
                Set<Id> parentAccountIds = new Set<Id>();
                for(sfLma__License__c updateLicense : updatedLicenses){
                    sfLma__License__c outdatedLicense = outdatedLicenses != null  ? outdatedLicenses.get(updateLicense.Id) : null;
                    if(outdatedLicense != null && updateLicense.sfLma__Account__c != null && updateLicense.sfLma__Account__c != outdatedLicense.sfLma__Account__c){
                        qualifiedLicenses.add(updateLicense);
                        parentAccountIds.add(updateLicense.sfLma__Account__c);
                    }
                }

                if(!qualifiedLicenses.isEmpty() && !parentAccountIds.isEmpty()){
                    
                    // GET PARENT ACCOUNTS
                    Map<Id, String> parentAccountNames = new Map<Id, String>();
                    for(Account acct : [SELECT Id, Name FROM Account WHERE Id IN:parentAccountIds]){
                        parentAccountNames.put(acct.Id, acct.Name);
                    }
                    
                    // GET CUSTOM METADATA SETTINGS
                    Set<String> accountNameKeywords = new Set<String>( TrialforceSettingsMeta.Account_Name_Keywords__c.replace('\r','').split('\n') );
                    Set<String> eligiblePackageIds = new Set<String>( TrialforceSettingsMeta.Eligible_Package_Ids__c.replace('\r','').split('\n') );
                    Integer extensionLength = (Integer)TrialforceSettingsMeta.Length_of_Extension__c;

                    if(eligiblePackageIds != null && !eligiblePackageIds.isEmpty()){
                        // UPDATE EXPIRATION DATES ON LICENSES IF PERMITTED
                        for(sfLma__License__c licenseToUpdate : qualifiedLicenses){
                            
                            // CHECK IF LICENSE PACKAGE IS ALLOWED
                            if(eligiblePackageIds.contains(licenseToUpdate.sfLma__Package__c)){

                                // GET PARENT ACCOUNT NAME
                                String parentAccountName = parentAccountNames.get(licenseToUpdate.sfLma__Account__c).toLowerCase();

                                // CHECK IF ACCOUNT IS PERMITTED TRIAL EXTENSIONS
                                Boolean accountAllowed = false;
                                if(accountNameKeywords != null){
                                    for(String keyword : accountNameKeywords){
                                        if(parentAccountName.contains(keyword)){
                                            // ACCOUNT NAME CONTAINS KEYWORD, ALLOW
                                            accountAllowed = true;
                                            break;
                                        }
                                    }
                                }
                                else{
                                    // NO KEYWORDS SPECIFIED, ALLOW
                                    accountAllowed = true;
                                }

                                // STOP PROCESSING LICENSE IF ACCOUNT IS NOT PERMITTED
                                if(!accountAllowed){
                                    break;
                                }

                                // EXTEND EXPIRATION
                                licenseToUpdate.sfLma__Expiration__c = licenseToUpdate.CreatedDate.date().addDays(extensionLength);
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SFLMALicenseHelper', 'extendTrialLicense'); 
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SFLMALicenseHelper', 'extendTrialLicense', updatedLicenses, ex, true);
        }
    }


}