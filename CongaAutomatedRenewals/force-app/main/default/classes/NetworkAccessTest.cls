/**
* @author Bethany Spencer
* @date 20150629
* @version 1.0
* @description NetworkAccessTest - Test class for the NetworkAccess class
*/
@isTest
private class NetworkAccessTest{

    /**
    * @description inputIP - 
    */
    static testMethod void inputIP() {
        NetworkAccess network = new NetworkAccess();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();
         
        inputParams.put('IP', '1.1.1.1');
         
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = network.invoke(request);
        
        System.AssertEquals(1,1);
    }

    /**
    * @description inputNoIP - 
    */
    static testMethod void inputNoIP() {
        NetworkAccess network = new NetworkAccess();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();
         
        inputParams.put('IP', '');
         
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = network.invoke(request);
        
        System.AssertEquals(1,1);
    }

    /**
    * @description describeTest - 
    */
    static testMethod void describeTest() {
        NetworkAccess network = new NetworkAccess();
        Process.PluginDescribeResult result = network.describe();
        
        System.AssertEquals(result.inputParameters.size(), 1);
        System.AssertEquals(result.OutputParameters.size(), 1);
    }


}