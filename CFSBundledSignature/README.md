# CFS Bundled Signature Install Instructions 

## 1. Package Dependencies

The following packages must be installed before installing the Bundled Signature package. Use the links below to install each one.

> **Sandbox installs:** swap `login.salesforce.com` for `test.salesforce.com` in each URL below.

| Package | Install Link |
|---|---|
| Conga Contracts for Salesforce | [Install](https://login.salesforce.com/?retURL=/packaging/installPackage.apexp?p0=04tal000007D26TAAS) |
| Conga Composer | [Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000AK1V) |
| Conga Sign | [Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04taj000000WFYdAAO) |
| Conga Grid | [Install](https://login.salesforce.com/?retURL=/packaging/installPackage.apexp?p0=04tg80000007tfjAAA) |
| NavigateEverywhere | [See UnofficialSF page for install link](https://unofficialsf.com/navigate-everywhere-flow-action/) |
| Flow Actions Base Pack & Screen Components Base Pack | [See UnofficialSF page for install links](https://unofficialsf.com/flow-action-and-screen-component-basepacks/) |

---

## 2. Picklist Updates

The picklist fields below belong to the Conga CFS managed package and cannot be deployed via the Bundled Signature package. Update the fields with the values listed _before_ installing the Bundled Signature package.

---

### Fields & Values to Add

| Object | Field | Values to Add |
|---|---|---|
| `APXT_Redlining__Contract_Agreement__c` | `APXT_Redlining__Type__c` | `Signature Bundle` |
| `APXT_Redlining__Contract_Agreement__c` | `APXT_Redlining__Status__c` | `Out for Signature`, `Active` |

---

### Picklist Update Steps

1. Log in to the target Salesforce org.
2. Go to **Setup** → search for **Object Manager** → open **Contract Agreement**.
3. Click **Fields & Relationships** in the left sidebar.
4. Click the field name (e.g. **Type** or **Status**).
5. Click **Edit** at the top of the field detail page.
6. Scroll to the **Values** section and click **New**.
7. Enter the value label exactly as shown in the table above and click **Save**.
8. Repeat for each value.

> **Repeat this process in every org** (sandbox, UAT, production) — these values do not deploy automatically with the unlocked package.

## 3. Install Bundled Signature Package

Use the install link provided and install for all users in your target org. As noted above, swap `login` for `test` if you are installing in a sandbox.
[Install CFS Bundled Signature](https://login.salesforce.com/?retURL=/packaging/installPackage.apexp?p0=04tak000000b18PAAQ)

---

## Components Manifest

All components are customizable, use them as a starting point and then adjust to your specific business requirements. Happy building!

### Flows
- `CNG_Conga_Contract_Agreement_Request`
- `CNG_Conga_Contract_Agreement_Updates`

### Lightning Pages
- `CNG_Contract_Agreement_Master_Bundled_Signature`

### Custom Fields
- `APXT_Redlining__Contract_Agreement__c.CNG_Signature_Bundle__c`
- `APXT_CongaSign__Transaction__c.Parent_a2g__c`

### Static Resources
- `CNG_Conga_Logo`

### Permission Sets
- `CNG_Conga_CFS_Bundled_Signature`

### Buttons
- `APXT_Redlining__Contract_Agreement__c.CNG_Review_Document_Sales`
- `APXT_Redlining__Contract_Agreement__c.CNG_Review_Document_Legal_Admin`
- `APXT_Redlining__Contract_Agreement__c.CNG_Send_for_Bundled_Signature`