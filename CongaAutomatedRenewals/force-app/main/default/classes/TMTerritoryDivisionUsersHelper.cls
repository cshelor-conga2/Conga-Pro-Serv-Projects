/**
* @author ECS, ERedding
* @date 20200124
* @version 1.00
* @description TMTerritoryDivisionUsersHelper - Custom functionality for the TM_Territory_Division_Users__c Custom Object
*/
public with sharing class TMTerritoryDivisionUsersHelper {

    /**
    * @description processUserChanges - 
    * @param List<TM_Territory_Division_Users__c> updatedTerrDivisionUsers
    * @param Map<Id, TM_Territory_Division_Users__c> outdatedTerrDivisionUsers
    * @return void
    */
    public static void processUserChanges(List<TM_Territory_Division_Users__c> updatedTerrDivisionUsers, Map<Id, TM_Territory_Division_Users__c> outdatedTerrDivisionUsers){
        try{
            if(TriggerHelper.DoExecute('TMTerritoryDivisionUsersHelper','processUserChanges') && updatedTerrDivisionUsers != null && outdatedTerrDivisionUsers != null){
                // GET QUALIFYING USER TERRITORY RECORDS
                for(TM_Territory_Division_Users__c updatedTerrDivisionUser : updatedTerrDivisionUsers){
                    TM_Territory_Division_Users__c outdatedTerrDivisionUser = outdatedTerrDivisionUsers != null ? outdatedTerrDivisionUsers.get(updatedTerrDivisionUser.Id) : null;
                    if(outdatedTerrDivisionUser != null){
                        // CATCH CSM CHANGE
                        if(updatedTerrDivisionUser.Assigned_CSM_UserId__c != null && updatedTerrDivisionUser.Assigned_CSM_UserId__c != outdatedTerrDivisionUser.Assigned_CSM_UserId__c){
                            TerritoryManagementHelper.QualifyingTDUs.put(updatedTerrDivisionUser.Id, updatedTerrDivisionUser);
                            TerritoryManagementHelper.RolesQualifyingForUpdate.add(TerritoryManagementHelper.CSMROLENAME);

                        }
                        // CATCH RM CHANGE
                        if(updatedTerrDivisionUser.Assigned_RM_UserId__c != null && updatedTerrDivisionUser.Assigned_RM_UserId__c != outdatedTerrDivisionUser.Assigned_RM_UserId__c){
                            TerritoryManagementHelper.QualifyingTDUs.put(updatedTerrDivisionUser.Id, updatedTerrDivisionUser);
                            TerritoryManagementHelper.RolesQualifyingForUpdate.add(TerritoryManagementHelper.RMROLENAME);
                        }
                    }
                }

                // CREATE LIST OF DIVISION UPDATES TO BE USED IN A COMPLETION EMAIL
                for(TM_Territory_Division_Users__c updatedTerrDivisionUser : TerritoryManagementHelper.QualifyingTDUs.values()){
                    TM_Territory_Division_Users__c outdatedTerrDivisionUser = outdatedTerrDivisionUsers != null ? outdatedTerrDivisionUsers.get(updatedTerrDivisionUser.Id) : null;
                    String hierarchy = updatedTerrDivisionUser.Territory_NameFx__c + ' - ' + updatedTerrDivisionUser.Division_NameFx__c;
                    
                    if(updatedTerrDivisionUser.Assigned_CSM_UserId__c != outdatedTerrDivisionUser.Assigned_CSM_UserId__c){
                        List<String> stringFormatValues = new List<String>{ hierarchy, outdatedTerrDivisionUser.CSM_User_NameFx__c, updatedTerrDivisionUser.CSM_User_NameFx__c };
                        TerritoryManagementHelper.RecordUpdateInfo.get('Division').add(String.format('The CSM User for division "{0}" was changed from "{1}" to "{2}"', stringFormatValues));
                    }
                    if(updatedTerrDivisionUser.Assigned_RM_UserId__c != outdatedTerrDivisionUser.Assigned_RM_UserId__c){
                        List<String> stringFormatValues = new List<String>{ hierarchy, outdatedTerrDivisionUser.RM_User_NameFx__c, updatedTerrDivisionUser.RM_User_NameFx__c };
                        TerritoryManagementHelper.RecordUpdateInfo.get('Division').add(String.format('The RM User for division "{0}" was changed from "{1}" to "{2}"', stringFormatValues));
                    }
                }

                // GET RECORDS TO UPDATE AND EXECUTE BATCH IF THESE CHANGED -DID NOT- COME FROM THE MANAGEMENT PAGE
                if(!TerritoryManagementHelper.QualifyingTDUs.isEmpty() && !TerritoryManagementHelper.MadeThroughManagementPage){
                    // EXECUTE BATCH CLASS TO UPDATE RECORDS ASYNCHRONOUSLY
                    Database.executeBatch(new BatchableTerritoryManagement(null, TerritoryManagementHelper.QualifyingTDUs, true), (Test.isRunningTest() ? 5 : 1));
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TMTerritoryDivisionUsersHelper', 'processUserChanges');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TMTerritoryDivisionUsersHelper', 'processUserChanges', updatedTerrDivisionUsers, ex, true);
        }
    }

}