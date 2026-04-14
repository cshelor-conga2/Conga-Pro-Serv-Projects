/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-23-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class APTS_GenerateAgreementDocumentBatch implements Database.Batchable<Apttus__APTS_Agreement__c>, Database.Stateful, Database.AllowsCallouts {
    //List<Apttus__APTS_Agreement__c> agreementsToUpdate, Map<string, string> recordTypeTemplateMap
    global Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c> agreementVersionMap;
    global List<Apttus__APTS_Agreement__c> agreementsToUpdate;
    global Map<string, string> recordTypeTemplateMap;

    public APTS_GenerateAgreementDocumentBatch(Map<Apttus__APTS_Agreement__c, Apttus__DocumentVersionDetail__c> agreementVersionMap, Map<string, string> recordTypeTemplateMap){
        this.agreementVersionMap = agreementVersionMap;
        this.agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
        agreementsToUpdate.addAll(agreementVersionMap.keySet());
        this.recordTypeTemplateMap = recordTypeTemplateMap;
    }

    public List<Apttus__APTS_Agreement__c> start(Database.BatchableContext context) {
        return agreementsToUpdate;
    }
    public void execute(Database.BatchableContext context, List<Apttus__APTS_Agreement__c> agreements) {
        string tsoRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('TSO').getRecordTypeId();
        try{
            Set<Id> setOfAgreementIds = new Set<Id>();
            String serverURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/55.0/' + UserInfo.getOrganizationId();
            for(Apttus__APTS_Agreement__c agreementSO: agreements)
            {
                ID agreementId = agreementSO.Id;
                ID templateId = recordTypeTemplateMap.get(agreementSO.RecordTypeId);
                string ndaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('NDA').getRecordTypeId();
                string msaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA').getRecordTypeId();
                //AK PSC-124 START
                string dpaRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('DPA').getRecordTypeId();

                String outputFormat = 'DOCX';
                if(agreementSO.RecordTypeId == ndaRecordTypeId || agreementSO.RecordTypeId == tsoRecordTypeId || agreementSO.RecordTypeId == dpaRecordTypeId ){
                    outputFormat = 'PDF';
                }
                //AK PSC-124 END
                Apttus__DocumentVersionDetail__c documentVersionDetail = agreementVersionMap.get(agreementSO);
                
                ID versionId = documentVersionDetail.Id; //copy from documentVersionDetail.Id from above call
                String pLevel = 'Insert comments and tracked changes only';
                Boolean isDraft = false;
                String sessionId =  UserInfo.getSessionId();
                setOfAgreementIds.add(agreementSO.Id);
                if(!Test.isRunningTest()){
                    Apttus.AgreementGenerateController c = new Apttus.AgreementGenerateController(new ApexPages.StandardController(agreementSO));   
                    c.generateDoc(templateId,   pLevel,  outputFormat, isDraft, versionId, sessionId, serverUrl);
                }
                if(agreementSO.RecordTypeId == ndaRecordTypeId || agreementSO.RecordTypeId == tsoRecordTypeId || agreementSO.RecordTypeId == dpaRecordTypeId){
                    CopyFileToAgreement(agreementSO.Id);
                }
            }
            List<Apttus__DocumentVersion__c> listOfDocumentVersions = [SELECT Id,OwnerId,Apttus__AgreementId__c,Apttus__AgreementId__r.OwnerId
                                                                       FROM Apttus__DocumentVersion__c
                                                                       WHERE Apttus__AgreementId__c 
                                                                       IN :setOfAgreementIds];
            
            if(listOfDocumentVersions != null)
            {
                for(Apttus__DocumentVersion__c oDcoumentVersion : listOfDocumentVersions)
                {
                    oDcoumentVersion.OwnerId = oDcoumentVersion.Apttus__AgreementId__r.OwnerId;
                }
                update listOfDocumentVersions;
            }
        } 
        catch(Exception ex){
            system.debug('@@Exception in DocGen');
            system.debug(ex);
        }
        List<Apttus__APTS_Agreement__c> agrToUpdate = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c agr: agreements){
            Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
            agreement.Id = agr.Id;
            agreement.APTS_DocGeninProgress__c = false;
            agreement.APTS_AutoGenerateComplete__c = true;
            agrToUpdate.add(agreement);
        }
        update agrToUpdate;
  }
  public void finish(Database.BatchableContext context) {
        
  }


    public void CopyFileToAgreement(string agreementId){
        //Insert ContentDocumentLink
        Apttus__DocumentVersionDetail__c dvd = [select Id, Apttus__Title__c, Apttus__ContentId__c from Apttus__DocumentVersionDetail__c where Apttus__DocumentVersionId__r.Apttus__AgreementId__c = :agreementId limit 1];
        // CopyFileToAgreement(dvd.Apttus__ContentId__c, agreementSO.Id);
        ContentVersion originalCV=[select id,ContentDocumentId,versiondata from Contentversion where ContentDocumentId=:dvd.Apttus__ContentId__c];
        Blob fileData = originalCV.VersionData;
        string base64 = EncodingUtil.base64Encode(fileData);

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = dvd.Apttus__Title__c;
        cv.PathOnClient = dvd.Apttus__Title__c;
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = agreementId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
    
}