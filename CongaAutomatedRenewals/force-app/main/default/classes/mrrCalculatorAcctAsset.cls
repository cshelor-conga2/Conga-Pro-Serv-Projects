/**
* @author BSI, BSpencer
* @date 20160720
* @version 1.0
* @description mrrCalculatorAcctAsset - 
*/
public class mrrCalculatorAcctAsset {
    //public static final String ERROR_EMAIL_RECIPIENT_SALESFORCE_ID = '00537000000M2CWAA0';

    /**
    * @description calculateMRR - 
    * @param Set<Id> accountIds
    * @return void
    */
    public static void calculateMRR(Set<Id> accountIds) {
        Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>([SELECT Id, Name, mrr_Active_MRR__c, mrr_Data_MRR__c, mrr_DocMerge_MRR__c, mrr_Contracts_MRR__c, 
                                                                       mrr_Services_MRR__c, mrr_Reseller_MRR__c, mrr_eSignature_MRR__c, mrr_Workflow_MRR__c 
                                                                       FROM Account WHERE Id IN :accountIds]);

        if(accountIdToAccountMap.isEmpty()) return;

        List<Asset> assets = [SELECT Id, AccountId, mrr_Asset_MRR__c, Product2.LOB__c FROM Asset WHERE Entitlement_Status__c = 'Active' AND AccountId IN :accountIds];

        Map<Id,AccountMRRInfo> accountIdToMRRInfoMap = new Map<Id,AccountMRRInfo>();
        for(Id accountId : accountIdToAccountMap.keySet()) {
            accountIdToMRRInfoMap.put(accountId, new AccountMRRInfo(accountId));
        }

        for(Asset asset : assets) {
            AccountMRRInfo mrrInfo = accountIdToMRRInfoMap.get(asset.AccountId);

            mrrInfo.ActiveMRR += isNull(asset.mrr_Asset_MRR__c,0);

            if(asset.Product2.LOB__c == 'Data') {
                mrrInfo.DataMRR += isNull(asset.mrr_Asset_MRR__c,0);
            }
            else if(asset.Product2.LOB__c == 'DocMerge') {
                mrrInfo.DocMergeMRR += isNull(asset.mrr_Asset_MRR__c,0);
            }
            else if(asset.Product2.LOB__c == 'Contracts') {
                mrrInfo.ContractsMRR += isNull(asset.mrr_Asset_MRR__c,0);
            }
            else if(asset.Product2.LOB__c == 'Services') {
                mrrInfo.ServicesMRR += isNull(asset.mrr_Asset_MRR__c,0);
            }
            else if(asset.Product2.LOB__c == 'Reseller') {
                mrrInfo.ResellerMRR += isNull(asset.mrr_Asset_MRR__c,0);
            }
            else if(asset.Product2.LOB__c == 'eSignature') {
                mrrInfo.ESignatureMRR += isNull(asset.mrr_Asset_MRR__c,0);
            }
            else if(asset.Product2.LOB__c == 'Workflow') {
                mrrInfo.WorkflowMRR += isNull(asset.mrr_Asset_MRR__c,0);
            }
        }

        // detect only accounts that changed
        Set<Id> accountIdsToUpdate = new Set<Id>();
        for(Id accountId : accountIds) {
            Account account = accountIdToAccountMap.get(accountId);
            AccountMRRInfo mrrInfo = accountIdToMRRInfoMap.get(accountId);
            if(account == null || mrrInfo == null) continue;

            if(account.mrr_Active_MRR__c != mrrInfo.ActiveMRR && (account.mrr_Active_MRR__c != null || mrrInfo.ActiveMRR != 0)) {
                account.mrr_Active_MRR__c = mrrInfo.ActiveMRR;
                accountIdsToUpdate.add(accountId);
            }
            if(account.mrr_Data_MRR__c != mrrInfo.DataMRR && (account.mrr_Data_MRR__c != null || mrrInfo.DataMRR != 0)) {
                account.mrr_Data_MRR__c = mrrInfo.DataMRR;
                accountIdsToUpdate.add(accountId);
            }
            if(account.mrr_DocMerge_MRR__c != mrrInfo.DocMergeMRR && (account.mrr_DocMerge_MRR__c != null || mrrInfo.DocMergeMRR != 0)) {
                account.mrr_DocMerge_MRR__c = mrrInfo.DocMergeMRR;
                accountIdsToUpdate.add(accountId);
            }
            if(account.mrr_Contracts_MRR__c != mrrInfo.ContractsMRR && (account.mrr_Contracts_MRR__c != null || mrrInfo.ContractsMRR != 0)) {
                account.mrr_Contracts_MRR__c = mrrInfo.ContractsMRR;
                accountIdsToUpdate.add(accountId);
            }
            if(account.mrr_Services_MRR__c != mrrInfo.ServicesMRR && (account.mrr_Services_MRR__c != null || mrrInfo.ServicesMRR != 0)) {
                account.mrr_Services_MRR__c = mrrInfo.ServicesMRR;
                accountIdsToUpdate.add(accountId);
            }
            if(account.mrr_Reseller_MRR__c != mrrInfo.ResellerMRR && (account.mrr_Reseller_MRR__c != null || mrrInfo.ResellerMRR != 0)) {
                account.mrr_Reseller_MRR__c = mrrInfo.ResellerMRR;
                accountIdsToUpdate.add(accountId);
            }
            if(account.mrr_eSignature_MRR__c != mrrInfo.ESignatureMRR && (account.mrr_eSignature_MRR__c != null || mrrInfo.ESignatureMRR != 0)) {
                account.mrr_eSignature_MRR__c = mrrInfo.ESignatureMRR;
                accountIdsToUpdate.add(accountId);
            }
            if(account.mrr_Workflow_MRR__c != mrrInfo.WorkflowMRR && (account.mrr_Workflow_MRR__c != null || mrrInfo.WorkflowMRR != 0)) {
                account.mrr_Workflow_MRR__c = mrrInfo.WorkflowMRR;
                accountIdsToUpdate.add(accountId);
            }
        }       

        List<Account> accountsToUpdate = new List<Account>();
        for(Id accountId : accountIdsToUpdate) {
            Account account = accountIdToAccountMap.get(accountId);
            accountsToUpdate.add(account);
        }
        
        if(!accountsToUpdate.isEmpty()){
            //if(Test.isRunningTest() && accountsToUpdate[0].Name == 'ERROR') accountsToUpdate[0].Name = null; /// if this is a test, force an error

            //System.debug('accountToUpdate: ' + accountsToUpdate);

            // Using partial processing with error handling so that end users are not interrupted by a record update failing.
            Database.saveResult[] saveResults = Database.update(accountsToUpdate, false);
            SystemIssueLogHelper.CheckForDatabaseErrors(saveResults, 'mrrCalculatorAcctAsset', 'calculateMRR', false);
                        
            //Boolean areThereErrors = false;
            //for (Database.saveResult result : saveResults)
            //{
            //    if (!result.isSuccess()) {
            //        areThereErrors = true;
            //        break;
            //    }
            //}

            //if(areThereErrors) {
            //    Contact[] contacts = [select Id, Email from Contact where Salesforce_User_Id__c = :ERROR_EMAIL_RECIPIENT_SALESFORCE_ID];
            //    if(contacts.size() > 0) {
                    
            //        String fromAddress = contacts[0].Email;
            //        List<String> toAddresses = new List<String>{ fromAddress };
            //        String subject = 'Error Updating records in mrrCalculatorAcctAsset class';
            //        String body = '';
            //        String targetObjectId = contacts[0].Id;

            //        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

            //        for (Database.saveResult result : saveResults)
            //        {
            //            if (!result.isSuccess())
            //            {
            //                body += 'Id = ' + result.getId() + '\n\n' + result.getErrors() + '\n\n';
            //                System.debug('Error: ' + body);
            //                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            //                email.setTargetObjectId(targetObjectId);
            //                email.setReplyTo(fromAddress);
            //                email.setSubject(subject);
            //                email.setPlainTextBody(body);
            //                messages.add(email);
            //            }
            //        }

            //        if(!messages.isEmpty() && !Test.isRunningTest()) Messaging.sendEmail(messages);
            //    }
            //}             
        }
    }

    /**
    * @description isNull - 
    * @param Decimal amount
    * @param Decimal defaultValue
    * @return Decimal
    */
    private static Decimal isNull(Decimal amount, Decimal defaultValue) {
        if(amount == null){
            return defaultValue;
        }
        return amount;
    }

    /**
    * @description class AccountMRRInfo - Wrapper Class
    */
    private class AccountMRRInfo {
        public Id AccountId = null;
        public Decimal ActiveMRR = 0;
        public Decimal DataMRR = 0;
        public Decimal DocMergeMRR = 0;
        public Decimal ContractsMRR = 0;
        public Decimal ServicesMRR = 0;
        public Decimal ResellerMRR = 0;
        public Decimal ESignatureMRR = 0;
        public Decimal WorkflowMRR = 0;

        /**
        * @description AccountMRRInfo - Constructor
        * @param Id accountId
        */
        public AccountMRRInfo(Id accountId) {
            this.AccountId = accountId;
        }
    }


}