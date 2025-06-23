/**
* @author Conga Services, KSears
* @date 20190314
* @version 1.00
* @description SupportRequestWizardController - Class for Support Request Wizard page
*/
public with sharing class SupportRequestWizardController {
	public Boolean step1 {get;set;}

	public List<SelectOption> typeSelections {get;set;}
	public String selectedType {get;set;}

	public Support_Request__c newSR {get;set;}
	public Map<Id,String> rtMap = new Map<Id,String>();

	public Integer issueBugCounter {get;set;}
	public Integer enhancementCounter {get;set;}
	public Integer dataCounter {get;set;}
	public String issueText {get;set;}

	List<String> exclude = new list<String> {'NA','na','n/a','N/A','.','..','....','... ','x','xx','xxxx'};

    public ContentVersion newfile {get;set;}

	/**	
	* @description SupportRequestWizardController - Constructor
	* @param ApexPages.StandardController stdController
	*/
	public SupportRequestWizardController(ApexPages.StandardController stdController) {
		initDropdowns();
	}

	/**	
	* @description initDropdowns - Populate the type dropdown
	* @return void
	*/
	public void initDropdowns(){
        newfile = new ContentVersion();
		newSR = new Support_Request__c();

		step1 = true;
		typeSelections = new List<SelectOption>();
		issueText = '';
		issueBugCounter = 0;
		enhancementCounter = 0;
		dataCounter = 0;

		typeSelections.clear();
		typeSelections.add(new SelectOption('', '--None--'));
		typeSelections.add(new SelectOption('Issue', 'Issue'));
		typeSelections.add(new SelectOption('Bug', 'Bug'));
		typeSelections.add(new SelectOption('Enhancement', 'Enhancement'));
		typeSelections.add(new SelectOption('Data Upload Request', 'Data Upload Request'));
	}

	/**	
	* @description choseType - Switch current Step
	* @return void
	*/
	public void choseType(){
		step1 = false;
		if(selectedType == 'Issue' || selectedType == 'Bug'){
			issueBugCounter++;
			if(selectedType == 'Issue'){
				issueText = 'What is the issue that you are experiencing? (user permissions, reporting limitations, error message on record save etc.)';
			}
			else{
				issueText = 'What is the issue that you are experiencing? (field miscalculating, renewal opportunity not created, Composer button error etc.)';
			}
		}

		if(selectedType == 'Enhancement'){
			enhancementCounter++;
		}

		if(selectedType == 'Data Upload Request'){
			dataCounter++;
		}	
	}
 
	/**	
	* @description backToType - Go back to type
	* @return void
	*/	
	public void backToType(){
		initDropdowns();			
	}

	/**	
	* @description issueBugNext - next for Issue/Bug
	* @return void
	*/	
	public void issueBugNext(){
		switch on issueBugCounter {
			when 1 {
				if(newSR.Subject__c != null && !exclude.contains(newSR.Subject__c)){
					issueBugCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}	
			when 2 {
				if(newSR.Issue__c != null && !exclude.contains(newSR.Issue__c)){
					issueBugCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}	
			when 3 {
				if(newSR.Initial_Occurence__c != null){
					issueBugCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}
			when 4 {
				if(newSR.Steps_to_Reproduce__c != null && !exclude.contains(newSR.Steps_to_Reproduce__c)){
					issueBugCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}
			when 5 {
				if(newSR.Current_Workaround__c != null && !exclude.contains(newSR.Current_Workaround__c)){
					issueBugCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}
			when else {
				issueBugCounter++;
			}
		}		
	}

	/**	
	* @description issueBugBack - back for Issue/Bug
	* @return void
	*/	
	public void issueBugBack(){
		if(issueBugCounter == 1){
			backToType();
		}
		else{
			issueBugCounter--;
		}
	}

	/**	
	* @description enhancementNext - next for Enhancement
	* @return void
	*/		
	public void enhancementNext(){
		switch on enhancementCounter {
			when 1 {
				if(newSR.Subject__c != null && !exclude.contains(newSR.Subject__c)){
					enhancementCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}
			when 2 {
				if(newSR.Issue__c != null && !exclude.contains(newSR.Issue__c)){
					enhancementCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}	
			when 3 {
				if(newSR.Desired_State__c != null && !exclude.contains(newSR.Desired_State__c)){
					enhancementCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}
			when else {
				enhancementCounter++;
			}
		}
	}

	/**	
	* @description enhancementBack - back for Enhancement
	* @return void
	*/	
	public void enhancementBack(){
		if(enhancementCounter == 1){
			backToType();
		}
		else{
			enhancementCounter--;
		}
	}		

	/**	
	* @description dataNext - next for Data
	* @return void
	*/	
	public void dataNext(){
		switch on dataCounter {
			when 1 {
				if(newSR.Subject__c != null && !exclude.contains(newSR.Subject__c)){
					dataCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}
			when 2 {
				if(newSR.Issue__c != null && !exclude.contains(newSR.Issue__c)){
					dataCounter++;
				}
				else{
					ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
				}
			}
			when else {
				dataCounter++;
			}
		}
	}

	/**	
	* @description dataBack - back for Data
	* @return void
	*/	
	public void dataBack(){
		if(dataCounter == 1){
			backToType();
		}
		else{
			dataCounter--;
		}
	}

	/**	
	* @description submitSR - Submit the form
	* @return void
	*/	
	public void submitSR(){
		if(issueBugCounter > 0){
			if(newSR.Example_Record_Link__c != null && !exclude.contains(newSR.Example_Record_Link__c)){
				issueBugCounter++;
				submitToDB();
			}
			else{
				apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
			}
		}

		if(enhancementCounter > 0){
			if(newSR.Example_Record_Link__c != null && !exclude.contains(newSR.Example_Record_Link__c)){
				enhancementCounter++;
				submitToDB();
			}
			else{
				apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Please fill out this field before moving on.'));
			}
		}

		if(dataCounter > 0){
			dataCounter++;
			submitToDB();
		}		
	}

	/**	
	* @description submitToDB - 
	* @return void
	*/	
	public void submitToDB(){
		newSR.RecordTypeId = Schema.SObjectType.Support_Request__c.getRecordTypeInfosByName().get('Salesforce Support Request').getRecordTypeId();
		newSR.Type__c = selectedType;
		newSR.Requester__c = UserInfo.getUserId();

		List<Group> groupList = new List<Group>();
		groupList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Team Salesforce' LIMIT 1];
		if(groupList.size() > 0){
			newSR.OwnerId = groupList[0].Id;
		}

		insert newSR;
		if(newFile != null && newFile.versionData != null){
			insert newfile;
			List<ContentVersion> conVers = new List<ContentVersion>();
			conVers = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :newfile.Id LIMIT 1];
			if(conVers.size() > 0){
				ContentDocumentLink cdl = new ContentDocumentLink();
				cdl.ContentDocumentId = conVers[0].ContentDocumentId;
				cdl.LinkedEntityId = newSR.Id;
				cdl.ShareType ='V';
				cdl.Visibility ='AllUsers';
				insert cdl;
			}
		}
	}

	/**	
	* @description pageContinue - 
	* @return PageReference
	*/	
	public PageReference pageContinue(){
        PageReference pageRef = new PageReference('/home/home.jsp');
		// if(ApexPages.currentPage().getHeaders().get('Host').contains('lightning')){
        // 	pageRef = new PageReference('/lightning/page/home');
		// }
		pageRef.setRedirect(true);
        return pageRef;		
	}


}