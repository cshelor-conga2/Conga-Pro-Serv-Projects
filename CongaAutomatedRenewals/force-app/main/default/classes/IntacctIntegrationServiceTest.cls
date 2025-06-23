/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IntacctIntegrationServiceTest - Test class for the IntacctIntegrationService class
*/
@isTest
public class IntacctIntegrationServiceTest {
    public static Integer timeSheetid = 153;

    /**
    * @description setup - Setup test data
    */
    @testSetup
    public static void setup() {
        IntacctSyncHelper.runOnTest = true;

        User currentUser = [select timezonesidkey from User where Id = :UserInfo.getUserId()];
        
        // create user
        Profile pfl = [select Id from Profile where Name='Standard User' limit 1];        
        User testUser = new User(Alias = 'test', Email='test@googletestorg.com', EmailEncodingKey='UTF-8', LastName='Testing', 
                                 LanguageLocaleKey='en_US', LocaleSidKey='en_US', Profileid = pfl.Id,  Division = 'US',
                                 CommunityNickname = 'test', TimezonesIdKey=currentUser.timezonesidkey, Username='test@googletestorg.com',
                                 Intacct_Id__c = 'test', Intacct_Entity_Id__c = 'ALLC');
        insert testUser;

        /*// products
        Product2 p1  = new Product2(Name = 'S1', ProductCode = 'S1', Family = 'Professional Services');
        insert new Product2[] { p1 };

        // pricebook entries
        PricebookEntry pbe1  = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = p1.Id,  IsActive = true, UnitPrice = 100);
        insert new PricebookEntry[] { pbe1 };

        // opportunity record types
        Map<String,RecordType> opportunityRecordTypeNameToRecordTypeMap = getOpportunityRecordTypesMap();
        System.assertNotEquals(null,opportunityRecordTypeNameToRecordTypeMap.get('Direct'),'Opportunity RecordType "Direct" does not exist');
        System.assertNotEquals(null,opportunityRecordTypeNameToRecordTypeMap.get('Indirect'),'Opportunity RecordType "Indirect" does not exist');

        // opportunities
        Opportunity op1 = new Opportunity(AccountId = a1.Id, Name = 'Direct', StageName = 'Closed Won', CloseDate = Date.today(), Type = 'New Business', LeadSource = 'Advertisement', RecordTypeId = opportunityRecordTypeNameToRecordTypeMap.get('Direct').Id, PriceBook2Id = Test.getStandardPricebookId());
        insert new Opportunity[] { op1 };

        // opportunity line items
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = op1.Id, PricebookEntryId = pbe1.Id, Description = 'Product 1', UnitPrice = pbe1.UnitPrice / 2, Quantity = 1, ServiceDate = Date.today(), Product_End_Date__c = Date.today().addDays(10));
        insert new OpportunityLineItem[] { oli1 };*/

        // period
        Date initDate = Date.today().toStartOfWeek();
        Date endDate = initDate.addDays(7);
        Period__c period1 = new Period__c(Name = 'TestPeriod', Type__c = 'Week', Start_Date__c = initDate, End_Date__c = endDate);
        insert new Period__c[] { period1 };

        // custom settings
        insertSettings();
    }

    /**
    * @description testGetSession - 
    */
    private static testmethod void testGetSession() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        Test.startTest();

        IntacctDataModel.IntacctSession session = IntacctIntegrationService.getSession();

        Test.stopTest();

