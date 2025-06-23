/**
* @author Systemyc, Giovanni Modica
* @date 20180105
* @version 1.00
* @description SiteOrderApprovalController - 
*/
public with sharing class SiteOrderApprovalController {
    public static final String SITE_NAME = 'Payments';
    private static final String SITE_PATH = 'pmtx';
    private static final String DEFAULT_ROLE = 'Economic Buyer';
    private static final String CHECKOUT_PAGE = 'pymt__sitecheckout';

    public static final String noOrderMessage = 'No order was specified';
    public static final String noOrderFoundMessage = 'The order id specified was invalid';
    public static final String noOpportunityMessage = 'The order is not associated to an opportunity';
    public static final String noSettingsMessage = 'There are no settings configured for Quotes And Invoices';
    public static final String noSiteSettingsMessage = 'There are no settings configured for the site "{0}"';
    public static final String noSiteMessage = 'There is no site "{0}"';
    public static final String noProcessorMessage = 'There is no default processor selected';
    public static final String acceptanceRequiredMessage = 'The terms must be accepted before submitting a payment';

    public Order order {get; private set;}
    public Opportunity opportunity {get; private set;}
    public Account account {get; private set;}
    public Contact contact {get; private set;}
    public Contact updatedContact {get; private set;}
    public quot__QI_Settings__c settings {get; private set;}
    public pymt__Sites_Website_Settings__c webSiteSettings {get; private set;}
    public List<OrderItem> lineItems {get; private set;}
    public List<Line> lines {get; private set;}

    private pymt__Processor_Connection__c processor;
    private Site site;
    private String orderId;
    private String contactId;
    private String accountId;

    public Boolean disableForm {get; private set;}
    public Boolean enableBillingInfoEdit {get; private set;}
    public String signature {get; set;}
    public Boolean termsAccepted {get; set;}

    /**
    * @description SiteOrderApprovalController - Constructor
    */
    public SiteOrderApprovalController() {
        // get settings
        settings = selectSettings();
        if(settings == null || String.isBlank(settings.quot__Sites_Website__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, noSettingsMessage));
            disableForm = true;
            return;
        }
        webSiteSettings = selectWebSiteSettings(settings.quot__Sites_Website__c);
        if(webSiteSettings == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, String.format(noSiteSettingsMessage, new String[] { settings.quot__Sites_Website__c })));
            disableForm = true;
            return;
        }
        site = selectSite(settings.quot__Sites_Website__c);
        if(site == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, String.format(noSiteMessage, new String[] { settings.quot__Sites_Website__c })));
            disableForm = true;
            return;
        }

        // get order
        orderId = ApexPages.currentPage() != null ? ApexPages.currentPage().getParameters().get('id') : null;
        if(String.isBlank(orderId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, noOrderMessage));
            disableForm = true;
            return;
        }        
        order = selectOrder(orderId);
        if(order == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, noOrderFoundMessage));
            disableForm = true;
            return;
        }

        // get opportunity
        if(order.OpportunityId != null) opportunity = selectOpportunity(order.OpportunityId);
        if(opportunity == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, noOpportunityMessage));
            disableForm = true;
            return;
        }

        // get account
        accountId = ApexPages.currentPage().getParameters().get('aid');
        if(!String.isBlank(accountId)) account = selectAccount(accountId);
        if(account == null && opportunity != null && opportunity.AccountId != null) account = selectAccount(opportunity.AccountId);
        if(account == null && order != null && order.AccountId != null) account = selectAccount(order.AccountId);

        // get contact
        contactId = ApexPages.currentPage().getParameters().get('cid');
        if(!String.isBlank(contactId)) contact = selectContact(contactId);
        if(contact == null && account != null && account.BillingContact__c != null) contact = selectContact(account.BillingContact__c);
        if(contact == null && opportunity != null && opportunity.Billing_Party__c != null && opportunity.Billing_Party__r.BillingContact__c != null) contact = selectContact(opportunity.Billing_Party__r.BillingContact__c);
        if(contact == null && order != null && order.BillToContactId != null) contact = selectContact(order.BillToContactId);

        // get order line items
        lineItems = selectOrderItems(order.Id);
		lines = convertOrderItemsToLines(lineItems);
        
        // get processor
        processor = selectProcessor();
        if(processor == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, noProcessorMessage));
            disableForm = true;
            return;
        }

        enableBillingInfoEdit = false;
    } 
    
    public String shipToStreet {
        get {
            if(contact != null && contact.MailingStreet != null) return contact.MailingStreet;
            if(account != null && account.ShippingStreet != null) return account.ShippingStreet;
            if(order != null && order.ShippingStreet != null) return order.ShippingStreet;
            return null;
        }
    }

    public String shipToCity {
        get {
            if(contact != null && contact.MailingCity != null) return contact.MailingCity;
            if(account != null && account.ShippingCity != null) return account.ShippingCity;
            if(order != null && order.ShippingCity != null) return order.ShippingCity;
            return null;
        }
    }   

    public String shipToState {
        get {
            if(contact != null && contact.MailingState != null) return contact.MailingState;
            if(account != null && account.ShippingState != null) return account.ShippingState;
            if(order != null && order.ShippingState != null) return order.ShippingState;
            return null;
        }
    }   

    public String shipToPostalCode {
        get {
            if(contact != null && contact.MailingPostalCode != null) return contact.MailingPostalCode;
            if(account != null && account.ShippingPostalCode != null) return account.ShippingPostalCode;
            if(order != null && order.ShippingPostalCode != null) return order.ShippingPostalCode;
            return null;
        }
    }   

    public String shipToCountry {
        get {
            if(contact != null && contact.MailingCountry != null) return contact.MailingCountry;
            if(account != null && account.ShippingCountry != null) return account.ShippingCountry;
            if(order != null && order.ShippingCountry != null) return order.ShippingCountry;
            return null;
        }
    }

    public String billToStreet {
        get {
            if(order != null && order.BillingStreet != null) return order.BillingStreet;
            if(updatedContact != null && updatedContact.MailingStreet != null) return updatedContact.MailingStreet;
            if(account != null && account.BillingStreet != null) return account.BillingStreet;
            return null;
        }
    }

    public String billToCity {
        get {
            if(order != null && order.BillingCity != null) return order.BillingCity;
            if(updatedContact != null && updatedContact.MailingCity != null) return updatedContact.MailingCity;
            if(account != null && account.BillingCity != null) return account.BillingCity;
            return null;
        }
    }   

    public String billToState {
        get {
            if(order != null && order.BillingState != null) return order.BillingState;
            if(updatedContact != null && updatedContact.MailingState != null) return updatedContact.MailingState;
            if(account != null && account.BillingState != null) return account.BillingState;
            return null;
        }
    }   

    public String billToPostalCode {
        get {
            if(order != null && order.BillingPostalCode != null) return order.BillingPostalCode;
            if(updatedContact != null && updatedContact.MailingCountry != null) return updatedContact.MailingPostalCode;
            if(account != null && account.BillingPostalCode != null) return account.BillingPostalCode;
            return null;
        }
    }   

    public String billToCountry {
        get {
            if(order != null && order.BillingCountry != null) return order.BillingCountry;
            if(updatedContact != null && updatedContact.MailingCountry != null) return updatedContact.MailingCountry;
            if(account != null && account.BillingCountry != null) return account.BillingCountry;
            return null;
        }
    }

    public String billToAddress {
        get {
            if(opportunity != null && opportunity.RecordType.DeveloperName == 'Indirect' && order != null && order.Billing_Address_Override__c != null) return order.Billing_Address_Override__c;
            return null;
        }
    }

    public Boolean canEditBillingInfo {
        get {
            return !alreadyPaid && opportunity != null && opportunity.RecordType.DeveloperName == 'Direct' && order.Type != 'Services';
        }
    }

    public String currencyShortFormatExpression {
        get {
            if(webSiteSettings == null || webSiteSettings.pymt__Currency_Format__c == null) return '{0,number,currency}';
            
            String format = webSiteSettings.pymt__Currency_Format__c;
            format = format.replace('ISO','').trim();
            format = formatCurrencyDecimals(format);

            return format;
        }
    }

    public String currencyFormatExpression {
        get {
            if(webSiteSettings == null || webSiteSettings.pymt__Currency_Format__c == null) return '{0,number,currency}';
            
            String format = webSiteSettings.pymt__Currency_Format__c;
            format = format.replace('ISO',UserInfo.getDefaultCurrency()).trim();
            format = formatCurrencyDecimals(format);

            return format;
        }
    }

    /**
    * @description formatCurrencyDecimals - 
    * @param String format
    * @return String
    */
    private String formatCurrencyDecimals(String format) {
        Integer totalDecimals = 0;
        Boolean decimalFound = false;
        for(Integer i = 0; i < format.length(); i++) {
            if(format.mid(i,1) == '.') decimalFound = true;
            else if(format.mid(i,1) == 'x' && decimalFound) totalDecimals++;
        }
        format = format.replace('x.' + 'x'.repeat(totalDecimals),'{0,number,#,##0.' + '0'.repeat(totalDecimals) + '}');
        return format;
    }

    public Decimal subtotal {
        get {
            return isNull(order.TotalAmount,0);
        }
    }

    public Decimal total {
        get {
            return isNull(order.TotalAmount,0) + isNull(shipping,0) + isNull(tax,0);
        }
    }

    public Decimal shipping {
        get {
            return 0;
        }
    }

    public Decimal discount {
        get {
            if(lineItems == null || lineItems.size() == 0) return 0;

            Decimal discount = 0;
            Decimal totalUnitPrice = 0;
            Decimal totalListPrice = 0;

            for(OrderItem orderItem : lineItems) {
                totalUnitPrice += orderItem.Quantity * orderItem.UnitPrice;
                totalListPrice += orderItem.Quantity * orderItem.ListPrice;
            }            

            discount = totalListPrice - totalUnitPrice;
            
            return discount;
        }
    }

    public Boolean showDiscount {
        get {
            return false;
        }
    }

    public Decimal tax {
        get {
            return order.AVA_SFORDERS__Sales_Tax__c;
        }
    }

    public Decimal balance {
        get {
            return order.Amount_DueFx__c;
        }
    }

    public Boolean alreadyPaid {
        get {
            return order.Amount_DueFx__c == 0;
        }
    }

    public Boolean hasRecurringAmount {
        get {
            return false;
        }
    }

    public String recurringSetup {
        get {
            return null;
        }
    }

    public Boolean requireSignatory {
        get {
            return true;
        }
    }

    public Boolean hasExpiration {
        get {
            return false;
        }
    }

    public Boolean hasLineItems {
        get {
            return lineItems != null && lineItems.size() > 0;
        }
    }

    ////////////////// ACTIONS ///////////////////

    /**
    * @description changeBillingInformation - 
    * @return PageReference
    */
    public PageReference changeBillingInformation() {
        if(updatedContact == null) {
            String street = billToStreet;
            String city = billToCity;
            String postalCode = billToPostalCode;
            String state = billToState;
            String country = billToCountry;

            updatedContact = new Contact();

            if(contact != null) {
                updatedContact.AccountId = account.Id;
                updatedContact.FirstName = contact.FirstName;
                updatedContact.LastName = contact.LastName;
                updatedContact.MailingStreet = street;
                updatedContact.MailingCity = city;
                updatedContact.MailingPostalCode = postalCode;
                updatedContact.MailingState = state;
                updatedContact.MailingCountry = country;
                updatedContact.Email = contact.Email;
                updatedContact.Phone = contact.Phone;
            }
        }
        else
            updatedContact = null;

        enableBillingInfoEdit = !enableBillingInfoEdit;

        return null;
    }

    /**
    * @description `Transaction - 
    * @return PageReference
    */
    public PageReference cancelTransaction() {
        return null;
    }

    /**
    * @description processQuote - 
    * @return PageReference
    */
    public PageReference processQuote() {
        if(requireSignatory && (String.isBlank(signature) || termsAccepted == false || termsAccepted == null )) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, acceptanceRequiredMessage));
            return null;
        }

        try {
            if(updatedContact != null) updatedContact = resolveDuplicates(updatedContact);
            pymt__PaymentX__c payment = createPayment();
            List<pymt__Shopping_Cart_Item__c> items = createItems(payment);
            Task acceptanceTask = createTask(payment);            

            SavePoint sp = Database.setSavePoint();
            try {
                if(updatedContact != null) {
                    upsert updatedContact;
                    //insert new OpportunityContactRole(OpportunityId = opportunity.Id, ContactId = updatedContact.Id, Role = DEFAULT_ROLE, IsPrimary = true);
                    account.BillingContact__c = updatedContact.Id;
                    update account;                
                    payment.pymt__Contact__c = updatedContact.Id;
                }
                insert payment;
                for(pymt__Shopping_Cart_Item__c item : items) {
                    item.pymt__Payment__c = payment.Id;
                }
                insert items;
                insert acceptanceTask;
            } 
            catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }

            return new PageReference(makeUrl(CHECKOUT_PAGE) + '?pid=' + payment.Id + '&key=' + payment.pymt__Key__c + '&cancel_url=' + getCurrentUrl() + '&finish_url=http://www.conga.com');
        } 
        catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
            System.debug(e.getMessage() + '\r\n' + e.getStackTraceString());
            return null;
        }                
    }

    /////////////////// SERVICE LOGIC //////////////////

    /**
    * @description resolveDuplicates - 
    * @param Contact contact    
    * @return Contact
    */
    private Contact resolveDuplicates(Contact contact) {
        Contact[] contacts = [select Id,AccountId,FirstName,LastName,Name,MailingStreet,MailingCity,MailingPostalCode,MailingState,MailingCountry,Email,Phone from Contact where (FirstName = :contact.FirstName and LastName = :contact.LastName) or Email = :contact.Email];
        if(contacts.size() == 0) return contact;

        Contact existingContact = contacts[0];
        existingContact.AccountId = account.Id;
        existingContact.FirstName = contact.FirstName;
        existingContact.LastName = contact.LastName;
        existingContact.MailingStreet = contact.MailingStreet;
        existingContact.MailingCity = contact.MailingCity;
        existingContact.MailingPostalCode = contact.MailingPostalCode;
        existingContact.MailingState = contact.MailingState;
        existingContact.MailingCountry = contact.MailingCountry;
        existingContact.Email = contact.Email;
        existingContact.Phone = contact.Phone;
        return existingContact;
    }

    /**
    * @description createPayment -  
    * @return pymt__PaymentX__c
    */
    private pymt__PaymentX__c createPayment() {
        Account paymentAccount = account;
        Contact paymentContact = updatedContact != null ? updatedContact : contact;
        Account billToAccount = account;
        Contact billToContact = updatedContact != null ? updatedContact : contact;
        Account shipToAccount = account;
        Contact shipToContact = updatedContact != null ? updatedContact : contact;

        pymt__PaymentX__c payment = new pymt__PaymentX__c();

        payment.Name = order.OrderNumber;
        payment.pymt__Account__c = paymentAccount.Id;
        payment.pymt__Amount__c = balance;
        // payment.pymt__Auth_Expiration__c = ;
        // payment.pymt__Auth_Amount__c = ;
        // payment.pymt__Authorization_Id__c = ;
        // payment.pymt__Batch_Id__c = ;
        // payment.pymt__Batch_Processing_Action__c = ;
        // payment.pymt__Batch_Processing_Result__c = ;
        payment.pymt__Billing_City__c = billToCity;
        payment.pymt__Billing_Company__c = billToAccount.Name;
        payment.pymt__Billing_Country__c = billToCountry;
        payment.pymt__Billing_Email__c = billToContact.Email;
        payment.pymt__Billing_First_Name__c = billToContact.FirstName;
        payment.pymt__Billing_Last_Name__c = billToContact.LastName;
        payment.pymt__Billing_Phone__c = billToContact.Phone;
        payment.pymt__Billing_Postal_Code__c = billToPostalCode;
        payment.pymt__Billing_State__c = billToState;
        payment.pymt__Billing_Street__c = billToStreet;
        // payment.pymt__Card_Type__c = ;
        // payment.quot__Case__c = ;
        // payment.pymt__Category_Split_Expression__c = ;
        // payment.pymt__Category_Split_Name__c = ;
        // payment.pymt__Category_Splits__c = ;
        // payment.pymt__Category_Split_Total__c = ;
        // payment.pymt__Check_Number__c = ;
        // payment.pymt__Connection_Error__c = ;
        payment.pymt__Contact__c = paymentContact.Id;
        payment.pymt__Currency_ISO_Code__c = UserInfo.getDefaultCurrency();
        payment.pymt__Discount__c = discount;
        //payment.External_ID__c = ;
        payment.pymt__Invoice_Number__c = order.OrderNumber;
        // payment.pymt__IP_Address__c = ;
        // payment.pymt__Is_Scheduled__c = ;
        payment.pymt__Key__c = ''; // TODO
        // payment.pymt__Last_4_Digits__c = ;
        // payment.pymt__Last_Batch_Processing_Attempt__c = ;
        // payment.pymt__Last_Response_Status__c = ;
        // payment.pymt__Latitude__c = ;
        payment.pymt__Log__c = '++++ Payment on Invoice ' + order.OrderNumber + ':\nOnline payment for ' + String.valueOf(total) + UserInfo.getDefaultCurrency();
        // payment.pymt__Longitude__c = ;
        //payment.pymt__Map__c = '<img src="/s.gif" alt="Transaction Location" border="0"/>';
        // payment.pymt__Memo__c = ;
        // payment.pymt__Merchant_Custom_Data__c = ;
        // payment.pymt__OnPaymentCompleted_Trigger__c = ;
        payment.pymt__Opportunity__c = opportunity.Id;
        payment.Order__c = order.Id;
        // payment.pymt__Parent_Transaction__c = ;
        payment.pymt__Date__c = Date.today();
        // payment.pymt__Payment_Method__c = ;
        payment.pymt__Payment_Processor__c = processor.Name; // TODO
        // payment.pymt__Payment_Request_Date__c = ;
        payment.pymt__Payment_Type__c = 'Credit Card';
        // payment.pymt__PO_Number__c = ;
        // payment.pymt__Processing_Action_Lead_Time__c = ;
        // payment.pymt__Processing_Attempts__c = ;
        payment.pymt__Processor_Connection__c = processor.Id;
        // payment.pymt__Payment_Profile__c = ;
        // payment.pymt__Reference_Id__c = ;
        // payment.pymt__Reschedule__c = ;
        // payment.pymt__Scheduled_Payment_Date__c = ;
        // payment.pymt__Scheduled_Payment_Number__c = ;
        // payment.pymt__Settlement_Id__c = ;
        payment.pymt__Shipping__c = shipping;
        // payment.pymt__Shipping_Calc_Result__c = ;
        payment.pymt__Shipping_Method__c = opportunity.quot__Shipping_Method__c;
        payment.pymt__Ship_To_City__c = shipToCity ;
        payment.pymt__Ship_To_Company__c = shipToAccount.Name;
        payment.pymt__Ship_To_Country__c = shipToCountry;
        payment.pymt__Ship_To_First_Name__c = shipToContact.FirstName;
        payment.pymt__Ship_To_Last_Name__c = shipToContact.LastName;
        payment.pymt__Ship_To_Name__c = shipToContact.Name;
        payment.pymt__Ship_To_Phone__c = shipToContact.Phone;
        payment.pymt__Ship_To_Postal_Code__c = shipToPostalCode;
        payment.pymt__Ship_To_State__c = shipToState;
        payment.pymt__Ship_To_Street__c = shipToStreet;
        payment.pymt__Status__c = 'In Process';
        // payment.pymt__Subscription_Id__c = ;
        payment.pymt__Tax__c = tax;
        // payment.pymt__Tax_Calc_Result__c = ;
        // payment.pymt__Tax_Method__c = ;
        // payment.pymt__Is_Test_Transaction__c = ;
        // payment.pymt__Transaction_Fee__c = ;
        // payment.pymt__Transaction_Id__c = ;
        payment.pymt__Transaction_Type__c = 'Payment';
        // payment.pymt__Trigger_Payment_Request__c = ;
        // payment.pymt__Trigger_Shipping_Calc__c = ;
        // payment.pymt__Trigger_Tax_Calc__c = ;

        return payment;
    }

    /**
    * @description createItems -  
    * @param pymt__PaymentX__c payment
    * @return List<pymt__Shopping_Cart_Item__c>
    */
    private List<pymt__Shopping_Cart_Item__c> createItems(pymt__PaymentX__c payment) {
        List<pymt__Shopping_Cart_Item__c> items = new List<pymt__Shopping_Cart_Item__c>();
        Integer lineNumber = 0;
        for(OrderItem orderItem : lineItems) {
            pymt__Shopping_Cart_Item__c item = new pymt__Shopping_Cart_Item__c();
            
            item.Name = orderItem.Order.Type == 'Services' ? orderItem.MilestoneId__r.Name : orderItem.Product2.Name;
            item.pymt__Contact__c = payment.pymt__Contact__c;
            item.pymt__Description__c = orderItem.Description;
            //item.pymt__Lead__c = ;
            item.pymt__Line_Number__c = ++lineNumber;
            item.pymt__On_Payment_Completed__c = orderItem.Product2.pymt__On_Payment_Completed__c;
            item.pymt__Payment__c = payment.Id;
            // item.pymt__Payment_Completed__c = ;
            item.pymt__Product__c = orderItem.Product2Id;
            item.pymt__Product_Code__c = orderItem.Order.Type == 'Services' ? '' : orderItem.Product2.ProductCode;
            item.pymt__Quantity__c = Math.abs(orderItem.Quantity);
            // item.pymt__Shipped__c = ;
            item.pymt__Tangible__c = orderItem.Product2.pymt__Tangible__c;
            item.pymt__Taxable__c = orderItem.Product2.pymt__Taxable__c;
            //item.pymt__Total__c = orderItem.TotalPrice;
            // item.pymt__Tracking_Number__c = ;
            item.pymt__Unit_Price__c = orderItem.Quantity < 0 ? - orderItem.UnitPrice : orderItem.UnitPrice;

            items.add(item);
        }

        return items;
    }

    /**
    * @description createTask -  
    * @param pymt__PaymentX__c payment
    * @return Task
    */
    private Task createTask(pymt__PaymentX__c payment) {
        Task acceptanceTask = new Task();
        acceptanceTask.Subject = 'SiteQuote Terms & Conditions Accepted';
        acceptanceTask.WhoId = payment.pymt__Contact__c;
        acceptanceTask.WhatId = order.Id;
        acceptanceTask.Status = 'Completed';
        acceptanceTask.Description = String.escapeSingleQuotes(signature) + ' accepted the Terms & Conditions on invoice ' + order.OrderNumber;
        return acceptanceTask;
    }

    ///////////////////////// UTILITY ////////////////////////

    /**
    * @description isNull -  
    * @param Decimal param
    * @param Decimal defaultValue    
    * @return Decimal
    */
    private Decimal isNull(Decimal param, Decimal defaultValue) {
        if(param == null) return defaultValue;
        else return param;
    }

    /**
    * @description makeUrl -  
    * @param String path  
    * @return String
    */
    private String makeUrl(String path) {
        String sitePath = site != null && site.UrlPathPrefix != null ? site.UrlPathPrefix : SITE_PATH;
        return '/' + sitePath + '/' + path;
    }

    /**
    * @description getCurrentUrl -   
    * @return String
    */
    private String getCurrentUrl() {
        String url = makeUrl('SiteOrderApproval') + '?id=' + order.Id;
        if(!String.isBlank(contactId)) url += '&cid=' + contactId;
        if(!String.isBlank(accountId)) url += '&aid=' + accountId;
        return url;
    }

    /**
    * @description convertOrderItemsToLines -  
    * @param List<OrderItem> lineItems   
    * @return List<Line>
    */    
    private List<Line> convertOrderItemsToLines(List<OrderItem> lineItems) {
        List<Line> lines = new List<line>();
        for(OrderItem oi : lineItems) {
            lines.add(new Line(oi));
        }
        return lines;
    }
  
    /**
    * @description Line - 
    */    
    public class Line {
        public String Id {get; private set;}
        public String product {get; private set;}
        public String description {get; private set;}
        public String type {get; private set;}
        public Decimal unitPrice {get; private set;}
        public Decimal totalPrice {get; private set;}
        public Decimal quantity {get; private set;}
        public Decimal discount {get; private set;}

        /**
        * @description Line - Constructor
        */           
        public Line(OrderItem oi) {
            Id = oi.Id;
            if(oi.Order.Type == 'Services') {
                product = oi.MilestoneId__r.Name;
            }
            else {
                product = oi.Product2.Name;
            }
            quantity = oi.Quantity;
            unitPrice = oi.UnitPrice;
            totalPrice = oi.TotalPrice;
            description = oi.Description;
            discount = oi.Calculated_Discount__c;
            type = oi.Order.Type;
        }
    }


    ////////////////////// SELECTORS ////////////////////////

    /**
    * @description selectOrder -  
    * @param Id orderId  
    * @return Order
    */    
    private Order selectOrder(Id orderId) {
        List<Order> orders = [
            SELECT
                Id,
                OrderNumber,
                EffectiveDate,
                AccountId,
                OpportunityId,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingPostalCode,
                BillingCountry,
                ShippingStreet,
                ShippingCity,
                ShippingState,
                ShippingPostalCode,
                ShippingCountry,
                ShipToContactId,
                BillToContactId,
                TotalAmount,
                AVA_SFORDERS__Sales_Tax__c,
                AVA_SFORDERS__Total__c,
                Billing_Address_Override__c,
                Amount_DueFx__c,
                Type,
                PoNumber,
                ProjectId__c,
                ProjectId__r.Name,
                Description
            FROM
                Order
            WHERE
                Id = :orderId
        ];
        
        if(orders.size() > 0){
            return orders[0];
        }
        return null;
    }

    /**
    * @description selectOpportunity -  
    * @param Id opportunityId  
    * @return Opportunity
    */  
    private Opportunity selectOpportunity(Id opportunityId) {
        List<Opportunity> opps = [
            SELECT
                Id,
                Name,
                Owner.FirstName,
                Owner.LastName,
                quot__Quote_Number__c,
                quot__Quote_Version__c,
                pymt__SiteQuote_Expiration__c,
                Account.Name,
                HasOpportunityLineItem,
                pymt__Tax__c,
                pymt__Shipping__c,
                pymt__Recurring_Amount__c,
                pymt__Frequency__c,
                pymt__Period__c,
                pymt__Occurrences__c,
                quot__Terms_and_Conditions__c,
                quot__Terms_and_Conditions_RT__c,
                pymt__Invoice_Number__c,
                quot__Shipping_Method__c,
                Billing_Party__c,
                Billing_Party__r.BillingContact__c,
                RecordTypeId,
                RecordType.DeveloperName
            FROM
                Opportunity
            WHERE
                Id = :opportunityId
        ];

        if(opps.size() > 0){
            return opps[0];
        }
        return null;
    }

    /**
    * @description selectAccount -  
    * @param Id accountId  
    * @return Account
    */  
    private Account selectAccount(Id accountId) {
        List<Account> accounts = [
            SELECT
                Id,
                Name,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingPostalCode,
                BillingCountry,
                ShippingStreet,
                ShippingCity,
                ShippingState,
                ShippingPostalCode,
                ShippingCountry,
                BillingContact__c
            FROM
                Account
            WHERE
                Id = :accountId
        ];

        if(accounts.size() > 0){
            return accounts[0];
        }
        return null;
    }

    /**
    * @description selectContact -  
    * @param Id contactId  
    * @return Contact
    */  
    private Contact selectContact(Id contactId) {
        List<Contact> contacts = [
            SELECT
                Id,
                Name,
                FirstName,
                LastName,
                Email,
                Phone,
                MailingStreet,
                MailingCity,
                MailingPostalCode,
                MailingState,
                MailingCountry,
                OtherStreet,
                OtherCity,
                OtherPostalCode,
                OtherState,
                OtherCountry
            FROM
                Contact
            WHERE
                Id = :contactId
        ];

        if(contacts.size() > 0){
            return contacts[0];
        }
        return null;
    }

    /**
    * @description selectOrderItems -  
    * @param Id orderId  
    * @return List<OrderItem>
    */  
    private List<OrderItem> selectOrderItems(Id orderId) {
        return [
            SELECT
                Id,
                OrderId,
                Description,
                Quantity,
                Product2.Name,
                Product2.ProductCode,
                Product2.pymt__On_Payment_Completed__c,
                Product2.pymt__Tangible__c,
                Product2.pymt__Taxable__c,
                UnitPrice,
                TotalPrice,
                ListPrice,
                Calculated_Discount__c,
                MilestoneId__c,
                MilestoneId__r.Name,
                Order.Type
            FROM
                OrderItem
            WHERE
                OrderId = :orderId
        ];
    }

    /**
    * @description selectSite -  
    * @param String name 
    * @return Site
    */  
    private Site selectSite(String name) {
        List<Site> sites = [
            SELECT 
                Id, 
                Name, 
                Subdomain, 
                UrlPathPrefix
            FROM
                Site
            WHERE
                Name = :name
        ];

        if(sites.size() > 0) return sites[0];

        return null;
    }

    /**
    * @description selectProcessor -  
    * @return pymt__Processor_Connection__c
    */  
    private pymt__Processor_Connection__c selectProcessor() {
        List<pymt__Processor_Connection__c> processors = [
            SELECT
                Id,
                Name
            FROM
                pymt__Processor_Connection__c
            WHERE
                pymt__Default_Connection__c = true
        ];

        if(processors.size() > 0) return processors[0];
        return null;
    } 

    /**
    * @description selectSettings -  
    * @return quot__QI_Settings__c
    */ 
    private quot__QI_Settings__c selectSettings() {
        return quot__QI_Settings__c.getInstance();
    }

    /**
    * @description selectWebSiteSettings - 
    * @param String name - 
    * @return pymt__Sites_Website_Settings__c
    */ 
    private pymt__Sites_Website_Settings__c selectWebSiteSettings(String name) {
        return pymt__Sites_Website_Settings__c.getInstance(name);
    }


}