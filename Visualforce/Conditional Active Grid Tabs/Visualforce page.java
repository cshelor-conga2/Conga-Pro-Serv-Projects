<apex:page sidebar="false" showHeader="true" docType="html-4.01-strict">
    <apex:outputPanel rendered="{!($User.Title == 'CEO')}" >
        <c:CEO_Active_Grid_Tabs/>
    </apex:outputPanel>
    <apex:outputPanel rendered="{!($User.Title != 'CEO')}" >
        <c:Non_CEO_Active_Grid_Tabs/>
    </apex:outputPanel>
</apex:page>