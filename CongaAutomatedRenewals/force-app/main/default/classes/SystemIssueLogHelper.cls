/**
* @author Conga Services
* @date 20180611
* @version 1.00
* @description SystemIssueLogHelper - Custom functionality for logging System Errors and saving them to the System_Issue_Log__c custom object
*/
public class SystemIssueLogHelper {
    public static List<SystemIssueLogWrapper> CachedIssueLogs {get;set;}

    /**
    * @description LogException - Add a single exception to the Cache
    * @param SystemIssueLogWrapper log - A single SystemIssueLogWrapper to log
    * @param Boolean doPersist - True = Commit to database, False - Add to cache only
    * @return void
    */
    public static void LogException(SystemIssueLogWrapper log, Boolean doPersist){
        if(CachedIssueLogs == null){
            CachedIssueLogs = new List<SystemIssueLogWrapper>();
        }

        CachedIssueLogs.add(log);
        if(doPersist){
            UpsertExceptions();
            CachedIssueLogs.clear();
        }
    } 

    /**
    * @description LogException - Add a list of exceptions to the Cache 
    * @param List<SystemIssueLogWrapper> logs - List of SystemIssueLogWrappers to log
    * @param Boolean doPersist - True = Commit to database, False - Add to cache only
    * @return void
    */
    public static void LogException(List<SystemIssueLogWrapper> logs, Boolean doPersist){
        if(CachedIssueLogs == null){
            CachedIssueLogs = new List<SystemIssueLogWrapper>();
        }
        
        CachedIssueLogs.addAll(logs); 
        if(doPersist){
            UpsertExceptions();
            CachedIssueLogs.clear();
        }
    }

    /**
    * @description LogException - Add a single exception to the Cache while handling various methods of supplying the affected records and the message
    * @param String className - Apex class name
    * @param String methodName - Apex class method name
    * @param Object affectedRecords - One or more record ids in any of the following formats: List<Id>, List<SObject>, Set<Id>, Map<Id, SObject>, Id
    * @param String message - Exception message in any of the following formats: String, Exception, Database.Error
    * @param Boolean doPersist - True = Commit to database, False - Add to cache only
    * @return void
    */
    public static void LogException(String className, String methodName, Object affectedRecords, Object message, Boolean doPersist) {
        if(CachedIssueLogs == null){
            CachedIssueLogs = new List<SystemIssueLogWrapper>();
        }

        SystemIssueLogWrapper newWrapper = new SystemIssueLogWrapper();
        newWrapper.ClassName = className;
        newWrapper.MethodName = methodName;

        // GET AFFECTED RECORDS
        if(affectedRecords instanceof List<Id>){
            newWrapper.RecordIds = (List<Id>)affectedRecords;
        }        
        else if(affectedRecords instanceof Set<Id>){
            newWrapper.RecordIds = SystemIssueLogHelper.CreateListofIds((Set<Id>)affectedRecords);
        }
        else if(affectedRecords instanceof List<SObject>){
            newWrapper.RecordIds = SystemIssueLogHelper.CreateListofIds((List<SObject>)affectedRecords);
        }
        else if(affectedRecords instanceof Map<Id, SObject>){
            newWrapper.RecordIds = SystemIssueLogHelper.CreateListofIds(((Map<Id, SObject>)affectedRecords).values());
        }          
        else if(affectedRecords instanceof Id){
            newWrapper.RecordIds = SystemIssueLogHelper.CreateListofIds((Id)affectedRecords);
        }
      
        // GET MESSAGE
        if(message instanceof String){
            newWrapper.Message = (String)message;
        }
        else if(message instanceof Exception){
            newWrapper.Message = ((Exception)message).getMessage() + ' ' + ((Exception)message).getStackTraceString();
        }
        else if(message instanceof Database.Error){
            newWrapper.Message = ((Database.Error)message).getMessage() + ' ' + String.valueOf(((Database.Error)message).getStatusCode());
        }
        else{
            newWrapper.Message = 'An error occurred in the specified class and method. No details are available.';
        }

        CachedIssueLogs.add(newWrapper);

        if(doPersist){
            UpsertExceptions();
            CachedIssueLogs.clear();
        }
    }

    /**
    * @description UpsertExceptions - Persist Exceptions to the database
    * @return void
    */
    public static void UpsertExceptions(){
        if(CachedIssueLogs != null){

            try{ 
                Map<String, System_Issue_Log__c> upsertItems = new Map<String, System_Issue_Log__c>();
                for(SystemIssueLogWrapper i : CachedIssueLogs){
                    System_Issue_Log__c newLog = i.getSObject();
                    upsertItems.put(newLog.Issue_UniqueID__c, newLog);
                }
                
                if(!upsertItems.isEmpty()){ 
                    Database.upsert(upsertItems.values(), System_Issue_Log__c.Issue_UniqueID__c, false);
                }
            
                // IF AN ERROR WAS LOGGED DURING UNIT TEST EXECUTION THEN REPORT ERROR IN LOG
                if(Test.isRunningTest()){
                    for(SystemIssueLogWrapper wrapper : CachedIssueLogs){
                        System.debug('SYSTEM ISSUE LOG: ' + wrapper.Message);
                    }
                }
            }
            catch(Exception ex){
                System.debug('Failed to commit logs to the database. ' + ex.getMessage());
            }

        }
    }

