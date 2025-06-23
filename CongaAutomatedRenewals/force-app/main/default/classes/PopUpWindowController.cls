/**
* @author BSpencer
* @date 20160523
* @version 1.00
* @description PopUpWindowController - Controller for the PopUpWindowPage VF Page
*/
global with sharing class PopUpWindowController {
    public Id CaseId {get; set;}
    public Case c {get; set;}

    /**
    * @description PopUpWindowController - Constructor 
    */
    public PopUpWindowController() {
        CaseId = ApexPages.currentPage().getParameters().get('cId');
        c = [SELECT Id, Status, CaseNumber, Account.Name, Subject, Description FROM Case WHERE Id = :CaseId];
    }

    /**
    * @description PopUpWindowController - Constructor
    * @param ApexPages.StandardController ctrl
    */
    public PopUpWindowController(ApexPages.StandardController ctrl){
        CaseId = (Id)ctrl.getId();
        c = [SELECT Id, Status, CaseNumber, Account.Name, Subject, Description FROM Case WHERE Id = :CaseId];
    }

    /**
    * @description checkStatus - 
    * @param String cId
    * @return Boolean
    */
    @RemoteAction
    global static Boolean checkStatus(String cId){
        Case cs = [SELECT Id, Status, CaseNumber, Origin, Account.Name, Subject, Description FROM Case WHERE Id = :cId];
        return (cs.Status == 'Working' && cs.Origin != 'Chat');
    }

    /**
    * @description updateStatus - 
    * @return void
    */
    public void updateStatus(){
        if(checkStatus(CaseId)){
            List<Case> updateList = new List<Case>();
            if(c != null){
                c.Status = 'On Hold';
                updateList.add(c);
            }

            if(updateList.size() > 0){
                update updateList;
            }
        }
    }


}