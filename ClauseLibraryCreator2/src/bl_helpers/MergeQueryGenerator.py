from simple_salesforce import Salesforce

from src.bl_helpers import common_helper
from src.bl_helpers.entities.MergeQuery import MergeQuery


def get_description(clause_type):
    return "Gets clauses with '" + clause_type + "' clause type"


def get_query(clause_type):
    return "SELECT Id, APXT_Redlining__Text_Rich__c, APXT_Redlining__Order__c FROM APXT_Redlining__Managed_Clause__c " \
           "WHERE APXT_Redlining__Contract_Agreement__r.ID = '{pv0}' AND APXT_Redlining__Clause_Type__c = " \
           + "'" + clause_type + "' ORDER BY APXT_Redlining__Order__c ASC"


class MergeQueryGenerator:
    def __init__(self, sf_connection: Salesforce, clause_types_dict: dict, clause_library_list: list):
        self.sf = sf_connection
        self.ClauseTypesDict = clause_types_dict
        self.ClauseLibraryList = clause_library_list
        self.FinalQueriesForInsertion = []
        self.QueriesDict = {}
        # Query name as key and clause type name as value
        self.UniqueQueryNamesFromClauseLibraryDict = {}

    def generate(self):
        self.__get_existing_merge_queries()
        self.__get_unique_query_names_from_clause_library_list()
        self.__prepare_final_queries_for_insertion()
        self.__insert_queries()
        self.__get_existing_merge_queries()

    def __get_existing_merge_queries(self):
        data = self.sf.query_all_iter("SELECT Id, APXTConga4__Key__c, APXTConga4__Name__c FROM "
                                      "APXTConga4__Conga_Merge_Query__c")
        for row in data:
            self.QueriesDict[row['APXTConga4__Name__c']] = row['APXTConga4__Key__c']
            common_helper.logDebug(",[" + row['APXTConga4__Name__c'] + "]" + row['APXTConga4__Key__c'])
        print(self.QueriesDict)

    def __get_unique_query_names_from_clause_library_list(self):
        for cl in self.ClauseLibraryList:
            query_name = str(cl.ClauseType) + "[" + str(cl.QueryAlias).replace('-', '') + "]"
            query_name = query_name[0:95]
            if query_name not in self.UniqueQueryNamesFromClauseLibraryDict:
                self.UniqueQueryNamesFromClauseLibraryDict[query_name] = cl.ClauseType

    def __prepare_final_queries_for_insertion(self):
        for key in self.UniqueQueryNamesFromClauseLibraryDict.keys():
            if key not in self.QueriesDict:
                desc = get_description(self.UniqueQueryNamesFromClauseLibraryDict[key])
                query = get_query(self.UniqueQueryNamesFromClauseLibraryDict[key])
                merge_query_obj = MergeQuery(Id='', QueryName=key, Query=query, Description=desc)
                self.FinalQueriesForInsertion.append(merge_query_obj.__dict__)

    def __insert_queries(self):
        common_helper.logDebug("Final queries for insertion")
        common_helper.logDebug(self.FinalQueriesForInsertion)
        final_queries_count = len(self.FinalQueriesForInsertion)
        if final_queries_count > 0:
            bulk_insert_result = self.sf.bulk.APXTConga4__Conga_Merge_Query__c.insert(
                self.FinalQueriesForInsertion)
            success_count, fail_count = common_helper.get_success_fail_count_of_bulk_insert(bulk_insert_result,
                                                                               "APXTConga4__Conga_Merge_Query__c")
