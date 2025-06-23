/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IACRMTaskHelper - Custom functionality for the ia_crm__Task__c object
*/
public class IntacctDataModel {
    
    /**
    * @description Class IntacctSettings
    */
    public class IntacctSettings {
        public String CompanyId {get; set;}
        public String SenderId {get; set;}
        public String SenderPassword {get; set;}
        public String UserId {get; set;}
        public String UserPassword {get; set;}
        public String SlideIn {get; set;}
        public String EndpointUrl {get; set;}
        public Boolean Log {get; set;}
        public Boolean LogSuccess {get; set;}
        
        /**
        * @description replaceVariables
        * @param String text
        * @return String
        */ 
        public String replaceVariables(String text) {
            text = text.replace('{{sender_id}}', SenderId);
            text = text.replace('{{sender_password}}', SenderPassword);
            text = text.replace('{{user_id}}', UserId);
            text = text.replace('{{user_password}}', UserPassword);
            text = text.replace('{{company_id}}', CompanyId);
            text = text.replace('{{temp_slide_in}}', IntacctUtils.isNull(SlideIn,''));
            return text;
        }
    }

    /**
    * @description Class IntacctSession
    */
    public class IntacctSession {
        public String SessionId {get; set;}
        public String Endpoint {get; set;}
        
        /**
        * @description IntacctSession - Constructor
        * @param String sessionId
        * @param String endpoint
        */
        public IntacctSession(String sessionId, String endpoint) {
            this.SessionId = sessionId;
            this.Endpoint = endpoint;
        }
        
        /**
        * @description replaceVariables
        * @param String text
        * @return String
        */        
        public String replaceVariables(String text) {
            text = text.replace('{{temp_session_id}}', SessionId);
            return text;
        }        
    }
    
    /**
    * @description Class IntacctError
    */
    public class IntacctError {
        public String ErrorNumber {get; set;}
        public String Description {get; set;}
        public String Description2 {get; set;}
        public String Correction {get; set;}
        
        /**
        * @description IntacctError - Constructor
        */
        public IntacctError() { 
        }
        
        /**
        * @description IntacctError - Constructor
        * @param Dom.XMLNode errormessageXml
        */        
        public IntacctError(Dom.XMLNode errormessageXml) {
            this();
            parse(errormessageXml);
        }
        

        /**
        * @description parse - 
        * @param Dom.XMLNode errormessageXml
        * @return void
        */           
        private void parse(Dom.XMLNode errormessageXml) {
            Dom.XMLNode errorXml = errormessageXml.getChildElement('error',null);
                
            Dom.XMLNode errornoXml = errorXml.getChildElement('errorno',null);                
            if(errornoXml != null) ErrorNumber = errornoXml.getText();
            
            Dom.XMLNode descriptionXml = errorXml.getChildElement('description',null);
            if(descriptionXml != null) Description = descriptionXml.getText();
            
            Dom.XMLNode description2Xml = errorXml.getChildElement('description2',null);
            if(description2Xml != null) Description2 = description2Xml.getText();
            
            Dom.XMLNode correctionXml = errorXml.getChildElement('correction',null);
            if(correctionXml != null) Correction = correctionXml.getText();
        }
    }    
    
    /**
    * @description interface IXml
    */
    public interface IXml {    
        String toXML();
    }
    
    /**
    * @description abstract class Request
    */
    public abstract class Request implements IXml {    
        public abstract String toXML();
    }
    
    /**
    * @description abstract class Response
    */
    public abstract class Response {
        public IntacctError Error {get; set;}
        public Boolean IsSuccess {get; set;}
        
        /**
        * @description Response - Constructorl
        */  
        public Response() {
            
        }
        
        /**
        * @description Response - Constructor
        * @param String xml
        */          
        public Response(String xml) {
            this();
            parseXml(xml);
        }
        
        /**
        * @description protected virtual parseXml - 
        * @param String xml
        * @return void
        */         
        protected virtual void parseXml(String xml) {
            IsSuccess = false;
            
            Dom.Document docXml = new Dom.Document();
            docXml.load(xml);
            
            Dom.XMLNode responseXml = docXml.getRootElement();                        
            Dom.XMLNode controlXml = responseXml.getChildElement('control',null);
            Dom.XMLNode controlStatusXml = controlXml.getChildElement('status',null);
            if(controlStatusXml.getText() != 'success') {                
                Dom.XMLNode errormessageXml = responseXml.getChildElement('errormessage',null);
                Error = new IntacctError(errormessageXml);
                return;
            }
            
            Dom.XMLNode operationXml = responseXml.getChildElement('operation',null);            
            Dom.XMLNode authenticationXml = operationXml.getChildElement('authentication',null);            
            Dom.XMLNode authenticationStatusXml = authenticationXml.getChildElement('status',null);
            if(authenticationStatusXml.getText() != 'success') {                
                Dom.XMLNode errormessageXml = operationXml.getChildElement('errormessage',null);
                Error = new IntacctError(errormessageXml);                                
            }
            else {
                Dom.XMLNode resultXml = operationXml.getChildElement('result',null);
                Dom.XMLNode resultStatusXml = resultXml.getChildElement('status',null);
                if(resultStatusXml.getText() != 'success') {                
                    Dom.XMLNode errormessageXml = resultXml.getChildElement('errormessage',null);
                    Error = new IntacctError(errormessageXml);                                
                }
                else {
                    Dom.XMLNode dataXml = resultXml.getChildElement('data',null);
                    parseData(dataXml);                
                    IsSuccess = true;    
                }            
            }
        }
        
