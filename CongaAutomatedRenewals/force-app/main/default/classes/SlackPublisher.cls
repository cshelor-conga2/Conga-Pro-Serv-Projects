/**
* @author Conga Product, Sheing Ng
* @date 20191213
* @version 1.00
* @description SlackPublisher - Custom logic for publishing to Slack
*/
public with sharing class SlackPublisher {
    public class Payload {
        @InvocableVariable(label='Slack Webhook URL')
        public String slackURL;
        @InvocableVariable(label='Message Text')
        public String messageText;
        @InvocableVariable(label='Field 1 Name')
        public String field1Name;
        @InvocableVariable(label='Field 1 Value')
        public String field1Value;
        @InvocableVariable(label='Field 2 Name')
        public String field2Name;
        @InvocableVariable(label='Field 2 Value')
        public String field2Value;
        @InvocableVariable(label='Field 3 Name')
        public String field3Name;
        @InvocableVariable(label='Field 3 Value')
        public String field3Value;
        @InvocableVariable(label='Field 4 Name')
        public String field4Name;
        @InvocableVariable(label='Field 4 Value')
        public String field4Value;
        @InvocableVariable(label='Linked Record ID')
        public String recordId;
        @InvocableVariable(label='Record Name')
        public String recordName;
        @InvocableVariable(label='Slack Bot')
        public String slackBot;
        @InvocableVariable(label='Channel')
        public String channel;
        @InvocableVariable(label='Slack Emoji')
        public String slackEmoji;
 		@InvocableVariable(label='Slack Icon URL')
        public String iconUrl;
    }
     
    @InvocableMethod(label='Post to Slack')
    public static void postToSlack(List<Payload> payloads) {
        try{
            Payload p = payloads[0]; 
            Map<String,Object> msg = new Map<String,Object>();
            String messageText = p.messageText + '\n>>>';

            if(!String.isBlank(p.field1Name) && !String.isBlank(p.field1Value)) {
                messageText += '\n*' + p.field1Name + ':* ' + p.field1Value;
            }

            if(!String.isBlank(p.field2Name) && !String.isBlank(p.field2Value)) {
                messageText += '\n*' + p.field2Name + ':* ' + p.field2Value;
            }

            if(!String.isBlank(p.field3Name) && !String.isBlank(p.field3Value)) {
                messageText += '\n*' + p.field3Name + ':* ' + p.field3Value;
            }

            if(!String.isBlank(p.field4Name) && !String.isBlank(p.field4Value)) {
                messageText += '\n*' + p.field4Name + ':* ' + p.field4Value;
            }

            if(!String.isBlank(p.recordId) && !String.isBlank(p.recordName)) {
                messageText += '\n*Link:* <' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + p.recordId + '|' + p.recordName + '>';
            }
            else if(!String.isBlank(p.recordId)) {
                messageText += '\n*Link:* <' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + p.recordId + '>';
            }
            msg.put('text', messageText);
            
            if(!String.isBlank(p.slackBot)){
                msg.put('username', p.slackBot);
            }
            
            if(!String.isBlank(p.channel)){
                msg.put('channel', p.channel);
            }
            
            if(!String.isBlank(p.slackEmoji)){
                msg.put('icon_emoji', p.slackEmoji);
            }
                
            if(!String.isBlank(p.iconUrl) && String.isBlank(p.slackEmoji)){
                msg.put('icon_url', p.iconUrl);
            }
              
            msg.put('mrkdwn', true);
            String body = JSON.serialize(msg);    
            System.enqueueJob(new QueueableSlackCall(p.slackURL, 'POST', body));
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SlackPublisher', 'postToSlack', null, ex, true);
        }
    }

    public class QueueableSlackCall implements System.Queueable, Database.AllowsCallouts {
        private final String url;
        private final String method;
        private final String body;
         
        public QueueableSlackCall(String url, String method, String body) {
            this.url = url;
            this.method = method;
            this.body = body;
        }
         
        public void execute(System.QueueableContext ctx) {
            try{
                HttpRequest req = new HttpRequest();
                req.setEndpoint(url);
                req.setMethod(method);
                req.setBody(body);
                Http http = new Http();
                if(!Test.isRunningTest()) {
                    HttpResponse res = http.send(req);
                }
            }
            catch(Exception ex){
                SystemIssueLogHelper.LogException('QueueableSlackCall', 'execute', null, ex, true);
            }
        }
    }


}