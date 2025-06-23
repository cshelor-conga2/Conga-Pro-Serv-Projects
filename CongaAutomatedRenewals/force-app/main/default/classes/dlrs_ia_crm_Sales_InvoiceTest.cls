/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_ia_crm_Sales_InvoiceTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_ia_crm_Sales_InvoiceTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new ia_crm__Sales_Invoice__c());
    }
}