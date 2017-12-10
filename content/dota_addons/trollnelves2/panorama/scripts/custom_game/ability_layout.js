//  GetAbilityData(slot)
//  GetAbilityCount()

function EmptyAbilityDataProvider() {
    this.GetAbilityData = function(slot) {
        return {};
    }

    this.GetAbilityCount = function() {
        return 0;
    }
}

function EntityAbilityDataProvider(entityId) {
    this.entityId = entityId;

    this.FilterAbility = function(id) {
        return !Abilities.IsAttributeBonus(id) && Abilities.IsDisplayedAbility(id);
    }

    this.FilterAbilities = function() {
        var abilities = [];
        var count = Entities.GetAbilityCount(this.entityId);

        for (var i = 0; i < count; i++) {
            var ability = Entities.GetAbility(this.entityId, i);

            if (this.FilterAbility(ability)) {
                abilities.push(ability);
            }
        }

        return abilities;
    }

    this.GetAbilityData = function(slot) {
        var ability = this.FilterAbilities()[slot];
        var data = {};

        data.id = ability;
        data.key = Abilities.GetKeybind(ability);
        data.name = Abilities.GetAbilityName(ability);
        data.texture = Abilities.GetAbilityTextureName(ability);
        data.cooldown = Abilities.GetCooldownLength(ability);
        data.ready = Abilities.IsCooldownReady(ability);
        data.remaining = Abilities.GetCooldownTimeRemaining(ability);
        data.activated = Abilities.IsActivated(ability);
        data.enabled = Entities.GetTeamNumber(Abilities.GetCaster(ability)) == Entities.GetTeamNumber(Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() )) && Abilities.GetLevel(ability) != 0;
        data.beingCast = Abilities.IsInAbilityPhase(ability);
        data.toggled = (Abilities.IsToggle(ability) && Abilities.GetToggleState(ability)) || Abilities.GetAutoCastState(ability);
        data.range = Abilities.GetCastRange(ability);
		data.caster = Abilities.GetCaster(ability);
		data.manaCost = Abilities.GetManaCost(ability);
		
        if (data.cooldown == 0 || data.ready){
            data.cooldown = Abilities.GetCooldown(ability);
        }

        return data
    }

    this.GetAbilityCount = function() {
        return this.FilterAbilities().length;
    }

    this.IsSilenced = function() {
        return Entities.IsSilenced(this.entityId);
    }

    this.IsStunned = function() {
        return Entities.IsStunned(this.entityId);
    }

    this.ShowTooltip = function(element, data) {
        //SetCurrentHoverSpell(data);

        var range = data.range.toString();

        if (data.range == 0) {
            range = "None";
        }

        element.SetDialogVariable("description", $.Localize("DOTA_Tooltip_ability_" + data.name + "_Description"));
        element.SetDialogVariable("cooldown", data.cooldown.toFixed(1).toString());
		element.AddClass("image_size");
		var text;
		
		$.DispatchEvent("UIShowCustomLayoutParametersTooltip", element, "AbilityTooltip","file://{resources}/layout/custom_game/ability_tooltip.xml",{name2:"ay lmao",badabum:10});
		var contentsPanel = element.GetParent().GetParent().GetParent().GetParent().GetParent().GetParent().FindChildTraverse("Tooltips").FindChildTraverse("AbilityTooltip").FindChildTraverse("Contents");
		contentsPanel.abilityName = data.name;
		contentsPanel.caster = data.caster;
    }

    this.HideTooltip = function() {
		$.DispatchEvent("UIHideCustomLayoutTooltip","AbilityTooltip" );
    }
}

var mouseOver = -1;
var oldID = 0;

