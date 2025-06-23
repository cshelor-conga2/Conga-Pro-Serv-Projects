/**
* @author Conga Services, ERedding
* @date 20180914
* @description CampaignMemberHelper - Contains custom functionality for the CampaignMember object including helper methods and trigger methods
*/
public without sharing class CampaignMemberHelper {

    // PARDOT HOUSE LIST CAMPAIGN
    public static Id PardotHouseListId {
    get {
        if(PardotHouseListId == null){
            for(Campaign campaign : [SELECT Id FROM Campaign WHERE Name = 'Pardot - House List' LIMIT 1]){
                PardotHouseListId = campaign.Id;
            }
        }
        return PardotHouseListId;
    } set; }


    /**
    * @description setMostRecentCampaign - Updates the Most_Recent_Campaign_Date__c and Most_Recent_Campaign__c fields on the CampaignMembers Contact/Lead when the member responds.
    * @param List<CampaignMember> newOrUpdatedMembers - New or Updated CampaignMember records
    * @param Map<Id, CampaignMember> outdatedMembers - Outdated CampaignMember records
    * @return void
    */
    public static void setMostRecentCampaign(List<CampaignMember> newOrUpdatedMembers, Map<Id, CampaignMember> outdatedMembers){
        try{        
            if(TriggerHelper.DoExecute('CampaignMemberHelper','setMostRecentCampaign') && newOrUpdatedMembers != null){

                // GET NECESSARY CAMPAIGN MEMBER AND RELATED DATA
                Map<Id, CampaignMember> memberData = new Map<Id, CampaignMember>([SELECT Id, HasResponded, FirstRespondedDate, Campaign.Name, ContactId, Contact.Most_Recent_Campaign_Date__c,
                                                                                  LeadId, Lead.Most_Recent_Campaign_Date__c FROM CampaignMember 
                                                                                  WHERE Id IN :newOrUpdatedMembers
                                                                                  AND CampaignId != :PardotHouseListId
                                                                                  ORDER BY LastModifiedDate]);

                // CHECK EACH CAMPAIGN MEMBER. IF A CONTACT OR LEAD HAS MULTIPLE UPDATED CAMPAIGN MEMBERS, USE THE DATE AND CAMPAIGN NAME FROM THE ONE MOST RECENTLY MODIFIED
                Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
                Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();
                for(CampaignMember newOrUpdatedMember : memberData.values()){
                    CampaignMember outdatedMember = outdatedMembers != null ? outdatedMembers.get(newOrUpdatedMember.Id) : null;

                    if(newOrUpdatedMember.HasResponded == true && newOrUpdatedMember.FirstRespondedDate != null && 
                        (outdatedMember == null || newOrUpdatedMember.HasResponded != outdatedMember.HasResponded || newOrUpdatedMember.FirstRespondedDate != outdatedMember.FirstRespondedDate)){

                        // CONTACT NEED UPDATING?
                        if(newOrUpdatedMember.ContactId != null && (newOrUpdatedMember.Contact.Most_Recent_Campaign_Date__c == null ||
                                                                    newOrUpdatedMember.FirstRespondedDate >= newOrUpdatedMember.Contact.Most_Recent_Campaign_Date__c)){

                            contactsToUpdate.put(newOrUpdatedMember.ContactId, new Contact(Id = newOrUpdatedMember.ContactId,
                                                                                    Most_Recent_Campaign_Date__c = newOrUpdatedMember.FirstRespondedDate, 
                                                                                    Most_Recent_Campaign__c = newOrUpdatedMember.Campaign.Name));
                        }
                        // LEAD NEED UPDATING?
                        else if(newOrUpdatedMember.LeadId != null && (newOrUpdatedMember.Lead.Most_Recent_Campaign_Date__c == null ||
                                                                      newOrUpdatedMember.FirstRespondedDate >= newOrUpdatedMember.Lead.Most_Recent_Campaign_Date__c)){
                            
                            leadsToUpdate.put(newOrUpdatedMember.LeadId, new Lead(Id = newOrUpdatedMember.LeadId,
                                                                                    Most_Recent_Campaign_Date__c = newOrUpdatedMember.FirstRespondedDate, 
                                                                                    Most_Recent_Campaign__c = newOrUpdatedMember.Campaign.Name));
                        }
                    }
                }

                // SAVE CONTACT CHANGES
                if(!contactsToUpdate.isEmpty()){
                    Database.SaveResult[] contactResults = Database.update(contactsToUpdate.values(), false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(contactResults, 'CampaignMemberHelper', 'setMostRecentCampaign', false);                    
                }

                // SAVE LEAD CHANGES
                if(!leadsToUpdate.isEmpty()){
                    Database.SaveResult[] leadResults = Database.update(leadsToUpdate.values(), false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(leadResults, 'CampaignMemberHelper', 'setMostRecentCampaign', false);                   
                }

                // SAVE LOGGED ERRORS
                SystemIssueLogHelper.UpsertExceptions();

                TriggerHelper.EndExecute('CampaignMemberHelper', 'setMostRecentCampaign');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('CampaignMemberHelper', 'setMostRecentCampaign', newOrUpdatedMembers, ex, true);
        }
    }

    /**
    * @author Conga Services
    * @date 20180919
    * @version 1.00
    * @description updateLeadProductInterest - Updates a Lead's Product Interest based on its Campaign Members
    *                                          EXECUTED BY A CAMPAIGN MEMBER AFTER INSERT TRIGGER HANDLER
    */  
    public static void updateLeadProductInterest(List<CampaignMember> newOrUpdatedMembers){
        if(TriggerHelper.DoExecute('CampaignMemberHelper','updateLeadProductInterest') && newOrUpdatedMembers != null && !newOrUpdatedMembers.isEmpty()){
            try{
                // GET LEADS IDS AND PARENT CAMPAIGNS FROM QUALIFYING CAMPAIGN MEMBERS
                Set<Id> qualifyingLeadIds = new Set<Id>();
                for(CampaignMember member : newOrUpdatedMembers){
                    if(member.LeadId != null){
                        // MEMBER HAS A LEAD, QUALIFIED
                        qualifyingLeadIds.add(member.LeadId);
                    }
                }

                if(!qualifyingLeadIds.isEmpty()){
                    // GET LEAD DATA AND PRODUCTS INTERESTS FROM CAMPAIGN MEMBERS
                    Map<Id, Lead> qualifiedLeadsMap = new Map<Id, Lead>();
                    Map<Id, Set<String>> productInterestsByLeadId = new Map<Id, Set<String>>();
                    for(CampaignMember existingMember : [SELECT Id, Campaign.Product_Interest__c, LeadId, Lead.Product_Interest__c, Lead.Block_Product_Interest_Owner_Update__c 
                                                         FROM CampaignMember WHERE LeadId IN :qualifyingLeadIds AND Campaign.Product_Interest__c != null AND CampaignId != :PardotHouseListId]){
                        if(!qualifiedLeadsMap.containsKey(existingMember.LeadId)){
                            qualifiedLeadsMap.put(existingMember.LeadId, existingMember.Lead);
                        }

                        if(!productInterestsByLeadId.containsKey(existingMember.LeadId)){
                            productInterestsByLeadId.put(existingMember.LeadId, new Set<String>());
                        }
                        productInterestsByLeadId.get(existingMember.LeadId).add(existingMember.Campaign.Product_Interest__c);
                    }

                    // GET USER ASSIGNED TO ROUND ROBIN 0 IN THE LMA_Lead_Owner_Round_Robin__c CUSTOM SETTINGS
                    List<LMA_Lead_Owner_Round_Robin__c> roundRobinZeroOwner = [SELECT Lead_Owner_Id__c FROM LMA_Lead_Owner_Round_Robin__c WHERE Round_Robin_Number__c = 0];

                    // LOOP OVER EACH LEAD AND CHECK CAMPAIGN MEMBERS
                    List<Lead> leadsToUpdate = new List<Lead>();
                    if(!roundRobinZeroOwner.isEmpty()){
                        for(Lead lead : qualifiedLeadsMap.values()){
                            if(productInterestsByLeadId.containsKey(lead.Id)){
                                String currentProductInterest = lead.Product_Interest__c;
                                String campaignProductInterest = '';
                                for(String campaignInterest : productInterestsByLeadId.get(lead.Id)){
                                    campaignProductInterest = campaignInterest;
                                    break;
                                }

                                // LEAD HAS ONE MEMBER OR ALL MEMBERS BELONG TO CAMPAIGNS WITH THE SAME INTEREST TYPE, UPDATE IF CURRENT VALUE DOES NOT MATCH CAMPAIGN VALUE
                                if(productInterestsByLeadId.get(lead.Id).size() == 1 && (String.isBlank(currentProductInterest) || currentProductInterest != campaignProductInterest)){
                                    lead.Product_Interest__c = campaignProductInterest;
                                    leadsToUpdate.add(lead);
                                }
                                // LEAD HAS MULTIPLE MEMBERS FROM CAMPAIGNS WITH VARIOUS PRODUCT INTERESTS. DEFAULT TO MULTIPLE PRODUCTS IF NECESSARY
                                else if(productInterestsByLeadId.get(lead.Id).size() > 1 && (String.isBlank(currentProductInterest) || currentProductInterest != 'Multiple Product')){
                                    lead.Product_Interest__c = 'Multiple Product';
                                    leadsToUpdate.add(lead);
                                }
                            }
                        }

                        // UPDATE LEADS
                        if(!leadsToUpdate.isEmpty()){
                            Database.SaveResult[] updateResults = Database.update(leadsToUpdate, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'CampaignMemberHelper', 'updateLeadProductInterest', true);
                        }
                    }
                    else{
                        SystemIssueLogHelper.LogException('CampaignMemberHelper', 'updateLeadProductInterest', newOrUpdatedMembers, 'No LMA Lead Owner with Round Robin = 0 was found and must exist.', true);
                    }

                    TriggerHelper.EndExecute('CampaignMemberHelper', 'updateLeadProductInterest');
                }
            }
            catch(Exception ex){
                SystemIssueLogHelper.LogException('CampaignMemberHelper', 'updateLeadProductInterest', newOrUpdatedMembers, ex, true);
            }
        }
    }


}