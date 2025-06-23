import xlrd


class InputReader:
    def __init__(self, filepath):
        self.filepath = filepath

        # Give the location of the file
        loc = filepath

        # To open Workbook
        self.wb = xlrd.open_workbook(loc)
        self.sheet = self.wb.sheet_by_index(0)
        self.sheet.cell_value(0, 0)

        # Extracting number of rows
        # print('Total rows = ' + str(self.sheet.nrows))

        # Extracting number of columns
        # print('Total columns = ' + str(self.sheet.ncols))

        # Show all columns
        # print('Column names')
        # for i in range(self.sheet.ncols):
        #     print(self.sheet.cell_value(0, i))

    def get_column_names(self):
        columns = []
        for i in range(self.sheet.ncols):
            columns.append(self.sheet.cell_value(0, i))
        return columns

    def get_column_index(self, column_name):
        for i in range(self.sheet.ncols):
            if column_name == self.sheet.cell_value(0, i):
                return i

    def get_column_data(self, column_name):
        column_index = self.get_column_index(column_name)
        return self.sheet.col_values(column_index, 1)

    def get_all_rows_data(self):
        rows = []
        for i in range(self.sheet.nrows):
            row = []
            for j in range(self.sheet.ncols):
                row.append(self.sheet.cell_value(i, j))
            rows.append(row)
        del rows[0]
        return rows
        # df = self.wb.parse(self.sheet.name, index_col=None, header=None, skiprows=1)
        # # This is needed to populated merged cell values in excel.
        # # df = df.fillna(method='ffill')
        #
        # sheet_rows = df.to_numpy().tolist()
        # return sheet_rows
