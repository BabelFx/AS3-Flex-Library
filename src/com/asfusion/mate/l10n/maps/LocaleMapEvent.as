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
	import flash.events.Event;

	public class LocaleMapEvent extends Event
	{	
		public static const TARGET_READY  :String = "targetReady";

		public var targetInst : Object = null;
		
		public function LocaleMapEvent(targetInst:Object)
		{
			super(TARGET_READY,false,false);
			this.targetInst = targetInst; 
		}
		
	}
}