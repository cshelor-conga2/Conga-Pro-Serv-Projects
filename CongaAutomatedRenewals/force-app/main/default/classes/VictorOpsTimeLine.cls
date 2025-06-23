/**
* @author Conga Services, KSears, ERedding
* @date 20200330
* @version 1.00
* @description VictorOpsTimeLine - Code to send cases to victor ops.  From victor ops website.  Is called from CaseHelper/Trigger.
*/
public class VictorOpsTimeLine{

    // VICTOROPS CUSTOM METADATA SETTINGS
    public static VictorOps_Settings__mdt VictorOpsSettings {
    get {
        if(VictorOpsSettings == null){
            for(VictorOps_Settings__mdt settings : [SELECT Id, Endpoint_URL__c, API_Key__c, Routing_Key__c FROM VictorOps_Settings__mdt LIMIT 1]){
                VictorOpsSettings = settings;
            }
        }
        return VictorOpsSettings;
    } set; }

    /**
    * @description caseToVictor - 
    * @param Boolean isRecovery
    * @param String casenumber
    * @param String subject
    * @param String name
    * @param String company
    * @param String description
    * @param String reason
    * @param String email
    * @return void 
    */
    @future(callout=true)
    public static void caseToVictor(Boolean isRecovery, String casenumber, String subject, String name, String company, String product, String description, String reason, String email, Id caseId){
        try{
            // MAKE CALLOUT TO VICTOR OPS
            if(String.isNotBlank(product) && VictorOpsSettings != null && String.isNotBlank(VictorOpsSettings.Endpoint_URL__c) && 
                String.isNotBlank(VictorOpsSettings.API_Key__c) && String.isNotBlank(VictorOpsSettings.Routing_Key__c)){

                String atMessage = 'from: ';
                String issueMessage = ', Case Subject: ';
                String critical = 'critical';
                String recovery = 'recovery';
                String message = 'New SalesForce Case '+ atMessage + UtilityClass.replaceNull(name, email) + issueMessage + UtilityClass.replaceNull(reason, subject);
                
                HttpRequest req = new HttpRequest();
                Http http = new Http();
                req.setEndpoint(String.format(VictorOpsSettings.Endpoint_URL__c, new List<String>{ VictorOpsSettings.API_Key__c, VictorOpsSettings.Routing_Key__c }));
                req.setMethod('POST');

                Map<String, String> data = new Map<String, String>();
                data.put('product', product);
                data.put('message_type', (isRecovery ? recovery : critical));
                data.put('entity_id', casenumber);
                data.put('entity_display_name', 'SalesForce Case Number: ' + casenumber);
                data.put('monitoring_tool', 'SalesForce');
                data.put('state_message', message);
                data.put('Subject', subject);
                data.put('Contact_Name ', name);
                data.put('Company_Name', company);
                data.put('Case_Description', description);
                data.put('Case_Reason', reason);
                data.put('Contact_Email', email);       
                
                String body = JSON.serialize(data);
                req.setBody(body);
                req.setHeader('Content-Type','application/json');
                HTTPResponse victorOpsResponse = http.send(req);

                if(victorOpsResponse.getStatusCode() != 200 && victorOpsResponse.getStatusCode() != 201){
                    // NOT SUCCESSFUL, LOG ERROR 
                    String httpErrorInfo = victorOpsResponse.getStatusCode() + ' ' + victorOpsResponse.getStatus() + ' - ' + victorOpsResponse.getBody();
                    String errorMessage = 'Victor Ops Case could not be created. HTTP Error: ' + httpErrorInfo;
                    SystemIssueLogHelper.LogException('VictorOpsTimeLine', 'caseToVictor', caseId, errorMessage, false);
                }
            }
            else{
                SystemIssueLogHelper.LogException('VictorOpsTimeLine', 'caseToVictor', caseId, 'VictorOps settings are missing.', false);
            }

            // COMMIT ANY ERRORS
            SystemIssueLogHelper.UpsertExceptions();
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('VictorOpsTimeLine', 'caseToVictor', caseId, ex, true);
        }
    }


}