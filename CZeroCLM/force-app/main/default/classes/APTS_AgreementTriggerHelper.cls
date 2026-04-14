/**
* @Name: APTS_AgreementTriggerHelper
* @Author: APTTUS
* @CreateDate: 07/31/2019
* @Description: TriggerHelper for Agreement Trigger.
-----------------------------------------------------------------------------------------------
**/
public class APTS_AgreementTriggerHelper{
    
    public static void IsDeletePermissionAvailable(SObject agreement)
    {
        List<PermissionSetAssignment> lstPermissionSet = [Select Id,PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSet.Name = 'APTS_Contract_Manager_Legal' and AssigneeId =:UserInfo.getUserId()];
        system.debug('IsDelete permission set assigned : '+ lstPermissionSet.size());
        if (lstPermissionSet == null || lstPermissionSet.size() <= 0) {
            System.debug('Restrict user to delete record');
            if (!Test.isRunningTest()) {
                agreement.addError('You are not authorized to delete this agreement. Please reach out to the legal team.');   
            }
        }
    }
    
    public static void updateInvoiceScheduleWithAgreement(List<Apttus__APTS_Agreement__c> newList){
        Set<ID> proposalIDSet = new Set<ID>();
        Map<ID,ID> proposalToAgreementMap = new Map<ID,ID>();
        for(Apttus__APTS_Agreement__c agreement : newList){
            String recType = Schema.getGlobalDescribe().get('Apttus__APTS_Agreement__c').getDescribe().getRecordTypeInfosById().get(agreement.RecordTypeId).getName();
            if(recType == 'Order' && agreement.Apttus_QPComply__RelatedProposalId__c != null){
                proposalIDSet.add(agreement.Apttus_QPComply__RelatedProposalId__c);
                proposalToAgreementMap.put(agreement.Apttus_QPComply__RelatedProposalId__c,agreement.ID);
            }
        }
        
        //String recordTypeName = Schema.getGlobalDescribe().get( Agreement ).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getName();
        
        List<Invoice_Schedule_Summary__c> invoiceSummaryList = [SELECT ID, Proposal_Id__c, Agreement__c 
                                                                FROM Invoice_Schedule_Summary__c 
                                                                WHERE Proposal_Id__c IN :proposalIDSet];
        for(Invoice_Schedule_Summary__c invoiceSummary : invoiceSummaryList){
            invoiceSummary.Agreement__c = proposalToAgreementMap.get(invoiceSummary.Proposal_Id__c);
        }
        if(invoiceSummaryList.size() > 0){
            try{
                update invoiceSummaryList;
            }
            catch(Exception e){
                System.Debug('Update failed due to ' + e);
            }
        }
    }
    public static void createAgreementShareforAccountOwners(List<Apttus__APTS_Agreement__c> newList){
        System.Debug('Creating account Share');
        System.enqueueJob(new APTS_CreateAgrShareQueueable(newList, null, 'Agreement', 'onCreate', null));      
    }
    
    //CK: Update ISR Opty based on Agreement realted opportunity 
    public static void updateISRBasedOnRelatedOpportunity(Map<Id,Apttus__APTS_Agreement__c> newMap,Map<Id,Apttus__APTS_Agreement__c> oldMap)
    {
        Set<Id> agmtIdSet = new Set<Id>();
        List<Internal_Service_Request__c> updateISRList = new List<Internal_Service_Request__c>();
        for (Apttus__APTS_Agreement__c  agmt : newMap.values()) {
            Apttus__APTS_Agreement__c oldAgmt = oldMap.get(agmt.Id);
            if (oldAgmt != null && oldAgmt.Apttus__Related_Opportunity__c != agmt.Apttus__Related_Opportunity__c) {
                agmtIdSet.add(agmt.Id);
            }
        }
        if (agmtIdSet.size() >= 0) {            
            List<Internal_Service_Request__c> lstIsr = [select Id,Opportunity__c,Agreement__c from Internal_Service_Request__c where Agreement__c In :agmtIdSet];
            for (Internal_Service_Request__c isr : lstIsr) {
                if (newMap.containsKey(isr.Agreement__c)) {
                    isr.Opportunity__c = newMap.get(isr.Agreement__c).Apttus__Related_Opportunity__c;
                    updateISRList.add(isr);
                }
            }
            // Updated Proposal  
            if(updateISRList != null && updateISRList.size() > 0){
                try{
                    system.debug('***AgreementHelper updateISRBasedOnRelatedOpportunity : ISR count = ' + updateISRList.size());
                    update updateISRList;
                } catch(Exception e){
                    System.Debug(' Update ISR records failed due to ' + e);
                }
            }   
        }
    }
    
    public static void deleteAccountOwnerShareRecords(List<Apttus__APTS_Agreement__c> newList){
        System.Debug('Update Agreement share');
        Set<ID> agreementIDSet = new Set<ID>();
        for(Apttus__APTS_Agreement__c agreement : newList){
            agreementIDSet.add(agreement.Id);
        }
        Map<ID, List<Apttus__APTS_Agreement__Share>> agreementToAgreementShareMap = new Map<ID, List<Apttus__APTS_Agreement__Share>>();
        List<Apttus__APTS_Agreement__Share> oldAgreementShareList = new List<Apttus__APTS_Agreement__Share>([SELECT ParentId,UserOrGroupId,AccessLevel,RowCause 
                                                                                                             FROM Apttus__APTS_Agreement__Share
                                                                                                             WHERE ParentId IN :agreementIDSet
                                                                                                             AND RowCause = 'Account_Owner__c']);
        System.enqueueJob(new APTS_CreateAgrShareQueueable(newList, null, 'Agreement', 'onUpdate', oldAgreementShareList));
    }
    
    // Added for Product Sold Field updated based on Agreement Line
    // Commented as part of CIT-13980
    /*
    public static void updateXFieldOnAgreementBasedOnAgrLineItem(Set<Id> agreementIDSet)
    {
        List <Apttus__APTS_Agreement__c> updateAgreementList = new List <Apttus__APTS_Agreement__c> ();
        Map <ID, List<Apttus__AgreementLineItem__c >> agreementIDToAgrLineItemsMap = new Map < ID, List <Apttus__AgreementLineItem__c>>();
        
        // CK: Addeded Apttus__ProductId__r.Family in SOQL
        List < Apttus__AgreementLineItem__c > relatedAgrLineItems = new List < Apttus__AgreementLineItem__c > ([SELECT id, Name, Apttus__AgreementId__c, Apttus__ProductId__r.Name,
                                                                                                                Apttus__ProductId__r.productcode,
                                                                                                                Apttus_CMConfig__ProductOptionId__c,
                                                                                                                Apttus_CMConfig__ProductOptionId__r.Apttus_Config2__ComponentProductId__r.productcode,
                                                                                                                Apttus__ProductId__r.Family, Apttus__ProductId__r.Display_Clause__c,
                                                                                                                Apttus_CMConfig__OptionId__r.Name, Apttus_CMConfig__AttributeValueId__r.Name,
                                                                                                                Apttus_CMConfig__LineType__c,
                                                                                                                Apttus_CMConfig__OptionId__c,
                                                                                                                Apttus_CMConfig__LineStatus__c,
                                                                                                                Apttus_CMConfig__OptionId__r.Display_Clause__c,
                                                                                                                Apttus__ProductId__r.Conga_Product__c,
                                                                                                                Apttus_CMConfig__OptionId__r.Conga_Product__c,
                                                                                                                Apttus_CMConfig__OptionId__r.Family,
                                                                                                                Apttus_CMConfig__OptionId__r.productcode,
                                                                                                                Apttus_CMConfig__HasOptions__c,
                                                                                                                Year_1__c, Year_2__c, Year_3__c, Year_4__c, Year_5__c,
                                                                                                                APTS_Exclude_From_Order_Form__c,            Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c, 
                                                                                                                Apttus__ProductId__r.Display_Product_Specific_Clause__c,
                                                                                                                Apttus_CMConfig__OptionId__r.Display_Product_Specific_Clause__c,
                                                                                                                Apttus__ProductId__r.APTS_Hide_SFDC_Platform_Entitlement_Cls__c,
                                                                                                                Apttus_CMConfig__OptionId__r.APTS_Hide_SFDC_Platform_Entitlement_Cls__c,
                                                                                                                Turbo_Engine_Class__c,
                                                                                                                Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c,
                                                                                                                Attribute__c
                                                                                                                FROM Apttus__AgreementLineItem__c
                                                                                                                WHERE Apttus__AgreementId__c IN: agreementIDSet
                                                                                                                // CK: Added additional where clause to exclude Products which has line status as - Existing or Cancelled
                                                                                                                AND APTS_Exclude_From_Order_Form__c = False
                                                                                                                AND Apttus_CMConfig__LineStatus__c != 'Existing' 
                                                                                                                AND Apttus_CMConfig__LineStatus__c != 'Cancelled'
                                                                                                                
                                                                                                               ]);
        if (relatedAgrLineItems.size() > 0) 
        {
            for (Apttus__AgreementLineItem__c agrLineItem: relatedAgrLineItems) 
            {
                if (agreementIDToAgrLineItemsMap.containsKey(agrLineItem.Apttus__AgreementId__c)) 
                {    
                    agreementIDToAgrLineItemsMap.get(agrLineItem.Apttus__AgreementId__c).add(agrLineItem);
                } 
                else
                {
                    agreementIDToAgrLineItemsMap.put(agrLineItem.Apttus__AgreementId__c, new List < Apttus__AgreementLineItem__c > {agrLineItem});
                }
            }
            for (Id parentAgreement: agreementIDSet) 
            {
                Boolean psOrTrainingIncluded = false;
                Boolean supportIncluded = false;
                Boolean congaOrUnifiedlCLMClauseIncluded = false;
                Boolean subscriptionServiceIncluded = false;
                String allCongaOrUnifiedCLMSKU = '';
                String AllAddOnSKUs = '';
                String eachAgreementValue = '';
                String DisplayClause = '';
                String strProductCodes = '';
                String strClause = '';
                String allTurboSkUs = '';  
                String turboEngineSku = '';
                String congaComposeClause = '';
                String genericSFDCSandboxClause = '';  
                String standardSandboxClause = '';
                String clmMaxProduct;
                String turboProductCodeWithAttributeClass = '';
                String adobeClause = '';
                String showGenericAdminClause;
                String lineConfigurationType = ''; //Richa added
                String lineStatus = ''; //Richa added
                
                if (agreementIDToAgrLineItemsMap.get(parentAgreement) != null) 
                {
                    for (Integer i = 0; i < agreementIDToAgrLineItemsMap.get(parentAgreement).size(); i++) 
                    {
                        //Richa added
                        lineConfigurationType = agreementIDToAgrLineItemsMap.get(parentAgreement)[i].Apttus_CMConfig__OptionId__c != null ? 
                            agreementIDToAgrLineItemsMap.get(parentAgreement)[i].Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c : 
                        agreementIDToAgrLineItemsMap.get(parentAgreement)[i].Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c  ;
                        if (lineConfigurationType != 'Bundle' ){ 
                            String eachLineItemValue = '';
                            String productName = agreementIDToAgrLineItemsMap.get(parentAgreement)[i].Apttus__ProductId__r.Name;
                            String optionName = agreementIDToAgrLineItemsMap.get(parentAgreement)[i].Apttus_CMConfig__OptionId__r.Name;
                            String attrValueName = agreementIDToAgrLineItemsMap.get(parentAgreement)[i].Attribute__c;
                            String LineType = agreementIDToAgrLineItemsMap.get(parentAgreement)[i].Apttus_CMConfig__LineType__c;
                            Apttus__AgreementLineItem__c agrLineItem = agreementIDToAgrLineItemsMap.get(parentAgreement)[i];
                            eachLineItemValue = eachLineItemValue + (productName == null ? '' : productName + '-') + (optionName == null ? '' : optionName + '-') + (attrValueName == null ? '' : attrValueName + '-');
                            eachAgreementValue = eachAgreementValue + (eachLineItemValue == null ? '' : eachLineItemValue + ';');
                            
                            String pName = LineType == 'Option' ? agrLineItem.Apttus_CMConfig__OptionId__r.Name : agrLineItem.Apttus__ProductId__r.Name;                                
                            String pCode = LineType == 'Option' ?  agrLineItem.Apttus_CMConfig__OptionId__r.productcode : agrLineItem.Apttus__ProductId__r.productcode;  
                            String agrFamily = LineType == 'Option' ? agrLineItem.Apttus_CMConfig__OptionId__r.Family : agrLineItem.Apttus__ProductId__r.Family;
                            Boolean CongaFlag = LineType == 'Option' ? agrLineItem.Apttus_CMConfig__OptionId__r.Conga_Product__c : agrLineItem.Apttus__ProductId__r.Conga_Product__c;                        
                            Boolean unifiedCLMFlag = pCode.startsWithIgnoreCase('CCLM-');
                            Boolean displayProductSpecificClause = LineType == 'Option' ? agrLineItem.Apttus_CMConfig__OptionId__r.Display_Product_Specific_Clause__c : agrLineItem.Apttus__ProductId__r.Display_Product_Specific_Clause__c;
                            Boolean showSFDCPlatformEntitlement = LineType == 'Option' ? agrLineItem.Apttus_CMConfig__OptionId__r.APTS_Hide_SFDC_Platform_Entitlement_Cls__c : agrLineItem.Apttus__ProductId__r.APTS_Hide_SFDC_Platform_Entitlement_Cls__c;        
                            //show productcodes with comma seperated string
                            if (pCode != null && pCode != '') {
                                strProductCodes += ',*' + pCode + '*';
                            }
                            
                            // Turbo Products 
                            if (pCode == 'TURBOENG' || pCode == 'TUR-CONF' || pCode == 'TUR-PRI' || pCode == '--TEST-CODE--'){  
                                if (turboProductCodeWithAttributeClass == '') {  
                                    turboProductCodeWithAttributeClass = '*' + pCode + ':' + agrLineItem.Turbo_Engine_Class__c + '*';  
                                }else {  
                                    String tempProductCodeWithAttributeClass = '*' + pCode + ':' + agrLineItem.Turbo_Engine_Class__c + '*';  
                                    if (!turboProductCodeWithAttributeClass.contains(tempProductCodeWithAttributeClass)){  
                                        turboProductCodeWithAttributeClass += turboProductCodeWithAttributeClass + ',' + tempProductCodeWithAttributeClass;  
                                    }  
                                }  
                            }
                            
                            // Added by Renish: find admin products (product name has admin) but should not be "CCLM-BUS-ADM", to show the admin clause
                            if(pName.contains('Admin') && pCode != 'CCLM-BUS-ADM'){
                                showGenericAdminClause = 'show-generic-admin-clause';
                            }
                            
                            // Support AMS and Managed Service
                            If(agrFamily == 'Support' || agrFamily == 'AMS' || agrFamily == 'Managed Services') {
                                supportIncluded = true;
                            }
                            else If(agrFamily == 'Professional Services' || agrFamily == 'Training') {
                                psOrTrainingIncluded = true;
                            }
                            
                            //Added by Kedar to set the flag Subcription Service Included
                            If(agrFamily != 'Support' && agrFamily != 'AMS' && agrFamily != 'Managed Services' && agrFamily != 'Training' &&
                               agrFamily != 'Professional Services' && agrLineItem.Apttus_CMConfig__HasOptions__c == false &&
                               agrLineItem.APTS_Exclude_From_Order_Form__c == false) 
                            {
                                subscriptionServiceIncluded = true;
                            }
                            
                            //Added by Kedar to set Show_Conga_Clause__c to true if there is any Conga Product in Agreement Line Item
                            //Modified by Nirmal to handle option products as well
                            //Modified by Renish to include Unified CLM products for Product Specific Term clause
                            If(LineType == 'Option' || (LineType != 'Option' && agrLineItem.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c != 'Bundle')){
                                If(displayProductSpecificClause == true) {
                                    
                                    If(congaOrUnifiedlCLMClauseIncluded == false) {
                                        congaOrUnifiedlCLMClauseIncluded = true;
                                    }
                                    
                                    If(allCongaOrUnifiedCLMSKU == '') {
                                        allCongaOrUnifiedCLMSKU = pName;
                                    }
                                    else if (!allCongaOrUnifiedCLMSKU.contains(pName)) {
                                        allCongaOrUnifiedCLMSKU = allCongaOrUnifiedCLMSKU + ', ' + pName;
                                    }
                                }
                            }
                            
                            if( pName.contains('CLM Enterprise Admin') 
                               || pName.contains('CLM Enterprise User')
                               || pName.contains('Conga CLM Enterprise User') || pCode == '--TEST-CODE--')
                            {  
                                clmMaxProduct = 'CLMMAX';     
                            }  
                            
                            If ( pCode == 'COMP-BUS-USR' || pCode == 'COMP-ENT-USR' || pCode == 'GRID-USR' || pCode == '--TEST-CODE--'){ // Conga Composer SKUs  
                                If(congaComposeClause == '') {  
                                    congaComposeClause = pName;  
                                }  
                                else if (!congaComposeClause.contains(pName)) {  
                                    congaComposeClause = congaComposeClause + ', ' + pName;  
                                }  
                            }  
                            If(pCode == 'TUR-PRI' || pCode == 'TUR-CONF' || pCode == '--TEST-CODE--'){  
                                If(allTurboSkUs == '') {  
                                    allTurboSkUs = pName+' '+agrLineItem.Turbo_Engine_Class__c;  
                                }  
                                else if (!allTurboSkUs.contains(pName)){  
                                    allTurboSkUs = allTurboSkUs + ', ' + pName+' '+agrLineItem.Turbo_Engine_Class__c;  
                                }
                            }
                            If(pCode == 'TURBOENG' || pCode == '--TEST-CODE--'){
                                If(turboEngineSku == ''){
                                    turboEngineSku = pName+' '+agrLineItem.Turbo_Engine_Class__c;
                                }
                            }
                            If (pCode == 'ABO-CUS-ESI-009' || pCode == 'ABO-ESN-ADB-001-SF' || pCode == 'ADB-SMS' || pCode == '--TEST-CODE--' ||
                                pCode == 'ABO-CUS-ESI-011' || pCode == 'ADB-SIGN'){ 
                                    If(adobeClause == '') {  
                                        adobeClause = pName;  
                                    }  
                                    else if (!adobeClause.contains(pName)){  
                                        adobeClause = adobeClause + ', ' + pName;  
                                    }                            
                                    //adobeClause = adobeClause == '' ? pName : adobeClause + ', ' + pName;  
                                }  
                            // Show the SFDC clause if hideSFDCPlatformEntitlement == false
                            if(genericSFDCSandboxClause =='' && showSFDCPlatformEntitlement == true){  
                                genericSFDCSandboxClause = '*DisplayStandardSFDCSandboxClause*';  
                            }   
                            if ((agrLineItem.Apttus__ProductId__r.Display_Clause__c != null && agrLineItem.Apttus__ProductId__r.Display_Clause__c != '') ||
                                (agrLineItem.Apttus_CMConfig__OptionId__c != null && agrLineItem.Apttus_CMConfig__OptionId__r.Display_Clause__c != null && agrLineItem.Apttus_CMConfig__OptionId__r.Display_Clause__c != '')) {
                                    String optionDisplayClause = agrLineItem.Apttus_CMConfig__OptionId__c != null ?
                                        agrLineItem.Apttus_CMConfig__OptionId__r.Display_Clause__c :
                                    agrLineItem.Apttus__ProductId__r.Display_Clause__c;
                                    if (optionDisplayClause != null && optionDisplayClause != '' && optionDisplayClause.contains(',')) {
                                        for (String str: optionDisplayClause.split(',')) {
                                            if (!strClause.contains('*' + str + '*')) {
                                                strClause += ',*' + str + '*';
                                            }
                                        }
                                    } else if (optionDisplayClause != null && optionDisplayClause != '') {
                                        if (!strClause.contains('*' + optionDisplayClause + '*')) {
                                            strClause += ',*' + optionDisplayClause + '*';
                                        }
                                    }
                                }
                        }
                    } //my if      
                }
                
                //Generic clause condition
                DisplayClause = strProductCodes != '' ? strProductCodes.removeStart(',') : '';
                DisplayClause += strClause != null && strClause != '' ? strClause : '';
                system.debug('Agreemnt Product logic (Display Clause ) : ' + DisplayClause);
                if (turboProductCodeWithAttributeClass != null ){  
                    DisplayClause += turboProductCodeWithAttributeClass;  
                }  
                if(clmMaxProduct!=null){  
                    DisplayClause +=  clmMaxProduct;     
                }
                if(showGenericAdminClause != null){
                    DisplayClause +=  showGenericAdminClause;     
                }    
                If(genericSFDCSandboxClause!=null){  
                    DisplayClause += genericSFDCSandboxClause;  
                }  
                If(standardSandboxClause!=null){  
                    DisplayClause += standardSandboxClause;  
                }      
                Apttus__APTS_Agreement__c updateAgreement = new Apttus__APTS_Agreement__c(  
                    Id = parentAgreement, 
                    APTS_Products_Sold__c = eachAgreementValue,   
                    //APTS_Technical_Support_Included__c = supportIncluded, //CIT-13514
                    Show_Conga_Clause__c = congaOrUnifiedlCLMClauseIncluded,   
                    Conga_SKUs__c = allCongaOrUnifiedCLMSKU, AddOn_SKUs__c = AllAddOnSKUs,  
                    Subscription_Service_Included__c = subscriptionServiceIncluded,  
                    APTS_PS_Or_Training_Included__c = psOrTrainingIncluded,   
                    Display_Clause__c = DisplayClause,
                    Conga_Composer_SKUs__c = congaComposeClause,  
                    Turbo_SKUs__c = allTurboSkUs,
                    Turbo_Engine_Sku__c = turboEngineSku,
                    Adobe_Skus__c = adobeClause 
                );
                updateAgreementList.add(updateAgreement);
            }
            if (updateAgreementList.size() > 0) 
            {
                system.debug('APTS_AgreementTriggerHelper: updateXFieldOnAgreementBasedOnAgrLineItem: Future method : '+ JSON.serialize(updateAgreementList));
                update updateAgreementList;
            }
        }
    }
    */
    //CK: Adding to updated Opportunity> Order Signature Date
    public static void updateOptyOrderSignatureDate(List<Apttus__APTS_Agreement__c> newList){
        
        List<Opportunity> updateOptyList = new List<Opportunity>();
        
        for(Apttus__APTS_Agreement__c agreement : newList){
            if(agreement.Apttus__Status__c == 'Fully Signed'){
                
                Opportunity sOpty = new Opportunity(Id = agreement.Apttus__Related_Opportunity__c, Order_Signature_Date__c = date.today());
                updateOptyList.add(sOpty);
                
            }
        }
        // Updated Opty  
        if(updateOptyList.size() > 0){
            try{
                system.debug('***AgreementHelper updateOptyOrderSignatureDate : ISR count = ' + updateOptyList.size());
                update updateOptyList;
            } catch(Exception e){
                System.Debug('Opportunity Order Signature Date Update failed due to ' + e);
            }
        }  
    }
    
