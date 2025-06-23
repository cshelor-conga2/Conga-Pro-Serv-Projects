/**
* @author ECS, ERedding
* @date 20191030
* @version 1.00
* @description AccountTeamMemberHelper - Custom functionality for the AccountTeamMember object
*/
public with sharing class AccountTeamMemberHelper {
	public static Integer NumberofAccountsUpdated;	
	public static Integer NumberofContactsUpdated;
	public static Integer NumberofOppsUpdated;

    // TERRITORY MANAGEMENT ROLL NAMES
    //public static final String TMRoleName {
    //get { 
    //    if(String.isBlank(TMRoleName)){ TMRoleName = TerritoryManagementHelper.TMRoleNames.get('TM'); } return TMRoleName; 
    //} set; }

    //public static final String CLMRoleName {
    //get { 
    //    if(String.isBlank(CLMRoleName)){ CLMRoleName = TerritoryManagementHelper.TMRoleNames.get('CLM'); } return CLMRoleName; 
    //} set; }

    //public static final String CSMRoleName {
    //get { 
    //    if(String.isBlank(CSMRoleName)){ CSMRoleName = TerritoryManagementHelper.TMRoleNames.get('CSM'); } return CSMRoleName;
    // } set; }

    //public static final String RMRoleName {
    //get { 
    //    if(String.isBlank(RMRoleName)){ RMRoleName = TerritoryManagementHelper.TMRoleNames.get('RM'); } return RMRoleName;
    //} set; }

    // TERRITORY MANAGEMENT TEAM MEMBER ROLE NAME CONSTANTS
    public static final String TMROLENAME = TerritoryManagementHelper.TMROLENAME;
    public static final String CLMROLENAME = TerritoryManagementHelper.CLMROLENAME;    
    public static final String CSMROLENAME = TerritoryManagementHelper.CSMROLENAME;
    public static final String RMROLENAME = TerritoryManagementHelper.RMROLENAME;


	/**
	* @description processTeamChanges - Updates parent accounts related Opps if any Team Members were added or changed and queues a TM Batchable job for updating Contacts
	*									  *** EXECUTED BY AFTER INSERT AND AFTER UPDATE TRIGGERS ***
	* @param List<AccountTeamMember> newOrUpdatedAccountTMs - List of new or updated AccountTeamMember records
    * @param Map<Id, AccountTeamMember> outdatedAccountTMs - Map of outdated AccountTeamMember records 
	*/
	public static void processTeamChanges(List<AccountTeamMember> newOrUpdatedAccountTMs, Map<Id, AccountTeamMember> outdatedAccountTMs){
		try{
			if(TriggerHelper.DoExecute('AccountTeamMemberHelper','processTeamChanges') && newOrUpdatedAccountTMs != null){
                // GET ROLE NAMES FROM CUSTOM METADATA
				Set<String> roleNames = new Set<String>{ TMROLENAME, CLMROLENAME, CSMROLENAME, RMROLENAME };

				// UNIQUE SET OF ROLES FROM CHANGED TEAM MEMBERS
				Map<Id, Set<String>> changedMemberRolesByAccount = new Map<Id, Set<String>>();

				// ORGANIZE DATA AND GET ACCOUNT IDS FROM QUALIFYING RECORDS
				Set<Id> parentAccountIds = new Set<Id>();
				for(AccountTeamMember newOrUpdatedAccountMember : newOrUpdatedAccountTMs){
                    AccountTeamMember outdatedAccountMember = outdatedAccountTMs != null ? outdatedAccountTMs.get(newOrUpdatedAccountMember.Id) : null;

                    if(roleNames.contains(newOrUpdatedAccountMember.TeamMemberRole) && 
                    	(outdatedAccountMember == null || newOrUpdatedAccountMember.TeamMemberRole != outdatedAccountMember.TeamMemberRole)){
                    	parentAccountIds.add(newOrUpdatedAccountMember.AccountId);

                    	if(!changedMemberRolesByAccount.containsKey(newOrUpdatedAccountMember.AccountId)){
							changedMemberRolesByAccount.put(newOrUpdatedAccountMember.AccountId, new Set<String>());
                    	}
                    	changedMemberRolesByAccount.get(newOrUpdatedAccountMember.AccountId).add(newOrUpdatedAccountMember.TeamMemberRole);
                    }
				}

				if(!parentAccountIds.isEmpty()){

					// GET DATA RELATED TO ACCOUNTS
					Map<Id, Account> accountData = new Map<Id, Account>();
					Map<Id, List<AccountTeamMember>> teamMembersByAcct = new Map<Id, List<AccountTeamMember>>();
					Map<Id, Integer> contactCountByAccount = new Map<Id, Integer>();
					for(Account acct : [SELECT Id, Type, OwnerId, TM_GeoId__c, TM_GeoId__r.Name,
											   TM_Territory_ManagerId__c, TM_Manager_Hold__c, 
											   Customer_Success_Manager__c, CSM_Manager_Hold__c,
											   TM_Renewals_ManagerId__c, RM_Manager_Hold__c,
											(SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMembers)
										FROM Account WHERE Id IN :parentAccountIds]){

						// ADD ACCOUNT TO MAP
						accountData.put(acct.Id, acct);

						// POPULATE ACCOUNT TEAM MEMBERS BTY ACCOUNT MAP
						for(AccountTeamMember member : [SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :accountData.keySet()]){
							if(!teamMembersByAcct.containsKey(member.AccountId)){
								teamMembersByAcct.put(member.AccountId, new List<AccountTeamMember>());
							}
							teamMembersByAcct.get(member.AccountId).add(member);
						}

						// POPULATE CONTACT COUNT BY ACCOUNT MAP
						try{
							for(AggregateResult agg : [SELECT AccountId, COUNT(Id) numContacts FROM Contact WHERE AccountId IN :parentAccountIds GROUP BY AccountId HAVING COUNT(Id) > 0]){
								contactCountByAccount.put((Id)agg.get('AccountId'), Integer.valueOf(agg.get('numContacts')));
							}
						}
						catch(Exception ex){
							SystemIssueLogHelper.LogException('AccountTeamMemberHelper', 'processTeamChanges', newOrUpdatedAccountTMs, ex, true);
						}
					}

					// GET DATA RELATED TO OPPORTUNITIES
					Map<Id, List<Opportunity>> oppsByAccount = new Map<Id, List<Opportunity>>();
					Map<Id, List<OpportunityTeamMember>> teamMembersByOpp = new Map<Id, List<OpportunityTeamMember>>();
					Map<Id, Set<Id>> splitMembersByOpp = new Map<Id, Set<Id>>();
					Set<Id> oppIds = new Set<Id>();
					for(Opportunity opp : [SELECT Id, Type, OwnerId, AccountId, Customer_Success_ManagerId__c, TM_Territory_ManagerId__c, 
										   TM_Manager_Hold__c, CSM_Manager_Hold__c, RM_Manager_Hold__c,
										   (SELECT Id, OpportunityId, TeamMemberRole, UserId FROM OpportunityTeamMembers ORDER BY CreatedDate DESC),
										   (SELECT OpportunityId, SplitOwnerId FROM OpportunitySplits)
										   FROM Opportunity WHERE AccountId IN :accountData.keySet() AND IsClosed = false]){
						// ADD OPP ID TO SET
						oppIds.add(opp.Id);

						// POPULATE OPPS BY ACCOUNT MAP
						if(!oppsByAccount.containsKey(opp.AccountId)){
							oppsByAccount.put(opp.AccountId, new List<Opportunity>());
						}
						oppsByAccount.get(opp.AccountId).add(opp);
 
						// POPULATE TEAM MEMBERS BY OPPORTUNITY MAP
						if(!opp.OpportunityTeamMembers.isEmpty()){
							for(OpportunityTeamMember member : opp.OpportunityTeamMembers){
								if(!teamMembersByOpp.containsKey(member.OpportunityId)){
									teamMembersByOpp.put(member.OpportunityId, new List<OpportunityTeamMember>());
								}
								teamMembersByOpp.get(member.OpportunityId).add(member);
							}
						}

						// POPULATE SPLIT MEMBERS BY OPP MAP
						if(!opp.OpportunitySplits.isEmpty()){
							for(OpportunitySplit splitMember : opp.OpportunitySplits){
								if(!splitMembersByOpp.containsKey(splitMember.OpportunityId)){
									splitMembersByOpp.put(splitMember.OpportunityId, new Set<Id>());
								}
								splitMembersByOpp.get(splitMember.OpportunityId).add(splitMember.SplitOwnerId);
							}
						}
					}

	                // GET ACCOUNT CUSTOMER TYPES
	                Set<String> nonCustomerTypes = new Set<String>{ TerritoryManagementHelper.PROSPECTTYPE, TerritoryManagementHelper.CUSTOMERFORMERTYPE };
                    Set<String> activeCustomerTypes = new Set<String>{ TerritoryManagementHelper.CUSTOMERTYPE, TerritoryManagementHelper.CUSTOMERPASTDUETYPE };

					////// LOOP OVER PARENT ACCOUNTS, RELATED CONTACTS, AND RELATED OPEN OPPORTUNITIES AND MAKE NECESSARY UPDATES
					NumberofContactsUpdated = 0;
					Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
					List<OpportunityTeamMember> oppsTMsToCreate = new List<OpportunityTeamMember>();
					Map<Id, OpportunityTeamMember> oppsTMsToUpdate = new Map<Id, OpportunityTeamMember>();
					List<OpportunityTeamMember> oppsTMsToDelete = new List<OpportunityTeamMember>();
					Set<Id> idsOfUpdatedOpps = new Set<Id>();
					for(Account acct : accountData.values()){
						if(teamMembersByAcct.containsKey(acct.Id) && changedMemberRolesByAccount.containsKey(acct.Id)){

							// GET ACCOUNT MEMBERS
							Id acctTMMemberId;
							Id acctCLMMemberId;
							Id acctCSMMemberId;
							Id acctRMMemberId;
							for(AccountTeamMember acctMember : teamMembersByAcct.get(acct.Id)){
								if(acctMember.TeamMemberRole == TMROLENAME){
									acctTMMemberId = acctMember.UserId;
								}
								else if(acctMember.TeamMemberRole == CLMROLENAME){
									acctCLMMemberId = acctMember.UserId;
								}
								else if(acctMember.TeamMemberRole == CSMROLENAME){
									acctCSMMemberId = acctMember.UserId;
								}
								else if(acctMember.TeamMemberRole == RMROLENAME){
									acctRMMemberId = acctMember.UserId;
								}
							}

							// GET ROLES OF CHANGED MEMBERS
							Set<String> changedMemberRoles = changedMemberRolesByAccount.get(acct.Id);

							///////////////////////////////////////////////////////////////////////////////////
							/////////////////////////// ACCOUNT AND CONTACT UPDATES ///////////////////////////
							///////////////////////////////////////////////////////////////////////////////////

							//// ACCOUNT TM UPDATES IF NOT HELD AND IS A QUALIFYING CHANGE
				            if(acctTMMemberId != null && !acct.TM_Manager_Hold__c && changedMemberRoles.contains(TMROLENAME)){

				                // ACCOUNT NOT AN ACTIVE CUSTOMER TYPE, UPDATE OWNER AND TM
				                if(nonCustomerTypes.contains(acct.Type) && (acct.TM_Territory_ManagerId__c != acctTMMemberId || acct.OwnerId != acctTMMemberId)){
				                    acct.TM_Territory_ManagerId__c = acctTMMemberId;
				                    acct.OwnerId = acctTMMemberId;
				                    acct.TM_Contact_Update__c = (contactCountByAccount.containsKey(acct.Id) ? true : false);
				                    accountsToUpdate.put(acct.Id, acct);
				                }
				                // ACCOUNT IS CUSTOMER OR CUSTOMER - PAST DUE, UPDATE TM ONLY
				                else if(activeCustomerTypes.contains(acct.Type) && acct.TM_Territory_ManagerId__c != acctTMMemberId){
				                    acct.TM_Territory_ManagerId__c = acctTMMemberId;
				                    acct.TM_Contact_Update__c = (contactCountByAccount.containsKey(acct.Id) ? true : false);
				                    accountsToUpdate.put(acct.Id, acct);
				                }
				            }

							//// ACCOUNT CSM UPDATES IF NOT HELD AND IS A QUALIFYING CHANGE
							if(acctCSMMemberId != null && !acct.CSM_Manager_Hold__c && activeCustomerTypes.contains(acct.Type) && changedMemberRoles.contains(CSMROLENAME)){

				                // UPDATE ACCOUNT CSM AND OWNER
				                if((acct.TM_GeoId__c == null || acct.TM_GeoId__r.Name != 'EMEA') && (acct.Customer_Success_Manager__c != acctCSMMemberId || acct.OwnerId != acctCSMMemberId)){
				                    acct.Customer_Success_Manager__c = acctCSMMemberId;
				                    acct.OwnerId = acctCSMMemberId;
				                    acct.TM_Contact_Update__c = (contactCountByAccount.containsKey(acct.Id) ? true : false);
				                    accountsToUpdate.put(acct.Id, acct);
				                }
				                // UPDATE ACCOUNT CSM ONLY
				                else if(acct.Customer_Success_Manager__c != acctCSMMemberId){
				                    acct.Customer_Success_Manager__c = acctCSMMemberId;
				                    acct.TM_Contact_Update__c = (contactCountByAccount.containsKey(acct.Id) ? true : false);
				                    accountsToUpdate.put(acct.Id, acct);
				                }
							}

							//// ACCOUNT RM UPDATES IF NOT HELD AND IS A QUALIFYING CHANGE
							if(acctRMMemberId != null && !acct.RM_Manager_Hold__c && activeCustomerTypes.contains(acct.Type) && changedMemberRoles.contains(RMROLENAME)){
				                // UPDATE ACCOUNT RM
				                if(acct.TM_Renewals_ManagerId__c != acctRMMemberId){
				                    acct.TM_Renewals_ManagerId__c = acctRMMemberId;
				                    accountsToUpdate.put(acct.Id, acct);
				                }
							}

					        //// COUNT HOW MANY CONTACTS THAT WILL BE CHECKED FOR UPDATES
					        if(acctTMMemberId != null && contactCountByAccount.containsKey(acct.Id)){
					        	NumberofContactsUpdated += contactCountByAccount.get(acct.Id);
					        }

							////////////////////////////////////////////////////////////////////////
							//////////////////////// OPPORTUNITY UPDATES ///////////////////////////
							////////////////////////////////////////////////////////////////////////
					        if(oppsByAccount.containsKey(acct.Id)){
					            for(Opportunity opp : oppsByAccount.get(acct.Id)){

					            	// GET CURRENT OPPORTUNITY MEMBERS
					            	OpportunityTeamMember oppCurrentOwnerMember;
							        OpportunityTeamMember oppCurrentTMMember;
							        OpportunityTeamMember oppCurrentCLMMember;
									OpportunityTeamMember oppCurrentCSMMember;
								    OpportunityTeamMember oppCurrentRMMember;
							        if(teamMembersByOpp.containsKey(opp.Id)){
								        for(OpportunityTeamMember currentMember : teamMembersByOpp.get(opp.Id)){
								            if(currentMember.TeamMemberRole == 'Opportunity Owner' && oppCurrentOwnerMember == null){
								            	oppCurrentOwnerMember = currentMember;
								            }
								            else if(currentMember.TeamMemberRole == TMROLENAME && oppCurrentTMMember == null){
								            	oppCurrentTMMember = currentMember;
								            }
								            else if(currentMember.TeamMemberRole == CLMROLENAME && oppCurrentCLMMember == null){
								            	oppCurrentCLMMember = currentMember;
								            }
											else if(currentMember.TeamMemberRole == CSMROLENAME && oppCurrentCSMMember == null){
									            oppCurrentCSMMember = currentMember;
									        }
										    else if(currentMember.TeamMemberRole == RMROLENAME && oppCurrentRMMember == null){
									            oppCurrentRMMember = currentMember;
									        }
								        }
								    }

									//// OPPORTUNITY TM UPDATES IF NOT HELD AND IS A QUALIFYING CHANGE
						            if(acctTMMemberId != null && !opp.TM_Manager_Hold__c && changedMemberRoles.contains(TMROLENAME) && (oppCurrentTMMember == null || oppCurrentTMMember.UserId != acctTMMemberId)){

			                            idsOfUpdatedOpps.add(opp.Id);											

			                        	// UPDATE OPP OWNER MEMBER IF IT EXISTS AND USER MATCHES THE TM
			                        	if(oppCurrentOwnerMember != null && oppCurrentOwnerMember.UserId == acctTMMemberId){
			                        		oppCurrentOwnerMember.TeamMemberRole = TMROLENAME;
			                        		oppsTMsToUpdate.put(oppCurrentOwnerMember.Id, oppCurrentOwnerMember);
			                        	}
			                        	// ELSE JUST CREATE A NEW TM MEMBER
			                        	else{
											oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = acctTMMemberId, TeamMemberRole = TMROLENAME));				                        		
			                        	}

										// DELETE OLD MEMBER IF NOT PART OF A SPLIT AND NO LONGER VALID
						            	if(oppCurrentTMMember != null && (!splitMembersByOpp.containsKey(opp.Id) || !splitMembersByOpp.get(opp.Id).contains(oppCurrentTMMember.UserId))){
								            oppsTMsToDelete.add(oppCurrentTMMember);
						            	}
						            }

					                //// OPPORTUNITY CLM MEMBER UPDATES AND IS A QUALIFYING CHANGE
						            if(acctCLMMemberId != null && changedMemberRoles.contains(CLMROLENAME) && (oppCurrentCLMMember == null || oppCurrentCLMMember.UserId != acctCLMMemberId)){

						            	oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = acctCLMMemberId, TeamMemberRole = CLMROLENAME));
			                            idsOfUpdatedOpps.add(opp.Id);

										// DELETE OLD MEMBER IF NOT PART OF A SPLIT AND NO LONGER VALID
										if(oppCurrentCLMMember != null && (!splitMembersByOpp.containsKey(opp.Id) || !splitMembersByOpp.get(opp.Id).contains(oppCurrentCLMMember.UserId))){
								            oppsTMsToDelete.add(oppCurrentCLMMember);
						            	}
						            }

									if(opp.Type == 'Renewal' || opp.Type == 'Existing Business'){

										// OPPORTUNITY CSM MEMBER UPDATES IF NOT HELD AND IS A QUALIFYING CHANGE
							            if(acctCSMMemberId != null && !opp.CSM_Manager_Hold__c && changedMemberRoles.contains(CSMROLENAME) && (oppCurrentCSMMember == null || oppCurrentCSMMember.UserId != acctCSMMemberId)){
							            	oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = acctCSMMemberId, TeamMemberRole = CSMROLENAME));
							            	
							            	idsOfUpdatedOpps.add(opp.Id);

		                        			// UPDATE OPP OWNER MEMBER IF IT EXISTS AND USER MATCHES THE CSM
				                        	if(oppCurrentOwnerMember != null && oppCurrentOwnerMember.UserId == acctCSMMemberId){
				                        		oppCurrentOwnerMember.TeamMemberRole = CSMROLENAME;
				                        		oppsTMsToUpdate.put(oppCurrentOwnerMember.Id, oppCurrentOwnerMember);
				                        	}
				                        	// ELSE JUST CREATE A NEW TM MEMBER
				                        	else{
												oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = acctCSMMemberId, TeamMemberRole = CSMROLENAME));			                        		
				                        	}

											// DELETE OLD MEMBER IF NOT PART OF A SPLIT AND NO LONGER VALID
							            	if(oppCurrentCSMMember != null && (!splitMembersByOpp.containsKey(opp.Id) || !splitMembersByOpp.get(opp.Id).contains(oppCurrentCSMMember.UserId))){
									            oppsTMsToDelete.add(oppCurrentCSMMember);
							            	}
							            }

						                // OPPORTUNITY RM MEMBER UPDATES IF NOT HELD AND IS A QUALIFYING CHANGE
							            if(acctRMMemberId != null && !opp.RM_Manager_Hold__c && changedMemberRoles.contains(RMROLENAME) && (oppCurrentRMMember == null || oppCurrentRMMember.UserId != acctRMMemberId)){
							            	oppsTMsToCreate.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = acctRMMemberId, TeamMemberRole = RMROLENAME));
				                            idsOfUpdatedOpps.add(opp.Id);

											// DELETE OLD MEMBER IF NOT PART OF A SPLIT AND NO LONGER VALID
							            	if(oppCurrentRMMember != null && (!splitMembersByOpp.containsKey(opp.Id) || !splitMembersByOpp.get(opp.Id).contains(oppCurrentRMMember.UserId))){
									            oppsTMsToDelete.add(oppCurrentRMMember);
							            	}
							            }
						            }
					            }
							}
						}
					}

					// SET RECORD UPDATE COUNTS
					NumberofAccountsUpdated = accountsToUpdate.size();
					NumberofOppsUpdated = idsOfUpdatedOpps.size();

					// SAVE ACCOUNT CHANGES
					if(!accountsToUpdate.isEmpty()){
						TriggerHelper.TemporaryOverride('AccountHelper','updateAcctTeamsFromLookups', false); // NO NEED TO UPDATE TEAMS AGAIN WHEN LOOKUPS ARE CHANGED
						Database.SaveResult[] accountResults = Database.update(accountsToUpdate.values(), false);
						SystemIssueLogHelper.CheckForDatabaseErrors(accountResults, 'AccountTeamMemberHelper', 'processTeamChanges', false);
					}

					////////// CONTACT CHANGES WILL BE HANDLED BY A SCHEDULED BATCH JOB SINCE THERE COULD BE MANY CONTACTS //////////

					// SAVE OPPORTUNITY TEAM CHANGES - DELETE
					if(!oppsTMsToDelete.isEmpty()){
						Database.DeleteResult[] deleteOppTMResults = Database.delete(oppsTMsToDelete, false);
						SystemIssueLogHelper.CheckForDatabaseErrors(deleteOppTMResults, 'AccountTeamMemberHelper', 'processTeamChanges', false);
					}

					// SAVE OPPORTUNITY TEAM CHANGES - UPDATE
					if(!oppsTMsToUpdate.isEmpty()){
						Database.SaveResult[] updateOppTMResults = Database.update(oppsTMsToUpdate.values(), false);
						SystemIssueLogHelper.CheckForDatabaseErrors(updateOppTMResults, 'AccountTeamMemberHelper', 'processTeamChanges', false);
					}

					// SAVE OPPORTUNITY TEAM CHANGES - CREATE
					if(!oppsTMsToCreate.isEmpty()){
						Database.SaveResult[] createOppTMResults = Database.insert(oppsTMsToCreate, false);
						SystemIssueLogHelper.CheckForDatabaseErrors(createOppTMResults, 'AccountTeamMemberHelper', 'processTeamChanges', false);
					}

					// SAVE LOGGED ERRORS
					SystemIssueLogHelper.UpsertExceptions();

                	// END AUDIT IF ONE IS STARTED
					TriggerHelper.EndExecute('AccountTeamMemberHelper','processTeamChanges');
				}
			}
		}	
		catch(Exception ex){
			SystemIssueLogHelper.LogException('AccountTeamMemberHelper', 'processTeamChanges', newOrUpdatedAccountTMs, ex, true);
		}
	}


}