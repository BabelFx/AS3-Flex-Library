package com.asfusion.mate.l10n.commands
{
	import com.asfusion.mate.l10n.events.LocaleEvent;
	
	import flash.net.*;
	import flash.system.Capabilities;
	
	import mx.managers.*;
	import mx.resources.IResourceBundle;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	public class LocaleCommand implements ILocaleCommand
	{	
		public function execute( event:LocaleEvent ):void {
			
			if (event is LocaleEvent) {
				switch(LocaleEvent(event).action) {
					case LocaleEvent.INITIALIZE  : initStartupLocale();						break;
					case LocaleEvent.LOAD_LOCALE : loadLocale(LocaleEvent(event).locale);		break;
				}
			}
		}
		
		// ************************************************************************
		// Protected Methods
		// ************************************************************************

		/**
		 * Loads the startup locale based on current OS Locale preferences; 
		 * unless overriden by FlashVars "localeChain" 
		 * 
		 */
		protected function initStartupLocale():void {
			// Nothing specified from the server/html wrapper, so look at OS Locale
			loadLocale(defaultLocale);
		}
		
		/**
		 * Switch to another embedded locale as specified. 
		 */
		protected function loadLocale(locale:String):void {
			// Always default back to the preferred OS locale setting...
			_localeMngr.localeChain = [locale,defaultLocale];
		}
		
		/**
		 * Determine the current OS setting for the preferred or default language locale
		 * @return String with the localization setting expected by ResourceManager 
		 */
		static private function get defaultLocale():String {
			var locale : String = "";
			
				switch(String(Capabilities.language)) {
					case "es":			locale = "es_ES";	break;
					case "fr":			locale = "fr_FR";	break;
					case "ja":			locale = "ja_JP";	break;
					case "ch":			locale = "ch_ZN";	break;
					case "en":			
					default  :          locale = "en_US";	break;
				}
				
			return locale;
		}
		
		
		private var _localeMngr	:IResourceManager = ResourceManager.getInstance();
	}
}