(function () {
    //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );      //Time of day (clock).
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );     //Heroes and team score at the top of the HUD.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );      //Lefthand flyout scoreboard.
    //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, false );     //Hero actions UI.
    //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false );     //Minimap.
    //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false );      //Entire Inventory UI
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );     //Shop portion of the Inventory.
    //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, false );      //Player items.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );     //Quickbuy.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );      //Courier controls.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );      //Glyph.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false );     //Gold display.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );      //Suggested items shop panel.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS, false );     //Hero selection Radiant and Dire player lists.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME, false );     //Hero selection game mode name display.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK, false );     //Hero selection clock.
    //GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, false );     //Top-left menu buttons in the HUD.
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );      //Endgame scoreboard.    
    GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false );     //Top-left menu buttons in the HUD.

    // These lines set up the panorama colors used by each team (for game select/setup, etc)
    GameUI.CustomUIConfig().team_colors = {}
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#00CC00;";
    GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#FF0000;";

    var tooltipManager = $.GetContextPanel().GetParent().GetParent().FindChildTraverse("Tooltips");
    tooltipManager.AddClass("CustomTooltipStyle");

    var newUI = $.GetContextPanel().GetParent().GetParent().FindChildTraverse("HUDElements");
    var centerBlock = newUI.FindChildTraverse("center_block");

    newUI.FindChildTraverse("RadarButton").style.visibility = "collapse";

    //Use 284 if you want to keep 4 ability minimum size, and only use 160 if you want ~2 ability min size
    centerBlock.FindChildTraverse("AbilitiesAndStatBranch").style.minWidth = "284px";

    centerBlock.FindChildTraverse("StatBranch").style.visibility = "collapse";
    //you are not spawning the talent UI, fuck off (Disabling mouseover and onactivate)
    //We also don't want to crash, valve plz
    centerBlock.FindChildTraverse("StatBranch").SetPanelEvent("onmouseover", function(){});
    centerBlock.FindChildTraverse("StatBranch").SetPanelEvent("onactivate", function(){});

    // Remove xp circle
    centerBlock.FindChildTraverse("xp").style.visibility = "collapse";
    centerBlock.FindChildTraverse("stragiint").style.visibility = "collapse";
    //Fuck that levelup button
    centerBlock.FindChildTraverse("level_stats_frame").style.visibility = "collapse";

    //fuck backpack UI (We have Lua filling these slots with junk, and if the player can't touch them it should be effectively disabled)
    var inventory = centerBlock.FindChildTraverse("inventory").FindChildTraverse("inventory_items");
    var backpack = inventory.FindChildTraverse("inventory_backpack_list")
    backpack.style.visibility = "collapse";
    //Add resource panel instead of backpack 
    var resourcePanel = $.CreatePanel( "Panel", inventory, "" );
    resourcePanel.BLoadLayout( "file://{resources}/layout/custom_game/resource.xml", false, false );
})();