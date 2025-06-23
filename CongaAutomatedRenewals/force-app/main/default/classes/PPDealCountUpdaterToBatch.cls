/**
* @author Jereriah Manning
* @date 20140720
* @version 2.00
* @description PPDealCountUpdaterToBatch - Created for Conga Partner Team
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
*        This is going to the be the "Count" Version moving forward
*
*    Updated by J Manning
*    31 AUG 2017
*    Version 3.0
*        Doing the Count Query work here and then handing the Maps over to a Batch job to avoid data, heap and time out limits 
*
*    Updated by J Manning
*    23 JAN 2018
*    Version 3.1
*        Updating to Fiscal Years
***************************************/
public class PPDealCountUpdaterToBatch{           
    
    /**
    * @description PPDealCountUpdaterToBatch - Constructor
    */
    public PPDealCountUpdaterToBatch(){
    }

    /**
    * @description doCount - 
    * @return void
    */
    //@future
    public static void doCount(){
        List<Partner_Profile__c> partnerProfileRecords = new List<Partner_Profile__c>();
        //List<Partner_Profile__c> partnerProfileRecordsToUpdate = new List<Partner_Profile__c>();
        Map<Id, Integer> countAllTimeMap = new Map<Id, Integer>();
        Map<Id, Integer> countLastYearMap = new Map<Id, Integer>();
        Map<Id, Integer> countThisYearMap = new Map<Id, Integer>();
        Map<Id,Id> PPAcctMap = new Map<Id,Id>();
        List<Partner_Profile__c> PPsToUpdate = new List<Partner_Profile__c>(); 
        
        // Get the Partner Profile records to update with found data
        partnerProfileRecords = [select Id, Account__c, Retired__c, Total_Certifications__c, First_Report_Date__c,  Average_Composer_Seats_Per_Deal__c FROM Partner_Profile__c WHERE Id !=null AND Retired__c = FALSE];
            //System.debug('************************* partnerProfileRecords after SOQL Loop ' + partnerProfileRecords); 
        
        for(Partner_Profile__c pp : [SELECT Id, Account__c FROM Partner_Profile__c WHERE Retired__c = False AND Account__c != null]){
            PPAcctMap.put((Id)pp.get('Id'), (Id)pp.get('Account__c'));
        }
        
        //Get Count - ALL TIME
        AggregateResult[] countAlltime = [SELECT COUNT(Id), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c != null AND (Type = 'New Business' OR Type = 'Existing Business') GROUP BY Referring_Partner_Primary__c];        
        for(AggregateResult atc: countAlltime){
            countAllTimeMap.put((Id) atc.get('Referring_Partner_Primary__c'), (Integer) atc.get('expr0'));
        }
            //System.debug('************************* countAlltime ' + countAlltime);         
            //System.debug('************************* countAllTimeMap ' + countAllTimeMap);
            
        // Get Count - LAST YEAR
        AggregateResult[] countLastYear = [SELECT COUNT(Id), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c!= null AND (Type = 'New Business' OR Type = 'Existing Business') AND CloseDate = LAST_FISCAL_YEAR GROUP BY Referring_Partner_Primary__c];
        for(AggregateResult atc: countLastYear){
            countLastYearMap.put((Id) atc.get('Referring_Partner_Primary__c'), (Integer) atc.get('expr0'));
        }
            //System.debug('************************* countLastYearMap' + countLastYearMap); 
            
        // Get Count - THIS YEAR
        AggregateResult[] countThisYear = [SELECT COUNT(Id), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c!= null AND (Type = 'New Business' OR Type = 'Existing Business') AND CloseDate = THIS_FISCAL_YEAR GROUP BY Referring_Partner_Primary__c];
        for(AggregateResult atc: countThisYear){
            countThisYearMap.put((Id) atc.get('Referring_Partner_Primary__c'), (Integer) atc.get('expr0'));
        }
            //System.debug('************************* countThisYearMap' + countThisYearMap);
            
        // Update the Partner Profile Records
        for(Partner_Profile__c pp : partnerProfileRecords){        
            // Count Established Accounts - ALL TIME
            if(countAllTimeMap.get(pp.Account__c) == null){
                pp.of_Conga_implementations_done__c = 0;
            } 
            else {
                pp.of_Conga_implementations_done__c = countAllTimeMap.get(pp.Account__c);   
            }
            
            // Count Established Accounts - THIS YEAR
            if(countThisYearMap.get(pp.Account__c) == null){
                pp.Implementations_done_This_Year__c = 0;
            } 
            else {
                pp.Implementations_done_This_Year__c = countThisYearMap.get(pp.Account__c);   
            }
            
            // Count Established Accounts - LAST YEAR
            if(countLastYearMap.get(pp.Account__c) == null){
                pp.Implementations_done_Last_Year__c = 0;
            } 
            else {
                pp.Implementations_done_Last_Year__c = countLastYearMap.get(pp.Account__c);   
            }                                                                    
                //partnerProfileRecordsToUpdate.add(pp);           
        }
                //System.debug('************************* Final list size for update call ' + partnerProfileRecordsToUpdate.size());
                //System.debug('************************* Final list for update call ' + partnerProfileRecordsToUpdate);
            
        // Pass to a BatchApex Handler
        PPUpdaterBatchClass ppubc = new PPUpdaterBatchClass();
        ppubc.query = 'SELECT Id, Account__c, of_Conga_implementations_done__c, Implementations_done_This_Year__c, Implementations_done_Last_Year__c, Total_Revenue_All_Time__c, Total_Revenue_New_Upsell_All_Time__c, Revenue_This_Year__c, Revenue_Last_Year__c, Total_Certifications__c, Average_Composer_Seats_Per_Deal__c, First_Report_Date__c, Most_Recent_Report__c, Notes__c, Courier_Deals_This_Year__c, Composer_Deals_This_Year__c, ActionGrid_Deals_This_Year__c, Conga_Contracts_Deals_This_Year__c, Conductor_Workflow_Deals_This_Year__c, Conga_Novatus_Deals_This_Year__c FROM Partner_Profile__c WHERE Retired__c = False AND Account__c != null';                    
        ppubc.countATMap = countAllTimeMap;
        ppubc.countLYMap = countLastYearMap;
        ppubc.countTYMap = countThisYearMap;                 

        ID batchprocessid = Database.executeBatch(ppubc);
    }


}