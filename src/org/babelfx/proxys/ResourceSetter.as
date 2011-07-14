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
package org.babelfx.proxys
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.events.PropertyChangeEvent;
	
	import org.babelfx.interfaces.ITargetInjectable;
	
	[Event(name='propertyChange',type='mx.events.PropertyChangeEvent')]
	
	
	[Event(name="propertyChange",type="flash.events.Event")]
	/**
	 * The ResourcSetter establishes a mapping between a single entry of bundled, localized content and a property(chain) of a single
	 * target instance. This class does not perform the injection nor validate the propertyChain. Rather, this class establishes the 
	 * relationship between resources and runtime targets.
	 * 
	 * The actual target references are managed by the ResourceInjector; which will iterate each instance in its cache, update the 
	 * ResourceSetter::target property, and perform the injection according to the ResourceSetter relationship specifications.
	 * 
	 * This class also supports data binding for the parameters property. Changes to parameters triggers notifications to 
	 * ResourceInjector; which then manually forces an update to the target [ui instance] with the localized parameterized string.
	 * 
	 * 
	 * @author thomasburleson
	 * 
	 */
	public class ResourceSetter extends EventDispatcher implements ITargetInjectable {
		
		// ************************************************************************************************************************
		// Public Properties
		// ************************************************************************************************************************
		
		/**
		 * String name of the compiled, resource property file  
		 */
		public var bundleName  : String = "";
		
		/**
		 * String lookup key for the desired resource content.
		 */
		public var key 		   : String = "";	

		
		/**
		 * Property that will receive the injected, localized resource. Property chains are allowed and will be
		 * dynamically resolved for each instance and for each injection. 
		 */
		public var property    	: String = "";

		

		/**
		 * Unique identifier for instance of target class. Only instances with this ID 
		 * will bre cached and participate in locdaleinjections with locale changes 
		 */
		public var targetID : String = "";
		

		[Bindable(event="propertyChange")]
		/**
		 * Array of values that will be used to build injectable content. Needed with 
		 * the resource has parameterized tokens that will be substituted dynamcially before each injection.
		 * These parameters are used in the mx.utils.StringUtils::substitute(resourec, parameters):String call.
		 * 
		 * Consider the resource property key/value pair: userMenu.currentUser.signedInAs = 'Signed in as {0}'
		 * During injection the above pair will expect parameters = ['Thomas Burleson'], which then results
		 * in runtime substitution === 'Signed in as Thomas Burleson'
		 * 
		 * @code 
		 * 			&lt;tools:ResourceSetter target="{txtWho}"  	
		 * 									property="htmlText" 	
		 * 									key="userMenu.currentUser.signedInAs" 	
		 * 									parameters="{[Model.instance.profile.fullName]}" /&gt;
		 * 
		 */
		public function get parameters():Array {
			return _parameters;
		}
		public function set parameters(value:Array):void {
			if (_parameters != value)
			{
				var prevParams : Array = _parameters;
				_parameters = value;
				
				IEventDispatcher(this).dispatchEvent( PropertyChangeEvent.createUpdateEvent(this,"parameters",prevParams,_parameters) );
			}
		}

		[Bindable("propertyChange")]
		/**
		 * Reference to the current target instance that has been assigned or temporarily JUST injected.
		 * Normally this property is updated by the ResourceInjector for each iteration of instances in
		 * its 'instance' cache.
		 */
		public function get target() : Object { 
			return _target;  	
		} 
		public function set target(src:Object):void {
			if (src != this.target) {
				var oldVal : Object = _target;
				
				if ((targetID != "") && (src != null)) {
					// Should we only support instances with SPECIFIC ids?
					if (src.hasOwnProperty("id") && (src["id"] != targetID)) return;
				}
				
				_target = src;
				IEventDispatcher(this).dispatchEvent( PropertyChangeEvent.createUpdateEvent(this,"target",oldVal,src) );
			}
		}
		
		/**
		 * Dispatcher for viewStateChange events; usually the document of the target instance.
		 * @IEventDispatcher
		 */
		public var trigger 		: Object;
		
		/**
		 * Viewstate that constrains when the injection is allowed. Targets not in this viewState will not be injected.
		 * @defaultValue '' 
		 */
		public var state       	: String = "";		
		
		[Inspectable(enumeration="string,boolean,uint,int,object,array,class",defaultValue="string")]
		public var type        	: String = "string";
		
		
		// ************************************************************************************************************************
		// Constructor
		// ************************************************************************************************************************
		
		/**
		 * Constructor 
		 *  
		 * @param target Object The target instance that has been assigned prior to use with the current injection.
		 * @param property String The target propertychain that should be resolved during injection
		 * @param key String The resource ID in the resource bundle
		 * @param state String The view state in which injection is enabled
		 * @param type String The type of resources that will be accessed by the 'key'
		 * @param parameters Array The runtime values that may be used within parameterized resources
		 * @param bundleName String The name of the resource bundle
		 * 
		 */
		public function ResourceSetter(target		:Object=null, 
									   property		:String="", 
									   key			:String="", 
									   state       	:String="",
									   type			:String="string", 
									   parameters	:Array =null, 
									   bundleName	:String="") {
			this.target     = target;
			this.property    = property;
			this.key         = key;

			this.state       = state;
			this.type        = type.toLowerCase();
			this.parameters  = parameters;
			
			this.bundleName  = bundleName;
		}
		
		
		/**
		 * @private
		 */
		private var _target     : Object = null; 		// destination object that receive injection into property

		
		
		/**
		 * @private 
		 */		
		private var _parameters 	: Array;	}
}