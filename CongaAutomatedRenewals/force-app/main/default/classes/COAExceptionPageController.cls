public class COAExceptionPageController {
    /*
     * author: Redpoint
     * date: 9/15/2017
     * purpose: Displays a table of exception records to the user who can attempt re-submitting the
     * related opportunities records back through the COA automation process.
     * note:
    */
    
    public List<COA_Exception__c> exceptions {get;set;} //provide list of all exceptions that have CO_Entered set to false
    public String sortDirection = 'ASC';                //determines whether the arrow points up or down
    public Integer offSetSize = 0;                      //the number of records to offset as a user goes through the pages
    public Integer limitSize = 25;                      //the number of records to show per page
    public Integer totalSize = 0;                       //the totoal number of exception records that meet criteria
    public Id record {get;set;}                         //record id of the exception chosen by user
    public String sortBy = '';                          //the column to sort by
    
    //constructor, populate list on initialization
    public COAExceptionPageController() {
        totalSize = 0;
        offSetSize = 0;
    
        if(exceptions != null && exceptions.size() > 0) {
            exceptions = null;
        }

        searchOpps();
    }
    
    //the button a user will click to re-submit the selected opportunity 
    public void resubmitOpportunity() {
        COA_Exception__c coaException = new COA_Exception__c(); 
        
        for(COA_Exception__c coa : exceptions) {
            if(coa.Id == record) {
                coaException = coa;  
            }
        }
        
        Opportunity oppRecord = [
                                SELECT Id 
                                FROM Opportunity 
                                WHERE Id =: coaException.Related_Opportunity__c];
        
        update oppRecord; //just update the opportunity to start the trigger
        
        removeExceptionFromList(coaException);
    }
    
    //if the opportunity was submitted successfully and a new order was created, remove exception record from list
    public void removeExceptionFromList(COA_Exception__c coaException) {
        List<CHANNEL_ORDERS__Service_Order__c> orders = [
                                                        SELECT Id 
                                                        FROM CHANNEL_ORDERS__Service_Order__c 
                                                        WHERE CHANNEL_ORDERS__Related_Opportunity__c =: coaException.Related_Opportunity__c];
        
        if(!orders.isEmpty()) {
            coaException.COA_Entered__c = true;
            //coaException.Service_Order_Created__c = true;
            update coaException;

            ApexPages.Message successmessage = new ApexPages.Message(ApexPages.Severity.Confirm, 'New Service Order created.');
            ApexPages.addMessage(successmessage);

        } else {
            ApexPages.Message errormessage = new ApexPages.Message(ApexPages.Severity.Error, 'Opportunity did not re-submit successfully.');
            ApexPages.addMessage(errormessage);
        }
    }

    /*----------------------------------------------- Pagination Code -----------------------------------------------*/

    public void searchOpps() {
        if(exceptions != null && !exceptions.isEmpty()) {
            exceptions.clear();
        }

        if(totalSize != null && totalSize == 0) {
            List<COA_Exception__c> temp = [SELECT Id FROM COA_Exception__c WHERE COA_Entered__c = False];
            
            if(temp.size() > 0) {
                totalSize = temp.size();
            }
        }

        exceptions = [
                        SELECT Id, Opportunity_Name__c, Customer_Org_Id__c, 
                            Opportunity_Sales_Op_Approved__c, Opportunity_Type__c, 
                            Status__c, Segmented_Deal__c, Related_Opportunity__c, Draft_Service_Order_Created__c
                        FROM COA_Exception__c 
                        WHERE Service_Order_Created__c = False OR Draft_Service_Order_Created__c = TRUE
                        ORDER BY Opportunity_Name__c
                        LIMIT :limitSize OFFSET :offSetSize];
    }

    public void first() {
        offSetSize = 0;
        searchOpps();
    }

    public void previous() {
        offSetSize = (offSetSize - limitSize);
        searchOpps();
    }

    public void next() {
        offSetSize = (offSetSize + limitSize);
        searchOpps();
    }

    public void last() {
        offSetSize = (totalSize - Math.mod(totalSize, limitSize));
        searchOpps();
    }

    public Boolean getprev() {
        if(offSetSize == 0) {
            return true;
        } else
            return false;
    }

    public Boolean getnxt() {
        if((offSetSize + limitSize) > totalSize) {
            return true;
        } else
            return false;
    }

    public Integer getTotalRecords() {
        return totalSize;
    }

    /*----------------------------------------------- Sorting Code -----------------------------------------------*/

    public String getSortDirection() {
        if(sortExpression == null || sortExpression == '') {
            return 'ASC';
        } else {
            return sortDirection;
        }
    }

    public void setSortDirection(String value) {
        sortDirection = value;
    }


    public String sortExpression {
        get {
            return sortBy;
        }

        set {
            if(value == sortBy) {
                sortDirection = (sortDirection == 'ASC') ? 'DESC' : 'ASC';
            } else {
                sortDirection = 'ASC';
                sortBy = value;
            }
        }
    }

    public PageReference sortByColumn() {
        String sortByCol = sortBy + ' ' + sortDirection;

        exceptions = database.query('SELECT Id, Opportunity_Name__c, Customer_Org_Id__c, ' + 
                                        'Opportunity_Sales_Op_Approved__c, Opportunity_Type__c, ' + 
                                        'Status__c, Segmented_Deal__c, Related_Opportunity__c, Draft_Service_Order_Created__c ' +
                                    'FROM COA_Exception__c ' + 
                                    'WHERE Service_Order_Created__c = False ' +
                                    'ORDER BY ' + sortByCol + ' LIMIT ' + limitSize + ' OFFSET ' + offSetSize);
        return null;
    }
}