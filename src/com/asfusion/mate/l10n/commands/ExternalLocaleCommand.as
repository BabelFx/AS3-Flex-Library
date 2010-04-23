package com.asfusion.mate.l10n.commands
{
	import com.asfusion.mate.l10n.events.LocaleEvent;
	
	import flash.events.IEventDispatcher;
	import flash.net.*;
	import flash.system.Capabilities;
	
	import mx.events.ResourceEvent;
	import mx.managers.*;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.utils.StringUtil;
	
	
	public class ExternalLocaleCommand extends LocaleCommand
	{	
		/**
		 *  Template to be used to build full URL path for the 
		 *  external resource bundle (swf)
		 *  
		 *  @example  
		 * 
		 *  "assets/locale/bundles/{0}.swf"
		 */
		public var externalPath : String = "assets/locale/bundles/{0}.swf";
		
		override public function execute( event:LocaleEvent ):void {
			
			if (event is LocaleEvent) {
				switch(LocaleEvent(event).action) {
					case LocaleEvent.LOAD_LOCALE  : 
					{
						loadLocale(LocaleEvent(event).locale);		
						break;	
					}
					default                       : 
					{
						super.execute(event);	
					}
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
		 * @param locale String specifing request locale; e.g. en_US, en_NZ, es_MX, etc.
		 * 
		 *  ******************************************************************************************
		 *  !!Important: before the locale resourcebundles are assigned (after loading) we must FIRST load (1) & (2):
		 *  ******************************************************************************************
		 * 
		 *   1) StyleSheets for locale
		 *   2) Runtime fonts for StyleSheets
		 *   3) Localized ResourceBundles
		 *   4) Dynamic Runtime Text
		 * 
		 */
		override protected function loadLocale(locale:String):void {
			var allKnown      : Array   = _localeMngr.getLocales();
			var alreadyLoaded : Boolean = (locale == defaultLocale) ? true : 
										  (allKnown.indexOf(locale) > -1) || (allKnown.indexOf(locale.toLowerCase()) > -1);
			
			// Cache for result handler
			_localeToLoad = locale;
			
			if (alreadyLoaded != true) {
				 
				var dispatcher : IEventDispatcher = _localeMngr.loadResourceModule(this.urlExternalLocale,false);
				    dispatcher.addEventListener(ResourceEvent.COMPLETE,onResult_localeLoaded);
				    dispatcher.addEventListener(ResourceEvent.ERROR,onError_localeLoaded);
				    
			} else {
				// Just set it as the first in the list... which fires "change" events also
				onResult_localeLoaded();
			} 
		}
		
		// ************************************************************************
		// Private DataService Handlers
		// ************************************************************************

		private function onResult_localeLoaded(event:ResourceEvent=null):void {
			
			 if (((_localeToLoad != "") && !event) || (event.type == ResourceEvent.COMPLETE)) {
				// Note: ResourceManager searches bundles for locales from first (0-index) to last
				//       the last locale is the "fallback" bundle. As such, en_US should always be the last.
				var fallback : Array = [defaultLocale];
				
				_localeMngr.localeChain = (_localeToLoad == fallback[0]) ? fallback : [_localeToLoad].concat(fallback);		// ["fr_FR","en_US"]
			} 
			
			// Cleanup
			_localeMngr.removeEventListener(ResourceEvent.COMPLETE,onResult_localeLoaded);
		}
		
		private function onError_localeLoaded(event:ResourceEvent):void {
			// @TODO Throw a FaultEvent for global alerts.
			trace(StringUtil.substitute("Resource load failed for url='{0}'",[this.urlExternalLocale]));
		}
		
		
		// ************************************************************************
		// Private  Properties
		// ************************************************************************
		
		
		/**
		 * Build app-relative url to the compiled locale resource bundles 
		 * @return 
		 * 
		 */
		private function get urlExternalLocale():String {
			return StringUtil.substitute(externalPath,[_localeToLoad]);
		}
		
		
		private var _localeToLoad : String   = "";
	}
}