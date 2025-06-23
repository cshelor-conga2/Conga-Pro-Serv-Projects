/**
* @author Systemyc, GModica, 20190214
* @author ECS, ERedding
* @date 20190701
* @version 1.00
* @description BatchableSch_OppCountOfPrimary - 
*/
public with sharing class BatchableSch_OppCountOfPrimary implements Database.Batchable<sObject>, Schedulable {
    private String query = 'SELECT Id FROM Opportunity WHERE IsClosed = false AND Type IN (\'Renewal\',\'Existing Business\')';

    /**
    * @description BatchableSch_OppCountOfPrimary - Constructor
    */      
    public BatchableSch_OppCountOfPrimary() {
    }

    /**
    * @description BatchableSch_OppCountOfPrimary - Constructor
    * @param String query
    */          
    public BatchableSch_OppCountOfPrimary(String query) {
        this.query = query;
    }

    /**
    * @description start - 
    */          
    public Database.QueryLocator start(Database.BatchableContext bc) {
        AsyncApexJob[] jobs = [
            SELECT Id, JobType, ApexClass.Name, Status, CompletedDate, MethodName, ExtendedStatus 
            FROM AsyncApexJob 
            WHERE Id != :BC.getJobId() 
                AND JobType IN ('BatchApex', 'BatchApexWorker') 
                AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') 
                AND ApexClass.Name = 'BatchableSch_OppCountOfPrimary'];

        if(!jobs.isEmpty()) {
            System.debug('There is currently a process running.');
            return Database.getQueryLocator('SELECT Id FROM Opportunity WHERE Id = null');
        }
        return Database.getQueryLocator(query);
    }

    /**
    * @description execute - Schedulable execute method
    */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this);
    }

    /**
    * @description execute - Batchable execute method
    */      
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<Opportunity> opportunities = (List<Opportunity>)scope;     
        Set<Id> opportunityIds = new Map<Id, Opportunity>(opportunities).keySet();
        AccountContactUtilities.updateCountOfPrimaryContact(opportunityIds);
    }

    /**
    * @description finish - 
    */      
    public void finish(Database.BatchableContext bc) {
        
    }


}