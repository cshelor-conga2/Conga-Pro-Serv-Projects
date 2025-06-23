def list_to_string(lst: list):
    return ', '.join([str(elem) for elem in lst])


def list_to_string_with_quotes_and_comma(words: list):
    return ", ".join("'{0}'".format(w) for w in words)


def combine_columns_data(column1_data: list, column2_data: list):
    len1 = len(column1_data)
    len2 = len(column2_data)

    combined_column_data = []
    if len1 == len2:
        for i in range(len1):
            combined_column_data.append(column1_data[i]+"-"+column2_data[i])

    return combined_column_data

