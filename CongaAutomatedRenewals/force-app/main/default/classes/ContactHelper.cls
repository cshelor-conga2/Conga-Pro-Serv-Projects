/**
* @author Conga Services
* @date 20180522
* @version 1.00
* @description ContactHelper - Custom functionality for the Contact object
*/
public with sharing class ContactHelper {

    // APTTUS INTEGRATION CUSTOM METADATA
    public static Set<String> ApttusIntegrationSyncedContactFields {
    get {
        if(ApttusIntegrationSyncedContactFields == null){
            ApttusIntegrationSyncedContactFields = new Set<String>();
            for(Apttus_Integration_Synced_Fields__mdt syncedContactField : [SELECT Synced_Field__r.QualifiedApiName FROM Apttus_Integration_Synced_Fields__mdt
                                                                            WHERE Synced_Object__r.QualifiedApiName = 'Contact' AND Is_Active__c = true]){
                ApttusIntegrationSyncedContactFields.add(syncedContactField.Synced_Field__r.QualifiedApiName);
            }
        }
        return ApttusIntegrationSyncedContactFields;
    } set; }



    /**
    * @author ERedding, GTM
    * @date 20201111
    * @description setApttusIntegrationStatuses - Sets the appropriate Apttus Integration Status values when applicable updates are made to a contact
    *                                               --- EXECUTED BY ACCOUNT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---       
    * @param List<Contact> newOrUpdatedContacts - Updated Contact records
    * @param Map<Id, Contact> outdatedContacts - Outdated Contact records
    * @return void
    */
    public static void setApttusIntegrationStatuses(List<Contact> newOrUpdatedContacts, Map<Id, Contact> outdatedContacts){
        try{
            if(TriggerHelper.DoExecute('ContactHelper','setApttusIntegrationStatuses') && newOrUpdatedContacts != null && UserInfo.getUserId() != '0051T000009Ct4iQAC'){// APTTUS INTEGRATION USER

                //// PROCESS CONTACTS
                for(Contact newOrUpdatedContact : newOrUpdatedContacts){
                    Contact outdatedContact = outdatedContacts != null ? outdatedContacts.get(newOrUpdatedContact.Id) : null;

                    // CONTACT IS NEW
                    if(outdatedContact == null){
                        newOrUpdatedContact.A1_Integration_Status__c = 'Eligible';
                    }
                    // CONTACT WAS CHANGED, CHECK SYNCED FIELDS FOR CHANGES
                    else if(outdatedContact != null && String.isNotBlank(newOrUpdatedContact.A1_Contact_ID__c) && ApttusIntegrationSyncedContactFields != null){
                        for(String contactField : ApttusIntegrationSyncedContactFields){
                            // NOT A COMPOUND FIELD, COMPARE FIELD TO FIELD
                            if(newOrUpdatedContact.get(contactField) != outdatedContact.get(contactField)){
                                newOrUpdatedContact.A1_Integration_Status__c = 'Eligible';
                                break;
                            }

                            // CANNOT REFERENCE A COMPOUND FIELD'S PARTS IN CUSTOM METADATA SO CHECK THE INNER FIELDS MANUALLY
                            if(contactField == 'Name' && 
                                (newOrUpdatedContact.FirstName != outdatedContact.FirstName || newOrUpdatedContact.LastName != outdatedContact.LastName || 
                                 newOrUpdatedContact.Salutation != outdatedContact.Salutation || newOrUpdatedContact.Suffix != outdatedContact.Suffix)){

                                newOrUpdatedContact.A1_Integration_Status__c = 'Eligible';
                                break;
                            }
                            else if(contactField == 'MailingAddress' && 
                                    (newOrUpdatedContact.MailingStreet != outdatedContact.MailingStreet || newOrUpdatedContact.MailingCity != outdatedContact.MailingCity || 
                                     newOrUpdatedContact.MailingState != outdatedContact.MailingState || newOrUpdatedContact.MailingCountry != outdatedContact.MailingCountry ||
                                     newOrUpdatedContact.MailingPostalCode != outdatedContact.MailingPostalCode)){

                                newOrUpdatedContact.A1_Integration_Status__c = 'Eligible';
                                break;
                            }
                            else if(contactField == 'OtherAddress' && 
                                    (newOrUpdatedContact.OtherStreet != outdatedContact.OtherStreet || newOrUpdatedContact.OtherCity != outdatedContact.OtherCity || 
                                     newOrUpdatedContact.OtherState != outdatedContact.OtherState || newOrUpdatedContact.OtherCountry != outdatedContact.OtherCountry ||
                                     newOrUpdatedContact.OtherPostalCode != outdatedContact.OtherPostalCode)){

                                newOrUpdatedContact.A1_Integration_Status__c = 'Eligible';
                                break;
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('ContactHelper', 'setApttusIntegrationStatuses');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('ContactHelper', 'setApttusIntegrationStatuses', newOrUpdatedContacts, ex, true);
        }
    }

    /**
    * @date 20200922
    * @description setApttusIntegrationOwner - Sets the appropriate Contact Owner matching the A1 Org using the email address provided by the integration
    *                                           --- EXECUTED BY CONTACT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---       
    * @param List<Contact> newOrUpdatedContacts - Updated Contact records
    * @param Map<Id, Contact> outdatedContacts - Outdated Contact records
    * @return void
    */
    public static void setApttusIntegrationOwner(List<Contact> newOrUpdatedContacts, Map<Id, Contact> outdatedContacts){
        try{
            if(TriggerHelper.DoExecute('ContactHelper','setApttusIntegrationOwner') && newOrUpdatedContacts != null && (UserInfo.getUserId() == '0051T000009Ct4iQAC' || Test.isRunningTest())){
                                                                                                                                    // APTTUS INTEGRATION USER -OR- RUNNING TEST

                // GET A1 OWNER EMAIL ADDRESSES FROM ACCOUNTS
                List<Contact> qualifyingContacts = new List<Contact>();
                Set<String> ownerEmails = new Set<String>();
                for(Contact newOrUpdatedContact : newOrUpdatedContacts){
                    Contact outdatedContact = outdatedContacts != null ? outdatedContacts.get(newOrUpdatedContact.Id) : null;
                    if(String.isNotBlank(newOrUpdatedContact.A1_Owner_Email__c) && (outdatedContact == null || newOrUpdatedContact.A1_Owner_Email__c != outdatedContact.A1_Owner_Email__c)){
                        qualifyingContacts.add(newOrUpdatedContact);
                        ownerEmails.add(newOrUpdatedContact.A1_Owner_Email__c);
                    }
                }

                if(!ownerEmails.isEmpty()){

                    // GET USERS MATCHING EMAIL ADDRESSES
                    Map<String, Id> usersByEmail = new Map<String, Id>();
                    for(User user : [SELECT Id, Email FROM User WHERE Email IN :ownerEmails AND Profile.UserLicense.Name = 'Salesforce']){
                        usersByEmail.put(user.Email, user.Id);
                    }

                    // PROCESS CONTACTS
                    for(Contact qualifyingContact : qualifyingContacts){
                        qualifyingContact.OwnerId = usersByEmail.containsKey(qualifyingContact.A1_Owner_Email__c) ? usersByEmail.get(qualifyingContact.A1_Owner_Email__c) : UserInfo.getUserId();
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('ContactHelper', 'setApttusIntegrationOwner');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('ContactHelper', 'setApttusIntegrationOwner', newOrUpdatedContacts, ex, true);
        }
    }

    /**
    * @author ERedding, GTM
    * @date 20201203
    * @description removeDepartedFromLastName - Checks a contact lastname for the 'departed' keyword in various formats and removes, setting Contact Status instead
    *                                               --- EXECUTED BY ACCOUNT BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---       
    * @param List<Contact> newOrUpdatedContacts - New or Updated Contact records
    * @return void
    */
    public static void removeDepartedFromLastName(List<Contact> newOrUpdatedContacts){
        try{
            if(TriggerHelper.DoExecute('ContactHelper','removeDepartedFromLastName') && newOrUpdatedContacts != null){

                // PROCESS NEW OR UPDATED CONTACTS
                for(Contact contact : newOrUpdatedContacts){
                    Set<String> departedValues = new Set<String>{ 
                        '- Departed', '-Departed', ', Departed',  ',Departed', 'Departed', '(Departed)'
                    };

                    // SEARCH LAST NAME FOR THE DEPARTED KEYWORD. IF FOUND, REMOVE AND SET THE CONTACT STATUS
                    if(contact.LastName.containsIgnoreCase('departed')){
                        for(String departedValue : departedValues){
                            contact.LastName = contact.LastName.removeEndIgnoreCase(departedValue).trim();
                        }

                        contact.Contact_Status__c = 'Departed';
                    }
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('ContactHelper', 'removeDepartedFromLastName', newOrUpdatedContacts, ex, true);
        }
    }

    /**
    * @date 20180918
    * @description addCampaignMembers - Updates a Contact's campaigns through its campaign members. Uses the Campaign Id or Ids specified in the SF_Campaign_ID__c field
    * @param Map<Id, Contact> updatedContacts - Map of updated contacts
    * @param Map<Id, Contact> outdatedContacts - Map of outdated contacts
    * @return void
    */
    public static void addCampaignMembers(Map<Id, Contact> updatedContacts, Map<Id, Contact> outdatedContacts){
        try{
            if(TriggerHelper.DoExecute('ContactHelper','addCampaignMembers') && updatedContacts != null && outdatedContacts != null){
                // GET QUALIFIED CONTACTS
                List<Contact> qualifiedContacts = new List<Contact>();
                for(Contact updatedContact : updatedContacts.values()){
                    if(String.isNotBlank(updatedContact.SF_Campaign_ID__c) && updatedContact.SF_Campaign_ID__c != outdatedContacts.get(updatedContact.Id).SF_Campaign_ID__c){
                        qualifiedContacts.add(updatedContact);
                    }
                }

                if(!qualifiedContacts.isEmpty()){
                    // GET IDS OF ALL ACTIVE CAMPAIGNS
                    Set<Id> activeCampaignIds = new Set<Id>();
                    for(Campaign campaign : [SELECT Id, Name FROM Campaign WHERE IsActive = TRUE]){
                        activeCampaignIds.add(campaign.Id);
                    }
                    
                    // LOOP OVER CONTACTS, GET CAMPAIGN IDS FROM EACH
                    Map<Id,Set<Id>> contactCampaignIdsMap = new Map<Id,Set<Id>>();
                    Set<Id> campaignIds = new Set<Id>();
                    for(Contact contact : qualifiedContacts){
                        if(String.isNotBlank(contact.SF_Campaign_ID__c)){
                            for(String campaignId : contact.SF_Campaign_ID__c.split(';')){
                                if(UtilityClass.validateId(campaignId)){
                                    campaignIds.add((Id)campaignId);
                                    if(!contactCampaignIdsMap.containsKey(contact.Id)){
                                        contactCampaignIdsMap.put(contact.Id, new Set<Id>());
                                    }
                                    contactCampaignIdsMap.get(contact.Id).add((Id)campaignId);
                                }
                                else{
                                    SystemIssueLogHelper.LogException('ContactHelper', 'addCampaignMembers', contact.Id, 'Invalid Campaign Id: ' + campaignId, false);        
                                }
                            }
                        }
                    }

                    if(!contactCampaignIdsMap.isEmpty()){
                        // REMOVE ANY INACTIVE CAMPAIGNS, WE DONT WANT TO ADD MEMBERS TO THEM
                        for(Id contactId : contactCampaignIdsMap.keySet()){
                            for(Id campaignId : contactCampaignIdsMap.get(contactId)){
                                // REMOVE CAMPAIGN FROM CONTACT IF ITS INACTIVE
                                if(!activeCampaignIDs.contains(campaignId)){
                                    contactCampaignIdsMap.get(contactId).remove(campaignId);
                                    campaignIds.remove(campaignId);
                                }
                                // REMOVE CONTACT FROM MAP IF IT HAS NO CAMPAIGNS
                                if(contactCampaignIdsMap.get(contactId).isEmpty()){
                                    contactCampaignIdsMap.remove(contactId);
                                    break;
                                }
                            }
                        }
                        
                        if(!contactCampaignIdsMap.isEmpty()){
                            // GET EXISTING MEMBERSHIPS FOR THE CONTACTS AND CAMPAIGNS IN QUESTION
                            Map<Id,Set<Id>> contactExistingMembershipsMap = new Map<Id,Set<Id>>();
                            for(CampaignMember member : [SELECT Id, CampaignId, ContactId FROM CampaignMember WHERE ContactId IN :qualifiedContacts AND CampaignId IN :campaignIds]){
                                if(!contactExistingMembershipsMap.containsKey(member.ContactId)){
                                    contactExistingMembershipsMap.put(member.ContactId, new Set<Id>());
                                }
                                contactExistingMembershipsMap.get(member.ContactId).add(member.CampaignId);
                            }
                            
                            // LOOP THROUGH CONTACTS AND CREATE MEMBERSHIPS FOR EACH CAMPAIGN THE CONTACT IS NOT ALREADY A MEMBER OF
                            List<CampaignMember> newMembersToInsert = new list<CampaignMember>();
                            for(Contact contact : qualifiedContacts){
                                if(contactCampaignIdsMap.containsKey(contact.Id)){
                                    for(Id campaignId : contactCampaignIdsMap.get(contact.Id)){
                                        if(contactExistingMembershipsMap.containsKey(contact.Id) && contactExistingMembershipsMap.get(contact.Id).contains(campaignId)){
                                            continue; // MEMBERSHIP ALREADY EXISTS, SKIP
                                        }
                                        else{
                                            newMembersToInsert.add(new CampaignMember(ContactId = contact.Id, CampaignId = campaignId));
                                        }
                                    }
                                }
                            }

                            // COMMIT NEW MEMBERS TO THE DATABASE
                            if(!newMembersToInsert.isEmpty()){
                                Database.SaveResult[] insertResults = Database.insert(newMembersToInsert, false);
                                SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'ContactHelper', 'addCampaignMembers', false);
                            }
                        }
                    }
                    
                    // SAVE ANY LOGGED ERRORS
                    SystemIssueLogHelper.UpsertExceptions();

                    // END AUDIT IF ONE IS STARTED
                    TriggerHelper.EndExecute('ContactHelper', 'addCampaignMembers');
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('ContactHelper', 'addCampaignMembers', updatedContacts, ex, true);
        }
    }

    /**
    * @description validateStateAndCountry - Validate State and Country values on Mailing and Other addresses
    * @param List<Contact> newOrUpdatedContacts - New or Updated Contact records
    * @param Map<Id, Contact> outdatedContacts - Outdated Contact records
    * @return void
    */
    public static void validateStateAndCountry(List<Contact> newOrUpdatedContacts, Map<Id, Contact> outdatedContacts){
        try{        
            if(TriggerHelper.DoExecute('ContactHelper','validateStateAndCountry') && newOrUpdatedContacts != null && !newOrUpdatedContacts.isEmpty()){
                // GET CONTACTS WITH QUALIFYING CHANGES
                List<Contact> qualifiedContacts = new List<Contact>();
                for(Contact newOrUpdatedContact : newOrUpdatedContacts){
                    Contact outdatedContact = outdatedContacts != null ? outdatedContacts.get(newOrUpdatedContact.Id) : null;
                    if(outdatedContact == null || (outdatedContact != null && (newOrUpdatedContact.MailingState != outdatedContact.MailingState || 
                                                                               newOrUpdatedContact.MailingCountry != outdatedContact.MailingCountry ||
                                                                               newOrUpdatedContact.OtherState != outdatedContact.OtherState ||
                                                                               newOrUpdatedContact.OtherCountry != outdatedContact.OtherCountry))){
                        qualifiedContacts.add(newOrUpdatedContact);
                    }
                }

                if(!qualifiedContacts.isEmpty()){
                    // GET STATE AND COUNTRY FIELDS NAMES
                    Map<String,String> countryStateFieldPairs = new Map<String,String>{ Contact.MailingCountry.getDescribe().getName() => Contact.MailingState.getDescribe().getName(), 
                                                                                        Contact.OtherCountry.getDescribe().getName() => Contact.OtherState.getDescribe().getName() };
                    for(Contact contact : qualifiedContacts){
                        StateAndCountryValidation.validateRecordCountryStatePairs(contact, countryStateFieldPairs);

                        // SET COUNTRY AND STATE NAME/CODE FIELDS FOR ACCOUNT
                        contact.Mailing_Country_Code__c = StateAndCountryValidation.CountryTwoLetterCodeByFullName.get(contact.MailingCountry);
                        contact.Other_Country_Code__c = StateAndCountryValidation.CountryTwoLetterCodeByFullName.get(contact.OtherCountry);

                        if(StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.containsKey(contact.MailingCountry)){
                            contact.Mailing_State_Code__c =  StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.get(contact.MailingCountry).get(contact.MailingState);
                        }

                        if(StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.containsKey(contact.OtherCountry)){
                            contact.Other_State_Code__c = StateAndCountryValidation.StateCodesByCountryFullNameAndStateFullName.get(contact.OtherCountry).get(contact.OtherState);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('ContactHelper', 'validateStateAndCountry');
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('ContactHelper', 'validateStateAndCountry', newOrUpdatedContacts, ex, true);
        }
    }


}