////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.events
{
	import flash.events.Event;
	
	import mx.resources.IResourceManager;
	
	import org.swizframework.utils.async.AsynchronousEvent;

	/**
	 * These event define actions and announcements within
	 * the l10nInjection engine.
	 *  
	 * @author thomasburleson
	 * 
	 */
	public class BabelFxEvent extends AsynchronousEvent
	{	
		// Command events
		
		public static const LOAD_DEFAULT   	:String = "loadUserPreferredLocale";
		public static const LOAD_LOCALE     :String = "loadLocale"; 
		
		// Notification events
		
		public static const INITIALIZED     :String = "initialized";
		public static const LOCALE_CHANGING	:String = "localeChanging";
		public static const LOCALE_CHANGED  :String = "localeChanged";
		
		public static const STATE_CHANGED   :String = "stateChanged";
		public static const TARGET_READY    :String = "creationComplete";
		public static const PARAMS_CHANGED  :String = "parametersChanged"
		
		// Public Properties
			
		public var locale 			: String = "";
		public var resourceManager 	: IResourceManager;
		
		// Constructor 
		
		public function BabelFxEvent(type:String, locale:String="en_US", resourceManager:IResourceManager=null) 
		{
			type ||= LOCALE_CHANGED;
			
			super(type,false,false);
			
			this.locale 		 = locale;
			this.resourceManager = resourceManager;
		}
		
	}
}