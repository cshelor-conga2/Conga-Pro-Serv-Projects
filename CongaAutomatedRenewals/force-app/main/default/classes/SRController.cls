/**
* @author Conga, dnelson
* @date 20180306
* @version 1.00
* @description SRController - Convert support request to assignment 
*/
public class SRController {
    private final Support_Request__c sr;

    /**
    * @description SRController - Constructor
    * @param ApexPages.StandardController stdController
    */
    public SRController(ApexPages.StandardController stdController) {
        this.sr = (Support_Request__c)stdController.getRecord();
    }
     
    /**
    * @description autoRun - 
    * @return PageReference
    */
    public PageReference autoRun() {
        String theId = ApexPages.currentPage().getParameters().get('id');  

        if(theId == null) {
            return null;
        }
        else{
            Support_Request__c sr = [SELECT Id, Type__c, Status__c, Subject__c, Description__c, Due_Date__c, Assignment__c, BSI_Project__c, Department__c, Category__c, Sub_Category__c
                                     FROM Support_Request__c WHERE Id = :theId];

            if(sr.Assignment__c != null){
                PageReference page = new PageReference('/' + sr.Assignment__c);
                return page;
            }
        
            if(sr.BSI_Project__c == null){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Please enter a project to create an assignment. A project milestone must also be available.');
                ApexPages.addMessage(myMsg);
                return null;
            } 
            else{
                Id recordTypeId = Schema.SObjectType.Assignment__c.getRecordTypeInfosByName().get('Business Systems').getRecordTypeId();
                List<Milestone__c> milestones = [SELECT Id, Name, ProjectId__c FROM Milestone__c WHERE ProjectId__c = :sr.BSI_Project__c AND IsActive__c = true LIMIT 1];
                
                if(milestones.isEmpty()){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'A project milestone must be available to convert to an assignment. Please add a milestone.');
                    ApexPages.addMessage(myMsg);
                    return null;
                }
                else{
                    for(Milestone__c milestone : milestones) {
                        Assignment__c a = new Assignment__c();
                        a.MilestoneId__c = milestone.Id;
                        a.Status__c = 'Backlog';
                        a.IsOverflow__c  = true;
                        a.Subject__c  = sr.Subject__c;
                        a.ProjectId__c  = sr.BSI_Project__c; 
                        a.OwnerId = UserInfo.getUserId();
                        a.RecordTypeId = recordTypeId;
                        a.Description__c = 'Please see support request ' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/'+ theId;
                        insert a;

                        sr.Status__c ='In Delivery Queue';
                        sr.Assignment__c = a.Id;
                        update sr;

                        PageReference pg = new PageReference('/' + a.Id);
                        pg.setRedirect(true);
                        return pg;
                    }  
                }
            }

            PageReference pageRef = new PageReference('/' + theId);
            return pageRef;
        }
    }


}