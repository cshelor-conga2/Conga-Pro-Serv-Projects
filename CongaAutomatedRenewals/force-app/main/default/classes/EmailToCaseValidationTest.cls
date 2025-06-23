/**
* @author JCDJ, jcdiaz@systemyc.com
* @date 2019-06-04
* @version 1.0
* @description EmailToCaseValidationTest - Test class for the EmailToCaseValidation class
*/
@isTest
public class EmailToCaseValidationTest {
	
	///**
	//* @description testCaseInsertOk - 
	//*/
	//@isTest
	//public static void testCaseInsertOk() {

	//	Id userId = UserInfo.getUserId();

	//	Case c = new Case(
	//		SuppliedEmail = 'test@test.com',
	//		OwnerId = userId,
	//		Subject = 'testing'
	//	);

	//	Test.startTest();
	//	insert c;
	//	Test.stopTest();

	//	System.assertNotEquals(null,c.Id);
	//}	

	///**
	//* @description testCaseInsertRejectedBySender - 
	//*/
	//@isTest
	//public static void testCaseInsertRejectedBySender() {

	//	EmailToCaseValidation.EmailToCaseValidationConfiguration config = new EmailToCaseValidation.EmailToCaseValidationConfiguration();

	//	System.assertEquals(true, config.Enabled);
	//	System.assertEquals(false, config.QueueNames.isEmpty());
	//	System.assertEquals(false, config.FromKeywords.isEmpty());
	//	System.assertEquals(false, config.SubjectKeywords.isEmpty());

	//	List<Group> groups = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :config.QueueNames AND Type = 'Queue'];
	//	System.assertEquals(false, groups.isEmpty());

	//	Id queueId = groups[0].Id;
	//	String queueName = groups[0].DeveloperName;
	//	String emailSender = new List<String>(config.FromKeywords)[0];
	//	String emailSubject = new List<String>(config.SubjectKeywords)[0];

	//	if (emailSender.startsWith('@')) emailSender = 'test' + emailSender;

	//	Case c = new Case(
	//		OwnerId = queueId,			
	//		SuppliedEmail = emailSender,
	//		Subject = emailSubject
	//	);

	//	Test.startTest();
	//	Database.SaveResult insertResult = Database.insert(c, false);
	//	Test.stopTest();

	//	System.assertEquals(false, insertResult.isSuccess());
	//	List<Database.Error> errors = insertResult.getErrors();
	//	System.assertEquals(1, errors.size());
	//	System.assertEquals(true, errors[0].getMessage().containsIgnoreCase(queueName));
	//	System.assertEquals(true, errors[0].getMessage().containsIgnoreCase(emailSender));
	//}

	///**
	//* @description testCaseInsertRejectedBySubject - 
	//*/
	//@isTest
	//public static void testCaseInsertRejectedBySubject() {
	//	EmailToCaseValidation.EmailToCaseValidationConfiguration config = new EmailToCaseValidation.EmailToCaseValidationConfiguration();

	//	System.assertEquals(true, config.Enabled);
	//	System.assertEquals(false, config.QueueNames.isEmpty());
	//	System.assertEquals(false, config.FromKeywords.isEmpty());
	//	System.assertEquals(false, config.SubjectKeywords.isEmpty());

	//	List<Group> groups = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :config.QueueNames AND Type = 'Queue'];
	//	System.assertEquals(false, groups.isEmpty());

	//	Id queueId = groups[0].Id;
	//	String queueName = groups[0].DeveloperName;
	//	String emailSubject = new List<String>(config.SubjectKeywords)[0];

	//	Case c = new Case(
	//		OwnerId = queueId,			
	//		SuppliedEmail = 'test@test.com',
	//		Subject = emailSubject
	//	);

	//	Test.startTest();
	//	Database.SaveResult insertResult = Database.insert(c, false);
	//	Test.stopTest();

	//	System.assertEquals(false, insertResult.isSuccess());
	//	List<Database.Error> errors = insertResult.getErrors();
	//	System.assertEquals(1, errors.size());
	//	System.assertEquals(true, errors[0].getMessage().containsIgnoreCase(queueName));
	//	System.assertEquals(true, errors[0].getMessage().containsIgnoreCase(emailSubject));	
	//}


}