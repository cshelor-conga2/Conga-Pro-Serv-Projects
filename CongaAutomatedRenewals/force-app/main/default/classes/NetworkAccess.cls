/**
* @author Bethany Spencer
* @date 20150629
* @version 1.0
* @description NetworkAccess - 
*/
global class NetworkAccess implements Process.Plugin{   

    /**
    * @description invoke - 
    * @param Process.PluginRequest request
    * @return Process.PluginResult
    */
    global Process.PluginResult invoke(Process.PluginRequest request){   
        Map<String, Object> result = new Map<String, Object>();
        Boolean isTrustedIP = false;
        String sourceIp = (String)request.inputParameters.get('IP');
        
        //IP not provided, use the current session IP address
        if(sourceIp == null || sourceIp == ''){
            Map<String,String> sessionAttributes;
            try {
                sessionAttributes = Test.isRunningTest() ? new Map<String,String>{ 'SourceIp' => '1.1.1.1'} : Auth.SessionManagement.getCurrentSession();
            }
            catch(Exception e){
                result.put('IsTrusted', false);
                return new Process.PluginResult(result);
            }

            sourceIp = sessionAttributes.get('SourceIp');
        }
        
        if(sourceIp != null){
            isTrustedIP = Auth.SessionManagement.inOrgNetworkRange(sourceIp);
        }
         
        result.put('IsTrusted', isTrustedIP);
        return new Process.PluginResult(result);
    }

    /**
    * @description describe - 
    * @return Process.PluginDescribeResult
    */
    global Process.PluginDescribeResult describe(){
        Process.PluginDescribeResult result = new Process.PluginDescribeResult();
        result.description='This plug-in verifies if the input IP address is in your organization trusted IP range';
        result.tag = 'Identity';
        
        result.inputParameters = new List<Process.PluginDescribeResult.InputParameter> {
            new Process.PluginDescribeResult.InputParameter('IP', Process.PluginDescribeResult.ParameterType.STRING, true)
        };
        
        result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter> {
            new Process.PluginDescribeResult.OutputParameter('IsTrusted', Process.PluginDescribeResult.ParameterType.Boolean)
        };

        return result;
    }


}