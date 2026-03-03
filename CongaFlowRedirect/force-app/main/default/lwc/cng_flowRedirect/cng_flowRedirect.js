import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class FlowSmartRedirect extends NavigationMixin(LightningElement) {

    @api recordId;
    @api redirectUrl;
    @api message;
    @api showSpinner;

    hasRendered = false;

    get shouldShowSpinner() {
        return this.showSpinner !== false;
    }

    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;

        // Let user see the message
        setTimeout(() => {
            this.closeFlowThenRedirect();
        }, 2000);
    }

    closeFlowThenRedirect() {
        // Close the Flow modal first
        this.dispatchEvent(new FlowNavigationFinishEvent());

        // Then redirect parent window
        setTimeout(() => {
            this.performRedirect();
        }, 400);
    }

    performRedirect() {

        if (this.recordId) {
            window.location.href = `/lightning/r/${this.recordId}/view`;
            return;
        }

        if (this.redirectUrl) {
            window.location.href = this.redirectUrl;
            return;
        }

        console.error('No redirect target provided.');
    }
}