/** 
* @author ECS, ERedding
* @date 20191114
* @version 1.00
* @description Batchable_BulkDMLProcessor - Batch class that can insert, update, or delete a specified list of SObjects in chunks
*/
public class Batchable_BulkDMLProcessor implements Database.Batchable<sObject> {
	private final List<SObject> RecordsToProcess;
	private final String DMLAction;

	/** 
	* @description Constructor with Parameters
	*/
	public Batchable_BulkDMLProcessor(List<SObject> pRecordsToProcess, String pDMLAction) {
		RecordsToProcess = pRecordsToProcess;
		DMLAction = pDMLAction.toLowerCase();
	}
	
	/** 
	* @description start - Get records to process
	*/
	public List<SObject> start(Database.BatchableContext context) {
		return RecordsToProcess;
	}

	/** 
	* @description Logic to be performed on scope
	*/
   	public void execute(Database.BatchableContext context, List<sObject> scope) {
		try{
			if(!scope.isEmpty()){
				if(DMLAction == 'insert'){
					Database.SaveResult[] insertResults = Database.insert(scope, false);
					SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'Batchable_BulkDMLProcessor', 'execute', false);
				}
				else if(DMLAction == 'update'){
					Database.SaveResult[] updateResults = Database.update(scope, false);
					SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'Batchable_BulkDMLProcessor', 'execute', false);
				}
				else if(DMLAction == 'delete'){
					Database.DeleteResult[] deleteResults = Database.delete(scope, false);
					SystemIssueLogHelper.CheckForDatabaseErrors(deleteResults, 'Batchable_BulkDMLProcessor', 'execute', false);
				}
				else{
					SystemIssueLogHelper.LogException('Batchable_BulkDMLProcessor', 'execute', scope, 'Unknown DML action specified. Must be Insert, Update, or Delete.', false);
					System.abortJob(context.getJobId());
				}

				// SAVE ANY ERRORS
				SystemIssueLogHelper.UpsertExceptions();
			}
		}
		catch(Exception ex){ 
			SystemIssueLogHelper.LogException('Batchable_BulkDMLProcessor', 'execute', scope, ex, true);
		}
	}
	
	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		if(!RecordsToProcess.isEmpty()){
			System.debug('BulkDMLProcessor complete. ' + RecordsToProcess.size() + ' records ' + (DMLAction == 'insert' ? 'created' : DMLAction == 'update' ? ' updated' : DMLAction == 'delete' ? ' deleted' : ''));
		}
		else{
			System.debug('BulkDMLProcessor complete. No records specified.');
		}
	}


}