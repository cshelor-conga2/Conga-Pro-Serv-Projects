/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180512
* @version 1.0
* @description IntacctSyncHelperTest - Test class for the IntacctSyncHelper class. Executes tests in the IntacctIntegrationServiceTest test class.
*/
@isTest
private class IntacctSyncHelperTest {

    /**
    * @description setup - 
    */
    @testSetup
    private static void setup() {
        IntacctIntegrationServiceTest.setup();
    }

    /**
    * @description testProject - 
    */
    private static testmethod void testProject() {
        Test.startTest();

        IntacctSyncHelper.runOnTest = true;
        IntacctIntegrationServiceTest.insertTestProject();

        Test.stopTest();
    }

    /**
    * @description testMilestone - 
    */
    private static testmethod void testMilestone() {
        PS_Project__c project = IntacctIntegrationServiceTest.insertTestProject();

        Test.startTest();

        IntacctSyncHelper.runOnTest = true;
        IntacctIntegrationServiceTest.insertTestMilestone(project.Id);

        Test.stopTest();
    }

    /**
    * @description testTimeCard - 
    */
    private static testmethod void testTimeCard() {
        PS_Project__c project = IntacctIntegrationServiceTest.insertTestProject();
        Milestone__c milestone = IntacctIntegrationServiceTest.insertTestMilestone(project.Id);

        Test.startTest();

        IntacctSyncHelper.runOnTest = true;
        IntacctIntegrationServiceTest.insertTestTimeCardHeader(project.Id, milestone.Id);

        Test.stopTest();
    }

    /**
    * @description testIntacctContract - 
    */
    private static testmethod void testIntacctContract() {
        Test.startTest();

        IntacctSyncHelper.runOnTest = true;
        IntacctIntegrationServiceTest.insertTestIntacctContract();

        Test.stopTest();
    }

    /**
    * @description testIntacctContractLine - 
    */
    private static testmethod void testIntacctContractLine() {
        List<Opportunity> opportunities = IntacctIntegrationServiceTest.setupOpportunities();
        PS_Project__c project = IntacctIntegrationServiceTest.insertTestProject();
        Milestone__c milestone = IntacctIntegrationServiceTest.insertTestMilestone(project.Id);
        ia_crm__Intacct_Contract__c contract = IntacctIntegrationServiceTest.insertTestIntacctContract();

        Test.startTest();

        IntacctSyncHelper.runOnTest = true;
        TriggerHelper.OverrideAllSettings(true,true);
        IntacctIntegrationServiceTest.insertTestIntacctContractLine(contract.Id, opportunities[0].Id, project, milestone);

        Test.stopTest();
    }

    /**
    * @description testErrors - 
    */
    private static testmethod void testErrors() {
        IntacctSyncHelper.errorOnTest = true;

        TriggerHelper.OverrideAllSettings(true,true);

        Test.startTest();

        PSProjectHelper.intacctSyncProjects(new Map<Id,PS_Project__c>(), new Map<Id,PS_Project__c>());
        ProjectTeamHelper.intacctSyncProjectTeams(new Map<Id,Project_Team__c>(), new Map<Id,Project_Team__c>());
        MilestoneHelper.intacctSyncMilestones(new Map<Id,Milestone__c>(), new Map<Id,Milestone__c>());
        IACRMIntacctContractLineHelper.intacctSyncIntacctContractLines(new Map<Id,ia_crm__Intacct_Contract_Line__c>(), new Map<Id,ia_crm__Intacct_Contract_Line__c>());
        IACRMProjectHelper.intacctSyncIntacctProjects(new Map<Id,ia_crm__Project__c>(), new Map<Id,ia_crm__Project__c>());
        IACRMTaskHelper.intacctSyncIntacctTasks(new Map<Id,ia_crm__Task__c>(), new Map<Id,ia_crm__Task__c>());
        TimeCardEntryHelper.intacctSyncTimeCardEntries(new Map<Id,Time_Card_Entry__c>(), new Map<Id,Time_Card_Entry__c>());
        TimeCardHeaderHelper.intacctSyncTimeCardHeaders(new Map<Id,Time_Card_Header__c>(), new Map<Id,Time_Card_Header__c>());

        Test.stopTest();

        IntacctSyncHelper.errorOnTest = false;

        TriggerHelper.OverrideAllSettings(false, false);
    }


}