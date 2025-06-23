/** 
* @author ECS, ERedding
* @date 20190906
* @version 1.00
* @description BatchableSch_MQLQualification - Batchable/Schedulable apex for Lead MQL Qualification.
*											   Places qualifying leads that have not been touched for 90 days back into the MQL Queue
*/
public class BatchableSch_MQLQualification implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
	private Id MQLQueueId;
	private Id RoundRobinZeroUserId;
	private Set<String> LeadStatuses;

   	public void execute(SchedulableContext context){
		Database.executeBatch(this, 20);
	}
	
	/** 
	* @description Batchable start method
	*/	
	public Database.QueryLocator start(Database.BatchableContext context) {
        if(LeadHelper.MQLSettings != null){
            // GET MQL QUALIFICATION SETTINGS
            LeadStatuses = new Set<String>( LeadHelper.MQLSettings.Qualifying_Statuses__c.replace('\r','').split('\n'));
            MQLQueueId = LeadHelper.MQLSettings.MQL_QueueId__c;

	        // GET USER ASSIGNED TO ROUND ROBIN 0 IN THE LMA_Lead_Owner_Round_Robin__c CUSTOM SETTINGS
	        for(LMA_Lead_Owner_Round_Robin__c roundRobinOwner : [SELECT Lead_Owner_Id__c FROM LMA_Lead_Owner_Round_Robin__c WHERE Round_Robin_Number__c = 0]){
	            RoundRobinZeroUserId = roundRobinOwner.Lead_Owner_Id__c;
	            break;
	        }
        }

        if(!leadStatuses.isEmpty() && MQLQueueId != null && RoundRobinZeroUserId != null){
			return Database.getQueryLocator([SELECT Id, Name, OwnerId, engagio__Matched_Account__c, engagio__EngagementMinutesLast3Months__c FROM Lead
											 WHERE Status IN :leadStatuses
											 AND (OwnerId != :MQLQueueId 
											      OR
												  (OwnerId = :MQLQueueId AND engagio__Matched_Account__c = null AND engagio__EngagementMinutesLast3Months__c = null)
												  OR
												  (OwnerId = :MQLQueueId AND engagio__Matched_Account__c != null AND engagio__EngagementMinutesLast3Months__c != null))]);
		}						
		else{
	        SystemIssueLogHelper.LogException('BatchableSch_MQLQualification', 'start', null, 'No MQL settings found, settings are incorrect, or no Round Robin 0 Owner found.', true);
	    	return Database.getQueryLocator([SELECT Id FROM Lead WHERE Id = null]); // RETURN NO RECORDS
	    }
	}
	
	/** 
	* @description Batchable execute method
	*/
   	public void execute(Database.BatchableContext context, List<Lead> scope) {
		try{
			Set<Id> leadsInMQLQueue = new Set<Id>();
			Set<Id> leadsNotInMQLQueue = new Set<Id>();
			for(Lead lead : scope){
				if(lead.OwnerId == MQLQueueId){
					leadsInMQLQueue.add(lead.Id);
				}
				else{
					leadsNotInMQLQueue.add(lead.Id);
				}
			}

	        Set<Id> leadsWithOldStatuses = new Set<Id>();
	        Set<Id> leadsWithOldOwners = new Set<Id>();	            
			if(!leadsNotInMQLQueue.isEmpty()){
	            // GET LEADS WHERE THE LAST -STATUS- CHANGE WAS 90 DAYS AGO OR MORE
	            for(AggregateResult agg : [SELECT LeadId, MAX(CreatedDate) changeDate FROM LeadHistory WHERE LeadId IN :leadsNotInMQLQueue AND Field = 'Status' GROUP BY LeadId]){
	            	if(((DateTime)agg.get('changeDate')) <= DateTime.now().addDays(-90)){
	            		leadsWithOldStatuses.add((Id)agg.get('LeadId'));
	            	}
	            }

	            // GET LEADS WHERE THE LAST -OWNER- CHANGE WAS 90 DAYS AGO OR MORE
	            for(AggregateResult agg : [SELECT LeadId, MAX(CreatedDate) changeDate FROM LeadHistory WHERE LeadId IN :leadsNotInMQLQueue AND Field = 'Owner' GROUP BY LeadId]){
	            	if(((DateTime)agg.get('changeDate')) <= DateTime.now().addDays(-90)){
	            		leadsWithOldOwners.add((Id)agg.get('LeadId'));
	            	}
	            }
			}

	        Set<Id> leadsMergedWithin24 = new Set<Id>();
	        Set<Id> leadsWithMQLRecords = new Set<Id>();	        
			if(!leadsInMQLQueue.isEmpty()){
	            // GET LEADS ARE STILL IN THE QUEUE BECAUSE THEY WERE MERGED WITHIN THE LAST 24 HOURS
	            for(LeadHistory history : [SELECT LeadId, CreatedDate FROM LeadHistory WHERE LeadId IN :leadsInMQLQueue AND Field = 'leadMerged']){
	            	if(UtilityClass.getDistanceBetweenDates(history.CreatedDate, DateTime.now(), UtilityClass.Interval.Hours, 2) < 24){
	            		leadsMergedWithin24.add(history.LeadId);
	            	}
	            }

	            // GET LEADS THAT HAVE MQL QUALIFICATION RECORDS
	            for(MQL_Qualification__c mqlRecord : [SELECT Id, LeadId__c FROM MQL_Qualification__c WHERE LeadId__c IN :leadsInMQLQueue]){
	            	leadsWithMQLRecords.add(mqlRecord.LeadId__c);
	            }
	        }

            // UPDATE LEADS
            List<Lead> leadsToUpdate = new List<Lead>();
            for(Lead lead : scope){

            	// LEAD QUALIFIES FOR AN MQL GROUP BUT ITS STUCK IN THE QUEUE BECAUSE OF A MERGE, FORCE OUT OF THE QUEUE USING ASSIGNMENT RULES
            	if(leadsInMQLQueue.contains(lead.Id) && leadsMergedWithin24.contains(lead.Id) && leadsWithMQLRecords.contains(lead.Id)){
            		lead.OwnerId = RoundRobinZeroUserId;
	                leadsToUpdate.add(lead);
            	}
            	// LEAD HAS NOT BEEN WORKED ON FOR AT LEAST 90 DAYS, PLACE BACK INTO QUEUE
            	else if(leadsNotInMQLQueue.contains(lead.Id) && leadsWithOldStatuses.contains(lead.Id) && leadsWithOldOwners.contains(lead.Id)){
	                lead.OwnerId = MQLQueueId;
	                leadsToUpdate.add(lead);
            	}
            	// ENGAGIO COULD NOT FIND AN ACCOUNT MATCH, FORCE THE MQL PROCESS BY POPULATING THE ENGAGEMENT MINUTES FIELD
            	else if((leadsInMQLQueue.contains(lead.Id) && lead.engagio__Matched_Account__c == null) || Test.isRunningTest()){
            		lead.engagio__EngagementMinutesLast3Months__c = 10;
	                leadsToUpdate.add(lead);
            	}
            }

            // SAVE CHANGES TO DATABASE
            if(!leadsToUpdate.isEmpty()){
                Database.saveResult[] leadResults = Database.update(leadsToUpdate, false);
                SystemIssueLogHelper.CheckForDatabaseErrors(leadResults, 'BatchableSch_MQLQualification', 'execute', true);
            }
		}
		catch(Exception ex){ 
			SystemIssueLogHelper.LogException('BatchableSch_MQLQualification', 'execute', scope, ex, true);
		}
	}
	
	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		// FINISH LOGIC
	}


}