/** 
* @author ECS, ERedding
* @date 20180318
* @version 1.00
* @description BatchableTerritoryManagement - Batch class that updates Accounts, Contacts, and Opportunities asynchronously when qualifying changes are made to 
*											  Accounts, Territory Segments, or Territory Divisions
*/
public class BatchableTerritoryManagement implements Database.Batchable<sObject>, Database.Stateful {
    private final String TMROLENAME = TerritoryManagementHelper.TMROLENAME;
    private final String CSMROLENAME = TerritoryManagementHelper.CSMROLENAME;
    private final String RMROLENAME = TerritoryManagementHelper.RMROLENAME;
	private final Set<String> ACTIVECUSTOMERTYPES = new Set<String>{ TerritoryManagementHelper.CUSTOMERTYPE, TerritoryManagementHelper.CUSTOMERPASTDUETYPE };

	private Map<Id, Map<Id, List<TM_Territory_Segment_Users__c>>> TSUsBySegmentAndTerritory;
	private Map<Id, Map<Id, List<TM_Territory_Division_Users__c>>> TSDsByDivisionAndTerritory;
	private Set<Id> TerritoryIds;
	private Map<String, List<String>> UpdateInfoForEmail;
    private Set<String> RolesQualifyingForUpdate;
	private Boolean SendEmail;

	public Integer NumberofAccountsUpdated;
	public Integer NumberofContactsUpdated;
	public Integer NumberofOppsUpdated;


	/** 
	* @description Constructor with Parameters
	*/
	public BatchableTerritoryManagement(Map<Id, TM_Territory_Segment_Users__c> updatedTSUs, Map<Id, TM_Territory_Division_Users__c> updatedTDUs, Boolean pSendEmail) {
		UpdateInfoForEmail = TerritoryManagementHelper.RecordUpdateInfo;
		RolesQualifyingForUpdate = TerritoryManagementHelper.RolesQualifyingForUpdate;

		NumberofAccountsUpdated = 0;
		NumberofContactsUpdated = 0;
		NumberofOppsUpdated = 0;
		SendEmail = pSendEmail;

		// GET TERRITORY SEGMENT AND TERRITORY DIVISION IDS
		Set<Id> territorySegmentIds = new Set<Id>();
		Set<Id> territoryDivisionIds = new Set<Id>();
		if(updatedTSUs != null){
			for(TM_Territory_Segment_Users__c terrSegmentUser : updatedTSUs.values()){
				territorySegmentIds.add(terrSegmentUser.TM_Territory_SegmentId__c);
			}
		}
		if(updatedTDUs != null){
			for(TM_Territory_Division_Users__c terrDivisionUser : updatedTDUs.values()){
				territoryDivisionIds.add(terrDivisionUser.TM_Territory_DivisionId__c);
			}
		}

		// GET TERRITORY SEGMENT AND TERRITORY DIVISION RECORDS
		TSUsBySegmentAndTerritory = new Map<Id, Map<Id, List<TM_Territory_Segment_Users__c>>>();
		TSDsByDivisionAndTerritory = new Map<Id, Map<Id, List<TM_Territory_Division_Users__c>>>();
		TerritoryIds = new Set<Id>();
		if(!territorySegmentIds.isEmpty()){
			for(TM_Territory_Segment__c terrSegment : [SELECT Id, TM_TerritoryId__c, TM_SegmentId__c,
														(SELECT Id, Applicable_Industries__c, Assigned_TM_UserId__c FROM TerritorySegmentUsers__r)
													   FROM TM_Territory_Segment__c WHERE Id IN :territorySegmentIds]){
				if(!TSUsBySegmentAndTerritory.containsKey(terrSegment.TM_SegmentId__c)){
					TSUsBySegmentAndTerritory.put(terrSegment.TM_SegmentId__c, new Map<Id, List<TM_Territory_Segment_Users__c>>());
				}
				TSUsBySegmentAndTerritory.get(terrSegment.TM_SegmentId__c).put(terrSegment.TM_TerritoryId__c, new List<TM_Territory_Segment_Users__c>());

				for(TM_Territory_Segment_Users__c terrSegmentUser : terrSegment.TerritorySegmentUsers__r){

					TSUsBySegmentAndTerritory.get(terrSegment.TM_SegmentId__c).get(terrSegment.TM_TerritoryId__c).add(terrSegmentUser);
					TerritoryIds.add(terrSegment.TM_TerritoryId__c);
				}
			}
		}

		if(!territoryDivisionIds.isEmpty()){
			for(TM_Territory_Division__c terrDivision : [SELECT Id, TM_TerritoryId__c, TM_DivisionId__c,
														  (SELECT Id, Assigned_CSM_UserId__c, Assigned_RM_UserId__c FROM TerritoryDivisionUsers__r)
													    FROM TM_Territory_Division__c WHERE Id IN :territoryDivisionIds]){
				if(!TSDsByDivisionAndTerritory.containsKey(terrDivision.TM_DivisionId__c)){
					TSDsByDivisionAndTerritory.put(terrDivision.TM_DivisionId__c, new Map<Id, List<TM_Territory_Division_Users__c>>());
				}
				TSDsByDivisionAndTerritory.get(terrDivision.TM_DivisionId__c).put(terrDivision.TM_TerritoryId__c, new List<TM_Territory_Division_Users__c>());

				for(TM_Territory_Division_Users__c terrDivisionUser : terrDivision.TerritoryDivisionUsers__r){
					TSDsByDivisionAndTerritory.get(terrDivision.TM_DivisionId__c).get(terrDivision.TM_TerritoryId__c).add(terrDivisionUser);
					TerritoryIds.add(terrDivision.TM_TerritoryId__c);

				}
			}
		}
	}

