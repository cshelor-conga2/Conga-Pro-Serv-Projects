/**
* @author ECS, ERedding
* @date 20190627
* @version 1.00
* @description CustomerSuccessHelper - Customer functionality for the Customer_Success__c object
*/
public with sharing class CustomerSuccessHelper {

	/**
	* @description updateXCareCheckbox - Updates the X-Care checkbox on Customer Success records depending on 
	* @param List<Customer_Success__c> updatedCSRecords
	* @param Map<Id, Customer_Success__c> outdatedCSRecords
	* @return void
	*/
	public static void updateXCareCheckbox(List<Customer_Success__c> updatedCSRecords, Map<Id, Customer_Success__c> outdatedCSRecords){
		try{
			if(TriggerHelper.DoExecute('CustomerSuccessHelper','updateXCareCheckbox') && updatedCSRecords != null && outdatedCSRecords != null){

				// GET IDS OF QUALIFIED CUSTOMER SUCCESS RECORDS
				Set<Id> qualifiedCSIds = new Set<Id>();
				for(Customer_Success__c updatedCSRecord : updatedCSRecords){
					Customer_Success__c outdatedCSRecord = outdatedCSRecords != null ? outdatedCSRecords.get(updatedCSRecord.Id) : null;
					if(outdatedCSRecord != null && (updatedCSRecord.Customer_Likely_To__c != outdatedCSRecord.Customer_Likely_To__c || 
													updatedCSRecord.License_Utilization__c != outdatedCSRecord.License_Utilization__c)){
						qualifiedCSIds.add(updatedCSRecord.Id);
					}
				}
			
				if(!qualifiedCSIds.isEmpty()){
					// GET IDS OF CUSTOMER SUCCESS RECORDS THAT HAVE CHILD ACCOUNTS THAT ARE DIVISION 4 OR DIVISION 5
					Set<Id> csRecordsWithDiv4Or5 = new Set<Id>();
					for(Account account : [SELECT Id, Customer_Success__c FROM Account WHERE Customer_Success__c IN :qualifiedCSIds AND CS_Division_Stamp__c IN ('Division 4','Division 5')]){
						csRecordsWithDiv4Or5.add(account.Customer_Success__c);
					}

					// RELOAD RECORDS FROM THE DATABASE TO PULL UPDATED FORMULA VALUES AND MAKE NECESSARY UPDATES
					List<Customer_Success__c> successRecordsToUpdate = new List<Customer_Success__c>();
					for(Customer_Success__c cs : [SELECT Id, Customer_Health_Total__c, X_Care__c FROM Customer_Success__c WHERE Id IN :qualifiedCSIds]){
						if(!cs.X_Care__c && csRecordsWithDiv4Or5.contains(cs.Id) && cs.Customer_Health_Total__c <= 4){
							successRecordsToUpdate.add(new Customer_Success__c(Id = cs.Id, X_Care__c = true));
						}
						else if(cs.X_Care__c && cs.Customer_Health_Total__c >= 5){
							successRecordsToUpdate.add(new Customer_Success__c(Id = cs.Id, X_Care__c = false));
						}
					}

					if(!successRecordsToUpdate.isEmpty()){
						// SAVE RECORDS AND CATCH ANY ERRORS
                        Database.saveResult[] csResults = Database.update(successRecordsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(csResults, 'CustomerSuccessHelper', 'updateXCareCheckbox', true);
					}
				}

				// END AUDIT IF ONE IS STARTED
				TriggerHelper.EndExecute('CustomerSuccessHelper','updateXCareCheckbox');
			}
		}	
		catch(Exception ex){
			SystemIssueLogHelper.LogException('CustomerSuccessHelper', 'updateXCareCheckbox', updatedCSRecords, ex, true);
		}		
	}


}