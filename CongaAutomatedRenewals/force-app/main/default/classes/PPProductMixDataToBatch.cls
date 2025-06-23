/**
* @author Jereriah Manning
* @date 20171023
* @version 1.00
* @description PPProductMixDataToBatch - Gathering Opp Data for partners based upon product mix and THIS FISCAL YEAR
*    Version 2.0 
*        Updated 1/4/2018 (JM)
*        Incorporating Product Mix data
*/
public class PPProductMixDataToBatch{

    /**
    * @description PPProductMixDataToBatch - Constructor
    */
    public PPProductMixDataToBatch(){   
    }

    /**
    * @description doCount - 
    * @return void
    */
    public static void doCount(){
        List<Partner_Profile__c> partnerProfileRecords = new List<Partner_Profile__c>();
        List<Partner_Profile__c> partnerProfileRecordsToUpdate = new List<Partner_Profile__c>();
        Map<Id,Double> CMDealsMap = new Map<Id, Double>();
        Map<Id,Double> AGDealsMap = new Map<Id, Double>();
        Map<Id,Double> CCDealsMap = new Map<Id, Double>();     
        Map<Id,Double> CourierDealsMap = new Map<Id, Double>();     
        Map<Id,Double> CNCWDealsMap = new Map<Id, Double>();    
        Map<Id,Double> NovatusDealsMap = new Map<Id, Double>(); 
        Map<Id,Double> CSDealsMap =  new Map<Id,Double>();
        Map<Id,String> NoteFieldMap = new Map<Id,String>();     
        Map<Id,Id> PPAcctMap = new Map<Id,Id>();       
        String newNotesValue = '';
        
        // Get the Partner Profile Records
        partnerProfileRecords = [SELECT Id, Account__c, Notes__c FROM Partner_Profile__c WHERE Id != null AND Retired__c = FALSE];    

            //System.debug('************************* partnerProfileRecords after SOQL Loop ' + partnerProfileRecords);     

        // Conga Composer (Standard or Portal/Platform/Community or CM Service Events)
        for(AggregateResult ar : [SELECT Count(OpportunityId) CMDealCount, Opportunity.Referring_Partner_Primary__c RefPartner
                                    FROM OpportunityLineItem 
                                    WHERE Opportunity.StageName = 'Closed Won' 
                                        AND Opportunity.Referring_Partner_Primary__c != null 
                                        AND Opportunity.CloseDate = This_Fiscal_Year 
                                        AND Product2.Family IN ('Conga Composer Licenses', 'Conga Composer - Portal-Platfo', 'Conga Composer Service Events') 
                                    GROUP BY Opportunity.Referring_Partner_Primary__c 
                                    ORDER BY Opportunity.Referring_Partner_Primary__c])
                                    {
            CMDealsMap.put((Id)ar.get('RefPartner'), (Double)ar.get('CMDealCount'));        
        }
            //System.debug('************************* CMDealsMap after SOQL Loop ' + CMDealsMap);                                     
    
        //Conga ActionGrid         
        for(AggregateResult ar : [SELECT Count(OpportunityId) AGDealCount, Opportunity.Referring_Partner_Primary__c RefPartner
                                    FROM OpportunityLineItem 
                                    WHERE Opportunity.StageName = 'Closed Won' 
                                        AND Opportunity.Referring_Partner_Primary__c != null 
                                        AND Opportunity.CloseDate = This_Fiscal_Year 
                                        AND Product2.Family = 'ActionGrid' 
                                    GROUP BY Opportunity.Referring_Partner_Primary__c 
                                    ORDER BY Opportunity.Referring_Partner_Primary__c])
                                    {
            AGDealsMap.put((Id)ar.get('RefPartner'), (Double)ar.get('AGDealCount'));        
        }
            //System.debug('************************* AGDealsMap after SOQL Loop ' + AGDealsMap);                                                                            
    
        //Conga Contracts        
        for(AggregateResult ar : [SELECT Count(OpportunityId) ContractsDealCount, Opportunity.Referring_Partner_Primary__c RefPartner
                                    FROM OpportunityLineItem 
                                    WHERE Opportunity.StageName = 'Closed Won' 
                                        AND Opportunity.Referring_Partner_Primary__c != null 
                                        AND Opportunity.CloseDate = This_Fiscal_Year 
                                        AND Product2.Family = 'Conga Contracts' 
                                    GROUP BY Opportunity.Referring_Partner_Primary__c 
                                    ORDER BY Opportunity.Referring_Partner_Primary__c])
                                    {
            CCDealsMap.put((Id)ar.get('RefPartner'), (Double)ar.get('ContractsDealCount'));        
        }
            //System.debug('************************* CCDealsMap after SOQL Loop ' + CCDealsMap);                                                                         
    
        //Conga Courier        
        for(AggregateResult ar : [SELECT Count(OpportunityId) CourierDealCount, Opportunity.Referring_Partner_Primary__c RefPartner
                                    FROM OpportunityLineItem 
                                    WHERE Opportunity.StageName = 'Closed Won' 
                                        AND Opportunity.Referring_Partner_Primary__c != null 
                                        AND Opportunity.CloseDate = This_Fiscal_Year 
                                        AND Product2.Family = 'Conga Courier' 
                                    GROUP BY Opportunity.Referring_Partner_Primary__c 
                                    ORDER BY Opportunity.Referring_Partner_Primary__c])
                                    {
            CourierDealsMap.put((Id)ar.get('RefPartner'), (Double)ar.get('CourierDealCount'));        
        }
            //System.debug('************************* CourierDealsMap after SOQL Loop ' + CourierDealsMap);                                                                                                             

        //Conga Conductor/Workflow        
        for(AggregateResult ar : [SELECT Count(OpportunityId) CNCWDealCount, Opportunity.Referring_Partner_Primary__c RefPartner
                                    FROM OpportunityLineItem 
                                    WHERE Opportunity.StageName = 'Closed Won' 
                                        AND Opportunity.Referring_Partner_Primary__c != null 
                                        AND Opportunity.CloseDate = This_Fiscal_Year 
                                        AND Product2.Family = 'Conga Conductor-Workflow' 
                                    GROUP BY Opportunity.Referring_Partner_Primary__c 
                                    ORDER BY Opportunity.Referring_Partner_Primary__c])
                                    {
            CNCWDealsMap.put((Id)ar.get('RefPartner'), (Double)ar.get('CNCWDealCount'));        
        }
            //System.debug('************************* CNCWDealsMap after SOQL Loop ' + CNCWDealsMap);                                                                                                                                                 
            
        //Conga Novatus
        for(AggregateResult ar : [SELECT Count(OpportunityId) NovatusDealCount, Opportunity.Referring_Partner_Primary__c RefPartner
                                    FROM OpportunityLineItem 
                                    WHERE Opportunity.StageName = 'Closed Won' 
                                        AND Opportunity.Referring_Partner_Primary__c != null 
                                        AND Opportunity.CloseDate = This_Fiscal_Year 
                                        AND Product2.Family = 'Novatus Contracts' 
                                    GROUP BY Opportunity.Referring_Partner_Primary__c 
                                    ORDER BY Opportunity.Referring_Partner_Primary__c])
                                    {
            CNCWDealsMap.put((Id)ar.get('RefPartner'), (Double)ar.get('NovatusDealCount'));        
        }
            //System.debug('************************* NovatusDealsMap after SOQL Loop ' + NovatusDealsMap);
            
        //Conga Sign
        for(AggregateResult ar : [SELECT Count(OpportunityId) NovatusDealCount, Opportunity.Referring_Partner_Primary__c RefPartner
                                    FROM OpportunityLineItem 
                                    WHERE Opportunity.StageName = 'Closed Won' 
                                        AND Opportunity.Referring_Partner_Primary__c != null 
                                        AND Opportunity.CloseDate = This_Fiscal_Year 
                                        AND Product2.Family = 'Conga Sign' 
                                    GROUP BY Opportunity.Referring_Partner_Primary__c 
                                    ORDER BY Opportunity.Referring_Partner_Primary__c])
                                    {
            CSDealsMap.put((Id)ar.get('RefPartner'), (Double)ar.get('NovatusDealCount'));        
        }
            //System.debug('************************* NovatusDealsMap after SOQL Loop ' + NovatusDealsMap);                                                                                                                                                                   
        
        // String together the new Notes field from each of the maps
            // Derepcated and replaced with individual fields for each product family
                // JM 29 JAN 2018
        /*for(Partner_Profile__c pp : partnerProfileRecords)
        {                    
        // Composer Deals
            if(CMDealsMap.get(pp.Account__c) == null)
            {                                        
                pp.Notes__c = 'Composer Deals This Fiscal Year: 0.0';
                newNotesValue = 'Composer Deals This Fiscal Year: 0.0';
            }
            else
            {
                pp.Notes__c = 'Composer Deals This Fiscal Year: ' + CMDealsMap.get(pp.Account__c);
                newNotesValue = 'Composer Deals This Fiscal Year: ' + CMDealsMap.get(pp.Account__c);                
            }
        // Conga Automation Deals
            if(CNCWDealsMap.get(pp.Account__c) == null)
            {                                        
                pp.Notes__c += '\nConductor|Workflow Deals This Fiscal Year: 0.0';
                newNotesValue += '\nConductor|Workflow Deals This Fiscal Year: 0.0';
            }
            else
            {
                pp.Notes__c += '\nConductor|Workflow Deals This Fiscal Year: ' + CNCWDealsMap.get(pp.Account__c); 
                newNotesValue += '\nConductor|Workflow Deals This Fiscal Year: ' + CNCWDealsMap.get(pp.Account__c); 
            }             
        // ActionGrid Deals
            if(AGDealsMap.get(pp.Account__c) == null)
            {                                        
                pp.Notes__c += '\nActionGrid Deals This Fiscal Year: 0.0';
                newNotesValue += '\nActionGrid Deals This Fiscal Year: 0.0';
            }
            else
            {
                pp.Notes__c += '\nActionGrid Deals This Fiscal Year: ' + AGDealsMap.get(pp.Account__c);  
                newNotesValue += '\nActionGrid Deals This Fiscal Year: ' + AGDealsMap.get(pp.Account__c); 
            }
        // Conga Contracts Deals
            if(CCDealsMap.get(pp.Account__c) == null)
            {                                        
                pp.Notes__c += '\nContracts Deals This Fiscal Year: 0.0';
                newNotesValue += '\nContracts Deals This Fiscal Year: 0.0';
            }
            else
            {
                pp.Notes__c += '\nContracts Deals This Fiscal Year: ' + CCDealsMap.get(pp.Account__c);  
                newNotesValue += '\nContracts Deals This Fiscal Year: ' + CCDealsMap.get(pp.Account__c);  
            }             
        // Courier Deals
            if(CourierDealsMap.get(pp.Account__c) == null)
            {                                        
                pp.Notes__c += '\nCourier Deals This Fiscal Year: 0.0';
                newNotesValue += '\nCourier Deals This Fiscal Year: 0.0';
            }
            else
            {
                pp.Notes__c += '\nCourier Deals This Fiscal Year: ' + CourierDealsMap.get(pp.Account__c);  
                newNotesValue += '\nCourier Deals This Fiscal Year: ' + CourierDealsMap.get(pp.Account__c);  
            }                                                                                                                
        // Novatus Deals
            if(NovatusDealsMap.get(pp.Account__c) == null)
            {                                        
                pp.Notes__c += '\nNovatus Deals This Fiscal Year: 0.0';
                newNotesValue += '\nNovatus Deals This Fiscal Year: 0.0';
            }
            else
            {
                pp.Notes__c += '\nnNovatus Deals This Fiscal Year: ' + NovatusDealsMap.get(pp.Account__c);  
                newNotesValue += '\nnNovatus Deals This Fiscal Year: ' + NovatusDealsMap.get(pp.Account__c); 
            }       
                        
            System.debug('************************* pp.Notes__c field after concatenations: ' + pp.Notes__c);                                                                                       
                        
        // Add the data to the List of records to update        
            partnerProfileRecordsToUpdate.add(pp);  
                System.debug('************************* Final list size for update call ' + partnerProfileRecordsToUpdate.size());
                System.debug('************************* Final list for update call: ' + partnerProfileRecordsToUpdate);                
            
        // Add to a map of Partner Profile reecord and the String for the Deal Type breakdown
            NoteFieldMap.put(pp.Id,newNotesValue);        
                System.debug('************************* Final Map PP Records and the new Note field value: ' + NoteFieldMap);             
        }
        */

        // Do the update without BatchApex Handler - FOR TESTING ONLY
        //Database.update(partnerProfileRecordsToUpdate);
        
        // Pass to a BatchApex Handler
        PPUpdaterBatchClass ppubc = new PPUpdaterBatchClass();
        ppubc.query = 'SELECT Id, Account__c, of_Conga_implementations_done__c, Implementations_done_This_Year__c, Implementations_done_Last_Year__c, Total_Revenue_All_Time__c, Total_Revenue_New_Upsell_All_Time__c, Revenue_This_Year__c, Revenue_Last_Year__c, Total_Certifications__c, Average_Composer_Seats_Per_Deal__c, First_Report_Date__c, Most_Recent_Report__c, Notes__c, Courier_Deals_This_Year__c, Composer_Deals_This_Year__c, ActionGrid_Deals_This_Year__c, Conga_Contracts_Deals_This_Year__c, Conductor_Workflow_Deals_This_Year__c, Conga_Novatus_Deals_This_Year__c, Conga_Sign_Deals_This_Year__c FROM Partner_Profile__c WHERE Retired__c = False AND Account__c != null';                    
        //ppubc.NFMap = NoteFieldMap;
        ppubc.CourierDealsMap = CourierDealsMap;
        ppubc.ComposerDealsMap = CMDealsMap;
        ppubc.ActionGridDealsMap = AGDealsMap;
        ppubc.AutomationDealsMap = CNCWDealsMap;
        ppubc.CongaContractsDealsMap = CCDealsMap;
        ppubc.NovatusDealsMap = NovatusDealsMap;
        ppubc.CongaSignDealsMap = CSDealsMap;           
    
        ID batchprocessid = Database.executeBatch(ppubc);         
    }                                            


}