# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import logging.config

from input_reader import InputReader
from src.bl_helpers.ClauseLibraryManager import ClauseLibraryManager
from src.bl_helpers.ClauseTypeGenerator import ClauseTypeGenerator
from src.constants import Constants
from src.salesforce_wrapper.SalesforceSingleton import SalesforceSingleton


def print_hi(name):
    # Use a breakpoint in the code line below to debug your script.
    print(f'Hi, {name}')  # Press Ctrl+F8 to toggle the breakpoint.


def check_salesforce_connection():
    try:
        sf = SalesforceSingleton().getInstance()
        metadata = sf.Account.metadata()
        print(metadata)
        query_response = sf.query("SELECT Id FROM Account Limit 5")
        if len(query_response['records']) > 0:
            print('Salesforce connection verification --> Successful')
        else:
            print('Salesforce connection verification --> Failed')
    except Exception as e:
        print('Salesforce connection verification --> Failed')


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    logging.config.fileConfig('config/logging.conf')
    # create logger
    logger = logging.getLogger(Constants.LOGGER_NAME)
    # check_salesforce_connection()
    sf = SalesforceSingleton().getInstance()

    input_reader = InputReader('ClausesBook.xlsx')
    all_rows_data = input_reader.get_all_rows_data()
    clm = ClauseLibraryManager(sf, all_rows_data)
    clm.generate_clause_library()





