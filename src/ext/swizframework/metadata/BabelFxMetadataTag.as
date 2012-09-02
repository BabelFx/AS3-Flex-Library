////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////


package ext.swizframework.metadata
{
	import org.swizframework.reflection.BaseMetadataTag;
	import org.swizframework.reflection.IMetadataTag;
	
	public class BabelFxMetadataTag extends BaseMetadataTag
	{
		
		// ========================================
		// public properties
		// ========================================
		
		
		/**
		 * Name of property or property path used to
		 * as the injection destination for the localized content.
		 *
		 * @return String
		 *
		 */
		public function get property():String
		{
			return _property;
		}
		
		
		/**
		 * Name of the resourcebundle key whose value is the localized
		 * content that will be injected into the target property.
		 */
		public function get key():String
		{
			return _key;
		}
		
		/**
		 * Name of viewState in which injection should occur for this tag
		 */
		public function get state():String 
		{
			return _state;
		}
		
		/**
		 * Type of localized content to be injected.
		 * Values = string,boolean,uint,int,object,array,class"
		 * 
		 * @defaultValue 'string'
		 */
		public function get type():String
		{
			return _type;
		}

		/**
		 * Name of resource bundle containing keys for the specified injection
		 *
		 * @return String
		 *
		 */
		public function get bundle():String
		{
			return _bundle;
		}
		
		/**
		 * Name of property, accessor, or function used to determine array
		 * of runtime parameters used as tokenized parameter values with the localized
		 * content.
		 */
		public function get parameters():String 
		{
			return _params;
		}
		
		
		// **********************************************************
		// Properties associated with changes to targets
		// **********************************************************
		
		/**
		 * Name of function to call after the locale has changed AND the ResourceInject
		 * has fired for all the resource setter(s).
		 */
		public function get eventHandler():String {
			return _eventHandler;
		}
		
		/**
		 * Returns event attribute of [BabelFx(event="")] tag.
		 */
		public function get event():String {
			return _event;
		}
		
		
		// ========================================
		// constructor
		// ========================================
		
		public function BabelFxMetadataTag()
		{
			super();
			
			defaultArgName = "bundle";
		}
		
		// ========================================
		// public methods
		// ========================================
		
		override public function copyFrom(metadataTag:IMetadataTag) : void
		{
			super.copyFrom( metadataTag );
			
			if (hasArg("property"))    	_property 	= getArg("property").value;
			if (hasArg("key"))    		_key 		= getArg("key").value;
			if (hasArg("parameters"))   _params 	= getArg("parameters").value;
			
			// Support `state` or `viewState` attribute 
			
			if (hasArg("viewState"))	_state	 	= getArg("viewState").value;
			if (hasArg("state"))    	_state	 	= getArg("state").value;
			
			// XML attributes of `type` are not valid; use `content` or `clazz`
			
			if (hasArg("clazz"))      	_type       = getArg("clazz").value;
			if (hasArg("content"))      _type       = getArg("content").value;
			if (hasArg("type"))    		_type 		= getArg("type").value;
			
			// Support `bundle` or `bundleName` attribute 

			if (hasArg("bundle"))    	_bundle 	= getArg("bundle").value;
			if (hasArg("bundleName"))   _bundle     = getArg("bundleName").value;
			
			// Support `change` attribute 
			
			if (hasArg("handler"))       _eventHandler  = getArg("handler").value;
			if (hasArg("eventHandler"))  _eventHandler 	= getArg("eventHandler").value;
			
			if (hasArg("event"))    	_event 		= getArg("event").value;
		}

		
		// ========================================
		// protected properties
		// ========================================
		
		protected var _bundle	:String; 
		protected var _property	:String;
		protected var _key		:String;
		protected var _type		:String = "string";
		protected var _params	:String; 
		protected var _state    :String;
		
		protected var _eventHandler   :String;
		protected var _event    :String;
		
	}
}
