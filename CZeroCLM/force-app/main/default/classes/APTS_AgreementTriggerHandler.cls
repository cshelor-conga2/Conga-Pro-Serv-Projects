/**
* @Name: APTS_AgreementTriggerHandler
* @Author: APTTUS
* @CreateDate: 07/31/2019
* @Description: Triggerhandler for Agreement Trigger.
-----------------------------------------------------------------------------------------------
**/
public class APTS_AgreementTriggerHandler{
    
    public static Boolean runOnceBeforeInsert = false;
    public static Boolean runOnceBeforeUpdate = false;
    public static Boolean runOnceBeforeInsertUpdate = false;
    public static Boolean runOnceBeforeDelete = false;
    public static Boolean runOnceAfterInsert = false;
    public static Boolean runOnceAfterUpdate = false;
    public static Boolean runOnceAfterInsertUpdate = false;
    public static Boolean executeTrigger = true;
    public static Boolean executionRunOnceAfterUpdate = true;
    
    //Is used to control the recurrsion. 
    public static Set<String> methods = new Set<String>();
    
    public static Boolean checkRecursiveFirstCall = false;
    public static void onBeforeUpdate(List<Apttus__APTS_Agreement__c> newList, Map<Id,Apttus__APTS_Agreement__c> newAgreementMap, Map<ID, Apttus__APTS_Agreement__c> oldMap){
        system.debug('***AgreementHandler : Calling onBeforeUpdate Agreement');
        List<Apttus__APTS_Agreement__c> psodAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> sowAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> ndaAgreementList = new List<Apttus__APTS_Agreement__c>();
        Map<Id,Apttus__APTS_Agreement__c> orderAgreementMap = new Map<Id,Apttus__APTS_Agreement__c>();
        Map<Id,Apttus__APTS_Agreement__c> sowAgreementMap = new Map<Id,Apttus__APTS_Agreement__c>();
        Map<Id,Apttus__APTS_Agreement__c> tsoAgreementMap = new Map<Id,Apttus__APTS_Agreement__c>();


        for(Apttus__APTS_Agreement__c agreement : newList){

            if(agreement.APTS_Record_Type_Name__c == 'PSOD'){
                psodAgreementList.add(agreement);
            }
            if(agreement.APTS_Record_Type_Name__c == 'SOW'){
              sowAgreementList.add(agreement);
            }
            if(agreement.APTS_Record_Type_Name__c == 'NDA'){
              ndaAgreementList.add(agreement);
            }



            if(!String.isBlank(agreement.APTS_Notes__c) && agreement.APTS_Notes__c!=oldMap.get(agreement.Id).APTS_Notes__c){
                agreement.Non_Standard_Legal_Language_on_Order__c = true;
            }

            //reset flag upon approval for HAR-14642
            if(agreement.Apttus_Approval__Approval_Status__c == 'Approved' && agreement.Apttus_Approval__Approval_Status__c!=oldMap.get(agreement.Id).Apttus_Approval__Approval_Status__c){
                agreement.Non_Standard_Legal_Language_on_Order__c = false;
            }
            //Apttus_Approval.ApprovalRequiredCheck checker = new Apttus_Approval.ApprovalRequiredCheck();
            //Boolean result = checker.doCheck(agreement.Id);
        }

        for(Apttus__APTS_Agreement__c agreement: newAgreementMap.values())
        {
            if(agreement.APTS_Record_Type_Name__c == 'Order'){
                orderAgreementMap.put(agreement.Id, agreement);
              }

              if(agreement.APTS_Record_Type_Name__c == 'SOW'){
                sowAgreementMap.put(agreement.Id, agreement);
              }
              
              if(agreement.APTS_Record_Type_Name__c == 'TSO'){
                tsoAgreementMap.put(agreement.Id, agreement);
              }
        }

        if(!psodAgreementList.isEmpty()){
            system.debug('***AgreementHandler onBeforeUpdate Start : updateSignedAgreementWithUser');
            APTS_AgreementTriggerHelper.updateSignedAgreementWithUser(psodAgreementList);
            system.debug('***AgreementHandler onBeforeUpdate End : updateSignedAgreementWithUser');
            
            system.debug('***AgreementHandler onBeforeUpdate Start : updateFYandFQ');
            APTS_AgreementTriggerHelper.updateFYandFQ(psodAgreementList);
            system.debug('***AgreementHandler onBeforeUpdate End : updateFYandFQ');
            
            //This method is called on before update to set the MSSA as Parent Agreement on PSOD and SOW agreements
            system.debug('***AgreementHandler onBeforeUpdate Start : updateMSSAOnAgreement');
            APTS_AgreementTriggerHelper.updateMSSAOnAgreement(psodAgreementList);
            system.debug('***AgreementHandler onBeforeUpdate End : updateMSSAOnAgreement');
      
        }

        if(!sowAgreementList.isEmpty()){
            // Set the owner of the SOW agreement to a user with authority to send for signatures when SOW is in Ready For Signature.
          system.debug('***AgreementHandler onBeforeUpdate Start : updateSOWAgreementWithUser');
          APTS_AgreementTriggerHelper.updateSOWAgreementWithUser(sowAgreementList);
          system.debug('***AgreementHandler onBeforeUpdate Start : updateSOWAgreementWithUser');
      
      //CIT-7614
      system.debug('***AgreementHandler onBeforeUpdate Start : populateQueueIdForTaskDefaulting');
          APTS_AgreementTriggerHelper.populateQueueIdForTaskDefaulting(sowAgreementList);
          system.debug('***AgreementHandler onBeforeUpdate Start : populateQueueIdForTaskDefaulting');

          //This method is called on before update to set the MSSA as Parent Agreement on PSOD and SOW agreements
          system.debug('***AgreementHandler onBeforeUpdate Start : updateMSSAOnAgreement');
          APTS_AgreementTriggerHelper.updateMSSAOnAgreement(sowAgreementList);
          system.debug('***AgreementHandler onBeforeUpdate End : updateMSSAOnAgreement');
      
    //CIT-10108
         system.debug('***AgreementHandler onBeforeUpdate Start : populateTermAndAgreementEndDate');
         APTS_AgreementTriggerHelper.populateTermAndAgreementEndDate(psodAgreementList);
         system.debug('***AgreementHandler onBeforeUpdate End : populateTermAndAgreementEndDate');
        }

        if(!orderAgreementMap.isEmpty()){
            system.debug('***AgreementHandler onBeforeUpdate Start : updateAgreementLineItemRelatedFlags');
            APTS_AgreementTriggerHelper.updateAgreementLineItemRelatedFlags(orderAgreementMap);
            system.debug('***AgreementHandler onBeforeUpdate End : updateAgreementLineItemRelatedFlags');
            //Richa
            //system.debug('***AAA**AgreementHandler onBeforeUpdate Start : markAgreementEligibleForIntegrationA12C1');
             //APTS_AgreementTriggerHelper.markAgreementEligibleForIntegrationA12C1(orderAgreementMap, oldMap);
            //system.debug('***AAA**AgreementHandler onBeforeUpdate Start : markAgreementEligibleForIntegrationA12C1');
            APTS_AgreementTriggerHelper.setDefaultPaymentTerm(orderAgreementMap.values(), oldMap);
            APTS_AgreementTriggerHelper.setPORequired(orderAgreementMap.values(), oldMap);
            APTS_AgreementTriggerHelper.setLegalInitials(orderAgreementMap.values());
            APTS_AgreementTriggerHelper.UpdateTypeOfPaperOnOrderAgreement(orderAgreementMap.values());////CIT-14945
        }

        if(!sowAgreementMap.isEmpty()){
            APTS_AgreementTriggerHelper.setPORequired(sowAgreementMap.values(), oldMap);
        }

        
        if(!tsoAgreementMap.isEmpty()){
            APTS_AgreementTriggerHelper.setPORequired(tsoAgreementMap.values(), oldMap);
        }
        
        //APTS_AgreementTriggerHelper.checkApprovalRequired(Trigger.new,false);
        
        if(!ndaAgreementList.isEmpty() && !checkRecursiveFirstCall){
            APTS_AgreementTriggerHelper.setEndDateandActivateNDAAgreement(ndaAgreementList, oldMap);
            checkRecursiveFirstCall = true;
        }
        APTS_TSO_AgreementTriggerHelper.updateServiceEstimateLineItems(newList, oldMap);
        // APTS_TSO_AgreementTriggerHelper.generateTSODocument(newList); CIT-11613
        APTS_AgreementTriggerHelper.updateDocumentGenerationStatus(newList, oldMap);

    }

