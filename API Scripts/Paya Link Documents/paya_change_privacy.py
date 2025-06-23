import json
import requests

# This script allows you to dynamically set the value of one field in the json data of a document. #
# All you need to do is set the global variables up front and the script will take care of the rest #

# Set global values for API key, Octiv URL, and json data #

user_api_key = {'api_key': '10545b4cb0b82a1766c85288d28b8c04cbd5cb45', 'per': '2'}
octivURL = 'https://paya-sandbox.octiv.com/api/v2/proposals'
docType = "proposal"  # sets Collaborate document type #
json_key = "visibility"  # document variable we are going to change #
json_value = 0  # value for document variable #


# Returns the document json data in a python dict #

def getDocuments(api_key, url):
    apiResponse = requests.get(url, params=api_key)

    # Creates a list of dictionaries, where each dictionary contains all the data for a single document #

    jsonDocs = apiResponse.json()

    return jsonDocs


# TEST FUNCTION #

def printData(docDict, docType):
    docCount = 0
    for i in range(len(docDict)):
        doc = docDict[i]
        print('Owner ID = ', doc[docType]['user_id'])
        print('Doc ID = ', doc[docType]['id'])
        docCount += 1

    print('Total number of documents =', docCount)


# Returns the document IDs in a list #

def getDocIDs(docDict, docType):
    docIds = []
    for i in range(len(docDict)):
        doc = docDict[i]
        id = doc[docType]['id']
        docIds.append(id)

    # print(docIds)
    # print('Total number of documents =', docCount)
    return docIds


# Uses the doc Ids and updates each respective doc with the json data defined in the global variables #

def updateDocs(docIds, api_key, url, json_key, json_value, docType):
    jsonDict = {
        docType: {
            json_key: json_value
        }
    }

    for i in range(len(docIds)):
        currentId = docIds[i]
        requestURL = url + '/' + str(currentId)
        apiResponse = requests.put(requestURL, json=jsonDict, params=api_key)

        print(apiResponse, ' -- Doc ID = ', currentId)


def main():
    allDocs = getDocuments(user_api_key, octivURL)

    # printData(allDocs, docType) #

    docIds = getDocIDs(allDocs, docType)

    updateDocs(docIds, user_api_key, octivURL, json_key, json_value, docType)


main()