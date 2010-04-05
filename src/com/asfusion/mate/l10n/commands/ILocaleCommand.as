package com.asfusion.mate.l10n.commands
{
	import com.asfusion.mate.l10n.events.LocaleEvent;

	public interface ILocaleCommand
	{
		
		function execute(event:LocaleEvent):void;
	}
}