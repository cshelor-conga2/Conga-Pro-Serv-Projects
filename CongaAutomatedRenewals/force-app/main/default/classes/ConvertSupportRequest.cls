/**
* @author Conga Services, KSears
* @date 20190305
* @version 1.00
* @description ConvertSupportRequest - Visualforce controller called from page to create Project from Support Request.
*/
public with sharing class ConvertSupportRequest {
    public Id srId;
    public Support_Request__c sr;
    public List<Support_Request__c> srList = new List<Support_Request__c>();

    /** 
    * @description Constructor
    */  
    public ConvertSupportRequest(ApexPages.StandardController stdController) {
        this.sr = (Support_Request__c)stdController.getRecord();
    }
    
    /** 
    * @description Autorun method called from visualforce page.   
    */
    public PageReference autoRun() {
        srId = ApexPages.currentPage().getParameters().get('id');
        List<Group> groupList = new List<Group>();
        groupList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Team Salesforce' LIMIT 1];

        if (srId != null){
            srList = [SELECT Id, Name, Subject__c, Issue__c, BSI_Project__c FROM Support_Request__c WHERE Id = :srId LIMIT 1];
            if(srList.size() > 0){
                if(srList[0].BSI_Project__c != null){
                    PageReference pageRef = new PageReference('/' + srList[0].BSI_Project__c);
                    pageRef.setRedirect(true);
                    return pageRef; 
                }
                else{
                    PS_Project__c newProj = new PS_Project__c();
                    newProj.Name = srList[0].Subject__c;
                    if(srList[0].Issue__c != null){
                        String fixedDesc = srList[0].Issue__c;
                        fixedDesc = fixedDesc.replaceAll('\\<.*?\\>', ' ');
                        fixedDesc = fixedDesc.replaceAll('&quot;', '"');
                        fixedDesc = fixedDesc.replaceAll('&#39;', '\'');
                        newProj.Description__c = fixedDesc;

                    }
                    newProj.BSI_Status__c = 'On Hold';
                    if(groupList.size() > 0){
                        newProj.OwnerId = groupList[0].Id;
                    }
                    insert newProj;
                    srList[0].Status__c = 'Assigned to Project';
                    srList[0].BSI_Project__c = newProj.Id;
                    update srList[0];
                    
                    List<Milestone__c> newMilestones = new List<Milestone__c>();
                    List<Product2> prodList = new List<Product2>();
                    prodList = [SELECT Id FROM Product2 WHERE Name = 'ProServe Hour' LIMIT 1];
                    List<Pricebook2> priceList = new List<Pricebook2>();
                    priceList = [SELECT Id FROM Pricebook2 WHERE Name = '2018-2019 Pricebook' LIMIT 1];

                    //Initiate and Design
                    Milestone__c iad = new Milestone__c();
                    iad.ProjectId__c = newProj.Id;
                    iad.Name = 'Initiate and Design';
                    iad.Hours_Currently_Budgeted__c = 5;
                    iad.Effective_Hourly_Rate__c = 250;
                    if(priceList.size() > 0){
                        iad.PricebookId__c = priceList[0].Id;
                    }
                    if(prodList.size() > 0){
                        iad.ProductId__c = prodList[0].Id;
                    }
                    newMilestones.add(iad);

                    //Build and Validate
                    Milestone__c bav = new Milestone__c();
                    bav.ProjectId__c = newProj.Id;
                    bav.Name = 'Build and Validate';
                    bav.Hours_Currently_Budgeted__c = 23;
                    bav.Effective_Hourly_Rate__c = 250;
                    if(priceList.size() > 0){
                        bav.PricebookId__c = priceList[0].Id;
                    }
                    if(prodList.size() > 0){
                        bav.ProductId__c = prodList[0].Id;
                    }
                    newMilestones.add(bav);

                    //Deploy
                    Milestone__c dep = new Milestone__c();
                    dep.ProjectId__c = newProj.Id;
                    dep.Name = 'Deploy';
                    dep.Hours_Currently_Budgeted__c = 2;
                    dep.Effective_Hourly_Rate__c = 250;
                    if(priceList.size() > 0){
                        dep.PricebookId__c = priceList[0].Id;
                    }
                    if(prodList.size() > 0){
                        dep.ProductId__c = prodList[0].Id;
                    }
                    newMilestones.add(dep);

                    insert newMilestones;

                    PageReference pg = new PageReference('/' + newProj.Id);
                    pg.setRedirect(true);
                    return pg;
                }
            }
        }
        PageReference pageRef = new PageReference('/' + srId);
        return pageRef;     
    }

}