    public static void onBeforeInsert(List<Apttus__APTS_Agreement__c> newList){
        system.debug('***AgreementHandler : Calling onBeforeInsert Agreement');
        List<Apttus__APTS_Agreement__c> psodAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> sowAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> orderAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> msaAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> tsoAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> ndaAgreementList = new List<Apttus__APTS_Agreement__c>();
    
        Map<Id,string> proposalMap = new Map<Id,string>();
        Map<Id,Id> proposalAgreementMap = new map<Id,Id>();
        
        for(Apttus__APTS_Agreement__c agreement : newList)
        { 
          if(proposalAgreementMap.containsKey(agreement.Id)==false )
          {
              if(agreement.Apttus_QPComply__RelatedProposalId__c !=null )
                  proposalAgreementMap.put(agreement.Id,agreement.Apttus_QPComply__RelatedProposalId__c);
          }
        }
        for(Apttus_Proposal__Proposal__c proposal:[select id,APTS_Entity_Code1__c from Apttus_Proposal__Proposal__c where id in :proposalAgreementMap.values()])
        {
           if(proposalMap.containsKey(proposal.Id)==false )
          {
               proposalMap.put(proposal.Id,proposal.APTS_Entity_Code1__c);
          }
        }
        
        for(Apttus__APTS_Agreement__c agreement : newList)
        {        
          // Harmony - Conga QTC - Entity Code Default with related Proposal EntityCode
          if(agreement.Apttus_QPComply__RelatedProposalId__c !=null )
          {
          
          //Apttus_Proposal__Proposal__c proposal = [select id,APTS_Entity_Code1__c from Apttus_Proposal__Proposal__c where id =:agreement.Apttus_QPComply__RelatedProposalId__c]; 
          Id propId = proposalAgreementMap.get(agreement.Id);
          agreement.Conga_Entity_Code__c= proposalMap.get(propId);
          }
         
         //--------------------------------
         
            if(agreement.APTS_Record_Type_Name__c == 'PSOD')
            {
                psodAgreementList.add(agreement);
            }
            
            if(agreement.APTS_Record_Type_Name__c == 'SOW' 
                && agreement.Apttus__Related_Opportunity__c != null
                && agreement.Apttus_Approval__Approval_Status__c != 'Pending Approval' 
                && agreement.Apttus_Approval__Approval_Status__c != 'Approved')
            {
                sowAgreementList.add(agreement);
            }
            if(agreement.APTS_Record_Type_Name__c == 'Order')
            {  
                orderAgreementList.add(agreement);
            }
            if(agreement.APTS_Record_Type_Name__c == 'MSSA')
            {
                msaAgreementList.add(agreement);
            }
            if(agreement.APTS_Record_Type_Name__c == 'TSO')
            {
                tsoAgreementList.add(agreement);
            }
            if(agreement.APTS_Record_Type_Name__c == 'NDA')
            {
                ndaAgreementList.add(agreement);
            }

            //AK PSC-124 START
            //Set status to Request - Request for all agreements.
            if(!Test.isRunningTest() && (agreement.SRC_SYSTEM__c == '' || agreement.SRC_SYSTEM__c == null) && agreement.APTS_record_type_name__c != 'NDA' && agreement.APTS_record_type_name__c != 'DPA'){ 
                agreement.Apttus__Status_Category__c = 'Request';
                if(agreement.Apttus__Status__c != 'In Amendment' && agreement.Apttus__Status__c != 'In Renewal' && agreement.APTS_record_type_name__c != 'NDA' && agreement.APTS_record_type_name__c != 'DPA' )
                {
                    agreement.Apttus__Status__c = 'Request';
                }
            }  
            //AK PSC-124 END
            
            if(!String.isBlank(agreement.APTS_Notes__c)){
                agreement.Non_Standard_Legal_Language_on_Order__c = true;
            }
        }
        //update Agreements with order
        if(!psodAgreementList.isEmpty()){
            APTS_AgreementTriggerHelper.setAgreementCurrency(psodAgreementList);
            system.debug('***AgreementHandler onBeforeInsert Start : updateOrderNumberonAgreement');
            APTS_AgreementTriggerHelper.updateOrderNumberonAgreement(psodAgreementList);
            system.debug('***AgreementHandler onBeforeInsert End : updateOrderNumberonAgreement');
            system.debug('***AgreementHandler onBeforeInsert Start : updateFYandFQ');
            APTS_AgreementTriggerHelper.updateFYandFQ(psodAgreementList);
            system.debug('***AgreementHandler onBeforeInsert End : updateFYandFQ');
        }

        system.debug('GDM: ListOfSOWAgreements: '+sowAgreementList);
        //update SOW agreement fields
        if (!sowAgreementList.isEmpty()) {
            APTS_AgreementTriggerHelper.updateGrossMarginOnAgreement(sowAgreementList);
      system.debug('***AgreementHandler onBeforeInsert Start : populateParentAgreementwithMSA');
            APTS_AgreementTriggerHelper.populateParentAgreementwithMSA(sowAgreementList);
      APTS_AgreementTriggerHelper.populateQueueIdForTaskDefaulting(sowAgreementList); //CIT-7614
            system.debug('***AgreementHandler onBeforeInsert End : populateParentAgreementwithMSA');
        }
        if(orderAgreementList.size() > 0)
        {
            APTS_AgreementTriggerHelper.updateRenewalAgreementFields(orderAgreementList);
            APTS_AgreementTriggerHelper.setCongaSignatory(orderAgreementList);
            APTS_AgreementTriggerHelper.setFieldsOnInsert(orderAgreementList);
            APTS_AgreementTriggerHelper.UpdateTypeOfPaperOnOrderAgreement(orderAgreementList);//CIT-14945
        }
        APTS_AgreementTriggerHelper.cancelOrderAgreements(newList);
        APTS_AgreementTriggerHelper.clearExternalId(newList);
        APTS_AgreementTriggerHelper.defaultMSAFields(msaAgreementList);
        APTS_AgreementTriggerHelper.defaultNDAFields(ndaAgreementList);
        APTS_TSO_AgreementTriggerHelper.updateServiceEstimateOnTSOAgreement(newList);
        //APTS_TSO_AgreementTriggerHelper.updateServiceEstimateLineItems(newList);
        if(tsoAgreementList.size() > 0)
        {
            APTS_AgreementTriggerHelper.updateCurrencyOnTSOAgreementFromServiceEstimate(tsoAgreementList);
        }
    }
   
