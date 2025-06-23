/**
* @author Conga, RKrause
* @author Conga Services, ERedding
* @date Created on 20171116. Modified 20172101
* @description ChattoPhoneCaseController - Extension for the ChattoPhoneCasePage visualforce page.
*/
public class ChattoPhoneCaseController{
    public Case DummyCase {get;set;} // DUMMY CASE FOR GETTING A STATUS VALUE FROM THE USER
    public Case InitialCase {get;set;}
    public Case NewCase {get;set;}

    /**
    * @description ChattoPhoneCaseController - Contructor
    * @param ApexPages.StandardController
    */
    public ChattoPhoneCaseController(ApexPages.StandardController ctrl){
        if(ctrl != null && ctrl.getRecord() != null){
            GetCaseInfo(ctrl.getId());
        }
    }

    /**
    * @description GetCaseInfo - Retrives required data from the Initial Case
    * @param Id pCaseId
    * @param PageReference
    */
    public PageReference GetCaseInfo(Id pCaseId){
        this.DummyCase = new Case();
        List<Case> initialCase = [SELECT Id, IsClosed, OwnerId, Status FROM Case WHERE Id = :pCaseId];
        if(initialCase.size() == 1){
            this.InitialCase = initialCase[0];
            if(this.InitialCase.IsClosed){
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'This cannot be done on a closed case.'));
            }
        }

        return null;
    }

    /**
    * @description CreateChatToPhoneCase - Clones the intial case creating a Chat to Phone case who becomes the parent of the initial case
    * @return PageReference
    */
    public PageReference CreateChatToPhoneCase(){
        if(this.InitialCase != null && !this.InitialCase.IsClosed){
            // CLONE CASE, SET FIELDS
            Map<Id,sObject> clonedCases = UtilityClass.cloneObjectsMap(new List<Case>{ InitialCase }, InitialCase.getsObjectType());
            for(Id initialCaseId : clonedCases.keySet()){
                this.NewCase = (Case)clonedCases.get(initialCaseId);
                this.NewCase.Origin = 'Chat to Phone';
                this.NewCase.Subject = 'Chat to Phone - ' + this.NewCase.Subject; 
                this.NewCase.OwnerId = '00G50000001BcN5';
                this.NewCase.Status = this.DummyCase.Status;
                break;
            }
            
            // INSERT NEW CASE
            if(this.NewCase != null){
                insert this.NewCase;
            }

            // REFRESH CASE
            List<Case> newCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :this.NewCase.Id LIMIT 1];
            if(newCase.size() == 1){
                this.NewCase = newCase[0];
            }

            // UPDATE INITIAL CASE TO BE A CHILD OF THE NEW CASE
            this.InitialCase.ParentId = this.NewCase.Id;
            update this.InitialCase;
        }

        return null;
    }


}