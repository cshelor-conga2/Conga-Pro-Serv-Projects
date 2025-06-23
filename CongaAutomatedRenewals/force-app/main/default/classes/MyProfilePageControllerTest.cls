/**
* @author ECS, ERedding
* @date 20190520
* @version 1.00
* @description MyProfilePageControllerTest - Test class for the MyProfilePageController class
*/
@isTest
public with sharing class MyProfilePageControllerTest {

	/**
	* @description testSave - 
	*/
	static testmethod void testSave() {
        // Modify the test to query for a portal user that exists in your org
        List<User> existingPortalUsers = [SELECT id, profileId, userRoleId FROM User WHERE UserRoleId <> null AND UserType='CustomerSuccess'];

        if(existingPortalUsers.isEmpty()) {
            User currentUser = [SELECT Id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
                                FROM User WHERE Id = :UserInfo.getUserId()];

            MyProfilePageController controller = new MyProfilePageController();
            System.assertEquals(currentUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
            System.assert(controller.isEdit == false, 'isEdit should default to false');
            
            controller.edit();
            System.assert(controller.isEdit == true);
            
            controller.cancel();
            System.assert(controller.isEdit == false);
            
            Contact c = new Contact();
            c.LastName = 'TestContact';
            insert c;
            
            MyProfilePageController.setContactFields(c, currentUser);
            controller.save();
            System.assert(Page.ChangePassword.getUrl().equals(controller.changePassword().getUrl()));
        }
        else{
            User existingPortalUser = existingPortalUsers[0];
            String randFax = Math.rint(Math.random() * 1000) + '5551234';
            
            System.runAs(existingPortalUser) {
                MyProfilePageController controller = new MyProfilePageController();
                System.assertEquals(existingPortalUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
                System.assert(controller.isEdit == false, 'isEdit should default to false');
                
                controller.edit();
                System.assert(controller.isEdit == true);
                
                controller.cancel();
                System.assert(controller.isEdit == false);
                
                controller.getUser().Fax = randFax;
                controller.save();
                System.assert(controller.isEdit == false);
            }
            
            // verify that the user and contact were updated
            existingPortalUser = [SELECT Id, Fax, Contact.Fax FROM User WHERE Id =: existingPortalUser.Id];
            System.assert(existingPortalUser.Fax == randFax);
            System.assert(existingPortalUser.Contact.Fax == randFax);
        }
    }


}