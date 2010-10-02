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
package com.mindspace.l10n.utils
{
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.UIDUtil;
	
	public class InjectorUtils
	{
		
		//.........................................isDerivative..........................................
		/**
		 * Check if the current object is a derivative class and return a boolean value
		 * true / false.
		 */
		 static public function isDerivative( injectorTarget:Object, targetClass:* ):Boolean {
		 	var foundDerivative:Boolean = false;
		 	
		 	if( targetClass && injectorTarget ) {
		 	
			 	var compareClass:Class = ( targetClass is Class ) ? targetClass : getDefinitionByName( targetClass ) as Class;
			 	if(compareClass!=null && (injectorTarget is compareClass))
			 	{
					// So is in the inheritance scope... but is it the SAME class?
			 		var targetClassName:String = getClazzName( injectorTarget as Class );
			 		var compareClassName:String = getClazzName( compareClass );
					
			 		foundDerivative = ( targetClassName != compareClassName );
			 	}
			}
		 
		 	return foundDerivative;
		 }
		 
		 static public function isSameClass(injectorTarget:Class, targetClass:Class):Boolean {
		 	var results : Boolean = false;
			
			
			 	if( injectorTarget!=null && targetClass!=null )
			 	{
			 		var injectorClassName :String = getClazzName( injectorTarget );
			 		var targetClassName   :String = getClazzName( targetClass );
					
			 		results = ( injectorClassName == targetClassName );
			 	}
				
		 	return results;
		 }

		
		 
	   	 /**
	   	  * Determine the object endpoint based on target and property values
	   	  * e.g.    target="{healthCare}"  property="pnlQualification.txtSummary.text"
	   	  *         object endpoint is healthCare.pnlQualification.txtSummary === txtSummary
	   	  * 
	   	  * @param target	Object instance
	   	  * @param chain    Property or Property chain in target instance
	   	  *  
	   	  * @return Object 	Reference to object instance whose property will be modified.
	   	  * 
	   	  */
	   	 static public function resolveEndPoint(target:Object, chain:String):Object {
	   	 	var results : Object = target;
	   	 	
	   	 	if (results != null) {
		   	 	var nodes : Array  = chain.split(".");
		   	 	if (nodes && nodes.length > 1) {
		   	 		// Scan all nodes EXCEPT the last (which should be the "true" property endPoint
		   	 		for (var i:int=0; i<nodes.length-1; i++) {
		   	 			
		   	 			// Is this a standard or "indexed" node; 
		   	 			// eg    frmRegister.registrationValidators[0].requiredFieldError has node 
		   	 			//       'registrationValidators' as an indexed node
		   	 			var pattern : RegExp = /(.+)\[(.+)]/;
		   	 			var matches : Array  = String(nodes[i]).match(pattern);
		   	 			var node    : String = (matches && (matches.length > 2)) ? matches[1] 		: nodes[i];
		   	 			var j       : int    = (matches && (matches.length > 2)) ? int(matches[2]) 	: -1; 
		   	 			
		   	 			if (results.hasOwnProperty(node)) {
		   	 				results = (j == -1) ? results[node] : results[node][j];
		   	 				continue;
		   	 			} else {
		   	 				throw new Error(node);
		   	 			} 
		   	 			
		   	 			
		   	 			// The scope chain is not valid. This is an UNEXPECTED condition
		   	 			if (results == null) throw new Error(node);
		   	 		}
		   	 	}
		   	 }
		   	 
		   	 return results;
	   	 }
	   	 
	   	 /**
	   	  * Determine the "true" property to modify in the target endpoint
	   	  * e.g.    "lblButton.label" --> resolved property === "label"
	   	  *  
	   	  * @param map 		Current property chain 
	   	  * @return String 	Property key in the "endPoint" target
	   	  * 
	   	  */
	   	 static public function resolveProperty(chain:String):String {
	   	 	var results : String = chain;
	   	 	if (results != "") {
		   	 	var nodes : Array  = chain.split(".");
		   	 	if (nodes && (nodes.length>0)) {
		   	 		results = nodes[nodes.length-1];
		   	 	}
	   	 	}
	   	 	
	   	 	return results;
	   	 }

		static private const _lookups : Dictionary = new Dictionary(true);
		
		static private function getClazzName(clazz:Class):String {
			var results : String = _lookups[clazz] as String;
			if (results == null) {
				results = getQualifiedClassName(clazz);
				_lookups[clazz] = results;
			}
			return results;
		}

	}
}