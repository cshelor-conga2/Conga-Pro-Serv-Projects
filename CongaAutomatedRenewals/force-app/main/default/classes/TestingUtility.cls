/**
* @author CRMCulture, LLC
*/
@isTest
public class TestingUtility {
    public static Boolean AUTOCREATE_LOOKUPOBJECTS = false; //Set if you want lookups to query for the first object in the table
    public static Boolean AUTO_LOOKUPCHILDOBJECTS = false; //Set if you want lookups to create objects (if AUTOCREATE_LOOKUPOBJECTS is true it will only create if one isnt found)
    public static Boolean FillAllFields = false;

    // Key : SobjectAPIName  For ex. Account 
    // Value : Map<String, Schema.SObjectField>, field map (k:fieldname, v:Schema.Sobjectfield)
    public static Profile userProfile = [Select Id from Profile where Name = 'System Administrator' Order By CreatedDate limit 1];
    private static final Map<String, Map<String, Schema.SObjectField>> FieldMapCache = new Map<String, Map<String, Schema.SObjectField>>();

    // Default Country and State
    // When Country and State Picklists are enabled, cannot dynamically resolve which States are within a Country
    public static string DefaultCountry = 'United States';
    public static string DefaultState = 'Wisconsin';

    // Key: sobject.field
    // Value: first picklist value
    private static final Map<String, String> DefaultPicklistValue = new Map<String, String>();

    // include nillable fields
    public static Map<String, Set<String>> IncludedFields = new Map<String, Set<String>>();

    // can't map by Schema.sObjectType, use object name String instead
    public static Map<String, Set<String>> ExcludedFields = new Map<String, Set<String>>{
        'All' => new Set<String>{'OwnerId', 'LastModifiedById', 'CreatedById', 'LastModifiedDate', 'CreatedDate'},
        'Account' => new Set<String>{'FirstName', 'LastName'},
        'User' => new Set<String>{'IsActive','DelegatedApproverId','CallCenterId','ContactId','DelegatedApproverId','ManagerId','UserRoleId','FederationIdentifier'}
    };

    public static List<SObject> createSObjectList(String objectName, Boolean cascade, Integer numberOfObjects) {
        List<SObject> populatedObjects = new List<SObject>();
        for(Integer i=0; i < numberOfObjects; i++){
            populatedObjects.add(createSObject(objectName, cascade, i));
        }
        return populatedObjects;  
    }

    public static SObject createSObject(String objectName) {
        return createSObject(objectName, false);
    }
    public static SObject createSObject(String objectName, Boolean cascade) {
        return createSObject(objectName, cascade, 1);
    }
    public static SObject createSObject(String objectName, Boolean cascade, Integer counter) {
        Schema.sObjectType token = UtilityClass.SObjectTypes.get(objectName);
        if (token == null) {
            return null; //throw new Exception('Unsupported ObjectType ' + objectName);
        }

        SObject obj = token.newSObject();
        for(Schema.SObjectField field : fieldMapFor(objectName.toLowerCase(), cascade).values()) {
            setFieldValue(obj, field, cascade, counter);
        }
        return obj;
    }

    /**
    *   Returns a field map for a given sobject. 
    *
    *   Note : this method is kept public for Test cases to share the same field map info, without requiring a field desribe.
    *
    *   @param objectName sobject api name for ex. Account
    *   @returns FieldMap [Key:FieldName,Value:Schema.SObjectField]
    */
    public static  Map<String, Schema.SObjectField> fieldMapFor(String objectName, Boolean cascade) {
        Map<String, Schema.SObjectField> fieldMap = null;
        if(FieldMapCache.containsKey(objectName)) {
            fieldMap = FieldMapCache.get(objectName);
        }
        else {
            fieldMap = new Map<String, Schema.SObjectField>();
            for(Schema.SObjectField field : UtilityClass.SObjectTypes.get(objectName).getDescribe().fields.getMap().values()){
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                if(fieldDescribe.isCreateable() && 
                    (
                        isIncludedField(objectName, fieldDescribe) || 
                        (
                            ((!fieldDescribe.isNillable() || FillAllFields) || (fieldDescribe.getType() == Schema.DisplayType.Reference && cascade)) // always fill references with cascade
                              && !isExcludedField(fieldDescribe) && !isExcludedField(objectName, fieldDescribe) && (!isPersonAccountField(fieldDescribe))
                        )
                    )
                ){
                    fieldMap.put(fieldDescribe.getName(), field);
                }
            }
            // cache it for next use
            FieldMapCache.put(objectName, fieldMap);
        }
        return fieldMap;
    }

