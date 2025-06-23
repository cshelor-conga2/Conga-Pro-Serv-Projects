# This class represents APXTConga4__Conga_Merge_Query__c custom object
# The field name also have to be same as custom object field in Salesforce
from src.bl_helpers import common_helper


class MergeQuery(object):
    def __init__(self, Id, QueryName, Query, Description):
        if not common_helper.IsNullOrEmpty(Id):
            self.Id = Id
        if not common_helper.IsNullOrEmpty(QueryName):
            self.APXTConga4__Name__c = QueryName
        if not common_helper.IsNullOrEmpty(QueryName):
            self.APXTConga4__Description__c = Description
        if not common_helper.IsNullOrEmpty(Query):
            self.APXTConga4__Query__c = Query

    def to_string(self):
        return 'Id = ' + self.Id + ', QueryName = ' + self.APXTConga4__Name__c + ", Desc = " + \
               self.APXTConga4__Description__c + ", Query = " + self.APXTConga4__Query__c