	/** 
	* @description Logic that defined what the scope of the batch class is
	*/
	public Database.QueryLocator start(Database.BatchableContext context) {
		try{
			// GET BATCH SCOPE
            return Database.getQueryLocator([SELECT Id, Name, OwnerId, Industry, Type, TM_Territory_ManagerId__c, Customer_Success_Manager__c, TM_Manager_Hold__c, CSM_Manager_Hold__c, 
            										RM_Manager_Hold__c, TM_Segment_TerritoryId__c, TM_SegmentId__c, TM_Division_TerritoryId__c, TM_DivisionId__c
            								 FROM Account 
											 WHERE (TM_Segment_TerritoryId__c IN :TerritoryIds OR TM_Division_TerritoryId__c IN :TerritoryIds)
											 AND (TM_SegmentId__c IN :TSUsBySegmentAndTerritory.keySet() OR TM_DivisionId__c IN :TSDsByDivisionAndTerritory.keySet())]);
		}
		catch(Exception ex){
			SystemIssueLogHelper.LogException('BatchableTerritoryManagement', 'start', null, ex, true);
			return Database.getQueryLocator([SELECT Id FROM Account WHERE Id = null]);
		}
	}

	/**
	* @description Logic to be performed on scope
	*/
   	public void execute(Database.BatchableContext context, List<Account> scope) {
		try{
			// GET TEAM MEMBERS RELATED TO THE ACCOUNTS
			Map<Id, List<AccountTeamMember>> teamMembersByAccount = new Map<Id, List<AccountTeamMember>>();
			for(AccountTeamMember member : [SELECT Id, AccountId, TeamMemberRole, UserId FROM AccountTeamMember WHERE AccountId IN :scope]){
				if(!teamMembersByAccount.containsKey(member.AccountId)){
					teamMembersByAccount.put(member.AccountId, new List<AccountTeamMember>());
				}
				teamMembersByAccount.get(member.AccountId).add(member);
			}

            // FIND RECORDS THAT NEED TO BE CREATED / DELETED
            List<AccountTeamMember> accountMembersToCreate = new List<AccountTeamMember>();
            List<AccountTeamMember> accountMembersToDelete = new List<AccountTeamMember>();
            for(Account acct : scope){
            	String accountIndustry = (String.isBlank(acct.Industry) ? 'None' : acct.Industry);

            	// GET THE MOST RECENT TM USING ACCOUNT TERRITORY SEGMENT AND INDUSTRY
            	Id latestTMUserId;
            	if(TSUsBySegmentAndTerritory.containsKey(acct.TM_SegmentId__c) && TSUsBySegmentAndTerritory.get(acct.TM_SegmentId__c).containsKey(acct.TM_Segment_TerritoryId__c)){
            		for(TM_Territory_Segment_Users__c terrSegmentUser : TSUsBySegmentAndTerritory.get(acct.TM_SegmentId__c).get(acct.TM_Segment_TerritoryId__c)){
						if(terrSegmentUser.Applicable_Industries__c.contains(accountIndustry)){
							latestTMUserId = terrSegmentUser.Assigned_TM_UserId__c;
							break;
						}
					}

					// IF AN INDUSTRY MATCH WAS NOT FOUND, DEFAULT TO THE TM ON THE RECORD THAT HAS THE -- BLANK INDUSTRY -- PICKLIST VALUE
					if(latestTMUserId == null){
	                    for(TM_Territory_Segment_Users__c terrSegmentUser : TSUsBySegmentAndTerritory.get(acct.TM_SegmentId__c).get(acct.TM_Segment_TerritoryId__c)){
	                        if(terrSegmentUser.Applicable_Industries__c.contains('None')){
	                            latestTMUserId = terrSegmentUser.Assigned_TM_UserId__c;
	                            break;
	                        }
	                    }
	                }
            	}

            	// GET THE MOST RECENT CSM AND RM USING ACCOUNT TERRITORY DIVISION
				Id latestCSMUserId;
            	Id latestRMUserId;
            	if(TSDsByDivisionAndTerritory.containsKey(acct.TM_DivisionId__c) && TSDsByDivisionAndTerritory.get(acct.TM_DivisionId__c).containsKey(acct.TM_Division_TerritoryId__c)){
            		for(TM_Territory_Division_Users__c terrDivisionUser : TSDsByDivisionAndTerritory.get(acct.TM_DivisionId__c).get(acct.TM_Division_TerritoryId__c)){
						latestCSMUserId = terrDivisionUser.Assigned_CSM_UserId__c;
						latestRMUserId = terrDivisionUser.Assigned_RM_UserId__c;
						break;	
					}
            	}

				// GET USERS FROM ACCOUNT MEMBERS
            	AccountTeamMember acctTMMember;
            	AccountTeamMember acctCSMMember;
            	AccountTeamMember acctRMMember;
            	if(teamMembersByAccount.containsKey(acct.Id)){
	            	for(AccountTeamMember member : teamMembersByAccount.get(acct.Id)){
	            		if(member.TeamMemberRole == TMROLENAME && acctTMMember == null){
	            			acctTMMember = member;
	            		}

	            		if(member.TeamMemberRole == CSMROLENAME && acctCSMMember == null){
							acctCSMMember = member;
	            		}

	            		if(member.TeamMemberRole == RMROLENAME && acctRMMember == null){
							acctRMMember = member;
	            		}
	            	}
	            }

	            // PROCESS ACCOUNT TM MEMBER CHANGES
            	if(latestTMUserId != null && !acct.TM_Manager_Hold__c && RolesQualifyingForUpdate.contains(TMROLENAME)){
            		if(acctTMMember == null || acctTMMember.UserId != latestTMUserId){
            			accountMembersToCreate.add(new AccountTeamMember(AccountId = acct.Id, UserId = latestTMUserId, TeamMemberRole = TMROLENAME));

            			if(acctTMMember != null){
		            		// DELETE OLD MEMBER, NO LONGER VALID
		            		accountMembersToDelete.add(acctTMMember);            				
            			}
            		}
            	}

	            // PROCESS ACCOUNT CSM MEMBER CHANGES
            	if(latestCSMUserId != null && ACTIVECUSTOMERTYPES.contains(acct.Type) && !acct.CSM_Manager_Hold__c && RolesQualifyingForUpdate.contains(CSMROLENAME)){
            		if(acctCSMMember == null || acctCSMMember.UserId != latestCSMUserId){
            			accountMembersToCreate.add(new AccountTeamMember(AccountId = acct.Id, UserId = latestCSMUserId, TeamMemberRole = CSMROLENAME));
            			
            			if(acctCSMMember != null){
		            		// DELETE OLD MEMBER, NO LONGER VALID
		            		accountMembersToDelete.add(acctCSMMember);            				
            			}
            		}
            	}

	            // PROCESS ACCOUNT RM MEMBER CHANGES
            	if(latestRMUserId != null && ACTIVECUSTOMERTYPES.contains(acct.Type) && !acct.RM_Manager_Hold__c && RolesQualifyingForUpdate.contains(RMROLENAME)){
            		if(acctRMMember == null || acctRMMember.UserId != latestRMUserId){
            			accountMembersToCreate.add(new AccountTeamMember(AccountId = acct.Id, UserId = latestRMUserId, TeamMemberRole = RMROLENAME));
            			
            			if(acctRMMember != null){
		            		// DELETE OLD MEMBER, NO LONGER VALID
		            		accountMembersToDelete.add(acctRMMember);            				
            			}
            		}
            	}
            }

			// DELETE INVALID ACCOUNT TEAM MEMBERS
			if(!accountMembersToDelete.isEmpty()){
				Database.DeleteResult[] accountTMDeleteResults = Database.delete(accountMembersToDelete, false);
				SystemIssueLogHelper.CheckForDatabaseErrors(accountTMDeleteResults, 'BatchableTerritoryManagement', 'execute', false);
			}

            // CREATE ACCOUNT TEAM MEMBERS
			if(!accountMembersToCreate.isEmpty()){
				Database.SaveResult[] accountTMCreateResults = Database.insert(accountMembersToCreate, false);
				SystemIssueLogHelper.CheckForDatabaseErrors(accountTMCreateResults, 'BatchableTerritoryManagement', 'execute', false);
			}

			// GET UPDATE COUNTS
			NumberofAccountsUpdated += (AccountTeamMemberHelper.NumberofAccountsUpdated == null ? 0 : AccountTeamMemberHelper.NumberofAccountsUpdated);
			NumberofContactsUpdated += (AccountTeamMemberHelper.NumberofContactsUpdated == null ? 0 : AccountTeamMemberHelper.NumberofContactsUpdated);
			NumberofOppsUpdated += (AccountTeamMemberHelper.NumberofOppsUpdated == null ? 0 : AccountTeamMemberHelper.NumberofOppsUpdated);

			// SAVE ANY ERRORS
			SystemIssueLogHelper.UpsertExceptions();
		}
		catch(Exception ex){
			SystemIssueLogHelper.LogException('BatchableTerritoryManagement', 'execute', scope, ex, true);
		}
	}
	
