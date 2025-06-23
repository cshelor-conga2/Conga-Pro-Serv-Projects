@RestResource(urlMapping='/conga/engineering/v1/replay')
global with sharing class EngineeringEvent_REST_Replay_v1 {
   
    @HttpGet
    global static void getData() {
        string objectName = RestContext.request.params.get('objectname');
        string startDateStr = RestContext.request.params.get('startdate');
        string endDateStr = RestContext.request.params.get('enddate');
        
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        
        try {
            DateTime [] dateRange = EngineeringEventReplayHelper.parseValidateDateRange(startDateStr, endDateStr);
            if (dateRange == null) {
                res.statusCode = 400;
                return;
            }

            Map<String,Object> jsonObj = EngineeringEventReplayHelper.processReplay(objectName, dateRange[0], dateRange[1]);
            if (jsonObj == null) {
                res.statusCode = 400;
            }
            else {
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(jsonObj));
            }
        }
        catch (Exception e) {
            System.debug('Error getting object data: ' + e.getMessage());
            res.statusCode = 500;
        }
    }
}