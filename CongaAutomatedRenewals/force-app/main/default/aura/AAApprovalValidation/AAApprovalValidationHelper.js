({
    startQuoteCheck: function(component,event,getQuoteId,callback) {
        //Call Your Apex Controller Method.
        var checkQuote = component.get("c.checkQuote");
        // set Opportunity RecordId to yourApexController method, parameter name should be exact match as that of apex method parameter name.   
        checkQuote.setParams({
            'objQuoteId': getQuoteId 
        });
        
        checkQuote.setCallback(this, function(response) {
            var checkQuoteState = response.getState();
            if (checkQuoteState === "SUCCESS") {
                var retVal = response.getReturnValue();
                var validQuote = retVal.includes("Valid");
                if(validQuote){
                    //Do Something
                    console.log('return value '+retVal);
                    callback(true);
                    
                }else{
                    console.log('return value '+retVal);
                    component.set("v.setMeOnInit","The Quote data is incomplete, please fix the items in red to proceed.");
                }
                
            } else {
                //Do Something
            }
        });
        $A.enqueueAction(checkQuote);
    },
    
    quoteRefreshHelper: function(component,event,getQuoteId,helper) {
        console.log('called quote refresh quoteRefreshHelper ');
        
        var self = this;
        var sendApprovalQuote = component.get("c.onSubmit");
        sendApprovalQuote.setParams({
            'objQuoteId': getQuoteId 
        });
        console.log('redirect 1');
        
        sendApprovalQuote.setCallback(this, function(response) {
            var sendApprovalQuoteState = response.getState();
            if (sendApprovalQuoteState === "SUCCESS") {
                setTimeout(function(){
                    console.log('redirect 2');
                    component.find("quoteRecord").reloadRecord(true);
                    self.stopProcessing(component);
                    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": getQuoteId
                    });
                    navEvt.fire();
                }, 5000);
            }
        });
        
        $A.enqueueAction(sendApprovalQuote);
    },
    
    quoteStatusHelper: function(component,event,getQuoteId,callback){
        var checkQuoteStatus = component.get("c.quoteApprovalStatus");
        var self = this;
        
        checkQuoteStatus.setParams({
            'objQuoteId': getQuoteId 
        });
        
        
        //component.set("v.setMeOnInit","Processing");
        
        checkQuoteStatus.setCallback(this, function(response) {
            var checkQuoteStatusState = response.getState();
            if (checkQuoteStatusState === "SUCCESS") {
                var retValStatus = response.getReturnValue();
                
                if(retValStatus == "Pending"){
                    component.set("v.setMeOnInit","Quote is already in pending for approval. Please close this dialog.");
                    
                }else{
                    console.log('hello pending ');
                    component.set("v.setMeOnInit","Quote is being submitted for approval.");
                    self.startProcessing(component);
                    component.set("v.redirectTrue", true);
                    var redirect = component.get("v.redirectTrue");
                    console.log('test  '+redirect);
                    callback(true);
                }
            }
            
        });
        $A.enqueueAction(checkQuoteStatus); 
    },
    startProcessing: function (component) {
        component.set("v.isProcessing", true);
    },
    stopProcessing: function (component) {
        component.set("v.isProcessing", false);
    }

})