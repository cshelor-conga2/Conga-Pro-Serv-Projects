/**
* @author Mark Brundege
* @date 20200416
* @version 1.00
* @description EngineeringEventReplayHelper - Logic for discovering tracked object IDs which have changed within a date range, 
*                                               and resending Engineering_Event__e Platform Event objects to external endpoints
*/
public with sharing class EngineeringEventReplayHelper {
    private static Long MAX_TIMESPAN_SECONDS = 2592000; // 30 days
    
    // require format: 2020-10-30T15:27:02 or 2020-10-30 15:27:02 UTC time
    /**
    * @description parseValidateDateRange - 
    */
    public static DateTime [] parseValidateDateRange(String startDateStr, String endDateStr) {
        if ( (! String.isBlank(startDateStr)) && (! String.isBlank(endDateStr)) ) {
            try {
                startDateStr = EngineeringEventReplayHelper.cleanDateStr(startDateStr);
                endDateStr = EngineeringEventReplayHelper.cleanDateStr(endDateStr);
                DateTime startDate = DateTime.valueOfGmt(startDateStr);
                DateTime endDate = DateTime.valueOfGmt(endDateStr);
                if (endDate > startDate) {
                    Long milliSpan = (endDate.getTime() - startDate.getTime());
                    if (milliSpan < (MAX_TIMESPAN_SECONDS * 1000)) {
                        return new DateTime [] {startDate, endDate};
                    }
                }
            }
            catch (Exception e) {
                System.debug('DateTime parse error on strings ' + startDateStr + ' and ' + endDateStr);
            }
        }        
        return null;
    }
    
    /**
    * @description cleanDateStr
    */
    private static String cleanDateStr (String dateTimeStr) {
        dateTimeStr = dateTimeStr.replace('T', ' ');
        dateTimeStr = dateTimeStr.replace('%20', ' ');
        return dateTimeStr;
    }
    
    /**
    * @description processReplay
    */
    public static Map<String,Object> processReplay(String objectName, DateTime startDate, DateTime endDate) {
        List<sObject> totalObjs = lookupRequestedObjects(objectName, startDate, endDate);
        //EngineeringEventSender.createEngineeringEvent(totalObjs, null);
        return EngineeringEventReplayHelper.formatResponse(totalObjs);
    }

    /**
    * @description formatResponse
    */    
    private static Map<String, Object> formatResponse(List<sObject> totalObjs) {
        List<String> objIds = new List<String>();
        for (Integer i = 0; i < totalObjs.size(); i++) {
            objIds.add(totalObjs.get(i).Id);
        }
        Map<String, Object> returnMap = new Map<String, Object>();
		returnMap.put('changeIds', objIds);
        return returnMap;
    }

    /**
    * @description lookupRequestedObjects
    */    
    private static List<sObject> lookupRequestedObjects (String objectName, DateTime startDate, DateTime endDate) {
        List<sObject> totalObjs = new List<sObject>();
        if ( (String.isBlank(objectName)) || (objectName == 'all') || (objectName == 'Salesforce_Org__c') ) {
            List<sObject> salesforceOrgs = lookupObjectsChangedWithinDates('Salesforce_Org__c', startDate, endDate);
            totalObjs.addAll(salesforceOrgs);
        }
        // TODO: add lookup calls for other tracked objects when implemented
        return totalObjs;
    }

    /**
    * @description lookupObjectsChangedWithinDates
    */    
    private static List<sObject> lookupObjectsChangedWithinDates (String objectName, DateTime startDate, DateTime endDate) {
        String startDateStr = startDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String endDateStr = endDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String query = 'SELECT Id FROM ' + objectName + ' WHERE LastModifiedDate > ' + startDateStr + ' AND LastModifiedDate < ' + endDateStr;
        List<sObject> objList = new List<sObject>();
        for (sObject obj : Database.query(query)) {
            objList.add(obj);
        }
        return objList;
    }
    
    
}