/**
* @author Jereriah Manning
* @date 20140720
* @version 2.00
* @description PPOtherDataUpdaterToBatch - Created for Conga Partner Team
*    Updated by Bethany Spencer
*    16Dec15
*    Version 2.1.0
*    Logic to allow multiple PPs and only roll-up values on non-retired records
*
*    Updated by Tiffany Kroner
*    8Jun2016
*    Version 2.2
*    updated to look at new opportunity fields 
*
*    Updated by Tiffany Kroner/J Manning
*    21 Oct 2016
*    Version 2.3
*    Added Conga Certifcations From Contacts
*
*    Updated by Tiffany Kroner/J Manning
*    04 May 2017
*    Version 2.4
*    Splitting some Tasks into multiple Classes b/c of time out issue.
*        This is going to the be the "Other" stuff moving forward
*
*    Updated by J Manning
*    31 AUG 2017
*    Version 3.0
*        Doing the Count Query work here and then handing the Maps over to a Batch job to avoid data, heap and time out limits    
***************************************/

public class PPOtherDataUpdaterToBatch{   
    
    /**
    * @description PPOtherDataUpdaterToBatch - Constructor
    */
    public PPOtherDataUpdaterToBatch(){
        // Now Unused
    }    
    
    /**
    * @description doCount - 
    * @return void
    */    
    // @Future
    public static void doCount(){
        List<Partner_Profile__c> partnerProfileRecords = new List<Partner_Profile__c>();
        List<Partner_Profile__c> partnerProfileRecordsToUpdate = new List<Partner_Profile__c>();
        Map<Id,Double> CertificationsCountMap = new Map<Id,Double>();  
        Map<Id,Double> CertificationsCountMap2 = new Map<Id,Double>();
        Map<Id,Double> ComposerCertsMap = new Map<Id,Double>();
        Map<Id,Double> ActionGridCertsMap = new Map<Id,Double>();
        Map<Id,Double> ContractsCertsMap = new Map<Id,Double>();                      
        Map<Id,Id> PPAcctMap = new Map<Id,Id>();
        Map<Id, Date> firstReportMap = new Map<Id, Date>();
        Map<Id,Double> avgCMSeatsMap = new Map<Id,Double>();        
        Map<Id, Date> mostRecentReportMap = new Map<Id, Date>();        
        List<Partner_Profile__c> PPsToUpdate = new List<Partner_Profile__c>(); 
        Map<Account, List<Contact>> AcctsWithContactsMap = new Map<Account, List<Contact>>();     
        
        partnerProfileRecords = [SELECT Id, Account__c, Retired__c, Total_Certifications__c, First_Report_Date__c, Average_Composer_Seats_Per_Deal__c, Most_Recent_Report__c
                                 FROM Partner_Profile__c WHERE Id !=null AND Retired__c = FALSE];            
            //System.debug('************************* partnerProfileRecords after SOQL Loop ' + partnerProfileRecords); 

        for(Partner_Profile__c pp : [SELECT Id, Account__c FROM Partner_Profile__c WHERE Retired__c = False AND Account__c != null]){
            PPAcctMap.put((Id)pp.get('Id'), (Id)pp.get('Account__c'));
        }            
            //System.debug('************************* PPAcctMapafter after SOQL Loop: ' + PPAcctMap); 
        
        // List of the Accounts that are parents of non-Retired Partner Profile records
        List<Account> PPAccounts = [SELECT Id 
                                    FROM Account 
                                    WHERE Id IN (SELECT Account__c FROM Partner_Profile__c WHERE Retired__c = FALSE AND Id != null) 
                                    ORDER BY Id ASC];
            //System.debug('************************* PPAccounts after Query: ' + PPAccounts); 

        // List of the Contacts that are related to parent Accounts of non-Retired Partner Profile records for Account starting with A - R                                               
        List<Contact> PPAccountContacts = [SELECT Id, AccountId, Email_Domain__c  
                                            FROM Contact 
                                            WHERE AccountId IN (SELECT Account__c FROM Partner_Profile__c WHERE Retired__c = FALSE AND Id != null) 
                                            AND Email_Domain__c NOT IN ('mail.com','google.com','gmail.com','hotmail.com','outlook.com','yahoo.com','apple.com','live.com','conga.com','getconga.com','congamerge.com','appextremes.com','salesforce.com','guest.salesforce.com','yourdomain.com','hotmail.co.uk')   
                                            AND Email_Domain__c != null AND Email_Domain__c != '' AND Contact_Status__c != 'Departed' 
                                            AND Account.RecordTypeId = '01250000000Dysv' 
                                            ORDER BY AccountId ASC];
            //System.debug('************************* PPAccountContacts after Query: ' + PPAccountContacts); 

        List<Account> acctsWithContactsSQ = [SELECT Id, 
                                              (SELECT Id, Email_Domain__c FROM Contacts WHERE Email_Domain__c != null AND Email_Domain__c != '' AND Email_Domain__c NOT IN ('mail.com','google.com','gmail.com','hotmail.com','outlook.com','yahoo.com','apple.com','live.com','conga.com','getconga.com','congamerge.com','appextremes.com','salesforce.com','guest.salesforce.com','yourdomain.com','hotmail.co.uk')) 
                                              FROM Account 
                                              WHERE Id IN (SELECT Account__c FROM Partner_Profile__c WHERE Retired__c = FALSE AND Id != null) 
                                              AND RecordTypeId = '01250000000Dysv' 
                                              ORDER BY Id ASC];
        
        Map<Id, String> acctIdEmailMap = new Map<Id, String>();
        //Integer debugCounter = 0;
                                              
        for(Account a : [SELECT Id, 
                          (SELECT Id, Email_Domain__c FROM Contacts WHERE Email_Domain__c != null AND Email_Domain__c != '' AND Email_Domain__c NOT IN ('mail.com','google.com','gmail.com','hotmail.com','outlook.com','yahoo.com','apple.com','live.com','conga.com','getconga.com','congamerge.com','appextremes.com','salesforce.com','salesforce.com2','salesforc.com','salesorce.com','00d000000000062eaa.ext','guest.salesforce.com','yourdomain.com','hotmail.co.uk')) 
                          FROM Account 
                          WHERE Id IN (SELECT Account__c FROM Partner_Profile__c WHERE Retired__c = FALSE AND Id != null) 
                          AND RecordTypeId = '01250000000Dysv' AND Id != '0015000000Hljf0AAB' 
                          ORDER BY Id ASC]){
            String EDCompiledString = '';
            for(Contact c : a.Contacts){
                if(!EDCompiledString.contains(c.Email_Domain__c)){                
                    EDCompiledString += '\'' + c.Email_Domain__c + '\''+ ',';
                }  
            }
            
            if(EDCompiledString.length() > 255){
                EDCompiledString = EDCompiledString.substring(0,254);    
            }
            EDCompiledString = EDCompiledString.removeEnd(',');
            
            acctIdEmailMap.put(a.Id, EDCompiledString);
                //system.debug('*********************** acctIdEmailMap in loop at position ' + debugCounter + ': ' + acctIdEmailMap); 
            
            //debugCounter++;
        }
                                                
        /*List<String> acctIdEDStringList = new List<String>();
        Map<String, Id> acctIdEmailMap2 = new Map<String, Id>();
        Id currentAcctId = (Id) PPAccountContacts.get(0).get('AccountId');
        String AcctEDExpanded;
        
        for(Contact ppc : PPAccountContacts)
        {            
            acctIdEDStringList.add(ppc.AccountId + '|' + ppc.Email_Domain__c);
            acctIdEmailMap2.put(ppc.AccountId + '|' + ppc.Email_Domain__c, ppc.AccountId);
            
            if(currentAcctId == ppc.AccountId)
            {
                AcctEDExpanded += ppc.Email_Domain__c  + ',';            
            }
            AcctEDExpanded = ppc.AccountId + '|' AcctEDExpanded;
            
        }*/

        // String for the concatenated Email domains 
        String ActEDs = ''; 
        
        // Map of Account Id to the Email string of emails domains from contacts at the Account
        Map<Id, String> accountEmailDomainsMap = new Map<Id, String>();                                
        
        // Loop through each of the accounts and contacts, stringing together
        //  the email domains from contacts at each account
        
        /*
        for(Account a : PPAccounts)
        {
            for(Contact cAR : PPAccountContacts)
            {
                if(cAR.AccountId == a.Id)
                {
                    if(!ActEDs.contains(cAR.Email_Domain__c)){                
                        ActEDs += '\'' + cAR.Email_Domain__c + '\''+ ',';
                    }                    
                }
            }      
                        
            // Add to a map that is Account Id and the string of email domains, seperated by , and enclosed in ''
            accountEmailDomainsMap.put(a.Id, ActEDs.removeEnd(','));            
            // Clear out the string for the next account
            ActEDs = '';
        }     
        */       
            //System.debug('************************* accountEmailDomainsMap after for Account/Contact Loops: ' + accountEmailDomainsMap);                 
        
        // Total Composer Certifications by Account regardless of Level of the Cert
        for(AggregateResult ar : [SELECT Contact__r.AccountId, Count(Id) CertCount FROM Certification__c WHERE Certification_Expired__c != TRUE AND Certification__c LIKE 'Composer%' GROUP BY Contact__r.AccountID]){
            ComposerCertsMap.put((Id)ar.get('AccountId'),(Double)ar.get('CertCount'));    
        }
        
        // Total ActionGrid Certifications by Account regardless of Level of the Cert
        for(AggregateResult ar : [SELECT Contact__r.AccountId, Count(Id) CertCount FROM Certification__c WHERE Certification_Expired__c != TRUE AND Certification__c LIKE 'ActionGrid%' GROUP BY Contact__r.AccountID]){
            ActionGridCertsMap.put((Id)ar.get('AccountId'),(Double)ar.get('CertCount'));    
        }
        
        // Total Contracts Certifications by Account regardless of Level and Type (CC or Novatus) of the Cert
        for(AggregateResult ar : [SELECT Contact__r.AccountId, Count(Id) CertCount FROM Certification__c WHERE Certification_Expired__c != TRUE AND Certification__c LIKE 'Contracts%' GROUP BY Contact__r.AccountID]){
            ContractsCertsMap.put((Id)ar.get('AccountId'),(Double)ar.get('CertCount'));    
        }
                            
        // Gather Aggregate total of Certs by Account
        for(AggregateResult ar : [SELECT Contact__r.AccountId, Count(Id) CertCount FROM Certification__c WHERE Certification_Expired__c != TRUE GROUP BY Contact__r.AccountID]){
            CertificationsCountMap2.put((Id)ar.get('AccountId'),(Double)ar.get('CertCount'));
        }
        
        // Average Composer Seats Per Deal    
        AggregateResult[] avgCMSeats = [SELECT AVG(Composer_Licenses__c), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c != null AND Composer_Licenses__c != 0 AND (Type = 'New Business' OR Type = 'Existing Business') GROUP BY Referring_Partner_Primary__c];  
        for(AggregateResult acms: avgCMSeats){
            avgCMSeatsMap.put((Id) acms.get('Referring_Partner_Primary__c'), (Double) acms.get('expr0'));
        }
        
        // Getting first AND most recent Report Dates
        AggregateResult[] firstReportDate = [SELECT MIN(CloseDate), MAX(CloseDate), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c != null AND StageName = 'Closed Won' AND (Type = 'New Business' OR Type = 'Existing Business') GROUP BY Referring_Partner_Primary__c];
        for(AggregateResult frd: firstReportDate){
            firstReportMap.put((Id) frd.get('Referring_Partner_Primary__c'), (Date) frd.get('expr0'));
            mostRecentReportMap.put((Id) frd.get('Referring_Partner_Primary__c'), (Date) frd.get('expr1'));
        }
        
        //System.debug('************************* PPAcctMap: ' + PPAcctMap);        
        //System.debug('************************* acctIdEDStringList: ' + acctIdEDStringList);
        //System.debug('************************* acctIdEmailMap: ' + acctIdEmailMap);                        
        //System.debug('************************* CertificationsCountMap2: ' + CertificationsCountMap2);    
        //System.debug('************************* firstReportMap: ' + firstReportMap);
        //System.debug('************************* mostRecentReportMap: ' + mostRecentReportMap);
        //System.debug('************************* avgCMSeatsMap: ' + avgCMSeatsMap);                    

        for(Partner_Profile__c pp : partnerProfileRecords){                     
        // Conga Certifications Count (Rolling Up from Contacts at this PP's Account
            if(CertificationsCountMap.get(pp.Account__c) == null){                                        
                pp.Total_Certifications__c = 0;
            }
            else{
                //AccountId = (Id)PPAcctMap.get(pp.Account__c);
                pp.Total_Certifications__c = CertificationsCountMap.get(pp.Account__c);  
            }
            
        // Average Composer Seats per deal (AVG of Composer Licenses)
            if(avgCMSeatsMap.get(pp.Account__c) == null){                                        
                //Do nothing b/c null is better than a Zero in this case
            }
            else{
                //AccountId = (Id)PPAcctMap.get(pp.Account__c);
                pp.Average_Composer_Seats_Per_Deal__c = avgCMSeatsMap.get(pp.Account__c);  
            }             
            
        // First Report Date (MIN of Close Date for the Opp)
            if(firstReportMap.get(pp.Account__c) == null || pp.First_Report_Date__c != null ){                                        
                //Do nothing b/c it's already filled in or we didn't find anything in the Map
            }
            else{
                //AccountId = (Id)PPAcctMap.get(pp.Account__c);
                pp.First_Report_Date__c = firstReportMap.get(pp.Account__c);  
            }
            
        // Most Recent Report Date (MAX of Close Date for the Opp)
            if(mostRecentReportMap.get(pp.Account__c) == null || pp.Most_Recent_Report__c != null){                                        
                //Do nothing b/c it's already filled in or we didn't find anything in the Map
            }
            else{
                //AccountId = (Id)PPAcctMap.get(pp.Account__c);
                pp.Most_Recent_Report__c = mostRecentReportMap.get(pp.Account__c);  
            }                                                                         
        // Email Domains
            if(accountEmailDomainsMap.get(pp.Account__c) == null){                                        
                //Do nothing b/c we didn't find anything in the Map
            }
            else{
                pp.Partner_Email_Domain_s__c = accountEmailDomainsMap.get(pp.Account__c);  
            }          
            //partnerProfileRecordsToUpdate.add(pp);                    
        }

            //System.debug('************************* Final list size for update call ' + partnerProfileRecordsToUpdate.size());
            //System.debug('************************* Final list for update call ' + partnerProfileRecordsToUpdate);
            
        // Pass to a BatchApex Handler
        PPUpdaterBatchClass ppubc = new PPUpdaterBatchClass();
        ppubc.query = 'SELECT Id, Account__c, of_Conga_implementations_done__c, Implementations_done_This_Year__c, Implementations_done_Last_Year__c, Total_Revenue_All_Time__c, Total_Revenue_New_Upsell_All_Time__c, Revenue_This_Year__c, Revenue_Last_Year__c, Total_Certifications__c, Average_Composer_Seats_Per_Deal__c, First_Report_Date__c, Most_Recent_Report__c, Notes__c, Courier_Deals_This_Year__c, Composer_Deals_This_Year__c, ActionGrid_Deals_This_Year__c, Conga_Contracts_Deals_This_Year__c, Conductor_Workflow_Deals_This_Year__c, Conga_Novatus_Deals_This_Year__c, Partner_Email_Domain_s__c, Total_Composer_Certifications__c, Total_ActionGrid_Certifications__c, Total_Contracts_Certifications__c, Is_Certified_Partner__c FROM Partner_Profile__c WHERE Retired__c = False AND Account__c != null';                    
        ppubc.CCMap = CertificationsCountMap2;
        ppubc.CMCertsMap = ComposerCertsMap;
        ppubc.AGCertsMap = ActionGridCertsMap;
        ppubc.CCertsMap = ContractsCertsMap;
        ppubc.averageSeatsMap = avgCMSeatsMap;
        ppubc.FRMap = firstReportMap;                 
        ppubc.MRRMap = mostRecentReportMap;
        ppubc.EDMap = acctIdEmailMap;

        ID batchprocessid = Database.executeBatch(ppubc);                          
    }


}