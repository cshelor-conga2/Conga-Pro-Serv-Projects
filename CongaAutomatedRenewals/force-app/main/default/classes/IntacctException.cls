/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IACRMTaskHelper - Custom functionality for the ia_crm__Task__c object
*/
public class IntacctException extends Exception {
    public String ErrorNumber {get; set;}
    public String Description {get; set;}
    
    /**
    * @description buildException
    * @param IntacctDataModel.IntacctError
    * @return IntacctException
    */
    public static IntacctException buildException(IntacctDataModel.IntacctError error){
        String description = IntacctUtils.isNull(error.ErrorNumber,'') + (String.isNotBlank(error.ErrorNumber) ? '\n' : '') + 
                             IntacctUtils.isNull(error.Description,'') + (String.isNotBlank(error.Description) ? '\n' : '') +
                             IntacctUtils.isNull(error.Description2,'');

        IntacctException e = new IntacctException(description);
        e.ErrorNumber = error.ErrorNumber;
        e.Description = description;
        return e;
    }


}