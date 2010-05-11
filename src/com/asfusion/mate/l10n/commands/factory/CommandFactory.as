////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2009 Farata Systems LLC
//  All Rights Reserved.
//
//  NOTICE: Farata Systems permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////
package com.asfusion.mate.l10n.commands.factory {
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
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.ClassFactory;
	import mx.core.IFactory;
	import mx.events.FlexEvent;
	import mx.styles.StyleProxy;
	import mx.logging.Log;
    import mx.logging.ILogger;
	import mx.logging.LogEventLevel;


	public class CommandFactory implements IFactory{
		
		// A class factory object that serves as a wrapper 
		// for classes, functions, strings, and even class factories
		private var _wrappedClassFactory : ClassFactory;
		
		// A reference to a function if the object instances are
		// to be created by a function 
		private var factoryFunction : Function = null;

		//Styles for the UI object to be created 
		public var styles:Object;
		
		//Event Listeners for the UI object to be created
		public var eventListeners:Object;
		
					
		private static const logger:ILogger = 
						Log.getLogger ("com.farata.core.UIStaticCassFactory");
		
		public function set properties(v:Object):void	{
			_wrappedClassFactory.properties = v;
		}
		public function get properties():* {
			return _wrappedClassFactory.properties ;
		}
				
		public function get wrappedClassFactory():ClassFactory {
			return _wrappedClassFactory;
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
		function CommandFactory( cf: * , props:Object = null, 
			                    styles:Object = null, eventListeners:Object = null ) {
				
			var className:String;// if the class name was passed as a String
			
			if ( cf is CommandFactory) {
				_wrappedClassFactory = CommandFactory(cf).wrappedClassFactory;
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
				
			if (props != null) _wrappedClassFactory.properties = props;
			if (styles != null) this.styles = styles;
			if (eventListeners != null) this.eventListeners = eventListeners;
		}

        /**
        * The implementation of newInstance is required by IFactory 
        */ 
		public function newInstance():* {
			var obj:*;
			if (factoryFunction!=null){ 
			   // using a function to create an object
				obj = factoryFunction();
				// Copy the properties to the new object 
				if (properties != null)  {
		        	for (var p:String in properties) {
		        		obj[p] = properties[p];
					}
		       	}
			} else	
			    obj = _wrappedClassFactory.newInstance();
			    
			// Set the styles on the new object     
			if (styles != null)  {
	        	for (var s:String in styles) {
	        		obj.setStyle(s,  styles[s]);
				}
			}
			
			//add event listeners, if any 
			if (eventListeners != null)  {
	        	for (var e:String in eventListeners) {
	        		obj.addEventListener(e,  eventListeners[e]);
				}
			}
			return obj;
		}
	}
}