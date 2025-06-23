/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @description OrderPaymentHelper - Helper class for the Order_Payment__c object
*/
public with sharing class OrderPaymentHelper {

    /**
    * @description rollUpApplied - Rolls up Order Payment Amount Applied values to the parent credit memo orders
    * @param List<Order_Payment__c> orderPayments - New or updated Order_Payment__c records
    * @return void
    */
    public static void rollUpApplied(List<Order_Payment__c> orderPayments){
        try{        
            if(TriggerHelper.DoExecute('OrderPaymentHelper','rollUpApplied') && orderPayments != null){
                List<Id> creditMemoIds = new List<Id>();
                for(Order_Payment__c payment : orderPayments){
                    if(payment.Credit_MemoId__c != null){
                        creditMemoIds.add(payment.Credit_MemoId__c);
                    }
                }

                List<Order> updateOrders = new List<Order>();
                for(Order[] orders : [SELECT Id, Amount_Applied_CM__c, (SELECT Id, Amount_Applied__c FROM Order_Payments2__r) FROM Order WHERE Id IN :creditMemoIds]){
                    for(Order order : orders){
                        Decimal origAmount = order.Amount_Applied_CM__c;
                        order.Amount_Applied_CM__c = 0;
                        for(Order_Payment__c payment : order.Order_Payments2__r){
                            if(payment.Amount_Applied__c != null){
                                order.Amount_Applied_CM__c += payment.Amount_Applied__c;
                            }
                        }

                        if(origAmount != order.Amount_Applied_CM__C){
                            updateOrders.add(order);
                        }
                    }
                }

                if(!updateOrders.isEmpty()){
                    Database.saveResult[] orderResults = Database.update(updateOrders, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(orderResults, 'OrderPaymentHelper', 'rollUpApplied', true);
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OrderPaymentHelper', 'rollUpApplied');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OrderPaymentHelper', 'rollUpApplied', orderPayments, ex, true);
        }       
    }


}