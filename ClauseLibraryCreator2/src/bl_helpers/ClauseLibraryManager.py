from simple_salesforce import Salesforce


from src.bl_helpers.ClauseGenerator import ClauseGenerator
from src.bl_helpers.ClauseTypeGenerator import ClauseTypeGenerator
from src.bl_helpers.MergeQueryGenerator import MergeQueryGenerator
from src.bl_helpers.entities.ClauseLibrary import ClauseLibrary
from src.constants import Constants


class ClauseLibraryManager:
    def __init__(self, sf_connection: Salesforce, sheet_rows: list):
        self.sf = sf_connection
        self.sheet_rows = sheet_rows
        self.ClauseLibraryList = []
        self.ClauseTypes = []
        self.ClauseTypesDict = {}

    def generate_clause_library(self):
        self.__transform_clause_library_input_data()
        self.__get_existing_clause_types()
        ctg = ClauseTypeGenerator(sf_connection=self.sf, clause_types_dict=self.ClauseTypesDict,
                                  clause_library_list=self.ClauseLibraryList)
        ctg.generate()

        # Fetch again so that newly generated clause types are also populated in the dictionary
        self.__get_existing_clause_types()

        cg = ClauseGenerator(sf_connection=self.sf, clause_types_dict=self.ClauseTypesDict,
                                 clause_library_list=self.ClauseLibraryList)
        cg.generate()

        mqg = MergeQueryGenerator(sf_connection=self.sf, clause_types_dict=self.ClauseTypesDict,
                                 clause_library_list=self.ClauseLibraryList)
        mqg.generate()

    def __transform_clause_library_input_data(self):
        total_rows = len(self.sheet_rows)

        # region Handle nan, convert data to string
        for x in range(total_rows):
            for y in range(len(self.sheet_rows[x])):
                # Trimming whitespaces at the start and end of data before import process
                self.sheet_rows[x][y] = str(self.sheet_rows[x][y]).strip()
                if self.sheet_rows[x][y] == "nan":
                    self.sheet_rows[x][y] = ""
        # endregion

        for x in range(total_rows):
            clause_type = self.sheet_rows[x][Constants.Clause_Type_Column_Index]
            query_alias = self.sheet_rows[x][Constants.Conga_Query_Alias_Column_Index]
            clause_name = self.sheet_rows[x][Constants.Clause_Name_Column_Index]
            clause_text = self.sheet_rows[x][Constants.Clause_Text_Column_Index]
            self.ClauseLibraryList.append(ClauseLibrary(row_no=x, clause_type=clause_type, clause_name=clause_name,
                                                        clause_text=clause_text, query_alias=query_alias))

        for cl in self.ClauseLibraryList:
            print(cl.ToString())

    def __get_existing_clause_types(self):
        data = self.sf.query_all_iter("SELECT Id, Name FROM APXT_Redlining__Clause_Type__c")
        for row in data:
            self.ClauseTypesDict[row['Name']] = row['Id']
        print(self.ClauseTypesDict)
