public with sharing class OpportunityHandler {
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
///////// REDPOINT DEVELOPED CODE ///////////////////////////////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

    // COUNTRY CODES BY NAME
    private static Map<String, String> CountryCodesByName {
    get {
        if(CountryCodesByName == null){
            CountryCodesByName = new Map<String, String>();
            for(Country_Territory__c country : [SELECT Name, Two_Letter_Code__c FROM Country_Territory__c]){
                countryCodesByName.put(country.Name, country.Two_Letter_Code__c);
            }
        }
        return CountryCodesByName;
    } set; }



    /*
     * author: Conga, KSears
     * date: 5/7/2019
     * purpose: Trigger entry point for manual opportunity/COA order handling. 
                The system should handle this automatically through the Batchable_OpportuniyCOA class
                but just in case there are still errors to work out, this will allow them to be submitted
                manually when checking the Trigger_COA_automation__c field on the opportunity.  
        OpportunityHandler.coaTriggerEntryPoint((Map<Id,Opportunity>)tp.newMap); goes in afterInserthandler
    */
    public static void coaTriggerEntryPoint(Map<Id, Opportunity> oppMap){
        if(TriggerHelper.DoExecute('OpportunityHandler', 'coaTriggerEntryPoint') && oppMap != null){
            Map<Id,Opportunity> qualifiedOppMap = new Map<Id,Opportunity>();
            for(Opportunity opp : oppMap.values()){
                if(opp.Trigger_COA_automation__c && opp.Sub_Type__c != 'Forecasting Opportunity'){
                    qualifiedOppMap.put(opp.Id,opp);
                }
            }
            if(qualifiedOppMap.size() > 0){
                closedWonOpportunityPath(qualifiedOppMap);
            }     
        }
    }

    /*
     * author: Redpoint
     * date: 9/12/2017
     * purpose: Takes in the updated opportunities and determines whether
     * new orders need to be created or if the opportunity needs to
     * go to the Opportunity Queue.
     * note:
     * CONGA SERVICES ER 20180806 - RECORD QUALIFICATION CODE MOVED INTO THIS TRIGGER METHOD FROM THE HANDLER
     * CONGA SERVICES ER 20190129 - ADDED TRIGGERHELPER DOEXECUTE METHOD TO ADD THE ABILITY TO TURN THIS TRIGGER CODE OFF IF NECESSARY
    */
    public static void closedWonOpportunityPath(Map<Id, Opportunity> oppMap) {
        //if(TriggerHelper.DoExecute('Opportunity.closedWonOpportunityPath') && oppMap != null && !oppMap.isEmpty()){
            Set<Id> qualifiedOppIds = new Set<Id>(); //oppMap.keySet();
            for(Opportunity opp : oppMap.values()){
                if(opp.Create_Service_Order__c && !opp.Service_Order_Created__c){
                    qualifiedOppIds.add(opp.Id);
                }
            }

            if(!qualifiedOppIds.isEmpty()){
                Map<Id, String> queuedOpportunities = new Map<Id, String>();
                List<Opportunity> opportunityDetails = new List<Opportunity>();
                List<Opportunity> opportunityOrder = new List<Opportunity>();

                //Query for the Opps so that related account field values aren't null
                for(Opportunity o : [SELECT Id, Customer_Org_Id_15_digit__c, Type, Sales_Ops_Approved__c, Account.Name, Account.Id, Account.BillingStreet,
                                            Account.BillingState, Account.BillingCountry, Account.BillingPostalCode, Account.BillingCity,
                                            (SELECT OpportunityId, ServiceDate, Product2.Name, Product_End_Date__c, Quantity, PricebookEntry.Partner_Product_Catalog__c, 
                                                    PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c, PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c,
                                                    Product_Unit_Price_per_Month__c
                                            FROM OpportunityLineItems)
                                        FROM Opportunity
                                        WHERE Id IN: qualifiedOppIds])
                {
                    opportunityDetails.add(o);
                }

                if(!opportunityDetails.isEmpty()) {
                    for(Opportunity opp : opportunityDetails) {
                        if(checkIfSegmentedOpportunity(opp, opp.OpportunityLineItems)){
                            queuedOpportunities.put(opp.Id, 'Segmented Deal');
                        } 
                        else{
                            opportunityOrder.add(opp);
                        }
                    }
                }

                if(!opportunityOrder.isEmpty()) {
                    createNewOrdersForOpportunities(opportunityOrder);
                }

                if(!queuedOpportunities.isEmpty()) {
                    addRecordsToOpportunityQueue(queuedOpportunities);
                }
            }
        //}
    }

    /*
     * author: Redpoint
     * date: 9/12/2017
     * purpose: If an opportunity does not meet the requirements for automation
     * a COA Exception record will be created for it with a status detailing why
     * new service orders were not created.
     * note:
    */
    public static void addRecordsToOpportunityQueue(Map<Id, String> opps) {
        // 2018-01-17 gmodica
        // optimization of method

        List<COA_Exception__c> insertExceptions = new List<COA_Exception__c>();
        List<COA_Exception__c> updateExceptions = new List<COA_Exception__c>();
        Set<Id> oppIds = opps.keySet();
        List<COA_Exception__c> existingExceptions = [SELECT Id, Related_Opportunity__c FROM COA_Exception__c where Related_Opportunity__c in :oppIds];

        Map<Id,List<COA_Exception__c>> oppsWithExceptions = new Map<Id,List<COA_Exception__c>>();
        for(COA_Exception__c existingRecord : existingExceptions) {                
            if(!oppsWithExceptions.containsKey(existingRecord.Related_Opportunity__c)){
                oppsWithExceptions.put(existingRecord.Related_Opportunity__c, new List<COA_Exception__c>());
            }
            oppsWithExceptions.get(existingRecord.Related_Opportunity__c).add(existingRecord);
        }

        for(Id opportunityId : oppIds) {
            String status = opps.get(opportunityId);

            if(!oppsWithExceptions.containsKey(opportunityId)) {
                COA_Exception__c e = new COA_Exception__c();
                e.Related_Opportunity__c = opportunityId;
                e.Status__c = status;

                if(status == 'Segmented Deal'){
                    e.Segmented_Deal__c = TRUE;
                }
                if(status.contains('Draft created')){
                    e.Draft_Service_Order_Created__c = TRUE;
                }

                insertExceptions.add(e);           
            } 
            else {
                List<COA_Exception__c> opportunityExceptions = oppsWithExceptions.get(opportunityId);
                if(opportunityExceptions != null && !opportunityExceptions.isEmpty()) {
                    for(COA_Exception__c ex : opportunityExceptions) {
                        ex.Status__c = status;

                        if(status == 'Segmented Deal'){
                            ex.Segmented_Deal__c = TRUE;
                        }
                        if(status.contains('Draft created')){
                            ex.Draft_Service_Order_Created__c = TRUE;
                        }

                        updateExceptions.add(ex);
                    }
                }
            }
        }

        if(!insertExceptions.isEmpty()){
            insert insertExceptions;
        }

        if(!updateExceptions.isEmpty()) {
            update updateExceptions;
        }
    }

    /*
     * author: Redpoint
     * date: 9/15/2017
     * purpose: Loop through Opporunity Line Items and compare start dates to determine if the Opp is segmented
     * note:
    */
    public static Boolean checkIfSegmentedOpportunity(Opportunity opp, List<OpportunityLineItem> olis){
        Boolean isSegmentedOpp = FALSE;

        //Check to ensure there are products on the opp and initialize comparison variables
        if(!olis.isEmpty()){
            Date startDate = olis[0].ServiceDate;
            Set<Date> allStartDates = new Set<Date>();

            //Loop through products on opp
            for(OpportunityLineItem oli : olis){
                //Check if the product name and start dates are the same
                if(oli.ServiceDate != null){
                    allStartDates.add(oli.ServiceDate);
                }
                
                //ksears - original code:
                // if(oli.ServiceDate == startDate){
                //     Continue;
                // //Check if the product name and start date are different. If so, add to queue
                // }else if(startDate != oli.ServiceDate){
                //     isSegmentedOpp = TRUE;
                //     BREAK;
                // }
            }
            if(allStartDates.size() > 1){
                isSegmentedOpp = TRUE;
            }
        }

        return isSegmentedOpp;
    }

    /*
     * author: Redpoint
     * date: 9/15/2017
     * purpose: Build out new Service Order record
     * note:
    */
    public static CHANNEL_ORDERS__Service_Order__c buildServiceOrder(Opportunity opp, CHANNEL_ORDERS__Customer__c customer, String orderType, Id contractTermsId, Date serviceDate){
        CHANNEL_ORDERS__Service_Order__c serviceOrder = new CHANNEL_ORDERS__Service_Order__c();
        serviceOrder.CHANNEL_ORDERS__Customer__c = customer.Id;
        serviceOrder.CHANNEL_ORDERS__Customer_Org_ID__c = customer.CHANNEL_ORDERS__Customer_Org_ID__c;
        serviceOrder.CHANNEL_ORDERS__Service_Order_Status__c = 'Draft';
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_City__c = opp.Account.BillingCity;
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_State__c = opp.Account.BillingState;
        //serviceOrder.CHANNEL_ORDERS__Customer_Billing_Country__c = opp.Account.BillingCountry;
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_Country__c = 'US';
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_Street__c = opp.Account.BillingStreet;
        serviceOrder.CHANNEL_ORDERS__Customer_Billing_Zip_Postal_Code__c = opp.Account.BillingPostalCode;
        serviceOrder.CHANNEL_ORDERS__Customer_Name__c = opp.Account.Name;
        serviceOrder.CHANNEL_ORDERS__Related_Opportunity__c = opp.Id;
        serviceOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c = contractTermsId;
        serviceOrder.CHANNEL_ORDERS__Order_Type__c = orderType;
        //serviceOrder.CHANNEL_ORDERS__Service_Start_Date__c = serviceDate;  //// CONGA SERVICES ER 20180702 - DATE CANNOT BE IN THE PAST, ADDED CONDITION
        serviceOrder.CHANNEL_ORDERS__Service_Start_Date__c = serviceDate >= Date.today() ? serviceDate : Date.today();
        serviceOrder.CHANNEL_ORDERS__Date_Partner_Received_Customer_Order__c = Date.today();
        serviceOrder.CHANNEL_ORDERS__I_certify__c = 'Yes';
        return serviceOrder;
    }

    /*
     * author: Redpoint
     * date: 9/15/2017
     * purpose: Build out new Customer record
     * note:
    */
    public static CHANNEL_ORDERS__Customer__c buildNewCOACustomer(Opportunity opp){
        // GET COUNTRY CODES BY NAME
        Map<String, String> countryCodesByName = new Map<String, String>();
        for(Country_Territory__c country : [SELECT Name, Two_Letter_Code__c FROM Country_Territory__c]){
            countryCodesByName.put(country.Name, country.Two_Letter_Code__c);
        }

        CHANNEL_ORDERS__Customer__c newCustomer = new CHANNEL_ORDERS__Customer__c();
        newCustomer.CHANNEL_ORDERS__Account__c = opp.Account.Id;
        newCustomer.CHANNEL_ORDERS__Customer_Company_Name__c = opp.Account.Name;
        newCustomer.CHANNEL_ORDERS__Customer_Org_ID__c = opp.Customer_Org_Id_15_digit__c;
        newCustomer.CHANNEL_ORDERS__Customer_Street__c = opp.Account.BillingStreet;
        newCustomer.CHANNEL_ORDERS__Customer_State__c = opp.Account.BillingState;
        newCustomer.CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = opp.Account.BillingPostalCode;
        newCustomer.CHANNEL_ORDERS__Customer_City__c = opp.Account.BillingCity;
        //newCustomer.CHANNEL_ORDERS__Customer_Country__c = opp.Account.BillingCountry;
        if(opp.Account.BillingCountry.length() > 2){
            newCustomer.CHANNEL_ORDERS__Customer_Country__c = CountryCodesByName.get(opp.Account.BillingCountry);
        }else{
            newCustomer.CHANNEL_ORDERS__Customer_Country__c = opp.Account.BillingCountry;
        }
        return newCustomer;
    }

    /*
     * author: Redpoint
     * date: 9/18/2017
     * purpose: Build out new Service Order Detail record
     * note:
    */
    public static CHANNEL_ORDERS__Service_Order_Detail__c buildSOProduct(Id productCatalogId, Decimal quantity, Id termsId, Decimal price){
        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = new CHANNEL_ORDERS__Service_Order_Detail__c();
        soDetail.CHANNEL_ORDERS__Product_Name__c = productCatalogId;
        soDetail.CHANNEL_ORDERS__pc_Partner_Contract_Term__c = termsId;
        soDetail.CHANNEL_ORDERS__Quantity__c = quantity;
        soDetail.CHANNEL_ORDERS__Customer_Price_Per_Month__c = price;
        soDetail.CHANNEL_ORDERS__pct_Currency__c = 'USD';
        return soDetail;
    }

    /*
     * author: Redpoint
     * date: 9/15/2017
     * purpose: Get the delta (difference) in quantities for related products via the mapping field chosen (Product Name for now)
     * note:
    */
    public static Map<String, Integer> calculateDelta(List<OpportunityLineItem> olis, List<CHANNEL_ORDERS__Service_Order__c> soList){
        Decimal delta;
        Integer counter = 0;
        Integer soQuantitySum = 0; 
        Integer sameProductQuantity = 0; 
        String sameProductAppName = olis[0].PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c;
        String prodAppName = olis[0].PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c;
        Map<String, Integer> soQuantityTotalMap = new Map<String, Integer>();
        Map<String, Integer> oppQuantityTotalMap = new Map<String, Integer>();
        Map<String, Integer> productToDeltaMap = new Map<String, Integer>();

        //Get the total quantity of the same product from existing orders
        for(CHANNEL_ORDERS__Service_Order__c so : soList){
            for(CHANNEL_ORDERS__Service_Order_Detail__c orderProduct : so.CHANNEL_ORDERS__Partner_Order_Detail__r){
                if(soQuantityTotalMap.containsKey(orderProduct.CHANNEL_ORDERS__Product_Name__r.CHANNEL_ORDERS__Partner_Application_Name__c)){
                    Integer q = soQuantityTotalMap.get(orderProduct.CHANNEL_ORDERS__Product_Name__r.CHANNEL_ORDERS__Partner_Application_Name__c);

                    soQuantityTotalMap.put(orderProduct.CHANNEL_ORDERS__Product_Name__r.CHANNEL_ORDERS__Partner_Application_Name__c, q + orderProduct.CHANNEL_ORDERS__Quantity__c.intValue());
                }
                else{
                    soQuantityTotalMap.put(orderProduct.CHANNEL_ORDERS__Product_Name__r.CHANNEL_ORDERS__Partner_Application_Name__c, orderProduct.CHANNEL_ORDERS__Quantity__c.intValue());
                }               
            }   
        }

        //Get the total quantity for OLIs of the same name
        for(OpportunityLineItem oli : olis){
            if(prodAppName == oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c){
                if(oppQuantityTotalMap.containsKey(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c)){
                    Integer value = oppQuantityTotalMap.get(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c);
                    oppQuantityTotalMap.put(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c, value + oli.Quantity.intValue());
                }
                else{
                    oppQuantityTotalMap.put(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c, oli.Quantity.intValue());
                }
            }
            else{
                prodAppName = oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c;
            }
        }


        for(CHANNEL_ORDERS__Service_Order__c so : soList){
            counter ++;         
            for(CHANNEL_ORDERS__Service_Order_Detail__c orderProduct : so.CHANNEL_ORDERS__Partner_Order_Detail__r){
                for(OpportunityLineItem oli : olis){
                    if(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c == orderProduct.CHANNEL_ORDERS__Product_Name__r.CHANNEL_ORDERS__Partner_Application_Name__c){ //Mapping
                        if(counter > 1){
                            soQuantitySum = soQuantityTotalMap.get(orderProduct.CHANNEL_ORDERS__Product_Name__r.CHANNEL_ORDERS__Partner_Application_Name__c);
                            delta = oli.Quantity - soQuantitySum;    
                            if(sameProductAppName == oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c){
                                delta = oppQuantityTotalMap.get(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c) - soQuantitySum;
                            }
                            else{
                                sameProductAppName = oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c;
                            }                        
                        }
                        else if(oli.Quantity == orderProduct.CHANNEL_ORDERS__Quantity__c){
                            delta = 0;
                        }
                        else{
                            delta = oli.Quantity - orderProduct.CHANNEL_ORDERS__Quantity__c;
                            if(sameProductAppName == oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c){
                                soQuantitySum = soQuantityTotalMap.get(orderProduct.CHANNEL_ORDERS__Product_Name__r.CHANNEL_ORDERS__Partner_Application_Name__c);
                                delta = oppQuantityTotalMap.get(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c) - soQuantitySum;
                            }
                            else{
                                sameProductAppName = oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c;
                            }                                  
                        }
                        productToDeltaMap.put(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c, delta.intValue());                            
                    }
                }
            }
        }
        return productToDeltaMap;
    }

    /*
     * author: Redpoint
     * date: 9/20/2017
     * purpose: If there are products with different contract terms create a Service Order for each contract term with the appropriate products on it.
     * note:
    */
    public static Map<CHANNEL_ORDERS__Service_Order__c, List<CHANNEL_ORDERS__Service_Order_Detail__c>> createMultipleOrdersForNewOrExistingBusiness(Map<Id, List<OpportunityLineItem>> contractIdToLineItems, 
        Opportunity o, String orderType, CHANNEL_ORDERS__Customer__c customer){

        Map<CHANNEL_ORDERS__Service_Order__c, List<CHANNEL_ORDERS__Service_Order_Detail__c>> orderToProductsMap = new Map<CHANNEL_ORDERS__Service_Order__c, List<CHANNEL_ORDERS__Service_Order_Detail__c>>();
        
        for(Id contractId : contractIdToLineItems.keySet()){
            List<OpportunityLineItem> lines = contractIdToLineItems.get(contractId);
            Date serviceDate = lines[0].ServiceDate;
            CHANNEL_ORDERS__Service_Order__c so = buildServiceOrder(o, customer, orderType, contractId, serviceDate);
            List<CHANNEL_ORDERS__Service_Order_Detail__c> soProductList = new List<CHANNEL_ORDERS__Service_Order_Detail__c>();
            for(OpportunityLineItem line : lines){         
                CHANNEL_ORDERS__Service_Order_Detail__c orderLine = new CHANNEL_ORDERS__Service_Order_Detail__c();
                orderLine.CHANNEL_ORDERS__Product_Name__c = line.PricebookEntry.Partner_Product_Catalog__c;
                orderLine.CHANNEL_ORDERS__Quantity__c = line.Quantity;
                orderLine.CHANNEL_ORDERS__pc_Partner_Contract_Term__c = line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c;
                //orderLine.CHANNEL_ORDERS__Partner_Order__c = so.Id;

                // CONGA SERVICES ER 20180808 - ADDED THESE TWO LINES TO FIX MISSING SERVICE ORDER DETAIL PRICE ISSUE. SR~12118
                orderLine.CHANNEL_ORDERS__Customer_Price_Per_Month__c = line.Product_Unit_Price_per_Month__c;
                orderLine.CHANNEL_ORDERS__pct_Currency__c = 'USD';

                soProductList.add(orderLine);
                serviceDate = line.ServiceDate;
            }
            so.CHANNEL_ORDERS__Partner_Contract_Rules__c = contractId;
            so.CHANNEL_ORDERS__Date_Partner_Received_Customer_Order__c = serviceDate;
            orderToProductsMap.put(so, soProductList);
        }
        return orderToProductsMap;     
    }

    public static Map<String, List<CHANNEL_ORDERS__Service_Order__c>> createMultipleOrdersForRenewal(Opportunity o, String orderType, 
        CHANNEL_ORDERS__Customer__c customer, Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> renewalOppIdToDetailMap, Date serviceDate, Set<String> contractIds){

        Map<String, List<CHANNEL_ORDERS__Service_Order__c>> multipleRenewalOrdersMap = new Map<String, List<CHANNEL_ORDERS__Service_Order__c>>();
        
        for(String contractId : contractIds){
            CHANNEL_ORDERS__Service_Order__c so = buildServiceOrder(o, customer, orderType, contractId, serviceDate);
            so.CHANNEL_ORDERS__Partner_Contract_Rules__c = contractId;
            so.CHANNEL_ORDERS__Date_Partner_Received_Customer_Order__c = serviceDate;
            if(multipleRenewalOrdersMap.containsKey(contractId)){
                multipleRenewalOrdersMap.get(contractId).add(so);
            }
            else{
                multipleRenewalOrdersMap.put(contractId, new List<CHANNEL_ORDERS__Service_Order__c> {so});
            }
        }
        return multipleRenewalOrdersMap;     
    }

    public static List<CHANNEL_ORDERS__Service_Order__c> queryExistingOrders(List<String> orgIds){
        List<CHANNEL_ORDERS__Service_Order__c> existingOrders = [SELECT Id, CHANNEL_ORDERS__Customer_Org_ID__c, CHANNEL_ORDERS__Related_Opportunity__c,
                                                                    (SELECT Id, CHANNEL_ORDERS__Quantity__c, CHANNEL_ORDERS__Product_Name__c, CHANNEL_ORDERS__Partner_Order__c, CHANNEL_ORDERS__Product_Name__r.CHANNEL_ORDERS__Partner_Application_Name__c
                                                                    FROM CHANNEL_ORDERS__Partner_Order_Detail__r)
                                                                FROM CHANNEL_ORDERS__Service_Order__c
                                                                WHERE CHANNEL_ORDERS__Customer_Org_ID__c IN: orgIds
                                                                ];
        return existingOrders;
    }

    public static List<CHANNEL_ORDERS__Customer__c> queryExistingCustomers(List<String> orgIds){
        List<CHANNEL_ORDERS__Customer__c> existingCustomers =   [SELECT Id, CHANNEL_ORDERS__Customer_Company_Name__c, CHANNEL_ORDERS__Customer_Org_ID__c 
                                                                 FROM CHANNEL_ORDERS__Customer__c 
                                                                 WHERE CHANNEL_ORDERS__Customer_Org_ID__c IN: orgIds
                                                                ];
        return existingCustomers;                                                                    
    }

    public static Map<String, CHANNEL_ORDERS__Partner_Product_Catalog__c> queryPartnerProductCatologs(){
        Map<String, CHANNEL_ORDERS__Partner_Product_Catalog__c> ppcMap = new Map<String, CHANNEL_ORDERS__Partner_Product_Catalog__c>();
        List<CHANNEL_ORDERS__Partner_Product_Catalog__c> ppcList = [SELECT CHANNEL_ORDERS__Billing_Frequency__c, CHANNEL_ORDERS__Contract_Auto_Renew__c, CHANNEL_ORDERS__Contract_Length__c, CHANNEL_ORDERS__Renewal_Terms__c, CHANNEL_ORDERS__Cancellation_Terms__c
                                                                    FROM CHANNEL_ORDERS__Partner_Product_Catalog__c
                                                                   ];

        for(CHANNEL_ORDERS__Partner_Product_Catalog__c ppc : ppcList){
            if(!ppcMap.containsKey(ppc.Id)){
                ppcMap.put(ppc.Id, ppc);
            }
        }
        return ppcMap;
    }

    public static Map<String, List<CHANNEL_ORDERS__Service_Order__c>> buildExistingServiceOrdersMap(List<CHANNEL_ORDERS__Service_Order__c> existingOrders){
        Map<String, List<CHANNEL_ORDERS__Service_Order__c>> existingServiceOrdersMap = new Map<String, List<CHANNEL_ORDERS__Service_Order__c>>();
        for(CHANNEL_ORDERS__Service_Order__c so : existingOrders) {
            if(existingServiceOrdersMap.containsKey(so.CHANNEL_ORDERS__Customer_Org_ID__c)) {
                existingServiceOrdersMap.get(so.CHANNEL_ORDERS__Customer_Org_ID__c).add(so);
            }else{
                existingServiceOrdersMap.put(so.CHANNEL_ORDERS__Customer_Org_ID__c, new List<CHANNEL_ORDERS__Service_Order__c> {so});
            }
        }
        return existingServiceOrdersMap;
    }

    public static Set<Id> buildRelatedOpportunitiesSet(List<CHANNEL_ORDERS__Service_Order__c> existingOrders){
        Set<Id> soRelatedOpportunities = new Set<Id>();
        for(CHANNEL_ORDERS__Service_Order__c so : existingOrders) {
            if(!soRelatedOpportunities.contains(so.CHANNEL_ORDERS__Related_Opportunity__c)) {
                soRelatedOpportunities.add(so.CHANNEL_ORDERS__Related_Opportunity__c );
            }
        }
        return soRelatedOpportunities;
    }

    /*
     * author: Redpoint
     * date: 9/7/2017
     * purpose: Create new order records for customers and determine type of order
     * note:
    */
    public static void createNewOrdersForOpportunities(List<Opportunity> oppsToCreateOrders) {
        //Need to determine which Partner Contract Terms to use
        Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> soDetailMap = new Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>>();
        Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> oppIdToDetailMap = new Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>>();
        Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> renewalOppIdToDetailMap = new Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>>();
        Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> existingOppIdToDetailMap = new Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>>();
        List<String> orgIds = new List<String>();
        List<CHANNEL_ORDERS__Service_Order_Detail__c> soDetailList = new List<CHANNEL_ORDERS__Service_Order_Detail__c>();
        List<COA_Exception__c> updateExceptions = new List<COA_Exception__c>();
        Map<String, CHANNEL_ORDERS__Customer__c> orgIdToCustomerMap = new Map<String, CHANNEL_ORDERS__Customer__c>();
        Map<Id, CHANNEL_ORDERS__Service_Order__c> serviceOrderMap = new Map<Id, CHANNEL_ORDERS__Service_Order__c>(); 
        Map<Id, List<CHANNEL_ORDERS__Service_Order__c>> multipleNewOrdersMap = new Map<Id, List<CHANNEL_ORDERS__Service_Order__c>>();
        Map<Id, List<CHANNEL_ORDERS__Service_Order__c>> multipleExistingOrdersMap = new Map<Id, List<CHANNEL_ORDERS__Service_Order__c>>();
        Map<String, List<CHANNEL_ORDERS__Service_Order__c>> multipleRenewalOrdersMap = new Map<String, List<CHANNEL_ORDERS__Service_Order__c>>();
        Map<String, CHANNEL_ORDERS__Customer__c> newCustomers = new Map<String, CHANNEL_ORDERS__Customer__c>();
        Map<String, CHANNEL_ORDERS__Customer__c> newCustomersForMultipleOrders = new Map<String, CHANNEL_ORDERS__Customer__c>();
        Map<String, CHANNEL_ORDERS__Customer__c> newCustomersForRenewalMultipleOrders = new Map<String, CHANNEL_ORDERS__Customer__c>();
        Map<String, CHANNEL_ORDERS__Customer__c> newCustomersForExistingMultipleOrders = new Map<String, CHANNEL_ORDERS__Customer__c>();
        Map<Id, String> addToQueue = new Map<Id, String>();
        Boolean createOrder = TRUE;
        String orderType;
        Date serviceDate;

        for(Opportunity opp : oppsToCreateOrders){
            orgIds.add(opp.Customer_Org_Id_15_digit__c);
        }

        List<CHANNEL_ORDERS__Service_Order__c> existingOrders = queryExistingOrders(orgIds);
        List<CHANNEL_ORDERS__Customer__c> existingCustomers = queryExistingCustomers(orgIds);
        Map<String, List<CHANNEL_ORDERS__Service_Order__c>> existingServiceOrdersMap = buildExistingServiceOrdersMap(existingOrders);
        Set<Id> soRelatedOpportunities = buildRelatedOpportunitiesSet(existingOrders);

        //Loop through list of existing Customers to add all Org Ids to the map. Later used to assign the customer record to the service order
        for(CHANNEL_ORDERS__Customer__c c : existingCustomers){
            if(!orgIdToCustomerMap.containsKey(c.CHANNEL_ORDERS__Customer_Org_ID__c)){
                orgIdToCustomerMap.put(c.CHANNEL_ORDERS__Customer_Org_ID__c, c);
            }
        }

        for(Opportunity o : oppsToCreateOrders){
            Set<OpportunityLineItem> mappedOppProducts = new Set<OpportunityLineItem>();
            Map<Id, List<OpportunityLineItem>> contractIdToLineItems = new Map<Id, List<OpportunityLineItem>>();
            Set<String> contractIds = new Set<String>();
            Integer emptyMappingCount = 0;
            Id contractTermsId;
            Set<Id> contractTermsIdSet = new Set<Id>();
            Boolean createMultipleOrders = FALSE;
            if(o.OpportunityLineItems.size() > 0){
                serviceDate = o.OpportunityLineItems[0].ServiceDate;
            }

            for(OpportunityLineItem line : o.OpportunityLineItems){
                if(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c != null){
                    contractTermsIdSet.add(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c);
                }
            }
            //Loop through Opp Products in order to determine if multiple orders need to be created and assign to a map
            for(OpportunityLineItem line : o.OpportunityLineItems){
                //Build map of Contract terms to OLIs                         
                if(contractIdToLineItems.containsKey(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c)){
                    contractIdToLineItems.get(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c).add(line);
                }
                else if(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c != null){
                    contractIdToLineItems.put(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c, new List<OpportunityLineItem> {line});
                }

                //Check if multiple orders need to be created
                if(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c != contractTermsId && contractTermsId != null && line.PricebookEntry.Partner_Product_Catalog__c != null){
                    createMultipleOrders = TRUE;
                }

                //ksears - original code:
                // if(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c != contractTermsId && contractTermsId != null && line.PricebookEntry.Partner_Product_Catalog__c != null){
                //     createMultipleOrders = TRUE;
                // }

                //Assign new value to contractTermsId to check and compare
                if(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c != null){
                    contractTermsId = line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c;
                    if(!contractIds.contains(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c)){
                        contractIds.add(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c);
                    }
                }
                //ksears - original code:
                // if(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c != null){
                //     contractTermsId = line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c;
                //     if(!contractIds.contains(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c)){
                //         contractIds.add(line.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c);
                //     }
                // }

                //Check for products with empty PPC mappings 
                if(line.PricebookEntry.Partner_Product_Catalog__c == null){
                    emptyMappingCount++;
                }

                if(line.PricebookEntry.Partner_Product_Catalog__c != null){
                    mappedOppProducts.add(line);
                }
            }

            //Get the existing customer record
            CHANNEL_ORDERS__Customer__c customer = orgIdToCustomerMap.get(o.Customer_Org_Id_15_digit__c);

            if(o.OpportunityLineItems.size() == emptyMappingCount){
                BREAK;    
            }  //Verify that opp has an address
            else if(o.Account.BillingStreet == NULL || o.Account.BillingCity == NULL || o.Account.BillingState == NULL || o.Account.BillingPostalCode == NULL || o.Account.BillingCountry == NULL){
                addToQueue.put(o.Id, 'Opportunity Missing Address');
            }
            else if(o.Type == 'New Business'){ 
                //if(!existingServiceOrdersMap.containsKey(o.Customer_Org_Id_15_digit__c) && !orgIdToCustomerMap.containsKey(o.Customer_Org_Id_15_digit__c)) {                
                    if(!createMultipleOrders){
                        CHANNEL_ORDERS__Customer__c newCustomer = buildNewCOACustomer(o);
                        newCustomers.put(o.Id, newCustomer);

                        CHANNEL_ORDERS__Service_Order__c serviceOrder = buildServiceOrder(o, newCustomer, 'Initial', contractTermsId, serviceDate);
                        serviceOrderMap.put(o.Id, serviceOrder);

                        for(OpportunityLineItem oli : mappedOppProducts){
                            if(oli.PricebookEntry.Partner_Product_Catalog__c != null){
                                CHANNEL_ORDERS__Service_Order_Detail__c soDetail = buildSOProduct(oli.PricebookEntry.Partner_Product_Catalog__c, oli.Quantity, oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c, oli.Product_Unit_Price_per_Month__c);
                                if(soDetailMap.containsKey(o.Id)){
                                    soDetailMap.get(o.Id).add(soDetail);
                                }
                                else{
                                    soDetailMap.put(o.Id, new List<CHANNEL_ORDERS__Service_Order_Detail__c> {soDetail});
                                }
                            }
                        }
                    }
                    else if(createMultipleOrders){
                        CHANNEL_ORDERS__Customer__c newCustomer = buildNewCOACustomer(o);
                        newCustomersForMultipleOrders.put(o.Id, newCustomer);
                        Map<CHANNEL_ORDERS__Service_Order__c, List<CHANNEL_ORDERS__Service_Order_Detail__c>> newOrdersWithOrderLines = createMultipleOrdersForNewOrExistingBusiness(contractIdToLineItems, o, 'Initial', newCustomer);
                        //Put the service orders in their own map and service order details in their own map, both with the contract Id as the key.
                        //Later used to identify which service order details belong to which order when inserting
                        for(CHANNEL_ORDERS__Service_Order__c sOrder : newOrdersWithOrderLines.keySet()){
                            if(multipleNewOrdersMap.containsKey(sOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c)){
                                multipleNewOrdersMap.get(sOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c).add(sOrder);
                            }
                            else{
                                multipleNewOrdersMap.put(sOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c, new List<CHANNEL_ORDERS__Service_Order__c> {sOrder});
                            }
                            for(CHANNEL_ORDERS__Service_Order_Detail__c sOrderDetail : newOrdersWithOrderLines.get(sOrder)){
                                if(oppIdToDetailMap.containsKey(sOrder.CHANNEL_ORDERS__Related_Opportunity__c)){
                                    oppIdToDetailMap.get(sOrder.CHANNEL_ORDERS__Related_Opportunity__c).add(sOrderDetail);
                                }
                                else{
                                    oppIdToDetailMap.put(sOrder.CHANNEL_ORDERS__Related_Opportunity__c, new List<CHANNEL_ORDERS__Service_Order_Detail__c> {sOrderDetail});
                                }
                            }
                        }
                    }
            //Service Order record exists with same Org Id as Opp
            }
            else if(o.Type == 'Renewal'){
                //if(existingServiceOrdersMap.containsKey(o.Customer_Org_Id_15_digit__c)){         
                List<OpportunityLineItem> mappedProductsList = new List<OpportunityLineItem>();
                mappedProductsList.addAll(mappedOppProducts);
                Map<String, Integer> productToDeltaMap = new Map<String, Integer>();
                if(existingServiceOrdersMap.containsKey(o.Customer_Org_Id_15_digit__c)){
                    List<CHANNEL_ORDERS__Service_Order__c> existingSOList = existingServiceOrdersMap.get(o.Customer_Org_Id_15_digit__c);
                    productToDeltaMap = calculateDelta(mappedProductsList, existingSOList);
                }
                else{
                    for(OpportunityLineItem oppLine : mappedProductsList){
                        productToDeltaMap.put(oppLine.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c, oppLine.Quantity.intValue());
                    }
                }
                
                Integer lineItemCounter = o.OpportunityLineItems.size();
                String lineItemAppName;
                for(OpportunityLineItem oli : mappedOppProducts){
                    if(!productToDeltaMap.isEmpty() && productToDeltaMap.containsKey(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c)){
                        if(productToDeltaMap.get(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c) == 0){
                            createOrder = FALSE;
                        }
                        else if(productToDeltaMap.get(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c) > 0 && (oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c != lineItemAppName || lineItemAppName == null)){
                            orderType = 'Add-On';
                            if(createMultipleOrders == FALSE){
                                CHANNEL_ORDERS__Service_Order_Detail__c soDetail = buildSOProduct(oli.PricebookEntry.Partner_Product_Catalog__c, productToDeltaMap.get(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c), oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c, oli.Product_Unit_Price_per_Month__c);//Quantity passed should be the delta
                                if(soDetailMap.containsKey(o.Id)){
                                    soDetailMap.get(o.Id).add(soDetail);
                                }
                                else{
                                    soDetailMap.put(o.Id, new List<CHANNEL_ORDERS__Service_Order_Detail__c>{soDetail});
                                }
                                lineItemAppName = oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c;
                            }
                            else if(createMultipleOrders && contractTermsId != null && contractTermsId != oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c){
                                CHANNEL_ORDERS__Service_Order_Detail__c soDetail = buildSOProduct(oli.PricebookEntry.Partner_Product_Catalog__c, productToDeltaMap.get(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c), oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c, oli.Product_Unit_Price_per_Month__c);//No SO Detail for this opp product on an existing order
                                if(renewalOppIdToDetailMap.containsKey(oli.OpportunityId)){
                                    renewalOppIdToDetailMap.get(oli.OpportunityId).add(soDetail);
                                }
                                else{
                                    renewalOppIdToDetailMap.put(oli.OpportunityId, new List<CHANNEL_ORDERS__Service_Order_Detail__c> {soDetail});
                                }
                            }
                        }
                        else if(productToDeltaMap.get(oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Application_Name__c) < 0){
                            //All reduction opportunities will go to the queue, old reduction code located at bottom
                            addToQueue.put(o.Id, 'Reduction');
                            createOrder = FALSE;
                        }
                    }
                    else if(createMultipleOrders && contractTermsId != null && contractTermsId != oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c){
                        //addToQueue.put(o.Id, 'Issue with Product Mapping');
                        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = buildSOProduct(oli.PricebookEntry.Partner_Product_Catalog__c, oli.Quantity, oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c, oli.Product_Unit_Price_per_Month__c);//Quantity passed should be the delta
                        if(renewalOppIdToDetailMap.containsKey(oli.OpportunityId)){
                            renewalOppIdToDetailMap.get(oli.OpportunityId).add(soDetail);
                        }
                        else{
                            renewalOppIdToDetailMap.put(oli.OpportunityId, new List<CHANNEL_ORDERS__Service_Order_Detail__c> {soDetail});
                        }
                    }
                    contractTermsId = oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c;
                }

                //Ensure there isn't an existing order for the current opportunity
                if(!soRelatedOpportunities.contains(o.Id) && !createMultipleOrders && createOrder) {
                    if(customer == null){
                        customer = buildNewCOACustomer(o);
                        newCustomers.put(o.Id, customer);
                    }
                    CHANNEL_ORDERS__Service_Order__c serviceOrder = buildServiceOrder(o, customer, orderType, contractTermsId, serviceDate);
                    serviceOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c = contractTermsId;
                    serviceOrderMap.put(o.Id, serviceOrder);
                }
                else if(createMultipleOrders){
                    Map<String, List<CHANNEL_ORDERS__Service_Order__c>> currentMultipleRenewalOrdersMap = new Map<String, List<CHANNEL_ORDERS__Service_Order__c>>();
                    if(customer == null){
                        customer = buildNewCOACustomer(o);
                        newCustomersForRenewalMultipleOrders.put(o.Id, customer);
                    }        
                    currentMultipleRenewalOrdersMap = createMultipleOrdersForRenewal(o, 'Add-On', customer, renewalOppIdToDetailMap, o.OpportunityLineItems[0].ServiceDate, contractIds);
                    //Populate global map
                    for(String key : currentMultipleRenewalOrdersMap.keySet()){
                        if(multipleRenewalOrdersMap.containsKey(key)){
                            for(CHANNEL_ORDERS__Service_Order__c s : currentMultipleRenewalOrdersMap.get(key)){
                                multipleRenewalOrdersMap.get(key).add(s);
                            }
                        }
                        else{
                            multipleRenewalOrdersMap.put(key, currentMultipleRenewalOrdersMap.get(key));
                        }
                    }
                }
                else if(createOrder == TRUE){
                    addToQueue.put(o.Id, 'There is already an Order related to this Opportunity'); //If none of the criteria match create a new record to add to the queue
                }
            }
            else if(o.Type == 'Existing Business'){
                //if(existingServiceOrdersMap.containsKey(o.Customer_Org_Id_15_digit__c)){    
                orderType = 'Add-on';

                //Ensure there isn't an existing order for the current opportunity
                if(!soRelatedOpportunities.contains(o.Id) && !createMultipleOrders) {
                    //Create new customer record if there isn't an existing one.
                    if(customer == null){
                        customer = buildNewCOACustomer(o);
                        newCustomers.put(o.Id, customer);
                    }              
                    CHANNEL_ORDERS__Service_Order__c serviceOrder = buildServiceOrder(o, customer, orderType, contractTermsId, serviceDate);
                    serviceOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c = contractTermsId;
                    serviceOrderMap.put(o.Id, serviceOrder);
                    for(OpportunityLineItem oli : mappedOppProducts){
                        contractTermsId = oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c;
                        CHANNEL_ORDERS__Service_Order_Detail__c soDetail = buildSOProduct(oli.PricebookEntry.Partner_Product_Catalog__c, oli.Quantity, oli.PricebookEntry.Partner_Product_Catalog__r.CHANNEL_ORDERS__Partner_Contract_Terms__c, oli.Product_Unit_Price_per_Month__c);
                        if(soDetailMap.containsKey(o.Id)){
                            soDetailMap.get(o.Id).add(soDetail);
                        }
                        else{
                            soDetailMap.put(o.Id, new List<CHANNEL_ORDERS__Service_Order_Detail__c> {soDetail});
                        }
                    }
                }
                else if(createMultipleOrders){
                    //Create new customer record if there isn't an existing one.
                    if(customer == null){
                        customer = buildNewCOACustomer(o);
                        newCustomersForExistingMultipleOrders.put(o.Id, customer);
                    }              
                    Map<CHANNEL_ORDERS__Service_Order__c, List<CHANNEL_ORDERS__Service_Order_Detail__c>> newOrdersWithOrderLines = createMultipleOrdersForNewOrExistingBusiness(contractIdToLineItems, o, 'Add-On', customer);
                    //Put the service orders in their own map and service order details in their own map, both with the contract Id as the key.
                    //Later used to identify which service order details belong to which order when inserting
                    for(CHANNEL_ORDERS__Service_Order__c sOrder : newOrdersWithOrderLines.keySet()){
                        if(multipleExistingOrdersMap.containsKey(sOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c)){
                            multipleExistingOrdersMap.get(sOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c).add(sOrder);
                        }
                        else{
                            multipleExistingOrdersMap.put(sOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c, new List<CHANNEL_ORDERS__Service_Order__c> {sOrder});
                        }

                        for(CHANNEL_ORDERS__Service_Order_Detail__c sOrderDetail : newOrdersWithOrderLines.get(sOrder)){
                            if(existingOppIdToDetailMap.containsKey(sOrder.CHANNEL_ORDERS__Related_Opportunity__c)){
                                existingOppIdToDetailMap.get(sOrder.CHANNEL_ORDERS__Related_Opportunity__c).add(sOrderDetail);
                            }
                            else{
                                existingOppIdToDetailMap.put(sOrder.CHANNEL_ORDERS__Related_Opportunity__c, new List<CHANNEL_ORDERS__Service_Order_Detail__c> {sOrderDetail});
                            }
                        }
                    }
                    //addToQueue.put(o, 'Multiple Orders for Existing Business/Renewal opp');
                }
                else{
                    addToQueue.put(o.Id, 'There is already an Order related to this Opportunity');
                }

            //}else{
                //addToQueue.put(o.Id, 'Org Id on Existing Business/Renewal Opp not found on Order or Customer');
            //}
            }
        }

        //Get custom setting value for whether to submit orders or just create drafts.
        CS_COA_Settings__c coaCustomSetting = CS_COA_Settings__c.getValues('COA Setting');
        String defaultStatus = coaCustomSetting.Default_Sales_Order_Status__c;

        //Inserting records for single orders
        insertServiceOrders(serviceOrderMap, oppsToCreateOrders, soDetailMap, newCustomers, defaultStatus);
        
        //Inserting records for multiple orders fro New Business opp
        insertMultipleServiceOrders(multipleNewOrdersMap, newCustomersForMultipleOrders, oppsToCreateOrders, oppIdToDetailMap, defaultStatus);
        
        //Insert records for multiple orders for a renewal op
        insertMultipleOrdersForRenewals(multipleRenewalOrdersMap, renewalOppIdToDetailMap, newCustomersForRenewalMultipleOrders, defaultStatus);

        //Insert records for multiple orders for an existing business opp
        insertMultipleOrdersForExistingBusiness(multipleExistingOrdersMap, existingOppIdToDetailMap, newCustomersForExistingMultipleOrders, defaultStatus);

        if(!addToQueue.isEmpty()) {
            addRecordsToOpportunityQueue(addToQueue);
        }
    }

    //@future(callout=true)
    public static void submitCOAs(String serviceOrderListStr){
        List<CHANNEL_ORDERS__Service_Order__c> sos = (List<CHANNEL_ORDERS__Service_Order__c>)JSON.deserialize(serviceOrderListStr, List<CHANNEL_ORDERS__Service_Order__c>.class);
        List<CHANNEL_ORDERS__Service_Order__c> updateOrderStatus = new List<CHANNEL_ORDERS__Service_Order__c>();
        List<CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitInput> serviceOrderSubmitInputList = new List<CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitInput>();
        Map<Id, String> createCOAExceptions = new Map<Id, String>();
        for(CHANNEL_ORDERS__Service_Order__c submitOrder : sos){
            CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitInput input = new CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitInput();
            input.serviceOrderId = submitOrder.Id;
            serviceOrderSubmitInputList.add(input);
        }

        Integer counter = 0;
        List<CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitOutput> serviceOrderSubmitOutputList = CHANNEL_ORDERS.COA_ServiceOrderSubmit.submit(serviceOrderSubmitInputList);
        for(CHANNEL_ORDERS.COA_ServiceOrderSubmit.COA_ServiceOrderSubmitOutput serviceOrderSubmitOutput: serviceOrderSubmitOutputList){
            if(!serviceOrderSubmitOutput.isSuccess){
                String errorMessage;
                for(String response : serviceOrderSubmitOutput.responseMessages){
                    errorMessage = errorMessage + ', ' + response;
                }
                CHANNEL_ORDERS__Service_Order__c failedOrder = sos[counter];
                if(errorMessage.contains('null')){
                    errorMessage = errorMessage.remove('null,');
                }
                createCOAExceptions.put(failedOrder.CHANNEL_ORDERS__Related_Opportunity__c, 'Draft created with submission error: ' + errorMessage);
            }
            else{
                CHANNEL_ORDERS__Service_Order__c successfulOrder = sos[counter];
                successfulOrder.CHANNEL_ORDERS__Service_Order_Status__c = 'Received';
                updateOrderStatus.add(successfulOrder);
            }
            counter ++;
        }
        //Call exceptions method
        addRecordsToOpportunityQueue(createCOAExceptions);

        if(!updateOrderStatus.isEmpty()){
            update updateOrderStatus;
        }
    }

    public static void insertServiceOrders(Map<Id, CHANNEL_ORDERS__Service_Order__c> ordersToInsertMap, List<Opportunity> oppList, 
        Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> detailMap, Map<String, CHANNEL_ORDERS__Customer__c> newCustomers, String orderStatus){
        List<CHANNEL_ORDERS__Service_Order_Detail__c> soDetailList = new List<CHANNEL_ORDERS__Service_Order_Detail__c>();

        //Insert new customer records
        Savepoint point = database.setSavePoint();
        if(!newCustomers.isEmpty()){
            insert newCustomers.values();
        }

        if(!ordersToInsertMap.isEmpty()){
            for(Opportunity opp : oppList){
                if(ordersToInsertMap.containsKey(opp.Id)){
                    CHANNEL_ORDERS__Service_Order__c newOrder = ordersToInsertMap.get(opp.Id);
                    if(newCustomers.containsKey(newOrder.CHANNEL_ORDERS__Related_Opportunity__c)){
                        newOrder.CHANNEL_ORDERS__Customer__c = newCustomers.get(newOrder.CHANNEL_ORDERS__Related_Opportunity__c).Id;
                    }
                }             
            }

            List<CHANNEL_ORDERS__Service_Order__c> insertOrders = ordersToInsertMap.values();
            List<COA_Exception__c> createExceptions = new List<COA_Exception__c>();
            Map<Id, String> createCOAExceptions = new Map<Id, String>();
            Integer counter = 0;
            for(Database.SaveResult sr : Database.insert(insertOrders, false)){
                String errors = '';
                if(!sr.isSuccess()){
                    database.rollback(point);
                    CHANNEL_ORDERS__Service_Order__c failedOrder = insertOrders[counter];
                    for(Database.error er : sr.getErrors()){
                        errors += er.getMessage();
                        createCOAExceptions.put(failedOrder.CHANNEL_ORDERS__Related_Opportunity__c, er.getMessage());
                    }
                }
                counter ++;
            }

            //Call exceptions method
            addRecordsToOpportunityQueue(createCOAExceptions);


            //Loop through to assing id of newly inserted service orders
            if(!detailMap.isEmpty()) {
                // get Partner Product Catalogs
                // CONGA SERVICES ER 20180529, QUERY CALL MOVED HERE FROM TOP OF METHOD FOR EFFICIENCY PURPOSES
                Map<String, CHANNEL_ORDERS__Partner_Product_Catalog__c> ppcMap = queryPartnerProductCatologs();

                for(String key : detailMap.keySet()){
                    for(CHANNEL_ORDERS__Service_Order_Detail__c detail : detailMap.get(key)){
                        CHANNEL_ORDERS__Service_Order__c serviceOrder = ordersToInsertMap.get(key);
                        if(serviceOrder != null){
                            detail.CHANNEL_ORDERS__Partner_Order__c = serviceOrder.Id;
                        }
                        CHANNEL_ORDERS__Partner_Product_Catalog__c ppc = ppcMap.get(detail.CHANNEL_ORDERS__Product_Name__c);
                        if(ppc != null){
                            detail.CHANNEL_ORDERS__pc_Billing_Frequency__c = ppc.CHANNEL_ORDERS__Billing_Frequency__c;
                            detail.CHANNEL_ORDERS__pc_Contract_Auto_Renew__c = ppc.CHANNEL_ORDERS__Contract_Auto_Renew__c;
                            detail.CHANNEL_ORDERS__pc_Contract_Length__c = ppc.CHANNEL_ORDERS__Contract_Length__c;
                            detail.CHANNEL_ORDERS__pc_Cancellation_Terms__c = ppc.CHANNEL_ORDERS__Cancellation_Terms__c;
                            detail.CHANNEL_ORDERS__pc_Renewal_Terms__c = ppc.CHANNEL_ORDERS__Renewal_Terms__c;
                        }
                        soDetailList.add(detail);
                    }
                }
            }
            
            if(!soDetailList.isEmpty()){
                insert soDetailList;
            }

            if(orderStatus == 'Submitted'){
                submitCOAs(JSON.serialize(ordersToInsertMap.values()));
            }
        }
    }

    public static void insertMultipleServiceOrders(Map<Id, List<CHANNEL_ORDERS__Service_Order__c>> multipleNewOrdersMap, Map<String, CHANNEL_ORDERS__Customer__c> newCustomersForMultipleOrders, 
        List<Opportunity> oppsToCreateOrders, Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> oppIdToDetailMap, String orderStatus){

        if(!multipleNewOrdersMap.isEmpty()){
            List<CHANNEL_ORDERS__Service_Order__c> insertOrders = new List<CHANNEL_ORDERS__Service_Order__c>();
            Set<CHANNEL_ORDERS__Service_Order__c> insertOrdersSet = new Set<CHANNEL_ORDERS__Service_Order__c>();
            List<CHANNEL_ORDERS__Service_Order_Detail__c> insertDetails = new List<CHANNEL_ORDERS__Service_Order_Detail__c>();
            Set<CHANNEL_ORDERS__Service_Order_Detail__c> insertDetailSet = new Set<CHANNEL_ORDERS__Service_Order_Detail__c>();

            //Insert new customer records
            Savepoint point = database.setSavePoint();
            if(!newCustomersForMultipleOrders.isEmpty()){
                insert newCustomersForMultipleOrders.values();
            }

            //Assign new customer record to order if initial order
            Integer orderCounter = 0;
            for(Opportunity opp : oppsToCreateOrders){
                for(String termId : multipleNewOrdersMap.keySet()){
                    for(CHANNEL_ORDERS__Service_Order__c so : multipleNewOrdersMap.get(termId)){
                        orderCounter ++;
                        if(newCustomersForMultipleOrders.containsKey(opp.Id)){
                            so.CHANNEL_ORDERS__Customer__c = newCustomersForMultipleOrders.get(opp.Id).Id;
                            //Assign to a set to ensure there's no duplication errors
                            if(!insertOrdersSet.contains(so)){
                                insertOrdersSet.add(so);
                            }
                        }
                    }
                }
            }

            insertOrders.addAll(insertOrdersSet);

            Map<Id, String> createCOAExceptions = new Map<Id, String>();
            Integer counter = 0;
            for(Database.SaveResult sr : Database.insert(insertOrders, false)){
                String errors = '';
                if(!sr.isSuccess()){
                    //result.success = false;
                    database.rollback(point);
                    CHANNEL_ORDERS__Service_Order__c failedOrder = insertOrders[counter];
                    for(Database.error er : sr.getErrors()){
                        errors += er.getMessage();
                        createCOAExceptions.put(failedOrder.CHANNEL_ORDERS__Related_Opportunity__c, er.getMessage());
                    }
                }
                counter ++;
            }
            //Call exceptions method
            addRecordsToOpportunityQueue(createCOAExceptions);

            //Loop through to assign id of newly inserted service orders
            if(!oppIdToDetailMap.isEmpty()){
                // get Partner Product Catalogs
                // CONGA SERVICES ER 20180529, QUERY CALL MOVED HERE FROM TOP OF METHOD FOR EFFICIENCY PURPOSES
                Map<String, CHANNEL_ORDERS__Partner_Product_Catalog__c> ppcMap = queryPartnerProductCatologs();

                for(String contractId : multipleNewOrdersMap.keySet()){    
                    for(CHANNEL_ORDERS__Service_Order__c newOrder : multipleNewOrdersMap.get(contractId)){   
                        for(CHANNEL_ORDERS__Service_Order_Detail__c sDetail : oppIdToDetailMap.get(newOrder.CHANNEL_ORDERS__Related_Opportunity__c)){
                            if(newOrder.Id != null && newOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c == sDetail.CHANNEL_ORDERS__pc_Partner_Contract_Term__c){                            
                                sDetail.CHANNEL_ORDERS__Partner_Order__c = newOrder.Id;
                                CHANNEL_ORDERS__Partner_Product_Catalog__c ppc = ppcMap.get(sDetail.CHANNEL_ORDERS__Product_Name__c);
                                sDetail.CHANNEL_ORDERS__pc_Billing_Frequency__c = ppc.CHANNEL_ORDERS__Billing_Frequency__c;
                                sDetail.CHANNEL_ORDERS__pc_Contract_Auto_Renew__c = ppc.CHANNEL_ORDERS__Contract_Auto_Renew__c;
                                sDetail.CHANNEL_ORDERS__pc_Contract_Length__c = ppc.CHANNEL_ORDERS__Contract_Length__c;
                                sDetail.CHANNEL_ORDERS__pc_Cancellation_Terms__c = ppc.CHANNEL_ORDERS__Cancellation_Terms__c;
                                sDetail.CHANNEL_ORDERS__pc_Renewal_Terms__c = ppc.CHANNEL_ORDERS__Renewal_Terms__c;
                                if(!insertDetailSet.contains(sDetail)){
                                    insertDetailSet.add(sDetail);
                                }
                            }     
                        }
                    }
                }
            }
            insertDetails.addAll(insertDetailSet);

            if(!insertDetails.isEmpty()){
                insert insertDetails;    
            }

            if(orderStatus == 'Submitted'){
                submitCOAs(JSON.serialize(insertOrders));
            }   
        }
    }

    public static void insertMultipleOrdersForRenewals(Map<String, List<CHANNEL_ORDERS__Service_Order__c>> multipleRenewalOrdersMap, Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> renewalOppIdToDetailMap,
        Map<String, CHANNEL_ORDERS__Customer__c> newCustomersForRenewalMultipleOrders, String orderStatus){
        
        Savepoint point = database.setSavePoint();
        if(!newCustomersForRenewalMultipleOrders.isEmpty()){
            insert newCustomersForRenewalMultipleOrders.values();
        }

        if(!multipleRenewalOrdersMap.isEmpty()){
            List<CHANNEL_ORDERS__Service_Order__c> insertOrders = new List<CHANNEL_ORDERS__Service_Order__c>();
            Set<CHANNEL_ORDERS__Service_Order__c> insertOrdersSet = new Set<CHANNEL_ORDERS__Service_Order__c>();
            Map<String, CHANNEL_ORDERS__Partner_Product_Catalog__c> ppcMap = queryPartnerProductCatologs();

            for(String termId : multipleRenewalOrdersMap.keySet()){
                for(CHANNEL_ORDERS__Service_Order__c so : multipleRenewalOrdersMap.get(termId)){
                    if(newCustomersForRenewalMultipleOrders.containsKey(so.CHANNEL_ORDERS__Related_Opportunity__c)){
                        so.CHANNEL_ORDERS__Customer__c = newCustomersForRenewalMultipleOrders.get(so.CHANNEL_ORDERS__Related_Opportunity__c).Id;
                    }
                    if(!insertOrdersSet.contains(so)){
                        insertOrdersSet.add(so);
                    }   
                }
            }

            insertOrders.addAll(insertOrdersSet);

            Map<Id, String> createCOAExceptions = new Map<Id, String>();
            Integer counter = 0;
            for(Database.SaveResult sr : Database.insert(insertOrders, false)){
                String errors = '';
                if(!sr.isSuccess()){
                    database.rollback(point);
                    CHANNEL_ORDERS__Service_Order__c failedOrder = insertOrders[counter];
                    for(Database.error er : sr.getErrors()){
                        errors += er.getMessage();
                        createCOAExceptions.put(failedOrder.CHANNEL_ORDERS__Related_Opportunity__c, er.getMessage());
                    }
                }
                counter ++;
            }
            //Call exceptions method
            addRecordsToOpportunityQueue(createCOAExceptions);
      
            //Loop through to assing id of newly inserted service orders
            List<CHANNEL_ORDERS__Service_Order_Detail__c> insertDetailList = new List<CHANNEL_ORDERS__Service_Order_Detail__c>();
            Set<CHANNEL_ORDERS__Service_Order_Detail__c> insertDetailSet = new Set<CHANNEL_ORDERS__Service_Order_Detail__c>();
            for(String contractId : multipleRenewalOrdersMap.keySet()){      
                for(CHANNEL_ORDERS__Service_Order__c newOrder : multipleRenewalOrdersMap.get(contractId)){
                    if(newOrder.Id != null && newOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c == contractId){
                        //if(renewalOppIdToDetailMap.get(newOrder.CHANNEL_ORDERS__Related_Opportunity__c) != null){
                            for(CHANNEL_ORDERS__Service_Order_Detail__c sDetail : renewalOppIdToDetailMap.get(newOrder.CHANNEL_ORDERS__Related_Opportunity__c)){
                                if(newOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c == sDetail.CHANNEL_ORDERS__pc_Partner_Contract_Term__c){
                                    CHANNEL_ORDERS__Partner_Product_Catalog__c ppc = ppcMap.get(sDetail.CHANNEL_ORDERS__Product_Name__c);
                                    sDetail.CHANNEL_ORDERS__Partner_Order__c = newOrder.Id;
                                    sDetail.CHANNEL_ORDERS__pc_Billing_Frequency__c = ppc.CHANNEL_ORDERS__Billing_Frequency__c;
                                    sDetail.CHANNEL_ORDERS__pc_Contract_Auto_Renew__c = ppc.CHANNEL_ORDERS__Contract_Auto_Renew__c;
                                    sDetail.CHANNEL_ORDERS__pc_Contract_Length__c = ppc.CHANNEL_ORDERS__Contract_Length__c;
                                    sDetail.CHANNEL_ORDERS__pc_Cancellation_Terms__c = ppc.CHANNEL_ORDERS__Cancellation_Terms__c;
                                    sDetail.CHANNEL_ORDERS__pc_Renewal_Terms__c = ppc.CHANNEL_ORDERS__Renewal_Terms__c;

                                    if(!insertDetailSet.contains(sDetail)){
                                        insertDetailSet.add(sDetail);
                                    }
                                }    
                            }
                        //}
                    }
                }     
                    
            }       

            insertDetailList.addAll(insertDetailSet);
            if(!insertDetailList.isEmpty()){
                insert insertDetailList;
            }

            if(orderStatus == 'Submitted'){
                submitCOAs(JSON.serialize(insertOrders));
            }
        }
    }

    public static void insertMultipleOrdersForExistingBusiness(Map<Id, List<CHANNEL_ORDERS__Service_Order__c>> multipleExistingOrdersMap, Map<String, List<CHANNEL_ORDERS__Service_Order_Detail__c>> existingOppIdToDetailMap,
        Map<String, CHANNEL_ORDERS__Customer__c> newCustomersForExistingMultipleOrders, String orderStatus){

        Savepoint point = database.setSavePoint();
        if(!newCustomersForExistingMultipleOrders.isEmpty()){
            insert newCustomersForExistingMultipleOrders.values();
        }

        if(!multipleExistingOrdersMap.isEmpty()){
            List<CHANNEL_ORDERS__Service_Order__c> insertOrders = new List<CHANNEL_ORDERS__Service_Order__c>();
            Set<CHANNEL_ORDERS__Service_Order__c> insertOrdersSet = new Set<CHANNEL_ORDERS__Service_Order__c>();

            for(String termId : multipleExistingOrdersMap.keySet()){
                for(CHANNEL_ORDERS__Service_Order__c so : multipleExistingOrdersMap.get(termId)){
                    if(newCustomersForExistingMultipleOrders.containsKey(so.CHANNEL_ORDERS__Related_Opportunity__c)){
                        so.CHANNEL_ORDERS__Customer__c = newCustomersForExistingMultipleOrders.get(so.CHANNEL_ORDERS__Related_Opportunity__c).Id;
                    }
                    if(!insertOrdersSet.contains(so)){
                        insertOrdersSet.add(so);
                    }  
                }
            }

            insertOrders.addAll(insertOrdersSet);
                
            Map<Id, String> createCOAExceptions = new Map<Id, String>();
            Integer counter = 0;
            for(Database.SaveResult sr : Database.insert(insertOrders, false)){
                String errors = '';
                if(!sr.isSuccess()){
                    database.rollback(point);
                    CHANNEL_ORDERS__Service_Order__c failedOrder = insertOrders[counter];
                    for(Database.error er : sr.getErrors()){
                        errors += er.getMessage();
                        createCOAExceptions.put(failedOrder.CHANNEL_ORDERS__Related_Opportunity__c, er.getMessage());
                    }
                }
                counter ++;
            }
            //Call exceptions method
            addRecordsToOpportunityQueue(createCOAExceptions);

            //Loop through to assing id of newly inserted service orders
            Set<CHANNEL_ORDERS__Service_Order_Detail__c> insertDetailSet = new Set<CHANNEL_ORDERS__Service_Order_Detail__c>();
            List<CHANNEL_ORDERS__Service_Order_Detail__c> insertOrderDetails = new List<CHANNEL_ORDERS__Service_Order_Detail__c>();
            if(!existingOppIdToDetailMap.isEmpty()){
                // get Partner Product Catalogs
                // CONGA SERVICES ER 20180529, QUERY CALL MOVED HERE FROM TOP OF METHOD FOR EFFICIENCY PURPOSES
                Map<String, CHANNEL_ORDERS__Partner_Product_Catalog__c> ppcMap = queryPartnerProductCatologs();

                for(String contractId : multipleExistingOrdersMap.keySet()){
                    for(CHANNEL_ORDERS__Service_Order__c newOrder : multipleExistingOrdersMap.get(contractId)){       
                        for(CHANNEL_ORDERS__Service_Order_Detail__c sDetail : existingOppIdToDetailMap.get(newOrder.CHANNEL_ORDERS__Related_Opportunity__c)){
                            if(newOrder.Id != null && newOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c == sDetail.CHANNEL_ORDERS__pc_Partner_Contract_Term__c){
                                CHANNEL_ORDERS__Partner_Product_Catalog__c ppc = ppcMap.get(sDetail.CHANNEL_ORDERS__Product_Name__c);
                                sDetail.CHANNEL_ORDERS__Partner_Order__c = newOrder.Id;
                                sDetail.CHANNEL_ORDERS__pc_Billing_Frequency__c = ppc.CHANNEL_ORDERS__Billing_Frequency__c;
                                sDetail.CHANNEL_ORDERS__pc_Contract_Auto_Renew__c = ppc.CHANNEL_ORDERS__Contract_Auto_Renew__c;
                                sDetail.CHANNEL_ORDERS__pc_Contract_Length__c = ppc.CHANNEL_ORDERS__Contract_Length__c;
                                sDetail.CHANNEL_ORDERS__pc_Cancellation_Terms__c = ppc.CHANNEL_ORDERS__Cancellation_Terms__c;
                                sDetail.CHANNEL_ORDERS__pc_Renewal_Terms__c = ppc.CHANNEL_ORDERS__Renewal_Terms__c;

                                if(!insertDetailSet.contains(sDetail)){
                                    insertDetailSet.add(sDetail);
                                }
                            }     
                        }
                    }
                }
            }

            insertOrderDetails.addAll(insertDetailSet);

            if (!insertOrderDetails.isEmpty()){
                insert insertOrderDetails;
            }

            if(orderStatus == 'Submitted'){
                submitCOAs(JSON.serialize(insertOrders));
            }
        }
    }

    
}