        /**
        * @description protected abstract parseXml - 
        * @param Dom.XMLNode dataXml
        * @return void
        */  
        protected abstract void parseData(Dom.XMLNode dataXml);
    }    
    
    /**
    * @description Class ApiRequest - 
    */
    public class ApiRequest extends Request {
        private final IntacctSettings settings;
        

        /**
        * @description ApiRequest - Constructor
        * @param IntacctSettings settings
        */  
        public ApiRequest(IntacctSettings settings) {
            this.settings = settings;    
        }
        

        /**
        * @description override toXML - 
        * @return String
        */       
        public override String toXML() {
            String xml = '<?xml version="1.0" encoding="UTF-8"?>';
            xml += '<request>';
            xml += new Control(settings).toXML();
            xml += '    <operation>';
            xml += '        <authentication>';
            xml += '            <login>';
            xml += '                <userid>{{user_id}}</userid>';
            xml += '                <companyid>{{company_id}}{{temp_slide_in}}</companyid>';
            xml += '                <password>{{user_password}}</password>';
            xml += '            </login>';
            xml += '        </authentication>';
            xml += '        <content>';
            xml += '            <function controlid="{{$guid}}">';
            xml += '                <getAPISession />';
            xml += '            </function>';
            xml += '        </content>';
            xml += '    </operation>';
            xml += '</request>';
            
            xml = IntacctUtils.replaceVariables(settings.replaceVariables(xml));
                                    
            return xml;
        }
    }
    
    /**
    * @description class ApiResponse
    */
    public class ApiResponse extends Response {
        public IntacctSession Session {get; set;}
        
        /**
        * @description ApiResponse - Constructor
        */  
        public ApiResponse() {
            super();
        }
        
        /**
        * @description ApiResponse - Constructor
        * @param String xml
        */          
        public ApiResponse(String xml) {
            super(xml);
        }

        /**
        * @description override parseData
        * @param Dom.XMLNode dataXml
        * @return void
        */         
        protected override void parseData(Dom.XMLNode dataXml) {
            Dom.XMLNode apiXml = dataXml.getChildElement('api',null);
            Dom.XMLNode sessionidXml = apiXml.getChildElement('sessionid',null);
            Dom.XMLNode endpointXml = apiXml.getChildElement('endpoint',null);

            Session = new IntacctSession(sessionidXml.getText(), endpointXml.getText());              
        }
    }
    
    /**
    * @description class FunctionRequest - 
    */
    public class FunctionRequest extends Request {
        private final IntacctSettings settings;
        private final IntacctSession session;
        private final Operation operation;
        
        /**
        * @description FunctionRequest - Constructor
        */
        public FunctionRequest(IntacctSettings settings, IntacctSession session, Operation operation) {
            this.settings = settings;
            this.session = session;
            this.operation = operation;
        }
        
        /**
        * @description toXML - 
        * @return String
        */        
        public override String toXML() {
            String xml = '<?xml version="1.0" encoding="UTF-8"?>';
            xml += '<request>';
            xml += new Control(settings).toXML();         
            xml += '    <operation>';
            xml += '        <authentication>';
            xml += '            <sessionid>{{temp_session_id}}</sessionid>';
            xml += '        </authentication>';  
            xml += '        <content>';
            xml += '            <function controlid="{{$guid}}">';
            xml += operation.toXML();
            xml += '            </function>';
            xml += '        </content>';
            xml += '    </operation>';
            xml += '</request>';
        
            xml = IntacctUtils.replaceVariables(settings.replaceVariables(session.replaceVariables(xml)));           
            return xml;
        }
    }    

    /**
    * @description class Control
    */
    private class Control implements IXml {    
        private final IntacctSettings settings;
        
        /**
        * @description Control - Constructor\
        * @param IntacctSettings settings
        */
        public Control(IntacctSettings settings) {
            this.settings = settings;    
        }
        
        /**
        * @description toXML - 
        * @return String
        */     
        public String toXML() {
            String xml = '';
            xml += '    <control>';
            xml += '        <senderid>{{sender_id}}</senderid>';
            xml += '        <password>{{sender_password}}</password>';
            xml += '        <controlid>{{$timestamp}}</controlid>';
            xml += '        <uniqueid>false</uniqueid>';
            xml += '        <dtdversion>3.0</dtdversion>';
            xml += '        <includewhitespace>false</includewhitespace>';
            xml += '    </control>';
            
            xml = IntacctUtils.replaceVariables(settings.replaceVariables(xml));                 
            return xml;
        }
    }
    
    /**
    * @description abstract class Operation
    */
    public abstract class Operation implements IXml { 

        /**
        * @description toXML - 
        * @return String
        */    
        public abstract String toXML();
    }


    /**
    * @description class CreateOperation
    */
    public class CreateOperation extends Operation { 
        private final IXml objectToCreate;
        
        /**
        * @description CreateOperation - Constructor
        * @param IXml objectToCreate
        */
        public CreateOperation(IXml objectToCreate) {
            this.objectToCreate = objectToCreate;
        }        
        
        /**
        * @description toXML - 
        * @return String
        */             
        public override String toXML() {
            String xml = '';
            xml += '                <create>';
            xml += objectToCreate.toXML();
            xml += '                </create>';
            
            return xml;
        }
    }
    
