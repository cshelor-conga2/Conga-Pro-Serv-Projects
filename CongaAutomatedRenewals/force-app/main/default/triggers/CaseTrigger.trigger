/**
* @author Conga Services
* @date 20181019
* @version 1.00
* @param Any platform trigger event for the Case object
*/ 
trigger CaseTrigger on Case (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Case.sObjectType);


    ///////////////// CONGA SERVICES ER 20181019 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
    //TriggerDispatcher.execute(Case.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    
    /////////// CODE MOVED TO CaseHelper CLASS
    //Map<Id, Decimal> acctIdsandBilledHours = new Map<Id, Decimal>();
    //List<Account> updateAccountList = new List<Account>();
    //List<Id> accounts = new List<Id>();

    //if (trigger.isBefore)
    //{
    //    for (Case mycase: Trigger.new)
    //    {
    //        if((mycase.FPR__c != NULL && mycase.BusinessHoursId !=NULL))
    //        {
    //            mycase.Time_to_FPR_Business_Hours__c = (((Double)(BusinessHours.diff (mycase.BusinessHoursId, mycase.CreatedDate, mycase.FPR__c)) / 3600000));
    //        }

    //        if((mycase.Date_Time_Assigned__c != NULL && mycase.BusinessHoursId !=NULL))
    //        {
    //            mycase.Time_to_Assignment_Hours__c = (((Double)(BusinessHours.diff (mycase.BusinessHoursId, mycase.CreatedDate, mycase.Date_Time_Assigned__c)) / 3600000));
    //        }
    //    }
    //}

    ////Logic to roll-up Billable Hours from Cases to Account. Cannot do this in standard roll-up summary field. 
    //if(trigger.isAfter)
    //{
    //    List<Case> cases = new List<Case>();

    //    //Cannot access trigger.new in after delete trigger context
    //    if (trigger.isDelete)
    //    {
    //        for (Case c : trigger.Old)
    //        {
    //            cases.add(c);
    //            system.debug('cases = ' + cases);
    //        }
    //    }
    //    else
    //    {
    //        for (Case c : trigger.new)
    //        {
    //            cases.add(c);
    //            system.debug('cases = ' + cases);
    //        }
    //    }
    //    for (case c : cases)
    //    {
    //        if (trigger.isInsert || trigger.isDelete || (trigger.isUpdate  && (trigger.oldMap.get(c.Id).Billable_Time_Hours__c != c.Billable_Time_Hours__c)))
    //        {
    //            AggregateResult [] groupedResult = [SELECT AccountId, SUM(Billable_Time_Hours__c)billedHours FROM CASE WHERE In_Current_Subscription__c = TRUE AND AccountId =: c.AccountId GROUP BY AccountId];
    //            system.debug('groupedResult = ' + groupedResult);

    //            if (!groupedResult.isEmpty())
    //            {
    //                for (AggregateResult ar : groupedResult)
    //                {
    //                    acctIdsandBilledHours.put((ID)ar.get('AccountId'), (Decimal)ar.get('billedHours'));
    //                    system.debug('acctIdsandBilledHours = ' + acctIdsandBilledHours);
    //                }
    //            }
    //            //Logic to handle all Cases associated with Account being deleted - want to zero out Billable_Time_Current_Subscription, but it no rows are returned in aggregate 
    //            else
    //            {
    //                acctIdsandBilledHours.put((ID)c.AccountId, 0);
    //                system.debug('acctIdsandBilledHours = ' + acctIdsandBilledHours);
    //            }
    //        }
    //    }
    //}

    //if (!acctIdsandBilledHours.isEmpty())
    //{
    //    for (Account a : [SELECT Id, Billable_Time_Current_Subscription__c FROM Account WHERE Id IN : acctIdsandBilledHours.keyset()])
    //    {
    //        a.Billable_Time_Current_Subscription__c = acctIdsandBilledHours.get(a.Id);
    //        system.debug('a.Billable_Time_Current_Subscription__c = ' + a.Billable_Time_Current_Subscription__c);
    //        updateAccountList.add(a);
    //        system.debug('updateAccountList = ' + updateAccountList);
    //    }
    //}

    //Database.saveResult[] acctResults = Database.update(updateAccountList, false);
    //system.debug('acctResults = ' + acctResults);

    //String subject = 'Error Updating Account Billable_Time_Current_Subscription__c';
    //String [] toAddresses = new String [] {'bspencer@appextremes.com'};
    //String body = '';
    //String fromAddress = 'bspencer@appextremes.com';
    
    //for (Database.saveResult res : acctResults)
    //{
    //    if (!res.isSuccess())
    //    {
    //        body += 'Id = ' + res.getId() + '\n\n' + res.getErrors() + '\n\n';
    //        handyMethods.sendErrorEmails(toAddresses, fromAddress, subject, body);
    //    }
    //}


}