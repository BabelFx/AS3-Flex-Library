package org.babelfx.events
{
	import flash.events.Event;
	
	/**
	 * This events define actions for Locales and ResourceBundles
	 * 
	 * @author thomasburleson
	 * 
	 */
	public class LocaleEvent extends Event
	{	
		public static const INITIALIZE   :String = "initializeLocaleDefaults";
		public static const LOAD_LOCALE  :String = "loadLocaleResources";
		
		public static const EVENT_ID     :String = "loadLocale";
		
		public var action : String = INITIALIZE;
		public var locale : String = "";
		
		public function LocaleEvent(action:String="", locale:String="en_US") {
			super(EVENT_ID, true, false);
			
			this.action = (action == "") ? INITIALIZE : action;
			this.locale = locale;
		}
		
		
	}
}