    /**
    * @description class UpdateOperation
    */
    public class UpdateOperation extends Operation { 
        private final IXml objectToUpdate;
        
        /**
        * @description UpdateOperation - Constructor
        * @param IXml objectToUpdate
        */        
        public UpdateOperation(IXml objectToUpdate) {
            this.objectToUpdate = objectToUpdate;
        }        
        
        /**
        * @description toXML - 
        * @return String
        */            
        public override String toXML() {
            String xml = '';
            xml += '                <update>';
            xml += objectToUpdate.toXML();
            xml += '                </update>';
            
            return xml;
        }
    }

    /**
    * @descriptionclass QueryOperation
    */
    public class QueryOperation extends Operation { 
        private final IXml objectToQuery;

        /**
        * @description QueryOperation - Constructor
        * @param IXml objectToQuery
        */     
        public QueryOperation(IXml objectToQuery) {
            this.objectToQuery = objectToQuery;
        }      

        /**
        * @description toXML - 
        * @return String
        */            
        public override String toXML() {
            String xml = '';
            xml += '                <readByQuery>';
            xml += objectToQuery.toXML();
            xml += '                </readByQuery>';
            
            return xml;
        }
    }
    
    /************************ PROJECT ***********************/
    
    /**
    * @description class Project
    */
    public class Project extends Response implements IXml {
        public String RecordNumber {get; set;}
        public String Id {get; set;}
        public String ProjectId {get; set;}
        public String Name {get; set;}
        public String Category {get; set;}
        public String Description {get; set;}
        public String Entity {get; set;}
        public Boolean IsActive {get; set;}
        public String CustomerId {get; set;}
        public String BeginDate {get; set;}
        public String EndDate {get; set;}
        public String ProjectType {get; set;}
        public String ManagerId {get; set;}
        public String TermName {get; set;}
        public String BillingType {get; set;}
        public Decimal BudgetQty {get; set;}
        public String ProjectCurrency {get; set;}
        public String PrimaryContact {get; set;}
        public String BillToContact {get; set;}
        public String ShipToContact {get; set;}
        public String SalesforceId {get; set;}
        public String OpportunityId {get; set;}
        public String ContractId {get; set;}
        public String PurchaseOrderNumber {get;set;}

        /**
        * @description Project - Constructor
        */   
        public Project() {
            super();
        }

        /**
        * @description Project - Constructor
        * @param PS_Project__c project
        */
        public Project(PS_Project__c project) {
            this.SalesforceId = project.Id;
            this.OpportunityId = project.OpportunityId__c;
            this.ContractId = project.OpportunityId__r.ContractId;
            this.Id = project.Intacct_Id__c;
            this.Name = String.isNotBlank(project.Name) ? project.Name.escapeHtml4() : '';
            this.Category = 'Contract';
            this.Entity = project.OpportunityId__c != null && String.isNotBlank(project.OpportunityId__r.ia_crm__Intacct_Entity_Id__c) ? project.OpportunityId__r.ia_crm__Intacct_Entity_Id__c : '';
            this.Description = String.isNotBlank(project.Description__c) ? project.Description__c.escapeHtml4() : '';
            this.IsActive = project.Is_Active__c;
            this.CustomerId = project.AccountId__c != null && String.isNotBlank(project.AccountId__r.ia_crm__IntacctID__c) ? project.AccountId__r.ia_crm__IntacctID__c : '';
            this.BeginDate =  project.Execution__c != null ? IntacctUtils.formatDate(project.Execution__c) : '';
            this.EndDate = project.Expiration_Date__c != null ? IntacctUtils.formatDate(project.Expiration_Date__c) : '';
            this.ProjectType = String.IsNotBlank(project.Agreement_Type__c) ? project.Agreement_Type__c : '';
            ProjectType = ProjectType.replace('Change Request','Change Requests');
            this.ManagerId = String.isNotBlank(project.Intacct_User_Id__c) ? project.Intacct_User_Id__c : '';
            this.TermName = String.IsNotBlank(project.Payment_Terms__c) ? project.Payment_Terms__c : '';
            this.TermName = ((TermName.replace(' days','').replace('Net ','N')).replace('Due On Receipt','Due upon receipt'));
            this.BillingType = String.isNotBlank(project.Billing_Type__c) ? project.Billing_Type__c : '';
            BillingType = ((BillingType.replace('Time and Materials','Time & Material')).replace('Fixed Bid','Fixed Fee')).replace('Non-Billable','');
            this.BudgetQty = project.Hours_EstimatedFx__c != null ? project.Hours_EstimatedFx__c : 0;
            this.ProjectCurrency = 'USD';
            this.PurchaseOrderNumber = String.IsNotBlank(project.Purchase_Order__c) ? project.Purchase_Order__c : '';

            // override the entity? if the settings specify an entity then override
            Intacct_Integration_Settings__c customSetting = Intacct_Integration_Settings__c.getInstance();
            if(customSetting != null && String.isNotBlank(customSetting.Intacct_Entity__c)) {
                this.Entity = customSetting.Intacct_Entity__c;
            }

            for(Project_Team__c team : project.Project_Teams__r) {
                if(team.Contact__c == null || String.isBlank(team.Role__c)) continue;
                if(team.Role__c.contains('Project Owner')) {
                    PrimaryContact = team.Contact__r.ia_crm__Intacct_Contact_ID__c;
                }
                if(team.Role__c.contains('Billing Contact')) {
                    BillToContact = team.Contact__r.ia_crm__Intacct_Contact_ID__c;
                    ShipToContact = team.Contact__r.ia_crm__Intacct_Contact_ID__c;
                }
            }
        }

