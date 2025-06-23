# This class represents APXT_Redlining__Clause__c custom object
# The field name also have to be same as custom object field in Salesforce
from src.bl_helpers import common_helper


class Clause(object):
    def __init__(self, Id, Name, ClauseType, ClauseText):
        if not common_helper.IsNullOrEmpty(Id):
            self.Id = Id
        if not common_helper.IsNullOrEmpty(Name):
            self.Name = Name
        if not common_helper.IsNullOrEmpty(ClauseType):
            self.APXT_Redlining__Clause_Type__c = ClauseType
        if not common_helper.IsNullOrEmpty(ClauseText):
            self.APXT_Redlining__Text__c = ClauseText
            self.APXT_Redlining__Text_Rich__c = ClauseText

    def to_string(self):
        return 'Id = ' + self.Id + ', Name = ' + self.Name + ", ClauseType = " + self.APXT_Redlining__Clause_Type__c \
               + ", Text= " + self.APXT_Redlining__Text__c
