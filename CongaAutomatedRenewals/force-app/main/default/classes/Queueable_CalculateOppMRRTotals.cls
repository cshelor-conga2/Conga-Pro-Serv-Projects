/**
* @author ECS, ERedding
* @date 20190618
* @version 1.00
* @description Queueable_CalculateOppMRRTotals - Queueable class for calculating Opportunity MRR Totals
*/
public with sharing class Queueable_CalculateOppMRRTotals implements Queueable {
    private Set<Id> OppsIds {get; set;}

    /** 
    * @description Queueable_CalculateOppMRRTotals - Constructor
    * @param Set<Id> oppIds - Ids of Opportunities to process
    */
    public Queueable_CalculateOppMRRTotals(Set<Id> oppIds){
        this.OppsIds = oppIds;
    }

    /** 
    * @description execute - Queueable execute method
    */
    public void execute(QueueableContext context){
        try{
            if(!OppsIds.isEmpty()){

                // GET OPP DATA
                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                for(Opportunity opp : [SELECT Id, Net_New_MRR__c, Net_New_MRR_Number__c, Total_MRR_Upsell__c, Total_MRR_Downsell__c, Total_MRR_Churn__c,
                                            Down_Sell_AI_Ave_MRR__c, Down_Sell_Automation_Ave_MRR__c, Down_Sell_Collaborate_Ave_MRR__c,
                                            Down_Sell_Composer_Ave_MRR__c, Down_Sell_Contracts_Ave_MRR__c, Down_Sell_Contracts_for_SF_Ave_MRR__c, Down_Sell_Courier_Ave_MRR__c, 
                                            Down_Sell_Grid_Ave_MRR__c, Down_Sell_Orchestrate_Ave_MRR__c, Down_Sell_Other_Ave_MRR__c, Down_Sell_Sign_Ave_MRR__c, Down_Sell_Support_Ave_MRR__c, 
                                            Down_Sell_Training_Ave_MRR__c,
                                            Churn_AI_Ave_MRR__c, Churn_Automation_Ave_MRR__c, Churn_Collaborate_Ave_MRR__c, Churn_Composer_Ave_MRR__c, 
                                            Churn_Contracts_Ave_MRR__c, Churn_Contracts_for_SF_Ave_MRR__c, Churn_Courier_Ave_MRR__c,Churn_Grid_Ave_MRR__c, Churn_Orchestrate_Ave_MRR__c, 
                                            Churn_Other_Ave_MRR__c, Churn_Support_Ave_MRR__c, Churn_Sign_Ave_MRR__c, Churn_Training_Ave_MRR__c,
                                            Upsell_AI_Ave_MRR__c,
                                            Upsell_Automation_Ave_MRR__c, Upsell_Collaborate_Ave_MRR__c, Upsell_Composer_Ave_MRR__c, Upsell_Contracts_Ave_MRR__c,  
                                            Upsell_Contracts_for_SF_Ave_MRR__c, Upsell_Courier_Ave_MRR__c, Upsell_Grid_Ave_MRR__c, Upsell_Orchestrate_Ave_MRR__c, 
                                            Upsell_Other_Ave_MRR__c, Upsell_Sign_Ave_MRR__c, Upsell_Support_Ave_MRR__c, Upsell_Training_Ave_MRR__c
                                        FROM Opportunity WHERE Id IN :OppsIds]){

                    // CALCULATE TOTAL MRR UPSELL
                    Decimal totalMRRUpsell = opp.Upsell_AI_Ave_MRR__c + opp.Upsell_Automation_Ave_MRR__c + opp.Upsell_Collaborate_Ave_MRR__c + opp.Upsell_Composer_Ave_MRR__c + 
                                             opp.Upsell_Contracts_Ave_MRR__c + opp.Upsell_Contracts_for_SF_Ave_MRR__c + opp.Upsell_Courier_Ave_MRR__c + opp.Upsell_Grid_Ave_MRR__c + 
                                             opp.Upsell_Orchestrate_Ave_MRR__c + opp.Upsell_Other_Ave_MRR__c + opp.Upsell_Sign_Ave_MRR__c + opp.Upsell_Support_Ave_MRR__c + 
                                             opp.Upsell_Training_Ave_MRR__c;

                    // CALCULATE TOTAL MRR DOWNSELL
                    Decimal totalMRRDownsell = opp.Down_Sell_AI_Ave_MRR__c + opp.Down_Sell_Automation_Ave_MRR__c + opp.Down_Sell_Collaborate_Ave_MRR__c + opp.Down_Sell_Composer_Ave_MRR__c + 
                                               opp.Down_Sell_Contracts_Ave_MRR__c + opp.Down_Sell_Contracts_for_SF_Ave_MRR__c + opp.Down_Sell_Courier_Ave_MRR__c + opp.Down_Sell_Grid_Ave_MRR__c + 
                                               opp.Down_Sell_Orchestrate_Ave_MRR__c + opp.Down_Sell_Other_Ave_MRR__c + opp.Down_Sell_Sign_Ave_MRR__c + opp.Down_Sell_Support_Ave_MRR__c + 
                                               opp.Down_Sell_Training_Ave_MRR__c;

                    // CALCULATE TOTAL MRR DOWNSELL
                    Decimal totalMRRChurn = opp.Churn_AI_Ave_MRR__c + opp.Churn_Automation_Ave_MRR__c + opp.Churn_Collaborate_Ave_MRR__c + opp.Churn_Composer_Ave_MRR__c + 
                                            opp.Churn_Contracts_Ave_MRR__c + opp.Churn_Contracts_for_SF_Ave_MRR__c + opp.Churn_Courier_Ave_MRR__c + opp.Churn_Grid_Ave_MRR__c + 
                                            opp.Churn_Orchestrate_Ave_MRR__c + opp.Churn_Other_Ave_MRR__c + opp.Churn_Sign_Ave_MRR__c + opp.Churn_Support_Ave_MRR__c + 
                                            opp.Churn_Training_Ave_MRR__c;

                    // ADD OPP TO UPDATE LIST IF A DIFFERENCE IN CALCULATIONS IS FOUND
                    if(opp.Net_New_MRR_Number__c != opp.Net_New_MRR__c || totalMRRUpsell != opp.Total_MRR_Upsell__c || 
                        totalMRRDownsell != opp.Total_MRR_Downsell__c || totalMRRChurn != opp.Total_MRR_Churn__c){

                        opp.Net_New_MRR_Number__c = opp.Net_New_MRR__c;
                        opp.Total_MRR_Upsell__c = totalMRRUpsell;
                        opp.Total_MRR_Downsell__c = totalMRRDownsell;
                        opp.Total_MRR_Churn__c = totalMRRChurn;
                        oppsToUpdate.add(opp);
                    }
                }

                // SAVE OPPS
                if(!oppsToUpdate.isEmpty()){
                    TriggerHelper.OverrideAllSettings(true, false); // NO TRIGGERS NEED TO RUN WITH THIS UPDATE
                    Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'Queueable_CalculateOppMRRTotals', 'execute', true);
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('Queueable_CalculateOppMRRTotals', 'execute', OppsIds, ex, true);
        }
    }


}