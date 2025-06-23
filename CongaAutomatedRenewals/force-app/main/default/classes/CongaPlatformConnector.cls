public with sharing class CongaPlatformConnector {
    
    public CongaPlatformConnector(ApexPages.StandardController controller){

    }
    /**
    * @description Generate Callout to Conga Platform
    * @cacheToken Whether to write the token back to cache (set as a parameter to avoid dml before callouts)
    */
    public static String getAccessToken() {
        return getAccessToken(true);
    }

    public static String getAccessToken(Boolean retry){  
        try {
            //TODO DETECT PLATFORM CACHE AND USE FOR CACHEING TOKEN 
            Conga_Platform_API__c CPAPI = Conga_Platform_API__c.getInstance();
            HttpRequest req = new HttpRequest(); 
            req.setMethod('GET');
            req.setTimeout(31000);
            String username = CPAPI.Username__c;
            String password = CPAPI.Password__c;
            String endpoint = CPAPI.AuthenticationURL__c;
            String apikey = CPAPI.APIKey__c;

            if(String.isBlank(username) || String.isBlank(endpoint) || String.isBlank(password)){
                System.debug('Missing Credentials In Custom Settings');
                return null;
            }
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            // System.debug(authorizationHeader);
            req.setHeader('Authorization', authorizationHeader);  
            if(String.isNotBlank(apikey))  req.setHeader(CongaPlatformConstants.API_HEADER_APIKEY, apikey);
            req.setEndpoint(endpoint);
            Http http = new Http();    
            HTTPResponse res = http.send(req);
            // System.debug('res ' + res);
            if(res.getStatusCode() >= 200 && res.getStatusCode() < 300){    
                Map<String,object> tokenmap = (Map<String,object>)JSON.deserializeuntyped(res.getbody());
                if(tokenmap.containsKey('error')){
                    System.Debug('Authorization Service Error - ' + res.getbody());    
                }
                // System.debug('gimme' + (string)tokenmap.get('idtoken'));
                return (string)tokenmap.get('idtoken'); 
            } 
            return null;
        } catch(System.CalloutException ex) {
            if (retry && ex.getMessage().containsIgnoreCase('connection reset')) {
                return getAccessToken(false);
            } else {
                throw ex;
            }
        }
    }

     public static HttpResponse generateCallout(Map<String, Object> params){ 
        return generateCallout(params, true);
    }

    public static HttpResponse generateCallout(Map<String, Object> params, Boolean retry){ 
        String accessToken = null;
        if(!( params.containsKey('headers') && ((Map<String, Object>)params.get('headers')).containsKey('Authorization'))){
            if(params.containsKey('accessToken')){
                accessToken = String.valueOf(params.get('accessToken'));
            }else{
                accessToken = getAccessToken();
            }
            if(String.isBlank(accessToken)){
                return createResponse('Unable to authorize to service', 'UNAUTHORIZED', 401);
            }
        }

        try {
            Conga_Platform_API__c CPAPI = Conga_Platform_API__c.getInstance();
            String baseUrl = CPAPI.ResourceManagementBaseURL__c;
            if(params.containsKey('baseUrl')){
                baseUrl = (String)params.get('baseUrl');
            }
            String apikey = CPAPI.APIKey__c;
            if( String.isBlank(baseUrl) || String.isBlank(apikey)){ 
                return createResponse('Unable to authorize to service - missing credentials', 'UNAUTHORIZED', 401);
            }
            //ADD AUTHORIZATION HEADERS TO REQUEST 
            HttpRequest httpReq = new HttpRequest();
            httpReq.setMethod(((String)params.get('method')).toUpperCase());
            httpReq.setHeader('Authorization', accessToken);
            httpReq.setHeader(CongaPlatformConstants.API_HEADER_APIKEY, apikey);

            //ADD OR OVERWRITE WITH PASSED INFORMATION
            if (params.containsKey('headers')) {
                Map<String, Object> headers = (Map<String, Object>)params.get('headers');
                for (String header : headers.keySet()) {
                    httpReq.setHeader(header, (String)headers.get(header));
                }
            }
            Pagereference pr = new Pagereference(baseUrl + params.get('route'));

            if(params.containsKey('parameters')){
                Map<String,Object> parameters = (Map<String,Object>)params.get('parameters');
                for(String param : parameters.keySet()){
                    pr.getParameters().put(param, (String)parameters.get(param));
                }
            }
            httpReq.setEndPoint(pr.getUrl());

            httpReq.setTimeout(120000); //MAXIMUM FOR ALL REQUESTS COMBINED
            if(params.containsKey('timeout')){
                httpReq.setTimeout(Integer.valueOf(params.get('timeout')));
            }
            if(params.containsKey('body')) {
                // System.debug('body: '+ (String)params.get('body'));
                httpReq.setBody((String)params.get('body'));
            }
            // System.debug('request: ' +httpReq);
            Http h = new Http();
            return h.send(httpReq);
        } catch(System.CalloutException ex) {
            if (retry && ex.getMessage().containsIgnoreCase('connection reset')) {
                return generateCallout(params, false);
            } else {
                throw ex;
            }
        }
    }

    public static HttpResponse createResponse(String body, String status, Integer statusCode){
        HttpResponse response = new HttpResponse();
        response.setStatus(status);
        response.setStatusCode(statusCode);
        response.setBody(body);
        return response;

    }
}