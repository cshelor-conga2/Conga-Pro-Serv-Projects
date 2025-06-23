import logging
from datetime import datetime

from src.constants import Constants

logger = logging.getLogger(Constants.LOGGER_NAME)


def get_float_Value(index, value):
    val = 0.0
    if index > -1 and IsNotNull(value):
        val = float(value)
    return val


def ignore_exception(IgnoreException=Exception, DefaultVal=None):
    """ Decorator for ignoring exception from a function
    e.g.   @ignore_exception(DivideByZero)
    e.g.2. ignore_exception(DivideByZero)(Divide)(2/0)
    """

    def dec(function):
        def _dec(*args, **kwargs):
            try:
                return function(*args, **kwargs)
            except IgnoreException:
                return DefaultVal

        return _dec

    return dec


def log(message):
    pass


def logError(message):
    logger.error(message)


def logException(message):
    logger.exception(message)


def logDebug(message):
    print(message)
    logger.debug(message)


def IsNotNull(value):
    return (value is not None) and (len(value) > 0)


def IsNullOrEmpty(value):
    return (value is None) or (len(str(value)) == 0)


def list_to_string(lst):
    return ' '.join([str(elem) for elem in lst])


def get_current_datetime():
    # datetime object containing current date and time
    now = datetime.now()

    # print("now =", now)

    # dd/mm/YY H:M:S
    dt_string = now.strftime("%d/%m/%Y %H:%M:%S")
    # print("date and time =", dt_string)
    return dt_string


def get_success_fail_count_of_bulk_insert(resultList, objectName):
    logDebug(" ==========  BULK " + objectName + " INSERT RESULT =========")

    success_count = 0
    fail_count = 0
    for result in resultList:
        is_success = result["success"]
        if is_success:
            success_count = success_count + 1
        else:
            fail_count = fail_count + 1

        logDebug("success=" + str(is_success) + ", created=" + str(result["created"]) + ", id="
                               + str(result['id']))
        for error in result['errors']:
            error_msg = str(error["message"])
            logError(error_msg)

    return success_count, fail_count
