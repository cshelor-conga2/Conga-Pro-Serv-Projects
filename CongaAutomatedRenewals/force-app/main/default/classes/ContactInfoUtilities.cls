/**
* @author CongaServices
* @date 20180402
* @version 1.00
* @description ContactInfoUtilities - Aura Enabled utility methods for the Contact object
*/
public with sharing class ContactInfoUtilities{

    /**
    * @description getContact -
    * @return Contact
    */
    //@AuraEnabled
    //public static Contact getContact() {
    //    Contact contact=null;
    //    User user = [Select ContactId from User where Id=: UserInfo.getUserId()];
    //    if(user.ContactId !=null){
    //        contact = [
    //                SELECT Id, Name, Email, Phone
    //                FROM Contact
    //                WHERE Id =:user.ContactId
    //            ];
    //    }
    //    return contact;
    //}

    /**
    * @description getUser - Gets and returns the current user
    * @return User
    */ 
    @AuraEnabled
    public static User getUser() {
        return [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    }


}