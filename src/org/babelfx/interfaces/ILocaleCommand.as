package org.babelfx.interfaces
{
	import org.babelfx.events.LocaleEvent;

	public interface ILocaleCommand
	{
		
		function execute(event:LocaleEvent):void;
	}
}