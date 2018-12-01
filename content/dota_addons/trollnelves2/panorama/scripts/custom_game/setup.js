var customHealthRegenLabel;
var customHpReg = {};
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
    // Hide tp slot
    centerBlock.FindChildTraverse("inventory_tpscroll_container").style.visibility = "collapse";

    //fuck backpack UI (We have Lua filling these slots with junk, and if the player can't touch them it should be effectively disabled)
    var inventory = centerBlock.FindChildTraverse("inventory").FindChildTraverse("inventory_items");
    var backpack = inventory.FindChildTraverse("inventory_backpack_list")
    backpack.style.visibility = "collapse";
    //Add resource panel instead of backpack 
    var resourcePanel = $.CreatePanel( "Panel", inventory, "" );
    resourcePanel.BLoadLayout( "file://{resources}/layout/custom_game/resource.xml", false, false );

    var healthContainer = centerBlock.FindChildTraverse("HealthContainer");
    var healthRegenLabel = healthContainer.FindChildTraverse("HealthRegenLabel");
    InitializeCustomHpRegenLabel(healthContainer);
    healthContainer.FindChildTraverse("HealthRegenLabel").style.visibility = "collapse";
    
	GameEvents.Subscribe( "gameui_activated", UpdateUI);
	GameEvents.Subscribe( "dota_portrait_ability_layout_changed", UpdateAbilityTooltips);
	GameEvents.Subscribe( "dota_ability_changed", UpdateAbilityTooltips);
	GameEvents.Subscribe( "dota_inventory_changed", UpdateItemTooltips);
	GameEvents.Subscribe( "dota_inventory_item_changed", UpdateItemTooltips);
	GameEvents.Subscribe( "m_event_keybind_changed", UpdateTooltips);
	GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateUI);
	GameEvents.Subscribe( "dota_player_update_query_unit", UpdateUI);
	GameEvents.Subscribe( "custom_hp_reg", function(args){customHpReg[args.unit] = args.value;UpdateHpRegLabel();});
})();

function InitializeCustomHpRegenLabel(healthContainer) {
    customHealthRegenLabel = $.CreatePanel("Label", healthContainer, "CustomHealthRegenLabel");
    customHealthRegenLabel.AddClass("MonoNumbersFont");
    customHealthRegenLabel.style.zIndex = 4;
    customHealthRegenLabel.style.color = "#3ED038";
    customHealthRegenLabel.style.fontSize = "14px";
    customHealthRegenLabel.style.textShadow = "2px 2px 0px 1.0 #00000066";
    customHealthRegenLabel.style.fontWeight = "bold";
    customHealthRegenLabel.style.marginTop = "-1px";
    customHealthRegenLabel.style.marginRight = "4px";
    customHealthRegenLabel.style.textAlign = "right";
    customHealthRegenLabel.style.horizontalAlign = "right";
    customHealthRegenLabel.style.verticalAlign = "center";
    customHealthRegenLabel.style.paddingRight = "2px";
}

function UpdateHpRegLabel(){
    var localHero = Players.GetLocalPlayerPortraitUnit();
	customHealthRegenLabel.text = "+" + parseFloat(Entities.GetHealthThinkRegen(localHero) + (customHpReg[localHero] || 0)).toFixed(2);
}

function UpdateTooltips() {
    UpdateItemTooltips();
    UpdateAbilityTooltips();
}

function UpdateUI() {
    UpdateTooltips();
    UpdateHpRegLabel();
}


function UpdateAbilityTooltips() {
    const abilityListPanel = $.GetContextPanel().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("abilities");
    for(var i = 0; i < 16; i++) {
        var abilityPanel = abilityListPanel.FindChildTraverse("Ability" + i);
        if(abilityPanel != null) {
            var buttonWell = abilityPanel.FindChildTraverse("ButtonWell");
            abilityPanel.SetPanelEvent("onmouseover", (function(index, tooltipParent) {
                return function(){
                    var entityIndex = Players.GetLocalPlayerPortraitUnit();
                    var abilityName = Abilities.GetAbilityName(Entities.GetAbility(entityIndex, index));
                    $.DispatchEvent("UIShowCustomLayoutParametersTooltip", tooltipParent, "AbilityTooltip",
                        "file://{resources}/layout/custom_game/ability_tooltip.xml", "entityIndex=" + entityIndex + "&abilityName="+abilityName);
                }
            })(i, buttonWell));
            abilityPanel.SetPanelEvent("onmouseout", 
                function(){
            		$.DispatchEvent("UIHideCustomLayoutTooltip","AbilityTooltip");
                });
        }
    }
}

function UpdateItemTooltips() {
    const inventoryListContainer = $.GetContextPanel().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("inventory_list_container");
    for(var i = 0; i < 6; i++) {
        var inventoryPanel = inventoryListContainer.FindChildTraverse("inventory_slot_" + i);
        if(inventoryPanel != null) {
            var buttonWell = inventoryPanel.FindChildTraverse("ButtonWell");
            inventoryPanel.SetPanelEvent("onmouseover", (function(index, tooltipParent, inventoryPanel) {
                return function(){
                    if(inventoryPanel.BHasClass("no_ability")) {
                        return;
                    }
                    var entityIndex = Players.GetLocalPlayerPortraitUnit();
                    var abilityName = Abilities.GetAbilityName(Entities.GetItemInSlot(entityIndex, index));
                    $.DispatchEvent("UIShowCustomLayoutParametersTooltip", tooltipParent, "AbilityTooltip",
                        "file://{resources}/layout/custom_game/ability_tooltip.xml", "entityIndex=" + entityIndex + "&abilityName="+abilityName);
                }
            })(i, buttonWell, inventoryPanel));
            inventoryPanel.SetPanelEvent("onmouseout", 
                function(){
            		$.DispatchEvent("UIHideCustomLayoutTooltip","AbilityTooltip");
                });
            // (function(index, tooltipParent) {
            //     return function(){
            //         $.Msg("HEHEHEHELEHLEHEOfaklsdfjasd;klgj;lasdkjfals;kgjasdlk;fhsadgladshfsghasdklfhdsaglkasdhflkasdhgadlskh");
            //         var entityIndex = Players.GetLocalPlayerPortraitUnit();
            //         var item = Entities.GetItemInSlot(entityIndex, index);
            //         var bControllable = Entities.IsControllableByPlayer( entityIndex, Game.GetLocalPlayerID() );
            //         var bSellable = Items.IsSellable( item ) && Items.CanBeSoldByLocalPlayer( item );

            //         if ( !bSellable)
            //         {
            //             // don't show a menu if there's nothing to do
            //             return;
            //         }

            //         var contextMenu = $.CreatePanel( "ContextMenuScript", $.GetContextPanel(), "" );
            //         contextMenu.AddClass( "ContextMenu_NoArrow" );
            //         contextMenu.AddClass( "ContextMenu_NoBorder" );
            //         contextMenu.GetContentsPanel().Item = item;
            //         contextMenu.GetContentsPanel().SetHasClass( "bSellable", bSellable );
            //         contextMenu.GetContentsPanel().BLoadLayout( "file://{resources}/layout/custom_game/dota_inventory_context_menu.xml", false, false );
            //     }
            // })(i, buttonWell));
        }
    }
}