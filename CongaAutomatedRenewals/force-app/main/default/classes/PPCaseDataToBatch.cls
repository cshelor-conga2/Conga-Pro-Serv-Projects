/**
* @author J. Manning
* @date 20180116
* @version 1.00
* @description PPCaseDataToBatch - Gathering Case Metrics for Partner Analytics and Reporting
*/
public class PPCaseDataToBatch{

    /**
    * @description PPCaseDataToBatch - Default Constructor, Does nothing
    */
    public PPCaseDataToBatch(){   
    }

    /**
    * @description doCount - 
    * @return void
    */
    public static void doCount(){
        List<Partner_Profile__c> partnerProfileRecords = new List<Partner_Profile__c>();
        List<Partner_Profile__c> partnerProfileRecordsToUpdate = new List<Partner_Profile__c>();
        List<Id> PPAccounts = new List<Id>();
        Map<Id,Double> PartnerInternalCaseCountLast365Map = new Map<Id,Double>();    
        Map<Id,Double> PartnerEndUserCaseCountLastYearMap = new Map<Id,Double>();    
        Map<Id,Double> PartnerInternalCaseHoursLast365Map = new Map<Id,Double>();    
        Map<Id,Double> PartnerEndUserCaseHoursLast365Map = new Map<Id,Double>();
        Map<Id, String> PPAcctEmailDomainMap = new Map<Id, String>();  
        Map<Id,Id> PPAcctMap = new Map<Id,Id>();       
        
        // Get the Partner Profile Records
        partnerProfileRecords = [SELECT Id, Account__c, Account__r.Id, Notes__c, Partner_Email_Domain_s__c   
                                 FROM Partner_Profile__c 
                                 WHERE Id !=null AND Retired__c = FALSE];            
            //System.debug('************************* partnerProfileRecords after SOQL Loop: ' + partnerProfileRecords);     

        // Create a Map of Account Id and it's email domains
        for(Partner_Profile__c pp : partnerProfileRecords){
            PPAccounts.add(pp.Account__r.Id);
            PPAcctEmailDomainMap.put(pp.Account__r.Id, pp.Partner_Email_Domain_s__c);
            PPAcctMap.put(pp.Account__r.Id, pp.Id); 
        }

        // Case details for any Case opened by a Contact at an Account that is a partner of a non-retired Partner Profile record
        for(Case c : [SELECT Id, AccountId, ContactId, Contact.AccountId, Time_Spent_Hours__c FROM Case 
                        //WHERE ContactId IN (SELECT Id FROM Contact WHERE AccountId = :PPAccounts)
                      WHERE (AccountId = :PPAccounts OR Contact.AccountId = :PPAccounts)   
                      AND (CreatedDate = LAST_N_DAYS:365 OR CreatedDate = TODAY)]){  

            // This is a case logged by a Partner Contact related to it's own Account
            // The Case Account matches the Contact's Account
            if(c.AccountId == c.Contact.AccountId && (c.AccountId != null && c.ContactId != null )){
                
                // Checking to see if the PartnerInternalCaseCountLast365Map map already has a pairing for this AccountId
                if(PartnerInternalCaseCountLast365Map.containsKey(c.AccountId)){
                    // Add one to the value found in the map by Getting the value and adding a 1
                    PartnerInternalCaseCountLast365Map.put(c.AccountId, PartnerInternalCaseCountLast365Map.get(c.AccountId)+ 1);    
                }
                // Checking to see if the PartnerInternalCaseCountLast365Map map doesn't has a pairing for this AccountId where the Case Account matches the Contact's Account
                else if(!PartnerInternalCaseCountLast365Map.containsKey(c.AccountId)){
                    // First time this Account was found so set the Value to 1
                    PartnerInternalCaseCountLast365Map.put(c.AccountId, 1);  
                }
                
                // Doing the work for Case Hours (Time_Spent_Hours__c)                
                if(!PartnerInternalCaseHoursLast365Map.containsKey(c.AccountId)){
                    if(c.Time_Spent_Hours__c != 0 && c.Time_Spent_Hours__c != null){
                        // First time this Account was found so set the Value to the Time_Spent_Hours
                        PartnerInternalCaseHoursLast365Map.put(c.AccountId, c.Time_Spent_Hours__c);                      
                    }
                    // Create an entry in the Map with a 0 placeholder so we end up with a value on the PP later
                    else{
                        PartnerInternalCaseHoursLast365Map.put(c.AccountId, 0);    
                    }
                }
                else if(PartnerInternalCaseHoursLast365Map.containsKey(c.AccountId)){
                    // Only try to do this if there's a value in the Time_Spent_Hours__c field
                    if(c.Time_Spent_Hours__c != 0 && c.Time_Spent_Hours__c != null){
                        // Add to the value found in the map by Getting the value and adding this Case's Time_Spent_Hours field value to existing value
                        PartnerInternalCaseHoursLast365Map.put(c.AccountId, (PartnerInternalCaseHoursLast365Map.get(c.AccountId) + c.Time_Spent_Hours__c));      
                    }                                  
                }                
            }
            
            // This is a case logged by a Partner Contact related to an Account other than it's own Partner Account
            // The Case Account doesn't match the Contact's Account
            // v2 Shifting everythign to the contact Id -- assumes the Contacts are under the correct Acct in SFDC
            if(c.AccountId != c.Contact.AccountId && (c.AccountId != null && c.ContactId != null)){
                // Checking to see if the PartnerEndUserCaseCountLastYearMap map doesn't has a pairing for this AccountId where the Case Account doesn't match the Contact's Account
                if(!PartnerEndUserCaseCountLastYearMap.containsKey(c.Contact.AccountId)){
                    // First time this Account was found so set the Value to 1
                    PartnerEndUserCaseCountLastYearMap.put(c.Contact.AccountId, 1);  
                }                  
                // Checking to see if the PartnerEndUserCaseCountLastYearMap map already has a pairing for this AccountId
                    // (else if) to avoid over stating by 1 on the first loop through as both IFs would be TRUE
                else if(PartnerEndUserCaseCountLastYearMap.containsKey(c.Contact.AccountId)){
                    
                    //system.debug('*********************** c.AccountId in loop: ' + c.AccountId);
                    //system.debug('*********************** c.Contact.AccountId in loop: ' + c.Contact.AccountId);
                    // Add one to the value found in the map by Getting the value and adding a 1
                    /*
                    if(c.AccountId != null)
                    {                
                        system.debug('*********************** PartnerEndUserCaseCountLastYearMap.get(c.AccountId) in loop: ' + PartnerEndUserCaseCountLastYearMap.get(c.AccountId));
                        if(PartnerEndUserCaseCountLastYearMap.get(c.AccountId) != null)
                        {
                            PartnerEndUserCaseCountLastYearMap.put(c.AccountId, PartnerEndUserCaseCountLastYearMap.get(c.AccountId)+ 1);    
                        }
                        // If the value of the map for this account is null, set it to one here
                        else if(PartnerEndUserCaseCountLastYearMap.get(c.AccountId) == null)
                        {
                            PartnerEndUserCaseCountLastYearMap.put(c.AccountId, 1);
                        }                        
                    }
                    */
                    if(c.Contact.AccountId != null){
                        PartnerEndUserCaseCountLastYearMap.put(c.Contact.AccountId, PartnerEndUserCaseCountLastYearMap.get(c.Contact.AccountId)+ 1);    
                    }
                }
              
                // Populate Customer / Prospect Case hours map for the last 365 days
                    // Should be the first time through and there's no entry for this Contact's Account Id yet
                if(!PartnerEndUserCaseHoursLast365Map.containsKey(c.Contact.AccountId)){
                    if(c.Time_Spent_Hours__c != 0 && c.Time_Spent_Hours__c != null){
                        // First time this Account was found so set the Value to the Time_Spent_Hours
                        PartnerEndUserCaseHoursLast365Map.put(c.Contact.AccountId, c.Time_Spent_Hours__c);                      
                    }
                    // Create an entry in the Map with a 0 placeholder so we end up with a value on the PP later, even if it's 0
                    else{
                        PartnerEndUserCaseHoursLast365Map.put(c.Contact.AccountId, 0);    
                    }
                }                
                // If we have an entry for this Contact's Account
                    // Probably should have one b/c of the 0 placeholder we might set
                else if(PartnerEndUserCaseHoursLast365Map.containsKey(c.Contact.AccountId)){
                    // Only try to do this is there's a value in the Time_Spent_Hours__c field and it's not a direct tie to that Contact's Acct
                    if(c.Time_Spent_Hours__c != 0 && c.Time_Spent_Hours__c != null && c.AccountId != c.Contact.AccountId){
                        // Add to the value found in the map by Getting the value and adding this Case's Time_Spent_Hours field value to existing value
                        PartnerEndUserCaseHoursLast365Map.put(c.Contact.AccountId, (PartnerEndUserCaseHoursLast365Map.get(c.Contact.AccountId) + c.Time_Spent_Hours__c));      
                    }                               
                }
            } 
                       
        }                  
            //System.debug('************************* PartnerInternalCaseCountLast365Map after SOQL Loop: ' + PartnerInternalCaseCountLast365Map);            
            //System.debug('************************* PartnerEndUserCaseCountLastYearMap after SOQL Loop: ' + PartnerEndUserCaseCountLastYearMap);  
            //System.debug('************************* PartnerInternalCaseHoursLast365Map after SOQL Loop: ' + PartnerInternalCaseHoursLast365Map);            
            //System.debug('************************* PartnerEndUserCaseHoursLast365Map after SOQL Loop: ' + PartnerEndUserCaseHoursLast365Map);                                                                                                                                                                                                           

        // Set up a list of PP Records to update with the new Aggregate Case data
        for(Partner_Profile__c ppToUpdate : partnerProfileRecords){
            ppToUpdate.Internal_Cases_Opened_Last_365__c = PartnerInternalCaseCountLast365Map.get(ppToUpdate.Account__c);
            ppToUpdate.Customer_Prospect_Cases_Opened_Last_365__c = PartnerEndUserCaseCountLastYearMap.get(ppToUpdate.Account__c);
            ppToUpdate.Internal_Cases_Hours_Last_365__c = PartnerInternalCaseHoursLast365Map.get(ppToUpdate.Account__c);
            ppToUpdate.Customer_Prospect_Case_Hours_Last_365__c = PartnerEndUserCaseHoursLast365Map.get(ppToUpdate.Account__c);
            partnerProfileRecordsToUpdate.add(ppToUpdate);
        }
            //System.debug('************************* partnerProfileRecordsToUpdate before insert: ' + partnerProfileRecordsToUpdate);                                                                                                                                                                                                           
        
        //Database.update(partnerProfileRecordsToUpdate);
        
        // Pass to a BatchApex Handler
        PPUpdaterBatchClass ppubc = new PPUpdaterBatchClass();
        ppubc.query = 'SELECT Id, Account__c, of_Conga_implementations_done__c, Implementations_done_This_Year__c, Implementations_done_Last_Year__c, Total_Revenue_All_Time__c, Total_Revenue_New_Upsell_All_Time__c, Revenue_This_Year__c, Revenue_Last_Year__c, Total_Certifications__c, Average_Composer_Seats_Per_Deal__c, First_Report_Date__c, Most_Recent_Report__c, Notes__c, Internal_Cases_Opened_Last_365__c, Customer_Prospect_Cases_Opened_Last_365__c, Internal_Cases_Hours_Last_365__c, Customer_Prospect_Case_Hours_Last_365__c FROM Partner_Profile__c WHERE Retired__c = False AND Account__c != null';                    
        ppubc.internalCaseCount = PartnerInternalCaseCountLast365Map;
        ppubc.CPCaseCount = PartnerEndUserCaseCountLastYearMap;
        ppubc.internalCaseHours = PartnerInternalCaseHoursLast365Map;
        ppubc.CPCaseHours = PartnerEndUserCaseHoursLast365Map;
    
        // Actually sets up the Batch job to do the updating
        ID batchprocessid = Database.executeBatch(ppubc);
    }


}