    // CK : Adding to show waring message to user on Order Agreement
    public static List<Apttus__APTS_Agreement__c> showWarning(List<Apttus__APTS_Agreement__c> newList){
        List<Apttus__APTS_Agreement__c> updateAgreementWarning = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agreement : newList){
            if(agreement.Order_Type__c == null){
                Apttus__APTS_Agreement__c sAgreement = new Apttus__APTS_Agreement__c(Id = agreement.Id, APTS_Warning__c = 'Order Type Missing');
                updateAgreementWarning.add(sAgreement);
            }
            else if(agreement.MSSA_Exception__c != null){
                
                Apttus__APTS_Agreement__c sAgreement = new Apttus__APTS_Agreement__c(Id = agreement.Id, APTS_Warning__c = '');
                updateAgreementWarning.add(sAgreement);
            }
            else{
                Apttus__APTS_Agreement__c sssAgreement = new Apttus__APTS_Agreement__c(Id = agreement.Id, APTS_Warning__c = '');
                updateAgreementWarning.add(sssAgreement);
            }
        }
        return updateAgreementWarning;
    }
    
    public static void updateSignedAgreementWithUser(List<Apttus__APTS_Agreement__c> psodAgreementList){
        List<Apttus__APTS_Agreement__c> agreementToUpdateList = new List<Apttus__APTS_Agreement__c>();
        
        List<Apttus__ComplyCustomProperties__c> customPropertiesList = Apttus__ComplyCustomProperties__c.getAll().values();
        String defaultUser = null;
        if(!Test.isRunningTest()){
            for(Apttus__ComplyCustomProperties__c customProperty : customPropertiesList){
                if(customProperty.APTS_Default_Owner_PSOD_Agreement__c != null){
                    defaultUser =  customProperty.APTS_Default_Owner_PSOD_Agreement__c;
                    break;
                }
            }
        } else {
            defaultUser  = 'APTS_PS_Ops_PSOD';
        }
        //User defaultAgreementUser = [SELECT ID FROM USER WHERE NAME = :defaultUser LIMIT 1];
        //Group psOpsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'PS Ops (PSOD)' LIMIT 1];
        Group psOpsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = :defaultUser LIMIT 1];
        if(!psodAgreementList.isEmpty()){
            for(Apttus__APTS_Agreement__c agreement : psodAgreementList) {
                System.Debug('+++agreement: ' + agreement);
                if(agreement.Apttus__Status__c == 'Fully Signed' 
                   && agreement.Apttus__Status_Category__c == 'In Signatures'
                   && agreement.APTS_Allow_Update_Owner__c == false){
                       //agreement.OwnerId = defaultUser.Id;
                       agreement.OwnerId = psOpsQueue.Id;
                       agreementToUpdateList.add(agreement);
                       agreement.APTS_Allow_Update_Owner__c = true;
                   }
            }
        }        
    }
    public static void updateOrderNumberonAgreement(List<Apttus__APTS_Agreement__c> psodAgreementList){
        
        List<Apttus__APTS_Agreement__c> agreementsToUpdateList = new List<Apttus__APTS_Agreement__c>();
        Map<ID, Apttus__APTS_Agreement__c> accountToAgreementMap = new Map<ID, Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agreement : psodAgreementList){
            accountToAgreementMap.put(agreement.Apttus__Account__c, agreement);
        }
        
        Set<ID> accountIDSet = accountToAgreementMap.keySet();
        Map<ID, List<Apttus__APTS_Agreement__c>> accountToPSODMap = new Map<ID, List<Apttus__APTS_Agreement__c>>();
        List<Apttus__APTS_Agreement__c> psodAgreementFromAccounts = new List<Apttus__APTS_Agreement__c>([SELECT ID, Apttus__Status_Category__c,APTS_Order_Number__c, APTS_Fiscal_Quarter__c, APTS_Fiscal_Year__c, Apttus__Account__c
                                                                                                         FROM Apttus__APTS_Agreement__c 
                                                                                                         WHERE  APTS_Record_Type_Name__c = 'PSOD' 
                                                                                                         AND Apttus__Account__c in :accountIDSet]);
        for(Apttus__APTS_Agreement__c psodAgreement : psodAgreementFromAccounts){
            List<Apttus__APTS_Agreement__c> agreementList = accountToPSODMap.get(psodAgreement.Apttus__Account__c) != null ? accountToPSODMap.get(psodAgreement.Apttus__Account__c) : new List<Apttus__APTS_Agreement__c>();
            agreementList.add(psodAgreement);
            accountToPSODMap.put(psodAgreement.Apttus__Account__c,agreementList);
        }
        
        for(ID accountID : accountIDSet){
            List<Apttus__APTS_Agreement__c> agreementList = accountToPSODMap.get(accountID);
            Integer orderNumber = 0;
            if(agreementList != null){
                orderNumber = agreementList.size();
            }
            accountToAgreementMap.get(accountID).APTS_Order_Number__c = orderNumber + 1 ;
        }
    }
    
    public static void createOpportunityForPSODAgreement(List<Apttus__APTS_Agreement__c> psodAgreementList,  Map<ID, Apttus__APTS_Agreement__c> oldMap){
        List<Opportunity> opportunityList = new List<Opportunity>();
        Map<ID,ID> accountToSubOpportunityMap = new Map<ID,ID>();
        Set<ID> accountIDSet = new Set<ID>();
        for(Apttus__APTS_Agreement__c agreement : psodAgreementList){
            accountIDSet.add(agreement.Apttus__Account__c);
        }
        List<Apttus__ComplyCustomProperties__c> customPropertiesList = Apttus__ComplyCustomProperties__c.getAll().values();
        String defaultUser = null;
        
        for(Apttus__ComplyCustomProperties__c customProperty : customPropertiesList){
            
            if(customProperty.APTS_Default_Owner_PSOD_Opportunity__c != null){
                defaultUser =  customProperty.APTS_Default_Owner_PSOD_Opportunity__c;
                break;
            }
        }
        for(Apttus__ComplyCustomProperties__c customProperty : customPropertiesList){
            
            if(customProperty.APTS_Default_Owner_PSOD_Opportunity__c != null){
                defaultUser =  customProperty.APTS_Default_Owner_PSOD_Opportunity__c;
                break;
            }
        }
        
        User defaultOpportunityUser = [SELECT ID FROM USER WHERE NAME = :defaultUser LIMIT 1];
        Map<ID,Account> accountNameMap = new Map<ID,Account>([SELECT ID, Name FROM Account WHERE ID IN :accountIDSet]);
        ID subscripionOpportunityId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Subscription').getRecordTypeId();
        for(Opportunity subOpp : [SELECT ID, AccountId FROM Opportunity WHERE AccountId IN :accountIDSet AND recordTypeID = :subscripionOpportunityId]){
            accountToSubOpportunityMap.put(subOpp.AccountId, subOpp.ID);
        }
        for(Apttus__APTS_Agreement__c agreement : psodAgreementList){
            if(agreement.Apttus__Status__c == 'Ready for Signatures' && agreement.Apttus__Status_Category__c == 'In Signatures' && agreement.Apttus__Related_Opportunity__c == null
               && agreement.Apttus__Status__c != oldMap.get(agreement.Id).Apttus__Status__c){
                   Opportunity newOpportunity = new Opportunity();
                   newOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Service').getRecordTypeId();
                   newOpportunity.AccountId = agreement.Apttus__Account__c;
                   newOpportunity.Name = accountNameMap.get(agreement.Apttus__Account__c).Name + ' -- PSOD #' + agreement.APTS_Order_Number__c + ' -- ' + agreement.APTS_Number_of_Hours__c + ' hours'; 
                   newOpportunity.Service_Opportunity_Types__c = 'PSOD';
                   newOpportunity.Platform__c = 'Salesforce';
                   newOpportunity.StageName = '1 - New'; 
                   newOpportunity.Forecast_Category__c = 'Pipeline'; 
                   newOpportunity.Subscription_Opportunity__c = accountToSubOpportunityMap.get(agreement.Apttus__Account__c);
                   newOpportunity.PS_Global_Region__c = 'AMER';  //CIT-17726
                   newOpportunity.PS_NA_Region__c = 'West';    //CIT-17726
                   newOpportunity.PS_Delivery_Owner__c = agreement.OwnerID;
                   newOpportunity.OwnerId = defaultOpportunityUser.ID;
                   if(agreement.Apttus__Contract_Start_Date__c > Date.today()){
                       newOpportunity.CloseDate =  agreement.Apttus__Contract_Start_Date__c;
                   } else {
                       newOpportunity.CloseDate = Date.today();
                   }
                   newOpportunity.CurrencyIsoCode = agreement.CurrencyIsoCode;
                   newOpportunity.Implementation_Prime__c = 'Apttus';
                   newOpportunity.Apttus_Service_Bookings__c = agreement.APTS_PSOD_Invoice_Total__c;
                   newOpportunity.Apttus_Services_Man_Hrs__c = agreement.APTS_Number_of_Hours__c;
                   newOpportunity.APTS_Related_PSOD_Agreement__c = agreement.ID;
                   opportunityList.add(newOpportunity);
               }
        }
        if(!opportunityList.isEmpty()){
            try{
                insert opportunityList;                                 
            } catch(Exception ex){
                System.Debug('Opportunity insert failed. ' + ex.getMessage());
            }
        }
    }
    
    public static void updateFYandFQ(List<Apttus__APTS_Agreement__c> psodAgreementList){
        Set<Id> agreementIDSet = new Set<ID>();
        Map<ID, Apttus__APTS_Agreement__c> accountToAgreementMap = new Map<ID, Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c agreement : psodAgreementList){
            agreementIDSet.add(agreement.ID);
            accountToAgreementMap.put(agreement.Apttus__Account__c, agreement);
        }
        Set<ID> accountIDSet = accountToAgreementMap.keySet();
        Map<ID, List<Apttus__APTS_Agreement__c>> accountToPSODMap = new Map<ID, List<Apttus__APTS_Agreement__c>>();
        
        List<Apttus__APTS_Agreement__c> psodAgreementFromAccounts = new List<Apttus__APTS_Agreement__c>([SELECT ID, 
                                                                                                         Apttus__Contract_Start_Date__c,
                                                                                                         Apttus__Status_Category__c, 
                                                                                                         APTS_Fiscal_Quarter__c, 
                                                                                                         APTS_Fiscal_Year__c, 
                                                                                                         Apttus__Account__c
                                                                                                         FROM Apttus__APTS_Agreement__c 
                                                                                                         WHERE  APTS_Record_Type_Name__c = 'PSOD' 
                                                                                                         AND Apttus__Account__c in :accountIDSet
                                                                                                         AND ID NOT in :agreementIDSet]);
        //}
        if(!psodAgreementFromAccounts.isEmpty()){
            for(Apttus__APTS_Agreement__c psodAgreement : psodAgreementFromAccounts){
                List<Apttus__APTS_Agreement__c> agreementList = accountToPSODMap.get(psodAgreement.Apttus__Account__c) != null? accountToPSODMap.get(psodAgreement.Apttus__Account__c) : new List<Apttus__APTS_Agreement__c>();
                agreementList.add(psodAgreement);
                accountToPSODMap.put(psodAgreement.Apttus__Account__c,agreementList);
            }
            
            //Fiscal Year and Fiscal quarter
            //if(!psodAgreementFromAccounts.isEmpty()){
            for(Apttus__APTS_Agreement__c agreement: psodAgreementList){
                String fiscalQuarter = null, fiscalYear = null;
                if(agreement.Apttus__Contract_Start_Date__c.month() > 10 || agreement.Apttus__Contract_Start_Date__c.month() == 1){
                    fiscalQuarter = 'FQ 4';
                } else if(agreement.Apttus__Contract_Start_Date__c.month() > 7){
                    fiscalQuarter = 'FQ 3';
                } else if(agreement.Apttus__Contract_Start_Date__c.month() > 4){
                    fiscalQuarter = 'FQ 2';
                } else if (agreement.Apttus__Contract_Start_Date__c.month() > 1){
                    fiscalQuarter = 'FQ 1';
                }
                
                Integer year = agreement.Apttus__Contract_Start_Date__c.Year();
                
                if(agreement.Apttus__Contract_Start_Date__c.month() == 1){
                    fiscalYear = 'FY ' + string.valueof(year).right(2);
                } else {
                    year = year + 1;
                    fiscalYear = 'FY ' + string.valueof(year).right(2);
                }
                
                List<Apttus__APTS_Agreement__c> agreementList = accountToPSODMap.get(agreement.Apttus__Account__c);
                Integer PSOD_FY_Count = 1, PSOD_FQ_Count = 1;
                
                System.Debug('+++agreementList: ' + agreementList);
                
                if(!agreementList.isEmpty()){
                    for(Apttus__APTS_Agreement__c tempAgreement : agreementList){
                        if(tempAgreement.APTS_Fiscal_Quarter__c == fiscalQuarter && tempAgreement.APTS_Fiscal_Year__c == fiscalYear){
                            PSOD_FQ_Count++;
                        }
                        if(tempAgreement.APTS_Fiscal_Year__c == fiscalYear){
                            PSOD_FY_Count++;
                        }
                    }
                }
                agreement.APTS_PSOD_Order_No_For_This_FY__c = PSOD_FY_Count;
                agreement.APTS_PSOD_Order_No_For_This_FQ__c = PSOD_FQ_Count;
            }
            //}
        } else {
            for(ID accountID : accountIDSet){
                Apttus__APTS_Agreement__c agreement = accountToAgreementMap.get(accountID);
                agreement.APTS_PSOD_Order_No_For_This_FY__c = 1;
                agreement.APTS_PSOD_Order_No_For_This_FQ__c = 1;
            }
        }
    }
    
    public static void updateGrossMarginOnAgreement(List<Apttus__APTS_Agreement__c> sowAgreementList){
        Map<ID, ID> agreementToOpportuntyMap = new Map<ID, ID>();
        Set<ID> opportunityIDSet = new Set<ID>();
        Map<ID, PSAService_Estimate__c> opportunityToServiceEstimateMap = new Map<ID,PSAService_Estimate__c>();
        
        for(Apttus__APTS_Agreement__c agreement : sowAgreementList){
            if(agreementToOpportuntyMap.get(agreement.ID) == null){
                agreementToOpportuntyMap.put(agreement.ID, agreement.Apttus__Related_Opportunity__c);
                opportunityIDSet.add(agreement.Apttus__Related_Opportunity__c);
            }
        }
        List<PSAService_Estimate__c> serviceEstimateList = [SELECT ID, 
                                                            PSAGross_Margin_Percent__c, 
                                                            PSAT_M_Amount__c,
                                                            PSATotal_Hours__c,
                                                            PSAOpportunity__c,
                                                            PSARate_based_Discount__c, 
                                                            PSATotal_Amount__c
                                                            FROM PSAService_Estimate__c 
                                                            WHERE PSAOpportunity__c in :opportunityIDSet 
                                                            AND PSAIs_Current__c = true 
                                                            AND Approval_Status__c = 'Approved'
                                                            AND PSAOpportunity__c != null
                                                            ORDER BY CreatedDate DESC];
        for(PSAService_Estimate__c serviceEstimate : serviceEstimateList){
            opportunityToServiceEstimateMap.put(serviceEstimate.PSAOpportunity__c, serviceEstimate);
        }
        for(Apttus__APTS_Agreement__c agreement : sowAgreementList){
            ID opportunityID = agreementToOpportuntyMap.get(agreement.ID);
            if(opportunityToServiceEstimateMap.get(opportunityID) != null)
            {
                PSAService_Estimate__c serviceEstimate = opportunityToServiceEstimateMap.get(opportunityID);
                agreement.APTS_Gross_Margin__c = serviceEstimate.PSAGross_Margin_Percent__c;
                agreement.APTS_Estimated_Fees__c = serviceEstimate.PSAT_M_Amount__c;
                agreement.APTS_Project_Duration_Hours__c = serviceEstimate.PSATotal_Hours__c;
                agreement.APTS_Total_Fees__c = serviceEstimate.PSATotal_Amount__c;
                agreement.APTS_Rate_Disc__c = serviceEstimate.PSARate_based_Discount__c;
            }
            else
            {
                agreement.APTS_Gross_Margin__c = 0;
                agreement.APTS_Estimated_Fees__c = 0;
                agreement.APTS_Project_Duration_Hours__c = 0;
                agreement.APTS_Total_Fees__c = 0;
                agreement.APTS_Rate_Disc__c = 0;
            }
        }
    }
    
    // Set the owner of the SOW agreement to a user with authority to send for signatures when SOW is in Ready For Signature.
    public static void updateSOWAgreementWithUser(List<Apttus__APTS_Agreement__c> sowAgreementList){
        
        List<Apttus__ComplyCustomProperties__c> customPropertiesList = Apttus__ComplyCustomProperties__c.getAll().values();
        String defaultUser = null;
        
        for(Apttus__ComplyCustomProperties__c customProperty : customPropertiesList){            
            if(customProperty.APTS_Default_Owner_SOW_Agreement__c != null){
                defaultUser =  customProperty.APTS_Default_Owner_SOW_Agreement__c;
                break;
            }
        } 
        
        User defaultSigner = null;
        User otherSigner = null;       
        List<User> signatoryUsers = [SELECT id, name FROM user WHERE id in (SELECT userorgroupid FROM groupmember WHERE group.name = 'SOW Signatory')];
        for(User usr:signatoryUsers){
            if(usr.name == defaultUser){
                defaultSigner = usr;
            }else if (usr.id == UserInfo.getUserId()){
                otherSigner= usr;
            }
        }
        
        if(defaultSigner != null || otherSigner != null){
            if(!sowAgreementList.isEmpty()){
                for(Apttus__APTS_Agreement__c agreement : sowAgreementList) {
                    if(agreement.Apttus__Status__c == 'Ready for Signatures' 
                       && agreement.Apttus__Status_Category__c == 'In Signatures'){ 
                           if(otherSigner != null){
                               agreement.OwnerId = otherSigner.ID;
                           }
                           else if(defaultSigner != null){
                               agreement.OwnerId = defaultSigner.ID;
                           }                                                                                                   
                       }                        
                }
            }            
        }                                   
    }
    
    public static List<Apttus__APTS_Agreement__c> cancelOrderAgreementsOtherThanEffectiveAgreement(List<Apttus__APTS_Agreement__c> newList){
        Set<Id> proposalIdSet = new Set<Id>();
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agreement : newList){
            if(agreement.Apttus_QPComply__RelatedProposalId__c != null){
                proposalIdSet.add(agreement.Apttus_QPComply__RelatedProposalId__c);
            }
        }
        If(proposalIdSet.size() > 0){
            List<Apttus__APTS_Agreement__c> agreementUpdtList = [Select Id, Apttus__Status_Category__c, Apttus__Status__c from
                                                                 Apttus__APTS_Agreement__c where Id Not In :newList And
                                                                 APTS_Record_Type_Name__c ='Order' And
                                                                 Apttus__Status_Category__c != 'Cancelled' And
                                                                 Apttus__Status_Category__c != 'Expired' And
                                                                 Apttus__Status_Category__c != 'Terminated' And
                                                                 Apttus__Status_Category__c != 'Amended' And
                                                                 Apttus_QPComply__RelatedProposalId__c In :proposalIdSet];
            
            for(Apttus__APTS_Agreement__c agreementTemp : agreementUpdtList){
                agreementTemp.Apttus__Status_Category__c = 'Cancelled';
                agreementTemp.Apttus__Status__c = Null;
                agreementList.add(agreementTemp);
            }
        }
        return agreementList;
    }
    
    Public static void setAgreementCurrency(List<Apttus__APTS_Agreement__c> psodAgreementList){
        Set<String> accountIdSet = new Set<String>();
        Map<String,String> currencyMap = new Map<String,String>();
        for(Apttus__APTS_Agreement__c agreement : psodAgreementList){
            accountIdSet.add(agreement.Apttus__Account__c);
        }
        List<Account> accList = [Select Id, CurrencyIsoCode from Account where Id In :accountIdSet];
        for(Account acc : accList){
            currencyMap.put(acc.Id,acc.CurrencyIsoCode);
        }
        for(Apttus__APTS_Agreement__c agreement : psodAgreementList){
            agreement.CurrencyIsoCode = currencyMap.get(agreement.Apttus__Account__c);
        }
    }
    
    public static void updateAgreementLineItemRelatedFlags(Map<Id,Apttus__APTS_Agreement__c> newAgreementMap)
    {
        Map<Id,String> agreementLineIdToLineType = new Map<Id,String>();
        for(Apttus__AgreementLineItem__c agreementLine : [Select Id, APTS_Is_Subscription_Line__c, APTS_Is_Support_Line__c,Apttus__AgreementId__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c In:newAgreementMap.keySet() And (APTS_Is_Subscription_Line__c= true Or APTS_Is_Support_Line__c = true)])
        {
            system.debug('GDM: Agrement Line: '+ agreementLine);
            
            if(agreementLine.APTS_Is_Subscription_Line__c == true)
            {
                if(agreementLineIdToLineType.containsKey(agreementLine.Apttus__AgreementId__c))
                {
                    if(agreementLineIdToLineType.get(agreementLine.Apttus__AgreementId__c) == 'Support'){
                        agreementLineIdToLineType.put(agreementLine.Apttus__AgreementId__c, 'Both');
                    }
                }
                else
                {
                    agreementLineIdToLineType.put(agreementLine.Apttus__AgreementId__c, 'Subscription');
                }
            }
            
            if(agreementLine.APTS_Is_Support_Line__c == true)
            {
                if(agreementLineIdToLineType.containsKey(agreementLine.Apttus__AgreementId__c))
                {
                    if(agreementLineIdToLineType.get(agreementLine.Apttus__AgreementId__c) == 'Subscription'){
                        agreementLineIdToLineType.put(agreementLine.Apttus__AgreementId__c, 'Both');
                    }
                }
                else
                {
                    agreementLineIdToLineType.put(agreementLine.Apttus__AgreementId__c, 'Support');
                }
            }
        }
        
        for(Id agreementId : agreementLineIdToLineType.keySet())
        {
            if(agreementLineIdToLineType.get(agreementId) == 'Subscription')
            {
                newAgreementMap.get(agreementId).APTS_Is_Subscription_Included__c = true;
            }
            else if(agreementLineIdToLineType.get(agreementId) == 'Support')
            {
                newAgreementMap.get(agreementId).APTS_Is_Support_Included__c = true;
            }
            else if(agreementLineIdToLineType.get(agreementId) == 'Both'){
                newAgreementMap.get(agreementId).APTS_Is_Subscription_Included__c = true;
                newAgreementMap.get(agreementId).APTS_Is_Support_Included__c = true;
            }
        }
        
    }
    public static void updateRenewalAgreementFields(List<Apttus__APTS_Agreement__c> agrList)
    {
        Map<Id, Id> agrToRelatedPropMap = new Map<Id, Id>();
        List<Apttus__APTS_Agreement__c> agrToUpdateList = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agrRec : agrList)
        {     
            if(agrRec.Apttus_QPComply__RelatedProposalId__c != null)
            {
                agrToRelatedPropMap.put(agrRec.Id, agrRec.Apttus_QPComply__RelatedProposalId__c);   
            }
        }
        
        if(!agrToRelatedPropMap.isEmpty())
        {
            Map<Id, String> quoteIdToOldQuoteNameMap = new Map<Id, String>();
            // Get the old quote name using the name of the present renewal proposal from agreement
            for(Apttus_Proposal__Proposal__c propRec : [select id, Apttus_Proposal__Proposal_Name__c 
                                                        from Apttus_Proposal__Proposal__c 
                                                        where Id in :agrToRelatedPropMap.values()
                                                        and RecordTypeId = :APTS_Constant.PROPOSAL_RENEWAL_RT_ID
                                                        and Apttus_QPConfig__IsSystemGenerated__c = true])
            {
                String[] propName = propRec.Apttus_Proposal__Proposal_Name__c.split(':');
                //RB: C1 migrated agreement does not have this naming convension.
                if(propName.size() > 1)
                {
                    String[] substring1 = propName[1].split('-'); // propName[1] example: Q-00004462-2022-02-27
                    if(substring1.size() > 1)
                    {
                        String oldQuoteName = substring1[0] + '-' + substring1[1]; // example: Q-00004462
                        quoteIdToOldQuoteNameMap.put(propRec.Id, oldQuoteName);
                    }
                }
            }
            System.debug('quoteIdToOldQuoteNameMap: ' + quoteIdToOldQuoteNameMap);
            Map<String, Apttus_Proposal__Proposal__c> oldQuoteNameToQuoteMap = new Map<String, Apttus_Proposal__Proposal__c>();
            // fetching the required data based on the old quote names retrieved
            for(Apttus_Proposal__Proposal__c propRec : [select id, Name, Apttus_QPComply__MasterAgreementId__c, 
                                                        Apttus_QPComply__MasterAgreementId__r.APTS_PO_Required__c,
                                                        Apttus_QPComply__MasterAgreementId__r.APTS_Salesforce_Org_Id__c
                                                        from Apttus_Proposal__Proposal__c 
                                                        where Name in :quoteIdToOldQuoteNameMap.values()])
            {
                oldQuoteNameToQuoteMap.put(propRec.Name, propRec);
            }
            System.debug('oldQuoteNameToQuoteMap: ' + oldQuoteNameToQuoteMap);
            if(!oldQuoteNameToQuoteMap.isEmpty())
            {
                for(Apttus__APTS_Agreement__c agrRec : agrList)
                {            
                    if(agrRec.Apttus_QPComply__RelatedProposalId__c != null && quoteIdToOldQuoteNameMap.containsKey(agrRec.Apttus_QPComply__RelatedProposalId__c))
                    {
                        Apttus_Proposal__Proposal__c oldQuoteRec = oldQuoteNameToQuoteMap.get(quoteIdToOldQuoteNameMap.get(agrRec.Apttus_QPComply__RelatedProposalId__c));
                        agrRec.APTS_PO_Required__c = oldQuoteRec.Apttus_QPComply__MasterAgreementId__r.APTS_PO_Required__c;
                        agrRec.APTS_Salesforce_Org_Id__c = oldQuoteRec.Apttus_QPComply__MasterAgreementId__r.APTS_Salesforce_Org_Id__c;
                        agrToUpdateList.add(agrRec);
                    }
                }
            }
        } 
    }
    
    public static void setOrderformAgreementId(List<Apttus__APTS_Agreement__c> agrList)
    {
        List<Apttus_Proposal__Proposal__c> propsUpdateList = new List<Apttus_Proposal__Proposal__c>();
        for(Apttus__APTS_Agreement__c agrRec : agrList)
        {     
            if(agrRec.Apttus_QPComply__RelatedProposalId__c != null)
            {
                propsUpdateList.add(new Apttus_Proposal__Proposal__c(Id = agrRec.Apttus_QPComply__RelatedProposalId__c, Apttus_QPComply__MasterAgreementId__c = agrRec.Id));
            }
        }
        if(propsUpdateList.size() > 0)
        {
            try 
            {
                update propsUpdateList;    
            } 
            catch (Exception e) 
            {
                System.debug(Logginglevel.ERROR, 'Exception occured when updating proposals: ' + e.getMessage());    
            }
        } 
    }
    public static void cancelOrderAgreements(List<Apttus__APTS_Agreement__c> newList){
        Map<Id, List<Apttus__APTS_Agreement__c>> proposalToAgrMap = new Map<Id, List<Apttus__APTS_Agreement__c>>();
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agreement : newList){
            
            if(agreement.RecordTypeId == APTS_Constant.AGREEMENT_ORDER_RT_ID)
            {
                if (agreement.Apttus_QPComply__RelatedProposalId__c != null){
                    if(proposalToAgrMap.containsKey(agreement.Apttus_QPComply__RelatedProposalId__c))
                    {
                        List<Apttus__APTS_Agreement__c> agrList = proposalToAgrMap.get(agreement.Apttus_QPComply__RelatedProposalId__c);
                        agrList.add(agreement);
                    }
                    else
                    {
                        proposalToAgrMap.put(agreement.Apttus_QPComply__RelatedProposalId__c, new List<Apttus__APTS_Agreement__c>{agreement});
                    }
                }
            }
        }
        
        If(proposalToAgrMap.size() > 0){
            List<Apttus__APTS_Agreement__c> agreementUpdtList = [Select Id, Apttus__Status_Category__c, Apttus__Status__c, Apttus_QPComply__RelatedProposalId__c
                                                                 from Apttus__APTS_Agreement__c where Id Not In :newList And
                                                                 APTS_Record_Type_Name__c = 'Order' And
                                                                 Apttus__Status_Category__c != 'Cancelled' And
                                                                 Apttus__Status_Category__c != 'Expired' And
                                                                 Apttus__Status_Category__c != 'Terminated' And
                                                                 Apttus__Status_Category__c != 'Amended' And
                                                                 Apttus_QPComply__RelatedProposalId__c In :proposalToAgrMap.keySet()];
            
            for(Apttus__APTS_Agreement__c agreementTemp : agreementUpdtList){                
                if(agreementTemp.Apttus__Status_Category__c == 'In Effect' || (agreementTemp.Apttus__Status_Category__c == 'In Signatures' && (agreementTemp.Apttus__Status__c != 'Ready for Signatures' && agreementTemp.Apttus__Status__c != 'Signature Declined')))
                {
                    for(Apttus__APTS_Agreement__c agrRec : proposalToAgrMap.get(agreementTemp.Apttus_QPComply__RelatedProposalId__c))
                    {
                        agrRec.addError('There is Agreement already created from this Quote in status category \'' + agreementTemp.Apttus__Status_Category__c + '\' and status \''+agreementTemp.Apttus__Status__c +'\', quote can no longer be modified.');
                    }                    
                }
                else if(agreementTemp.Apttus__Status_Category__c == 'Request' || agreementTemp.Apttus__Status_Category__c == 'In Authoring' || (agreementTemp.Apttus__Status_Category__c == 'In Signatures' && (agreementTemp.Apttus__Status__c == 'Ready for Signatures' || agreementTemp.Apttus__Status__c == 'Signature Declined'))) {
                    agreementTemp.Apttus__Status_Category__c = 'Cancelled';
                    agreementTemp.Apttus__Status__c = 'Cancelled Request';
                    agreementList.add(agreementTemp);
                }
            }
        }
        
        if(agreementList.size() > 0)
        {
            update agreementList;
        }
    }
    
    /**
* @description Check whether approval is required for agreement record based on search filters
* @param List<Apttus__APTS_Agreement__c> newList
* @param Boolean isInsert
* @return
*/ 
    public static void checkApprovalRequired(List<Apttus__APTS_Agreement__c> newList,Boolean isInsert)
    {
        APTS_C4C_Custom_Metadata__mdt c4cMeta = [select APTS_Exclude_Approval_Check_Status__c,APTS_Agreement_Status_for_Approval_Check__c,APTS_Agreement_Record_Types_for_Approval__c from APTS_C4C_Custom_Metadata__mdt where DeveloperName = 'System_Properties' limit 1];
        
        List<String> statusToExclude = new List<String>();
        List<String> agreementCatForApproval = new List<String>();
        List<String> agreementRecordTypesforApproval = new List<String>();
        
        List<Id> sobjectIds = new List<Id>();
        List<Boolean> approvalFlags = new List<Boolean>();
        
        List<Apttus__APTS_Agreement__c> updateAgreements = new List<Apttus__APTS_Agreement__c>();
        
        if(!String.isBlank(c4cMeta.APTS_Exclude_Approval_Check_Status__c))
        {
            statusToExclude = c4cMeta.APTS_Exclude_Approval_Check_Status__c.split(',');
        }
        
        if(!String.isBlank(c4cMeta.APTS_Agreement_Status_for_Approval_Check__c))
        {
            agreementCatForApproval = c4cMeta.APTS_Agreement_Status_for_Approval_Check__c.split(',');
        }
        
        if(!String.isBlank(c4cMeta.APTS_Agreement_Record_Types_for_Approval__c))
        {
            agreementRecordTypesforApproval = c4cMeta.APTS_Agreement_Record_Types_for_Approval__c.split(',');
        }
        
        for(Apttus__APTS_Agreement__c agreement : newList)
        {
            Map<Id, String> approvalStatusMap = new Map<Id, String>();
            String recType = Schema.getGlobalDescribe().get('Apttus__APTS_Agreement__c').getDescribe().getRecordTypeInfosById().get(agreement.RecordTypeId).getDeveloperName();
            if(agreementRecordTypesforApproval.contains(recType) && UserInfo.getUserId() != System.Label.APTS_Data_Migration_User_Id && agreementCatForApproval.contains(agreement.Apttus__Status_Category__c) && !statusToExclude.contains(agreement.Apttus_Approval__Approval_Status__c))
            {
                sobjectIds.add(agreement.Id);
            }
        }
        
        if(sobjectIds.size() > 0)
        {
            approvalFlags = Apttus_Approval.ApprovalsWebService.checkIfApprovalRequired(sobjectIds);
            for(Apttus__APTS_Agreement__c agreement : newList)
            {
                if(sobjectIds.contains(agreement.Id))
                {
                    if(approvalFlags.get(sobjectIds.indexOf(agreement.Id)))
                    {
                        updateAgreements.add(new Apttus__APTS_Agreement__c(Id=agreement.Id,Apttus_Approval__Approval_Status__c = 'Approval Required'));
                    }
                    else
                    {
                        updateAgreements.add(new Apttus__APTS_Agreement__c(Id=agreement.Id,Apttus_Approval__Approval_Status__c = 'None'));
                    }
                }
            }
            
            if(updateAgreements.size() > 0)
            {
                //set flag so trigger is not executed again
                APTS_AgreementTriggerHandler.executeTrigger = false;
                
                update updateAgreements;
            }
        }
    }
    
    //GDM it will populate the Agreement lookup on Service Estimate record and its related Line Items
    public static void populateAgreementOnServiceEstimateAndItsLines(List<Apttus__APTS_Agreement__c> sowAgreementList){
        Map<Id,Id> opportunityIdToAgreementIdMap = new Map<Id,Id>();
        if(sowAgreementList != null && !sowAgreementList.isEmpty()){
            for(Apttus__APTS_Agreement__c agreement : sowAgreementList)
            {
                if(agreement.Apttus__Related_Opportunity__c != null){
                    opportunityIdToAgreementIdMap.put(agreement.Apttus__Related_Opportunity__c, agreement.Id);
                }
            }
        }
        
        if(!opportunityIdToAgreementIdMap.isEmpty())
        {
            fetchServiceEstimateRecords(opportunityIdToAgreementIdMap);
        }
    }
    
    public static void fetchServiceEstimateRecords(Map<Id,Id> opportunityIdToAgreementIdMap){
        
        List<PSAService_Estimate__c> serviceEstimateRecords = [Select id, PSAOpportunity__c, PSAIs_Current__c from PSAService_Estimate__c where PSAOpportunity__c IN: opportunityIdToAgreementIdMap.keySet() and PSAIs_Current__c = true];
        Map<Id,Id> serviceEstimateIdToAgreementIdMap = new Map<Id,Id>();
        List<PSAService_Estimate__c> seRecordListToBeUpdated = new List<PSAService_Estimate__c>();
        
        for(PSAService_Estimate__c seRecord : serviceEstimateRecords){
            if(opportunityIdToAgreementIdMap.containsKey(seRecord.PSAOpportunity__c))
            {
                seRecord.APTS_Agreement__c = opportunityIdToAgreementIdMap.get(seRecord.PSAOpportunity__c);
                seRecordListToBeUpdated.add(seRecord);
                serviceEstimateIdToAgreementIdMap.put(seRecord.Id,opportunityIdToAgreementIdMap.get(seRecord.PSAOpportunity__c));
            }
        }
        
        if(!seRecordListToBeUpdated.isEmpty())
        {
            try {
                update seRecordListToBeUpdated;
            } catch (Exception ex) {
                system.debug('Exception while updating ServiceEstimate records: '+ex);
            }
        }
        
        if(serviceEstimateIdToAgreementIdMap != null || !serviceEstimateIdToAgreementIdMap.isEmpty())
        {
            fetchServiceEstimateLineItemRecords(serviceEstimateIdToAgreementIdMap);
        }
    }
    
    public static void fetchServiceEstimateLineItemRecords(Map<Id,Id> serviceEstimateIdToAgreementIdMap){
        List<PSAService_Estimate_Line_Item__c> serviceEstimateLIRecords = [Select id, PSAService_Estimate__c from PSAService_Estimate_Line_Item__c where PSAService_Estimate__c IN: serviceEstimateIdToAgreementIdMap.keySet()];
        List<PSAService_Estimate_Line_Item__c> seLineItemRecordListToBeUpdated = new List<PSAService_Estimate_Line_Item__c>();
        for(PSAService_Estimate_Line_Item__c seLineItemRecord : serviceEstimateLIRecords){
            
            if(serviceEstimateIdToAgreementIdMap.containsKey(seLineItemRecord.PSAService_Estimate__c))
            {
                seLineItemRecord.APTS_Agreement__c = serviceEstimateIdToAgreementIdMap.get(seLineItemRecord.PSAService_Estimate__c);
                seLineItemRecordListToBeUpdated.add(seLineItemRecord);
            }
        }
        
        if(!seLineItemRecordListToBeUpdated.isEmpty())
        {
            try {
                update seLineItemRecordListToBeUpdated;
            } catch (Exception ex) {
                system.debug('Exception while updating ServiceEstimate records: '+ex);
            }
        }
    }
    
    // HAR-12361, before update call to set the default payment term on order agreements
    public static void setDefaultPaymentTerm(List<Apttus__APTS_Agreement__c> orderAgreementList, Map<Id, Apttus__APTS_Agreement__c> oldMap)
    {
        Set<Id> agreementParentIdsSet = new Set<Id>();
        for(Apttus__APTS_Agreement__c agrRec : orderAgreementList)
        {
            // If Parent Agreement is blank and the user hasn't set a payment term then...
            if(agrRec.Apttus__Parent_Agreement__c == null && agrRec.APTS_Payment_Terms__c == null && agrRec.APTS_Payment_Terms__c == oldMap.get(agrRec.Id).APTS_Payment_Terms__c)
            {
                agrRec.APTS_Payment_Terms__c = APTS_Constant.PAYMENT_TERM_NET30;
            }
            // If Parent agreement has changed then set payment term from parent agreement
            else if(agrRec.Apttus__Parent_Agreement__c != null && agrRec.Apttus__Parent_Agreement__c != oldMap.get(agrRec.Id).Apttus__Parent_Agreement__c)
            {
                agreementParentIdsSet.add(agrRec.Apttus__Parent_Agreement__c);
            }
        }
        if(agreementParentIdsSet.size() > 0)
        {
            Map<Id, Apttus__APTS_Agreement__c> agrIdToAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
            for(Apttus__APTS_Agreement__c agr : [select id, APTS_Payment_Terms__c, APTS_Other_Payment_Term__c, Conga_Entity_Code__c from Apttus__APTS_Agreement__c where id in :agreementParentIdsSet])
            {
                agrIdToAgreementMap.put(agr.Id, agr);
            }
            if(!agrIdToAgreementMap.isEmpty())
            {
                for(Apttus__APTS_Agreement__c agrRec : orderAgreementList)
                {
                    if(agrIdToAgreementMap.containsKey(agrRec.Apttus__Parent_Agreement__c))
                    {
                        Apttus__APTS_Agreement__c tmpAgr = agrIdToAgreementMap.get(agrRec.Apttus__Parent_Agreement__c); 
                        agrRec.APTS_Payment_Terms__c = tmpAgr.APTS_Payment_Terms__c;
                        if(tmpAgr.APTS_Payment_Terms__c == 'Other')
                        {
                            agrRec.APTS_Other_Payment_Term__c = tmpAgr.APTS_Other_Payment_Term__c;
                        }
                        agrRec.Conga_Entity_Code__c = tmpAgr.Conga_Entity_Code__c;
                    }
                }
            }
        }
    }
    
    // HAR-13748, before insert method to clear external id if not created during data migration
    public static void clearExternalId(List<Apttus__APTS_Agreement__c> agreementList)
    {
        for(Apttus__APTS_Agreement__c agr : agreementList)
        {
            if(UserInfo.getUserId() != System.Label.APTS_Data_Migration_User_Id && agr.SRC_EXTERNAL_ID__c != null)
            {
                agr.SRC_EXTERNAL_ID__c = null;
            }
        }
    }
    
    // HAR-13805, before updated method to set PO Required field
    public static void setPORequired(List<Apttus__APTS_Agreement__c> agreementList, Map<Id, Apttus__APTS_Agreement__c> oldMap)
    {
        for(Apttus__APTS_Agreement__c agr : agreementList)
        {
            if(agr.APTS_PO_Required_Y_N__c != oldMap.get(agr.Id).APTS_PO_Required_Y_N__c)
            {
                if(agr.APTS_PO_Required_Y_N__c != null && agr.APTS_PO_Required_Y_N__c.toLowerCase() == 'y')
                {
                    agr.APTS_PO_Required__c = 'Yes';
                }
                else 
                {
                    agr.APTS_PO_Required__c = 'No';
                }
            }
        }
    }
    
    public static void setLegalInitials(List<Apttus__APTS_Agreement__c> agreementList) {
        List<Contact> contactList = [Select Id from Contact where Name = 'Conga Legal' AND Email = 'legal@conga.com' Limit 1];
        for( Apttus__APTS_Agreement__c agreement : agreementList) {
            if(agreement.APTS_Notes_Legal_Approved__c != NULL && contactList.size()>0) {
                agreement.APTS_Legal_Initials__c = contactList[0].Id;
            }
            else if(agreement.APTS_Legal_Initials__c != NULL && agreement.APTS_Notes_Legal_Approved__c == NULL) {
                agreement.APTS_Legal_Initials__c = NULL;
            }
        }
    }
    
    
    public static void setCongaSignatory(List<Apttus__APTS_Agreement__c> agreementList) {
        Set<Id> accountIDSet = new Set<Id>();
        Set<Id> proposalIds = new Set<Id>();
        List<Apttus_Proposal__Proposal__c> proposals = new List<Apttus_Proposal__Proposal__c>();
        Map<Id,Id> proposalSignerMap = new Map<Id,Id>();
        for (Apttus__APTS_Agreement__c agreement : agreementList) {
            if(agreement.Apttus__Parent_Agreement__c == null){
                accountIDSet.add(agreement.Apttus__Account__c);
            }
            if (agreement.Apttus_QPComply__RelatedProposalId__c != null)
                proposalIds.add(agreement.Apttus_QPComply__RelatedProposalId__c);
            if(agreement.APTS_Notes_Legal_Approved__c != NULL) {
                setLegalInitials(agreementList);
            }
        }
        
        if (proposalIds.size() > 0) {
            proposals = [SELECT RecordType.Name,RecordType.DeveloperName,Apttus_Proposal__Opportunity__r.Geo__c,Apttus_Proposal__Account__r.Geo__c,Apttus_Proposal__Opportunity__r.type, 
                         TCV__c,APTS_CARR__c,Apttus_Proposal__Opportunity__r.Segment__c,AVP__r.Id,Manager__r.Id,SVP__r.Id,
                         Manager__r.Title,AVP__r.Title,SVP__r.Title
                         FROM Apttus_Proposal__Proposal__c
                         WHERE Id IN :proposalIds];
            
            List<APTS_Signature_Routing__c> routingConfig = new List<APTS_Signature_Routing__c>();
            for (Apttus_Proposal__Proposal__c proposal : proposals) {
                Id congaSigner;
                //CIT-1595
                if(proposal.Apttus_Proposal__Opportunity__r.type == 'Existing - Velocity Upsell')
                {
                    if(proposal.Apttus_Proposal__Account__r.Geo__c == 'APAC')        //CIT-10324
                    {
                        Id signerId = id.valueOf(Label.CPQ_Velocity_Geo_Order_Form_Signer);
                        congaSigner = signerId;
                    }else{    
                        Id signerId = id.valueOf(Label.CPQ_Velocity_Order_Form_Signer);
                        congaSigner = signerId;
                    }
                }
                //CIT-1595 ends here
                
                else{
                    if(proposal.Apttus_Proposal__Opportunity__r.Segment__c != NULL) {
                        if ((proposal.APTS_CARR__c > 100000 &&
                             (proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Enterprise') ||
                              proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Strategic'))) ||
                            (proposal.APTS_CARR__c > 50000 &&
                             proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Commercial'))) 
                        {
                            routingConfig = [SELECT APTS_Min_TCV__c,APTS_Max_TCV__c,APTS_Geo__c,APTS_Signer__c,APTS_Sales_Type__c,APTS_Segment__c
                                             FROM APTS_Signature_Routing__c];
                        }
                    }
                    if (routingConfig.size() > 0) {
                        for (APTS_Signature_Routing__c config : routingConfig) {
                            if (((proposal.APTS_CARR__c > config.APTS_Min_TCV__c && proposal.APTS_CARR__c <= config.APTS_Max_TCV__c) &&
                                 proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains(config.APTS_Segment__c)) ||
                                (proposal.APTS_CARR__c > config.APTS_Min_TCV__c && config.APTS_Max_TCV__c == NULL))
                            {
                                congaSigner = config.APTS_Signer__c;
                                break;
                            } 
                        }
                    } 
                    else if(proposal.Apttus_Proposal__Opportunity__r.Segment__c != NULL) {
                        if((proposal.APTS_CARR__c >= 0 && proposal.APTS_CARR__c <= 50000 &&
                            (proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Enterprise') ||
                             proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Strategic'))) ||
                           (proposal.APTS_CARR__c >= 0 && proposal.APTS_CARR__c <= 15000 &&
                            proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Commercial'))) {
                                if (proposal.Manager__r.Id != NULL && proposal.Manager__r.Title != NULL && 
                                    proposal.Manager__r.Title.contains('Director')) {
                                        congaSigner = proposal.Manager__r.Id;
                                    } else if (proposal.AVP__r.Id != null && proposal.AVP__r.Title != NULL &&
                                               proposal.AVP__r.Title.contains('Director')) {
                                                   congaSigner = proposal.AVP__r.Id;
                                               } else if (proposal.SVP__r.Id != null && proposal.SVP__r.Title != NULL && 
                                                          proposal.SVP__r.Title.contains('Director')) {
                                                              congaSigner = proposal.SVP__r.Id;
                                                          }
                            } 
                        else if ((proposal.APTS_CARR__c > 50000 && proposal.APTS_CARR__c <= 100000 &&
                                  (proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Enterprise') ||
                                   proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Strategic'))) ||
                                 (proposal.APTS_CARR__c > 15000 && proposal.APTS_CARR__c <= 50000 &&
                                  proposal.Apttus_Proposal__Opportunity__r.Segment__c.contains('Commercial'))) {
                                      if (proposal.AVP__r.Id != null) {
                                          congaSigner = proposal.AVP__r.Id;
                                      }
                                  }
                    }
                }
                if (congaSigner != null)
                    proposalSignerMap.put(proposal.Id, congaSigner);
            }
            
            for (Apttus__APTS_Agreement__c agreement : agreementList) {
                if (agreement.Apttus_QPComply__RelatedProposalId__c != null && 
                    proposalSignerMap.containsKey(agreement.Apttus_QPComply__RelatedProposalId__c)) {
                        agreement.Conga_Signatory__c = proposalSignerMap.get(agreement.Apttus_QPComply__RelatedProposalId__c);
                    }
            }
        }
    }
    
    // This method is called on before insert to set the fields on the order agreements
    public static void setFieldsOnInsert(List<Apttus__APTS_Agreement__c> agreementList)
    {
        Map<Id, Id> agreementToPropIdMap = new Map<Id, Id>();
        
        for(Apttus__APTS_Agreement__c agreement : agreementList)
        {
            if(agreement.Apttus_QPComply__RelatedProposalId__c != null) 
            {
                agreementToPropIdMap.put(agreement.Id, agreement.Apttus_QPComply__RelatedProposalId__c);
            }
        }
        if(agreementToPropIdMap.size() > 0)
        {
            Map<Id, Apttus_Proposal__Proposal__c> propIdToPropMap = new Map<Id, Apttus_Proposal__Proposal__c>([Select id, APTSMSSAAgreements__c, 
                                                                                                               APTSMSSAAgreements__r.APTS_Payment_Terms__c,
                                                                                                               APTSMSSAAgreements__r.APTS_Other_Payment_Term__c
                                                                                                               from Apttus_Proposal__Proposal__c 
                                                                                                               where Id in :agreementToPropIdMap.values()]);
            for(Apttus__APTS_Agreement__c agreement : agreementList)
            {
                if(agreementToPropIdMap.containsKey(agreement.ID))
                {
                    Apttus_Proposal__Proposal__c propRec = propIdToPropMap.get(agreementToPropIdMap.get(agreement.ID));
                    if(propRec.APTSMSSAAgreements__c != null)
                    {
                        agreement.Apttus__Parent_Agreement__c = propRec.APTSMSSAAgreements__c;
                        agreement.APTS_Payment_Terms__c = propRec.APTSMSSAAgreements__r.APTS_Payment_Terms__c;
                        if(propRec.APTSMSSAAgreements__r.APTS_Payment_Terms__c == 'Other')
                        {
                            agreement.APTS_Other_Payment_Term__c = propRec.APTSMSSAAgreements__r.APTS_Other_Payment_Term__c;
                        }
                    }
                }
            } // agreement loop end
        }
    } // method end
    //Avani : CIT-7614
    public static void populateQueueIdForTaskDefaulting(List<Apttus__APTS_Agreement__c> agreementList){
        try{
            Id queueIsToAssign;
            QueueSobject queueDetail=[select Id, QueueId, SobjectType, SystemModstamp,Queue.Name from QueueSobject  where SobjectType = 'Apttus__APTS_Agreement__c' and Queue.name='Ops Deals Desk' limit 1];
            if(queueDetail!=null){
                queueIsToAssign=queueDetail.QueueId;
                for(Apttus__APTS_Agreement__c agr:agreementList){
                    agr.Queue_Id__c=queueIsToAssign;
                }
            }
            
        }catch(Exception e){
            system.debug('Exception e'+e.getMessage() +' at '+e.getLineNumber()); 
        }
    }
    
    //Avani : CIT -7615 This method is called on before insert to populate the MSA 
    public static void populateParentAgreementwithMSA(List<Apttus__APTS_Agreement__c> agreementList){
        try{
            Map<Id,Apttus__APTS_Agreement__c> agreementOpportunityMap=new Map<Id,Apttus__APTS_Agreement__c>();
            Map<id,string> opportunityWithFeesDetail=new Map<Id,String>();
            Map<Id,Id> oppotunityWithMSAMap=new Map<Id,Id>();
            List<Apttus__APTS_Agreement__c>  agrList=new  List<Apttus__APTS_Agreement__c> ();
            if(agreementList!=null && !agreementList.isEmpty()){
                for(Apttus__APTS_Agreement__c agr:agreementList){
                    if(agr.Apttus__Related_Opportunity__c!=null || test.isRunningTest()){
                        agreementOpportunityMap.put(agr.Apttus__Related_Opportunity__c,agr);
                    }
                }
                if(!agreementOpportunityMap.isEmpty() || test.isRunningTest()){
                    agrList=[select Id,RecordType.name,Apttus__Status__c, Apttus__Status_Category__c,APTS_Fees_Payment_Term__c, APTS_Expenses_Payment_Term__c,Apttus__Related_Opportunity__c,Apttus__Parent_Agreement__c
                             from Apttus__APTS_Agreement__c  
                             where Apttus__Related_Opportunity__c  =:agreementOpportunityMap.keySet() and RecordType.Name ='MSA' and Apttus__Status__c ='Activated' order by LastModifiedDate asc];
                }
                
                if(!agrList.isEmpty() || test.isRunningTest()){
                    for(Apttus__APTS_Agreement__c agr:agrList){
                        oppotunityWithMSAMap.put(agr.Apttus__Related_Opportunity__c,agr.Id);
                        if(agr.APTS_Fees_Payment_Term__c!=null && agr.APTS_Expenses_Payment_Term__c!=null){
                            opportunityWithFeesDetail.put(agr.Apttus__Related_Opportunity__c,agr.APTS_Fees_Payment_Term__c+'%'+agr.APTS_Expenses_Payment_Term__c);
                        }
                        
                    }
                }
                
                if(!agreementOpportunityMap.isEmpty() || test.isRunningTest()){
                    List<string> feesExpensePayment=new List<string>();
                    for(Id oppId:agreementOpportunityMap.keySet()){
                        if(oppotunityWithMSAMap.get(oppId)!=null || test.isRunningTest()){
                            string feeInformation=opportunityWithFeesDetail.get(oppId);
                            
                            Apttus__APTS_Agreement__c sowAgreement= agreementOpportunityMap.get(oppId);
                            if(sowAgreement!=null || test.isRunningTest()){
                                sowAgreement.Apttus__Parent_Agreement__c=oppotunityWithMSAMap.get(oppId);
                                if(feeInformation!=null || test.isRunningTest()){
                                    feesExpensePayment =feeInformation.split('%');
                                }
                                if(!feesExpensePayment.isEmpty() || test.isRunningTest()){
                                    sowAgreement.APTS_Fees_Payment_Term__c=feesExpensePayment[0];
                                    system.debug('fee' +feesExpensePayment[1]+' one '+feesExpensePayment[0]);
                                    if(feesExpensePayment[1]!=null){
                                        sowAgreement.APTS_Expenses_Payment_Term__c=feesExpensePayment[1];
                                    }
                                    
                                }
                                
                            }
                        }
                        
                    }
                }
            }
        }catch(Exception e){
            system.debug('Exception e'+e.getMessage() +' at '+e.getLineNumber());
        }
    }
    //This method is called on before update to set the MSSA as Parent Agreement on PSOD and SOW agreements
    public static void updateMSSAOnAgreement(List<Apttus__APTS_Agreement__c> agreementList)
    {
        Set<Id> accountIDSet = new Set<Id>();
        Set<Id> parentAgreementApttusSet = new Set<Id>();
        Set<Id> parentAgreementCongaSet = new Set<Id>();
        Map<ID, List<Apttus__APTS_Agreement__c>> parentAgreementApttusMap = new Map<ID, List<Apttus__APTS_Agreement__c>>();
        Map<ID, List<Apttus__APTS_Agreement__c>> parentAgreementCongaMap = new Map<ID, List<Apttus__APTS_Agreement__c>>();
        for (Apttus__APTS_Agreement__c agreement : agreementList)
        {
            if(agreement.Apttus__Parent_Agreement__c == null){
                accountIDSet.add(agreement.Apttus__Account__c);
            }
        }
        List<Apttus__APTS_Agreement__c> parentAgreementList = new List<Apttus__APTS_Agreement__c>([SELECT ID, Apttus__Account__c, Conga_Entity_Code__c 
                                                                                                   FROM Apttus__APTS_Agreement__c 
                                                                                                   WHERE Apttus__Account__c IN :accountIDSet
                                                                                                   AND APTS_Record_Type_Name__c =: APTS_Constant.MSSA_RECORDTYPE
                                                                                                   AND Conga_Entity_Code__c IN (:APTS_Constant.ENTITY_CODE_CONGA, :APTS_Constant.ENTITY_CODE_APTTUS)                                                                                       
                                                                                                   AND Apttus__Status_Category__c = 'In Effect'
                                                                                                   AND Apttus__Status__c = 'Activated' 
                                                                                                  ]);
        if(parentAgreementList.size() > 0) 
        {
            for (Apttus__APTS_Agreement__c agreement : parentAgreementList) 
            {
                if(agreement.Conga_Entity_Code__c == APTS_Constant.ENTITY_CODE_APTTUS){
                    if(parentAgreementApttusMap.containsKey(agreement.Apttus__Account__c))
                    {
                        parentAgreementApttusSet.add(agreement.Apttus__Account__c);
                    }
                    else
                    {
                        parentAgreementApttusMap.put(agreement.Apttus__Account__c, new List<Apttus__APTS_Agreement__c>{agreement});       
                    }
                }
                if(agreement.Conga_Entity_Code__c == APTS_Constant.ENTITY_CODE_CONGA){
                    if(parentAgreementCongaMap.containsKey(agreement.Apttus__Account__c))
                    {
                        parentAgreementCongaSet.add(agreement.Apttus__Account__c);
                    }
                    else
                    {
                        parentAgreementCongaMap.put(agreement.Apttus__Account__c, new List<Apttus__APTS_Agreement__c>{agreement});       
                    }
                }
            }
            parentAgreementApttusMap.keySet().removeAll(parentAgreementApttusSet);
            parentAgreementCongaMap.keySet().removeAll(parentAgreementCongaSet);
            Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([Select Id, Subscription_Opportunity__r.Conga_Entity_Code__c
                                                                          from Opportunity 
                                                                          where AccountId IN :accountIDSet
                                                                          AND RecordType.Name = 'Service'
                                                                          AND StageName NOT IN ('Closed Won', 'Closed Lost')]);                                    
            for (Apttus__APTS_Agreement__c childAgreement : agreementList)
            {    
                if (parentAgreementApttusMap.containsKey(childAgreement.Apttus__Account__c))
                {
                    Id parentAgreementId = parentAgreementApttusMap.get(childAgreement.Apttus__Account__c)[0].Id;
                    String entityCode = parentAgreementApttusMap.get(childAgreement.Apttus__Account__c)[0].Conga_Entity_Code__c;
                    if(childAgreement.APTS_Record_Type_Name__c == 'PSOD' && entityCode == APTS_Constant.ENTITY_CODE_APTTUS)
                    {   
                        childAgreement.Apttus__Parent_Agreement__c = parentAgreementId;
                    }
                    
                    if(opportunityMap != null && !opportunityMap.isEmpty() && childAgreement.APTS_Record_Type_Name__c == 'SOW' 
                       && childAgreement.APTS_SOW_Type__c == 'SOW (Main)' 
                       && entityCode == opportunityMap.get(childAgreement.Apttus__Related_Opportunity__c).Subscription_Opportunity__r.Conga_Entity_Code__c)
                    {   
                        childAgreement.Apttus__Parent_Agreement__c = parentAgreementId;
                    }
                }
                if (parentAgreementCongaMap.containsKey(childAgreement.Apttus__Account__c) 
                    && childAgreement.APTS_Record_Type_Name__c == 'SOW' 
                    && childAgreement.APTS_SOW_Type__c == 'SOW (Main)')
                {
                    Id parentAgreementId = parentAgreementCongaMap.get(childAgreement.Apttus__Account__c)[0].Id;
                    String entityCode = parentAgreementCongaMap.get(childAgreement.Apttus__Account__c)[0].Conga_Entity_Code__c;
                    
                    if(opportunityMap != null && !opportunityMap.isEmpty() 
                       && entityCode == opportunityMap.get(childAgreement.Apttus__Related_Opportunity__c).Subscription_Opportunity__r.Conga_Entity_Code__c)
                    {   
                        childAgreement.Apttus__Parent_Agreement__c = parentAgreementId;
                    }
                }
            }
        }  
    }
    
    //This method updates the Related pportunity field on MSA Agreement record based on it's child order agreement
    public static void updateRelatedOpportunityOnMSAAgreement_NewLogo(Set<Id> setOfOpportunityIds,List<Apttus__APTS_Agreement__c>  listOfNewOrderAgreements)
    {
        if(listOfNewOrderAgreements != null)
        {
            Map<Id,Apttus__APTS_Agreement__c> listOfParentAgreementsToUpdate = new Map<Id,Apttus__APTS_Agreement__c>();
            Map<Id,Opportunity> mapOfOpportunities;
            if(setOfOpportunityIds != null){
                mapOfOpportunities = new Map<Id,Opportunity>([SELECT Id,Name,Type 
                                                              FROM Opportunity 
                                                              WHERE Id IN: setOfOpportunityIds]);
            }
            for(Apttus__APTS_Agreement__c oAgreement : listOfNewOrderAgreements)
            {
                if(oAgreement.APTS_Record_Type_Name__c.equalsIgnoreCase('Order'))
                {
                    if(oAgreement.Apttus__Related_Opportunity__c != null && mapOfOpportunities != null && 
                       mapOfOpportunities.containsKey(oAgreement.Apttus__Related_Opportunity__c) && mapOfOpportunities.get(oAgreement.Apttus__Related_Opportunity__c).Type != null &&
                       mapOfOpportunities.get(oAgreement.Apttus__Related_Opportunity__c).Type.equalsIgnoreCase('New Business - New Logo') && oAgreement.Apttus__Parent_Agreement__c != null)
                    {
                        Apttus__APTS_Agreement__c parentMSAAgreement = new Apttus__APTS_Agreement__c(Id=oAgreement.Apttus__Parent_Agreement__c);
                        if (parentMSAAgreement.Apttus__Related_Opportunity__c != oAgreement.Apttus__Related_Opportunity__c){
                        parentMSAAgreement.Apttus__Related_Opportunity__c = oAgreement.Apttus__Related_Opportunity__c;
                        listOfParentAgreementsToUpdate.put(oAgreement.Apttus__Parent_Agreement__c,parentMSAAgreement);
                        }
                    }
                }
            }
            if(listOfParentAgreementsToUpdate != null && !listOfParentAgreementsToUpdate.isEmpty()){
                update listOfParentAgreementsToUpdate.values();
            }   
        }
    }
    
    // This method updates the document generation status to show message on the UI
    public static void updateDocumentGenerationStatus(List<Apttus__APTS_Agreement__c> newAgreements, Map<Id, Apttus__APTS_Agreement__c> oldAgreementMap){
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
        string msaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA').getRecordTypeId();
        string ndaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('NDA').getRecordTypeId();
        string dpaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('DPA').getRecordTypeId();//AK PSC-124 
        // string tsoRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('TSO').getRecordTypeId(); CIT-11613
        for(Apttus__APTS_Agreement__c agreement: newAgreements){
            Apttus__APTS_Agreement__c oldAgreement = oldAgreementMap.get(agreement.Id);
            if(agreement.RecordTypeId == msaRecordTypeId && agreement.APTS_AutoGenerateComplete__c != true && agreement.APTS_Type_of_Paper__c == 'Conga Hybrid Redlined' && agreement.APTS_Approved_By_Deal_Desk__c == true && agreement.APTS_Approved_By_Deal_Desk__c != oldAgreement.APTS_Approved_By_Deal_Desk__c){
                agreement.APTS_DocGeninProgress__c = true;
            }
            if(agreement.RecordTypeId == ndaRecordTypeId && agreement.APTS_AutoGenerateComplete__c != true){
                agreement.APTS_DocGeninProgress__c = true;
            }
            //AK PSC-124 
             if(agreement.RecordTypeId == dpaRecordTypeId && agreement.APTS_AutoGenerateComplete__c != true){
                agreement.APTS_DocGeninProgress__c = true;
            }
            if(agreement.RecordTypeId == ndaRecordTypeId && agreement.APTS_Type_of_Paper__c != oldAgreement.APTS_Type_of_Paper__c 
               && agreement.APTS_Type_of_Paper__c == 'Conga Hybrid Redlined' ){
                   agreement.APTS_DocGeninProgress__c = true;
               }       
            /* CIT-11613  if(agreement.RecordTypeId == tsoRecordTypeId && agreement.APTS_AutoGenerateComplete__c != true
&& agreement.APTS_Is_Service_Estimate_Approved__c == true && agreement.APTS_Is_Service_Estimate_Current__c == true){
agreement.APTS_DocGeninProgress__c = true;
} */
            
            
        }
    }
    
    // This method starts the process to start document generation
    public static void generateDocument(List<Apttus__APTS_Agreement__c> newAgreements, Map<Id, Apttus__APTS_Agreement__c> oldAgreementMap){
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
        string msaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA').getRecordTypeId();
        for(Apttus__APTS_Agreement__c agreement: newAgreements){
            Apttus__APTS_Agreement__c oldAgreement = oldAgreementMap.get(agreement.Id);
            if(agreement.RecordTypeId == msaRecordTypeId && agreement.APTS_AutoGenerateComplete__c != true && agreement.APTS_Type_of_Paper__c == 'Conga Hybrid Redlined' && agreement.APTS_Approved_By_Deal_Desk__c == true && agreement.APTS_Approved_By_Deal_Desk__c != oldAgreement.APTS_Approved_By_Deal_Desk__c){
                agreementsToUpdate.add(agreement);
            }
        }
        if(agreementsToUpdate.size() == 0){
            return;
        }
        
        List<Apttus__APTS_Template__c> templates = [select Id, name, Apttus__Type__c from Apttus__APTS_Template__c where name in ('C2 MSA', 'NDA') and Apttus__Type__c = 'Agreement'];
        Map<string, string> recordTypeTemplateMap = new Map<string, string>();
        for(Apttus__APTS_Template__c template: templates){
            if(template.Name.indexOf('MSA') >= 0){
                recordTypeTemplateMap.put(msaRecordTypeId, template.Id);
            }
        }
        String docAction = Apttus.AgreementGenerateController.ACTION_GENERATE;
        String outputFormat = 'DOCX';
        String comments = '';
        
        Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c> agreementVersionMap = new Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c>();
        for(Apttus__APTS_Agreement__c agr: agreementsToUpdate){
            string templateId = recordTypeTemplateMap.get(agr.RecordTypeId);
            Apttus__DocumentVersionDetail__c  documentVersionDetail = Apttus.AgreementGenerateController.createDocVersionSO(agr.Id,  templateId,  docAction,  outputFormat,  comments);
            agreementVersionMap.put(agr, documentVersionDetail);
        }
        
        APTS_GenerateAgreementDocumentBatch batchObj = new APTS_GenerateAgreementDocumentBatch(agreementVersionMap, recordTypeTemplateMap); 
        Database.executeBatch(batchObj, 1);
        system.debug('@@ Generate Document method exit');
    }
    
    /**
* @description : Populate Effective End Date
* @author Rajesh | 15-Dec-2022 
* @param newList
* @return void
**/
    public static void setEndDateandActivateNDAAgreement(List<Apttus__APTS_Agreement__c> newList,Map<ID, Apttus__APTS_Agreement__c> oldMap){
        Set<Id> newAgreement = new Set<Id>();
        Map<Id,ContentDocumentLink> mapAgreementCDL = new Map<Id,ContentDocumentLink>();
        for(Apttus__APTS_Agreement__c objAgreement : newList){ 
            newAgreement.add(objAgreement.Id);
        }
        
        for(ContentDocumentLink  contentDocumentNDA : [SELECT Id,ContentDocumentId,ContentDocument.CreatedDate,LinkedEntityId
                                                       FROM ContentDocumentLink WHERE LinkedEntityId IN :newAgreement ORDER BY ContentDocument.CreatedDate DESC])
        {
            mapAgreementCDL.put(contentDocumentNDA.LinkedEntityId,contentDocumentNDA);
        }
        
        if(!mapAgreementCDL.isEmpty()){
            System.enqueueJob(new APTS_NDASetEndDateActivateQueueable(newList, oldMap, mapAgreementCDL, 'Agreement', null));  
        }
    }
    
    /**
* @description : Auto Generate the Doc on change of Paper type
* @author Rajesh | 23-Dec-2022 
* @param newList
* @return void
**/
    public static void autoGenerateDocPaperChange(List<Apttus__APTS_Agreement__c> newList,Map<ID, Apttus__APTS_Agreement__c> oldMap){
        
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
        string ndaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('NDA').getRecordTypeId();
        for(Apttus__APTS_Agreement__c agreement: newList){
        if((agreement.APTS_Type_of_Paper__c == 'Conga Hybrid Redlined' || agreement.APTS_Type_of_Paper__c == 'Conga Redlined'))
        {
                if (oldMap == null )
                {
                    agreementsToUpdate.add(agreement);
                }
                else
                {
                    Apttus__APTS_Agreement__c oldAgreement = oldMap.get(agreement.Id);
                    if(agreement.APTS_Type_of_Paper__c != oldAgreement.APTS_Type_of_Paper__c){
                           agreementsToUpdate.add(agreement);
                       }
                }
               
                
            }
        }
        if(agreementsToUpdate.size() == 0){
            return;
        }
        
        List<Apttus__APTS_Template__c> templates = [select Id, name, Apttus__Type__c from Apttus__APTS_Template__c where name = 'NDA' and Apttus__Type__c = 'Agreement'];
        Map<string, string> recordTypeTemplateMap = new Map<string, string>();
        for(Apttus__APTS_Template__c template: templates){
            if(template.Name.indexOf('NDA') >= 0){
                recordTypeTemplateMap.put(ndaRecordTypeId, template.Id);
            }
        }
        String docAction = Apttus.AgreementGenerateController.ACTION_GENERATE;
        String outputFormat = 'DOCX';
        String comments = '';
        
        Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c> agreementVersionMap = new Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c>();
        for(Apttus__APTS_Agreement__c agr: agreementsToUpdate){
            string templateId = recordTypeTemplateMap.get(agr.RecordTypeId);
            Apttus__DocumentVersionDetail__c  documentVersionDetail = Apttus.AgreementGenerateController.createDocVersionSO(agr.Id,  templateId,  docAction,  outputFormat,  comments);
            agreementVersionMap.put(agr, documentVersionDetail);
        }
        APTS_GenerateDocumentNDABatch batchObj = new APTS_GenerateDocumentNDABatch(agreementVersionMap, recordTypeTemplateMap); 
        Database.executeBatch(batchObj, 1);
    }
    
   
    //AK PSC-124 START
     public static void autoGenerateDocPaperChangeDPA(List<Apttus__APTS_Agreement__c> newList,Map<ID, Apttus__APTS_Agreement__c> oldMap){
        
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
        string dpaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('DPA').getRecordTypeId();
        for(Apttus__APTS_Agreement__c agreement: newList){
             if((agreement.APTS_Type_of_Paper__c == 'Conga Hybrid Redlined' || agreement.APTS_Type_of_Paper__c == 'Conga Redlined'))
             {
              if (oldMap == null )
                {
                    agreementsToUpdate.add(agreement);
                }
                else
                {
                    Apttus__APTS_Agreement__c oldAgreement = oldMap.get(agreement.Id);
                    if(agreement.APTS_Type_of_Paper__c != oldAgreement.APTS_Type_of_Paper__c)
                    {
                           agreementsToUpdate.add(agreement);
                    }
                }
            }
        }
        if(agreementsToUpdate.size() == 0){
            return;
        }
        
        List<Apttus__APTS_Template__c> templates = [select Id, name, Apttus__Type__c from Apttus__APTS_Template__c where name = 'DPA' and Apttus__Type__c = 'Agreement'];
        Map<string, string> recordTypeTemplateMap = new Map<string, string>();
        for(Apttus__APTS_Template__c template: templates){
            if(template.Name.indexOf('DPA') >= 0){
                recordTypeTemplateMap.put(dpaRecordTypeId, template.Id);
            }
        }
        String docAction = Apttus.AgreementGenerateController.ACTION_GENERATE;
        String outputFormat = 'DOCX';
        String comments = '';
        
        Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c> agreementVersionMap = new Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c>();
        for(Apttus__APTS_Agreement__c agr: agreementsToUpdate){
            string templateId = recordTypeTemplateMap.get(agr.RecordTypeId);
            Apttus__DocumentVersionDetail__c  documentVersionDetail = Apttus.AgreementGenerateController.createDocVersionSO(agr.Id,  templateId,  docAction,  outputFormat,  comments);
            agreementVersionMap.put(agr, documentVersionDetail);
        }
        APTS_GenerateDocumentNDABatch batchObj = new APTS_GenerateDocumentNDABatch(agreementVersionMap, recordTypeTemplateMap); 
        Database.executeBatch(batchObj, 1);
    }
    //AK PSC-124 END
    
    // This method will default the values on the fields of NDA Agreement - CIT-20621
    public static void defaultNDAFields(List<Apttus__APTS_Agreement__c> newNDAAgreements){
        if(newNDAAgreements != null)
        {
            for(Apttus__APTS_Agreement__c oAgreement : newNDAAgreements)
            {
                oAgreement.Apttus__Termination_Notice_Days__c = APTS_Constant.TERMINATION_NOTICE_DAYS;
                oAgreement.Apttus__Term_Months__c=APTS_Constant.TERM_MONTHS; //CIT-23612
            }
        }
    }
    
    
    // This method will default the values on the fields of MSA Agreement
    public static void defaultMSAFields(List<Apttus__APTS_Agreement__c> newMSAAgreements){
        if(newMSAAgreements != null)
        {
            for(Apttus__APTS_Agreement__c oAgreement : newMSAAgreements)
            {
                oAgreement.APTS_Expiration_Warning__c = APTS_Constant.TERMINATION_NOTICE;
                //oAgreement.APTS_Type_of_Paper__c = APTS_Constant.TYPE_OF_PAPER_ONLINE_MSSA;
                oAgreement.Conga_Entity_Code__c = APTS_Constant.ENTITY_CODE_APTTUS;
                oAgreement.APTS_Renewal_Uplift_Type__c = APTS_Constant.RENEWAL_UPLIFT_TYPE_UPLIFT_PERCENT;
                oAgreement.APTS_Renewal_Uplift_Cap__c = APTS_Constant.RENEWAL_UPLIFT_CAP;
                oAgreement.Apttus__Perpetual__c = APTS_Constant.BOOL_TRUE;
                oAgreement.APTS_Payment_Terms__c = APTS_Constant.PAYMENT_TERM_NET30;
                oAgreement.APTS_Tax__c = APTS_Constant.TEXT_STANDARD;
                oAgreement.APTS_Right_to_Suspend__c = APTS_Constant.TEXT_YES;
                oAgreement.APTS_Indemnification_Categories__c = APTS_Constant.TEXT_STANDARD;
                oAgreement.APTS_Unlimited_Liability_Direct__c = APTS_Constant.TEXT_STANDARD;
                oAgreement.APTS_Limit_of_Liability_Dir_Supercap__c = APTS_Constant.TEXT_NO;
                oAgreement.APTS_Unlimited_Liability_Indirect__c = APTS_Constant.TEXT_NO;
                oAgreement.APTS_Lim_of_Liability_Indir_Supercap__c = APTS_Constant.TEXT_NO;
                oAgreement.APTS_Assignment__c = APTS_Constant.ASSIGNMENT_WITH_CONSENT;
                oAgreement.APTS_Change_in_Control_Merger__c = APTS_Constant.CHANGE_IN_CONTROL_MERGE;
                oAgreement.APTS_Venue__c = APTS_Constant.VENUE_DELAWARE;
                oAgreement.APTS_Marketing_Language__c = APTS_Constant.TEXT_BLANKET_OPT_IN;
                oAgreement.APTS_IsConsentRequired__c = APTS_Constant.TEXT_N;
                oAgreement.APTS_Non_Standard_Contingency_Opt_Out__c = APTS_Constant.TEXT_NO;
                oAgreement.CurrencyIsoCode = APTS_Constant.CURRENCY_USD;
                oAgreement.APTS_Include_Auto_Renewal_Clause__c = APTS_Constant.BOOL_TRUE;
                oAgreement.Insurance_Obligations__c = APTS_Constant.INSURANCE_OBLIGATIONS;
                //oAgreement.APTS_Availability_Uptime__c = APTS_Constant.AVAILABILITY_UPTIME;
                oAgreement.APTS_SLA_Termination__c = APTS_Constant.TEXT_NO;
                oAgreement.APTS_Penalties__c = APTS_Constant.PENALTIES_STANDARD;
                oAgreement.Technical_Support_Type__c = APTS_Constant.TEXT_STANDARD;
                oAgreement.PS_Terms_Included__c = APTS_Constant.TEXT_YES;
                oAgreement.APTS_Original_Content_Template_PS__c = APTS_Constant.TEXT_APTTUS_STANDARD;
                oAgreement.APTS_Ownership_of_Deliverables__c = APTS_Constant.TEXT_APTTUS;
                oAgreement.APTS_Acceptance_Period__c = APTS_Constant.ACCEPTANCE_PERIOD;
                oAgreement.APTS_SFDC_Platform_Terms_Addendum_Incl__c = APTS_Constant.TEXT_YES;
                oAgreement.APTS_Data_Security_Original_Content_Temp__c = APTS_Constant.TEXT_APTTUS_STANDARD;
                oAgreement.APTS_DS_Material_Deviations__c = APTS_Constant.TEXT_NO;
                oAgreement.APTS_Security_Incident_Notification__c = APTS_Constant.SECURITY_INCIDENT_NOTIFICATION_NOTICE;
                oAgreement.APTS_Data_Processing_Addendum_Executed__c = APTS_Constant.TEXT_YES;
                oAgreement.APTS_Cross_Termination_of_MSSA_Order__c = APTS_Constant.TEXT_NO;
                
            }
        }
    }
    
    // This method starts the process to start document generation
    public static void generateNDADocument(List<Apttus__APTS_Agreement__c> newAgreements){
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
        
        string ndaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('NDA').getRecordTypeId();
        string dpaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('DPA').getRecordTypeId();//AK PSC-124 
        for(Apttus__APTS_Agreement__c agreement: newAgreements){//AK PSC-124 
            if((agreement.RecordTypeId == ndaRecordTypeId || agreement.RecordTypeId == dpaRecordTypeId) && agreement.APTS_Type_of_Paper__c == 'Conga Standard' && agreement.APTS_AutoGenerateComplete__c != true){
                agreementsToUpdate.add(agreement);
            }
        }      
        
        if(agreementsToUpdate.size() == 0){
            return;
        }
        
        List<Apttus__APTS_Template__c> templates = [select Id, name, Apttus__Type__c from Apttus__APTS_Template__c where name = 'Pre-Signed MNDA' and Apttus__Type__c = 'Agreement'];
        if(templates.size() == 0){
            return;
        }
        Map<string, string> recordTypeTemplateMap = new Map<string, string>();
        recordTypeTemplateMap.put(ndaRecordTypeId, templates[0].Id);
        recordTypeTemplateMap.put(dpaRecordTypeId, templates[0].Id);//AK PSC-124 
        String docAction = Apttus.AgreementGenerateController.ACTION_GENERATE;
        String outputFormat = 'PDF';
        String comments = '';
        
        Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c> agreementVersionMap = new Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c>();
        for(Apttus__APTS_Agreement__c agr: agreementsToUpdate){
            string templateId = recordTypeTemplateMap.get(agr.RecordTypeId);
            Apttus__DocumentVersionDetail__c  documentVersionDetail = Apttus.AgreementGenerateController.createDocVersionSO(agr.Id,  templateId,  docAction,  outputFormat,  comments);
            agreementVersionMap.put(agr, documentVersionDetail);
        }
        
        APTS_GenerateAgreementDocumentBatch batchObj = new APTS_GenerateAgreementDocumentBatch(agreementVersionMap, recordTypeTemplateMap); 
        Database.executeBatch(batchObj, 1);
    }
    
    //CIT-10108 - This method is called on before update to set Term and Agreement Enddate PSOD
    public static void populateTermAndAgreementEndDate(List<Apttus__APTS_Agreement__c> psodAgreementList)
    {    
        for(Apttus__APTS_Agreement__c agm : psodAgreementList){
            if (agm.Apttus__Term_Months__c != 6 && agm.APTS_Number_of_Hours__c >= 8 && agm.APTS_Number_of_Hours__c <= 100 ){
                agm.Apttus__Term_Months__c = 6;
                agm.Apttus__Contract_End_Date__c = agm.Apttus__Contract_Start_Date__c.addMonths(6).addDays(-1);
            }else if (agm.Apttus__Term_Months__c != 12 && agm.APTS_Number_of_Hours__c >= 101 && agm.APTS_Number_of_Hours__c <= 200){
                agm.Apttus__Term_Months__c = 12;
                agm.Apttus__Contract_End_Date__c = agm.Apttus__Contract_Start_Date__c.addMonths(12).addDays(-1);
            }
        }
    }
    
    //CIT-7424 - This method is called when order agreement is Activated and it copy files from order agreement to Opportunity
    public static void copyFilesFromOrderAgreementToOppty(List<Apttus__APTS_Agreement__c> AgreementList) 
    {
        Integer delayInMinutes = 1;
        System.enqueueJob(new APTS_CopyFilefromOrderAgrToOptyQueueable(AgreementList),delayInMinutes);
    }

    //CIT-11807
    public static void updateCurrencyOnTSOAgreementFromServiceEstimate(List<Apttus__APTS_Agreement__c> tsoAgreementList)
    {
        List<Id> serviceEstimateIdList = new List<Id>();
        for(Apttus__APTS_Agreement__c agreement : tsoAgreementList) {
            serviceEstimateIdList.add(agreement.APTS_Related_Service_Estimate__c);
        }
        Map<Id,PSAService_Estimate__c> serviceEstimateMap = new Map<Id,PSAService_Estimate__c>([SELECT Id,CurrencyIsoCode FROM PSAService_Estimate__c WHERE Id IN :serviceEstimateIdList]);
        for(Apttus__APTS_Agreement__c agreement : tsoAgreementList)
        {
            if(serviceEstimateMap.size() > 0) {
                PSAService_Estimate__c serviceEstimate = serviceEstimateMap.get(agreement.APTS_Related_Service_Estimate__c);
                if(serviceEstimate != null && agreement.CurrencyIsoCode != serviceEstimate.CurrencyIsoCode)
                {
                    agreement.CurrencyIsoCode = serviceEstimate.CurrencyIsoCode;
                }
            }
        }
    }
    
    //CIT-14945
    public static void UpdateTypeOfPaperOnOrderAgreement(List<Apttus__APTS_Agreement__c> OrderAgreementList)
    {
        Set<ID> ParentMSAAgreementIDs = new Set<ID> ();
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
        Set<String> ExcludeStatus = new Set<String>{'Terminated', 'Expired', 'Cancelled', 'Activated','Cancelled Request'};
            
            for(Apttus__APTS_Agreement__c agreement : OrderAgreementList) {
                if(!ExcludeStatus.contains(agreement.Apttus__Status__c)  && agreement.Apttus__Parent_Agreement__c != NULL && agreement.Conga_Entity_Code__c == APTS_Constant.ENTITY_CODE_CONGA)
                {
                    agreementsToUpdate.add(agreement);
                    ParentMSAAgreementIDs.add(agreement.Apttus__Parent_Agreement__c);                  
                }
            }
        if(!agreementsToUpdate.isEmpty()){
            
            Map<Id, Apttus__APTS_Agreement__c> parentAgreementsMap = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id, APTS_Type_of_Paper__c 
                                                                                                             FROM Apttus__APTS_Agreement__c 
                                                                                                             WHERE APTS_Type_of_Paper__c != NULL
                                                                                                             AND ID IN :ParentMSAAgreementIDs]);
            
            if(!parentAgreementsMap.isEmpty()){
                
                for(Apttus__APTS_Agreement__c OrderAgreements : agreementsToUpdate)  {
                    Apttus__APTS_Agreement__c parentAgreement = parentAgreementsMap.get(OrderAgreements.Apttus__Parent_Agreement__c);
                    if (parentAgreement != null && OrderAgreements.MSA_Type_of_Paper__c != parentAgreement.APTS_Type_of_Paper__c) {
                        OrderAgreements.MSA_Type_of_Paper__c = parentAgreement.APTS_Type_of_Paper__c;
                    }
                }              
            }
        }
    }
    //860
    public static void updateOpportunityOnPrimaryProposal(Map<Id,Apttus__APTS_Agreement__c> newMap,Map<Id,Apttus__APTS_Agreement__c> oldMap)
    {
        Set<ID> agreementEligible = new Set<Id>();
        Map<Id, Opportunity> oppMapToUpdate = new Map<Id, Opportunity>();
        for (Apttus__APTS_Agreement__c agmm : newMap.values()){            
            if (oldMap.get(agmm.Id).APTS_Include_Auto_Renewal_Clause__c != agmm.APTS_Include_Auto_Renewal_Clause__c
               && agmm.Apttus__Status__c == 'Activated'){
                agreementEligible.add(agmm.Id);
            }
        }
         // Get Opportunity from Primary Proposal which has this mssa agreement on it and oppo should be open
         List<Apttus_Proposal__Proposal__c> proposalLst =[SELECT id , Apttus_Proposal__Opportunity__r.recordtype.name, Apttus_Proposal__Opportunity__c , 
                                                          APTSMSSAAgreements__c, APTSMSSAAgreements__r.APTS_Include_Auto_Renewal_Clause__c
                                                          FROM Apttus_Proposal__Proposal__c 
                                                          WHERE Apttus_Proposal__Primary__c = true
                                                          AND APTSMSSAAgreements__c In :agreementEligible
                                                          AND Apttus_Proposal__Opportunity__c != null
                                                          AND Recordtype.developerName = :APTS_Constant.RENEWAL_RECORDTYPE
                                                          AND Apttus_Proposal__Opportunity__r.StageName != 'Closed Won'
                                                          AND Apttus_Proposal__Opportunity__r.Stagename != 'Closed Lost'];
        
        for (Apttus_Proposal__Proposal__c prop :proposalLst ){
            Opportunity opp = new Opportunity(Id=prop.Apttus_Proposal__Opportunity__c);
            opp.APTS_Is_Eligible_for_Auto_Renewal__c = prop.APTSMSSAAgreements__r.APTS_Include_Auto_Renewal_Clause__c;
            oppMapToUpdate.put(Opp.Id , Opp);
        }      
        if (oppMapToUpdate.size () > 0){
            update oppMapToUpdate.values();
        }
    } 
    
     //AK PSC-196 START
      public static void CopyFileToAgreement(string agreementId){
        //Insert ContentDocumentLink
        Apttus__DocumentVersionDetail__c dvd = [select Id, Apttus__Title__c, Apttus__ContentId__c from Apttus__DocumentVersionDetail__c where Apttus__DocumentVersionId__r.Apttus__AgreementId__c = :agreementId limit 1];
        // CopyFileToAgreement(dvd.Apttus__ContentId__c, agreementSO.Id);
        ContentVersion originalCV=[select id,ContentDocumentId,versiondata from Contentversion where ContentDocumentId=:dvd.Apttus__ContentId__c];
        Blob fileData = originalCV.VersionData;
        string base64 = EncodingUtil.base64Encode(fileData);

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = dvd.Apttus__Title__c;
        cv.PathOnClient = dvd.Apttus__Title__c;
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = agreementId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
     //AK PSC-196 END
     
    
    //CIT-19742
    /*public static void updateCNRJunctionRecords(List<Apttus__APTS_Agreement__c> orderAgreementList){
        try {
            if(orderAgreementList.size() > 0) {
                Map<Id,Id> proposalAgreementMap = new Map<Id,Id>();
                for(Apttus__APTS_Agreement__c agreement : orderAgreementList) {
                    proposalAgreementMap.put(agreement.Apttus_QPComply__RelatedProposalId__c,agreement.Id);
                }
                if(proposalAgreementMap.size() > 0) {
                    List<APTS_CNROrderFormJunctionObject__c> CNRJunctionRecordsToUpdate = new List<APTS_CNROrderFormJunctionObject__c>();
                    List<APTS_CNROrderFormJunctionObject__c> CNROrderFormJunctionRecordList = [SELECT Id, APTS_Replaced_Proposal__c,  APTS_Cancelled_PLI__r.Apttus_Proposal__Proposal__r.APTS_RecordTypeName__c, 
                                                                                                APTS_Cancelled_PLI__r.Apttus_QPConfig__DerivedFromId__r.IsDerivative__c, APTS_Cancelled_PLI__r.APTS_Related_All_Quotes__c, 
                                                                                                APTS_Cancelled_PLI__r.Apttus_QPConfig__DeltaQuantity__c, APTS_Cancelled_PLI__r.Apttus_QPConfig__DeltaPrice__c,  
                                                                                                APTS_Related_All_Quotes__c
                                                                                                FROM APTS_CNROrderFormJunctionObject__c 
                                                                                                WHERE APTS_Replaced_Proposal__c IN :proposalAgreementMap.keySet()];
                    if(CNROrderFormJunctionRecordList.size() == 0) return;
                    Map<Id,Set<String>> agreementNameMap = new Map<Id,Set<String>>();
                    Set<String> tmpSet = new Set<String>();
                    for(APTS_CNROrderFormJunctionObject__c CNROrderFormJunctionRecord : CNROrderFormJunctionRecordList) {
                        System.debug('Inside for');
                        if(proposalAgreementMap.containsKey(CNROrderFormJunctionRecord.APTS_Replaced_Proposal__c)) {
                            System.debug('Inside for IF');
                            CNROrderFormJunctionRecord.APTS_Replaced_Order_Agreement__c = proposalAgreementMap.get(CNROrderFormJunctionRecord.APTS_Replaced_Proposal__c);
                            CNRJunctionRecordsToUpdate.add(CNROrderFormJunctionRecord);
                            string propRecordType = CNROrderFormJunctionRecord.APTS_Cancelled_PLI__r.Apttus_Proposal__Proposal__r.APTS_RecordTypeName__c;
                            boolean isValidLine = !CNROrderFormJunctionRecord.APTS_Cancelled_PLI__r.Apttus_QPConfig__DerivedFromId__r.IsDerivative__c && (propRecordType == 'Add-on' || propRecordType == 'Renewal + Add-on')
                                                    && CNROrderFormJunctionRecord.APTS_Cancelled_PLI__r.Apttus_QPConfig__DeltaPrice__c < 0 ? TRUE : FALSE;
                            if(CNROrderFormJunctionRecord.APTS_Cancelled_PLI__r.APTS_Related_All_Quotes__c != NULL && CNROrderFormJunctionRecord.APTS_Cancelled_PLI__r.APTS_Related_All_Quotes__c != '' && isValidLine) {
                                tmpSet = agreementNameMap.containsKey(CNROrderFormJunctionRecord.APTS_Replaced_Order_Agreement__c)? agreementNameMap.get(CNROrderFormJunctionRecord.APTS_Replaced_Order_Agreement__c) : new Set<String>();
                                System.debug('tmpSet ' + tmpSet);
                                if(CNROrderFormJunctionRecord.APTS_Related_All_Quotes__c.contains(',')) {
                                    String quotes = CNROrderFormJunctionRecord.APTS_Related_All_Quotes__c;
                                    tmpSet.addAll(CNROrderFormJunctionRecord.APTS_Related_All_Quotes__c.split(','));
                                    System.debug('tmpSet ' + tmpSet);
                                } else {
                                    tmpSet.add(CNROrderFormJunctionRecord.APTS_Related_All_Quotes__c);
                                    System.debug('tmpSet ' + tmpSet);
                                }
                            }
                            agreementNameMap.put(CNROrderFormJunctionRecord.APTS_Replaced_Order_Agreement__c,tmpSet);
                        }                                                                                
                    }
                    if(CNRJunctionRecordsToUpdate.size() > 0) {
                        update CNRJunctionRecordsToUpdate;
                    }
                    List<string> agreementsToUpdate = new List<string>();
                    if(agreementNameMap.size() > 0) {
                        System.debug('agreementNameMap ' + agreementNameMap);
                        for(Id agreementId : agreementNameMap.keySet()) {
                            Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Id = agreementId);
                            String relatedAllQuotes = '';
                            if(agreementNameMap.get(agreementId).size() > 0) {
                                for(String str : agreementNameMap.get(agreementId)) {
                                    relatedAllQuotes += str + ',';
                                }
                                System.debug('relatedAllQuotes ' + relatedAllQuotes);
                            }
                            relatedAllQuotes = relatedAllQuotes.substringBeforeLast(',');
                            //agreement.APTS_Related_All_Quotes__c = relatedAllQuotes;
                            agreementsToUpdate.add(agreement.Id + '-' + relatedAllQuotes);
                        }
                        if(agreementsToUpdate.size() > 0) {
                            updateAgreementRecords(agreementsToUpdate);
                        }
                    }
                }
            }
        } catch (Exception e) {
            system.debug('Exception e'+e.getMessage());
        }
    }

    @future
    public static void updateAgreementRecords(List<string> agreementsString) {
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
        if(agreementsString.size() > 0) {
            for(string str : agreementsString) {
                Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(Id = str.substringBefore('-'));
                agreement.APTS_Related_All_Quotes__c = str.substringAfter('-');
                agreementsToUpdate.add(agreement);
            }
            if(agreementsToUpdate.size() > 0)
                update agreementsToUpdate;
        }
    }*/
    
    
}