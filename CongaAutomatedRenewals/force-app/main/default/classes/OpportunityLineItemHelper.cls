/**
* @author Conga Services
* @date 20180611
* @version 1.00
* @description OpportunityLineItemHelper - Contains custom functionality for the OpportunityLineItem object
*/
public without sharing class OpportunityLineItemHelper {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// STATIC VARIABLES //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // OPP LINE ITEMS UPDATE QUEUE
    public static Map<Id, Opportunity> ParentOppsToUpdate {
    get {
        if(ParentOppsToUpdate == null){
            ParentOppsToUpdate = new Map<Id, Opportunity>();
        }
        return ParentOppsToUpdate;
    } set; }

    // PARENT OPPORTUNITY UPDATE QUEUE
    public static Map<Id, OpportunityLineItem> OppLineItemsToUpdate {
    get {
        if(OppLineItemsToUpdate == null){
            OppLineItemsToUpdate = new Map<Id, OpportunityLineItem>();
        }
        return OppLineItemsToUpdate;
    } set; }


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// TRIGGER / HELPER METHODS /////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /**
    * @author Conga Services, ERedding
    * @date 20190816
    * @description copyDataFromParentProduct - Copies various data down to the Opp Line Item from the parent Product
    *                                            --- EXECUTED BY OPPORTUNITY LINE ITEM BEFORE INSERT TRIGGER ---
    * @param List<OpportunityLineItem> newOrUpdatedOppItems - List of new OpportunityLineItem records
    * @return void
    */
    public static void copyDataFromParentProduct(List<OpportunityLineItem> newOrUpdatedOppItems){
        try{
            if(TriggerHelper.DoExecute('OpportunityLineItemHelper','copyDataFromParentProduct') && newOrUpdatedOppItems != null){
                
                // GET PARENT PRODUCT IDS
                Set<Id> parentProductIds = new Set<Id>();
                for(OpportunityLineItem newOrUpdatedOppItem : newOrUpdatedOppItems){
                    parentProductIds.add(newOrUpdatedOppItem.Product2Id);
                }

                // GET PARENT PRODUCTS
                Map<Id, Product2> parentProductMap = new Map<Id, Product2>([SELECT Id, Product_Line__c, FY16_Revenue_Type__c, Service_Event_MRR__c, Exclude_from_MRR__c 
                                                                            FROM Product2 WHERE Id IN :parentProductIds]);
        
                // POPULATE FIELDS ON NEW OPP ITEMS 
                for(OpportunityLineItem oppItem : newOrUpdatedOppItems){
                    if(parentProductMap.containsKey(oppItem.Product2Id)){
                        Product2 parentProduct = parentProductMap.get(oppItem.Product2Id);
                        oppItem.Product_Line__c = parentProduct.Product_Line__c;
                        oppItem.Revenue_Type__c = parentProduct.FY16_Revenue_Type__c;
                        oppItem.Service_Event_MRR__c = parentProduct.Service_Event_MRR__c;
                        oppItem.Exclude_from_MRR__c = parentProduct.Exclude_from_MRR__c;
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityLineItemHelper','copyDataFromParentProduct');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityLineItemHelper', 'copyDataFromParentProduct', newOrUpdatedOppItems, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20200415
    * @description overwriteCPQBlockPricingChanges - Copies over Quantity and Pricing changes that CPQ does for Block Price products
    *                                                   --- EXECUTED BY OPPORTUNITY LINE ITEM AFTER INSERT AND AFTER UPDATE TRIGGER ---
    * @param List<OpportunityLineItem> newOrUpdatedOppItems - List of new or updated OpportunityLineItem records
    * @param Map<Id, OpportunityLineItem> outdatedOppItems - List of outdated OpportunityLineItem records
    * @return void
    */
    public static void overwriteCPQBlockPricingChanges(List<OpportunityLineItem> newOrUpdatedOppItems, Map<Id, OpportunityLineItem> outdatedOppItems){
        try{
            if(TriggerHelper.DoExecute('OpportunityLineItemHelper','overwriteCPQBlockPricingChanges') && newOrUpdatedOppItems != null){

                // GET OPP ITEM IDS FROM ITEMS THAT ARE NEW OR HAVE A QUALIFYING CHANGE
                Set<Id> qualifiedOppItemIds = new Set<Id>();
                for(OpportunityLineItem newOrUpdatedOppItem : newOrUpdatedOppItems){
                    OpportunityLineItem outdatedOppItem = outdatedOppItems != null ? outdatedOppItems.get(newOrUpdatedOppItem.Id) : null;
                    if(newOrUpdatedOppItem.SBQQ__QuoteLine__c != null && (outdatedOppItem == null || newOrUpdatedOppItem.Quantity != outdatedOppItem.Quantity || 
                                                                                                     newOrUpdatedOppItem.UnitPrice != outdatedOppItem.UnitPrice || 
                                                                                                     newOrUpdatedOppItem.TotalPrice != outdatedOppItem.TotalPrice)){
                        // NEW OPP ITEM OR UPDATED OPP ITEM WITH QUALIFYING CHANGE
                        qualifiedOppItemIds.add(newOrUpdatedOppItem.Id);
                    }
                }

                if(!qualifiedOppItemIds.isEmpty()){
                    // POPULATE FIELDS ON NEW OPP ITEMS
                    List<OpportunityLineItem> oppItemsToUpdate = new List<OpportunityLineItem>();
                    for(OpportunityLineItem oppItem : [SELECT Id, Quantity, UnitPrice, TotalPrice, SBQQ__QuoteLine__r.SBQQ__Quantity__c, SBQQ__QuoteLine__r.SBQQ__NetTotal__c
                                                       FROM OpportunityLineItem WHERE Id IN :qualifiedOppItemIds 
                                                                                AND SBQQ__QuoteLine__r.SBQQ__PricingMethod__c = 'Block'
                                                                                AND SBQQ__QuoteLine__r.SBQQ__Quantity__c > 0]){

                        if(oppItem.Quantity != oppItem.SBQQ__QuoteLine__r.SBQQ__Quantity__c || oppItem.UnitPrice != (oppItem.SBQQ__QuoteLine__r.SBQQ__NetTotal__c / oppItem.SBQQ__QuoteLine__r.SBQQ__Quantity__c) ||
                            oppItem.TotalPrice != oppItem.SBQQ__QuoteLine__r.SBQQ__NetTotal__c){
                        
                            oppItem.Quantity = oppItem.SBQQ__QuoteLine__r.SBQQ__Quantity__c;
                            oppItem.TotalPrice = oppItem.SBQQ__QuoteLine__r.SBQQ__NetTotal__c;
                            oppItemsToUpdate.add(oppItem);
                        }
                    }

                    // QUEUE ITEMS FOR UPDATE
                    if(!oppItemsToUpdate.isEmpty()){
                        for(OpportunityLineItem oppItem : oppItemsToUpdate){
                            if(OppLineItemsToUpdate.containsKey(oppItem.Id)){
                                OppLineItemsToUpdate.get(oppItem.Id).Quantity = oppItem.Quantity;
                                OppLineItemsToUpdate.get(oppItem.Id).TotalPrice = oppItem.TotalPrice;
                            }
                            else{
                                OppLineItemsToUpdate.put(oppItem.Id, oppItem); 
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityLineItemHelper','overwriteCPQBlockPricingChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityLineItemHelper', 'overwriteCPQBlockPricingChanges', newOrUpdatedOppItems, ex, true);
        }
    }

    /**
    * @author Conga Services, DNelson, ERedding
    * @date 20181025
    * @description updateProductSegmentation - Update field to CLM if opportunity product family is Contract Lifecycle Management or Novatus Contracts.
    *                                           --- EXECUTED FROM OPPORTUNITY LINE ITEM AFTER INSERT AND AFTER DELETE TRIGGERS ---
    * @param List<OpportunityLineItem> newOrDeletedOppItems - New or Deleted Opp Item records
    * @return void
    */
    public static void updateProductSegmentation(List<OpportunityLineItem> newOrDeletedOppItems){
        try{
            if(TriggerHelper.DoExecute('OpportunityLineItemHelper','updateProductSegmentation') && newOrDeletedOppItems != null){
                // SET OF APPLICABLE CLM PRODUCT FAMILIES
                Set<String> clmProductFamilies = new Set<String>{ 'Contract Lifecycle Management', 'Novatus Contracts' };

                // GET PARENT OPP IDS FROM QUALIFYING OPP ITEMS
                Set<Id> parentOppIds = new Set<Id>();
                for(OpportunityLineItem newOrDeletedOppItem : newOrDeletedOppItems) {
                    if(clmProductFamilies.contains(newOrDeletedOppItem.Product_Family__c)){
                        parentOppIds.add(newOrDeletedOppItem.OpportunityId);
                    }
                }

                if(!parentOppIds.isEmpty()){
                    // CREATE MAP OF OPPS AND DEFAULT PRODUCT SEGMENTATION TO BLANK
                    Map<Id, Opportunity> oppProductSegValues = new Map<Id, Opportunity>();
                    for(Id oppId : parentOppIds){
                        oppProductSegValues.put(oppId, new Opportunity(Id = oppId, Product_Segmentation__c = ''));
                    }

                    // LOOP OVER ALL OPP ITEMS FOR OPPS AND SET PRODUCT SEGMENTATION VALUES
                    for(OpportunityLineItem oppItem : [SELECT Id, OpportunityId, Product_Family__c FROM OpportunityLineItem WHERE OpportunityId IN :parentOppIds]){
                        if(oppProductSegValues.containsKey(oppItem.OpportunityId) && clmProductFamilies.contains(oppItem.Product_Family__c)){
                            oppProductSegValues.get(oppItem.OpportunityId).Product_Segmentation__c = 'CLM';
                        }
                    }

                    // QUEUE OPPS FOR UPDATE
                    for(Opportunity opp : oppProductSegValues.values()){
                        if(ParentOppsToUpdate.containsKey(opp.Id)){
                            ParentOppsToUpdate.get(opp.Id).Product_Segmentation__c = opp.Product_Segmentation__c;
                        }
                        else{
                            ParentOppsToUpdate.put(opp.Id, opp); 
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityLineItemHelper','updateProductSegmentation');
            }
        }       
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityLineItemHelper', 'updateProductSegmentation', newOrDeletedOppItems, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181017
    * @description updateServiceProdEndDates - Finds new OpportunityLineItems with Quote Lines and populates the ServiceDate and Product_End_Date__c from the Quote Line
    *                                           --- EXECUTED FROM OPPORTUNITY LINE ITEM BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<OpportunityLineItem> newOrUpdatedItems - New or updated Opp Item records
    * @param Map<Id, OpportunityLineItem> outdatedItems - Outdated Opp Item records
    * @return void
    */
    public static void updateServiceProdEndDates(List<OpportunityLineItem> newOrUpdatedItems, Map<Id, OpportunityLineItem> outdatedItems){
        try{
            if(TriggerHelper.DoExecute('OpportunityLineItemHelper','updateServiceProdEndDates') && newOrUpdatedItems != null){
                // GET PARENT OPP IDS AND OPP ITEM IDS FROM ITEMS THAT ARE NEW OR HAVE A QUALIFYING CHANGE
                Set<Id> parentQuoteLineIds = new Set<Id>();
                List<OpportunityLineItem> qualifiedOppItems = new List<OpportunityLineItem>();
                for(OpportunityLineItem newOrUpdatedItem : newOrUpdatedItems){
                    OpportunityLineItem outdatedItem = outdatedItems != null ? outdatedItems.get(newOrUpdatedItem.Id) : null;
                    if(outdatedItem == null || (outdatedItem != null && newOrUpdatedItem.SBQQ__QuoteLine__c != null && newOrUpdatedItem.SBQQ__QuoteLine__c != outdatedItem.SBQQ__QuoteLine__c)){
                        // NEW OPP ITEM OR UPDATED OPP ITEM WITH QUALIFYING CHANGE
                        qualifiedOppItems.add(newOrUpdatedItem);
                        parentQuoteLineIds.add(newOrUpdatedItem.SBQQ__QuoteLine__c);
                    }
                }

                if(!qualifiedOppItems.isEmpty()){
                    // GET PARENT QUOTE LINES
                    Map<Id, SBQQ__QuoteLine__c> parentQuoteLines = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, Opp_Item_Start_Date__c, Opp_Item_End_Date__c FROM SBQQ__QuoteLine__c 
                                                                                                    WHERE Id IN :parentQuoteLineIds]);

                    // POPULATE OPP ITEM SERVICE AND PRODUCT END DATES
                    for(OpportunityLineItem qualifiedOppItem : qualifiedOppItems){
                        if(parentQuoteLines.containsKey(qualifiedOppItem.SBQQ__QuoteLine__c)){
                            qualifiedOppItem.ServiceDate = parentQuoteLines.get(qualifiedOppItem.SBQQ__QuoteLine__c).Opp_Item_Start_Date__c;
                            qualifiedOppItem.Product_End_Date__c = parentQuoteLines.get(qualifiedOppItem.SBQQ__QuoteLine__c).Opp_Item_End_Date__c;
                            qualifiedOppItem.Leap_Year_Day__c = UtilityClass.checkRangeForLeapYear(qualifiedOppItem.ServiceDate, qualifiedOppItem.Product_End_Date__c);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityLineItemHelper','updateServiceProdEndDates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityLineItemHelper', 'updateServiceProdEndDates', newOrUpdatedItems, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181017
    * @description updateMRRDates - Finds OpportunityLineItems with qualifying changes that require an update to MRR Start and MRR End fields
    *                                   --- EXECUTED FROM OPPORTUNITY LINE ITEM BEFORE INSERT, BEFORE UPDATE, AND AFTER DELETE TRIGGERS ---
    * @param List<OpportunityLineItem> newOrUpdatedItems - New or updated Opp Item records
    * @param Map<Id, OpportunityLineItem> outdatedOrDeletedItems - Outdated or deleted Opp Item records
    * @return void
    */
    public static void updateMRRDates(List<OpportunityLineItem> newOrUpdatedItems, Map<Id, OpportunityLineItem> outdatedOrDeletedItems){
        try{
            if(TriggerHelper.DoExecute('OpportunityLineItemHelper','updateMRRDates')){
                // GET PARENT OPP IDS, PARENT PRODUCT IDS, AND OPP ITEM IDS FROM ITEMS THAT ARE NEW OR HAVE A QUALIFYING CHANGE
                Set<Id> parentOppIds = new Set<Id>();
                Set<Id> parentPricebookEntryIds = new Set<Id>();                
                List<OpportunityLineItem> qualifiedOppItems = new List<OpportunityLineItem>();
                Boolean itemsDeleted = false;

                // GET DATA FROM NEW OR UPDATED ITEMS
                if(newOrUpdatedItems != null){
                    for(OpportunityLineItem newOrUpdatedItem : newOrUpdatedItems){
                        OpportunityLineItem outdatedItem = outdatedOrDeletedItems != null && outdatedOrDeletedItems.containsKey(newOrUpdatedItem.Id) ? outdatedOrDeletedItems.get(newOrUpdatedItem.Id) : null;
                        if(outdatedItem == null || (outdatedItem != null && (newOrUpdatedItem.ServiceDate != outdatedItem.ServiceDate || 
                                                                             newOrUpdatedItem.Product_End_Date__c != outdatedItem.Product_End_Date__c ||
                                                                                (newOrUpdatedItem.SBQQ__QuoteLine__c != null && 
                                                                                 newOrUpdatedItem.SBQQ__QuoteLine__c != outdatedItem.SBQQ__QuoteLine__c)))){
                            // NEW OPP ITEM OR UPDATED OPP ITEM WITH QUALIFYING CHANGE
                            qualifiedOppItems.add(newOrUpdatedItem);
                            parentOppIds.add(newOrUpdatedItem.OpportunityId);
                            parentPricebookEntryIds.add(newOrUpdatedItem.PricebookEntryId);
                        }
                    }
                }
                // GET DATA FROM DELETED ITEMS
                else if(outdatedOrDeletedItems != null){
                    itemsDeleted = true;
                    for(OpportunityLineItem outdatedItem : outdatedOrDeletedItems.values()){
                        parentOppIds.add(outdatedItem.OpportunityId);
                    }
                }

                if(!parentOppIds.isEmpty()){

                    // CREATE WRAPPER CLASSES AND FIND MIN AND MAX FROM ANY OPP ITEMS NOT IN TRIGGER DATA SET
                    Map<Id, MRRDates> datesByOpp = new Map<Id, MRRDates>();
                    List<OpportunityLineItem> outsideOppItems = new List<OpportunityLineItem>();
                    for(OpportunityLineItem outsideOppItem : [SELECT Id, OpportunityId, ServiceDate, Product_End_Date__c, MRR_Start_Date__c, MRR_End_Date__c, 
                                                              PricebookEntry.Product2.FY16_Revenue_Type__c, PricebookEntry.Product2.Exclude_from_MRR__c
                                                              FROM OpportunityLineItem WHERE OpportunityId IN :parentOppIds AND Id NOT IN :qualifiedOppItems]){
                        outsideOppItems.add(outsideOppItem);
                        if(outsideOppItem.PricebookEntry.Product2.FY16_Revenue_Type__c == 'Recurring' && !outsideOppItem.PricebookEntry.Product2.Exclude_from_MRR__c){
                            if(datesByOpp.containsKey(outsideOppItem.OpportunityId)){
                                MRRDates mrrDates = datesByOpp.get(outsideOppItem.OpportunityId);
                                // COMPARE MIN AND UPDATE IF NECESSARY
                                if(outsideOppItem.ServiceDate != null && (mrrDates.MRRStart == null || outsideOppItem.ServiceDate < mrrDates.MRRStart)){
                                    mrrDates.MRRStart = outsideOppItem.ServiceDate;
                                }
                                // COMPARE MAX AND UPDATE IF NECESSARY
                                if(outsideOppItem.Product_End_Date__c != null && (mrrDates.MRREnd == null || outsideOppItem.Product_End_Date__c > mrrDates.MRREnd)){
                                    mrrDates.MRREnd = outsideOppItem.Product_End_Date__c;
                                }
                            }
                            else{
                                // WRAPPER NOT CREATED YET FOR THIS OPP, CREATE
                                datesByOpp.put(outsideOppItem.OpportunityId, new MRRDates(outsideOppItem.ServiceDate, outsideOppItem.Product_End_Date__c));
                            }
                        }
                    }

                    if(!itemsDeleted){ // LOGIC ONLY FOR NEW OR UPDATED RECORDS, SKIP CODE IF EXECUTED FROM DELETE TRIGGER
                        
                        // GET PARENT PRICEBOOK ENTRIES
                        Map<Id, PricebookEntry> parentPricebookEntryMap = new Map<Id, PricebookEntry>([SELECT Id, Product2.FY16_Revenue_Type__c, Product2.Exclude_from_MRR__c FROM PricebookEntry
                                                                                                       WHERE Id IN :parentPricebookEntryIds]);

                        // CREATE/UPDATE WRAPPER CLASSES WITH DATES FROM RECURRING OPP ITEMS IN TRIGGER DATA SET
                        for(OpportunityLineItem oppItem : qualifiedOppItems){
                            PricebookEntry priceEntry = parentPricebookEntryMap.get(oppItem.PricebookEntryId);

                            if(priceEntry.Product2.FY16_Revenue_Type__c == 'Recurring' && !priceEntry.Product2.Exclude_from_MRR__c){
                                if(datesByOpp.containsKey(oppItem.OpportunityId)){
                                    MRRDates mrrDates = datesByOpp.get(oppItem.OpportunityId);
                                    // UPDATE START DATE
                                    if(oppItem.ServiceDate != null && (mrrDates.MRRStart == null || oppItem.ServiceDate < mrrDates.MRRStart)){
                                        mrrDates.MRRStart = oppItem.ServiceDate;
                                    }
                                    // UPDATE END DATE
                                    if(oppItem.Product_End_Date__c != null && (mrrDates.MRREnd == null || oppItem.Product_End_Date__c > mrrDates.MRREnd)){
                                        mrrDates.MRREnd = oppItem.Product_End_Date__c;
                                    }
                                }
                                else{
                                    // NO DATA LOADED FROM OUTSIDE RECORDS, CREATE WRAPPER
                                    datesByOpp.put(oppItem.OpportunityId, new MRRDates(oppItem.ServiceDate, oppItem.Product_End_Date__c));
                                }
                            }
                        }

                        // UPDATE ITEMS IN TRIGGER DATA SET
                        for(OpportunityLineItem oppItem : qualifiedOppItems){
                            if(datesByOpp.containsKey(oppItem.OpportunityId)){
                                MRRDates mrrDates = datesByOpp.get(oppItem.OpportunityId);
                                if(oppItem.MRR_Start_Date__c != mrrDates.MRRStart || oppItem.MRR_End_Date__c != mrrDates.MRREnd){
                                    oppItem.MRR_Start_Date__c = mrrDates.MRRStart;
                                    oppItem.MRR_End_Date__c = mrrDates.MRREnd;
                                    oppItem.MRR_Has_Leap_Year_Day__c = UtilityClass.checkRangeForLeapYear(mrrDates.MRRStart, mrrDates.MRREnd);
                                }
                            }
                        }
                    }

                    // UPDATE ITEMS NOT IN TRIGGER DATA SET
                    List<OpportunityLineItem> outsideOppItemsToUpdate = new List<OpportunityLineItem>();
                    for(OpportunityLineItem outsideOppItem : outsideOppItems){
                        if(datesByOpp.containsKey(outsideOppItem.OpportunityId)){
                            MRRDates mrrDates = datesByOpp.get(outsideOppItem.OpportunityId);
                            if(outsideOppItem.MRR_Start_Date__c != mrrDates.MRRStart || outsideOppItem.MRR_End_Date__c != mrrDates.MRREnd){
                                outsideOppItem.MRR_Start_Date__c = mrrDates.MRRStart;
                                outsideOppItem.MRR_End_Date__c = mrrDates.MRREnd;
                                outsideOppItem.MRR_Has_Leap_Year_Day__c = UtilityClass.checkRangeForLeapYear(mrrDates.MRRStart, mrrDates.MRREnd);
                                outsideOppItemsToUpdate.add(outsideOppItem);
                            }
                        }
                    }

                    // SAVE OUTSIDE OPP ITEMS SINCE THEY ARE NOT IN THE TRIGGER CONTEXT
                    if(!outsideOppItemsToUpdate.isEmpty()){
                        for(OpportunityLineItem oppItem : outsideOppItemsToUpdate){
                            if(OppLineItemsToUpdate.containsKey(oppItem.Id)){
                                OppLineItemsToUpdate.get(oppItem.Id).MRR_Start_Date__c = oppItem.MRR_Start_Date__c;
                                OppLineItemsToUpdate.get(oppItem.Id).MRR_End_Date__c = oppItem.MRR_End_Date__c;
                                OppLineItemsToUpdate.get(oppItem.Id).MRR_Has_Leap_Year_Day__c = oppItem.MRR_Has_Leap_Year_Day__c;
                            }
                            else{
                                OppLineItemsToUpdate.put(oppItem.Id, oppItem); 
                            }
                        }

                        //TriggerHelper.TemporaryOverride('OpportunityLineItemHelper','updateParentOppMRRDates', false); // NO NEED TO EXECUTE WITH DML CALL, CURRENT CONTEXT WILL EXECUTE
                        //Database.saveResult[] oppItemResults = Database.update(outsideOppItemsToUpdate, false);
                        //TriggerHelper.TemporaryOverride('OpportunityLineItemHelper','updateParentOppMRRDates', true); // REENABLE SO CURRENT CONTEXT CAN EXECUTE
                        //SystemIssueLogHelper.CheckForDatabaseErrors(oppItemResults, 'OpportunityLineItemHelper', 'updateMRRDates', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityLineItemHelper','updateMRRDates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityLineItemHelper', 'updateMRRDates', newOrUpdatedItems, ex, true);
        }
    }

    // WRAPPER CLASS FOR updateMRRDates METHOD
    public class MRRDates {
        Date MRRStart {get; set;}
        Date MRREnd {get; set;}
        public MRRDates(Date mrrStartDate, Date mrrEndDate){
            this.MRRStart = mrrStartDate;
            this.MRREnd = mrrEndDate;
        }
    }


    /**
    * @author Conga Services, ERedding
    * @date 20181114
    * @description updateParentOppMRRDates - Updates Parent Opportunities with updated MRR Start and/or MRR End fields
    *                                          --- EXECUTED FROM OPPORTUNITY LINE ITEM AFTER INSERT, AFTER UPDATE, AND AFTER DELETE TRIGGERS ---
    * @param List<OpportunityLineItem> newOrUpdatedItems - New or updated Opp Item records
    * @param Map<Id, OpportunityLineItem> outdatedOrDeletedItems - Outdated Opp Item records
    * @return void
    */
    public static void updateParentOppMRRDates(List<OpportunityLineItem> newOrUpdatedItems, Map<Id, OpportunityLineItem> outdatedOrDeletedItems){
        try{
            if(TriggerHelper.DoExecute('OpportunityLineItemHelper','updateParentOppMRRDates')){
                // GET PARENT OPP IDS AND OPP ITEM IDS FROM ITEMS THAT ARE NEW OR HAVE A QUALIFYING CHANGE
                Set<Id> parentOppIds = new Set<Id>();

                // GET DATA FROM NEW OR UPDATED ITEMS
                if(newOrUpdatedItems != null){
                    for(OpportunityLineItem newOrUpdatedItem : newOrUpdatedItems){
                        OpportunityLineItem outdatedItem = outdatedOrDeletedItems != null ? outdatedOrDeletedItems.get(newOrUpdatedItem.Id) : null;
                        if(outdatedItem == null || (outdatedItem != null && (newOrUpdatedItem.MRR_Start_Date__c != outdatedItem.MRR_Start_Date__c || 
                                                                             newOrUpdatedItem.MRR_End_Date__c != outdatedItem.MRR_End_Date__c))){
                            // NEW OPP ITEM OR UPDATED OPP ITEM WITH QUALIFYING CHANGE
                            parentOppIds.add(newOrUpdatedItem.OpportunityId);
                        }
                    }
                }
                // GET DATA FROM DELETED ITEMS
                else if(outdatedOrDeletedItems != null){
                    for(OpportunityLineItem outdatedItem : outdatedOrDeletedItems.values()){
                        parentOppIds.add(outdatedItem.OpportunityId);
                    }
                }

                if(!parentOppIds.isEmpty()){
                    Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
                    for(AggregateResult result : [SELECT OpportunityId, MIN(MRR_Start_Date__c) minStart, MAX(MRR_End_Date__c) maxEnd FROM OpportunityLineItem
                                                  WHERE OpportunityId IN :parentOppIds AND PricebookEntry.Product2.FY16_Revenue_Type__c = 'Recurring'
                                                  AND PricebookEntry.Product2.Exclude_from_MRR__c = false
                                                  GROUP BY OpportunityId]){

                        Id opportunityId = (Id)result.get('OpportunityId');
                        Date startDate = (Date)result.get('minStart');
                        Date endDate = (Date)result.get('maxEnd');
                        Boolean leapYear = UtilityClass.checkRangeForLeapYear(startDate, endDate);

                        if(opportunityId != null){
                            oppsToUpdate.put(opportunityId, new Opportunity(Id = opportunityId, MRR_Sub_Start__c = startDate, MRR_Sub_End__c = endDate, MRR_Has_Leap_Year_Day__c = leapYear));
                        }
                    }

                    // QUEUE PARENT OPPS FOR UPATE
                    if(!oppsToUpdate.isEmpty()){
                        for(Opportunity opp : oppsToUpdate.values()){
                            if(ParentOppsToUpdate.containsKey(opp.Id)){
                                ParentOppsToUpdate.get(opp.Id).MRR_Sub_Start__c = opp.MRR_Sub_Start__c;
                                ParentOppsToUpdate.get(opp.Id).MRR_Sub_End__c = opp.MRR_Sub_End__c;
                                ParentOppsToUpdate.get(opp.Id).MRR_Has_Leap_Year_Day__c = opp.MRR_Has_Leap_Year_Day__c;
                            }
                            else{
                                ParentOppsToUpdate.put(opp.Id, opp); 
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityLineItemHelper','updateParentOppMRRDates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityLineItemHelper', 'updateParentOppMRRDates', newOrUpdatedItems, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181128
    * @description updateLeapYearFlag - Updates the Leap_Year_Day__c checkbox when the ServiceDate or Product_End_Date__c changes
    *                                     --- EXECUTED FROM OPPORTUNITY LINE ITEM BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<OpportunityLineItem> newOrUpdatedOppItems - List of new or updated OpportunityLineItem records
    * @param Map<Id, OpportunityLineItem> outdatedOppItems - Map of outdated OpportunityLineItem records
    * @return void
    */
    public static void updateLeapYearFlag(List<OpportunityLineItem> newOrUpdatedOppItems, Map<Id, OpportunityLineItem> outdatedOppItems){
        try{
            if(TriggerHelper.DoExecute('OpportunityLineItemHelper','updateLeapYearFlag') && newOrUpdatedOppItems != null){
                // UPDATE QUALIFYING RECORDS
                for(OpportunityLineItem newOrUpdatedOppItem : newOrUpdatedOppItems){
                    OpportunityLineItem outdatedOppItem = outdatedOppItems != null ? outdatedOppItems.get(newOrUpdatedOppItem.Id) : null;
                    if(outdatedOppItem == null || (outdatedOppItem != null && (newOrUpdatedOppItem.ServiceDate != outdatedOppItem.ServiceDate ||
                                                                               newOrUpdatedOppItem.Product_End_Date__c != outdatedOppItem.Product_End_Date__c))){
                        newOrUpdatedOppItem.Leap_Year_Day__c = UtilityClass.checkRangeForLeapYear(newOrUpdatedOppItem.ServiceDate, newOrUpdatedOppItem.Product_End_Date__c);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityLineItemHelper','updateLeapYearFlag');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OpportunityLineItemHelper', 'updateLeapYearFlag', newOrUpdatedOppItems, ex, true);
        } 
    }
    
    /**
    * @author ECS, ERedding
    * @date 20190710
    * @description updateOppPartnerExpertiseScore - Executes the OpportunityHelper.updatePartnerExpertiseScore method on opps from new or deleted Opportunity Line Items
    *                                                --- EXECUTED BY OPPORTUNITY LINE ITEM AFTER INSERT AND AFTER DELETE TRIGGERS ---
    * @param List<OpportunityLineItem> newOrDeletedOppItems - List of new or deleted Opportunity Line Items
    * @return void
    */
    public static void updateOppPartnerExpertiseScore(List<OpportunityLineItem> newOrDeletedOppItems){
        try{
            if(TriggerHelper.DoExecute('OpportunityLineItemHelper','updateOppPartnerExpertiseScore') && newOrDeletedOppItems != null){

                // GET PARENT OPP IDS
                Set<Id> parentOppIds = new Set<Id>();
                for(OpportunityLineItem oppItem : newOrDeletedOppItems){
                    parentOppIds.add(oppItem.OpportunityId);
                }

                // GET PARENT OPP RECORDS
                List<Opportunity> oppsToUpdate = [SELECT Id, ImplementationPartnerPrimary__c, ImplementationPartnerSecondary__c FROM Opportunity 
                                                  WHERE Id IN :parentOppIds AND (ImplementationPartnerPrimary__c != null OR ImplementationPartnerSecondary__c != null)];

                if(!oppsToUpdate.isEmpty()){
                    // UPDATE OPPS
                    OpportunityHelper.updatePartnerExpertiseScore(oppsToUpdate, null);

                    // QUEUE PARENT OPPS FOR UPDATE
                    for(Opportunity opp : oppsToUpdate){
                        if(ParentOppsToUpdate.containsKey(opp.Id)){
                            ParentOppsToUpdate.get(opp.Id).Partner_Expertise_Score_Text__c = opp.Partner_Expertise_Score_Text__c;
                        }
                        else{
                            ParentOppsToUpdate.put(opp.Id, opp); 
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OpportunityLineItemHelper','updateOppPartnerExpertiseScore');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('OpportunityLineItemHelper', 'updateOppPartnerExpertiseScore', newOrDeletedOppItems, ex, true);
        }
    }


}