/**
* @author ECS, ERedding
* @date 20191024
* @version 1.00
* @description BatchableSch_CalculateOppMRRTotals - Batchable/Schedulable class for calculating Opportunity MRR Totals
*/
public with sharing class BatchableSch_CalculateOppMRRTotals implements Database.Batchable<SObject>, Schedulable {
    private Set<Id> OppsIds {get; set;}

    /** 
    * @description BatchableSch_CalculateOppMRRTotals - Constructor WITH parameters
    * @param Set<Id> oppIds - Ids of Opportunities to process
    */
    public BatchableSch_CalculateOppMRRTotals(Set<Id> oppIds){
        this.OppsIds = oppIds;
    }

    /** 
    * @description BatchableSch_CalculateOppMRRTotals - Constructor with no parameters
    */    
    public BatchableSch_CalculateOppMRRTotals(){
        this.OppsIds = new Set<Id>();
    }

	/** 
	* @description Scheduable execute method
	*/
   	public void execute(SchedulableContext context) {
		Database.executeBatch(this, 1);
	}

	/** 
	* @description Batchable start method
	*/	
	public Database.QueryLocator start(Database.BatchableContext context) {
		DateTime thirtyMinutesAgo = DateTime.now().addMinutes(-30);
		return Database.getQueryLocator([SELECT Id, Net_New_MRR__c, Net_New_MRR_Number__c, Total_MRR_Upsell__c, Total_MRR_Downsell__c, Total_MRR_Churn__c, Total_MRR_Cross_Sell__c,
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
                                            Upsell_Other_Ave_MRR__c, Upsell_Sign_Ave_MRR__c, Upsell_Support_Ave_MRR__c, Upsell_Training_Ave_MRR__c,
                                            Cross_Sell_AI_Ave_NNMRR__c, Cross_Sell_Automation_Ave_MRR__c, Cross_Sell_Collaborate_Ave_NNMRR__c, Cross_Sell_Composer_Ave_NNMRR__c, 
                                            Cross_Sell_Contracts_Ave_NNMRR__c, Cross_Sell_Contracts_for_SF_Ave_NNMRR__c, Cross_Sell_Courier_Ave_NNMRR__c, Cross_Sell_Grid_Ave_NNMRR__c, 
                                            Cross_Sell_Orchestrate_Ave_NNMRR__c, Cross_Sell_Sign_Ave_NNMRR__c, Cross_Sell_Support_Ave_NNMRR__c
                                        FROM Opportunity WHERE LastModifiedDate >= :thirtyMinutesAgo OR Id IN :OppsIds]);
	}

    /** 
    * @description execute - Schedulable execute method
    */
    public void execute(Database.BatchableContext context, List<Opportunity> scope){
        try{
            // GET OPP DATA
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for(Opportunity opp : scope){

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

                // CALCULATE TOTAL MRR CROSSSELL
                Decimal totalMRRCrossSell = opp.Cross_Sell_AI_Ave_NNMRR__c + opp.Cross_Sell_Automation_Ave_MRR__c + opp.Cross_Sell_Collaborate_Ave_NNMRR__c + opp.Cross_Sell_Composer_Ave_NNMRR__c + 
                                            opp.Cross_Sell_Contracts_Ave_NNMRR__c + opp.Cross_Sell_Contracts_for_SF_Ave_NNMRR__c + opp.Cross_Sell_Courier_Ave_NNMRR__c + opp.Cross_Sell_Grid_Ave_NNMRR__c + 
                                            opp.Cross_Sell_Orchestrate_Ave_NNMRR__c + opp.Cross_Sell_Sign_Ave_NNMRR__c + opp.Cross_Sell_Support_Ave_NNMRR__c;

                // ADD OPP TO UPDATE LIST IF A DIFFERENCE IN CALCULATIONS IS FOUND
                if(opp.Net_New_MRR_Number__c != opp.Net_New_MRR__c || totalMRRUpsell != opp.Total_MRR_Upsell__c || 
                    totalMRRDownsell != opp.Total_MRR_Downsell__c || totalMRRChurn != opp.Total_MRR_Churn__c || totalMRRCrossSell != opp.Total_MRR_Cross_Sell__c){

                    opp.Net_New_MRR_Number__c = opp.Net_New_MRR__c;
                    opp.Total_MRR_Upsell__c = totalMRRUpsell;
                    opp.Total_MRR_Downsell__c = totalMRRDownsell;
                    opp.Total_MRR_Churn__c = totalMRRChurn;
                    opp.Total_MRR_Cross_Sell__c = totalMRRCrossSell;
                    oppsToUpdate.add(opp);
                }
            }

            // SAVE OPPS
            if(!oppsToUpdate.isEmpty()){
                TriggerHelper.OverrideAllSettings(true, false); // NO TRIGGERS NEED TO RUN WITH THIS UPDATE
                Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'BatchableSch_CalculateOppMRRTotals', 'execute', true);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_CalculateOppMRRTotals', 'execute', scope, ex, true);
        }
    }

	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		// NO FINISH LOGIC
	}


}