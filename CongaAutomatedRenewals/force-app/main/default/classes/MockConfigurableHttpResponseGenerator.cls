/**
* @author Conga Services, ERedding
* @date 20190411
* @version 1.0
* @description MockConfigurableHttpResponseGenerator - 
*/
@isTest
public class MockConfigurableHttpResponseGenerator  implements HttpCalloutMock {
    public Map<string,integer> requestRuns{get;set;}
    public Map<string,HttpResponse> responses {get;set;}

    /**
    * @description MockConfigurableHttpResponseGenerator - Constructor
    */
    public MockConfigurableHttpResponseGenerator(){
        responses = new Map<String,HttpResponse>();
    }

    /**
    * @description MockConfigurableHttpResponseGenerator - Constructor
    * @param Map<string, HttpResponse> fakeResponses
    */    
    public MockConfigurableHttpResponseGenerator(Map<string,HttpResponse> fakeResponses){
        if (requestRuns == null) requestRuns = new Map<String,Integer>();
        if(responses == null) responses = new Map<String,HttpResponse>();
        responses.putAll(fakeResponses);
    }

    /**
    * @description respond - 
    * @param HTTPRequest req
    * @return HTTPResponse
    */
    public HTTPResponse respond(HTTPRequest req) {
        // OPTIONALLY, ONLY SEND A MOCK RESPONSE FOR A SPECIFIC ENDPOINT AND METHOD. 
        //System.debug('Mock Request for ' + req.getEndpoint() + ' and Method = ' + req.getMethod());

		// TRY TO LOOK FOR A KEY WITH JUST THE ENDPOINT
        if(responses != null &&  responses.containsKey(req.getEndpoint())) {
            String requestKey = req.getEndpoint();
            Integer runs = requestRuns.get(requestKey);    
            requestRuns.put(requestKey, runs == null ? 1 : ++runs);
            return responses.get(requestKey);    
        }

        // TRY TO LOOK FOR A KEY WITH ENDPOINT AND METHOD: <ENDPOINT>|<METHOD>
        if(responses != null &&  responses.containsKey(req.getEndpoint() + '|' + req.getMethod())) {
            //System.debug('found endpoint with method');
            String requestKey = req.getEndpoint() + '|' + req.getMethod();
            Integer runs = requestRuns.get(requestKey);    
            requestRuns.put(requestKey, runs == null ? 1 : ++runs);
            return responses.get(requestKey);
        }
        
        // CREATE A FAKE RESPONSE FAILURE IF NOT HANDLED
        String requestKey = 'DEFAULT REQUEST';
        Integer runs = requestRuns.get(requestKey);    
        requestRuns.put(requestKey, runs == null ? 1 : ++runs);

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(404);
        return res;
    }


}