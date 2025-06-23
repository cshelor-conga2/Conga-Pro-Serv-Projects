/**
* @author Mark Brundege
* @date 20200416
* @version 1.00
* @description EngineeringEventReplayHelperTest - Test class for the EngineeringEventReplayHelper class
*/
@isTest
public with sharing class EngineeringEventReplayHelperTest {
    
    @isTest static void ParseValidateDateRangeReturnsExpectedDatetimes () {
        DateTime dateTimeNow = datetime.now();
        DateTime startTime5MinAgo = dateTimeNow.addMinutes(-5);

        String startTimeStr = startTime5MinAgo.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        String endTimeStr = dateTimeNow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        DateTime[] parsedDateTimes = EngineeringEventReplayHelper.parseValidateDateRange(startTimeStr, endTimeStr);
        System.assertEquals(startTime5MinAgo, parsedDateTimes[0]);
        System.assertEquals(dateTimeNow, parsedDateTimes[1]);
        
    }
    
    @isTest static void ParseValidateDateRangeReturnsNullForOutOfOrderDateTimes () {
        DateTime dateTimeNow = datetime.now();
        DateTime startTime5MinAgo = dateTimeNow.addMinutes(-5);

        String startTimeStr = startTime5MinAgo.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        String endTimeStr = dateTimeNow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        
        // note adding out of order below
        DateTime[] parsedDateTimes = EngineeringEventReplayHelper.parseValidateDateRange(endTimeStr, startTimeStr);
        
        System.assertEquals(null, parsedDateTimes);
    }
    
    @isTest static void ParseValidateDateRangeReturnsNullForDateTimeRangeTooLarge () {
        DateTime dateTimeNow = datetime.now();
        DateTime startTime2MonthsAgo = dateTimeNow.addDays(-60);

        String startTimeStr = startTime2MonthsAgo.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        String endTimeStr = dateTimeNow.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        DateTime[] parsedDateTimes = EngineeringEventReplayHelper.parseValidateDateRange(startTimeStr, endTimeStr);
        
        System.assertEquals(null, parsedDateTimes);
    }
    
    @isTest static void ReplayHelperShouldReturnStringWithExpectedOrgId () {
        Salesforce_Org__c newSfOrg1 = new Salesforce_Org__c(Name = 'Test Org1');
        Salesforce_Org__c newSfOrg2 = new Salesforce_Org__c(Name = 'Test Org2');

        Test.startTest();

        insert new List<Salesforce_Org__c>{ newSfOrg1, newSfOrg2 };

        Test.stopTest();

        DateTime startTime5MinAgo = datetime.now().addMinutes(-5);
        DateTime endTime5MinAfter = datetime.now().addMinutes(5);
        Map<String,Object> replayMap = EngineeringEventReplayHelper.processReplay('Salesforce_Org__c', startTime5MinAgo, endTime5MinAfter);
        
        System.debug(replayMap);
        
        List<String> objIds = (List<String>)replayMap.get('changeIds');
        //System.debug('object ids:');
        //System.debug(objIds);

        System.assert(objIds.indexOf(newSfOrg1.Id) > -1);
        System.assert(objIds.indexOf(newSfOrg2.Id) > -1);
    }

}