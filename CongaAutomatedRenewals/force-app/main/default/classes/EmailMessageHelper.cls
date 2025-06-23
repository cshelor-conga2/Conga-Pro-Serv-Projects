/**
* @author Systemyc
* @date 20180219
* @version 1.00
* @description Helper class form EmailMessage object.
*/
public with sharing class EmailMessageHelper {
    public static final string negotiationLegalStatus = 'Negotiation - Legal';
    public static final string negotiationCustomerStatus = 'Negotiation - Customer';
    public static final string rejectedStatus = 'Rejected';
    private static final string mailToAddressSuffix = '@na1mail.congacontracts.com';
    private static final string subjectPrefix = 'RE:';

    /**
    * @description updateQuoteStatus - Helper class form EmailMessage object.
    *                                   --- EXECUTED FROM EMAIL MESSAGE AFTER INSERT TRIGGER ---
    * @param List<EmailMessage> newMessages
    * @return void
    */
    public static void updateQuoteStatus(List<EmailMessage> newMessages){
        try{
            //Check for "EmailMessage.updateQuoteStatus" value in "Trigger Settings" custom settings.
            if(TriggerHelper.DoExecute('EmailMessageHelper','updateQuoteStatus') && newMessages != null){
                String quotePrefix = Schema.SObjectType.SBQQ__Quote__c.getKeyPrefix();
                List<EmailMessage> qualifiedEmails = new List<EmailMessage>();
                for(EmailMessage message : newMessages){
                    if(message.RelatedToId <> null && message.Incoming <> null && message.ToAddress <> null && message.Subject <> null){
                        if(String.valueOf(message.RelatedToId).startsWith(quotePrefix) && message.Incoming && message.Subject.startsWith(subjectPrefix) && (message.ToAddress.contains(mailToAddressSuffix) || message.CcAddress.endsWith(mailToAddressSuffix))){                                                        
                            qualifiedEmails.add(message);
                        }
                    }
                }

                if(!qualifiedEmails.isEmpty()){
                    //Extract SBQQ__Status__c object Id's related to mail messages.
                    List<Id> quoteIds = new List<Id>();
                    for(EmailMessage message : qualifiedEmails){
                        if(message.RelatedToId <> null){
                            quoteIds.add(message.RelatedToId);
                        }
                    }

                    //Select SBQQ__Status__c records for update.
                    if(quoteIds.size() > 0){
                        RecordType recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Draft' AND SObjectType = 'SBQQ__Quote__c']; //'0125000000021ec'
                        List<SBQQ__Quote__c> quotesToUpdate = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c 
                                                               WHERE Id IN :quoteIds AND SBQQ__Status__c <> :negotiationLegalStatus AND RecordTypeId = :recordType.Id];

                        for(SBQQ__Quote__c quote : quotesToUpdate){
                            quote.SBQQ__Status__c = negotiationLegalStatus;
                        }

                        if(!quotesToUpdate.isEmpty()){
                            update quotesToUpdate;
                        } 
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('EmailMessageHelper','updateQuoteStatus');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('EmailMessageHelper', 'updateQuoteStatus', newMessages, ex, true);
        }
    }


}