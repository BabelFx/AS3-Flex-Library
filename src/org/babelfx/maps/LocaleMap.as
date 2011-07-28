////////////////////////////////////////////////////////////////////////////////
//
//  THE MINDSPACE GROUP, LLC
//  Copyright 2008-2011 Mindspace 
//  All Rights Reserved.
//
//  NOTICE: Mindspace permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package org.babelfx.maps
{
	import com.asfusion.mate.core.GlobalDispatcher;
	import com.asfusion.mate.core.ListenerProxy;
	import com.asfusion.mate.events.InjectorEvent;
	import com.codecatalyst.factory.ClassFactory;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.IFactory;
	import mx.core.IUIComponent;
	import mx.events.FlexEvent;
	import mx.logging.ILogger;
	import mx.logging.ILoggingTarget;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	
	import org.babelfx.commands.LocaleCommand;
	import org.babelfx.events.*;
	import org.babelfx.injectors.AbstractInjector;
	import org.babelfx.interfaces.ILocaleCommand;
	import org.babelfx.utils.InjectorUtils;
	import org.babelfx.utils.debug.LocaleLogger;

	//--------------------------------------
	//  Other metadata
	//--------------------------------------
	
	/**
	 *  Dispatched before the current locale will be changed.
	 *  
	 *  <p>The <code>commandFactory</code> will be used to create an instance of ILocaleCommand. Before the 
	 *  <code>ILocaleCommand::execute</code> is invoked, this event announces that the locale will change soon.</p> 
	 * 
	 *  @eventType org.babelfx.events.LocaleMapEvent.LOCALE_CHANGING
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	[Event(name='localeChanging',type='org.babelfx.events.LocaleMapEvent')]

	/**
	 *  Dispatched when a new instance of a <code>ResourceInjector::target</code> is 
	 *  ready for injection. All children <code>ResourceInjector</code>s listen
	 *  for <code>LocaleMapEvent.TARGET_READY</code> events from the <code>LocaleMap</code> instance.
	 *  
	 *  @eventType org.babelfx.events.LocaleMapEvent.TARGET_READY
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	[Event(name='targetReady',	 type='org.babelfx.events.LocaleMapEvent')]
	
	/**
	 *  Dispatched when the <code>LocaleMap</code> instance has been initialized. Currently
	 *  only available via MXML instantiation; not with programmatic instantiation.
	 *  
	 *  @eventType org.babelfx.events.LocaleMapEvent.INITIALIZED
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 */
	[Event(name='initialized',   type='org.babelfx.events.LocaleMapEvent')]
	
	
	
	[DefaultProperty("injectors")]
	
	
	/**
	 * The LocaleMap is a smart container for ResourceInjectors. It also provides mechanisms for notifications
	 * of DisplayObject <code>creationComplete</code> events and <code>addedToStage</code> events.
	 *
	 * <p>Below are recommendations for usage:
	 * <ul>
	 * 	<li>The LocaleMap must be extended using MXML and instantiated using an MXML tag. AS3 programmatic instantiation has rudimentary support.</li>
	 * 	<li>The LocaleMap subclass should be instantiated at the application-level, module-level, or a configuration level. Do not instantiate within a view component; as unexpected behaviour may manifest.</li>
	 * </ul>
	 * </p>
	 * 
	 * @mxml
	 * 
	 *  @see org.babelfx.maps.AbstractMap
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 9
	 *  @playerversion AIR 1.1
	 *  @productversion Flex 3
	 * 
	 */
	public class LocaleMap extends AbstractMap  {
		
		// ************************************************************************************************
		//  Public Properties
		// ************************************************************************************************
		
		[Bindable]
		/**
		 *  Property that enables logging for all BabelFx activity. If the user does not specify a custom <code>loggingTarget</code>,
		 *  the a <code>TraceTarget</code> will be used to output to the console.
		 * 
		 *  @default false
		 * 
	     *  
	     *  @langversion 3.0
	     *  @playerversion Flash 9
	     *  @playerversion AIR 1.1
	     *  @productversion Flex 3
		 */
		public function get enableLog():Boolean {
			return _logCommands;
		}
		/**
		 *  @private
		 */
		public function set enableLog(val:Boolean):void {
			LocaleLogger.addToFilters(this);
			
			// Use existing or default if active...
			this.loggingTarget = val ? LocaleLogger.sharedTarget || TraceTarget : null;

			_logger 	 = LocaleLogger.getLogger(this);
			_logCommands = val;
		}
		
		
		/**
		 * Write-only property that allows developers to specify a custom LoggingTarget that will be used with <code>enableLogging</code> is <code>true</code>.
		 * The <code>val</code> may be an ILoggingTarget instance, IFactory instance or a Class, String, Object reference that will be used by 
		 * <code>ClassFactory::newInstance()</code>. The instance that is returned must implement the <code>mx.logging.ILoggingTarget</code>
		 * interface.
		 * 
		 * @mxml
		 * 
		 * <pre>
		 *    &lt;l10n:LocaleMap&gt;
		 * 		&lt;l10n:loggingTarget&gt;
		 * 				&lt;l10n:ClassFactory generator="{mx.logging.targets.TraceTarget}" properties="{{level:LogEventType.WARN + LogEventType.ERROR}}"
		 * 		&lt;/l10n:logginTargets&gt;
		 * 	  &lt;/l0n:LocaleMap&gt;
		 * </pre>
		 * 
		 * @param val Object
		 * 
		 * @see com.codecatalyst.factory.ClassFactory
		 * @see mx.logging.targets.TraceTarget
		 *  
		 * @langversion 3.0
		 */
		public function set loggingTarget(val : *):void {
			if (val != _logTarget) {
				
				LocaleLogger.removeLoggingTarget(_logTarget);
				
				_logTarget = (val is ILoggingTarget) ? 	ILoggingTarget(val) 						  :
							 (val is IFactory)		 ?	IFactory(val).newInstance() as ILoggingTarget : 
							 (val is Class)          ?  new ClassFactory(val,null,_defaultProperties).newInstance() : 
							 (val is String)         ?  new ClassFactory(val,null,_defaultProperties).newInstance() : null;
				
				LocaleLogger.addLoggingTarget(_logTarget);
			}
		}
		
		/**
		 * Write-only property that allows developers to implement and install custom loaders for external ResourceBundles.
		 * The <code>val</code> may be an IFactory instance or a Class, String, Object reference that will be used by 
		 * <code>ClassFactory::newInstance()</code>. 
		 * 
		 * <p>The instance that is returned <b>must</b> implement the <code>org.babelfx.interfaces.ILocaleCommand</code>
		 * interface.</p>
		 * 
		 * @mxml
		 * 
		 * <pre>
		 *    &lt;l10n:LocaleMap&gt;
		 * 		&lt;l10n:commandFactory&gt;
		 * 			&lt;ClassFactory generator="{ExternalLocaleCommand}"&gt;
		 *				&lt;properties>
		 *					&lt;mx:Object externalPath="\{0\}.swf"/&gt;
		 *				&lt;/properties&gt;
		 *			&lt;/ClassFactory&gt;
		 *      &lt;/l10n:commandFactory&gt;
		 * 	  &lt;/l0n:LocaleMap&gt;
		 * </pre>
		 * 
		 *  @param val The value of the constraint can be specified in either
     	 *  of four (4) forms. It can be specified as an IFactory instance or it can be specified as a String, Class, or 
		 *  Object instance that references a class that implements the ILocaleCommand interface or a IFactory instance.
		 * 
		 * @see com.codecatalyst.factory.ClassFactory
		 * @see org.babelfx.interfaces.ILocaleCommand
		 *  
		 * @langversion 3.0
		 */
		public function set commandFactory(val:*):void {
			if (val == null) return;
			
			if (val is IFactory)     _commandFactory = val as IFactory;
			else if (val is Class)	 _commandFactory = new ClassFactory(val as Class);
			else {
				_logger.error(ERROR_INVALID_FACTORY);
				
				// Use internal default locale switcher command 
				// LocaleCommand does not load external bundles, instead it simply switches embedded locales
				_commandFactory = new ClassFactory(LocaleCommand);
			}
			
			_isCustomFactory = true;
		}
		
		/**
		 * An array of classes that, when an object is created, should trigger the InjectorHandlers to run. 
		 * 
		 *  @default true
		 * 
		 */
		public function get targets():*
		{
			return _targets;
		}
		public function set targets(value:*):void
		{	
			var oldValue:Array = _targets;
			var newValue:Array = (value is Array) ? value as Array :
			                     (value is Class) ? [value]        : [];
			
			if (!_isInitialized) {
				// Fix to init issue with Flex4 (must preserve all targets)
				// Only after initialization, does assigning targets CLEAR all
				// current targets...
				newValue = newValue.concat(targets);	
			}
	        
			if (oldValue !== newValue)
	        {
	        	if(targetsRegistered) unregisterAll();
	        	_targets = newValue;
				
	        	invalidateProperties();
	        }
		}
		
		/**
		 * Since all children injectors (ResourceInjector and SmartResourcInjector) listen
		 * for TARGET_READY events from the LocaleMap instance, this is a wrapper
		 * facade to simplify that relationship. 
		 * 
		 * NOTE: This method is called from within the LocaleMap class AND provides 
		 * easy registration of non-GUI instances from outside this class.
		 *  
		 * @param src UIComponent, Sprite or non-DisplayObject instance
		 * 
		 */
		public function announceTargetReady(src:Object):void {
			if (src != null) {
				this.dispatchEvent(new LocaleMapEvent(LocaleMapEvent.TARGET_READY, src));
			}
		}

		public function addTarget(another:Class):void {
			if (another && !alreadyRegistered(another)) {
				_targets.push(another);
				invalidateProperties();
			}
		}
		
		private function alreadyRegistered(target:Class):Boolean {
			var results : Boolean = false;
			for each (var it:Class in _targets) {
				if (it == null) continue;
				if (InjectorUtils.isSameClass(it,target)) {
					results = true;
					break;
				}
			}
			
			return results;
		}

		/**
		 * If this property is true, the injector will inject not only the Class in the
		 * target property, but also all the classes that extend from that class. 
		 * If the target is an interface, it will inject all the objects that implement
		 * the interface.
		 * 
		 *  @default false
		 * */
		public function get includeDerivatives():Boolean
		{
			return _includeDerivatives;
		}
		public function set includeDerivatives(value:Boolean):void
		{
			var oldValue:Boolean = _includeDerivatives;
	        if (oldValue !== value)
	        {
	        	_includeDerivatives       = value;
	        	includeDerivativesChanged = true;
				
	        	if (_isInitialized == true) validateNow();
	        }
		}

		
		// ************************************************************************************************
		//  Support for Programmatic instantiations
		// ************************************************************************************************
		
		public var injectors : Array = [ ];

		public function addInjectors(injectors:Array):void {
			if (this.injectors != injectors) {
				for each (var oit:AbstractInjector in injectors) {
					if (oit == null) continue;
					oit.release();
				}
				
				this.injectors = injectors;
				
				for each (var nit:AbstractInjector in injectors) {
					nit.initialized(this,"");
				}
				invalidateProperties();
			}
		}
		
		public function inject(locale:String=null):void {
			validateNow();
			if (locale  != null) {
				dispatchEvent(new LocaleEvent(LocaleEvent.LOAD_LOCALE,locale));
			}
		}
		
		// ************************************************************************************************
		//  Validation Methods
		// ************************************************************************************************

		/**
		 * @inheritDoc
		 */ 
		public function validateNow():void
		{
			commitProperties();
		}

		/**
		 * Processes the properties set on the component.
		*/
		protected function commitProperties():void {
			var haveTargets : Boolean = (_targets.length > 0); 

			if(_dispatcher != null) {
				registerAll();
				listenForCreationComplete(haveTargets);
				listenForSprites(haveTargets);
				
				includeDerivativesChanged = false;
			}
		}

		
		/**
		*  @inheritDoc
		*/
		public function invalidateProperties():void
		{
			if( _isInitialized == true ) commitProperties();
		}
		


		override public function initialized(document:Object, id:String):void {
			super.initialized(document,id);
			
			_isInitialized = true;
			
			commitProperties();
			
			dispatchEvent(new LocaleMapEvent(LocaleMapEvent.INITIALIZED, document));
			// Add listener to register non-UIComponents for injection...
			this.addEventListener(LocaleMapEvent.REGISTER_TARGET, onSpriteAddedToStage);

			_logger.debug("addEventListener for externally dispatched '{0}' ", LocaleMapEvent.REGISTER_TARGET);
			
		}
		
		// ************************************************************************************************
		//  Registration Methods
		// ************************************************************************************************
		
		protected  function registerAll():void {
			if(!targetsRegistered && _targets) {
				for each (var it:* in _targets) {
					registerTargetClass(it);
				}
				targetsRegistered = true;
			}
		}

		/**
		 * Unregisters a target or targets. Used internally whenever a new target/s is set or _dispatcher changes.
		*/
		protected function unregisterAll():void
		{
			if(!_dispatcher) return;
						
			if( _targets && targetsRegistered )
			{
				for each( var currentTarget:* in _targets)
				{
					var currentType:String = ( currentTarget is Class) ? getQualifiedClassName(currentTarget) : currentTarget;
					_dispatcher.removeEventListener(currentType, onCreationComplete_Target);
					_logger.debug("unregisterAll() target {0}",currentType);
				}
				targetsRegistered = false;
			}
		}
		
		protected function registerTargetClass(target:*):void {
			var currentType:String = ( target is Class) ? getQualifiedClassName( target ) : (target as String);
			
			if (currentType && currentType != "") {
				_logger.debug("registerTargetClass({0})",currentType);
				_dispatcher.addEventListener( currentType, onCreationComplete_Target, false, 0, true);
			}
		}
		

		// ************************************************************************************************
		//  CreationComplete Listeners Methods
		// ************************************************************************************************
		
		/**
		 * Add support to auto-listen for Sprites and MovieClips "addedToStage" events. This is required
		 * because only IUIComponent dispatches "creationComplete" events.
		 *  
		 * @param active Boolean to add or remove global listener
		 * 
		 */
		protected function listenForSprites(active:Boolean = true):void {
			if (active == true) _dispatcher.addEventListener(Event.ADDED_TO_STAGE,onSpriteAddedToStage);
			else			    _dispatcher.removeEventListener(Event.ADDED_TO_STAGE,onSpriteAddedToStage);
			
			_logger.debug("listenForSprites(active=={0}) Activating global listener for all sprite '{1}' events", active, Event.ADDED_TO_STAGE);
		}
		
		protected function listenForCreationComplete(active:Boolean = true):void {
			if (active == true) {
				
				addListenerProxy( _dispatcher, FlexEvent.CREATION_COMPLETE );

				_dispatcher.addEventListener(LocaleEvent.EVENT_ID,onLoadLocale,false,0,true);
				this.addEventListener(LocaleEvent.EVENT_ID,onLoadLocale);
				
			} else {
				
				removeListenerProxy( _dispatcher, FlexEvent.CREATION_COMPLETE );

				_dispatcher.removeEventListener(LocaleEvent.EVENT_ID,onLoadLocale);
				this.removeEventListener(LocaleEvent.EVENT_ID,onLoadLocale);
			}
			

			listenForDerivatives(active);
		}
		
		/**
		 * If a class has already been registered, then listen for instantiations of
		 * subclasses (or derivative classes) for that class.
		 * 
		 * NOTE: this option suffers a performance impact since EVERY component addedToStage or creationComplete
		 *       will then be checked as a possible derivative.
		 *  
		 * @param active
		 */
		protected function listenForDerivatives(active:Boolean):void {
			// Listen for creation of derivative instances of targets...
			if(includeDerivativesChanged || !active) {
				
				
				if( includeDerivatives && active ) {

					_logger.debug("listenForDerivatives() Attaching listener for Derivative creationComplete");
					_dispatcher.addEventListener( InjectorEvent.INJECT_DERIVATIVES, onCreationComplete_Derivative, false, 0, true);
					
				} else {
					_logger.debug("listenForDerivatives() Removing listener for Derivative creationComplete");
					_dispatcher.removeEventListener( InjectorEvent.INJECT_DERIVATIVES, onCreationComplete_Derivative );
				}
			}						
		}
		
		
		private function addListenerProxy(eventDispatcher:IEventDispatcher, type:String = null):ListenerProxy {
			var listenerProxy:ListenerProxy = _listenerProxies[eventDispatcher];
			
			if(listenerProxy == null)
			{
				listenerProxy = new ListenerProxy(eventDispatcher);
				_listenerProxies[eventDispatcher] = listenerProxy;
			}
			
			listenerProxy.addListener((type == null) ? "creationComplete" : type, 
									  (type == null) ? this 			  : null );

			_logger.debug("addListenerProxy() Attaching global listener for all GUI '{0}' events", type);
			

			return listenerProxy;
		}
		
		private function removeListenerProxy(eventDispatcher:IEventDispatcher,type:String):void {
			var listenerProxy:ListenerProxy = _listenerProxies[eventDispatcher];
			
			if(listenerProxy && type && (type != "")) {
				listenerProxy.removeListener(type);
				delete _listenerProxies[eventDispatcher];
				_logger.debug("removeListenerProxy() Detaching global listener for all GUI '{0}' events", type);	
			}	
		}
		

		// ************************************************************************************************
		//  CreationComplete EventHandlers
		// ************************************************************************************************
		
		/**
		 * For any non-UIComponent instance (such as Sprites or MovieClips), announce to all injectors that the target
		 * is ready for injections. This method is ALSO used to support registration (and target-ready announcements)
		 * for non-GUI instances (such as models and controllers).
		 * 
		 * Note: LocaleMapEvent.REGISTER_TARGET events are used to register non-GUI instances 
		 *       
		 * @param event
		 */		
		protected function onSpriteAddedToStage(event:Event):void {
			var target:Object = (event is LocaleMapEvent) ? LocaleMapEvent(event).targetInst : event.target;
			
			if (target && !(target is IUIComponent)) {
				_logger.debug("onSpriteAddedToStage() for '{0}'", getQualifiedClassName(target));
				announceTargetReady(target);
			}
		}
		
		protected function onLoadLocale(event:LocaleEvent):void {
			// Make sure the _logger is configured...
			configureLogging(_logCommands);
			_logger.debug("onLoadLocale() request for {0}",event.action);
			
			if (event.action == LocaleEvent.LOAD_LOCALE) {
				
				// Notify any listeners that a locale switch will happen next!
				dispatchEvent(new LocaleMapEvent(LocaleMapEvent.LOCALE_CHANGING));
				_logger.debug("onLoadLocale() announce 'changing' locale");
				
				// Delegate the event processing to the ILocaleCommand instance
				if (_localeCommand == null) _localeCommand = _commandFactory.newInstance() as ILocaleCommand; 
				
				if (_localeCommand != null) _localeCommand.execute(event);
				else  			 			_logger.error(ERROR_INVALID_COMMAND_INSTANCE);
			}
			
			// If multiple localeMaps are instantiated, only the FIRST map to get the event should process
			// the loadLocale request. Kill propagation to the other possible map instances
			
			event.stopImmediatePropagation();
		}
		
		/**
		 * Called by the dispacher when the event gets triggered.
		 * This method fires an event announcing that a target instance is READY (creationComplete).
		*/
		protected function onCreationComplete_Target(event:Event, logIt:Boolean=true):void {
			var instance 	: Object = kevValueFrom(event,"injectorTarget") as Object;
			var clazzName   : String = getQualifiedClassName(instance); 
			var uid			: *      = kevValueFrom(event,"uid");
			
			if (logIt == true) {
				_logger.debug("onCreationComplete_Target() for '{0}'", uid || clazzName);	
			}
			announceTargetReady(instance);
		}

		/**
		 * This function is a handler for the injection event, if the target it is a 
		 * derivative class the injection gets triggered
		 */ 
		protected function onCreationComplete_Derivative( event:Event ):void {
			var instance : Object = kevValueFrom(event,"injectorTarget") as Object;
			var uid		 : *      = kevValueFrom(event,"uid");
			
			if( _targets ) {
				for each( var entry:* in _targets) {
					var isDerivative : Boolean = InjectorUtils.isDerivative( instance, entry  );
					
					if( isDerivative == true )   {
						_logger.debug("onCreationComplete_Derivative() for '{0}'", uid);
						onCreationComplete_Target( event, false );				
					}
				}
			}
		}
		
			private function kevValueFrom(event:Event,key:String):* {
				return (event && event.hasOwnProperty(key)) ? event[key] : null;
			}
		
		
		// ************************************************************************************************
		//  Private Logging features 
		// ************************************************************************************************
		 
		private function configureLogging(val:Boolean):void {
			if (_commandFactory && _commandFactory is ClassFactory) {
				
				if (ClassFactory(_commandFactory).properties == null) {
					var clazz : Class = ClassFactory(_commandFactory).generatorClazz;
					ClassFactory(_commandFactory).properties = { log : LocaleLogger.getLogger(clazz, _isCustomFactory) };
				}
				
				enableLog = val;
			}
		}
		
		private var _logger						:ILogger        = LocaleLogger.getLogger(this);
		private var _logTarget                  :ILoggingTarget = LocaleLogger.sharedTarget;
		private var _logCommands				:Boolean 		= false;
		
		// ************************************************************************************************
		//  Private Attributes
		// ************************************************************************************************

		
		protected var targetsRegistered			:Boolean = false;
		protected var includeDerivativesChanged	:Boolean = false;

		private var _targets					:Array   = [ ];
		private var _includeDerivatives			:Boolean = false;
	
		private var _isInitialized				:Boolean = false;
		
		private var _dispatcher 				:IEventDispatcher 	= new GlobalDispatcher();
		private var _listenerProxies			:Dictionary 		= new Dictionary(true);

		private var _localeCommand              :ILocaleCommand = null;
		
		private var _defaultProperties          :Object             = { level:LogEventLevel.DEBUG, includeCategory:true, includeTime:true, includeLevel:true };
		private var _commandFactory 			:IFactory 			= new ClassFactory(LocaleCommand);
		private var _isCustomFactory            :Boolean            = false;
		
		private namespace self;
		
		private static const ERROR_INVALID_FACTORY 			: String = "Error - LocaleMap::set commandFactory(). This method expects either (a) <ILocaleCommand> Class or (b) IFactory instance";
		private static const ERROR_INVALID_COMMAND_INSTANCE : String = "Error - LocaleMap::commandFactory() does not generate an <ILocaleCommand> instance.";
	}
}