	/** 
	* @description Code to fire when all batches are complete
	*/
	public void finish(Database.BatchableContext context) {
		try{
			// ALL RECORDS UPDATED, SEND COMPLETION MESSAGE
			if(SendEmail){
				AsyncApexJob asyncJob = [SELECT Id, Status, CreatedById, CreatedBy.FirstName FROM AsyncApexJob WHERE Id = :context.getJobId()];
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

				// GET EMAIL TEMPLATE			
				List<EmailTemplate> emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Territory_Management_Update_Complete'];
				if(emailTemplate != null && emailTemplate.size() == 1){
					List<String> stringFormatValues = new List<String>();
					stringFormatValues.add(asyncJob.CreatedBy.FirstName);
						
					String segmentChanges = '';
					String divisionChanges = '';
					if(UpdateInfoForEmail != null){

						// BUILD SEGMENT CHANGE LIST
						if(UpdateInfoForEmail.containsKey('Segment') && !UpdateInfoForEmail.get('Segment').isEmpty()){
							for(String segmentChange : UpdateInfoForEmail.get('Segment')){
								segmentChanges += '<li>' + segmentChange + '</il>\r\n';
							}
						}
						else{
							segmentChanges = 'None';
						}

						// BUILD DIVISION CHANGE LIST
						if(UpdateInfoForEmail.containsKey('Division') && !UpdateInfoForEmail.get('Division').isEmpty()){
							for(String divisionChange : UpdateInfoForEmail.get('Division')){
								divisionChanges += '<li>' + divisionChange + '</il>\r\n';
							}
						}
						else{
							divisionChanges = 'None';
						}
					}

					stringFormatValues.add(segmentChanges);
					stringFormatValues.add(divisionChanges);
					stringFormatValues.add(String.valueOf(NumberofAccountsUpdated));
					stringFormatValues.add(String.valueOf(NumberofOppsUpdated));					
					stringFormatValues.add(String.valueOf(NumberofContactsUpdated));

					// REPLACE HTML TEMPLATE MERGE TAGS
					emailTemplate[0].HtmlValue = String.format(emailTemplate[0].HtmlValue, stringFormatValues);

					// STRIP HTML TAGS FOR TEXT BODY
					stringFormatValues[1] = stringFormatValues[1].replace('<li>', '').replace('</il>', '');
					stringFormatValues[2] = stringFormatValues[2].replace('<li>', '').replace('</il>', '');

					// REPLACE TEXT TEMPLATE MERGE TAGS
					emailTemplate[0].Body = String.format(emailTemplate[0].Body, stringFormatValues);

					// BUILD EMAIL
					email.setSubject(emailTemplate[0].Subject);
					email.setHtmlBody(emailTemplate[0].HtmlValue);
					email.setPlainTextBody(emailTemplate[0].Body);
				}

				// ADD RECIPIENTS AND SEND EMAIL IF IT HAS BEEN BUILT
				if(String.isNotBlank(email.subject) && !Test.isRunningTest()){
					email.setToAddresses(new List<Id>{ asyncJob.CreatedById });
					Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email }, true);
				}
			}
		}
		catch(Exception ex){
			SystemIssueLogHelper.LogException('BatchableTerritoryManagement', 'finish', null, ex, true);
		}
	}


}