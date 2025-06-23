/**
* @author BSpencer
* @date 20150629
* @version 1.00
* @description TOTPPlugin - 
*/
global class TOTPPlugin implements Process.Plugin{

    /**
    * @description describe - 
    * @return Process.PluginDescribeResult
    */
    global Process.PluginDescribeResult describe(){
        Process.PluginDescribeResult result = new Process.PluginDescribeResult();
        result.description = 'This plug-in handles salesforce standard two factor authentication methods.';
        result.tag = 'Identity';
        
        result.inputParameters = new List<Process.PluginDescribeResult.InputParameter> {
            new Process.PluginDescribeResult.InputParameter('OTP_INPUT', Process.PluginDescribeResult.ParameterType.String, true),
            new Process.PluginDescribeResult.InputParameter('OTP_REGISTRATION_INPUT', Process.PluginDescribeResult.ParameterType.String, true),
            new Process.PluginDescribeResult.InputParameter('SECRET_INPUT', Process.PluginDescribeResult.ParameterType.String, true)      
        };
        
        result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter> {
            new Process.PluginDescribeResult.OutputParameter('QR_URL_OUTPUT', Process.PluginDescribeResult.ParameterType.String),
            new Process.PluginDescribeResult.OutputParameter('SECRET_OUTPUT', Process.PluginDescribeResult.ParameterType.String),
            new Process.PluginDescribeResult.OutputParameter('IsValid_OUTPUT', Process.PluginDescribeResult.ParameterType.Boolean)
        };
        
        return result;
    }
    
    /**
    * @description invoke - 
    * @param Process.PluginRequest request
    * @return Process.PluginResult
    */ 
    global Process.PluginResult invoke(Process.PluginRequest request){   
        Map<String,String> qr;
        String url; 
        String otp;
        String secret;
        Boolean status = false;
    
        String userid   = UserInfo.getUserId();  
        
        Map<String, Object> result = new Map<String, Object>();
        List<TwoFactorInfo> twoFactors = [SELECT UserId, Type FROM TwoFactorInfo WHERE userID = :userid];
        
        secret = (String)request.inputParameters.get('SECRET_INPUT');
        
        if(twoFactors.isEmpty() && secret == null){
            qr = Auth.SessionManagement.getQrCode();      
            url = qr.get('qrCodeUrl');
            secret = qr.get('secret');
            
            result.put('QR_URL_OUTPUT', url);
            result.put('SECRET_OUTPUT', secret);
            return new Process.PluginResult(result);
        }
         
        otp = (String)request.inputParameters.get('OTP_REGISTRATION_INPUT');
        
        if(otp == null){
            otp = (String)request.inputParameters.get('OTP_INPUT');
        }
        
        result.put('IsValid_OUTPUT', validate(otp, secret));
        return new Process.PluginResult(result);
    }
      
    /**
    * @description validate - 
    * @param String otp
    * @param String secret
    * @return Boolean
    */     
    private Boolean validate(String otp, String secret){
        String userid   = UserInfo.getUserId();   
        Boolean status = false;
         
        if(secret == null){
            try {
                status = Auth.SessionManagement.validateTotpTokenForUser(otp);
            } 
            catch(Exception e){
                system.debug('The key is invalid or the current user has attempted too many validations');
            } 
            return status;
        }
        
        status = Auth.SessionManagement.validateTotpTokenForKey(secret, otp);
        if(status == true){
           TwoFactorInfo twoFactor = new TwoFactorInfo(UserId = userid, Type = 'TOTP', SharedKey = secret);
           insert twoFactor;
        }
        return status;
    }


}