        /**
        * @description Project - Constructor
        * @param String xml
        */
        public Project(String xml) {
            super(xml);
        }

        /**
        * @description toXML - 
        * @return String
        */  
        public String toXML() {
            String xml = '';
            xml += '                    <PROJECT>';
            if(String.isNotBlank(Id)) {
                xml += '                        <RECORDNO>' + Id + '</RECORDNO>';
            }
            xml += '                        <NAME>' + IntacctUtils.cleanHtmlText(Name) + '</NAME>';
            xml += '                        <DESCRIPTION>' + IntacctUtils.cleanHtmlText(Description).Left(2000) + '</DESCRIPTION>';
            xml += '                        <PROJECTCATEGORY>' + Category + '</PROJECTCATEGORY>';
            xml += '                        <PROJECTSTATUS>' + (IsActive ? 'Active' : '') + '</PROJECTSTATUS>';
            //xml += '                        <STATUS>' + (IsActive ? 'Active' : 'Inactive') + '</STATUS>'; //TODO: Fail when Inactive
            xml += '                        <MEGAENTITYID>' + Entity + '</MEGAENTITYID>';
            xml += '                        <LOCATIONID>' + Entity + '</LOCATIONID>';
            xml += '                        <CUSTOMERID>' + CustomerId + '</CUSTOMERID>';
            xml += '                        <CURRENCY>' + ProjectCurrency + '</CURRENCY>';
            xml += '                        <BEGINDATE>' + BeginDate + '</BEGINDATE>';
            xml += '                        <ENDDATE>' + EndDate + '</ENDDATE>';
            xml += '                        <PROJECTTYPE>' + ProjectType.escapeHtml4() + '</PROJECTTYPE>';
            xml += '                        <MANAGERID>' + ManagerId + '</MANAGERID>';
            xml += '                        <PONUMBER>' + PurchaseOrderNumber + '</PONUMBER>';
            xml += '                        <TERMNAME>' + TermName.escapeHtml4() + '</TERMNAME>';
            xml += '                        <BILLINGTYPE>' + BillingType.escapeHtml4() + '</BILLINGTYPE>';
            xml += '                        <BUDGETQTY>' + String.valueOf(BudgetQty) + '</BUDGETQTY>';
            // if(String.isNotBlank(PrimaryContact)) {
            //     xml += '                        <CONTACTINFO><CONTACTNAME>' + PrimaryContact + '</CONTACTNAME></CONTACTINFO>';
            // }
            // if(String.isNotBlank(BillToContact)) {
            //     xml += '                        <BILLTO><CONTACTNAME>' + BillToContact + '</CONTACTNAME></BILLTO>';
            // }
            // if(String.isNotBlank(ShipToContact)) {
            //     xml += '                        <SHIPTO><CONTACTNAME>' + ShipToContact + '</CONTACTNAME></SHIPTO>';
            // }
            //xml += '                        <SFDCKEY>' + SalesforceId + '</SFDCKEY>';
            xml += '                        <SFDC_PROJECT_ID>' + SalesforceId + '</SFDC_PROJECT_ID>';
            xml += '                        <SFDC_OPPORTUNITY_ID>' + (String.isNotBlank(OpportunityId) ? OpportunityId : '') + '</SFDC_OPPORTUNITY_ID>';
            xml += '                        <SFDC_CONTRACT_ID>' + (String.isNotBlank(ContractId) ? ContractId : '') + '</SFDC_CONTRACT_ID>';
            xml += '                    </PROJECT>';
            return xml;
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
            Dom.XMLNode projectXml = dataXml.getChildElement('project',null);
            Dom.XMLNode recordnoXml = projectXml.getChildElement('RECORDNO',null);
            RecordNumber = recordnoXml.getText();
            Id = RecordNumber;
            Dom.XMLNode projectidXml = projectXml.getChildElement('PROJECTID',null);
            ProjectId = projectidXml.getText();
        }

        /**
        * @description fillFields - 
        * @param PS_Project__c project
        * @return Boolean
        */
        public Boolean fillFields(PS_Project__c project) {
            Boolean modified = false;

            if(project.Intacct_Id__c != this.Id) {
                project.Intacct_Id__c = this.Id;
                modified = true;
            }
            if(project.Intacct_Project_Id__c != this.ProjectId) {
                project.Intacct_Project_Id__c = this.ProjectId;
                modified = true;
            }

            if(project.Intacct_Sync_Status__c != 'OK') {
                project.Intacct_Sync_Status__c = 'OK';
                project.Intacct_Sync_Errors__c = null;
                modified = true;
            }

            return modified;
        }
    }

    /**
    * @description ProjectResource
    */
    public class ProjectResource extends Response implements IXml {
        public String RecordNumber {get; set;}
        public String Id {get; set;}
        public String ProjectId {get; set;}
        public String ItemId {get; set;}
        public String BillingRate {get; set;}
        public String BillingPricing {get; set;}

        /**
        * @description ProjectResource - Constructor
        */

        public ProjectResource() {
            super();
        }

