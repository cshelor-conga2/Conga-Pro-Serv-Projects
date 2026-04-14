public class APTS_CongaSignRedirectionCtrl 
{
  public pageReference execute()
    {
        String url = buildRedirectionUrl(ApexPages.currentPage().getParameters().get('id'));
        return new PageReference(url);
    } 
    
    public String buildRedirectionUrl(Id agreementId)
    {
        String url = '/apex/APXT_CongaSign__apxt_sendForSignature?id='+agreementId;
        
        Apttus__APTS_Agreement__c agreement = [SELECT Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Opportunity__r.Contact__c,Apttus__Account__r.Name,
                                               Conga_Signatory__c,APTS_Record_Type_Name__c,Order_Type__c,APTS_Legal_Initials__c,APTS_Notes_Legal_Approved__c ,Apttus__Requestor__c, Apttus__Related_Opportunity__r.Apttus_Service_Bookings__c ,APTS_Customer_Signatory_Contact__c, ACV_Contract_Value_if_applicable__c  
                                               FROM Apttus__APTS_Agreement__c 
                                               WHERE Id=:agreementId];
        APTS_C4C_Custom_Metadata__mdt config = [SELECT APTS_Conga_Sign_Routing_Type__c,APTS_Conga_Sign_Email_Subject__c,APTS_Conga_Sign_Email_Message__c 
                                                FROM APTS_C4C_Custom_Metadata__mdt 
                                                WHERE DeveloperName='System_Properties'];
        if(agreement.APTS_Record_Type_Name__c == 'Order') {
            url+= recipientsForOrderAgreements(agreement,config);
        }
        //Added for CIT-366
        else if(agreement.APTS_Record_Type_Name__c == 'SOW')
        {
            url+= recipientsForSOWAgreements(agreement,config);
        }//End of changes for CIT-366
        //Added for CIT-5944
        else if(agreement.APTS_Record_Type_Name__c == 'PSOD')
        {
            url+=recipientsForPSODAgreements(agreement,config);
        } else if(agreement.APTS_Record_Type_Name__c == 'TSO') {
            // CIT-7605
            url+=recipientsForTSOAgreements(agreement,config);
        }//End of changes for CIT-5944
        else if(agreement.APTS_Record_Type_Name__c == 'NDA' || agreement.APTS_Record_Type_Name__c == 'MSSA' || agreement.APTS_Record_Type_Name__c == 'DPA' || agreement.APTS_Record_Type_Name__c == 'MPA') {
            url+=recipientsForLegalAgreements(agreement, config);
        }
        else {
            url+=recipientsForNonOrderAgreements(agreement,config);
        }
        return url; 
    }

    public String recipientsForOrderAgreements (Apttus__APTS_Agreement__c agreement,APTS_C4C_Custom_Metadata__mdt config) {
        String url = '';
        url+= '&routingType='+config.APTS_Conga_Sign_Routing_Type__c;
        if(agreement.Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Opportunity__r.Contact__c != NULL) {
            url+= '&recipient1='+agreement.Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Opportunity__r.Contact__c;
        }
        if(agreement.APTS_Notes_Legal_Approved__c  != NULL) {
            if(agreement.APTS_Legal_Initials__c != NULL )
                url+= '&recipient2='+agreement.APTS_Legal_Initials__c; 
            if(agreement.Conga_Signatory__c != NULL)
                url+= '&recipient3='+agreement.Conga_Signatory__c;
        }
        if(agreement.Conga_Signatory__c != NULL) 
            url+= '&recipient2='+agreement.Conga_Signatory__c;

        String subject = '';
        
        if(!String.isBlank(config.APTS_Conga_Sign_Email_Subject__c))
        {
            subject = config.APTS_Conga_Sign_Email_Subject__c.replace('{ACCOUNT_NAME}',agreement.Apttus__Account__r.Name);
          subject = subject.replace('{CURRENT_DATE}',System.now().format('MM/dd/yyyy'));
        }
        
        url+= '&emailSubject='+subject;
        
        url+= '&emailMessage='+ config.APTS_Conga_Sign_Email_Message__c;
        url+= '&expireOn='+date.today().addMonths(1);
        return url;
    }

    public String recipientsForLegalAgreements(Apttus__APTS_Agreement__c agreement,APTS_C4C_Custom_Metadata__mdt config) {
        String url = '';
        if(agreement.APTS_Record_Type_Name__c == 'MSSA') {
            url+= '&recipient1='+agreement.Apttus__Requestor__c;
            url+= '&recipient1role=CC';
            url+= '&recipient2='+agreement.APTS_Customer_Signatory_Contact__c;
            url+= '&recipient3='+agreement.Conga_Signatory__c;
        }
        else {
            url+= '&recipient1='+agreement.APTS_Customer_Signatory_Contact__c;
        }
        url+= '&routingType='+config.APTS_Conga_Sign_Routing_Type__c;
        
        String subject = '';
        
        if(!String.isBlank(config.APTS_Conga_Sign_Email_Subject__c)) {
            subject = config.APTS_Conga_Sign_Email_Subject__c.replace('{ACCOUNT_NAME}',agreement.Apttus__Account__r.Name);
            subject = subject.replace('{CURRENT_DATE}',System.now().format('MM/dd/yyyy'));
        }
        url+= '&emailSubject='+subject;
        url+= '&emailMessage='+ config.APTS_Conga_Sign_Email_Message__c;
        url+= '&expireOn='+date.today().addMonths(1);
        url+= '&businessUnit=Conga_SignLegal';
        return url; 
    }
    
    public String recipientsForNonOrderAgreements(Apttus__APTS_Agreement__c agreement,APTS_C4C_Custom_Metadata__mdt config) {
        String url = '';
        url+= '&routingType='+config.APTS_Conga_Sign_Routing_Type__c;
        
        if(agreement.Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Opportunity__r.Contact__c != null)
        {
          url+= '&recipient1='+agreement.Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Opportunity__r.Contact__c;    
        } 
        
        if(agreement.Conga_Signatory__c!=null)
        {
            url+= '&recipient2=' + agreement.Conga_Signatory__c;
        }
        String subject = '';
        
        if(!String.isBlank(config.APTS_Conga_Sign_Email_Subject__c))
        {
            subject = config.APTS_Conga_Sign_Email_Subject__c.replace('{ACCOUNT_NAME}',agreement.Apttus__Account__r.Name);
          subject = subject.replace('{CURRENT_DATE}',System.now().format('MM/dd/yyyy'));
        }
        url+= '&emailSubject='+subject;
        url+= '&emailMessage='+ config.APTS_Conga_Sign_Email_Message__c;
        url+= '&expireOn='+date.today().addMonths(1);
        return url; 
    }
    
    //Added on 12th Dec '22 for CIT-366 (Autopopulate signatories for SOWs)
    public String recipientsForSOWAgreements (Apttus__APTS_Agreement__c agreement,APTS_C4C_Custom_Metadata__mdt config) 
    {
        Conga_PS_Signature_Routing__mdt  signatories = [SELECT id,Conga_Signing_Authority_1__c,Conga_Signing_Authority_2__c,Initial_1__c, Initial_2__c, Initial_3__c, PS_Deal_Desk__c   
                                                FROM Conga_PS_Signature_Routing__mdt where DeveloperName = 'C2_Combined_SOW'];
        String url = '';
        url+= '&routingType='+config.APTS_Conga_Sign_Routing_Type__c;
        Integer index = 1;
        if(signatories!=null && signatories.Initial_1__c!=null)
        {
            url+= '&recipient'+ index +'=' + signatories.Initial_1__c + '&recipient'+ index +'role=SIGNER';
            index++;
        }
        if(signatories!=null && signatories.Initial_2__c!=null)
        {
            url+= '&recipient'+ index +'=' + signatories.Initial_2__c + '&recipient'+ index +'role=SIGNER';
            index++;
        }
        //Scenario when Service Bookings > 500K USD--then require Initial_3(Finance)
        if(agreement.Apttus__Related_Opportunity__r.Apttus_Service_Bookings__c!=null && agreement.Apttus__Related_Opportunity__r.Apttus_Service_Bookings__c >= 500000)
    {
            if(signatories!=null && signatories.Initial_3__c!=null)
            {
                url+= '&recipient'+ index +'=' + signatories.Initial_3__c + '&recipient'+ index +'role=SIGNER';
                index++;
            }
    }
        if(agreement.Apttus__Requestor__c!=null)
        {
            url+= '&recipient'+ index +'=' + agreement.Apttus__Requestor__c + '&recipient'+ index +'role=CC';
            index++;
        }
        if(agreement.APTS_Customer_Signatory_Contact__c !=null)
        {
            url+= '&recipient'+ index +'=' + agreement.APTS_Customer_Signatory_Contact__c + '&recipient'+ index +'role=SIGNER';
            index++;
        }
       
        if(agreement.Apttus__Related_Opportunity__r.Apttus_Service_Bookings__c!=null && agreement.Apttus__Related_Opportunity__r.Apttus_Service_Bookings__c >= 500000)
    {
            if(signatories!=null && signatories.Conga_Signing_Authority_2__c!=null)
            {
                url+= '&recipient'+ index +'=' + signatories.Conga_Signing_Authority_2__c + '&recipient'+ index +'role=SIGNER';
                index++;
            }
    }
        else
        {
            if(signatories !=null && signatories.Conga_Signing_Authority_1__c!=null)
            {
                url+= '&recipient'+ index +'=' + signatories.Conga_Signing_Authority_1__c + '&recipient'+ index +'role=SIGNER';
                index++;
            } 
        }
        
        if(signatories!=null && signatories.PS_Deal_Desk__c!=null)
        {
            String[] dealDeskUserIds = signatories.PS_Deal_Desk__c.split(',');
            for(String userId : dealDeskUserIds)
            {
               url+= '&recipient'+ index +'=' + userId + '&recipient'+ index +'role=CC';
               index++;
            }
        }
        String subject = '';
        
        if(!String.isBlank(config.APTS_Conga_Sign_Email_Subject__c))
        {
            subject = agreement.Apttus__Account__r.Name!=null ? config.APTS_Conga_Sign_Email_Subject__c.replace('{ACCOUNT_NAME}',agreement.Apttus__Account__r.Name) : config.APTS_Conga_Sign_Email_Subject__c;
          subject = subject.replace('{CURRENT_DATE}',System.now().format('MM/dd/yyyy'));
        }
        url+= '&emailSubject='+subject;
        url+= '&emailMessage='+ config.APTS_Conga_Sign_Email_Message__c;
        url+= '&expireOn='+date.today().addMonths(1);
        return url;
    }
    //End of changes for CIT-366
    //Added for CIT-5944
    public String recipientsForPSODAgreements (Apttus__APTS_Agreement__c agreement,APTS_C4C_Custom_Metadata__mdt config) 
    {
        Conga_PS_Signature_Routing__mdt  signatories = [SELECT id,Conga_Signing_Authority_1__c,Conga_Signing_Authority_2__c,Initial_1__c, Initial_2__c, Initial_3__c, PS_Deal_Desk__c   
                                                FROM Conga_PS_Signature_Routing__mdt where DeveloperName = 'PSOD'];
        String url = '';
        url+= '&routingType='+config.APTS_Conga_Sign_Routing_Type__c;
        Integer index = 1;
        
        if(agreement.APTS_Customer_Signatory_Contact__c !=null)
        {
            url+= '&recipient'+ index +'=' + agreement.APTS_Customer_Signatory_Contact__c + '&recipient'+ index +'role=SIGNER';
            index++;
        }
       
        if(agreement.Apttus__Related_Opportunity__r.Apttus_Service_Bookings__c!=null && agreement.Apttus__Related_Opportunity__r.Apttus_Service_Bookings__c >= 500000)
    {
            if(signatories!=null && signatories.Conga_Signing_Authority_2__c!=null)
            {
                url+= '&recipient'+ index +'=' + signatories.Conga_Signing_Authority_2__c + '&recipient'+ index +'role=SIGNER';
                index++;
            }
    }
        else
        {
            if(signatories !=null && signatories.Conga_Signing_Authority_1__c!=null)
            {
                url+= '&recipient'+ index +'=' + signatories.Conga_Signing_Authority_1__c + '&recipient'+ index +'role=SIGNER';
                index++;
            } 
        }
        if(agreement.Apttus__Requestor__c!=null)
        {
            url+= '&recipient'+ index +'=' + agreement.Apttus__Requestor__c + '&recipient'+ index +'role=CC';
            index++;
        }
        
        if(signatories!=null && signatories.PS_Deal_Desk__c!=null)
        {
            String[] dealDeskUserIds = signatories.PS_Deal_Desk__c.split(',');
            for(String userId : dealDeskUserIds)
            {
               url+= '&recipient'+ index +'=' + userId + '&recipient'+ index +'role=CC';
               index++;
            }
        }
        String subject = '';
        
        if(!String.isBlank(config.APTS_Conga_Sign_Email_Subject__c))
        {
            subject = agreement.Apttus__Account__r.Name!=null ? config.APTS_Conga_Sign_Email_Subject__c.replace('{ACCOUNT_NAME}',agreement.Apttus__Account__r.Name) : config.APTS_Conga_Sign_Email_Subject__c;
          subject = subject.replace('{CURRENT_DATE}',System.now().format('MM/dd/yyyy'));
        }
        url+= '&emailSubject='+subject;
        url+= '&emailMessage='+ config.APTS_Conga_Sign_Email_Message__c;
        url+= '&expireOn='+date.today().addMonths(1);
        return url;
    }

    public string recipientsForTSOAgreements(Apttus__APTS_Agreement__c agreement, APTS_C4C_Custom_Metadata__mdt config){
        string url = '';
        //set routing type
        url+= '&routingType='+config.APTS_Conga_Sign_Routing_Type__c;

        if(agreement.ACV_Contract_Value_if_applicable__c != null && agreement.ACV_Contract_Value_if_applicable__c > 500000){
            // Fetching Signatories
            List<Conga_PS_Signature_Routing__mdt> signatoriesList = [SELECT id,Conga_Signing_Authority_1__c,Conga_Signing_Authority_2__c,Initial_1__c, Initial_2__c, Initial_3__c, PS_Deal_Desk__c   
            FROM Conga_PS_Signature_Routing__mdt where DeveloperName = 'TSO2'];

            if(signatoriesList != null && signatoriesList.size()>0){
                Conga_PS_Signature_Routing__mdt signatories = signatoriesList[0];
                url+= '&recipient1=' + signatories.Initial_1__c + '&recipient1role=SIGNER';
                url+= '&recipient2=' + signatories.Initial_2__c + '&recipient2role=SIGNER';
                url+= '&recipient3=' + agreement.APTS_Customer_Signatory_Contact__c + '&recipient3role=SIGNER';
                url+= '&recipient4=' + signatories.Conga_Signing_Authority_1__c + '&recipient4role=SIGNER';
                url+= '&recipient5email=' + signatories.PS_Deal_Desk__c + '&recipient5role=CC&recipient5name=PS%20Deals%20Desk';
            }
        } else {
            List<Conga_PS_Signature_Routing__mdt> signatoriesList = [SELECT id,Conga_Signing_Authority_1__c,Conga_Signing_Authority_2__c,Initial_1__c, Initial_2__c, Initial_3__c, PS_Deal_Desk__c   
            FROM Conga_PS_Signature_Routing__mdt where DeveloperName = 'TSO1'];
            if(signatoriesList != null && signatoriesList.size()>0){
                Conga_PS_Signature_Routing__mdt signatories = signatoriesList[0];
                url+= '&recipient1=' + signatories.Initial_1__c + '&recipient1role=SIGNER';
                url+= '&recipient2=' + agreement.APTS_Customer_Signatory_Contact__c + '&recipient2role=SIGNER';
                url+= '&recipient3=' + signatories.Conga_Signing_Authority_1__c + '&recipient3role=SIGNER';
                url+= '&recipient4email=' + signatories.PS_Deal_Desk__c + '&recipient4role=CC&recipient4name=PS%20Deals%20Desk';
            }
        }
        System.debug('@@Final URL');
        System.debug(url);
        String subject = '';
        
        if(!String.isBlank(config.APTS_Conga_Sign_Email_Subject__c))
        {
            subject = agreement.Apttus__Account__r.Name!=null ? config.APTS_Conga_Sign_Email_Subject__c.replace('{ACCOUNT_NAME}',agreement.Apttus__Account__r.Name) : config.APTS_Conga_Sign_Email_Subject__c;
          subject = subject.replace('{CURRENT_DATE}',System.now().format('MM/dd/yyyy'));
        }
        url+= '&emailSubject='+subject;
        url+= '&emailMessage='+ config.APTS_Conga_Sign_Email_Message__c;
        // url+= '&expireOn='+date.today().addMonths(1);

        return url;
    }
}