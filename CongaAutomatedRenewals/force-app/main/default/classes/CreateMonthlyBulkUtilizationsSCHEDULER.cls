/**
* @author Jereriah Manning, Bethany Spencer, Created for Conga Partner Team
* @date 20151202
* @version 1.00
* @description CreateMonthlyBulkUtilizationsSCHEDULER - 
*/
global class CreateMonthlyBulkUtilizationsSCHEDULER implements Schedulable {

    //Runs on the 10th day of the month at 11am
    public static String CRON_EXP = '0 0 11 10 * ? *';
    
    /**
    * @description scheduleIt - 
    * @return String
    */
    global static String scheduleIt(){
        CreateMonthlyBulkUtilizationsSCHEDULER cmbuS = new CreateMonthlyBulkUtilizationsSCHEDULER();
        return Test.isRunningTest() ? '' : System.schedule('Monthly Bulk License Utilization Creation', CRON_EXP, cmbuS);
    }
    
    /**
    * @description execute - Schedulable execute method
    * @param SchedulableContext sc
    * @return void
    */
    global void execute(SchedulableContext sc){
        CreateMonthlyBulkUtilizationRecords2 cmbur = new CreateMonthlyBulkUtilizationRecords2();
    }


}

/*******************************************************************************
CRON SYNTAX

There are seven fields for Salesforce’s cron syntax, unlike *nix’s 5 fields.
* Seconds [0-59]
* Minutes [0-59]
* Hours [0-23]
* Day of month [1-31]
* Month [1-12 or JAN-DEC]
* Day of week [1-7 or SUN-SAT]
* Year [1970-2099]

There are also some special characters you can use:
, used to delimit values [hours, day of month, month, day of week, year]
- used to specify a range [hours, day of month, month, day of week, year]
* used to specify all values [hours, day of month, month, day of week, year]
? used to specify no specific value [day of month, day of week]
/ used to specify increments [hours, day of month, month, day of week, year]
L used to specify the end of a range [day of month, day of week]
W used to specify the nearest weekday [day of month]
# used to specify the nth day of the month [day of week]
/*******************************************************************************/