import { LightningElement, api, track } from 'lwc';
import getInvoiceSummaryCount from '@salesforce/apex/APTS_AgreementInvoiceWarningController.getInvoiceSummaryCount';  

export default class APTS_AgreementInvoiceValidation extends LightningElement {
    
    @api orderFormAgmtId;
    @api action;
    
    @track showMsg = false;
    @track spinnerOn = true;
    @track hasRendered = false;
    @track errorMsg;
    
    async connectedCallback()
    {
        console.log('Component connected');
        console.log('orderFormAgmtId ' + this.orderFormAgmtId);
        console.log('action ' + this.action);
        
        if (this.orderFormAgmtId) {
           await this.fetchInvoiceSummaries();
        }
    }

    renderedCallback() {
        if (this.hasRendered) return; // Prevent multiple executions
        this.hasRendered = true;

        console.log('This is renderedcallback ' + this.orderFormAgmtId);
        
        // if (this.orderFormAgmtId) {
        //    await this.fetchInvoiceSummaries();
        // }
    }

    async fetchInvoiceSummaries() {
        console.log('fetchInvoiceSummaries');
        this.spinnerOn = true;

        try {
            const result = await getInvoiceSummaryCount({ agreementId: this.orderFormAgmtId });
            console.log('Result: ', result);

            if (result == 0) {
                this.errorMsg = 'Missing Invoice Summary records. Please create a new Order Form Record from the quote.';
                this.showMsg = true;
            } else {
                console.log('inside else');

                if(this.action == 'Generate')
                {
                    console.log('before Generate');
                    const url = '/apex/Apttus__LightningSelectTemplate?id='+ this.orderFormAgmtId +'&action=Generate_Agreement&templateType=Agreement';
                    console.log('url ' + url);

                    window.location.href = url;
                }
                else
                {
                    console.log('before Regenerate');   
                    const url = '/apex/Apttus__LightningSelectTemplate?id='+ this.orderFormAgmtId +'&action=Regenerate_Agreement&templateType=Agreement';
                    console.log('url ' + url);

                    window.location.href = url;
                }
            }
        } catch (error) {
            console.error('Error:', error);
            this.errorMsg = 'Error fetching invoice summary';
            this.showMsg = true;
        } finally {
            this.spinnerOn = false;
        }
    }
    
    navigateToAgreement() {
        window.location.href = '/' + this.orderFormAgmtId;
    }
}