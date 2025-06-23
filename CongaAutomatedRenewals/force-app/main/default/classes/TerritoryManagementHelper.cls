/**
* @author ECS, ERedding
* @date 20190408
* @version 1.00
* @description TerritoryManagementHelper - Custom functionality for the custom built Conga Territory Management
*/
public with sharing class TerritoryManagementHelper {
    //////////////////////////////////////////////////////////////////////////////////////////////
    //////////////// CONSTANTS FOR USE BY ALL AREAS OF TERRITORY MANAGEMENT CODE /////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////
    public static final String PROSPECTTYPE = 'Prospect';
    public static final String CUSTOMERTYPE = 'Customer';
    public static final String CUSTOMERPASTDUETYPE = 'Customer - Past Due';
    public static final String CUSTOMERFORMERTYPE = 'Customer - Former';

    // TERRITORY MANAGEMENT ROLL NAMES
    public static final String TMROLENAME {
    get { 
        if(String.isBlank(TMROLENAME)){ TMROLENAME = TeamMemberRoleNames.get('TM'); } return TMROLENAME; 
    } set; }
    public static final String CLMROLENAME {
    get { 
        if(String.isBlank(CLMROLENAME)){ CLMROLENAME = TeamMemberRoleNames.get('CLM'); } return CLMROLENAME;
     } set; }    
    public static final String CSMROLENAME {
    get { 
        if(String.isBlank(CSMROLENAME)){ CSMROLENAME = TeamMemberRoleNames.get('CSM'); } return CSMROLENAME;
     } set; }
    public static final String RMROLENAME {
    get { 
        if(String.isBlank(RMROLENAME)){ RMROLENAME = TeamMemberRoleNames.get('RM'); } return RMROLENAME;
     } set; }
    public static final String BDRROLENAME {
    get { 
        if(String.isBlank(BDRROLENAME)){ BDRROLENAME = TeamMemberRoleNames.get('BDR'); } return BDRROLENAME;
     } set; }
    public static final String SDRROLENAME {
    get { 
        if(String.isBlank(SDRROLENAME)){ SDRROLENAME = TeamMemberRoleNames.get('SDR'); } return SDRROLENAME;
     } set; }
    public static final String SEROLENAME {
    get { 
        if(String.isBlank(SEROLENAME)){ SEROLENAME = TeamMemberRoleNames.get('SE'); } return SEROLENAME;
     } set; }
    private static Map<String, String> TeamMemberRoleNames {
    get {
        if(TeamMemberRoleNames == null){
            TeamMemberRoleNames = new Map<String, String>();
            List<Territory_Management_Role_Names__mdt> roleNamesMetadata = [SELECT TM_Role_Name__c, CLM_Role_Name__c, CSM_Role_Name__c, RM_Role_Name__c,
                                                                                   BDR_Role_Name__c, SDR_Role_Name__c, SE_Role_Name__c
                                                                            FROM Territory_Management_Role_Names__mdt LIMIT 1];
            if(!roleNamesMetadata.isEmpty()){
                TeamMemberRoleNames.put('TM', roleNamesMetadata[0].TM_Role_Name__c);
                TeamMemberRoleNames.put('CLM', roleNamesMetadata[0].CLM_Role_Name__c);
                TeamMemberRoleNames.put('CSM', roleNamesMetadata[0].CSM_Role_Name__c);
                TeamMemberRoleNames.put('RM', roleNamesMetadata[0].RM_Role_Name__c);
                TeamMemberRoleNames.put('BDR', roleNamesMetadata[0].BDR_Role_Name__c);
                TeamMemberRoleNames.put('SDR', roleNamesMetadata[0].SDR_Role_Name__c);
                TeamMemberRoleNames.put('SE', roleNamesMetadata[0].SE_Role_Name__c);

            }
            else{
                SystemIssueLogHelper.LogException('TerritoryManagementHelper', 'Static Variable', null, 'No Metadata Found For TeamMemberRoleNames', true);
            }
        }
        return TeamMemberRoleNames;
    } set; }


    /////////////////////////////////////////////////////////////////////////////////////////////
    //////////////// STATIC VARIABLES USED BY TERRITORY MANAGEMENT PAGE UPDATES /////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
    public static Set<String> RolesQualifyingForUpdate = new Set<String>();
    public static Boolean MadeThroughManagementPage = false; // Flags whether Segment/Division changes were made directly to the records OR through the Territory Management Page
   
    // TERRITORY SEGMENT USER RECORDS WITH QUALIFYING UPDATES
    public static Map<Id, TM_Territory_Segment_Users__c> QualifyingTSUs {
    get {
        if(QualifyingTSUs == null){
            QualifyingTSUs = new Map<Id, TM_Territory_Segment_Users__c>();
        }
        return QualifyingTSUs;
    } set; }

    //// TERRITORY DIVISION USER RECORDS WITH QUALIFYING UPDATES
    public static Map<Id, TM_Territory_Division_Users__c> QualifyingTDUs {
    get {
        if(QualifyingTDUs == null){
            QualifyingTDUs = new Map<Id, TM_Territory_Division_Users__c>();
        }
        return QualifyingTDUs;
    } set; }

    // RECORD UPDATE INFO
    public static Map<String, List<String>> RecordUpdateInfo {
    get {
        if(RecordUpdateInfo == null){
            RecordUpdateInfo = new Map<String, List<String>>();
            RecordUpdateInfo.put('Segment', new List<String>());
            RecordUpdateInfo.put('Division', new List<String>());
        }
        return RecordUpdateInfo;
    } set; }


}