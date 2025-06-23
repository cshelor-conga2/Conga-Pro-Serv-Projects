/***************************************************************************************************
* Class Name   : BooleanExpression
* Created Date : July 4, 2018
* Author       : Vijaya Sankar N
* Description  : Class to evaluate a boolean expression 
* Example      : (TRUE AND (FALSE OR TRUE)) is TRUE
****************************************************************************************************/
public class BooleanExpression {
    static Map<String, String> logicTypes = new Map<String, String>();
    static Map<String, Map<String, String>> expressionLogic = new Map<String, Map<String, String>>();
    
    /**
    * Evaluate a boolean expreassion
    * 
    */
    public static Boolean eval(String pExpression) {
        try{
            // If expression contains all TRUE or FALSE
            if(String.isBlank(pExpression)) { return FALSE; }
            if(pExpression.contains('NULL')) { return FALSE; }
            if(pExpression.containsAny('1234567890')) { return FALSE; }            
            if(pExpression.containsNone('TRUE') && pExpression.containsNone('FALSE')) { return FALSE; }
            if(pExpression.containsNone('FALSE')) { return TRUE; }        
            if(pExpression.containsNone('TRUE')) { return FALSE; }

            fillLogic();
            return Boolean.valueOf(evaluateExpression(pExpression.toUpperCase()));
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('BooleanExpression', 'eval', null, ex, true);
            return FALSE;
        }
    }
    
    /**
    * Evaluate the expression
    * 
    */
    public static String evaluateExpression(String pExpression) {
        for(String logicType : logicTypes.keySet()) {
            if(pExpression.contains(logicType)) {
                pExpression = simplifyExpression(pExpression, logicTypes.get(logicType));
            }
        }
        
        if(pExpression.contains('AND') || pExpression.contains('OR') || pExpression.contains('(')) {
            pExpression = evaluateExpression(pExpression);
        }
        
        return pExpression;
    }
    
    /**
     * Simplify the expression
     * 
     */
    public static String simplifyExpression(String pExpression, String pLogicType){
        Map<String, String> logic = new Map<String, String>(expressionLogic.get(pLogicType));
        for(String key : logic.keySet()) {
            pExpression = pExpression.replace(key, logic.get(key));
        }
        
        return pExpression;
    } 
    
    /**
    * Fill AND and OR Logic
    * 
    */
    public static void fillLogic() {
        Map<String, String> andLogic = new Map<String, String>();
        Map<String, String> orLogic = new Map<String, String>();
        Map<String, String> parenLogic = new Map<String, String>();
        
        logicTypes.put('AND', 'AND');
        logicTypes.put('OR', 'OR');
        logicTypes.put('(', 'PARENS');
        
        // AND Logic
        andLogic.put('TRUE AND TRUE', 'TRUE');
        andLogic.put('TRUE AND FALSE', 'FALSE');
        andLogic.put('FALSE AND TRUE', 'FALSE');
        andLogic.put('FALSE AND FALSE', 'FALSE');
        expressionLogic.put('AND', andLogic);
        
        // OR Logic
        orLogic.put('TRUE OR TRUE', 'TRUE');
        orLogic.put('TRUE OR FALSE', 'TRUE');
        orLogic.put('FALSE OR TRUE', 'TRUE');
        orLogic.put('FALSE OR FALSE', 'FALSE');
        expressionLogic.put('OR', orLogic);
        
        // Braces Logic
        parenLogic.put('(TRUE)', 'TRUE');
        parenLogic.put('(FALSE)', 'FALSE');
        expressionLogic.put('PARENS', parenLogic);
    }


}