    static String getDefaultPicklistValue(SObject obj, Schema.DescribeFieldResult fieldDescribe) {
        String key = obj.getSObjectType() + '.' + fieldDescribe.getName();

        if (!DefaultPicklistValue.containsKey(key)) {
            List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
            String value = entries.size() > 0 ? entries[0].getValue() : null;
            DefaultPicklistValue.put(key, value);
        }
        return DefaultPicklistValue.get(key);
    }

    static Boolean isExcludedField(Schema.DescribeFieldResult fieldDescribe) {
        return ExcludedFields.get('All').contains(fieldDescribe.getName());
    }

    static Boolean isExcludedField(String objName, Schema.DescribeFieldResult fieldDescribe) {
        return (!ExcludedFields.containsKey(objName) ? false : ExcludedFields.get(objName).contains(fieldDescribe.getName()));
    }

    static Boolean isIncludedField(String objName, Schema.DescribeFieldResult fieldDescribe) {
        return (!IncludedFields.containsKey(objName) ? false : IncludedFields.get(objName).contains(fieldDescribe.getName()));
    }  

    static Boolean isPersonAccountField(Schema.DescribeFieldResult fieldDescribe) {
        Boolean isPersonAccountEnabled = UtilityClass.SObjectTypes.get('Account').getDescribe().fields.getMap().containsKey('IsPersonAccount');
        Set<String> skipPersonAccountFields = new Set<String>{ 'Salutation' };
        Boolean customPerson = fieldDescribe.isCustom() && fieldDescribe.getName().endsWith('pc');
        Boolean standardPerson = !fieldDescribe.isCustom() && fieldDescribe.getName().startsWith('Person');

        return customPerson || standardPerson || (isPersonAccountEnabled && skipPersonAccountFields.contains(fieldDescribe.getName()));
    }

    static void setFieldValue(SObject obj, Schema.SObjectField field, Boolean cascade) {
        setFieldValue(obj, field, cascade, 0);
    }

