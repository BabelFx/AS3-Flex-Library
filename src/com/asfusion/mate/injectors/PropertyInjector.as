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
package com.asfusion.mate.injectors 
{
	import com.asfusion.mate.core.Binder;
	import com.asfusion.mate.utils.InjectorUtils;
	
	import flash.utils.Dictionary;
	
	import mx.core.IMXMLObject;

	/**
	 * PropertyInjector sets a value from an object (source) to a destination (target). 
	 * If the source key is bindable, the PropertyInjector will bind  
	 * the source to the targetKey. Otherwise, it will only set the property once.
	 */
	public class PropertyInjector implements IMXMLObject, com.asfusion.mate.injectors.ITargetInjectable
	{
		
		// ************************************************************************************************************
		//    Public Properties
		// ************************************************************************************************************
		
		/**
		 * Flag that will be used to define the type of binding used by the PropertyInjector tag. 
		 * If softBinding is true, it will use weak references in the binding. Default value is false
		 * 
		 * @default false
		 * */
		public var softBinding:Boolean = false;


		/**
		 * Which "view state" should be used to trigger the injector when paramters, target, or locale changes? 
		 */
		public var state : String = "";
		
		/**
		 * The name of the property on the source object that the injector will use to read and set on the target object
		 * 
		 * @default null
		 * */
		public var sourceKey:String = "";

		/**
		 * 
		 * 
		 * @default null
		 * */
		public function get source():Object {
			return _source;
		}
		public function set source(value:Object):void {
			if (value != _source) {
				_source = value;
				validateNow();
			}
		}
		
		
		/**
		 * The name of the property that the injector will set in the target object
		 * 
		 * @default null
		 * */
		public  var targetID:String = null;

		/**
		 * The name of the property that the injector will set in the target object
		 * 
		 * @default null
		 * */
		public  var targetKey:String = "";
		
		
		/**
		 * An object that contains the data that the injector will use to set the target object
		 * 
		 * @default null
		 * */
		public function get target():Object {
			return _target;
		}
		public function set target(src:Object):void {
			var currentState : String = this.state;
			
			if (src != _target) {
				if (isCurrentState() == true) {
					_target = src;
					validateNow();
				}
			}
			
				function isCurrentState():Boolean {
					var results : Boolean = true;
					if ((src != null) && (state !="")) {
						if (src.hasOwnProperty("currentState")) {
							return (String(src["currentState"]) == currentState);
						}
					}
					
					return results;
				}
		}


		public var id    : String = "";			// useful for MXML tag usages
		public var scope : Object = null;		// used for logging purposes


		// ************************************************************************************************************
		//    Public methods
		// ************************************************************************************************************
		
		public function validateNow():void {
			commitProperties();
		}
		
		public function initialized(document:Object, id:String):void {
			this._owner = document;
			this.id     = id;
			
			validateNow();
		}
	
		// ************************************************************************************************************
		//    Protected methods
		// ************************************************************************************************************
		
		/**
		 * 
		 */
		protected function commitProperties():void {
			if (!target || !source) 					return;
			if ((targetKey=="") || (sourceKey==""))		return;
			
			if(targetID == null || targetID == String(target["id"])) {
				
				// Resolving property chains is possible [in general] since target::creationComplete() is done.
				var resolvedTarget : Object = InjectorUtils.resolveEndPoint(target,targetKey);
				var resolvedKey    : String = InjectorUtils.resolveProperty(targetKey);
				
				if ((resolvedTarget != null) && (resolvedKey != "")) {
					var binder:Binder 	= new Binder( softBinding, scope );
					var done  : Boolean = binder.bind(scope, resolvedTarget, resolvedKey, source, sourceKey);
					
					if ( done == true) {
						// Save to cache xref and set immediate value...
						_bindings[target] = binder;
					}
				}
			}
		}
		
		// ************************************************************************************************************
		//    Private Attributes
		// ************************************************************************************************************

		private var _bindings 	: Dictionary = new Dictionary(true);
		
		private var _source		: Object 	 = null;
		private var _target		: Object	 = null;
		
		private var _owner      : Object     = null;
		
	}
}