        /**
        * @description ProjectResource - Constructor
        * @param Milestone__c milestone
        */
        public ProjectResource(Milestone__c milestone) {
            this.Id = milestone.Intacct_Resource_Id__c;
            this.ProjectId = milestone.ProjectId__r.Intacct_Id__c;
            this.BillingRate = milestone.Effective_Hourly_Rate__c != null ? String.valueOf(milestone.Effective_Hourly_Rate__c) : '';
            this.BillingPricing = 'Billing rate';
            this.ItemId = milestone.ProductId__c != null ? milestone.ProductId__r.ProductCode : '';
        }

        /**
        * @description ProjectResource - Constructor
        * @param String xml
        */
        public ProjectResource(String xml) {
            super(xml);
        }


        /**
        * @description toXML - 
        * @return String
        */  
        public String toXML() {
            String xml = '';
            xml += '                    <PROJECTRESOURCES>';
            if(String.isNotBlank(Id)) {
                xml += '                        <RECORDNO>' + Id + '</RECORDNO>';
            }
            xml += '                        <PROJECTKEY>' + ProjectId + '</PROJECTKEY>';
            xml += '                        <ITEMID>' + ItemId + '</ITEMID>';
            xml += '                        <BILLINGPRICING>' + BillingPricing  + '</BILLINGPRICING>';
            xml += '                        <BILLINGRATE>' + BillingRate + '</BILLINGRATE>';
            xml += '                    </PROJECTRESOURCES>';

            return xml;
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
            Dom.XMLNode projectresourcesXml = dataXml.getChildElement('projectresources',null);
            Dom.XMLNode recordnoXml = projectresourcesXml.getChildElement('RECORDNO',null);
            RecordNumber = recordnoXml.getText();
            Id = RecordNumber;
        }

        /**
        * @description fillFields - 
        * @param Milestone__c milestone
        * @return Boolean
        */
        public Boolean fillFields(Milestone__c milestone) {
            Boolean modified = false;

            if(milestone.Intacct_Resource_Id__c != this.Id) {
                milestone.Intacct_Resource_Id__c = this.Id;
                modified = true;
            }

            return modified;
        }
    }


    /************************ MILESTONE ***********************/
            
    /**
    * @description Milestone
    */
    public class Milestone extends Response implements IXml {
        public String RecordNumber {get; set;}
        public String Id {get; set;}
        public String ProjectId {get; set;}
        public String Name {get; set;}        
        public Boolean IsActive {get; set;}
        public Boolean Billable {get; set;}
        public String ItemId {get; set;}
        public Double EstQty {get; set;}
        public String Utilized {get; set;}
               
        /**
        * @description Milestone - Constructor
        */
        public Milestone() {
            super();
        }
        
        /**
        * @description Milestone - Constructor
        * @param Milestone__c milestone
        */
        public Milestone(Milestone__c milestone) {
            this.Id = milestone.Intacct_Id__c;
            this.ProjectId = milestone.ProjectId__r.Intacct_Project_Id__c;
            this.Name = String.isNotBlank(milestone.Name) ? milestone.Name.escapeHtml4() : '';
            this.IsActive = milestone.IsActive__c;
            this.Billable = milestone.Is_Billable__c!=null ? milestone.Is_Billable__c : false;
            this.ItemId = milestone.ProductId__c != null && String.isNotBlank(milestone.ProductId__r.ProductCode) ? milestone.ProductId__r.ProductCode : '';
            this.EstQty = milestone.Hours_Currently_Budgeted__c != null ? milestone.Hours_Currently_Budgeted__c : 0;
            this.Utilized = 'true';
        }
            
        /**
        * @description Milestone - Constructor
        * @param String xml
        */
        public Milestone(String xml) {
            super(xml);
        }
        
        /**
        * @description toXML - 
        * @return String
        */
        public String toXML() {
            String xml = '';
            xml += '                    <TASK>';
            if(String.isNotBlank(Id)) {
                xml += '                        <RECORDNO>' + Id + '</RECORDNO>';
            }
            xml += '                        <NAME>' + IntacctUtils.cleanHtmlText(Name) + '</NAME>';
            xml += '                        <PROJECTID>' + ProjectId + '</PROJECTID>';
            xml += '                        <TASKSTATUS>' + (IsActive ? 'In Progress' : 'Not Started') + '</TASKSTATUS>'; // TODO: find out the values for the status
            xml += '                        <BILLABLE>' +  (Billable? 'true' : 'false') + '</BILLABLE>';
            xml += '                        <UTILIZED>' +  Utilized + '</UTILIZED>';
            xml += '                        <ITEMID>' +  ItemId + '</ITEMID>';
            xml += '                        <ESTQTY>' +  String.valueOf(ESTQTY) + '</ESTQTY>';
            xml += '                        <PBEGINDATE></PBEGINDATE>';
            xml += '                        <PENDDATE></PENDDATE>';
            xml += '                    </TASK>';
           
            return xml;
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
            Dom.XMLNode milestoneXml = dataXml.getChildElement('task',null);
            Dom.XMLNode recordnoXml = milestoneXml.getChildElement('RECORDNO',null);
            RecordNumber = recordnoXml.getText();
            Id = RecordNumber;
            // Dom.XMLNode taskidXml = milestoneXml.getChildElement('TASKID',null);
            // Id = taskidXml.getText();
        }

