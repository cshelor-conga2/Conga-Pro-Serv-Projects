/**
* @author Systemyc, GModica
* @date 20190123
* @version 1.00
* @description PromiseTest - Test class for the Promise class
*/
@isTest
private class PromiseTest {

    /**
    * @description testTask - 
    */
    private testmethod static void testTask() {
        Lead l = new Lead(LastName = 'Test');

        Test.startTest();

        new Promise(new FirstTask())
                .execute(l);

        Test.stopTest();
    }

    /**
    * @description testTaskNoParam - 
    */
    private testmethod static void testTaskNoParam() {
        Lead l = new Lead(LastName = 'Test');

        Test.startTest();

        new Promise(new FirstTask())
                .execute();

        Test.stopTest();
    }   

    /**
    * @description testError - 
    */
    private testmethod static void testError() {
        Lead l = new Lead(LastName = 'Test');

        Test.startTest();

        new Promise(new ErrorTask())
                .error(new ErrorHandler())
                .execute(l);

        Test.stopTest();
    }

    /**
    * @description testDone - 
    */
    private testmethod static void testDone() {
        Lead l = new Lead(LastName = 'Test');

        Test.startTest();

        new Promise(new FirstTask())
                .done(new DoneTask())
                .execute(l);

        Test.stopTest();
    }

    /**
    * @description class FirstTask - 
    */
    private class FirstTask implements Promise.Deferred {
        public Object resolve(Object input) {
            return input;
        }
    }

    /**
    * @description class DoneTask - 
    */
    private class DoneTask implements Promise.Done {
        public void done(Object input) {

        }
    }

    /**
    * @description class ErrorHandler - 
    */
    private class ErrorHandler implements Promise.Error {
        public Object error(Exception e, Object input) {
            return input;
        }
    }

    /**
    * @description class ErrorTask - 
    */
    private class ErrorTask implements Promise.Deferred {
        public Object resolve(Object input) {
            throw new TestException('Test');
        }
    }

    /**
    * @description TestException - 
    */
    private class TestException extends Exception {

    }


}