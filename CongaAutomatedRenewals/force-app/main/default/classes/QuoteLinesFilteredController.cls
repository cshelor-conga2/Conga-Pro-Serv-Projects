public class QuoteLinesFilteredController {
    public Id objId {get; set;}
    
    public List<SBQQ__QuoteLine__c> getQuoteLineList() {
        return [SELECT SBQQ__ProductName__c,
                SBQQ__StartDate__c,
                Opp_Item_Start_Date__c,
                SBQQ__EndDate__c,
                Opp_Item_End_Date__c,
                SBQQ__Quantity__c,
                SBQQ__EffectiveQuantity__c,
                SBQQ__ListPrice__c,
                SBQQ__CustomerPrice__c,
                SBQQ__Discount__c,
                SBQQ__AdditionalDiscountAmount__c,
                SBQQ__CustomerTotal__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :objId];
    }
}