from configparser import RawConfigParser

parser = RawConfigParser()

config_folder_path = 'config'
# Load base config and check which instance the app wants to run
parser.read(config_folder_path + '/app.config')
running_config = parser.get('DEFAULT', 'Instance')
print(" >> Running Instance = " + running_config)

# Based on running config, load the configuration - dev/qa
config_parser = RawConfigParser()
config_file = config_folder_path + "/" + running_config + '.config'

print(" >> loading " + running_config + "Config " + config_file)
config_parser.read(config_file)


class ConfigHelperSingleton:
    __instance = None

    @staticmethod
    def getConfig():
        """ Static access method. """
        if ConfigHelperSingleton.__instance is None:
            ConfigHelperSingleton()
        return ConfigHelperSingleton.__instance

    def __init__(self):
        """ Virtually private constructor. """
        if ConfigHelperSingleton.__instance is not None:
            raise Exception("This class is a singleton!")
        else:
            ConfigHelperSingleton.__instance = config_parser
