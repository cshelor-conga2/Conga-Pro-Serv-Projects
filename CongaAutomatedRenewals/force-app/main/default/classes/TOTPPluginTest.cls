/**
* @author BSpencer
* @date 20150629
* @version 1.00
* @description TOTPPluginTest - Test class for the TOTPPlugin class
*/
@isTest
private class TOTPPluginTest{

    /**
    * @description getQRCode - 
    */
    static testMethod void getQRCode() {
        TOTPPlugin totp = new TOTPPlugin();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();
         
        Map<String,String> qr = Auth.SessionManagement.getQrCode(); 
         
        inputParams.put('OTP_INPUT', null);
         
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = totp.invoke(request);
    }

    /**
    * @description validateToken - 
    */    
    static testMethod void validateToken() {
        TOTPPlugin totp = new TOTPPlugin();
        Map<String,Object> inputParams = new Map<String,Object>();
        Map<String,Object> outputParams = new Map<String,Object>();
         
        Map<String,String> qr = Auth.SessionManagement.getQrCode(); 
         
        inputParams.put('OTP_INPUT', '1234');
        inputParams.put('SECRET_INPUT', qr.get('secret'));
         
        Process.PluginRequest request = new Process.PluginRequest(inputParams);
        Process.PluginResult result;
        result = totp.invoke(request);
    }

    /**
    * @description describeTest - 
    */
    static testMethod void describeTest() {
        TOTPPlugin totp = new TOTPPlugin();
        Process.PluginDescribeResult result = totp.describe();
        System.AssertEquals(result.InputParameters.size(), 3);
        System.AssertEquals(result.OutputParameters.size(), 3);
    }


}