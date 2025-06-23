/**
* @author Conga Services
* @date 20181019
* @version 1.0
* @param Any platform trigger event for the Asset object
*/ 
trigger AssetTrigger on Asset (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete) {
    TriggerFactory.createTriggerDispatcher(Asset.sObjectType);

    ///////////////// CONGA SERVICES ER 20181019 - BELOW CODE IS FOR THE OLD TRIGGER FACTORY THAT HAS BEEN DEPRECATED.
    //TriggerDispatcher.execute(Asset.sObjectType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    //List<Asset> assetList = new List<Asset>();

    //if(Trigger.isAfter && Trigger.isInsert) 
    //{
    //  for (Asset a : trigger.new)
    //  {
    //      assetList.add(a);
    //  }

    //    assetHandler.handleAfterInsert(assetList);
    //    Asset_Helper.UpdateAccountOwnership(assetList);
    //}
     
/*  else if(Trigger.isAfter && Trigger.isUpdate) 
    {

        List<Asset> newAssets = new List<Asset>();

        for (Asset a : trigger.New)
        {
            newAssets.add(a);
        }
        
        List<Asset> oldAssets = new List<Asset>();

        for (Asset a : trigger.Old)
        {
            oldAssets.add(a);

        }

        assetHandler.handleAfterUpdate(newAssets, oldAssets);
    }*/


}