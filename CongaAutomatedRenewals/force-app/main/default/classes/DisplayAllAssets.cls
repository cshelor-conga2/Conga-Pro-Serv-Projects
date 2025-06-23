/**
* @author Bethany Spencer
* @date 20161104
* @version 1.00
* @description DisplayAllAssets - 
*/
public class DisplayAllAssets {
    public Account AccountInfo {get;set;}

    /**
    * @description DisplayAllAssets - Constructor
    * @param ApexPages.StandardController controller
    */
    public DisplayAllAssets(ApexPages.StandardController controller){
        String accountId = [SELECT AccountId FROM Case WHERE Id = :Apexpages.currentpage().getparameters().get('id')].AccountId;
        AccountInfo = new Account(Id = accountId);
    }


}