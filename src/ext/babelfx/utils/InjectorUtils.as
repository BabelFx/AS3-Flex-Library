////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.utils
{
	import com.codecatalyst.util.NumberUtil;
	
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.IList;
	import mx.core.UIComponent;
	
	public class InjectorUtils
	{
		/**
		 * Scan up the target hierarchy for any `states` information
		 * 
		 */  
		static public function scanForTrigger( target:Object ):IEventDispatcher 
		{
			var results :IEventDispatcher = null;
			
			if (target && target is UIComponent) 
			{
				var ui : UIComponent = target as UIComponent;
				
				results = (ui.states.length > 0) ? ui : scanForTrigger(ui.parent);
			}
			
			return results;
		}
		
		
	   	 /**
	   	  * Determine the object endpoint based on target and property values
	   	  * e.g.    target="{healthCare}"  property="pnlQualification.txtSummary.text"
	   	  *         object endpoint is healthCare.pnlQualification.txtSummary === txtSummary
		  * e.g.    property="dataProvider[0].user.lastName"
		  * 
	   	  * @param target	Object instance
	   	  * @param chain    Property or Property chain in target instance
	   	  *  
	   	  * @return Object 	Reference to object instance whose property will be modified.
	   	  * 
	   	  */
	   	 static public function resolveEndPoint(target:Object, chain:String):Object 
		 {
	   	 	var results : Object = target;
	   	 	
	   	 	if ( target != null ) 
			{
		   	 	var nodes : Array  = chain.split(".");
		   	 	if (nodes && nodes.length > 1) 
				{
		   	 		// Scan all nodes EXCEPT the last (which should be the "true" property endPoint
					
		   	 		for (var i:int=0; i<nodes.length-1; i++) 
					{
		   	 			// Is this a standard or "indexed" node; 
		   	 			// eg    frmRegister.registrationValidators[0].requiredFieldError has node 
		   	 			//       'registrationValidators' as an indexed node
						
		   	 			var pattern : RegExp = /(.+)\[(.+)]/;
		   	 			var matches : Array  = String(nodes[i]).match(pattern);
		   	 			var node    : String = (matches && (matches.length > 2)) ? matches[1] 		: nodes[i];
		   	 			var j       : int    = (matches && (matches.length > 2)) ? int(matches[2]) 	: -1; 
		   	 			
		   	 			if ( results.hasOwnProperty(node) ) 
						{
		   	 				results = results[node];
							
							// Does the chain include a array indexing notation; e.g. dataProvide[3]
							
							if ( (j >= -1) && NumberUtil.isWholeNumber(j) )
							{
								// Add support for IList, Array, or Map
								
								if ( results is IList )
								{
									results = (results as IList).getItemAt( j ) as Object;
									
								} else if ( results is Array ) {
									
									results = (results as Array)[j];
									
								} else {
									
									results = results[j];
								}
							}
							
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
		  * by accessing the last segment of the chain.
		  * 
	   	  * e.g.    "lblButton.label" --> resolved property === "label"
	   	  *  
	   	  * @param map 		Current property chain 
	   	  * @return String 	Property key in the "endPoint" target
	   	  * 
	   	  */
	   	 static public function resolveProperty(chain:String):String 
		 {
	   	 	var results : String = chain;
			
	   	 	if (results != "") 
			{
		   	 	var nodes : Array  = chain.split(".");
		   	 	if ( nodes && (nodes.length>0) ) 
				{
		   	 		results = nodes[ nodes.length-1 ];
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