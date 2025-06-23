/**
* @author John Coston, Jereriah Manning, Created for Conga Partner Team
* @date 20170205
* @version 1.00
* @description CreateMonthlyBulkUtilizationRecords2 - 
*/
public class CreateMonthlyBulkUtilizationRecords2{
    private List<Partner_Profile__c> PartnerProfiles = [SELECT Id, Account__c, Account__r.Name, Bulk_License_Count__c, Bulk_Licenses_Allocated__c FROM Partner_Profile__c ORDER By Account__r.Name ASC LIMIT 25000];
    private List<AggregateResult> LatestCongaUsageHistory = new List<AggregateResult>();
    private List<AggregateResult> LatestCaseStats = new List<AggregateResult>();   
    private List<AggregateResult> PartnerCaseStatsList = new List<AggregateResult>();        
    private Map<Id, Id> PPIdMap = new Map<Id, Id>();
    private Map<Id, Double> PPLicenseMap = new Map<Id, Double>();
    private Map<Id, AggregateResult> AccountCaseStatMap = new Map<Id, AggregateResult>();
    private Map<Id, AggregateResult> PartnerCaseStatMap = new Map<Id, AggregateResult>();    
    List<Bulk_License_Utilization__c> BulkLicenseUtilizationToCreate = new List<Bulk_License_Utilization__c>();
    
    /**
    * @description CreateMonthlyBulkUtilizationRecords2 - Constructor
    */
    public CreateMonthlyBulkUtilizationRecords2(){
        populateLatestCongaHistoryList();
        populateLatestCaseStatsList();
        populatePartnerCaseStatsList();
        populateMaps();
        setupInsertList();
        createBLURecords();
    }

    /**
    * @description populateMaps - 
    * @return void
    */
    private void populateMaps(){
        //System.debug('****************** PartnerProfiles.size() in populateMaps: ' + PartnerProfiles.size());
        //System.debug('****************** LatestCaseStats.size() in populateMaps: ' + LatestCaseStats.size());                
        
        if(PartnerProfiles.size() > 0){                               
            for (Partner_Profile__c pp : PartnerProfiles){
                PPIdMap.put(pp.Account__c, pp.Id);
                PPLicenseMap.put(pp.Id, pp.Bulk_License_Count__c);
            }
        }

        Id tempPartnerId;        
        if(LatestCaseStats.size() > 0){
            for(AggregateResult a : LatestCaseStats){
                //System.debug('****************** a in populateMaps: ' + a);                
                tempPartnerId = (Id) a.get('Establishing_Partner__c');
                AccountCaseStatMap.put(tempPartnerId, a);    
            }
        }

        Id partnerAccountId;        
        if(PartnerCaseStatsList.size() > 0){
            for(AggregateResult a : PartnerCaseStatsList){
                //System.debug('****************** a in populateMaps: ' + a);  
                partnerAccountId = (Id) a.get('AccountId');
                PartnerCaseStatMap.put(partnerAccountId, a);                                              
            } 
        }          
    }

    /**
    * @description populateLatestCongaHistoryList - 
    * @return void
    */       
    private void populateLatestCongaHistoryList(){
        LatestCongaUsageHistory = [SELECT AVG(Salesforce_Org__r.Conga_Licenses__c) CMLicenses, COUNT(Salesforce_Org__c) TotalAccounts, SUM(Total_Composer_Successes__c) CMSuccesses, SUM(Composer_Service_Events__c) CMServiceEvents, SUM(Total_Conductor_Successes__c) CNSuccesses, SUM(Total_Workflow_Successes__c) WFSuccesses, SUM(Total_CMM_Successes__c) MMSuccesses, SUM(Total_Unique_Users__c) UniqueUsers, Establishing_Partner__c, Establishing_Partner__r.Name 
                                FROM Conga_Usage_History2__c 
                                WHERE (Establishing_Partner__c IN 
                                        (SELECT Account__c FROM Partner_Profile__c WHERE (Account__r.Type = 'Partner - ISV/Wholesale' OR Account__r.Type = 'Partner - VAR/ISV' OR Account__r.Type = 'Partner - ISV/OEM')) 
                                    AND Month__c = LAST_MONTH AND Salesforce_Org__r.Org_Type__c = 'Production'
                                ) 
                                GROUP BY Establishing_Partner__c, Establishing_Partner__r.Name 
                                LIMIT 25000];
        
        //System.debug('****************** LatestCongaUsageHistory.size() after populating: ' + LatestCongaUsageHistory.size());
        //System.debug('****************** LatestCongaUsageHistory after populating: ' + LatestCongaUsageHistory);        
    }

