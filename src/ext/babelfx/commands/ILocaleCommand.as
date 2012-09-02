////////////////////////////////////////////////////////////////////////////////
//	
// Copyright (c) 2012 Mindspace, LLC - http://www.gridlinked.info/
//	
// Open source under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).
// 
////////////////////////////////////////////////////////////////////////////////

package ext.babelfx.commands
{
	import ext.babelfx.events.BabelFxEvent;
	
	import org.swizframework.storage.ISharedObjectBean;
	import org.swizframework.utils.logging.SwizLogger;

	public interface ILocaleCommand
	{
		function get logger()	:SwizLogger;
		function set logger(val : SwizLogger):void;
		
		function get lso()   : ISharedObjectBean;
		function set lso(val : ISharedObjectBean):void;
		
		function get enableUserPreference()   : Boolean;
		function set enableUserPreference(val : Boolean):void;

		function get userPreferredLocale()   : String;
		function set userPreferredLocale(val : String):void;
		
		function execute(event:BabelFxEvent):void;
	}
}