    public static void onAfterInsert(List<Apttus__APTS_Agreement__c> newList)
    {
        system.debug('***AgreementHandler : Calling onAfterInsert Agreement');
        List<Apttus__APTS_Agreement__c> orderAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> sowAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> dpaAgreementList = new List<Apttus__APTS_Agreement__c>();//AK PSC-124 
        List<Apttus__APTS_Agreement__c> ndaAgreementList = new List<Apttus__APTS_Agreement__c>();
        
        Map<Id,Apttus__APTS_Agreement__c> hasLinesOrderAgreementMap = new Map<Id,Apttus__APTS_Agreement__c>();
        Set<Id> setOfOpportunityIdsOfOrderAgreement = new Set<Id>();

        for(Apttus__APTS_Agreement__c agreement : newList){
            if(agreement.APTS_Record_Type_Name__c == 'Order' || Test.isRunningTest()){  
                setOfOpportunityIdsOfOrderAgreement.add(agreement.Apttus__Related_Opportunity__c);
                orderAgreementList.add(agreement);
                hasLinesOrderAgreementMap.put(agreement.Id,agreement);
            }
            else if(agreement.APTS_Record_Type_Name__c == 'SOW')
            {
                sowAgreementList.add(agreement);
            }
             else if(agreement.APTS_Record_Type_Name__c == 'NDA')
            {
                ndaAgreementList.add(agreement);
            }
            //AK PSC-124 
             else if(agreement.APTS_Record_Type_Name__c == 'DPA')
            {
                dpaAgreementList.add(agreement);
            }
          
        }
        //Link Invoice Schedule with order agreement
        system.debug('***AgreementHandler onAfterInsert Start : updateInvoiceScheduleWithAgreement');
        APTS_AgreementTriggerHelper.updateInvoiceScheduleWithAgreement(orderAgreementList);
        system.debug('***AgreementHandler onAfterInsert End : updateInvoiceScheduleWithAgreement');

        
        APTS_AgreementTriggerHelper.updateRelatedOpportunityOnMSAAgreement_NewLogo(setOfOpportunityIdsOfOrderAgreement,orderAgreementList);        
        
        // Updates the parent MSSA on child order agreement creation
        /*system.debug('***AgreementHandler onAfterInsert Start : updateParentAgreementIdBasedOnAccount');
        APTS_AgreementTriggerHelper.updateParentAgreementIdBasedOnAccount(orderAgreementList); // update agreement
        system.debug('***AgreementHandler onAfterInsert End : updateParentAgreementIdBasedOnAccount');*/

        //creates agreement share records for order agreements for account owner
        system.debug('***AgreementHandler onAfterInsert Start : createAgreementShareforAccountOwners');
        //APTS_AgreementTriggerHelper.createAgreementShareforAccountOwners(newList);
        system.debug('***AgreementHandler onAfterInsert End : createAgreementShareforAccountOwners');
        if(orderAgreementList.size() > 0)
        {
            APTS_AgreementTriggerHelper.setOrderformAgreementId(orderAgreementList);
            //APTS_AgreementTriggerHelper.updateCNRJunctionRecords(orderAgreementList); //CIT-19742
        }
        
        if(sowAgreementList.size() > 0)
        {
            //It will populate the Agreement lookup on Service Estimate records & on Service Estimate Line Item records
            APTS_AgreementTriggerHelper.populateAgreementOnServiceEstimateAndItsLines(sowAgreementList);
        }
        /* Commented as part CIT-13980
        if (!hasLinesOrderAgreementMap.isEmpty()) 
        {        
            A4A_Run_Job_Once_First_Time_All_Accounts__c cusSettings = A4A_Run_Job_Once_First_Time_All_Accounts__c.getInstance('AccountExecution');
            Decimal delaySec = 5;
            if (cusSettings != null && cusSettings.Agmt_UpdateXFieldOnAgreementBasedOnAgrLi__c != null && cusSettings.Agmt_UpdateXFieldOnAgreementBasedOnAgrLi__c > 0)
            {
                delaySec = cusSettings.Agmt_UpdateXFieldOnAgreementBasedOnAgrLi__c;
            }
            
            DateTime newTime = DateTime.now().AddSeconds(Integer.valueOf(delaySec));
            String hour = String.valueOf(newTime.hour());
            String min = String.valueOf(newTime.minute()); 
            String ss = String.valueOf(newTime.second());
            String month = String.valueOf(newTime.month()); 
            String dd = String.valueOf(newTime.day());
            String year = String.valueOf(newTime.year());

            //parse to cron expression
            
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' '+ dd +' '+ month +' ?' + ' ' + year;
            System.debug('Job Cron Expression : '+ nextFireTime);
            system.debug('***AgreementHandler onAfterUpdate Start : updateXFieldOnAgreementBasedOnAgrLineItem');
            APTS_SchedulableAgreementUpdate schedulableAgmtUpdate = new APTS_SchedulableAgreementUpdate(hasLinesOrderAgreementMap.keySet());
            System.schedule('Order Agreement Job Started At ' + String.valueOf(Datetime.now()) + ' ' + String.valueOf(Datetime.now().millisecond()), nextFireTime, schedulableAgmtUpdate);
            system.debug('***AgreementHandler onAfterUpdate End : updateXFieldOnAgreementBasedOnAgrLineItem');
        }
        */ // CIT-13980
         if (!ndaAgreementList.isEmpty()){
            APTS_AgreementTriggerHelper.autoGenerateDocPaperChange(ndaAgreementList,null);
        }
         //AK PSC-124 
         if (!dpaAgreementList.isEmpty()){
            APTS_AgreementTriggerHelper.autoGenerateDocPaperChangeDPA(dpaAgreementList,null);
        }
        
        APTS_AgreementTriggerHelper.generateNDADocument(newList);
        APTS_TSO_AgreementTriggerHelper.updateServiceEstimateLineItems(newList);
    }


