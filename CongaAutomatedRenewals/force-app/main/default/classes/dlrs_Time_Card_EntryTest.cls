/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Time_Card_EntryTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Time_Card_EntryTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Time_Card_Entry__c());
    }
}