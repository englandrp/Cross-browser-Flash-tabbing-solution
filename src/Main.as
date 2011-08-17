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

package {
	
	import fl.controls.Button;
	import flash.accessibility.*;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import com.richardengland.utils.Tabbing;

	
	public class Main extends MovieClip
	{
		/** Object that deals with tabbing functionality (on the Flash side - also requires tabbing.js and correct set up in html) **/
		public var tabbing:Tabbing;
		private var _btns:Array;
		/** Main constructor **/
		public function Main()
		{	
			
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
		}
		
		private function init(e:Event = null):void 
		{
			/** 
			 * call this to reset the overall tabbing list for the flash player object
			 * ...that's it! The rest is handled by the tabbing object. Easy! See the HTML for the rest of the setup
			 **/
			tabbing = new Tabbing(this);
			//tabbing.refreshTabbingList(); //this is now called by the playerReady function due to ExternalInterface event order
			
			//...and this is just setting up the example elements and event handlers
			popup.visible = false;
			popupDemoBtn.addEventListener( MouseEvent.CLICK, showPopup );
			popup.closeBtn.addEventListener( MouseEvent.CLICK, hidePopup );
			
			_btns = [btn1, btn2, btn3, btn4, popup.btn5, popup.btn6, popup.btn7, popupDemoBtn, popup.closeBtn, popup.textExample];
			
			for each(var btn:Object in _btns) {
				btn.addEventListener( MouseEvent.CLICK, clickButton);
				btn.addEventListener( FocusEvent.FOCUS_IN, receiveFocus);
			}
		}
		
		/** handle generic button presses **/
		private function clickButton( ev:MouseEvent ):void
		{
			output.text = ev.target.name + " was clicked!";
		}
		
		/** handle focus events **/
		private function receiveFocus( ev:FocusEvent ):void
		{
			output.text = ev.target.name + " received focus...";
		}
		
		/** show the popup **/
		private function showPopup( ev:MouseEvent ):void
		{
			popup.visible = true; 
			tabbing.createNewTabsFor(popup); //passes only the elements in the displayobject as tabbing items
		}
		
		/** hide the popup **/
		private function hidePopup( ev:MouseEvent ):void
		{
			popup.visible = false; 
			tabbing.createNewTabsFor(this);
		}
	
		
		
	}
}