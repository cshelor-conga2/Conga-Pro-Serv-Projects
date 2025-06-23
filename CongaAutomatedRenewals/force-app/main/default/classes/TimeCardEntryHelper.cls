/**
* @author CRMCulture, KSears
* @date 20181023
* @version 1.0
* @description TimeCardEntryHelper - Custom functionality for the Time_Card_Entry__c object
*/
public class TimeCardEntryHelper {

    /**
    * @author CRMCulture, KSears, eredding
    * @description rollUpWeeklyHours - Trigger fired to Calculate this and last week's times
    * @param List<Time_Card_Entry__c> newEntries
    * @return void 
    */
    public static void rollUpWeeklyHours(List<Time_Card_Entry__c> newEntries) {
        try{
            if(TriggerHelper.DoExecute('TimeCardEntryHelper','rollUpWeeklyHours') && newEntries != null){
                Set<Id> milestoneIds = new Set<Id>();
                for(Time_Card_Entry__c tce : newEntries){
                    milestoneIds.add(tce.MilestoneId__c);
                }

                Date myDate = Date.today();
                Date thisWeekStart = myDate.toStartofWeek();
                Date thisWeekEnd = thisWeekStart.addDays(7);
                Date lastWeekStart = thisWeekStart.addDays(-7);
                Date lastWeekEnd = lastWeekStart.addDays(7);

                // GET MILESTONES
                List<Milestone__c> milestoneList = [SELECT Id, Hours_Last_Week__c, Hours_This_Week__c FROM Milestone__c WHERE Id IN :milestoneIds];

                // GET TIME CARD ENTRIES
                Map<Id, List<Time_Card_Entry__c>> entriesByMilestone = new Map<Id, List<Time_Card_Entry__c>>();
                for(Time_Card_Entry__c entry : [SELECT Id, MilestoneId__c, Date_Entered__c, Hours_Entered__c FROM Time_Card_Entry__c WHERE MilestoneId__c IN :milestoneIds]){
                    if(entriesByMilestone.containsKey(entry.MilestoneId__c)){
                        entriesByMilestone.get(entry.MilestoneId__c).add(entry);
                    }
                    else{
                        entriesByMilestone.put(entry.MilestoneId__c, new List<Time_Card_Entry__c>());
                        entriesByMilestone.get(entry.MilestoneId__c).add(entry);
                    }
                }

                // CALCULATE HOURS OR SET TO 0 IF NO ENTRIES EXIST FOR A MILESTONE
                List<Milestone__c> updateMilestones = new List<Milestone__c>();
                if(!milestoneList.isEmpty()){
                    for(Milestone__c milestone : milestoneList){
                        if(entriesByMilestone.containsKey(milestone.Id) && !entriesByMilestone.get(milestone.Id).isEmpty()){
                            Decimal thisWeekHours = 0.0;
                            Decimal lastWeekHours = 0.0;
                            for(Time_Card_Entry__c timeEntry : entriesByMilestone.get(milestone.Id)){
                                if(timeEntry.Date_Entered__c >= thisWeekStart && timeEntry.Date_Entered__c <= thisWeekEnd){
                                    thisWeekHours = thisWeekHours + timeEntry.Hours_Entered__c;
                                }
                                if(timeEntry.Date_Entered__c >= lastWeekStart && timeEntry.Date_Entered__c <= lastWeekEnd){
                                    lastWeekHours = lastWeekHours + timeEntry.Hours_Entered__c;
                                }
                            }

                            milestone.Hours_This_Week__c = thisWeekHours;
                            milestone.Hours_Last_Week__c = lastWeekHours;
                            updateMilestones.add(milestone);
                        }
                        else{
                            milestone.Hours_This_Week__c = 0.0;
                            milestone.Hours_Last_Week__c = 0.0;
                            updateMilestones.add(milestone);
                        }
                    }

                    if(!updateMilestones.isEmpty()){
                        Database.saveResult[] milestoneResults = Database.update(updateMilestones, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(milestoneResults, 'TimeCardEntryHelper', 'rollUpWeeklyHours', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TimeCardEntryHelper', 'rollUpWeeklyHours');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TimeCardEntryHelper', 'rollUpWeeklyHours', newEntries, ex, true);
        }
    }

    /**
    * @author Systemyc, GModica
    * @date 20181205
    * @description intacctSyncTimeCardEntries - 
    * @param Map<Id, Time_Card_Entry__c> newMap
    * @param Map<Id, Time_Card_Entry__c> oldMap
    * @return void
    */
    public static void intacctSyncTimeCardEntries(Map<Id, Time_Card_Entry__c> newMap, Map<Id, Time_Card_Entry__c> oldMap) {
        try{
            if(TriggerHelper.DoExecute('TimeCardEntryHelper','intacctSyncTimeCardEntries') && newMap != null){
                IntacctSyncHelper.syncTimeCardEntries(newMap, oldMap);

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('TimeCardEntryHelper', 'intacctSyncTimeCardEntries');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('TimeCardEntryHelper', 'intacctSyncTimeCardEntries', newMap, ex, true);
        }
    }


}