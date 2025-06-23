# This class represents APXT_Redlining__Clause_Type__c custom object
# The field name also have to be same as custom object field in Salesforce
from src.bl_helpers import common_helper


class ClauseType(object):
    def __init__(self, Id, Name):
        if not common_helper.IsNullOrEmpty(Id):
            self.Id = Id
        if not common_helper.IsNullOrEmpty(Name):
            self.Name = Name

    def to_string(self):
        return 'Id = ' + self.Id + ', Name = ' + self.Name
