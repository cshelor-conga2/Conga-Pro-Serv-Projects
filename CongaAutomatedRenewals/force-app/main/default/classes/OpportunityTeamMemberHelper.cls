/**
* @author ECS, ERedding
* @date 20191030
* @version 1.00
* @description OpportunityTeamMemberHelper - Custom functionality for the OpportunityTeamMember object
*/
public with sharing class OpportunityTeamMemberHelper {

    // TERRITORY MANAGEMENT TEAM MEMBER ROLE NAME CONSTANTS
    public static final String TMROLENAME = TerritoryManagementHelper.TMROLENAME;
    public static final String CSMROLENAME = TerritoryManagementHelper.CSMROLENAME;
    public static final String RMROLENAME = TerritoryManagementHelper.RMROLENAME;
    public static final String BDRROLENAME = TerritoryManagementHelper.BDRROLENAME;
    public static final String SDRROLENAME = TerritoryManagementHelper.SDRROLENAME;
    public static final String SEROLENAME = TerritoryManagementHelper.SEROLENAME;

	/**
	* @description processTeamChanges - Queues opportunities for TM updates if any Team Members were added or changed
	*									  *** EXECUTED BY AFTER INSERT AND AFTER UPDATE TRIGGERS ***
	* @param List<OpportunityTeamMember> newOrUpdatedOppTMs - List of new or updated OpportunityTeamMember records
    * @param Map<Id, OpportunityTeamMember> outdatedOppTMs - Map of outdated OpportunityTeamMember records 
	*/
	public static void processTeamChanges(List<OpportunityTeamMember> newOrUpdatedOppTMs, Map<Id, OpportunityTeamMember> outdatedOppTMs){
		try{		
			if(TriggerHelper.DoExecute('OpportunityTeamMemberHelper','processTeamChanges') && newOrUpdatedOppTMs != null){
				// GET ROLE NAMES FROM CUSTOM METADATA
				Set<String> roleNames = new Set<String>{ TMROLENAME, CSMROLENAME, RMROLENAME, BDRROLENAME, SDRROLENAME, SEROLENAME };

				// UNIQUE SET OF ROLES FROM CHANGED TEAM MEMBERS
				Map<Id, Set<String>> changedMemberRolesByOpp = new Map<Id, Set<String>>();

				// ORGANIZE DATA AND GET OPPORTUNITY IDS FROM QUALIFYING RECORDS
				Set<Id> parentOppIds = new Set<Id>();
				for(OpportunityTeamMember newOrUpdatedOppMember : newOrUpdatedOppTMs){
                    OpportunityTeamMember outdatedOppTM = outdatedOppTMs != null ? outdatedOppTMs.get(newOrUpdatedOppMember.Id) : null;

                    if(roleNames.contains(newOrUpdatedOppMember.TeamMemberRole) && 
                    	(outdatedOppTM == null || newOrUpdatedOppMember.TeamMemberRole != outdatedOppTM.TeamMemberRole)){
                    	parentOppIds.add(newOrUpdatedOppMember.OpportunityId);

                    	if(!changedMemberRolesByOpp.containsKey(newOrUpdatedOppMember.OpportunityId)){
							changedMemberRolesByOpp.put(newOrUpdatedOppMember.OpportunityId, new Set<String>());
                    	}
                    	changedMemberRolesByOpp.get(newOrUpdatedOppMember.OpportunityId).add(newOrUpdatedOppMember.TeamMemberRole);
                    }
				}

				if(!parentOppIds.isEmpty()){

					// GET DATA RELATED TO OPPORTUNITIES
					Map<Id, Opportunity> opportunityData = new Map<Id, Opportunity>();
					Map<Id, List<OpportunityTeamMember>> teamMembersByOpp = new Map<Id, List<OpportunityTeamMember>>();
					for(Opportunity opp : [SELECT Id, Type, OwnerId, Account.Type, AccountId, Account.TM_GeoId__c, Account.TM_GeoId__r.Name, Customer_Success_ManagerId__c, TM_Territory_ManagerId__c, 
										   TM_Manager_Hold__c, CSM_Manager_Hold__c, RM_Manager_Hold__c, SE_Assigned__c, SDR__c,
										   (SELECT Id, OpportunityId, TeamMemberRole, UserId FROM OpportunityTeamMembers ORDER BY CreatedDate DESC)
										   FROM Opportunity WHERE Id IN :parentOppIds AND IsClosed = false]){

						// POPULATE OPPORTUNITY DATA MAP
						opportunityData.put(opp.Id, opp);
 
						// POPULATE TEAM MEMBERS BY OPPORTUNITY MAP
						if(!opp.OpportunityTeamMembers.isEmpty()){
							for(OpportunityTeamMember member : opp.OpportunityTeamMembers){
								if(!teamMembersByOpp.containsKey(member.OpportunityId)){
									teamMembersByOpp.put(member.OpportunityId, new List<OpportunityTeamMember>());
								}
								teamMembersByOpp.get(member.OpportunityId).add(member);
							}
						}
					}

	                // GET ACCOUNT CUSTOMER TYPES
	                Set<String> nonCustomerTypes = new Set<String>{ TerritoryManagementHelper.PROSPECTTYPE, TerritoryManagementHelper.CUSTOMERFORMERTYPE };
                    Set<String> activeCustomerTypes = new Set<String>{ TerritoryManagementHelper.CUSTOMERTYPE, TerritoryManagementHelper.CUSTOMERPASTDUETYPE };

					// LOOP OVER OPPS AND MAKE NECESSARY UPDATES
					Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
		            for(Opportunity opp : opportunityData.values()){
				        if(teamMembersByOpp.containsKey(opp.Id) && changedMemberRolesByOpp.containsKey(opp.Id)){
			
			            	// GET CURRENT OPPORTUNITY MEMBERS
					        OpportunityTeamMember oppCurrentTMMember;
							OpportunityTeamMember oppCurrentCSMMember;
							OpportunityTeamMember oppCurrentRMMember;
	                        OpportunityTeamMember oppCurrentBDRMember;
	                        OpportunityTeamMember oppCurrentSDRMember;
	                        OpportunityTeamMember oppCurrentSEMember;
					        for(OpportunityTeamMember currentMember : teamMembersByOpp.get(opp.Id)){
					            if(currentMember.TeamMemberRole == TMROLENAME && oppCurrentTMMember == null){
					            	oppCurrentTMMember = currentMember;
					            }
								if(currentMember.TeamMemberRole == CSMROLENAME && oppCurrentCSMMember == null){
						            oppCurrentCSMMember = currentMember;
						        }
						        if(currentMember.TeamMemberRole == RMROLENAME && oppCurrentRMMember == null){
						            oppCurrentRMMember = currentMember;
						        }
                                if(currentMember.TeamMemberRole == BDRROLENAME && oppCurrentBDRMember == null){
                                    oppCurrentBDRMember = currentMember;
                                }
                                if(currentMember.TeamMemberRole == SDRROLENAME && oppCurrentSDRMember == null){
                                    oppCurrentSDRMember = currentMember;
                                }
                                if(currentMember.TeamMemberRole == SEROLENAME && oppCurrentSEMember == null){
                                    oppCurrentSEMember = currentMember;
                                }
					        }

					        // GET ROLES OF CHANGED MEMBERS
							Set<String> changedMemberRoles = changedMemberRolesByOpp.get(opp.Id);

							//// OPPORTUNITY TM UPDATES IF NOT HELD
		                    if(oppCurrentTMMember != null && !opp.TM_Manager_Hold__c && changedMemberRoles.contains(TMROLENAME)){
		                    	// OPP IS NEW OR (OPP IS EXISTING AND ACCOUNT IS PROSPECT OR CUSTOMER - FORMER), UPDATE OWNER AND TM FOR ALL OPEN OPPS
		                        if((opp.Type == 'New Business' || (opp.Type == 'Existing Business' && nonCustomerTypes.contains(opp.Account.Type))) && 
		                        	(opp.OwnerId != oppCurrentTMMember.UserId || opp.TM_Territory_ManagerId__c != oppCurrentTMMember.UserId)){

		                            opp.OwnerId = oppCurrentTMMember.UserId;
		                            opp.TM_Territory_ManagerId__c = oppCurrentTMMember.UserId;
		                            oppsToUpdate.put(opp.Id, opp);
		                        }
		                        // OPP IS RENEWAL OR (OPP IS EXISTING AND ACCOUNT IS CUSTOMER/CUSTOMER - PAST DUE), UPDATE TM FOR ALL OPEN OPPS
		                        else if((opp.Type == 'Renewal' || (opp.Type == 'Existing Business' && activeCustomerTypes.contains(opp.Account.Type))) && opp.TM_Territory_ManagerId__c != oppCurrentTMMember.UserId){
		                            opp.TM_Territory_ManagerId__c = oppCurrentTMMember.UserId;
		                            oppsToUpdate.put(opp.Id, opp);
		                        }
		                    }
							
							//// OPPORTUNITY CSM AND RM UPDATES IF A RENEWAL OR EXISTING BUSINESS
							if(opp.Type == 'Renewal' || opp.Type == 'Existing Business'){
								if(oppCurrentCSMMember != null && !opp.CSM_Manager_Hold__c && changedMemberRoles.contains(CSMROLENAME)){
		                            // ONLY UPDATE RENEWAL OPPS THAT ARE NOT HELD
		                            if(opp.OwnerId != oppCurrentCSMMember.UserId || opp.Customer_Success_ManagerId__c != oppCurrentCSMMember.UserId){
		                                opp.Customer_Success_ManagerId__c = oppCurrentCSMMember.UserId;
			                            
			                            // UPDATE OWNER TO CSM ONLY IF NOT AN EMEA ACCOUNT
			                            if(opp.Type == 'Renewal' && (opp.Account.TM_GeoId__c == null || opp.Account.TM_GeoId__r.Name != 'EMEA')){
			                            	opp.OwnerId = oppCurrentCSMMember.UserId;
			                            }
		                                oppsToUpdate.put(opp.Id, opp);
		                            }
		                        }

								if(oppCurrentRMMember != null && !opp.RM_Manager_Hold__c && changedMemberRoles.contains(RMROLENAME)){
		                            // UPDATE OWNER TO RM ONLY ON OPPS THAT ARE NOT HELD AND NOT AN EMEA ACCOUNT. AN RM -WILL- OVERWRITE A CSM
		                            if(opp.Type == 'Renewal' && opp.OwnerId != oppCurrentRMMember.UserId && (opp.Account.TM_GeoId__c == null || opp.Account.TM_GeoId__r.Name != 'EMEA')){
			                            opp.OwnerId = oppCurrentRMMember.UserId;
		                                oppsToUpdate.put(opp.Id, opp);
		                            }
		                        }
							}

							//// OPPORTUNITY BDR UPDATES
	                    	if(oppCurrentBDRMember != null && oppCurrentSDRMember == null && opp.SDR__c != oppCurrentBDRMember.UserId && changedMemberRoles.contains(BDRROLENAME)){
	                    		opp.SDR__c = oppCurrentBDRMember.UserId;
	                            oppsToUpdate.put(opp.Id, opp);
	                    	}

	                    	//// OPPORTUNITY SDR UPDATES
	                    	if(oppCurrentSDRMember != null  && oppCurrentBDRMember == null && opp.SDR__c != oppCurrentSDRMember.UserId && changedMemberRoles.contains(SDRROLENAME)){
	                    		opp.SDR__c = oppCurrentSDRMember.UserId;
	                            oppsToUpdate.put(opp.Id, opp);
	                    	}

							//// OPPORTUNITY SE UPDATES
		                    if(oppCurrentSEMember != null && opp.SE_Assigned__c != oppCurrentSEMember.UserId && changedMemberRoles.contains(SEROLENAME)){
	                    		opp.SE_Assigned__c = oppCurrentSEMember.UserId;
	                            oppsToUpdate.put(opp.Id, opp);
		                    }
						}
					}

					// SAVE CHANGES
					if(!oppsToUpdate.isEmpty()){
						//TriggerHelper.TemporaryOveride('Opportunity.setTeamStampFields', false); // BOOKING OWNER UPDATE TRIGGERS STAMP UPDATE WHICH OVERWRITES TM CHANGE
						TriggerHelper.TemporaryOverride('OpportunityHelper','updateOppTeamsFromLookups', false); // NO NEED TO UPDATE TEAMS AGAIN WHEN LOOKUPS ARE CHANGED
						Database.SaveResult[] oppResults = Database.update(oppsToUpdate.values(), false);
						SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'OpportunityTeamMemberHelper', 'processTeamChanges', false);
					}
				}

				// END AUDIT IF ONE IS STARTED
				TriggerHelper.EndExecute('OpportunityTeamMemberHelper','processTeamChanges');
			}
		}
		catch(Exception ex){
			SystemIssueLogHelper.LogException('OpportunityTeamMemberHelper', 'processTeamChanges', newOrUpdatedOppTMs, ex, true);
		}
	}


}