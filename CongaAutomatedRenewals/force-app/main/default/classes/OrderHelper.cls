/**
* @author Conga Services
* @date 20181023
* @version 1.0
* @description OrderHelper - Helper class for the Order object
*/
public class OrderHelper {

    /**
    * @description createRevSchedule - 
    * @param List<Order> orders - Updated Order records
    * @return void 
    */
    public static void createRevSchedule(List<Order> orders){
        try{        
            if(TriggerHelper.DoExecute('OrderHelper','createRevSchedule') && orders != null){
                //Set<Id> ordIds = new Set<Id>();
                //for(Order o : orders){
                //  ordIds.add(o.Id);
                //}

                //Id invoiceRt = null;
                //Id creditMemoRt = null;
                //for(RecordType rt : [SELECT Id,DeveloperName FROM RecordType WHERE SObjectType = 'Order']){
                //  if(rt.DeveloperName == 'Invoice'){
                //      invoiceRt = rt.Id;
                //  }
                //  else if(rt.DeveloperName == 'Credit_Memo'){
                //      creditMemoRt = rt.Id;
                //  }
                //}

                List<Order> activated = [SELECT Id, RecordTypeId FROM Order WHERE ActivatedDate != null AND Id IN :orders];
                if(!activated.isEmpty()){
                    List<OrderItem> orderItems = [SELECT Id, OrderId, (SELECT Id FROM Revenue_Schedules__r), Unit_Price_4__c, Quantity, Product_End_Date__c, Product_Start_Date__c
                                                  FROM OrderItem WHERE OrderId IN :activated];    
                    if(!orderItems.isEmpty()){
                        Map<Id,List<OrderItem>> orderIdToItemsMap = new Map<Id,List<OrderItem>>();
                        for(OrderItem oi : orderItems) {
                            if(!orderIdToItemsMap.containsKey(oi.OrderId)){
                                orderIdToItemsMap.put(oi.OrderId, new List<OrderItem>());
                                orderIdToItemsMap.get(oi.OrderId).add(oi);
                            }
                            else{
                                orderIdToItemsMap.get(oi.OrderId).add(oi);
                            }
                        }
                        
                        List<Revenue_Schedule__c> revList = new List<Revenue_Schedule__c>();
                        for(Order o : activated){
                            if(orderIdToItemsMap.containsKey(o.Id)){
                                for(OrderItem item : orderIdToItemsMap.get(o.Id)) {
                                    if(item.Unit_Price_4__c != null && item.Quantity != null && item.Product_Start_Date__c != null && item.Product_End_Date__c != null){
                                        List<UtilityClass.MonthCost> mCosts = UtilityClass.getMonthCosts((item.Unit_Price_4__c * item.Quantity), item.Product_Start_Date__c, item.Product_End_Date__c);
                                        for(UtilityClass.MonthCost mc : mCosts){
                                            if(item.Revenue_Schedules__r.size() == 0){
                                                Revenue_Schedule__c rev = new Revenue_Schedule__c();
                                                rev.Revenue__c = mc.Cost;
                                                rev.Date__c = Date.newInstance(mc.Year, mc.Month, 1);
                                                rev.Order_ProductId__c = item.Id;
                                                rev.Count_of_Days__c = mc.NoDays;
                                                rev.Daily_Revenue_Amount__c = (double)((double)(mc.Cost)/(double)(mc.NoDays));
                                                revList.add(rev);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if(!revList.isEmpty()){
                            Database.saveResult[] revResults = Database.insert(revList, false);
                            SystemIssueLogHelper.CheckForDatabaseErrors(revResults, 'OrderHelper', 'createRevSchedule', true);
                        }
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OrderHelper', 'createRevSchedule');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OrderHelper', 'createRevSchedule', orders, ex, true);
        }
    }

    /**
    * @description clearSiteQuoteExp - 
    * @param List<Order> orders - Updated Order records
    * @return void 
    */
    public static void clearSiteQuoteExp(List<Order> orders){
        try{        
            if(TriggerHelper.DoExecute('OrderHelper','clearSiteQuoteExp') && orders != null){
                Set<Id> ordIds = new Set<Id>();
                for(Order o : orders){
                    if(o.Status == 'Paid'){
                        ordIds.add(o.Id);
                    }
                }

                if(!ordIds.isEmpty()){
                    Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
                    for(Order o : [SELECT Id, OpportunityId, Opportunity.pymt__SiteQuote_Expiration__c FROM Order WHERE Id IN :ordIds AND Status = 'Paid']){
                        if(o.OpportunityId != null && !oppsToUpdate.containsKey(o.OpportunityId)){
                            o.Opportunity.pymt__SiteQuote_Expiration__c = null;
                            oppsToUpdate.put(o.OpportunityId, o.Opportunity);
                        }
                    }

                    if(!oppsToUpdate.isEmpty()){
                        Database.saveResult[] oppResults = Database.update(oppsToUpdate.values(), false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(oppResults, 'OrderHelper', 'clearSiteQuoteExp', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OrderHelper', 'clearSiteQuoteExp');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('OrderHelper', 'clearSiteQuoteExp', orders, ex, true);
        }
    }

    /**
    * @description validateStateAndCountry - Validate State and Country values on Billing and Shipping addresses
    * @param List<Order> newOrUpdatedOrders - New or Updated Order records
    * @param Map<Id, Order> outdatedOrders - Outdated Order records
    * @return void
    */
    public static void validateStateAndCountry(List<Order> newOrUpdatedOrders, Map<Id, Order> outdatedOrders){
        try{
            if(TriggerHelper.DoExecute('OrderHelper','validateStateAndCountry') && newOrUpdatedOrders != null){
                // GET ACCOUNTS WITH QUALIFYING CHANGES
                List<Order> qualifiedOrders = new List<Order>();
                for(Order newOrUpdatedOrder : newOrUpdatedOrders){
                    Order outdatedOrder = outdatedOrders != null ? outdatedOrders.get(newOrUpdatedOrder.Id) : null;
                    if(outdatedOrder == null || (outdatedOrder != null && (newOrUpdatedOrder.BillingState != outdatedOrder.BillingState || 
                                                                           newOrUpdatedOrder.BillingCountry != outdatedOrder.BillingCountry ||
                                                                           newOrUpdatedOrder.ShippingState != outdatedOrder.ShippingState ||
                                                                           newOrUpdatedOrder.ShippingCountry != outdatedOrder.ShippingCountry))){
                        qualifiedOrders.add(newOrUpdatedOrder);
                    }
                }

                if(!qualifiedOrders.isEmpty()){
                    // GET STATE AND COUNTRY FIELDS NAMES
                    Map<String,String> countryStateFieldPairs = new Map<String,String>{ Order.BillingCountry.getDescribe().getName() => Order.BillingState.getDescribe().getName(), 
                                                                                        Order.ShippingCountry.getDescribe().getName() => Order.ShippingState.getDescribe().getName() };
                    for(Order order : qualifiedOrders){
                        StateAndCountryValidation.validateRecordCountryStatePairs(order, countryStateFieldPairs);
                    }
                }
                
                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('OrderHelper', 'validateStateAndCountry');
            }
        }
        catch(Exception ex){
             SystemIssueLogHelper.LogException('OrderHelper', 'validateStateAndCountry', newOrUpdatedOrders, ex, true);
        }
    }


    /**
    * @author CRMCulture
    * @version 1.00
    * @description Order Helper Method called from the Order Before Update Trigger. Generates the XML required by Quickbooks 
    * when importing Invoices with Line Items. XML is only generated when the parent Order's Status = Sent, Credit Memo, or Refund and Ready_for_QB__c = true
    */
    //public static void GenerateQBInvoiceLineItemXML(Map<Id, Order> pNewOrders){
    //  if(TriggerHelper.DoExecute('Order.GenerateQBInvoiceLineItemXML')){
    //      //System.debug('Updated Orders: ' + pNewOrders.keySet());
    //      //System.debug('Keys: ' + pNewOrders.size());
            
    //      // Get Necessary Order Data
    //      List<Order> ordersToProcess = new List<Order>([SELECT Id, QB_Invoice_Line_Item_Aggregate_XML__c, (SELECT Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.QB_Class__c, Quantity, UnitPrice, Description FROM OrderItems) FROM Order 
    //                                                     WHERE Id IN :pNewOrders.keySet()]);
            
 //           if(ordersToProcess.size() > 0){
    //          for(Order order : ordersToProcess){
    //              // Process Only Qualifying Orders
    //              if((pNewOrders.get(order.Id).Status == 'Sent' || pNewOrders.get(order.Id).Status == 'Credit Memo' || pNewOrders.get(order.Id).Status == 'Refund') && pNewOrders.get(order.Id).Ready_for_QB__c == TRUE){
    //              //if(pNewOrders.get(order.Id).Status == 'Ready to Send' && pNewOrders.get(order.Id).Sent__c == true){   
    //                  String LineItemAggregate = '<InvoiceLineItems>';
    //                  Integer NumberOfLineItems = order.OrderItems.size();
    //                  Integer LineItemCount = 0;

    //                  for(OrderItem orderDetail : order.OrderItems){
    //                      LineItemCount = LineItemCount + 1;                          
    //                      String quantity = '0';
    //                      String rate = '0';
    //                      if(orderDetail.Quantity != null){
    //                          quantity = String.valueOf(orderDetail.Quantity);
    //                      }
    //                      if(orderDetail.UnitPrice != null){
 //                             rate =  String.valueOf(orderDetail.UnitPrice);                          
 //                         }

    //                      //Add Line Item Standard Fields to Aggregate
    //                      LineItemAggregate += '<Row>';
    //                      LineItemAggregate += '<ItemName>' + orderDetail.PricebookEntry.Product2.Name + '</ItemName>';
    //                      LineItemAggregate += '<ItemQuantity>' + quantity + '</ItemQuantity>';
    //                      LineItemAggregate += '<ItemRate>' + rate + '</ItemRate>';
    //                      LineItemAggregate += '<ItemClass>' + (String.isEmpty(orderDetail.PricebookEntry.Product2.QB_Class__c) ? '' : orderDetail.PricebookEntry.Product2.QB_Class__c) + '</ItemClass>';
    //                      LineItemAggregate += '<ItemDescription>'+ (String.isEmpty(orderDetail.Description) ? '' : orderDetail.Description) + '</ItemDescription>';

    //                      //  Close Row
    //                      LineItemAggregate += '</Row>';

    //                      // Add Line Item Aggregate to Order after last Line Item has been processed
    //                      if(LineItemCount == NumberOfLineItems){
    //                          // Finished with Line Items, Close XML
    //                          LineItemAggregate += '</InvoiceLineItems>'; 
    //                          pNewOrders.get(order.Id).QB_Invoice_Line_Item_Aggregate_XML__c = LineItemAggregate;
    //                      }
    //                  }
    //              }
    //          }
    //      }
    //  }
    //}

    
}