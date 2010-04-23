package com.asfusion.mate.l10n.events
{
	import flash.events.Event;

	public class LocaleMapEvent extends Event
	{	
		public static const TARGET_READY  	:String = "targetReady";
		public static const LOCALE_CHANGING	:String = "localeChanging";

		public var targetInst : Object = null;
		
		public function LocaleMapEvent(eventID:String="targetReady",targetInst:Object=null) {
			super(eventID,false,false);
			this.targetInst = targetInst; 
		}
		
	}
}