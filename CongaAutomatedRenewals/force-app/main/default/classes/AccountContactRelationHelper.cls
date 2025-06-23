/**
* @author ECS, ERedding
* @date 20200501
* @version 1.00
* @description AccountContactRelationHelper - Custom functionality for the AccountContactRelation object
*/
public with sharing class AccountContactRelationHelper {

    /**
    * @description removeDepartedFromPrimaryRoles - 
    * @param List<AccountContactRelation> updatedRelations - Updated Contact records
    * @param Map<Id, AccountContactRelation> outdatedRelations - Outdated Contact records
    * @return void
    */
    public static void removeDepartedFromPrimaryRoles(List<AccountContactRelation> updatedRelations, Map<Id, AccountContactRelation> outdatedRelations){
        try{        
            if(TriggerHelper.DoExecute('AccountContactRelationHelper','removeDepartedFromPrimaryRoles') && updatedRelations != null){
                // GET IDS OF CONTACTS WITH QUALIFYING AccountContactRelation CHANGES
                List<Id> qualifyingContactIds = new List<Id>();
                for(AccountContactRelation updatedRelation : updatedRelations){
                    AccountContactRelation outdatedRelation = outdatedRelations != null ? outdatedRelations.get(updatedRelation.Id) : null;
                    if(outdatedRelation != null && updatedRelation.Status__c == 'No Longer at Company' && updatedRelation.Status__c != outdatedRelation.Status__c){
                        if(Trigger.isBefore && updatedRelation.IsPrimary__c){
                        	// BEFORE UPDATE TRIGGER, REMOVE PRIMARY FLAG
                        	updatedRelation.IsPrimary__c = false;
                        }
                        else if(Trigger.isAfter){
                        	// AFTER UPDATE TRIGGER, ADD CONTACT ID TO SET
                        	qualifyingContactIds.add(updatedRelation.ContactId);
                        }
                    }
                }

                if(!qualifyingContactIds.isEmpty()){
                
                	// GET ACCOUNT CONTACT RELATIONS THAT ARE PRIMARY AND REMOVE FLAG
                	List<OpportunityContactRole> accountContactRelationsToUpdate = new List<OpportunityContactRole>();
                	for(OpportunityContactRole oppContactRole : [SELECT Id, IsPrimary FROM OpportunityContactRole WHERE ContactId IN :qualifyingContactIds AND IsPrimary = true]){
                		oppContactRole.IsPrimary = false;
                		accountContactRelationsToUpdate.add(oppContactRole);
                	}

                	if(!accountContactRelationsToUpdate.isEmpty()){
                        Database.saveResult[] updateResults = Database.update(accountContactRelationsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'AccountContactRelationHelper', 'removeDepartedFromPrimaryRoles', true);
                	}
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AccountContactRelationHelper', 'removeDepartedFromPrimaryRoles');
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('AccountContactRelationHelper', 'removeDepartedFromPrimaryRoles', updatedRelations, ex, true);
        }
    }


}