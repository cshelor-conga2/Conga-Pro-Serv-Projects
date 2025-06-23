public with sharing class OctivTemplateController
{
  private ApexPages.standardController standardController;
  private final Opportunity initialRecord;
  private Id opportunityId;
  private String octivBaseURL = '';
  private String apiKey = '';
  private Set<Id> profileIds;
  //private List<OctivTemplateService.OctivTemplate> globalOctivTemplates;
  private Map<Integer, OctivTemplateService.OctivTemplate> globalOctivTemplatesById;
  public List<selectOption> availableTemplates { get;set; }
  public List<selectOption> availableTemplates1 { get;set; }
  public String categorySearchTemplate { get;set; }
  public String nameSearchTemplate { get;set; }
  public List<selectOption> availableCategories { get;set; }
  public String selectedCategory { get;set; }
  public String nameSearch { get;set; }
  public boolean isPageVisible { get;set; }
  public Opportunity Opp{get;set;}
  public string gebid{get;set;}

  public OctivTemplateController(ApexPages.standardController std)
  {
    standardController = std;
    initialRecord = (Opportunity) std.getRecord();
    opportunityId = initialRecord.Id;
    getOctivAPIInformation();
    setupAvailableCategories();
    selectedCategory = availableCategories[0].getValue();
    setupAcceptableProfiles();
    isPageVisible = checkProfileAccess();
    // Used for testing, remove before deployment
    //isPageVisible = true;
    updateTemplates();
    categorySearch();
    nameSearch();
    Opp=new Opportunity();
    Opp=[select Id,GE_ES_GE_Bid_Legal_Entity_Name__c from Opportunity where Id=:initialRecord.Id];
    string gebid=Opp.GE_ES_GE_Bid_Legal_Entity_Name__c;
    //initialRecord.GE_ES_GE_Bid_Legal_Entity_Name__c;
  }  // End constructor   
   
   private void setupAvailableCategories()
  {
    availableCategories = new List<SelectOption>();
    Map<String, Octiv_Category__c> categories = Octiv_Category__c.getAll();
    for(Octiv_Category__c category : categories.values())
    {
      if(category.Name.equals('Inspection-I-LES Complex Workscopes'))
      {
        if(verifyRoleAccess(userInfo.getUserId()))
        {
          availableCategories.add(new SelectOption(category.Name, category.Category_Name__c));
          availableCategories.sort();
        }  // End if the current user's role permits access
      } 
       else if(category.Name.equals('Outage Services-Performance Test'))
      { 
        if(verifyRoleAccess2(userInfo.getuserId()))
        {
          availableCategories.add(new SelectOption(category.Name, category.Category_Name__c));
          availableCategories.sort();
        }  // End if the current user's role permits access
      }  // End if category name is Outage Services-Performance Test // End if category name is I&LES Complex Workscopes
      else
      {
        availableCategories.add(new SelectOption(category.Name, category.Category_Name__c));
        availableCategories.sort();
      }  // End else populate this category
    }  // End categories loop
  }  // End setupCategories method
  

   private boolean verifyRoleAccess(String userId)
  {
    List<GroupMember> testGroups = [SELECT GroupId,Id,UserOrGroupId FROM GroupMember where GroupId = :[SELECT Id,Name FROM Group where DeveloperName = 'GE_PW_PGP_PGS_Complex_Workscopes_Group'].id and UserOrGroupId=:userId];
    boolean returnValue = false;
    if(testGroups.size() > 0)
    {
      returnValue = true;
    }  // End if userRoleId equals the test role Id
    return returnValue;
  } 
  
  
  private boolean verifyRoleAccess2(String userId)
  {
    List<GroupMember> testGroups = [SELECT GroupId,Id,UserOrGroupId FROM GroupMember where GroupId = :[SELECT Id,Name FROM Group where DeveloperName = 'GE_PW_RG_Perf_Complex_Workscopes_Group'].id and UserOrGroupId=:userId];
    boolean returnValue = false;
    if(testGroups.size() > 0)
    {
      returnValue = true;
    }  // End if userRoleId equals the test role Id
    return returnValue;
  }  
 
  public PageReference updateTemplates()
  {
    //globalOctivTemplates = new List<OctivTemplateService.OctivTemplate>();
    globalOctivTemplatesById = new Map<Integer, OctivTemplateService.OctivTemplate>();
    for(SelectOption option : availableCategories)
    {
      addGlobalOctivTemplates(OctivTemplateService.retrieveTemplates(option.getValue(), octivBaseURL, apiKey));
    }  // End availableCategories loop
    return null;
  }  // End updateTemplates method

  private void addGlobalOctivTemplates(List<OctivTemplateService.OctivTemplate> octivTemplates)
  {
    for(OctivTemplateService.OctivTemplate octivTemplate : octivTemplates)
    {
      if(!globalOctivTemplatesById.containsKey(octivTemplate.id))
      {
        globalOctivTemplatesById.put(octivTemplate.id, octivTemplate);
      }  // End if globalOctivTemplatesById does not contain the current template
    }  // End octivTemplates loop
  }  // End addOctivTemplates method

  public PageReference categorySearch()
  {
    availableTemplates = new List<selectOption>();
    availableTemplates.add(new selectOption('--Select Template--', '--Select Template--'));
    for(OctivTemplateService.OctivTemplate someTemplate : globalOctivTemplatesById.values())
    {
      if(someTemplate.tag_names_str.containsIgnoreCase(selectedCategory))
      {
        String templateId = '';
        templateId += someTemplate.id;
        availableTemplates.add(new SelectOption(templateId, someTemplate.name));
      }  // End if this template is in the selected category
    }  // End for loop
    return null;
  }  // End categorySearch method

  public PageReference nameSearch()
  {
    availableTemplates1 = new List<selectOption>();
    availableTemplates1.add(new selectOption('--Select Template--', '--Select Template--'));
    for(OctivTemplateService.OctivTemplate someTemplate : globalOctivTemplatesById.values())
    {
      if(!String.isBlank(nameSearch) && someTemplate.name.containsIgnoreCase(nameSearch))
      {
        String templateId = '';
        templateId += someTemplate.id;
        availableTemplates1.add(new SelectOption(templateId, someTemplate.name));
      }  // End if this template is in the selected category
    }  // End for loop
    return null;
  }  // End nameSearch method


  public PageReference submitCategorySearch()
  {
    PageReference returnPage = Page.OctivCreateDocument;
    returnPage.getParameters().put('templateId', categorySearchTemplate);
    return handOffToOctiv(returnPage);
  }  // End submitCategorySearch method

  public PageReference submitNameSearch()
  {
    PageReference returnPage = Page.OctivCreateDocument;
    returnPage.getParameters().put('templateId', nameSearchTemplate);
    return handOffToOctiv(returnPage);
  }  // End submitNameSearch method

  public PageReference navBackToOpportunity()
  {
    PageReference returnPage = new PageReference('/' + opportunityId);
    returnPage.setRedirect(true);
    return returnPage;
  }  // End navBackToOpportunity method

  private PageReference handOffToOctiv(pageReference returnPage)
  {
    returnPage.getParameters().put('sObjectType', 'Opportunity');
    returnPage.getParameters().put('recordId', opportunityId);
    returnPage.setRedirect(true);
    return returnPage;
  }  // End handOffToOctiv method

  private void setupAcceptableProfiles()
  {
    profileIds = new Set<Id>();
    Map<String, Octiv_Template_Profiles__c> acceptableProfiles = Octiv_Template_Profiles__c.getAll();
    if(!acceptableProfiles.isEmpty())
    {
      for(Octiv_Template_Profiles__c profile : acceptableProfiles.values())
      {
        profileIds.add((Id)profile.Profile_Id__c);
      }  // End acceptableProfiles.values() loop
    }  // End if acceptableProfiles is not null
  }  // End setupAcceptableProfiles method

  private boolean checkProfileAccess()
  {
    boolean profileMatch = false;
    for(Id profileId : profileIds)
    {
      if(Id.valueOf(userInfo.getProfileId()) == profileId)
      {
        profileMatch = true;
      }  // End if current user's profileId is equal to the current test profileId
    }  // End profileIds loop
    return profileMatch;
  }  // End checkProfileAccess method

  private void getOctivAPIInformation()
  {
    Octiv_Template_API__c apiSetting = Octiv_Template_API__c.getInstance('Octiv');
    if(apiSetting != null)
    {
      octivBaseURL = apiSetting.Endpoint__c;
      apiKey = apiSetting.API_Key__c;
    }  // End if apiSetting is not null
    else
    {
      octivBaseURL = '';
      apiKey = '';
    }  // End else set the API properties to blank
  }
  
public void saveOpp(){
    update Opp;
    }  // End getOctivAPIInformation method
}  
// End OctivTemplate class