        System.assertEquals('7SZw9WbhftHAxcr0vbtPKvuL0cHFyg..', session.sessionId);
        System.assertEquals('https://api.intacct.com/ia/xml/xmlgw.phtml', session.endPoint);

    }

    /**
    * @description testSettingsMissingError - 
    */
    private static testmethod void testSettingsMissingError() {

        deleteSettings();
        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        String errorMessage = null;
        Test.startTest();

        try {
            IntacctDataModel.IntacctSession session = IntacctIntegrationService.getSession();
        }
        catch (exception e) {
            errorMessage = e.getMessage();
        }

        Test.stopTest();

        System.assertNotEquals(null, errorMessage);
        System.assertEquals(label.INTACCT_Error_Settings, errorMessage);
    }

    /**
    * @description testSyncProject - 
    */
    private static testmethod void testSyncProject() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();
        PS_Project__c project = insertTestProject();

        Test.startTest();

        new IntacctIntegrationService.SetStatusPending().resolve(new IntacctIntegrationService.IntacctObjectSync(project));
        syncProject(project.Id);

        Test.stopTest();

        project = getProjectById(project.Id);

        System.assertEquals('OK', project.Intacct_Sync_Status__c);
        System.assertEquals('103', project.Intacct_Id__c);
        System.assertEquals('P-86', project.Intacct_Project_Id__c);
    }

    /**
    * @description testSyncProjectTeam - 
    */
    private static testmethod void testSyncProjectTeam() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        Contact c = new Contact(LastName = 'Test');
        insert c;

        sessionInitialize();
        PS_Project__c project = insertTestProject();

        Test.startTest();

        insert new Project_Team__c(Project__c = project.Id, Role__c = 'Billing Contact', Contact__c = c.Id);

        Test.stopTest();

    }

    /**
    * @description testSyncProjectResource - 
    */
    private static testmethod void testSyncProjectResource() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();
        PS_Project__c project = insertTestProject();
        Milestone__c milestone = insertTestMilestone(project.Id);

        Test.startTest();

        new IntacctIntegrationService.SetStatusPending().resolve(new IntacctIntegrationService.IntacctObjectSync(project));
        syncProject(project.Id);

        Test.stopTest();

        project = getProjectById(project.Id);
        System.assertEquals('OK', project.Intacct_Sync_Status__c);
        System.assertEquals('103', project.Intacct_Id__c);
        System.assertEquals('P-86', project.Intacct_Project_Id__c);

        milestone = getMilestoneById(milestone.Id);
        System.assertEquals('94', milestone.Intacct_Resource_Id__c);
    }

    /**
    * @description testSyncProjectError - 
    */
    private static testmethod void testSyncProjectError() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();
        PS_Project__c project = insertTestProject();
        project.Intacct_Id__c = 'error';
        project.Intacct_Project_Id__c = 'error';
        project.Intacct_Sync_Status__c = 'In Process';
        update project;

        Test.startTest();

        syncProjectWithError(project.Id);

        Test.stopTest();

        project = getProjectById(project.Id);

        System.assertEquals('Error', project.Intacct_Sync_Status__c);
        System.assert(project.Intacct_Sync_Errors__c.contains('There was an error processing the request'));
        System.assertEquals('error', project.Intacct_Id__c);
        System.assertEquals('error', project.Intacct_Project_Id__c);
    }

    /**
    * @description testSyncMilestone - 
    */
    private static testmethod void testSyncMilestone() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();
        PS_Project__c project = insertTestProject();
        Milestone__c milestone = insertTestMilestone(project.Id);

        Test.startTest();

        new IntacctIntegrationService.SetStatusPending().resolve(new IntacctIntegrationService.IntacctObjectSync(milestone));
        syncMilestone(milestone.Id);

        Test.stopTest();

        milestone = getMilestoneById(milestone.Id);

        System.assertEquals('OK', milestone.Intacct_Sync_Status__c);
        System.assertEquals('73', milestone.Intacct_Id__c);
    }

    /**
    * @description testSyncMilestoneError - 
    */
    private static testmethod void testSyncMilestoneError() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();
        PS_Project__c project = insertTestProject();
        Milestone__c milestone = insertTestMilestone(project.Id);
        milestone.Intacct_Id__c = 'error';
        milestone.Intacct_Sync_Status__c = 'In Process';
        update milestone;

        Test.startTest();

        new IntacctIntegrationService.SetStatusPending().resolve(new IntacctIntegrationService.IntacctObjectSync(milestone));
        syncMilestoneWithError(milestone.Id);

        Test.stopTest();

        milestone = getMilestoneById(milestone.Id);

        System.assertEquals('Error', milestone.Intacct_Sync_Status__c);
        System.assert(milestone.Intacct_Sync_Errors__c.contains('There was an error processing the request'));
        System.assertEquals('error', milestone.Intacct_Id__c);

    }

    /**
    * @description testSyncTimeCardHeader - 
    */
    private static testmethod void testSyncTimeCardHeader() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();
        PS_Project__c project = insertTestProject();
        project.Intacct_Project_Id__c = '1234';
        update project;
        Milestone__c milestone = insertTestMilestone(project.Id);
        milestone.Intacct_Id__c = '1234';
        update milestone;
        Time_Card_Header__c timeCardHeader = insertTestTimeCardHeader(project.Id, milestone.Id);

        Test.startTest();

        new IntacctIntegrationService.SetTimeCardStatusPending().resolve(new IntacctIntegrationService.IntacctObjectSync(timeCardHeader));
        syncTimeCardHeader(timeCardHeader.Id);

        Test.stopTest();

        timeCardHeader = getTimeCardHeaderById(timeCardHeader.Id);

        System.assertEquals('OK', timeCardHeader.Intacct_Sync_Status__c);
        System.assertEquals('67', timeCardHeader.Intacct_Id__c);
    }

    /**
    * @description testSyncTimeCardHeaderError - 
    */
    private static testmethod void testSyncTimeCardHeaderError() {

        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();
        PS_Project__c project = insertTestProject();
        project.Intacct_Project_Id__c = '1234';
        update project;
        Milestone__c milestone = insertTestMilestone(project.Id);
        milestone.Intacct_Id__c = '1234';
        update milestone;
        Time_Card_Header__c timeCardHeader = insertTestTimeCardHeader(project.Id, milestone.Id);
        timeCardHeader.Intacct_Id__c = 'error';
        timeCardHeader.Intacct_Sync_Status__c = 'In Process';

        Test.startTest();

        new IntacctIntegrationService.SetTimeCardStatusPending().resolve(new IntacctIntegrationService.IntacctObjectSync(timeCardHeader));
        syncTimeCardHeaderWithError(timeCardHeader.Id);

        Test.stopTest();

        timeCardHeader = getTimeCardHeaderById(timeCardHeader.Id);

        System.assertEquals('Error', timeCardHeader.Intacct_Sync_Status__c);
        System.assert(timeCardHeader.Intacct_Sync_Errors__c.contains('There was an error processing the request'));
        System.assertEquals('error', timeCardHeader.Intacct_Id__c);
    }

    /**
    * @description testSyncIntacctContractLine - 
    */
    private static testmethod void testSyncIntacctContractLine() {
        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();

        List<Opportunity> opportunities = setupOpportunities();
        System.assertEquals(false, opportunities.isEmpty());


        PS_Project__c project = insertTestProject();
        project.OpportunityId__c = opportunities[0].Id;
        project.Intacct_Project_Id__c = 'P-86';
        update project;
        Milestone__c milestone = insertTestMilestone(project.Id);
        ia_crm__Intacct_Contract__c contract = insertTestIntacctContract();

        Test.startTest();

        ia_crm__Intacct_Contract_Line__c line = insertTestIntacctContractLine(contract.Id, opportunities[0].Id, project, milestone);
        new IntacctIntegrationService.SetStatusPending().resolve(new IntacctIntegrationService.IntacctObjectSync(line));
        syncIntacctContractLine(line.Id);

        Test.stopTest();

        line = getIntacctContractLineById(line.Id);

        System.assertEquals('OK', line.Intacct_Sync_Status__c);
    }

    /**
    * @description testSyncIntacctProject - 
    */
    private static testmethod void testSyncIntacctProject() {
        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();

        List<Opportunity> opportunities = setupOpportunities();
        System.assertEquals(false, opportunities.isEmpty());

        PS_Project__c project = insertTestProject();
        project.OpportunityId__c = opportunities[0].Id;
        project.Intacct_Project_Id__c = 'P-86';
        update project;
        Milestone__c milestone = insertTestMilestone(project.Id);
        milestone.ProductId__c = [select Id from Product2 where Name = 'S1'][0].Id;
        update milestone;

        Test.startTest();

        IntacctSyncHelper.runOnTest = true;
        ia_crm__Project__c intacctProject = new ia_crm__Project__c(
            ia_crm__Project_ID__c = 'P-86',
            Name = 'Test'
        );
        insert intacctProject;

        Test.stopTest();

        intacctProject = getIntacctProjectById(intacctProject.Id);
        System.assertEquals(project.Id, intacctProject.PS_Project__c);

        List<OpportunityLineItem> olis = getOpportunityLineItemsByOpportunityId(opportunities[0].Id);
        System.assertEquals(false, olis.isEmpty());
        for(OpportunityLineItem oli : olis) {
            System.assertEquals(intacctProject.Id,oli.ia_crm__Project__c);
        }
    }

    /**
    * @description testSyncIntacctTask - 
    */
    private static testmethod void testSyncIntacctTask() {
        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        sessionInitialize();

        List<Opportunity> opportunities = setupOpportunities();
        System.assertEquals(false, opportunities.isEmpty());

        PS_Project__c project = insertTestProject();
        project.OpportunityId__c = opportunities[0].Id;
        project.Intacct_Project_Id__c = 'P-86';
        update project;
        Milestone__c milestone = insertTestMilestone(project.Id);
        milestone.ProductId__c = [select Id from Product2 where Name = 'S1'][0].Id;
        update milestone;

        ia_crm__Project__c intacctProject = new ia_crm__Project__c(
            ia_crm__Project_ID__c = 'P-86',
            Name = 'Test'
        );
        insert intacctProject;

        Test.startTest();

        IntacctSyncHelper.runOnTest = true;
        IntacctSyncHelper.syncingIntacctProjects = false;
        ia_crm__Task__c intacctTask = new ia_crm__Task__c(
            ia_crm__Project__c = intacctProject.Id,
            Name = milestone.Name
        );
        insert intacctTask;
        update intacctTask;

        Test.stopTest();

        intacctProject = getIntacctProjectById(intacctProject.Id);
        System.assertEquals(project.Id, intacctProject.PS_Project__c);

        List<OpportunityLineItem> olis = getOpportunityLineItemsByOpportunityId(opportunities[0].Id);
        System.assertEquals(false, olis.isEmpty());
        for(OpportunityLineItem oli : olis) {
            System.assertEquals(intacctProject.Id,oli.ia_crm__Project__c);
            System.assertEquals(intacctTask.Id,oli.ia_crm__Task__c);
        }
    }

    /**
    * @description testOthers - 
    */
    private static testmethod void testOthers() {
        Test.setMock(HttpCalloutMock.class, new IntacctServicesMock());

        PS_Project__c project = insertTestProject();
        Milestone__c milestone = insertTestMilestone(project.Id);
        Time_Card_Header__c timeCardHeader = insertTestTimeCardHeader(project.Id, milestone.Id);
        Contact c = new Contact(LastName = 'Test');
        insert c;
        Project_Team__c pt = new Project_Team__c(Project__c = project.Id, Role__c = 'Billing Contact', Contact__c = c.Id);
        insert pt;
        Test.startTest();

        pt.Role__c = 'Administrator';
        update pt;

        delete [SELECT Id FROM Time_Card_Entry__c WHERE Time_Card_HeaderId__c = :timeCardHeader.Id LIMIT 1];

        Test.stopTest();
    }

    /**
    * @description class IntacctServicesMock - 
    */
    private class IntacctServicesMock implements HttpCalloutMock {

        /**
        * @description respond - 
        * @param HttpRequest request
        * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);

            String operationName = getOperationName(request.getBody());

            if (operationName == 'GET_SESSION') {
                response.setBody(getSessionDefaultResponse());
                return response;
            }
            else if (operationName == 'CREATE_PROJECT') {
                response.setBody(getCreateProjectDefaultResponse());
                return response;
            }
            else if (operationName == 'CREATE_MILESTONE') {
                response.setBody(getCreateMilestoneDefaultResponse());
                return response;
            }
            else if (operationName == 'CREATE_PROJECTRESOURCES') {
                response.setBody(createProjectResourceDefaultResponse());
                return response;
            }
            else if (operationName == 'CREATE_TIMESHEET') {
                response.setBody(createTimesheetDefaultResponse());
                return response;
            }
            else if (operationName == 'GET_TIMESHEETENTRY') {
                response.setBody(getTimesheetEntryDefaultResponse());
                return response;
            }
            else if (operationName == 'GET_REVENUEDIVISION') {
                response.setBody(getRevenueDivisionDefaultResponse());
                return response;
            }
            else if (operationName == 'GET_CONTRACTDETAIL') {
                response.setBody(getContractDetailDefaultResponse());
                return response;
            }
            else if (operationName == 'UPDATE_CONTRACTDETAIL') {
                response.setBody(getUpdateContractDetailDefaultResponse());
                return response;
            }
            else if (operationName == 'ERROR') {
                response.setBody(getErrorDefaultResponse());
                return response;
            }
            else {
                response.setStatusCode(500);
                return response;
            }
        }

        /**
        * @description getOperationName - 
        * @param String xml
        * @return String
        */
        private String getOperationName(String xml) {
            String operationName = null;

            Dom.Document docXml = new Dom.Document();
            docXml.Load(xml);
            Dom.XMLNode rootElement = docXml.getRootElement();
            Dom.XMLNode operationNode = rootElement.getChildElement('operation', null);
            Dom.XMLNode contentNode = operationNode.getChildElement('content', null);
            Dom.XMLNode functionNode = contentNode.getChildElement('function',null);
            Dom.XMLNode[] childElements = functionNode.getChildElements();
            if (childElements.isEmpty()) {
                return null;
            }

            Dom.XMLNode node = childElements[0];
            if (node.getName() == 'getAPISession') {
                operationName = 'GET_SESSION';
            }
            else if(node.getName() == 'update') {
                Dom.XMLNode[] childNodes = node.getChildElements();
                if (childNodes.isEmpty()) {
                    return null;
                }
                Dom.XMLNode nodeType = childNodes[0];
                if (nodeType.getName() == 'PROJECT') {
                    if(nodeType.getChildElement('RECORDNO',null).getText() == 'error') {
                        operationName = 'ERROR';
                    }
                    else {
                        operationName = 'UPDATE_PROJECT';
                    }
                }
                else if (nodeType.getName() == 'TASK') {
                    if(nodeType.getChildElement('RECORDNO',null).getText() == 'error') {
                        operationName = 'ERROR';
                    }
                    else {
                        operationName = 'UPDATE_TASK';
                    }
                }
                else if (nodeType.getName() == 'TIMESHEET') {
                    if(nodeType.getChildElement('RECORDNO',null).getText() == 'error') {
                        operationName = 'ERROR';
                    }
                    else {
                        operationName = 'UPDATE_TIMESHEET';
                    }
                }
                else if (nodeType.getName() == 'CONTRACTDETAIL') {
                    if(nodeType.getChildElement('RECORDNO',null).getText() == 'error') {
                        operationName = 'ERROR';
                    }
                    else {
                        operationName = 'UPDATE_CONTRACTDETAIL';
                    }
                }
            }
            else if(node.getName() == 'create') {
                Dom.XMLNode[] childNodes = node.getChildElements();
                if (childNodes.isEmpty()) {
                    return null;
                }
                Dom.XMLNode nodeType = childNodes[0];
                if (nodeType.getName() == 'PROJECT') {
                    operationName = 'CREATE_PROJECT';
                }
                else if (nodeType.getName() == 'TASK') {
                    operationName = 'CREATE_MILESTONE';
                }
                else if (nodeType.getName() == 'PROJECTRESOURCES') {
                    operationName = 'CREATE_PROJECTRESOURCES';
                }
                else if (nodeType.getName() == 'TIMESHEET') {
                    operationName = 'CREATE_TIMESHEET';
                }
                else if (nodeType.getName() == 'TIMESHEET') {
                    operationName = 'CREATE_TIMESHEET';
                }
            }
            else if(node.getName() == 'readByQuery') {
                Dom.XMLNode objectNode = node.getChildElement('object',null);

                if (objectNode.getText() == 'revenue_division') {
                    operationName = 'GET_REVENUEDIVISION';
                }
                else if (objectNode.getText() == 'TIMESHEETENTRY') {
                    operationName = 'GET_TIMESHEETENTRY';
                }
                else if (objectNode.getText() == 'CONTRACTDETAIL') {
                    operationName = 'GET_CONTRACTDETAIL';
                }
            }

            return operationName;
        }

        /**
        * @description getSessionDefaultResponse - 
        * @return String
        */
        private String getSessionDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533826704092</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-09T07:58:24-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>getAPISession</function>';
            defaultResponse+= '         <controlid>cf9917cb-2c9e-481b-9661-e302dcdb4dc5</controlid>';
            defaultResponse+= '         <data>';
            defaultResponse+= '             <api>';
            defaultResponse+= '                 <sessionid>7SZw9WbhftHAxcr0vbtPKvuL0cHFyg..</sessionid>';
            defaultResponse+= '                 <endpoint>https://api.intacct.com/ia/xml/xmlgw.phtml</endpoint>';
            defaultResponse+= '             </api>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return  defaultResponse;
        }

        /**
        * @description getErrorDefaultResponse - 
        * @return String
        */
        private String getErrorDefaultResponse() {
            String defaultResponse = '';
            defaultResponse = '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse += '<response>';
            defaultResponse += '    <control>';
            defaultResponse += '        <status>success</status>';
            defaultResponse += '        <senderid>Conga</senderid>';
            defaultResponse += '        <controlid>1534419684</controlid>';
            defaultResponse += '        <uniqueid>false</uniqueid>';
            defaultResponse += '        <dtdversion>3.0</dtdversion>';
            defaultResponse += '    </control>';
            defaultResponse += '    <operation>';
            defaultResponse += '        <authentication>';
            defaultResponse += '            <status>success</status>';
            defaultResponse += '            <userid>salesforce</userid>';
            defaultResponse += '            <companyid>Conga-imp</companyid>';
            defaultResponse += '            <sessiontimestamp>2018-08-16T04:41:30-07:00</sessiontimestamp>';
            defaultResponse += '        </authentication>';
            defaultResponse += '        <result>';
            defaultResponse += '            <status>failure</status>';
            defaultResponse += '            <function>read</function>';
            defaultResponse += '            <controlid>05eb59f0-aadf-48fd-ae70-0f0f3308b8f0</controlid>';
            defaultResponse += '            <errormessage>';
            defaultResponse += '                <error>';
            defaultResponse += '                    <errorno>DL02000001</errorno>';
            defaultResponse += '                    <description>Error</description>';
            defaultResponse += '                    <description2>There was an error processing the request.</description2>';
            defaultResponse += '                    <correction></correction>';
            defaultResponse += '                </error>';
            defaultResponse += '            </errormessage>';
            defaultResponse += '        </result>';
            defaultResponse += '    </operation>';
            defaultResponse += '</response>';
            return defaultResponse;
        }

        /**
        * @description getCreateProjectDefaultResponse - 
        * @return String
        */
        private String getCreateProjectDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533887167864</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T00:46:08-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>create</function>';
            defaultResponse+= '         <controlid>98628795-70a3-4d90-823e-515009f1d136</controlid>';
            defaultResponse+= '         <data listtype="objects" count="1">';
            defaultResponse+= '             <project>';
            defaultResponse+= '                 <RECORDNO>103</RECORDNO>';
            defaultResponse+= '                 <PROJECTID>P-86</PROJECTID>';
            defaultResponse+= '             </project>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }

        /**
        * @description getUpdateProjectDefaultResponse - 
        * @return String
        */
        private String getUpdateProjectDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533887167864</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T00:46:08-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>create</function>';
            defaultResponse+= '         <controlid>98628795-70a3-4d90-823e-515009f1d136</controlid>';
            defaultResponse+= '         <data listtype="objects" count="1">';
            defaultResponse+= '             <project>';
            defaultResponse+= '                 <RECORDNO>103</RECORDNO>';
            defaultResponse+= '                 <PROJECTID>P-86</PROJECTID>';
            defaultResponse+= '             </project>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }

        /**
        * @description getCreateMilestoneDefaultResponse - 
        * @return String
        */
        private String getCreateMilestoneDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533912148287</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T07:42:28-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>create</function>';
            defaultResponse+= '         <controlid>34631b0b-d797-4bd7-a6bf-6e6a97ed1861</controlid>';
            defaultResponse+= '         <data listtype="objects" count="1">';
            defaultResponse+= '             <task>';
            defaultResponse+= '                 <RECORDNO>73</RECORDNO>';
            defaultResponse+= '             </task>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }

        /**
        * @description createProjectResourceDefaultResponse - 
        * @return String
        */
        private String createProjectResourceDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533914204326</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T08:16:44-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>create</function>';
            defaultResponse+= '         <controlid>f5633bab-813d-4ecd-9f69-c8ad0fd9cc8d</controlid>';
            defaultResponse+= '         <data listtype="objects" count="1">';
            defaultResponse+= '             <projectresources>';
            defaultResponse+= '                 <RECORDNO>94</RECORDNO>';
            defaultResponse+= '             </projectresources>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }

        /**
        * @description createTimesheetDefaultResponse - 
        * @return String
        */
        private String createTimesheetDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533918435368</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T09:27:16-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>create</function>';
            defaultResponse+= '         <controlid>ec016d10-620d-43d3-86ad-f7483226fef5</controlid>';
            defaultResponse+= '         <data listtype="objects" count="1">';
            defaultResponse+= '             <timesheet>';
            defaultResponse+= '                 <RECORDNO>67</RECORDNO>';
            defaultResponse+= '             </timesheet>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }

        /**
        * @description getTimesheetEntryDefaultResponse - 
        * @return String
        */
        private String getTimesheetEntryDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533918436379</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T09:27:16-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>readByQuery</function>';
            defaultResponse+= '         <controlid>7d56bca2-615e-42d4-9661-20cd0460bc3b</controlid>';
            defaultResponse+= '         <data listtype="timesheetentry" count="1" totalcount="1" numremaining="0" resultId="">';
            defaultResponse+= '             <timesheetentry>';
            defaultResponse+= '                 <RECORDNO>' + String.valueOf(IntacctIntegrationServiceTest.timeSheetid) + '</RECORDNO>';
            IntacctIntegrationServiceTest.timeSheetid++;
            defaultResponse+= '                 <LINENO>1</LINENO>';
            defaultResponse+= '                 <TIMESHEETKEY>67</TIMESHEETKEY>';
            defaultResponse+= '                 <PROJECTKEY>105</PROJECTKEY>';
            defaultResponse+= '                 <PROJECTID>P-88</PROJECTID>';
            defaultResponse+= '                 <PROJECTNAME>GM_20180810_002</PROJECTNAME>';
            defaultResponse+= '                 <PROJECT_CLASSID/>';
            defaultResponse+= '                 <TASKKEY>74</TASKKEY>';
            defaultResponse+= '                 <TASKNAME>ML-002</TASKNAME>';
            defaultResponse+= '                 <TASK_CLASSID/>';
            defaultResponse+= '                 <CUSTOMERKEY/>';
            defaultResponse+= '                 <CUSTOMERID/>';
            defaultResponse+= '                 <CUSTOMERNAME/>';
            defaultResponse+= '                 <ITEMKEY>587</ITEMKEY>';
            defaultResponse+= '                 <ITEMID>SOW -0001</ITEMID>';
            defaultResponse+= '                 <ITEMNAME>T&amp;M Custom SOW</ITEMNAME>';
            defaultResponse+= '                 <ENTRYDATE>08/10/2018</ENTRYDATE>';
            defaultResponse+= '                 <QTY>8</QTY>';
            defaultResponse+= '                 <DESCRIPTION/>';
            defaultResponse+= '                 <NOTES>GM - Test</NOTES>';
            defaultResponse+= '                 <STATE>Draft</STATE>';
            defaultResponse+= '                 <LOCATIONKEY>2</LOCATIONKEY>';
            defaultResponse+= '                 <LOCATIONID>ALLC</LOCATIONID>';
            defaultResponse+= '                 <LOCATIONNAME>AppExtremes , Inc DBA Conga</LOCATIONNAME>';
            defaultResponse+= '                 <DEPARTMENTKEY/>';
            defaultResponse+= '                 <DEPARTMENTID/>';
            defaultResponse+= '                 <DEPARTMENTNAME/>';
            defaultResponse+= '                 <TIMETYPEKEY/>';
            defaultResponse+= '                 <TIMETYPE/>';
            defaultResponse+= '                 <TIMETYPE_EARNINGTYPEKEY/>';
            defaultResponse+= '                 <TIMETYPE_GLACCOUNTKEY/>';
            defaultResponse+= '                 <TIMETYPE_GLOFFSETACCOUNTKEY/>';
            defaultResponse+= '                 <BILLABLE>true</BILLABLE>';
            defaultResponse+= '                 <BILLED>false</BILLED>';
            defaultResponse+= '                 <EMPLOYEEDIMKEY>17</EMPLOYEEDIMKEY>';
            defaultResponse+= '                 <EMPLOYEEID>gmodica</EMPLOYEEID>';
            defaultResponse+= '                 <EMPLOYEENAME>Modica, Giovanni</EMPLOYEENAME>';
            defaultResponse+= '                 <EMPLOYEE_EARNINGTYPEKEY/>';
            defaultResponse+= '                 <TS_BEGINDATE>08/05/2018</TS_BEGINDATE>';
            defaultResponse+= '                 <TS_ENDDATE>08/11/2018</TS_ENDDATE>';
            defaultResponse+= '                 <TS_GLPOSTDATE>08/11/2018</TS_GLPOSTDATE>';
            defaultResponse+= '                 <TS_LOCATIONKEY>2</TS_LOCATIONKEY>';
            defaultResponse+= '                 <TS_LOCATIONID>ALLC</TS_LOCATIONID>';
            defaultResponse+= '                 <STATJOURNALKEY/>';
            defaultResponse+= '                 <BILLUACCTKEY/>';
            defaultResponse+= '                 <NONBILLUACCTKEY/>';
            defaultResponse+= '                 <BILLNUACCTKEY/>';
            defaultResponse+= '                 <NONBILLNUACCTKEY/>';
            defaultResponse+= '                 <STATGLBATCHKEY/>';
            defaultResponse+= '                 <STATGLENTRYLINENO/>';
            defaultResponse+= '                 <LABORGLBATCHKEY/>';
            defaultResponse+= '                 <LABORGLENTRYLINENO/>';
            defaultResponse+= '                 <LABORGLENTRYOFFSETLINENO/>';
            defaultResponse+= '                 <LABORGLENTRYAMOUNT/>';
            defaultResponse+= '                 <LABORGLENTRYTRXAMOUNT/>';
            defaultResponse+= '                 <LABORGLENTRYCOSTRATE/>';
            defaultResponse+= '                 <STATGLENTRYAMOUNT/>';
            defaultResponse+= '                 <VARGLENTRYAMOUNT/>';
            defaultResponse+= '                 <VARGLENTRYTRXAMOUNT/>';
            defaultResponse+= '                 <VARGLBATCHKEY/>';
            defaultResponse+= '                 <VARGLENTRYLINENO/>';
            defaultResponse+= '                 <VARGLENTRYOFFSETLINENO/>';
            defaultResponse+= '                 <CLZNAMOUNT/>';
            defaultResponse+= '                 <EXTCOSTRATE/>';
            defaultResponse+= '                 <EXTBILLRATE/>';
            defaultResponse+= '                 <WHENCREATED>08/10/2018 16:27:16</WHENCREATED>';
            defaultResponse+= '                 <WHENMODIFIED>08/10/2018 16:27:16</WHENMODIFIED>';
            defaultResponse+= '                 <CREATEDBY>65</CREATEDBY>';
            defaultResponse+= '                 <MODIFIEDBY>65</MODIFIEDBY>';
            defaultResponse+= '                 <BILLABLE_QTY>8</BILLABLE_QTY>';
            defaultResponse+= '                 <NON_BILLABLE_QTY>0</NON_BILLABLE_QTY>';
            defaultResponse+= '                 <APPROVED_QTY>0</APPROVED_QTY>';
            defaultResponse+= '                 <APPROVED_BILLABLE_QTY>0</APPROVED_BILLABLE_QTY>';
            defaultResponse+= '                 <APPROVED_NON_BILLABLE_QTY>0</APPROVED_NON_BILLABLE_QTY>';
            defaultResponse+= '                 <UTILIZED_QTY>8</UTILIZED_QTY>';
            defaultResponse+= '                 <NON_UTILIZED_QTY>0</NON_UTILIZED_QTY>';
            defaultResponse+= '                 <APPROVED_UTILIZED_QTY>0</APPROVED_UTILIZED_QTY>';
            defaultResponse+= '                 <APPROVED_NON_UTILIZED_QTY>0</APPROVED_NON_UTILIZED_QTY>';
            defaultResponse+= '                 <SFDC_PROJECT_ID>a1m1D000000IiqZQAS</SFDC_PROJECT_ID>';
            defaultResponse+= '                 <PROJECTDIMKEY>105</PROJECTDIMKEY>';
            defaultResponse+= '                 <VENDORDIMKEY/>';
            defaultResponse+= '                 <VENDORID/>';
            defaultResponse+= '                 <VENDORNAME/>';
            defaultResponse+= '                 <CLASSDIMKEY>1</CLASSDIMKEY>';
            defaultResponse+= '                 <CLASSID>Services</CLASSID>';
            defaultResponse+= '                 <CLASSNAME>Services Revenue</CLASSNAME>';
            defaultResponse+= '                 <CONTRACTDIMKEY/>';
            defaultResponse+= '                 <CONTRACTID/>';
            defaultResponse+= '                 <CONTRACTNAME/>';
            defaultResponse+= '                 <GLDIMREVENUE_DIVISION/>';
            defaultResponse+= '                 <RGLDIM165746_10020/>';
            defaultResponse+= '             </timesheetentry>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }

        /**
        * @description getRevenueDivisionDefaultResponse - 
        * @return String
        */
        private String getRevenueDivisionDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533918435368</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T09:27:16-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>create</function>';
            defaultResponse+= '         <controlid>ec016d10-620d-43d3-86ad-f7483226fef5</controlid>';
            defaultResponse+= '         <data listtype="objects" count="1">';
            defaultResponse+= '             <revenue_division>';
            defaultResponse+= '                 <id>15</id>';
            defaultResponse+= '             </revenue_division>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }
        /**
        * @description getContractDetailDefaultResponse - 
        * @return String
        */
        private String getContractDetailDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533918435368</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T09:27:16-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>create</function>';
            defaultResponse+= '         <controlid>ec016d10-620d-43d3-86ad-f7483226fef5</controlid>';
            defaultResponse+= '         <data listtype="objects" count="1">';
            defaultResponse+= '             <contractdetail>';
            defaultResponse+= '                 <RECORDNO>20</RECORDNO>';
            defaultResponse+= '             </contractdetail>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }

        /**
        * @description getUpdateContractDetailDefaultResponse - 
        * @return String
        */
        private String getUpdateContractDetailDefaultResponse() {
            String defaultResponse = '';
            defaultResponse+= '<?xml version="1.0" encoding="UTF-8"?>';
            defaultResponse+= '<response>';
            defaultResponse+= ' <control>';
            defaultResponse+= '     <status>success</status>';
            defaultResponse+= '     <senderid>Conga</senderid>';
            defaultResponse+= '     <controlid>1533918435368</controlid>';
            defaultResponse+= '     <uniqueid>false</uniqueid>';
            defaultResponse+= '     <dtdversion>3.0</dtdversion>';
            defaultResponse+= ' </control>';
            defaultResponse+= ' <operation>';
            defaultResponse+= '     <authentication>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <userid>salesforce</userid>';
            defaultResponse+= '         <companyid>Conga-imp</companyid>';
            defaultResponse+= '         <sessiontimestamp>2018-08-10T09:27:16-07:00</sessiontimestamp>';
            defaultResponse+= '     </authentication>';
            defaultResponse+= '     <result>';
            defaultResponse+= '         <status>success</status>';
            defaultResponse+= '         <function>create</function>';
            defaultResponse+= '         <controlid>ec016d10-620d-43d3-86ad-f7483226fef5</controlid>';
            defaultResponse+= '         <data listtype="objects" count="1">';
            defaultResponse+= '             <contractdetail>';
            defaultResponse+= '                 <RECORDNO>20</RECORDNO>';
            defaultResponse+= '             </contractdetail>';
            defaultResponse+= '         </data>';
            defaultResponse+= '     </result>';
            defaultResponse+= ' </operation>';
            defaultResponse+= '</response>';
            return defaultResponse;
        }
    }

    /**
    * @description setupOpportunities - 
    * @return List<Opportunity>
    */
    public static List<Opportunity> setupOpportunities() {
        // accounts
        Account a1 = new Account(Name = 'Test', BillingStreet = '390 Interlocken Crescent Suite 500', BillingCity = 'Broomfield', BillingState = 'Colorado', BillingPostalCode = '80021', BillingCountry = 'United States');
        insert new Account[] { a1 };

        // products
        Product2 p1  = new Product2(Name = 'S1', ProductCode = 'S1', Family = 'Professional Services');
        insert new Product2[] { p1 };

        // pricebook entries
        PricebookEntry pbe1  = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = p1.Id,  IsActive = true, UnitPrice = 100);
        insert new PricebookEntry[] { pbe1 };

        // opportunity record types
        Map<String,RecordType> opportunityRecordTypeNameToRecordTypeMap = getOpportunityRecordTypesMap();
        System.assertNotEquals(null,opportunityRecordTypeNameToRecordTypeMap.get('Direct'),'Opportunity RecordType "Direct" does not exist');
        System.assertNotEquals(null,opportunityRecordTypeNameToRecordTypeMap.get('Indirect'),'Opportunity RecordType "Indirect" does not exist');

        // opportunities
        Opportunity op1 = new Opportunity(AccountId = a1.Id, Name = 'Direct', StageName = 'Qualify', CloseDate = Date.today(), Type = 'New Business', LeadSource = 'Advertisement', RecordTypeId = opportunityRecordTypeNameToRecordTypeMap.get('Direct').Id, PriceBook2Id = Test.getStandardPricebookId());
        insert new Opportunity[] { op1 };

        // opportunity line items
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = op1.Id, PricebookEntryId = pbe1.Id, Description = 'Product 1', UnitPrice = pbe1.UnitPrice / 2, Quantity = 1, ServiceDate = Date.today(), Product_End_Date__c = Date.today().addDays(10));
        insert new OpportunityLineItem[] { oli1 };

        return new List<Opportunity> { op1 };
    }

    /**
    * @description insertSettings - 
    * @return void
    */
    private static void insertSettings() {
        Intacct_Integration_Settings__c settings = new Intacct_Integration_Settings__c(
            Company_Id__c = 'Conga-imp',
            Sender_Id__c = 'Conga',
            Sender_Password__c = 'Password1',
            User_Id__c = 'salesforce',
            User_Password__c = 'Password1'
        );
        insert settings;
    }

    /**
    * @description deleteSettings - 
    * @resultrn void
    */
    private static void deleteSettings() {
        Intacct_Integration_Settings__c[] settings = [
            SELECT
                Id
            FROM Intacct_Integration_Settings__c
        ];

        if(!settings.isEmpty()) {
            delete settings;
        }
    }

    /**
    * @description insertTestProject - 
    * @return PS_Project__c
    */
    public static PS_Project__c insertTestProject() {
        // accounts
        Account a1 = new Account(Name = 'Test Project', BillingStreet = '390 Interlocken Crescent Suite 500', BillingCity = 'Broomfield', BillingState = 'Colorado', BillingPostalCode = '80021', BillingCountry = 'United States');
        insert new Account[] { a1 };

        Id recordTypeId = getPSProjectRecordTypeId();
        System.assertNotEquals(null, recordTypeId);

        PS_Project__c project = new PS_Project__c(
            RecordTypeId = recordTypeId,
            Name = 'Test Project',
            Is_Active__c = true,
            AccountId__c = a1.Id
        );

        insert project;

        Contact c1 = new Contact(LastName = 'Test');
        insert c1;

        Project_Team__c t1 = new Project_Team__c(Project__c = project.Id, Contact__c = c1.Id, Role__c = 'Project Owner');
        Project_Team__c t2 = new Project_Team__c(Project__c = project.Id, Contact__c = c1.Id, Role__c = 'Billing Contact');
        insert new Project_Team__c[] { t1, t2 };

        return project;
    }

    /**
    * @description insertTestMilestone - 
    * @param Id projectId
    * @return Milestone__c
    */
    public static Milestone__c insertTestMilestone(Id projectId) {
        // products
        Product2 p1  = new Product2(Name = 'S2', ProductCode = 'S2', Family = 'Professional Services');
        insert new Product2[] { p1 };

        Milestone__c milestone = new Milestone__c(
            Name = 'Test Milestone',
            IsActive__c = true,
            Is_Billable__c = true,
            ProjectId__c = projectId,
            PricebookId__c = Test.getStandardPricebookId(),
            ProductId__c = p1.Id,
            Hours_Currently_Budgeted__c = 600,
            Value_Hourly_Rate__c = 100,
            Effective_Hourly_Rate__c = 150
        );

        insert milestone;
        return milestone;
    }

    /**
    * @description insertTestTimeCardHeader - 
    * @param Id projectId
    * @param Id milestoneId
    * @return Time_Card_Header__c
    */
    public static Time_Card_Header__c insertTestTimeCardHeader(Id projectId, Id milestoneId) {
        Period__c[] periods = getTestPeriods();
        System.assertEquals(false, periods.isEmpty());

        User[] users = getTestUsers();
        System.assertEquals(false, users.isEmpty());

        Time_Card_Header__c timeCardHeader = new Time_Card_Header__c(
            PeriodId__c = periods[0].Id,
            Status__c = 'Approved - Final', // this is required to sync
            UserId__c = users[0].Id
        );

        insert timeCardHeader;

        Time_Card_Entry__c entry1 = new Time_Card_Entry__c(
            ProjectId__c = projectId,
            MilestoneId__c = milestoneId,
            Date_Entered__c = periods[0].Start_Date__c,
            Time_Card_HeaderId__c = timeCardHeader.Id,
            Hours_Entered__c = 1,
            Notes__c = 'Notes'
        );
        Time_Card_Entry__c entry2 = new Time_Card_Entry__c(
            ProjectId__c = projectId,
            MilestoneId__c = milestoneId,
            Date_Entered__c = periods[0].Start_Date__c.addDays(1),
            Time_Card_HeaderId__c = timeCardHeader.Id,
            Hours_Entered__c = 2,
            Notes__c = 'Notes'
        );
        insert new Time_Card_Entry__c[] { entry1, entry2 };

        return timeCardHeader;
    }

    /**
    * @description insertTestIntacctContract - 
    * @return ia_crm__Intacct_Contract__c
    */
    public static ia_crm__Intacct_Contract__c insertTestIntacctContract() {
        ia_crm__Intacct_Contract__c contract = new ia_crm__Intacct_Contract__c(
            Name = 'Test',
            ia_crm__Contract_ID__c = 'P-86'
        );
        insert contract;
        return contract;
    }

    /**
    * @description insertTestIntacctContractLine -
    * @param Id contractId
    * @param Id opportunityId
    * @param PS_Project__c project
    * @param Milestone__c milestone
    * @return ia_crm__Intacct_Contract_Line__c
    */
    public static ia_crm__Intacct_Contract_Line__c insertTestIntacctContractLine(Id contractId, Id opportunityId, PS_Project__c project, Milestone__c milestone) {
        ia_crm__Intacct_Contract_Line__c l = new ia_crm__Intacct_Contract_Line__c(
            Name = '1',
            ia_crm__Intacct_Contract__c = contractId,
            ia_crm__Opportunity__c = opportunityId,
            ia_crm__Item__c = milestone.ProductId__c,
            ProjectId__c = project.Id
        );
        insert l;
        return l;
    }

    /**
    * @description syncProject -
    * @param Id projectId
    * @return void
    */
    @future(callout = true)
    private static void syncProject(Id projectId) {
        PS_Project__c project = IntacctIntegrationService.selectProjectsById(new Set<Id> { projectId })[0];

        IntacctIntegrationService.IntacctObjectSync ios = new IntacctIntegrationService.IntacctObjectSync(project);

        new IntacctIntegrationService.SyncProjectWithIntacct().resolve(ios);
        new IntacctIntegrationService.SetStatusCompleted().resolve(ios);
    }

    /**
    * @description syncProjectWithError - 
    * @param Id projectId
    * @return void
    */
    @future(callout = true)
    private static void syncProjectWithError(Id projectId) {
        PS_Project__c project = IntacctIntegrationService.selectProjectsById(new Set<Id> { projectId })[0];

        IntacctIntegrationService.IntacctObjectSync ios = new IntacctIntegrationService.IntacctObjectSync(project);

        try {
            new IntacctIntegrationService.SyncProjectWithIntacct().resolve(ios);
        }
        catch(Exception e) {
            new IntacctIntegrationService.SetStatusError().error(e, ios);
        }
    }

    /**
    * @description syncMilestone - 
    * @param Id milestoneId
    * @return void
    */
    @future(callout = true)
    private static void syncMilestone(Id milestoneId) {
        Milestone__c milestone = IntacctIntegrationService.selectMilestonesById(new Set<Id> { milestoneId })[0];

        IntacctIntegrationService.IntacctObjectSync ios = new IntacctIntegrationService.IntacctObjectSync(milestone);

        new IntacctIntegrationService.SyncMilestoneWithIntacct().resolve(ios);
        new IntacctIntegrationService.SetStatusCompleted().resolve(ios);
    }

    /**
    * @description syncMilestoneWithError - 
    * @param Id milestoneId
    * @return void
    */
    @future(callout = true)
    private static void syncMilestoneWithError(Id milestoneId) {
        Milestone__c milestone = IntacctIntegrationService.selectMilestonesById(new Set<Id> { milestoneId })[0];

        IntacctIntegrationService.IntacctObjectSync ios = new IntacctIntegrationService.IntacctObjectSync(milestone);

        try {
            new IntacctIntegrationService.SyncMilestoneWithIntacct().resolve(ios);
        }
        catch(Exception e) {
            new IntacctIntegrationService.SetStatusError().error(e, ios);    
        }
    }

    /**
    * @description syncTimeCardHeader - 
    * @param Id timeCardHeaderId
    * @return void
    */
    @future(callout = true)
    private static void syncTimeCardHeader(Id timeCardHeaderId) {
        Time_Card_Header__c timeCardHeader = IntacctIntegrationService.selectTimeCardHeadersById(new Set<Id> { timeCardHeaderId })[0];

        IntacctIntegrationService.IntacctObjectSync ios = new IntacctIntegrationService.IntacctObjectSync(timeCardHeader);

        new IntacctIntegrationService.SyncTimeCardHeadersWithIntacct().resolve(ios);
    }

    /**
    * @description syncTimeCardHeaderWithError - 
    * @param Id timeCardHeaderId
    * @return void
    */
    @future(callout = true)
    private static void syncTimeCardHeaderWithError(Id timeCardHeaderId) {
        Time_Card_Header__c timeCardHeader = IntacctIntegrationService.selectTimeCardHeadersById(new Set<Id> { timeCardHeaderId })[0];

        IntacctIntegrationService.IntacctObjectSync ios = new IntacctIntegrationService.IntacctObjectSync(timeCardHeader);

        try {
            new IntacctIntegrationService.SyncTimeCardHeadersWithIntacct().resolve(ios);
        }
        catch(Exception e) {
            new IntacctIntegrationService.SetTimeCardStatusError().error(e, ios);    
        }
    }  

    /**
    * @description syncIntacctContractLine - 
    * @param Id contractLineId
    * @return void
    */
    @future(callout = true)
    private static void syncIntacctContractLine(Id contractLineId) {
        ia_crm__Intacct_Contract_Line__c contractLine = IntacctIntegrationService.selectContractLinesByIds(new Set<Id> { contractLineId })[0];

        IntacctIntegrationService.IntacctObjectSync ios = new IntacctIntegrationService.IntacctObjectSync(contractLine);

        new IntacctIntegrationService.SyncContractLineWithIntacct().resolve(ios);
    }   

    /**
    * @description getPSProjectRecordTypeId - 
    * @return Id
    */
    private static Id getPSProjectRecordTypeId() {
        for (RecordType recordType : getObjectRecordTypes('PS_Project__c')) {
            if (recordType.DeveloperName == 'PS_Project') {
                return recordType.Id;
            }
        }
        return null;
    }

    /**
    * @description getOpportunityRecordTypesMap - 
    * @return Map<String, RecordType>
    */
    private static Map<String, RecordType> getOpportunityRecordTypesMap() {
        Map<String, RecordType> opportunityRecordTypeNameToRecordTypeMap = new Map<String, RecordType>();
        for(RecordType recordType : getObjectRecordTypes('Opportunity')) {
            opportunityRecordTypeNameToRecordTypeMap.put(recordType.DeveloperName,recordType);
        }
        return opportunityRecordTypeNameToRecordTypeMap;
    }

    /**
    * @description sessionInitialize - 
    * @return void
    */
    private static void sessionInitialize() {
        IntacctDataModel.IntacctSession session = new IntacctDataModel.IntacctSession('0000','http://localhost');
        IntacctIntegrationService.cachedSession = session;
    }   


    //////////////////////////////////////////////// SELECTORS //////////////////////////////////////////////////////


    /**
    * @description getProjectById - 
    * @param Id projectId
    * @return PS_Project__c
    */
    private static PS_Project__c getProjectById(Id projectId) {
        return [
            SELECT
                Intacct_Sync_Status__c,
                Intacct_Sync_Errors__c,
                Intacct_Id__c,
                Intacct_Project_Id__c
            FROM PS_Project__c
            WHERE Id = :projectId
        ];
    }

    /**
    * @description getObjectRecordTypes - 
    * @param String objectName
    * @return RecordType[]
    */
    private static RecordType[] getObjectRecordTypes(String objectName) {
        return [
            SELECT
                Id,
                DeveloperName
            FROM RecordType
            WHERE SObjectType = :objectName
        ];
    }

    /**
    * @description getTestProducts - 
    * @return Product2[]
    */
    private static Product2[] getTestProducts() {
        return [
            SELECT
                Id
            FROM Product2
        ];
    }

    /**
    * @description getTestPeriods - 
    * @return Period__c[]
    */
    private static Period__c[] getTestPeriods() {
        return [
            SELECT
                Id,
                Start_Date__c
            FROM Period__c
        ];
    }

    /**
    * @description getTestUsers - 
    * @return User[]
    */
    private static User[] getTestUsers() {
        return [
            SELECT
                Id
            FROM User
            WHERE Intacct_Id__c != null
        ];
    }

    /**
    * @description getTestOpportunities - 
    * @return Opportunity[]
    */
    private static Opportunity[] getTestOpportunities() {
        return [
            SELECT
                Id
            FROM
                Opportunity
        ];
    }

    /**
    * @description getMilestoneById - 
    * @param Id milestoneId
    * @return Milestone__c
    */
    private static Milestone__c getMilestoneById(Id milestoneId) {
         return [
            SELECT
                Intacct_Sync_Status__c,
                Intacct_Sync_Errors__c,
                Intacct_Id__c,
                Intacct_Resource_Id__c
            FROM Milestone__c
            WHERE Id = :milestoneId
        ];       
    }

    /**
    * @description getTimeCardHeaderById - 
    * @param Id timeCardHeaderId
    * @return Time_Card_Header__c
    */
    private static Time_Card_Header__c getTimeCardHeaderById(Id timeCardHeaderId) {
         return [
            SELECT
                Intacct_Sync_Status__c,
                Intacct_Sync_Errors__c,
                Intacct_Id__c
            FROM Time_Card_Header__c
            WHERE Id = :timeCardHeaderId
        ];       
    }   

    /**
    * @description getIntacctContractLineById - 
    * @param Id contractLineId
    * @return ia_crm__Intacct_Contract_Line__c
    */
    private static ia_crm__Intacct_Contract_Line__c getIntacctContractLineById(Id contractLineId) {
        return [
            SELECT
                Intacct_Sync_Status__c,
                Intacct_Sync_Errors__c
            FROM
                ia_crm__Intacct_Contract_Line__c
            WHERE
                Id = :contractLineId
        ];
    }

    /**
    * @description getIntacctProjectById - 
    * @param Id projectId
    * @return ia_crm__Project__c
    */
    private static ia_crm__Project__c getIntacctProjectById(Id projectId) {
        return [
            SELECT
                PS_Project__c
            FROM
                ia_crm__Project__c
            WHERE
                Id = :projectId
        ];
    }

    /**
    * @description getOpportunityLineItemsByOpportunityId - 
    * @param Id opportunityId
    * @return List<OpportunityLineItem>
    */
    private static List<OpportunityLineItem> getOpportunityLineItemsByOpportunityId(Id opportunityId) {
        return [
            SELECT
                OpportunityId,
                ia_crm__Project__c,
                ia_crm__Task__c
            FROM
                OpportunityLineItem
            WHERE
                OpportunityId = :opportunityId
        ];
    }


}