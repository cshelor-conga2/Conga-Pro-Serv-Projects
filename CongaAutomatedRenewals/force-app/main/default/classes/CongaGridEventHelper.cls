/**
* @author ECS, ERedding
* @date 20200102
* @version 1.00
* @description CongaGridEventHelper - Custom logic for the Conga_Grid_Event__e Platform Event object
*/
public with sharing class CongaGridEventHelper {

    // CONGA GRID ALERT SETTINGS METADATA
    private static List<Conga_Grid_Export_Alert_Settings__mdt> AlertSettings {
    get {
        if(AlertSettings == null){
            AlertSettings = [SElECT Export_Number_Threshold__c, Slack_Endpoint__c FROM Conga_Grid_Export_Alert_Settings__mdt LIMIT 1];
        }
        return AlertSettings;
    } set; }


    /**
    * @author ECS, ERedding; Conga Product, Sheing Ng
    * @description postEventToSlack - Creates a Slack post when specific Conga Grid Events occur
    *                             				 --- EXECUTED BY ACCOUNT AFTER INSERT ---
    * @param List<Conga_Grid_Event__e> newCongaGridEvents - List of new or updated Conga Grid Event records
    * @return void
    */
    public static void postEventToSlack(List<Conga_Grid_Event__e> newCongaGridEvents){
        try{
            if(TriggerHelper.DoExecute('CongaGridEventHelper','postEventToSlack') && newCongaGridEvents != null && !AlertSettings.isEmpty()){
			    for(Conga_Grid_Event__e gridEvent : newCongaGridEvents) {

			    	// POST A NOTIFICATION TO SLACK IF THE EXPORT NUMBER IS GREATER THAN 1000
			        if(gridEvent.ExportNumber__c >= AlertSettings[0].Export_Number_Threshold__c){

			        	// GET CREATED BY USER INFORMATION
			            User user = [SELECT Name FROM User where Id = :gridEvent.CreatedById];

			            // CREATE PAYLOAD FOR SLACK AND CALL POST METHOD
			            SlackPublisher.Payload payload = new SlackPublisher.Payload();
			            payload.slackURL = AlertSettings[0].Slack_Endpoint__c;
			            payload.slackEmoji = ':chunli:';
			            payload.slackBot = 'Conga Grid Salesforce Alarm';
			            payload.messageText = ':warning: WARNING';
			            payload.channel = 'grid-monitoring-alarm';
			            payload.field1Name = 'Export Number';
			            payload.field1Value = String.valueOf(gridEvent.ExportNumber__c);
			            payload.field2Name = 'Export Type';
			            payload.field2Value = gridEvent.ExportType__c;
			            payload.field3Name = 'View Name';
			            payload.field3Value = gridEvent.ViewName__c;
			            payload.field4Name = 'Created By Id';
			            payload.field4Value = user.Name;
			            SlackPublisher.postToSlack(new List<SlackPublisher.Payload>{ payload });
			        }
			    }

			    // END AUDIT IF ONE IS STARTED
			    TriggerHelper.EndExecute('CongaGridEventHelper', 'postEventToSlack');
			}
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('CongaGridEventHelper', 'postEventToSlack', newCongaGridEvents, ex, true);

        }
    }


}