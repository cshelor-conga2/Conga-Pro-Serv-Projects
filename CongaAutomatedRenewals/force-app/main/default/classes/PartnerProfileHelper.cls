/**
* @author ECS, ERedding
* @date 20190603
* @version 1.00
* @description PartnerProfileHelper - Custom functionality for the Partner_Profile__c object
*/
public with sharing class PartnerProfileHelper {

	/**
	* @date 20200116
	* @description updatePartnerProfileName - Updates the name of new Partner Profiles or updated Partner Profiles where the record type has changed.
	* @param List<Partner_Profile__c> newOrUpdatedPPs
	* @param Map<Id, Partner_Profile__c> outdatedPPs	
	* @return void
	*/
	public static void updatePartnerProfileName(List<Partner_Profile__c> newOrUpdatedPPs, Map<Id, Partner_Profile__c> outdatedPPs){
		try{
			if(TriggerHelper.DoExecute('PartnerProfileHelper','updatePartnerProfileName') && newOrUpdatedPPs != null){
				// GET RECORD TYPES FOR PARTNER PROFILE OBJECT
				Map<Id, Schema.RecordTypeInfo> recordTypesById = Schema.getGlobalDescribe().get('Partner_Profile__c').getDescribe().getRecordTypeInfosById();

				// GET ACCOUNT IDS
				Set<Id> accountsIds = new Set<Id>();
				for(Partner_Profile__c newOrUpdatedPP : newOrUpdatedPPs){
					accountsIds.add(newOrUpdatedPP.Account__c);
				}

				// GET ACCOUNTS
				Map<Id, Account> parentAccounts = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :accountsIds]);

				// SET NAMES ON NEW RECORDS
				for(Partner_Profile__c newOrUpdatedPP : newOrUpdatedPPs){
					Partner_Profile__c outdatedPP = outdatedPPs != null ? outdatedPPs.get(newOrUpdatedPP.Id) : null;
					if(outdatedPP == null || newOrUpdatedPP.RecordTypeId != outdatedPP.RecordTypeId){
				    	if(recordTypesById.containsKey(newOrUpdatedPP.RecordTypeId) && parentAccounts.containsKey(newOrUpdatedPP.Account__c)){
				    		newOrUpdatedPP.Name = (parentAccounts.get(newOrUpdatedPP.Account__c).Name + ' - ' + recordTypesById.get(newOrUpdatedPP.RecordTypeId).Name);
				    	}
					}
			    }

			    // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('PartnerProfileHelper', 'updatePartnerProfileName');
			}
		}
		catch(Exception ex){
			SystemIssueLogHelper.LogException('PartnerProfileHelper', 'updatePartnerProfileName', newOrUpdatedPPs, ex, true);
		}
	}

	/**
	* @description updateActivePartnerProfile - Standardized and bulkified version translated from the old PPIdOnAccount2 trigger.
	* @param List<Partner_Profile__c> outdatedPartnerProfiles
	* @return void
	*/
	public static void updateActivePartnerProfile(List<Partner_Profile__c> outdatedPartnerProfiles){
		try{
			if(TriggerHelper.DoExecute('PartnerProfileHelper','updateActivePartnerProfile') && outdatedPartnerProfiles != null){
				// GET QUALIFIED PP RECORDS
			    List<String> ppRecordIds = new List<String>();
				for(Partner_Profile__c pp : outdatedPartnerProfiles){                    
			        if(pp.Retired__c == false){
			            ppRecordIds.add(pp.Id);       
			        }
			    }

			    // GET LATEST VERSIONS OF PP RECORDS AND PARENT ACCOUNTS
				Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
			    if(!ppRecordIds.isEmpty()){
				    // GET LATEST VERSIONS OF PP RECORDS
				    for(Partner_Profile__c ppRecord : [SELECT Id, Account__c FROM Partner_Profile__c WHERE IsDeleted = false AND Id = :ppRecordIds]){
				    	if(ppRecord.Account__c != null && !accountsToUpdate.containsKey(ppRecord.Account__c)){
							accountsToUpdate.put(ppRecord.Account__c, new Account(Id = ppRecord.Account__c, Active_Partner_Profile_Record_Id__c = ppRecord.Id, Active_Partner_Profile__c = ppRecord.Id));
			    		}
				    }

				    // SAVE ACCOUNTS TO DATABASE
				    if(!accountsToUpdate.isEmpty()){
                        Database.saveResult[] accountResults = Database.update(accountsToUpdate.values(), false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(accountResults, 'PartnerProfileHelper', 'updateActivePartnerProfile', true);
				    }
				}

				// END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('PartnerProfileHelper', 'updateActivePartnerProfile');
			}
		}	
		catch(Exception ex){
			SystemIssueLogHelper.LogException('PartnerProfileHelper', 'updateActivePartnerProfile', outdatedPartnerProfiles, ex, true);
		}
	}


}