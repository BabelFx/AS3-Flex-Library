////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.swizframework.processors
{
	import ext.babelfx.events.BabelFxEvent;
	import ext.babelfx.injectors.ResourceInjector;
	import ext.babelfx.maps.LocalizationMap;
	import ext.babelfx.proxys.ResourceSetter;
	import ext.swizframework.metadata.BabelFxMetadataTag;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import org.swizframework.core.Bean;
	import org.swizframework.core.ISwiz;
	import org.swizframework.events.SwizEvent;
	import org.swizframework.metadata.EventTypeExpression;
	import org.swizframework.processors.BaseMetadataProcessor;
	import org.swizframework.processors.ProcessorPriority;
	import org.swizframework.reflection.IMetadataTag;
	import org.swizframework.storage.ISharedObjectBean;
	import org.swizframework.storage.SharedObjectBean;
	import org.swizframework.utils.logging.SwizLogger;
	
	/**
	 * This metadata processor is used to configure [BabelFx] targets
	 * for injection of localized content.
	 * 
	 */
	public class BabelFxProcessor extends BaseMetadataProcessor
	{
		
		/**
		 * Auto load the default resources after Swiz finishes initializing...
		 * NOTE: disable this if the application wants to delay l10n loading
		 *       and later manually invoke using new BabelFxEvent(BabelFxEvent.LOAD_DEFAULT)
		 */
		public var autoLoadDefault : Boolean = true;
		
		// ========================================
		// constructor
		// ========================================
		
		/**
		 * Constructor
		 */
		public function BabelFxProcessor( metadataNames:Array = null )
		{
			super( ( metadataNames == null ) ? [ "BabelFx", "Babel", "l10n", "BabelFxHandler", "BabelHandler", "l10nHandler" ] : metadataNames, BabelFxMetadataTag );
		}
		
		
		// *********************************************************************************
		// Public overrides for BaseMetadataProcessor
		// *********************************************************************************
		
		/**
		 * Set the processing priority so the [BabelFx] processor runs AFTER the [PostConstruct] 
		 */
		override public function get priority():int {
			return ProcessorPriority.POST_CONSTRUCT - 10;
		}
		
		/**
		 * When all [BabelFx] tags have been processed for bean instance, then
		 * execute the injector to inject all content into destinations; based
		 * on proxy/resourceSetter settings.
		 */
		override public function setUpMetadataTags(metadataTags:Array, bean:Bean):void 
		{
			buildLocalizationMap();
			
			super.setUpMetadataTags( metadataTags, bean );
			
			
			if ( metadataTags.length > 0 )
			{
				// Perform content injection immediately 
				
				var injector : ResourceInjector = loadInjectorFor( bean.source );
				
				if ( injector )
				{
					injector.id 	||= String(++ _counter);
					injector.logger ||= SwizLogger.getLogger( injector );
					
					_map.addInjectors( injector );
				}
			}
		}
		
		/**
		 * Executed when a [DeepLink] has been removed
		 */
		override public function tearDownMetadataTags(metadataTags:Array, bean:Bean):void
		{
			super.tearDownMetadataTags(metadataTags, bean);
			
			// Since we have 1 injector per bean.source...
			
			var injector : ResourceInjector = removeLocalization( bean.source );
			_map.removeInjectors( injector );
		}
		
		
		/**
		 * Executed when a [BableFx] tag is found on an AS3 class
		 * NOTE: [BabelFx] tags are not suuported at the method or property level.
		 */
		override public function setUpMetadataTag( metadataTag:IMetadataTag, bean:Bean ):void
		{
			addLocalization( bean.source, BabelFxMetadataTag( metadataTag ));
		}
		

		
		// *********************************************************************************
		// Protected `add/remove Injector for instance` methods
		// *********************************************************************************
		
		
		/**
		 * For any bean instance, create a ResourceInjector with children resourceSetters
		 * specific to that bean instance. 
		 */
		protected function addLocalization( instance:Object, btag:BabelFxMetadataTag ):void
		{
			// If the tag has not been attached to a function or property...
				
			if ( btag.host.name == "undefined" )	btag.host.name = null;
			
			
			var injector : ResourceInjector = loadInjectorFor( instance, btag)
			var setter   : ResourceSetter   = new ResourceSetter().init( btag );
			
			
			// If we have a injection setting, then add the tag
				
			if ( btag.key && btag.property ) 
			{
				// Do we have key and target property defined; min reqs for ResourceSetter ?
				
				injector.proxies = [ setter  ].concat( injector.proxies );
			}
			else 
			{
				// Do we have a `change` handler implied by [BabelFx(event="")] associated a method ?
				
				if ( btag.event || btag.host.name ) 
				{
					var expression	: EventTypeExpression = new EventTypeExpression( btag.event, swiz );
					
					// If we have 1 specific event type, then filter with it. Otherwise trigger on all events
					// Do we have a handler function defined ?
					
					setter.filter = expression.eventTypes.length > 1 ? null : expression.eventTypes[ 0 ];
					setter.eventHandler = btag.host.name || btag.eventHandler;
					
					// No filters if all allowed.
					if (setter.filter == "*") setter.filter = null;
					
					injector.proxies = [ setter  ].concat( injector.proxies );
					
				} else {
					
					// Do we have a bundleName defined ?
					
					if ( btag.bundle )
						injector.bundleName = btag.bundle;
				}
					
			}
		}
		
		/**
		 * For a specific bean instance, release any injectors and setters.
		 * Then clear the internal cache reference.
		 */
		protected function removeLocalization(  instance:Object ):ResourceInjector 
		{
			var injector : ResourceInjector = (_registry[ instance ] as ResourceInjector); 
			if ( injector )	
			{
				injector.release();
				delete _registry[ instance ];
			}
			
			return injector;
		}
		
		// *********************************************************************************
		// Protected builder methods
		// *********************************************************************************
		
		
		/**
		 * For the specified instance, create and cache a ResourceInjector
		 */
		protected function loadInjectorFor( instance:Object, btag:BabelFxMetadataTag = null ):ResourceInjector
		{
			_registry[ instance ] ||= (btag ? new ResourceInjector( btag.bundle, instance ) : null);
			
			return _registry[ instance ] as ResourceInjector;
		}
		
		/**
		 * Load LocalizationMap instance that may be declared as a Swiz bean, or build
		 * a default, internal instance.
		 * 
		 */
		protected function buildLocalizationMap():LocalizationMap 
		{
				
				/**
				 * Swiz start up has finished processing all beanProviders.
				 * So tell localeMap to start inject into those beans; 
				 * if the [BabelFx] tag has been defined.
				 */
				function onSwizLoadFinished(event:Event):void 
				{
					swiz.dispatcher.removeEventListener(SwizEvent.LOAD_COMPLETE,onSwizLoadFinished);	
					
					if ( autoLoadDefault == true )
					{
						// Load default locale: load externally if needed and switch to user-preferred locale 
						
						_map.dispatchEvent( new BabelFxEvent(BabelFxEvent.LOAD_DEFAULT) );
					}
					
					// Mark the map as initialized (if needed), after all the Swiz
					// beans have been configured.
					
					_map.isInitialized = true;
				}
			
			if ( !_map ) 
			{
				_map   			  = beanFactory.getBeanByType( LocalizationMap ) as LocalizationMap;
				_map 			||= new LocalizationMap( swiz.dispatcher );
				_map.dispatcher ||= swiz.dispatcher;
				_map.logger     ||= SwizLogger.getLogger( _map );
				_map.lso        ||= buildSharedObjectBean();
				
				swiz.dispatcher.addEventListener(SwizEvent.LOAD_COMPLETE,onSwizLoadFinished);
			}
			
			return _map;
		}
		
		
		/**
		 * Builds internal persistence mechanism for `userPreferred` locales
		 */
		protected function buildSharedObjectBean():ISharedObjectBean 
		{
			var bean : SharedObjectBean = new SharedObjectBean();
			    bean.name = "babelfx";
			
			return bean;
		}
		
		// *********************************************************************************
		// Private Attributes
		// *********************************************************************************
		
		
		private var _counter  : uint = 0;
		private var _map 	  : LocalizationMap;
		private var _registry : Dictionary = new Dictionary(true);
	}
}

