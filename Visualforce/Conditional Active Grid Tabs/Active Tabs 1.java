<apex:component >
<div id="tabstrip" style="display:none;">
    <ul> 
		<li class="k-state-active">Contract Agreements</li>
        <li>Fuel Quotes</li>
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
</apex:component>