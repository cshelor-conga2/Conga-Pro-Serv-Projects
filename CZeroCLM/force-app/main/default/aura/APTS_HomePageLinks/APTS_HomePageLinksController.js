({
    doInit : function(component, event, helper) {
        helper.getListViewDetail(component, 'Apttus__APTS_Agreement__c','APTS_My_Agreements','myAgreementsList');               
        //helper.getListViewDetail(component, 'Apttus__APTS_Template__c','Clauses','clausesList');               
	},
	createWizard: function (component, event, helper) {
        $A.get("e.force:navigateToURL").setParams({"url": '/apex/APTS_CreateAgreementPage'}).fire();
    },
    NewAgreement: function (component, event, helper) {
        $A.get("e.force:navigateToURL").setParams({"url": '/flow/CNG_Conga_CLM_Request_Agreement'}).fire();
    },    
    gotoMyAgreements: function(component, event, helper) {       
        var listId = component.get("v.myAgreementsList");
        $A.get("e.force:navigateToURL").setParams({"url": '/lightning/o/Apttus__APTS_Agreement__c/list?filterName='+listId}).fire();
    },
    gotoMyDashBoard: function(component, event, helper) {       
         $A.get("e.force:navigateToURL").setParams({"url": '/lightning/r/Dashboard/01ZRL000005IwIn2AK/view?queryScope=userFolders'}).fire();
    },
    MyQueueAgreements: function(component, event, helper) {
        helper.navigateToMyQueue(component);
    }
   
})