function AbilityBar(elementId) {
    this.element = $(elementId);
    this.abilities = {};
    this.customIcons = {};
	
    this.SetProvider = function(provider) {
        this.provider = provider;
        this.Update();
    }

    this.Update = function() {
        var count = this.provider.GetAbilityCount();
		this.element = $("#AbilityPanel");
        for (var i = 0; i < count; i++) {
			if(i==6){
				this.element = $("#AbilityPanel2");
			}
            this.UpdateSlot(i);
        }

        for (slot in this.abilities) {
            if (slot >= count) {
                this.abilities[slot].Delete();
                delete this.abilities[slot];
            }
        }
    }

    this.UpdateSlot = function(slot) {
		
        var data = this.provider.GetAbilityData(slot);
        data.texture = GetTexture(data, this.customIcons);

        var ability = this.GetAbility(slot);
        ability.SetData(data);
		if(mouseOver == slot && oldID != data.id){
			this.provider.HideTooltip();
			this.provider.ShowTooltip(ability.image, ability.data);
			oldID = data.id;
		}

        if (this.provider.IsSilenced && this.provider.IsStunned) {
            ability.SetDisabled(this.provider.IsSilenced(), this.provider.IsStunned());
        }
		ability.SetDisabled2(!data.enabled);
    }

    this.AddCustomIcon = function(abilityName, iconPath) {
        this.customIcons[abilityName] = iconPath;
    }

    this.GetAbility = function(slot) {
        if (!this.abilities[slot]) {
            var ability = new AbilityButton(this.element,slot);
            this.abilities[slot] = ability;

            for (index in this.abilities) {
                if (index > slot) {
                    this.element.MoveChildBefore(this.abilities[slot].image, this.abilities[index].image)
                    break;
                }
            }
        }

        return this.abilities[slot];
    }

    this.RegisterEvents = function(clickable) {
        for (key in this.abilities) {
            var executeCapture = (function(bar, slot) {
                return function() {
                    // A bit of a hack, can't think of a better way for now
                    var ability = bar.GetAbility(slot);

                    Abilities.ExecuteAbility(ability.data.id, bar.provider.entityId, false);
                }
            } (this, key));
			
			var rightClickCapture = (function(bar, slot) {
                return function() {
                    // A bit of a hack, can't think of a better way for now
                    var ability = bar.GetAbility(slot);
					Game.PrepareUnitOrders( { OrderType: dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO, AbilityIndex: ability.data.id } );
                }
            } (this, key));

            var mouseOverCapture = (function(bar, slot) {
                return function() {
                    var ability = bar.GetAbility(slot);

                    bar.provider.ShowTooltip(ability.image, ability.data);
					mouseOver = slot;
					
					
                }
            } (this, key));

            var mouseOutCapture = (function(bar) {
                return function() {
                    bar.provider.HideTooltip();
					mouseOver = -1;
                }
            } (this));

            var ability = this.abilities[key];

            if (clickable) {
                ability.image.SetPanelEvent("onactivate", executeCapture);
            }
            
            ability.image.SetPanelEvent("onmouseover", mouseOverCapture);
            ability.image.SetPanelEvent("onmouseout", mouseOutCapture);
            ability.image.SetPanelEvent("oncontextmenu", rightClickCapture);
        }
    }
}

