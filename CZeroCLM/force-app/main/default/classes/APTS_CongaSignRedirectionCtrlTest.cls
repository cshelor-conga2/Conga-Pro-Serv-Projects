@isTest
public class APTS_CongaSignRedirectionCtrlTest 
{
	@testSetup 
    static void setupTestData()
    {
        Trigger_Switches_Bypass__c custSetting = new Trigger_Switches_Bypass__c(Name = 'SurvivorParentAccount',
                                                                                errormessage__c = 'This account is identified as a duplicate and is being prepared to be merged please use this survivor account:',
                                                                                isActive__c = True); 
        insert custSetting;
        
        
        
        List<TriggerSwitch__c> switches = new List<TriggerSwitch__c>();        
        TriggerSwitch__c switch0 = new TriggerSwitch__c();
        switch0.Name = 'APTSCPQHandler_ProposalAutoUpdOpp';
        switch0.IsActive__c = false;
        //switches.add(switch0);
        TriggerSwitch__c switch1 = new TriggerSwitch__c();
        switch1.Name = 'APTSCPQHandler_ProposalSetApproval';
        switch1.IsActive__c = false;
        switches.add(switch1);
        TriggerSwitch__c switch2 = new TriggerSwitch__c();
        switch2.Name = 'APTSCPQHandler_StopOppUpdateOnProposal';
        switch2.IsActive__c = false;
        switches.add(switch2);
        TriggerSwitch__c switch3 = new TriggerSwitch__c();
        switch3.Name = 'APTSCPQHandler_ProposalSetOppType';
        switch3.IsActive__c = false;
        switches.add(switch3);
        TriggerSwitch__c switch4 = new TriggerSwitch__c();
        switch4.Name = 'APTSCPQHandler_ProposalSetPricelist';
        switch4.IsActive__c = false;
        switches.add(switch4);
        TriggerSwitch__c switch5 = new TriggerSwitch__c();
        switch5.Name = 'APTSCPQHandler_ProposalRollUpOppAccept';
        switch5.IsActive__c = false;
        switches.add(switch5);
        
        TriggerSwitch__c switch6 = new TriggerSwitch__c();
        switch6.Name = 'APTSCPQHandler_ProposalRollUpAcceptNum';
        switch6.IsActive__c = false;
        switches.add(switch6);

        TriggerSwitch__c switch7 = new TriggerSwitch__c();
        switch7.Name = 'APTSCPQHandler_ProposalUpdDRBStatus';
        switch7.IsActive__c = false;
        switches.add(switch7);

        TriggerSwitch__c switch8 = new TriggerSwitch__c();
        switch8.Name = 'APTSCPQHandler_ProposalSetPropRequest';
        switch8.IsActive__c = false;
        //switches.add(switch8);

        TriggerSwitch__c switch9 = new TriggerSwitch__c();
        switch9.Name = 'APTSCPQHandler_CancelPropsOnPropAccept';
        switch9.IsActive__c = false;
        switches.add(switch9);

        APTSCPQHandler_OppSetBillShipToProposal.isRun = false;
        APTS_OpportunityAgreementHandler.isRun = false;
        
        TriggerSwitch__c switch10 = new TriggerSwitch__c();
        switch10.Name = 'APTSCPQHandler_OppSetValueToProposal';
        switch10.IsActive__c = false;
        switches.add(switch10);



        TriggerSwitch__c switch11 = new TriggerSwitch__c();
        switch11.Name = 'APTSCPQHandler_OptySetRenewalFields';
        switch11.IsActive__c = false;
        switches.add(switch11);

        TriggerSwitch__c switch13 = new TriggerSwitch__c();
        switch13.Name = 'APTSCPQHandler_PropRenewalUpliftChange';
        switch13.IsActive__c = false;
        switches.add(switch13);
        
        TriggerSwitch__c switch14 = new TriggerSwitch__c();
        switch14.Name = 'APTSCPQHandler_PropMSSAChange';
        switch14.IsActive__c = false;
        switches.add(switch14);   
        
        TriggerSwitch__c switch15 = new TriggerSwitch__c();
        switch15.Name = 'APTSCPQHandler_ABODataSync';
        switch15.IsActive__c = false;
        switches.add(switch15);   
        
        TriggerSwitch__c switch16 = new TriggerSwitch__c();
        switch16.Name = 'APTSCPQHandler_ConfigSetApproval';
        switch16.IsActive__c = false;
        switches.add(switch16);
        
        TriggerSwitch__c switch17 = new TriggerSwitch__c();
        switch17.Name = 'APTSCPQHandler_SetAgreementOnAsset';
        switch17.IsActive__c = false;
        switches.add(switch17);        
        
        TriggerSwitch__c switch18 = new TriggerSwitch__c();
        switch18.Name = 'APTSSalesHandler_SetOpportunityFields';
        switch18.IsActive__c = false;
        switches.add(switch18);
        
        TriggerSwitch__c switch19 = new TriggerSwitch__c();
        switch19.Name = 'APTSCPQHandler_PopulateDataOnOpp';
        switch19.IsActive__c = false;
        switches.add(switch19);
        
        TriggerSwitch__c switch20 = new TriggerSwitch__c();
        switch20.Name = 'APTSCPQHandler_UpdateSandboxCountPC';
        switch20.IsActive__c = false;
        switches.add(switch20);

        TriggerHandlerBase.disableAllTriggerHandlers(Account.sObjectType);
        TriggerHandlerBase.disableAllTriggerHandlers(Opportunity.sObjectType);
        TriggerHandlerBase.disableAllTriggerHandlers(Contact.sObjectType);
        TriggerHandlerBase.disableAllTriggerHandlers(PSAService_Estimate__c.sObjectType);
        TriggerFactory.SetTriggerDisabled(true);
        ISRHandler.SetTriggerDisabled(true);
      
        SalesOpportunityTriggerHandler.runOnce = false;
        
        insert switches;
        //Create Account
        Account testAccount = new Account();
        testAccount.Name ='Test Account 101';
        testAccount.Account_Region__c = 'North America Enterprise';
        testAccount.Sub_Region__c = 'Central';
        testAccount.Vertical__c = 'North America Enterprise';
        testAccount.CurrencyIsoCode = 'USD';
        insert testAccount;

         //Create Opportunity
         Opportunity testOpportunity = new Opportunity();
         testOpportunity.Name = 'Test Opportunity 101';
         testOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Subscription').getRecordTypeId();
         //testOpportunity.OwnerID = testUser.Id;
         testOpportunity.AccountId = testAccount.ID;
         testOpportunity.CloseDate = Date.today();
         testOpportunity.Type = Label.APTS_Oppty_RecordType_NewLogo;   //'New Business - New Logo';
         testOpportunity.StageName = '1 - New';
         testOpportunity.Region__c = 'North America Enterprise';
         testOpportunity.Sub_Region__c = 'Central';
         testOpportunity.ForecastCategoryName = 'Pipeline';
         testOpportunity.Expected_Start_Date__c = Date.today();
         testOpportunity.CloseDate = Date.today();
         //testOpportunity.Contact__c = testContact.Id;
         testOpportunity.CurrencyIsoCode = 'USD';
         insert testOpportunity;
 
 
         //Create Proposal
         Apttus_Proposal__Proposal__c testProposal = new Apttus_Proposal__Proposal__c();
         testProposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal 101';
         //testProposal.RecordTypeId = Schema.SObjectType.get('Apttus_Proposal__Proposal__c').getRecordTypeInfosByName().get('New Sales').getRecordTypeId();
         testProposal.RecordTypeId = Schema.getGlobalDescribe().get('Apttus_Proposal__Proposal__c').getDescribe().getRecordTypeInfosByName().get('New Sales').getRecordTypeId();
         //testProposal.OwnerId = testUser.Id;
         testProposal.Apttus_Proposal__Account__c = testAccount.Id;
         testProposal.Apttus_Proposal__Opportunity__c = testOpportunity.Id;
         //testProposal.Apttus_Proposal__Primary_Contact__c = testContact.Id; 
         testProposal.CurrencyIsoCode ='USD';
         insert testProposal;
 
        //Create request Agreement
        //
        List<Apttus__APTS_Agreement__c> agreements = new List<Apttus__APTS_Agreement__c>();
        
        Apttus__APTS_Agreement__c testAgreement1 = new Apttus__APTS_Agreement__c();
        testAgreement1.Name = 'Test Agreement 1';
        testAgreement1.RecordTypeId = Schema.getGlobalDescribe().get('Apttus__APTS_Agreement__c').getDescribe().getRecordTypeInfosByName().get('Order').getRecordTypeId();
        testAgreement1.Apttus__Account__c = testAccount.Id;
        testAgreement1.Apttus_QPComply__RelatedProposalId__c = testProposal.Id;
        testAgreement1.Apttus__Status_Category__c = 'Request';
        testAgreement1.Apttus__Status__c = 'Request';
        testAgreement1.APTS_Type_of_Paper__c = 'Apttus Standard';
        testAgreement1.Apttus__Perpetual__c = true;
        //testAgreement1.OwnerId = testUser.Id;
        testAgreement1.MSSA_Exception__c = 'Standalone X-Author';
        //agreements.add(testAgreement1);
        
        Contact signatory = new Contact();
        signatory.FirstName = 'Test';
        signatory.LastName = 'User';
        signatory.Email = 'test@test.com';
        insert signatory;
        
        Apttus__APTS_Agreement__c testAgreement2 = new Apttus__APTS_Agreement__c();
        testAgreement2.Name = 'Test Agreement 2';
        testAgreement2.RecordTypeId = Schema.getGlobalDescribe().get('Apttus__APTS_Agreement__c').getDescribe().getRecordTypeInfosByName().get('SOW').getRecordTypeId();
        testAgreement2.Apttus__Account__c = testAccount.Id;
        testAgreement2.Apttus_QPComply__RelatedProposalId__c = testProposal.Id;
        testAgreement2.Apttus__Status_Category__c = 'Request';
        testAgreement2.Apttus__Status__c = 'Request';
        testAgreement2.APTS_Type_of_Paper__c = '';
        testAgreement2.Apttus__Perpetual__c = true;
        testAgreement2.APTS_Customer_Signatory_Contact__c = signatory.Id;
        testAgreement2.ACV_Contract_Value_if_applicable__c = 500000;
        //testAgreement2.OwnerId = testUser.Id;
        //testAgreement2.MSSA_Exception__c = 'Standalone X-Author';
        agreements.add(testAgreement2);
        
        insert agreements;
        //insert testAgreement1;
    }
    
