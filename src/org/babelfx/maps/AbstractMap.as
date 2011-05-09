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

package org.babelfx.maps
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.core.IMXMLObject;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;

	[ExcludeClass]
	
	public class AbstractMap extends EventDispatcher implements IMXMLObject
	{
		public var id : String = "";
		
		public function AbstractMap(target:IEventDispatcher=null) {
			super(target);
		}
		
		public function initialized(document:Object, id:String):void {
	   	 	this.id = id;
	   	 	
	   	 	// Make sure the owner has finished creating all children to insure that calls to the 'function set registry()' 
	   	 	// is performed with values that are initialized properly in the owner.
	   	 	_owner = document as UIComponent;
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this,"owner",null,_owner));
		}
		
		[Bindable("propertyChange")]
		public function get owner():UIComponent {
			return _owner;
		}
		private var _owner : UIComponent = null;
		
	}
}