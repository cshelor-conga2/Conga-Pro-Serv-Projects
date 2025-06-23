<apex:page sidebar="false" showHeader="true" docType="html-4.01-strict">
    <div id="tabstrip" style="display:none;">
        <ul> 
            <apex:outputText value="{! IF( $User.Title = 'CEO', '<li class=\"k-state-active\">Contract Agreement</li><li>Fuel Quotes</li>', '<li>Contract Agreement</li><li class=\"k-state-active\">Fuel Quote</li>') }" escape="false" />
		</ul>
    
<!-- Contract Agreements -->
<div style="overflow:hidden;"> 
<CRMC_PP:Grid ObjectName="APXT_Redlining__Contract_Agreement__c" DelayLoad="false"  ViewID="" 
 EnableNewButton="true"  EnableNewInline="true"  EnableEdit="true"  EnableActions="true"  EnableFieldChooser="true" 
 EnableStickyViews="true"  EnableToolbar="true"  EnableViews="true"  EnableFormatting="true"  EnableReadingPane="true" />
 <CRMC_PP:DrillUp /> 
 </div>

<!-- Fuel Quotes -->
<div style="overflow:hidden;"> 
<CRMC_PP:Grid ObjectName="Fuel_Quote__c" DelayLoad="true"  ViewID="" 
 EnableNewButton="true"  EnableNewInline="true"  EnableEdit="true"  EnableActions="true"  EnableFieldChooser="true" 
 EnableStickyViews="true"  EnableToolbar="true"  EnableViews="true"  EnableFormatting="true"  EnableReadingPane="true" />
 <CRMC_PP:DrillUp /> 
 </div>

</div>
<script>
$(document).ready(function() {
    $("#tabstrip").kendoTabStrip({
      activate: function(e){
        setTimeout(function(){          $(window).resize();        });
      }
    });
    $("#tabstrip").css("display", "block");
});
 </script>
</apex:page>