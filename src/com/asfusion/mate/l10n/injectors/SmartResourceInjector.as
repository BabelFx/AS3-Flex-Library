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
package com.asfusion.mate.l10n.injectors
{
	 import com.asfusion.mate.l10n.events.LocaleMapEvent;
	 import com.asfusion.mate.l10n.maps.LocaleMap;
	 
	 import flash.events.Event;
	 import flash.events.IEventDispatcher;
	 import flash.utils.Dictionary;
	 import flash.utils.getQualifiedClassName;
	 
	 import mx.collections.ArrayCollection;
	 import mx.events.PropertyChangeEvent;
	 import mx.events.StateChangeEvent;
	 import mx.resources.IResourceManager;
	 import mx.utils.ObjectProxy;

	/**
	 * Sample MXML Usage.
	 * @code
	 * 
	 *  <LocaleMap>
	 *    <SmartResourceInjector target="{DocumentViewer}" bundle="registration">
	 *       <ResourceProxy 	property  = "vacuum.lblButton.label" 
	 * 		  				    key       = "documentviewer.relatedVideos" 
	 * 							bundle    = "user" 
	 * 							parameters= "{[_model.userName]}"  />
	 *	  </SmartResourceInjector>
	 *  </LocaleMap>
	 *  
	 * @author thomasburleson
	 * 
	 */
	[DefaultProperty("registry")]
	[Event(name="change",type="flash.events.Event")]
	  
	public class SmartResourceInjector extends ResourceInjector {
		
		/**
		 * Special accessor to expose all collected instances  
		 * @return Array of target class instances
		 * 
		 */
		public function get targetInstances():Array {
			return _instances;
		}
		
		 /**
		  * Class whose instances should be used to trigger this injector to process and 
		  * injector resource bundle settings 
		  */
		 public function get target() : Class {
		 	return _target;
		 }   
		 public function set target(src:Class):void {
		 	if (src != _target) {
		 		_target = src;
		 		
			 	// Register class with LocaleMap, to be notified of creationComplete for instances
				if (_target && map) map.addTarget(_target);
			}
		 }
		 private var _target : Class = null;
		 
		 
		 
	     /**
	      * LocaleMap reference used to attach listener for  
	      */
		 public function get map() : LocaleMap {
		 	return _map;
		 }   
		 public function set map(src:LocaleMap):void {
		 	if (src != _map) {
		 		if (_map != null) {
		 			_map.removeEventListener(LocaleMapEvent.TARGET_READY,onInstanceCreationComplete);
		 		}
		 		
			 	// Register class with LocaleMap, to be notified of creationComplete for instances
		 		_map = src;
		 		_map.addEventListener(LocaleMapEvent.TARGET_READY,onInstanceCreationComplete,false,2);

				if (_target != null) _map.addTarget(_target);
			}
		 }
	     private var _map             : LocaleMap   = null;
				 
		 
	    // *********************************************************************************
	    //  Public Constructor 
	    // *********************************************************************************
	   
	     /**
	      * Public constructor 
	      *  
	      * @param bundleName
	      * 
	      */
	     public function SmartResourceInjector( target       : Class           = null, 
	     										bundleName   : String          = "", 
	     										localeManager: IResourceManager= null, 
	     										map          : LocaleMap  = null)  {
	     	super(bundleName,localeManager);
	     	  
	         this.map     = map;
	         this.target  = target;
	         
	     }  
	   
	    // *********************************************************************************
	    //  IMXMLObject Interface 
	    // *********************************************************************************
	   
	   	 /**
	   	  * Method is auto-invoked during MXML initialization. Note: if a SmartResourceInjector instance
	   	  * was programmatically instantiated (not as a tag), then this method is never called.
	   	  * 
	   	  * @param document	Owner for this tag instance
	   	  * @param id       Reference for this tag instances
	   	  * 
	   	  */
	   	 override public function initialized(document:Object, id:String):void {
	   	 	var parent : LocaleMap = document as LocaleMap;
	   	 	if (parent == null) {
	   	 		// Can only use SmartResourceInjectors inside LocaleMap
	   	 		throw new Error(INVALID_USAGE);
	   	 	}
	   	 	
	   	 	// The map owner is usually a mx.core.Container
	   	 	super.initialized(parent.owner,id);
			this.map = parent;
	   	 } 
		
		
		/**
		 * Clear reference use of specified target "instance" or all _instances
		 * Or ask ResourceInjector superclass to release references to ResourceMap
		 * @param target
		 * 
		 */
		override public function release(target:Object=null):void {
			var items : Array = (target == null) ? _instances : [target];
			
			if (target == null) {
				_instances = [];
				clearProxyTargets();
			} else if ((target is ResourceMap) != true) {
				// Splice remove the specified target instance
				var buffer : Array = [];
				for each (var it:Object in _instances) {
					if (it != target) buffer.push(it);
				}
				
				_instances = buffer;
			}

			super.release(target);
	   	 }
	   	 		   
		/**
		 * Force updates of localization values to either the specified Proxy or all proxies 
		 */ 
		public function validateNow(inst:Object=null):void {
			commitProperties(inst);
		}
		
		// ************************************************************************************
		// Protected Methods
		// ************************************************************************************
		
		/**
		 * Build a registry from the target instances. 
		 *  
		 * @param target  
		 * 
		 */
		override protected function buildRegistry(src:Object):void {
		 	var items     : Array = [];
		 	var hasTargets: Array = []; 
		 	
		 	if (src is Array) 				 items = src as Array;
		 	else if (src is ArrayCollection) items = ArrayCollection(src).source;
		 	else if (src  is Object)         items = [src];
		 	
		 	for each (var it:Object in items) {
		 		if (it == null) continue;
		 		
		 		if (wantsInjection(it) == true) {
					registerProxyTarget(it);
					
					// Listen for changes to "target" so "callbacks" will trigger updates to  with localization values.
		 			_smartCache.push(it);
					
		 			if (it is ResourceProxy) {
						ResourceProxy(it).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,onRegistrationChanges,false,0,true);	
						if (ResourceProxy(it).state != "")  _listenForStateChanges = true;
					}
					else if (it is PropertyProxy) {
						PropertyProxy(it).owner = this;
						if (PropertyProxy(it).state != "")  _listenForStateChanges = true;
					} 
		 		}
		 		else {
		 			hasTargets.push(it);
		 		}
		 	}
		 	
		 	// Pass the "standard" resourceMaps (or Objects) to ResourceInjector to build, cache, and manage
		 	// Thus, the SmartResourceInjector supports "mixed" registry items (Objects & ResourceProxy)
		 	super.buildRegistry(hasTargets);
		 	
		}
		
		/**
		 * Processes the properties set on the component.
		*/
		protected function commitProperties(inst:Object=null):void {
			var items : Array = (inst != null) ? [inst] : _instances;

			// Iterate each instance, and update all proxies with instance...
			for each ( var it:Object in items) {
				for each (var proxy:ITargetInjectable in _smartCache) {
					if (proxy == null) continue;
					
					// (1) temp cache of class reference (if any)
					var clazz : Class = (proxy.target as Class);

					// (2) Assignment of target actually fires injectors to perform injection...
					proxy.target = it;
					
					// (3) Restore cached, individual Class target (if any)
					if (clazz != null) proxy.target = clazz;
				}				
			}
			
			clearProxyTargets();
		}
		
		// ************************************************************************************
		// Protected EventHandles Methods
		// ************************************************************************************
		
		/**
		 * An instance of the "target" class has been instantiated and is ready.
		 * Cache this instance, then iterate all "injectable" ResourceProxy instances
		 * and update the proxied localized settings...
		 * 
		 * @param event 
		 * 
		 */
		protected function onInstanceCreationComplete(event:LocaleMapEvent):void {
			var inst : Object = event.targetInst;
			
			// If this Injector instance still has a target AND 
			// the instance is a derivative of the target Class
			if (shouldCacheInstance(inst) == true) {
				
				log.debug("onInstanceCreationComplete({0})",getQualifiedClassName(event.targetInst));
				// trace("adding smartcache: " + inst["id"]);
				
				// For current instance, iterate proxies and update target property
				_instances.push(inst);
				validateNow(inst);
				
				// Do any of the registry items want injection during state changes
				if (_listenForStateChanges == true){
					if (inst is IEventDispatcher) {
						IEventDispatcher(inst).addEventListener(StateChangeEvent.CURRENT_STATE_CHANGE,onTargetStateChange,false,0,true);
					} 
				}

			}
		}	  


	    /**
	     * When state change occurs (in UIComponents) then trigger updates for this instance...
	     *  
	     * @param event StateChangeEvent.CURRENT_STATE_CHANGE	
	     * 
	     */
	    override protected function onTargetStateChange(event:StateChangeEvent):void {
				log.debug("onTargetStateChange({0})",event.newState);
	    		validateNow(event.target);
	    }
	    

 		/**
	   	  * The locale has changed, so update the properties of all items registered for any bundle 
	   	  * @param event ResourceEvent.Change
	   	  * 
	   	  */
	   	override protected function onLocaleChange(event:Event=null):void {
	   	 	// Update instances of target Class and force updates of all _smartCache proxies...
	   	 	// Then iterate standard ResourceMap entrys
			clearProxyTargets();	// Force updates to all proxies
	   	 	validateNow();

			super.onLocaleChange(event);	   	 	
		}		

	    /**
	     * The target OR the parameterized values for a registry item has changed... therefore we must 
	     * scan the associated bundle and update the target with current localization, parameterized text 
	     * @param event
	     * 
	     */
	    override protected function onRegistrationChanges(event:PropertyChangeEvent):void {
	    	var rProxy : ResourceProxy = event.target as ResourceProxy;
			if (rProxy != null) {
				// If the proxy just was assigned a target value that is a Class
				// reference, then do something special...
				
				if ( isProxyTargetClass(rProxy) && (event.oldValue == null) ){
					
						// Foree release and re-add with new Class reference...
						release(rProxy);
						buildRegistry(rProxy);
					
				} else {				
	
					// Use Injector bundle name if not overridden in proxy
			    	if (rProxy.bundleName == "") rProxy.bundleName = this.bundleName;
	
		    		switch(event.property) {
		    			case "target" :	assignResourceValuesTo(rProxy);		
										break;
						
		    			default       : validateNow();						
										break;	// Call to force iteration over all instances 
		    		}
				}
			}
	    }
	    
	    
		// *********************************************************************************
	    //  Private Methods
	    // *********************************************************************************
	    
	    private function clearProxyTargets():void {
	    	for each (var proxy:ITargetInjectable in _smartCache) {
	    		if (proxy == null) continue;
	    		if ((proxy.target != null) && !(proxy.target is Class)) {
					// Only clear if the target is an "instance"
	    			proxy.target = null;
				}
	    	}
	    }
		
		/**
		 * 	Check if the specified registry item is a ResourceProxy which requires
		 *  runtime injection of "target" instances.
		 * 
		 * @param it Registry item for Injector. 
		 * @return True/False requires runtime injection 
		 * 
		 */
		private function wantsInjection(it:Object):Boolean {
			// Must be instance of ResourceProxy WITH no target assigned...
			return shouldUseInjectorTarget(it) || isProxyTargetClass(it);
		} 
		
		private function shouldUseInjectorTarget(it:Object):Boolean {
			// Must be instance of ResourceProxy WITH no target assigned...
			// So the target attribute in <SmartResourceInjector will be used
			
			return ((it is ITargetInjectable) && (ITargetInjectable(it).target == null));
		}
		
		private function isProxyTargetClass(it:Object):Boolean {
			return ( (it is ITargetInjectable) 				&& 
					 (ITargetInjectable(it).target !=null) 	&& 
					 (ITargetInjectable(it).target is Class)
				   ); 
		}
		
		/**
		 * This allows <ResourceProxy target="{<Class>}" .../> so the target attribute is used as 
		 * override for <SmartResourceInjector target="{<Class>}" />
		 *   
		 * @param it
		 */
		private function registerProxyTarget(it:Object) : void {
			if (isProxyTargetClass(it) == true) {
				var clazz : Class = (ITargetInjectable(it).target as Class);
				map.addTarget(clazz);
			}
		}
	   	
		
		private function shouldCacheInstance(inst:Object):Boolean {
			var results : Boolean = false;
			
			if (inst != null) {
				if (_smartCache.length > 0) {
					for each (var proxy:ITargetInjectable in _smartCache) {
						if (proxy == null) continue;		
						
						if (
							  ((proxy.target == null) && (target is Class)       && (inst is target))       || 
							  ((proxy.target != null) && (proxy.target is Class) && (inst is Class(proxy.target)))
						   ){
							// When targetID is specified, only cache if ID matches 
							var targetID : String = (proxy is ResourceProxy) ? ResourceProxy(proxy).targetID : 
													(proxy is PropertyProxy) ? PropertyProxy(proxy).targetID : "";
	
							results = (targetID == "") 			? true 						:
							          inst.hasOwnProperty("id")	? (inst['id'] == targetID)	: false;
						} 
							  
						// Exist loop asap!
						if (results == true) break;
					}
				} else {
					// Rare case where no proxies are specified, but a targetClass is still specified...
					// Useful to trigger localChange events
					if (target && (target is Class) && (inst is target)) results = true;
				}
			}
				
			return results;
		}
		
		// *********************************************************************************
	    //  Private Attributes
	    // *********************************************************************************
	    
		/**
		  * Registered instances of ResourceProxy where "target" is initially null; which means
		  * these proxies want runtime injection of target instances from SmartResourceInjector 
		  */
		 private var _smartCache      		: Array            = [];
	     
		 /**
		  * Cached Instances of the "target" class
		  * @FIXME: need to use weak dictionary for GC to work properly 
		  */
		 private var _instances       		: Array            = [];	// @FIXME: This needs to be dictionary w/ weak references

	
		 /**
		  * Should this Injector listen for  StateChangeEvent.CURRENT_STATE_CHANGE events
		  * on all target instances?
		  */		 
		 private var _listenForStateChanges : Boolean    = false;
		 
		 static private const INVALID_USAGE : String     = "SmartResourceInjector can only be used with LocaleMaps";     
	}
}

