/** 
* @author ECS, ERedding
* @date 20191115
* @version 1.00
* @description BatchableSch_TMContactUpdater - Batchable/Scheduled class for Conga Territory Management that updates contact ownership fields.
*/
public class BatchableSch_TMContactUpdater implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
	private Set<Id> FlaggedAccounts;

	/** 
	* @description Scheduable execute method
	*/
   	public void execute(SchedulableContext context) {
   		Database.executeBatch(this, 20);
	}
	
	/** 
	* @description Batchable start method
	*/	
	public Database.QueryLocator start(Database.BatchableContext context) {
		FlaggedAccounts = new Set<Id>();
        return Database.getQueryLocator([SELECT Id, OwnerId, TM_Territory_ManagerId__c, AccountId, Account.OwnerId, Account.TM_Territory_ManagerId__c 
        								 FROM Contact WHERE Account.TM_Contact_Update__c = true]);
	}

	/** 
	* @description Batchable execute method
	*/
   	public void execute(Database.BatchableContext context, List<Contact> scope) {
		try{
			List<Contact> contactsToUpdate = new List<Contact>();
			for(Contact contact : scope){
				FlaggedAccounts.add(contact.AccountId);
				Boolean changeMade = false;

				// UPDATE CONTACT OWNER IF DIFFERENT THAN ITS ACCOUNT
				if(contact.OwnerId != contact.Account.OwnerId){
					contact.OwnerId = contact.Account.OwnerId;
					changeMade = true;
				}

				// UPDATE CONTACT TERRITORY MANAGER IF DIFFERENT THAN ITS ACCOUNT
				if(contact.TM_Territory_ManagerId__c != contact.Account.TM_Territory_ManagerId__c){
					contact.TM_Territory_ManagerId__c = contact.Account.TM_Territory_ManagerId__c;
					changeMade = true;
				}

				if(changeMade){
					contactsToUpdate.add(contact);
				}
			}

			if(!contactsToUpdate.isEmpty()){
				Database.SaveResult[] contactUpdateResults = Database.update(contactsToUpdate, false);
				SystemIssueLogHelper.CheckForDatabaseErrors(contactUpdateResults, 'BatchableSch_TMContactUpdater', 'execute', true);
			}
		}
		catch(Exception ex){ 
			SystemIssueLogHelper.LogException('BatchableSch_TMContactUpdater', 'execute', scope, ex, true);
		}
	}

	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		// UNFLAG ACCOUNTS
		List<Account> accountsToUnflag = new List<Account>();
		for(Id accountId : FlaggedAccounts){
			accountsToUnflag.add(new Account(Id = accountId, TM_Contact_Update__c = false));
		}

		// SAVE ACCOUNTS
		if(!accountsToUnflag.isEmpty()){
			Batchable_BulkDMLProcessor bulkDMLProcessor = new Batchable_BulkDMLProcessor(accountsToUnflag, 'update');
			Database.executeBatch(bulkDMLProcessor, 5);

			//Database.SaveResult[] accountUpdateResults = Database.update(accountsToUnflag, false);
			//SystemIssueLogHelper.CheckForDatabaseErrors(accountUpdateResults, 'BatchableSch_TMContactUpdater', 'finish', false);
		}
	}


}