////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2009 Farata Systems LLC
//  All Rights Reserved.
//
//  NOTICE: Farata Systems permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package com.mindspace.l10n.utils.factory {
	/**
	 *  UIStaticClassFactory is an implementation of the Class Factory design pattern
	 *  for dynamic creaion of UI components. It allows dynamic passing of the 
	 *  propeties, styles and event listeners during the object creation.
	 *  It's implemented as a wrapper for mx.core.ClassFactory and can 
	 *  be used as a class factory not just for classes, but for functions
	 *  and even strings.    
	 *  
	 *  @see mx.core.IFactory
	 */
	
	import flash.events.IEventDispatcher;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	
	import mx.core.ClassFactory;
	import mx.core.IFactory;
	import mx.logging.ILogger;
	import mx.logging.Log;


	public class StaticClassFactory implements IFactory{
		
		/**
		 * Styles for the UI object to be created 
		 */
		public var styles:Object;
		
		/**
		 * Event Listeners for the Class instance to be created 
		 */
		public var eventListeners:Object;
		
					
		private static const logger:ILogger = 
						Log.getLogger ("com.farata.core.UIStaticCassFactory");
		
		/**
		 * Mutators so MXML tag instantiation can be used with a properties="" attribute
		 *  
		 * @param v Object of property key/value pairs
		 */
		public function set properties(v:Object):void	{
			if (_wrappedClassFactory == null) _wrappedClassFactory = new ClassFactory(Object);
			_wrappedClassFactory.properties = v;
		}
		public function get properties():* {
			return _wrappedClassFactory ? _wrappedClassFactory.properties : null;
		}
				
		
		/**
		 * Accessor for nesting StaticClassFactories
		 *  
		 * @return ClassFactory wrapper
		 */
		public function get wrappedClassFactory():ClassFactory {
			return _wrappedClassFactory;
		}
		
		
		public function get source():Class {
			return _wrappedClassFactory.generator;
		}
		/**
		 * Mutator for use by constructor and useful as MXML tag attribute;
		 * e.g.  generator="{new TraceTarget()}"
		 *  
		 * @param cf Class, Function, ClassFactory, or String 
		 */
		public function set generator(cf:*):void {
			if (cf == null) return;
			
			var props		:Object = this.properties;
			var className	:String = "";				// if the class name was passed as a String
			
			if ( cf is StaticClassFactory) {
				_wrappedClassFactory = StaticClassFactory(cf).wrappedClassFactory;
			} if ( cf is ClassFactory) {
				_wrappedClassFactory = cf;
			} else if (cf is Class) { 
				_wrappedClassFactory = new ClassFactory(Class(cf));
			} else if (cf is String) { 
				className = String(cf);
				try {
					var clazz:Class = getDefinitionByName(className) as Class;
					_wrappedClassFactory = new  ClassFactory(clazz);
				} catch (e:Error) 	{
					trace(" Class '"+ className + "' can't be loaded dynamically. Ensure it's explicitly referenced in the application file or specified via @rsl.");
				} 	
			} else if (cf is Function) { 
				factoryFunction = cf;
			} else {
					className = "null";
					if (cf!=null)
						className = describeType(cf).@name.toString();
					trace("'" + className + "'" + " is invalid parameter for UIClassFactory constructor.");
			}		
			
			if (!_wrappedClassFactory) {
				_wrappedClassFactory = new ClassFactory(Object);				
			}		
			
			_wrappedClassFactory.properties = props;
		}
		
		/**
		 * Constructor of UIClassFactory takes four arguments
		 * cf   -  The object to build. It can be a class name, 
		 *         a string containing the class name, a function,
		 *         or another class factory object;
		 * props - inital values for some or all properties if the object;
		 * styles - styles to be applied to the object being built
		 * eventListeners - event listeners to be added to the object being built
		 */ 	
		function StaticClassFactory( cf: * = null, props:Object = null, 
			                    styles:Object = null, eventListeners:Object = null ) {
				
			generator = cf;
			
			if (props != null) 			wrappedClassFactory.properties 	= props;
			if (styles != null) 		this.styles 				    = styles;
			if (eventListeners != null) this.eventListeners 			= eventListeners;
		}

        /**
        * The implementation of newInstance is required by IFactory 
        */ 
		public function newInstance():* {
			var results:* = (factoryFunction != null) ? null : wrappedClassFactory.newInstance();
			
		    // using a function to create an object
			// Copy the properties to the new object 
			if (factoryFunction!=null){ 
				
				results = factoryFunction();
				if (properties != null)  {
		        	for (var p:String in properties) {
		        		results[p] = properties[p];
					}
		       	}
			}  
			    
			// Set the styles on the new object     
			//add event listeners, if any
			
			if (styles != null)  {
	        	for (var s:String in styles) {
	        		results.setStyle(s,  styles[s]);
				}
			}
			
			if (eventListeners != null)  {
	        	for (var e:String in eventListeners) {
					if (results is IEventDispatcher) {
						IEventDispatcher(results).addEventListener(e,  eventListeners[e]);
					}
				}
			}
			
			return results;
		}

		/**
		 * A class factory object that serves as a wrapper 
		 * for classes, functions, strings, and even class factories
		 */
		private var _wrappedClassFactory : ClassFactory;
		
		/**
		 * A reference to a function if the object instances are
		 * to be created by a function
		 */
		private var factoryFunction : Function = null;

	}
}