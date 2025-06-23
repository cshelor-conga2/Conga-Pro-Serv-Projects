#### Import libraries used for web requests ####

import json
import requests
from csv import DictReader

#### Open and parse through a one column CSV file that contains document IDs. Currently hardcoded to a file.  Could easily be expanded to take that as a param ####
#### This function retuns a string list of document IDs                                                                                                        ####

def createDict():
    with open("docs to delete ids.csv") as f:
        Ids = [row["Doc id"] for row in DictReader(f)]

    return Ids

#### Test function to make sure IDs were transferred to list correctly ####

def printIdsTest(Ids):

    print(Ids)
    for id in Ids:
        print(id)


#### Takes as a parameter the list of document IDs, then loops through that and makes a delete API call with each ID                     ####
#### The json library delete function waits for a response from the system before moving on, which ensures we don't overload the system  ####

def document_delete(Ids):

    #### Basic creds ####
    api_key = '057f87263a77dd637a8caba9437b5fac52761123'

    #### Delete documents by looping through array of document IDs ####

    for id in Ids:

        deleteDocURL = 'https://ruralking.octiv.com/api/v2/contracts/' + id + '?api_key=' + api_key
        deleteRequest = requests.delete(deleteDocURL)

        #### Print the response and corresponding document ID so we can identify if any delete calls fail ####
        
        print(deleteRequest, " ", id)

#### Main function ####

def main():
    Ids = createDict()

    #### Test Function ####

    printIdsTest(Ids)

    #document_delete(Ids)

#### Run program ####

main()