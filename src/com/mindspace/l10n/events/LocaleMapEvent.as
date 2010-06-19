package com.mindspace.l10n.events
{
	import flash.events.Event;

	/**
	 * These event define actions and announcements within
	 * the l10nInjection engine.
	 *  
	 * @author thomasburleson
	 * 
	 */
	public class LocaleMapEvent extends Event
	{	
		public static const INITIALIZED     :String = "initialized";
		public static const TARGET_READY  	:String = "targetReady";
		public static const LOCALE_CHANGING	:String = "localeChanging";
		
		/**
		 * Event to register non-UI instances with LocaleMap... 
		 */
		public static const REGISTER_TARGET :String = "registerTarget";

		public var targetInst : Object = null;
		
		public function LocaleMapEvent(eventID:String="targetReady",targetInst:Object=null) {
			super(eventID,false,false);
			this.targetInst = targetInst; 
		}
		
	}
}