    /**
    * @description CreateListofIds - Creates a List of Ids from various inputs
    * @param Object pInput - Can be any of the following: List<SObject>, Set<Id>, Id
    * @return List<Id> - List of record Ids
    */
    public static List<Id> CreateListofIds(Object pInput){ 
        List<Id> listOfIds = new List<Id>();
        if(pInput instanceof List<SObject> && ((List<SObject>)pInput).size() > 0 && ((List<SObject>)pInput)[0].getSobjectType().getDescribe().fields.getMap().containsKey('Id')){
            for(SObject record : (List<SObject>)pInput){
                if(record.get('Id') != null){
                    listOfIds.add((Id)record.get('Id'));
                }
            }
        }
        else if(pInput instanceof Set<Id> && ((Set<Id>)pInput).size() > 0){
            listOfIds.addAll((Set<Id>)pInput);        
        }
        else if(pInput instanceof Id && ((Id)pInput) != null){
            listOfIds.add((Id)pInput);
        }

        return listOfIds;
    }

    /**
    * @description CheckForDatabaseErrors - CheckForDatabaseErrors - Method that loops over a list of Database.saveResults returned by a Database call.
    *                                       A SystemIssueLogWrapper will be created and placed in the cache for records that were unsuccessful.
    *                                       If no errors occurred then no log entries are created.
    * @param List<DatabaseResult> results - List of DatabaseResult wrapper class instances
    * @param String className - Apex class name
    * @param String methodName - Apex class method name
    * @param Boolean doPersist - Flag that set whether errors are committed to the Database right away or not. True = Yes Commit
    */   
    public static void CheckForDatabaseErrors(List<SystemIssueLogHelper.DatabaseResult> results, String className, String methodName, Boolean doPersist){
        // LOOP OVER ALL SAVERESULTS AND CREATE ERROR LOGS FOR ANY UNSUCCESSFUL RECORDS
        for(SystemIssueLogHelper.DatabaseResult result : results){
            if(!result.IsSuccess){
                SystemIssueLogWrapper newLog = new SystemIssueLogWrapper(className, methodName, result);
                SystemIssueLogHelper.LogException(newLog, false);
            }
        }

        // COMMIT ERROR LOGS TO DATABASE IF DESIRED
        if(doPersist){
            SystemIssueLogHelper.UpsertExceptions();
        }
    }
    /**
    * @description CheckForDatabaseErrors - Overload method for CheckForDatabaseErrors that takes a List of SaveResults
    */
    public static void CheckForDatabaseErrors(List<Database.SaveResult> saveResults, String className, String methodName, Boolean doPersist){
        List<SystemIssueLogHelper.DatabaseResult> results = new List<SystemIssueLogHelper.DatabaseResult>();
        for(Database.SaveResult result : saveResults){
            results.add(new SystemIssueLogHelper.DatabaseResult(result.getErrors(), result.getId(), result.isSuccess()));
        }
        CheckForDatabaseErrors(results, className, methodName, doPersist);
    }
    /**
    * @description CheckForDatabaseErrors - Overload method for CheckForDatabaseErrors that takes a List of UpsertResults
    */    
    public static void CheckForDatabaseErrors(List<Database.UpsertResult> upsertResults, String className, String methodName, Boolean doPersist){
        List<SystemIssueLogHelper.DatabaseResult> results = new List<SystemIssueLogHelper.DatabaseResult>();
        for(Database.UpsertResult result : upsertResults){
            results.add(new SystemIssueLogHelper.DatabaseResult(result.getErrors(), result.getId(), result.isSuccess()));
        }
        CheckForDatabaseErrors(results, className, methodName, doPersist);
    }
    /**
    * @description CheckForDatabaseErrors - Overload method for CheckForDatabaseErrors that takes a List of DeleteResults
    */    
    public static void CheckForDatabaseErrors(List<Database.DeleteResult> deleteResults, String className, String methodName, Boolean doPersist){
        List<SystemIssueLogHelper.DatabaseResult> results = new List<SystemIssueLogHelper.DatabaseResult>();
        for(Database.DeleteResult result : deleteResults){
            results.add(new SystemIssueLogHelper.DatabaseResult(result.getErrors(), result.getId(), result.isSuccess()));
        }
        CheckForDatabaseErrors(results, className, methodName, doPersist);
    }
    /**
    * @description CheckForDatabaseErrors - Overload method for CheckForDatabaseErrors that takes a List of UndeleteResults
    */    
    public static void CheckForDatabaseErrors(List<Database.UndeleteResult> undeleteResults, String className, String methodName, Boolean doPersist){
        List<SystemIssueLogHelper.DatabaseResult> results = new List<SystemIssueLogHelper.DatabaseResult>();
        for(Database.UndeleteResult result : undeleteResults){
            results.add(new SystemIssueLogHelper.DatabaseResult(result.getErrors(), result.getId(), result.isSuccess()));
        }
        CheckForDatabaseErrors(results, className, methodName, doPersist);
    }

    /**
    * @description DatabaseResult - DatabaseResult WRAPPER CLASS
    */
    public class DatabaseResult{
        public List<Database.Error> Errors {get;set;}
        public Id RecordId {get;set;}
        public Boolean IsSuccess {get;set;}

        public DatabaseResult(List<Database.Error> pErrors, Id pRecordId, Boolean pIsSuccess){
            this.Errors = pErrors;
            this.RecordId = pRecordId;
            this.IsSuccess = pIsSuccess;
        }
    }


}