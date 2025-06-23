/**
* @author ECS, ERedding
* @date 20200123
* @version 1.00
* @description CampaignAttributionHelper - Contains custom code for Campaign Fractional Attribution functionality.
*/
public with sharing class CampaignAttributionHelper {
	private static Set<Id> ParentRecordIds {get;set;}

    // PRIMARY CONTACT BY ACCOUNT MAP
    private static Map<Id, Id> PrimaryContactByAccount {
    get {
        if(PrimaryContactByAccount == null){
            PrimaryContactByAccount = new Map<Id, Id>();
            for(AccountContactRelation primaryContact : [SELECT AccountId, ContactId FROM AccountContactRelation 
            											 WHERE AccountId IN :ParentRecordIds AND IsPrimary__c = true AND IsDirect = true]){
             	if(!PrimaryContactByAccount.containsKey(primaryContact.AccountId)){
             		PrimaryContactByAccount.put(primaryContact.AccountId, primaryContact.ContactId);
             	}
            }
        }
        return PrimaryContactByAccount;
    } set; }

	/**
	* @description evaluateTasks - Runs tasks through the Camaign Fractional Atribution process
	* @param Map<String, List<Task>> - Map of tasks that grouped by Attribution Department.
	* @return Map<Id, Id> - Map of Task Ids and the Campaign Ids they have been evaluated to be eligible for.
	*/
	public static void evaluateTasks(List<Task> attributionTasks){
		try{
			ParentRecordIds = new Set<Id>();
			if(!attributionTasks.isEmpty()){
                // GET PARENT IDS FROM TASKS
                Set<String> parentLookups = UtilityClass.getPicklistValues('Campaign_Attribution_Criteria_Node__mdt', 'Parent_Lookup_Field__c').keySet();
                for(Task task : attributionTasks){
                	for(String parentLookup : parentLookups){
						ParentRecordIds.add((Id)task.get(parentLookup));
                	}
	            }

                // ORGANIZE CRITERIA GROUP SETTINGS
                Map<Id, CriteriaGroupWrapper> groupWrappers = new Map<Id, CriteriaGroupWrapper>();
                Map<String, Set<String>> parentObjectFields = new Map<String, Set<String>>();
                Set<Id> attributionCampaignIds = new Set<Id>();
                for(Campaign_Attribution_Criteria_Group__mdt criteriaGroup : [SELECT Id, DeveloperName, Criteria_Logic__c, Campaign_Id__c, Pull_in_Primary_Contact__c, Member_Status__c,
                                                                              (SELECT Ordinal__c, Object__c, Field_API_Name__c, Parent_Lookup_Field__c, Operator__c, Value__c
                                                                               FROM GroupCriteriaNodes__r)
                                                                              FROM Campaign_Attribution_Criteria_Group__mdt WHERE Is_Active__c = true]){
                	
                	if(Test.isRunningTest()){
                		// GET CAMPAIGN IDS FROM TEST CLASS IF THIS CODE IS RUNNING FROM A TEST
                		criteriaGroup.Campaign_Id__c = CampaignAttributionHelperTest.TestCampaignIdMap.get(criteriaGroup.DeveloperName);
                	}

                	// CREATE NEW GROUP WRAPPER
                	groupWrappers.put(criteriaGroup.Id, new CriteriaGroupWrapper(criteriaGroup.Criteria_Logic__c, criteriaGroup.Campaign_Id__c, criteriaGroup.Member_Status__c, 
                																 criteriaGroup.Pull_in_Primary_Contact__c));

                	// ADD CAMPAIGN ID
                	attributionCampaignIds.add(criteriaGroup.Campaign_Id__c);

                	// CREATE NODE WRAPPERS
                	List<CriteriaNodeWrapper> nodes = new List<CriteriaNodeWrapper>();
                	for(Campaign_Attribution_Criteria_Node__mdt node : criteriaGroup.GroupCriteriaNodes__r){
                		nodes.add(new CriteriaNodeWrapper(Integer.valueOf(node.Ordinal__c), node.Object__c, node.Field_API_Name__c, node.Parent_Lookup_Field__c, node.Operator__c, node.Value__c));
                	}

                	// SORT LIST OF NODES USING CUSTOM SORT
                	nodes.sort();

                	// ADD NODES TO PARENT GROUP AND GET PARENT OBJECT FIELDS
                	for(CriteriaNodeWrapper nodeWrapper : nodes){
                		groupWrappers.get(criteriaGroup.Id).Nodes.put(String.valueOf(nodeWrapper.Ordinal), nodeWrapper);
                		
                		if(nodeWrapper.ObjectName != 'Task'){
	                		if(!parentObjectFields.containsKey(nodeWrapper.ObjectName)){
	                			parentObjectFields.put(nodeWrapper.ObjectName, new Set<String>());
	                		}
	                		parentObjectFields.get(nodeWrapper.ObjectName).add(nodeWrapper.FieldAPIName);
	                	}
                	}
                }

                // QUERY FOR PARENT DATA
				Map<String, Map<Id, SObject>> taskParentDataMap = queryForParentData(parentObjectFields, ParentRecordIds);

				// GET ANY EXISTING ATTRIBUTION CAMPAIGN MEMBERS
				Map<Id, Map<Id, Id>> memberIdsByCampaignAndWhoId = new Map<Id, Map<Id, Id>>();
				for(CampaignMember member : [SELECT Id, CampaignId, ContactId, LeadId FROM CampaignMember WHERE CampaignId IN :attributionCampaignIds]){
					if(!memberIdsByCampaignAndWhoId.containsKey(member.CampaignId)){
						memberIdsByCampaignAndWhoId.put(member.CampaignId, new Map<Id, Id>());
					}

					if(member.ContactId != null){
						memberIdsByCampaignAndWhoId.get(member.CampaignId).put(member.ContactId, member.Id);
					}
					else if(member.LeadId != null){
						memberIdsByCampaignAndWhoId.get(member.CampaignId).put(member.LeadId, member.Id);
					}
				}

				// EVALUATE TASKS
				List<CampaignMember> campaignMembersToCreate = new List<CampaignMember>();
				List<CampaignMember> campaignMembersToUpdate = new List<CampaignMember>();
                for(CriteriaGroupWrapper groupWrapper : groupWrappers.values()){
	                for(Task task : attributionTasks){
	                	// FOR EACH TASK, POPULATE EACH GROUP CRITERIA NODE WITH DATA
	                	for(String ordinalKey : groupWrapper.Nodes.keySet()){
	                		CriteriaNodeWrapper node = groupWrapper.Nodes.get(ordinalKey);
	                		
	                		// RESET FIELD VALUE SO ITS NOT CARRIED OVER FROM THE LAST TASK
	                		node.FieldDataValue = null;
	                		
	                		if(node.ObjectName == 'Task'){
	                			// GET DATA FROM TASK FIELD
	                			node.FieldDataValue = String.valueOf(task.get(node.FieldAPIName));
	                		}
	                		else{
	                			// GET DATA FROM PARENT FIELD
	                			Id parentRecordId = (Id)task.get(node.ParentLookupFieldName);
	                			if(parentRecordId != null && taskParentDataMap.containsKey(node.ObjectName) && taskParentDataMap.get(node.ObjectName).containsKey(parentRecordId)){
									node.FieldDataValue = String.valueOf(taskParentDataMap.get(node.ObjectName).get(parentRecordId).get(node.FieldAPIName));
	                			}
	                		}
	                	}

	                	// EVALUATE CRITERIA NODES
	                	groupWrapper.buildBooleanLogic();

	                	// EVALUATE BOOLEAN LOGIC AND CREATE CAMPAIGN MEMBERS IF TASK MEETS CRITERIA
	                	Boolean taskResult = BooleanExpression.eval(groupWrapper.BooleanLogic);
	                	if(taskResult && task.WhoId != null){
	                		// GET CURRENT MEMBERS FOR CAMPAIGN
	                		Set<Id> existingMembers = (memberIdsByCampaignAndWhoId.containsKey(groupWrapper.CampaignId) ? memberIdsByCampaignAndWhoId.get(groupWrapper.CampaignId).keySet() : new Set<Id>());

	                		////// CREATE OR UPDATE TASK WHO ID MEMBER
	                		if(existingMembers.contains(task.WhoId)){
	                			// MEMBER ALREADY EXISTS, UPDATE DATE TIME FIELD
	                			Id memberId = memberIdsByCampaignAndWhoId.get(groupWrapper.CampaignId).get(task.WhoId);
	                			campaignMembersToUpdate.add(new CampaignMember(Id = memberId, Last_Attribution_Activity__c = DateTime.now()));
	                		}
	                		else{
	                			// MEMBER DOES NOT EXIST, CREATE IT
		                		CampaignMember member = new CampaignMember(CampaignId = groupWrapper.CampaignId, Status = groupWrapper.MemberStatus, Last_Attribution_Activity__c = DateTime.now());
		                		if(String.valueOf(task.WhoId).left(3) == '003'){
		                			member.ContactId = task.WhoId;
		                			campaignMembersToCreate.add(member);
		                		}
		                		else if(String.valueOf(task.WhoId).left(3) == '00Q'){
		                			member.LeadId = task.WhoId;
		                			campaignMembersToCreate.add(member);
		                		}
		                	}

	                		////// CREATE OR UPDATE ACCOUNT PRIMARY CONTACT MEMBER
	                		if(groupWrapper.PullInPrimary && task.WhatId != null && String.valueOf(task.WhatId).left(3) == '001'){
	                			Id primaryContactId = (PrimaryContactByAccount.containsKey(task.WhatId) ? PrimaryContactByAccount.get(task.WhatId) : null);
	                			if(primaryContactId != null && primaryContactId != task.WhoId){
		                			if(existingMembers.contains(primaryContactId)){
		                				// MEMBER ALREADY EXISTS, UPDATE DATE TIME FIELD
		                				Id memberId = memberIdsByCampaignAndWhoId.get(groupWrapper.CampaignId).get(primaryContactId);
		                				campaignMembersToUpdate.add(new CampaignMember(Id = memberId, Last_Attribution_Activity__c = DateTime.now()));

		                			}
		                			else{
		                				// MEMBER DOES NOT EXIST, CREATE IT
										campaignMembersToCreate.add(new CampaignMember(CampaignId = groupWrapper.CampaignId, Status = groupWrapper.MemberStatus, Last_Attribution_Activity__c = DateTime.now(), 
																					   ContactId = primaryContactId));

		                			}		                				
	                			}
	                		}
	                	}
	                }
	            }

	            // CREATE NEW MEMBERS
	            if(!campaignMembersToCreate.isEmpty()){
                    Database.saveResult[] createMemberResults = Database.insert(campaignMembersToCreate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(createMemberResults, 'CampaignAttributionHelper', 'evaluateTasks', false);	            	
	            }

	            // UPDATE EXISTING MEMBERS
	            if(!campaignMembersToUpdate.isEmpty()){
                    Database.saveResult[] updateMemberResults = Database.update(campaignMembersToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(updateMemberResults, 'CampaignAttributionHelper', 'evaluateTasks', false);
	            }

	            // SAVE ANY ERRORS
	            SystemIssueLogHelper.UpsertExceptions();
            }
		}
		catch(Exception ex){
			SystemIssueLogHelper.LogException('CampaignAttributionHelper', 'evaluateTasks', null, ex, true);
		}
	}

	/**
	* @description queryForParentData - Dynamically queries for parent data using the provided object and field names and record ids
	* @param Map<String, Set<String>> - 
	* @return Set<Id> - 
	*/
	private static Map<String, Map<Id, SObject>> queryForParentData(Map<String, Set<String>> pParentObjectFields, Set<Id> pParentRecordIds){
		Map<String, Map<Id, SObject>> taskParentDataMap = new Map<String, Map<Id, SObject>>();
		try{
			for(String objectName : pParentObjectFields.keySet()){
				// GET FIELDS
				String fieldNames = '';
				for(String fieldName : pParentObjectFields.get(objectName)){
					if(String.isBlank(fieldNames)){
						fieldNames = ', ' + fieldName;
					}
					else{
						fieldNames = fieldNames + ', ' + fieldName;
					}
				}

				String soql = 'SELECT Id' + fieldNames + ' FROM ' + objectName + ' WHERE Id IN :pParentRecordIds';
				List<SObject> parentData = Database.query(soql);
				if(!parentData.isEmpty()){
					taskParentDataMap.put(objectName, new Map<Id, SObject>());
					for(SObject record : parentData){
						taskParentDataMap.get(objectName).put(record.Id, record);
					}
				}
			}
			return taskParentDataMap;
		}
		catch(Exception ex){
			SystemIssueLogHelper.LogException('CampaignAttributionHelper', 'queryForParentData', null, ex, true);
			return taskParentDataMap;
		}
	}

	private class CriteriaGroupWrapper{
		private String CriteriaLogic;
		private String BooleanLogic;
		private Id CampaignId;
		private String MemberStatus;
		private Boolean PullInPrimary;
		private Map<String, CriteriaNodeWrapper> Nodes;

		private CriteriaGroupWrapper(String pCriteriaLogic, String pCampaignId, String pMemberStatus, Boolean pPullInPrimary){
			CriteriaLogic = pCriteriaLogic;
			CampaignId = (UtilityClass.validateId(pCampaignId) ? (Id)pCampaignId : null);
			MemberStatus = pMemberStatus;
			PullInPrimary = pPullInPrimary;
			Nodes = new Map<String, CriteriaNodeWrapper>();
		}

		private void buildBooleanLogic(){
			if(!Nodes.isEmpty()){
				BooleanLogic = CriteriaLogic;
				for(String ordinalKey : Nodes.keySet()){
					CriteriaNodeWrapper nodeWrapper = Nodes.get(ordinalKey);
					Boolean result = nodeWrapper.evaluateCriteriaExpression();
					BooleanLogic = BooleanLogic.replace(ordinalKey, (result != null && result == true ? 'TRUE' : result != null && result == false ? 'FALSE' : 'NULL'));
				}

			}
		}
	}

	private class CriteriaNodeWrapper implements Comparable{
		private Integer Ordinal;
		private String ObjectName;		
		private String FieldAPIName;
		private String ParentLookupFieldName;
		private String CriteriaOperator;
		private String CriteriaValue;
		private String FieldDataValue;

		private CriteriaNodeWrapper(Integer pOrdinal, String pObjectName, String pFieldAPIName, String pParentLookupFieldName, String pCriteriaOperator, String pCriteriaValue){
			Ordinal = pOrdinal;
			ObjectName = pObjectName;
			FieldAPIName = pFieldAPIName;
			ParentLookupFieldName = pParentLookupFieldName ;
			CriteriaOperator = pCriteriaOperator;
			CriteriaValue = (pCriteriaValue == null ? '' : pCriteriaValue);
		}

		private Boolean evaluateCriteriaExpression(){
			try{
				if(CriteriaOperator == 'IsBlank'){
					Boolean boolFromString;
					if(CriteriaValue == '0' || CriteriaValue.toLowerCase() == 'false'){
						boolFromString = false;
					}
					else if(CriteriaValue == '1' || CriteriaValue.toLowerCase() == 'true'){
						boolFromString = true;
					}
					return (String.isBlank(FieldDataValue) == boolFromString); 
				}
				else if(CriteriaOperator == 'Equals'){ return FieldDataValue == CriteriaValue; }
				else if(CriteriaOperator == 'DoesNotEqual'){ return (FieldDataValue != CriteriaValue); }
				else if(CriteriaOperator == 'StartsWith'){
					if(String.isBlank(FieldDataValue)){ return false; }
					return FieldDataValue.startsWithIgnoreCase(CriteriaValue);
				}
				else if(CriteriaOperator == 'EndsWith'){
					if(String.isBlank(FieldDataValue)){ return false; }
					return (FieldDataValue.endsWithIgnoreCase(CriteriaValue));
				}
				else if(CriteriaOperator == 'Contains'){
					if(String.isBlank(FieldDataValue)){ return false; }
					return (FieldDataValue.containsIgnoreCase(CriteriaValue));
				}
				else if(CriteriaOperator == 'DoesNotContain' && (String.isBlank(FieldDataValue) || !FieldDataValue.containsIgnoreCase(CriteriaValue))){ 
					return true;
				}

	            SystemIssueLogHelper.LogException('CampaignAttributionHelper.CriteriaNodeWrapper', 'evaluateCriteriaExpression', null, 'Invalid Operator', true);
				return false;
			}
			catch(Exception ex){
	            SystemIssueLogHelper.LogException('CampaignAttributionHelper.CriteriaNodeWrapper', 'evaluateCriteriaExpression', null, ex, true);
	            return null;
			}
		}

		// CUSTOM SORT METHOD
   	 	public Integer compareTo(Object compareTo) {
	        CriteriaNodeWrapper compareNodes = (CriteriaNodeWrapper)compareTo;
	        Integer returnValue = 0; // The return value of 0 indicates that both elements are equal.
	        if (Ordinal > compareNodes.Ordinal) {
	            returnValue = -1; // Set return value to a positive value.
	        }
	        else if (Ordinal < compareNodes.Ordinal) {
	            returnValue = 1; // Set return value to a negative value.
	        }
	        return returnValue;
	    }
	}


}