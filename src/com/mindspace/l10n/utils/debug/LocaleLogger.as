package com.mindspace.l10n.utils.debug
{
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.logging.ILogger;
	import mx.logging.ILoggingTarget;
	import mx.logging.LogEvent;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	
	public class LocaleLogger extends EventDispatcher implements ILogger
	{
		protected static var loggers		:Dictionary = new Dictionary();
		protected static var loggingTargets	:Array		= [];
		
		public static function getLogger( target:Object , fullPath:Boolean = true):ILogger
		{
			loggers ||= new Dictionary();
			
			// Target is a class or instance; we want the fully-qualified Classname
			var className:String  = getQualifiedClassName( target );
			var logger:LocaleLogger = loggers[ className ];
			
			// if the logger doesn't already exist, create and store it
			if( logger == null )
			{
				var category : String = fullPath 					 ?  className 									: 
									    className.indexOf("::") >= 0 ?	className.substr(className.indexOf("::")+2)	:
										className;
				logger = new LocaleLogger( category, new ConstructorLock);
				loggers[ className ] = logger;
			}
			
			// check for existing targets interested in this logger
			for each( var logTarget:ILoggingTarget in loggingTargets ) {
				
				if( categoryMatchInFilterList( logger.category, logTarget.filters ) )
					logTarget.addLogger( logger );
			}
			
			return logger;
		}
		
		public static function addLoggingTarget( it:ILoggingTarget ):void
		{
			if (it == null) return;
			
			initializeTarget(it);
			
			loggingTargets ||= [];
			if( loggingTargets.indexOf( it ) < 0 ) loggingTargets.push( it );
			
			if( loggers != null ) {
				
				for each( var logger:ILogger in loggers ) {
					if( categoryMatchInFilterList( logger.category, it.filters ) )
						it.addLogger( logger );
				}
			}
		}
		
		
		/**
		 *  This method checks that the specified category matches any of the filter
		 *  expressions provided in the <code>filters</code> Array.
		 *
		 *  @param category The category to match against
		 *  @param filters A list of Strings to check category against.
		 *  @return <code>true</code> if the specified category matches any of the
		 *            filter expressions found in the filters list, <code>false</code>
		 *            otherwise.
		 */
		public static function categoryMatchInFilterList( category:String, filters:Array ):Boolean
		{
			var result:Boolean = false;
			var filter:String;
			var index:int = -1;
			for( var i:uint = 0; i < filters.length; i++ )
			{
				filter = filters[ i ];
				// first check to see if we need to do a partial match
				// do we have an asterisk?
				index = filter.indexOf( "*" );
				
				if( index == 0 )
					return true;
				
				index = index < 0 ? index = category.length : index - 1;
				
				if( category.substring( 0, index ) == filter.substring( 0, index ) )
					return true;
			}
			return false;
		}
		
		/**
		 * If the LoggingTarget appears to be un-initialized, then
		 * configure to DEBUG all pertinent l10nInjection packages
		 *  
		 * @param val ILoggingTarget instance
		 * 
		 */
		private static function initializeTarget(val:ILoggingTarget):void {
			var tracer : TraceTarget = val as TraceTarget	
			if (tracer != null) {
				// If it appears to be an unchanged tracer... customize it for l10nInjection
				if (!tracer.includeCategory && 
					!tracer.includeDate 	&& 
					!tracer.includeTime 	&& 
					!tracer.includeLevel) {

					var l10nPackages : Array = [
												 "com.asfusion.mate.l10n.maps.*",
												 "com.asfusion.mate.l10n.commands.*",
												 "com.asfusion.mate.l10n.injectors.*"
											    ];
					
					tracer.filters			= tracer["filters"].concat(l10nPackages);
					tracer.level			= (tracer.level == LogEventLevel.ALL) ? LogEventLevel.DEBUG : tracer.level;
					tracer.includeDate		= false;
					tracer.includeTime		= true;
					tracer.includeCategory  = true;
					tracer.includeLevel     = true;
				}
			}
		}
		
		// ========================================
		// static stuff above
		// ========================================
		// ========================================
		// instance stuff below
		// ========================================
		
		protected var _category:String;
		
		public function LocaleLogger( className:String , locker:ConstructorLock)
		{
			super();
			
			_category = className;
		}
		
		/**
		 *  The category this logger send messages for.
		 */
		public function get category():String
		{
			return _category;
		}
		
		protected function constructMessage( msg:String, params:Array ):String
		{
			// replace all of the parameters in the msg string
			for( var i:int = 0; i < params.length; i++ )
			{
				msg = msg.replace( new RegExp( "\\{" + i + "\\}", "g" ), params[ i ] );
			}
			return msg;
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 *  @inheritDoc
		 */
		public function log( level:int, msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), level ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function debug( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.DEBUG ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function info( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.INFO ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function warn( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.WARN ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function error( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.ERROR ) );
			}
		}
		
		/**
		 *  @inheritDoc
		 */
		public function fatal( msg:String, ... rest ):void
		{
			if( hasEventListener( LogEvent.LOG ) )
			{
				dispatchEvent( new LogEvent( constructMessage( msg, rest ), LogEventLevel.FATAL ) );
			}
		}
	}
}

class ConstructorLock {
}

