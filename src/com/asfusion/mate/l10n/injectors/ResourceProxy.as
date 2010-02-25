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
package com.asfusion.mate.l10n.injectors
{
	import com.asfusion.mate.injectors.*;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.events.PropertyChangeEvent;
	
	[Event(name='propertyChange',type='mx.events.PropertyChangeEvent')]
	
	/**
	 * Special ResourceMap that supports runtime databinding changes to the paramters property.
	 * Changes to parameters triggers notifications to ResourceInjector; which then manually forces an 
	 * update to the target [ui instance] with the localized parameterized string.
	 * Parameterized property values exmaples include the 
	 * 
	 * @example userMenu.currentUser.signedInAs === 'Signed in as {0}'
	 * 
	 * @code 
	 * 			<tools:ResourceProxy 	target="{txtWho}"  	
	 * 									property="htmlText" 	
	 * 									key="userMenu.currentUser.signedInAs" 	
	 * 									parameters="{[Model.instance.profile.fullName]}" />
	 *  
	 * @author thomasburleson
	 * 
	 */
	public class ResourceProxy extends ResourceMap implements IEventDispatcher, ITargetInjectable {
		
		/**
		 * Unique identifier for instance of target class. Only this instances with the <inst>.id === targetID 
		 * will bre processed/be updated regarding locale changes 
		 */
		public var targetID : String = "";
		
		override public function set trigger(src:Object) : void {
			if (src != this.trigger) {
				
				var oldVal : Object = this.trigger;
				super.trigger = src;
				
				dispatchEvent(PropertyChangeEvent.createUpdateEvent(this,"trigger",oldVal,src));
			}
		}

		override public function set target(src:Object):void {
			if (src != this.target) {
				
				if ((targetID != "") && (src != null)) {
					// Should we only support instances with SPECIFIC ids?
					if (src.hasOwnProperty("id") && (src["id"] != targetID)) return;
				}
				
				var oldVal : Object = this.target;
				super.target = src;
				
				dispatchEvent(PropertyChangeEvent.createUpdateEvent(this,"target",oldVal,src));
			}
		}

		override public function set parameters(src:Array):void {
			if (src != this.parameters) {
				var oldVal : Array = super.parameters;
				super.parameters = src;
				
				dispatchEvent(PropertyChangeEvent.createUpdateEvent(this,"parameters",oldVal,src));
			}
		}

		public function ResourceProxy(	target		:Object=null, 
										property	:String="", 
										key			:String="", 
										state       :String="",
										type		:String="string", 
										parameters	:Array =null, 
										bundleName	:String="") {
											
			super(target,key,property,"", type,parameters,bundleName);
			_evtDispatcher = new EventDispatcher(this);
		}


		// *****************************************************
		// Public Methods for IEventDispatcher Interface
		// *****************************************************
		
        public function addEventListener( type:String,
                                        listener:Function,
                                        useCapture:Boolean = false,
                                        priority:int = 0,
                                        useWeakReference:Boolean = false):void	{	_evtDispatcher.addEventListener( type, listener, useCapture, priority, useWeakReference );		}
        public function removeEventListener( type:String,
                                            listener:Function,
                                            useCapture:Boolean = false ):void	{	_evtDispatcher.removeEventListener( type, listener, useCapture );																											}
        public function dispatchEvent( evt:Event ):Boolean						{	return _evtDispatcher.dispatchEvent( evt );																																																	}
        public function hasEventListener( type:String ):Boolean					{	return _evtDispatcher.hasEventListener( type );																																													}
        public function willTrigger( type:String ):Boolean 						{	return _evtDispatcher.willTrigger( type );																																																	}


		private var _evtDispatcher : IEventDispatcher = null;
	}
}