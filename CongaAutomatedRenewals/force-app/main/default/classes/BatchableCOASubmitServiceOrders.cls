/** 
* @author Conga Services
* @date 
* @version 1.00
* @description BatchableCOASubmitServiceOrders - [Description]
*/
public class BatchableCOASubmitServiceOrders implements Database.Batchable<sObject> {
	private final Set<Id> ServiceOrderIds {get; set;}

	/** 
	* @description BatchableCOASubmitServiceOrders - Constructor
	*/
	public BatchableCOASubmitServiceOrders(Set<Id> pServiceOrderIds) {
		ServiceOrderIds = pServiceOrderIds;
	}
	
	/** 
	* @description start - Define what the scope is going to be
	*/
	public Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator([SELECT Id FROM CHANNEL_ORDERS__Service_Order__c WHERE Id IN :ServiceOrderIds]);
	}

	/** 
	* @description execute - Logic to be performed on scope
	*/
   	public void execute(Database.BatchableContext context, List<CHANNEL_ORDERS__Service_Order__c> scope) {
		try{
			// GATHER ORDERS TO SUBMIT
			List<CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitInput> serviceOrderSubmitInput = new List<CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitInput>();
			for(CHANNEL_ORDERS__Service_Order__c serviceOrder: scope){
				CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitInput input = new CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitInput();
				input.serviceOrderId = serviceOrder.Id;
				serviceOrderSubmitInput.add(input);
			}

			// SUBMIT ORDERS
			List<CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitOutput> serviceOrderSubmitOutputs = CHANNEL_ORDERS.COA_ServiceOrderSubmit.submit(serviceOrderSubmitInput);

			// READ RESULTS AND UPDATE ORDERS
			for(CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitOutput serviceOrderSubmitOutput : serviceOrderSubmitOutputs){
				for(CHANNEL_ORDERS__Service_Order__c serviceOrder : scope){
					if(serviceOrderSubmitOutput.serviceOrderId == serviceOrder.Id){

						// SUCCESS
						if(serviceOrderSubmitOutput.isSuccess){
							serviceOrder.CHANNEL_ORDERS__Service_Order_Status__c = 'Received';
						}
						// ERROR						
						else{
							System.debug(serviceOrderSubmitOutput.serviceOrderId);
							System.debug(serviceOrderSubmitOutput.isSuccess);
							System.debug(serviceOrderSubmitOutput.responseMessages);

							// GET ANY RESPONSE MESSAGES
							String messages = '';
							if(serviceOrderSubmitOutput.responseMessages != null && !serviceOrderSubmitOutput.responseMessages.isEmpty()){
								for(String message : serviceOrderSubmitOutput.responseMessages){
									messages += message + ', ';
								}
								messages = messages.left(messages.length()-2);
								messages = messages.left(255);
							}
							serviceOrder.CHANNEL_ORDERS__Service_Order_Status__c = 'Error';
							serviceOrder.CHANNEL_ORDERS__Error_Comment__c = messages;
						}
					}
				}
			}

			if(!scope.isEmpty()){
				Database.SaveResult[] updateResults = Database.update(scope, false);
				SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'BatchableCOASubmitServiceOrders', 'execute', true);
			}
		}
		catch(Exception ex){ 
			SystemIssueLogHelper.LogException('BatchableCOASubmitServiceOrders', 'execute', scope, ex, true);
		}
	}
	
	/** 
	* @description finish - Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		System.debug('Batch Apex BatchableCOASubmitServiceOrders completed for these Service Orders: ' + ServiceOrderIds);
	}


}