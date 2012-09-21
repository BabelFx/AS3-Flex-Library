////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.injectors
{
	 import avmplus.getQualifiedClassName;
	 
	 import com.codecatalyst.util.PropertyUtil;
	 import com.codecatalyst.util.invalidation.InvalidationTracker;
	 
	 import ext.babelfx.events.BabelFxEvent;
	 import ext.babelfx.proxys.ResourceSetter;
	 import ext.babelfx.utils.Binder;
	 import ext.babelfx.utils.InjectorUtils;
	 
	 import flash.events.Event;
	 import flash.events.IEventDispatcher;
	 import flash.utils.Dictionary;
	 
	 import mx.core.UIComponent;
	 import mx.events.FlexEvent;
	 import mx.events.PropertyChangeEvent;
	 import mx.events.StateChangeEvent;
	 import mx.resources.IResourceManager;
	 
	 import utils.string.supplant;
	 

	[DefaultProperty("proxies")]
	
	/**
	 * Manages list of 1 or more ResourceSetter or PropertySetter instances
	 * to 0-n target instances.
	 * 
	 */
	[Bindable]
	public class ResourceInjector extends AbstractInjector 
	{
		
		// *********************************************************************************
		//  Public Properties 
		// *********************************************************************************
		
		[Invalidate("properties")]
		public var targets 		: Array = [ ];
		
		[Invalidate("properties")]
		public var proxies      : Array = [ ];
		

		// *********************************************************************************
		//  Public Properties 
		// *********************************************************************************
		
		/**
		 * Function name to be invoked on target instances after locale has changed
		 * and injections are finished.
		 */
		public var eventHandler  : String;

		
		/**
		 * Returns event attribute of [BabelFx(event="")] tag.
		 * Allows `announceChange()` to filter which events should be dispatched
		 * to the `event` handler
		 */
		public var filter        : String;
		
	    // *********************************************************************************
	    //  Public Constructor 
	    // *********************************************************************************
	   
	     /**
	      * Public constructor 
	      *  
	      * @param bundleName
	      * 
	      */
	     public function ResourceInjector( bundleName   : String           = "", 
										   target       : Object           = null, 
										   localeManager: IResourceManager = null )  
		 {
			super( bundleName, localeManager );
			
			this.targets  	 = target ? [ target ] : [ ];
			
	     }  
	   
	    // *********************************************************************************
	    //  Public Methods
	    // *********************************************************************************
	   
		 /**
		 * Invoked by the LocalizationManager when the locale changes.
		 */
		 public function execute( target:Object=null, why:String=null ):void 
		 {
			 var targets : Array = target ? [target] : this.targets;
			 
			 	/**
				 * Optimization to inject with parameters only if parameters changed
				 */ 
			 	function doInjection(map:ResourceSetter):Boolean
				{
					var params : Array = map.parameters || [ ];
					switch( why )
					{
						case BabelFxEvent.PARAMS_CHANGED:	return (params.length > 0);
					}
					
					return (map.key && map.property);
				}
				
			 
			 validateBundleName();
			 
			 for each (var inst:Object in targets)
			 {
				 if ( validateTargetsReady( inst ) )
				 {
					 logger.debug( supplant("ResourceInjector[{0}] :: execute( {1} - why=`{3}` - {2} mappings )", [ this.id, getQualifiedClassName(inst), proxies.length,  why] ));
					 
					 for each (var map:ResourceSetter in proxies)
					 {
						if ( doInjection(map) ) 
							assignResourceValues( inst, map );					 
					 }
					 
					 announceChange( inst, why || BabelFxEvent.LOCALE_CHANGED );
				 }
			 }
			 
		 }
		 
		
		/**
		 * Clear reference use of specified target "instance" or all _instances
		 * Or ask ResourceInjector superclass to release references to ResourceMap
		 * @param target
		 * 
		 */
		public function release(target:Object=null):void 
		{
			disconnectListeners( target ? [target] : targets );
			
			if ( target == null ) {
				
				var queue : Array = [].concat(this.targets)
				for each (var it:Object in queue )
				{
					release(it);
				}
				targets = [ ];
				
			} else {
				
				var index : int = this.targets.indexOf( target );
				if ( index > -1 )
				{
					logger.debug( supplant("ResourceInjector[{0}] :: release( {1} - {2} mappings )", [ this.id, getQualifiedClassName(target) , proxies.length] ));
					
					// Splice remove the specified target instance
					this.targets.splice(index,1);
				}
			}
	   	 }
		
		
		/**
		 * Force updates of localization values to either the specified Proxy or all proxies.
		 * Useful to support injections after programmatic modifications to targets.
		 * 
		 * e.g.
		 *     injector.targets.push( newTargetInst );
		 *     injector.validateNow( newTargetInst );
		 */ 
		public function validateNow(target:Object = null, reason:String=null) : void  
		{
			commitProperties();
			execute(target, reason);
		}
		
		
		
		// ************************************************************************************
		// Protected Event Handlers
		// ************************************************************************************

		protected function onCreationComplete(event:FlexEvent):void 
		{
			var item 			: UIComponent = event.target as UIComponent;
			var detachListener 	: Function    = listenCreationComplete( false );
			
			logger.debug( supplant("ResourceInjector[{0}] : onCreationComplete( ui=`{1}` )", [ this.id, getQualifiedClassName(item) ] ));
				
			detachListener( item );
			validateNow( item, BabelFxEvent.TARGET_READY );
			
		}
		
		
		/**
		 * When state change occurs (in UIComponents) then trigger updates for this instance...
		 * @param event StateChangeEvent.CURRENT_STATE_CHANGE	
		 * 
		 */
		protected function onTargetStateChange(event:StateChangeEvent):void 
		{
			logger.debug( supplant("ResourceInjector[{0}] : onTargetStateChange( ui=`{1}`, currentState=`{2}` )", [ this.id, getQualifiedClassName(event.target), event.target.currentState ] ));
			
			validateNow( event.target, BabelFxEvent.STATE_CHANGED );
		}

		/**
	     * The target OR the parameterized values for a registry item has changed... therefore we must 
	     * scan the associated bundle and update the target with current localization, parameterized text 
	     * @param event
	     * 
	     */
	    protected function onRegistrationChanges(source:Object, target:Object = null):void 
		{
	    	var proxy : ResourceSetter = (source is Event) 			? source.target as ResourceSetter :
				                         (source is ResourceSetter) ? source as ResourceSetter        : null;
			
			if (proxy != null) {
				// Use Injector bundle name if not overridden in proxy
			
				logger.debug( supplant("ResourceInjector[{0}] : onRegistrationChanges( ui=`{1}`, parameters=`{2}` )", [ this.id, getQualifiedClassName(target), proxy.parameters.toString() ] ));
				
		    	if ( !proxy.bundleName ) 
					proxy.bundleName = this.bundleName;

				// fire all injections
		
				validateNow( target, BabelFxEvent.PARAMS_CHANGED );
			}
	    }
	    
	    
		// *********************************************************************************
	    //  Protected Methods
	    // *********************************************************************************
	    
		 /**
		  * Validation processing when targets or proxies change.
		  * NOTE: this does not fire injections
		  */
		 protected function commitProperties():void 
		 {
			 // Clean listeners from previous targets & attach listeners to current targets
			 
			 if ( _invalidator.invalidated( ["targets"] ) )
			 {
				var previous : Array = (_invalidator.previousValue("targets") as Array) || [ ];
				
				previous.forEach( listenViewStateChanges(false) );
				previous.forEach( listenCreationComplete(false) );
				previous.forEach( listenParameterValueChanges(false) );
				
				targets.forEach( listenViewStateChanges(true) );
				targets.forEach( listenCreationComplete(true) );
				targets.forEach( listenParameterValueChanges(true) );
				
			 }
			 
			 // Clean listeners from previous resourceSetters & attach listeners to current resourceSetters
			 
			 if ( _invalidator.invalidated( ["proxies"] ) )
			 {
				disconnectListeners( [ ], _invalidator.previousValue("proxies") as Array );
				proxies.forEach( listenRegistrationChanges(true) );
			 }
			 
		 }
		 
		 
		 /**
		  * Clear all listeners associated with target instances and proxies 
		  */
		 protected function disconnectListeners( instances:Array, proxies:Array=null ):void 
		 {
			 instances.forEach( listenViewStateChanges(false) );
			 instances.forEach( listenCreationComplete(false) );
			 instances.forEach( listenParameterValueChanges(false) );
			 
			 proxies ||= this.proxies;
			 
			 proxies.forEach( listenRegistrationChanges(false) );		
		 }
		 
		 
		 /**
		 * If a [BabelFx("<name>")] or [BabelFx(bundle="<name>")] was not defined
		 * then scan all ResourceSetters to grab first available bundleName.
		 * 
		 * NOTE: a resource bundleName is required at the ResourceSetter-level before
		 *       injections will be performed.
		 */
		 protected function validateBundleName():Boolean 
		 {
			 if ( !bundleName )
			 {
				 for each (var proxy:ResourceSetter in proxies) 
				 {
					 if ( proxy.bundleName ) 
					 {
						 // Grab first bundle name available in scan
						 
						 this.bundleName = proxy.bundleName;
						 break;
					 }
				 }
			 }
			 
			 return bundleName && (bundleName != "");
			 
		 }
		 
		 /**
		 * Confirm that all UIComponent instances are `ready`; which occurs after their creationComplete events
		 * For any not ready [not fully initialized], then attach a temporary creationComplete eventHandler.
		 */
		 protected function validateTargetsReady( target:Object=null ):Boolean 
		 {			 
			 var targets : Array = target ? [ target ] : this.targets;
			 
				 /**
				 * Is the specified instance still pending a creationComplete ?
				 */
				 function isCreationCompletePending( element:*, index:int, arr:Array ):Boolean
				 {
					 var ui 		: UIComponent = element as UIComponent
					 var isPending 	: Boolean = (ui && !ui.initialized);
					 
					 return isPending;
				 }
				 
			 // Attach creationComplete listeners; if needed
				 
			 targets.forEach( listenCreationComplete(true) );
			 
			 // Return if any targets are pending creationComplete
			 
			 return !targets.some( isCreationCompletePending );
		 }
		 
		 
		 /**
		 * Determine if all change handlers that should be invoked after the locale changes and the target
		 * injections are finished.
		 */
		 protected function getTargetEventHandlers():Array
		 {
			 var handlers : Array = [ ];
			 
			 for each (var proxy:ResourceSetter in proxies) 
			 {
				 if ( proxy.eventHandler ) 
				 {
					 // Grab first bundle name available in scan
					 
					 handlers.push({
						 name   :  proxy.eventHandler,
						 filter :  proxy.filter
					 });
						 
					 break;
				 }
			 }
			 
			 return handlers;
		 }
		 
		 // *********************************************************************************
		 //  Protected `Listen` Methods
		 // *********************************************************************************

		 /**
		  *  Listen for `creationComplete changes` events.
		  *  This means all default viewstate children are ready for injection
		  */
		 protected function listenCreationComplete(active:Boolean=true):Function 
		 {
			 function iterator( element:*, index:int=0, arr:Array=null ):void 
			 {
				 var inst : UIComponent = element as UIComponent;
				 if (inst )
				 {
					 if ( active && !inst.initialized )
					 {
						 inst.addEventListener(FlexEvent.CREATION_COMPLETE,onCreationComplete,false,0,true);
						 
					 } else {
						 
						 inst.removeEventListener(FlexEvent.CREATION_COMPLETE,onCreationComplete);
					 }
				 }
			 }
			 
			 return iterator;
		 }

		 
		 /**
		  *  Listen for `viewstate changes` events.
		  *  Needed if any of the registry items want to perform injection during state changes
		  */
		 protected function listenViewStateChanges(active:Boolean=true):Function 
		 {
			 	function iterator( element:*, index:int, arr:Array ):void 
				{
					 var inst : IEventDispatcher = element as IEventDispatcher;
					 if (inst )
					 {
						 var dispatcher : IEventDispatcher = InjectorUtils.scanForTrigger( inst );
						 
						 if ( dispatcher != null )
						 {
							 if ( active )
							 {
								 dispatcher.addEventListener(StateChangeEvent.CURRENT_STATE_CHANGE,onTargetStateChange,false,0,true);
								 
							 } else {
								 
								 dispatcher.removeEventListener(StateChangeEvent.CURRENT_STATE_CHANGE,onTargetStateChange);
							 }
						 }
					 }
				}
				
			
			return iterator;
		 }
		 
		 /**
		  *  Listen for `parameters` changes in the ResourceSetter instance. 
		  */
		 protected function listenRegistrationChanges(active:Boolean=true):Function 
		 {
				 function iterator( element:*, index:int, arr:Array ):void 
				 {
					 var setter : ResourceSetter = element as ResourceSetter;
					 if (setter )
					 {
						 if ( active )
						 {
							 setter.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,onRegistrationChanges,false,0,true);
							 
						 } else {
							 
							 setter.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE,onRegistrationChanges);
						 }
					 }
				 }
			 
			
			 return iterator;
		 }
		 
		 
		 /**
		  *  Listen for `parameter` value changes,
		  * 
		  *  Since the ResourceSetter manages parameter property chains, this method establishes binding for 
		  *  each of the parameter chains for each current target. Thus when the value of the property changes,
		  *  we can trigger injections for that resourceSetter.
		  *  
		  */
		 protected function listenParameterValueChanges(active:Boolean=true):Function 
		 {
				 /**
				 * Iterator function to activate/deactivate changeWatchers for ResourceSetter parameter values
				 */
				 function iterator( element:*, index:int, arr:Array ):void 
				 {
					 var inst 	  : Object = element as Object;
					 var watchers : Array  = null;
					 
					 if ( active )
					 {
						 // For all watchers associated with this `inst`, activate the watching overlays
						 
						 watchers = (_watchRegistry[ inst ] ||= [ ]) as Array
							 
						 for each (var setter:ResourceSetter in proxies)
						 {
							 if ( !setter.hasParameters ) continue;
							 
							 for each ( var param:String in setter.parameters )
							 {
								 watchers.push( createWatcher( inst, param, setter, element ) );
							 }
						 }
						 
					 } else {
						 
						 // For all watchers associated with this `inst`, clear or deactivate the watching overlays
						 
						 watchers = _watchRegistry[ inst ] as Array;
						 
						 if ( watchers ) 
						 {
							 for each (var it:Binder in watchers)
							 {
								 it.unbind();
							 }
							 
							 delete _watchRegistry[ inst ];
						 }
					 }
				 }
			 
			 
			 return iterator;
		 }
		 
		 
		 /**
		  * Function curry used to `snapshot` setter associated with Binder notifications
		  */
		 protected function createWatcher(source:Object, chain:String, setter:ResourceSetter, target:Object):Binder
		 {
			 var id : String = this.id;
			 
				 /**
				  * Just announce that the current setter has `property` changes for the specificed target
				  * and injections will re-fire into that target.
				  */
				 function onChainChanges(event:PropertyChangeEvent):void 
				 {
					 logger.debug( supplant("ResourceInjector[{0}] :: onChainChanges( ui=`{1}`, parameters=`{2}` )", [ id, getQualifiedClassName(target), setter.parameters.toString() ] ));
					 
					 onRegistrationChanges( setter, source );
				 }
			 
			 return new Binder().bindCallback( source, chain, onChainChanges );
		 }
		 
		 
		 /**
		 * The locale has changed and the injections have finished for this `inst`ance.
		 * So announce `injection complete` by invoking the specified event handler (if provided) on
		 * each registered target instance.
		 * 
		 */
		 protected function announceChange( inst : Object, changeType:String ):void
		 {
			 var handlers : Array = getTargetEventHandlers();
			 
			 for (var j:uint=0; j< handlers.length; j++) 
			 {
				 var handlerName : String = handlers[j].name as String;
				 var filter      : String = handlers[j].filter as String;
				 
				 if ( handlerName )
				 {
					var handlerFn : Function = PropertyUtil.getObjectPropertyValue( inst, handlerName ) as Function;
					
					if ( handlerFn != null ) 
					{
						// Should we invoke the handler function for this event of type `changeType` ?
						
						if ( !filter || (filter == changeType) )
						{
							logger.debug( supplant("ResourceInjector[{0}] :: [BabelFx( event=`{1}` )] on {2}::{3}() )", [ this.id, changeType, getQualifiedClassName(inst), handlerName ] ));
							
							var arguments : Array = (handlerFn.length > 0) ? [ new BabelFxEvent( changeType, null, resourceManager) ] : null;
							
							handlerFn.apply( inst, arguments );
						}
					}
				 }
			 }
		 }

		// *********************************************************************************
	    //  Private Attributes
	    // *********************************************************************************
		 
		 private var _invalidator    : InvalidationTracker 	= new InvalidationTracker(this as IEventDispatcher, commitProperties, true);
		 
		 private var _watchRegistry  : Dictionary           = new Dictionary(true);
	}
}

