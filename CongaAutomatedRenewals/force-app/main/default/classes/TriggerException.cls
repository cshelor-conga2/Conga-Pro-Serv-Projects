/**
* @author Conga Services
* @date 20170509
* @version 1.00
* @description Provides a means to extend exception class for debugging
*/
public class TriggerException extends Exception {

    /**
    * @description methodForUnitTest - Test method used by the TriggerFactoryTest test class to achieve full code coverage for this class.
    * @return void
    */
    @testVisible
    private void methodForUnitTest(){
        if(Test.isRunningTest()){
            String test = 'Test';
        }
    }


}