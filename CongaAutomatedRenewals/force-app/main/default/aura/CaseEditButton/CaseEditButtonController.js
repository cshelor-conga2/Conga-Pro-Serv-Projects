({
    openModal : function(component, event, helper) {
        document.getElementById("modaldialog").style.display = "block";
        document.getElementById("dialogbackdrop").style.display = "block";
    },
    closeModal : function(component,event, helper){
	       	document.getElementById("modaldialog").style.display = "none";
	       	document.getElementById("dialogbackdrop").style.display = "none";
   	}
})