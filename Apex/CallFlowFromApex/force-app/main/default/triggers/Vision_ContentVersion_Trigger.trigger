trigger Vision_ContentVersion_Trigger on ContentVersion (after insert) {
    // This trigger is designed to handle the after insert event for ContentVersion records.
    // It will call the Flow_Trigger_Handler class to process the inserted records.

    // Query a single from the Vision object to get the Id prefix
    Vision__c obj = [SELECT Id FROM Vision__c LIMIT 1];
    String visionIdPrefix = String.valueOf(obj.Id).substring(0, 3);
    
    // Only trigger ContentVersions added to Vision object (FirstPublishLocationId starts with '001')
    List<ContentVersion> relatedVision = new List<ContentVersion>();
    for (ContentVersion cv : Trigger.new) {
        if (cv.FirstPublishLocationId != null && String.valueOf(cv.FirstPublishLocationId).substring(0, 3) == visionIdPrefix) {
            relatedVision.add(cv);
        }
    }
    if (!relatedVision.isEmpty()) {
        Flow_Trigger_Handler.callFlow(relatedVision);
    }
}