    static void setFieldValue(SObject obj, Schema.SObjectField field, Boolean cascade, Integer counter) {
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        if(fieldDescribe.getName().endsWith('Country')) {
            obj.put(field, DefaultCountry);
        } else if (fieldDescribe.getName().endsWith('State')) {
            obj.put(field, DefaultState);
        } else if (fieldDescribe.getType() == Schema.DisplayType.base64) {
            obj.put(field, blob.valueOf(counter.format()));
        } else if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
            obj.put(field, false);
        } else if (fieldDescribe.getType() == Schema.DisplayType.Combobox) {
            obj.put(field, counter.format());
        } else if (fieldDescribe.getType() == Schema.DisplayType.Currency) {
            obj.put(field, counter);
        } else if (fieldDescribe.getType() == Schema.DisplayType.Date) {
            obj.put(field, Date.today());
        } else if (fieldDescribe.getType() == Schema.DisplayType.DateTime) {
            obj.put(field, DateTime.now());
        } else if (fieldDescribe.getType() == Schema.DisplayType.Double) {
            obj.put(field, counter);
        } else if (fieldDescribe.getType() == Schema.DisplayType.Email) {
            obj.put(field, 'test' + counter.format() + '@mailinator.com');
        } else if (fieldDescribe.getType() == Schema.DisplayType.EncryptedString) {
            obj.put(field, 's');
        } else if (fieldDescribe.getType() == Schema.DisplayType.Id) {
            //System.debug('Id field ' + fieldDescribe.getName());
        } else if (fieldDescribe.getType() == Schema.DisplayType.Integer) {
            obj.put(field, counter);
        } else if (fieldDescribe.getType() == Schema.DisplayType.MultiPicklist) {
            obj.put(field, getDefaultPicklistValue(obj, fieldDescribe));
        } else if (fieldDescribe.getType() == Schema.DisplayType.Percent) {
            obj.put(field, counter);
        } else if (fieldDescribe.getType() == Schema.DisplayType.Phone) {
            obj.put(field, '123-456-7890');
        } else if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
            obj.put(field, getDefaultPicklistValue(obj, fieldDescribe));
        } else if (fieldDescribe.getName() == 'CommunityNickname' && fieldDescribe.getType() == Schema.DisplayType.String) { 
            obj.put(field, 'test'+ string.valueof(math.roundtolong(math.random()*1000000)) ); 
        } else if (fieldDescribe.getName() == 'UserName' && fieldDescribe.getType() == Schema.DisplayType.String) { 
            obj.put(field, 'test'+ string.valueof(Userinfo.getOrganizationId())+ string.valueof(math.roundtolong(math.random()*1000000))+ string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','')+'@mailinator.com'); // was a@a.com
        } else if (fieldDescribe.getType() == Schema.DisplayType.String) {
            obj.put(field, counter.format()); 
        } else if (fieldDescribe.getType() == Schema.DisplayType.Reference) {
            String referenceObjectType = fieldDescribe.getReferenceTo()[0].getDescribe().getName();
            try{ 
                if (referenceObjectType == 'RecordType') {
                    setRecordType(obj);
                } else if (cascade && referenceObjectType != obj.getSObjectType().getDescribe().getName() &&
                            referenceObjectType !='BusinessHours') {
                    // TODO avoid infinite loop for same-type references
                    Boolean foundItem = false;
                    if(AUTO_LOOKUPCHILDOBJECTS){
                        String rSoql = ' select Id from ' + referenceObjectType + ' limit 1';
                        List<sObject> referenceQuery = database.query(rsoql);
                        if(referenceQuery.size() > 0){
                            foundItem = true;
                            obj.put(field,referenceQuery[0].Id);
                        }
                    }
                    if(AUTOCREATE_LOOKUPOBJECTS && !foundItem){
                        //System.debug('Creating reference to ' + referenceObjectType + ' for field ' + obj.getSObjectType().getDescribe().getName() + '.' + fieldDescribe.getName());
                        SObject reference = createSObject(referenceObjectType);
                        //System.debug('Inserting ' + reference);
                        insert reference;
                        obj.put(field, reference.Id);
                    } 
                }
                else if (referenceObjectType == 'Profile') { 
                    obj.put(field,userProfile.Id);
                }
            }catch(DmlException ex){
                //System.debug('Failed insert for ' + referenceObjectType + ' ' + ex.getMessage());
            }
        } else if (fieldDescribe.getType() == Schema.DisplayType.TextArea) {
            obj.put(field, counter.format()); 
        } else if (fieldDescribe.getType() == Schema.DisplayType.Time) {
            obj.put(field, Time.newInstance(0, 0, 0, 0)); 
        } else if (fieldDescribe.getType() == Schema.DisplayType.URL) {
            obj.put(field, 'http://test' + counter + '.com'); 
        } else {
            //System.debug('Unhandled field type ' + fieldDescribe.getType());
        }
    }

    static void setRecordType(SObject obj) {
        List<Schema.RecordTypeInfo> recordTypes = obj.getSObjectType().getDescribe().getRecordTypeInfos();

        if (recordTypes.size() > 1) { // all objects have default Master type
            for (Schema.RecordTypeInfo recordType : recordTypes) {
                if (recordType.isAvailable() && recordType.isDefaultRecordTypeMapping()) {
                    obj.put('RecordTypeId', recordType.getRecordTypeId());
                }
            }
        }
    }

    /**
    * @description createTestMeta - Helper method for creating test custom metadata records that are not saved to the database
    */
    public static SObject createTestMeta(String pCustomMetaObject, Map<String, Object> pFieldValueMap){
        // GET SOBJECT TYPE AND START A NEW CUSTOM METEDATA RECORD
        Schema.SObjectType customMetaObjectType = UtilityClass.SObjectTypes.get(pCustomMetaObject);
        if(customMetaObjectType != null){
            SObject newCustomMetaRecord = customMetaObjectType.newSobject();

            // POPULATE CUSTOM METADATA RECORD FIELDS
            Map<String, Object> customMetaFieldValues = (Map<String, Object>)JSON.deserializeUntyped(JSON.serializePretty(newCustomMetaRecord));
            for(String fieldName : pFieldValueMap.keySet()){
                customMetaFieldValues.put(fieldName, pFieldValueMap.get(fieldName));    
            }
            newCustomMetaRecord = (SObject)JSON.deserialize(JSON.serialize(customMetaFieldValues), SObject.class);

            // RETURN TEST META
            return newCustomMetaRecord;
        }
        return null;
    }


    /**      
    * @author Conga Services, ERedding
    * @date 20190731
    * @description MultiRequestMock - Returns the correct mock response based on request endpoint and http method. For testing multiple call outs happening in a single transaction.
    */
    public class MultiRequestMock implements HttpCalloutMock {
        public Map<String, Map<String, HttpCalloutMock>> HttpCalloutMockClasses; // MOCK CLASSES WITH INNER RESPONSES
        public Map<String, Map<String, HttpResponse>> HttpMockResponses; // MOCK RESPONSES

        /**
        * @description MultiRequestMock - Default Constructor
        */ 
        public MultiRequestMock() {
            this.HttpCalloutMockClasses = new Map<String, Map<String, HttpCalloutMock>>();
            this.HttpMockResponses = new Map<String, Map<String, HttpResponse>>();
        }

        /**
        * @description MultiRequestMock - Constructor taking a parameter
        * @param Map<String, Map<String, HttpCalloutMock>> pHttpCalloutMockClasses
        */
        public MultiRequestMock(Map<String, Map<String, HttpCalloutMock>> pHttpCalloutMockClasses) {
            this.HttpCalloutMockClasses = pHttpCalloutMockClasses;
        }

        /**
        * @description MultiRequestMock - Constructor taking a parameter
        * @param Map<String, Map<String, HttpResponse>> pMockHttpResponses
        */
        public MultiRequestMock(Map<String, Map<String, HttpResponse>> pMockHttpResponses) {
            this.HttpMockResponses = pMockHttpResponses;
        }

        /**
        * @description addCalloutMockClass - Add a mock response class that implements HttpCalloutMock
        * @param String url - 
        * @param String httpMethod - 
        * @param HttpCalloutMock httpCalloutMockClass - 
        */
        public void addCalloutMockClass(String url, String httpMethod, HttpCalloutMock httpCalloutMockClass) {
            if(!HttpCalloutMockClasses.containsKey(url)){
                HttpCalloutMockClasses.put(url, new Map<String, HttpCalloutMock>());
            }
            HttpCalloutMockClasses.get(url).put(httpMethod, httpCalloutMockClass);
        }

        /**
        * @description addHttpMockResponse - Add a standalone Http mock response
        * @param String url - 
        * @param String httpMethod - 
        * @param HttpCalloutMock httpMockResponse - 
        */
        public void addHttpMockResponse(String url, String httpMethod, HttpResponse httpMockResponse) {
            if(!HttpMockResponses.containsKey(url)){
                HttpMockResponses.put(url, new Map<String, HttpResponse>());
            }
            HttpMockResponses.get(url).put(httpMethod, httpMockResponse);
        }

        /**
        * @description respond - Returns the appropriate HTTPResponse based on the given HTTPRequest
        * @param HTTPRequest req
        * @return HTTPResponse
        */
        public HTTPResponse respond(HTTPRequest req) {
            // LOOK FIRST AT MOCK REPONSE CLASSES
            if(HttpCalloutMockClasses.containsKey(req.getEndpoint()) && HttpCalloutMockClasses.get(req.getEndpoint()).containsKey(req.getMethod()) && 
                HttpCalloutMockClasses.get(req.getEndpoint()).get(req.getMethod()) != null){

                return HttpCalloutMockClasses.get(req.getEndpoint()).get(req.getMethod()).respond(req);
            }
            // THEN LOOK AT MOCK RESPONSES
            else if(HttpMockResponses.containsKey(req.getEndpoint()) && HttpMockResponses.get(req.getEndpoint()).containsKey(req.getMethod()) &&
                HttpMockResponses.get(req.getEndpoint()).get(req.getMethod()) != null){
                
                return HttpMockResponses.get(req.getEndpoint()).get(req.getMethod());
            }

            throw new CustomException('No Mock Callout matches the request\'s endpoint and/or method');
        }
    }

    public class CustomException extends Exception{
    }


}