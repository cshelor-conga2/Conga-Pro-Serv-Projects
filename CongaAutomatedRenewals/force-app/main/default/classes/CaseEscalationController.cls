public class CaseEscalationController {
	@AuraEnabled
    public static Settings getSettings() {
        Settings s = new Settings();
        
        List<Case_Escalation_Settings__mdt> metadataSettings = [select Id,Email__c,Outage_Template_Id__c,CETID__c,Template_Group__c from Case_Escalation_Settings__mdt where MasterLabel = 'Default' limit 1];
        if(metadataSettings.isEmpty()) return s;
        
        Case_Escalation_Settings__mdt metadataSetting = metadataSettings[0];
        
        s.email = metadataSetting.Email__c;
        s.outageTemplateId = metadataSetting.Outage_Template_Id__c;
        s.CETID = metadataSetting.CETID__c;
        s.templateGroup = metadataSetting.Template_Group__c;
        
        return s;
    }
    
	@AuraEnabled
    public static Boolean escalateCase(Id caseId) {
        List<Case> cases = selectCaseByIds(new Set<Id> { caseId });
        if(cases.isEmpty()) return false;
        
        Case c = cases[0];
        c.Status = 'Escalated to Tier 3';
        update c;
        
        return true;
    }
    
    @AuraEnabled
    public static String getCongaSessionVariables() {
        PageReference pr = Page.CongaSessionVariables;
        String content = !Test.isRunningTest() ? pr.getContent().toString() : 'Start_Of_SessionId:session:End_Of_SessionIdStart_Of_ServerUrl:server:End_Of_ServerUrl';
        
        Integer s = content.indexOf('Start_Of_SessionId:') + 'Start_Of_SessionId:'.length();
        Integer e = content.indexOf(':End_Of_SessionId');
        String sessionId = content.substring(s, e);
        
        s = content.indexOf('Start_Of_ServerUrl:') + 'Start_Of_ServerUrl:'.length();
        e = content.indexOf(':End_Of_ServerUrl');
        String serverUrl = content.substring(s, e);
        
        return sessionId + '&' + serverUrl;
    }
    
    // CLASSES
    
    public class Settings {
		@AuraEnabled
        public String email {get; set;}
        @AuraEnabled
        public String outageTemplateId {get; set;}
        @AuraEnabled
        public String CETID {get; set;}
        @AuraEnabled
        public String templateGroup {get; set;}
        
        public Settings() {
            this.email = 'tier3support@getconga.com';
            this.outageTemplateId = '00X50000001c4Op';
            this.CETID = 'a1250000003Ajk4';
            this.templateGroup = 'EscalationDocs';
        }
    }
    
    // SELECTORS
    
    private static List<Case> selectCaseByIds(Set<Id> caseIds) {
        return [
            select
            	Id,
            	CaseNumber,
            	Status
            from
            	Case
            where
            	Id in :caseIds
        ];
    }
}