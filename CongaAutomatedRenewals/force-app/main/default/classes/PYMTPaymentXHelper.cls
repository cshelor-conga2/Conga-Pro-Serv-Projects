/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @description PYMTPaymentXHelper - Custom functionality and trigger methods for the pymt__PaymentX__c object
*/
public with sharing class PYMTPaymentXHelper {

    /**
    * @description autoApplyPayments 
    * @param List<pymt__PaymentX__c> pmts - Updated pymt__PaymentX__c records
    * @return void
    */
    public static void autoApplyPayments(List<pymt__PaymentX__c> updatedPayments){
        try{
            if(TriggerHelper.DoExecute('PYMTPaymentXHelper','autoApplyPayments') && updatedPayments != null && !updatedPayments.isEmpty()){
                Set<Id> paymentIds = new Set<Id>();
                Set<Id> oppIds = new Set<Id>();
                Map<Id,List<OpportunityLineItem>> oppOlisMap = new Map<Id,List<OpportunityLineItem>>();
                for(pymt__PaymentX__c updatedPayment : updatedPayments){
                    paymentIds.add(updatedPayment.Id);
                    oppIds.add(updatedPayment.pymt__Opportunity__c);
                }

                for(Opportunity o : [SELECT Id, (SELECT Id, ServiceDate FROM OpportunityLineItems) FROM Opportunity WHERE Id IN :oppIds]){
                    if(checkMultiYear(o.OpportunityLineItems)){
                        oppOlisMap.put(o.Id,o.OpportunityLineItems);
                    }
                }

                Id invoiceRt = null;
                for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Order']){
                    if(rt.DeveloperName == 'Invoice'){
                        invoiceRt = rt.Id;
                    }
                }

                if(oppOlisMap != null && invoiceRt != null){
                    Map<Id,pymt__PaymentX__c> paymentsWithoutOrders = new Map<Id,pymt__PaymentX__c>();
                    Map<Id,pymt__PaymentX__c> paymentsWithOrders = new Map<Id,pymt__PaymentX__c>();
                    Set<Id> opportunityIds = new Set<Id>();
                    Set<Id> orderIds = new Set<Id>();

                    for(pymt__PaymentX__c pmt : [SELECT Id, pymt__Status__c, pymt__Opportunity__c, Order__c, pymt__Amount__c, pymt__Card_Type__c, pymt__Date__c, pymt__Payment_Type__c
                                                 FROM pymt__PaymentX__c WHERE Id IN :paymentIds AND pymt__Status__c = 'Completed']){
                        if((pmt.pymt__Payment_Type__c == 'Credit Card' && String.isNotBlank(pmt.pymt__Card_Type__c)) || (pmt.pymt__Payment_Type__c != 'Credit Card')) {
                            if(pmt.Order__c == null){
                                paymentsWithoutOrders.put(pmt.Id, pmt);
                                opportunityIds.add(pmt.pymt__Opportunity__c);
                            }
                            else{
                                paymentsWithOrders.put(pmt.Id, pmt);
                                orderIds.add(pmt.Order__c);
                            }
                        }
                    }

                    // GET ORDERS TO PROCESS
                    Map<Id, List<Order>> ordersByOppOrOrderId = new Map<Id, List<Order>>();
                    if(!paymentsWithoutOrders.isEmpty()){
                        for(Order order : [SELECT Id, OpportunityId, (SELECT Id FROM Order_Payments__r WHERE PaymentId__c IN :paymentsWithoutOrders.keySet()) 
                                           FROM Order WHERE OpportunityId IN :opportunityIds AND RecordTypeId = :invoiceRt]){
                            if(ordersByOppOrOrderId.containsKey(order.OpportunityId)){
                                ordersByOppOrOrderId.get(order.OpportunityId).add(order);
                            }
                            else{
                                ordersByOppOrOrderId.put(order.OpportunityId, new List<Order>());
                                ordersByOppOrOrderId.get(order.OpportunityId).add(order);
                            }
                        }
                    }

                    if(!paymentsWithOrders.isEmpty()){
                        for(Order order : [SELECT Id, (SELECT Id FROM Order_Payments__r WHERE PaymentId__c IN :paymentsWithOrders.keySet())
                                           FROM Order WHERE Id IN :orderIds AND RecordTypeId = :invoiceRt]){
                            if(!ordersByOppOrOrderId.containsKey(order.Id)){
                                ordersByOppOrOrderId.put(order.Id, new List<Order>());
                                ordersByOppOrOrderId.get(order.Id).add(order);
                            }
                        }
                    }   

                    Map<Id,pymt__PaymentX__c> allPayments = new Map<Id,pymt__PaymentX__c>();
                    allPayments.putAll(paymentsWithoutOrders);
                    allPayments.putAll(paymentsWithOrders);

                    // PROCESS ORDERS
                    List<Order_Payment__c> newOrderPmts = new List<Order_Payment__c>();
                    for(pymt__PaymentX__c pmt : allPayments.values()){
                        Id mapKey = null;
                        if(pmt.Order__c == null && ordersByOppOrOrderId.containsKey(pmt.pymt__Opportunity__c)){
                            mapKey = pmt.pymt__Opportunity__c;
                        }
                        else if(ordersByOppOrOrderId.containsKey(pmt.Order__c)){
                            mapKey = pmt.Order__c;
                        }

                        for(Order o : ordersByOppOrOrderId.get(mapKey)){
                            if(o.Order_Payments__r.size() == 0){
                                Order_Payment__c ordPmt = new Order_Payment__c();
                                ordPmt.InvoiceId__c = o.Id;
                                ordPmt.PaymentId__c = pmt.Id;
                                ordPmt.Amount_Applied__c = pmt.pymt__Amount__c;
                                ordPmt.Payment_Received_Date__c = pmt.pymt__Date__c;
                                ordPmt.Payment_Type__c = pmt.pymt__Payment_Type__c;
                                ordPmt.Card_Type__c = pmt.pymt__Card_Type__c;
                                newOrderPmts.add(ordPmt);
                            }
                        }
                    }

                    if(!newOrderPmts.isEmpty()){
                        Database.saveResult[] orderPaymentResults = Database.insert(newOrderPmts, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(orderPaymentResults, 'PYMTPaymentXHelper', 'autoApplyPayments', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('PYMTPaymentXHelper', 'autoApplyPayments');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('PYMTPaymentXHelper', 'autoApplyPayments', updatedPayments, ex, true);
        }
    }


    /**
    * @description checkMultiYear
    * @param List<OpportunityLineItem> olis - List of OpportunityLineITem records
    * @return Boolean
    */
    public static Boolean checkMultiYear(List<OpportunityLineItem> olis){
        Boolean result = true;
        if(olis.size() > 1){
            for(OpportunityLineItem oli : olis){
                if(oli.ServiceDate.year() != System.now().year()){
                    result = false;
                    break;
                }
            }
        }
        return result;
    }


}