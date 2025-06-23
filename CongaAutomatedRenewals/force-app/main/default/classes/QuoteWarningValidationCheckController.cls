/**
 * @File Name          : QuoteWarningValidationCheckController.cls
 * @Description        : 
 * @Author             : MS Simplus August
 * @Group              : 
 * @Last Modified By   : MS Simplus August
 * @Last Modified On   : 23/11/2019, 3:31:19 am
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    23/11/2019   MS Simplus August     Initial Version
**/
global without sharing class QuoteWarningValidationCheckController {
    
    // QUOTE RECALL SETTINGS METADATA
    private static Set<Id> PermittedIds {
    get {
        if(PermittedIds == null){
            PermittedIds = new Set<Id>();
            List<Quote_Button_Settings__mdt> quoteRecallSettings = [SELECT Permitted_Ids_for_Recall__c FROM Quote_Button_Settings__mdt LIMIT 1];
            if(!quoteRecallSettings.isEmpty() && String.isNotBlank(quoteRecallSettings[0].Permitted_Ids_for_Recall__c)){
                for(String profileEntry : quoteRecallSettings[0].Permitted_Ids_for_Recall__c.replace('\r','').split('\n')){
                    String profileId = profileEntry.left(18);
                    if(UtilityClass.validateId(profileId)){
                        PermittedIds.add(profileId);
                    }
                }
            }
        }
        return PermittedIds;
    } set; }

    public Id objQuoteId {get;set;}
    public static String strResult;
    private static Map<String, Quote_Error_Check__mdt> mapQuoteErrCheck = new Map<String, Quote_Error_Check__mdt>();
    private static Set<String> setValidationFields = new Set<String>();
    private static Set<Id> profileId = new Set<Id>();
    public static boolean isValid;
    
    public static Set<String> setIncValidation = new Set<String>();
    //public static Map<String, List<Profiles_Roles_For_Validation__mdt>> mapProfileRoleForVal = new Map<String, List<Profiles_Roles_For_Validation__mdt>>();
    public static Set<String> setProfileRoleForVal = new Set<String>();
    public static Set<String> setRemoveProfileRoleforVal = new Set<String>();

    public QuoteWarningValidationCheckController(ApexPages.StandardController controller){
        objQuoteId = controller.getId();
    }
    
    public PageReference checkQuote(){
        String strResult = QuoteWarningValidationCheckController.checkQuote(objQuoteId);

        if(strResult <> null && isValid == false) {
            ApexPages.Message myMsg = new ApexPages.message(ApexPages.severity.WARNING, strResult);
            ApexPages.addMessage(myMsg);
        } else {
        /*  ApexPages.Message myMsg = new ApexPages.message(ApexPages.severity.INFO, strResult);
            ApexPages.addMessage(myMsg); */
        }     
        return null;
    }


    @AuraEnabled
    webservice static String checkQuote(Id objQuoteId){
        SBQQ__Quote__c quote = [ SELECT Id, Non_Payment_Late_Charge__c, SBQQ__PaymentTerms__c, 
                                Auto_Renew__c, SBQQ__Type__c, Expiration_Warning__c, Managed_Clauses__c,
                                OwnerId, Current_User_Profile_Name__c, SBQQ__Primary__c, SBQQ__PrimaryContact__c,
                                Opportunity_Type__c, Overall_Subscription_Discount__c, New_Products_Discount__c, Discount_Reason__c, Existing_Overall_Subscription_Discount__c, Approval_Request_Notes__c, Non_Profit_Discount_Approval_Percent__c,
                                Account_Industry__c
                                FROM SBQQ__Quote__c
                                WHERE  Id=:objQuoteId
                                LIMIT 1][0];

        List<Quote_Error_Check__mdt> quoteErrCheckList = [ SELECT Id, MasterLabel, Error_Message__c, Error__c, Active__c, 
                                                        (SELECT Profile__c, Role__c, Include_Exclude__c, Quote_Error_Check__c, Quote_Error_Check__r.MasterLabel FROM Profiles_Roles_For_Validation__r) 
                                                        FROM Quote_Error_Check__mdt ];

        Map<Id,Profile> mapProfile = new Map<Id,Profile>([SELECT Id, Name FROM Profile]);
        Map<Id,UserRole> mapUserRole = new Map<Id,UserRole>([SELECT Id, Name FROM UserRole]); 

        for(Quote_Error_Check__mdt quoteErrCheck : quoteErrCheckList){
            mapQuoteErrCheck.put(quoteErrCheck.MasterLabel, quoteErrCheck);
            for(Profiles_Roles_For_Validation__mdt prfv : quoteErrCheck.Profiles_Roles_For_Validation__r){
                setProfileRoleForVal.add(quoteErrCheck.MasterLabel);
                //System.debug(setProfileRoleForVal);
                if(prfv.Profile__c != NULL || prfv.Role__c != NULL){
                    //System.debug('@@PROFILE/ROLE NOT BLANK');
                    if(prfv.Profile__c != NULL && prfv.Role__c != NULL){
                        //System.debug('@@PROFILE AND ROLE NOT BLANK: PROFILE: ' + prfv.Profile__c + ' ROLE: ' + prfv.Role__c);
                        if(UserInfo.getUserRoleId() != NULL){
                            if(prfv.Profile__c == mapProfile.get(UserInfo.getProfileId()).Name && prfv.Role__c == mapUserRole.get(UserInfo.getUserRoleId()).Name && prfv.Include_Exclude__c == 'Exclude'){
                                setRemoveProfileRoleforVal.add(quoteErrCheck.MasterLabel);
                                //System.debug('@@REMOVE: ' + setRemoveProfileRoleforVal);
                            } else if(prfv.Profile__c == mapProfile.get(UserInfo.getProfileId()).Name && prfv.Role__c == mapUserRole.get(UserInfo.getUserRoleId()).Name && prfv.Include_Exclude__c == 'Include'){
                                setIncValidation.add(quoteErrCheck.MasterLabel);
                            }
                        }
                    } else {
                        //System.debug('@@PROFILE/ROLE ONLY');
                        if(prfv.Profile__c == mapProfile.get(UserInfo.getProfileId()).Name && prfv.Include_Exclude__c == 'Include'){
                            setIncValidation.add(quoteErrCheck.MasterLabel);
                        } else if(prfv.Profile__c != mapProfile.get(UserInfo.getProfileId()).Name && prfv.Include_Exclude__c =='Exclude'){
                            setRemoveProfileRoleforVal.add(quoteErrCheck.MasterLabel);
                        } else if(prfv.Profile__c == mapProfile.get(UserInfo.getProfileId()).Name && prfv.Include_Exclude__c =='Exclude'){
                            setIncValidation.add(quoteErrCheck.MasterLabel);
                        } else if(UserInfo.getUserRoleId() != NULL){
                            if(prfv.Role__c == mapUserRole.get(UserInfo.getUserRoleId()).Name && prfv.Include_Exclude__c == 'Include'){
                                setIncValidation.add(quoteErrCheck.MasterLabel);
                            } else if(prfv.Role__c != mapUserRole.get(UserInfo.getUserRoleId()).Name && prfv.Include_Exclude__c == 'Exclude'){
                                setRemoveProfileRoleforVal.add(quoteErrCheck.MasterLabel);
                            } else if(prfv.Role__c == mapUserRole.get(UserInfo.getUserRoleId()).Name && prfv.Include_Exclude__c == 'Exclude'){
                                setIncValidation.add(quoteErrCheck.MasterLabel);
                            } 
                        } 
                    }
                }
            }
        }
        //System.debug('@@@VALIDATION INCLUDED: ' + setIncValidation);
        //System.debug('@@@VALIDATIO REMOVED: ' + setRemoveProfileRoleforVal);
        setIncValidation.removeAll(setRemoveProfileRoleforVal);
        

        if((quote.SBQQ__PaymentTerms__c != 'Net 30' || quote.Auto_Renew__c != '1' || quote.Non_Payment_Late_Charge__c != 1 ||
          quote.Expiration_Warning__c != 30) && quote.Managed_Clauses__c == 0 && quote.Opportunity_Type__c == 'New Business'){
            if(setProfileRoleForVal.contains('Mgd Clauses req for non standard term')){
                if(setIncValidation.contains('Mgd Clauses req for non standard term')){
                    setValidationFields.add(mapQuoteErrCheck.get('Mgd Clauses req for non standard term').MasterLabel);
                }
            } else {
                setValidationFields.add(mapQuoteErrCheck.get('Mgd Clauses req for non standard term').MasterLabel);
            }
        }
        
        if(quote.OwnerId != Userinfo.getUserId()){
            if(setProfileRoleForVal.contains('Quote Owner Not Submitter - Sales User')){
                if(setIncValidation.contains('Quote Owner Not Submitter - Sales User')){
                    setValidationFields.add(mapQuoteErrCheck.get('Quote Owner Not Submitter - Sales User').MasterLabel);
                }
            } else {
                setValidationFields.add(mapQuoteErrCheck.get('Quote Owner Not Submitter - Sales User').MasterLabel);
            }
        }

        if(quote.SBQQ__Primary__c != TRUE || quote.SBQQ__PrimaryContact__c == NULL){
            //System.debug('@@@@Must be Primary/Have Primary Contact');
            if(setProfileRoleForVal.contains('Must be Primary/Have Primary Contact')){
                if(setIncValidation.contains('Must be Primary/Have Primary Contact')){
                    //System.debug('@@@@setProfileRoleForVal');
                    setValidationFields.add(mapQuoteErrCheck.get('Must be Primary/Have Primary Contact').MasterLabel);
                }
            } else {
                setValidationFields.add(mapQuoteErrCheck.get('Must be Primary/Have Primary Contact').MasterLabel);
            }
        }

        if(quote.Approval_Request_Notes__c == NULL && ((quote.Existing_Overall_Subscription_Discount__c < quote.Overall_Subscription_Discount__c && Quote.Opportunity_Type__c == 'Renewal') || 
                                                       (Quote.Opportunity_Type__c != 'Renewal' && quote.New_Products_Discount__c > 10 && quote.Account_Industry__c != 'Non-Profit and Education') || 
                                                       (Quote.Opportunity_Type__c != 'Renewal' && quote.New_Products_Discount__c > 33.333333 && quote.Account_Industry__c == 'Non-Profit and Education') || 
                                                       (Quote.Opportunity_Type__c == 'New Business' && quote.Managed_Clauses__c > 0))){
            if(setProfileRoleForVal.contains('Approval Request Notes Required')){
                if(setIncValidation.contains('Approval Request Notes Required')){
                    setValidationFields.add(mapQuoteErrCheck.get('Approval Request Notes Required').MasterLabel);
                }
            } else {
                setValidationFields.add(mapQuoteErrCheck.get('Approval Request Notes Required').MasterLabel);
            }
        }
        
           if(quote.Discount_Reason__c == NULL && ((quote.Existing_Overall_Subscription_Discount__c < quote.Overall_Subscription_Discount__c && Quote.Opportunity_Type__c == 'Renewal') || 
                                                   (Quote.Opportunity_Type__c != 'Renewal' && quote.New_Products_Discount__c > 10 && quote.Account_Industry__c != 'Non-Profit and Education') ||
                                                   (Quote.Opportunity_Type__c != 'Renewal' && quote.New_Products_Discount__c > 33.333333 && quote.Account_Industry__c == 'Non-Profit and Education'))){
            if(setProfileRoleForVal.contains('Discount Reason Required')){
                if(setIncValidation.contains('Discount Reason Required')){
                    setValidationFields.add(mapQuoteErrCheck.get('Discount Reason Required').MasterLabel);
                }
            } else {
                setValidationFields.add(mapQuoteErrCheck.get('Discount Reason Required').MasterLabel);
            }
        }

        if(!setValidationFields.isEmpty()){
            strResult = '<br/>';
            for(String strFieldName : setValidationFields){
                if(mapQuoteErrCheck.containsKey(strFieldName) && mapQuoteErrCheck.get(strFieldName).Active__c){
                    isValid = false;
                    strResult += '<li class="errmsg"><font color="red">' + mapQuoteErrCheck.get(strFieldName).Error_Message__c + '</li>'; 
                }   
            }  
        } else{
            isValid = true;
            strResult = '<br/>';
            strResult += '<li class="errmsg"><font color="black">' + 'Quote is Valid' + '</li>';
        }
        
        return strResult;
    }
    
    @AuraEnabled
    public static String quoteApprovalStatus(Id objQuoteId){
        String StringQuoteStatus = [SELECT Id, ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = : objQuoteId].ApprovalStatus__c;
        
        return StringQuoteStatus;
    }
    
    @AuraEnabled
    public static String onSubmit(Id objQuoteId){
        String submitted = 'Submitted';
        
        if(objQuoteId != null){
            SBAA.ApprovalAPI.submit(objQuoteId, SBAA__Approval__c.Quote__c);
        }
        
        return submitted;
    }

    @AuraEnabled
    public static void onRecall(Id quoteId) {

        // GET QUOTE RECORD
        List<SBQQ__Quote__c> quoteToRecall = [SELECT Id, OwnerId FROM SBQQ__Quote__c WHERE Id = :quoteId];

        // SWITCH QUOTE OWNERSHIP TO CURRENT USER IF THE CURRENT USER IS ALLOWED TO RECALL
        Id currentOwner;
        if(!quoteToRecall.isEmpty() && quoteToRecall[0].OwnerId != UserInfo.getUserId() && (PermittedIds.contains(UserInfo.getProfileId()) || 
                                                                                            PermittedIds.contains(UserInfo.getUserRoleId()) || 
                                                                                            PermittedIds.contains(UserInfo.getUserId()))){
            currentOwner = quoteToRecall[0].OwnerId;
            quoteToRecall[0].OwnerId = UserInfo.getUserId();
            update quoteToRecall[0];
        }

        if (quoteId != null) {
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
        }

        // SWITCH OWNERSHIP BACK
        if(!quoteToRecall.isEmpty() && currentOwner != null){
            quoteToRecall[0].OwnerId = currentOwner;
            update quoteToRecall[0];
        }
    }

}