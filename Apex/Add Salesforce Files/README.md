![Logo of the project](https://conga.com/themes/conga/images/logo.svg)

# Conga Collaborate-Salesforce Files Integration
> Developed by Chris Shelor
>
> v1 published 11/13/19 

This project extends the Conga Collaborate Salesforce managed package functionality to allow for adding Salesforce Files as attachments to a Collaborate document.

Version 1: extends the Collaborate/Salesforce integration to allow the latest File on the launching record to be added to the document as an attachment

Goals for Version 2: ability to choose between attaching all Files or the first File and to choose whether they get created as embedded pages or as attachments


## Installing / Getting started

### Configure Salesforce
 
1. Create a custom metadata type with the API name of `Collaborate_API_Setting__mdt`
2. Add two text fields to the metadata type with a character length of 50:
	1. API Endpoint - api_endpoint__c
	2. API Key - api_key__c
3. Create a metadata record of the type you just configured:
	1. Set the API endpoint as https://domain.octiv.com/api/v2
	2. Set the API key using the key from your Collaborate user record
3. Add a remote site that points to your Collaborate root domain, i.e. https://domain.octiv.com
4. Add the trigger, class, and test class to your Salesforce environment

## Developing

Any contributions to Version 2 goals are welcome.  To get started:

```shell
git clone https://github.com/Tinderbox/pro-serv.git
cd Apex/Add Salesforce Files
```
Add the trigger, class, and test class to your Salesforce environment.

When pushing a change set from sandbox to production:
1. Include the class, test class, trigger, custom metadata type, and the two custom fields created on the metadata type 
2. Create the remote site and custom metadata record before creating any documents

## Features

* Allows a user to automatically add a Salesforce File to a Collaborate document as an attachment
* Main function does the following four tasks:
    1. Queries the latest SF File on the launching object (queryFile function)
    2. Creates the Content in Collaborate (createMedia function)
    3. Parses the HTTP response to get the Content Id (parseJSON function)
    4. Attaches the created Content to the created document (attachMedia function)

## Contributing

If you'd like to contribute, please fork the repository and use a feature
branch. Pull requests are warmly welcomed.