    public static void onAfterUpdate(List<Apttus__APTS_Agreement__c> newList, Map<ID, Apttus__APTS_Agreement__c> oldMap, Map<ID, Apttus__APTS_Agreement__c> newMap){
        // Avoid recursion. This flag value is reset for every transaction.
        /*if(checkRecursiveFirstCall == true)
        {
            return;
        }
        checkRecursiveFirstCall = true; // This must come below the above if statement.
*/
        system.debug('***AgreementHandler : Calling afterUpdate Agreement');
        List<Apttus__APTS_Agreement__c> orderAgreementList = new List<Apttus__APTS_Agreement__c>();

        List<Apttus__APTS_Agreement__c> changedAgreementList = new List<Apttus__APTS_Agreement__c>();
        
        Map<Id,Apttus__APTS_Agreement__c> hasLinesOrderAgreementMap = new Map<Id,Apttus__APTS_Agreement__c>();

        List<Apttus__APTS_Agreement__c> warningAgreementList = new List<Apttus__APTS_Agreement__c>();

        List<Apttus__APTS_Agreement__c> psodAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> ndaAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> dpaAgreementList = new List<Apttus__APTS_Agreement__c>();//AK PSC-124 START
        List<Apttus__APTS_Agreement__c> mpaAgreementList = new List<Apttus__APTS_Agreement__c>();//AK PSC-196

        Set<Apttus__APTS_Agreement__c> SetAggUpdate = new Set<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> TmplstAggUpdate = new List<Apttus__APTS_Agreement__c>();

        List<Apttus__APTS_Agreement__c> activatedAgreementList = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> mssaAgreementList= new List<Apttus__APTS_Agreement__c> (); //CIT-860
        for(Apttus__APTS_Agreement__c agreement : newList){
            
            if(agreement.APTS_Record_Type_Name__c == 'Order'){  

                orderAgreementList.add(agreement);
            } else if(agreement.APTS_Record_Type_Name__c == 'PSOD'){

                psodAgreementList.add(agreement);
            } else if(agreement.APTS_Record_Type_Name__c == 'NDA'){

                ndaAgreementList.add(agreement);
            } 
            //AK PSC-124 
            else if(agreement.APTS_Record_Type_Name__c == 'DPA'){

                dpaAgreementList.add(agreement);
            } 
            //AK PSC-196
            else if(agreement.APTS_Record_Type_Name__c == 'MPA' && agreement.Apttus__Status_Category__c == 'In Signatures' && agreement.Apttus__Status__c == 'Ready For Signatures'){
            
                APTS_AgreementTriggerHelper.CopyFileToAgreement(agreement.ID);
            }
            if( oldMap == null || oldMap.get(agreement.ID).Apttus__Account__c != newMap.get(agreement.ID).Apttus__Account__c){
                changedAgreementList.add(agreement);
            }
            
            //System.Debug('***AgreementHandler -----'+oldMap.get(agreement.Id).APTS_Line_Count__c+'------'+newMap.get(agreement.Id).APTS_Line_Count__c);
            
            // Added for Product Sold Field updated based on Agreement Line
            // if(agreement.APTS_Record_Type_Name__c == 'Order' && (oldMap == null || oldMap.get(agreement.Id).APTS_Line_Count__c != newMap.get(agreement.Id).APTS_Line_Count__c)){
            //     hasLinesOrderAgreementMap.put(agreement.Id,agreement);                
            // }

            // CK: Added to show Warning Message to user - 
           if(oldMap == null ||  oldMap.get(agreement.ID).Apttus__Parent_Agreement__c != newMap.get(agreement.ID).Apttus__Parent_Agreement__c||oldMap.get(agreement.ID).Order_Type__c != newMap.get(agreement.ID).Order_Type__c || oldMap.get(agreement.ID).MSSA_Exception__c != newMap.get(agreement.ID).MSSA_Exception__c ){
                warningAgreementList.add(agreement);
           }

            if(agreement.APTS_Record_Type_Name__c == 'Order' && agreement.Apttus__Status_Category__c == 'In Effect' && agreement.Apttus__Status__c == 'Activated')
            {
                activatedAgreementList.add(agreement);
            }
            if (agreement.APTS_Record_Type_Name__c == 'MSSA'){  //CIT-860
                mssaAgreementList.add(agreement);
            }
        }
        if(!psodAgreementList.isEmpty()){
            system.debug('***AgreementHandler onAfterUpdate Start : createOpportunityForPSODAgreement');
            APTS_AgreementTriggerHelper.createOpportunityForPSODAgreement(psodAgreementList, oldMap);
            system.debug('***AgreementHandler onAfterUpdate End : createOpportunityForPSODAgreement');
        }
        if (!changedAgreementList.isEmpty()){
            //System.enqueueJob(new APTS_CreateAgrShareQueueable(changedAgreementList, 'Agreement', 'onUpdate', listhereofold));
            system.debug('***AgreementHandler onAfterUpdate Start : createOpportunityForPSODAgreement');
            APTS_AgreementTriggerHelper.deleteAccountOwnerShareRecords  (changedAgreementList);
            system.debug('***AgreementHandler onAfterUpdate End : createOpportunityForPSODAgreement');
            //APTS_AgreementTriggerHelper.createAgreementShareforAccountOwners(changedAgreementList);
        }
        
        if (!ndaAgreementList.isEmpty()){
            APTS_AgreementTriggerHelper.autoGenerateDocPaperChange(ndaAgreementList, oldMap);
        }
        //AK PSC-124 
         if (!dpaAgreementList.isEmpty()){
            APTS_AgreementTriggerHelper.autoGenerateDocPaperChangeDPA(dpaAgreementList, oldMap);
        }
        
        if(!orderAgreementList.isEmpty()){
            // CK: Added to updated Order Signature Data on Opportunity when order Agreement is Fully Signed
            APTS_AgreementTriggerHelper.updateOptyOrderSignatureDate(orderAgreementList);
        }

        //CK: Update ISR Opty based on Agreement realted opportunity 
        system.debug('***AgreementHandler onAfterUpdate Start : updateISRBasedOnRelatedOpportunity');
        APTS_AgreementTriggerHelper.updateISRBasedOnRelatedOpportunity(newMap,oldMap);
        system.debug('***AgreementHandler onAfterUpdate End : updateISRBasedOnRelatedOpportunity');
        
        //CK: Added to show Warning Message to user
        if (!warningAgreementList.isEmpty()){        
            system.debug('***AgreementHandler onAfterUpdate Start : showWarning');
            TmplstAggUpdate =  APTS_AgreementTriggerHelper.showWarning(warningAgreementList); // update agreement
            system.debug('***AgreementHandler onAfterUpdate End : showWarning');
            SetAggUpdate.addAll(TmplstAggUpdate);
        }
        
        if (!activatedAgreementList.isEmpty())
        {
            system.debug('***AgreementHandler onAfterUpdate Start : cancelOrderAgreementsOtherThanEffectiveAgreement');
            TmplstAggUpdate = APTS_AgreementTriggerHelper.cancelOrderAgreementsOtherThanEffectiveAgreement(activatedAgreementList);
            system.debug('***AgreementHandler onAfterUpdate End : cancelOrderAgreementsOtherThanEffectiveAgreement');
            if(executionRunOnceAfterUpdate) 
            {
                system.debug('***AgreementHandler onAfterUpdate Start : copyFilesFromOrderAgreementToOppty');
                APTS_AgreementTriggerHelper.copyFilesFromOrderAgreementToOppty(activatedAgreementList);
                system.debug('***AgreementHandler onAfterUpdate End : copyFilesFromOrderAgreementToOppty');
                executionRunOnceAfterUpdate = false;
            }
            SetAggUpdate.addAll(TmplstAggUpdate);
        }
        //CIT-860
        if (mssaAgreementList.size() > 0){
            system.debug('***AgreementHandler onAfterUpdate Start : updateOpportunityOnPrimaryProposal');
            APTS_AgreementTriggerHelper.updateOpportunityOnPrimaryProposal(newMap,oldMap);
            system.debug('***AgreementHandler onAfterUpdate End : updateOpportunityOnPrimaryProposal');        
        }
        //Converted into future methods
        // Added for Product Sold Field updated based on Agreement Line
        // if (!hasLinesOrderAgreementMap.isEmpty()) 
        // {        
        //     system.debug('***AgreementHandler onAfterUpdate Start : updateXFieldOnAgreementBasedOnAgrLineItem');
        //     APTS_AgreementTriggerHelper.updateXFieldOnAgreementBasedOnAgrLineItem(hasLinesOrderAgreementMap.keySet()); // update agreement
        //     system.debug('***AgreementHandler onAfterUpdate End : updateXFieldOnAgreementBasedOnAgrLineItem');
        // }
        
        system.debug('***AgreementHandler onAfterUpdate Start : Actual Update');
        if (SetAggUpdate != null && SetAggUpdate.size() > 0 ) {
            
            List<Apttus__APTS_Agreement__c> lstAggUpdate = new List<Apttus__APTS_Agreement__c>();
            lstAggUpdate.addAll(SetAggUpdate);
            system.debug('***AgreementHandler Update Agmt : ' + json.serialize(lstAggUpdate));
            system.debug('***AgreementHandler agreement count : ' + SetAggUpdate.size());
            update lstAggUpdate;
        }
        system.debug('***AgreementHandler onAfterUpdate End : Actual Update');
        if(APTS_AgreementTriggerHandler.executeTrigger)
        {
        APTS_AgreementTriggerHelper.checkApprovalRequired(Trigger.new,false);
        }
        APTS_AgreementTriggerHelper.generateDocument(newList, oldMap);
       // APTS_TSO_AgreementTriggerHelper.generateTSODocument(newList, oldMap); CIT-11613
    }

    
    
