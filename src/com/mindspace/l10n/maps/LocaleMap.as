/*
Copyright 2009  Mindspace LLC, Thomas Burleson

Licensed under the Apache License, Version 2.0 (the "License"); 
you may not use this file except in compliance with the License. Y
ou may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 

Unless required by applicable law or agreed to in writing, s
oftware distributed under the License is distributed on an "AS IS" BASIS, 
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
See the License for the specific language governing permissions and limitations under the License

Author: Thomas Burleson, Principal Architect
        thomas burleson at g mail dot com
                
@ignore
*/
package com.mindspace.l10n.maps
{
	import com.asfusion.mate.core.GlobalDispatcher;
	import com.asfusion.mate.core.ListenerProxy;
	import com.asfusion.mate.events.InjectorEvent;
	import com.mindspace.l10n.commands.ILocaleCommand;
	import com.mindspace.l10n.commands.LocaleCommand;
	import com.mindspace.l10n.events.*;
	import com.mindspace.l10n.utils.InjectorUtils;
	import com.mindspace.l10n.utils.debug.LocaleLogger;
	import com.mindspace.l10n.utils.factory.StaticClassFactory;
	
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

	[Event(name='localeChanging',type='com.mindspace.l10n.events.LocaleMapEvent')]
	[Event(name='targetReady',	 type='com.mindspace.l10n.events.LocaleMapEvent')]
	[Event(name='initialized',   type='com.mindspace.l10n.events.LocaleMapEvent')]
	
	public class LocaleMap extends AbstractMap  {
		
		// ************************************************************************************************
		//  Public Properties
		// ************************************************************************************************
		
		[Bindable]
		public function get enableLog():Boolean {
			return _debugEnabled;
		}
		public function set enableLog(val:Boolean):void {
			_debugEnabled = val;
			
			if (val == true) {
				// Attach existing or new customized _logger
				this.loggingTarget = _logTarget ? _logTarget : new StaticClassFactory(TraceTarget,_defaultProperties);		
				
			} else if (!val && (_logTarget !=null)) {
				// Disable any logging for now...
				LocaleLogger.removeLoggingTarget(_logTarget);
			}
		}
		
		
		/**
		 * Setter that accepts an TraceTarget instance or a ClassFactory for an ILoggingTarget generator
		 *  
		 * @param val ILoggingTarget or IFactory
		 * 
		 */
		public function set loggingTarget(val : *):void {
			if (val == null) return;	// Clear existing target not supported
			
			if ((_logTarget != null) && val) LocaleLogger.removeLoggingTarget(_logTarget);
			
			
			_logTarget = (val is ILoggingTarget) ? 	ILoggingTarget(val) 						  :
						 (val is IFactory)		 ?	IFactory(val).newInstance() as ILoggingTarget : 
						 (val is Class)          ?  new StaticClassFactory(val,_defaultProperties).newInstance() : 
						 (val is String)         ?  new StaticClassFactory(val,_defaultProperties).newInstance() : null;
			
			if (_logTarget != null) {
				_debugEnabled = true;
				LocaleLogger.addToFilters(this);
				LocaleLogger.addLoggingTarget(_logTarget);
			}
		}
		
		/**
		 * Factory method that allows developers to build and use custom resourceBundle loaders within the LocaleMap 
		 * subclasses.
		 * 
		 * @code
		 * 
		 *    <l10n:LocaleMap>
		 * 		<l10n:commandFactory>
		 * 				<mx:ClassFactory generator="{MyLocaleLoader}" properties="{loaderConfig}" />
		 *      </l10n:commandFactory>
		 * 		<l10n:loggingTarget>
		 * 				<l10n:StaticClassFactory generator="{mx.logging.targets.TraceTarget}" properties="{{level:LogEventType.WARN + LogEventType.ERROR}}"
		 * 		</l10n:logginTargets>
		 * 	  </l0n:LocaleMap>
		 *  
		 * @param val Class with interface ILocaleCommand or a IFactory instance...
		 * 
		 */
		public function set commandFactory(val:*):void {
			if (val == null) return;
			
			if (val is IFactory)     _commandFactory = val as IFactory;
			else if (val is Class)	 _commandFactory = new StaticClassFactory(val as Class);
			else {
				// Use internal default locale switcher command 
				// LocaleCommand does not load external bundles, instead it simply switches embedded locales
				_commandFactory = new StaticClassFactory(LocaleCommand);
				_logger.error(ERROR_INVALID_FACTORY);
			}
			
			_isCustomFactory = true;
		}
		
		/**
		 * An array of classes that, when an object is created, should trigger the <code>InjectorHandlers</code> to run. 
		 * 
		 *  @default true
		 * */
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
	        	_includeDerivatives = value;
	        	includeDerivativesChanged = true;
	        	validateNow()
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
				_dispatcher.addEventListener( currentType, onCreationComplete_Target, false, 0, true);
				_logger.debug("registerTargetClass({0})",currentType);
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
		

		protected function listenForDerivatives(active:Boolean):void {
			// Listen for creation of derivative instances of targets...
			if(includeDerivativesChanged || !active) {
				includeDerivativesChanged = false;
				
				if(includeDerivatives && active) {
					_logger.debug("listenForDerivatives() Attaching listener for Derivative creationComplete");
					_dispatcher.addEventListener( InjectorEvent.INJECT_DERIVATIVES, onCreationComplete_Derivative, false, 0, true);
				} else {
					_logger.debug("listenForDerivatives() Removing listener for Derivative creationComplete");
					_dispatcher.removeEventListener( InjectorEvent.INJECT_DERIVATIVES, onCreationComplete_Derivative );
				}
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
			_logger.debug("onSpriteAddedToStage() for '{0}'", getQualifiedClassName(target));
			
			if (target && !(target is IUIComponent)) announceTargetReady(target);
		}
		
		protected function onLoadLocale(event:LocaleEvent):void {
			// Make sure the _logger is configured...
			configureLogging(_debugEnabled);
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
		}
		
		/**
		 * Called by the dispacher when the event gets triggered.
		 * This method fires an event announcing that a target instance is READY (creationComplete).
		*/
		protected function onCreationComplete_Target(event:Event, logIt:Boolean=true):void {
			var injectorTarget 	: Object = kevValueFrom(event,"injectorTarget") as Object;
			var uid			 	: *      = kevValueFrom(event,"uid");
			
			if (logIt == true) {
				var id 			: String = (uid != null) ? uid : getQualifiedClassName(injectorTarget); 
				_logger.debug("onCreationComplete_Target() for '{0}'",id);	
			}
			announceTargetReady(injectorTarget);
		}

		/**
		 * This function is a handler for the injection event, if the target it is a 
		 * derivative class the injection gets triggered
		 */ 
		protected function onCreationComplete_Derivative( event:Event ):void {
			var injectorTarget 	: Object = kevValueFrom(event,"injectorTarget") as Object;
			var uid			 	: *      = kevValueFrom(event,"uid");
			
			if( _targets ) {
				for each( var currentTarget:* in _targets) {
					var isDerivative : Boolean = InjectorUtils.isDerivative( injectorTarget, currentTarget  );
					
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
			if (_commandFactory && _commandFactory is StaticClassFactory) {
				
				if (StaticClassFactory(_commandFactory).properties == null) {
					var clazz : Class = StaticClassFactory(_commandFactory).source;
					StaticClassFactory(_commandFactory).properties = {log:LocaleLogger.getLogger(clazz, _isCustomFactory)}
				}
				
				enableLog = val;
			}
		}
		
		private var _logger						:ILogger        = LocaleLogger.getLogger(this);
		private var _logTarget                  :ILoggingTarget = null;
		private var _debugEnabled				:Boolean 		= false;
		
		// ************************************************************************************************
		//  Private Attributes
		// ************************************************************************************************

		
		protected var targetsRegistered			:Boolean = false;
		protected var includeDerivativesChanged	:Boolean = false;

		private var _targets					:Array   = [ ];
		private var _includeDerivatives			:Boolean = false;
	
		private var _isInitialized				:Boolean = false;
		
		private var _dispatcher 				:GlobalDispatcher 	= new GlobalDispatcher();
		private var _listenerProxies			:Dictionary 		= new Dictionary(true);

		private var _localeCommand              :ILocaleCommand = null;
		
		private var _defaultProperties          :Object             = { level:LogEventLevel.DEBUG, includeCategory:true, includeTime:true, includeLevel:true };
		private var _commandFactory 			:IFactory 			= new StaticClassFactory(LocaleCommand);
		private var _isCustomFactory            :Boolean            = false;
		
		private namespace self;
		
		private static const ERROR_INVALID_FACTORY 			: String = "Error - LocaleMap::set commandFactory(). This method expects either (a) <ILocaleCommand> Class or (b) IFactory instance";
		private static const ERROR_INVALID_COMMAND_INSTANCE : String = "Error - LocaleMap::commandFactory() does not generate an <ILocaleCommand> instance.";
	}
}