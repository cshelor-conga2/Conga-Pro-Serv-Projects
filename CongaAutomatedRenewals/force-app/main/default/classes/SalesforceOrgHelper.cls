/**
* @author Conga Services
* @date 20181023
* @version 1.00
* @description SalesforceOrgHelper - This class houses static methods to help perform ETL against Salesforce_Org__c objects
*/
public class SalesforceOrgHelper { 

    /**
    * @author JPesusich, ERedding
    * @description This method updates a cooresponding license record for every insert of a Salesforce_Org__c record. 
    */ 
    public static void updateLicenseObjectWithOrg(Map<Id, Salesforce_Org__C> newOrgs){
        try{        
            if(TriggerHelper.DoExecute('SalesforceOrgHelper','updateLicenseObjectWithOrg') && newOrgs != null && !newOrgs.isEmpty()){
                // GET SALESFORCE ORG IDS
                List<String> orgId18s = new List<String>();
                List<String> orgId15s = new List<String>();
                for(Salesforce_Org__c org : newOrgs.values()){
                    if(org.Salesforce_Account_Id__c != null){ 
                        orgId18s.add(org.Salesforce_Account_Id__c);
                        orgId15s.add(String.valueOf(org.Salesforce_Account_Id__c).substring(0,15));
                    }
                }

                // UPDATE LICENSE SALESFORCE ORG LOOKUPS
                List<sfLma__License__c> licensesToUpdate = new List<sfLma__License__c>();
                for(sfLma__License__c[] licenses : [SELECT Id, Salesforce_OrgId__c, sfLma__Subscriber_Org_ID__c FROM sfLma__License__c 
                                                    WHERE sfLma__Subscriber_Org_ID__c IN :orgId18s OR sfLma__Subscriber_Org_ID__c IN :orgId15s]){
                    for(sfLma__License__c lic : licenses){
                        for(Salesforce_Org__c org : newOrgs.values()){
                            if(Id.valueOf(org.Salesforce_Account_Id__c) == Id.valueOf(lic.sfLma__Subscriber_Org_ID__c) && lic.Salesforce_OrgId__c != org.Id){
                                lic.Salesforce_OrgId__c = org.Id;
                                licensesToUpdate.add(lic);
                            }
                        }
                    }
                }

                // COMMIT UPDATES TO DATABASE
                if(licensesToUpdate.size() > 0){
                    Database.saveResult[] licenseResults = Database.update(licensesToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(licenseResults, 'SalesforceOrgHelper', 'updateLicenseObjectWithOrg', true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SalesforceOrgHelper', 'updateLicenseObjectWithOrg');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SalesforceOrgHelper', 'updateLicenseObjectWithOrg', newOrgs, ex, true);
        } 
    }



  // Map Salesforce_Org__c to Account fields
    //private static Map<String,String> fieldMap = new Map<String,String>{
        // Mapped to different field names
        //'Account__c'=>'Id',
        //'Gringotts_Account_Id__c'=>'Id',// Legacy gringotts account id, will be new org id for new customers
            
        // Were standard Account fields, no longer
        //'Name'=>'Name',
        //'Phone__c'=>'Phone',
        //'BillingCity__c'=>'BillingCity',
        //'BillingCountry__c'=>'BillingCountry',
        //'BillingPostalCode__c'=>'BillingPostalCode',
        //'BillingState__c'=>'BillingState',
        //'BillingStreet__c'=>'BillingStreet',
        //'Description__c'=>'Description',
        //'Site__c'=>'Site',//##SMH ,
        //'Salesforce_Account_Id__c'=>'Salesforce_Account_Id__c'

        // Custom field names haven't changed
        // ##SMH ERROR: No such column 'Allow_All_Master_Objects__c' on entity 'Account'.## 'Allow_All_Master_Objects__c'=>'Allow_All_Master_Objects__c',
        // ##SMH ERROR: No such column 'Allowed_Master_Object_Namespaces__c' on entity 'Account'.## 'Allowed_Master_Object_Namespaces__c'=>'Allowed_Master_Object_Namespaces__c',
        // ##SMH ERROR: No such column 'Allowed_Master_Objects__c' on entity 'Account'.## 'Allowed_Master_Objects__c'=>'Allowed_Master_Objects__c',
        // ##SMH ERROR: No such column## 'Composer_Disable_Text_Based_Merge_Field__c'=>'Composer_Disable_Text_Based_Merge_Field__c',
        // ##SMH ERROR: No such column## 'Composer_Enable_Text_Based_Merge_Field__c'=>'Composer_Enable_Text_Based_Merge_Field__c',
        // ##SMH ERROR: No such column## 'Composer_Simple_Report_Column_Names__c'=>'Composer_Simple_Report_Column_Names__c',
        // ##SMH ERROR: No such column## 'Conga_Account_Suspension_Date__c'=>'Conga_Account_Suspension_Date__c',
        // ##SMH ERROR: No such column## 'Conga_Activation_Date__c'=>'Conga_Activation_Date__c',
        // ##SMH ERROR: No such column## 'Conga_Allow_My_Templates__c'=>'Conga_Allow_My_Templates__c',
        // ##SMH ERROR: No such column## 'Conga_Authorized_Users_Verified__c' => 'Conga_Authorized_Users_Verified__c',
        // ##SMH ERROR: No such column## 'Conga_Prevent_Auto_Incrementing__c'=>'Conga_Prevent_Auto_Incrementing__c',
        // ##SMH ERROR: No such column## 'Conga_Query_Object_Name_Correction__c'=>'Conga_Query_Object_Name_Correction__c',
        // ##SMH ERROR: No such column## 'Conga_Require_TS_TE_in_Word__c'=>'Conga_Require_TS_TE_in_Word__c',
        // ##SMH ERROR: No such column## 'Conga_Use_Communication_Templates__c'=>'Conga_Use_Communication_Templates__c',
        // ##SMH ERROR: No such column## 'Conga_Use_Custom_Template_Repository__c'=>'Conga_Use_Custom_Template_Repository__c',
        // ##SMH ERROR: No such column## 'Conga_Use_Conga_Template_Repository_5__c'=>'Conga_Use_Conga_Template_Repository_5__c',
        // ##SMH ERROR: No such column## 'Conga_Conductor_API_Floor__c'=>'Conga_Conductor_API_Floor__c',
        // ##SMH ERROR: No such column## 'Conga_Conductor_Authorized__c'=>'Conga_Conductor_Authorized__c',
        // ##SMH ERROR: No such column## 'Conga_Conductor_Expiration_Date__c'=>'Conga_Conductor_Expiration_Date__c',
        // ##SMH ERROR: No such column## 'Conga_Conductor_Scheduler_Email__c'=>'Conga_Conductor_Scheduler_Email__c',
        // ##SMH ERROR: No such column## 'Conga_Conductor_Scheduler_Master_Switch__c'=>'Conga_Conductor_Scheduler_Master_Switch__c',
        // ##SMH ERROR: No such column## 'Conga_Conductor_Scheduler_Password__c'=>'Conga_Conductor_Scheduler_Password__c',
        // ##SMH ERROR: No such column## 'Conga_Conductor_Scheduler_Security_Token__c'=>'Conga_Conductor_Scheduler_Security_Token__c',
        // ##SMH ERROR: No such column## 'Conga_Conductor_Scheduler_Username__c'=>'Conga_Conductor_Scheduler_Username__c',
        // ##SMH ERROR: No such column## 'Conga_Enforce_User_Management__c'=>'Conga_Enforce_User_Management__c',
        // ##SMH ERROR: No such column## 'Conga_Enforce_LMA__c'=>'Conga_Enforce_LMA__c',
        // ##SMH ERROR: No such column## 'Conga_Lockout_Editor__c'=>'Conga_Lockout_Editor__c',
        // ##SMH ERROR: No such column## 'Conga_SendGrid_Password__c'=>'Conga_SendGrid_Password__c',
        // ##SMH ERROR: No such column## 'Conga_SendGrid_Username__c'=>'Conga_SendGrid_Username__c',
        // ##SMH ERROR: No such column## 'Conga_Subscription_Expiration_Date__c'=>'Conga_Subscription_Expiration_Date__c',
        // ##SMH ERROR: No such column## 'Conga_Task_Custom_Field__c'=>'Conga_Task_Custom_Field__c',
        // ##SMH ERROR: No such column## 'Conga_Task_Custom_Field_Label__c'=>'Conga_Task_Custom_Field_Label__c',
        // ##SMH ERROR: No such column## 'Conga_Trial_Expiration_Date__c'=>'Conga_Trial_Expiration_Date__c',
        // ##SMH ERROR: No such column## 'Conga_Use_Minimal_Account_Fields__c'=>'Conga_Use_Minimal_Account_Fields__c',
        // ##SMH ERROR: No such column## 'Conga_Use_Minimal_Contact_Fields__c'=>'Conga_Use_Minimal_Contact_Fields__c',
        // ##SMH ERROR: No such column## 'Conga_Use_Minimal_Lead_Fields__c'=>'Conga_Use_Minimal_Lead_Fields__c',
        // ##SMH ERROR: No such column## 'Conga_User_Management_System__c'=>'Conga_User_Management_System__c',
        // ##SMH ERROR: No such column## 'Conga_Workflow_24_Hour_Limit__c'=>'Conga_Workflow_24_Hour_Limit__c',
        // ##SMH ERROR: No such column## 'Conga_Workflow_Authorized__c'=>'Conga_Workflow_Authorized__c',
        // ##SMH ERROR: No such column## 'Conga_Workflow_Expiration_Date__c'=>'Conga_Workflow_Expiration_Date__c',
        // ##SMH ERROR: No such column## 'Courier_From_Source__c'=>'Courier_From_Source__c',
        // ##SMH ERROR: No such column## 'Courier_From_Type__c'=>'Courier_From_Type__c',
        // ##SMH ERROR: No such column## 'Courier_Activation_Date__c'=>'Courier_Activation_Date__c',
        // ##SMH ERROR: No such column## 'Courier_Admin_Email__c'=>'Courier_Admin_Email__c',
        // ##SMH ERROR: No such column## 'Courier_Admin_Name__c'=>'Courier_Admin_Name__c',
        // ##SMH ERROR: No such column## 'Courier_Disabled_by_AppExtremes__c'=>'Courier_Disabled_by_AppExtremes__c',
        // ##SMH ERROR: No such column## 'Courier_Email_Footer__c'=>'Courier_Email_Footer__c',
        // ##SMH ERROR: No such column## 'Courier_Email_Format__c'=>'Courier_Email_Format__c',
        // ##SMH ERROR: No such column## 'Courier_Enabled__c'=>'Courier_Enabled__c',
        // ##SMH ERROR: No such column## 'Courier_Enable_Report_based_Recipients__c'=>'Courier_Enable_Report_based_Recipients__c',
        // ##SMH ERROR: No such column## 'Courier_Expired__c'=>'Courier_Expired__c',
        // ##SMH ERROR: No such column## 'Courier_Login_Problem_Notification_Date__c'=>'Courier_Login_Problem_Notification_Date__c',
        // ##SMH ERROR: No such column## 'Courier_Monthly_Plan__c'=>'Courier_Monthly_Plan__c',
        // ##SMH ERROR: No such column## 'Courier_Org_Wide_Email_Id__c'=>'Courier_Org_Wide_Email_Id__c',
        // ##SMH ERROR: No such column## 'Courier_Password__c'=>'Courier_Password__c',
        // ##SMH ERROR: No such column## 'Courier_Schedules_Overage__c'=>'Courier_Schedules_Overage__c',
        // ##SMH ERROR: No such column## 'Courier_Security_Token__c'=>'Courier_Security_Token__c',
        // ##SMH ERROR: No such column## 'Courier_Server_Number__c'=>'Courier_Server_Number__c',
        // ##SMH ERROR: No such column## 'Courier_Subscription_Expiration_Date__c'=>'Courier_Subscription_Expiration_Date__c',
        // ##SMH ERROR: No such column## 'Conga_Licenses__c'=>'Conga_Licenses__c',
        // ##SMH ERROR: No such column## 'Courier_Subscription_Start_Date__c'=>'Courier_Subscription_Start_Date__c',
        // ##SMH ERROR: No such column## 'Conga_Subscription_Start_Date__c'=>'Conga_Subscription_Start_Date__c',
        // ##SMH ERROR: No such column## 'Conga_Licenses__c'=>'Conga_Licenses__c',
        // ##SMH ERROR: No such column## 'Courier_Trial_Expiration_Date__c'=>'Courier_Trial_Expiration_Date__c',
        // ##SMH ERROR: No such column## 'Courier_Trial_Maximum_Reports__c'=>'Courier_Trial_Maximum_Reports__c',
        // ##SMH ERROR: No such column## 'Courier_Use_Admin_as_ReplyTo__c'=>'Courier_Use_Admin_as_ReplyTo__c',
        // ##SMH ERROR: No such column## 'Courier_User_Name__c'=>'Courier_User_Name__c',
        // ##SMH ERROR: No such column## 'Salesforce_Account_Id__c'=>'Salesforce_Account_Id__c',
        // ##SMH ERROR: No such column## 'Enable_Extended_Logging__c'=>'Enable_Extended_Logging__c',
        // ##SMH ERROR: No such column## 'Establishing_Partner__c'=>'Establishing_Partner__c',
        // ##SMH ERROR: No such column## 'Maximum_Concurrent_Processes__c'=>'Maximum_Concurrent_Processes__c',
        // ##SMH ERROR: No such column## 'Composer_Max_Rows_Per_Detail_Data_Set__c'=>'Composer_Max_Rows_Per_Detail_Data_Set__c',
        // ##SMH ERROR: No such column## 'Composer_Max_Templates_Per_Merge__c'=>'Composer_Max_Templates_Per_Merge__c',
        // ##SMH ERROR: No such column## 'Refresh_Token_Status__c'=>'Refresh_Token_Status__c',
        // ##SMH ERROR: No such column## 'Salesforce_Instance__c'=>'Salesforce_Instance__c',
        // ##SMH ERROR: No such column## 'Salesforce_Users__c'=>'Salesforce_Users__c',
        // ##SMH ERROR: No such column## 'Sandbox_Edition__c'=>'Sandbox_Edition__c',
        // ##SMH ERROR: No such column## 'Subscriber_Org_Type__c'=>'Subscriber_Org_Type__c',
        // ##SMH ERROR: No such column## 'Composer_WordDetailRegionClassicMode__c'=>'Composer_WordDetailRegionClassicMode__c'

        // Formula fields
        //'AccountId__c'=>'',
        //'Salesforce_Org_Id_15__c'=>'', Formula

        // Not used yet or ever
        //'Allow_All_Master_Objects__c'=>'', TODO
        //'Allowed_Master_Object_Namespaces__c'=>'', TODO
        //'Allowed_Master_Objects__c'=>'', TODO
        //'Org_Id__c'=>'', // NOT USED
        //'Org_Type__c'=>'', // NOT USED
    //};


    ///////////////// CONGA SERVICES, EREDDING 20180703 - CODE NO LONGER NEEDED BASED ON DISCUSSION WITH REESE. OTHER TOOLS/PROCESSES ARE HANDLING THIS


    ///**
    //* @author JPesusich, ERedding
    //* @version 1.00
    //* @description This method updates/creates a corresponding Account record for every Saleforce_Org__c record
    //*/
    //public static void upsertAccountRecord(List<Salesforce_Org__c> newOrgs){
    //    if(TriggerHelper.DoExecute('SalesforceOrg.UpsertAccountRecord') && newOrgs != null && !newOrgs.isEmpty()){
    //        try{
    //            // GET BUSINESS ACCOUNT RECORD
    //            Id rAcctTypeId = null;
    //            for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account' AND IsActive = true]){
    //                if(rt.DeveloperName == 'Business_Account'){
    //                    rAcctTypeId = rt.Id;
    //                    break;
    //                }
    //            }
                
    //            // CREATE COLLECTIONS OF NECESSARY DATA
    //            Set<String> gringottsIds = new Set<String>();
    //            List<Salesforce_Org__c> sfOrgsWithoutMatchingAccounts = new List<Salesforce_Org__c>();
    //            Map<String, Salesforce_Org__c> sfOrgsWithIdsMap = new Map<String, Salesforce_Org__c>();
    //            for(Salesforce_Org__c sfOrg : newOrgs){
    //                if(String.isNotBlank(sfOrg.Gringotts_Account_Id__c)){
    //                    gringottsIds.add(sfOrg.Gringotts_Account_Id__c);
    //                    sfOrgsWithIdsMap.put(sfOrg.Gringotts_Account_Id__c, sfOrg);
    //                }
    //                else{
    //                    sfOrgsWithoutMatchingAccounts.add(sfOrg);
    //                }
    //            }

    //            // SEARCH FOR MATCHING ACCOUNTS FOR SF ORGS WITH GRINGOTTS IDS
    //            List<Account> accountsToUpdate = new List<Account>();
    //            Map<Id, Account> foundAccounts = new Map<Id, Account>((List<Account>)Database.query('SELECT ' + String.join(fieldMap.values(),',') + ' FROM Account WHERE Id IN :gringottsIds'));
    //            for(String gringottsId : sfOrgsWithIdsMap.keySet()){
    //                if(foundAccounts.containsKey(gringottsId)){
    //                    // MATHCING ACCOUNT FOUND, CHECK FOR QUALIFYING CHANGES
    //                    Boolean doUpdate = false;
    //                    for(String fieldName : fieldMap.keySet()){
    //                        // ACCOUNT FOUND, CHECK FOR CHANGES
    //                        if(foundAccounts.get(gringottsId).get(fieldMap.get(fieldName)) != sfOrgsWithIdsMap.get(gringottsId).get(fieldName)){
    //                            foundAccounts.get(gringottsId).put(fieldMap.get(fieldName), sfOrgsWithIdsMap.get(gringottsId).get(fieldName));
    //                            doUpdate = true;
    //                        }
    //                    }

    //                    if(doUpdate){
    //                        // CHANGE MADE, QUEUE ACCOUNT FOR UPDATE
    //                        accountsToUpdate.add(foundAccounts.get(gringottsId));
    //                    }

    //                    if(sfOrgsWithIdsMap.get(gringottsId).Id == null){
    //                        // NEW SF ORG WITH A GRINGOTTS ID, UPDATE SF ORG WITH FOUND ACCOUNT
    //                        sfOrgsWithIdsMap.get(gringottsId).Account__c = foundAccounts.get(gringottsId).Id;
    //                    }
    //                }
    //                else{
    //                    // MATHCING ACCOUNT NOT FOUND, ADD SF ORG TO NEW ACCOUNT LIST
    //                    sfOrgsWithoutMatchingAccounts.add(sfOrgsWithIdsMap.get(gringottsId));
    //                }
    //            }

    //            // CREATE NEW ACCOUNTS TO INSERT
    //            List<Account> accountsToInsert = new List<Account>();
    //            for(Salesforce_Org__c sfOrg : sfOrgsWithoutMatchingAccounts){
    //                Account acct = new Account(RecordTypeId = rAcctTypeId);
    //                for(String fieldName : fieldMap.keySet()){
    //                    if(fieldName != 'Id'){
    //                        acct.put(fieldMap.get(fieldName), sfOrg.get(fieldName));
    //                    }
    //                }
    //                accountsToInsert.add(acct);
    //            }

    //            // COMMIT NEW ACCOUNTS TO DATABASE AND REPORT ANY ERRORS TO THE SYSTEM ISSUE LOG
    //            if(!accountsToInsert.isEmpty()){
    //                Database.SaveResult[] insertResults = Database.insert(accountsToInsert, false);
    //                SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'Salesforce_OrgHelper', 'upsertAccountRecord', false);

    //                // PROCESS SUCCESSFUL RESULTS
    //                for(Integer i = 0; i < insertResults.size(); i++){
    //                    Database.SaveResult result = insertResults[i];
    //                    if(result.isSuccess()){
    //                        for(Salesforce_Org__c sfOrg : newOrgs){
    //                            if(sfOrg.Gringotts_Account_Id__c == null && sfOrg.Salesforce_Account_Id__c == accountsToInsert[i].Salesforce_Account_Id__c){
    //                                sfOrg.Gringotts_Account_Id__c = result.getId(); //only for insert
    //                                sfOrg.Account__c = result.getId();
    //                            }
    //                        }
    //                    }
    //                }
    //            }

    //            // COMMIT UPDATED ACCOUNTS TO DATABASE AND REPORT ANY ERRORS TO THE SYSTEM ISSUE LOG
    //            if(!accountsToUpdate.isEmpty()){
    //                Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
    //                SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'Salesforce_OrgHelper', 'upsertAccountRecord', false);
    //            }

    //            // COMMIT ANY ERRORS TO THE DATABASE
    //            SystemIssueLogHelper.UpsertExceptions();
    //        }
    //        catch(Exception ex){
    //            SystemIssueLogHelper.LogException(new SystemIssueLogWrapper('Salesforce_OrgHelper', 'upsertAccountRecord', SystemIssueLogHelper.CreateListofIds(newOrgs), ex), true);
    //        }
    //    }
    //}


}