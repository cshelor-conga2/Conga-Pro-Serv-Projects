@RestResource(urlMapping='/conga/engineering/v1/license')
global with sharing class EngineeringEvent_REST_Data_v1 {
   
    @HttpGet
    global static void getData() {
        string salesforceId = RestContext.request.params.get('salesforceId');
        string externalIdObjectName = RestContext.request.params.get('externalIdObjectName');
        string externalId = RestContext.request.params.get('externalId');
        
        System.assert(string.isNotBlank(salesforceId) || (string.isNotBlank(externalIdObjectName) && string.isNotBlank(externalId)));
        
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        
        try {
            Map<String,Object> jsonObj = EngineeringEventHelper.retrieveAccountRelatedObject(salesforceId, externalId, externalIdObjectName);
            if (jsonObj == null) {
                res.statusCode = 400;
            } else {
                res.addHeader('Content-Type', 'application/json');
                res.responseBody = Blob.valueOf(JSON.serialize(jsonObj));
            }
        } catch (Exception e) {
            System.debug('Error getting object data: ' + e.getMessage());
            res.statusCode = 500;
        }
    }
}