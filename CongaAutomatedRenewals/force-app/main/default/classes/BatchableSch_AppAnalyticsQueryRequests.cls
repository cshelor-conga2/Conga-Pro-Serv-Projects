/** 
* @author GTM, ERedding
* @date 20201005
* @version 1.00
* @description BatchableSch_AppAnalyticsQueryRequests - Batchable/Schedulable apex class that generates AppAnalyticsQueryRequest recods for AppAnalytics
*/
public class BatchableSch_AppAnalyticsQueryRequests implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    private final String PACKAGEUSAGELOG = 'PackageUsageLog';
    private final String PACKAGEUSAGESUMMARY = 'PackageUsageSummary';
    private final String SUBSCRIBERSNAPSHOT = 'SubscriberSnapshot';

    private Boolean HitConcurrentLimit;

    public Set<String> SubscriberOrgIDs;
    public Set<String> PackageIDs;
    public Set<String> AlreadyProcessedLogIds;
    public Set<String> AlreadyProcessedSummaryIds;
    public Set<String> AlreadyProcessedSnapshotIds;

    public String OrgStatus;
    public Datetime LogStartTime;
    public Datetime LogEndTime;
    public Datetime SummaryStartTime;
    public Datetime SummaryEndTime;
    public Datetime SnapshotStartTime;
    public Datetime SnapshotEndTime;

    public Boolean CreateLogRequests;
    public Boolean CreateSummaryRequests;
    public Boolean CreateSnapshotRequests;

    /** 
    * @description BatchableSch_CampaignReporting - Constructor
    */
    public BatchableSch_AppAnalyticsQueryRequests() {
        // LOG AND SNAPSHOT CREATION IS ENABLED BY DEFAULT AND SUMMARY CREATION IS ENABLED ON THE FIRST OF THE MONTH OR DURING A TEST
        CreateLogRequests = TRUE;
        CreateSummaryRequests = (Date.today().day() == 1 || Test.isRunningTest() ? TRUE : FALSE);
        CreateSnapshotRequests = TRUE;

        // INITIALIZE COLLECTIONS
        SubscriberOrgIDs = new Set<String>();
        PackageIDs = new Set<String>();
        AlreadyProcessedLogIds = new Set<String>();
        AlreadyProcessedSummaryIds = new Set<String>();
        AlreadyProcessedSnapshotIds = new Set<String>();

        // SET DEFAULT ORG STATUS
        OrgStatus = 'ACTIVE';
        if(Test.isRunningTest()){
            OrgStatus = ''; // LICENSE ORG STATUSES ARE BLANK DURING TESTS
        }
    }

    /** 
    * @description Scheduable execute method
    */
    public void execute(SchedulableContext context) {
        Database.executeBatch(this, 10);
    }
    
    /** 
    * @description Batchable start method
    */  
    public Database.QueryLocator start(Database.BatchableContext context) {
        if(CreateLogRequests || CreateSummaryRequests || CreateSnapshotRequests){
            HitConcurrentLimit = false;

            // GET YESTERDAY'S DATE
            Date yesterday = Date.today().addDays(-1);
            Datetime yesterdayStart = Datetime.newInstanceGmt(yesterday.year(), yesterday.month(), yesterday.day(), 0, 0, 0);
            Datetime yesterdayEnd = Datetime.newInstanceGmt(yesterday.year(), yesterday.month(), yesterday.day(), 23, 59, 59);

            // SET LOG DATES IF THEY WERE NOT SPECIFIED MANUALLY
            if(CreateLogRequests && (LogStartTime == null || LogEndTime == null)){
                LogStartTime = yesterdayStart;
                LogEndTime = yesterdayEnd;
            }

            // SET SUMARY DATES IF THEY WERE NOT SPECIFIED MANUALLY
            if(CreateSummaryRequests && (SummaryStartTime == null || SummaryEndTime == null)){
                // CREATE START AND END TIMES FOR ALL OF LAST MONTH
                Date lastMonthEnd = Date.newInstance(Datetime.now().year(), Datetime.now().month(), 1).addDays(-1);
                SummaryStartTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), 1, 0, 0, 0);
                SummaryEndTime = Datetime.newInstanceGmt(lastMonthEnd.year(), lastMonthEnd.month(), lastMonthEnd.day(), 23, 59, 59);
            }

            // SET SNAPSHOT DATES IF THEY WERE NOT SPECIFIED MANUALLY
            if(CreateSnapshotRequests && (SnapshotStartTime == null || SnapshotEndTime == null)){
                SnapshotStartTime = yesterdayStart.addMinutes(-1); 
                SnapshotEndTime = yesterdayEnd.addMinutes(1);
                // EXPANDING THE RANGE OF TIME BY 1 MINUTE ON EITHER SIDE OF THE RANGE IS REQUIRED FOR SNAPSHOTS SO A WHOLE DAY IS CONTAINED WITHIN THE SPECIFIED START AND END
            }

            // UPDATE USER PROVIDED IDS
            //// ORG IDS HAVE TO BE 15 LENGTH TO MATCH DATA IN THE sfLma__Subscriber_Org_ID__c FIELD
            if(!SubscriberOrgIDs.isEmpty()){
                for(String orgId : SubscriberOrgIDs){
                    orgId = orgId.left(15);
                }
            }
            //// PACKAGE IDS HAVE TO BE 18 LENGTH TO MATCH DATA IN THE sfLma__Package__r.sfLma__Package_ID__c FIELD
            if(!PackageIDs.isEmpty()){
                for(String packageId : PackageIDs){
                    packageId = (String)((Id)packageId);
                }
            }

            // BUILD QUERY
            String licenseQuery = 'SELECT Id, sfLma__Subscriber_Org_ID__c, sfLma__Package__r.sfLma__Package_ID__c FROM sfLma__License__c ';
                   licenseQuery += 'WHERE sfLma__Status__c = \'Active\' AND sfLma__Org_Status__c = :OrgStatus ';
                   licenseQuery += 'AND sfLma__Subscriber_Org_ID__c != null AND sfLma__Package__r.sfLma__Package_ID__c != null ';

            if(!SubscriberOrgIDs.isEmpty() && !PackageIDs.isEmpty()){
                // ORG AND PACKAGE IDS PROVIDED, FILTER ON BOTH
                licenseQuery += 'AND sfLma__Subscriber_Org_ID__c IN :SubscriberOrgIDs AND sfLma__Package__r.sfLma__Package_ID__c IN :PackageIDs ';
            }
            else if(!SubscriberOrgIDs.isEmpty() && PackageIDs.isEmpty()){
                // ORG IDS PROVIDED, FILTER ON ORG
                licenseQuery += 'AND sfLma__Subscriber_Org_ID__c IN :SubscriberOrgIDs ';
            }
            else if(SubscriberOrgIDs.isEmpty() && !PackageIDs.isEmpty()){
                // PACKAGE IDS PROVIDED, FILTER ON PACKAGE
                licenseQuery += 'AND sfLma__Package__r.sfLma__Package_ID__c IN :PackageIDs ';
            }

            // BUILD OR STATEMENTS
            licenseQuery += 'AND (';
            if(CreateLogRequests){
                licenseQuery += 'sfLma__Package__r.sfLma__Package_ID__c NOT IN :AlreadyProcessedLogIds';
            }
            if(CreateSummaryRequests){
                licenseQuery += (CreateLogRequests ? ' OR ' : '') + 'sfLma__Package__r.sfLma__Package_ID__c NOT IN :AlreadyProcessedSummaryIds';
            }
            if(CreateSnapshotRequests){
                licenseQuery += (CreateLogRequests || CreateSummaryRequests ? ' OR ' : '') + 'sfLma__Package__r.sfLma__Package_ID__c NOT IN :AlreadyProcessedSnapshotIds';
            }
            licenseQuery += ') ORDER BY sfLma__Package__r.sfLma__Package_ID__c';

            // GET ACTIVE LICENSES
            return Database.getQueryLocator(licenseQuery); 
        }
        else {
            // GET ACTIVE LICENSES
            return Database.getQueryLocator('SELECT Id FROM sfLma__License__c WHERE Id = null');             
        }
    }
    
    /** 
    * @description Batchable execute method
    */
    public void execute(Database.BatchableContext context, List<sfLma__License__c> scope) {
        try{
            // GET ORG IDS IN 15 AND 18 LENGTHS
            Map<String, String> licensePackageIdsMap = new Map<String, String>(); // KEYS ARE 15 LENGTH IDS, VALUES ARE 18 LENGTH IDS
            for(sfLma__License__c license : scope){
                licensePackageIdsMap.put(license.sfLma__Package__r.sfLma__Package_ID__c.left(15), license.sfLma__Package__r.sfLma__Package_ID__c);
            }

            // GET IDS FROM REQUESTS THAT HAVE ALREADY BEEN CREATED
            for(AppAnalyticsQueryRequest request : [SELECT DataType, OrganizationIds, PackageIds FROM AppAnalyticsQueryRequest
                                                    WHERE ((DataType = :PACKAGEUSAGELOG AND StartTime = :LogStartTime AND EndTime = :LogEndTime) OR 
                                                           (DataType = :PACKAGEUSAGESUMMARY AND StartTime = :SummaryStartTime AND EndTime = :SummaryEndTime) OR
                                                           (DataType = :SUBSCRIBERSNAPSHOT AND StartTime = :SnapshotStartTime AND EndTime = :SnapshotEndTime))
                                                    AND PackageIds != null AND PackageIds IN :licensePackageIdsMap.keySet()]){

                String packageId18 = licensePackageIdsMap.get(request.PackageIds);
                if(request.DataType == PACKAGEUSAGELOG){
                    AlreadyProcessedLogIds.add(packageId18);
                }
                else if(request.DataType == PACKAGEUSAGESUMMARY){
                    AlreadyProcessedSummaryIds.add(packageId18);
                }
                else if(request.DataType == SUBSCRIBERSNAPSHOT){
                    AlreadyProcessedSnapshotIds.add(packageId18);
                }
            }

            // CREATE MAP FOR LOGGING ERRORS
            Map<String, Map<String, List<Database.Error>>> newRequestErrors = new Map<String, Map<String, List<Database.Error>>>{
                PACKAGEUSAGELOG => new Map<String, List<Database.Error>>(),
                PACKAGEUSAGESUMMARY => new Map<String, List<Database.Error>>(),
                SUBSCRIBERSNAPSHOT => new Map<String, List<Database.Error>>()
            };

            //// CREATE NEW LOG, SUMMARY, AND SNAPSHOT REQUESTS FOR EACH PACKAGE AND COORESPONDING ORG ID
            for(String packageId18 : licensePackageIdsMap.values()){
                String packageId15 = packageId18.left(15);

                // CREATE A PREVIOUS 24 HOUR LOG REQUEST IF IF IT DOESNT ALREADY EXIST AND LOG START AND END TIMES ARE VALID
                if(!AlreadyProcessedLogIds.contains(packageId18) && CreateLogRequests && LogStartTime != null && LogEndTime != null && LogStartTime < LogEndTime){
                    Database.SaveResult result = Database.insert(new AppAnalyticsQueryRequest(DataType = PACKAGEUSAGELOG, PackageIds = packageId15, StartTime = LogStartTime, EndTime = LogEndTime), false);
                    if(result.isSuccess()){
                        AlreadyProcessedLogIds.add(packageId18);
                    }
                    else{
                        newRequestErrors.get(PACKAGEUSAGELOG).put(packageId18, result.getErrors());
                    }
                }

                // CREATE A MONTHLY SUMMARY REQUEST IF IT DOESNT ALREADY EXIST, SUMMARY START AND END TIMES ARE VALID, AND ITS THE FIRST OF THE MONTH OR CREATION WAS FORCED
                if(!AlreadyProcessedSummaryIds.contains(packageId18) && CreateSummaryRequests && SummaryStartTime != null && SummaryEndTime != null && SummaryStartTime < SummaryEndTime){
                    Database.SaveResult result = Database.insert(new AppAnalyticsQueryRequest(DataType = PACKAGEUSAGESUMMARY, PackageIds = packageId15, StartTime = SummaryStartTime, EndTime = SummaryEndTime), false);
                    if(result.isSuccess()){
                        AlreadyProcessedSummaryIds.add(packageId18);
                    }
                    else{
                        newRequestErrors.get(PACKAGEUSAGESUMMARY).put(packageId18, result.getErrors());
                    }
                }

                // CREATE A PREVIOUS 24 HOUR SNAPSHOT REQUEST IF IF IT DOESNT ALREADY EXIST AND SNAPSHOT START AND END TIMES ARE VALID
                if(!AlreadyProcessedSnapshotIds.contains(packageId18) && CreateSnapshotRequests && SnapshotStartTime != null && SnapshotEndTime != null && SnapshotStartTime < SnapshotEndTime){
                    Database.SaveResult result = Database.insert(new AppAnalyticsQueryRequest(DataType = SUBSCRIBERSNAPSHOT, PackageIds = packageId15, StartTime = SnapshotStartTime, EndTime = SnapshotEndTime), false);
                    if(result.isSuccess()){
                        AlreadyProcessedSnapshotIds.add(packageId18);
                    }
                    else{
                        newRequestErrors.get(SUBSCRIBERSNAPSHOT).put(packageId18, result.getErrors());
                    }
                }
            }

            // CHECK ERROR MAP FOR CONCURRENT ERRORS
            for(String requestType : newRequestErrors.keySet()){
                for(String packageId18 : newRequestErrors.get(requestType).keySet()){
                    Boolean concurrentError = false;
                    for(Database.Error error : newRequestErrors.get(requestType).get(packageId18)){
                        if(error.getMessage().contains('concurrent')){
                            concurrentError = true;
                            HitConcurrentLimit = true;
                            break;
                        }
                        else{
                            // LOG ERROR TO LOG OBJECT IF THE ERROR IS NOT ABOUT A CONCURRENT ISSUE
                            SystemIssueLogHelper.LogException('BatchableSch_AppAnalyticsQueryRequests', 'execute', null, error.getMessage(), false);
                        }
                    }

                    if(!concurrentError){
                        // NOT A CONCURRENT ERROR, DONT NEED TO RETRY SO ADD TO ALREADY PROCESSED LIST
                        if(requestType == PACKAGEUSAGELOG){
                            AlreadyProcessedLogIds.add(packageId18);
                        }
                        else if(requestType == PACKAGEUSAGESUMMARY){
                            AlreadyProcessedSummaryIds.add(packageId18);
                        }
                        else if(requestType == SUBSCRIBERSNAPSHOT){
                            AlreadyProcessedSnapshotIds.add(packageId18);
                        }
                    }
                }
            }

            // LOG ANY ERRORS
            SystemIssueLogHelper.UpsertExceptions();
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BatchableSch_AppAnalyticsQueryRequests', 'execute', scope, ex, true);
        }
    }
    
    /** 
    * @description Code to fire when all batches are complete
    */
    public void finish(Database.BatchableContext context) {
        // RESTART JOB WITH SAME PARAMETERS IF CONCURRENT LIMIT IS HIT
        if(HitConcurrentLimit || Test.isRunningTest()){
            BatchableSch_AppAnalyticsQueryRequests newBatch = new BatchableSch_AppAnalyticsQueryRequests();
            // CARRY DATA OVER INTO NEW JOB
            newBatch.SubscriberOrgIDs = SubscriberOrgIDs;
            newBatch.PackageIDs = PackageIDs;
            newBatch.AlreadyProcessedLogIds = AlreadyProcessedLogIds;
            newBatch.AlreadyProcessedSummaryIds = AlreadyProcessedSummaryIds;
            newBatch.AlreadyProcessedSnapshotIds = AlreadyProcessedSnapshotIds;

            newBatch.OrgStatus = OrgStatus;
            newBatch.LogStartTime = LogStartTime;
            newBatch.LogEndTime = LogEndTime;
            newBatch.SummaryStartTime = SummaryStartTime;
            newBatch.SummaryEndTime = SummaryEndTime;
            newBatch.SnapshotStartTime = SnapshotStartTime;
            newBatch.SnapshotEndTime = SnapshotEndTime;

            newBatch.CreateLogRequests = CreateLogRequests;
            newBatch.CreateSummaryRequests = CreateSummaryRequests;
            newBatch.CreateSnapshotRequests = CreateSnapshotRequests;

            // CONTINUE PROCESSING IN NEW JOB
            if(!Test.isRunningTest()){
                System.scheduleBatch(newBatch, 'AppAnalyticsQueryRequestsRecursion' + context.getJobId(), 3, 10);
            }
        }
    }


}