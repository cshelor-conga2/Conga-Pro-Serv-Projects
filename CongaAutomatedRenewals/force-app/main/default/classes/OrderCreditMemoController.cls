/**
* @author CRMCulture
* @date 20160524
* @version 1.00
* @description OrderCreditMemoController
*/
public without sharing class OrderCreditMemoController {
    public Id InvoiceId {get;set;}
    public List<Order> InvoicesToClone {get;set;}
    public Decimal PercentApplied {get;set;}
    public Decimal DollarsApplied {get;set;}
    public Boolean ApplyToDiscount {get;set;}
    public List<OrderItem> UpdateItems {get;set;}

    /**
    * @description OrderCreditMemoController - Constructor 
    */
    public OrderCreditMemoController(ApexPages.StandardController ctrl) {
        InvoiceId = (Id)ctrl.getId();

        InvoicesToClone = new List<Order>(); 
        InvoicesToClone = [select Id,TotalAmount,Status from Order where Id = :InvoiceId];

        PercentApplied = null;
        DollarsApplied = null;
        ApplyToDiscount = false;
    }

    /**
    * @description AutoRun - 
    * @return PageReference
    */
    public PageReference AutoRun(){
        PageReference page = null;
        if(String.isNotBlank(InvoiceId)){
            Id creditMemoId = null;
            for(RecordType rt : [select Id,DeveloperName from RecordType where SObjectType = 'Order']){
                if(rt.DeveloperName == 'Credit_Memo'){
                    creditMemoId = rt.Id;
                }
            }
            Map<Id,sObject> cloneOrds = UtilityClass.cloneObjectsMap(invoicesToClone, invoicesToClone.get(0).getsObjectType());
            List<sObject> cords = new List<sObject>();
            for(Id key : cloneOrds.keySet()){
                Order co = (Order)cloneOrds.get(key);
                co.RecordTypeId = creditMemoId;
                co.Status = 'Draft';
                co.Invoice_Acknd__c = null;
                co.EffectiveDate = System.today();
                co.EndDate = System.today();
                cords.add(co);
            }
            insert cords;
            Map<Id,Id> newOrdIds = new Map<Id,Id>();
            for(Id oldOrdId : cloneOrds.keySet()){
                newOrdIds.put(oldOrdId, cloneOrds.get(oldOrdId).Id);
            }
            
            List<OrderItem> prods = new List<OrderItem>();
            if(!ApplyToDiscount){
                for(OrderItem oi : [select Id from OrderItem where OrderId in :cloneOrds.keySet()]){
                    prods.add(oi);
                }
            }
            else{
                for(OrderItem oi : [select Id from OrderItem where PricebookEntry.Product2.Name = 'Discount']){
                    prods.add(oi);
                }
            }
            if(cords.size()>0){
                if(prods.size()>0){
                    Map<Id,sObject> cloneProds =  UtilityClass.cloneObjectsMap(prods, prods.get(0).getsObjectType());
                    
                    // APPLY NEW ORDER ID TO ITEMS
                    List<sObject> values = cloneProds.values();
                    for(sObject ords : values){
                        Id oldOrdId = Id.valueOf(String.valueOf(ords.get('OrderId')));
                        
                        ords.put('SBQQ__QuoteLine__c', null);
                        ords.put('ServiceDate', null);
                        ords.put('EndDate', null);
                        
                        ords.put('OrderId', newOrdIds.get(oldOrdId));
                    }

                    insert values;

                    List<Order_Payment__c> opsToInsert = new List<Order_Payment__c>();
                    for(Id pmt : newOrdIds.keySet()){
                        Order_Payment__c op = new Order_Payment__c();
                        op.Credit_MemoId__c = newOrdIds.get(pmt);
                        op.InvoiceId__c = pmt;
                        if(PercentApplied != null && PercentApplied != 0){
                            op.Amount_Applied__c = InvoicesToClone[0].TotalAmount * (PercentApplied/100);
                        }
                        else if(DollarsApplied != null && DollarsApplied != 0){
                            op.Amount_Applied__c = DollarsApplied;
                        }
                        else{
                            op.Amount_Applied__c = InvoicesToClone[0].TotalAmount;
                        }
                        op.Payment_Received_Date__c = System.today();
                        op.Payment_Type__c = 'Refund';
                        opsToInsert.add(op);
                    }
                    insert opsToInsert;

                    updateItems = new List<OrderItem>();
                    for(OrderItem oi : [select Id,Quantity,UnitPrice,AVA_SFORDERS__LineTax__c,Order.TotalAmount,Order.ActivatedDate from OrderItem where Id in :values]){
                        if(DollarsApplied != oi.Order.TotalAmount && PercentApplied != 100){
                            oi.Quantity = (-1);
                            if(PercentApplied != null && PercentApplied != 0){
                                oi.UnitPrice = InvoicesToClone[0].TotalAmount * (PercentApplied/100);
                            }
                            else if(DollarsApplied != null && DollarsApplied != 0){
                                oi.UnitPrice = DollarsApplied;
                            }
                        }
                        else{
                            oi.Quantity = (-1) * oi.Quantity;
                        }
                        if(oi.AVA_SFORDERS__LineTax__c != null){
                            oi.AVA_SFORDERS__LineTax__c = oi.AVA_SFORDERS__LineTax__c * (-1);
                        }
                        updateItems.add(oi);
                    }

                    if(updateItems.size()>0){
                        update updateItems;
                    }

                }

                if(InvoicesToClone[0].Status != null){
                    update InvoicesToClone[0];
                }
                
                page = new ApexPages.StandardController(cords[0]).view();
                page.setRedirect(true);
            }
        }
        return page;
    }


}