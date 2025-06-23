/**
* @author ECS, ERedding
* @date 20190925
* @version 1.00
* @description IACRMSalesInvoiceHelper - Custom functionality for the ia_crm__Sales_Invoice__c object
*/
public with sharing class IACRMSalesInvoiceHelper {

    /**
    * @description stampInvoiceWithPeriod - Stamps an Intacct Sales Invoice with the period it is for. Usually the week before the Invoice is sent out.
    *                                         --- EXECUTED BY IACRM SALES INVOICE BEFORE INSERT AND BEFORE UPDATE TRIGGERS ---
    * @param List<ia_crm__Sales_Invoice__c> newOrUpdatedQuotes - List of updated Quote records
    * @param Map<Id, ia_crm__Sales_Invoice__c> outdatedQuotes - Map of outdated Quote records
    * @return void
    */
    public static void stampInvoiceWithPeriod(List<ia_crm__Sales_Invoice__c> newOrUpdatedInvoices, Map<Id, ia_crm__Sales_Invoice__c> outdatedInvoices){
        try{
            if(TriggerHelper.DoExecute('IACRMSalesInvoiceHelper','stampInvoiceWithPeriod') && newOrUpdatedInvoices != null){
                Map<Integer, String> monthNamesByNumber = new Map<Integer, String>{ 1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April', 5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August',
                                                                                    9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December' };

                // UPDATE QUALIFYING RECORDS
                for(ia_crm__Sales_Invoice__c newOrUpdatedInvoice : newOrUpdatedInvoices){
                    ia_crm__Sales_Invoice__c outdatedInvoice = outdatedInvoices != null ? outdatedInvoices.get(newOrUpdatedInvoice.Id) : null;
                    if(newOrUpdatedInvoice.ia_crm__Document_Type__c == 'Sales Invoice' && (outdatedInvoice == null || newOrUpdatedInvoice.ia_crm__Date__c != outdatedInvoice.ia_crm__Date__c)){
                    	Date periodStartDate = newOrUpdatedInvoice.ia_crm__Date__c.toStartOfWeek().addDays(-7);
                    	Date periodEndDate = newOrUpdatedInvoice.ia_crm__Date__c.toStartOfWeek().addDays(-1);
                    	String periodStartText = (periodStartDate.day() + ' ' + monthNamesByNumber.get(periodStartDate.month()) + ' ' + periodStartDate.year());
                    	String periodEndText = (periodEndDate.day() + ' ' + monthNamesByNumber.get(periodEndDate.month()) + ' ' + periodEndDate.year());

                    	// STAMP INVOICE
                    	newOrUpdatedInvoice.Period__c = (periodStartText + ' - ' + periodEndText);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('IACRMSalesInvoiceHelper', 'stampInvoiceWithPeriod');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('IACRMSalesInvoiceHelper', 'stampInvoiceWithPeriod', newOrUpdatedInvoices, ex, true);
        } 
    }








}