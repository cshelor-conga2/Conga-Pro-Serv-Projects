/**
* @author Stas Daszkiewicz
* @date 20190107
* @version 1.0
* @description RenewalQuoteFromOpportunityController - Controller for the renewalQuote VF Page
*/
global class RenewalQuoteFromOpportunityController {

    /**
    * @description RenewalQuoteFromOpportunityController - Constructor
    * @param ApexPages.StandardController stdController
    */
    public RenewalQuoteFromOpportunityController(ApexPages.StandardController stdController) {
    }

    /**
    * @description webservice static generateRenewalQuote - 
    * @param Id opportunityId
    * @return String
    */
    @RemoteAction
    webservice static String generateRenewalQuote(Id opportunityId) {
        List<Opportunity> renewalOpps = [SELECT Id, SBQQ__Renewal__c, SBQQ__RenewedContract__c FROM Opportunity WHERE Id = :opportunityId];
        if(renewalOpps.size() > 0) {
            if(!renewalOpps[0].SBQQ__Renewal__c) {
                return 'Renewal quote can only be generated on Renewal opportunities.';
            }

            if(renewalOpps[0].SBQQ__RenewedContract__c == null) {
                return 'Renewed Contract is required.';
            }
            else{
                List<Contract> renewalContract = [SELECT Id, SBQQ__RenewalQuoted__c FROM Contract WHERE Id = :renewalOpps[0].SBQQ__RenewedContract__c];
                if(renewalContract.size() > 0) {
                    if(!renewalContract[0].SBQQ__RenewalQuoted__c) {
                        renewalContract[0].SBQQ__RenewalQuoted__c = TRUE;
                        update renewalContract;

                        renewalContract[0].SBQQ__RenewalQuoted__c = FALSE;
                        update renewalContract;
                        return 'Successfully generated renewal quote.';
                    }
                    
                    if (renewalContract[0].SBQQ__RenewalQuoted__c == TRUE) {
                        renewalContract[0].SBQQ__RenewalQuoted__c = FALSE;
                        update renewalContract;

                        renewalContract[0].SBQQ__RenewalQuoted__c = TRUE;
                        update renewalContract;
                        return 'Successfully generated renewal quote.';
                    }
                }
            }    
        }
        return null;
    }


}