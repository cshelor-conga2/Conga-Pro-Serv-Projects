/**
 * @author CoE, ERedding
 * @date 2021005
 * @version 1.00
 * @param After Update trigger event for the AppAnalyticsQueryRequest sobject
*/ 
trigger AppAnalyticsQueryRequestTrigger on AppAnalyticsQueryRequest (before insert, after update) {
    TriggerFactory.createTriggerDispatcher(AppAnalyticsQueryRequest.sObjectType);
}