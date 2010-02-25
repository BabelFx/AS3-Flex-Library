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

	[Event(name='targetReady',type='com.asfusion.mate.l10n.maps.LocaleMapEvent')]
	
	public class LocaleMap extends AbstractMap 
	{
		//.........................................targets..........................................
		private var _targets:Array = [];
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
			
	        if (oldValue !== newValue)
	        {
	        	if(targetsRegistered) unregisterAll();
	        	
	        	_targets = newValue;
	        	validateNow()
	        }
		}

		public function register(target:Class):void {
			if (!alreadyRegistered(target)) {
				this.targets = [target].concat(this.targets);
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

		//.........................................includeDerivatives..........................................
		private var _includeDerivatives:Boolean = false;
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


		/*-.........................................invalidateProperties..........................................*/
		private var needsInvalidation:Boolean;
		/**
		*  @inheritDoc
		*/
		public function invalidateProperties():void
		{
			if( !isInitialized ) needsInvalidation = true;
			else commitProperties();
		}
		


		override public function initialized(document:Object, id:String):void {
			super.initialized(document,id);

			if( needsInvalidation )
			{
				commitProperties();
				needsInvalidation = false;
			}			
		}

		/*-.........................................validateNow..........................................*/
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
		protected function commitProperties():void
		{
			if(!_dispatcher) return;
			
			if(!targetsRegistered && _targets) {
				for each( var currentTarget:* in _targets)
				{
					var currentType:String = ( currentTarget is Class) ? getQualifiedClassName( currentTarget ) : currentTarget;
					_dispatcher.addEventListener( currentType, fireEvent, false, 0, true);
				}
				targetsRegistered = true;
			}
			
			if(_targets.length>0) 
			{
				addListenerProxy( _dispatcher );
				if(includeDerivativesChanged)
				{
					includeDerivativesChanged = false;
					if(includeDerivatives)
					{
						_dispatcher.addEventListener( InjectorEvent.INJECT_DERIVATIVES, injectDerivativesHandler, false, 0, true);
					}
					else
					{
						_dispatcher.removeEventListener( InjectorEvent.INJECT_DERIVATIVES, injectDerivativesHandler );
					}
				}
			}
		}


		protected function addListenerProxy(eventDispatcher:IEventDispatcher, type:String = null):ListenerProxy
		{
			var listenerProxy:ListenerProxy = _listenerProxies[eventDispatcher];
			
			if(listenerProxy == null)
			{
				listenerProxy = new ListenerProxy(eventDispatcher);
				_listenerProxies[eventDispatcher] = listenerProxy;
			}
			
			listenerProxy.addListener((type == null) ? "creationComplete" : type, 
									  (type == null) ? this 			  : null );

			return listenerProxy;
		}
		

		//.........................................fireEvent..........................................
		/**
		 * Called by the dispacher when the event gets triggered.
		 * This method fires an event announcing that a target instance is READY (creationComplete).
		*/
		protected function fireEvent(event:InjectorEvent):void {
			dispatchEvent(new LocaleMapEvent(event.injectorTarget));
		}
		
		//.........................................unregisterAll..........................................
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
					_dispatcher.removeEventListener(currentType, fireEvent);
				}
				targetsRegistered = false;
			}
		}
		
		//.........................................injectDerivativesHandler..........................................
		/**
		 * This function is a handler for the injection event, if the target it is a 
		 * derivative class the injection gets triggered
		 */ 
		protected function injectDerivativesHandler( event:InjectorEvent ):void
		{
			if( _targets )
			{
				for each( var currentTarget:* in _targets)
				{
					if( InjectorUtils.isDerivative( event.injectorTarget, currentTarget  ) )
					{
						fireEvent( event );
					}
				}
			}
		}
		
		 
		/**
		 * Flag indicating if this <code>InjectorHandlers</code> is registered to listen to a target list or not.
		 */
		protected var targetsRegistered:Boolean;
		
		/**
		 * Flag indicating if the includeDerivatives property has been changed.
		 */
		protected var includeDerivativesChanged:Boolean;

		/*-.........................................initialized..........................................*/
		private var isInitialized:Boolean;
		

		private var _dispatcher 	: GlobalDispatcher 	= new GlobalDispatcher();
		private var _listenerProxies: Dictionary 		= new Dictionary(true);
		
		private namespace self;
	}
}