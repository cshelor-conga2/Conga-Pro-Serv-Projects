//test class: OppTerrAssignDefaultLogicFiltertest

@istest
public class OppTerrAssignDefaultLogicFiltertest{
public static testmethod void oppTerrAssigntest(){

Id subsOwnerId = '00550000006uj0HAAQ';
Set<id> acclistid=new Set<id>();
Account acc =new Account(name='testaccount',OwnerId = subsOwnerId);
insert acc;
acclistid.add(acc.id);

contact con = new contact();
        con.LastName= 'Test Contact';
        con.accountId = acc.id;  
        con.Email = 'test@testemail.com';  
        insert con;
        system.debug('con-- '+con);

Id directRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Direct').getRecordTypeId();
Id indirectRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Indirect').getRecordTypeId();
List<id> opplistid=new List<id>();

Opportunity directOpp = new Opportunity();
directOpp.Name ='testopporunityDirect';
directOpp.StageName = '0 - Qualification';
directOpp.RecordTypeId =  directRecTypeId;
directOpp.AccountId = acc.Id;
directOpp.CloseDate = Date.newInstance(2020, 12, 12);
directOpp.type='New Business - New Logo';
insert directOpp;
opplistid.add(directOpp.id);

Opportunity indirectOpp = new Opportunity();
indirectOpp.Name ='testopporunityIndirect';
indirectOpp.StageName = '0 - Qualification';
indirectOpp.RecordTypeId =  indirectRecTypeId;
indirectOpp.AccountId = acc.Id;
indirectOpp.CloseDate = Date.newInstance(2020, 12, 12);
indirectOpp.type='New Business - New Logo';

insert indirectOpp;
opplistid.add(indirectOpp.id);

OppTerrAssignDefaultLogicFilter CheckOppty=new OppTerrAssignDefaultLogicFilter();
Map<Id,Id> mapid=CheckOppty.getOpportunityTerritory2Assignments(opplistid);
Id modelId=CheckOppty.getActiveModelId();
Map<Id, Id> MapTerritory=CheckOppty.getAccountSalesRepTerritory(modelId, acclistid);

}
}