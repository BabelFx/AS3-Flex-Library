////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.utils {

import mx.binding.utils.ChangeWatcher;
import mx.logging.ILogger;

/**
 * Binder is a helper class used to bind properties of two objects
 *
 */
public class Binder
{
	// ****************************************************************************
	// Static Methods 
	// ****************************************************************************
	
	public static function bindProperty( site:Object, prop:String,  host:Object, chain:Object, commitOnly:Boolean = false, useWeakReference:Boolean = true):ChangeWatcher
	{
		function assign(event:*):void {
			site[prop] = w.getValue();
		}
		
		var w:ChangeWatcher =  ChangeWatcher.watch(host, chain, null, commitOnly, useWeakReference);
		
		if (w != null)
		{
			w.setHandler(assign);
			assign(null);
		}
		
		return w;
	}
	
	// ****************************************************************************
	// Public Properties
	// ****************************************************************************

	public var logger : ILogger;

	// ****************************************************************************
	// Constructor
	// ****************************************************************************


	public function Binder( logger:ILogger=null )
	{
		this.logger = logger;	// logging purposes
	}


	// ****************************************************************************
	// Public Methods
	// ****************************************************************************


	/**
	 * Watch the source object's property(s) and invoke callback whenever a change is detected.
	 * 
	 */
	public function bindCallback(source:Object, propertyChain:String, callback:Function, commitOnly:Boolean = false, useWeakReference:Boolean = false):Binder
	{
		unbind();
		_watcher = canWatch(source,propertyChain) ? ChangeWatcher.watch(source, propertyChain.split("."), callback, commitOnly, useWeakReference) : null;
		
		return this;
	}
	
	
	/**
	 * The function that implements the binding between two objects.
	 */
	public function bind(source:Object, sourceKey:String, target:Object, targetKey:String):Binder
    {
		if(target && targetKey && source && sourceKey)
		{
			var multipleLevels : int    = sourceKey.indexOf(".");
			var chainSourceKey : Object = (multipleLevels > 0) ? sourceKey.split(".") : sourceKey;
			var data           : Object = null;

			try
			{
				
				_watcher = canWatch(source,sourceKey) ? bindProperty(target, targetKey, source, chainSourceKey) : null;
			}
			catch(error:ReferenceError) {
				data = {target:target, targetKey:targetKey};
				logError(CANNOT_BIND, error, source, sourceKey, data);
			}
			catch(error:TypeError) {
				data = {target:target, targetKey:targetKey, source:source, sourceKey:sourceKey};
				logError(PROPERTY_TYPE_ERROR, error, source, sourceKey, data);
			}

		} else {

			if(!targetKey)			logError(TARGET_KEY_UNDEFINED);
			else if(!target)		logError(TARGET_UNDEFINED);
			else if(!source)		logError(SOURCE_UNDEFINED);

		}

		return this;
	}
	
	
	public function unbind():void 
	{
		if (_watcher) _watcher.unwatch();
		_watcher = null;
	}

	

	/**
	 * Check if the source property chain is bindable, if the chain path is more than one level deep;
	 * then it is a "property chain" that must be split by the '.' delimiters. 
	 * 
	 * if (source == "networkModel.topology.state.layout") then 
	 *     source    			== networkModel
	 *     sourcePropertyChain  == [ 'topology', 'state', 'layout' ]
	 *  
	 * @param injectTag
	 * 
	 * @return Boolean true if the full property chain is bindable 
	 * 
	 */
	public function canWatch(source:Object, property:String ):Boolean {
		var results     : Boolean = true;
		
		if (source && (property != ""))
		{
			var sourceChain	: Array  = property.split('.');
			var path        : String = sourceChain[0];
			var name		: String = sourceChain[0];
			
			// Deepscan to check all paths of source chain for bindability
			for each (var property:String in sourceChain.slice( 0 )) {
				if (source && source.hasOwnProperty(property)) {
					
					// Descend down the source chain to the next level
					if (ChangeWatcher.canWatch(source, property)) {
						
						source  = source[property];
						name    = property;
						path   += "." + property;
						
					} else {
						logger && logger.debug( "Binder::canWatch() {0}.{1} is not bindable!", name, property);	
						results = false;
						
						break;							
					}
					
				} else {
					logger && logger.warn( "Binder::canWatch() {0}.{1} is null! Unable to determine if {2} is fully bindable!", path, property, source);							
					break;
				}					
			}
		}
		
		return results; 
	}
	
	

	
	// ****************************************************************************
	// Private Error logging
	// ****************************************************************************

    private function logError(	errorCode	:String,
    							error		:Error	=null,
    							source		:*		=null,
    							sourceKey	:String	=null,
    							data		:Object	=null) : void {

    	if ( logger ) logger.error( errorCode );
    }

	// ****************************************************************************
	// Private Properties
	// ****************************************************************************
	
	private var _watcher : ChangeWatcher;
	
	
    static 	private 	const PROPERTY_NOT_FOUND:String 	= "Property not found";
    static 	private 	const PROPERTY_TYPE_ERROR:String 	= "Property type mismatch";

    static 	private 	const TARGET_KEY_UNDEFINED:String   = "TargetKey undefined";
    static 	private 	const TARGET_UNDEFINED:String 	    = "Target undefined";
    static 	private 	const SOURCE_UNDEFINED:String 	    = "Source undefined";
    static 	private 	const SOURCE_NULL:String 	        = "Source null";

    static 	private 	const CANNOT_BIND:String 			= "Cannot bind";
    static 	private 	const NOT_BINDING:String 		    = "Not binding";

}
}
