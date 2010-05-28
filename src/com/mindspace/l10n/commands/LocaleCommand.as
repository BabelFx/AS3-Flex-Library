package com.mindspace.l10n.commands
{
	import com.mindspace.l10n.events.LocaleEvent;
	
	import flash.net.*;
	import flash.system.Capabilities;
	
	import mx.logging.ILogger;
	import mx.managers.*;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	public class LocaleCommand implements ILocaleCommand
	{	
		
		public var log : ILogger = null;
		
		public function execute( event:LocaleEvent ):void {
			
			if (event is LocaleEvent) {
				switch(LocaleEvent(event).action) {
					case LocaleEvent.INITIALIZE  : initStartupLocale();							break;
					case LocaleEvent.LOAD_LOCALE : loadLocale(LocaleEvent(event).locale);		break;
				}
			}
		}
		
		// ************************************************************************
		// Protected Methods
		// ************************************************************************

		/**
		 * Loads the startup locale based on current OS Locale preferences; 
		 * 
		 */
		protected function initStartupLocale():void {
			log.debug("initStartupLocale()");
			loadLocale(defaultLocale);
		}
		
		/**
		 * Switch to another embedded locale as specified. 
		 */
		protected function loadLocale(locale:String):void {
			// Always default back to the preferred OS locale setting...
			var localeChain : Array = locale != defaultLocale ? [locale,defaultLocale] : [locale];
			
			log.debug("loadLocale({0}) - embedded.",localeChain);
			_localeMngr.localeChain = localeChain;
			
			
		}
		
		/**
		 * Determine the current OS setting for the preferred or default language locale
		 * @return String with the localization setting expected by ResourceManager 
		 */
		static protected function get defaultLocale():String {
			var locale : String = "";
			
				switch(String(Capabilities.language)) {
					case "da":			locale = "da_DK";	break;		// Danish
					case "de":			locale = "de_DE";	break;		// German
					case "es":			locale = "es_ES";	break;		// Spanish
					case "fr":			locale = "fr_FR";	break;		// French
					case "fi":			locale = "fi_FL";	break;		// Finnish
					case "it":			locale = "it_IT";	break;		// Italian
					case "ja":			locale = "ja_JP";	break;		// Japanese
					case "ko":			locale = "ko_KR";	break;		// Korean
					case "nl":			locale = "nl_NL";	break;		// Dutch
					case "no":			locale = "nb_NO";	break;		// Norwegian
					case "pt":			locale = "pt_BR";	break;		// Portuguese
					case "ru":			locale = "ru_RU";	break;		// Russian
					case "sv":			locale = "sv_SE";	break;		// Swedish
					
					case "zh_CN":		locale = "zh_CN";	break;		// Simplified Chinese
					case "zh_TW":		locale = "zh_tw";	break;		// Traditional Chinese

					case "en":			
					default  :          locale = "en_US";	break;
				}
				
			return locale;
		}
		
		
		protected var _localeMngr	:IResourceManager = ResourceManager.getInstance();
	}
}