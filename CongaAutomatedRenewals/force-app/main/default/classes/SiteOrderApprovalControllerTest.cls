/**
* @author Systemyc, Giovanni Modica
* @date 20180105
* @version 1.00
* @description SiteOrderApprovalControllerTest - Test class for the SiteOrderApprovalController class
*/
@isTest
private class SiteOrderApprovalControllerTest {

	/**
	* @description setup - Setup test data
	*/
	@testSetup 
	static void setup() {
        TriggerHelper.OverrideAllSettings(true, false);
        
		// accounts
		Account a1 = new Account(Name = 'Test', BillingStreet = '390 Interlocken Crescent Suite 500', BillingCity = 'Broomfield', BillingState = 'Colorado', BillingPostalCode = '80021', BillingCountry = 'United States');
		insert new Account[] { a1 };

		// contacts
		Contact c1 = new Contact(FirstName = 'Aria', LastName = 'Stark', AccountId = a1.Id, MailingStreet = '1000 S. McCaslin Blvd Suite 301', MailingCity = 'Superior', MailingState = 'Colorado', MailingPostalCode = '800027', MailingCountry = 'United States', Phone = '+1 123 4567890', Email = 'astark@example.com');
		Contact c2 = new Contact(FirstName = 'Jon', LastName = 'Snow', AccountId = a1.Id, MailingStreet = '1000 S. McCaslin Blvd Suite 301', MailingCity = 'Superior', MailingState = 'Colorado', MailingPostalCode = '800027', MailingCountry = 'United States', Phone = '+1 123 4567890', Email = 'jsnow@example.com');
		insert new Contact[] { c1, c2 };

		a1.BillingContact__c = c1.Id;
		update new Account[] { a1 };

		// products
		Product2 p1  = new Product2(Name = 'P1', ProductCode = 'P1', Family = 'Conga Composer Licenses');
		Product2 p2  = new Product2(Name = 'P2', ProductCode = 'P2', Family = 'Conga Composer Licenses');
		Product2 p3  = new Product2(Name = 'S1', ProductCode = 'S1', Family = 'Professional Services');
		Product2 p4  = new Product2(Name = 'S2', ProductCode = 'S2', Family = 'Professional Services');
        insert new Product2[] { p1, p2, p3, p4 };

		// pricebook entries
		PricebookEntry pbe1  = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = p1.Id,  IsActive = true, UnitPrice = 100);
        PricebookEntry pbe2  = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = p2.Id,  IsActive = true, UnitPrice = 200);
		PricebookEntry pbe3  = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = p3.Id,  IsActive = true, UnitPrice = 100);
		PricebookEntry pbe4  = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = p4.Id,  IsActive = true, UnitPrice = 200);
        insert new PricebookEntry[] { pbe1, pbe2, pbe3, pbe4 };

		// opportunity record types
		Map<String,RecordType> opportunityRecordTypeNameToRecordTypeMap = new Map<String,RecordType>();
		for(RecordType recordType : [SELECT Id,DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity']) {
			opportunityRecordTypeNameToRecordTypeMap.put(recordType.DeveloperName,recordType);
		}
		System.assertNotEquals(null,opportunityRecordTypeNameToRecordTypeMap.get('Direct'),'Opportunity RecordType "Direct" does not exist');
		System.assertNotEquals(null,opportunityRecordTypeNameToRecordTypeMap.get('Indirect'),'Opportunity RecordType "Indirect" does not exist');

		// opportunities
		Opportunity op1 = new Opportunity(Name = 'Direct', AccountId = a1.Id, StageName = 'Qualify', CloseDate = Date.today(), Type = 'New Business', LeadSource = 'Advertisement', RecordTypeId = opportunityRecordTypeNameToRecordTypeMap.get('Direct').Id, PriceBook2Id = Test.getStandardPricebookId());
		Opportunity op2 = new Opportunity(Name = 'Indirect', AccountId = a1.Id, StageName = 'Qualify', CloseDate = Date.today(), Type = 'New Business', LeadSource = 'Advertisement', RecordTypeId = opportunityRecordTypeNameToRecordTypeMap.get('Indirect').Id, PriceBook2Id = Test.getStandardPricebookId());
		Opportunity op3 = new Opportunity(Name = 'Service', AccountId = a1.Id, StageName = 'Qualify', CloseDate = Date.today(), Type = 'New Business', LeadSource = 'Advertisement', RecordTypeId = opportunityRecordTypeNameToRecordTypeMap.get('Direct').Id, PriceBook2Id = Test.getStandardPricebookId());
		insert new Opportunity[] { op1, op2, op3 };

		// opportunity line items
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = op1.Id, PricebookEntryId = pbe1.Id, Description = 'Product 1', UnitPrice = pbe1.UnitPrice / 2, Quantity = 1, ServiceDate = Date.today(), Product_End_Date__c = Date.today().addDays(10));
		OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = op2.Id, PricebookEntryId = pbe1.Id, Description = 'Product 1', UnitPrice = pbe2.UnitPrice, Quantity = 1, ServiceDate = Date.today(), Product_End_Date__c = Date.today().addDays(10));
		OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = op3.Id, PricebookEntryId = pbe3.Id, Description = 'Service 1', UnitPrice = pbe3.UnitPrice, Quantity = 1, ServiceDate = Date.today(), Product_End_Date__c = Date.today().addDays(10));
		OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId = op3.Id, PricebookEntryId = pbe4.Id, Description = 'Service 2', UnitPrice = pbe4.UnitPrice, Quantity = 2, ServiceDate = Date.today(), Product_End_Date__c = Date.today().addDays(10));
		insert new OpportunityLineItem[] { oli1, oli2, oli3, oli4 };

		// projects
		PS_Project__c proy1 = new PS_Project__c(Name = 'Project', Is_Active__c = true, AccountId__c = a1.Id, OpportunityId__c = op3.Id);
		insert new PS_Project__c[] { proy1 };

		// milestones
		Milestone__c m1 = new Milestone__c(Name = 'M1', ProjectId__c = proy1.Id, PricebookId__c = Test.getStandardPricebookId(), IsActive__c = true, Is_Billable__c = true, ProductId__c = p3.Id, Hours_Currently_Budgeted__c = 10, Value_Hourly_Rate__c = 100, Effective_Hourly_Rate__c = 100);
		Milestone__c m2 = new Milestone__c(Name = 'M2', ProjectId__c = proy1.Id, PricebookId__c = Test.getStandardPricebookId(), IsActive__c = true, Is_Billable__c = true, ProductId__c = p4.Id, Hours_Currently_Budgeted__c = 20, Value_Hourly_Rate__c = 200, Effective_Hourly_Rate__c = 200);
		insert new Milestone__c[] { m1, m2 };

		// order record types
		Map<String,RecordType> orderRecordTypeNameToRecordTypeMap = new Map<String,RecordType>();
		for(RecordType recordType : [SELECT Id,DeveloperName FROM RecordType WHERE SObjectType = 'Order']) {
			orderRecordTypeNameToRecordTypeMap.put(recordType.DeveloperName,recordType);
		}
		System.assertNotEquals(null,orderRecordTypeNameToRecordTypeMap.get('Invoice'),'Order RecordType "Invoice" does not exist');

		// orders
		Order o1 = new Order(AccountId = a1.Id, OpportunityId = op1.Id, Status = 'Draft', Type = 'New Business', RecordTypeId = orderRecordTypeNameToRecordTypeMap.get('Invoice').Id, EffectiveDate = Date.today(), BillToContactId = a1.BillingContact__c, PriceBook2Id = Test.getStandardPricebookId());
		Order o2 = new Order(AccountId = a1.Id, OpportunityId = op2.Id, Status = 'Draft', Type = 'New Business', RecordTypeId = orderRecordTypeNameToRecordTypeMap.get('Invoice').Id, EffectiveDate = Date.today(), BillToContactId = a1.BillingContact__c, PriceBook2Id = Test.getStandardPricebookId());
		Order o3 = new Order(AccountId = a1.Id, OpportunityId = op3.Id, Status = 'Draft', Type = 'Services', RecordTypeId = orderRecordTypeNameToRecordTypeMap.get('Invoice').Id, EffectiveDate = Date.today(), BillToContactId = a1.BillingContact__c, PriceBook2Id = Test.getStandardPricebookId(), ProjectId__c = proy1.Id);
		insert new Order[] { o1, o2, o3 };

		// order items
		OrderItem oi1 = new OrderItem(OrderId = o1.Id, Quantity = oli1.Quantity, UnitPrice = oli1.UnitPrice, Unit_Price_4__c = oli1.UnitPrice, Description = oli1.Description, PricebookEntryId = oli1.PricebookEntryId, Product_Start_Date__c = oli1.ServiceDate, Product_End_Date__c = oli1.Product_End_Date__c, AVA_SFORDERS__LineTax__c = 5);
		OrderItem oi2 = new OrderItem(OrderId = o2.Id, Quantity = oli2.Quantity, UnitPrice = oli2.UnitPrice, Unit_Price_4__c = oli2.UnitPrice, Description = oli2.Description, PricebookEntryId = oli2.PricebookEntryId, Product_Start_Date__c = oli2.ServiceDate, Product_End_Date__c = oli2.Product_End_Date__c);
		OrderItem oi3 = new OrderItem(OrderId = o3.Id, Quantity = oli3.Quantity, UnitPrice = oli3.UnitPrice, Unit_Price_4__c = oli3.UnitPrice, Description = oli3.Description, PricebookEntryId = oli3.PricebookEntryId, Product_Start_Date__c = oli3.ServiceDate, Product_End_Date__c = oli3.Product_End_Date__c, MilestoneId__c = m1.Id);
		OrderItem oi4 = new OrderItem(OrderId = o3.Id, Quantity = oli4.Quantity, UnitPrice = oli4.UnitPrice, Unit_Price_4__c = oli4.UnitPrice, Description = oli4.Description, PricebookEntryId = oli4.PricebookEntryId, Product_Start_Date__c = oli4.ServiceDate, Product_End_Date__c = oli4.Product_End_Date__c, MilestoneId__c = m2.Id);
		OrderItem oi5 = new OrderItem(OrderId = o3.Id, Quantity = - (oli4.Quantity - 1), UnitPrice = oli4.UnitPrice, Description = oli4.Description, PricebookEntryId = oli4.PricebookEntryId, Product_Start_Date__c = oli4.ServiceDate, Product_End_Date__c = oli4.Product_End_Date__c, MilestoneId__c = m2.Id);
		insert new OrderItem[] { oi1, oi2, oi3, oi4, oi5 };

		// activate orders
		o1.Status = 'Pending';
		o2.Status = 'Pending';
		o3.Status = 'Pending';
		update new Order[] { o1, o2, o3 };

		// settings
		pymt__Settings__c s1 = new pymt__Settings__c(Name = 'PaymentConnect Settings', pymt__Update_Opp_Fields__c = true, pymt__Update_Shopping_Cart_Items__c = true, pymt__Gateway_Simulation_Mode__c = true, pymt__Test_Mode__c = true);
		insert new pymt__Settings__c[] { s1 };
		
		quot__QI_Settings__c settings = new quot__QI_Settings__c(quot__Sites_Website__c = SiteOrderApprovalController.SITE_NAME);
		insert settings;

		pymt__Sites_Website_Settings__c websiteSettings = new pymt__Sites_Website_Settings__c(Name = SiteOrderApprovalController.SITE_NAME, pymt__Currency_Format__c = '$x.xx ISO');
		insert websiteSettings;

		// processors record types
		Map<String,RecordType> processorRecordTypeNameToRecordTypeMap = new Map<String,RecordType>();
		for(RecordType recordType : [SELECT Id,DeveloperName FROM RecordType WHERE SObjectType = 'pymt__Processor_Connection__c']) {
			processorRecordTypeNameToRecordTypeMap.put(recordType.DeveloperName,recordType);
		}
		System.assertNotEquals(null,processorRecordTypeNameToRecordTypeMap.get('Authorize_Net'),'Processor RecordType "Authorize_Net" does not exist');

		// processors
		pymt__Processor_Connection__c proc1 = new pymt__Processor_Connection__c(Name = 'Authorize.Net', pymt__PaymentConnect_Setup__c = s1.Id, pymt__Processor_Id__c = 'Authorize.Net', pymt__Test_Mode__c = true, RecordTypeId = processorRecordTypeNameToRecordTypeMap.get('Authorize_Net').Id, pymt__Default_Connection__c = true);
		insert new pymt__Processor_Connection__c[] { proc1 };
	}
	
	/**
	* @description testInitialState - 
	*/
    static testmethod void testInitialState() {
		Order o = [SELECT Id,OpportunityId,AccountId,Account.BillingContact__c,Account.BillingStreet,Account.BillingCity,Account.BillingState,Account.BillingPostalCode,
						  Account.BillingCountry,Account.BillingContact__r.MailingStreet,Account.BillingContact__r.MailingCity,Account.BillingContact__r.MailingState,
						  Account.BillingContact__r.MailingPostalCode,Account.BillingContact__r.MailingCountry FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		PageReference pageRef = Page.SiteOrderApproval;
        pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();    

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		PageReference cancelPage = controller.cancelTransaction();

		Test.stopTest();

		System.assertEquals(null, controller.disableForm);
		System.assertEquals(false, controller.enableBillingInfoEdit);
		System.assertEquals(null, controller.signature);
		System.assertEquals(null, controller.termsAccepted);
		System.assertEquals(1, controller.lineItems.size());
		System.assertEquals(o.Id, controller.order.Id);
		System.assertEquals(o.OpportunityId, controller.opportunity.Id);
		System.assertEquals(o.AccountId, controller.account.Id);
		System.assertEquals(o.Account.BillingContact__c, controller.contact.Id);
		System.assertEquals(null, controller.updatedContact);
		System.assertNotEquals(null, controller.settings);
		System.assertNotEquals(null, controller.webSiteSettings);
		System.assertEquals(o.Account.BillingContact__r.MailingStreet, controller.shipToStreet);
		System.assertEquals(o.Account.BillingContact__r.MailingCity, controller.shipToCity);
		System.assertEquals(o.Account.BillingContact__r.MailingState, controller.shipToState);
		System.assertEquals(o.Account.BillingContact__r.MailingPostalCode, controller.shipToPostalCode);
		System.assertEquals(o.Account.BillingContact__r.MailingCountry, controller.shipToCountry);
		System.assertEquals(o.Account.BillingStreet, controller.billToStreet);
		System.assertEquals(o.Account.BillingCity, controller.billToCity);
		System.assertEquals(o.Account.BillingState, controller.billToState);
		System.assertEquals(o.Account.BillingPostalCode, controller.billToPostalCode);
		System.assertEquals(o.Account.BillingCountry, controller.billToCountry);					
		System.assertEquals('${0,number,#,##0.00}', controller.currencyShortFormatExpression);
		System.assertEquals('${0,number,#,##0.00} ' + UserInfo.getDefaultCurrency(), controller.currencyFormatExpression);
		System.assertEquals(0, controller.shipping);
		System.assertEquals(false, controller.showDiscount);
		System.assertEquals(false, controller.hasRecurringAmount);
		System.assertEquals(null, controller.recurringSetup);
		System.assertEquals(true, controller.requireSignatory);
		System.assertEquals(false, controller.hasExpiration);
		System.assertEquals(false, controller.alreadyPaid);
		System.assertEquals(true, controller.hasLineItems);
		System.assertEquals(null, controller.billToAddress);
		System.assertEquals(null, cancelPage);
	}

	/**
	* @description testInitialStateForDirect - 
	*/
    static testmethod void testInitialStateForDirect() {
		Order o = [SELECT Id,AVA_SFORDERS__Sales_Tax__c FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		PageReference pageRef = Page.SiteOrderApproval;
        pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();    

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(true, controller.canEditBillingInfo);
		System.assertEquals(50, controller.subtotal);
		System.assertEquals(50 + o.AVA_SFORDERS__Sales_Tax__c, controller.total);
		System.assertEquals(50, controller.discount);
		System.assertEquals(controller.total, controller.balance);
	}

	/**
	* @description testInitialStateForIndirect - 
	*/
	static testmethod void testInitialStateForIndirect() {
		Order o = [SELECT Id,AVA_SFORDERS__Sales_Tax__c FROM Order WHERE Opportunity.Name = 'Indirect' limit 1];

		PageReference pageRef = Page.SiteOrderApproval;
        pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();    

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(false, controller.canEditBillingInfo);
		System.assertEquals(200, controller.subtotal);
		System.assertEquals(200 + o.AVA_SFORDERS__Sales_Tax__c, controller.total);
		System.assertEquals(-100, controller.discount);
		System.assertEquals(controller.total, controller.balance);
	}
	
	/**
	* @description testChangeBillingContact - 
	*/
    static testmethod void testChangeBillingContact() {
		Order o = [SELECT Id,AccountId,Account.BillingContact__r.FirstName,Account.BillingContact__r.LastName,Account.BillingContact__r.Email,Account.BillingContact__r.Phone,Account.BillingStreet,Account.BillingCity,Account.BillingState,Account.BillingPostalCode,Account.BillingCountry FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		System.assertEquals(0,[SELECT count() FROM Contact WHERE AccountId = :o.AccountId and Email = 'giovanni.modica@getconga.com']);

		PageReference pageRef = Page.SiteOrderApproval;
        pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();    

		SiteOrderApprovalController controller = new SiteOrderApprovalController();
		System.assertEquals(false, controller.enableBillingInfoEdit);
		System.assertEquals(null, controller.updatedContact);

		controller.changeBillingInformation();
		System.assertNotEquals(null, controller.updatedContact);
		System.assertEquals(true, controller.enableBillingInfoEdit);

		controller.changeBillingInformation();
		System.assertEquals(null, controller.updatedContact);
		System.assertEquals(false, controller.enableBillingInfoEdit);

		controller.changeBillingInformation();
		System.assertNotEquals(null, controller.updatedContact);
		System.assertEquals(o.AccountId, controller.updatedContact.AccountId);
		System.assertEquals(o.Account.BillingContact__r.FirstName, controller.updatedContact.FirstName);
		System.assertEquals(o.Account.BillingContact__r.LastName, controller.updatedContact.LastName);
		System.assertEquals(o.Account.BillingContact__r.Phone, controller.updatedContact.Phone);
		System.assertEquals(o.Account.BillingContact__r.Email, controller.updatedContact.Email);
		System.assertEquals(o.Account.BillingStreet, controller.updatedContact.MailingStreet);
		System.assertEquals(o.Account.BillingCity, controller.updatedContact.MailingCity);
		System.assertEquals(o.Account.BillingState, controller.updatedContact.MailingState);
		System.assertEquals(o.Account.BillingPostalCode, controller.updatedContact.MailingPostalCode);
		System.assertEquals(o.Account.BillingCountry, controller.updatedContact.MailingCountry);

		controller.updatedContact.FirstName = 'Giovanni';
		controller.updatedContact.LastName = 'Modica';
		controller.updatedContact.Email = 'giovanni.modica@getconga.com';
		controller.updatedContact.Phone = '+1 (234) 567-8901'; 
		controller.updatedContact.MailingStreet = 'Street';
		controller.updatedContact.MailingCity = 'Miami';
		controller.updatedContact.MailingState = 'Florida';
		controller.updatedContact.MailingPostalCode = '35521';
		controller.updatedContact.MailingCountry = 'United States';

		controller.signature = 'Giovanni Modica';
		controller.termsAccepted = true;
		controller.processQuote();

		Test.stopTest();

		List<Contact> contacts = [SELECT Id,FirstName,LastName,AccountId,Email,Phone,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry FROM Contact WHERE AccountId = :o.AccountId and Email = 'giovanni.modica@getconga.com'];
		System.assertEquals(1,contacts.size());
		Contact c = contacts[0];
		System.assertEquals('Giovanni', c.FirstName);
		System.assertEquals('Modica', c.LastName);
		System.assertEquals('giovanni.modica@getconga.com', c.Email);
		System.assertEquals('+1 (234) 567-8901', c.Phone);
		System.assertEquals('Street', c.MailingStreet);
		System.assertEquals('Miami', c.MailingCity);
		System.assertEquals('Florida', c.MailingState);
		System.assertEquals('35521', c.MailingPostalCode);
		System.assertEquals('United States', c.MailingCountry);
		Account a = [SELECT Id,BillingContact__c FROM Account WHERE Id = :o.AccountId];
		System.assertEquals(c.Id, a.BillingContact__c);
	}

	/**
	* @description testChangeBillingContactWithDuplicate - 
	*/
    static testmethod void testChangeBillingContactWithDuplicate() {
		Order o = [SELECT Id,AccountId,Account.BillingContact__r.FirstName,Account.BillingContact__r.LastName,Account.BillingContact__r.Email,Account.BillingContact__r.Phone,Account.BillingStreet,Account.BillingCity,Account.BillingState,Account.BillingPostalCode,Account.BillingCountry FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		System.assertEquals(1, [SELECT count() FROM Contact WHERE AccountId = :o.AccountId and Email = 'jsnow@example.com']);

		PageReference pageRef = Page.SiteOrderApproval;
        pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();    

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		controller.changeBillingInformation();

		controller.updatedContact.FirstName = 'Jon';
		controller.updatedContact.LastName = 'Snow';
		controller.updatedContact.Email = 'jsnow@example.com';
		controller.updatedContact.Phone = '+1 (234) 567-8901'; 
		controller.updatedContact.MailingStreet = 'Street';
		controller.updatedContact.MailingCity = 'Miami';
		controller.updatedContact.MailingState = 'Florida';
		controller.updatedContact.MailingPostalCode = '35521';
		controller.updatedContact.MailingCountry = 'United States';

		controller.signature = 'Jon Snow';
		controller.termsAccepted = true;

		controller.processQuote();

		Test.stopTest();

		List<Contact> contacts = [SELECT Id,FirstName,LastName,AccountId,Email,Phone,MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry FROM Contact WHERE AccountId = :o.AccountId and Email = 'jsnow@example.com'];
		System.assertEquals(1,contacts.size());
		Contact c = contacts[0];
		System.assertEquals('Jon', c.FirstName);
		System.assertEquals('Snow', c.LastName);
		System.assertEquals('jsnow@example.com', c.Email);
		System.assertEquals('+1 (234) 567-8901', c.Phone);
		System.assertEquals('Street', c.MailingStreet);
		System.assertEquals('Miami', c.MailingCity);
		System.assertEquals('Florida', c.MailingState);
		System.assertEquals('35521', c.MailingPostalCode);
		System.assertEquals('United States', c.MailingCountry);
		Account a = [SELECT Id,BillingContact__c FROM Account WHERE Id = :o.AccountId];
		System.assertEquals(c.Id, a.BillingContact__c);
	}

	/**
	* @description testProductOrderProcess - 
	*/
    static testmethod void testProductOrderProcess() {
		Order o = [SELECT Id, OrderNumber, AccountId FROM Order WHERE Opportunity.Name = 'Indirect' limit 1];

		System.assertEquals(0, [SELECT count() FROM pymt__PaymentX__c]);
		System.assertEquals(0, [SELECT count() FROM pymt__Shopping_Cart_Item__c]);
		System.assertEquals(0, [SELECT count() FROM Task WHERE AccountId = :o.AccountId]);

		PageReference pageRef = Page.SiteOrderApproval;
        pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();    

		SiteOrderApprovalController controller = new SiteOrderApprovalController();
		controller.signature = 'Giovanni Modica';
		controller.termsAccepted = true;
		controller.processQuote();

		Test.stopTest();

		pymt__Processor_Connection__c processor = [SELECT Id,Name FROM pymt__Processor_Connection__c WHERE Name = 'Authorize.Net' limit 1];

		List<pymt__PaymentX__c> payments = [SELECT
												Id, 
												Name,
												pymt__Account__c,
												pymt__Amount__c,
												pymt__Billing_City__c,
												pymt__Billing_Company__c,
												pymt__Billing_Country__c,
												pymt__Billing_Email__c,
												pymt__Billing_First_Name__c,
												pymt__Billing_Last_Name__c,
												pymt__Billing_Phone__c,
												pymt__Billing_Postal_Code__c,
												pymt__Billing_State__c,
												pymt__Billing_Street__c,
												pymt__Contact__c,
												pymt__Currency_ISO_Code__c,
												pymt__Discount__c,
												pymt__Invoice_Number__c,
												pymt__Key__c,
												pymt__Log__c,
												pymt__Opportunity__c,
												Order__c,
												pymt__Date__c,
												pymt__Payment_Processor__c,
												pymt__Payment_Type__c,
												pymt__Processor_Connection__c,
												pymt__Shipping__c,
												pymt__Shipping_Method__c,
												pymt__Ship_To_City__c,
												pymt__Ship_To_Company__c,
												pymt__Ship_To_Country__c,
												pymt__Ship_To_First_Name__c,
												pymt__Ship_To_Last_Name__c,
												pymt__Ship_To_Name__c,
												pymt__Ship_To_Phone__c,
												pymt__Ship_To_Postal_Code__c,
												pymt__Ship_To_State__c,
												pymt__Ship_To_Street__c,
												pymt__Status__c,
												pymt__Tax__c,
												pymt__Transaction_Type__c
											FROM
												pymt__PaymentX__c];
		System.assertEquals(1, payments.size());
		pymt__PaymentX__c payment = payments[0];
		System.assertEquals(o.OrderNumber, payment.Name);
		System.assertEquals(o.AccountId, payment.pymt__Account__c);
		System.assertEquals(controller.balance, payment.pymt__Amount__c);
		System.assertEquals(controller.billToCity, payment.pymt__Billing_City__c);
		System.assertEquals(controller.account.Name, payment.pymt__Billing_Company__c);
		System.assertEquals(controller.billToCountry, payment.pymt__Billing_Country__c);
		System.assertEquals(controller.contact.Email, payment.pymt__Billing_Email__c);
		System.assertEquals(controller.contact.FirstName, payment.pymt__Billing_First_Name__c);
		System.assertEquals(controller.contact.LastName, payment.pymt__Billing_Last_Name__c);
		System.assertEquals(controller.contact.Phone, payment.pymt__Billing_Phone__c);
		System.assertEquals(controller.billToPostalCode, payment.pymt__Billing_Postal_Code__c);
		System.assertEquals(controller.billToState, payment.pymt__Billing_State__c);
		System.assertEquals(controller.billToStreet, payment.pymt__Billing_Street__c);
		System.assertEquals(controller.contact.Id, payment.pymt__Contact__c);
		System.assertEquals(UserInfo.getDefaultCurrency(), payment.pymt__Currency_ISO_Code__c);
		System.assertEquals(controller.discount, payment.pymt__Discount__c);
		System.assertEquals(o.OrderNumber, payment.pymt__Invoice_Number__c);
		System.assertNotEquals(null, payment.pymt__Key__c);
		System.assertEquals('++++ Payment on Invoice ' + o.OrderNumber + ':\nOnline payment for ' + String.valueOf(controller.total) + UserInfo.getDefaultCurrency(), payment.pymt__Log__c);
		System.assertEquals(controller.opportunity.Id, payment.pymt__Opportunity__c);
		System.assertEquals(o.Id, payment.Order__c);
		System.assertEquals(Date.today(), payment.pymt__Date__c);
		System.assertEquals(processor.Name, payment.pymt__Payment_Processor__c);
		System.assertEquals('Credit Card', payment.pymt__Payment_Type__c);
		System.assertEquals(processor.Id, payment.pymt__Processor_Connection__c);
		System.assertEquals(controller.shipping, payment.pymt__Shipping__c);
		System.assertEquals(controller.opportunity.quot__Shipping_Method__c, payment.pymt__Shipping_Method__c);
		System.assertEquals(controller.shipToCity, payment.pymt__Ship_To_City__c);
		System.assertEquals(controller.account.Name, payment.pymt__Ship_To_Company__c);
		System.assertEquals(controller.shipToCountry, payment.pymt__Ship_To_Country__c);
		System.assertEquals(controller.contact.FirstName, payment.pymt__Ship_To_First_Name__c);
		System.assertEquals(controller.contact.LastName, payment.pymt__Ship_To_Last_Name__c);
		System.assertEquals(controller.contact.Name, payment.pymt__Ship_To_Name__c);
		System.assertEquals(controller.contact.Phone, payment.pymt__Ship_To_Phone__c);
		System.assertEquals(controller.shipToPostalCode, payment.pymt__Ship_To_Postal_Code__c);
		System.assertEquals(controller.shipToState, payment.pymt__Ship_To_State__c);
		System.assertEquals(controller.shipToStreet, payment.pymt__Ship_To_Street__c);
		System.assertEquals('In Process', payment.pymt__Status__c);
		System.assertEquals(controller.tax, payment.pymt__Tax__c);
		System.assertEquals('Payment', payment.pymt__Transaction_Type__c);

		List<pymt__Shopping_Cart_Item__c> items = [SELECT
													Id,
													Name,
													pymt__Contact__c,
													pymt__Description__c,
													pymt__Line_Number__c,
													pymt__On_Payment_Completed__c,
													pymt__Payment__c,
													pymt__Product__c,
													pymt__Product_Code__c,
													pymt__Quantity__c,
													pymt__Tangible__c,
													pymt__Taxable__c,
													pymt__Unit_Price__c
												FROM
													pymt__Shopping_Cart_Item__c
												WHERE pymt__Payment__c = :payment.Id
												ORDER BY pymt__Line_Number__c];
        System.assertEquals(1, items.size());
		for(Integer i = 0; i < items.size(); i++) {
			pymt__Shopping_Cart_Item__c item = items[i];
			String pi = String.valueOf(i + 1);
			System.assertEquals('P' + pi, item.Name);
			System.assertEquals(payment.pymt__Contact__c, item.pymt__Contact__c);
			System.assertEquals('Product ' + pi,item.pymt__Description__c);
			System.assertEquals(i + 1, item.pymt__Line_Number__c);
			System.assertEquals(null, item.pymt__On_Payment_Completed__c);
			System.assertEquals(payment.Id, item.pymt__Payment__c);
			System.assertNotEquals(null, item.pymt__Product__c);
			System.assertEquals('P' + pi, item.pymt__Product_Code__c);
			System.assertEquals(i + 1, item.pymt__Quantity__c);
			System.assertEquals(false, item.pymt__Tangible__c);
			System.assertEquals(false, item.pymt__Taxable__c);
			System.assertEquals(item.pymt__Quantity__c * 200, item.pymt__Unit_Price__c);
		}

		List<Task> tasks = [SELECT Id,Subject,WhoId,WhatId,Status,Description FROM Task];
		System.assertEquals(1, tasks.size());
		Task t = tasks[0];
        System.assertEquals('SiteQuote Terms & Conditions Accepted', t.Subject);
        System.assertEquals(payment.pymt__Contact__c, t.WhoId);
        System.assertEquals(o.Id, t.WhatId);
        System.assertEquals('Completed', t.Status);
        System.assertEquals(controller.signature + ' accepted the Terms & Conditions on invoice ' + o.OrderNumber, t.Description);        
	}

	/**
	* @description testServiceOrderProcess - 
	*/
	static testmethod void testServiceOrderProcess() {
		Order o = [SELECT Id,AccountId,Account.BillingContact__r.FirstName,Account.BillingContact__r.LastName,Account.BillingContact__r.Email,Account.BillingContact__r.Phone,Account.BillingStreet,Account.BillingCity,Account.BillingState,Account.BillingPostalCode,Account.BillingCountry FROM Order WHERE Opportunity.Name = 'Service' limit 1];

		System.assertEquals(0, [SELECT count() FROM pymt__PaymentX__c]);
		System.assertEquals(0, [SELECT count() FROM pymt__Shopping_Cart_Item__c]);
		System.assertEquals(0, [SELECT count() FROM Task WHERE AccountId = :o.AccountId]);

		PageReference pageRef = Page.SiteOrderApproval;
        pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();    

		SiteOrderApprovalController controller = new SiteOrderApprovalController();
		controller.signature = 'Giovanni Modica';
		controller.termsAccepted = true;
		controller.processQuote();

		Test.stopTest();

		// payment and task generation is already tested testProductOrderProcess, so only test things specific to service
		List<pymt__PaymentX__c> payments = [SELECT Id,pymt__Contact__c FROM pymt__PaymentX__c];
		System.assertEquals(1, payments.size());
		pymt__PaymentX__c payment = payments[0];

		List<pymt__Shopping_Cart_Item__c> items = [SELECT
													Id,
													Name,
													pymt__Contact__c,
													pymt__Description__c,
													pymt__Line_Number__c,
													pymt__On_Payment_Completed__c,
													pymt__Payment__c,
													pymt__Product__c,
													pymt__Product_Code__c,
													pymt__Quantity__c,
													pymt__Tangible__c,
													pymt__Taxable__c,
													pymt__Unit_Price__c
												FROM
													pymt__Shopping_Cart_Item__c
												WHERE pymt__Payment__c = :payment.Id
												order by pymt__Line_Number__c];
		System.assertEquals(3, items.size());
		for(Integer i = 0; i < items.size(); i++) {
			pymt__Shopping_Cart_Item__c item = items[i];
			String pi = i == 2 ? String.valueOf(i) : String.valueOf(i + 1);
			System.assertEquals('M' + pi, item.Name);
			System.assertEquals(payment.pymt__Contact__c, item.pymt__Contact__c);
			System.assertEquals('Service ' + pi,item.pymt__Description__c);
			System.assertEquals(i + 1, item.pymt__Line_Number__c);
			System.assertEquals(null, item.pymt__On_Payment_Completed__c);
			System.assertEquals(payment.Id, item.pymt__Payment__c);
			System.assertNotEquals(null, item.pymt__Product__c);
			System.assertEquals(null, item.pymt__Product_Code__c);
			System.assertEquals((i == 2 ? (i - 1) : (i + 1)), item.pymt__Quantity__c); // positive
			System.assertEquals((i == 2 ? -1 : 1) * (i == 2 ? i : (i + 1)) * 100, item.pymt__Unit_Price__c); // thrid item should be a discount
		}		
	}
	
	/**
	* @description testNoOrder - 
	*/
    static testmethod void testNoOrder() {
		Order o = [SELECT Id FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		PageReference pageRef = Page.SiteOrderApproval;
		Test.setCurrentPage(pageRef);

		Test.startTest();

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(true, controller.disableForm);
		System.assertEquals(true, pageHasMessage(SiteOrderApprovalController.noOrderMessage), 'Page does not contains the right message: ' + SiteOrderApprovalController.noOrderMessage + '. Instead the message is: ' + ApexPages.getMessages()[0].getDetail());
		System.assertEquals(null, controller.shipToStreet);
		System.assertEquals(null, controller.shipToCity);
		System.assertEquals(null, controller.shipToState);
		System.assertEquals(null, controller.shipToPostalCode);
		System.assertEquals(null, controller.shipToCountry);
		System.assertEquals(null, controller.billToStreet);
		System.assertEquals(null, controller.billToCity);
		System.assertEquals(null, controller.billToState);
		System.assertEquals(null, controller.billToPostalCode);
		System.assertEquals(null, controller.billToCountry);
	}

	/**
	* @description testNoOrderFound - 
	*/
    static testmethod void testNoOrderFound() {
		Order o = [SELECT Id,OpportunityId FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		PageReference pageRef = Page.SiteOrderApproval;
		pageRef.getParameters().put('id', String.valueOf(o.OpportunityId));
		Test.setCurrentPage(pageRef);

		Test.startTest();

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(true, controller.disableForm);
		System.assertEquals(true, pageHasMessage(SiteOrderApprovalController.noOrderFoundMessage), 'Page does not contains the right message: ' + SiteOrderApprovalController.noOrderFoundMessage + '. Instead the message is: ' + ApexPages.getMessages()[0].getDetail());
	}

	/**
	* @description testNoOpportunity - 
	*/
    static testmethod void testNoOpportunity() {
		Order o = [SELECT Id,OpportunityId FROM Order WHERE Opportunity.Name = 'Direct' limit 1];
		o.OpportunityId = null;
		update o;

		PageReference pageRef = Page.SiteOrderApproval;
		pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(true, controller.disableForm);
		System.assertEquals(true, pageHasMessage(SiteOrderApprovalController.noOpportunityMessage), 'Page does not contains the right message: ' + SiteOrderApprovalController.noOpportunityMessage + '. Instead the message is: ' + ApexPages.getMessages()[0].getDetail());
	}

	/**
	* @description testNoSettings - 
	*/
    static testmethod void testNoSettings() {
		delete quot__QI_Settings__c.getOrgDefaults();

		Order o = [SELECT Id,OpportunityId FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		PageReference pageRef = Page.SiteOrderApproval;
		pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(true, controller.disableForm);
		System.assertEquals(true, pageHasMessage(SiteOrderApprovalController.noSettingsMessage), 'Page does not contains the right message: ' + SiteOrderApprovalController.noSettingsMessage + '. Instead the message is: ' + ApexPages.getMessages()[0].getDetail());
	}

	/**
	* @description testNoWebSiteSettings - 
	*/
    static testmethod void testNoWebSiteSettings() {
		delete pymt__Sites_Website_Settings__c.getInstance(SiteOrderApprovalController.SITE_NAME);

		Order o = [SELECT Id,OpportunityId FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		PageReference pageRef = Page.SiteOrderApproval;
		pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(true, controller.disableForm);
		System.assertEquals(true, pageHasMessage(String.format(SiteOrderApprovalController.noSiteSettingsMessage,new String[] { SiteOrderApprovalController.SITE_NAME })), 'Page does not contains the right message: ' + String.format(SiteOrderApprovalController.noSiteSettingsMessage,new String[] { SiteOrderApprovalController.SITE_NAME }) + '. Instead the message is: ' + ApexPages.getMessages()[0].getDetail());
	}

	/**
	* @description testNoSite - 
	*/
    static testmethod void testNoSite() {
		quot__QI_Settings__c settings = quot__QI_Settings__c.getOrgDefaults();
		settings.quot__Sites_Website__c = 'None';
		update settings;

		pymt__Sites_Website_Settings__c webSiteSettings = pymt__Sites_Website_Settings__c.getInstance(SiteOrderApprovalController.SITE_NAME);
		webSiteSettings.Name = 'None';
		update webSiteSettings;

		Order o = [SELECT Id,OpportunityId FROM Order WHERE Opportunity.Name = 'Direct' limit 1];

		PageReference pageRef = Page.SiteOrderApproval;
		pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(true, controller.disableForm);
		System.assertEquals(true, pageHasMessage(String.format(SiteOrderApprovalController.noSiteMessage,new String[] { 'None' })), 'Page does not contains the right message: ' + String.format(SiteOrderApprovalController.noSiteMessage,new String[] { 'None' }) + '. Instead the message is: ' + ApexPages.getMessages()[0].getDetail());
	}

	/**
	* @description testNoProcessor - 
	*/
    static testmethod void testNoProcessor() {
		Order o = [SELECT Id, OpportunityId FROM Order WHERE Opportunity.Name = 'Direct' LIMIT 1];

		delete [SELECT Id FROM pymt__Processor_Connection__c];

		PageReference pageRef = Page.SiteOrderApproval;
		pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();

		SiteOrderApprovalController controller = new SiteOrderApprovalController();

		Test.stopTest();

		System.assertEquals(true, controller.disableForm);
		System.assertEquals(true, pageHasMessage(SiteOrderApprovalController.noProcessorMessage), 'Page does not contains the right message: ' + SiteOrderApprovalController.noProcessorMessage + '. Instead the message is: ' + ApexPages.getMessages()[0].getDetail());
	}

	/**
	* @description testNoTermsAccepted - 
	*/
    static testmethod void testNoTermsAccepted() {
		Order o = [SELECT Id,OpportunityId FROM Order WHERE Opportunity.Name = 'Direct' LIMIT 1];

		PageReference pageRef = Page.SiteOrderApproval;
		pageRef.getParameters().put('id', String.valueOf(o.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();

		SiteOrderApprovalController controller = new SiteOrderApprovalController();
		controller.processQuote();

		Test.stopTest();

		System.assertEquals(true, pageHasMessage(SiteOrderApprovalController.acceptanceRequiredMessage), 'Page does not contains the right message: ' + SiteOrderApprovalController.acceptanceRequiredMessage + '. Instead the message is: ' + ApexPages.getMessages()[0].getDetail());
	}


	/**
	* @description pageHasMessage - 
	* @param String message
	* @return Boolean
	*/
	private static Boolean pageHasMessage(String message) {
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean hasMessage = false;
        for(Apexpages.Message msg : msgs) {
            if (msg.getDetail().contains(message)) hasMessage = true;
        }
        return hasMessage;
    }


}