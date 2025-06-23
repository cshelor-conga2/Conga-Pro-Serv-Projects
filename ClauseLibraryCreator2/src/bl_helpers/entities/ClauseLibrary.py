class ClauseLibrary:
    def __init__(self, row_no, clause_type, clause_name, clause_text, query_alias):
        self.RowNo = row_no
        self.ClauseType = clause_type
        self.ClauseName = clause_name
        self.ClauseText = clause_text
        self.QueryAlias = query_alias

    def ToString(self):
        return str(self.RowNo) + " - " + self.ClauseType + " | " \
               + self.QueryAlias + " | " + self.ClauseName + " | " + self.ClauseText
