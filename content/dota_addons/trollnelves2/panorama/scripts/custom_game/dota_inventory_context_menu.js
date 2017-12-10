"use strict";

function DismissMenu()
{
	$.DispatchEvent( "DismissAllContextMenus" )
}

function OnSell()
{
	GameEvents.SendCustomGameEventToServer( "sell_item", { item:$.GetContextPanel().Item});
	DismissMenu();
}
