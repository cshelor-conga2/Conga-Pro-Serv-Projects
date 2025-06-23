/**
* @author ECS, ERedding
* @date 20181030
* @version 1.00
* @description SBQQSubscriptionHelper - Custom functionality for the SBQQ_Subscription__c managed object
*/
public class SBQQSubscriptionHelper {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// STATIC VARIABLES //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // PARENT OPPORTUNITY UPDATE QUEUE
    public static Map<Id, Opportunity> ParentOppsToUpdate {
    get {
        if(ParentOppsToUpdate == null){
            ParentOppsToUpdate = new Map<Id, Opportunity>();
        }
        return ParentOppsToUpdate;
    } set; }

    // PARENT CONTRACT UPDATE QUEUE
    public static Map<Id, Contract> ParentContractsToUpdate {
    get {
        if(ParentContractsToUpdate == null){
            ParentContractsToUpdate = new Map<Id, Contract>();
        }
        return ParentContractsToUpdate;
    } set; }


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// TRIGGER / HELPER METHODS /////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /**
    * @description updateLeapYearFlag - Updates the Has_Leap_Year_Day__c field using the UtilityClass.checkRangeForLeapYear method
    *                                     ****** EXECUTED FROM SBQQ SUBSCRIPTION BEFORE INSERT AND BEFORE UPDATE TRIGGERS ******
    * @param List<SBQQ__Subscription__c> newOrUpdatedSubscriptions - New or Updated SBQQ Subscription records
    * @param Map<Id, SBQQ__Subscription__c> outdatedSubscriptions - Outdated SBQQ Subscription records
    * @return void
    */
    public static void updateLeapYearFlag(List<SBQQ__Subscription__c> newOrUpdatedSubscriptions, Map<Id, SBQQ__Subscription__c> outdatedSubscriptions){
        try{
            if(TriggerHelper.DoExecute('SBQQSubscriptionHelper','updateLeapYearFlag') && newOrUpdatedSubscriptions != null){
                // CHECK EACH SUBSCRIPTION TO SEE IF IT QUALIFIES
                List<SBQQ__Subscription__c> qualifiedSubscriptions = new List<SBQQ__Subscription__c>();
                for(SBQQ__Subscription__c newOrUpdatedSub : newOrUpdatedSubscriptions){
                    SBQQ__Subscription__c outdatedSub = outdatedSubscriptions != null ? outdatedSubscriptions.get(newOrUpdatedSub.Id) : null;
                    if(outdatedSub == null || (outdatedSub != null && (newOrUpdatedSub.SBQQ__StartDate__c != outdatedSub.SBQQ__StartDate__c ||
                                                                       newOrUpdatedSub.SBQQ__EndDate__c != outdatedSub.SBQQ__EndDate__c))){
                        // NEW SUBSCRIPTION OR UPDATED SUBSCRIPTION WITH CHANGED NET PRICE, START DATE, OR END DATE, SUBSCRIPTION QUALIFIES
                        qualifiedSubscriptions.add(newOrUpdatedSub);
                    }
                }

                if(!qualifiedSubscriptions.isEmpty()){
                    // UPDATE SUBSCRIPTION LEAP YEAR FLAGS
                    for(SBQQ__Subscription__c sub : qualifiedSubscriptions){
                        sub.Has_Leap_Year_Day__c = UtilityClass.checkRangeForLeapYear(sub.SBQQ__StartDate__c, sub.SBQQ__EndDate__c);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQSubscriptionHelper','updateLeapYearFlag');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQSubscriptionHelper', 'updateLeapYearFlag', newOrUpdatedSubscriptions, ex, true);
        }
    }

    /**
    * @description calculateOppCurrentAverageMRR - Checks for new or updated Subscriptions that should trigger an update of related Opp Current MRR amounts
    *                                               ****** EXECUTED FROM SBQQ SUBSCRIPTION AFTER INSERT AND AFTER UPDATE TRIGGERS ******
    * @param List<SBQQ__Subscription__c> newOrUpdatedSubscriptions - New or Updated SBQQ Subscription records
    * @param Map<Id, SBQQ__Subscription__c> outdatedSubscriptions - Outdated SBQQ Subscription records
    * @return void
    */
    public static void calculateOppCurrentAverageMRR(List<SBQQ__Subscription__c> newOrUpdatedSubscriptions, Map<Id, SBQQ__Subscription__c> outdatedSubscriptions){
        try{
            if(TriggerHelper.DoExecute('SBQQSubscriptionHelper','calculateOppCurrentAverageMRR') && newOrUpdatedSubscriptions != null){
                // CHECK EACH SUBSCRIPTION TO SEE IF IT QUALIFIES
                List<SBQQ__Subscription__c> qualifiedSubscriptions = new List<SBQQ__Subscription__c>();
                Set<Id> parentContractIds = new Set<Id>();
                for(SBQQ__Subscription__c newOrUpdatedSub : newOrUpdatedSubscriptions){
                    SBQQ__Subscription__c outdatedSub = outdatedSubscriptions != null ? outdatedSubscriptions.get(newOrUpdatedSub.Id) : null;
                    if(outdatedSub == null || (outdatedSub != null && (newOrUpdatedSub.SBQQ__NetPrice__c != outdatedSub.SBQQ__NetPrice__c || 
                                                                       newOrUpdatedSub.SBQQ__StartDate__c != outdatedSub.SBQQ__StartDate__c ||
                                                                       newOrUpdatedSub.SBQQ__EndDate__c != outdatedSub.SBQQ__EndDate__c ||
                                                                       newOrUpdatedSub.SBQQ__Contract__c != outdatedSub.SBQQ__Contract__c))){
                        // NEW SUBSCRIPTION OR QUALIFIED UPDATED SUBSCRIPTION
                        qualifiedSubscriptions.add(newOrUpdatedSub);
                        parentContractIds.add(newOrUpdatedSub.SBQQ__Contract__c);
                    }
                }

                if(!qualifiedSubscriptions.isEmpty()){
                    // GET PARENT CONTRACT DATA
                    Map<Id, Contract> parentContracts = new Map<Id, Contract>([SELECT Id, SBQQ__RenewalOpportunity__c FROM Contract WHERE Id IN :parentContractIds
                                                                               AND SBQQ__RenewalOpportunity__r.IsClosed = false]);

                    // EXECUTE OVERLOAD METHOD THAT PERFORMS THE BULK OF THE LOGIC
                    List<Opportunity> oppsToUpdate = calculateOppCurrentAverageMRR(qualifiedSubscriptions, parentContracts);

                    // QUEUE PARENT OPPORTUNITIES FOR UPDATE
                    if(!oppsToUpdate.isEmpty()){
                        for(Opportunity opp : oppsToUpdate){
                            if(ParentOppsToUpdate.containsKey(opp.Id)){
                                Map<String, Object> populatedFields = opp.getPopulatedFieldsAsMap();
                                for(String fieldName : populatedFields.keySet()){
                                    ParentOppsToUpdate.get(opp.Id).put(fieldName, opp.get(fieldName));
                                }
                            }
                            else{
                                ParentOppsToUpdate.put(opp.Id, opp); 
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQSubscriptionHelper','calculateOppCurrentAverageMRR');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQSubscriptionHelper', 'calculateOppCurrentAverageMRR', newOrUpdatedSubscriptions, ex, true);
        }
    }

    /**
    * @description calculateOppCurrentAverageMRR - Recalculates the current MRR amounts on opps related to the supplied subscriptions and contracts
    *                                                ***** EXECUTED FROM SBQQ SUBSCRIPTION AFTER INSERT AND AFTER UPDATE -AND- CONTRACT AFTER UPDATE TRIGGERS *****
    * @param List<Contract> newOrUpdatedContracts - New or Updated Contract records
    * @param Map<Id,Contract> outdatedContracts - Outdated Contract records
    * @return List<Opportunity> - List of updated opportunities
    */
    public static List<Opportunity> calculateOppCurrentAverageMRR(List<SBQQ__Subscription__c> qualifiedSubscriptions, Map<Id, Contract> parentContracts){
        try{
            if(qualifiedSubscriptions != null){
                if(!qualifiedSubscriptions.isEmpty() && !parentContracts.isEmpty()){
                    Set<Id> contractIds = new Set<Id>();
                    for(SBQQ__Subscription__c qualifiedSub : qualifiedSubscriptions){
                        Contract parentContract = parentContracts.get(qualifiedSub.SBQQ__Contract__c);
                        if(parentContract.SBQQ__RenewalOpportunity__c != null){
                            contractIds.add(parentContract.Id);
                        }
                    }

                    if(!contractIds.isEmpty()){
                        // GET OPP AVERAGE MRR FIELD MAPPING
                        Map<String, String> productLineToFieldMap = new Map<String, String>();
                        for(Opp_Average_MRR_Mapping__mdt meta : [SELECT FieldId__r.QualifiedAPIName, Product_Line__c FROM Opp_Average_MRR_Mapping__mdt WHERE ObjectId__r.QualifiedAPIName = 'Opportunity']){
                            productLineToFieldMap.put(meta.Product_Line__c, meta.FieldId__r.QualifiedAPIName);
                        }

                        // GET AGGREGATE RESULTS FOR SUBSCRIPTIONS ON RENEWAL OPPORTUNITIES
                        List<AggregateResult> aggResults = new List<AggregateResult>();
                        aggResults.addAll([SELECT SBQQ__Contract__r.SBQQ__RenewalOpportunity__c oppId, SBQQ__Product__r.Product_Line__c, SUM(Average_MRRFx__c) mrr
                                           FROM SBQQ__Subscription__c
                                           WHERE SBQQ__Contract__c IN :contractIds AND SBQQ__Contract__r.SBQQ__RenewalOpportunity__c != null
                                           AND SBQQ__Product__r.Product_Line__c IN :productLineToFieldMap.keySet()
                                           AND SBQQ__Product__r.Exclude_from_MRR__c = false
                                           GROUP BY SBQQ__Contract__r.SBQQ__RenewalOpportunity__c, SBQQ__Product__r.Product_Line__c]);

                        // LOOP OVER EACH AGGREGATE RESULT OF SUMMED MRR BY OPP AND PRODUCT LINE. MAP TO THE CORRECT FIELD AND QUEUE THE OPP FOR UPDATE
                        Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
                        for(AggregateResult result : aggResults){
                            Id oppId = (Id)result.get('oppId');
                            String productLine = (String)result.get('Product_Line__c');
                            Decimal mrr = (Decimal)result.get('mrr');

                            if(productLineToFieldMap.containsKey(productLine)){
                                if(!oppsToUpdate.containsKey(oppId)){
                                    Opportunity opp = new Opportunity(Id = oppId);
                                    oppsToUpdate.put(oppId, opp);
                                }
                                oppsToUpdate.get(oppId).put(productLineToFieldMap.get(productLine), mrr);
                            }
                        }

                        return oppsToUpdate.values();
                        // UPDATE OPPS
                        //if(!oppsToUpdate.isEmpty()){
                        //    Database.saveResult[] oppResults = Database.update(oppsToUpdate.values(), false);
                        //    SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'SBQQSubscriptionHelper', 'calculateOppCurrentAverageMRR', true);                        
                        //}
                    }
                }
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQSubscriptionHelper', 'calculateOppCurrentAverageMRR', qualifiedSubscriptions, ex, true);
        }
        return new List<Opportunity>(); // RETURN EMPTY MAP AS THE DEFAULT
    }

    /**
    * @description calculateMRR - Checks for new or updated Subscriptions that should trigger an update of related Opp Current MRR amounts
    *                               ***** EXECUTED FROM SBQQ SUBSCRIPTION AFTER INSERT AND AFTER UPDATE TRIGGERS *****
    * @param List<SBQQ__Subscription__c> newOrUpdatedSubscriptions - New or Updated SBQQ Subscription records
    * @param Map<Id, SBQQ__Subscription__c> outdatedSubscriptions - Outdated SBQQ Subscription records
    * @return void
    */
    public static void calculateMRR(Map<Id, SBQQ__Subscription__c> newOrUpdatedSubscriptions, Map<Id, SBQQ__Subscription__c> outdatedSubscriptions){
        try{
            if(TriggerHelper.DoExecute('SBQQSubscriptionHelper','calculateMRR') && newOrUpdatedSubscriptions != null){
                List<SBQQ__Subscription__c> subscriptionsToProcess = new List<SBQQ__Subscription__c>();
                List<SBQQ__Subscription__c> zeroedSubscriptions = new List<SBQQ__Subscription__c>();
                List<MRR_Calculation__c> calculationsToInsert = new List<MRR_Calculation__c>();
                List<MRR_Calculation__c> calculationsToUpdate = new List<MRR_Calculation__c>();
                List<MRR_Calculation__c> calculationsToDelete = new List<MRR_Calculation__c>();

                // GET QUALIFIED SUBSCRIPTION RECORDS
                if(outdatedSubscriptions == null || outdatedSubscriptions.isEmpty()){
                    // NEWLY CREATE SUBSCRIPTIONS, ADD ALL THAT DO NOT HAVE A NET PRICE OF 0 AND DO NOT HAVE A QUANTITY OF 0
                    for(SBQQ__Subscription__c sub : newOrUpdatedSubscriptions.values()){
                        if(sub.SBQQ__Account__c != null && (sub.SBQQ__QuoteLine__c != null || (sub.SBQQ__NetPrice__c > 0 && sub.SBQQ__StartDate__c != null && sub.SBQQ__EndDate__c != null))){
                            subscriptionsToProcess.add(sub);
                        }
                    }
                }
                else if(outdatedSubscriptions != null && !outdatedSubscriptions.isEmpty()){
                    // SUBSCRIPTIONS UPDATED, CHECK EACH ONE FOR AN APPLICABLE CHANGE
                    for(SBQQ__Subscription__c sub : newOrUpdatedSubscriptions.values()){
                        SBQQ__Subscription__c outdatedSub = outdatedSubscriptions != null ? outdatedSubscriptions.get(sub.Id) : null;

                        if(outdatedSub != null && sub.SBQQ__Account__c != null && (sub.SBQQ__QuoteLine__c != null || (sub.SBQQ__StartDate__c != null && sub.SBQQ__EndDate__c != null)) && 
                            (sub.SBQQ__QuoteLine__c != outdatedSub.SBQQ__QuoteLine__c || sub.SBQQ__Account__c != outdatedSub.SBQQ__Account__c ||
                             sub.SBQQ__StartDate__c != outdatedSub.SBQQ__StartDate__c || sub.SBQQ__EndDate__c != outdatedSub.SBQQ__EndDate__c || 
                             sub.SBQQ__Quantity__c != outdatedSub.SBQQ__Quantity__c || sub.SBQQ__RenewalQuantity__c != outdatedSub.SBQQ__RenewalQuantity__c || 
                             sub.SBQQ__SegmentQuantity__c != outdatedSub.SBQQ__SegmentQuantity__c || sub.SBQQ__NetPrice__c != outdatedSub.SBQQ__NetPrice__c)){

                            if(sub.SBQQ__NetPrice__c == 0 || (sub.SBQQ__QuoteLine__c == null && sub.SBQQ__Quantity__c == 0 && sub.SBQQ__RenewalQuantity__c == 0 && sub.SBQQ__SegmentQuantity__c == 0)){
                                // SUBSCRIPTION NET PRICE WAS SET TO ZERO OR ALL QTY FIELDS ARE 0. ANY MRR CALCULATIONS NEED TO BE DELETED.
                                zeroedSubscriptions.add(sub);
                            }
                            else{
                                // APPLICABLE CHANGE FOUND, QUEUE SUBSCRIPTION FOR PROCESSING
                                subscriptionsToProcess.add(sub);
                            }
                        }
                    }
                }

                // GET EXISTING MRR CALCULATION RECORDS FOR QUALIFIED SUBSCRIPTIONS
                Map<Id, Map<Id, MRR_Calculation__c>> existingMRRCalculations = new Map<Id, Map<Id, MRR_Calculation__c>>();
                for(MRR_Calculation__c mrr : [SELECT Id, SubscriptionId__c, AccountId__c, Date__c, Month__c, MRR__c, Product_Family__c, Product_Line__c, Type__c FROM MRR_Calculation__c 
                                              WHERE SubscriptionId__c IN :subscriptionsToProcess OR SubscriptionId__c IN :zeroedSubscriptions ORDER BY Date__c]){
                    if(!existingMRRCalculations.containsKey(mrr.SubscriptionId__c)){
                        existingMRRCalculations.put(mrr.SubscriptionId__c, new Map<Id, MRR_Calculation__c>());
                    }
                    existingMRRCalculations.get(mrr.SubscriptionId__c).put(mrr.Id, mrr);
                }

                // PROCESS ZEROED SUBSCRIPTIONS
                for(SBQQ__Subscription__c sub : zeroedSubscriptions){
                    if(existingMRRCalculations.containsKey(sub.Id)){
                        calculationsToDelete.addAll(existingMRRCalculations.get(sub.Id).values());
                    }
                }

                // IF THERE ARE SUBSCRIPTIONS TO PROCESS, REFRESH THEM AND GET ALL THE NECESSARY DATA
                if(!subscriptionsToProcess.isEmpty()){
                    subscriptionsToProcess = [SELECT Id, Name, SBQQ__Account__c, SBQQ__NetPrice__c, SBQQ__Quantity__c, SBQQ__RenewalQuantity__c, SBQQ__SegmentQuantity__c, 
                                                     SBQQ__StartDate__c, SBQQ__EndDate__c, Product_MRR__c,
                                                     SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__NetTotal__c, SBQQ__QuoteLine__r.Opp_Item_Start_Date__c, SBQQ__QuoteLine__r.Opp_Item_End_Date__c,
                                                     SBQQ__Product__c, SBQQ__Product__r.Family, SBQQ__Product__r.Product_Line__c
                                              FROM SBQQ__Subscription__c
                                              WHERE Id IN :subscriptionsToProcess 
                                              AND SBQQ__Product__r.FY16_Revenue_Type__c = 'Recurring'
                                              AND SBQQ__Product__r.Exclude_from_MRR__c = false];
                }

                // PROCESS NEW OR CHANGED SUBSCRIPTIONS
                for(SBQQ__Subscription__c sub : subscriptionsToProcess){
                    if((sub.SBQQ__QuoteLine__c != null && sub.SBQQ__QuoteLine__r.Opp_Item_Start_Date__c != null && sub.SBQQ__QuoteLine__r.Opp_Item_End_Date__c != null) || 
                        (sub.SBQQ__StartDate__c != null && sub.SBQQ__EndDate__c != null)){

                        Date mrrStartDate = null;
                        Date mrrEndDate = null;
                        Decimal monthlyMRR = 0;

                        if(sub.SBQQ__QuoteLine__c != null){
                            // GET DATES FROM QUOTE LINE
                            mrrStartDate = sub.SBQQ__QuoteLine__r.Opp_Item_Start_Date__c;
                            mrrEndDate = sub.SBQQ__QuoteLine__r.Opp_Item_End_Date__c;

                            // CALCULATE MONTHLY MRR
                            Integer daysInYear = (UtilityClass.checkRangeForLeapYear(mrrStartDate, mrrEndDate) ? 366 : 365);
                            monthlyMRR = ((UtilityClass.replaceNull(sub.SBQQ__QuoteLine__r.SBQQ__NetTotal__c, 0) / (mrrStartDate.daysBetween(mrrEndDate) + 1)) * daysInYear / 12).setScale(4);
                        }
                        else{
                            // GET DATES FROM SUBSCRIPTION
                            mrrStartDate = sub.SBQQ__StartDate__c;
                            mrrEndDate = sub.SBQQ__EndDate__c;

                            // GET QUANTITY
                            Decimal quantity = 0;
                            if(UtilityClass.replaceNull(sub.SBQQ__Quantity__c, 0) != 0){
                                quantity = sub.SBQQ__Quantity__c;
                            }
                            else if(UtilityClass.replaceNull(sub.SBQQ__RenewalQuantity__c, 0) != 0){
                                quantity = sub.SBQQ__RenewalQuantity__c;
                            }
                            else{
                                quantity = UtilityClass.replaceNull(sub.SBQQ__SegmentQuantity__c, 0);
                            }

                            // CALCULATE MONTHLY MRR
                            Integer daysInYear = UtilityClass.checkRangeForLeapYear(mrrStartDate, mrrEndDate) ? 366 : 365;
                            monthlyMRR = (((UtilityClass.replaceNull(sub.SBQQ__NetPrice__c, 0) * quantity) / (mrrStartDate.daysBetween(mrrEndDate) + 1)) * daysInYear / 12).setScale(4);
                        }

                        // CALCULATE NUMBER OF MONTHS
                        Integer numberOfMonths = mrrStartDate.monthsBetween(mrrEndDate) + 1;
                        List<MRR_Calculation__c> mrrCalculations = new List<MRR_Calculation__c>();                        
                        if(monthlyMRR != 0){
                            // LOOP OVER EACH MONTH IN A SUBSCRIPTION
                            for(Integer month = 1; month <= numberOfMonths; month++){

                                // CREATE DAILY MRR RECORDS IF SUBSCRIPTION STARTS IN THE MIDDLE OF THE MONTH
                                if(month == 1 && mrrStartDate.day() != 1){
                                    Integer numberOfDaysInMonth = Date.daysInMonth(mrrStartDate.year(), mrrStartDate.month()+(month-1));                            
                                    Integer numberOfDaysWithMRR = mrrStartDate.daysBetween(Date.newInstance(mrrStartDate.year(), mrrStartDate.month(), numberOfDaysInMonth))+1;

                                    for(Integer day = 1; day <= numberOfDaysWithMRR; day++){
                                        Date mrrDate = mrrStartDate.addDays(day-1);
                                        MRR_Calculation__c newCalc = new MRR_Calculation__c(
                                            Name = sub.Name + '-' + String.valueOf(mrrDate),
                                            SubscriptionId__c = sub.Id,
                                            AccountId__c = sub.SBQQ__Account__c, 
                                            Date__c = mrrDate,
                                            Month__c = String.valueOf(mrrDate.month()),
                                            Year__c = String.valueOf(mrrDate.year()),
                                            MRR__c = (monthlyMRR / numberOfDaysWithMRR).setScale(4),
                                            Product_Family__c = sub.SBQQ__Product__r.Family,
                                            Product_Line__c = sub.SBQQ__Product__r.Product_Line__c,
                                            Type__c = 'Daily'
                                            );

                                        mrrCalculations.add(newCalc);
                                    }
                                }
                                // CREATE DAILY MRR RECORDS IF SUBSCRIPTION ENDS IN THE MIDDLE OF THE MONTH
                                else if(month == numberOfMonths && mrrEndDate.day() != Date.daysInMonth(mrrEndDate.year(), mrrEndDate.month())){
                                    Integer numberOfDaysWithMRR = Date.newInstance(mrrEndDate.year(), mrrEndDate.month(), 1).daysBetween(mrrEndDate)+1;

                                    for(Integer day = 1; day <= numberOfDaysWithMRR; day++){
                                        Date mrrDate = Date.newInstance(mrrEndDate.year(), mrrEndDate.month(), 1).addDays(day-1);
                                        MRR_Calculation__c newCalc = new MRR_Calculation__c(
                                            Name = sub.Name + '-' + String.valueOf(mrrDate),
                                            SubscriptionId__c = sub.Id,
                                            AccountId__c = sub.SBQQ__Account__c,
                                            Date__c = mrrDate,
                                            Month__c = String.valueOf(mrrDate.month()),
                                            Year__c = String.valueOf(mrrDate.year()),
                                            MRR__c = (monthlyMRR / numberOfDaysWithMRR).setScale(4),
                                            Product_Family__c = sub.SBQQ__Product__r.Family,
                                            Product_Line__c = sub.SBQQ__Product__r.Product_Line__c,
                                            Type__c = 'Daily'
                                            );

                                        mrrCalculations.add(newCalc);
                                    }
                                }
                                // OTHERWISE CREATE MONTHLY MRR RECORD
                                else{
                                    
                                    Date mrrDate = Date.newInstance(mrrStartDate.addMonths(month-1).year(), mrrStartDate.addMonths(month-1).month(), 1);
                                    MRR_Calculation__c newCalc = new MRR_Calculation__c(
                                        Name = sub.Name + '-' + String.valueOf(mrrDate),
                                        SubscriptionId__c = sub.Id,
                                        AccountId__c = sub.SBQQ__Account__c, 
                                        Date__c = mrrDate,
                                        Month__c = String.valueOf(mrrDate.month()),
                                        Year__c = String.valueOf(mrrDate.year()),
                                        MRR__c = monthlyMRR,
                                        Product_Family__c = sub.SBQQ__Product__r.Family,
                                        Product_Line__c = sub.SBQQ__Product__r.Product_Line__c,
                                        Type__c = 'Monthly'
                                        );

                                    mrrCalculations.add(newCalc);
                                }
                            }
                        }

                        // CHECK EXISTING MRR CALCULATION RECORDS AGAINST NEW ONES AND QUEUE FOR INSERT, UPDATE OR DELETE
                        if(existingMRRCalculations.containsKey(sub.Id)){
                            for(MRR_Calculation__c newMRR : mrrCalculations){
                                Boolean matchFound = false;

                                for(MRR_Calculation__c existingMRR : existingMRRCalculations.get(sub.Id).values()){
                                    if(newMRR.Date__c == existingMRR.Date__c){
                                        if(newMRR.MRR__c != existingMRR.MRR__c || newMRR.AccountId__c != existingMRR.AccountId__c){
                                            newMRR.Id = existingMRR.Id;
                                            calculationsToUpdate.add(newMRR);  
                                        }

                                        matchFound = true;
                                        existingMRRCalculations.get(sub.Id).remove(existingMRR.Id);
                                        break;
                                    }
                                }

                                if(!matchFound){ 
                                    calculationsToInsert.add(newMRR);
                                }
                            }

                            if(!existingMRRCalculations.get(sub.Id).isEmpty()){
                                // IF ANY EXISTING MRR RECORDS REMAIN IN THE MAP FOR THE SUBSCRIPTION, THEY ARE OUTSIDE OF THE SUBSCRIPTION'S DATE RANGE
                                // OR NOW HAVE AN MRR OF 0 AND NEED TO BE DELETED
                                calculationsToDelete.addAll(existingMRRCalculations.get(sub.Id).values());
                            }
                        }
                        else{
                            // NO SUBSCRIPTIONS EXIST, INSERT ALL
                            calculationsToInsert.addAll(mrrCalculations);
                        }
                    }
                }

                // CREATE MRR RECORDS QUEUED FOR INSERT
                if(!calculationsToInsert.isEmpty()){
                    Database.SaveResult[] insertResults = Database.insert(calculationsToInsert, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'SBQQSubscriptionHelper', 'calculateMRR', false);
                }

                // UPDATE MRR RECORDS QUEUED FOR UPDATE
                if(!calculationsToUpdate.isEmpty()){
                    Database.SaveResult[] updateResults = Database.update(calculationsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'SBQQSubscriptionHelper', 'calculateMRR', false);
                }

                // DELETE MRR RECORDS QUEUED FOR DELETE
                if(!calculationsToDelete.isEmpty()){
                    Database.DeleteResult[] deleteResults = Database.delete(calculationsToDelete, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(deleteResults, 'SBQQSubscriptionHelper', 'calculateMRR', false);
                }

                // SAVE ANY LOGGED ERRORS
                SystemIssueLogHelper.UpsertExceptions();

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQSubscriptionHelper','calculateMRR');
            }   
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQSubscriptionHelper', 'calculateMRR', newOrUpdatedSubscriptions, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190501
    * @description updateAccountCSDivision - Calculates the CS Division on Accounts with new Subscriptions created from qualifying New Business Opps
    *                                          ******** EXECUTED BY SBQQ SUBSCRIPTION AFTER INSERT TRIGGER ********
    * @param List<SBQQ__Subscription__c> newSubscriptions - New SBQQ__Subscription__c records
    * @return void
    */
    public static void updateAccountCSDivision(List<SBQQ__Subscription__c> newSubscriptions){
        try{
            if(TriggerHelper.DoExecute('SBQQSubscriptionHelper','updateAccountCSDivision') && newSubscriptions != null){
                // GET PARENT CONTRACT IDS
                Set<Id> parentContractIds = new Set<Id>();
                for(SBQQ__Subscription__c newSubscription : newSubscriptions){
                    if(newSubscription.SBQQ__Contract__c != null){
                        parentContractIds.add(newSubscription.SBQQ__Contract__c);
                    }
                }

                if(!parentContractIds.isEmpty()){
                    // GET PARENT ACCOUNT IDS FROM QUALIFYING CONTRACT OPPS
                    Map<Id, Account> parentAccountsMap = new Map<Id, Account>();
                    for(Contract contract : [SELECT Id, SBQQ__Opportunity__r.AccountId, SBQQ__Opportunity__r.Account.CS_Division_Stamp__c, SBQQ__Opportunity__r.Account.Burdened_MRR__c 
                                             FROM Contract WHERE Id IN :parentContractIds
                                             AND SBQQ__Opportunity__r.Type = 'New Business' AND SBQQ__Opportunity__r.New_Org__c = false AND SBQQ__Opportunity__r.IsClosed = true 
                                             AND SBQQ__Opportunity__r.IsWon = true AND SBQQ__Opportunity__r.Sales_Ops_Approved__c = true]){
                        parentAccountsMap.put(contract.SBQQ__Opportunity__r.AccountId, contract.SBQQ__Opportunity__r.Account);
                    }

                    if(!parentAccountsMap.isEmpty()){
                        // GET LATEST MONTH AND YEAR FOR EACH ACCOUNT
                        Map<Id, Date> latestMonthDateByAccount = new Map<Id, Date>();
                        Date startingDate = null;
                        for(AggregateResult agg : [SELECT AccountId__c, MAX(Date__c) latestMonth FROM MRR_Calculation__c WHERE AccountId__c IN :parentAccountsMap.keySet() GROUP BY AccountId__c]){
                            Integer year = ((Date)agg.get('latestMonth')).year();
                            Integer month = ((Date)agg.get('latestMonth')).month();
                            Date latestMonthDate = Date.newInstance(year, month, 1);

                            latestMonthDateByAccount.put((Id)agg.get('AccountId__c'), latestMonthDate);

                            if(startingDate == null || latestMonthDate < startingDate){
                                startingDate = latestMonthDate;
                            }
                        }

                        if(!latestMonthDateByAccount.isEmpty()){

                            // CALCULATE BURDENED MRR FOR EACH ACCOUNT
                            Map<Id, Integer> burdenedMRRByAccount = new Map<Id, Integer>();
                            for(AggregateResult agg : [SELECT AccountId__c, Month__c, Year__c, SUM(MRR__c) burdenedMRR FROM MRR_Calculation__c 
                                                       WHERE AccountId__c IN :parentAccountsMap.keySet() AND Date__c >= :startingDate
                                                       GROUP BY AccountId__c, Month__c, Year__c]){

                                Id accountId = (Id)agg.get('AccountId__c');
                                Integer aggYear = Integer.valueOf(agg.get('Year__c'));
                                Integer aggMonth = Integer.valueOf(agg.get('Month__c'));
                                Integer burdenedMRR = Integer.valueOf(agg.get('burdenedMRR'));

                                if(latestMonthDateByAccount.containsKey(accountId) && latestMonthDateByAccount.get(accountId).year() == aggYear && 
                                   latestMonthDateByAccount.get(accountId).month() == aggMonth){
                                    // ADD CALCULATION TO MAP
                                    burdenedMRRByAccount.put(accountId, burdenedMRR);
                                }
                            }

                            // GET CS DIVISION FOR EACH ACCOUNT
                            List<Account> accountsToUpdate = new List<Account>();
                            Map<Id, String> acctCSDivisionValues = new Map<Id, String>();
                            if(!burdenedMRRByAccount.isEmpty()){

                                // GET BURDENED MRR FROM DIVISIONS
                                List<TM_Division__c> tmDivisions = [SELECT CS_Division__c, Minimum_MRR__c, Maximum_MRR__c FROM TM_Division__c WHERE Is_Active__c = true];
                                for(Id accountId : burdenedMRRByAccount.keySet()){
                                    Account accountToUpdate = parentAccountsMap.get(accountId);
                                    Integer calculatedBurdenedMRR = burdenedMRRByAccount.get(accountId);

                                    // FIND MATCHING CS DIVISION FROM MAPPINGS
                                    String csDivision = '';
                                    for(TM_Division__c tmDivision : tmDivisions){
                                        if((tmDivision.Maximum_MRR__c != null && calculatedBurdenedMRR >= tmDivision.Minimum_MRR__c  && calculatedBurdenedMRR <= tmDivision.Maximum_MRR__c) ||
                                            (tmDivision.Maximum_MRR__c == null && calculatedBurdenedMRR >= tmDivision.Minimum_MRR__c)){
                                            csDivision = tmDivision.CS_Division__c;
                                            break;
                                        }
                                    }

                                    Boolean updateMade = false;
                                    if(String.isNotBlank(csDivision)){
                                        acctCSDivisionValues.put(accountId, csDivision);

                                        // UPDATE ACCOUNT IF NECESARY
                                        if(accountToUpdate.CS_Division_Stamp__c != csDivision){
                                            accountToUpdate.CS_Division_Stamp__c = csDivision;
                                            updateMade = true;
                                        }
                                    }

                                    // PLACE ACCOUNT IN UPDATE LIST IF AN UPDATE WAS MADE
                                    if(updateMade){
                                        accountsToUpdate.add(accountToUpdate); 
                                    }
                                }

                                if(!accountsToUpdate.isEmpty()){
                                    // SAVE ACCOUNTS AND CATCH ANY ERRORS
                                    TriggerHelper.TemporaryOverride('AccountHelper','copyCSDivisionStampToOpps', false); // DISABLE SINCE THE CURRENT CODE WILL UPDATE OPPS.
                                    Database.saveResult[] accountResults = Database.update(accountsToUpdate, false);
                                    SystemIssueLogHelper.CheckForDatabaseErrors(accountResults, 'SBQQSubscriptionHelper', 'updateAccountCSDivision', false);
                                }

                                // GET OPPS THAT NEED TO BE UPDATED
                                if(!acctCSDivisionValues.isEmpty()){
                                    List<Opportunity> oppsToUpdate = new List<Opportunity>();

                                    // GET OPEN OPPS
                                    for(Opportunity opp : [SELECT Id, AccountId, CS_Division__c FROM Opportunity WHERE AccountId IN :acctCSDivisionValues.keySet() AND IsClosed = false]){
                                        if(acctCSDivisionValues.get(opp.AccountId) != opp.CS_Division__c){
                                            oppsToUpdate.add(new Opportunity(Id = opp.Id, CS_Division__c = acctCSDivisionValues.get(opp.AccountId)));
                                        }
                                    }

                                    // GET THE LATEST CLOSED WON IF ANY
                                    for(Opportunity opp : [SELECT Id, AccountId, CS_Division__c FROM Opportunity WHERE AccountId IN :acctCSDivisionValues.keySet() AND 
                                                           IsClosed = true AND IsWon = true AND Type = 'New Business' AND CS_Division__c = null ORDER BY CloseDate DESC LIMIT 1]){
                                        if(acctCSDivisionValues.get(opp.AccountId) != opp.CS_Division__c){
                                            oppsToUpdate.add(new Opportunity(Id = opp.Id, CS_Division__c = acctCSDivisionValues.get(opp.AccountId)));
                                        }
                                    }

                                    // QUEUE PARENT OPPORTUNITIES FOR UPDATE
                                    if(!oppsToUpdate.isEmpty()){
                                        for(Opportunity opp : oppsToUpdate){
                                            if(ParentOppsToUpdate.containsKey(opp.Id)){
                                                ParentOppsToUpdate.get(opp.Id).CS_Division__c = opp.CS_Division__c;
                                            }
                                            else{
                                                ParentOppsToUpdate.put(opp.Id, opp); 
                                            }
                                        }

                                        // SAVE UPDATED OPPS AND CATCH ANY ERRORS
                                        //Database.saveResult[] oppResults = Database.update(oppsToUpdate, false);
                                        //SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'SBQQSubscriptionHelper', 'updateAccountCSDivision', false);
                                    }
                                }
                            }

                            // SAVE LOGGED ERRORS
                            SystemIssueLogHelper.UpsertExceptions();
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQSubscriptionHelper','updateAccountCSDivision');
            }
        }
        catch(Exception ex) {
            SystemIssueLogHelper.LogException('SBQQSubscriptionHelper', 'updateAccountCSDivision', newSubscriptions, ex, true);
        }
    }

    /**
    * @author Conga Services, ERedding
    * @date 20190625
    * @description setUpliftPercentage - Sets the appropriate Renewal Uplift % on subscriptions from Renewal Opportunities
    *                                      ****** EXECUTED BY SBQQ SUBSCRIPTION BEFORE INSERT TRIGGER ******
    * @param List<SBQQ__Subscription__c> newSubscriptions - List of new Subscription records
    * @return void
    */
    public static void setUpliftPercentage(List<SBQQ__Subscription__c> newSubscriptions){
        try{
            if(TriggerHelper.DoExecute('SBQQSubscriptionHelper','setUpliftPercentage') && newSubscriptions != null){

                // GET PARENT QUOTE LINES
                Set<Id> parentQuoteLineIds = new Set<Id>();
                for(SBQQ__Subscription__c subscription : newSubscriptions){
                    if(subscription.SBQQ__QuoteLine__c != null){
                        parentQuoteLineIds.add(subscription.SBQQ__QuoteLine__c);
                    }
                }

                if(!parentQuoteLineIds.isEmpty()){

                    // GET PARENT RENEWAL QUOTES
                    Map<Id, SBQQ__QuoteLine__c> parentQuoteLinesMap = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, SBQQ__SubscriptionPricing__c, SBQQ__Quote__r.SBQQ__Account__r.Renewal_Uplift_Cap__c
                                                                                                       FROM SBQQ__QuoteLine__c 
                                                                                                       WHERE Id IN :parentQuoteLineIds
                                                                                                       AND SBQQ__Quote__r.SBQQ__Account__r.SBQQ__RenewalPricingMethod__c = 'Uplift']);
                    // PROCESS QUOTE LINES
                    for(SBQQ__Subscription__c newSubscription : newSubscriptions){
                        SBQQ__QuoteLine__c parentQuoteLine = parentQuoteLinesMap != null ? parentQuoteLinesMap.get(newSubscription.SBQQ__QuoteLine__c) : null;
                        if(parentQuoteLine != null && parentQuoteLine.SBQQ__SubscriptionPricing__c != 'Percent Of Total' && 
                            newSubscription.SBQQ__CustomerPrice__c < newSubscription.SBQQ__ListPrice__c){

                            Decimal upliftCap = (UtilityClass.replaceNull(parentQuoteLine.SBQQ__Quote__r.SBQQ__Account__r.Renewal_Uplift_Cap__c, 0.00) / 100);
                            Decimal upliftPercent = upliftCap <= 0.00 || upliftCap > 0.08 ? 0.08 : upliftCap;
                            Decimal upliftedPrice = newSubscription.SBQQ__CustomerPrice__c * (1 + upliftPercent);

                            if(upliftedPrice < newSubscription.SBQQ__ListPrice__c){
                                newSubscription.SBQQ__RenewalUpliftRate__c = upliftPercent * 100; // UPLIFT DOES NOT GO OVER LIST, USE UPLIFT PERCENTAGE
                            }
                            else{
                                // UPLIFT GOES OVER LIST, CALCULATE RATE
                                Decimal calcPercentage = ((newSubscription.SBQQ__ListPrice__c - newSubscription.SBQQ__CustomerPrice__c) / newSubscription.SBQQ__CustomerPrice__c) * 100;
                                newSubscription.SBQQ__RenewalUpliftRate__c = calcPercentage;
                            }
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQSubscriptionHelper','setUpliftPercentage');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQSubscriptionHelper', 'setUpliftPercentage', newSubscriptions, ex, true);
        }
    }

    /**
    * @author ECS, ERedding
    * @date 20190723
    * @description calculateTotalDiscount - Calculate the overall subscription discount values for subscriptions with qualifying changes
    *                                          ****** EXECUTED BY SUBSCRIPTION AFTER INSERT, AFTER UPDATE, AND AFTER DELETE TRIGGERS ******
    * @param List<SBQQ__Subscription__c> newOrUpdatedSubscription - List of new or updated Subscription records
    * @param Map<Id, SBQQ__Subscription__c> outdatedOrDeletedSubscriptions - Map of outdated or deleted Subscription records
    * @return void
    */
    public static void calculateTotalDiscount(List<SBQQ__Subscription__c> newOrUpdatedSubscriptions, Map<Id, SBQQ__Subscription__c> outdatedOrDeletedSubscriptions){
        try{
            if(TriggerHelper.DoExecute('SBQQSubscriptionHelper','calculateTotalDiscount') && (newOrUpdatedSubscriptions != null || outdatedOrDeletedSubscriptions != null)){
                // GET QUALIFYING QUOTES
                Set<Id> parentContractIds = new Set<Id>();
                if(newOrUpdatedSubscriptions != null){
                    // NEW OR UPDATED, QUALIFY
                    for(SBQQ__Subscription__c newOrUpdatedSubscription : newOrUpdatedSubscriptions){
                        SBQQ__Subscription__c outdatedSubscription = outdatedOrDeletedSubscriptions != null ? outdatedOrDeletedSubscriptions.get(newOrUpdatedSubscription.Id) : null;
                        if(outdatedSubscription == null || newOrUpdatedSubscription.SBQQ__Product__c != outdatedSubscription.SBQQ__Product__c ||
                                                           newOrUpdatedSubscription.SBQQ__StartDate__c != outdatedSubscription.SBQQ__StartDate__c ||
                                                           newOrUpdatedSubscription.SBQQ__EndDate__c != outdatedSubscription.SBQQ__EndDate__c ||
                                                           newOrUpdatedSubscription.SBQQ__ListPrice__c != outdatedSubscription.SBQQ__ListPrice__c ||
                                                           newOrUpdatedSubscription.SBQQ__CustomerPrice__c != outdatedSubscription.SBQQ__CustomerPrice__c ||
                                                           newOrUpdatedSubscription.Original_List_Price__c != outdatedSubscription.Original_List_Price__c ||
                                                           newOrUpdatedSubscription.Original_Unprorated_Customer_Unit_Price__c != outdatedSubscription.Original_Unprorated_Customer_Unit_Price__c ||
                                                           newOrUpdatedSubscription.SBQQ__Quantity__c != outdatedSubscription.SBQQ__Quantity__c ||
                                                           newOrUpdatedSubscription.SBQQ__Contract__c != outdatedSubscription.SBQQ__Contract__c ||
                                                           newOrUpdatedSubscription.SBQQ__Discount__c != outdatedSubscription.SBQQ__Discount__c ||
                                                           newOrUpdatedSubscription.SBQQ__AdditionalDiscountAmount__c != outdatedSubscription.SBQQ__AdditionalDiscountAmount__c){
                            parentContractIds.add(newOrUpdatedSubscription.SBQQ__Contract__c);
                        }
                    }
                }
                else if(newOrUpdatedSubscriptions == null && outdatedOrDeletedSubscriptions != null){
                    // DELETED, ALL QUALIFY
                    for(SBQQ__Subscription__c deletedSubscription : outdatedOrDeletedSubscriptions.values()){
                        parentContractIds.add(deletedSubscription.SBQQ__Contract__c);
                    }
                }

                // PROCESS QUALIFIED QUOTES
                if(!parentContractIds.isEmpty()){

                    // LOAD ALL CHILD QUOTE LINES
                    Map<Id, List<SBQQ__Subscription__c>> subscriptionsByContract = new Map<Id, List<SBQQ__Subscription__c>>();
                    for(SBQQ__Subscription__c subscription : [SELECT Id, SBQQ__Contract__c, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__ListTotal__c, SBQQ__QuoteLine__r.SBQQ__CustomerTotal__c,
                                                              SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__CustomerPrice__c, Original_List_Price__c, Original_Unprorated_Customer_Unit_Price__c
                                                              FROM SBQQ__Subscription__c 
                                                              WHERE SBQQ__Contract__c IN :parentContractIds AND SBQQ__Product__r.FY16_Revenue_Type__c = 'Recurring'
                                                              AND (SBQQ__ListPrice__c > 0 OR (SBQQ__ListPrice__c = 0 AND SBQQ__PricingMethod__c = 'Percent of Total'))]){
                        if(!subscriptionsByContract.containsKey(subscription.SBQQ__Contract__c)){
                            subscriptionsByContract.put(subscription.SBQQ__Contract__c, new List<SBQQ__Subscription__c>());
                        }
                        subscriptionsByContract.get(subscription.SBQQ__Contract__c).add(subscription);
                    }

                    // CALCULATE TOTAL DISCOUNT PERCENTAGE FOR QUOTES
                    List<Contract> contractsToUpdate = new List<Contract>();
                    for(Id contractId : subscriptionsByContract.keySet()){
                        Decimal originalListPriceTotal = 0.00;
                        Decimal originalCustomerPriceTotal = 0.00;
                        Decimal currentListPriceTotal = 0.00;
                        Decimal currentCustomerPriceTotal = 0.00;

                        for(SBQQ__Subscription__c subscription : subscriptionsByContract.get(contractId)){

                            // GET DATA FOR ORIGINAL DISCOUNT                            
                            if(subscription.SBQQ__QuoteLine__c != null){
                                originalListPriceTotal += UtilityClass.replaceNull(subscription.SBQQ__QuoteLine__r.SBQQ__ListTotal__c, 0.00);
                                originalCustomerPriceTotal += UtilityClass.replaceNull(subscription.SBQQ__QuoteLine__r.SBQQ__CustomerTotal__c, 0.00);
                            }
                            else{
                                originalListPriceTotal += UtilityClass.replaceNull(subscription.SBQQ__ListPrice__c, 0.00) * subscription.SBQQ__Quantity__c;
                                originalCustomerPriceTotal += UtilityClass.replaceNull(subscription.SBQQ__CustomerPrice__c, 0.00) * subscription.SBQQ__Quantity__c;
                            }

                            // GET DATA FOR CURRENT DISCOUNT
                            currentListPriceTotal += UtilityClass.replaceNull(subscription.Original_List_Price__c, 0.00) * subscription.SBQQ__Quantity__c;
                            currentCustomerPriceTotal += UtilityClass.replaceNull(subscription.Original_Unprorated_Customer_Unit_Price__c, 0.00) * subscription.SBQQ__Quantity__c;
                        }

                        Decimal originalOverallDiscount = 0.00;
                        Decimal currentOverallDiscount = 0.00;
                        // CALCULATE ORIGINAL DISCOUNT
                        if(originalListPriceTotal > 0){
                            originalOverallDiscount = ((originalListPriceTotal - originalCustomerPriceTotal) / originalListPriceTotal) * 100;
                        }
                        // CALCULATE CURRENT DISCOUNT
                        if(currentListPriceTotal > 0){
                            currentOverallDiscount = ((currentListPriceTotal - currentCustomerPriceTotal) / currentListPriceTotal) * 100;
                        }

                        // ADD QUOTE TO UPDATE LIST
                        contractsToUpdate.add(new Contract(Id = contractId, Overall_Subscription_Discount__c = originalOverallDiscount,
                                                                            Current_Overall_Subscription_Discount__c = currentOverallDiscount));
                    }

                    // QUEUE PARENT CONTRACTS FOR UPDATE
                    if(!contractsToUpdate.isEmpty()){
                        for(Contract contract : contractsToUpdate){
                            if(ParentContractsToUpdate.containsKey(contract.Id)){
                                ParentContractsToUpdate.get(contract.Id).Overall_Subscription_Discount__c = contract.Overall_Subscription_Discount__c;
                                ParentContractsToUpdate.get(contract.Id).Current_Overall_Subscription_Discount__c = contract.Current_Overall_Subscription_Discount__c;
                            }
                            else{
                                ParentContractsToUpdate.put(contract.Id, contract); 
                            }
                        }

                        //Database.saveResult[] updateResults = Database.update(contractsToUpdate, false);
                        //SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'SBQQSubscriptionHelper', 'calculateTotalDiscount', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQSubscriptionHelper','calculateTotalDiscount');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQSubscriptionHelper', 'calculateTotalDiscount', (newOrUpdatedSubscriptions != null ? newOrUpdatedSubscriptions : outdatedOrDeletedSubscriptions.values()), ex, true);
        } 
    }


    /**
    * @author ECS, ERedding
    * @date 20200227
    * @description updateParentContractDates - Updates active parent contracts with the MIN start and MAX end of all child subscriptions when child subscription dates change
    *                                            ****** EXECUTED BY SUBSCRIPTION AFTER UPDATE TRIGGER ******
    * @param List<SBQQ__Subscription__c> newOrUpdatedSubs - List of new or updated Subscription records
    * @param Map<Id, SBQQ__Subscription__c> outdatedSubs - Map of outdated Subscription records
    * @return void
    */
    public static void updateParentContractDates(List<SBQQ__Subscription__c> newOrUpdatedSubs, Map<Id, SBQQ__Subscription__c> outdatedSubs){
        try{
            if(TriggerHelper.DoExecute('SBQQSubscriptionHelper','updateParentContractDates') && newOrUpdatedSubs != null){
                // GET PARENT CONTRACT IDS OF QUALIFYING SUBSCRIPTIONS
                Set<Id> parentContractIds = new Set<Id>();
                for(SBQQ__Subscription__c newOrUpdatedSub : newOrUpdatedSubs){
                    SBQQ__Subscription__c outdatedSub = outdatedSubs != null ? outdatedSubs.get(newOrUpdatedSub.Id) : null;
                    if(outdatedSub != null && (newOrUpdatedSub.SBQQ__SubscriptionStartDate__c != outdatedSub.SBQQ__SubscriptionStartDate__c ||
                                               newOrUpdatedSub.SBQQ__SubscriptionEndDate__c != outdatedSub.SBQQ__SubscriptionEndDate__c)){
                        // EITHER START DATE OR END DATE HAS CHANGED
                        parentContractIds.add(newOrUpdatedSub.SBQQ__Contract__c);
                    }
                }

                // GET ACTIVE CONTRACTS AND THEIR CURRENT DATES
                Map<Id, Contract> activeContracts = new Map<Id, Contract>([SELECT Id, StartDate, EndDate FROM Contract WHERE Id IN :parentContractIds AND Status = 'Activated']);

                // PERFORM AN AGGREGATE TO FIND THE MIN START AND MAX END FROM SUBSCRIPTIONS RELATED TO ACTIVE CONTRACTS
                List<Contract> contractsToUpdate = new List<Contract>();
                for(AggregateResult agg : [SELECT SBQQ__Contract__c, MIN(SBQQ__SubscriptionStartDate__c) min, MAX(SBQQ__SubscriptionEndDate__c) max FROM SBQQ__Subscription__c
                                           WHERE SBQQ__Contract__c IN :activeContracts.keySet() GROUP BY SBQQ__Contract__c]){
                    Date startDate = (Date)agg.get('min');
                    Date endDate = (Date)agg.get('max');
                    Id contractId = (Id)agg.get('SBQQ__Contract__c');

                    // UPDATE CONTRACTS IF NECESSARY
                    if(activeContracts.containsKey(contractId) && (activeContracts.get(contractId).StartDate != startDate || activeContracts.get(contractId).EndDate != endDate)){
                        contractsToUpdate.add(new Contract(Id = contractId, StartDate = startDate, EndDate = endDate));
                    }
                }

                // UPDATE CONTRACTS
                if(!contractsToUpdate.isEmpty()){
                    for(Contract contract : contractsToUpdate){
                        if(ParentContractsToUpdate.containsKey(contract.Id)){
                            ParentContractsToUpdate.get(contract.Id).StartDate = contract.StartDate;
                            ParentContractsToUpdate.get(contract.Id).EndDate = contract.EndDate;
                        }
                        else{
                            ParentContractsToUpdate.put(contract.Id, contract); 
                        }
                    }

                    //Database.saveResult[] updateResults = Database.update(contractsToUpdate, false);
                    //SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'SBQQSubscriptionHelper', 'updateParentContractDates', true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('SBQQSubscriptionHelper','updateParentContractDates');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('SBQQSubscriptionHelper', 'updateParentContractDates', newOrUpdatedSubs, ex, true);
        } 
    }


}