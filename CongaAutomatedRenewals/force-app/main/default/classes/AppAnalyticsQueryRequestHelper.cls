/**
* @author GTM, ERedding
* @date 20201005
* @version 1.00
* @description AppAnalyticsQueryRequestHelper - Custom logic for the AppAnalyticsQueryRequest object
*/
public with sharing class AppAnalyticsQueryRequestHelper {
    
    // PRODUCT METRICS AZURE CUSTOM METADATA SETTINGS
    private static Product_Metrics_Azure_Settings__mdt ProductMetricsAzureSettings {
    get {
        if(ProductMetricsAzureSettings == null){
            for(Product_Metrics_Azure_Settings__mdt settings : [SELECT Id, Endpoint_URL__c, Environment__c, Number_of_Retries_Allowed__c
                                                                FROM Product_Metrics_Azure_Settings__mdt LIMIT 1]){
                ProductMetricsAzureSettings = settings;
            }
        }
        return ProductMetricsAzureSettings;
    } set; }

    /**
    * @description copyCompletedRequestFileToAzure - Trigger method creating a set of ids of completed AppAnalytics Query Requests
    *                                                   ********* EXECUTED BY AppAnalyticsQueryRequest AFTER UPDATE TRIGGER ********
    * @param List<AppAnalyticsQueryRequest> updatedRequests - Updated AppAnalyticsQueryRequest records
    * @param Map<Id, AppAnalyticsQueryRequest> outdatedRequests - Outdated AppAnalyticsQueryRequest records
    * @return void
    */
    public static void copyCompletedRequestFileToAzure(List<AppAnalyticsQueryRequest> updatedRequests, Map<Id, AppAnalyticsQueryRequest> outdatedRequests){
        try{
            if(TriggerHelper.DoExecute('AppAnalyticsQueryRequestHelper','copyCompletedRequestFileToAzure') && updatedRequests != null && outdatedRequests != null){

                // GET UPDATED REQUESTS THAT ARE NOW MARKED AS COMPLETE AND HAVE A DOWNLOAD URL
                Set<Id> qualifiedRequestIds = new Set<Id>();
                for(AppAnalyticsQueryRequest updatedRequest : updatedRequests){
                    AppAnalyticsQueryRequest outdatedRequest = outdatedRequests != null ? outdatedRequests.get(updatedRequest.Id) : null;
                    if(outdatedRequest != null && updatedRequest.RequestState != outdatedRequest.RequestState && updatedRequest.RequestState == 'Complete' && String.isNotBlank(updatedRequest.DownloadUrl)){
                        qualifiedRequestIds.add(updatedRequest.Id);
                    }
                }

                // SEND QUALIFYING DOCUMENTS TO FUTURE METHOD
                if(!qualifiedRequestIds.isEmpty()){
                    AppAnalyticsQueryRequestHelper.copyCompletedRequestFileToAzureAPI(qualifiedRequestIds);               
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AppAnalyticsQueryRequestHelper', 'copyCompletedRequestFileToAzure');
            }
        }   
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AppAnalyticsQueryRequestHelper', 'copyCompletedRequestFileToAzure', updatedRequests, ex, true);
        }
    }

    /**
    * @description copyCompletedRequestFileToAzure - Future method with HTTP callouts that gathers completed AppAnalytics Query Requests and uploading them to Azure
    * @param List<AppAnalyticsQueryRequest> updatedRequests - Updated AppAnalyticsQueryRequest records
    * @param Map<Id, AppAnalyticsQueryRequest> outdatedRequests - Outdated AppAnalyticsQueryRequest records
    * @return void
    */
    @future(callout=true)
    public static void copyCompletedRequestFileToAzureAPI(Set<Id> qualifiedRequestIds){
        try{
            if(qualifiedRequestIds != null && ProductMetricsAzureSettings != null && String.isNotBlank(ProductMetricsAzureSettings.Endpoint_URL__c) &&
                String.isNotBlank(ProductMetricsAzureSettings.Environment__c) && ProductMetricsAzureSettings.Number_of_Retries_Allowed__c != null){
                
                List<AppAnalyticsQueryRequest> completedRequestsWithFiles = new List<AppAnalyticsQueryRequest>();
                if(Test.isRunningTest()){
                    // USE DATA FROM TEST CLASS DURING A TEST 
                    completedRequestsWithFiles = AppAnalyticsQueryRequestHelperTest.CompletedTestRequests;
                }
                else{
                    for(AppAnalyticsQueryRequest request : [SELECT Id, RequestState, DataType, OrganizationIds, PackageIds, StartTime, DownloadUrl, DownloadSize
                                                            FROM AppAnalyticsQueryRequest
                                                            WHERE Id IN :qualifiedRequestIds AND RequestState = 'Complete']){
                        if(String.isNotBlank(request.DownloadUrl)){
                         	completedRequestsWithFiles.add(request);
                        }
                    }
                }

                for(AppAnalyticsQueryRequest request : completedRequestsWithFiles){
                    Integer attemptsAllowed = (Integer)ProductMetricsAzureSettings.Number_of_Retries_Allowed__c + 1; // NUMBER OF RETRIES + THE INITIAL ATTEMPT
                    String orgIdValue = String.isNotBlank(request.OrganizationIds) ? request.OrganizationIds : 'ALLORGS';
                    String packageIdValue = String.isNotBlank(request.PackageIds) ? request.PackageIds : 'ALLPACKAGES';

                    // GET DATATYPE AND CREATE FILE NAME
                    String datatype = (request.DataType.contains('Summary') ? 'Summary' : request.DataType.contains('Log') ? 'Detail' : request.DataType.contains('Snapshot') ? 'Snapshot' : 'Other');
                    String filename = String.format('{0}|{1}|{2}|{3}|{4}.csv', new List<String>{ 'C1', datatype, String.valueOf(request.StartTime.dateGMT()), orgIdValue, packageIdValue });

                    ///////////////////////////////////////////////////////////////////////////////////////////////
                    //////////////////////// SEND FILENAME AND DOWNLOAD URL TO AZURE SCRIPT ///////////////////////
                    ///////////////////////////////////////////////////////////////////////////////////////////////
                    Http http = new Http();
                    HttpRequest httpRequest = new HttpRequest();
                    httpRequest.setTimeout(120000);
                    httpRequest.setMethod('GET');
                    httpRequest.setEndpoint(String.format(ProductMetricsAzureSettings.Endpoint_URL__c, new List<String>{ filename, EncodingUtil.urlEncode(request.DownloadUrl, 'UTF-8'), ProductMetricsAzureSettings.Environment__c }));

                    // SEND REQUEST AND RETRY IF NECCESARY
                    for(Integer sendAttempts = 1; sendAttempts <= attemptsAllowed; sendAttempts++){
                        HttpResponse azureResponse = http.send(httpRequest);
                        if(azureResponse.getStatusCode() < 200 || azureResponse.getStatusCode() >= 400){
                            if(sendAttempts < attemptsAllowed){
                                // ERROR, ATTEMPTS REMAIN, ALLOW LOOP TO CONTINUE
                                continue;
                            }
                            else if(sendAttempts == attemptsAllowed){
                                // ERROR, NO ATTEMPTS REMAIN, LOG ERROR
                                String httpErrorInfo = 'HTTP Error: ' + azureResponse.getStatusCode() + ' ' + azureResponse.getStatus() + ' - ' + azureResponse.getBody();
                                SystemIssueLogHelper.LogException('AppAnalyticsQueryRequestHelper', 'copyCompletedRequestFileToAzure', qualifiedRequestIds, httpErrorInfo, true);
                            }
                        }
                        break;
                    }
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AppAnalyticsQueryRequestHelper', 'copyCompletedRequestFileToAzure', qualifiedRequestIds, ex, true);
        }
    }


}