/** 
* @author Conga Services
* @date 
* @version 1.00
* @description BatchableSch_CampaignAttribution - [Description]
*/
public class BatchableSch_CampaignAttribution implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
	private Map<Id, Integer> InactivityThresholdByCampaignId;

	/** 
	* @description Scheduable execute method
	*/
   	public void execute(SchedulableContext context) {
		Database.executeBatch(this, 50);
	}
	
	/** 
	* @description Batchable start method
	*/	
	public Database.QueryLocator start(Database.BatchableContext context) {
		// GET METADATA SETTINGS
		List<Campaign_Attribution_Criteria_Group__mdt> criteriaGroups;
		if(!Test.isRunningTest()){
			criteriaGroups = [SELECT Campaign_Id__c, Inactivity_Theshold__c FROM Campaign_Attribution_Criteria_Group__mdt WHERE Is_Active__c = true];
		}
		else{
			criteriaGroups = BatchableSch_CampaignAttributionTest.CriteriaGroupTestMeta;
		}

		// GET THRESHOLDS BY CAMPAIGN ID
		InactivityThresholdByCampaignId = new Map<Id, Integer>();
		for(Campaign_Attribution_Criteria_Group__mdt criteriaGroup : criteriaGroups){
			InactivityThresholdByCampaignId.put(criteriaGroup.Campaign_Id__c, Integer.valueOf(criteriaGroup.Inactivity_Theshold__c));
		}

		// GET SCOPE OF CAMPAIGN MEMBERS TO PROCESS
		return Database.getQueryLocator([SELECT Id, CampaignId, Last_Attribution_Activity__c FROM CampaignMember 
										 WHERE CampaignId IN :InactivityThresholdByCampaignId.keySet() AND Last_Attribution_Activity__c != null]);
	}
	
	/** 
	* @description Batchable execute method
	*/
   	public void execute(Database.BatchableContext context, List<CampaignMember> scope) {
		try{
			// CHECK ALL CAMPAIGNS IN SCOPE FOR LAST ATTRIBUTION ACTIVITY DATES THAT ARE OVER THE CRITERIA GROUP THRESHOLD
			List<CampaignMember> membersToDelete = new List<CampaignMember>();
			for(CampaignMember member : scope){
				Integer threshold = InactivityThresholdByCampaignId != null ? InactivityThresholdByCampaignId.get(member.CampaignId) : null;
				if(threshold != null && UtilityClass.getDistanceBetweenDates(member.Last_Attribution_Activity__c, DateTime.now(), UtilityClass.Interval.Days, 0) > threshold){

					// MEMBER'S LAST ATTRIBUTION ACTIVITY IS BEYOND THE SET THRESHOLD, DELETE IT
					membersToDelete.add(member);
				}
			}

			if(!membersToDelete.isEmpty()){
                Database.deleteResult[] deleteMemberResults = Database.delete(membersToDelete, false);
                SystemIssueLogHelper.CheckForDatabaseErrors(deleteMemberResults, 'BatchableSch_CampaignAttribution', 'execute', true);
			}
		}
		catch(Exception ex){ 
			SystemIssueLogHelper.LogException('BatchableSch_CampaignAttribution', 'execute', scope, ex, true);
		}
	}
	
	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		// NO FINISH LOGIC
	}


}