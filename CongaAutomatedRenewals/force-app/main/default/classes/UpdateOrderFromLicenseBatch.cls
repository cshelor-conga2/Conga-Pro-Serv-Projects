/**
* @author Conga Services
* @date 20190212
* @version 1.00
* @description UpdateOrderFromLicenseBatch - 
*/
public with sharing class UpdateOrderFromLicenseBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
	public final String LicensesToProcess;
	public Datetime LastRunDateTime;
	public final Map<Id,String> PackageMap;
	public final Map<Id, User> InvalidUsers;
	public Set<Order> Orders;
	public Map<Id,Id> orderToLicenseMap;


	/**
	* @description UpdateOrderFromLicenseBatch - Constructor
	*/
	public UpdateOrderFromLicenseBatch() {
		// GET DATETIME OF LAST SUCCESSFUL RUN
		this.LastRunDateTime = System.Now().addHours(-96);
		if(!Test.isRunningTest()){
			for(AsyncApexJob myJob : [SELECT Status, ApexClass.Name, CompletedDate FROM AsyncApexJob WHERE ApexClass.Name = 'UpdateOrderFromLicenseBatch' AND Status = 'Completed' ORDER BY CompletedDate DESC LIMIT 1]){
				if(myJob.CompletedDate != null){
					this.LastRunDateTime = myJob.CompletedDate;
				} 
			}		
		}

		this.packageMap = new Map<Id, String>();
		// GET LMA PACKAGES
		for(SfLma__Package__c sfPackage : [SELECT Id, Name FROM SfLma__Package__c]){
			this.PackageMap.put(sfPackage.Id, sfPackage.Name);
		}
		
		// GET ID OF USER(S) TO FILTER OUT
		this.InvalidUsers = new Map<Id, User>([SELECT Id, Name FROM User WHERE Name IN ('Lance Foster')]);
		this.LicensesToProcess = ' SELECT Id, CreatedDate, SfLma__Package__c, SfLma__Subscriber_Org_ID__c FROM sfLma__License__c WHERE CreatedDate > :LastRunDateTime ORDER BY SfLma__Subscriber_Org_ID__c ';
		this.Orders = new Set<Order>();
		this.OrderToLicenseMap = new Map<Id,Id>();
	}

	/**
	* @description start - 
	* @param Database.BatchableContext bc
	* @return Database.QueryLocator
	*/
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(LicensesToProcess);
	}

	/**
	* @description execute - 
	* @param Database.BatchableContext bc
	* @param List<sObject> scope
	* @return void
	*/
	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		Set<String> orgIds = new Set<String>();
   		if(scope.size() > 0){
			List<sfLma__License__c> sfLicenses = (List<sfLma__License__c>)scope;
			for(sfLma__License__c sfLicense : sfLicenses){
				if(sfLicense.SfLma__Subscriber_Org_ID__c != null){
					orgIds.add(sfLicense.SfLma__Subscriber_Org_ID__c);
				}
			}
			// FIND APPLICABLE ORDERS AND UPDATE
			for(Order o : [SELECT Id, Package_Installs__c, Most_Recent_Package_Install__c, Customer_org_id__c, OwnerId, Owner.Name FROM Order 
						   WHERE Customer_org_id__c IN :orgIds AND Type != 'Services' AND Status != 'Cancelled' AND Status != 'Credit Memo' AND OwnerId NOT IN :invalidUsers.keySet()]){
				for(sfLma__License__c sfLicense : sfLicenses){
					if(o.Customer_org_id__c == sfLicense.SfLma__Subscriber_Org_ID__c){
						if(packageMap != null && packageMap.containsKey(sfLicense.SfLma__Package__c)){
							String packageName = packageMap.get(sfLicense.SfLma__Package__c);
							if(o.Most_Recent_Package_Install__c != packageName){
								o.Most_Recent_Package_Install__c = packageName;
								o.Most_Recent_Install_Date_Time__c = System.Now();
								
								if(String.isBlank(o.Package_Installs__c)){
									o.Package_Installs__c = packageName;
								}
								else{
									o.Package_Installs__c = o.Package_Installs__c + ';' + packageName;
								}
								orderToLicenseMap.put(o.Id,sfLicense.Id);
								Orders.add(o);	
							}						
						}
					}
				}
			}
		}
	}

	/**
	* @description finish - 
	* @param Database.BatchableContext bc
	* @return void
	*/
	public void finish(Database.BatchableContext BC) {
		if(Orders != null && Orders.size() > 0){
			List<Order> ordersToUpdate = new List<Order>(Orders);
			List<Id> updatedOrderIds = new List<Id>();
			List<String> failedOrderIds = new List<Id>();
			Database.SaveResult[] srList = Database.update(ordersToUpdate, true);
	        SystemIssueLogHelper.CheckForDatabaseErrors(srList, 'UpdateOrderFromLicenseBatch', 'finish', true);

			for(Database.SaveResult sr : srList){
				if(sr.isSuccess()){
					updatedOrderIds.add(sr.getId());
				}
			}

			if(updatedOrderIds.size()>0){
				SendProcessingEmail(updatedOrderIds, orderToLicenseMap);	
			}	
		}
	}

	/**
	* @description execute - 
	* @param SchedulableContext sc
	* @return void
	*/
	public void execute(SchedulableContext sc){
		 Database.executeBatch(new UpdateOrderFromLicenseBatch(), 200);
	}

	/**
	* @description SendProcessingEmail - 
	* @param List<Id> updatedIds
	* @param Map<Id,Id> ordLicenseMap
	* @return void
	*/
	private static void SendProcessingEmail(List<Id> updatedIds, Map<Id,Id> ordLicenseMap){
		List<EmailTemplate> emailTemplate = [SELECT Id, Subject, HTMLValue, Body FROM EmailTemplate WHERE DeveloperName = 'Order_Update_Batch_Processing_Complete'];
		List<OrgWideEmailAddress> owe = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Conga Onboarding' LIMIT 1];
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

		if(emailTemplate.size() == 1){
			String orderList = '';
			for(Order o : [SELECT Id, Package_Installs__c, OrderNumber, Most_Recent_Package_Install__c, Most_Recent_Install_Date_Time__c FROM Order WHERE Id IN :updatedIds]){
				Id licenseId;
				if(ordLicenseMap!=null && ordLicenseMap.containsKey(o.Id)){
					licenseId = ordLicenseMap.get(o.Id);
				}
				orderList += '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + o.Id + '">' + o.OrderNumber + '</a>' + ' | ' + o.Most_Recent_Package_Install__c + ' | ' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + licenseId + '">' + 'Related License Record' + '</a>' +  '<br/>';
			}

			email.setSubject(emailTemplate[0].Subject.replace('{NumberOfOrders}', String.valueOf(updatedIds.size())));
			email.setHtmlBody(emailTemplate[0].HtmlValue.replace('{ListOfOrders}', orderList));
			email.setPlainTextBody(emailTemplate[0].Body.replace('{ListOfOrders}', orderList));
			if(owe.size()==1){
				email.setToAddresses(new List<String>{owe[0].Address});
				email.setOrgWideEmailAddressId(owe[0].Id);
			}
			
			if(!Test.isRunningTest()){
				Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email }, true);
			}
		}
	}


}