    /**
    * @description populateLatestCaseStatsList - 
    * @return void
    */        
    private void populateLatestCaseStatsList(){
        LatestCaseStats = [SELECT Count(Id) CaseCount, SUM(Time_Spent_Hours__c) TotalHours, Account.Establishing_Partner__c, Account.Establishing_Partner__r.Name 
                        FROM Case
                        WHERE (AccountId IN                                                     
                                (SELECT Account_For_BLU_Report__c FROM Conga_Usage_History2__c WHERE (Establishing_Partner__c != null OR Establishing_Partner__c != '') AND Month__c = LAST_MONTH) 
                            AND CreatedDate = LAST_MONTH
                        )
                        GROUP BY Account.Establishing_Partner__c, Account.Establishing_Partner__r.Name 
                        LIMIT 25000];
                        
        //System.debug('****************** PartnerCaseStatsList.size() after populating: ' + PartnerCaseStatsList.size());
        //System.debug('****************** PartnerCaseStatsList after populating: ' + PartnerCaseStatsList);                           
    }

    /**
    * @description populatePartnerCaseStatsList - 
    * @return void
    */
    private void populatePartnerCaseStatsList(){
        PartnerCaseStatsList = [SELECT Count(Id) PartnerCaseCount, SUM(Time_Spent_Hours__c) PartnerTotalHours, AccountId, Account.Name 
                        FROM Case
                        WHERE (
                            (Account.Type = 'Partner - ISV/Wholesale' OR Account.Type = 'Partner - VAR/ISV' OR Account.Type = 'Partner - ISV/OEM') 
                            AND CreatedDate = LAST_MONTH
                        ) 
                        GROUP BY AccountId, Account.Name 
                        LIMIT 25000];
                        
        //System.debug('****************** LatestCaseStats.size() after populating: ' + LatestCaseStats.size());
        //System.debug('****************** LatestCaseStats after populating: ' + LatestCaseStats);                           
    }

    /**
    * @description setupInsertList - 
    * @return void
    */       
    private void setupInsertList(){
        /*** Method Variables for Aggregate Query results ***/
        Id EstablishingPartnerId;
        Double NumberOfCustomerAccounts, UtilizedCMLicenses, CMSuccesses, CMServiceEvents, CNSuccesses, WFSuccesses, MMSuccesses, UniqueUsers;
        AggregateResult CaseQueryResult;
        AggregateResult PartnerCaseQueryResult;                    
        /******/
        
        for(AggregateResult a : LatestCongaUsageHistory){            
            if(a.get('Establishing_Partner__c') != null){
                EstablishingPartnerId = (Id) a.get('Establishing_Partner__c');
                NumberOfCustomerAccounts = (Double) a.get('TotalAccounts');
                UtilizedCMLicenses = (Double) a.get('CMLicenses');      
                CMSuccesses = (Double) a.get('CMSuccesses');
                CMServiceEvents = (Double) a.get('CMServiceEvents');
                CNSuccesses = (Double) a.get('CNSuccesses');
                WFSuccesses = (Double) a.get('WFSuccesses');
                MMSuccesses = (Double) a.get('MMSuccesses');
                UniqueUsers = (Double) a.get('UniqueUsers');
                
                CaseQueryResult = AccountCaseStatMap.get(EstablishingPartnerId);
                    //System.debug('****************** CaseQueryResult: ' + CaseQueryResult + ' for Account Id: ' + EstablishingPartnerId);                                 
                PartnerCaseQueryResult = PartnerCaseStatMap.get(EstablishingPartnerId);
                    //System.debug('****************** PartnerCaseQueryResult: ' + PartnerCaseQueryResult + ' for Account Id: ' + EstablishingPartnerId);                 
                
                if(PPIdMap.get(EstablishingPartnerId) != null){
                    Bulk_License_Utilization__c blu = new Bulk_License_Utilization__c();
                    blu.Licenses_Available__c = PPLicenseMap.get(PPIdMap.get(EstablishingPartnerId));
                    blu.Partner_Profile__c = PPIdMap.get(EstablishingPartnerId);  
                    blu.Number_Of_Customer_Accounts__c = NumberOfCustomerAccounts;
                    blu.Total_Utilized_Composer_Licenses__c = UtilizedCMLicenses; 
                    blu.Composer_Service_Events_Used__c = CMServiceEvents;
                    blu.Composer_Successes__c = CMSuccesses;
                    blu.Conductor_Successes__c = CNSuccesses;
                    blu.Workflow_Successes__c = WFSuccesses;
                    blu.Total_CMM_Successes__c = MMSuccesses;
                    blu.Composer_Unique_Users__c = UniqueUsers;

                    if (PartnerCaseQueryResult != null){
                        blu.Partner_Cases_Opened__c = (Double) PartnerCaseQueryResult.get('PartnerCaseCount');
                        blu.Partner_Case_Hours__c = (Double) PartnerCaseQueryResult.get('PartnerTotalHours');
                    }                        
                    
                    if(CaseQueryResult != null){
                        blu.Established_Account_Cases_Opened__c = (Double) CaseQueryResult.get('CaseCount');
                        blu.Established_Account_Case_Hours__c = (Double) CaseQueryResult.get('TotalHours');
                    }
                        
                    //System.debug('****************** blu before adding to list to insert: ' + blu); 
                    BulkLicenseUtilizationToCreate.add(blu);
                }                                               
            }            
        }      
    }

    /**
    * @description createBLURecords - 
    * @return void
    */  
    private void createBLURecords(){
        Database.insert(BulkLicenseUtilizationToCreate);  
    }


}