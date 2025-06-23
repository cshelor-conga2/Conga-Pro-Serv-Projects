trigger Collaborate_Proposal_Create_API on Opportunity (after update) {
    for (Opportunity updatedOpportunity : Trigger.new) {
        if (updatedOpportunity.NextStep == 'Test') {
        Collaborate_Proposal_Create_API.makePostCallout();
        }
    }
}