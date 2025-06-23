# ClauseLibraryCreator
Creates Conga clause library components - Clause Type, Clause, Conga Query
This utility takes an Excel file as an input and generates few Conga library components.
Supported components:
- Clause Type
- Clause
- Conga Query

The sample Excel file is given ClausesBook.xlsx.

```
ClauseType    | CongaQueryAlias(Max 20 Chars)   | ClauseName | ClauseText |
---------------------------------------------------------------------------
CT-AB	      | CTAB	                        | CT-C1	     | Clause 1
CT-AB	      | CTAB	                        | CT-C2	     | Clause 2
CT-CD	      | CTCD	                        | CT-C3	     | Clause 3
```
The output of above data would be:
- CT-AB and CT-CD clause types will be created if they don't exist
- Clause 1 will be created with name CT-C1 and clause type CT-AB
- Clause 2 will be created with name CT-C2 and clause type CT-AB
- Clause 3 will be created with name CT-C3 and clause type CT-CD
- CTAB and CTCD conga query objects will be created with the query and description


**Installation Steps:**
- Install the python (for Windows 64-bit : https://www.python.org/ftp/python/3.9.2/python-3.9.2-amd64.exe)

**Setup Steps**
- Download the entire folder and copy at some place on your system.
- Open config\dev.config file and update your Salesforce instance credentails (username, password, security token)


**How to use this?**
- Once above installation and setup steps are completed, **_update the ClauseBook.xlsx based on your need_**
- Open command prompt and run following command which will start creating clause library components
```
cd Path_to_ClauseLibraryCreator
venv\Scripts\activate.bat
pip install -r requirements.txt 
python main.py
```
- That's it.
- Refer logs folder for log files

Please drop main to Bharat Panchal (bpanchal@conga.com) for any query.
