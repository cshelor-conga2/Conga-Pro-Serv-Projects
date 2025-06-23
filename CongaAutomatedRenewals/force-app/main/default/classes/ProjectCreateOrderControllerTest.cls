/**
* @author Conga Services
* @date 20160909
* @version 1.00
* @description ProjectCreateOrderControllerTest - Test methods for the ProjectCreateOrderController class
*/
@isTest
private class ProjectCreateOrderControllerTest {

	/**
	* @description testCreateOrders - Test method for ProjectCreateOrderController methods
	*/
    @testSetup
    public static void setupTestData(){
    	TriggerHelper.OverrideAllSettings(true, false);

		List<Period__c> testPeriods = (List<Period__c>)TestingUtility.createSObjectList('Period__c', true, 2); 
		testPeriods[0].Start_Date__c = Date.today().addDays(-7);
		testPeriods[0].End_Date__c = Date.today();
		testPeriods[0].Type__c = 'Week';
		testPeriods[1].Start_Date__c = testPeriods[0].Start_Date__c.addDays(7);
		testPeriods[1].End_Date__c = testPeriods[0].End_Date__c.addDays(7);
		testPeriods[1].Type__c = 'Week';
		insert testPeriods;

		Id rAcctTypeId = UtilityClass.getRecordTypesForObject('Account').get('Business_Account');
		List<Account> testAccounts = (List<Account>)TestingUtility.createSObjectList('Account', true, 1);  
		testAccounts[0].Name = 'Winterfell Inc.';  
		testAccounts[0].RecordTypeId = rAcctTypeId;
		testAccounts[0].mrr_Active_MRR__c = 100.00;						
		insert testAccounts;

		List<Contact> testContacts = (List<Contact>)TestingUtility.createSObjectList('Contact', true, 1);
		testContacts[0].AccountId = testAccounts[0].Id;
		testContacts[0].FirstName = 'Test';
		testContacts[0].LastName = 'User';
		testContacts[0].Email = 'TestEmail@mailinator.com';
		insert testContacts;

		List<PS_Project__c> testProjects = (List<PS_Project__c>)TestingUtility.createSObjectList('PS_Project__c', true, 2);
		testProjects[0].AccountId__c = testAccounts[0].Id;
		testProjects[0].Name = 'Sample Project';
		testProjects[0].Rate__c = 1.0;
		testProjects[0].Is_Active__c = true;
		testProjects[1].AccountId__c = testAccounts[0].Id;
		testProjects[1].Name = 'Sample Project';
		testProjects[1].Is_Active__c = true;
		testProjects[1].Rate__c = 1.0;
		insert testProjects;

		List<Product2> testProducts = (List<Product2>)TestingUtility.createSObjectList('Product2', true, 2);
		testProducts[0].Name = 'prod1';
		testProducts[0].ProductCode = 'prod1';			
		testProducts[0].LOB__c = 'Services';
		testProducts[0].FY16_Revenue_Type__c = 'Non-Recurring';
		testProducts[1].Name = 'prod2';
		testProducts[1].ProductCode = 'prod2';			
		testProducts[1].LOB__c = 'Services';
		testProducts[1].FY16_Revenue_Type__c = 'Non-Recurring';		
		insert testProducts;

		List<Milestone__c> testMilestones = (List<Milestone__c>)TestingUtility.createSObjectList('Milestone__c', true, 2);
		testMilestones[0].Name = 'Sample Milestone 1';
		testMilestones[0].ProjectId__c = testProjects[0].Id;
		testMilestones[0].IsActive__c = true;
		testMilestones[0].Is_Billable__c = true;
		testMilestones[0].PricebookId__c = Test.getStandardPricebookId();
		testMilestones[0].Effective_Hourly_Rate__c = 5;
		testMilestones[0].ProductId__c = testProducts[0].Id;
		testMilestones[1].Name = 'Sample Milestone 3';
		testMilestones[1].ProjectId__c = testProjects[1].Id;
		testMilestones[1].IsActive__c = true;
		testMilestones[1].Is_Billable__c = true;
		testMilestones[1].PricebookId__c = Test.getStandardPricebookId();
		testMilestones[1].Effective_Hourly_Rate__c = 5;
		testMilestones[1].ProductId__c = testProducts[0].Id;	
		insert testMilestones;

		List<Project_Team__c> testProjectTeamsMembers = (List<Project_Team__c>)TestingUtility.createSObjectList('Project_Team__c', true, 3);
		testProjectTeamsMembers[0].Contact__c = testContacts[0].Id;
		testProjectTeamsMembers[0].Project__c = testProjects[0].Id;
		testProjectTeamsMembers[0].Role__c = 'Billing Contact';
		testProjectTeamsMembers[0].Billing_Contact__c = true;
		testProjectTeamsMembers[1].Contact__c = testContacts[0].Id;
		testProjectTeamsMembers[1].Project__c = testProjects[0].Id;
		testProjectTeamsMembers[1].Role__c = 'Billing Contact';
		testProjectTeamsMembers[1].Billing_Contact__c = true;
		testProjectTeamsMembers[2].Contact__c = testContacts[0].Id;
		testProjectTeamsMembers[2].Project__c = testProjects[1].Id;
		testProjectTeamsMembers[2].Role__c = 'Billing Contact';
		testProjectTeamsMembers[2].Billing_Contact__c = true;
		insert testProjectTeamsMembers;

		List<Time_Card_Header__c> testTimeCardHeaders = (List<Time_Card_Header__c>)TestingUtility.createSObjectList('Time_Card_Header__c', true, 1);
		testTimeCardHeaders[0].PeriodId__c = testPeriods[0].Id;
		testTimeCardHeaders[0].Status__c = 'Approved - Final';
		insert testTimeCardHeaders;

		List<Time_Card_Entry__c> testTimeCardEntries = (List<Time_Card_Entry__c>)TestingUtility.createSObjectList('Time_Card_Entry__c', false, 2);
		testTimeCardEntries[0].Time_Card_HeaderId__c = testTimeCardHeaders[0].Id;
		testTimeCardEntries[0].Notes__c = 'Test Notes';
		testTimeCardEntries[0].ProjectId__c = testProjects[0].Id;
		testTimeCardEntries[0].MilestoneId__c = testMilestones[0].Id;
		testTimeCardEntries[0].Hours_Entered__c = 2.00;
		testTimeCardEntries[0].Date_Entered__c = Date.today().addDays(-2);
		testTimeCardEntries[1].Time_Card_HeaderId__c = testTimeCardHeaders[0].Id;
		testTimeCardEntries[1].Notes__c = 'Test Notes';
		testTimeCardEntries[1].ProjectId__c = testProjects[1].Id;
		testTimeCardEntries[1].MilestoneId__c = testMilestones[1].Id;
		testTimeCardEntries[1].Hours_Entered__c = 10.00;
		testTimeCardEntries[1].Date_Entered__c = Date.today();
		insert testTimeCardEntries;

    	TriggerHelper.OverrideAllSettings(false, false);		
    }

