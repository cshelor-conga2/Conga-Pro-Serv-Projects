/**
* @author Conga Services, KSears
* @date 20190319
* @version 1.00
* @description SupportRequestRedirectController Redirects support requests after the record type selection
*/
public with sharing class SupportRequestRedirectController {

    /** 
    * @description SupportRequestRedirectController - Constructor 
    * @param ApexPages.StandardController stdController
    */
    public SupportRequestRedirectController(ApexPages.StandardController stdController) {
    }

    /** 
    * @description redirect 
    * @return PageReference
    */
    public PageReference redirect() {
        String rtId = apexpages.currentpage().getparameters().get('RecordType');
        if(rtId != null){
            Map<Id, Schema.RecordTypeInfo> recordType = Schema.SObjectType.Support_Request__c.getRecordTypeInfosById();//[SELECT Id, Name FROM RecordType WHERE Id = :rtId LIMIT 1];
            if(!recordType.isEmpty()){
                if(recordType.containsKey(rtId) && recordType.get(rtId).Name != 'Salesforce Support Request'){
                    PageReference outpage = new PageReference('/a1a/e?retURL=%2Fa1a%2Fo');
                    outpage.getParameters().put('RecordType', rtId);

                    for(String key : System.currentPageReference().getParameters().keySet()){
                        if(!key.equalsIgnoreCase('view') && !key.equalsIgnoreCase('sfdc.override') && !key.equalsIgnoreCase('id')) {
                            outpage.getParameters().put(key, System.currentPageReference().getParameters().get(key));
                        }
                    }

                    outpage.getParameters().remove('save_new');
                    outpage.getParameters().put('nooverride','1');
                    outpage.setRedirect(true);   
                    return outpage; 
                }
                else{
                    PageReference outpage = new PageReference('/apex/SupportRequestWizard');
                    outpage.setRedirect(true);   
                    return outpage; 
                }
            }
        }
        else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Info,'Please select a Record Type'));
        }
        return null;
    }


}