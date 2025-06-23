/** 
* @author Conga Services, eredding
* @date 20180806
* @version 1.00
* @description Schedulable_ProcessSignUpRequests - Schedulable apex that queries for new SignUpRequest copies and executes logic accordingly
*/
public class Schedulable_ProcessSignUpRequests implements Schedulable {

    /** 
    * @description execute - Logic to execute on a schedule
    */
    public void execute(SchedulableContext sc) {
        Map<String, Signup_Request__c> signUpRequestsByOrgId = new Map<String, Signup_Request__c>();
        try{
            // GET Signup_Request__c RECORDS CREATED IN THE PAST 7 DAYS
            for(Signup_Request__c request : [SELECT Id, Created_Org_Id__c, Trial_Days__c, CreatedDate FROM Signup_Request__c 
                                             WHERE CreatedDate = LAST_N_DAYS:7 AND Status__c = 'Success' LIMIT 300]){
                signUpRequestsByOrgId.put(request.Created_Org_Id__c, request);
            }

            // FIND AND PROCESS ANY LICENSES AND SALEFORCE ORGS MATCHING THE CREATED ORG ID
            if(!signUpRequestsByOrgId.isEmpty()){
                List<sfLma__License__c> licensesToUpdate = new List<sfLma__License__c>();
                List<Salesforce_Org__c> salesforceOrgsToUpdate = new List<Salesforce_Org__c>();

                // LICENSES
                for(sfLma__License__c license : [SELECT Id, sfLma__Expiration__c, sfLma__Subscriber_Org_ID__c FROM sfLma__License__c 
                                                 WHERE sfLma__Subscriber_Org_ID__c IN :signUpRequestsByOrgId.keySet()]){
                    if(signUpRequestsByOrgId.containsKey(license.sfLma__Subscriber_Org_ID__c)){
                        Date ninetyDaysOut = signUpRequestsByOrgId.get(license.sfLma__Subscriber_Org_ID__c).CreatedDate.addDays(90).date();
                        if(license.sfLma__Expiration__c != ninetyDaysOut){
                            license.sfLma__Expiration__c = ninetyDaysOut;
                            licensesToUpdate.add(license);
                        }
                    }
                }

                // SALESFORCE ORGS
                for(Salesforce_Org__c sfOrg : [SELECT Id, Conga_Trial_Expiration_Date__c, Courier_Trial_Expiration_Date__c, Salesforce_Org_Id_15__c FROM Salesforce_Org__c
                                               WHERE Salesforce_Org_Id_15__c IN :signUpRequestsByOrgId.keySet()]){

                    if(signUpRequestsByOrgId.containsKey(sfOrg.Salesforce_Org_Id_15__c)){
                        Date ninetyDaysOut = signUpRequestsByOrgId.get(sfOrg.Salesforce_Org_Id_15__c).CreatedDate.addDays(90).date();
                        if(sfOrg.Conga_Trial_Expiration_Date__c != ninetyDaysOut || sfOrg.Courier_Trial_Expiration_Date__c != ninetyDaysOut){
                            // SET EXPIRATION DATES
                            sfOrg.Conga_Trial_Expiration_Date__c = ninetyDaysOut;
                            sfOrg.Courier_Trial_Expiration_Date__c = ninetyDaysOut;
                            // SET AUTHORIZATION CHECKBOXES
                            sfOrg.Conga_Conductor_Authorized__c = true;
                            sfOrg.Conga_Workflow_Authorized__c = true;
                            sfOrg.Courier_Enabled__c = true;
                            salesforceOrgsToUpdate.add(sfOrg);
                        }
                    }
                }

                // SAVE LICENSE UPDATES
                if(!licensesToUpdate.isEmpty()){
                    Database.SaveResult[] updateLicensesResult = Database.update(licensesToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(updateLicensesResult, 'Schedulable_ProcessSignUpRequests', 'execute', true);
                }

                // SAVE SALESFORCE ORG UPDATES
                if(!salesforceOrgsToUpdate.isEmpty()){
                    Database.SaveResult[] updateSalesforceOrgsResult = Database.update(salesforceOrgsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(updateSalesforceOrgsResult, 'Schedulable_ProcessSignUpRequests', 'execute', true);
                }

                // SAVE ANY LOGGED ERRORS
                SystemIssueLogHelper.UpsertExceptions();
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('Schedulable_ProcessSignUpRequests', 'execute', signUpRequestsByOrgId.values(), ex, true);
        }
    }


}