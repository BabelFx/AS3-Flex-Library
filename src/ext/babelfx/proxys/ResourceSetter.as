////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.proxys
{
	import com.codecatalyst.util.PropertyUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.events.PropertyChangeEvent;
	
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
	public class ResourceSetter extends EventDispatcher  {
		
		// ************************************************************************************************************************
		// Public Properties
		// ************************************************************************************************************************
		
		/**
		 * String name of the compiled, resource property file  
		 */
		public var bundleName  : String;
		
		/**
		 * String lookup key for the desired resource content.
		 */
		public var key 		   : String;	

		
		/**
		 * Property that will receive the injected, localized resource. Property chains are allowed and will be
		 * dynamically resolved for each instance and for each injection. 
		 */
		public var property    	: String;

		
		/**
		 * Simply accessor to quick-check presence of parameters;
		 * which will be used in tokenized string injections
		 * 
		 */
		public function get hasParameters():Boolean
		{
			return (_parameters && _parameters.length > 0);
		}
		
		
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
				
				IEventDispatcher(this).dispatchEvent( PropertyChangeEvent.createUpdateEvent( this, "parameters", prevParams, _parameters ) );
			}
		}
		
		/**
		 * For the array of parameters, evaluate the runtime values for each parameter within 
		 * the specified target instance.
		 *  
		 * NOTE: the AbstractInjector::assignResourceValues() invokes this method.
		 */
		public function evaluateParameters( instance : Object ):Array {
			var keys   : Array = parameters || [ ];
			var values : Array = [ ];
			
			if ( instance )
			{
				for (var j:uint=0; j<keys.length; j++)
				{
					values.push( PropertyUtil.getObjectPropertyValue( instance, keys[j], "" ) );					
				}
			}
			
			return values.length > 0 ? values : null;
		}
		
		/**
		 * Viewstate that constrains when the injection is allowed. Targets not in this viewState will not be injected.
		 * @defaultValue '' 
		 */
		public var state       	: String;		
		
		[Inspectable(enumeration="string,boolean,uint,int,object,array,class",defaultValue="string")]
		public var type        	: String = "string";
		
		
		
		/**
		 * Name of the function that should be called after the locale changes and the injections are finished.
		 */
		public var eventHandler  : String;
		
		
		/**
		 * Type of event that is authorized to invoke the eventHandler. If null, then any event will invoke the handler
		 */
		public var filter : String;
		
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
		public function ResourceSetter(property		:String=null, 
									   key			:String=null, 
									   state       	:String=null,
									   type			:String="string", 
									   parameters	:Array =null, 
									   bundleName	:String=null) {
			this.property    = property;
			this.key         = key;

			this.state       = state;
			this.type        = type.toLowerCase();
			this.parameters  = parameters;
			
			this.bundleName  = bundleName;
		}
		
		/**
		 * Initialize instance based on properties of `data` object
		 */
		public function init(data:Object):ResourceSetter 
		{
				function keyValue(key:String,defaultVal:*=""):* 
				{
					var result : * = defaultVal;
					if (data && data.hasOwnProperty(key)) {
						result = data[key];
					}
					return result;
				}
			
			this.property	 = keyValue("property", keyValue("uiKey", 		null) );
			this.key		 = keyValue("key",		keyValue("resourceKey", null) )
			this.type		 = keyValue("type", 	keyValue("uiType",		"string") );

			this.state       = keyValue("state",null);
			this.bundleName	 = keyValue("bundle",	keyValue("bundleName", 	null) );
			this.eventHandler= keyValue("change",   keyValue("eventHandler", null) );
			
			var params : String = keyValue("parameters","") || "";
			    params = params.replace(" ","");
				
			this.parameters	 = (params != "") ? params.split(",") : null;
				
			return this;
		}
		
		/**
		 * @private 
		 */		
		private var _parameters 	: Array;	
	}
}