trigger addFilesTrigger on tinderbox__Document__c (before insert) {
    for (tinderbox__Document__c newDocument : Trigger.new) {
        addFilesExtension.addFiles(newDocument.tinderbox__Opportunity__c, newDocument.tinderbox__TinderBoxId__c);  
    }
}