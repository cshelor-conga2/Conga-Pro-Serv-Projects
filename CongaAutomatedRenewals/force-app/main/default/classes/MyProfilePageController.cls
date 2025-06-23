/**
* @author Ashley Green
* @date 20111114
* @version 1.0
* @description MyProfilePageController - An apex class that keeps updates of a portal user in sync with its corresponding contact. Guest users are never able to access this page. 
*/
public with sharing class MyProfilePageController {
    private User user;
    @testVisible private boolean isEdit = false;
    
    /**
    * @description MyProfilePageController - Constructor
    */
    public MyProfilePageController() {
        user = [SELECT id, email, username, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email
                FROM User
                WHERE id = :UserInfo.getUserId()];
        
        // guest users should never be able to access this page
        if (user.usertype == 'GUEST') {
            throw new NoAccessException();
        }
    }
    
    /**
    * @description getUser - 
    * @return User
    */
    public User getUser() {
        return user;
    }

    /**
    * @description getIsEdit - 
    * @return Boolean
    */
    public Boolean getIsEdit() {
        return isEdit;
    }

    /**
    * @description edit - 
    * @return void
    */
    public void edit() {
        isEdit = true;
    }    
    
    /**
    * @description save - 
    * @return void
    */
    public void save() {
        if (user.contact != null) {              
            setContactFields(user.contact, user);
        }
        
        try{
            update user;
            if(user.contact != null) { 
                update user.contact;
            }
            isEdit = false;
        }
        catch(DmlException e) {
            ApexPages.addMessages(e);
        }
    }
    
    /**
    * @description changePassword - 
    * @return PageReference
    */  
    public PageReference changePassword() {
        return Page.ChangePassword;
    }
    
    /**
    * @description cancel - 
    * @return void
    */
    public void cancel() {
        isEdit = false;
        user = [SELECT Id, email, username, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email
                FROM User
                WHERE Id = :UserInfo.getUserId()];
    }

    /**
    * @description setContactFields - 
    * @param Contact c
    * @param User u
    * @return void
    */
    @testVisible
    private static void setContactFields(Contact c, User u) {
        c.title = u.title;
        c.firstname = u.firstname;
        c.lastname = u.lastname;
        c.email = u.email;
        c.phone = u.phone;
        c.mobilephone = u.mobilephone;
        c.fax = u.fax;
        c.mailingstreet = u.street;
        c.mailingcity = u.city;
        c.mailingstate = u.state;
        c.mailingpostalcode = u.postalcode;
        c.mailingcountry = u.country;
    }


}