        /**
        * @description fillFields - 
        * @param Milestone__c milestone
        * @return Boolean
        */
        public Boolean fillFields(Milestone__c milestone) {
            Boolean modified = false;

            if(milestone.Intacct_Id__c != this.Id) {
                milestone.Intacct_Id__c = this.Id;
                modified = true;
            }

            if(milestone.Intacct_Sync_Status__c != 'OK') {
                milestone.Intacct_Sync_Status__c = 'OK';
                milestone.Intacct_Sync_Errors__c = null;
                modified = true;
            }

            return modified;
        }
    }



    /************************ TIME CARD ENTRY ***********************/


    /**
    * @description
    */
    public class TimeCardHeader extends Response implements IXml {
        public String RecordNumber {get; set;}
        public String Id {get; set;}
        public Date BeginDate {get; set;}
        public String EmployeeId {get; set;}
        public String LocationId {get; set;}
        public String State {get; set;}
        public List<TimeCardEntry> TimeCardEntries {get; private set;}
        
        /**
        * @description TimeCardHeader - Constructor
        */
        public TimeCardHeader() {
            super();
        }
       
        /**
        * @description TimeCardHeader - Constructor
        * @param Time_Card_Header__c timeCardHeader
        */ 
        public TimeCardHeader(Time_Card_Header__c timeCardHeader) {
            if(String.isNotBlank(timeCardHeader.Intacct_Id__c)) this.Id = timeCardHeader.Intacct_Id__c;
            this.BeginDate = timeCardHeader.Start_Date__c;
            this.EmployeeId = timeCardHeader.UserId__r.Intacct_Id__c;
            this.LocationId = timeCardHeader.UserId__r.Intacct_Entity_Id__c;
            this.State = 'Submitted';
            TimeCardEntries = new List<TimeCardEntry>();
            for(Time_Card_Entry__c timeCardEntry : timeCardHeader.Time_Card_Entries__r) {
                if(timeCardEntry.ProjectId__c == null || String.isBlank(timeCardEntry.ProjectId__r.Intacct_Project_Id__c) ||
                   timeCardEntry.MilestoneId__c == null || String.isBlank(timeCardEntry.MilestoneId__r.Intacct_Id__c)) continue;
                 TimeCardEntries.add(new TimeCardEntry(timeCardEntry));
            }
        }

        /**
        * @description TimeCardHeader - Constructor
        * @param String xml
        */
        public TimeCardHeader(String xml) {
            super(xml);
        }

        /**
        * @description toXML - 
        * @return String
        */
        public String toXML() {
            String xml = '';
            xml += '                    <TIMESHEET>';
            if(String.isNotBlank(Id)) {
                xml += '                        <RECORDNO>' + Id + '</RECORDNO>';
            }
            xml += '                        <EMPLOYEEID>' + EmployeeId + '</EMPLOYEEID>';
            xml += '                        <LOCATIONID>' + LocationId + '</LOCATIONID>';
            xml += '                        <BEGINDATE>' + IntacctUtils.formatDate(BeginDate) + '</BEGINDATE>';
            xml += '                        <STATE>' + State + '</STATE>';
            xml += '                        <TIMESHEETENTRIES>';

            for(TimeCardEntry timeCardEntry : TimeCardEntries) {
                xml += timeCardEntry.toXML();
            }

            xml += '                        </TIMESHEETENTRIES>';
            xml += '                    </TIMESHEET>';

            return xml;
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
            Dom.XMLNode timeSheetXml = dataXml.getChildElement('timesheet',null);
            Dom.XMLNode recordnoXml = timeSheetXml.getChildElement('RECORDNO',null);

            if(String.isBlank(Id)) {
                Id = recordnoXml.getText();
            }
        }

        /**
        * @description fillFields - 
        * @param Milestone__c milestone
        * @return Boolean
        */
        public Boolean fillFields(Time_Card_Header__c timeCardHeader) {
            Boolean modified = false;

            if(timeCardHeader.Intacct_Id__c != this.Id) {
                timeCardHeader.Intacct_Id__c = this.Id;
                modified = true;
            }

            if(timeCardHeader.Intacct_Sync_Status__c != 'OK') {
                timeCardHeader.Intacct_Sync_Status__c = 'OK';
                timeCardHeader.Intacct_Sync_Errors__c = null;
                modified = true;
            }

            for(Time_Card_Entry__c timeCardEntry : timeCardHeader.Time_Card_Entries__r) {
                if(timeCardEntry.ProjectId__c != null && String.isNotBlank(timeCardEntry.ProjectId__r.Intacct_Project_Id__c) &&
                    timeCardEntry.MilestoneId__c != null && String.isNotBlank(timeCardEntry.MilestoneId__r.Intacct_Id__c)) {
                    if(String.isBlank(timeCardEntry.Intacct_Id__c)) {
                        timeCardEntry.Intacct_Id__c = IntacctIntegrationService.getTimeSheetEntryId(timeCardHeader.Intacct_Id__c, timeCardEntry.Id);
                        modified = true;
                    }
                    if(timeCardEntry.Intacct_Sync_Status__c != 'OK') {
                        timeCardEntry.Intacct_Sync_Status__c = 'OK';
                        timeCardEntry.Intacct_Sync_Errors__c = null;
                        modified = true;
                    }
                }
                else {
                    if(String.isNotBlank(timeCardEntry.Intacct_Sync_Status__c)) {
                        timeCardEntry.Intacct_Sync_Status__c = null;
                        timeCardEntry.Intacct_Sync_Errors__c = null;
                        modified = true;
                    }
                }

            }

            return modified;
        }
    }