function AbilityButton(parent, slot, ability) {
    this.parent = parent;
    this.image = $.CreatePanel("Image", parent, "AbilityImage" + slot);
    this.image.AddClass("AbilityButton");
    this.ability = ability;

    this.inside = $.CreatePanel("Panel", this.image, "");
    this.inside.AddClass("AbilityButtonInside");

    this.shortcut = $.CreatePanel("Label", this.image, "");
    this.shortcut.AddClass("ShortcutText")

    this.cooldown = $.CreatePanel("Label", this.image, "");
    this.cooldown.AddClass("CooldownText");

    this.shineMask = $.CreatePanel("Panel", this.image, "");

    this.silence = $.CreatePanel("Panel", this.image, "");
    this.silence.AddClass("AbilitySilenced");

    this.stun = $.CreatePanel("Panel", this.image, "");
    this.stun.AddClass("AbilityStunned");
	
	this.disabled = $.CreatePanel("Panel", this.image, "");
	this.disabled.AddClass("AbilityDisabled");
	
	this.manaCost = $.CreatePanel("Label", this.image, "");
	this.manaCost.AddClass("ManaCostText");
	

    this.data = {};

    this.SetData = function(data) {
        if (this.data.texture != data.texture) {
            this.image.SetImage(data.texture);
        }

        if (this.data.key != data.key) {
            this.shortcut.text = data.key;
        }

        if (this.data.cooldown != data.cooldown ||
            this.data.ready != data.ready ||
            this.data.remaining != data.remaining ||
            this.data.activated != data.activated) {
            this.SetCooldown(data.remaining, data.cooldown, data.ready, data.activated);
        }
		this.manaCost.text = data.manaCost > 0 && data.manaCost || "";
        this.image.SetHasClass("AbilityBeingCast", data.beingCast);
        this.image.SetHasClass("AbilityButtonToggled", data.toggled);

        this.data = data;
    }

    this.SetCooldown = function(remaining, cd, ready, activated) {
        if (ready && activated) {
            this.image.SetHasClass("AbilityButtonEnabled", true);
            this.image.SetHasClass("AbilityButtonDeactivated", false);
            this.image.SetHasClass("AbilityButtonOnCooldown", false);
        }

        if (!ready){
            this.image.SetHasClass("AbilityButtonEnabled", false);
            this.image.SetHasClass("AbilityButtonDeactivated", false);
            this.image.SetHasClass("AbilityButtonOnCooldown", true);
        }

        if (!activated) {
            this.image.SetHasClass("AbilityButtonEnabled", false);
            this.image.SetHasClass("AbilityButtonDeactivated", true);
            this.image.SetHasClass("AbilityButtonOnCooldown", false);
        }

        var progress = (-360 * (remaining / cd)).toString();
        var text = cd.toFixed(1);

        if (!ready){
            text = remaining.toFixed(1);
        }

        if (remaining == 0 && activated) {
            this.shineMask.AddClass("CooldownEndShine");
        } else {
            this.shineMask.RemoveClass("CooldownEndShine"); 
        }

        if (cd == 0 || !activated) {
            progress = 0;
            text = "";
        }

        this.inside.style.clip = "radial(50% 50%, 0deg, " + progress + "deg)";
        this.cooldown.text = text;
    }

    this.SetDisabled = function(silenced, stunned) {
        this.silence.style.opacity = (silenced && !stunned) ? "1.0" : "0.0";
        this.stun.style.opacity = stunned ? "1.0" : "0.0";
    }
	this.SetDisabled2 = function(enabled) {
        this.disabled.style.opacity = enabled ? "1.0" : "0.0";
    }

    this.Delete = function() {
        this.image.visible = false;
        this.image.DeleteAsync(0);
    }

    this.SetDisabled(false, false);
}

var currentHero = null;
var abilityBar = null;
var currentHP = null;
var currentMP = null;
var CurrentDmg = null;
var CurrentBonusDmg = null;
var CurrentArmor = null;

function UpdateUI(){
    $.Schedule(0.025, UpdateUI);

    var localHero = Players.GetLocalPlayerPortraitUnit();

    if (localHero != currentHero) {
        currentHero = localHero;
        LoadHeroUI(localHero);
    }
	if (currentMP != Entities.GetMana(localHero)){
		UpdateMP(localHero);
	}
	if( currentHP != Entities.GetHealth(localHero)){
		UpdateHP(localHero);
	}
	UpdateGoldRemaining(localHero);

    if (abilityBar != null) {
        abilityBar.Update();
    }
}
function UpdateStats(){
	$.Schedule(0.1,function(){
	var localUnit = Players.GetLocalPlayerPortraitUnit();
	UpdateHP(localUnit);
	UpdateHpReg(localUnit);
	UpdateMP(localUnit);
	UpdateMpReg(localUnit);
	UpdateDamage(localUnit);
	UpdateArmor(localUnit);
	});
	
}

function UpdateHP(localHero){
	$("#CurrentHealth").style.width = Entities.GetHealthPercent(localHero).toFixed(1) * 5 + "px"
	$("#HealthText").text = Entities.GetHealth(localHero) + "/" + Entities.GetMaxHealth(localHero);
	var currentHP = Entities.GetHealth(localHero);
}

