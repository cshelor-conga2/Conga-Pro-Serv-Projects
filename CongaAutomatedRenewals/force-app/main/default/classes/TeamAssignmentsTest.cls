/**
* @author Joseph Markey
* @date 20171108
* @version 1.00
* @description TeamAssignmentsTest - Test class for the TeamAssignmentsUtilities class
*/
@isTest
public class TeamAssignmentsTest {

    /**
    * @description test_method_1 - 
    */
    public static testMethod void test_method_1() {
        // stage test data
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Conga Services User' LIMIT 1];

        User u = new User(
            Alias = 'standt',
            Email = 'salesforce@getconga.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'TestFirstName',
            IsActive = true,
            LastName = 'TestLastName',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Denver ',
            UserName = 'testUser'+UserInfo.getOrganizationId()+'@testorg.com'
        );
        insert u;

        PS_Project__c proj = new PS_Project__c(
            Is_Active__c = true
        );
        insert proj;

        Milestone__c m = new Milestone__c(
            Name = 'Test Milestone',
            ProjectId__c = proj.Id
        );
        insert m;

        Assignment__c a = new Assignment__c(
            Description__c = 'Test',
            Due_Date__c = System.Today(),
            MilestoneId__c = m.Id,
            OwnerId = u.Id,
            ProjectId__c = Proj.Id,
            Skill_Set__c = 'JavaScript',
            Subject__c = 'Test',
            Status__c = 'On hold',
            Time_Level_of_Effort__c = 'High'
        );
        insert a;

        // execute the test
        Test.startTest();

        List<Assignment__c> assignments = new List<Assignment__c>();
        assignments.add(a);
        // invoke test methods
        TeamAssignmentsUtilities.getAssignmentRecordTypes();
        TeamAssignmentsUtilities.getLevelOfEffort();
        TeamAssignmentsUtilities.getOpenAssignments('Professional Services ', 'Test', false);
        TeamAssignmentsUtilities.getAssignmentsByTeamMember();
        TeamAssignmentsUtilities.updateAssignments(assignments);

        Test.stopTest();
    }


}