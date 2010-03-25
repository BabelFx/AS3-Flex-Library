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
package com.asfusion.mate.l10n.maps
{
	import com.asfusion.mate.core.GlobalDispatcher;
	import com.asfusion.mate.core.ListenerProxy;
	import com.asfusion.mate.events.InjectorEvent;
	import com.asfusion.mate.utils.InjectorUtils;
	
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.events.FlexEvent;
	import mx.utils.StringUtil;

	[Event(name='targetReady',type='com.asfusion.mate.l10n.maps.LocaleMapEvent')]
	
	public class LocaleMap extends AbstractMap  {
		

		// ************************************************************************************************
		//  Public Properties
		// ************************************************************************************************

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
			
			if (!isInitialized) {
				// Fix to init issue with Flex4 (must preserve all targets)
				// Only after initialization, does assigning targets CLEAR all
				// current targets...
				newValue = targets.concat(newValue);	
			}
	        
			if (oldValue !== newValue)
	        {
	        	if(targetsRegistered) unregisterAll();
	        	
	        	_targets = newValue;
	        	invalidateProperties();
	        }
		}

		public function addTarget(target:Class):void {
			if (target && !alreadyRegistered(target)) {
				targets = targets.concat([target]);
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
			}
		}

		
		/**
		*  @inheritDoc
		*/
		public function invalidateProperties():void
		{
			if( !isInitialized ) needsInvalidation = true;
			else				 commitProperties();
		}
		


		override public function initialized(document:Object, id:String):void {
			super.initialized(document,id);

			if( needsInvalidation )
			{
				commitProperties();
				needsInvalidation = false;
			}			
		}
		
		// ************************************************************************************************
		//  Registration Methods
		// ************************************************************************************************
		
		protected  function registerAll():void {
			if(!targetsRegistered && _targets) {
				for each (var it:* in _targets) {
					register(it);
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
					logDebug("UnRegisters target {0}",[currentType]);
				}
				targetsRegistered = false;
			}
		}
		
		protected function register(target:*):void {
			var currentType:String = ( target is Class) ? getQualifiedClassName( target ) : (target as String);
			
			if (currentType && currentType != "") {
				_dispatcher.addEventListener( currentType, onCreationComplete_Target, false, 0, true);
				logDebug("Registered target {0}",[currentType]);
			}
		}
		

		// ************************************************************************************************
		//  CreationComplete Listeners Methods
		// ************************************************************************************************
		
		protected function listenForCreationComplete(active:Boolean = true):void {

			if (active == true) addListenerProxy   ( _dispatcher, FlexEvent.CREATION_COMPLETE );
			else 				removeListenerProxy( _dispatcher, FlexEvent.CREATION_COMPLETE );
			
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

			logDebug("LocaleMap: Attaching listenerProxy for creationComplete");
			

			return listenerProxy;
		}
		
		private function removeListenerProxy(eventDispatcher:IEventDispatcher,type:String):void {
			var listenerProxy:ListenerProxy = _listenerProxies[eventDispatcher];
			
			if(listenerProxy && type && (type != "")) {
				listenerProxy.removeListener(type);
				delete _listenerProxies[eventDispatcher];
				logDebug("LocaleMap: Removing listenerProxy for creationComplete");			
			}	
		}
		

		protected function listenForDerivatives(active:Boolean):void {
			// Listen for creation of derivative instances of targets...
			if(includeDerivativesChanged || !active) {
				includeDerivativesChanged = false;
				
				if(includeDerivatives && active) {
					_dispatcher.addEventListener( InjectorEvent.INJECT_DERIVATIVES, onCreationComplete_Derivative, false, 0, true);
					logDebug("LocaleMap: Attaching listener for Derivative creationComplete");
				} else {
					_dispatcher.removeEventListener( InjectorEvent.INJECT_DERIVATIVES, onCreationComplete_Derivative );
					logDebug("LocaleMap: Removing listener for Derivative creationComplete");
				}
			}						
		}
		
		
		// ************************************************************************************************
		//  CreationComplete EventHandlers
		// ************************************************************************************************
		
		/**
		 * Called by the dispacher when the event gets triggered.
		 * This method fires an event announcing that a target instance is READY (creationComplete).
		*/
		protected function onCreationComplete_Target(event:InjectorEvent):void {
			dispatchEvent(new LocaleMapEvent(event.injectorTarget));
			logDebug("LocaleMap: onCreationComplete_Target() for '{0}'",[event.uid]);
		}

		/**
		 * This function is a handler for the injection event, if the target it is a 
		 * derivative class the injection gets triggered
		 */ 
		protected function onCreationComplete_Derivative( event:InjectorEvent ):void
		{
			if( _targets ) {
				for each( var currentTarget:* in _targets) {
					var isDerivative : Boolean = InjectorUtils.isDerivative( event.injectorTarget, currentTarget  );
					
					if( isDerivative == true )   {
						onCreationComplete_Target( event );				
						
						logDebug("LocaleMap: onCreationComplete_Derivative() for '{0}'",[event.uid]);
					}
				}
			}
		}
		
		private function logDebug(format:String,params:Array=null):void {
			//trace(StringUtil.substitute(format,!params ? [] : params));
		}
		
		
		// ************************************************************************************************
		//  Private Attributes
		// ************************************************************************************************
		
		 
		protected var targetsRegistered			:Boolean = false;
		protected var includeDerivativesChanged	:Boolean = false;

		private var _targets					:Array   = [ ];
		private var _includeDerivatives			:Boolean = false;
	
		private var needsInvalidation			:Boolean = false;
		private var isInitialized				:Boolean = false;
		
		private var _dispatcher 				:GlobalDispatcher 	= new GlobalDispatcher();
		private var _listenerProxies			:Dictionary 		= new Dictionary(true);
		
		private namespace self;
	}
}