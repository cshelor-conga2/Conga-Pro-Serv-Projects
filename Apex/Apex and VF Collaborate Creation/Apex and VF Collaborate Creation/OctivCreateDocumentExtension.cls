public with sharing class OctivCreateDocumentExtension { 
     // MODIFICATION HISTORY: 
     //  01-30-2013 ProCore Resource Group, Jeff Stevens 
     //              Created.  Copied from proposalExtension to handle overrides for new proposal type - document 
 
 
     public String   TBAccountEndPoint       {get;set;} 
     public final    tinderbox__Document__c  current_document; 
     public String   sobjectId; 
     public String   sobjectType;
     public String templateId { get;set; } 
     public String   docType                 {get;set;}
     public String queryString { get;set; }
     public boolean isSessionIdDisabled { get;set; }
     public String retUrl { get;set; } 
 

     // The extension constructor initializes the private member   
     // variable acct by using the getRecord method from the standard   
     // controller. 
 

     public OctivCreateDocumentExtension(ApexPages.StandardController stdController) { 
         // TODO: Fix whatever this is trying to do. 
         this.current_document = (tinderbox__Document__c)stdController.getRecord(); 
 
 
         // See if recordId exists. 
         sobjectId = ApexPages.currentPage().getParameters().get('recordId'); 
         sobjectType = ApexPages.currentPage().getParameters().get('sObjectType');
         templateId = ApexPages.currentPage().getParameters().get('templateId'); 
         docType = ApexPages.currentPage().getParameters().get('docType');
         queryString = 'sobject_id=' + sObjectId + '&sobject_type' + SObjectType + '&template_id=' + templateId;
         isSessionIdDisabled = false;
         retUrl = '%2f' + sObjectType; 
         if (docType == null || docType == '') { 
             docType = 'document'; 
         } else { 
             docType = docType.toLowerCase(); 
         } 
 
 
         // Get endpoint from Accounts Custom Setting 
         TBAccountEndPoint = null; 
         // Creating/Adding Documents may contain a specific TBAccountID. 
         String tbAccountId = ApexPages.currentPage().getParameters().get('TBAccountID'); 
     } 
 
 
     public String getParentID() 
     { 
         return sobjectId; 
     } 
      
     public String getSObjectType() 
     { 
         return sobjectType; 
     } 
 

     public String getSessionID() 
     { 
         return UserInfo.getSessionId(); 
     } 
      
}