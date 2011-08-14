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

package com.richardengland.utils {

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.display.*;
	import flash.text.TextField;
	import flash.system.Security;
	import flash.system.Capabilities;
	import flash.utils.setTimeout;
	import flash.accessibility.*;
	
	public class Tabbing extends EventDispatcher {

		/** Tabbing vars **/
		private var _tabbingList:Array = [];
		private var _oTabbingList:Array = [];
		private var _forceTabReset:Boolean = false;
		private var _currentY:Number = 0;
		private var _flashObjID:String = "";
		private var _client:String = "";
		private var _config:Object = {};
		
		/** Monitoring when Flash object is ready for ExternalInterface calls **/
		private var ready:Boolean;
		
		/** Reference to a display object to get flashvars from. **/
		private var reference:DisplayObjectContainer;
		
		public function Tabbing(ref:DisplayObjectContainer):void {
			reference = ref;
			playerReady(); //sets up ExternalInterface to JS commands
			
			Security.allowDomain("*");
			_client = 'FLASH ' + Capabilities.version;
			
			//create a "blank" sprite to catch the focus leaving flash items and clear the focus selection
			var blank:Sprite = new Sprite();
			reference.addChild(blank);
			blank.name = "blank";
			blank.x = -500;
			//give accessibility 
			
			//create a "steal" sprite to catch the first actual focus in flash in IE and make sure it moves straight back to browser in this instance
			var steal:Sprite = new Sprite();
			reference.addChild(steal);
			steal.name = "steal";
			steal.x = -500;
			steal.y = -500;
			steal.mouseEnabled = true;
			steal.buttonMode = true;
			steal.tabIndex = 1;
			steal.addEventListener( FocusEvent.FOCUS_IN, moveFocusToBrowser);
			
			
		};
		
		/** Move focus back to browser (to fix IE stealing focus) **/
		public function moveFocusToBrowser( ev:FocusEvent):void {
			
			//trace("Steal the focus");
			ExternalInterface.call("stealFocus", true);
			
		}
		
		/** Send a ready ping to javascript. **/
		public function playerReady() {
			if(ExternalInterface.available && ready != true) {
				ready = true;
				setTimeout(playerReadyPing,50);
			}
		};
		
		
		/** The timeout on this ping is needed for IE - it'll not get the playerReady call. **/
		private function playerReadyPing() {
			try {
				if(ExternalInterface.objectID && !_flashObjID) {
					_flashObjID = ExternalInterface.objectID;
				}
				if (_flashObjID) {
					ExternalInterface.addCallback("sendEvent", sendEvent);
					ExternalInterface.addCallback("sendTabAction", sendTabAction);
					ExternalInterface.addCallback("sendTextUpdate", sendTextUpdate);
					ExternalInterface.addCallback("setFocusTo", setFocusTo);
					ExternalInterface.call("playerReady",{
						id:_flashObjID,
						client:_client
					});
					
					refreshTabbingList();
				}
				
				if (ExternalInterface.available && !_flashObjID) {
					ExternalInterface.addCallback("sendEvent", sendEvent);
					ExternalInterface.addCallback("sendTabAction", sendTabAction);
					ExternalInterface.addCallback("sendTextUpdate", sendTextUpdate);
					ExternalInterface.addCallback("setFocusTo", setFocusTo);
					ExternalInterface.call("playerReady",{
						id:"flashplayer",
						client:_client
					});
					
					refreshTabbingList();
				}
			} catch (err:Error) {
				trace(" !!!!!!!!!!!!!!!! NO ExternalInterface ?????????????????????????? ");
			}
		}
		
		/**  Dispatch events. **/
		public function sendEvent(typ:String, prm:Object = undefined):void {
			
			refreshTabbingList(); //update tabbing list on event
			
		}
		
		/** set the focus to an object **/
		public function setFocusTo( typ:String,prm:Object=undefined ):void
		{
				
			findFocusObject( typ, reference );

		}
		
		/** find an object that's focussed in the html form **/
		public function findFocusObject(findName:String, container:DisplayObjectContainer , indentString:String = ""):void
		{
			var child:Object;
			//casting the instance down to Object (rather than DisplayObject), which is dynamic and won't throw the error no matter what we access
			for (var i:uint=0; i < container.numChildren; i++)
			{
				try{
					child = container.getChildAt(i);
				} catch (err:Error) {
				}

				if (child is InteractiveObject && child.visible && child.mouseEnabled && child.alpha > 0 ) {
					
					var c:InteractiveObject = child as InteractiveObject;
					
					
				}
				
				//try {
					var t:TextField	
					if(child.name == findName){
						child.stage.focus = child;
						if (child is TextField) {
							//give it a border (simulate the focus effect you get for buttons in Flash)
							t = child as TextField;
							t.border = true;
							t.borderColor = 0xFF5500;
							
						}
						//break;
					} else {
						if (child is TextField) {
							
							//remove any border (if any)
							t = child as TextField;
							if(child.borderColor == 0xFF5500){
								t.border = false;
								t.borderColor = 0x000000;
							}
							
						}
					}
				//}catch (err:Error) {
				//	trace(err);
				//};
			
				//check for nested items
				if (child is DisplayObjectContainer && child.visible &&  child.alpha > 0) 
				{
					//contains DisplayObject children - call this function again (with child reference!)
					findFocusObject(findName, DisplayObjectContainer(child), indentString + "    ")
				}
			}
		}
		
		/** find an object by name and simulate a mouse click **/
		public function findClickObject(findName:String, container:DisplayObjectContainer , indentString:String = ""):void
		{
			var child:Object;
			//casting the instance down to Object (rather than DisplayObject), which is dynamic and won't throw the error no matter what we access
			for (var i:uint=0; i < container.numChildren; i++)
			{
				//catch an error / security sandbox (cross domain?) issue caused when the stopBtn is pressed for example
				try{
					child = container.getChildAt(i);
					//trace(indentString, child, child.name);
				} catch (err:Error) {
					trace(" -- Error getting container.getChildAt(i) with child ", i);
				}
				
				if (child is InteractiveObject && child.visible && child.mouseEnabled && child.alpha > 0 ) {
					
					var c:InteractiveObject = child as InteractiveObject;
					try{
						if (child.name == findName) {
						//	
							trace("Trying to simulate a mouse click for", findName);
							child.dispatchEvent(new MouseEvent(MouseEvent.CLICK, true, false));
							trace("Simulated a mouse click for", findName);
							//child.stage.focus = child;
							break;
						}
					}catch (err:Error) {
						trace(" -- Error finding child.name of ", findName);
					};
					
				}
				
				//check for nested items
				if (child is DisplayObjectContainer && child.visible &&  child.alpha > 0) 
				{
					//contains DisplayObject children - call this function again (with child reference!)
					findClickObject(findName, DisplayObjectContainer(child), indentString + "    ")
				}
			}
		}
		
		//find a text input by name and update text value
		public function findTextObject(findName:String, container:DisplayObjectContainer , textString:String = ""):void
		{
			var child:Object;
			//casting the instance down to Object (rather than DisplayObject), which is dynamic and won't throw the error no matter what we access
			for (var i:uint=0; i < container.numChildren; i++)
			{
				//catch an error / security sandbox (cross domain?) issue caused when the stopBtn is pressed for example
				try{
					child = container.getChildAt(i);
					//trace(textString, child, child.name);
				} catch (err:Error) {
					//trace(" -- Error getting container.getChildAt(i) with child ", i);
				}
				//var t:TextField
				if (child is TextField) {
					
					var c:TextField = child as TextField;
					try{
						if (child.name == findName) {
						
							child.text = textString;
							//trace("Simulated a mouse click for", findName);
							//child.stage.focus = child;
							break;
						}
					}catch (err:Error) {
						//trace(" -- Error finding child.name of ", findName);
					};
					
				}
				
				//check for nested items
				if (child is DisplayObjectContainer && child.visible &&  child.alpha > 0) 
				{
					//contains DisplayObject children - call this function again (with child reference!)
					findTextObject(findName, DisplayObjectContainer(child), textString)
				}
			}
		}
		
		
		
		/**  Dispatch new text to input object. **/
		public function sendTextUpdate(typ:String, prm:Object = undefined):void {
			
			//find the object first...
			findTextObject( typ,  reference, prm.txt);

		}
		
		/**  simulate a mouse click on the selected tab object **/
		public function sendTabAction(typ:String, prm:Object = undefined):void {
			
			// simulate a mouse click 
			findClickObject( typ,  reference );

		}	
	
		/**  create tab objects for a passed display object **/
		public function createNewTabsFor( tabsForObject:DisplayObjectContainer ):void
		{	
			_oTabbingList = _tabbingList;
			_tabbingList = [];
			loopInteractiveObjects ( tabsForObject );
		
			//remove duplicates in array
			function fRemoveDup(ac:Array) : void
			{
				var i, j : int;
				for (i = 0; i < ac.length - 1; i++)
					for (j = i + 1; j < ac.length; j++)
						if (ac[i] === ac[j])
							ac.splice(j, 1);
			}
			fRemoveDup(_tabbingList);
			
			_tabbingList.sortOn("tabIndex", Array.NUMERIC); // (order);

			
			//only do following if array has changed

			//send _tabbingList array back to javascript
			if (ExternalInterface.available) {
				ExternalInterface.call("newTabbingList", _tabbingList);
			}
			
			_forceTabReset = false; //reset to avoid further changes
			
		}
		
		/**  create tab objects from the root of the player **/
		public function refreshTabbingList(ev:MouseEvent = null):void
		{
			_oTabbingList = _tabbingList;
			_tabbingList = [];
			loopInteractiveObjects ( reference );
			
			//remove duplicates in array
			function fRemoveDup(ac:Array) : void
			{
				var i, j : int;
				for (i = 0; i < ac.length - 1; i++)
					for (j = i + 1; j < ac.length; j++)
						if (ac[i] === ac[j])
							ac.splice(j, 1);
			}
			fRemoveDup(_tabbingList);
			
			_tabbingList.sortOn("tabIndex", Array.NUMERIC); // (order);

			//only do following if array has changed
			if (_oTabbingList.length != _tabbingList.length || _forceTabReset ) {
			//send _tabbingList array back to javascript
				if (ExternalInterface.available) {
					ExternalInterface.call("newTabbingList", _tabbingList);
				}
				
				_forceTabReset = false; //reset to avoid further changes
			}

		}
		
		

		public function loopInteractiveObjects(container:DisplayObjectContainer, indentString:String = "", theY:Number = 0 ):void
		{
			var child:Object;
			
			//casting the instance down to Object (rather than DisplayObject), which is dynamic and won't throw the error no matter what we access
			for (var i:uint=0; i < container.numChildren; i++)
			{
				try {
					child = container.getChildAt(i);
				} catch (err:Error) { }
				
				if (child is InteractiveObject && child.visible && child.mouseEnabled && child.alpha > 0 ) {
					
					var c:InteractiveObject = child as InteractiveObject;
					
					try {
						var tabbingObject:Object = new Object();
						tabbingObject.name = child.name ;
						tabbingObject.accessibilityName = c.accessibilityProperties.name ;
						tabbingObject.accessibilityDesc = c.accessibilityProperties.description ;
						tabbingObject.isText = (child is TextField) ;
						tabbingObject.tabIndex = c.tabIndex;
						//gets the height of the object on stage
						_currentY = theY + child.y;
						tabbingObject.theY = _currentY;
						//trace(_currentY);
						//trace(indentString + "Tabbing item: ", child.name );
						//trace (indentString + "Tabbing item: ", child, child.name, c.accessibilityProperties.name, c.accessibilityProperties.description  );
						if( tabbingObject.accessibilityName && tabbingObject.accessibilityName != ""){
							_tabbingList.push( tabbingObject );
							
						}
						//trace (indentString + c.accessibilityProperties.description );
					} catch (err:Error) {
						//trace (indentString + child + "- Item is not accessible");
					}
				}
				
				//check for nested items
				if (child is DisplayObjectContainer && child.visible &&  child.alpha > 0) 
				{
					_currentY = theY+child.y;
					//contains DisplayObject children - call this function again (with child reference!)
					loopInteractiveObjects(DisplayObjectContainer(child), indentString + "    ", _currentY);
				}
				
				
			}
			
			_currentY = 0;
		}
		
		}



}