trigger addPagesUponCreateTrigger on tinderbox__Document__c (before insert) {
    for (tinderbox__Document__c newDocument : Trigger.new) {
        addPagesUponCreate.addPages(newDocument.tinderbox__Opportunity__c, newDocument.tinderbox__TinderBoxId__c);  
    }
}