/**
* @author Conga Services
* @date 20180926
* @version 2.00
* @description TriggerFactoryTest  - Test class for the various classes related to the Conga Services Trigger Factory
*/
@isTest
public with sharing class TriggerFactoryTest {

    /**
    * @description class TestTriggerHandlerBase - 
    */
    public class TestTriggerHandlerBase extends TriggerHandlerBase {
    }

    /**
    * @description class TestTriggerDispatcherBase - 
    */
    public class TestTriggerDispatcherBase extends TriggerDispatcherBase {
    }   

    /**
    * @description class TestTriggerDispatcherBaseExecute - 
    */
    public class TestTriggerDispatcherBaseExecute extends TriggerDispatcherBase {
        TestTriggerHandlerBase testTriggerHandlerBase = new TestTriggerHandlerBase();
        public virtual override void beforeInsert(TriggerParameters tp) {
            execute(testTriggerHandlerBase, tp, TriggerParameters.TriggerEvent.beforeInsert);
            execute(null, tp, TriggerParameters.TriggerEvent.beforeInsert);
        }

        public virtual override void beforeUpdate(TriggerParameters tp) {
            execute(testTriggerHandlerBase, tp, TriggerParameters.TriggerEvent.beforeUpdate);
            execute(null, tp, TriggerParameters.TriggerEvent.beforeUpdate);
        }

        public virtual override void beforeDelete(TriggerParameters tp) {
            execute(testTriggerHandlerBase, tp, TriggerParameters.TriggerEvent.beforeDelete);
            execute(null, tp, TriggerParameters.TriggerEvent.beforeDelete);
        }

        public virtual override void afterInsert(TriggerParameters tp) {
            execute(testTriggerHandlerBase, tp, TriggerParameters.TriggerEvent.afterInsert);
            execute(null, tp, TriggerParameters.TriggerEvent.afterInsert);
        }

        public virtual override void afterUpdate(TriggerParameters tp) {
            execute(testTriggerHandlerBase, tp, TriggerParameters.TriggerEvent.afterUpdate);
            execute(null, tp, TriggerParameters.TriggerEvent.afterUpdate);
        }

        public virtual override void afterDelete(TriggerParameters tp) {
            execute(testTriggerHandlerBase, tp, TriggerParameters.TriggerEvent.afterDelete);
            execute(null, tp, TriggerParameters.TriggerEvent.afterDelete);
        }

        public virtual override void afterUndelete(TriggerParameters tp) {
            execute(testTriggerHandlerBase, tp, TriggerParameters.TriggerEvent.afterUndelete);
            execute(null, tp, TriggerParameters.TriggerEvent.afterUndelete);
        }
    }   

    /**
    * @description setup - Test data setup method
    */
    @testSetup
    public static void setup(){
        // CREATE TEST ACCOUNTS
        Account testAccount1 = new Account(Name = 'Test Account 1');
        Account testAccount2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{ testAccount1, testAccount2 };

        // UPDATE TEST ACCOUNTS
        testAccount1.Name = 'Test Account 123';
        testAccount2.Name = 'Test Account 321';
        update new List<Account>{ testAccount1, testAccount2 };
    }

    /**
    * @description triggerParametersTest - Test TriggerParameters code
    */
    public static testMethod void triggerParametersTest() {
        // GET TEST ACCOUNTS
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        Map<Id, Account> testAccountsMap = new Map<Id, Account>(testAccounts);

        Test.startTest();
        // BEFORE INSERT
        TriggerParameters testBeforeInsert = new TriggerParameters(testAccounts, testAccounts, testAccountsMap, testAccountsMap, true, false, true, false, false, false, false);
        // BEFORE UPDATE
        TriggerParameters testBeforeUpdate = new TriggerParameters(testAccounts, testAccounts, testAccountsMap, testAccountsMap, true, false, false, true, false, false, false);
        // BEFORE DELETE
        TriggerParameters testBeforeDelete = new TriggerParameters(testAccounts, testAccounts, testAccountsMap, testAccountsMap, true, false, false, false, true, false, false);
        // AFTER INSERT
        TriggerParameters testAfterInsert = new TriggerParameters(testAccounts, testAccounts, testAccountsMap, testAccountsMap, false, true, true, false, false, false, false);
        // AFTER UPDATE
        TriggerParameters testAfterUpdate = new TriggerParameters(testAccounts, testAccounts, testAccountsMap, testAccountsMap, false, true, false, true, false, false, false);
        // AFTER DELETE
        TriggerParameters testAfterDelete = new TriggerParameters(testAccounts, testAccounts, testAccountsMap, testAccountsMap, false, true, false, false, true, false, false);
        // AFTER UNDELETE
        TriggerParameters testAfterUndelete = new TriggerParameters(testAccounts, testAccounts, testAccountsMap, testAccountsMap, false, true, false, false, false, true, false);
        // BEFORE INSERT, EXECUTING
        TriggerParameters testIsExecuting = new TriggerParameters(testAccounts, testAccounts, testAccountsMap, testAccountsMap, true, false, true, false, false, false, true);

        Test.stopTest();
    }

    /**
    * @description triggerHelperTest - Test TriggerHelper code
    */
    public static testMethod void triggerHelperTest() {
        Test.startTest();

        System.assert(TriggerHelper.DoExecute('Class1', 'Method1') == false);

        TriggerHelper.TemporaryOverride('Class1', 'Method1', true);
        System.assert(TriggerHelper.DoExecute('Class1', 'Method1') == true);

        triggerHelper.OverrideAllSettings(true, false);
        System.assert(TriggerHelper.DoExecute('Class1', 'Method1') == false);

        Test.stopTest();
    }

    /**
    * @description triggerFactoryTest - Test TriggerFactory code. Not all can be covered outside of a trigger call and without Dispatchers and Handlers 
    *                                   set up so cover as much as possible. The rest of the code will be covered by triggers and trigger method calls
    */
    public static testMethod void triggerFactoryTest() {
        Test.startTest();

        try{
            TriggerFactory.createTriggerDispatcher(Schema.getGlobalDescribe().get('ApexClass')); //TRY CREATING A TRIGGER DISPATCHER ON A METADATA TYPE THAT WILL NEVER HAVE A DISPATCHER
        }
        catch(Exception ex){
            System.assert(ex.getMessage().startsWith('No Trigger dispatcher registered'));
        }

        // TRY GETTING ITriggerDispatcher FOR OBJECTS THAT MAY OR MAY NOT HAVE ONE
        ITriggerDispatcher testDispatcherAccount = TriggerFactory.getTriggerDispatcher(Schema.getGlobalDescribe().get('Account'));
        ITriggerDispatcher testDispatcherContact = TriggerFactory.getTriggerDispatcher(Schema.getGlobalDescribe().get('Contact'));
        ITriggerDispatcher testDispatcherLead = TriggerFactory.getTriggerDispatcher(Schema.getGlobalDescribe().get('Lead'));

        Test.stopTest();
    }

    /**
    * @description triggerExceptionTest - Test TriggerException code
    */
    public static testMethod void triggerExceptionTest() {
        Test.startTest();

        TriggerException triggerEx = new TriggerException('Test Exception');
        triggerEx.methodForUnitTest();

        try{
            throw triggerEx;
        }
        catch(Exception ex){
            System.assert(ex instanceof triggerException);
        }

        Test.stopTest();
    }

    /**
    * @description triggerHandlerBaseTest - Test TriggerHandlerBase code
    */
    public static testMethod void triggerHandlerBaseTest() {
        TestTriggerHandlerBase testHandlerBase = new TestTriggerHandlerBase();
        testHandlerBase.beforeInsertMainEntry(null);
        testHandlerBase.beforeInsertRecursiveEntry(null);

        testHandlerBase.beforeUpdateMainEntry(null);
        testHandlerBase.beforeUpdateRecursiveEntry(null);

        testHandlerBase.beforeDeleteMainEntry(null);
        testHandlerBase.beforeDeleteRecursiveEntry(null);

        testHandlerBase.afterInsertMainEntry(null);
        testHandlerBase.afterInsertRecursiveEntry(null);

        testHandlerBase.afterUpdateMainEntry(null);
        testHandlerBase.afterUpdateRecursiveEntry(null);

        testHandlerBase.afterDeleteMainEntry(null);
        testHandlerBase.afterDeleteRecursiveEntry(null);

        testHandlerBase.afterUndeleteMainEntry(null);
        testHandlerBase.afterUndeleteRecursiveEntry(null);
    }

    /**
    * @description triggerDispatcherBaseTest - Test TriggerDispatcherBase code
    */
    public static testMethod void triggerDispatcherBaseTest() {
        TestTriggerDispatcherBase testDispatcherBase = new TestTriggerDispatcherBase();
        testDispatcherBase.bulkBefore(null);
        testDispatcherBase.beforeInsert(null);
        testDispatcherBase.beforeUpdate(null);
        testDispatcherBase.beforeDelete(null);
        testDispatcherBase.afterInsert(null);
        testDispatcherBase.afterUpdate(null);
        testDispatcherBase.afterDelete(null);
        testDispatcherBase.afterUndelete(null);
        testDispatcherBase.bulkAfter(null);
        testDispatcherBase.andFinally();
    }

    /**
    * @description triggerDispatcherBaseExecuteTest - Test TriggerDispatcherBase execute method
    */
    public static testMethod void triggerDispatcherBaseExecuteTest() {
        TestTriggerDispatcherBaseExecute testDispatcherBaseExecute = new TestTriggerDispatcherBaseExecute();
        testDispatcherBaseExecute.beforeInsert(null);
        testDispatcherBaseExecute.beforeUpdate(null);
        testDispatcherBaseExecute.beforeDelete(null);
        testDispatcherBaseExecute.afterInsert(null);
        testDispatcherBaseExecute.afterUpdate(null);
        testDispatcherBaseExecute.afterDelete(null);
        testDispatcherBaseExecute.afterUndelete(null);
    }


}