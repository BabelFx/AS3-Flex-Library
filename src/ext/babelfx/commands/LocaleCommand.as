////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.commands
{
	import ext.babelfx.events.BabelFxEvent;
	
	import flash.net.*;
	import flash.system.Capabilities;
	
	import mx.logging.ILogger;
	import mx.managers.*;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	import org.swizframework.storage.ISharedObjectBean;
	import org.swizframework.utils.logging.SwizLogger;
	
	
	public class LocaleCommand implements ILocaleCommand {	
		
		
		[Bindable]
		/**
		 *  Logger to be used for debugging purposes
		 */
		public var logger : SwizLogger;
		
		[Bindable]
		/**
		 *  Persistence mechanism to store user's last selected
		 *  locale preference. Used at subsequent startups to auto-restore
		 *  last locale.
		 */
		public var lso : ISharedObjectBean;
		

		[Bindable]
		/**
		 *  LSO id used to persist user locale preference. 
		 */
		public var lsoKey : String = "userPreferredLocale";
		
		
		[Bindable]
		/**
		 * Should the user's preferred locale be used 
		 * as the override during loadDefaultLocale() ?  
		 */
		public var enableUserPreference : Boolean = true;
		
		
		/**
		 * Accessors for user preferred locale 
		 */
		public function get userPreferredLocale():String 
		{
			return (lso && enableUserPreference) ? lso.getString( LSO_PREFIX + lsoKey ) : null;
		}
		public function set userPreferredLocale(val:String):void {
			if ( !val || val == "") return;
			
			if ( (val != userPreferredLocale)  && lso )
			{
				logger.debug( "LocaleCommand::set userPreferredLocale( `{0}` )", val );
				
				lso.setString( LSO_PREFIX + lsoKey, val );
			}
		}
		
		public function execute( event:BabelFxEvent ):void 
		{
			switch(event.type) 
			{
				case BabelFxEvent.LOAD_DEFAULT  	: loadDefaultLocale();						break;
				case BabelFxEvent.LOAD_LOCALE		: loadLocale(BabelFxEvent(event).locale);	break;
			}
		}
		
		// ************************************************************************
		// Protected Methods
		// ************************************************************************

		/**
		 * Loads the startup locale based upon:
		 * 
		 *   1) user's last, preferred locale (if available), or
		 *   2) on current OS Locale preferences; 
		 * 
		 */
		protected function loadDefaultLocale():void {
			
			var locale : String = userPreferredLocale || defaultLocaleFromOS;
			
			logger.debug( "LocaleCommand::loadDefaultLocale( `{0}` )", locale );
			
			loadLocale( locale, false);
		}
		
		/**
		 * Switch to another embedded locale as specified. 
		 */
		protected function loadLocale(locale:String, updateUserPreference:Boolean = true):void 
		{
			var chain 	: Array = _localeMngr.localeChain;
			var current : String= (chain && chain.length) ? chain[0] as String : defaultLocaleFromOS;
			
			if ( current != locale )
			{
				// Always default back to the preferred OS locale setting...
				//
				// Note: ResourceManager searches bundles for locales from first (0-index) to last
				//       the last locale is the "fallback" bundle. As such, en_US should always be the last.
				
				logger.debug( "LocaleCommand::loadLocale( [ {0} ] )", [locale,current].toString() );
				
				// Adjust localeChain... always have en_US as fallback.
				
				chain = [locale, current];
				if ( chain.indexOf( "en_US" ) < 0) 	chain.push( "en_US" ); 
				
				_localeMngr.localeChain = chain;
				
			}
			
			// Should we persist the locale as the user's last, preferred locale ?
			
			if ( updateUserPreference ) userPreferredLocale = locale;
		}
		
		/**
		 * Determine the current operating system (OS) setting for the preferred or default language locale
		 * @return String with the localization setting expected by ResourceManager 
		 */
		static protected function get defaultLocaleFromOS():String {
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
		
		protected static const LSO_PREFIX : String = "BabelFx_";
	}
}