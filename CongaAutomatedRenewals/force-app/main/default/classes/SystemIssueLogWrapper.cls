/**
* @author Conga Services
* @date 20180611
* @version 1.00
* @description This Class is a representaiton of a System_Issue_Log__c object
*/
public class SystemIssueLogWrapper{
    public Id IssueId {get;set;}
    public String ClassName {get;set;}
    public String MethodName {get;set;}
    public String Message {get;set;} 
    public List<Id> RecordIds {get;set;}

    /**
    * @description SystemIssueLogWrapper - Constructor with no parmameters. For creating an empty instance of SystemIssueLogWrapper
    */
    public SystemIssueLogWrapper(){
        RecordIds = new List<Id>();
    }

    /**
    * @description SystemIssueLogWrapper - Constructor with parameters. Message derived from a supplied String value
    * @param String className - Apex class name
    * @param String methodName - Apex class method name
    * @param List<Id> affectedRecords - List of the affected record ids
    * @param String message - Error message string
    */
    public SystemIssueLogWrapper(String className, String methodName, List<Id> affectedRecords, String message){
        this();
        this.ClassName = className;
        this.MethodName = methodName;
        this.RecordIds.addAll(affectedRecords);
        this.Message = message;
    }

    /**
    * @description SystemIssueLogWrapper - Constructor with parameters. Message derived from an instance of the Exception class
    * @param String className - Apex class name
    * @param String methodName - Apex class method name
    * @param List<Id> affectedRecords - List of the affected record ids
    * @param Exception ex - Instance of an Apex Exception
    */
    public SystemIssueLogWrapper(String className, String methodName, List<Id> affectedRecords, Exception ex){
        this(className, methodName, affectedRecords, ex.getMessage() + ' ' + ex.getStackTraceString());
    }

    /**
    * @description SystemIssueLogWrapper - Constructor with parameters. Message derived from an instance of Database.Error
    * @param String className - Apex class name
    * @param String methodName - Apex class method name
    * @param List<Id> affectedRecords - List of the affected record ids
    * @param Database.Error err - Instance of a Database.Error
    */
    public SystemIssueLogWrapper(String className, String methodName, List<Id> affectedRecords, Database.Error err){
        this(className, methodName, affectedRecords, err.getMessage() + ' ' + String.valueOf(err.getStatusCode()));
    }

    /**
    * @description SystemIssueLogWrapper - Constructor with parameters. Data derived from an instance of a SystemIssueLogHelper.DatabaseResult wrapper class
    * @param String className - Apex class name
    * @param String methodName - Apex class method name
    * @param SystemIssueLogHelper.DatabaseResult result - Instance of a SystemIssueLogHelper.DatabaseResult wrapper class
    */
    public SystemIssueLogWrapper(String className, String methodName, SystemIssueLogHelper.DatabaseResult result){
        this();
        this.ClassName = className;
        this.MethodName = methodName;
        this.RecordIds.add(result.RecordId);
        String errorMessages = '';
        for(Database.Error err : result.Errors){
            if(errorMessages == ''){
                errorMessages = err.getStatusCode() + ': ' + err.getMessage();
            }
            else{
                errorMessages += '\r\n' + err.getStatusCode() + ': ' + err.getMessage();
            }
        }
        this.Message = errorMessages;
    }

    /**
    * @description SystemIssueLogWrapper - Constructor with parameters. All data derived from the supplied System_Issue_Log__c record.
    * @param System_Issue_Log__c log - A System_Issue_Log__c record
    */ 
    public SystemIssueLogWrapper(System_Issue_Log__c log){
        this();
        this.IssueId = log.Id; 
        this.ClassName = log.Class_Name__c;
        this.MethodName = log.Method_Name__c;
        this.Message = log.Message__c;
        if(String.isNotBlank(log.Record_Ids__c)){
            List<String> ids =  log.Record_Ids__c.split(',');
            for(String s : ids){
                RecordIds.add(Id.valueOf(s));
            }
        } 
    }

    /**
    * @description getUniqueId - Creates a unique ID from the ClassName, MethodName, and Message class variable values
    * @return String
    */
    public String getUniqueId(){
        String uId = (String.isBlank(ClassName) ? '' : ClassName) + '|' + (String.isBlank(MethodName) ? '' : MethodName) + '|' + (String.isBlank(Message) ? '' : Message.left(100));
        if(uId.length() > 255){
            return uId.Left(255);
        }
        return uId;
    }

    /**
    * @description getSObject - Creates a new System_Issue_Log__c record from various class variable values
    * @return System_Issue_Log__c
    */
    public System_Issue_Log__c getSObject(){
        System_Issue_Log__c newLog = new System_Issue_Log__c();
        if(IssueId != null){
            newLog = new System_Issue_Log__c(Id = IssueId);
        }
        newLog.Class_Name__c = this.ClassName;
        newLog.Method_Name__c = this.MethodName;
        newLog.Record_Ids__c = String.join(this.RecordIds,',');
        newLog.Message__c = this.Message;
        newLog.Issue_UniqueID__c = getUniqueId();
        return newLog;
    }


}