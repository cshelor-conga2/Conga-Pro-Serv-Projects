/*** Apex version of the default logic.
* To assign opportunities based rules - 
    - Assign subscription opportunities to rep level territory associated with related account
    - Assign service and training opportunities based on PS Global region and PS NA region values
*/
global class OppTerrAssignDefaultLogicFilter implements TerritoryMgmt.OpportunityTerritory2AssignmentFilter {
    /** No-arg constructor.*/
     global OppTerrAssignDefaultLogicFilter() {}
     /**
      * Get mapping of opportunity to territory2Id. The incoming list of opportunityIds contains only those with IsExcludedFromTerritory2Filter=false.
      * If territory2Id = null in result map, clear the opportunity.territory2Id if set.
      * If opportunity is not present in result map, its territory2Id remains intact.
      */
    global Map<Id,Id> getOpportunityTerritory2Assignments(List<Id> opportunityIds) {
        Map<Id, Id> OppIdTerritoryIdResult = new Map<Id, Id>();
 
        // Get the active territory model Id
        Id activeModelId = getActiveModelId();
        
        if(activeModelId != null){
           // List<Territory2> Terr = [Select Id, NAME from Territory2 
                             //        where NAME in ('NA Central','NA East','NA South','NA West','APAC_Services','EMEA_Services')];
            

        
            List<Opportunity> opportunities = [Select Id, AccountId, Territory2Id, RecordType.NAME from Opportunity where Id IN :opportunityIds];
            Set<Id> accountIds = new Set<Id>();        
        
            for(Opportunity opp:opportunities){
                if(opp.AccountId != null && (opp.RecordType.Name == 'Direct' || opp.RecordType.Name == 'Indirect')){
                    accountIds.add(opp.AccountId);
                }
            }
            Map<Id,Id> accountSalesRepTerritory = new Map<Id,Id>();
            if (accountIds.size()>0)
                accountSalesRepTerritory  = getAccountSalesRepTerritory(activeModelId, accountIds);
                   
            for(Opportunity opp:opportunities){
                if((opp.RecordType.Name == 'Direct')||(opp.RecordType.Name == 'Indirect')){
                    Id salesTerrId = accountSalesRepTerritory.get(opp.AccountId);
                    OppIdTerritoryIdResult.put(opp.Id, salesTerrId);
                }
               
            }
        }
        return OppIdTerritoryIdResult;
    }
     
    /**
     * Query assigned territoryIds in active model for given accountIds
     * Create a map of accountId to rep level territory
          */
    @TestVisible
    private Map<Id,Id> getAccountSalesRepTerritory(Id activeModelId, Set<Id> accountIds){
        Map<Id,Id> accountSalesRepTerritory = new Map<Id,Id>();
        for(ObjectTerritory2Association ota:[Select ObjectId, Territory2Id, Territory2.Territory2Type.DeveloperName from ObjectTerritory2Association 
                                             where objectId IN:accountIds and Territory2.Territory2ModelId = :activeModelId 
                                             and Territory2.Territory2Type.DeveloperName = 'Sales_Rep_Level_Territory']){
        accountSalesRepTerritory.put(ota.ObjectId,ota.Territory2Id);
        }
        return accountSalesRepTerritory;
    }     
 
    /**
     * Get the Id of the Active Territory Model.
     * If none exists, return null.
     */
     @TestVisible
    private Id getActiveModelId() {
        List<Territory2Model> models = [Select Id from Territory2Model where State = 'Active'];
        Id activeModelId = null;
        if(models.size() == 1){
            activeModelId = models.get(0).Id;
        }
        return activeModelId;
    }
}