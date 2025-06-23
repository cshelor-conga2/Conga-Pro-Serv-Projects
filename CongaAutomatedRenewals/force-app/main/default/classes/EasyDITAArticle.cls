public with sharing class EasyDITAArticle {
    @AuraEnabled
    public String Title { get; set; }
    
    @AuraEnabled
    public String Description { get; set; }
    
    @AuraEnabled
    public String Url { get; set; }
}