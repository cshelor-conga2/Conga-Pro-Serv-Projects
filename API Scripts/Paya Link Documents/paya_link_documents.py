
import requests
import csv

api_key = '3dbbf25b33b60f8e841535a36f0ccc9cc18a971f'
postURL = 'https://paya.octiv.com/document_links?api_key=' + api_key
documentIdCsv = 'doc_ids_to_link.csv'


def create_parent_list(IdCsv):
    with open(IdCsv) as csvfile:
        reader = csv.DictReader(csvfile)
        parentIds = []
        for row in reader:
            parentIds.append(row['Parent Doc Octiv ID'])

    return parentIds

def create_child_list(IdCsv):
    with open(IdCsv) as csvfile:
        reader = csv.DictReader(csvfile)
        childIds = []
        for row in reader:
            childIds.append(row['Child Doc Octiv ID'])

    return childIds

def testPrintIds(parentList, childList):
    print("parent Ids: ",  parentList)
    print("child Ids: ",  childList)

def create_links(parentList, childList):

    #print(parentList)
    #print(childList)
    count = 0
    errorsList = []
    for id in parentList:
        parent_doc = parentList[count]
        child_doc = childList[count]
        count+=1
        linkData = {'document_link[document_id]': child_doc, 'document_link[link_option_direction]': 'inward',
                    'document_link[link_option_id]': '60', 'document_link[linked_id]': parent_doc,
                    'document_link[linked_type]': 'Proposal', 'document_link[linking_id]': child_doc,
                    'document_link[linking_type]': 'Proposal'}
        postRequest = requests.post(postURL, data=linkData)
        if postRequest.status_code != 200:
            errorsList.append(child_doc)

        print(postRequest.status_code)

    print(errorsList)

def main():
    parentList = create_parent_list(documentIdCsv)
    childList = create_child_list(documentIdCsv)

    #testPrintIds(parentList, childList)

    create_links(parentList, childList)

main()
