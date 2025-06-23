/**
* @author Jereriah Manning
* @date 20140720
* @version 2.00
* @description PPRevenueUpdaterToBatch - Created for Conga Partner Team
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
*        This is going to the be the "Revenue" Version moving forward
*
*    Updated by J Manning
*    31 AUG 2017
*    Version 3.0
*        Doing the Revenue Query work here and then handing the Maps over to a Batch job to avoid data, heap and time out limits
*
*    Updated by J Manning
*    03 JAN 2018
*    Version 3.1
*        Updated to Fiscal Year calculations        
***************************************/

public class PPRevenueUpdaterToBatch{    
    
    /**
    * @description PPRevenueUpdaterToBatch - Constructor
    */
    public PPRevenueUpdaterToBatch(){
      // Unused now
    }    
    
    /**
    * @description doCount - 
    * @return void
    */
    public static void doCount()
    {        
        List<Partner_Profile__c> partnerProfileRecords = new List<Partner_Profile__c>();
        Map<Id, Double> sumAllTimeMap = new Map<Id, Double>();
        Map<Id, Double> sumNewandUpsellAllTimeMap = new Map<Id, Double>();    
        Map<Id, Double> sumThisYearMap = new Map<Id, Double>();
        Map<Id, Double> sumLastYearMap = new Map<Id, Double>();
        Map<Id,Id> PPAcctMap = new Map<Id,Id>();
        List<Partner_Profile__c> PPsToUpdate = new List<Partner_Profile__c>();     
        
        partnerProfileRecords = [select Id, Account__c, Retired__c, Total_Certifications__c, First_Report_Date__c,  Average_Composer_Seats_Per_Deal__c FROM Partner_Profile__c WHERE Id !=null AND Retired__c = FALSE];
            System.debug('************************* partnerProfileRecords after SOQL Loop: ' + partnerProfileRecords);

        for(Partner_Profile__c pp : [SELECT Id, Account__c FROM Partner_Profile__c WHERE Retired__c = False AND Account__c != null])
        {
            PPAcctMap.put((Id)pp.get('Id'), (Id)pp.get('Account__c'));
        }
        
        AggregateResult[] sumAlltime = [SELECT SUM(Amount), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c != null AND StageName = 'Closed Won' AND Type = 'New Business' GROUP BY Referring_Partner_Primary__c];                
            System.debug('************************* sumAlltime: ' + sumAlltime);        
                    
        for(AggregateResult stc: sumAlltime)
        {
            sumAllTimeMap.put((Id) stc.get('Referring_Partner_Primary__c'), (Double) stc.get('expr0'));
        }
            System.debug('************************* sumAllTimeMap ' + sumAllTimeMap); 
            
        AggregateResult[] sumNewandUpsellAlltime = [SELECT SUM(Amount), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c != null AND StageName = 'Closed Won' AND (Type = 'New Business' OR Type = 'Existing Business') GROUP BY Referring_Partner_Primary__c];        
            System.debug('************************* sumNewandUpsellAlltime: ' + sumNewandUpsellAlltime);          

        for(AggregateResult stc: sumNewandUpsellAlltime){
            sumNewandUpsellAllTimeMap.put((Id) stc.get('Referring_Partner_Primary__c'), (Double) stc.get('expr0'));
        }
            System.debug('************************* sumNewandUpsellAllTimeMap: ' + sumAllTimeMap);
            
        AggregateResult[] sumLastYear = [SELECT SUM(Amount), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c != null AND StageName = 'Closed Won' AND (Type = 'New Business' OR Type = 'Existing Business') AND CloseDate = LAST_FISCAL_YEAR GROUP BY Referring_Partner_Primary__c];        
            System.debug('************************* sumLastYear: ' + sumLastYear);
        
        for(AggregateResult stc: sumLastYear ){
            sumLastYearMap.put((Id) stc.get('Referring_Partner_Primary__c'), (Double) stc.get('expr0'));
        }
            System.debug('************************* sumLastYearMap: ' + sumLastYearMap);                                       
        
        AggregateResult[] sumThisYear = [SELECT SUM(Amount), Referring_Partner_Primary__c FROM Opportunity WHERE Referring_Partner_Primary__c != null AND StageName = 'Closed Won' AND (Type = 'New Business' OR Type = 'Existing Business') AND CloseDate = THIS_FISCAL_YEAR GROUP BY Referring_Partner_Primary__c];        
            System.debug('************************* sumThisYear: ' + sumThisYear);
            
        for(AggregateResult stc: sumThisYear ){
            sumThisYearMap.put((Id) stc.get('Referring_Partner_Primary__c'), (Double) stc.get('expr0'));
        }            
            System.debug('************************* sumThisYearMap: ' + sumThisYearMap);
            
        for(Partner_Profile__c pp : partnerProfileRecords)
        {                                               
        // Sum of revenue generated ALL TIME - NET NEW ONLY                      
            if(sumAllTimeMap.get(pp.Account__c) == null){
                pp.Total_Revenue_All_Time__c = 0;
            } 
            else 
            {
                pp.Total_Revenue_All_Time__c = sumAllTimeMap.get(pp.Account__c);   
            }            
            
        // Sum of revenue generated ALL TIME - NET NEW AND UPSELL                     
            if(sumNewandUpsellAllTimeMap.get(pp.Account__c) == null){
                pp.Total_Revenue_New_Upsell_All_Time__c = 0;
            } 
            else 
            {
                pp.Total_Revenue_New_Upsell_All_Time__c = sumNewandUpsellAllTimeMap.get(pp.Account__c);   
            }                  

        // Sum of revenue generated This Year            
            if(sumThisYearMap.get(pp.Account__c) == null){
                pp.Revenue_This_Year__c = 0;
            } 
            else 
            {
                pp.Revenue_This_Year__c = sumThisYearMap.get(pp.Account__c);   
            }
            
        // Sum of revenue generated Last Year
            if(sumLastYearMap.get(pp.Account__c) == null){
                pp.Revenue_Last_Year__c = 0;
            } 
            else 
            {
                pp.Revenue_Last_Year__c = sumLastYearMap.get(pp.Account__c);   
            }          
                                                 
            
            //partnerProfileRecordsToUpdate.add(pp);           
        }
            //System.debug('************************* Final list size for update call ' + partnerProfileRecordsToUpdate.size());
            //System.debug('************************* Final list for update call ' + partnerProfileRecordsToUpdate);
        
        //Database.update(partnerProfileRecordsToUpdate);
        
        // Pass to a BatchApex Handler
                PPUpdaterBatchClass ppubc = new PPUpdaterBatchClass();
                    ppubc.query = 'SELECT Id, Account__c, of_Conga_implementations_done__c, Implementations_done_This_Year__c, Implementations_done_Last_Year__c, Total_Revenue_All_Time__c, Total_Revenue_New_Upsell_All_Time__c, Revenue_This_Year__c, Revenue_Last_Year__c, Total_Certifications__c, Average_Composer_Seats_Per_Deal__c, First_Report_Date__c, Most_Recent_Report__c, Notes__c, Courier_Deals_This_Year__c, Composer_Deals_This_Year__c, ActionGrid_Deals_This_Year__c, Conga_Contracts_Deals_This_Year__c, Conductor_Workflow_Deals_This_Year__c, Conga_Novatus_Deals_This_Year__c FROM Partner_Profile__c WHERE Retired__c = False AND Account__c != null';                    
                    ppubc.sumATMap = sumAllTimeMap;
                    ppubc.sumNewUpsellATMap = sumNewandUpsellAllTimeMap;
                    ppubc.sumTYMap = sumThisYearMap;                 
                    ppubc.sumLYMap = sumLastYearMap;
                
                ID batchprocessid = Database.executeBatch(ppubc);                
    }
    
}