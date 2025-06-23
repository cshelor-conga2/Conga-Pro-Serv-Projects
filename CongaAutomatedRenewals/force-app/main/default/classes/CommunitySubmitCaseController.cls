/**
* @author ECS, ERedding
* @date 20200811
* @description CommunitySubmitCaseController - Custom controller for the CommunitySubmitCase lighting component
*/
public with sharing class CommunitySubmitCaseController {
    
    /**
    * @description getUserInfo - Returns user data for the user currently logged in to the community
    * @param Id pUserId - User Id
    * @return User
    */
    @AuraEnabled
    public static User getUserInfo(Id pUserId){
        if(pUserId != null){
            for(User queriedUser : [SELECT Id, ContactId FROM User WHERE Id = :pUserId]){
            	return queriedUser;
            }
        }
        return new User(Id = pUserId); 
    }


}