    public static void onBeforeDelete(List<Apttus__APTS_Agreement__c> oldList){
        Boolean isMSSA = false;
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
        for (Apttus__APTS_Agreement__c agmt : oldList) {
           // string recordTypeName = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(agmt.recordtypeid).getname();
           string recordTypeName = agmt.APTS_Record_Type_Name__c; 
            system.debug('Record Type : '+ recordTypeName);
            if (recordTypeName == APTS_Constant.MSSA_RECORDTYPE) {   
                isMSSA = true;
                System.debug('MSSA true');
                agreement = agmt;
                break;
            }
        }
        if (isMSSA == true) {
            System.debug('Start validating delete operation');
            APTS_AgreementTriggerHelper.IsDeletePermissionAvailable(agreement);
        }
    }

    public static void onAfterInsertUpdate(List<Apttus__APTS_Agreement__c> newList, Map<ID, Apttus__APTS_Agreement__c> newMap, Map<ID, Apttus__APTS_Agreement__c> oldMap){
//APTS_AgreementTriggerHelper.syncOpportunityFields(newList);
    //   List<Apttus__APTS_Agreement__c> sowAgreementList = new List<Apttus__APTS_Agreement__c>();
        
    //   for(Apttus__APTS_Agreement__c agreement : newList){

    //     if(agreement.APTS_Record_Type_Name__c == 'SOW'){

    //         if(oldMap == null || oldMap.get(agreement.ID).Apttus__Related_Opportunity__c != newMap.get(agreement.ID).Apttus__Related_Opportunity__c){
    //             sowAgreementList.add(agreement);
    //         }
    //     }
    //   }
    //   //if(!Test.isRunningTest()){
    //     if(!sowAgreementList.isEmpty()){
    //         if (Trigger.isUpdate) 
    //         {
    //             if (isAfterUpdateFlag == false)
    //             {
    //                     isAfterUpdateFlag = true;
    //                     APTS_AgreementTriggerHelper.updateGrossMarginOnAgreement(sowAgreementList); // update agreement      
    //                     isAfterUpdateFlag = false;
    //             }
    //         }
    //         else {
    //             APTS_AgreementTriggerHelper.updateGrossMarginOnAgreement(sowAgreementList); // update agreement
    //         }
    //     }
      //}        
    }
}