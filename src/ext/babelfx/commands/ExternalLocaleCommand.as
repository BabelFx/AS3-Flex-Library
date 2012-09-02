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
	
	import flash.events.IEventDispatcher;
	import flash.net.*;
	
	import mx.events.ResourceEvent;
	import mx.managers.*;
	import mx.utils.StringUtil;
	
	import utils.string.supplant;
	
	
	public class ExternalLocaleCommand extends LocaleCommand
	{	
		/**
		 *  Template to be used to build full URL path for the 
		 *  external resource bundle (swf)
		 *  
		 *  @DefaultVal String "assets/locale/bundles/{0}.swf"   
		 */
		public var externalPath : String = "assets/locale/bundles/{0}.swf";
		
		override public function execute( event:BabelFxEvent ):void {
			
				switch(event.type) {
					case BabelFxEvent.LOAD_LOCALE  : 
					{
						loadLocale(BabelFxEvent(event).locale);		
						break;	
					}
					default                       : 
					{
						// Let the LocaleCommand process this request
						
						super.execute(event);	
					}
				}
		}
		
		// ************************************************************************
		// Protected Methods
		// ************************************************************************
		
		/**
		 * Load locale specified. If already loaded, then simply trigger ResourceManger "change" event so
		 * databindings fire to update with locale settings. If not loaded, then load from "locale/Resource_{locale}.swf" file 
		 *  
		 * @param locale String specifies request locale; e.g. en_US, en_NZ, es_MX, etc.
		 * 
		 *  ******************************************************************************************
		 *  !!Important: before the locale resourcebundles are assigned (after loading) we must FIRST load (1) and (2):
		 *  ******************************************************************************************
		 * 
		 *   1) StyleSheets for locale
		 *   2) Runtime fonts for StyleSheets
		 *   3) Localized ResourceBundles
		 *   4) Dynamic Runtime Text
		 * 
		 */
		override protected function loadLocale(locale:String, updateUserPreference:Boolean = true):void 
		{
			
			if ( !locale || (locale == "")) return;
			
				/**
				 * When load of external bundle completes
				 */
				function onResult_localeLoaded(event:ResourceEvent=null):void {
					
					logger.debug( "ExternalLocaleCommand::onResult_localeLoaded( `{0}` )", locale );
					
					_localeMngr.removeEventListener(ResourceEvent.COMPLETE,onResult_localeLoaded);
					
					if ( !event || (event.type == ResourceEvent.COMPLETE) )
					{
						super.loadLocale( locale, updateUserPreference );
					}
				}
				
				/**
				 * External, remote load failed...
				 */
				function onError_localeLoaded(event:ResourceEvent):void 
				{
					// @TODO Throw a FaultEvent for global alerts.
				}
				
			var allKnown      : Array   = _localeMngr.getLocales();
			var alreadyLoaded : Boolean = (allKnown.indexOf(locale) > -1) || (allKnown.indexOf(locale.toLowerCase()) > -1);
			var bundlePath    : String  = buildExternalLocaleURL(locale);
			
			logger.debug( "ExternalLocaleCommand::loadLocale( `{0}`, url=`{1}` )", locale, bundlePath );
			
			if (alreadyLoaded != true) 
			{
				var dispatcher : IEventDispatcher = _localeMngr.loadResourceModule( bundlePath  ,false);
				
					dispatcher.addEventListener(ResourceEvent.COMPLETE, onResult_localeLoaded);
					dispatcher.addEventListener(ResourceEvent.ERROR, onError_localeLoaded);
				
			} else {
				// Just set it as the first in the list... which fires "change" events also
				onResult_localeLoaded();
			} 
		}
		
		
		// ************************************************************************
		// Private  Methods
		// ************************************************************************
		
		
		/**
		 * Build app-relative url to the compiled locale resource bundles 
		 * @return 
		 * 
		 */
		protected function buildExternalLocaleURL(locale:String):String {
			return supplant( externalPath, [locale] );
		}
		
	}
}