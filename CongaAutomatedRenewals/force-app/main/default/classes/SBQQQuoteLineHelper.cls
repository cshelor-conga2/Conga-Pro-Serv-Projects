/**
* @author Conga Services
* @date 20181029
* @version 1.00
* @description SBQQQuoteLineHelper - Custom functionality for the SBQQ__QuoteLine__c object
*/
public class SBQQQuoteLineHelper {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// STATIC VARIABLES //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // PARENT QUOTE UPDATE QUEUE
    public static Map<Id, SBQQ__Quote__c> ParentQuoteUpdateQueue {
    get {
        if(ParentQuoteUpdateQueue == null){
            ParentQuoteUpdateQueue = new Map<Id, SBQQ__Quote__c>();
        }
        return ParentQuoteUpdateQueue;
    } set; }


    // CHILD OPP ITEM UPDATE QUEUE
    public static Map<Id, OpportunityLineItem> ChildOppItemUpdateQueue {
    get {
        if(ChildOppItemUpdateQueue == null){
            ChildOppItemUpdateQueue = new Map<Id, OpportunityLineItem>();
        }
        return ChildOppItemUpdateQueue;
    } set; }


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// TRIGGER / HELPER METHODS /////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /**
    * @author Conga Services, ERedding
    * @date 20190816
    * @description copyDataFromParentProduct - Copies various data down to the Quote Line from the parent Product
    *                                            --- EXECUTED BY SBQQ QUOTE LINE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines - List of new or updated Quote Line records
    * @param Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines - Map of outdated Quote Line records
    * @return void
    */
    public static void copyDataFromParentProduct(List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines, Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteLineHelper','copyDataFromParentProduct') && newOrUpdatedQuoteLines != null){
                // GET QUOTE LINES WITH QUALIFYING CHANGES
                List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
                Set<Id> parentProductIds = new Set<Id>();
                for(SBQQ__QuoteLine__c newOrUpdatedQuoteLine : newOrUpdatedQuoteLines){
                    SBQQ__QuoteLine__c outdatedQuoteLine = outdatedQuoteLines != null ? outdatedQuoteLines.get(newOrUpdatedQuoteLine.Id) : null;
                    if(newOrUpdatedQuoteLine.SBQQ__Product__c != null && (outdatedQuoteLine == null || newOrUpdatedQuoteLine.SBQQ__Product__c != outdatedQuoteLine.SBQQ__Product__c)){
                        quoteLinesToUpdate.add(newOrUpdatedQuoteLine);
                        parentProductIds.add(newOrUpdatedQuoteLine.SBQQ__Product__c);
                        
                    }
                }

                if(!quoteLinesToUpdate.isEmpty()){
                    // GET PARENT PRODUCTS
                    Map<Id, Product2> parentProductMap = new Map<Id, Product2>([SELECT Id, Exclude_from_MRR__c FROM Product2 WHERE Id IN :parentProductIds]);
                    for(SBQQ__QuoteLine__c quoteLine : quoteLinesToUpdate){
                        if(parentProductMap.containsKey(quoteLine.SBQQ__Product__c)){
                            quoteLine.Exclude_from_MRR__c = parentProductMap.get(quoteLine.SBQQ__Product__c).Exclude_from_MRR__c;
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteLineHelper','copyDataFromParentProduct');               
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteLineHelper', 'copyDataFromParentProduct', newOrUpdatedQuoteLines, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181029
    * @description updateOppItemStartEndDates - Determines if there are applicable Quote Line changes that require related Opp Item Start/End date updates
    *                                            --- EXECUTED BY SBQQ QUOTE LINE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines - List of new or updated Quote Line records
    * @param Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines - Map of outdated Quote Line records
    * @return void
    */
    public static void updateOppItemStartEndDates(List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines, Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteLineHelper','updateOppItemStartEndDates') && newOrUpdatedQuoteLines != null){
                // GET QUOTE LINES WITH QUALIFYING CHANGES
                List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
                for(SBQQ__QuoteLine__c newOrupdatedQuoteLine : newOrUpdatedQuoteLines){
                    SBQQ__QuoteLine__c outdatedQuoteLine = outdatedQuoteLines != null ? outdatedQuoteLines.get(newOrupdatedQuoteLine.Id) : null;
                    if(outdatedQuoteLine == null || (outdatedQuoteLine != null && (newOrupdatedQuoteLine.SBQQ__StartDate__c != outdatedQuoteLine.SBQQ__StartDate__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__EndDate__c != outdatedQuoteLine.SBQQ__EndDate__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__Group__c != outdatedQuoteLine.SBQQ__Group__c))){
                        // NEW OR A QUALIFIED CHANGE OCCURED, ADD TO LIST
                        quoteLinesToUpdate.add(newOrupdatedQuoteLine);
                    }
                }

                // CALCULATE Opp_Item_Start_Date__c AND Opp_Item_End_Date__c
                SBQQQuoteLineHelper.calculateOppItemStartEndDates(quoteLinesToUpdate);

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteLineHelper','updateOppItemStartEndDates');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteLineHelper', 'updateOppItemStartEndDates', newOrUpdatedQuoteLines, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181029
    * @description calculateOppItemStartEndDates - Helper method that populates the Opp Item Start and Opp Item End Dates based on several conditions
    *                                              --- EXECUTED BY SBQQ QUOTE AFTER UPDATE, SBQQ QUOTE GROUP AFTER UPDATE, AND SBQQ QUOTE LINE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---   
    * @param List<SBQQ__QuoteLine__c> quoteLines - List of new or updated QuoteLines on which to calculate dates.
    * @return List<SBQQ__QuoteLine__c>
    */
    public static List<SBQQ__QuoteLine__c> calculateOppItemStartEndDates(List<SBQQ__QuoteLine__c> quoteLines){
        try{
            if(quoteLines != null && !quoteLines.isEmpty()){
                // GET PARENT IDS
                Set<Id> parentQuoteIds = new Set<Id>();
                Set<Id> parentProductIds = new Set<Id>();
                Set<Id> parentGroupIds = new Set<Id>();
                for(SBQQ__QuoteLine__c quoteLine : quoteLines){
                    parentQuoteIds.add(quoteLine.SBQQ__Quote__c);
                    parentProductIds.add(quoteLine.SBQQ__Product__c);
                    if(quoteLine.SBQQ__Group__c != null){
                        parentGroupIds.add(quoteLine.SBQQ__Group__c);
                    }
                }

                // GET QUOTE LINE PARENT DATA
                Map<Id, SBQQ__Quote__c> parentQuotesMap = new Map<Id, SBQQ__Quote__c>();
                Map<Id, SBQQ__QuoteLineGroup__c> parentGroupsMap = new Map<Id, SBQQ__QuoteLineGroup__c>();
                Map<Id, Product2> parentProductsMap = new Map<Id, Product2>();
                if(!parentQuoteIds.isEmpty()){
                    parentQuotesMap = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__StartDate__c, Effective_End_Date__c FROM SBQQ__Quote__c WHERE Id IN :parentQuoteIds]);
                }
                if(!parentGroupIds.isEmpty()){
                    parentGroupsMap = new Map<Id, SBQQ__QuoteLineGroup__c>([SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c WHERE Id IN :parentGroupIds]);
                }
                if(!parentProductIds.isEmpty()){
                    parentProductsMap = new Map<Id, Product2>([SELECT Id, FY16_Revenue_Type__c FROM Product2 WHERE Id IN :parentProductIds]);
                }

                for(SBQQ__QuoteLine__c quoteLine : quoteLines){

                    // GET PARENT RECORDS FOR THE CURRENT QUOTE LINE
                    Product2 parentProduct = parentProductsMap.get(quoteLine.SBQQ__Product__c);
                    SBQQ__Quote__c parentQuote = parentQuotesMap.get(quoteLine.SBQQ__Quote__c);
                    SBQQ__QuoteLineGroup__c lineGroup = parentGroupsMap.get(quoteLine.SBQQ__Group__c);

                    // CALCULATE OPP ITEM START AND END DATES, DEFAULT TO QUOTE LINE DATES
                    Date startDate = quoteLine.SBQQ__StartDate__c;
                    Date endDate = quoteLine.SBQQ__EndDate__c;

                    //////// START
                    if(quoteLine.SBQQ__StartDate__c == null && lineGroup != null && lineGroup.SBQQ__StartDate__c != null){
                        startDate = lineGroup.SBQQ__StartDate__c;
                    }             
                    else if(quoteLine.SBQQ__StartDate__c == null){
                        startDate = parentQuote.SBQQ__StartDate__c;
                    }

                    //////// END
                    if(quoteLine.SBQQ__EndDate__c == null && lineGroup != null && lineGroup.SBQQ__EndDate__c != null){
                        endDate = lineGroup.SBQQ__EndDate__c;
                    }
                    else if(quoteLine.SBQQ__EndDate__c == null && lineGroup != null && lineGroup.SBQQ__EndDate__c == null && 
                            lineGroup.SBQQ__SubscriptionTerm__c != null && lineGroup.SBQQ__SubscriptionTerm__c != 0){
                        // USE GROUP START DATE
                        if(lineGroup.SBQQ__StartDate__c != null){
                            endDate = lineGroup.SBQQ__StartDate__c.addMonths((Integer)lineGroup.SBQQ__SubscriptionTerm__c);
                        }
                        // USE PARENT QUOTE START DATE
                        else{
                            endDate = parentQuote.SBQQ__StartDate__c.addMonths((Integer)lineGroup.SBQQ__SubscriptionTerm__c);
                        }
                    }
                    else if(quoteLine.SBQQ__EndDate__c == null){
                        endDate = parentQuote.Effective_End_Date__c;
                    }

                    // NON RECURRING PRODUCTS DONT GET AN END DATE
                    if(parentProduct != null && parentProduct.FY16_Revenue_Type__c != 'Recurring'){
                        endDate = null; 
                    }

                    // UPDATE LINE ITEM DATES IF THEY NEED TO BE
                    if((startDate != null && quoteLine.Opp_Item_Start_Date__c != startDate) || (endDate != null && quoteLine.Opp_Item_End_Date__c != endDate)){
                        quoteLine.Opp_Item_Start_Date__c = startDate;
                        quoteLine.Opp_Item_End_Date__c = endDate;
                        quoteLine.Has_Leap_Year_Day__c = UtilityClass.checkRangeForLeapYear(startDate, endDate);
                        quoteLine.Subscription_Months__c = UtilityClass.getDistanceBetweenDates(startDate, endDate, UtilityClass.Interval.Months, 4);
                        quoteLine.Subscription_Years__c = UtilityClass.getDistanceBetweenDates(startDate, endDate, UtilityClass.Interval.Years, 4);
                    }
                }
            }
            return quoteLines;
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteLineHelper', 'calculateOppItemStartEndDates', quoteLines, ex, true);
            return quoteLines;
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181029
    * @description updateChildOppItemDates - Upon an applicable change, updates Service Date and Product End Date fields on child Opp Item records
    *                                         --- EXECUTED BY SBQQ QUOTE LINE AFTER UPDATE TRIGGER ---
    * @param List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines - List of new or updated Quote Line records
    * @param Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines - Map of outdated Quote Line records
    * @return void
    */
    public static void updateChildOppItemDates(List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines, Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteLineHelper','updateChildOppItemDates') && newOrUpdatedQuoteLines != null){
                // GET QUOTE LINES WITH QUALIFYING CHANGES
                Map<Id, SBQQ__QuoteLine__c> parentQuoteLines = new Map<Id, SBQQ__QuoteLine__c>();
                for(SBQQ__QuoteLine__c newOrUpdatedQuoteLine : newOrUpdatedQuoteLines){
                    SBQQ__QuoteLine__c outdatedQuoteLine = outdatedQuoteLines != null ? outdatedQuoteLines.get(newOrUpdatedQuoteLine.Id) : null;
                    if(outdatedQuoteLine == null || (outdatedQuoteLine != null && (newOrUpdatedQuoteLine.Opp_Item_Start_Date__c != outdatedQuoteLine.Opp_Item_Start_Date__c ||
                                                                                   newOrUpdatedQuoteLine.Opp_Item_End_Date__c != outdatedQuoteLine.Opp_Item_End_Date__c))){
                        // NEW OR A QUALIFIED CHANGE OCCURED, ADD TO 
                        parentQuoteLines.put(newOrUpdatedQuoteLine.Id, newOrUpdatedQuoteLine);
                    }
                }

                if(!parentQuoteLines.isEmpty()){
                    // GET OPP ITEMS TO UPDATE
                    List<OpportunityLineItem> oppItemsToUpdate = new List<OpportunityLineItem>();
                    for(OpportunityLineItem oppItem : [SELECT Id, SBQQ__QuoteLine__c, ServiceDate, Product_End_Date__c FROM OpportunityLineItem WHERE SBQQ__QuoteLine__c IN :parentQuoteLines.keySet()]){
                        SBQQ__QuoteLine__c parentQuoteLine = parentQuoteLines.get(oppItem.SBQQ__QuoteLine__c);
                        if(oppItem.ServiceDate != parentQuoteLine.Opp_Item_Start_Date__c || oppItem.Product_End_Date__c != parentQuoteLine.Opp_Item_End_Date__c){
                            oppItem.ServiceDate = parentQuoteLine.Opp_Item_Start_Date__c;
                            oppItem.Product_End_Date__c = parentQuoteLine.Opp_Item_End_Date__c;
                            oppItemsToUpdate.add(oppItem);
                        }
                    }

                    // QUEUE CHILD OPP ITEMS FOR UPDATE
                    if(!oppItemsToUpdate.isEmpty()){
                        for(OpportunityLineItem oppItem : oppItemsToUpdate){
                            OpportunityLineItem queuedRecord = ChildOppItemUpdateQueue.get(oppItem.Id);
                            if(queuedRecord != null){
                                queuedRecord.ServiceDate = oppItem.ServiceDate;
                                queuedRecord.Product_End_Date__c = oppItem.Product_End_Date__c;
                            }
                            else{
                                ChildOppItemUpdateQueue.put(oppItem.Id, oppItem); 
                            }
                        }

                        //Database.saveResult[] oppItemResults = Database.update(oppItemsToUpdate, false);
                        //SystemIssueLogHelper.CheckForDatabaseErrors(oppItemResults, 'SBQQQuoteLineHelper', 'updateChildOppItemDates', true);    
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteLineHelper','updateChildOppItemDates');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteLineHelper', 'updateChildOppItemDates', newOrUpdatedQuoteLines, ex, true);
        } 
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181029
    * @description updateParentMRRLeapYear - Upon an applicable change, updates Service Date and Product End Date fields on child Opp Item records
    *                                         --- EXECUTED BY SBQQ QUOTE LINE AFTER INSERT AND AFTER UPDATE TRIGGER ---   
    * @param List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines - List of new or updated Quote Line records
    * @param Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines - Map of outdated Quote Line records
    * @return void
    */
    public static void updateParentMRRLeapYear(List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines, Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteLineHelper','updateParentMRRLeapYear') && newOrUpdatedQuoteLines != null){
                // GET QUOTE LINES WITH QUALIFYING CHANGES
                Set<Id> parentQuoteIds = new Set<Id>();
                for(SBQQ__QuoteLine__c newOrUpdatedQuoteLine : newOrUpdatedQuoteLines){
                    SBQQ__QuoteLine__c outdatedQuoteLine = outdatedQuoteLines != null  ? outdatedQuoteLines.get(newOrUpdatedQuoteLine.Id) : null;
                    if(outdatedQuoteLine == null || (outdatedQuoteLine != null && (newOrUpdatedQuoteLine.Opp_Item_Start_Date__c != outdatedQuoteLine.Opp_Item_Start_Date__c ||
                                                                                   newOrUpdatedQuoteLine.Opp_Item_End_Date__c != outdatedQuoteLine.Opp_Item_End_Date__c))){
                        parentQuoteIds.add(newOrUpdatedQuoteLine.SBQQ__Quote__c);
                    }
                }

                if(!parentQuoteIds.isEmpty()){
                    // CREATE MAP OF QUOTES AND DEFAULT MRR LEAP YEAR VALUES TO FALSE 
                    Map<Id, SBQQ__Quote__c> quoteLeapYearFlags = new Map<Id, SBQQ__Quote__c>();
                    for(Id quoteId : parentQuoteIds){
                        quoteLeapYearFlags.put(quoteId, new SBQQ__Quote__c(Id = quoteId, MRR_Has_Leap_Year_Day__c = false));
                    }

                    // GET CHILD QUOTE LINES
                    Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
                    for(SBQQ__QuoteLine__c quoteLine : [SELECT Id, SBQQ__Quote__c, Opp_Item_Start_Date__c, Opp_Item_End_Date__c, Has_Leap_Year_Day__c FROM SBQQ__QuoteLine__c
                                                        WHERE SBQQ__Quote__c IN :parentQuoteIds 
                                                        AND SBQQ__Product__r.FY16_Revenue_Type__c = 'Recurring'
                                                        AND SBQQ__Product__r.Exclude_from_MRR__c = false]){
                        if(!quoteLinesMap.containsKey(quoteLine.SBQQ__Quote__c)){
                            quoteLinesMap.put(quoteLine.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
                        }
                        quoteLinesMap.get(quoteLine.SBQQ__Quote__c).add(quoteLine);
                    }

                    // LOOP OVER ALL QUOTE ITEMS FOR QUOTES AND CHANGE MRR LEAP YEAR FLAG IF APPLICABLE
                    for(Id parentQuoteId : quoteLinesMap.keySet()){
                        for(SBQQ__QuoteLine__c quoteLine : quoteLinesMap.get(parentQuoteId)){
                            if(UtilityClass.checkRangeForLeapYear(quoteLine.Opp_Item_Start_Date__c, quoteLine.Opp_Item_End_Date__c)){
                                quoteLeapYearFlags.get(quoteLine.SBQQ__Quote__c).MRR_Has_Leap_Year_Day__c = true;
                                break; // ONE RECORD WITH A LEAP YEAR IS ALL THAT IS NEEDED TO FLAG LEAP YEAR ON A QUOTE
                            }
                        }
                    }

                    // QUEUE PARENT QUOTES FOR UPDATE
                    for(SBQQ__Quote__c quote : quoteLeapYearFlags.values()){
                        if(ParentQuoteUpdateQueue.containsKey(quote.Id)){
                            ParentQuoteUpdateQueue.get(quote.Id).MRR_Has_Leap_Year_Day__c = quote.MRR_Has_Leap_Year_Day__c;
                        }
                        else{
                            ParentQuoteUpdateQueue.put(quote.Id, quote); 
                        }
                    }

                    // SAVE QUOTES
                    //Database.saveResult[] quoteResults = Database.update(quoteLeapYearFlags.values(), false);
                    //SystemIssueLogHelper.CheckForDatabaseErrors(quoteResults, 'SBQQQuoteLineHelper', 'updateParentMRRLeapYear', true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteLineHelper','updateParentMRRLeapYear');               
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteLineHelper', 'updateParentMRRLeapYear', newOrUpdatedQuoteLines, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20181114
    * @description updateNetTotal - Calculates the Net Total for the Quote Line
    *                                --- EXECUTED BY SBQQ QUOTE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines - List of new or updated Quote Line records
    * @param Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines - Map of outdated Quote Line records
    * @return void
    */
    public static void updateNetTotal(List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines, Map<Id, SBQQ__QuoteLine__c> outdatedQuoteLines){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteLineHelper','updateNetTotal') && newOrUpdatedQuoteLines != null){
                // GET QUOTE LINES WITH QUALIFYING CHANGES
                List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
                for(SBQQ__QuoteLine__c newOrupdatedQuoteLine : newOrUpdatedQuoteLines){
                    SBQQ__QuoteLine__c outdatedQuoteLine = outdatedQuoteLines != null ? outdatedQuoteLines.get(newOrupdatedQuoteLine.Id) : null;
                    if(outdatedQuoteLine == null || (outdatedQuoteLine != null && (newOrupdatedQuoteLine.SBQQ__Renewal__c != outdatedQuoteLine.SBQQ__Renewal__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__Existing__c != outdatedQuoteLine.SBQQ__Existing__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__PriorQuantity__c != outdatedQuoteLine.SBQQ__PriorQuantity__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__NetPrice__c != outdatedQuoteLine.SBQQ__NetPrice__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__DiscountScheduleType__c != outdatedQuoteLine.SBQQ__DiscountScheduleType__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__PricingMethod__c != outdatedQuoteLine.SBQQ__PricingMethod__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__CarryoverLine__c != outdatedQuoteLine.SBQQ__CarryoverLine__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__Quantity__c != outdatedQuoteLine.SBQQ__Quantity__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__UpgradedQuantity__c != outdatedQuoteLine.SBQQ__UpgradedQuantity__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__AllowAssetRefund__c != outdatedQuoteLine.SBQQ__AllowAssetRefund__c ||
                                                                                   newOrupdatedQuoteLine.SBQQ__SubscriptionPricing__c != outdatedQuoteLine.SBQQ__SubscriptionPricing__c))){
                        // NEW OR A QUALIFIED CHANGE OCCURED, ADD TO LIST
                        quoteLinesToUpdate.add(newOrupdatedQuoteLine);
                    }
                }

                // CALCULATE Net Total
                for(SBQQ__QuoteLine__c line : quoteLinesToUpdate){
                    // REPLICATE RECORD FIELDS AS VARIABLES SO NULL CAN BE REPLACED
                    Decimal quantity = UtilityClass.replaceNull(line.SBQQ__Quantity__c, 0);
                    Decimal priorQuantity = UtilityClass.replaceNull(line.SBQQ__PriorQuantity__c, 0);
                    Decimal upgradedQuantity = UtilityClass.replaceNull(line.SBQQ__UpgradedQuantity__c, 0);
                    Decimal netPrice = UtilityClass.replaceNull(line.SBQQ__NetPrice__c, 0);

                    Decimal effectiveQuantity;
                    // CALCULATE EFFECTIVE QUANTITY
                    if(line.SBQQ__DiscountScheduleType__c == 'Slab' || line.SBQQ__PricingMethod__c == 'Block'){
                        if(
                            (!line.SBQQ__Existing__c && !line.SBQQ__CarryoverLine__c && quantity == 0)
                            ||
                            (
                                (line.SBQQ__Existing__c || line.SBQQ__CarryoverLine__c)
                                && 
                                (
                                    quantity == (priorQuantity - upgradedQuantity) ||
                                    (!line.SBQQ__AllowAssetRefund__c && String.isBlank(line.SBQQ__SubscriptionPricing__c) && quantity < (priorQuantity - upgradedQuantity))
                                )
                            )
                        )
                        {
                            effectiveQuantity = 0;
                        }
                        else{
                            effectiveQuantity = 1;
                        }
                    }
                    else{
                        if(!line.SBQQ__Existing__c && !line.SBQQ__CarryoverLine__c){
                            effectiveQuantity = quantity;
                        }
                        else{
                            if(quantity >= (priorQuantity - upgradedQuantity)){
                                if(line.SBQQ__SubscriptionPricing__c == 'Percent Of Total'){
                                    effectiveQuantity = quantity;
                                }
                                else{
                                    effectiveQuantity = (quantity - priorQuantity + upgradedQuantity);
                                }
                            }
                            else{
                                if(!line.SBQQ__AllowAssetRefund__c && String.isBlank(line.SBQQ__SubscriptionPricing__c)){
                                    effectiveQuantity = 0;
                                }
                                else{
                                    effectiveQuantity = (quantity - priorQuantity + upgradedQuantity);
                                }
                            }
                        }
                    }

                    // CALCULATE NET TOTAL
                    line.Net_Total__c = (line.SBQQ__Renewal__c && !line.SBQQ__Existing__c && priorQuantity == null ? 0 : netPrice * effectiveQuantity);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteLineHelper','updateNetTotal');                
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteLineHelper', 'updateNetTotal', newOrUpdatedQuoteLines, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190723
    * @description calculateDiscounts - 
    *                                    --- EXECUTED BY SBQQ QUOTE LINE AFTER INSERT, AFTER UPDATE, AND AFTER DELETE TRIGGERS ---
    * @param List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines - List of new or updated Quote Line records
    * @param Map<Id, SBQQ__QuoteLine__c> outdatedOrDeletedQuoteLines - Map of outdated or deleted Quote Line records
    * @return void
    */
    public static void calculateDiscounts(List<SBQQ__QuoteLine__c> newOrUpdatedQuoteLines, Map<Id, SBQQ__QuoteLine__c> outdatedOrDeletedQuoteLines){
        try{
            if(TriggerHelper.DoExecute('SBQQQuoteLineHelper','calculateDiscounts') && (newOrUpdatedQuoteLines != null || outdatedOrDeletedQuoteLines != null)){
                // GET QUALIFYING QUOTES
                Set<Id> parentQuoteIds = new Set<Id>();
                if(newOrUpdatedQuoteLines != null){
                    // NEW OR UPDATED, QUALIFY
                    for(SBQQ__QuoteLine__c newOrUpdatedQuoteLine : newOrUpdatedQuoteLines){
                        SBQQ__QuoteLine__c outdatedQuoteLine = outdatedOrDeletedQuoteLines != null ? outdatedOrDeletedQuoteLines.get(newOrUpdatedQuoteLine.Id) : null;
                        if(outdatedQuoteLine == null || newOrUpdatedQuoteLine.SBQQ__Product__c != outdatedQuoteLine.SBQQ__Product__c ||
                                                         newOrUpdatedQuoteLine.Opp_Item_Start_Date__c != outdatedQuoteLine.Opp_Item_Start_Date__c ||
                                                         newOrUpdatedQuoteLine.Opp_Item_End_Date__c != outdatedQuoteLine.Opp_Item_End_Date__c ||
                                                         newOrUpdatedQuoteLine.SBQQ__Quantity__c != outdatedQuoteLine.SBQQ__Quantity__c ||
                                                         newOrUpdatedQuoteLine.SBQQ__PriorQuantity__c != outdatedQuoteLine.SBQQ__PriorQuantity__c ||
                                                         newOrUpdatedQuoteLine.SBQQ__ListPrice__c != outdatedQuoteLine.SBQQ__ListPrice__c ||
                                                         newOrUpdatedQuoteLine.SBQQ__Discount__c != outdatedQuoteLine.SBQQ__Discount__c ||
                                                         newOrUpdatedQuoteLine.SBQQ__AdditionalDiscountAmount__c != outdatedQuoteLine.SBQQ__AdditionalDiscountAmount__c ||
                                                         newOrUpdatedQuoteLine.SBQQ__AdditionalDiscount__c != outdatedQuoteLine.SBQQ__AdditionalDiscount__c){
                            parentQuoteIds.add(newOrUpdatedQuoteLine.SBQQ__Quote__c);
                        }
                    }
                }
                else if(newOrUpdatedQuoteLines == null && outdatedOrDeletedQuoteLines != null){
                    // DELETED, ALL QUALIFY
                    for(SBQQ__QuoteLine__c deletedQuoteLine : outdatedOrDeletedQuoteLines.values()){
                        parentQuoteIds.add(deletedQuoteLine.SBQQ__Quote__c);  
                    }
                }

                // PROCESS QUALIFIED QUOTES
                if(!parentQuoteIds.isEmpty()){

                    // LOAD ALL CHILD QUOTE LINES
                    Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuote = new Map<Id, List<SBQQ__QuoteLine__c>>();
                    for(SBQQ__QuoteLine__c quoteLine : [SELECT Id, SBQQ__Quote__c, SBQQ__ListTotal__c, SBQQ__CustomerTotal__c, SBQQ__PriorQuantity__c FROM SBQQ__QuoteLine__c 
                                                        WHERE SBQQ__Quote__c IN :parentQuoteIds 
                                                        AND SBQQ__Product__r.License_Type__c != 'Site License'
                                                        AND SBQQ__Product__r.FY16_Revenue_Type__c = 'Recurring'
                                                        AND SBQQ__EffectiveQuantity__c > 0
                                                        AND (SBQQ__ListPrice__c > 0 OR (SBQQ__ListPrice__c = 0 AND SBQQ__SubscriptionPricing__c = 'Percent of Total'))]){
                        
                        if(!quoteLinesByQuote.containsKey(quoteLine.SBQQ__Quote__c)){
                            quoteLinesByQuote.put(quoteLine.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
                        }
                        quoteLinesByQuote.get(quoteLine.SBQQ__Quote__c).add(quoteLine);
                    }

                    // CALCULATE TOTAL DISCOUNT PERCENTAGE FOR QUOTES
                    List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
                    for(Id quoteId : quoteLinesByQuote.keySet()){
                        
                        //////////////////////////// OVERALL SUBSCRIPTION DISCOUNT ///////////////////////
                        Decimal overall_extendedPriceTotal = 0.00;
                        Decimal overall_customerPriceTotal = 0.00;

                        for(SBQQ__QuoteLine__c quoteLine : quoteLinesByQuote.get(quoteId)){
                            overall_extendedPriceTotal += UtilityClass.replaceNull(quoteLine.SBQQ__ListTotal__c, 0.00);
                            overall_customerPriceTotal += UtilityClass.replaceNull(quoteLine.SBQQ__CustomerTotal__c, 0.00);
                        }

                        Decimal overallSubscriptionDiscount = 0.00;
                        if(overall_extendedPriceTotal > 0){
                            overallSubscriptionDiscount = ((overall_extendedPriceTotal - overall_customerPriceTotal) / overall_extendedPriceTotal) * 100;
                        }
                        //////////////////////////////////////////////////////////////////////////////////


                        //////////////////////////// NEW PRODUCTS DISCOUNT ///////////////////////////////
                        Decimal newProduct_extendedPriceTotal = 0.00;
                        Decimal newProduct_customerPriceTotal = 0.00;

                        for(SBQQ__QuoteLine__c quoteLine : quoteLinesByQuote.get(quoteId)){
                            if(quoteLine.SBQQ__PriorQuantity__c == 0 || quoteLine.SBQQ__PriorQuantity__c == null){
                                newProduct_extendedPriceTotal += UtilityClass.replaceNull(quoteLine.SBQQ__ListTotal__c, 0.00);
                                newProduct_customerPriceTotal += UtilityClass.replaceNull(quoteLine.SBQQ__CustomerTotal__c, 0.00);
                            }
                        }

                        Decimal newProductsDiscount = 0.00;
                        if(newProduct_extendedPriceTotal > 0){
                            newProductsDiscount = ((newProduct_extendedPriceTotal - newProduct_customerPriceTotal) / newProduct_extendedPriceTotal) * 100;
                        }
                        //////////////////////////////////////////////////////////////////////////////////

                        // ADD QUOTE TO UPDATE LIST
                        quotesToUpdate.add(new SBQQ__Quote__c(Id = quoteId, Overall_Subscription_Discount__c = overallSubscriptionDiscount, New_Products_Discount__c = newProductsDiscount));
                    }

                    // QUEUE PARENT QUOTES FOR UPDATE
                    if(!quotesToUpdate.isEmpty()){
                        for(SBQQ__Quote__c quote : quotesToUpdate){
                            SBQQ__Quote__c queuedRecord = ParentQuoteUpdateQueue.get(quote.Id);
                            if(queuedRecord != null){
                                queuedRecord.Overall_Subscription_Discount__c = quote.Overall_Subscription_Discount__c;
                                queuedRecord.New_Products_Discount__c = quote.New_Products_Discount__c;
                            }
                            else{
                                ParentQuoteUpdateQueue.put(quote.Id, quote); 
                            }
                        }

                        // UPDATE QUOTES
                        //Database.saveResult[] updateResults = Database.update(quotesToUpdate, false);
                        //SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'SBQQQuoteLineHelper', 'calculateDiscounts', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQQuoteLineHelper','calculateDiscounts');           
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQQuoteLineHelper', 'calculateDiscounts', (newOrUpdatedQuoteLines != null ? newOrUpdatedQuoteLines : outdatedOrDeletedQuoteLines.values()), ex, true);
        } 
    }


}