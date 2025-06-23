import json
import requests
import csv


def getuserids(): #reads csv of user ids and load into array
	ids= []
	with open("userids.csv") as csvfile:
		reader = csv.reader(csvfile)
		for row in reader:
			ids.append(row)
	return ids

def getextids(): #reads csv of sfdc ids and loads
	extids = []
	with open("ext-int-ids.csv") as csvfile:
		reader = csv.reader(csvfile)
		for row in reader:
			extids.append(row)
	return extids



def update_users(url, api_key, ids, extids): # loop to build json body, serialize it, and request to update users with the sfdc id

	for i in range(len(ids)):
		
		currentid= ids[i][0] #grabs current user id
		currentextid = extids[i][0] #grabs current ext id
		#print(currentid)
		#print(currentextid)
		request_url = url + '/' + currentid + '?api_key=' + api_key
		data = {}
		sub_data = {}
		sub_data["ext_integration_id"] = currentextid
		data["user"] = sub_data
		#print(data)
		json_data = json.dumps(data)
		headers = {'Content-Type': 'application/json','Accept': 'application/json'}
		#json_body = '{"api_key": "9a5cc95575c0141eec901a59c905f9f696c2558c", "user": {"ext_integration_id": "' + currentextid + '"}}'
		print(request_url)
		print(json_data)
		
		apiResponse = requests.put(request_url, data=json_data, headers=headers)
		print(apiResponse, ' -- user id --', currentid)

def main():
	
	octivURL = 'https://ge.octiv.com/api/v2/users'
	api_key = '9a5cc95575c0141eec901a59c905f9f696c2558c'

	ids = getuserids()

	extids= getextids()

	update_users(octivURL, api_key, ids, extids)

main()