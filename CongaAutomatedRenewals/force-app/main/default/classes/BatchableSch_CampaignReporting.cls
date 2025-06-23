/** 
* @author ECS, KSears, ERedding
* @date 20190708
* @version 1.00
* @description BatchableSch_CampaignReporting - Combination batchable and schedulable class for campaign roll ups
*/
public with sharing class BatchableSch_CampaignReporting implements Database.Batchable<Id>, Schedulable, Database.Stateful {
    public Set<Id> SpecifiedCampaignIds;    
    public Set<Id> NextLevelCampaignIds;

    /** 
    * @description BatchableSch_CampaignReporting - Constructor
    */
    public BatchableSch_CampaignReporting() {
    }

    /** 
    * @description BatchableSch_CampaignReporting - Constructor with Parameters
    */
    public BatchableSch_CampaignReporting(Set<Id> campaignIds) {
        this.SpecifiedCampaignIds = campaignIds;
    }

    /** 
    * @description Batchable start method
    */  
    public List<Id> start(Database.BatchableContext bc) {
        try{
            this.NextLevelCampaignIds = new Set<Id>();           
            List<Id> campaignIdsToProcess = new List<Id>();
            if(SpecifiedCampaignIds != null && !SpecifiedCampaignIds.isEmpty()){
                // USE SPECIFIED CAMPAIGN IDS
                for(Campaign campaign : [SELECT Id, ParentId FROM Campaign WHERE IsActive = TRUE AND Id IN :SpecifiedCampaignIds]){
                    campaignIdsToProcess.add(campaign.Id);

                    if(campaign.ParentId != null){
                        this.NextLevelCampaignIds.add(campaign.ParentId);
                    }
                }
            }
            else{         
                // FIND STAND ALONE OR CHILDREN AT THE BOTTOM OF A HIERARCHY
                for(Campaign campaign : [SELECT Id, ParentId, (SELECT Id FROM ChildCampaigns WHERE IsActive = TRUE) FROM Campaign WHERE IsActive = TRUE]){
                    if(campaign.ChildCampaigns.isEmpty()){
                        campaignIdsToProcess.add(campaign.Id);

                        if(campaign.ParentId != null){
                            this.NextLevelCampaignIds.add(campaign.ParentId);
                        }
                    }
                }
            }
            return campaignIdsToProcess;   
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_CampaignReporting', 'start', null, ex, true);
            return new List<Id>();
        }
    }
    
    /** 
    * @description Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        BatchableSch_CampaignReporting batchClass = new BatchableSch_CampaignReporting(null);
        Database.executeBatch(batchClass, 5);
    }

    /** 
    * @description Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<Id> scope) {
        try{
            // BUILD MAP OF CAMPAIGNS TO UPDATE
            Map<Id, Campaign> campaignsByIdMap = new Map<Id,Campaign>();
            for(Id campaignId : scope){
                campaignsByIdMap.put(campaignId, new Campaign(Id = campaignId, Average_Days_to_Opportunity__c = 0, Average_Days_to_Close__c = 0, Future_Avg_MRR_in_Campaign__c = 0, 
                                                              Future_Avg_MRR_in_Hierarchy__c = 0, Total_Won_MRR_in_Campaign__c = 0, Total_Won_MRR_in_Hierarchy__c = 0));
            }

            if(!campaignsByIdMap.isEmpty()){

                ////////////////////////////////////// GET CALCULATIONS FROM CHILD CAMPAIGNS /////////////////////////////////////
                // CREATE CHILD CAMPAIGNS BY PARENT CAMPAIGN IDS MAP
                Map<Id, List<Campaign>> childCampaignsByParentId = new Map<Id, List<Campaign>>();
                for(Campaign childCampaign : [SELECT Id, ParentId, Average_Days_to_Opportunity__c, Average_Days_to_Close__c, Future_Avg_MRR_in_Campaign__c, Future_Avg_MRR_in_Hierarchy__c, 
                                                     Total_Won_MRR_in_Campaign__c, Total_Won_MRR_in_Hierarchy__c
                                              FROM Campaign WHERE ParentId IN :campaignsByIdMap.keySet()]){
                    if(!childCampaignsByParentId.containsKey(childCampaign.ParentId)){
                        childCampaignsByParentId.put(childCampaign.ParentId, new List<Campaign>());
                    }
                    childCampaignsByParentId.get(childCampaign.ParentId).add(childCampaign);
                }

                //// CALCULATE METRICS FROM CHILD CAMPAIGNS IF THEY EXIST
                Set<Id> parentCampaignsWithChildren = new Set<Id>();
                for(Id parentCampaignId : childCampaignsByParentId.keyset()){
                    if(!childCampaignsByParentId.get(parentCampaignId).isEmpty()){
                        parentCampaignsWithChildren.add(parentCampaignId);

                        Campaign parentCampaign = campaignsByIdMap.get(parentCampaignId);
                        Decimal aveDaysToOppTotal = 0;
                        Decimal aveDaysToCloseTotal = 0;
                        Decimal totalWonMRR = 0;
                        Decimal totalFutureAvgMRR = 0;
                        Integer count = childCampaignsByParentId.get(parentCampaignId).size();

                        for(Campaign childCampaign : childCampaignsByParentId.get(parentCampaignId)){
                            aveDaysToOppTotal += UtilityClass.replaceNull(childCampaign.Average_Days_to_Opportunity__c, 0);
                            aveDaysToCloseTotal += UtilityClass.replaceNull(childCampaign.Average_Days_to_Close__c, 0);

                            if(UtilityClass.replaceNull(childCampaign.Total_Won_MRR_in_Hierarchy__c, 0) > 0){
                                totalWonMRR += childCampaign.Total_Won_MRR_in_Hierarchy__c;
                            }
                            else{
                                totalWonMRR += UtilityClass.replaceNull(childCampaign.Total_Won_MRR_in_Campaign__c, 0);
                            }

                            if(UtilityClass.replaceNull(childCampaign.Future_Avg_MRR_in_Hierarchy__c, 0) > 0){
                                totalFutureAvgMRR += childCampaign.Future_Avg_MRR_in_Hierarchy__c;
                            }
                            else{
                                totalFutureAvgMRR += UtilityClass.replaceNull(childCampaign.Future_Avg_MRR_in_Campaign__c, 0);
                            }
                        }

                        parentCampaign.Average_Days_to_Opportunity__c = aveDaysToOppTotal / count;
                        parentCampaign.Average_Days_to_Close__c = aveDaysToCloseTotal / count;
                        parentCampaign.Total_Won_MRR_in_Hierarchy__c = totalWonMRR;
                        parentCampaign.Future_Avg_MRR_in_Hierarchy__c = totalFutureAvgMRR;
                    }
                }
                ////////////////////////////////////////

                ////////////////////////////////////// RUN CALCULATIONS FROM CHILD MEMBERS /////////////////////////////////////

                // GET LEADS FROM CAMPAIGN MEMBERS
                Map<Id,List<CampaignMember>> membersByCampaignId = new Map<Id,List<CampaignMember>>();                
                for(CampaignMember member : [SELECT Id, CampaignId, LeadId, CreatedDate, Lead.ConvertedDate, Lead.ConvertedOpportunity.IsClosed, Lead.ConvertedOpportunity.CloseDate
                                             FROM CampaignMember WHERE CampaignId IN :campaignsByIdMap.keyset() AND Lead.IsConverted = true AND Lead.ConvertedOpportunityId != null]){
                    if(!membersByCampaignId.containsKey(member.CampaignId)){
                        membersByCampaignId.put(member.CampaignId, new List<CampaignMember>());
                    }
                    membersByCampaignId.get(member.CampaignId).add(member);
                }

                //// CALCULATE AVERAGE DAYS TO OPPORTUNITY
                for(Id campaignId : membersByCampaignId.keyset()){
                    Integer total = 0;
                    Integer count = 0;
                    for(CampaignMember member : membersByCampaignId.get(campaignId)){
                        total += member.CreatedDate.date().daysBetween(member.Lead.ConvertedDate);
                        count++;
                    }

                    if(count > 0){
                        if(parentCampaignsWithChildren.contains(campaignId)){
                            count++; // ADD ONE MORE COUNT FOR EXISTING AMOUNT COMING FROM CHILD CAMPAIGNS
                        }
                        campaignsByIdMap.get(campaignId).Average_Days_to_Opportunity__c = (campaignsByIdMap.get(campaignId).Average_Days_to_Opportunity__c + Double.valueOf(total)) / count;
                    }
                }

                //// CALCULATE AVERAGE DAYS TO OPP CLOSE
                for(Id campaignId : membersByCampaignId.keyset()){
                    Integer total = 0;
                    Integer count = 0;
                    for(CampaignMember member : membersByCampaignId.get(campaignId)){
                        if(member.Lead.ConvertedOpportunity.IsClosed && member.Lead.ConvertedOpportunity.CloseDate != null){
                            total += member.CreatedDate.date().daysBetween(member.Lead.ConvertedOpportunity.CloseDate);
                            count++;
                        }
                    }

                    if(count > 0){
                        if(parentCampaignsWithChildren.contains(campaignId)){
                            count++; // ADD ONE MORE COUNT FOR EXISTING AMOUNT COMING FROM CHILD CAMPAIGNS
                        }
                        campaignsByIdMap.get(campaignId).Average_Days_to_Close__c = (campaignsByIdMap.get(campaignId).Average_Days_to_Close__c + Double.valueOf(total)) / count;
                    }
                }

                // GET OPPORTUNITIES THROUGH THEIR PRIMARY CAMPAIGNS               
                Map<Id, List<Opportunity>> oppsByCampaignId = new Map<Id, List<Opportunity>>();
                for(Opportunity opp : [SELECT Id, IsClosed, IsWon, CampaignId, Total_MRR_UpsellFx__c, Future_Ave_MRR_TotalFx__c FROM Opportunity WHERE CampaignId IN :campaignsByIdMap.keyset()]){
                    if(!oppsByCampaignId.containsKey(opp.CampaignId)){
                        oppsByCampaignId.put(opp.CampaignId, new List<Opportunity>());
                    }
                    oppsByCampaignId.get(opp.CampaignId).add(opp);
                }

                //// CALCULATE TOTAL WON MRR -AND- FUTURE AVG MRR TOTAL IN CAMPAIGN (TOTAL ROLL UP FIELD) FROM WON OPPORTUNITY'S
                for(Id campaignId : oppsByCampaignId.keyset()){
                    Decimal totalMRRUpsell = 0.00;
                    Decimal totalFutureAveMRR = 0.00;

                    for(Opportunity opp : oppsByCampaignId.get(campaignId)){
                        if(opp.IsClosed && opp.IsWon){
                            totalMRRUpsell += UtilityClass.replaceNull(opp.Total_MRR_UpsellFx__c, 0.00);
                        }
                        totalFutureAveMRR += UtilityClass.replaceNull(opp.Future_Ave_MRR_TotalFx__c, 0.00);                                    
                    }

                    campaignsByIdMap.get(campaignId).Total_Won_MRR_in_Campaign__c = totalMRRUpsell;
                    campaignsByIdMap.get(campaignId).Future_Avg_MRR_in_Campaign__c = totalFutureAveMRR;
                }

                //// ADD MEMBER TOTALS TO HIERARCHY TOTALS IF CAMPAIGN IS A PARENT -OR- IF NOT A PARENT JUST COPY MEMBER AMOUNT INTO HIERARCHY AMOUNT
                for(Campaign campaign : campaignsByIdMap.values()){
                    if(parentCampaignsWithChildren.contains(campaign.Id)){
                        campaign.Total_Won_MRR_in_Hierarchy__c += campaign.Total_Won_MRR_in_Campaign__c;
                        campaign.Future_Avg_MRR_in_Hierarchy__c += campaign.Future_Avg_MRR_in_Campaign__c;
                    }
                    else{
                        campaign.Total_Won_MRR_in_Hierarchy__c = campaign.Total_Won_MRR_in_Campaign__c;
                        campaign.Future_Avg_MRR_in_Hierarchy__c = campaign.Future_Avg_MRR_in_Campaign__c;
                    }
                }
                
                //////////////////////////////////////

                // SAVE RESULTS TO DATABASE CATCHING ANY ERRORS
                Database.SaveResult[] updateResults = Database.update(campaignsByIdMap.values(), false);
                SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'BatchableSch_CampaignReporting', 'execute', true);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_CampaignReporting', 'execute', scope, ex, true);
        }
    }

    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // CALCULATIONS FINISHED, START NEXT LEVEL IF NECESSARY
        if(NextLevelCampaignIds != null && !NextLevelCampaignIds.isEmpty()){
            BatchableSch_CampaignReporting batchClass = new BatchableSch_CampaignReporting(NextLevelCampaignIds);
            Database.executeBatch(batchClass, 5);
        }
    }


}