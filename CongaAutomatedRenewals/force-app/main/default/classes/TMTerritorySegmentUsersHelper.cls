/**
* @author ECS, ERedding
* @date 20200124
* @version 1.00
* @description TMTerritorySegmentUsersHelper - Custom functionality for the TM_Territory_Segment_Users__c Custom Object
*/
public with sharing class TMTerritorySegmentUsersHelper {

    /**
    * @description processUserChanges - 
    * @param List<TM_Territory_Segment_Users__c> updatedTerrSegmentUsers
    * @param Map<Id, TM_Territory_Segment_Users__c> outdatedTerrSegmentUsers
    * @return void
    */
    public static void processUserChanges(List<TM_Territory_Segment_Users__c> updatedTerrSegmentUsers, Map<Id, TM_Territory_Segment_Users__c> outdatedTerrSegmentUsers){
        try{
            if(TriggerHelper.DoExecute('TMTerritorySegmentUsersHelper','processUserChanges') && updatedTerrSegmentUsers != null){
                // GET QUALIFYING RECORDS
                for(TM_Territory_Segment_Users__c updatedTerrSegmentUser : updatedTerrSegmentUsers){
                    TM_Territory_Segment_Users__c outdatedTerrSegmentUser = outdatedTerrSegmentUsers != null ? outdatedTerrSegmentUsers.get(updatedTerrSegmentUser.Id) : null;
                    if(updatedTerrSegmentUser.Assigned_TM_UserId__c != null && (outdatedTerrSegmentUser == null ||
                                                                                updatedTerrSegmentUser.Assigned_TM_UserId__c != outdatedTerrSegmentUser.Assigned_TM_UserId__c || 
                                                                                updatedTerrSegmentUser.Applicable_Industries__c != outdatedTerrSegmentUser.Applicable_Industries__c)){
                        TerritoryManagementHelper.QualifyingTSUs.put(updatedTerrSegmentUser.Id, updatedTerrSegmentUser);
                        TerritoryManagementHelper.RolesQualifyingForUpdate.add(TerritoryManagementHelper.TMROLENAME);
                    }
                }

                // CREATE LIST OF SEGMENT UPDATES TO BE USED IN A COMPLETION EMAIL
                for(TM_Territory_Segment_Users__c updatedTerrSegmentUser : TerritoryManagementHelper.QualifyingTSUs.values()){
                    TM_Territory_Segment_Users__c outdatedTerrSegmentUser = outdatedTerrSegmentUsers != null ? outdatedTerrSegmentUsers.get(updatedTerrSegmentUser.Id) : null;

                    String hierarchy = updatedTerrSegmentUser.Territory_NameFx__c + ' - ' + updatedTerrSegmentUser.Segment_NameFx__c;
                    if(outdatedTerrSegmentUser != null){
                        List<String> stringFormatValues = new List<String>{ hierarchy, outdatedTerrSegmentUser.TM_User_NameFx__c, updatedTerrSegmentUser.TM_User_NameFx__c };
                        TerritoryManagementHelper.RecordUpdateInfo.get('Segment').add(String.format('The Assigned TM for segment "{0}" was changed from "{1}" to "{2}"', stringFormatValues));
                    }
                    else{
                        TerritoryManagementHelper.RecordUpdateInfo.get('Segment').add(String.format('Users and Industries added to segment "{0}"', new List<String>{ hierarchy }));
                    }
                }

                // GET RECORDS TO UPDATE AND EXECUTE BATCH IF THESE CHANGED -DID NOT- COME FROM THE MANAGEMENT PAGE
                if(!TerritoryManagementHelper.QualifyingTSUs.isEmpty() && !TerritoryManagementHelper.MadeThroughManagementPage){
                    // EXECUTE BATCH CLASS TO UPDATE RECORDS ASYNCHRONOUSLY
                    Database.executeBatch(new BatchableTerritoryManagement(TerritoryManagementHelper.QualifyingTSUs, null, true), (Test.isRunningTest() ? 5 : 1));
                }
                
                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritorySegmentUsersHelper', 'processUserChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritorySegmentUsersHelper', 'processUserChanges', updatedTerrSegmentUsers, ex, true);
        }
    }


}