/**
* @author ECS, ERedding
* @date 20190314
* @version 1.00
* @description TerritoryManagementController - Custom Controller for Conga Territory Management VF Page
*/
public with sharing class TerritoryManagementController {
    public List<SelectOption> TMUsers {get; set;}
    public List<SelectOption> CLMUsers {get; set;}    
    public List<SelectOption> CSMUsers {get; set;}
    public List<SelectOption> RMUsers {get; set;}
    public Set<Id> TMUserIds {get; set;}
    public Set<Id> CLMUserIds {get; set;}
    public Set<Id> CSMUserIds {get; set;}
    public Set<Id> RMUserIds {get; set;}
    public List<SelectOption> Geos {get; set;}
    public List<SelectOption> Regions {get; set;}
    public List<SelectOption> Territories {get; set;}
    public List<SelectOption> Segments {get; set;}
    public List<SelectOption> Divisions {get; set;}
    public String SelectedGeo {get; set;}
    public String SelectedRegion {get; set;}
    //public String SelectedTerritory {get; set;}
    public String SelectedSegment {get; set;}
    public String SelectedDivision {get; set;}
    public List<TerrSegmentWrapper> TerrSegmentWrappers {get; set;}
    public List<TerrDivisionWrapper> TerrDivisionWrappers {get; set;}
    public String NewEntryTSId {get; set;}

    /** 
    * @description TerritoryManagementController - Constructor. Initialize variables and load data
    */
    public TerritoryManagementController(){
        // INITIALIZE CLASS VARIABLES
        TMUsers = new List<SelectOption>();
        CLMUsers = new List<SelectOption>();        
        CSMUsers = new List<SelectOption>();
        RMUsers = new List<SelectOption>();
        TMUserIds = new Set<Id>();
        CLMUserIds = new Set<Id>();
        CSMUserIds = new Set<Id>();
        RMUserIds = new Set<Id>();
        Geos = new List<SelectOption>();
        Regions = new List<SelectOption>();
        //Territories = new List<SelectOption>();
        Segments = new List<SelectOption>();
        Divisions = new List<SelectOption>();
        TerrSegmentWrappers = new List<TerrSegmentWrapper>();
        TerrDivisionWrappers = new List<TerrDivisionWrapper>();

        // ADD -- NONE -- OPTIONS TO USER PICKLISTS
        TMUsers.add(new SelectOption('', '--- None ---'));
        CLMUsers.add(new SelectOption('', '--- None ---'));        
        CSMUsers.add(new SelectOption('', '--- None ---'));
        RMUsers.add(new SelectOption('', '--- None ---'));

        // GET TERRITORY MANAGER USERS, CUSTOMER SUCCESS MANAGER USERS, AND CLM USERS AVAILABLE FOR CHOOSING
        for(User user : [SELECT Id, Name, IsActive, UserRole.Name, ProfileId, Profile.Name FROM User 
                         WHERE IsActive = true AND UserType = 'Standard' AND (NOT Name LIKE '%Integration%') AND (NOT Department LIKE '%Integration%') ORDER BY Name]){
        
            // GET TM USERS
            if(user.UserRole != null && (user.UserRole.Name.contains('Territory Manager') || user.UserRole.Name.contains('Sales'))){
                TMUsers.add(new SelectOption(user.Id, (user.IsActive ? user.Name : user.Name + ' (Inactive)'), !user.IsActive));
                TMUserIds.add(user.Id);
            }
            // GET CSM USERS
            if(user.UserRole != null && user.UserRole.Name.contains('Customer Success')){
                CSMUsers.add(new SelectOption(user.Id, (user.IsActive ? user.Name : user.Name + ' (Inactive)'), !user.IsActive));
                CSMUserIds.add(user.Id);
            }

            // GET RM USERS
            if(user.Profile.Name == 'Conga CS User' || user.Profile.Name == 'Conga Sales User'){
                RMUsers.add(new SelectOption(user.Id, (user.IsActive ? user.Name : user.Name + ' (Inactive)'), !user.IsActive));
                RMUserIds.add(user.Id);
            }

            // GET CSM USERS, ALL USERS ARE AVAILABLE AS CSMs FOR NOW
            CLMUsers.add(new SelectOption(user.Id, (user.IsActive ? user.Name : user.Name + ' (Inactive)'), !user.IsActive)); 
            CLMUserIds.add(user.Id);
        }

        // LOAD INITIAL DATA
        loadGeos();
    }
    
    /** 
    * @description loadGeos - Loads Geos from TM_Geo__c records
    * @return void
    */
    @testVisible
    private void loadGeos(){
        // LOAD GEO OPTIONS
        Geos.clear();

        List<TM_Geo__c> geoRecords = [SELECT Id, Name, Is_Active__c FROM TM_Geo__c ORDER BY Name];
        if(!geoRecords.isEmpty()){
            Geos.add(new SelectOption('ChooseGeo', '--- Choose a Geo ---', true));
            SelectedGeo = 'ChooseGeo';

            for(TM_Geo__c geo : geoRecords){
                Geos.add(new SelectOption(geo.Id, (geo.Is_Active__c ? geo.Name : geo.Name + ' (Inactive)')));
            }
        }
        else{
            Geos.add(new SelectOption('NoGeos', '--- No Geos Found ---'));
            SelectedGeo = 'NoGeos';
        }

        // LOAD REGIONS AFTER GEOS
        loadRegions();
    }

    /** 
    * @description loadRegions - Loads Regions from TM_Region__c records
    * @return void
    */
    public void loadRegions(){
        // LOAD REGION OPTIONS
        Regions.clear();

        if(SelectedGeo == 'ChooseGeo' || SelectedGeo == 'NoGeos'){
            Regions.add(new SelectOption('ChooseGeo', '--- Choose a Geo ---', true));
            SelectedRegion = 'ChooseGeo';
        }
        else if(String.isNotBlank(SelectedGeo) && SelectedGeo instanceof Id){
            List<TM_Region__c> regionRecords = [SELECT Id, Name, Is_Active__c FROM TM_Region__c WHERE TM_GeoId__c = :SelectedGeo ORDER BY Name];
            if(!regionRecords.isEmpty()){
                Regions.add(new SelectOption('ChooseRegion', '--- Choose a Region ---', true));
                SelectedRegion = 'ChooseRegion';

                for(TM_Region__c region : regionRecords){
                    Regions.add(new SelectOption(region.Id, (region.Is_Active__c ? region.Name : region.Name + ' (Inactive)')));
                }
            }
            else{
                Regions.add(new SelectOption('NoRegions', '--- No Regions Found ---'));
                SelectedRegion = 'NoRegions';
            }
        }

        // LOAD SEGMENTS AFTER REGIONS
        loadSegments();
    }

    ///** 
    //* @description loadTerritories - Loads Territories from TM_Territory__c records
    //* @return void
    //*/
    //public void loadTerritories(){
    //    // LOAD TERRITORIES
    //    Territories.clear();

    //    if(SelectedRegion == 'ChooseGeo' || SelectedRegion == 'ChooseRegion' || SelectedRegion == 'NoRegions'){
    //      Territories.add(new SelectOption('ChooseRegion', '--- Choose a Region ---', true));
    //      SelectedTerritory = 'ChooseRegion';
    //    }
    //    else if(String.isNotBlank(SelectedRegion) && SelectedRegion instanceof Id){
    //        List<TM_Territory__c> territoryRecords = [SELECT Id, Name, Is_Active__c FROM TM_Territory__c WHERE TM_RegionId__c = :SelectedRegion ORDER BY Name];
    //        if(!territoryRecords.isEmpty()){
    //            Territories.add(new SelectOption('ChooseTerritory', '--- Choose a Territory ---', true));
    //            Territories.add(new SelectOption('All', '--- Show All ---', false));
    //            SelectedTerritory = 'ChooseTerritory';

    //            for(TM_Territory__c territory : territoryRecords){
    //                Territories.add(new SelectOption(territory.Id, (territory.Is_Active__c ? territory.Name : territory.Name + ' (Inactive)')));
    //            }
    //        }
    //        else{
    //            Territories.add(new SelectOption('NoTerritories', '--- No Territories Found ---'));
    //            SelectedTerritory = 'NoTerritories';
    //        }
    //    }

    //    // LOAD SEGMENTS
    //    loadSegments();
    //}


    /** 
    * @description loadSegments - Loads Segment data from TM_Segment__c records
    * @return void
    */
    public void loadSegments(){
        // CLEAR SEGMENT LIST
        Segments.clear();

        if(SelectedRegion == 'ChooseGeo' || SelectedRegion == 'ChooseRegion' || SelectedRegion == 'NoRegions'){
            Segments.add(new SelectOption('ChooseRegion', '--- Choose a Region ---', true));
            SelectedSegment = 'ChooseRegion';
        }
        else if(String.isNotBlank(SelectedRegion) && SelectedRegion instanceof Id){
            List<TM_Territory_Segment__c> territorySegmentRecords = [SELECT TM_SegmentId__c, TM_SegmentId__r.Name, TM_SegmentId__r.Is_Active__c FROM TM_Territory_Segment__c
                                                                     WHERE TM_TerritoryId__r.TM_RegionId__c = :SelectedRegion ORDER BY Name];
            if(!territorySegmentRecords.isEmpty()){
            
                Segments.add(new SelectOption('ChooseSegment', '--- Choose a Segment ---', true));
                SelectedSegment = 'ChooseSegment';

                Set<Id> segmentsAlreadyAdded = new Set<Id>(); // PREVENTS DUPLICATE SELECT OPTIONS
                for(TM_Territory_Segment__c terrSeg : territorySegmentRecords){
                    if(!segmentsAlreadyAdded.contains(terrSeg.TM_SegmentId__c)){
                        Segments.add(new SelectOption(terrSeg.TM_SegmentId__c, (terrSeg.TM_SegmentId__r.Is_Active__c ? terrSeg.TM_SegmentId__r.Name : terrSeg.TM_SegmentId__r.Name + ' (Inactive)')));
                        segmentsAlreadyAdded.add(terrSeg.TM_SegmentId__c);
                    }
                }
            }
            else{
                Segments.add(new SelectOption('NoSegments', '--- No Segments Found ---'));
                SelectedSegment = 'NoSegments';
            }
        }

        // LOAD DIVISIONS
        loadDivisions();
    }

    /** 
    * @description loadDivisions - Loads Segment data from TM_Division__c records
    * @return void
    */
    public void loadDivisions(){
        // CLEAR DIVISION LIST
        Divisions.clear();

        if(SelectedRegion == 'ChooseGeo' || SelectedRegion == 'ChooseRegion' || SelectedRegion == 'NoRegions'){
            Divisions.add(new SelectOption('ChooseRegion', '--- Choose a Region ---', true));
            SelectedDivision = 'ChooseRegion';
        }
        else if(String.isNotBlank(SelectedRegion) && SelectedRegion instanceof Id){
            List<TM_Territory_Division__c> territoryDivisionRecords = [SELECT TM_DivisionId__c, TM_DivisionId__r.Name, TM_DivisionId__r.Is_Active__c FROM TM_Territory_Division__c
                                                                       WHERE TM_TerritoryId__r.TM_RegionId__c = :SelectedRegion ORDER BY Name];
            if(!territoryDivisionRecords.isEmpty()){
                Divisions.add(new SelectOption('ChooseDivision', '--- Choose a Division ---', true));
                SelectedDivision = 'ChooseDivision';

                Set<Id> divisionsAlreadyAdded = new Set<Id>(); // PREVENTS DUPLICATE SELECT OPTIONS
                for(TM_Territory_Division__c terrDiv : territoryDivisionRecords){
                    if(!divisionsAlreadyAdded.contains(terrDiv.TM_DivisionId__c)){
                        Divisions.add(new SelectOption(terrDiv.TM_DivisionId__c, (terrDiv.TM_DivisionId__r.Is_Active__c ? terrDiv.TM_DivisionId__r.Name : terrDiv.TM_DivisionId__r.Name + ' (Inactive)')));
                        divisionsAlreadyAdded.add(terrDiv.TM_DivisionId__c);
                    }
                }
            }
            else{
                Divisions.add(new SelectOption('NoDivisions', '--- No Divisions Found ---'));
                SelectedDivision = 'NoDivisions';
            }
        }
    }

    /** 
    * @description loadTerritorySegments - Loads data from TM_Territory_Segment__c records
    * @return void
    */
    public void loadTerritorySegments(){
        // CLEAR SEGMENT LIST
        TerrSegmentWrappers.clear();

        if(String.isNotBlank(SelectedSegment) && SelectedSegment instanceof Id){

            // UPDATE SEGMENT WRAPPERS WITH CURRENTLY SELECTED USERS
            for(TM_Territory_Segment__c territorySegment : [SELECT Id, Name, TM_TerritoryId__c, TM_TerritoryId__r.Name, TM_TerritoryId__r.Is_Active_for_Segments__c, TM_SegmentId__c,
                                                             (SELECT Id, TM_Territory_SegmentId__c, Applicable_Industries__c, Assigned_TM_UserId__c, Assigned_TM_UserId__r.Name, 
                                                                     Assigned_CLM_UserId__c, Assigned_CLM_UserId__r.Name FROM TerritorySegmentUsers__r ORDER BY CreatedDate)
                                                            FROM TM_Territory_Segment__c
                                                            WHERE TM_SegmentId__c = :SelectedSegment AND TM_TerritoryId__r.TM_RegionId__c = :SelectedRegion ORDER BY Name]){

                // CREATE WRAPPER FOR TERRITORY SEGMENT DATA
                TerrSegmentWrapper terrSegmentWrapper = new TerrSegmentWrapper(territorySegment.Id, (territorySegment.TM_TerritoryId__r.Is_Active_for_Segments__c ? territorySegment.TM_TerritoryId__r.Name : territorySegment.TM_TerritoryId__r.Name + ' (Inactive)'));

                // CREATE WRAPPERS FOR TERRITORY SEGMENT USERS DATA
                for(TM_Territory_Segment_Users__c terrSegmentUser : territorySegment.TerritorySegmentUsers__r){
                    TerrSegmentUsersWrapper userDataWrapper = new TerrSegmentUsersWrapper(terrSegmentUser.Id, terrSegmentUser.TM_Territory_SegmentId__c);

                    // ADD TM USERS AND ASSIGN CURRENTLY CHOSEN USER
                    if(terrSegmentUser.Assigned_TM_UserId__c != null){
                        userDataWrapper.SelectedTMUserId = terrSegmentUser.Assigned_TM_UserId__c;
                        userDataWrapper.OriginalTMUserId = terrSegmentUser.Assigned_TM_UserId__c;
                    }

                    // ADD CURRENTLY CHOSEN INDUSTRIES
                    if(String.isNotBlank(terrSegmentUser.Applicable_Industries__c)){
                        //userDataWrapper.SelectedIndustries = terrSegmentUser.Applicable_Industries__c.split(';');
                        userDataWrapper.IndustriesRecord.Applicable_Industries__c = terrSegmentUser.Applicable_Industries__c;
                        userDataWrapper.OriginalIndustries = terrSegmentUser.Applicable_Industries__c;
                        //userDataWrapper.OriginalIndustries = terrSegmentUser.Applicable_Industries__c.split(';');
                    }

                    // ADD CLM USERS AND ASSIGN CURRENTLY CHOSEN USER
                    if(terrSegmentUser.Assigned_CLM_UserId__c != null){
                        userDataWrapper.SelectedCLMUserId = terrSegmentUser.Assigned_CLM_UserId__c;
                        userDataWrapper.OriginalCLMUserId = terrSegmentUser.Assigned_CLM_UserId__c;
                    }

                    // CHECK IF USER IS ON A SEGMENT BUT NO LONGER AVAILABLE TO BE CHOSEN
                    if(terrSegmentUser.Assigned_TM_UserId__c != null && !TMUserIds.contains(terrSegmentUser.Assigned_TM_UserId__c)){
                        TMUsers.add(new SelectOption(terrSegmentUser.Assigned_TM_UserId__c, terrSegmentUser.Assigned_TM_UserId__r.Name, true));
                        TMUserIds.add(terrSegmentUser.Assigned_TM_UserId__c);
                    }

                    // CHECK IF USER IS ON A SEGMENT BUT NO LONGER AVAILABLE TO BE CHOSEN
                    if(terrSegmentUser.Assigned_CLM_UserId__c != null && !CLMUserIds.contains(terrSegmentUser.Assigned_CLM_UserId__c)){
                        CLMUsers.add(new SelectOption(terrSegmentUser.Assigned_CLM_UserId__c, terrSegmentUser.Assigned_CLM_UserId__r.Name, true));
                        CLMUserIds.add(terrSegmentUser.Assigned_CLM_UserId__c);
                    }
                    terrSegmentWrapper.UserWrappers.add(userDataWrapper);
                }
                TerrSegmentWrappers.add(terrSegmentWrapper);
            }
        }
    }

    /** 
    * @description loadTerritoryDivisions - Loads data from TM_Territory_Division__c records
    * @return void
    */
    public void loadTerritoryDivisions(){
        // CLEAR DIVISION LIST
        TerrDivisionWrappers.clear();

        if(String.isNotBlank(SelectedDivision) && SelectedDivision instanceof Id){

            // UPDATE SEGMENT WRAPPERS WITH CURRENTLY SELECTED USERS
            for(TM_Territory_Division__c territoryDivision : [SELECT Id, Name, TM_TerritoryId__c, TM_TerritoryId__r.Name, TM_TerritoryId__r.Is_Active_for_Divisions__c, TM_DivisionId__c,
                                                               (SELECT Id, TM_Territory_DivisionId__c, Assigned_CSM_UserId__c, Assigned_CSM_UserId__r.Name, 
                                                                       Assigned_RM_UserId__c, Assigned_RM_UserId__r.Name FROM TerritoryDivisionUsers__r)
                                                              FROM TM_Territory_Division__c
                                                              WHERE TM_DivisionId__c = :SelectedDivision AND TM_TerritoryId__r.TM_RegionId__c = :SelectedRegion ORDER BY Name]){

                TerrDivisionWrapper terrDivisionWrapper = new TerrDivisionWrapper(territoryDivision.Id, (territoryDivision.TM_TerritoryId__r.Is_Active_for_Divisions__c ? territoryDivision.TM_TerritoryId__r.Name : territoryDivision.TM_TerritoryId__r.Name + ' (Inactive)'));
                
                // CREATE WRAPPERS FOR TERRITORY DIVISION USERS DATA
                for(TM_Territory_Division_Users__c terrDivisionUser : territoryDivision.TerritoryDivisionUsers__r){
                    TerrDivisionUsersWrapper userDataWrapper = new TerrDivisionUsersWrapper(terrDivisionUser.Id, terrDivisionUser.TM_Territory_DivisionId__c);

                    // ADD TM USERS AND ASSIGN CURRENTLY CHOSEN USER
                    if(terrDivisionUser.Assigned_CSM_UserId__c != null){
                        userDataWrapper.SelectedCSMUserId = terrDivisionUser.Assigned_CSM_UserId__c;
                        userDataWrapper.OriginalCSMUserId = terrDivisionUser.Assigned_CSM_UserId__c;
                    }

                    // ADD CLM USERS AND ASSIGN CURRENTLY CHOSEN USER
                    if(terrDivisionUser.Assigned_RM_UserId__c != null){
                        userDataWrapper.SelectedRMUserId = terrDivisionUser.Assigned_RM_UserId__c;
                        userDataWrapper.OriginalRMUserId = terrDivisionUser.Assigned_RM_UserId__c;
                    } 

                    // CHECK IF CSM USER IS ON A DIVISION BUT NO LONGER AVAILABLE TO BE CHOSEN
                    if(terrDivisionUser.Assigned_CSM_UserId__c != null && !CSMUserIds.contains(terrDivisionUser.Assigned_CSM_UserId__c)){
                        CSMUsers.add(new SelectOption(terrDivisionUser.Assigned_CSM_UserId__c, terrDivisionUser.Assigned_CSM_UserId__r.Name, true));
                        CSMUserIds.add(terrDivisionUser.Assigned_CSM_UserId__c);
                    }

                    // CHECK IF RM USER IS ON A DIVISION BUT NO LONGER AVAILABLE TO BE CHOSEN
                    if(terrDivisionUser.Assigned_RM_UserId__c != null && !RMUserIds.contains(terrDivisionUser.Assigned_RM_UserId__c)){
                        RMUsers.add(new SelectOption(terrDivisionUser.Assigned_RM_UserId__c, terrDivisionUser.Assigned_RM_UserId__r.Name, true));
                        RMUserIds.add(terrDivisionUser.Assigned_RM_UserId__c);
                    }
                    terrDivisionWrapper.UserWrappers.add(userDataWrapper);
                }
                TerrDivisionWrappers.add(terrDivisionWrapper);
            }
        }
    }

    /** 
    * @description addTSEntry - 
    * @return PageReference
    */
    public PageReference addTSUserEntry(){
        if(String.isNotBlank(NewEntryTSId)){
            for(TerrSegmentWrapper tsWrapper : TerrSegmentWrappers){
                if(tsWrapper.RecordId == NewEntryTSId){
                    tsWrapper.UserWrappers.add(new TerrSegmentUsersWrapper(null, tsWrapper.RecordId));
                    break;
                }
            }
        }
        return null;
    }

    /** 
    * @description saveChanges - Saves any changes made to segments
    * @return PageReference
    */
    public PageReference saveChanges(){

        // GET TERRITORY SEGMENTS TO UPDATE
        List<TM_Territory_Segment_Users__c> territorySegmentsUsersToCreate = new List<TM_Territory_Segment_Users__c>();
        List<TM_Territory_Segment_Users__c> territorySegmentsUsersToUpdate = new List<TM_Territory_Segment_Users__c>();
        for(TerrSegmentWrapper terrSegmentWrapper : TerrSegmentWrappers){
            for(TerrSegmentUsersWrapper userWrapper : terrSegmentWrapper.UserWrappers){
                TM_Territory_Segment_Users__c terrSegmentUsers = new TM_Territory_Segment_Users__c();
                Boolean changeMade = false;
                if(userWrapper.SelectedTMUserId != userWrapper.OriginalTMUserId){
                    terrSegmentUsers.Assigned_TM_UserId__c = userWrapper.SelectedTMUserId;
                    changeMade = true;
                }

                if(userWrapper.SelectedCLMUserId != userWrapper.OriginalCLMUserId){
                    terrSegmentUsers.Assigned_CLM_UserId__c = userWrapper.SelectedCLMUserId;
                    changeMade = true;
                }

                if(userWrapper.OriginalIndustries != userWrapper.IndustriesRecord.Applicable_Industries__c && String.isNotBlank(userWrapper.IndustriesRecord.Applicable_Industries__c)){
                    terrSegmentUsers.Applicable_Industries__c = userWrapper.IndustriesRecord.Applicable_Industries__c;
                    changeMade = true;
                }
                else if(String.isBlank(userWrapper.IndustriesRecord.Applicable_Industries__c)){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'At least one (1) industry must be chosen on a Territory Segment Users entry.'));
                    return null;
                }

                if(changeMade){
                    if(userWrapper.RecordId != null){
                        terrSegmentUsers.Id = userWrapper.RecordId;
                        territorySegmentsUsersToUpdate.add(terrSegmentUsers);
                    }
                    else{
                        terrSegmentUsers.TM_Territory_SegmentId__c = terrSegmentWrapper.RecordId;
                        territorySegmentsUsersToCreate.add(terrSegmentUsers);
                    }
                }
            }
        }

        // GET TERRITORY DIVISIONS TO UPDATE
        List<TM_Territory_Division_Users__c> territoryDivisionUsersToUpdate = new List<TM_Territory_Division_Users__c>();
        for(TerrDivisionWrapper terrDivisionWrapper : TerrDivisionWrappers){
            for(TerrDivisionUsersWrapper userWrapper : terrDivisionWrapper.UserWrappers){
                TM_Territory_Division_Users__c terrDivisionUsers = new TM_Territory_Division_Users__c();
                Boolean changeMade = false;
                if(userWrapper.SelectedCSMUserId != userWrapper.OriginalCSMUserId){
                    terrDivisionUsers.Assigned_CSM_UserId__c = userWrapper.SelectedCSMUserId;
                    changeMade = true;
                }

                if(userWrapper.SelectedRMUserId != userWrapper.OriginalRMUserId){
                    terrDivisionUsers.Assigned_RM_UserId__c = userWrapper.SelectedRMUserId;
                    changeMade = true;
                } 

                if(changeMade && userWrapper.RecordId != null){
                    terrDivisionUsers.Id = userWrapper.RecordId;
                    territoryDivisionUsersToUpdate.add(terrDivisionUsers);
                }            
            }
        }

        // SET STATIC VARIABLE SO THE BELOW DML CALLS DONT EXECUTE BATCH JOBS. THIS CODE WILL DO THAT
        TerritoryManagementHelper.MadeThroughManagementPage = true;

        // SAVE NEW TERRITORY SEGMENT USER RECORDS
        if(!territorySegmentsUsersToCreate.isEmpty()){
            Database.SaveResult[] insertResults = Database.insert(territorySegmentsUsersToCreate, false);
            SystemIssueLogHelper.CheckForDatabaseErrors(insertResults, 'TerritoryManagement', 'saveChanges', false);
        }

        // SAVE UPDATED TERRITORY SEGMENT USER RECORDS
        if(!territorySegmentsUsersToUpdate.isEmpty()){
            Database.SaveResult[] updateResults = Database.update(territorySegmentsUsersToUpdate, false);
            SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'TerritoryManagement', 'saveChanges', false);
        }

        // SAVE UPDATED TERRITORY DIVISION USER RECORDS
        if(!territoryDivisionUsersToUpdate.isEmpty()){
            Database.SaveResult[] updateResults = Database.update(territoryDivisionUsersToUpdate, false);
            SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'TerritoryManagement', 'saveChanges', false);
        }

        // SAVE ANY ERRORS
        SystemIssueLogHelper.UpsertExceptions();

        // EXECUTE BATCH CLASS TO UPDATE RECORDS ASYNCHRONOUSLY
        if(!TerritoryManagementHelper.QualifyingTSUs.isEmpty() || !TerritoryManagementHelper.QualifyingTDUs.isEmpty()){
            Database.executeBatch(new BatchableTerritoryManagement(TerritoryManagementHelper.QualifyingTSUs, TerritoryManagementHelper.QualifyingTDUs, true), 1);
        }

        // RELOAD DATA
        loadTerritorySegments();
        loadTerritoryDivisions();
        return null;
    }

    /** 
    * @description revertChanges - Cancels any changes by reloading all Segment and Division data
    * @return void
    */
    public PageReference revertChanges(){
        // RELOAD DATA
        loadTerritorySegments();
        loadTerritoryDivisions();
        return null;
    }

    /** 
    * @description class TerrSegmentWrapper - Segment Wrapper Class
    */
    @testVisible
    private class TerrSegmentWrapper{ 
        public Id RecordId {get;set;}
        public String RecordName {get;set;}          
        public List<TerrSegmentUsersWrapper> UserWrappers {get;set;}

        /** 
        * @description TerrSegmentWrapper - Constructor
        * @param Id pRecordId
        * @param String pRecordName
        */
        public TerrSegmentWrapper(Id pRecordId, String pRecordName){
            RecordId = pRecordId;
            RecordName = pRecordName;
            UserWrappers = new List<TerrSegmentUsersWrapper>();
        }
    }

    /** 
    * @description class TerrSegmentUsersWrapper - Territory Segment Users Wrapper Class
    */
    @testVisible
    private class TerrSegmentUsersWrapper{ 
        public Id RecordId {get;set;}
        public Id TerritorySegmentId {get;set;}
        public TM_Territory_Segment_Users__c IndustriesRecord {get;set;}
        public String OriginalIndustries {get;set;}
        public String SelectedTMUserId {get;set;}
        public String OriginalTMUserId {get;set;}
        public String SelectedCLMUserId {get;set;}
        public String OriginalCLMUserId {get;set;}

        /** 
        * @description TerrSegmentUsersWrapper - Constructor
        * @param Id pRecordId
        * @param Id pTerritorySegmentId
        */
        public TerrSegmentUsersWrapper(Id pRecordId, Id pTerritorySegmentId){
            RecordId = pRecordId;
            TerritorySegmentId = pTerritorySegmentId;
            SelectedTMUserId = '';
            OriginalTMUserId = '';
            SelectedCLMUserId = '';
            OriginalCLMUserId = '';
            OriginalIndustries = '';
            IndustriesRecord = new TM_Territory_Segment_Users__c();
        }
    }

    /** 
    * @description class TerrDivisionWrapper - Division Wrapper Class
    */
    @testVisible
    private class TerrDivisionWrapper{ 
        public Id RecordId {get;set;}
        public String RecordName {get;set;}          
        public List<TerrDivisionUsersWrapper> UserWrappers {get;set;}
        
        /** 
        * @description TerrDivisionWrapper - Constructor
        * @param Id pRecordId
        * @param String pRecordName    
        */
        public TerrDivisionWrapper(Id pRecordId, String pRecordName){
            RecordId = pRecordId;
            RecordName = pRecordName;
            UserWrappers = new List<TerrDivisionUsersWrapper>();       
        }
    }

    /** 
    * @description class TerrDivisionUsersWrapper - Territory Division Users Wrapper Class
    */
    @testVisible
    private class TerrDivisionUsersWrapper{ 
        public Id RecordId {get;set;}       
        public Id TerritoryDivisionId {get;set;}
        public String SelectedCSMUserId {get;set;}
        public String OriginalCSMUserId {get;set;}
        public String SelectedRMUserId {get;set;}
        public String OriginalRMUserId {get;set;}

        /** 
        * @description DivisionDataWrapper - Constructor
        * @param Id pRecordId
        * @param Id pTerritoryDivisionId  
        */
        public TerrDivisionUsersWrapper(Id pRecordId, Id pTerritoryDivisionId){
            RecordId = pRecordId;
            TerritoryDivisionId = pTerritoryDivisionId;
            SelectedCSMUserId = '';
            OriginalCSMUserId = '';
            SelectedRMUserId = '';
            OriginalRMUserId = '';            
        }
    }


}