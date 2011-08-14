/**
* Cross browser tabbing solution/engine for Flash projects
* 
* Released under MIT license:
* http://www.opensource.org/licenses/mit-license.php
* 
* @author Richard England 2011
* @see http://www.richardengland.co.uk
* @version 0.1
*/


var lastAction = ""; //store last "click" selection (useful for toggle states for example - e.g. play/pause - remembers focus)
var index = 0;
var flashObj; // the flash player object
var firstInput; // the first input object

function playerReady( obj ){
	
	flashObj = obj;
	//get the flash object's "top" CSS value
	var topV = $("#flashplayer").offset().top;
	//add a form to the document and places it at same top offset as flash player object
	$("body").prepend('<form name="form1" id="form1" style="position:absolute; top:'+topV+'px; left:-1500px;"></form>');

}

doOnce = false;
function stealFocus( obj ){
	
	if(!doOnce){
		//alert("steal the focus");
		doOnce = true;
	}
	
	

}

function addFormField( name, accessName, accessDesc, tabIndex, theTop) {


	var id = document.getElementById("id").value;
	var accesskey = "";
	if(accessDesc == "") accessDesc = accessName;
	if(index == 0) accesskey = " accesskey='q' "; //for first item only - keyboard shortcut
	var field = $("#form1").append("<div class='temp' id='row" + id + "'><label for='txt" + id + "'>" + accessDesc + " <input tabindex='"+tabIndex+"' type='button' size='20' name='" + name + "' id='"+ name + "' value='"+accessName+"' alt='"+accessName+"' title='"+accessName+"' onfocus='sendFocus( this ); ' onclick='doAction( this );' " + accesskey + "></label></div>");
	
	//set the position so scroll will work properly with tabbing
	$("#row" + id).css( 
              { 
			  "position"	: "absolute",
              "top"			: theTop + "px" ,
              "display"		:"block" 
              }
	)
	id = (id - 1) + 2;

	document.getElementById("id").value = id;
	
}

function addTextField( name, accessName, accessDesc, tabIndex, theTop ) {

	//alert( name );
	var id = document.getElementById("id").value;
	if(accessDesc == "") accessDesc = accessName;
	$("#form1").append("<div class='temp' id='row" + id + "' style='position:absolute; top:" + theTop + "px; left:0px;'><label for='txt" + id + "'>" + accessDesc + " <input tabindex='"+tabIndex+"' type='text' size='20' name='" + name + "' id='"+ name + "' value='' alt='"+accessName+"' title='"+accessName+"' onfocus='sendFocus( this ); ' onclick='doAction( this );' onkeyup='doTextUpdate(this)' style='position:absolute;' ></div>");

	id = (id - 1) + 2;

	document.getElementById("id").value = id;
	
}

function removeAllFormFields() {
	$(".temp").remove();
	
	document.getElementById('form1').innerHTML = '<input type="hidden" id="id" value="1">';
}

function removeFormField(id) {

	$(id).remove();

}


function sendToActionScript(value) {
 thisMovie("ExternalInterfaceExample").sendToActionScript(value);
}

function sendToJavaScript(value) {
 //document.forms["form2"].text1.value += "ActionScript says: " + value + "\n";
}
 
 


//receives a new tabbing list object/array from Flash and generates the form by looping through the list
function newTabbingList( obj ){

	removeAllFormFields();
	
	var i = 0;
	var highestTabIndex = 0;
	var isLastActionStillAvailable = false;

	var lowestTabIndex = 10000;
	while(i < obj.length ) {
		if(obj[i].tabIndex < lowestTabIndex) {
			firstInput = obj[i].name;
			lowestTabIndex = obj[i].tabIndex;
		}
		if(lastAction == obj[i].name)  isLastActionStillAvailable = true;
		if(obj[i].isText){
			addTextField(obj[i].name, obj[i].accessibilityName, obj[i].accessibilityDesc, obj[i].tabIndex, obj[i].theY);
		} else {
			addFormField(obj[i].name, obj[i].accessibilityName, obj[i].accessibilityDesc, obj[i].tabIndex, obj[i].theY);
		}
		if(obj[i].tabIndex > highestTabIndex) highestTabIndex = obj[i].tabIndex;
		i++
	}
	
	
	if(lastAction != "" && isLastActionStillAvailable){
		
		$("#" + lastAction).focus();
	} else {
		
		$("#" + firstInput).focus();
	}

	addFormField("blank", "blank",  "blank", highestTabIndex + 1, 0);
	
	
	index = i;
}

function doPlayFocus(){
	t = thisMovie("flashplayer");
	t.setFocusTo("playButton", false);
}

//sends text input back to text input in Flash object
function doTextUpdate( inputFocus ){
	
	id = inputFocus.id;
	t = thisMovie("flashplayer");
	t.sendTextUpdate (id , {txt: inputFocus.value});
	lastAction = id;
	
	//alert("doTextUpdate " + inputFocus.value);
}


function doAction( inputFocus ){
	
	id = inputFocus.id;
	t = thisMovie("flashplayer");
	t.sendTabAction (id , false);
	lastAction = id;
	
	//alert("doAction " + inputFocus.id);
	//$("#" + lastAction).focus();
}

function thisMovie(movieName) {
	 if (navigator.appName.indexOf("Microsoft") != -1) {
		 return window[movieName];
	 } else {
		 return document.getElementById(movieName);
	 }
 }
 
function sendFocus( inputFocus ) {
	
	id = inputFocus.id;
	t = thisMovie("flashplayer");
	if(id == "blank") {
		//fix for IE focus
		$("#" + firstInput).focus();
	} else {
		t.setFocusTo(id, false);
	}
	
	
}