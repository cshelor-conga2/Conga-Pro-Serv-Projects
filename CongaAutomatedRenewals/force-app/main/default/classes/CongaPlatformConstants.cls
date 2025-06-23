public class CongaPlatformConstants {
   
    public static final String API_ACCOUNT = '/v1/accounts/{0}'; //GET, DELETE, PATCH - (AccountId)
    public static final String API_ACCOUNT_EXTERNAL = '/v1/accounts/{0}/{1}'; //GET - (SystemType, AccountId)
    public static final String API_ACCOUNTS = '/v1/accounts'; //GET, POST
    public static final String API_LICENSE_DESIGNEES = '/v1/accounts/{0}/license-designees'; //GET, POST - (AccountId)
    public static final String API_ASSIGN_LICENSE = '/v1/accounts/{0}/license-designees/{1}/licenses'; //GET POST (AccountId, LicesneDesigneeId)
    public static final String API_USER_DESIGNEE = '/v1/accounts/{0}/users/{1}/license-designees'; //GET (AccountId, UserId)
    public static final String API_USER_LICENSES = '/v1/accounts/{0}/users/{1}/licenses'; //GET (AccountId, UserId)
    public static final String API_USERS = '/v1/users'; //GET POST
    public static final String API_USER = '/v1/users/{0}'; //GET, DELETE
    public static final String API_USERS_ACCOUNT = '/v1/accounts/{0}/users'; //GET, POST - (AccountId)
    public static final String API_USERS_EXTERNAL = '/v1/users/{0}/{1}'; //GET - (SystemType, UserId)
    public static final String API_DELETE_USER = '/v1/accounts/{0}/users/{1}'; //DELETE - (AccountId, UserId)
    public static final String API_PRODUCTS = '/v1/products'; //GET, POST
    public static final String API_PRODUCT_EXTERNAL = '/v1/products/{0}/{1}'; //GET, DELETE - (SystemType, ProudctId)
    public static final String API_ASSETS = '/v1/accounts/{0}/assets'; //GET, POST - (AccountId)
    public static final String API_MANAGE_ASSET = '/v1/accounts/{0}/assets/{1}'; //GET, DELETE, PATCH - (AccountId, AssetId)
    public static final String API_ASSET_EXTERNAL = '/v1/assets/{0}/{1}'; //GET - (SystemType, AssetId)
    public static final String API_HEADER_APIKEY = 'x-api-key';
    public static final String API_REGION_AFFINITY = '/v1/region-affinities'; //GET
    public static final String API_SERVICE_APIKEY = 'ServiceApiKey';

}