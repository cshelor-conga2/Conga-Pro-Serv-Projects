/**
* @author Joseph Markey
* @date 20171108
* @version 1.00
* @description TeamAssignmentsUtilities - Describes the TeamAssignmentsUtilities class 
*/
public with sharing class TeamAssignmentsUtilities {
    public String userType {get;set;}

    /**
    * @description TeamAssignmentsUtilities - Constructor
    */
    public TeamAssignmentsUtilities(){  
        Id currentUserId = UserInfo.getUserId();
        List<User> users = [SELECT Id, Name, FirstName, LastName, IsActive, Team__c FROM User WHERE Id = :currentUserId LIMIT 1];   
        if(!users.isEmpty()){
            userType = users[0].Team__c;
        }
    }

    /**
    * @description class TeamMemberAssignment - 
    */
    public class TeamMemberAssignment {
        public User thisUser {get;set;}
        public List<Assignment__c> assignments {get;set;}
        public TeamMemberAssignment(User pThisUser, List<Assignment__c> pAssignments) {
            this.thisUser = pThisUser;
            this.assignments = pAssignments;
        }
    }

    //@RemoteAction
    //public static List<User> getOwners() {
    //  return [
 //         SELECT Id, Name, FirstName, LastName, IsActive
 //         FROM User
 //         WHERE  IsActive = true AND (Profile.Name = 'System Administrator' OR Profile.Name = 'Conga Services User')
 //         ORDER BY FirstName ASC
 //         LIMIT 10000
 //     ];
    //}

    /**
    * @description getAssignmentRecordTypes - 
    * @return List<String>
    */
    @RemoteAction
    public static List<String> getAssignmentRecordTypes() {
        String objectAPIName = 'Assignment__c' ;   
        List<String> options = new List<String>();
        List<RecordType> assignmentTypes = new List<RecordType>();

        assignmentTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Assignment__c'];
        for(RecordType info : assignmentTypes){
            options.add(info.Name);
        }
        return options;
    }


    //@RemoteAction 
    //public static List<String> getProjectManagers() {
    //    List<String> options = new List<String>();
    //    Schema.DescribeFieldResult fieldResult = Assignment__c.Status__c.getDescribe();
    //    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    //    for(Schema.PicklistEntry pickListVal : ple) {
    //        options.add(pickListVal.getLabel());
    //    }
        
    //    return options;
    //}

    /**
    * @description getLevelOfEffort - 
    * @return List<String>
    */
    @RemoteAction 
    public static List<String> getLevelOfEffort() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Assignment__c.Time_Level_of_Effort__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple) {
            if(pickListVal.getLabel() != 'Complete' && pickListVal.getLabel() != 'In Progress') {
                options.add(pickListVal.getLabel());
            }
        }
        
        return options;
    }

    /**
    * @description getOpenAssignments -
    * @param String assignmentRecordType
    * @param String pLevelOfEffort
    * @param Boolean isOverflow
    * @return List<Assignment__c>
    */
    @RemoteAction
    public static List<Assignment__c> getOpenAssignments(String assignmentRecordType, String pLevelOfEffort, Boolean isOverflow) {
        String strAnd = '';
        String orderBy = '';
        if(String.isNotBlank(assignmentRecordType) && isOverflow == false) {
            strAnd += ' AND RecordType.Name = :assignmentRecordType';
        }
        if(String.isNotBlank(assignmentRecordType) && isOverflow != false) {
            strAnd += ' AND (RecordType.Name = :assignmentRecordType OR IsOverflow__c = true)';
        }
        if(String.isNotBlank(pLevelOfEffort)) {
            strAnd += ' AND Time_Level_of_Effort__c = :pLevelOfEffort';
        }
        if(assignmentRecordType == 'Professional Services'){
            orderBy += '  RecordType.Name DESC, ';
        }
        if(assignmentRecordType == 'Business Systems'){
            orderBy += ' RecordType.Name ASC, ';
        }
        orderBy += ' IsOverflow__c ASC';
        String soql = 'SELECT Id, Name, AccountFx__c, IsOverflow__c, RecordType.Name, Description__c, Due_Date__c, MilestoneId__r.Name, OwnerId, Owner.Name, Priority__c, ProjectId__r.Name, Project_ManagerFX__c, Skill_Set__c, Subject__c, Status__c, Time_Level_of_Effort__c'+
            ' FROM Assignment__c'+
            ' WHERE (Status__c = \'Backlog\' OR Status__c = \'Not Yet Started - BSI\') '+strAnd+
            ' ORDER BY '+ orderBy +
            ' LIMIT 10000';
        return Database.query(soql);
    }

    /**
    * @description getAssignmentsByTeamMember - 
    * @return List<TeamMemberAssignment>
    */
    @RemoteAction
    public static List<TeamMemberAssignment> getAssignmentsByTeamMember() {
        Id currentUserId = UserInfo.getUserId();
        List<TeamMemberAssignment> tmas = new List<TeamMemberAssignment>();
        List<Assignment__c> allAssignments = new List<Assignment__c>();
        List<Assignment__c> assignments = new List<Assignment__c>();
        List<Id> userIds = new List<Id>();
        List<User> users = new List<User>();
        List<User> usersQ = [
            SELECT Id, Name, FirstName, LastName, IsActive, Team__c
            FROM User
            WHERE  IsActive = true AND (Team__c = 'Professional Services' OR Team__c = 'Business Systems')
            ORDER BY FirstName ASC
            LIMIT 10000
        ];

        for(User u : usersQ){
            if(u.Id == currentUserId){
                users.add(u);
            }
        }
        for(User u : usersQ){
            if(u.Id != currentUserId){
                users.add(u);
            }
        }        
        //(Profile.Name = 'System Administrator' OR Profile.Name = 'Conga Services User')
        for(User u : users) {
            userIds.add(u.Id);
        }

        allAssignments = [
            SELECT Id, Name, AccountFx__c, Description__c, Due_Date__c, MilestoneId__r.Name, OwnerId, Owner.Name, Priority__c, ProjectId__r.Name, Project_ManagerFX__c, Skill_Set__c, Subject__c, Status__c, Time_Level_of_Effort__c
            FROM Assignment__c
            WHERE Status__c != 'Backlog' AND Status__c != 'Complete'
                AND OwnerId IN :userIds
            ORDER BY Priority__c ASC
            LIMIT 10000
        ];

        for(User u : users) {
            assignments = new List<Assignment__c>();
            for(Assignment__c a : allAssignments) { 
                if(u.Id==a.OwnerId) {
                    assignments.add(a);
                }
            }
            tmas.add(new TeamMemberAssignment(u, assignments));
        }

        return tmas;
    }

    /**
    * @description updateAssignments - 
    * @param List<Assignment__c> pAssignments
    * @return void
    */
    @RemoteAction
    public static void updateAssignments(List<Assignment__c> pAssignments) {
        update pAssignments;
    }


}