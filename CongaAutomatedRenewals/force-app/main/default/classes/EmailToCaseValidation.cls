/**
* @author JCDJ, jcdiaz@systemyc.com
* @date 2019-06-03
* @version 1.0
* @description EmailToCaseValidation - 
*/
@isTest
public class EmailToCaseValidation {

	/**
	* @description Helper class to load configuration from custom metadata type Email_to_case_Validation__mdt
	*/
	//public class EmailToCaseValidationConfiguration {
	//	public Boolean Enabled {get; set;}
	//	public Set<String> QueueNames {get; set;}
	//	public Set<String> FromKeywords {get; set;}
	//	public Set<String> SubjectKeywords {get; set;}

	//	/**
	//	* @description EmailToCaseValidationConfiguration - Constructor
	//	*/
	//	public EmailToCaseValidationConfiguration() {
	//		this.Enabled = false;
	//		this.QueueNames = new Set<String>();
	//		this.FromKeywords = new Set<String>();
	//		this.SubjectKeywords = new Set<String>();

	//		List<Email_to_case_Validation__mdt> configurations = [SELECT Enabled__c, From__c, Queue__c, Subject__c FROM Email_to_case_Validation__mdt];
	//		if (configurations.isEmpty()) return;
			
	//		Email_to_case_Validation__mdt configuration = configurations[0];
			
	//		this.Enabled = configuration.Enabled__c;

	//		if (!String.isBlank(configuration.Queue__c)) {
	//			for (String queueName : configuration.Queue__c.split(';')) {
	//				this.QueueNames.add(queueName);
	//			}
	//		}

	//		if (!String.isBlank(configuration.From__c)) {
	//			for (String fromKeyword : configuration.From__c.split(';')) {
	//				this.FromKeywords.add(fromKeyword);
	//			}
	//		}

	//		if (!String.isBlank(configuration.Subject__c)) {
	//			for (String subjectKeyword : configuration.Subject__c.split(';')) {
	//				this.SubjectKeywords.add(subjectKeyword);
	//			}
	//		}
	//	}
	//}

	/**
	* @description validateEmailToCase - Validation to avoid Case creation if certain conditions apply to incomming message.
	* @param List<Case> newCases
	* @return void
	*/
	//public static void validateEmailToCase(List<Case> newCases) {
	//	try{
	//		if(TriggerHelper.DoExecute('EmailToCaseValidation','validateEmailToCase') && newCases != null){

	//			if (newCases.isEmpty()) return;
			
	//			EmailToCaseValidationConfiguration configuration = new EmailToCaseValidationConfiguration();
	//			if (!configuration.Enabled) return;
	//			if (configuration.QueueNames.isEmpty()) return;
	//			if (configuration.FromKeywords.isEmpty()) return;
	//			if (configuration.SubjectKeywords.isEmpty()) return;

	//			Map<Id,Group> queuesMap = new Map<Id,Group>([SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :configuration.QueueNames AND Type = 'Queue']);
	//			if (queuesMap.isEmpty()) return;

	//			for (Case c : newCases) {

	//				// message destination condition
	//				Boolean ownerMatch = false;
	//				for (Id queueId : queuesMap.keySet()) {
	//					if (c.OwnerId == queueId) {
	//						ownerMatch = true;
	//						break;
	//					}
	//				}
	//				if (!ownerMatch) continue; // If this condition isn't satisfied, there's no need to evaluate further conditions.

	//				// message sender condition
	//				Boolean fromMatch = false;
	//				String fromValidation;
	//				if (!String.isBlank(c.SuppliedEmail)) {
	//					for (String fromKeyword : configuration.FromKeywords) {
	//						if (c.SuppliedEmail.containsIgnoreCase(fromKeyword)) {
	//							fromMatch = true;
	//							fromValidation = String.Format('"{0}" contains "{1}"',new String[] {c.SuppliedEmail,fromKeyword}); //TODO: label
	//							break;
	//						}
	//					}
	//				}
	//				if (fromMatch) {
	//					// message destination condition is true and also this condition --> case creation rejected.
	//					String queueDevName = queuesMap.get(c.OwnerId).DeveloperName;
	//					String errorMessage = 'Case creation rejected by email-to-case custom validation. Message sent to queue "{0}" and from address {1}.'; //TODO: Label
	//					errorMessage = String.Format(errorMessage,new String[] {queueDevName, fromValidation});
	//					c.addError(errorMessage);
	//					continue; 
	//				}

	//				// message subject condition
	//				Boolean subjectMatch = false;
	//				String subjectValidation;
	//				if (!String.isBlank(c.Subject)) {
	//					for (String subjectKeyword : configuration.SubjectKeywords) {
	//						if (c.Subject.containsIgnoreCase(subjectKeyword)) {
	//							subjectMatch = true;
	//							subjectValidation = String.Format('"{0}" contains "{1}"', new String[] {c.Subject,subjectKeyword}); //TODO: Label
	//							break;
	//						}
	//					}
	//				}
	//				if (subjectMatch) {
	//					// message destination condition is true and also this condition --> case creation rejected.
	//					String queueDevName = queuesMap.get(c.OwnerId).DeveloperName;
	//					String errorMessage = 'Case creation rejected by email-to-case custom validation. Message sent to queue "{0}" and message subject {1}.'; //TODO: Label
	//					errorMessage = String.Format(errorMessage, new String[] {queueDevName, subjectValidation});
	//					c.addError(errorMessage);
	//					continue; 
	//				}
	//			}

	//			// END AUDIT IF ONE IS STARTED
	//			TriggerHelper.EndExecute('EmailToCaseValidation','validateEmailToCase');
	//		}
	//	}
	//	catch(Exception ex){
	//		SystemIssueLogHelper.LogException('EmailToCaseValidation', 'validateEmailToCase', newCases, ex, true);
	//	}
	//}

	/**
	* @description doDefaultAssignment - To execute default assigment of inserted Case records.
	* @param Set<Id> newCaseIds
	* @return void
	*/
	//public static void doDefaultAssignment(Set<Id> newCaseIds) {
	//	try{
	//		if(TriggerHelper.DoExecute('EmailToCaseValidation','doDefaultAssignment') && newCaseIds != null){
				
	//			if (newCaseIds.isEmpty()) return;

	//			List<Case> cases = [SELECT Id FROM Case WHERE Id IN :newCaseIds AND Owner.Name IN ('Email-to-Case (success)','Email-to-Case (tdasupport)')];
	//			if (cases.isEmpty()) return;

	//			Database.DMLOptions dmo = new Database.DMLOptions();
	//			dmo.assignmentRuleHeader.useDefaultRule = true;

	//			for(Case c : cases) {
	//				c.setOptions(dmo);
	//			}

	//	    	Database.SaveResult[] updateResults = Database.update(cases, false);
	//			SystemIssueLogHelper.CheckForDatabaseErrors(updateResults, 'EmailToCaseValidation', 'doDefaultAssignment', true);

	//			// END AUDIT IF ONE IS STARTED
	//			TriggerHelper.EndExecute('EmailToCaseValidation','doDefaultAssignment');
	//		}
	//	}
	//	catch(Exception ex){
	//		SystemIssueLogHelper.LogException('EmailToCaseValidation', 'doDefaultAssignment', newCaseIds, ex, true);
	//	}
	//}


}