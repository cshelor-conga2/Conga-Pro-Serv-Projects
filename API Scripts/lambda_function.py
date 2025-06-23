# Import libraries used for web requests

import json
import requests

def lambda_handler(event, context):

    ################ Basic creds ################
    api_key='761b778e98beb3819a661feb3282c033735ea35c'
    ################ Basic creds ################

    ################ Create the document ################

    octivPayload = {
        'contract': {
            "name": "Example " + event['document_type'],
            "client": event['company_name'],
            "description": "Sample Text",
            "value": 0,
            "password": "",
            "archived": 0,
            "visibility": 0,
            # "template_id": "40391",  # We'll rely on Template_Mapped_ID below instead
            "variable_data": {
                "Template_Mapped_ID": "40391"
            }
        }
    }
    createDocURL = 'https://marcustest.octiv.com/api/v2/contracts?api_key=' + api_key
    createResponse = requests.post(createDocURL, json=octivPayload).json()
    contract_id = createResponse['contract']['id']
    # return contract_id
    # print(contract_id)


    ################ Add recipients ################

    createRecipientURL = 'https://marcustest.octiv.com/api/v2/contracts' + '/' + str(contract_id) + '/recipients?api_key=' + api_key

    createRecipientPayload = {
        'recipient': {
            'first_name': event['recipient_firstname'],
            'last_name': event['recipient_lastname'],
            'email_address': event['recipient_email'],
            'signer': event['signer'],
            'signer_position': event['signer_position'],
            'redliner': event['redliner']
        }
    }

    recipientResponse = requests.post(createRecipientURL, json=createRecipientPayload).json()
    exampleRecipientID = recipientResponse['recipient']['id']


    ################ Publish the document ################

    publishURL = 'https://marcustest.octiv.com/api/v2/contracts' + '/' + str(contract_id) + '/publish?api_key=' + api_key
    publishResponse = requests.get(publishURL)


    ################ Send emails to recipients ################

    emailURL = 'https://marcustest.octiv.com/api/v2/contracts' + '/' + str(contract_id) + '/emails?api_key=' + api_key

    emailPayload = {
        'email': {
            'subject': 'Review: ' + event['recipient_firstname'],
            'message':  'Thanks for checking out Octiv! Click the button below to review this document, make redline requests, and sign. An Octiv team member will address your requested redlines as soon as they can (yes, a real person here will look at your test redlines).',
            'recipient_ids': [
                recipientResponse['recipient']['id']
            ],
            'bcc_yourself': 'false'
        }
    }

    emailResponse = requests.post(emailURL, json=emailPayload).json()


    ################ Return the recipient link ################

    endMessage = '<p>Thanks ' + event['recipient_firstname'] + '! Take a look at your <a href="' + recipientResponse['recipient']['variables']['recipient_proposal_url'] + '">document here</a>.<p>'
    print(endMessage)
    return endMessage
