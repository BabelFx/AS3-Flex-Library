////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.utils
{
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;

	public class BabelFxUtils 
	{
		/**
		 * Generate an accessor function to simplify resource lookups
		 * This hides the `ResourceManager.getInstance()` and snapshots the value
		 * of the property file/`bundle` name and the resource value expected data type
		 * 
		 * @code
		 * 
		 * 	 [BabelFx(event = "BabelFxEvent.LOCALE_CHANGED")]
		 *   public function onLocaleChanged():void 
		 *   {
		 *  	var lookup:Function = BabelFxUtils.getLookup('header');
		 *
         *      btnContinue.label = lookup( model.canContinue ? 'continue' : 'locked');
		 * 		btnContinue.toolTip = model.canContinue ? '' : lookup('whyLockedMsg');
		 * 
		 *      // Use parameters in lookup also...
		 * 
		 *      lblWelcome.label    = lookup ( 'welcomeUser', [this.user.fullName] );
		 *   }
		 * 
		 */
		static public function getLookup( bundle:String, type:String='string' ) : Function 
		{
			/**
			 * Accessor function to easily provide resourceManager lookups for  
			 * multiple keys in the same bundleName.
			 * 
			 * @param key String Identifier for the resource bundle key
			 * @param filter Function used to post process the resource value [Optional]; must return a value:*
			 * @param parameters Array used to provide token values for parameterized string values 
			 * @param scope Context for the `filter` function invocation
			 */
			function accessorFn( key:String, ... rest) : *
			{
				var result : *;
				
				var filter     : Function = getByType(rest, Function ) as Function;
				var parameters : Array    = getByType(rest, Array ) as Array;
				var scope      : Object   = getByType(rest, Object, 2 ) as Object;
				
				var mngr : IResourceManager = ResourceManager.getInstance();
				
				switch( type ) {
					
					case "string"	: result = mngr.getString(bundle,key, parameters);	break;
					case "boolean"	: result = mngr.getBoolean(bundle,key) ;			break;
					case "uint"     : result = mngr.getUint(bundle,key) ;				break;
					case "int"      : result = mngr.getInt(bundle,key) ;				break;
					case "object"   : result = mngr.getObject(bundle,key );				break;
					case "array"    : result = mngr.getStringArray(bundle,key );		break;
					case "class"    : result = mngr.getClass(bundle,key );				break;
				}
				
				return (filter != null) ? filter.call(scope, result) : result;
			}
			
			return accessorFn;
		}
		
		/**
		 * Internal utility method to quickly lookup argument by its class type.
		 * This allows support for javascript-like coding where argument types can be dynamic
		 * using the `... rest` support.
		 * 
		 * @see accessorFn above
		 */
		static protected function getByType(args:Array, type:Class, start:int=0):*
		{
			var result : *;
			
			args ||= [ ];
			
			for (var j:uint=start; j<args.length; j++)
			{
				if (args[j] is type) 
					result = args[j];
			}
			return result;
		}
		
	}
}