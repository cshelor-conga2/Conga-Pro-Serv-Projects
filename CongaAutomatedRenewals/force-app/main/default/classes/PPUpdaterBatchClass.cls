/**
* @author Jereriah Manning
* @date 20170908
* @version 1.00
* @description PPUpdaterBatchClass - Created for Conga Partner Team
*/
global class PPUpdaterBatchClass implements Database.Batchable<sObject>{
    public String query;
    public List<Partner_Profile__c> pprecordstoupdate = new List<Partner_Profile__c>();    

    // Count Maps
    public Map<Id, Integer> countATMap = new Map<Id, Integer>();
    public Map<Id, Integer> countLYMap = new Map<Id, Integer>();
    public Map<Id, Integer> countTYMap = new Map<Id, Integer>();

    // Revenue Maps
    public Map<Id, Double> sumATMap = new Map<Id, Double>();
    public Map<Id, Double> sumNewUpsellATMap = new Map<Id, Double>();    
    public Map<Id, Double> sumTYMap = new Map<Id, Double>();
    public Map<Id, Double> sumLYMap = new Map<Id, Double>();
    
    // Case Maps
    public Map<Id, Double> internalCaseCount = new Map<Id, Double>();
    public Map<Id, Double> CPCaseCount = new Map<Id, Double>();
    public Map<Id, Double> internalCaseHours = new Map<Id, Double>();
    public Map<Id, Double> CPCaseHours = new Map<Id, Double>();
    
    // "Other" Maps    
    public Map<Id, Double> CCMap = new Map<Id, Double>();
    public Map<Id, Double> CMCertsMap = new Map<Id, Double>();
    public Map<Id, Double> AGCertsMap = new Map<Id, Double>();
    public Map<Id, Double> CCertsMap = new Map<Id, Double>();        
        
    public Map<Id, Double> averageSeatsMap = new Map<Id, Double>();
    public Map<Id, Date> FRMap = new Map<Id, Date>();
    public Map<Id, Date> MRRMap = new Map<Id, Date>();
    //public Map<Id, String> NFMap = new Map<Id, String>();
    public Map<Id, Double> CourierDealsMap = new Map<Id, Double>();
    public Map<Id, Double> ComposerDealsMap = new Map<Id, Double>();
    public Map<Id, Double> ActionGridDealsMap = new Map<Id, Double>();
    public Map<Id, Double> AutomationDealsMap = new Map<Id, Double>();
    public Map<Id, Double> CongaContractsDealsMap = new Map<Id, Double>();        
    public Map<Id, Double> NovatusDealsMap = new Map<Id, Double>();
    public Map<Id, Double> CongaSignDealsMap = new Map<Id, Double>(); 
    public Map<Id, String> EDMap = new Map<Id, String>();     
    

    /**
    * @description start - 
    */
    global Database.querylocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }

    /**
    * @description execute - 
    */
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        List<Partner_Profile__c> ppRecords = new List<Partner_Profile__c>();
        for(sObject o : scope){
            Partner_Profile__c pp = (Partner_Profile__c)o;
                        
            // Count Established Accounts - ALL TIME
            if(!countATMap.isEmpty()){
                if(countATMap.get(pp.Account__c) == null){
                    pp.of_Conga_implementations_done__c = 0;
                } 
                else {
                    pp.of_Conga_implementations_done__c = countATMap.get(pp.Account__c);   
                }
            }

            // Count Established Accounts - THIS YEAR            
            if(!countTYMap.isEmpty()){                
                if(countTYMap.get(pp.Account__c) == null){
                    pp.Implementations_done_This_Year__c = 0;
                } 
                else {
                    pp.Implementations_done_This_Year__c = countTYMap.get(pp.Account__c);   
                }
            } 

            // Count Established Accounts - LAST YEAR            
            if(!countLYMap.isEmpty()) {                
                if(countLYMap.get(pp.Account__c) == null){
                    pp.Implementations_done_Last_Year__c = 0;
                } 
                else {
                    pp.Implementations_done_Last_Year__c = countLYMap.get(pp.Account__c);   
                }
            }                        
            
            // Sum of revenue generated ALL TIME - NET NEW ONLY                      
            if(!sumATMap.isEmpty()){
                if(sumATMap.get(pp.Account__c) == null){
                    pp.Total_Revenue_All_Time__c = 0;
                } 
                else {
                    pp.Total_Revenue_All_Time__c = sumATMap.get(pp.Account__c);   
                }
            }

            // Sum of revenue generated ALL TIME - NET NEW AND UPSELL                     
            if(!sumNewUpsellATMap.isEmpty()){
                if(sumNewUpsellATMap.get(pp.Account__c) == null){
                    pp.Total_Revenue_New_Upsell_All_Time__c = 0;
                } 
                else {
                    pp.Total_Revenue_New_Upsell_All_Time__c = sumNewUpsellATMap.get(pp.Account__c);   
                }                  
            }

            // Sum of revenue generated THIS YEAR            
            if(!sumTYMap.isEmpty()){
                if(sumTYMap.get(pp.Account__c) == null){
                    pp.Revenue_This_Year__c = 0;
                } 
                else {
                    pp.Revenue_This_Year__c = sumTYMap.get(pp.Account__c);   
                }
            }            
            
            // Sum of revenue generated LAST YEAR
            if(!sumLYMap.isEmpty()){
                if(sumLYMap.get(pp.Account__c) == null){
                    pp.Revenue_Last_Year__c = 0;
                } 
                else {
                    pp.Revenue_Last_Year__c = sumLYMap.get(pp.Account__c);   
                }                 
            }   

            // Total Conga Certifications Count (Rolling Up from Contacts at this PP's Account)
            if(!CCMap.isEmpty()){
                if(CCMap.get(pp.Account__c) == null){                                        
                    pp.Total_Certifications__c = 0;
                    pp.Is_Certified_Partner__c = FALSE;
                }
                else{
                    pp.Total_Certifications__c = CCMap.get(pp.Account__c);
                    pp.Is_Certified_Partner__c = TRUE;  
                }
            }

            // Total Composer Certifications Count (Rolling Up from Contacts at this PP's Account)
            if(!CMCertsMap.isEmpty()){
                if(CMCertsMap.get(pp.Account__c) == null){                                        
                    pp.Total_Composer_Certifications__c = 0;
                }
                else{
                    pp.Total_Composer_Certifications__c = CMCertsMap.get(pp.Account__c);  
                }
            }

            // Total ActionGrid Certifications Count (Rolling Up from Contacts at this PP's Account)
            if(!AGCertsMap.isEmpty()){
                if(AGCertsMap.get(pp.Account__c) == null){                                        
                    pp.Total_ActionGrid_Certifications__c = 0;
                }
                else{
                    pp.Total_ActionGrid_Certifications__c = AGCertsMap.get(pp.Account__c);  
                }
            }

            // Total Contracts Certifications Count (Rolling Up from Contacts at this PP's Account)
            if(!CCertsMap.isEmpty()){
                if(CCertsMap.get(pp.Account__c) == null){                                        
                    pp.Total_Contracts_Certifications__c = 0;
                }
                else{
                    pp.Total_Contracts_Certifications__c = CCertsMap.get(pp.Account__c);  
                }
            }      

            // Average Composer Seats per deal (AVG of Composer Licenses)
            if(!averageSeatsMap.isEmpty()){
                if(averageSeatsMap.get(pp.Account__c) == null){                                        
                    //Do nothing b/c null is better than a Zero in this case
                }
                else{
                    pp.Average_Composer_Seats_Per_Deal__c = averageSeatsMap.get(pp.Account__c);  
                }             
            }

            if(!FRMap.isEmpty()){
                // First Report Date (MIN of Close Date for the Opp)
                if(FRMap.get(pp.Account__c) == null || pp.First_Report_Date__c != null ){                                        
                    //Do nothing b/c it's already filled in or we didn't find anything in the Map
                }
                else{
                    pp.First_Report_Date__c = FRMap.get(pp.Account__c);  
                }
            }

            // Most Recent Report Date (MAX of Close Date for the Opp)
            if(!MRRMap.isEmpty()){
                if(MRRMap.get(pp.Account__c) == null || pp.Most_Recent_Report__c != null){                                        
                    //Do nothing b/c it's already filled in or we didn't find anything in the Map
                }
                else{
                    //AccountId = (Id)PPAcctMap.get(pp.Account__c);
                    pp.Most_Recent_Report__c = MRRMap.get(pp.Account__c);  
                }             
            }

            // Composer Deals influenced THIS FISCAL YEAR
            if(!ComposerDealsMap.isEmpty()){
                if(ComposerDealsMap.get(pp.Account__c) == null){
                    pp.Composer_Deals_This_Year__c = 0;
                } 
                else {
                    pp.Composer_Deals_This_Year__c = ComposerDealsMap.get(pp.Account__c);   
                }                 
            }

            // ActionGrid Deals influenced THIS FISCAL YEAR
            if(!ActionGridDealsMap.isEmpty()){
                if(ActionGridDealsMap.get(pp.Account__c) == null){
                    pp.ActionGrid_Deals_This_Year__c = 0;
                } 
                else {
                    pp.ActionGrid_Deals_This_Year__c = ActionGridDealsMap.get(pp.Account__c);   
                }                 
            } 

            // Courier Deals influenced THIS FISCAL YEAR
            if(!CourierDealsMap.isEmpty()){
                if(CourierDealsMap.get(pp.Account__c) == null){
                    pp.Courier_Deals_This_Year__c = 0;
                } 
                else {
                    pp.Courier_Deals_This_Year__c = CourierDealsMap.get(pp.Account__c);   
                }                 
            }  

            // Conductor/Workflow "Automation" Deals influenced THIS FISCAL YEAR
            if(!AutomationDealsMap.isEmpty()){
                if(AutomationDealsMap.get(pp.Account__c) == null){
                    pp.Conductor_Workflow_Deals_This_Year__c = 0;
                } 
                else {
                    pp.Conductor_Workflow_Deals_This_Year__c = AutomationDealsMap.get(pp.Account__c);   
                }                 
            }   

            // Conga Contracts Deals influenced THIS FISCAL YEAR
            if(!CongaContractsDealsMap.isEmpty()){
                if(CongaContractsDealsMap.get(pp.Account__c) == null){
                    pp.Conga_Contracts_Deals_This_Year__c = 0;
                } 
                else {
                    pp.Conga_Contracts_Deals_This_Year__c = CongaContractsDealsMap.get(pp.Account__c);   
                }                 
            }  

            // Novatus Deals influenced THIS FISCAL YEAR
            if(!NovatusDealsMap.isEmpty()){
                if(NovatusDealsMap.get(pp.Account__c) == null){
                    pp.Conga_Novatus_Deals_This_Year__c = 0;
                } 
                else {
                    pp.Conga_Novatus_Deals_This_Year__c = NovatusDealsMap.get(pp.Account__c);   
                }                 
            }

            // Conga Sign influenced THIS FISCAL YEAR
            if(!CongaSignDealsMap.isEmpty()){
                if(CongaSignDealsMap.get(pp.Account__c) == null){
                    pp.Conga_Sign_Deals_This_Year__c = 0;
                } 
                else {
                    pp.Conga_Sign_Deals_This_Year__c = CongaSignDealsMap.get(pp.Account__c);   
                }
            }

            // Partner Contact Email Domains 
            if(!EDMap.isEmpty()){
                if(EDMap.get(pp.Account__c) == null){
                    // Do nothing here since the map doesn't have a value for this Partner Profile (Account)
                }
                else {
                    pp.Partner_Email_Domain_s__c = EDMap.get(pp.Account__c);   
                }
            }

            // Internal Cases - LAST 365
            if(!internalCaseCount.isEmpty()){
                if(internalCaseCount.get(pp.Account__c) == null){
                    // Do nothing here since the map doesn't have a value for this Partner Profile (Account)
                } 
                else {
                    pp.Internal_Cases_Opened_Last_365__c = internalCaseCount.get(pp.Account__c);   
                }
            }

            // Customer/Prospect Cases - LAST 365
            if(!CPCaseCount.isEmpty()){
                if(CPCaseCount.get(pp.Account__c) == null){
                    // Do nothing here since the map doesn't have a value for this Partner Profile (Account)
                } 
                else {
                    pp.Customer_Prospect_Cases_Opened_Last_365__c = CPCaseCount.get(pp.Account__c);   
                }                 
            }

            // Internal Case Hours - LAST 365
            if(!internalCaseHours.isEmpty()){
                if(internalCaseHours.get(pp.Account__c) == null){
                    // Do nothing here since the map doesn't have a value for this Partner Profile (Account)
                } 
                else {
                    pp.Internal_Cases_Hours_Last_365__c = internalCaseHours.get(pp.Account__c);   
                }                 
            }

            // Customer/Prospect Hours - LAST 365
            if(!CPCaseHours.isEmpty()){
                if(CPCaseHours.get(pp.Account__c) == null){
                    // Do nothing here since the map doesn't have a value for this Partner Profile (Account)
                } 
                else {
                    pp.Customer_Prospect_Case_Hours_Last_365__c = CPCaseHours.get(pp.Account__c);   
                }                 
            }                                                                                                                        
            // Notes field Map for Deal Type breakdown
                // Deprecated and replaced with individual fields
            /*if(!NFMap.isEmpty())
            {
                if(NFMap.get(pp.Id) != null)
                {
                    pp.Notes__c = NFMap.get(pp.Id);                             
                }
            }*/           
          
            // Add to the list to update in the Batch Processor
            ppRecords.add(pp);
        }

        // Do the actual record updates in however many batches the Batch Processor deems necessary
        Database.update(ppRecords);
    }
    
    /**
    * @description finish - 
    */
    global void finish(Database.BatchableContext bc){
        // System debug at the end
        // Add email, but check to make sure it's in Prod since we can't email from SB
        //system.debug('************** In the Finish method in batch class!!!');
    }


}