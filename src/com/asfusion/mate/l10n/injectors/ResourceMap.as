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
	
	
	[ExcludeClass]
	
	/**
	 * Identifies property on target that should be updated by resourceKey value in "bundleName"; when the locale changes.
	 * This class allows target-level mappings so the ResourceInjector can use multiple bundles within any instantiation.
	 *   
	 * @author thomasburleson
	 * 
	 */
	internal class ResourceMap {
		public var bundleName  : String = "";
		public var key 		   : String = "";	// must be unique for any ResourceInjector

		/**
		 * These 3 implicit mutators are required to support 
		 * PropertyChange notifications to ResourceInjectors
		 **/
		public function get target() : Object 		{ return _target;  	} 
		public function set target(src:Object):void { _target = src;	}
		
		public function get trigger() : Object 		 { return _trigger;  	} 
		public function set trigger(src:Object):void { _trigger = src;		}
		
		public function get parameters() : Array 		{ return _parameters;  	} 
		public function set parameters(src:Array):void 	{ _parameters = src;	}

		public var property    : String = "";
		public var state       : String = "";		// view state applicable; default === ""
		public var type        : String = "string";
		
		public function ResourceMap(target:Object, key:String, property:String, state:String="", type:String="string", parameters:Array=null, bundleName:String="") {
			this.bundleName  = bundleName;
			this.key         = key;

			this.target      = target;
			this.property    = property;
			this.state       = state;
			
			this.type        = type.toLowerCase();
			this._parameters = parameters;
		}
		
		private var _target     : Object = null; 		// destination object that receive injection into property
		private var _trigger    : Object = null;		// who will announce state changes; defaults to "target"	
		private var _parameters : Array  = null;		// dynamic values used as part of injection process
	}
}