var customHpReg = {};
function UpdateHpReg(localHero){
	$("#HpRegText").text = "+" + parseFloat(Entities.GetHealthThinkRegen(localHero) + (customHpReg[localHero] || 0)).toFixed(2);
}
function UpdateMpReg(localHero){
	if(Entities.GetMaxMana(localHero) != 0){
		$("#MpRegText").text = "+" + parseFloat(Entities.GetManaThinkRegen(localHero)).toFixed(2);
	}
}
function UpdateMP(localHero){
	if(Entities.GetMaxMana(localHero) != 0){
		$("#CurrentMana").style.width = (Entities.GetMana(localHero)/Entities.GetMaxMana(localHero)*100).toFixed(1) + "%"
		$("#ManaText").text = Entities.GetMana(localHero) + "/" + Entities.GetMaxMana(localHero);
		$("#ManaBar").style.opacity = 1;
		$("#ManaBar").style.height = "25px";
	}else{
		$("#ManaBar").style.opacity = 0;
		$("#ManaBar").style.height = 0;
	}
	var currentMP = Entities.GetMana(localHero);
}

var goldRemaining = {};
var maxGold = {};
function UpdateGoldRemaining(localHero){
	var goldRem = goldRemaining[localHero] || 0;
	var mGold = maxGold[localHero] || 0;
	if (goldRem > 0 && mGold > 0){
		$("#CurrentGold").style.width = (goldRem/mGold*100).toFixed(1) + "%"
		$("#GoldText").text = goldRem + "/" + mGold;
		$("#GoldBar").style.opacity = 1;
	}else{
		$("#GoldBar").style.opacity = 0;
	}
	
}

function UpdateDamage(localHero){
	if (Entities.GetDamageBonus(localHero) != 0){
		$("#AttackText").text = Entities.GetDamageMax(localHero) + "+" + Entities.GetDamageBonus(localHero);
	}else{
		$("#AttackText").text = Entities.GetDamageMax(localHero);
	}
	CurrentDmg = Entities.GetDamageMax(localHero);
	CurrentBonusDmg = Entities.GetDamageBonus(localHero);
	
}

function UpdateArmor(localHero){
	$("#ArmorText").text = Entities.GetPhysicalArmorValue(localHero);
	CurrentArmor = Entities.GetPhysicalArmorValue(localHero);
}


function LoadHeroUI(heroId){
    $("#HeroPortrait").heroname = Entities.GetUnitName(heroId);
    $("#HeroNameLabel").text = $.Localize("#" + Entities.GetUnitName(heroId));

    if (abilityBar == null) {
        abilityBar = new AbilityBar("#AbilityPanel");
    }
	UpdateStats(heroId);
    abilityBar.SetProvider(new EntityAbilityDataProvider(heroId));
    abilityBar.RegisterEvents(true);
}

function GetTexture(data, customIcons) {
    var icon = "file://{images}/spellicons/" + (data.texture || data) + ".png";
    var name = data.name;

    if (customIcons[name]){
        icon = "file://{resources}/images/custom_game/" + customIcons[name];
    }

    return icon;
}

function CenterCamera(){
    GameUI.SetCameraTarget(Players.GetLocalPlayerPortraitUnit());
    $.Schedule(0.025, function() {
        GameUI.SetCameraTarget(-1);
    })
}

(function () {
    UpdateUI();
	GameEvents.Subscribe( "dota_inventory_changed", UpdateStats);
	GameEvents.Subscribe( "dota_inventory_item_changed", UpdateStats);
	GameEvents.Subscribe( "m_event_dota_inventory_changed_query_unit", UpdateStats);
	GameEvents.Subscribe( "m_event_keybind_changed", UpdateStats);
	GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateStats);
	GameEvents.Subscribe( "dota_player_update_query_unit", UpdateStats);
	GameEvents.Subscribe( "item_sold", UpdateStats);
	GameEvents.Subscribe( "unit_upgrade_complete", function(){LoadHeroUI(Players.GetLocalPlayerPortraitUnit());});
	GameEvents.Subscribe( "custom_hp_reg", function(args){customHpReg[args.unit] = args.value;UpdateStats();});
	GameEvents.Subscribe( "gold_remaining_update", function(args){goldRemaining[args.unit] = args.amount;maxGold[args.unit] = args.maxGold;});
})();