	/**
	* @description testCreateOrders_SingleProject - Test method for ProjectCreateOrderController class using a Standard Controller
	*/
    private static testmethod void testCreateOrders_SingleProject(){
		List<PS_Project__c> projects = [SELECT Id FROM PS_Project__c];
		System.assert(projects.size() == 2);

		List<String> projectIds = new List<String>();
		for(PS_Project__c p : projects){
			projectIds.add(String.valueOf(p.Id));
		}

        Test.startTest();

		ApexPages.StandardController sc = new ApexPages.StandardController(projects[0]);
		PageReference pageRef = Page.Project_List_Create_Order;
		ApexPages.currentPage().getParameters().put('id', projects[0].Id);

		ProjectCreateOrderController cn = new ProjectCreateOrderController(sc);
		cn.StandardPricebookId = Test.getStandardPricebookId();
		cn.CreateOrder();
        
        Test.stopTest(); 
        
        List<Order> orders = [SELECT Id, (SELECT Id, Quantity, UnitPrice FROM OrderItems) FROM Order WHERE ProjectId__c = :projects[0].Id];
        System.assert(orders.size() == 1);
		System.assert(orders[0].OrderItems.size() == 1);
        System.assert(orders[0].OrderItems[0].UnitPrice == 5);
        System.assert(orders[0].OrderItems[0].Quantity == 2);
    }

	/**
	* @description testCreateOrders_MultipleProjects - Test method for ProjectCreateOrderController class using a Standard SET Controller
	*/
    private static testmethod void testCreateOrders_MultipleProjects(){
		List<PS_Project__c> projects = [SELECT Id FROM PS_Project__c];
		System.assert(projects.size() == 2);

		List<String> projectIds = new List<String>();
		String projectIdsString = projects[0].Id + ',' + projects[1].Id;
		for(PS_Project__c p : projects){
			projectIds.add(String.valueOf(p.Id));
		}

        Test.startTest();

		ApexPages.StandardSetController sc = new ApexPages.StandardSetController(projects);
		PageReference pageRef = Page.Project_List_Create_Order;
		ApexPages.currentPage().getParameters().put('projectRecordIds', projectIdsString);

		ProjectCreateOrderController cn = new ProjectCreateOrderController(sc);
		cn.StandardPricebookId = Test.getStandardPricebookId();
		cn.CreateOrder();
        
        Test.stopTest(); 
        
        List<Order> orders = [SELECT Id, (SELECT Id, Quantity, UnitPrice FROM OrderItems) FROM Order WHERE ProjectId__c IN :projects];
        System.assert(orders.size() == 2);
		System.assert(orders[0].OrderItems.size() == 1);
        System.assert(orders[1].OrderItems.size() == 1);
        System.assert(orders[0].OrderItems[0].UnitPrice == 5);
        System.assert(orders[0].OrderItems[0].Quantity == 2);
        System.assert(orders[1].OrderItems[0].UnitPrice == 5);
        System.assert(orders[1].OrderItems[0].Quantity == 10);
    }

