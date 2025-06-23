/**
* @author Conga Services, KSears
* @date 20170228
* @version 1.00
* @description CreateProjectController 
*/
public with sharing class CreateProjectController {
    public List<Opportunity> oppList {get;set;}
    public Set<Id> oppIds {get;set;}
    String idString = ApexPages.currentPage().getParameters().get('id');

    /**
    * @description Constructor 1
    * @param ApexPages.StandardController stController
    */
    public CreateProjectController (ApexPages.StandardController stController){
        oppList = new List<Opportunity>();
        oppIds = new Set<Id>();

        oppIds.add(stController.getRecord().id);

        if(oppIds.size() > 0){
            oppList = [SELECT Id, Name, AccountId, CloseDate,
                        (SELECT Id, OpportunityId, Product2Id, Product2.Name, Product2.Hourly_Rate__c, Quantity, UnitPrice, 
                                Product2.Hours__c, PricebookEntryId, PricebookEntry.Pricebook2Id
                         FROM OpportunityLineItems WHERE Product2.Family = 'Professional Services'),
                        (SELECT Id, OpportunityId, Role, ContactId FROM OpportunityContactRoles) 
                       FROM Opportunity WHERE Id IN :oppIds];
        }
    }

    /**
    * @description Constructor 2
    * @param ApexPages.StandardSetController stSetController
    */
    public CreateProjectController (ApexPages.StandardSetController stSetController){
        oppList = new List<Opportunity>();
        oppIds = new Set<Id>();

        for(SObject opp : stSetController.getSelected()){
            oppIds.add(opp.Id);
        }

        if(oppIds.size() > 0){
            oppList = [SELECT Id, Name, AccountId, CloseDate,
                        (SELECT Id, OpportunityId, Product2Id, Product2.Name, Product2.Hourly_Rate__c, Quantity, UnitPrice, 
                                Product2.Hours__c, PricebookEntryId, PricebookEntry.Pricebook2Id
                         FROM OpportunityLineItems WHERE Product2.Family = 'Professional Services'),
                        (SELECT Id, OpportunityId, Role, ContactId FROM OpportunityContactRoles) 
                       FROM Opportunity WHERE Id IN :oppIds];
        }
    }

    /**
    * @description autoRun
    * @return PageReference
    */
    public PageReference autoRun(){
        PageReference page = new PageReference('/a1j/o');

        if(oppList.size() == 0){
            if(idString != null){
                oppIds = new Set<Id>();
                for(String s : idString.split(',')){
                    oppIds.add(s);
                }
                if(oppIds.size() > 0){
                    oppList = [SELECT Id, Name, AccountId, CloseDate,
                                (SELECT Id, OpportunityId, Product2Id, Product2.Name, Product2.Hourly_Rate__c, Quantity, UnitPrice, 
                                        Product2.Hours__c, PricebookEntryId, PricebookEntry.Pricebook2Id
                                 FROM OpportunityLineItems WHERE Product2.Family = 'Professional Services'),
                                (SELECT Id, OpportunityId, Role, ContactId FROM OpportunityContactRoles) 
                               FROM Opportunity WHERE Id IN :oppIds];
                }               
            }
        }

        if(oppList.size() > 0){
            List<PS_Project__c> newProjects = new List<PS_Project__c>();
            List<Milestone__c> newMilestones = new List<Milestone__c>();
            List<Project_Team__c> newTeams = new List<Project_Team__c>();
            Map<Id, Id> oppProjMap = new Map<Id,Id>();

            for(Opportunity opp : oppList){
                PS_Project__c newProj = new PS_Project__c();
                newProj.Name = opp.Name;
                newProj.AccountId__c = opp.AccountId;
                newProj.OpportunityId__c = opp.Id;
                newProj.Execution__c = opp.CloseDate;
                if(opp.OpportunityLineItems.size() == 0){
                    newProj.Project_Type__c = 'Onboarding';
                }

                newProjects.add(newProj);
            }
            if(newProjects.size() > 0){
                Database.SaveResult[] insertProjectResults = Database.insert(newProjects, false);
                SystemIssueLogHelper.CheckForDatabaseErrors(insertProjectResults, 'CreateProjectController', 'autoRun', false);

                for(PS_Project__c newProj : newProjects){
                    for(Opportunity opp : oppList){
                        if(newProj.OpportunityId__c == opp.Id){
                            oppProjMap.put(opp.Id,newProj.Id);
                        }
                    }
                }
                //create new milestones from line items
                for(Opportunity opp : oppList){
                    if(opp.OpportunityLineItems.size() > 0){
                        for(OpportunityLineItem oli : opp.OpportunityLineItems){
                            Milestone__c newMile = new Milestone__c();
                            newMile.ProductId__c = oli.Product2Id;
                            newMile.PricebookId__c = oli.PricebookEntry.Pricebook2Id;
                            newMile.ProductId__c = oli.Product2Id;
                            newMile.Name = oli.Product2.Name;
                            if(oli.Product2.Hours__c == null){
                                newMile.Hours_Currently_Budgeted__c = oli.Quantity;
                            }
                            else{
                                newMile.Hours_Currently_Budgeted__c = oli.Product2.Hours__c;
                            }
                            if(oli.Product2.Hourly_Rate__c == null){
                                newMile.Effective_Hourly_Rate__c = oli.UnitPrice;
                            }
                            else{
                                newMile.Effective_Hourly_Rate__c = oli.Product2.Hourly_Rate__c;
                            }

                            if(oli.OpportunityId == opp.Id){
                                newMile.ProjectId__c = oppProjMap.get(opp.Id);
                            }

                            newMilestones.add(newMile);
                        }
                    }
                    //if there are no line items, create Onboarding Milestone
                    else{
                        Milestone__c newMile = new Milestone__c();
                        newMile.Name = 'Onboarding';
                        newMile.Hours_Currently_Budgeted__c = .75;
                        newMile.Effective_Hourly_Rate__c =  0;
                        newMile.ProjectId__c = oppProjMap.get(opp.Id);
                        newMilestones.add(newMile);
                    }
                    //create new project teams from contact roles
                    for(OpportunityContactRole ocr : opp.OpportunityContactRoles){
                        Project_Team__c newTeam = new Project_Team__c();
                        newTeam.Contact__c = ocr.ContactId;
                        newTeam.Opportunity_Role__c = ocr.Role;
                        if(ocr.OpportunityId == opp.Id){
                            newTeam.Project__c = oppProjMap.get(opp.Id);
                        }

                        newTeams.add(newTeam);
                    }   
                }

                if(newMilestones.size() > 0){
                    Database.SaveResult[] insertMilestoneResults = Database.insert(newMilestones, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(insertMilestoneResults, 'CreateProjectController', 'autoRun', false);
                }

                if(newTeams.size() > 0){
                    Database.SaveResult[] insertTeamResults = Database.insert(newTeams, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(insertTeamResults, 'CreateProjectController', 'autoRun', false);
                }

                // SAVE ANY LOGGED ERRORS TO THE DATABASE
                SystemIssueLogHelper.UpsertExceptions();
            }
        
        }
        return page.setRedirect(true);
    }


}