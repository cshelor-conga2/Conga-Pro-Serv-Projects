public class OctivTemplateService
{

  public class OctivTemplate implements Comparable
  {
    public String type { get;set; }
    public Integer id { get;set; }
    public String name { get;set; }
    public String author { get;set; }
    public String description { get;set; }
    public String tag_names_str { get;set; }

    public octivTemplate(String t, Integer i, String n, String a, String d, String tag)
    {
      type = t;
      id = i;
      name = n;
      author = a;
      description = d;
      tag_names_str = tag;
    }  // End constructor
    public Integer compareTo(Object compareToObject)
    {
      OctivTemplate cto = (OctivTemplate) compareToObject;
      if(this.name.equals(cto.name))
      {
        return 0;
      }  // End if the two objects are equal
      else if(this.name < cto.name)
      {
        return -1;
      }  // End if this instance is less than that passed in
      else return 1;
    }  // End compareTo method
  }  // End OctivTemplate class

  //@future (callout=true)
  public static List<OctivTemplate> retrieveTemplates(String categoryName, String uri, String apiKey)
  {
    List<OctivTemplate> octivTemplates;
    String apiCall = '?q%5Bname_or_description_cont%5D=';
    String apiPrefix = 'api_key=';
    String apiPart2 = '&q%5Bsearch_tags%5D=1&q%5Btype_null%5D=1&';
    String sanitizedSearch = replaceSpaces(categoryName);
    String perAmount = '&per=200';
    String calloutEndpoint = uri + apiCall + sanitizedSearch + apiPart2 + apiPrefix + apiKey + perAmount;
    System.debug('callout: ' + calloutEndpoint);
    HttpRequest req = new HttpRequest();
    req.setMethod('GET');
    req.setEndpoint(calloutEndpoint);
    req.setHeader('X-Ember', 'ignite');
    Http http = new Http();
    HttpResponse res = http.send(req);
    System.debug('Http Response: ' + res.getBody());
    if(res.getStatusCode() == 200)
    {
      octivTemplates = parseResponse(res.getBody());
      System.debug('template list has: ' + octivTemplates.size());
      octivTemplates.sort();
    }  // End if response code equals 200
    return octivTemplates;
  }  // End retrieveTemplates method

  private static List<OctivTemplate> parseResponse(String body)
  {
    List<OctivTemplate> octivTemplates = new List<OctivTemplate>();
    JsonParser parser = JSON.createParser(body);
    while(parser.nextToken() != null)
    {
      if(parser.getCurrentToken() == JSONToken.START_Array)
      {
        while(parser.nextToken() != null)
        {
          if(parser.getCurrentToken() == JSONToken.START_OBJECT)
          {
            OctivTemplate template = (OctivTemplate)parser.readValueAs(OctivTemplate.class);
            octivTemplates.add(template);
            parser.skipChildren();
          }  // End if current token is START_OBJECT
        }  // End inner while loop
      }  // End if current token is START_ARRAY
    }  // End outer while loop
    return octivTemplates;
  }  // End parseResponse method
  private static String replaceSpaces(String inputString)
  {
    String returnString = '';
    if(inputString != null)
    {
    for(String s : inputString.split(' '))
    {
      returnString += s + '%20';
    }  // End for loop
    returnString = returnString.subStringBeforeLast('%20');
    System.debug('returnString = ' + returnString);
    }  // End if inputString is not null
    return returnString;
  }  // End replaceSpaces method
}  // End OctivTemplateService class