    /**
    * @description
    */
    public class TimeCardEntry extends Response implements IXml {
        public String SalesforceId {get; set;}
        public String RecordNumber {get; set;}
        public String TimeSheetId {get; set;}
        public String Id {get; set;}
        public String SalesforceProjectId {get; set;}
        public Date BeginDate {get; set;}
        public Date EntryDate {get; set;}
        public String Description {get; set;}
        public String Notes {get; set;}
        public String ProjectId {get; set;}
        public String TaskId {get; set;}
        public String EmployeeId {get; set;}
        public String LocationId {get; set;}
        public Decimal Quantity {get; set;}
        public Boolean Billable {get; set;}
        public String ContractId {get; set;}
        public String RevenueStream {get; set;}
        public String RevenueDivision {get; set;}

        /**
        * @description TimeCardEntry - Constructor
        */ 
        public TimeCardEntry() {
            super();
        }

        /**
        * @description TimeCardEntry - Constructor
        * @param Time_Card_Entry__c timeCardEntry
        */         
        public TimeCardEntry(Time_Card_Entry__c timeCardEntry) {
            if(String.isNotBlank(timeCardEntry.Intacct_Id__c)) this.Id = timeCardEntry.Intacct_Id__c;
            this.SalesforceId = timeCardEntry.Id;
            this.SalesforceProjectId = timeCardEntry.ProjectId__c;
            this.LocationId = timeCardEntry.Time_Card_HeaderId__r.UserId__r.Intacct_Entity_Id__c;
            this.ProjectId = timeCardEntry.ProjectId__r.Intacct_Project_Id__c;
            this.TaskId = timeCardEntry.MilestoneId__r.Intacct_Id__c;
            this.Notes = String.isNotBlank(timeCardEntry.Notes__c) ? timeCardEntry.Notes__c : '';
            this.Quantity = timeCardEntry.Hours_Entered__c;
            this.EntryDate = timeCardEntry.Date_Entered__c;
            this.Billable = true;
            this.ContractId = String.isNotBlank(timeCardEntry.ProjectId__r.OpportunityId__r.Contract.ia_crm__Intacct_Contract__r.ia_crm__Contract_ID__c) ? timeCardEntry.ProjectId__r.OpportunityId__r.Contract.ia_crm__Intacct_Contract__r.ia_crm__Contract_ID__c : '';
            this.RevenueStream = 'Services';
            this.RevenueDivision = timeCardEntry.MilestoneId__c != null && timeCardEntry.MilestoneId__r.ProductId__c != null && String.isNotBlank(timeCardEntry.MilestoneId__r.ProductId__r.LOB__c) ? timeCardEntry.MilestoneId__r.ProductId__r.LOB__c : '';
        }
                    
        /**
        * @description toXML - 
        * @return String
        */
        public String toXML() {
            String xml = '';
            xml += '                            <TIMESHEETENTRY>';
            if(String.isNotBlank(Id)) {
                xml += '                                <RECORDNO>' + Id + '</RECORDNO>';
            }
            xml += '                                <LOCATIONID>' + LocationId + '</LOCATIONID>';
            xml += '                                <ENTRYDATE>' + IntacctUtils.formatDate(EntryDate) + '</ENTRYDATE>';
            xml += '                                <QTY>' + String.valueOf(Quantity) + '</QTY>';
            xml += '                                <BILLABLE>' + (Billable? 'true' : 'false') + '</BILLABLE>';
            xml += '                                <PROJECTID>' + ProjectId + '</PROJECTID>';
            xml += '                                <DESCRIPTION>' + '' + '</DESCRIPTION>';
            xml += '                                <SFDC_PROJECT_ID>' + SalesforceId + '</SFDC_PROJECT_ID>';            
            xml += '                                <TASKKEY>' + TaskId + '</TASKKEY>';
            xml += '                                <NOTES>' + IntacctUtils.cleanHtmlText(Notes.Left(2000).escapeHtml4()) + '</NOTES>';
            xml += '                                <GLDIMRevenue_Division>' + IntacctIntegrationService.getRevenueDivisionId(RevenueDivision) + '</GLDIMRevenue_Division>';
            xml += '                                <CONTRACTID>' + ContractId + '</CONTRACTID>'; 
            xml += '                                <CLASSID>' + RevenueStream + '</CLASSID>';
            xml += '                            </TIMESHEETENTRY>';
            
            return xml;
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
        }

    }

    /**
    * @description TimeSheetEntryQuery
    */
    public class TimeSheetEntryQuery implements IXml {
        public String TimeSheetId {get; set;}
        public Id TimeCardEntryId {get; set;}

        /**
        * @description TimeCardHeader - Constructor
        * @param String timeSheetId
        * @param Id timeCardEntryId
        */ 
        public TimeSheetEntryQuery(String timeSheetId, Id timeCardEntryId) {
            this.TimeSheetId = timeSheetId;
            this.TimeCardEntryId = timeCardEntryId;
        }

        /**
        * @description toXML - 
        * @return String
        */
        public String toXML() {
            String xml = '';
            xml += '                    <object>TIMESHEETENTRY</object>';
            xml += '                    <fields>*</fields>';
            xml += '                    <query>TIMESHEETKEY = \'' +  TimeSheetId + '\' AND SFDC_PROJECT_ID = \'' + TimeCardEntryId + '\'</query>';

            return xml;
        }
    }

