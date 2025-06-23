from simple_salesforce import Salesforce

from src.bl_helpers import common_helper
from src.bl_helpers.entities.ClauseType import ClauseType


class ClauseTypeGenerator:
    def __init__(self, sf_connection: Salesforce, clause_types_dict: dict, clause_library_list: list):
        self.sf = sf_connection
        self.ClauseTypesDict = clause_types_dict
        self.ClauseLibraryList = clause_library_list
        self.UniqueClauseTypes = []
        self.FinalClauseTypesForInsertion = []

    def generate(self):
        print('The list after removing duplicates')
        self.__extract_unique_clause_types()
        print(str(self.UniqueClauseTypes))

        self.__create_clause_types()

    def __extract_unique_clause_types(self):
        for cl in self.ClauseLibraryList:
            if cl.ClauseType not in self.UniqueClauseTypes:
                self.UniqueClauseTypes.append(cl.ClauseType)

        # remove already existed clause types (in SF) from unique clause types
        for uct in self.UniqueClauseTypes:
            if uct not in self.ClauseTypesDict:
                self.FinalClauseTypesForInsertion.append(uct)

    def __create_clause_types(self):
        print('Final list for insertion')
        print(str(self.FinalClauseTypesForInsertion))
        final_clause_types = []
        for uct in self.FinalClauseTypesForInsertion:
            ct = ClauseType(Id='', Name=uct)
            final_clause_types.append(ct.__dict__)
        final_clause_types_count = len(final_clause_types)
        if final_clause_types_count > 0:
            bulk_insert_result = self.sf.bulk.APXT_Redlining__Clause_Type__c.insert(
                final_clause_types)
            success_count, fail_count = common_helper.get_success_fail_count_of_bulk_insert(bulk_insert_result,
                                                                               "APXT_Redlining__Clause_Type__c")

