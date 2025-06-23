/**
* @author CustomerZero, RJain
* @date 20210115
* @version 1.00
* @description CampaignHelper - Contains custom functionality for the Campaign object including helper methods and trigger methods
*/
public without sharing class CampaignHelper {

    public static void setApttusIntegrationOwner(List<Campaign> newCampList, Map<Id, Campaign> oldCampigns){
    	try{        
            if(TriggerHelper.DoExecute('CampaignHelper','setApttusIntegrationOwner') && newCampList != null){
            	
		        Set<String> ownerEmails = new Set<String>();
		        List<Campaign> qualifyingCamps = new List<Campaign>();
		        for (Campaign record : newCampList){
		            if (oldCampigns != null && !oldCampigns.isEmpty() ){
		                Campaign oldRecord = oldCampigns.get(record.Id);
		                if (record.A1_Owner_Email__c != oldRecord.A1_Owner_Email__c){
		                    qualifyingCamps.add(record);
		                    ownerEmails.add(record.A1_Owner_Email__c);  
		                }
		            }
		            if ((oldCampigns == null || oldCampigns.isEmpty() ) && record.A1_Owner_Email__c != null ){
		                qualifyingCamps.add(record);
		                ownerEmails.add(record.A1_Owner_Email__c);
		            }
		        }
		        if(!ownerEmails.isEmpty()){
		            Map<String, Id> usersByEmail = new Map<String, Id>();
		            for(User user : [SELECT Id, Email FROM User WHERE Email IN :ownerEmails AND Profile.UserLicense.Name = 'Salesforce']){
		                usersByEmail.put(user.Email, user.Id);
		            }
		            // PROCESS Campaigns
		            for(Campaign record : qualifyingCamps){
		                record.OwnerId = usersByEmail.containsKey(record.A1_Owner_Email__c) ?
		                                 usersByEmail.get(record.A1_Owner_Email__c) : UserInfo.getUserId();
		            }
		        }
		    }

		    // END AUDIT IF ONE IS STARTED
            TriggerHelper.EndExecute('CampaignHelper', 'setApttusIntegrationOwner');
	    }
	    catch(Exception ex){
	        SystemIssueLogHelper.LogException('CampaignHelper', 'setApttusIntegrationOwner', newCampList, ex, true);
	    }
	}


}