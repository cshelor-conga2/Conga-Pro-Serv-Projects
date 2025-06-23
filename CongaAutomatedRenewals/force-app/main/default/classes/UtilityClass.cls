/**
* @author Conga Services
* @date 20140701
* @version 1.00
* @description This class has helper methods.
*/
public with sharing class UtilityClass {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////// STATIC VARIABLES //////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // GLOBAL DESCRIBE SOBJECTTYPES
    public static Map<String, Schema.SObjectType> SObjectTypes {
    get {
        if(SObjectTypes == null){
            SObjectTypes = Schema.getGlobalDescribe();
        }
        return SObjectTypes;
    } set; }


    // ALL ORG RECORD TYPES
    public static Map<String, Map<String, Id>> AllRecordTypes {
    get {
        if(AllRecordTypes == null){
            AllRecordTypes = new Map<String, Map<String, Id>>();
            for(RecordType rt : [SELECT Id, DeveloperName, SobjectType FROM RecordType]){
                if(!AllRecordTypes.containsKey(rt.SobjectType)){
                    AllRecordTypes.put(rt.SobjectType, new Map<String, Id>());
                }
                AllRecordTypes.get(rt.SobjectType).put(rt.DeveloperName, rt.Id);
            }
        }
        return AllRecordTypes;
    } set; }


    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// STATIC METHODS ///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * @author Conga Services
    * @version 1.00, 20140701
    * @description Gets the type name of the SObject.
    * @param SObject The SObject for which the name to be obtained.
    * @return String - The type name.
    */
    public static String getSObjectTypeName(SObject so) {
        return so.getSObjectType().getDescribe().getName();
    }

    public static List<MonthCost> getMonthCosts(Decimal totalAmount, Date startDate, Date endDate){ 
        Integer numberOfDays = startDate.daysBetween(endDate);
        Integer numberOfMonths = startDate.monthsBetween(endDate);
        Decimal costPerDay = ((Decimal)(totalAmount / (Decimal)numberOfDays));
        Decimal runningCost = 0.0;
        Map<String,MonthCost> aggCost = new Map<String,MonthCost>();
        for(Date b = startDate; b <= endDate; b= b.addDays(1)){
            String dateKey = b.year() + '-' + b.month();
            if(!aggCost.containsKey(dateKey)){
                aggCost.put(dateKey, new MonthCost(b.year(), b.month())); 
            }
            aggCost.get(dateKey).NoDays += 1;
            Decimal roundedValue = costPerDay.setScale(2, system.RoundingMode.HALF_UP);
            aggCost.get(dateKey).Cost += roundedValue;
            runningCost += roundedValue;
            if(b== endDate){
              aggCost.get(dateKey).Cost += (totalAmount - runningCost);
            }
        }
        return new List<MonthCost>(aggCost.values());
    }
    
    public class MonthCost{
        public Integer Year {get;set;}
        public Integer Month {get;set;}
        public Integer NoDays {get;set;}
        public Decimal Cost {get;set;}
        public MonthCost(Integer year, Integer month){
            this.Cost = 0.0000;
            this.Year = year;
            this.Month = month;
            this.NoDays = 0;
        }
    }  

    /**
    * @author Conga Services
    * @version 1.10, 20151201
    * @description Clones every field given a list of any object type (objects only need to have id field queried)
    * @param SObject The SObject for which the name to be obtained.
    * @return String - The type name.
    */
    public static Map<Id, sObject> cloneObjectsMap(List<sObject> sObjects, Schema.SObjectType objectType){
       // A list of IDs representing the objects to clone
       List<Id> sObjectIds = new List<Id>{};
       // A list of fields for the sObject being cloned
       List<String> sObjectFields = new List<String>{};
       // A list of new cloned sObjects
       Map<Id, sObject> clonedSObjects = new Map<Id, sObject>{};

       // Get all the fields from the selected object type using
       // the get describe method on the object type.
       if(objectType != null){
           sObjectFields.addAll(objectType.getDescribe().fields.getMap().keySet());
       }

       // If there are no objects sent into the method,
       // then return an empty list
       if (sObjects != null && !sObjects.isEmpty() && !sObjectFields.isEmpty()){
           // Strip down the objects to just a list of Ids.
           for (sObject objectInstance: sObjects){
               sObjectIds.add(objectInstance.Id);
           }
           // Using the list of sObject IDs and the object type,
           // we can construct a string based SOQL query   to retrieve the field values of all the objects.
           String allSObjectFieldsQuery = 'SELECT ' + sObjectFields.get(0);
           for (Integer i=1 ; i < sObjectFields.size() ; i++){
               allSObjectFieldsQuery += ', ' + sObjectFields.get(i);
           }
           allSObjectFieldsQuery += ' FROM ' +
                                  objectType.getDescribe().getName() +
                                  ' WHERE ID IN (\'' + sObjectIds.get(0) +
                                  '\'';

           for (Integer i=1 ; i < sObjectIds.size() ; i++){
               allSObjectFieldsQuery += ', \'' + sObjectIds.get(i) + '\'';
           }
           allSObjectFieldsQuery += ')';
           try{
               // Execute the query. For every result returned,
               // use the clone method on the generic sObject
               // and add to the collection of cloned objects
               for (SObject sObjectFromDatabase:  Database.query(allSObjectFieldsQuery)){
                   clonedSObjects.put(sObjectFromDatabase.Id, sObjectFromDatabase.clone(false,true));
               }
           }
           catch (Exception ex){
               System.debug('Clone Object Exception:' + ex.getMessage());
               throw ex;
           }
       }

       // return the cloned sObject collection.
       return clonedSObjects;
   }

    /**
    * @author Conga Services
    * @version 1.00, 20140822
    * @return String
    * @description returns a GUID string - helpful for creating unique temporary ids in settings tables
    */
    private static String kHexChars = '0123456789abcdef';
    public static String NewGuid() {
        String returnValue = '';
        Integer nextByte = 0;

        for (Integer i=0; i<16; i++) {

            if (i==4 || i==6 || i==8 || i==10) 
                returnValue += '-';

            nextByte = (Math.round(Math.random() * 255)-128) & 255;

            if (i==6) {
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);
            }

            if (i==8) {
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
            }

            returnValue += getCharAtIndex(kHexChars, nextByte >> 4);
            returnValue += getCharAtIndex(kHexChars, nextByte & 15);
        }

        return returnValue;
    }

    private static String getCharAtIndex(String str, Integer index) {
        if (str == null) return null;
        if (str.length() <= 0) return str;
        if (index == str.length()) return null;
        return str.substring(index, index+1);
    }

    /**
    * @description mergeRecords - Overload method for mergeRecords that takes single SObjects as parameters
    * @param SObject recordToUpdate - Record to be updated by merge
    * @param SObject recordToMerge - Record to be merged
    * @return SObject - SObject containing merged data
    */ 
    public static SObject mergeRecords(SObject recordToUpdate, SObject recordToMerge){
        if(recordToUpdate != null && recordToMerge != null && recordToUpdate.Id == recordToMerge.Id && recordToUpdate.getSObjectType() == recordToMerge.getSObjectType()){
            Map<Id, SObject> mergedRecords = mergeRecords(new Map<Id, SObject>{ recordToUpdate.Id => recordToUpdate }, new Map<Id, SObject>{ recordToMerge.Id => recordToMerge });
            recordToUpdate =  mergedRecords != null && !mergedRecords.isEmpty() ? mergedRecords.values()[0] : null;
        }
        return recordToUpdate;
    }
    /**
    * @description mergeRecords - Merges changed data of sobjects from right to left (recordsToMerge INTO recordsToUpdate)
    * @param Map<Id, SObject> recordsToUpdate - Records to be updated by merge
    * @param Map<Id, SObject> recordsToMerge - Records to be merged
    * @return Map<Id, SObject> - Map of SObjects containing merged data
    */ 
    public static Map<Id, SObject> mergeRecords(Map<Id, SObject> recordsToUpdate, Map<Id, SObject> recordsToMerge){
        if(recordsToUpdate != null && !recordsToUpdate.isEmpty() && recordsToMerge != null && !recordsToMerge.isEmpty()){
            for(SObject recordToUpdate : recordsToUpdate.values()){
                if(recordToUpdate.Id != null && recordsToMerge.containsKey(recordToUpdate.Id)){
                    // GET POPULATED FIELDS FROM SOBJECT TO MERGE
                    Map<String, Object> fieldsToMerge = recordsToMerge.get(recordToUpdate.Id).getPopulatedFieldsAsMap();

                    // MERGE DIFFERING DATA FROM RIGHT TO LEFT
                    for(String fieldName : fieldsToMerge.keySet()){
                        if(fieldName != 'Id' && recordToUpdate.get(fieldName) != fieldsToMerge.get(fieldName)){
                            recordToUpdate.put(fieldName, fieldsToMerge.get(fieldName));
                        }
                    }
                }
            }
        }
        return recordsToUpdate;
    }

    /**
    * @description getDistanceBetweenDates - 
    * @param Date pStartDate - Starting date
    * @param Date pEndDate - Ending date
    * @param String pInterval - Interval to calculate. Available values are Milliseconds, Seconds, Minutes, Hours, Days, Weeks, Months, Quarters, Years
    * @param Integer pScale - 
    * @return Decimal - Distance between the given dates returned in the specified interval to the specified scale (decimal places)
    */ 
    public enum Interval { Milliseconds, Seconds, Minutes, Hours, Days, Weeks, Months, Quarters, Years }
    public static Decimal getDistanceBetweenDates(Date pStartDate, Date pEndDate, Interval pInterval, Integer pScale) {
        if(pStartDate != null && pEndDate != null){
            Datetime startDateTime = Datetime.newInstanceGMT(pStartDate.year(), pStartDate.month(), pStartDate.day(), 0, 0, 0);
            Datetime endDateTime = Datetime.newInstanceGMT(pEndDate.year(), pEndDate.month(), pEndDate.day(), 23, 59, 59);
            return getDistanceBetweenDates(startDateTime, endDateTime, pInterval, pScale);
        }
        return 0.00;
    }
    public static Decimal getDistanceBetweenDates(Datetime pStartDateTime, Datetime pEndDateTime, Interval pInterval, Integer pScale) {
        if(pStartDateTime != null && pEndDateTime != null){
            Decimal milliseconds = (pEndDateTime.getTime() - pStartDateTime.getTime()) + 999;
            pScale = Math.abs(UtilityClass.replaceNull(pScale, 0));

            // CALCULATE MONTHS IF REQUESTED INTERVAL IS MONTHS OR QUARTERS
            Decimal totalMonths = 0.00;
            if(pInterval == Interval.Months || pInterval == Interval.Quarters){
                Map<Decimal, Decimal> numOfDaysPerMonth = new Map<Decimal, Decimal>{ 1=>31, 2=>28, 3=>31, 4=>30, 5=>31, 6=>30, 7=>31, 8=>31, 9=>30, 10=>31, 11=>30, 12=>31 };
                Date startDate = pStartDateTime.dateGMT();
                Date endDate = pEndDateTime.dateGMT();

                // STARTING DATE
                Decimal daysInStartingMonth = startDate.month() == 2 && Date.isLeapYear(startDate.year()) ? 29 : numOfDaysPerMonth.get(startDate.month());
                Decimal daysInEndingMonth = endDate.month() == 2 && Date.isLeapYear(endDate.year()) ? 29 : numOfDaysPerMonth.get(endDate.month());
                if(startDate < Date.newInstance(endDate.year(), endDate.month(), 1)){
                    // STARTING AND ENDING DATES ARE -NOT- IN THE SAME MONTH/YEAR

                    // ADD AMOUNT OF MONTH FROM STARTING DATE
                    totalMonths += ((daysInStartingMonth - startDate.day()) + 1) / daysInStartingMonth;

                    // ADD AMOUNT OF MONTH FROM ENDING DATE
                    totalMonths += endDate.day() / daysInEndingMonth;
                }
                else{
                    // STARTING AND ENDING DATES -ARE- IN THE SAME MONTH/YEAR
                    totalMonths += (endDate.day() - startDate.day() + 1) / daysInStartingMonth;
                }

                // COUNT WHOLE MONTHS BETWEEN DATES, EXCLUDING START AND END
                Date betweenMonthsDate = Date.newInstance(startDate.year(), startDate.month() + 1, 1);
                while(betweenMonthsDate < Date.newInstance(endDate.year(), endDate.month(), 1)){
                    totalMonths++;
                    betweenMonthsDate = betweenMonthsDate.addMonths(1);
                }
            }

            if(pInterval == Interval.Milliseconds){ return milliseconds; } // RETURN MILLISECONDS
            else if(pInterval == Interval.Seconds){ return (milliseconds/1000).setScale(pScale); } // RETURN SECONDS
            else if(pInterval == Interval.Minutes){ return (milliseconds/1000/60).setScale(pScale); } // RETURN MINUTES
            else if(pInterval == Interval.Hours){ return (milliseconds/1000/60/60).setScale(pScale); } // RETURN HOURS
            else if(pInterval == Interval.Days){ return (milliseconds/1000/60/60/24).setScale(pScale); } // RETURN DAYS
            else if(pInterval == Interval.Weeks){ return (milliseconds/1000/60/60/24/7).setScale(pScale); } // RETURN WEEKS             
            else if(pInterval == Interval.Months){ return totalMonths.setScale(pScale); } // RETURN MONTHS
            else if(pInterval == Interval.Quarters){ return (totalMonths/3.00).setScale(pScale); } // RETURN QUARTERS
            else if(pInterval == Interval.Years && !checkRangeForLeapYear(pStartDateTime.dateGMT(), pEndDateTime.dateGMT())){
                return (milliseconds/1000/60/60/24/365).setScale(pScale); // RETURN YEARS -NOT- CONSIDERING LEAP YEARS
            }
            else if(pInterval == Interval.Years && checkRangeForLeapYear(pStartDateTime.dateGMT(), pEndDateTime.dateGMT())){
                return (milliseconds/1000/60/60/24/(365 + (1 / (milliseconds/1000/60/60/24/365)))).setScale(pScale); // RETURN YEARS CONSIDERING LEAP YEARS
            }
        }
        return 0.00;
    }

    /**
    * @author ECS, ERedding
    * @date 20181026
    * @description checkRangeForLeapYear - Checks if a February 29th leap year day occurs between two dates. 
    * @param Date pStartDate - Starting date
    * @param Date pEndDate - Ending date
    * @return Boolean - True, a 29th Feb day does occur OR False, it does not.
    */
    public static Boolean checkRangeForLeapYear(Date pStartDate, Date pEndDate) {
        if(pStartDate != null && pEndDate != null){
            ////////// ADD START DATE YEAR IF APPLICABLE
            if(Date.isLeapYear(pStartDate.year()) && pStartDate <= Date.newInstance(pStartDate.year(),2,29) && pEndDate >= Date.newInstance(pStartDate.year(),2,29)){
                return true;
            }

            ////////// ADD END DATE YEAR IF APPLICABLE
            if(Date.isLeapYear(pEndDate.year()) && pEndDate >= Date.newInstance(pEndDate.year(),2,29) && pStartDate <= Date.newInstance(pEndDate.year(),2,29)){
                return true;
            }

            ////////// CHECK FOR ANY LEAP YEARS BETWEEN START AND END IF A FULL YEAR FALLS BETWEEN THE DATES
            if(pEndDate.year() - pStartDate.year() > 1){
                for(Integer year = pStartDate.year() + 1; year < pEndDate.year(); year++){
                    if(Date.isLeapYear(year)){
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
    * @author ECS, ERedding
    * @date 20181114
    * @description replaceNull - Replaces a null parameter with a replacement value. Multiple overload methods for handling different inputs
    * @param String, Date, Integer, Decimal pCheckValue - Value to check for null
    * @param String, Date, Integer, Decimal pReplacementValue - Replacement value to be used in place of null
    * @return String, Date, Integer, Decimal
    */
    public static String replaceNull(String pCheckValue, String pReplacementValue) {
        return (pCheckValue == null ? pReplacementValue : pCheckValue);
    }
    public static Date replaceNull(Date pCheckValue, Date pReplacementValue) {
        return (pCheckValue == null ? pReplacementValue : pCheckValue);
    }
    public static Integer replaceNull(Integer pCheckValue, Integer pReplacementValue) {
        return (pCheckValue == null ? pReplacementValue : pCheckValue);
    }
    public static Decimal replaceNull(Decimal pCheckValue, Decimal pReplacementValue) {
        return (pCheckValue == null ? pReplacementValue : pCheckValue);
    }

    /**
    * @author ECS, ERedding
    * @date 20180809
    * @description validateId - Validates that a given string is a 15 or 18 character SF record Id
    * @param String pIdString - String to validate
    * @return Boolean
    */
    public static Boolean validateId(String pIdString) {
        if(String.isNotBlank(pIdString)){
            String cleanString = pIdString.trim();
            if((cleanString.length() == 15 || cleanString.length() == 18) && Pattern.matches('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}', cleanString)) {
                return true;
            }
        }
        return false;
    }

    /**
    * @author ECS, ERedding
    * @date 20180906
    * @description getAllRecordTypes - Return nested maps of all SObject record types by SObject Name and recordtype DeveloperName.
    * @return Map<String, Map<String, Id>>
    */
    public static Map<String, Map<String, Id>> getAllRecordTypes(){
        return AllRecordTypes;
    }

    /**
    * @author ECS, ERedding
    * @date 20190416
    * @description getRecordTypesForObjects - Returns record types for the specified objects
    * @param List<String> objectAPINames - List of API names of the SObjects to get record types for
    * @return Map<String, Map<String, Id>> - Nested Maps organizing record type ids by SObject API Name and record type Developer Name
    */
    public static Map<String, Map<String, Id>> getRecordTypesForObjects(List<String> objectAPINames){
        Map<String, Map<String, Id>> recordTypeMap = new Map<String, Map<String, Id>>();
        if(objectAPINames != null){
            for(String objectAPIName : objectAPINames){
                if(AllRecordTypes.containsKey(objectAPIName)){
                    for(String rtDeveloperName : AllRecordTypes.get(objectAPIName).keySet()){
                        if(!recordTypeMap.containsKey(objectAPIName)){
                            recordTypeMap.put(objectAPIName, new Map<String, Id>());
                        }
                        recordTypeMap.get(objectAPIName).put(rtDeveloperName, AllRecordTypes.get(objectAPIName).get(rtDeveloperName));      
                    }
                }

                ////////////////////// 20200528 ECS EREDDING - OLD RECORD TYPE RETRIEVAL THAT USES A MUCH SLOWER METHOD /////////////////////
                //Schema.SObjectType sObjectType = SObjectTypes.get(objectAPIName);
                //if(sObjectType != null){
                //    Map<Id, Schema.RecordTypeInfo> recordTypesById = sObjectType.getDescribe().getRecordTypeInfosById();
                //    for(Schema.RecordTypeInfo recordTypeInfo : recordTypesById.values()){
                //        if(!recordTypeMap.containsKey(objectAPIName)){
                //            recordTypeMap.put(objectAPIName, new Map<String, Id>());
                //        }
                //        recordTypeMap.get(objectAPIName).put(recordTypeInfo.getDeveloperName(), recordTypeInfo.getRecordTypeId());                
                //    }
                //}
            }
        }
        return recordTypeMap;
    }

    /**
    * @author ECS, ERedding
    * @date 20181019
    * @description getRecordTypesForObject - Returns record types for the specified object
    * @param String objectAPIName - API Name of the object to get record types for
    * @return Map<String, Id> - Map of record types DeveloperNames by Record Type Id
    */
    public static Map<String, Id> getRecordTypesForObject(String objectAPIName){
        return AllRecordTypes.get(objectAPIName);

        ////////////////////// 20200528 ECS EREDDING - OLD RECORD TYPE RETRIEVAL THAT USES A MUCH SLOWER METHOD /////////////////////
        //Schema.SObjectType sObjectType = SObjectTypes.get(objectAPIName);
        //if(sObjectType != null){
        //    Map<Id, Schema.RecordTypeInfo> recordTypesById = sObjectType.getDescribe().getRecordTypeInfosById();
        //    for(Schema.RecordTypeInfo recordTypeInfo : recordTypesById.values()){
        //        recordTypeMap.put(recordTypeInfo.getDeveloperName(), recordTypeInfo.getRecordTypeId());                
        //    }
        //}
    }

    /**
    * @author ECS, ERedding
    * @date 20181019
    * @description picklistValues - Gets the active picklist values for a picklist field 
    * @param String objectAPIName - API name of an object
    * @param String fieldAPIName - API name of the picklist field
    * @return Map<String, String> - Map of picklist labels by their api name
    */
    public static Map<String, String> getPicklistValues(String objectAPIName, String fieldAPIName){
        Map<String,String> picklistLabelsByValue = new Map<String,String>();
        Schema.SObjectType objType = SObjectTypes.get(objectAPIName);
        if(objType != null){
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();  
            List<Schema.PicklistEntry> values = fieldMap.get(fieldAPIName).getDescribe().getPickListValues();
            for(Schema.PicklistEntry pickListVal : values){ 
                if(pickListVal.isActive()){
                    picklistLabelsByValue.put(pickListVal.getValue(), pickListVal.getLabel());
                }
            }
        }
        return picklistLabelsByValue;
    }

    /**
    * @author Christian Tinghino, https://bugcoder.it/?p=38
    * @date 20171129
    * @description picklistValuesByRecordType - Uses the Salesforce API to get applicable picklist values for a specific object and record type
    *                                           REQUIRES A REMOTE SITE TO BE CONFIGURED WITH YOUR ORG'S URL. USING WITHIN LIGHTNING REQUIRES 
    *                                           A DIFFERENT ACCESS SOLUTION FOUND HERE: https://rajvakati.com/2018/01/28/salesforce-ui-api-lightning-examples/
    *
    *                                           *** CONGA SERVICES EREDDING 20181018, ENHANCED TO HANDLE EITHER AN ID OR A DEVELOPER NAME
    *
    * @param String objectAPIName - API name of an object
    * @param String recordTypeIdOrDevName - Id OR DeveloperName of the record type by which to filter picklist values
    * @param String fieldAPIName - API name of the picklist field to get values from
    * @return Map<String, String> - Map of picklist labels by their api name
    */
    public static Map<String, String> getPicklistValuesByRecordType(String objectAPIName, String recordTypeIdOrDevName, String fieldAPIName) {
        // GET RECORD TYPE ID
        Id recordTypeId;
        if(recordTypeIdOrDevName instanceof Id){
            recordTypeId = Id.valueOf(recordTypeIdOrDevName);
        }
        else{
            Map<String, Id> objectRecordTypes = getRecordTypesForObject(objectAPIName);
            if(objectRecordTypes.containsKey(recordTypeIdOrDevName)){
                recordTypeId = objectRecordTypes.get(recordTypeIdOrDevName);
            }
        }

        Map<String,String> result = new Map<String,String>();
        if(recordTypeId != null){
            // BUILD ENDPOINT
            String endpoint = URL.getSalesforceBaseUrl().toExternalForm();
            endpoint += '/services/data/v41.0';
            endpoint += '/ui-api/object-info/{0}/picklist-values/{1}/{2}';
            endpoint = String.format(endpoint, new String[]{ objectAPIName, recordTypeId, fieldAPIName });
            EncodingUtil.urlEncode(endpoint,'UTF-8');

            // BUILD AND SEND HTTP REQUEST
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse res;
            try{
                res = http.send(req);
            }
            catch(CalloutException ex){
                System.debug('A Remote Site must be set up granting this code HTTP access to your org. Your Remote Site URL will be: ' + URL.getSalesforceBaseUrl().toExternalForm());
                throw ex;
            }

            // PARSE HTTP RESPONSE AND RETREIVE PICKLIST VALUES AND LABELS
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if(!root.containsKey('values')){
                return result; // NO VALUES FOUND, RETURN EMPTY MAP
            }
            List<Object> pValues = (List<Object>)root.get('values');
            for(Object pValue : pValues){
                Map<String, Object> pValueMap = (Map<String, Object>)pValue;
                result.put((String)pValueMap.get('value'), (String)pValueMap.get('label'));
            }
        }
        return result;
    }

    /**
    * @author Glyn Anderson, https://glyntalkssalesforce.blogspot.com/2018/08/dependent-picklist-values-in-apex.html
    * @date 20180813
    * @description dependentPicklistValues - Gets the controlling values and dependent picklist values of a controlling field.
    * @param Schema.sObjectField controlField - Schema.sObjectField of the controlling Picklist or Checkbox field.
    * @return Map<Object, List<String>> - Map of control api values to their dependent picklist api values.
    */
    public static Map<Object,List<String>> getDependentPicklistValues(Schema.sObjectField dependentField){
        Schema.DescribeFieldResult dependDescribe = dependentField.getDescribe();
        Schema.sObjectField controlToken = dependDescribe.getController();

        if(controlToken == null) return new Map<Object, List<String>>(); // RETURN EMPTY MAP IF THE SUPPLIED DEPENDENT FIELD HAS NO CONTROLLING FIELD

        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries = control.getType() == Schema.DisplayType.Boolean ? null : control.getPicklistValues();
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
        for(Schema.PicklistEntry entry : dependDescribe.getPicklistValues()){
            if(entry.isActive()){
                List<String> base64chars = String.valueOf(((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for(Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++){
                    Object controlValue = (controlEntries == null ? (Object)(index == 1) : (Object)(controlEntries[index].isActive() ? controlEntries[index].getValue() : null));
                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod(index, 6);
                    if(controlValue == null || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0){
                        continue;
                    }

                    if (!dependentPicklistValues.containsKey(controlValue)){
                        dependentPicklistValues.put(controlValue, new List<String>());
                    }
                    dependentPicklistValues.get(controlValue).add(entry.getValue());
                }
            }
        }
        return dependentPicklistValues;
    }


}