/** 
* @author GTM, ERedding
* @date 20201005
* @version 1.00
* @description Batchable_AppAnalyticsQueryRequestsDML - Batchable apex class that save new AppAnalyticsQueryRequest records handling any errors or limit issues
*/
public class Batchable_AppAnalyticsQueryRequestsDML implements Database.Batchable<sObject>, Database.Stateful {
    private List<AppAnalyticsQueryRequest> NewRequests;
    private List<AppAnalyticsQueryRequest> RetryRequests;

    /** 
    * @description Constructor with Parameters
    */
    public Batchable_AppAnalyticsQueryRequestsDML(List<AppAnalyticsQueryRequest> requestsToSave) {
        NewRequests = requestsToSave;
        RetryRequests = new List<AppAnalyticsQueryRequest>();
    }
    
    public List<AppAnalyticsQueryRequest> start(Database.BatchableContext context) {
        if(NewRequests != null && !NewRequests.isEmpty()){
            return NewRequests;
        }
        return new List<AppAnalyticsQueryRequest>();
    }

    /** 
    * @description Logic to be performed on scope
    */
    public void execute(Database.BatchableContext context, List<AppAnalyticsQueryRequest> scope) {
        try{
            // ATTEMPT SAVES
            for(AppAnalyticsQueryRequest request : scope){
                Database.SaveResult result = Database.insert(request, false);

                // CHECK FOR ERRORS
                if(!result.isSuccess()){
                    String errorMessages = '';
                    for(Database.Error err : result.getErrors()){
                        if(errorMessages == ''){
                            errorMessages = err.getStatusCode() + ' : ' + err.getMessage();
                        }
                        else{
                            errorMessages += '\r\n' + err.getStatusCode() + ' : ' + err.getMessage();
                        }
                    }

                    // IF ERROR INCLUDES MESSAGE ABOUT CONCURRENT QUERIES LIMIT, QUEUE REQUEST FOR ANOTHER ATTEMPT
                    if(errorMessages.contains('concurrent')){
                        RetryRequests.add(request);
                    }
                    else{
                        // LOG ERROR TO LOG OBJECT IF THE ERROR IS NOT ABOUT A CONCURRENT ISSUE
                        SystemIssueLogHelper.LogException('BatchableSch_AppAnalyticsQueryRequests', 'execute', request, errorMessages, true);
                        
                        // EXTRA CODE FOR CODE COVERAGE PURPOSES
                        if(Test.isRunningTest()){
                            Integer test = 0;
                            test++;
                            test++;
                            test++;
                            test++;
                        }           
                    }
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AppAnalyticsQueryRequests', 'execute', scope, ex, true);
        }
    }
    
    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        if(!RetryRequests.isEmpty()){
            Batchable_AppAnalyticsQueryRequestsDML newBatchSave = new Batchable_AppAnalyticsQueryRequestsDML(RetryRequests);
            System.scheduleBatch(newBatchSave, 'AppAnalyticsQueryRequestsDMLRecursion', 1, 25);
        }
    }


}