/**
* @author Conga Services
* @date 20190212
* @version 1.00
* @description UpdateOppFromLicenseBatch - Updated fields on opportunity when a new licence is installed.  Sends email to onboarding team.
*/
public with sharing class UpdateOppFromLicenseBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    public final String LicensesToProcess;
    public Datetime LastRunDateTime;
    public final Map<Id,String> PackageMap;
    public Set<Opportunity> Opps; //Orders
    public Map<Id,Id> oppToLicenseMap; //orderToLicenseMap;

    /**
    * @description UpdateOppFromLicenseBatch - Constructor
    */
    public UpdateOppFromLicenseBatch() {
        // GET DATETIME OF LAST SUCCESSFUL RUN
        this.LastRunDateTime = System.Now().addHours(-96);
        if(!Test.isRunningTest()){
            for(AsyncApexJob myJob : [SELECT Status, ApexClass.Name, CompletedDate FROM AsyncApexJob WHERE ApexClass.Name='UpdateOppFromLicenseBatch' AND Status='Completed' ORDER BY CompletedDate DESC Limit 1]){
                if(myJob.CompletedDate!=null){
                    this.LastRunDateTime = myJob.CompletedDate;
                } 
            }       
        }
        this.packageMap = new Map<Id, String>();
        
        // GET LMA PACKAGES
        for(SfLma__Package__c sfPackage : [SELECT Id, Name FROM SfLma__Package__c]){
            this.PackageMap.put(sfPackage.Id, sfPackage.Name);
        }
        
        // GET ID OF USER(S) TO FILTER OUT
        this.LicensesToProcess = ' Select Id, CreatedDate, SfLma__Package__c, SfLma__Subscriber_Org_ID__c From sfLma__License__c Where CreatedDate > :LastRunDateTime Order by SfLma__Subscriber_Org_ID__c ';
        this.Opps = new Set<Opportunity>();
        this.oppToLicenseMap = new Map<Id,Id>();
    }

    /**
    * @description start - 
    * @param Database.BatchableContext bc
    * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(LicensesToProcess);
    }

    /**
    * @description execute - 
    * @param Database.BatchableContext bc
    * @param List<sObject> scope
    * @return void
    */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        Set<String> orgIds = new Set<String>();
        if(scope.size()>0){
            List<sfLma__License__c> sfLicenses = (List<sfLma__License__c>)scope;
            for(sfLma__License__c sfLicense : sfLicenses){
                if(sfLicense.SfLma__Subscriber_Org_ID__c != null){
                    orgIds.add(sfLicense.SfLma__Subscriber_Org_ID__c);
                }
            }
            // FIND APPLICABLE Opps AND UPDATE
            for(Opportunity o : [SELECT Id, Package_Installs__c, Most_Recent_Package_Install__c, Most_Recent_Install_Date_Time__c, Customer_org_id__c, OwnerId, Owner.Name FROM Opportunity
                                 WHERE Customer_Org_Id__c IN :orgIds AND IsClosed = true AND IsWon = true AND Sales_Ops_Approved__c = true AND Sales_Ops_Status__c = 'Synced with Intacct']){
                for(sfLma__License__c sfLicense : sfLicenses){
                    if(o.Customer_org_id__c == sfLicense.SfLma__Subscriber_Org_ID__c){
                        if(packageMap != null && packageMap.containsKey(sfLicense.SfLma__Package__c)){
                            String packageName = packageMap.get(sfLicense.SfLma__Package__c);
                            if(o.Most_Recent_Package_Install__c!=packageName){
                                o.Most_Recent_Package_Install__c = packageName;
                                o.Most_Recent_Install_Date_Time__c = System.Now();

                                if(String.isBlank(o.Package_Installs__c)){
                                    o.Package_Installs__c = packageName;
                                }
                                else{
                                    o.Package_Installs__c = o.Package_Installs__c + ';' + packageName;
                                }
                                oppToLicenseMap.put(o.Id,sfLicense.Id);
                                Opps.add(o);    
                            }                       
                        }
                    }
                }
            }
        }
    }

    /**
    * @description finish - 
    * @param Database.BatchableContext bc
    * @return void
    */
    public void finish(Database.BatchableContext bc) {
        if(Opps != null && Opps.size() > 0){
            List<Opportunity> oppsToUpdate = new List<Opportunity>(Opps);
            List<Id> updatedOppIds = new List<Id>();
            List<String> failedOrderIds = new List<Id>();
            Database.SaveResult[] srList = Database.update(oppsToUpdate, true);
            SystemIssueLogHelper.CheckForDatabaseErrors(srList, 'UpdateOppFromLicenseBatch', 'finish', true);

            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    updatedOppIds.add(sr.getId());
                }
            }

            if(updatedOppIds.size()>0){
                SendProcessingEmail(updatedOppIds, oppToLicenseMap);
            }   
        }
    }

    /**
    * @description execute - 
    * @param SchedulableContext sc
    * @return void
    */
    public void execute(SchedulableContext sc){
         Database.executeBatch(new UpdateOppFromLicenseBatch(), 200);
    }

    /**
    * @description SendProcessingEmail - 
    * @param List<Id> updatedIds
    * @param Map<Id,Id> oppLicenseMap
    * @return void
    */
    private static void SendProcessingEmail(List<Id> updatedIds, Map<Id,Id> oppLicenseMap){
        List<EmailTemplate> emailTemplate = [Select Id, Subject, HTMLValue, Body From EmailTemplate Where DeveloperName = 'Opportunity_Update_Batch_Processing_Complete'];
        List<OrgWideEmailAddress> owe = [Select Id, Address, DisplayName From OrgWideEmailAddress Where DisplayName = 'Conga Onboarding' Limit 1];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        if(emailTemplate.size() == 1){
            String oppList = '';
            for(Opportunity o : [SELECT Id, Package_Installs__c, Name, Most_Recent_Package_Install__c, Most_Recent_Install_Date_Time__c FROM Opportunity WHERE Id IN :updatedIds]){
                Id licenseId;
                if(oppLicenseMap!=null && oppLicenseMap.containsKey(o.Id)){
                    licenseId = oppLicenseMap.get(o.Id);
                }
                oppList += '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + o.Id + '">'  + o.Name + '</a>' + ' | ' + o.Most_Recent_Package_Install__c + ' | ' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + licenseId + '">' + 'Related License Record' + '</a>' +  '<br/>';
            }

            email.setSubject(emailTemplate[0].Subject.replace('{NumberOfOpps}', String.valueOf(updatedIds.size())));
            email.setHtmlBody(emailTemplate[0].HtmlValue.replace('{ListOfOpps}', oppList));
            email.setPlainTextBody(emailTemplate[0].Body.replace('{ListOfOpps}', oppList));

            if(owe.size()==1){
                email.setToAddresses(new List<String>{owe[0].Address});
                email.setOrgWideEmailAddressId(owe[0].Id);
            }

            if(!Test.isRunningTest()){
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email }, true);
            }
        }
    }


}