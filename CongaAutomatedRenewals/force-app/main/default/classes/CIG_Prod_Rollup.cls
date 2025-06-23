/**
* @author Conga Services, KSears
* @date 20181220
* @version 1.00
* @description CIG_Prod_Rollup helper class
*/
public with sharing class CIG_Prod_Rollup {

    /**
    * @description RollupUseage helper method - 
    * @param List<Salesforce_Org__c> sfOrgs
    * @return void
    */
    public static void RollupUseage(List<Salesforce_Org__c> sfOrgs){
        try{
            //init
            Set<Id> allOrgIds = new Set<Id>();
            Set<Id> orgIds = new Set<Id>();
            Set<Id> usageId = new Set<Id>();
            Map<Id,Id> orgAccIds = new Map<Id,Id>();
            Map<Id,List<Asset>> assetsForOrgId = new Map<Id,List<Asset>>();
            Map<Id,Salesforce_Org__c> updateOrgs = new Map<Id,Salesforce_Org__c>();

            for(Salesforce_Org__c org : sfOrgs){
                allOrgIds.add(org.Id);
                orgAccIds.put(org.Account__c,org.Id);
            }

            for(Asset a : [SELECT Id, AccountId, Name, Quantity, Start_Date__c, End_Date__c FROM Asset WHERE AccountId IN :orgAccIds.keyset()]){
                if(a.Name == 'Conga Invoice Generation for Salesforce Billing' || a.Name == 'Service Events for Conga Invoice Generation for Salesforce Billing'){
                    if(!assetsForOrgId.containsKey(orgAccIds.get(a.AccountId))){
                        assetsForOrgId.put(orgAccIds.get(a.AccountId), new List<Asset>{a});
                    }
                    else{
                        assetsForOrgId.get(orgAccIds.get(a.AccountId)).add(a);
                    }
                }
            }

            for(Id i : assetsForOrgId.keyset()){
                for(Salesforce_Org__c org : sfOrgs){
                    if(i == org.Id){
                        Decimal total = 0;
                        for(Asset a : (List<Asset>)assetsForOrgId.get(i)){
                            if(a.Name == 'Conga Invoice Generation for Salesforce Billing'){
                                total = total + 1000;
                                org.Asset_Start_Date__c = a.Start_Date__c;
                                org.Asset_End_Date__c = a.End_Date__c;
                            }
                            else{
                                total = total + a.Quantity;
                            }
                        }
                        org.Allowed_Usage__c = total;
                        updateOrgs.put(org.Id,org);
                    }
                }
            }
    
            //grab all of the success
            for(Salesforce_Org__c org : sfOrgs){
                if(org.Asset_Start_Date__c != null && org.Asset_End_Date__c != null){
                    orgIds.add(org.Id);
                }
            }

            for(Conga_Usage_History2__c use : [SELECT Salesforce_Org__c, Salesforce_Org__r.Asset_Start_Date__c, Salesforce_Org__r.Asset_End_Date__c, Month__c, Total_Composer_Successes__c
                                               FROM Conga_Usage_History2__c WHERE Salesforce_Org__c IN :allOrgIds AND Type__c = 'CSFB' AND Month__c = THIS_MONTH]){
                for(Salesforce_Org__c org : sfOrgs){
                    if(use.Salesforce_Org__c == org.Id){
                        org.Monthly_Total_Success__c = use.Total_Composer_Successes__c;
                        if(!updateOrgs.containsKey(org.Id)){
                            updateOrgs.put(org.Id,org);
                        }
                    }
                }               
            }

            for(Conga_Usage_History2__c use : [SELECT Salesforce_Org__c, Salesforce_Org__r.Asset_Start_Date__c, Salesforce_Org__r.Asset_End_Date__c, Month__c 
                                               FROM Conga_Usage_History2__c WHERE Salesforce_Org__c IN :orgIds AND Type__c = 'CSFB']){
                if(use.Month__c >= use.Salesforce_Org__r.Asset_Start_Date__c && use.Month__c <= use.Salesforce_Org__r.Asset_End_Date__c){
                    usageId.add(use.Id);
                }
            }

            AggregateResult[] groupedResults  = [SELECT Salesforce_Org__c, SUM(Total_Composer_Successes__c)tot FROM Conga_Usage_History2__c 
                                                 WHERE Id IN :usageId GROUP BY Salesforce_Org__c];
            for (AggregateResult ar : groupedResults){
                for(Salesforce_Org__c org : sfOrgs){
                    if(ar.get('Salesforce_Org__c') == org.Id){
                        org.Total_Success__c = (Decimal)ar.get('tot');                      
                        if(!updateOrgs.containsKey(org.Id)){
                            updateOrgs.put(org.Id,org);
                        }
                    }
                }
            }

            if(updateOrgs.size() > 0){
                Database.SaveResult[] updateResults = Database.update(updateOrgs.values(), false);
                SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'CIG_Prod_Rollup', 'RollupUseage', true);
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('CIG_Prod_Rollup', 'RollupUseage', sfOrgs, ex, true);
        }
    }


}