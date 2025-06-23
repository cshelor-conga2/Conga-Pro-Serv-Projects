/**
* @author ECS, ERedding
* @date 20190823
* @version 1.00
* @description ApexAuditHelper - Custom functionality for auditing apex code performance and saving results to a custom object
*/
public without sharing class ApexAuditHelper {

	// TRIGGER DISPATCHERS WILL SET THE STARTING DISPATCHER VALUE TO ENSURE THE SAVE AUDITS METHOD IS
	// ONLY CALLED ONCE AND AFTER ALL CODE EXECUTION IS COMPLETE
	public static String StartingDispatcher {
		get;
		set {
			if(String.isBlank(StartingDispatcher) || value == null){
				StartingDispatcher = value;
			}
		}
	}
														
	public static Map<String, AuditWrapper> AuditWrappers {
		get {
        if(AuditWrappers == null){
            AuditWrappers = new Map<String, AuditWrapper>();
        }
        return AuditWrappers;
    } set; }


	/**
	* @description saveAudits - 
	*/
	public static void saveAudits(String pStartingDispatcher){
		try{
			if(!AuditWrappers.isEmpty() && String.isNotBlank(pStartingDispatcher) && StartingDispatcher == pStartingDispatcher){
				// GET EXISTING AUDIT HEADER AND DETAIL DATA
				Map<String, List<Apex_Audit_Snapshot__c>> existingDetailsByUniqueID = new Map<String, List<Apex_Audit_Snapshot__c>>();
				Map<String, Decimal> auditHeaderMaxDetails = new Map<String, Decimal>();
				Map<String, Id> headerIds = new Map<String, Id>();
				for(Apex_Audit__c header : [SELECT Id, Max_Number_of_Details__c, UniqueID__c, 
														(SELECT Date_of_Execution__c, LastModifiedDate FROM ApexAuditSnapshots__r ORDER BY LastModifiedDate)
														FROM Apex_Audit__c WHERE UniqueID__c IN :AuditWrappers.keySet()]){
				
					if(!existingDetailsByUniqueID.containsKey(header.UniqueID__c)){
						existingDetailsByUniqueID.put(header.UniqueID__c, new List<Apex_Audit_Snapshot__c>());
						if(!header.ApexAuditSnapshots__r.isEmpty()){
							existingDetailsByUniqueID.get(header.UniqueID__c).addAll(header.ApexAuditSnapshots__r);
						}
					}

					if(!auditHeaderMaxDetails.containsKey(header.UniqueID__c)){
						auditHeaderMaxDetails.put(header.UniqueID__c, header.Max_Number_of_Details__c);
					}

					if(!headerIds.containsKey(header.UniqueID__c)){
						headerIds.put(header.UniqueID__c, header.Id);
					}
				}

				// CHECK AUDIT HEADERS THAT NEED TO BE CREATED
				Map<String, Apex_Audit__c> newHeaders = new Map<String, Apex_Audit__c>();
				for(AuditWrapper wrapper : AuditWrappers.values()){
					if(!headerIds.containsKey(wrapper.UniqueID) && !newHeaders.containsKey(wrapper.UniqueID)){
						newHeaders.put(wrapper.UniqueID, new Apex_Audit__c(Class_Name__c = wrapper.ClassName, Method_Name__c = wrapper.MethodName, UniqueID__c = wrapper.UniqueID));
					}
				}

				// PROCESS NEW AUDIT HEADERS
				if(!newHeaders.isEmpty()){
					Database.upsert(newHeaders.values(), Apex_Audit__c.UniqueID__c, false);
					for(Apex_Audit__c newHeader : newHeaders.values()){
						if(newHeader.Id != null){
							existingDetailsByUniqueID.put(newHeader.UniqueID__c, new List<Apex_Audit_Snapshot__c>());
							auditHeaderMaxDetails.put(newHeader.UniqueID__c, 20);

							headerIds.put(newHeader.UniqueID__c, newHeader.Id);
						}
						else{
							System.debug('Could not create new Audit Header with unique ID: ' + newHeader.UniqueID__c);
							SystemIssueLogHelper.LogException('ApexAuditHelper', 'saveAudits', null, 'Could not create new Audit Header with unique ID: ' + newHeader.UniqueID__c, false);
						}
					}
				}

				// CHECK FOR AND PROCESS NEW AND UPDATED AUDIT DETAILS
				Map<String, Apex_Audit_Snapshot__c> detailsToCreate = new Map<String, Apex_Audit_Snapshot__c>();
				Map<String, Apex_Audit_Snapshot__c> detailsToUpdate = new Map<String, Apex_Audit_Snapshot__c>();
				for(AuditWrapper wrapper : AuditWrappers.values()){
					if(existingDetailsByUniqueID.containsKey(wrapper.UniqueID) && !existingDetailsByUniqueID.get(wrapper.UniqueID).isEmpty() && !detailsToUpdate.containsKey(wrapper.UniqueID)){

						Apex_Audit_Snapshot__c oldestDetail = existingDetailsByUniqueID.get(wrapper.UniqueID)[0];
						Apex_Audit_Snapshot__c newestDetail = existingDetailsByUniqueID.get(wrapper.UniqueID)[existingDetailsByUniqueID.get(wrapper.UniqueID).size()-1];
						Decimal timeSinceLastDetail = UtilityClass.getDistanceBetweenDates(newestDetail.LastModifiedDate, DateTime.now(), UtilityClass.Interval.Seconds, 0);

						if(timeSinceLastDetail >= 180 || Test.isRunningTest()){
							// ONLY CREATE OR UPDATE DETAILS IF ITS BEEN AT LEAST 180 SECONDS (3 MINUTES) SINCE THE LAST ONE

							if(existingDetailsByUniqueID.get(wrapper.UniqueID).size() >= auditHeaderMaxDetails.get(wrapper.UniqueID)){

								// MAX NUMBER OF DETAILS REACHED, RECYCLE
								oldestDetail.Was_Asynchronous__c = wrapper.IsAsync;
								oldestDetail.Date_of_Execution__c = wrapper.DateOfExecution;
								oldestDetail.CPU_Time_Use__c = wrapper.CPUUsage;
								oldestDetail.SOQL_Query_Use__c = wrapper.SOQLUsage;
								oldestDetail.DML_Use__c = wrapper.DMLUsage;
								oldestDetail.Redundancy__c = wrapper.Redundancy;
								oldestDetail.Number_of_Redundant_Executions__c = wrapper.NumOfExecutions;
								detailsToUpdate.put(wrapper.UniqueID, oldestDetail);
							}
							else if(existingDetailsByUniqueID.get(wrapper.UniqueID).size() < auditHeaderMaxDetails.get(wrapper.UniqueID)){

								// NUMBER OF EXISTING DETAILS NOT AT MAX NUMBER YET, CREATE NEW
								Apex_Audit_Snapshot__c newDetail = new Apex_Audit_Snapshot__c();
								newDetail.Parent_Audit_HeaderId__c = headerIds.get(wrapper.UniqueID);
								newDetail.Was_Asynchronous__c = wrapper.IsAsync;
								newDetail.Date_of_Execution__c = wrapper.DateOfExecution;
								newDetail.CPU_Time_Use__c = wrapper.CPUUsage;
								newDetail.SOQL_Query_Use__c = wrapper.SOQLUsage;
								newDetail.DML_Use__c = wrapper.DMLUsage;
								newDetail.Redundancy__c = wrapper.Redundancy;
								newDetail.Number_of_Redundant_Executions__c = wrapper.NumOfExecutions;
								detailsToCreate.put(wrapper.UniqueID, newDetail);
							}
						}
					}
					else if(!existingDetailsByUniqueID.containsKey(wrapper.UniqueID) || existingDetailsByUniqueID.get(wrapper.UniqueID).isEmpty()){

						// NO DETAILS YET, CREATE NEW
						Apex_Audit_Snapshot__c newDetail = new Apex_Audit_Snapshot__c();
						newDetail.Parent_Audit_HeaderId__c = headerIds.get(wrapper.UniqueID);
						newDetail.Was_Asynchronous__c = wrapper.IsAsync;
						newDetail.Date_of_Execution__c = wrapper.DateOfExecution;
						newDetail.CPU_Time_Use__c = wrapper.CPUUsage;
						newDetail.SOQL_Query_Use__c = wrapper.SOQLUsage;
						newDetail.DML_Use__c = wrapper.DMLUsage;
						newDetail.Redundancy__c = wrapper.Redundancy;
						newDetail.Number_of_Redundant_Executions__c = wrapper.NumOfExecutions;
						detailsToCreate.put(wrapper.UniqueID, newDetail);
					}
				}

				// CREATE NEW AUDIT DETAILS
				if(!detailsToCreate.isEmpty()){
					Database.saveResult[] createResults = Database.insert(detailsToCreate.values(), false);
					SystemIssueLogHelper.CheckForDatabaseErrors(createResults, 'ApexAuditHelper', 'saveAudits', false);  
				}

				// UPDATE EXISTING AUDIT DETAILS
				if(!detailsToUpdate.isEmpty()){
					Database.saveResult[] updateResults = Database.update(detailsToUpdate.values(), false);
					SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'ApexAuditHelper', 'saveAudits', false);  
				}

				// LOG ANY ERRORS
				SystemIssueLogHelper.UpsertExceptions();

				// CLEAR WRAPPER LIST AND SET STARTING DISPATCHER TO NULL
				AuditWrappers.clear();
				StartingDispatcher = null;
			}
		}
		catch(Exception ex){
			System.debug('Error while trying to save audits: ' + ex.getMessage());
			SystemIssueLogHelper.LogException('ApexAuditHelper', 'saveAudits', null, ex, true);
		}
	}

	/**
	* @description startAudit - 
	*/
	public static void startAudit(String className, String methodName){
		try{
			if(String.isNotBlank(className) && String.isNotBlank(methodName)){
				String uniqueID = ApexAuditHelper.createUniqueID(className, methodName);
				AuditWrapper wrapper;

				if(!AuditWrappers.containsKey(uniqueID)){
					wrapper = new AuditWrapper(className, methodName);
				}
				else{
					wrapper = AuditWrappers.get(uniqueID);
					wrapper.Redundancy = true;
					wrapper.NumOfExecutions++;
				}

				wrapper.CPUUsage = Limits.getCpuTime();
				wrapper.SOQLUsage = Limits.getQueries();
				wrapper.DMLUsage = Limits.getDMLStatements();
				AuditWrappers.put(uniqueID, wrapper);
			}
		}
		catch(Exception ex){
			System.debug('Error while trying to start audit: ' + ex.getMessage());
			SystemIssueLogHelper.LogException('ApexAuditHelper', 'startAudit', null, ex, true);
		}
	}

	/**
	* @description stopAudit - 
	*/
	public static void stopAudit(String className, String methodName){
		try{
			if(String.isNotBlank(className) && String.isNotBlank(methodName)){
				String uniqueID = ApexAuditHelper.createUniqueID(className, methodName);
				if(AuditWrappers.containsKey(uniqueID)){
					AuditWrapper wrapper = AuditWrappers.get(uniqueID);
					wrapper.CPUUsage = (Limits.getCpuTime() - wrapper.CPUUsage);
					wrapper.SOQLUsage = (Limits.getQueries() - wrapper.SOQLUsage);
					wrapper.DMLUsage = (Limits.getDMLStatements() - wrapper.DMLUsage);
				}
			}
		}
		catch(Exception ex){
			System.debug('Error while trying to stop audit: ' + ex.getMessage());
			SystemIssueLogHelper.LogException('ApexAuditHelper', 'stopAudit', null, ex, true);
		}
	}

	/**
	* @description createUniqueID - 
	*/
	public static String createUniqueID(String className, String methodName){
		try{
			if(String.isNotBlank(className) && String.isNotBlank(methodName)){
				return (className + '.' + methodName).left(100);
			}
		}
		catch(Exception ex){
			System.debug('Error creating Unique ID: ' + ex.getMessage());
			SystemIssueLogHelper.LogException('ApexAuditHelper', 'createUniqueID', null, ex, true);
		}
		return 'MissingClassOrMethod';
	}

    /**
    * @description AuditWrapper - AuditWrapper WRAPPER CLASS
    */
    public class AuditWrapper{
    	public String UniqueID {get;set;}
    	public String ClassName {get;set;}
    	public String MethodName {get;set;}
    	public Boolean IsAsync {get;set;}
    	public DateTime DateOfExecution {get;set;}
    	public Integer CPUUsage {get;set;}
    	public Integer SOQLUsage {get;set;}
    	public Integer DMLUsage {get;set;}
    	public Boolean Redundancy {get;set;}
    	public Integer NumOfExecutions {get;set;}

        public AuditWrapper(String pClassName, String pMethodName){
            UniqueID = ApexAuditHelper.createUniqueID(pClassName, pMethodName);
            ClassName = pClassName;
            MethodName = pMethodName;
            IsAsync = System.isBatch() || System.isQueueable() || System.isFuture() || System.isScheduled() ? true : false;
            DateOfExecution = DateTime.now();
            CPUUsage = 0;
            SOQLUsage = 0;
            DMLUsage = 0;
            Redundancy = false;
            NumOfExecutions = 0;
        }
    }


}