package com.mindspace.l10n.commands
{
	import com.mindspace.l10n.events.LocaleEvent;

	public interface ILocaleCommand
	{
		
		function execute(event:LocaleEvent):void;
	}
}