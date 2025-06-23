public class QuoteComposerOrderFormController {
	
	@TestVisible
	private static string testApproverId = null;
	
    @AuraEnabled
    public static String getComposerParameters(Id quoteId) {
        List<SBQQ__Quote__c> quotes = [select Id,Composer_Order_Form_Params__c,Owner_Contract_Approver_Id__c from SBQQ__Quote__c where Id = :quoteId];
        if(quotes.isEmpty()) return null;

		SBQQ__Quote__c quote = quotes[0];
		String approvedId = quote.Owner_Contract_Approver_Id__c;
        String urlParameters = quote.Composer_Order_Form_Params__c;
		List<String> fromToIds = Label.ReplaceMatchIds.split(',');
		Map<String,String> fromToReplaceIds = new Map<String,String>();
		if(String.isBlank(approvedId)) approvedId = Label.DefaultApproverId;

		//for testing purposes
		if(testApproverId!=null) approvedId=testApproverId;

		for(String match : fromToIds){
			List<String> replaceIds = match.split('>');
			if (replaceIds.size()!= 2) continue;
			fromToReplaceIds.put(replaceIds[0], replaceIds[1]);
		}

		if(fromToReplaceIds.containsKey(approvedId)) approvedId = fromToReplaceIds.get(approvedId);

        urlParameters = urlParameters.replace('{{approverId}}',approvedId);

        urlParameters = urlParameters.replace('{{queryId}}',Label.OrderFormQueryId);

        urlParameters = replaceFields(SObjectType.SBQQ__Quote__c.name, quoteId, urlParameters);

        urlParameters = getCongaSessionVariables() + '&' + urlParameters;

        return urlParameters;
    }

    private static String getCongaSessionVariables() {
        PageReference pr = Page.CongaSessionVariables;
        String content = !Test.isRunningTest() ? pr.getContent().toString() : 'Start_Of_SessionId:session:End_Of_SessionIdStart_Of_ServerUrl:server:End_Of_ServerUrl';

        Integer s = content.indexOf('Start_Of_SessionId:') + 'Start_Of_SessionId:'.length();
        Integer e = content.indexOf(':End_Of_SessionId');
        String sessionId = content.substring(s, e);

        s = content.indexOf('Start_Of_ServerUrl:') + 'Start_Of_ServerUrl:'.length();
        e = content.indexOf(':End_Of_ServerUrl');
        String serverUrl = content.substring(s, e);

        return sessionId + '&' + serverUrl;
    }

    private static String replaceFields(String objectName, String id, String text) {
		Set<String> fieldNames = getObjectFields(objectName, text);
		if(fieldNames.isEmpty()) return text;
		fieldNames.add('Id');

		String query = 'select ' + String.join(new List<String>(fieldNames),',') + ' from ' + objectName + ' where Id = :id';

		List<SObject> records = Database.query(query);
		if(records.isEmpty()) return text;

		SObject record = records[0];

		Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new String[] { objectName});
		Schema.DescribeSObjectResult dsr = results[0];
		Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();

		for(String fieldName : fieldNames) {
			if(!fieldsMap.containsKey(fieldName)) continue;

			String value = '';

			Schema.DescribeFieldResult field = fieldsMap.get(fieldName).getDescribe();
			Schema.DisplayType type = field.getType();
			if(type == Schema.DisplayType.Date) {
				Date dateField = (Date)record.get(fieldName);
				if(dateField != null) {
					value = dateField.format();
				}
			} else if(type == Schema.DisplayType.DateTime) {
				DateTime dateTimeField = (DateTime)record.get(fieldName);
				if(dateTimeField != null) {
					value = dateTimeField.format();
				}
			} else {
				value = String.valueOf(record.get(fieldName));
            }
            
            if(value == null) value = '';

            String fieldNameToReplace = '{!' + fieldName + '}';
            text = text.replace(fieldNameToReplace, value);
            fieldNameToReplace = '{!' + objectName + '.' + fieldName + '}';
            text = text.replace(fieldNameToReplace, value);
		}

		return text;
	}

	public static Set<String> getObjectFields(String objectName, String text) {
		Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new String[] { objectName});
		Schema.DescribeSObjectResult dsr = results[0];
		Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();

		Set<String> fields = new Set<String>();

		Pattern formatPattern = Pattern.compile('\\{!([a-zA-Z\\_]*)\\.?([^}]*)}');
		Matcher formatMatcher = formatPattern.matcher(text);
		while(formatMatcher.find()) {
            String field = formatMatcher.group(2);
            if(String.isBlank(field)) field = formatMatcher.group(1);
			if(!fieldsMap.containsKey(field)) continue;
			fields.add(field);
		}

		return fields;
	}
}