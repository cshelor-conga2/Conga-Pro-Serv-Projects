/**
* @author Jereriah Manning
* @date 20170205
* @version 1.00
* @description UpdateCongaUsageEstablishingPartner2 - Created for Conga Partner Team
*/
public class UpdateCongaUsageEstablishingPartner2 {

    /**
    * @description UpdateCongaUsageEstablishingPartner2 - Constructor, does nothing
    */
    public UpdateCongaUsageEstablishingPartner2(){

    }

    /**
    * @description updateCongaUsageHistoryRecords - 
    * @return void
    */
    public static void updateCongaUsageHistoryRecords(){
        List<Conga_Usage_History2__c> cuhUpdateList = new List<Conga_Usage_History2__c>();
        List<Conga_Usage_History2__c> cuhRecordsToUpdate = [SELECT Id, Salesforce_Org__r.Establishing_Partner__c, Account_for_BLU_Report__c, Salesforce_Org__r.Account__c 
                                                            FROM Conga_Usage_History2__c
                                                            WHERE Month__c = LAST_MONTH
                                                            AND Salesforce_Org__r.Establishing_Partner__c != null 
                                                            AND Salesforce_Org__r.Establishing_Partner__c != '' 
                                                            LIMIT 10000];
        
        //System.Debug('*************** cuhRecordsToUpdate.size: ' + cuhRecordsToUpdate.size());
        
        for(Conga_Usage_History2__c cuh : cuhRecordsToUpdate){
            //System.Debug('*************** cuh in For loop: ' + cuh);            
            
            cuh.Establishing_Partner__c = cuh.Salesforce_Org__r.Establishing_Partner__c;   
            if(cuh.Salesforce_Org__r.Account__c != null){
                cuh.Account_For_BLU_Report__c = cuh.Salesforce_Org__r.Account__c;        
            }            
            cuhUpdateList.add(cuh);
        }
        //System.Debug('*************** cuhUpdateList.size: ' + cuhUpdateList.size());

        Database.update(cuhUpdateList);
    }


}