////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.injectors
{
	import ext.babelfx.proxys.ResourceSetter;
	import ext.babelfx.utils.InjectorUtils;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.IMXMLObject;
	import mx.core.UIComponent;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.styles.IStyleClient;
	
	import org.swizframework.utils.logging.SwizLogger;
	
	import utils.string.supplant;
	
		
	[ExcludeClass]
	
	public class AbstractInjector extends EventDispatcher implements IMXMLObject {
		
		// *********************************************************************************
		//  Public Properties 
		// *********************************************************************************		
		
		public var logger	  : SwizLogger;
		public var id         : String;
		public var bundleName : String; 
		
		public function get resourceManager():IResourceManager
		{
			return _resourceManager;
		}

		// *********************************************************************************
		//  Public Constructor 
		// *********************************************************************************
		
		/**
		 * Public constructor 
		 *  
		 * @param bundleName
		 * 
		 */
		public function AbstractInjector( bundleName:String=null, localeManager:IResourceManager=null)  
		{  
			this.bundleName     = bundleName;
			_resourceManager 	= !localeManager ? ResourceManager.getInstance() : localeManager;
		}  
		
		// *********************************************************************************
		//  IMXMLObject Interface 
		// *********************************************************************************
		
		/**
		 * Method is auto-invoked during MXML initialization. Note: if a ResourceInjector instance
		 * was programmatically instantiated (not as a tag), then this method is never called.
		 * 
		 * @param document	Owner for this tag instance
		 * @param id       Reference for this tag instances
		 * 
		 */
		public function initialized(document:Object, id:String):void
		{
			this.id = id;
			_owner  = document as IEventDispatcher;
		} 
							
		// *********************************************************************************
		//  Proxy Methods
		// *********************************************************************************
		

		/**
		 * Core method that injections the current locale value into the property of the
		 * specified target. This method also confirms state values [if specified].
		 * 
		 * NOTE: the ResourceSetter::bundleName has precedence over the ResourceInjector::bundleName.
		 * 
		 */
		public function assignResourceValues(target:Object, map:ResourceSetter):void {
			var bundle : String = map.bundleName || this.bundleName;
			
			if (bundle && (bundle != "")) 
			{
				var endPoint : Object   = resolveEndPoint(target, map);
				var property : String   = resolveProperty( map );
				var inject   : Function = assignKeyValue( endPoint, property, map, target );
				
				if ( isResolvedValid( endPoint,property ) != true ) 
				{
					logError( target, map, ERROR_UNKNOWN_PROPERTY );
					
				} else if ( isValidTargetState(target, map) ) {
					
					switch( map.type ) {
						
						case "string"	: inject( _resourceManager.getString(bundle,map.key, map.evaluateParameters(target) ));		break;
						case "boolean"	: inject( _resourceManager.getBoolean(bundle,map.key) );					break;
						case "uint"     : inject( _resourceManager.getUint(bundle,map.key) );						break;
						case "int"      : inject( _resourceManager.getInt(bundle,map.key) );						break;
						case "object"   : inject( _resourceManager.getObject(bundle,map.key) );						break;
						case "array"    : inject( _resourceManager.getStringArray(bundle,map.key) );				break;
						case "class"    : inject( _resourceManager.getClass(bundle,map.key) );						break;
						
						default         : logError(target, map,ERROR_UNKNOWN_DATATYPE);								break;
					}
				}
				
			} else {
				
				logError( target, map, ERROR_UNKNOWN_BUNDLE );
			}
		}
		
		
		// *********************************************************************************
		//  Protected Methods
		// *********************************************************************************
		
		
		/**
		 * Build curried function that pre-captures the target and property information
		 * @return Function
		 */
		protected function assignKeyValue( endPoint:Object, property:*, map:ResourceSetter, target:Object ):Function 
		{
			var id : String = this.id;
			/**
			 * Injection function uses closure to access captured `endPoint` and `property` values
			 */
			function injectFn( val:* ):void 
			{
				if (val == null) {
					logError(endPoint, map, ERROR_KEY_VALUE_MISSING);
				} else {
					
					logger.debug( supplant("ResourceInjector[{0}] ::: inject( ui=`{1}` property=`{2}` value=`{3}` state=`{4}` )", [ id, getQualifiedClassName(target), map.property, val, map.state || ""  ] ));
					
					if (endPoint.hasOwnProperty(property) == true) 	{
						// The endPoint property could be a function...
						try {
							var accessor : Function = endPoint[property] as Function;
						} catch (e:Error) { 
							// do nothing...
						}
						
						if (accessor != null)  accessor.apply(endPoint,[val]);
						else					 endPoint[property] = val;
						
					}
					else if (endPoint is IStyleClient) {
						// If not a property or a setter, then check if a style should be applied
						(endPoint as IStyleClient).setStyle(property,val);
					}
					
				}
			}
			
			return injectFn;
		}
		
		private function isResolvedValid( target:Object, property:String ):Boolean 
		{
			var results : Boolean = (target != null) 		&&
									(property != "") 		&&
									(target.hasOwnProperty(property) == true);
			
			// If the ui does not have a standard property, then is
			// the property actually a styling key?
			
			if ( !results && (target is UIComponent)) 
			{
				// Is the property a "style" key?
				results = UIComponent(target).getStyle(property) != null;
			} 
			
			return results; 	  
		}
		
		private function isValidTargetState(target:Object, map:ResourceSetter):Boolean {
			var results 	 : Boolean = true;
			
			if ( map.state ) 
			{
				var ui : UIComponent = InjectorUtils.scanForTrigger( target ) as UIComponent;
				results = ui ? (ui.currentState == map.state) : false;
			}
			
			return results;
		}
		
		
		/**
		 * Determine the object endpoint based on target and property values
		 * e.g.    target="{healthCare}"  property="pnlQualification.txtSummary.text"
		 *         object endpoint is healthCare.pnlQualification.txtSummary === txtSummary
		 * 
		 * @param map 		Current ResourceMap registry entry 
		 * @return Object 	Reference to object instance whose property will be modified.
		 * 
		 */
		private function resolveEndPoint(target:Object, map:ResourceSetter):Object {	   	 
			var results : Object = null;
			
			try {
				results = InjectorUtils.resolveEndPoint(target, map.property);
			} catch (e:Error) {
				logError(target, map,ERROR_UNKNOWN_NODE,e.message);
			}
			
			return results;
		}
		
		/**
		 * Determine the "true" property to modify in the target endpoint
		 * e.g.    "lblButton.label" --> resolved property === "label"
		 *  
		 * @param map 		Current ResourceMap registry entry 
		 * @return String 	Property key in the "endPoint" target
		 * 
		 */
		private function resolveProperty(map:ResourceSetter):String {
			return InjectorUtils.resolveProperty(map.property);
		}
		
		private function logError(target:Object, map:ResourceSetter,errorType:String,node:String=null ):void 
		{
			var targetID : String = getTargetIdentifier( target );
			var details  : String = "";
			
			switch(errorType) {
				case ERROR_UNKNOWN_PROPERTY : 
				{
					details = supplant(errorType, [targetID, map.property, 	map.key	 ]);		
					logger.warn(details);
					break;
				}
				case ERROR_UNKNOWN_DATATYPE : {
					details = supplant(errorType, [map.type, map.key, 		targetID, 	map.property]);
					logger.error(details);
					break;	
				}
				case ERROR_UNKNOWN_NODE     : 
				{
					details = supplant(errorType, [targetID, map.property, 	map.key, 	node        ]);
					logger.warn(details);
					break;	
				}
				case ERROR_UNKNOWN_BUNDLE   : 
				{
					details = supplant(errorType, [targetID                                          ]);
					logger.error(details);
					break;
				}
				case ERROR_KEY_VALUE_MISSING: 
				{
					details = supplant(errorType, [ map.bundleName,	map.key						]);
					logger.error(details);
					break;
				}
			}
			
			function getTargetIdentifier(inst:Object):String {
				var results : String = (inst != null) ? getQualifiedClassName( inst ) : "<???>";
				
				if (inst && inst.hasOwnProperty("id")) {
					results = (inst["id"] != null) ? inst["id"] : results;
				}
				
				return results;
			}
		}
		
		private static const ERROR_UNKNOWN_PROPERTY : String = "-> Target {0}['{1}'] is unknown for resource key '{2}'.";
		private static const ERROR_UNKNOWN_DATATYPE : String = "-> Unknown data type {0} when mapping resource key '{1}' to {2}[{3}].";
		private static const ERROR_UNKNOWN_NODE     : String = "-> Unresolved node '{3}' in property {0}[{1}] for resource key '{2}'.";
		private static const ERROR_UNKNOWN_BUNDLE   : String = "-> Unknown or unspecified bundlename for target '{0}'!";
		private static const ERROR_KEY_VALUE_MISSING: String = "-> Property bundle '{0}' does not have the resource key '{1}'!";
		
		private var _owner           : IEventDispatcher = null;
		private var _resourceManager : IResourceManager = null;
		
	}
}

