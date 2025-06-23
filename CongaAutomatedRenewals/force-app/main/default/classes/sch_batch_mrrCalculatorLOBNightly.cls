/**
* @author Conga Services
* @date 20160722
* @version 1.0
* @description sch_batch_mrrCalculatorLOBNightly - 
*/
global class sch_batch_mrrCalculatorLOBNightly implements Schedulable {
    public static String Frequency = '0 0 22 * * ?';

    /**
    * @description execute - 
    * @param SchedulableContext ctx
    */
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new batch_mrrCalculatorLOBNightly(), 2);
    }

    /**
    * @description scheduleIt - 
    * @return String
    */
    global static String scheduleIt(){
        sch_batch_mrrCalculatorLOBNightly runUpdates = new sch_batch_mrrCalculatorLOBNightly();

        if(Test.isRunningTest()){
            return System.schedule('Updating Account LOB MRR TEST', Frequency, runUpdates);
        }
        else{
            return System.schedule('Updating Account LOB MRR', Frequency, runUpdates);  
        }
    }


}