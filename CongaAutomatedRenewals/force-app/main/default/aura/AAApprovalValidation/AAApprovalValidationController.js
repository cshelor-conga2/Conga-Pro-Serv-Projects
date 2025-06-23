({
    //This is method of your Component controller
    quoteValidation : function(component, event, helper) {
        //get Opportunity Record Id
        var getQuoteId = component.get("v.recordId");
        
        helper.startQuoteCheck(component,event,getQuoteId,(result)=>{
            console.log('hello controller redirect');
            
            if(result){
            	helper.quoteStatusHelper(component,event,getQuoteId,(redirect)=>{
            
                    if(redirect){
                        helper.quoteRefreshHelper(component,event,getQuoteId);
                    }
                });
            }
        });
        },       
})