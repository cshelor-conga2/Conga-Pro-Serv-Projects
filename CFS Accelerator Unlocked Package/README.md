# 

# Package post-installation steps
1. Import the Grid zip file, `CFS Accelerator - Grid Views v1.1.zip` stored in this folder. Import all Views and the Page included in the zip file
2. Activate flexipages (Lightning pages) for the Conga Query, Conga Template, and Contract Agreement objects
3. Assign page layouts for the Conga Template and Contract Agreement objects
4. Assign Grid Visualforce Pages permission set to all Grid users
5. Assign Conga CLM - Read Only permission set to any CFS users who are read-only
6. Edit the Conga Legal app and make it visible to any profiles who need to access it

# Package version summary

- Package name: `CFS Accelerator`
- Version name: `CFS Accelerator - Fall '25 Release`
- Version number: `1.1.0.1`
- Version description: `Fall '25 Release v1.1.0.1 - Components for CFS Accelerator`
- Source path: `force-app`
- Source API version: `62.0`

### Package dependencies

- `CongaComposer` (alias: `CongaComposer`) — Package Id: `04tKe000000syJwIAI`
- `CongaContracts` (alias: `CongaContracts`) — Package Id: `04tKk000000cCs2IAE`
- `CongaGrid` (alias: `CongaGrid`) — Package Id: `04tKg000000D2p4IAC`

Your package alias `CFS Accelerator` maps to packaging org id: `0HoKa0000008hLbKAI`.

# Project manifest

All Salesforce metadata components included in this project came from the `force-app` directory. It's a simple, human-readable manifest grouped by metadata type and showing the relative paths for each component.

## Summary

- Root metadata folder: `force-app/main/default`
- Total component files listed: 41 (metadata files and related contents)

## Manifest (grouped by metadata type)

### Applications

- `force-app/main/default/applications/Conga_Legal.app-meta.xml`

### Tabs

- `force-app/main/default/tabs/Contract_Management_Center.tab-meta.xml`
- Used to display the Contract Management Center Grid visualforce page

### Report types

- `force-app/main/default/reportTypes/Managed_Clauses.reportType-meta.xml`

### Reports (APXTConga4__Conga_Reports)

- `force-app/main/default/reports/APXTConga4__Conga_Reports/Open_Contracts_by_Status_QIg.report-meta.xml`
- `force-app/main/default/reports/APXTConga4__Conga_Reports/Open_Contracts_by_Requestor_Nbq.report-meta.xml`
- `force-app/main/default/reports/APXTConga4__Conga_Reports/Non_Standard_Managed_Clauses_oRJ.report-meta.xml`
- `force-app/main/default/reports/APXTConga4__Conga_Reports/Contract_Volume_by_Month_68p.report-meta.xml`
- These reports are used in the `Contracts Summary` dashboard

### Queues

- `force-app/main/default/queues/Legal_Queue.queue-meta.xml`

### Permission sets

- `force-app/main/default/permissionsets/CNG_Conga_CLM_Read_Only.permissionset-meta.xml`
- `force-app/main/default/permissionsets/ActionGrid_Visualforce_Pages.permissionset-meta.xml`

### Pages

- `force-app/main/default/pages/Contract_Management_Center_Multi_Tab.page`
- `force-app/main/default/pages/Contract_Management_Center_Multi_Tab.page-meta.xml`
- This visualforce page was created by the Conga Grid managed package

### Flows

- `force-app/main/default/flows/Conga_Email_Message_Updates.flow-meta.xml`
- `force-app/main/default/flows/Conga_Contract_Request.flow-meta.xml`

### Flow tests

- `force-app/main/default/flowtests/Conga_Email_Message_Updates_Test_Outgoing_Email_on_non_Contract_Agreement.flowtest-meta.xml`
- `force-app/main/default/flowtests/Conga_Email_Message_Updates_Test_Outgoing_Email.flowtest-meta.xml`

### FlexiPages (record pages / utility bar)

- `force-app/main/default/flexipages/Conga_Template_Record_Page.flexipage-meta.xml`
- `force-app/main/default/flexipages/Contract_Agreement_Master.flexipage-meta.xml`
- `force-app/main/default/flexipages/Conga_Query_Record_Page.flexipage-meta.xml`
- `force-app/main/default/flexipages/Conga_Legal_UtilityBar.flexipage-meta.xml`
- Must be activated after package install

### Layouts

- `force-app/main/default/layouts/APXT_Redlining__Contract_Agreement__c-Contract Agreement Master Layout.layout-meta.xml`
- `force-app/main/default/layouts/APXTConga4__Conga_Template__c-Conga Template Master Layout.layout-meta.xml`
- Must be assigned after package install

### Content assets

- `force-app/main/default/contentassets/Conga_Logo_150px.asset`
- `force-app/main/default/contentassets/Conga_Logo_150px.asset-meta.xml`

### Dashboards

- `force-app/main/default/dashboards/CongaContractsDashboards.dashboardFolder-meta.xml`
- `force-app/main/default/dashboards/CongaContractsDashboards/vGolaudvliwyogKxTSzvWXKdgXALKv.dashboard-meta.xml`

### Email templates

- `force-app/main/default/email/Conga_Email_Templates.emailFolder-meta.xml`
- `force-app/main/default/email/Conga_Email_Templates/CNG_Send_for_Negotiation.email`
- `force-app/main/default/email/Conga_Email_Templates/CNG_Send_for_Negotiation.email-meta.xml`
- `force-app/main/default/email/Conga_Email_Templates/Contract_Agreement_Rejected`
- `force-app/main/default/email/Conga_Email_Templates/Contract_Agreement_Approved`
- `force-app/main/default/email/Conga_Email_Templates/Contract_Agreement_Approval_Request`

### Objects (fields, list views, web links)

- `force-app/main/default/objects/APXT_Redlining__Cycle__c/fields/CNG_Cycle_Label__c.field-meta.xml`
- `force-app/main/default/objects/APXT_Redlining__Contract_Agreement__c/fields/CNG_Third_Party_Paper__c.field-meta.xml`
- `force-app/main/default/objects/APXT_Redlining__Contract_Agreement__c/webLinks/CNG_Review_Document_Sales.webLink-meta.xml`
- `force-app/main/default/objects/APXT_Redlining__Contract_Agreement__c/listViews/Legal_Queue_Contract_Agreement.listView-meta.xml`
- `force-app/main/default/objects/APXT_Redlining__Contract_Agreement__c/listViews/CNG_All_Agreements.listView-meta.xml`

## Notes & next steps

- This manifest was generated from the files under `force-app/main/default` discovered in the repository at the time of generation. If you add or remove metadata files, regenerate this list.
- To regenerate quickly on a Windows PowerShell prompt run:

```powershell
Get-ChildItem -Recurse -File force-app | ForEach-Object { $_.FullName }
```


