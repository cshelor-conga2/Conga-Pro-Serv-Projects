import logging

from simple_salesforce import Salesforce

from src.config_helper.ConfigHelper import ConfigHelperSingleton
from src.constants import Constants, ConfigConstants

logger = logging.getLogger(Constants.LOGGER_NAME)


class SalesforceConfig:
    def __init__(self, end_point, username, password, security_token, token_validity_in_seconds):
        self.EndPoint = end_point
        self.Username = username
        self.Password = password
        self.SecurityToken = security_token
        self.TokenValidityInSeconds = token_validity_in_seconds


config = ConfigHelperSingleton.getConfig()
sf_config = SalesforceConfig(
    end_point=config.get(ConfigConstants.SALESFORCE_CONFIG, ConfigConstants.SF_INSTANCE_URL),
    username=config.get(ConfigConstants.SALESFORCE_CONFIG, ConfigConstants.SF_USERNAME),
    password=config.get(ConfigConstants.SALESFORCE_CONFIG, ConfigConstants.SF_PASSWORD),
    security_token=config.get(ConfigConstants.SALESFORCE_CONFIG, ConfigConstants.SF_SECURITY_TOKEN),
    token_validity_in_seconds=int(config.get(ConfigConstants.SALESFORCE_CONFIG,
                                             ConfigConstants.SF_TOKEN_VALIDITY_IN_SECONDS))
)


class SalesforceSingleton:
    __instance = None

    def getInstance(self):
        return self.__instance

    def __init__(self):
        self.__instance = Salesforce(username=sf_config.Username,
                        password=sf_config.Password,
                        security_token=sf_config.SecurityToken,
                        domain='test')
