/**
* @author Conga Services
* @date 20160909
* @version 1.00
* @description ProjectCreateOrderController - Controller class for the Project_Create_Order VF page
*/
public with sharing class ProjectCreateOrderController {
    ApexPages.StandardController controller {get; set;}
    ApexPages.StandardSetController setController {get; set;}
    public List<String> SelectedProjectIds {get; set;}
    public List<ProjectOrderResult> Results {get;set;}
    protected List<PS_Project__c> CrmcProjects {get; set;}
    public List<SelectOption> Periods {get;set;}
    public String SelectedPeriodId {get;set;}
    public List<PricebookEntry> PricebookEntries {get;set;}
    public Id StandardPricebookId {get;set;}

    /**
    * @description ProjectCreateOrderController - Constructor taking a Standard Controller for a parameters
    * @param ApexPages.StandardController ctrl
    */
    public ProjectCreateOrderController(ApexPages.StandardController ctrl) {    
        SelectedProjectIds = new List<String>();
        controller = ctrl; 

        String projectId = System.currentPageReference().getParameters().get('id');  
        if(String.isNotBlank(projectId)){          
            SelectedProjectIds.add(projectId);
        }

        Initialize();
    }

    /**
    * @description ProjectCreateOrderController - Constructor taking a Standard SET Controller for a parameter
    * @param ApexPages.StandardSetController ctrl
    */   
    public ProjectCreateOrderController(ApexPages.StandardSetController ctrl) {    
        SelectedProjectIds = new List<String>();  
        setController = ctrl;  
        String projectRecordIds = ApexPages.currentPage().getParameters().get('projectRecordIds');
        if(String.isNotBlank(projectRecordIds)){
            SelectedProjectIds.addAll(projectRecordIds.split(','));
        }

        Initialize();
    }

    /**
    * @description Initialize - Initialization method
    * @return void
    */   
    public void Initialize(){ 
        Results = new List<ProjectOrderResult>();    
        Periods = new List<SelectOption>(); 
        for(Period__c week : [SELECT Id, Name, Start_Date__c, End_Date__c FROM Period__c 
                              WHERE Start_Date__c <= :Date.today() AND Start_Date__c >=: Date.today().addDays(-45) 
                              AND Type__c = 'Week' ORDER BY Start_Date__c]){

            Periods.add(new SelectOption(week.id,String.format('{0} - {1} to {2}', new List<String>{week.Name, String.valueOf(week.Start_Date__c), String.valueOf(week.End_Date__c)}) ));
        } 

        if(Periods.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are No Periods Defined'));  
        }

        //List<Period__c> weeks = [SELECT Id FROM Period__c WHERE Start_Date__c <=: Date.today().addDays(-7) AND End_Date__c >=: Date.today().addDays(-7) 
        //                         AND Type__c = 'Week' LIMIT 1]; 
        //if(weeks.size() > 0){
        //    SelectedPeriodId = weeks[0].Id;
        //}

        List<Pricebook2> standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE AND IsActive = TRUE LIMIT 1];
        if(standardPricebook.size() > 0){
            StandardPricebookId = standardPricebook[0].Id;
        }
    }

    /**
    * @description CreateOrder - Button click Create Order method
    * @return PageReference
    */   
    public PageReference CreateOrder(){ 
        return CreateOrdersForProjects(SelectedProjectIds);
    }

    /**
    * @description CreateOrdersForProjects - Created Orders for qualifying projects
    * @return PageReference
    */   
    public PageReference CreateOrdersForProjects(List<String> pProjectIds) {
        if(pProjectIds == null || pProjectIds.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Projects Have Been Selected')); 
            return null;
        }

        // Get All Active and Billable Milestones
        Period__c SelectedPeriod = null;
        if(String.isBlank(SelectedPeriodId)){
            List<Period__c> weeks = [SELECT Id, Name, Start_Date__c, End_Date__c FROM Period__c WHERE Start_Date__c <= :Date.today().addDays(-7) AND End_Date__c >= :Date.today().addDays(-7) 
                                     AND Type__c = 'Week' LIMIT 1];
            if(weeks.size() == 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable To Determine the Period To Run')); 
                return null;
            }
            SelectedPeriod = weeks[0];
        }
        else{
            List<Period__c> weeks = [SELECT Id, Name, Start_Date__c, End_Date__c FROM Period__c where Id = :SelectedPeriodId LIMIT 1]; 
            if(weeks.size() == 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable To Determine the Period To Run')); 
                return null;
            }
            SelectedPeriod = weeks[0];
        } 

        List<Period__c> orderPeriod = [SELECT Id from Period__c WHERE Start_Date__c <=: SelectedPeriod.Start_Date__c.addDays(7) AND End_Date__c >=: SelectedPeriod.End_Date__c.addDays(7) 
                                       AND Type__c = 'Week' LIMIT 1 ];

        DateTime dtStart = SelectedPeriod.Start_Date__c; //DateTime.newInstance(SelectedPeriod.Start_Date__c.year(), SelectedPeriod.Start_Date__c.month(), SelectedPeriod.Start_Date__c.day());
        DateTime dtEnd = SelectedPeriod.End_Date__c; //DateTime.newInstance(SelectedPeriod.End_Date__c.year(), SelectedPeriod.End_Date__c.month(), SelectedPeriod.End_Date__c.day());
        
        Map<Id,Order> projectOrders = new Map<Id,Order>();
        Map<Id,PS_Project__c> projects = new Map<Id,PS_Project__c>();
        List<Order> newOrders = new List<Order>();
        Set<Id> utilizedPricebooks = new Set<Id>();
        Set<Id> utilizedProducts = new Set<Id>();
        for(PS_Project__c project : [SELECT Id, Name, AccountId__c, Invoice_Type__c, Payment_Terms__c, Rate__c, ProductId__c, Billing_ContactId__c, Billing_ContactId__r.Name, AccountId__r.Name, Purchase_Order__c,
                                            AccountId__r.BillingStreet, AccountId__r.BillingCity, AccountId__r.BillingState, AccountId__r.BillingPostalCode, AccountId__r.BillingCountry, OpportunityId__c,
                                            (
                                                SELECT Id, ProductId__c, EmployeeId__c, ProjectId__c, Hours_Entered__c, MilestoneId__r.PricebookId__c, MilestoneId__r.ProductId__c 
                                                FROM Time_Card_Entries__r 
                                                WHERE Order_ItemId__c = null AND Hours_Entered__c != null AND Date_Entered__c >=: SelectedPeriod.Start_Date__c AND Date_Entered__c <=: SelectedPeriod.End_Date__c
                                            ),
                                            (
                                                SELECT Id, Contact__c, Contact__r.Email, Billing_Contact__c, Role__c
                                                FROM Project_Teams__r
                                            )
                                     FROM PS_Project__c 
                                     WHERE Id IN: pProjectIds]){

            //Create Order Header and Choose the correct logic to execute depending on the Project Invoice Type 
            if(project.Time_Card_Entries__r != null && project.Time_Card_Entries__r.Size() > 0){
                // Create and Insert New Order
                Order newOrder =  new Order();
                newOrder.ProjectId__c = project.Id;
                newOrder.AccountId = project.AccountId__c;
                newOrder.Pricebook2Id = project.Time_Card_Entries__r[0].MilestoneId__r.PricebookId__c;
                newOrder.Type = 'Services';

                //newOrder.BillToContactId = project.Billing_ContactId__c;
                newOrder.BillingStreet = project.AccountId__r.BillingStreet;
                newOrder.BillingCity = project.AccountId__r.BillingCity;
                newOrder.BillingState = project.AccountId__r.BillingState;
                newOrder.BillingPostalCode = project.AccountId__r.BillingPostalCode;
                newOrder.BillingCountry = project.AccountId__r.BillingCountry;
                newOrder.EffectiveDate = Date.today();
                newOrder.Status = 'Draft';
                if(orderPeriod != null && orderPeriod.size() > 0){
                    newOrder.PeriodId__c = orderPeriod.get(0).Id;// SelectedPeriod.Id;//select next period   
                }
                newOrder.Purchase_Order__c = project.Purchase_Order__c;
                newOrder.PoNumber = project.Purchase_Order__c;
                newOrder.OpportunityId = project.OpportunityId__c;
                newOrder.Terms__c = project.Payment_Terms__c;

                String concatEmails = '';
                Integer totalRecieve = 0;
                for(Project_Team__c pt : project.Project_Teams__r){
                    if(pt.Billing_Contact__c && pt.Contact__r.Email != null){
                        totalRecieve++;
                    }
                }

                Integer count = 0;
                for(Project_Team__c pt : project.Project_Teams__r){
                    if(pt.Contact__c != null){
                        if(pt.Role__c != null && newOrder.BillToContactId == null){
                            Set<String> sSet;
                            List<String> sList = new List<String>();
                            sList = pt.Role__c.split(',');
                            if(sList.size() > 0){
                                sSet = new Set<String>(sList);
                                if(sSet.contains('Billing Contact')){
                                    newOrder.BillToContactId = pt.Contact__c;
                                }
                            }
                        }
                        if(pt.Billing_Contact__c && pt.Contact__r.Email != null){
                            concatEmails = concatEmails + pt.Contact__r.Email;
                            count++;
                            if(count < totalRecieve){
                                concatEmails = concatEmails + ',';
                            }
                        }
                    }
                }

                newOrder.Additional_Contact_Emails__c = concatEmails;
                newOrder.Description = String.Format('{0} - {1}', new List<String>{dtStart.format('yyyy/MM/dd'),dtEnd.format('yyyy/MM/dd') });
                newOrders.add(newOrder);
                projectOrders.put(project.Id,newOrder); 
                projects.put(project.Id, project);

                // Get Utilized Pricebooks and Products
                for(Time_Card_Entry__c entry : project.Time_Card_Entries__r){
                    utilizedPricebooks.add(entry.MilestoneId__r.PricebookId__c);
                    utilizedProducts.add(entry.MilestoneId__r.ProductId__c);
                }
            }
            else{
                Results.add(new ProjectOrderResult(project,null, String.format('There Are No Unaccounted For Milestone Details For The Period {0} to {1}', new List<String>{String.valueOf(SelectedPeriod.Start_Date__c),String.valueOf(SelectedPeriod.End_Date__c)})));
            }
        } 

        if(newOrders.size() > 0){
            insert newOrders;
        }
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,String.format('No New Orders Were Generated For The Period {0} to {1}', new List<String>{String.valueOf(SelectedPeriod.Start_Date__c),String.valueOf(SelectedPeriod.End_Date__c)})));
            return null;
        }

        PricebookEntries = new List<PricebookEntry>([SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2Id IN :utilizedPricebooks AND Product2Id IN :utilizedProducts]);

        if(projects.size() > 0){  
            Map<Id, Milestone__c> milestones = new Map<Id, Milestone__c>();
            for(Milestone__c ms : [SELECT Id, PricebookId__c,Effective_Hourly_Rate__c, ProductId__c FROM Milestone__c WHERE ProjectId__c IN :projects.keySet()]){
                milestones.put(ms.Id, ms);
            }
            // List for New Order Details and List for Milestone Details to Update
            List<OrderItem> newOrderItems = new List<OrderItem>(); 
            Map<Id,List<Time_Card_Entry__c>> updateDetails = new Map<Id,List<Time_Card_Entry__c>>();
            for(Id projId : projects.keySet()){
                PS_Project__c currProj = projects.get(projId);
                // Get Active Billable Milestones for the current project
                // Get Active and Billable Milestone Details for the Project and Sum the Hours Worked grouped by Milestone
                Map<Id,Double> hoursPerMilestone = new Map<Id,Double>();
                for(Time_Card_Entry__c detail : currProj.Time_Card_Entries__r){
                    Double hoursInvoiced = 0;
                    if(hoursPerMilestone.containsKey(detail.MilestoneId__c)){
                        hoursInvoiced = hoursPerMilestone.get(detail.MilestoneId__c);
                    }
                    hoursInvoiced += detail.Hours_Entered__c;
                    hoursPerMilestone.put(detail.MilestoneId__c, hoursInvoiced);
                    if(!updateDetails.containsKey(detail.MilestoneId__c)){
                        updateDetails.put(detail.MilestoneId__c, new List<Time_Card_Entry__c>());
                    }
                    updateDetails.get(detail.MilestoneId__c).add(detail);
                }

                for(Id milestoneId : hoursPerMilestone.keySet()){
                    OrderItem orderItem = new OrderItem();
                    //new fields - ksears
                    Decimal rate = milestones.get(milestoneId).Effective_Hourly_Rate__c;
                    orderItem.UnitPrice = rate;
                    orderItem.Unit_Price_4__c = rate;

                    orderItem.OrderId = projectOrders.get(projId).Id;
                    //System.debug(orderItem.OrderId);

                    orderItem.ProjectId__c = projId;
                    //System.debug(orderItem.ProjectId__c);

                    orderItem.MilestoneId__c = milestoneId;
                    //System.debug(orderItem.MilestoneId__c);
                    //orderItem.Product__c = milestones.get(milestoneId).ProductId__c;
                    //orderItem.UnitPrice = currProj.Rate__c;
                    orderItem.Quantity = hoursPerMilestone.get(milestoneId);

                    Id pbId;
                    Id proId;
                    if(milestones.get(milestoneId) != null){
                        pbId = milestones.get(milestoneId).PricebookId__c;
                        proId = milestones.get(milestoneId).ProductId__c;
                    }
                    //System.debug(pbId);
                    //System.debug(proId);


                    orderItem.PricebookEntryId = FindOrCreatePricebookEntry(pbId, proId, rate);
                    //System.debug(orderItem.PricebookEntryId);

                    //System.debug(orderItem);
                    newOrderItems.add(orderItem);
                }
            } 

            //Update details lookup to order detail
            if(newOrderItems.size() > 0){
                //System.debug(newOrderItems);
                insert newOrderItems;
                
                List<Time_Card_Entry__c> upMDs = new List<Time_Card_Entry__c>();
                for(OrderItem od : newOrderItems){ 
                    for(Time_Card_Entry__c upMD : updateDetails.get(od.MilestoneId__c)){
                        upMD.Order_ItemId__c = od.Id;
                        upMDs.add(upMD);
                    } 
                }
                update upMDs;
            } 
        }

        return null;
    }

    /**
    * @description FindOrCreatePricebookEntry - Returns the PricebookEntry applicable to the given parameters or creates one if it does not exist. 
    * @param Id pPricebookId
    * @param Id pProductId
    * @param Decimal pRate
    * @return Id
    */   
    public Id FindOrCreatePricebookEntry(Id pPricebookId, Id pProductId, Decimal pRate){
        for(PricebookEntry entry : PricebookEntries){
            if(entry.Pricebook2Id == pPricebookId && entry.Product2Id == pProductId){
                return entry.Id;
            }
        }

      // Check if a Standard Pricebook Entry exists
      Boolean hasStandardEntry = false;
        for(PricebookEntry entry : PricebookEntries){
            if(entry.Pricebook2Id == StandardPricebookId && entry.Product2Id == pProductId){
                hasStandardEntry = true;
                break;
            }
        }

          // Create Custom Entry only, standard entry exists
        if(hasStandardEntry && pPricebookId != StandardPricebookId){
            PricebookEntry newCustomEntry = new PricebookEntry(Pricebook2Id = pPricebookId, Product2Id = pProductId, UnitPrice = pRate, IsActive = true);
            insert newCustomEntry;
            PricebookEntries.add(newCustomEntry);
            return newCustomEntry.Id;
        }  
        // Create Standard Entry and create Custom Entry only if the received pricebook is NOT the standard pricebook
        else if(!hasStandardEntry){
            PricebookEntry newStandardEntry = new PricebookEntry(Pricebook2Id = StandardPricebookId, Product2Id = pProductId, UnitPrice = pRate, IsActive = true);
            PricebookEntry newCustomEntry = new PricebookEntry(Pricebook2Id = pPricebookId, Product2Id = pProductId, UnitPrice = pRate, IsActive = true);            
            
            if(pPricebookId != StandardPricebookId){
                // NEEDS STANDARD AND CUSTOM ENTRIES
                insert newStandardEntry;
                insert newCustomEntry;
                PricebookEntries.add(newStandardEntry);
                PricebookEntries.add(newCustomEntry);
                return newCustomEntry.Id;
            }
            else{
                // NEEDS ONLY THE STANDARD ENTRY
                insert newStandardEntry;
                PricebookEntries.add(newStandardEntry);
                return newStandardEntry.Id;
            }
        }
        return null;
    }

    /**
    * @description ProjectOrderResult - Wrapper class for reporting on Projects that do not have any qualifying time card entry details to create orders for.
    */  
    public class ProjectOrderResult{
        public PS_Project__c Project {get; set;}
        public Order ProjectOrder {get; set;}
        public String Details {get; set;}
        public ProjectOrderResult(PS_Project__c pProject, Order pOrder, String pDetails){
            Project = pProject; 
            ProjectOrder = pOrder; 
            Details = pDetails;
        } 
    }


}