/**
* @author Jereriah Manning
* @date 20140724
* @version 1.00
* @description PPCountUpdateScheduler - Created for Conga Partner Team
*    Version 2.0 
*        Updated 5/4/2017 (JM)
*    Version 3.0
*        Updated 9/1/2017 (JM)
*/
global class PPCountUpdateScheduler implements Schedulable {

    // 12:30am, every Saturday
    public static String CRON_EXP2 = '0 30 0 ? * 7 *';

    /**
    * @description scheduleIt - 
    * @return String
    */
    global static String scheduleIt() {
        PPCountUpdateScheduler ppcus = new PPCountUpdateScheduler();
        return Test.isRunningTest() ? null : System.schedule('Weekly PP Count Updater', CRON_EXP2, ppcus);
    }
    
    /**
    * @description execute - Schedulable execute method
    * @return void
    */
    global void execute(SchedulableContext sc){
        PPDealCountUpdaterToBatch.doCount();
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