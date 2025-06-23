/**
* @author JHafer
* @date 20180402
* @version 1.00
* @description LiveAgentUtilities - 
*/
public with sharing class LiveAgentUtilities {

	/**
	* @description getContact
    * @param Id contactId
    * @return Contact
	*/
	@AuraEnabled
    public static Contact getContact(Id contactId) {
        Contact contact = null;
        User user = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(user.ContactId != null){
            contact = [SELECT Id, Name, Email, Phone FROM Contact WHERE Id = :user.ContactId];
        }
        else{
            contact = new Contact(FirstName = 'she');
        }
        return contact;
    }


}