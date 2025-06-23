/**
* @author BSpencer
* @date 20160426
* @version 1.00
* @description CaseQuickEditController - Controller for the CaseQuickEditPage VF page
*/
public with sharing class CaseQuickEditController {
    public Case CurrentCase {get;set;}
    public Id CaseId {get;set;}
    
    /**
    * @description CaseQuickEditController - Constructor 
    * @param ctrl ApexPages.StandardController
    */
    public CaseQuickEditController(ApexPages.StandardController ctrl) {
        CurrentCase = (Case)ctrl.getRecord();
    }

    /**
    * @description backToCase -  
    * @return PageReference
    */
    public PageReference backToCase(){
        update CurrentCase;
        return null;

    }


}