from simple_salesforce import Salesforce

from src.bl_helpers import common_helper
from src.bl_helpers.entities.Clause import Clause


class ClauseGenerator:
    def __init__(self, sf_connection: Salesforce, clause_types_dict: dict, clause_library_list: list):
        self.sf = sf_connection
        self.ClauseTypesDict = clause_types_dict
        self.ClauseLibraryList = clause_library_list
        self.FinalClausesForInsertion = []

    def generate(self):
        # region Update rows with clause type id and add record in list for final insertion
        for cl in self.ClauseLibraryList:
            if cl.ClauseType not in self.ClauseTypesDict:
                common_helper.logError("Clause without clause type: " + cl.ToString())
            else:
                clause = Clause(Id='', Name=cl.ClauseName, ClauseType=self.ClauseTypesDict[cl.ClauseType],
                                ClauseText=cl.ClauseText)
                self.FinalClausesForInsertion.append(clause.__dict__)
        # endregion

        common_helper.logDebug("Final clauses for insertion")
        common_helper.logDebug(self.FinalClausesForInsertion)
        final_clauses_count = len(self.FinalClausesForInsertion)
        if final_clauses_count > 0:
            bulk_insert_result = self.sf.bulk.APXT_Redlining__Clause__c.insert(
                self.FinalClausesForInsertion)
            success_count, fail_count = common_helper.get_success_fail_count_of_bulk_insert(bulk_insert_result,
                                                                               "APXT_Redlining__Clause__c")