	/**
	* @description testCreateOrders_ExecuteTwiceOnSameProject - Test method for ProjectCreateOrderController class using a Standard Controller
	*/
    private static testmethod void testCreateOrders_ExecuteTwiceOnSameProject(){
		List<PS_Project__c> projects = [SELECT Id FROM PS_Project__c];
		System.assert(projects.size() == 2);

		List<String> projectIds = new List<String>();
		for(PS_Project__c p : projects){
			projectIds.add(String.valueOf(p.Id));
		}

        Test.startTest();

		ApexPages.StandardController sc = new ApexPages.StandardController(projects[0]);
		PageReference pageRef = Page.Project_List_Create_Order;
		ApexPages.currentPage().getParameters().put('id', projects[0].Id);

		ProjectCreateOrderController cn = new ProjectCreateOrderController(sc);
		cn.StandardPricebookId = Test.getStandardPricebookId();
		cn.CreateOrder();

		// CALL AGAIN TO TEST THAT NO MORE ORDERS THAN NECESSARY ARE CREATED
		cn.CreateOrder();

        Test.stopTest(); 
        
        List<Order> orders = [SELECT Id, (SELECT Id, Quantity, UnitPrice FROM OrderItems) FROM Order WHERE ProjectId__c = :projects[0].Id];
        System.assert(orders.size() == 1);
		System.assert(orders[0].OrderItems.size() == 1);
        System.assert(orders[0].OrderItems[0].UnitPrice == 5);
        System.assert(orders[0].OrderItems[0].Quantity == 2);
    }

	/**
	* @description testFindOrCreatePricebookEntry - Test method for FindOrCreatePricebookEntry helper method
	*/
    private static testmethod void testFindOrCreatePricebookEntry(){
    	List<PS_Project__c> projects = [SELECT Id FROM PS_Project__c];
		System.assert(projects.size() == 2);

		List<Product2> products = [SELECT Id FROM Product2];
		System.assert(products.size() == 2);

		ApexPages.StandardController sc = new ApexPages.StandardController(projects[0]);
		PageReference pageRef = Page.Project_List_Create_Order;
		ApexPages.currentPage().getParameters().put('id', projects[0].Id);
		ProjectCreateOrderController cn = new ProjectCreateOrderController(sc);

		Id standardPricebookId = Test.getStandardPricebookId();
		Pricebook2 customPricebook = new Pricebook2(Name = 'Custom Pricebook', IsActive = true);
		insert customPricebook;
		
		cn.StandardPricebookId = Test.getStandardPricebookId();
		cn.PricebookEntries = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE IsActive = true 
							   AND (Pricebook2Id = :standardPricebookId OR Pricebook2Id = :customPricebook.Id) 
							   AND Product2Id IN :products];

        Test.startTest();

		// NO STANDARD PRICEBOOK ENTRY EXIST FOR PRODUCT YET, CREATE STANDARD ENTRY
		Id standardEntryId = cn.FindOrCreatePricebookEntry(standardPricebookId, products[0].Id, 50.00);
		System.assert(standardEntryId != null);

		// NO CUSTOM PRICEBOOK ENTRY EXIST FOR PRODUCT YET, CREATE CUSTOM ENTRY
		Id customEntryId = cn.FindOrCreatePricebookEntry(customPricebook.Id, products[0].Id, 50.00);
		System.assert(standardEntryId != null);
		System.assert(standardEntryId != customEntryId);

		// RETURN EXISTING STANDARD ENTRY
		standardEntryId = cn.FindOrCreatePricebookEntry(standardPricebookId, products[0].Id, 50.00);
		System.assert(standardEntryId != null);
		System.assert(standardEntryId != customEntryId);		

		// RETURN EXISTING CUSTOM ENTRY
		customEntryId = cn.FindOrCreatePricebookEntry(customPricebook.Id, products[0].Id, 50.00);
		System.assert(customEntryId != null);
		System.assert(customEntryId != standardEntryId);

		// GET CUSTOM PRICEBOOK ENTRY FOR PRODUCT THAT HAS NO ENTRIES YET
		Id customEntry2Id = cn.FindOrCreatePricebookEntry(customPricebook.Id, products[1].Id, 50.00);
		System.assert(customEntry2Id != null);
		System.assert(customEntry2Id != standardEntryId);
		System.assert(customEntry2Id != customEntryId);

        Test.stopTest(); 
    }


}