   /* @isTest 
    static void testExecute()
    {
        Apttus__APTS_Agreement__c agmt = [Select id from Apttus__APTS_Agreement__c limit 1];
        
    	PageReference pageRef = Page.APTS_CongaSignRedirection;
		test.setCurrentPageReference(pageRef);
        
        pageRef.getParameters().put('id',agmt.Id);
        
        APTS_CongaSignRedirectionCtrl ctrl = new APTS_CongaSignRedirectionCtrl();
        ctrl.execute();
    }*/
    @isTest 
    static void testExecute1()
    {
        Apttus__APTS_Agreement__c agmt = [Select id,RecordTypeId,Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Opportunity__r.Contact__c,Apttus__Account__r.Name,
                                               Conga_Signatory__c,APTS_Record_Type_Name__c,Order_Type__c,APTS_Legal_Initials__c,APTS_Notes_Legal_Approved__c ,Apttus__Requestor__c, Apttus__Related_Opportunity__r.Apttus_Service_Bookings__c ,APTS_Customer_Signatory_Contact__c, ACV_Contract_Value_if_applicable__c from Apttus__APTS_Agreement__c limit 1];
        //agmt.RecordTypeId = Schema.getGlobalDescribe().get('Apttus__APTS_Agreement__c').getDescribe().getRecordTypeInfosByName().get('SOW').getRecordTypeId();
        //update agmt;
        APTS_C4C_Custom_Metadata__mdt config = [SELECT APTS_Conga_Sign_Routing_Type__c,APTS_Conga_Sign_Email_Subject__c,APTS_Conga_Sign_Email_Message__c 
                                                FROM APTS_C4C_Custom_Metadata__mdt 
                                                WHERE DeveloperName='System_Properties'];
        
    	PageReference pageRef = Page.APTS_CongaSignRedirection;
		test.setCurrentPageReference(pageRef);
        
        pageRef.getParameters().put('id',agmt.Id);
        
        APTS_CongaSignRedirectionCtrl ctrl = new APTS_CongaSignRedirectionCtrl();
        ctrl.execute();
        ctrl.recipientsForOrderAgreements(agmt, config);
        ctrl.recipientsForNonOrderAgreements(agmt, config);
        ctrl.recipientsForPSODAgreements(agmt, config);
        ctrl.recipientsForTSOAgreements(agmt, config);
        ctrl.recipientsForLegalAgreements(agmt, config);
    }
}