////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////


package ext.babelfx.maps
{
    import com.codecatalyst.util.IterableUtil;
    import com.codecatalyst.util.invalidation.InvalidationTracker;
    
    import ext.babelfx.commands.ILocaleCommand;
    import ext.babelfx.commands.LocaleCommand;
    import ext.babelfx.events.BabelFxEvent;
    import ext.babelfx.injectors.ResourceInjector;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    
    import mx.core.ClassFactory;
    import mx.core.IFactory;
    import mx.core.IMXMLObject;
    import mx.resources.IResourceManager;
    import mx.resources.ResourceManager;
    
    import org.swizframework.storage.ISharedObjectBean;
    import org.swizframework.utils.logging.SwizLogger;
    
    import utils.string.supplant;
    

    //--------------------------------------
    //  Other metadata
    //--------------------------------------

    /**
     *  Dispatched before the current locale will be changed.
     *
     *  <p>The <code>commandFactory</code> will be used to create an instance of ILocaleCommand. Before the
     *  <code>ILocaleCommand::execute</code> is invoked, this event announces that the locale will change soon.</p>
     *
     *  @eventType org.babelfx.events.MapEvent.LOCALE_CHANGING
     *
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    [Event(name = 'localeChanging', type = 'ext.babelfx.events.MapEvent')]

    /**
     *  Dispatched after the current locale has changed, but BEFORE the ResourceInjectors are triggered.
     *  This event is dispatched whenever the ResourceManager::localeChain is modified (by BabelFx or other means).
     *
     *  @eventType org.babelfx.events.MapEvent.LOCALE_CHANGED
     *
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    [Event(name = 'localeChanged', type = 'ext.babelfx.events.MapEvent')]



	/**
	 * If LocalizationMap is instantiated as a tag with child ResourceInjector tags, they
	 * can be auto-assigend to the `injectors` property
	 */
    [DefaultProperty("injectors")]


    /**
     * The LocaleMap is a smart container for ResourceInjectors. 
	 * 
     */
    public class LocalizationMap extends EventDispatcher implements IMXMLObject
    {

	
		// ************************************************************************************************
		//  Public Properties
		// ************************************************************************************************
	
		public var lso	  :	ISharedObjectBean;
		public var logger : SwizLogger;
		
		[Bindable]
		[Invalidate("properties")]
		/**
		 * Should the user's preferred locale be used 
		 * as the override during loadDefaultLocale() ?  
		 */
		public var enableUserPreference : Boolean = true;
		

		[Bindable]
        [Dispatcher]
		[Invalidate("properties")]
        /**
         * Swiz dispatcher injected
         */
        public var dispatcher:IEventDispatcher;

		
		[Bindable]
		[Invalidate("properties")]
		/**
		 * List of ResourceInjectors used to inject localized
		 * content into target properties
		 */
		public var injectors : Array = [ ];
		

        /**
         * Write-only property that allows developers to implement and install custom loaders for external ResourceBundles.
         * The <code>val</code> may be an IFactory instance or a Class, String, Object reference that will be used by
         * <code>ClassFactory::newInstance()</code>.
		 * 
         */
        public function set commandFactory(val:*):void
        {
            if (val == null)
                return;

            if (val is IFactory)
                _commandFactory = val as IFactory;
            else
            {
                // Use internal default locale switcher command 
                // LocaleCommand does not load external bundles, instead it simply switches embedded locales
                _commandFactory = new ClassFactory(val as Class || LocaleCommand);
            }

        }

		/**
		 * Public accessor to the ResourceManager instance... same
		 * accessor available in all UIComponent instances
		 */
		public function get resourceManager() : IResourceManager 
		{
			return ResourceManager.getInstance();
		}
		
		
		/**
		 * Support for IMXMLObject when this class is instantiated as a tag instance in MXML
		 */
		public function set isInitialized( val : Boolean ):void
		{
			if ( val != _isInitialized )
			{
				_isInitialized = val;
				
				// If initialized, invalidate to fire injectors in 1-2 frames...
				
				if ( val ) _invalidator.invalidate( "injectors" );
			}
		}
		

        // ************************************************************************************************
        //  Support for Programmatic instantiations
        // ************************************************************************************************

        public function addInjectors(target:*):void
        {
			var queue  : Array = [ ]; 
			var items : Array = ( target is ResourceInjector ) ? [ target ] 		:
				        	    ( target is Array )            ? (target as Array)	: [ ];
			
			// Only merge new instances
			
			for each (var it:* in items )
			{
				var injector : ResourceInjector = it as ResourceInjector;
				
				if ( injector && injectors.indexOf( injector ) < 0 )
				{
					injectors.push( injector );
					queue.push (injector );
				}
			}
			
			// Immediately fire `new` injectors
			
			fireInjectors( queue );
        }

		/**
		 * Remove the specified 
		 */
		public function removeInjectors(target:*):void
		{
			releaseInjectors( target );
		}

		
		// ************************************************************************************************
		//  Constructor
		// ************************************************************************************************
		
		
		public function LocalizationMap(dispatcher:IEventDispatcher=null, injectors:Array=null) 
		{
			this.dispatcher = dispatcher;
			this.injectors  = injectors || new Array();
			
			// Announce ResourceManager locale changes BEFORE the ResourceInjectors fire...
			
			resourceManager.addEventListener(Event.CHANGE, onResourceManagerChange, false, 10, true);
			
			// Listen for commands to load locales
			
			listenLoadLocale( true );
		}
		

		/**
		 * Support for IMXMLObject when this class is instantiated as a 
		 * tag instance in MXML
		 * 
		 */
		public function initialized(document:Object, id:String):void
		{
			this.isInitialized = true;
			
		}

		// ************************************************************************************************
		//  Protected Methods
		// ************************************************************************************************
		
		/**
		 * Reattach listeners and use current set of injects to refire localized content
		 */
		protected function commitProperties():void 
		{
			if ( !_isInitialized ) return;
			
			if ( _invalidator.invalidated( ["dispatcher"] ) )
			{
				listenLoadLocale( true );
			}
			
			if ( _invalidator.invalidated( ["injectors"] ) )
			{
				releaseInjectors( _invalidator.previousValue("injectors") as Array );
				
				fireInjectors( injectors );	
			}
			
			if ( _invalidator.invalidated( ["enableUserPreference"] ) )
			{
				if ( _localeCommand ) 
					_localeCommand.enableUserPreference = this.enableUserPreference;
			}
		}
		

		/**
		 * Listen for request to load the locale.
		 * If not using an ExternalLocaleCommand, then the localeChain is simply changed; which then [later]
		 * fires a ResourceManager.CHANGE event.
		 * 
		 * NOTE we need to listen at both the Swiz level (for biz events) and the map level (for direct events)
		 */
		protected function listenLoadLocale(active:Boolean=true):void 
		{
			var it:IEventDispatcher;
			
			for each ( it in [dispatcher, this] ) {
				if ( !it ) continue;
				
				it.removeEventListener(BabelFxEvent.LOAD_DEFAULT, onLoadLocale);
				it.removeEventListener(BabelFxEvent.LOAD_LOCALE, onLoadLocale );
			}
			
			if (active == true) 
			{
				for each ( it in [dispatcher, this] ) {
					if ( !it ) continue;
					
					it.addEventListener(BabelFxEvent.LOAD_DEFAULT, onLoadLocale);
					it.addEventListener(BabelFxEvent.LOAD_LOCALE, onLoadLocale );
				}
			}
		}
		
		
		// ************************************************************************************************
		//  Protected Injector Methods
		// ************************************************************************************************
		
		
		/**
		 * Tell each injector to fire all injections defined for its current target.
		 */
		protected function fireInjectors( items:Array ):void 
		{
			if ( !_isInitialized ) return;
			
			var ids : Array = IterableUtil.getItemsByProperty(items, "id");
			logger.debug( supplant( "LocalizationMap::fireInjectors( ids=`{0}` )", [ids.toString()] ) );
			
			for each ( var it:ResourceInjector in items) 
			{
				it.execute();
			}
		}
		
		/**
		 * Release the specified 
		 */
		protected function releaseInjectors( target:* ):void
		{
			var items : Array = ( target is ResourceInjector ) ? [ target ] 		:
								( target is Array )            ? (target as Array)	: [ ];
			
			for each (var it:* in items )
			{
				var injector : ResourceInjector = it as ResourceInjector;
				var index    : int              = it ? injectors.indexOf( it ) : -1;
				
				if ( index > -1 ) 
				{
					injectors.splice(index,1);
				}
				
				injector.release();
			}
		}
		


        // ************************************************************************************************
        //  Protected EventHandlers
        // ************************************************************************************************


        /**
         * Announce to LocalizationMap listeners that the resourceManager localeChain has changed
         * but the ResourceInjectors have NOT yet been triggered.
         *
         * @param Event Event.CHANGE
         */
        protected function onResourceManagerChange(event:Event):void
        {
			fireInjectors( injectors );
			
			// Announce to external listeners that the locale has changed and injectors have finished.
			
            dispatchEvent(new BabelFxEvent(BabelFxEvent.LOCALE_CHANGED, null, resourceManager));
        }


		/**
		 * Request that BabelFx change the locale (using either embedded bundles or
		 * externally loaded bundles).
		 */
        protected function onLoadLocale(event:BabelFxEvent):void
        {
			// If multiple localeMaps are instantiated, only the FIRST map to get the event should process
			// the loadLocale request. Kill propagation to the other possible map instances
			
			event.stopImmediatePropagation();

			// Notify any listeners that a locale switch will happen next!
			
            dispatchEvent( new BabelFxEvent(BabelFxEvent.LOCALE_CHANGING, null, resourceManager) );

            // Delegate the event processing to the ILocaleCommand instance
            _localeCommand 			||= _commandFactory.newInstance() as ILocaleCommand;
			_localeCommand.lso 		||= this.lso;
			_localeCommand.logger	||= SwizLogger.getLogger( _localeCommand  );
			
			_localeCommand.enableUserPreference = enableUserPreference;
			
            _localeCommand.execute(event);

        }



        // ************************************************************************************************
        //  Private Attributes
        // ************************************************************************************************

		private var _invalidator    :InvalidationTracker = new InvalidationTracker(this as IEventDispatcher, commitProperties, true);
		
        private var _commandFactory	:IFactory = new ClassFactory( LocaleCommand );

        private var _localeCommand	:ILocaleCommand = null;
		
		private var _isInitialized  :Boolean = false;

    }
}