    /**
    * @description TimeSheetEntryQueryResponse
    */
    public class TimeSheetEntryQueryResponse extends Response {
        public String Id {get; set;}

        /**
        * @description TimeSheetEntryQueryResponse - Constructor
        */
        public TimeSheetEntryQueryResponse(String xml) {
            super(xml);
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
            Dom.XMLNode timesheetentryXml = dataXml.getChildElement('timesheetentry',null);
            Dom.XMLNode recordnoXml = timesheetentryXml.getChildElement('RECORDNO',null);
            Id = recordnoXml.getText();
        }
    }

    /**
    * @description
    */
    public class RevenueDivisionQuery implements IXml {
        public String RevenueDivisionName {get; set;}

        /**
        * @description RevenueDivisionQuery - Constructor
        * @param String revenueDivisionName
        */
        public RevenueDivisionQuery(String revenueDivisionName) {
            this.RevenueDivisionName = revenueDivisionName;
        }

        /**
        * @description toXML - 
        * @return String
        */
        public String toXML() {
            String xml = '';
            xml += '                    <object>revenue_division</object>';
            xml += '                    <fields>name,id</fields>';
            xml += '                    <query>name = \'' +  RevenueDivisionName + '\'</query>';
            
            return xml;
        }
    }

    /**
    * @description
    */
    public class RevenueDivisionResponse extends Response {
        public String Id {get; set;}

        /**
        * @description RevenueDivisionResponse - Constructor
        */
        public RevenueDivisionResponse(String xml) {
            super(xml);
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
            Id = '';
            Dom.XMLNode revenue_divisionXml = dataXml.getChildElement('revenue_division',null);
            if(revenue_divisionXml == null) return;

            Dom.XMLNode idXml = revenue_divisionXml.getChildElement('id',null);
            Id = idXml.getText();            
        }
    }
    
    /************************ CONTRACT LINES ***********************/
    
    /**
    * @description
    */
    public class ContractLine extends Response implements IXml {
        public String Id {get; set;}
        public String LineNumber {get; set;}
        public String ContractId {get; set;}                
        public String ProjectId {get; set;}

        /**
        * @description ContractLine - Constructor
        */
        public ContractLine() {
            super();
        }
        
        /**
        * @description ContractLine - Constructor
        * @param ia_crm__Intacct_Contract_Line__c contractLine
        */
        public ContractLine(ia_crm__Intacct_Contract_Line__c contractLine) {
            this.LineNumber = contractLine.ia_crm__Line_number__c;
            this.ContractId = contractLine.ia_crm__Intacct_Contract__r.ia_crm__Contract_ID__c;
            this.ProjectId = contractLine.ProjectId__r.Intacct_Project_Id__c;
        }

        /**
        * @description ContractLine - Constructor
        * @param String xml
        */               
        public ContractLine(String xml) {
            super(xml);
        }

        /**
        * @description toXML - 
        * @return String
        */
        public String toXML() {
            Id = IntacctIntegrationService.getContractLineId(ContractId, LineNumber);
                
            String xml = '';
            xml += '                    <CONTRACTDETAIL>';
            xml += '                        <RECORDNO>' + Id + '</RECORDNO>';
            xml += '                        <PROJECTID>' + ProjectId + '</PROJECTID>';
            xml += '                    </CONTRACTDETAIL>';
           
            return xml;
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
            
        }

        /**
        * @description fillFields - 
        * @param ia_crm__Intacct_Contract_Line__c contractLine
        * @return Boolean
        */
        public Boolean fillFields(ia_crm__Intacct_Contract_Line__c contractLine) {
            Boolean modified = false;
            if(contractLine.Intacct_Sync_Status__c != 'OK') {
                contractLine.Intacct_Sync_Status__c = 'OK';
                contractLine.Intacct_Sync_Errors__c = null;
                modified = true;
            }
            return modified;
        }
    }
    
    /**
    * @description ContractLineQuery
    */
    public class ContractLineQuery implements IXml {
        public String ContractId {get; set;}
        public String LineNumber {get; set;}


        /**
        * @description ContractLineQuery - Constructor
        */
        public ContractLineQuery(String contractId, String lineNumber) {
            this.ContractId = contractId;
            this.LineNumber = lineNumber;
        }

        /**
        * @description toXML - 
        * @return String
        */
        public String toXML() {
            String xml = '';
            xml += '                    <object>CONTRACTDETAIL</object>';
            xml += '                    <fields>RECORDNO</fields>';
            xml += '                    <query>CONTRACTID = \'' +  ContractId + '\' AND LINENO = \'' + LineNumber + '\'</query>';

            return xml;
        }
    }

    /**
    * @description ContractLineQueryResponse
    */
    public class ContractLineQueryResponse extends Response {
        public String Id {get; set;}

        /**
        * @description ContractLineQueryResponse - Constructor
        */
        public ContractLineQueryResponse(String xml) {
            super(xml);
        }

        /**
        * @description override parseData - 
        * @param Dom.XMLNode dataXml
        * @return void
        */
        protected override void parseData(Dom.XMLNode dataXml) {
            Id = '';

            Dom.XMLNode contractdetailXml = dataXml.getChildElement('contractdetail',null);
            if(contractdetailXml == null) return;

            Dom.XMLNode recordnoXml = contractdetailXml.getChildElement('RECORDNO',null);
            Id = recordnoXml.getText();            
        }
    }


}