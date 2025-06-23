/**
* @author Conga Services, eredding
* @date 20180809
* @version 1.00
* @description UtilityClassTest - Test methods for the UtilityClass class
*/
@isTest
public with sharing class UtilityClassTest {

    /**
    * @description getSObjectTypeNameTest 
    */
    public static testmethod void getSObjectTypeNameTest() {
        Account testAccount = new Account();
        String sObjectName = UtilityClass.getSObjectTypeName(testAccount);
        System.assert(String.isNotBlank(sObjectName));
        System.assert(sObjectName == 'Account');
    }

    /**
    * @description getMonthCostsTest 
    */
    public static testmethod void getMonthCostsTest() {
        List<UtilityClass.MonthCost> monthCosts = UtilityClass.getMonthCosts(25000, Date.today(), Date.today().addMonths(11));
        System.assert(monthCosts.size() == 12);
    }

    /**
    * @description newGuidTest 
    */
    public static testmethod void cloneObjectsMapTest() {
        List<Account> testAccounts = new List<Account>();
        Account testAccount1 = new Account(Name = 'Test Account 1');
        Account testAccount2 = new Account(Name = 'Test Account 2');
        testAccounts.add(testAccount1); testAccounts.add(testAccount2);
        insert testAccounts;

        Map<Id, sObject> clonedAccounts = UtilityClass.cloneObjectsMap(testAccounts, testAccount1.getsObjectType());
        System.assert(clonedAccounts.size() == 2);
        System.assert(clonedAccounts.containsKey(testAccount1.Id));
        System.assert(clonedAccounts.containsKey(testAccount2.Id));
        System.assert(((Account)clonedAccounts.get(testAccount1.Id)).Name == testAccount1.Name);
        System.assert(((Account)clonedAccounts.get(testAccount2.Id)).Name == testAccount2.Name);
    }

    /**
    * @description newGuidTest 
    */
    public static testmethod void newGuidTest() {
        String newGuid = UtilityClass.NewGuid();
        System.assert(String.isNotBlank(newGuid));
        System.assert(newGuid.length() == 36);
    }

    /**
    * @description validateIdTest 
    */
    public static testmethod void validateIdTest() {
        Boolean validId = UtilityClass.validateId('00Q5000001L7Xty');
        Boolean invalidId = UtilityClass.validateId('00Q5000001L7Xty.');
        System.assert(validId == true);
        System.assert(invalidId == false);
    }

    /**
    * @description mergeRecordsTest 
    */
    public static testmethod void mergeRecordsTest() {
        // CREATE TEST ACCOUNTS
        Account testAccount = new Account(Name = 'Test Account', Type = 'Customer');
        insert testAccount;

        // CREATE TEST OPPORTUNITIES
        Opportunity testOpportunity1 = new Opportunity(Name = 'Test Opp', Type = 'New Business', AccountId = testAccount.Id, CloseDate = Date.today().addDays(30), StageName = 'Qualify');
        Opportunity testOpportunity2 = new Opportunity(Name = 'Test Opp 2', Type = 'Existing Business', AccountId = testAccount.Id, CloseDate = Date.today().addDays(30), StageName = 'Qualify');
        Opportunity testOpportunity3 = new Opportunity(Name = 'Test Opp 3', Type = 'Renewal', AccountId = testAccount.Id, CloseDate = Date.today().addDays(30), StageName = 'Qualify');
        insert new List<Opportunity>{ testOpportunity1, testOpportunity2, testOpportunity3 };

        // CREATE MODIFIED VERSIONS OF TEST RECORDS
        Account testAccountChanges = new Account(Id = testAccount.Id, Phone = '1231231234', Fax = '321324321', Website = 'www.testaccount.com', Description = 'Test Description');
        
        Opportunity testOpportunity1Changes = new Opportunity(Id = testOpportunity1.Id, CloseDate = Date.today().addDays(60), Description = 'Test Desc 123', Type = 'Renewal', StageName = 'Business Evaluation');
        Opportunity testOpportunity2Changes = new Opportunity(Id = testOpportunity2.Id, CloseDate = Date.today().addDays(60), Description = 'Test Desc 321', Type = 'New Business', StageName = 'Solution');
        Opportunity testOpportunity3Changes = new Opportunity(Id = testOpportunity3.Id, CloseDate = Date.today().addDays(60), Description = 'Test Desc 987', Type = 'Existing Business', StageName = 'Negotiation');

        Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>{ testOpportunity1.Id => testOpportunity1,
                                                                      testOpportunity2.Id => testOpportunity2,
                                                                      testOpportunity3.Id => testOpportunity3
                                                                    };

        Map<Id, Opportunity> oppChangesToMerge = new Map<Id, Opportunity>{ testOpportunity1.Id => testOpportunity1Changes,
                                                                           testOpportunity2.Id => testOpportunity2Changes,
                                                                           testOpportunity3.Id => testOpportunity3Changes
                                                                        };

        Test.startTest();

        // RUN MERGE FUNCTIONALITY
        testAccount = (Account)UtilityClass.mergeRecords(testAccount, testAccountChanges);
        Map<Id, Opportunity> mergedOpps = (Map<Id, Opportunity>)UtilityClass.mergeRecords(oppsToUpdate, oppChangesToMerge);
        testOpportunity1 = mergedOpps.get(testOpportunity1.Id);
        testOpportunity2 = mergedOpps.get(testOpportunity2.Id);
        testOpportunity3 = mergedOpps.get(testOpportunity3.Id);

        // TEST FOR CORRECTLY MERGED RECORDS
        //// ACCOUNT DATA
        System.assert(testAccount.Name == 'Test Account');
        System.assert(testAccount.Type == 'Customer');
        System.assert(testAccount.Phone == testAccountChanges.Phone);
        System.assert(testAccount.Fax == testAccountChanges.Fax);
        System.assert(testAccount.Website == testAccountChanges.Website);
        System.assert(testAccount.Description == testAccountChanges.Description);
        //// OPPORTUNITY 1 DATA
        System.assert(testOpportunity1.Name == 'Test Opp');
        System.assert(testOpportunity1.Type == testOpportunity1Changes.Type);
        System.assert(testOpportunity1.AccountId == testAccount.Id);
        System.assert(testOpportunity1.CloseDate == testOpportunity1Changes.CloseDate);
        System.assert(testOpportunity1.Description == testOpportunity1Changes.Description);
        System.assert(testOpportunity1.StageName == testOpportunity1Changes.StageName);
        //// OPPORTUNITY 2 DATA
        System.assert(testOpportunity2.Name == 'Test Opp 2');
        System.assert(testOpportunity2.Type == testOpportunity2Changes.Type);
        System.assert(testOpportunity2.AccountId == testAccount.Id);
        System.assert(testOpportunity2.CloseDate == testOpportunity2Changes.CloseDate);
        System.assert(testOpportunity2.Description == testOpportunity2Changes.Description);
        System.assert(testOpportunity2.StageName == testOpportunity2Changes.StageName);
        //// OPPORTUNITY 3 DATA
        System.assert(testOpportunity3.Name == 'Test Opp 3');
        System.assert(testOpportunity3.Type == testOpportunity3Changes.Type);
        System.assert(testOpportunity3.AccountId == testAccount.Id);
        System.assert(testOpportunity3.CloseDate == testOpportunity3Changes.CloseDate);
        System.assert(testOpportunity3.Description == testOpportunity3Changes.Description);
        System.assert(testOpportunity3.StageName == testOpportunity3Changes.StageName);

        Test.stopTest();
    }

    /**
    * @description getDistanceBetweenDatesTest 
    */
    public static testmethod void getDistanceBetweenDatesTest() {
        // TEST DATES, ONE YEAR SPAN
        Date testStartDate = Date.newInstance(2019, 1, 1);
        Date testEndDate = Date.newInstance(2019, 12, 31);

        // TEST DATETIMES, 4 YEAR SPAN WITH A LEAP YEAR
        Datetime testStartDatetime = Datetime.newInstanceGmt(2018, 1, 1, 0, 0, 0);
        Datetime testEndDateTime = Datetime.newInstanceGmt(2021, 12, 31, 23, 59, 59);

        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Milliseconds, 4) == 31535999999.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Seconds, 4) == 31535999.9990);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Minutes, 4) == 525600.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Hours, 4) == 8760.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Days, 4) == 365.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Weeks, 4) == 52.1429);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Months, 4) == 12.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Quarters, 4) == 4.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDate, testEndDate, UtilityClass.Interval.Years, 4) == 1.0000);

        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Milliseconds, 4) == 126230399999.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Seconds, 4) == 126230399.9990);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Minutes, 4) == 2103840.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Hours, 4) == 35064.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Days, 4) == 1461.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Weeks, 4) == 208.7143);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Months, 4) == 48.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Quarters, 4) == 16.0000);
        System.assert(UtilityClass.getDistanceBetweenDates(testStartDatetime, testEndDateTime, UtilityClass.Interval.Years, 4) == 4.0000);
    }

    /**
    * @description checkRangeForLeapYearTest 
    */
    public static testmethod void checkRangeForLeapYearTest() {
        // CONTAINS NO FEB 29TH LEAP YEAR DAY
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2019, 2, 1), Date.newInstance(2020, 2, 28)) == false); // FALSE, ENDS RIGHT BEFORE FEB 29TH
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2020, 3, 1), Date.newInstance(2021, 2, 28)) == false); // FALSE, STARTS RIGHT AFTER FEB 29TH
        
        // DOES CONTAIN ONE OR MORE FEB 29TH LEAP YEAR DAYS
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2019, 2, 1), Date.newInstance(2020, 2, 29)) == true); // TRUE, ENDS ON FEB 29TH
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2020, 2, 29), Date.newInstance(2021, 3, 1)) == true); // TRUE, STARTS ON FEB 29TH
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2020, 1, 1), Date.newInstance(2020, 12, 31)) == true); // TRUE, CONTAINS FEB 29TH
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2019, 1, 1), Date.newInstance(2021, 12, 31)) == true); // TRUE, CONTAINS FEB 29TH IN YEAR 2020
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2020, 1, 1), Date.newInstance(2030, 12, 31)) == true); // TRUE, CONTAINS MULTIPLE FEB 29TH DAYS
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2020, 2, 28), Date.newInstance(2020, 3, 31)) == true); // TRUE, CONTAINS FEB 29TH
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2020, 2, 28), Date.newInstance(2020, 2, 29)) == true); // TRUE, CONTAINS FEB 29TH
        System.assert(UtilityClass.checkRangeForLeapYear(Date.newInstance(2020, 2, 29), Date.newInstance(2020, 2, 29)) == true); // TRUE, CONTAINS FEB 29TH
    }

    /**
    * @description replaceNullTest 
    */
    public static testmethod void replaceNullTest() {
        String nullString;
        Date nullDate;
        Integer nullInteger;
        Decimal nullDecimal;

        System.assert(UtilityClass.replaceNull(nullString, 'Replacement String') == 'Replacement String');
        System.assert(UtilityClass.replaceNull(nullDate, Date.today()) == Date.today());
        System.assert(UtilityClass.replaceNull(nullInteger, 10) == 10);
        System.assert(UtilityClass.replaceNull(nullDecimal, 10.50) == 10.50);
    }

    /**
    * @description getAllRecordTypesTest
    */
    public static testmethod void getAllRecordTypesTest() {
        Map<String, Map<String, Id>> recordTypes = UtilityClass.getAllRecordTypes();
        System.assert(recordTypes != null && !recordTypes.isEmpty());
    }

    /**
    * @description getRecordTypesForObjectsTest
    */
    public static testmethod void getRecordTypesForObjectsTest() {
        Map<String, Map<String, Id>> recordTypes = UtilityClass.getRecordTypesForObjects(new List<String>{ 'Account', 'Opportunity' });
        System.assert(recordTypes != null && !recordTypes.isEmpty());
        System.assert(recordTypes.containsKey('Account') && !recordTypes.get('Account').isEmpty());
    }

    /**
    * @description getRecordTypesForObjectTest
    */
    public static testmethod void getRecordTypesForObjectTest() {
        Map<String, Id> recordTypes = UtilityClass.getRecordTypesForObject('Account');
        System.assert(recordTypes != null && !recordTypes.isEmpty());
    }

    /**
    * @description getPicklistValuesTest
    */
    public static testmethod void getPicklistValuesTest() {
        Map<String, String> picklistValues = UtilityClass.getPicklistValues('Account', 'Type');
        System.assert(picklistValues != null && !picklistValues.isEmpty());
    }

    /**
    * @description picklistValuesByRecordTypeTest
    */
    public static testmethod void picklistValuesByRecordTypeTest(){
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new PicklistValuesByRecordTypeHTTPMock());

        // TEST CALLING METHOD USING A RECORD TYPE ID
        Map<String, String> testMap1 = UtilityClass.getPicklistValuesByRecordType('Account', Id.valueOf('01250000000Du0BAAS'), 'Type');
        System.assert(!testMap1.isEmpty());
        System.assert(testMap1.size() == 2);
        System.assert(testMap1.containsKey('ControlValue1'));
        System.assert(testMap1.containsKey('ControlValue2'));

        // TEST CALLING METHOD USING A RECORD TYPE DEVELOPER NAME
        Map<String, String> testMap2 = UtilityClass.getPicklistValuesByRecordType('Contact', 'Standard', 'LeadSource');
        System.assert(!testMap2.isEmpty());
        System.assert(testMap2.size() == 2);
        System.assert(testMap1.containsKey('ControlValue1'));
        System.assert(testMap1.containsKey('ControlValue2'));

        Test.stopTest();
    }

    /**
    * @description picklistValuesByRecordTypeTest_Exceptions
    */
    public static testmethod void picklistValuesByRecordTypeTest_Exceptions(){
        // TEST CALLING METHOD USING AN ID THAT IS INVALID
        Map<String, String> testMap3 = UtilityClass.getPicklistValuesByRecordType('Contact', '0120000000000', 'LeadSource');
        System.assert(testMap3.isEmpty());

        // TEST CALLING METHOD USING A DEVELOPER NAME THAT DOES NOT EXIST
        Map<String, String> testMap4 = UtilityClass.getPicklistValuesByRecordType('Account', 'FakeDeveloperName', 'Type');
        System.assert(testMap4.isEmpty());
    }

    /**
    * @description dependentPicklistValuesTest
    */
    public static testmethod void dependentPicklistValuesTest() {
        // NO DEPENDENT PICKLISTS EXIST IN SF OUT OF THE BOX. EXECUTE METHOD JUST TO COVER AS MUCH CODE AS POSSIBLE AND ENSURE IT RETURNS AN EMPTY MAP
        Map<Object,List<String>> testMap1 = UtilityClass.getDependentPicklistValues(Account.Type);
        Map<Object,List<String>> testMap2 = UtilityClass.getDependentPicklistValues(Contact.LeadSource);
    }

    /**
    * @description PicklistValuesByRecordTypeHTTPMock - HTTP Mock class for testing the PicklistValuesByRecordType UtilityClass method
    */
    public class PicklistValuesByRecordTypeHTTPMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            String body = '{"controllerValues":{},"defaultValue":null,"url":"/services/data/v41.0/ui-api/object-info/Account/picklist-values/012000000000000AAA/Control_Field_2__c",';
                   body += '"values":[{"attributes":null,"label":"Control Value 1","validFor":[],"value":"ControlValue1"},';
                   body += '{"attributes":null,"label":"Control Value 2","validFor":[],"value":"ControlValue2"}]}';
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }

}