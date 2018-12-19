-- This is the primary trollnelves2 trollnelves2 script and should be used to assist in initializing your game mode


-- Set this to true if you want to see a complete debug output of all events/processes done by trollnelves2
-- You can also change the cvar 'trollnelves2_spew' at any time to 1 or 0 for output/no output
TROLLNELVES2_DEBUG_SPEW = true

if trollnelves2 == nil then
	DebugPrint( '[TROLLNELVES2] creating trollnelves2 game mode' )
	_G.trollnelves2 = class({})
end

-- This library allow for easily delayed/timed actions
require('libraries/timers')
-- This library can be used for sending panorama notifications to the UIs of players/teams/everyone
require('libraries/notifications')
require('libraries/popups')
require('libraries/team')
require('libraries/player')
require('libraries/entity')

require('internal/trollnelves2')

require('settings')
require('events')


function trollnelves2:GameSetup()
	DebugPrint("HERE:::" .. PlayerResource:GetPlayerCount())
	Timers:CreateTimer(90, function()
		InitializeTrollIDFromVoting2()

		GameRules:FinishCustomGameSetup()
	end)
end

function InitializeTrollIDFromVoting2() -- Refactor
	local trolls = {}
	local playerCount = PlayerResource:GetPlayerCountForTeam( DOTA_TEAM_GOODGUYS )
	for i=1,playerCount do
		local pID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i)
		PlayerResource:SetCustomTeamAssignment(pID, DOTA_TEAM_GOODGUYS)
		local player_choise = GameRules.players[pID] or 1
		if player_choise == 2 then
			table.insert(trolls,pID)
		end
	end
	local trollPlayer
	if #trolls > 0 then
		trollPlayer = trolls[math.random(#trolls)]
	else
		trollPlayer = math.random(playerCount) - 1
	end
	if not GameRules.test then
	    PlayerResource:SetCustomTeamAssignment( trollPlayer , DOTA_TEAM_BADGUYS )
	    local trollPlayerHandle = PlayerResource:GetPlayer(trollPlayer)
	    trollPlayerHandle:SetSelectedHero("npc_dota_hero_troll_warlord")
		GameRules.trollID = trollPlayer
	end
	local playerCount = PlayerResource:GetPlayerCountForTeam( DOTA_TEAM_GOODGUYS )
	for i=1,playerCount do
    local pID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i)
    local playerHandle = PlayerResource:GetPlayer(pID)
    playerHandle:SetSelectedHero("npc_dota_hero_wisp")
	end

end

function OnPlayerVote(eventSourceIndex, args)
	local playerID = args["pID"]
	local vote = args["team"]
	GameRules.players[playerID] = vote == "troll" and 2 or 1
end

function InitializeHero(hero)
	hero.food = 0
	hero.buildings = {} -- This keeps the name and quantity of each building
	hero.units = {}
	hero.disabledBuildings = {}
	PlayerResource:SetGold(hero,0)
	PlayerResource:SetLumber(hero,0) -- Secondary resource of the player
	if GameRules.stunHeroes then
		hero:AddNewModifier(nil, nil, "modifier_stunned", { })
		table.insert(GameRules.heroes,hero)
	end
	local pID = hero:GetPlayerOwnerID()
	Timers:CreateTimer(0.25,function()
		local player = PlayerResource:GetPlayer(pID)
		if player then
			CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = PlayerResource:GetLumber(pID) })
			CustomGameEventManager:Send_ServerToPlayer(player, "player_custom_gold_changed", { gold = PlayerResource:GetGold(pID) })
		end
		return 0.25
	end)
end

function InitializeBuilder(hero)
	InitializeHero(hero)
	local pID = hero:GetPlayerOwnerID()
	hero.alive = true
	PlayerResource:SetCustomPlayerColor(pID, GameRules.playersColors[GameRules.colorCounter][1], GameRules.playersColors[GameRules.colorCounter][2], GameRules.playersColors[GameRules.colorCounter][3])
	GameRules.colorCounter = GameRules.colorCounter + 1

	hero:ClearInventory()

	local root = CreateItem("item_root_ability",hero,hero)
	local silence = CreateItem("item_silence_ability",hero,hero)
	local glyph = CreateItem("item_glyph_ability",hero,hero)
	local night = CreateItem("item_night_ability",hero,hero)
	local blink = CreateItem("item_blink_datadriven",hero,hero)
	hero:AddItem(root)
	hero:AddItem(silence)
	hero:AddItem(glyph)
	hero:AddItem(night)
	hero:AddItem(blink)

	hero.goldPerSecond = 0
	hero.lumberPerSecond = 0
	Timers:CreateTimer(0.03, function() 
		if hero and not hero:IsNull() then
			PlayerResource:ModifyGold(hero, hero.goldPerSecond)
			PlayerResource:ModifyLumber(hero, hero.lumberPerSecond)
			return 1
		end
	end)


	-- Learn all abilities (this isn't necessary on creatures)
	for i=0,15 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then ability:SetLevel(ability:GetMaxLevel()) end
	end
	hero:SetAbilityPoints(0)
	UpdateSpells(hero)
	PlayerResource:SetGold(hero,30)
	PlayerResource:SetLumber(hero,0) -- Secondary resource of the player
	PlayerResource:ModifyFood(hero,0)

	hero:NotifyWearablesOfModelChange(false)
end


function InitializeTroll(hero)
	local pID = hero:GetPlayerOwnerID()
	GameRules.trollID = pID
	InitializeHero(hero)
	GameRules.trollHero = hero
	hero:AddNewModifier(nil, nil, "modifier_stunned", {duration=GameRules.trollTimer})
	GameRules.trollSpawned = true
	Timers:CreateTimer(0.1,function()
		if hero then
			AddFOWViewer(hero:GetTeamNumber(), hero:GetAbsOrigin(), 150, 0.1, false)
			return 0.1
		end
	end)
	Timers:CreateTimer(0.3,function()
		if hero and not hero:IsNull() then
			local allEntities = Entities:FindAllByClassname("npc_dota_creature")
			for k,v in pairs(allEntities) do
				if v and not v:IsNull() and IsCustomBuilding(v) and v:GetTeamNumber() ~= team and hero:CanEntityBeSeenByMyTeam(v) and not v.minimapEntity then
					v.minimapEntity = CreateUnitByName("minimap_entity", v:GetAbsOrigin(), false, v:GetOwner(), v:GetOwner(), v:GetTeamNumber())
					v.minimapEntity:AddNewModifier(v.minimapEntity, nil, "modifier_minimap", {})
					v.minimapEntity.correspondingEntity = v
				end
			end
			local minimapEntities = Entities:FindAllByClassname("npc_dota_building")
			for k,minimapEnt in pairs(minimapEntities) do
				if minimapEnt and not minimapEnt:IsNull() and hero:CanEntityBeSeenByMyTeam(minimapEnt) and minimapEnt.correspondingEntity and minimapEnt.correspondingEntity == "dead" then
					minimapEnt.correspondingEntity = nil
					minimapEnt:ForceKill(false)
					UTIL_Remove(minimapEnt)
				end
			end
		end
		return 0.3
	end)


	for i=0,15 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then ability:SetLevel(ability:GetMaxLevel()) end
	end
	hero:SetAbilityPoints(0)
	-- Clear inventory
	hero:ClearInventory()
	PlayerResource:ModifyGold(hero,0)
	PlayerResource:ModifyLumber(hero,0) -- Secondary resource of the player
	local player = hero:GetPlayerOwner()
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "hide_cheese_panel", { })
	end
	local units = Entities:FindAllByClassname("npc_dota_creature")
	for _,unit in pairs(units) do
		local unit_name = unit:GetUnitName();
		if string.match(unit_name,"shop") or string.match(unit_name,"troll_hut") then
			unit:SetOwner(hero)
			unit:SetControllableByPlayer(pID, true)
			unit:AddNewModifier(unit,nil,"modifier_invulnerable",{})
			unit:AddNewModifier(unit,nil,"modifier_phased",{})
			table.insert(GameRules.shops,unit)
			if string.match(unit_name,"troll_hut") then
				unit.ancestors = {}
				if hero.buildings[unit:GetUnitName()] then
						hero.buildings[unit:GetUnitName()] = hero.buildings[unit:GetUnitName()] + 1
				else
						hero.buildings[unit:GetUnitName()] = 1
				end
				BuildingHelper:AddModifierBuilding(unit)
				BuildingHelper:BlockGridSquares(GetUnitKV(unit_name,"ConstructionSize"), 0, unit:GetAbsOrigin())
			end
		end
	end
	if GameRules.test then
		hero:AddItemByName("item_dmg_12")
		hero:AddItemByName("item_armor_11")
		hero:AddItemByName("item_hp_11")
		hero:AddItemByName("item_hp_reg_11")
		hero:AddItemByName("item_atk_spd_6")
		hero:AddItemByName("item_disable_repair")
	end

end


function trollnelves2:OnHeroInGame(hero)
	DebugPrint("OnHeroInGame *******************")
	local team = hero:GetTeamNumber()
	local pID = hero:GetPlayerOwnerID()
	if team == DOTA_TEAM_BADGUYS then
		hero.hpReg = 0
		hero.hpRegDebuff = 0
		hero.fullHpReg = 0
		hero.hpRegTimer = Timers:CreateTimer(FrameTime(),function()
			local rate = FrameTime()
			local hpReg = 0
			hero.hpRegDebuff = hero.hpRegDebuff or 0
			hero.fullHpReg = math.max(hero.hpReg-hero.hpRegDebuff,0)
			if hero.fullHpReg > 0 and hero:IsAlive() then
				rate = 1/hero.fullHpReg > rate and 1/hero.fullHpReg or rate
				hpReg = hero.fullHpReg * rate
				hero:SetHealth(hero:GetHealth() + hpReg)
			end
			return rate
		end)
	end
	GameRules.playerCount = GameRules.playerCount + 1

	if PlayerResource:IsElf(hero) then
		--Builder team!
		if team == DOTA_TEAM_GOODGUYS then
			InitializeBuilder(hero)
		--Troll team!
		elseif team == DOTA_TEAM_BADGUYS then
			InitializeTroll(hero)
		end
	end
end

function trollnelves2:PreStart()
	local gameStartTimer = 5
	ModifyLumberPrice(0)
	Timers:CreateTimer(0.03,function()
		if gameStartTimer > 0 then
			Notifications:ClearBottomFromAll()
			Notifications:BottomToAll({text="Game starts in " .. gameStartTimer, style={color='#E62020'}, duration=1})
			gameStartTimer = gameStartTimer - 1
			return 1
		else
			if GameRules.trollSpawned == true then
				Notifications:ClearBottomFromAll()
				Notifications:BottomToAll({text="Game started!", style={color='#E62020'}, duration=1})
				GameRules.startTime = GameRules:GetGameTime()
				GameRules.stunHeroes = false
				for _,pHero in pairs(GameRules.heroes) do
					if pHero and not pHero:IsNull() then
						pHero:RemoveModifierByName("modifier_stunned")
						if string.match(pHero:GetUnitName(),"troll") then
							PlayerResource:SetGold(pHero,0)
							pHero:AddNewModifier(nil, nil, "modifier_stunned", {duration=GameRules.trollTimer})
							local timer = GameRules.trollTimer
							Timers:CreateTimer(0.03,function()
								if timer > 0 then
									Notifications:ClearBottomFromAll()
									Notifications:BottomToAll({text="Troll spawns in " .. timer, style={color='#E62020'}, duration=1})
									timer = timer - 1
									return 1.0
								end
							end)
						end
					end
				end
			else
				Notifications:ClearBottomFromAll()
				Notifications:BottomToAll({text="Troll hasn't spawned yet!Resetting!", style={color='#E62020'}, duration=1})
				gameStartTimer = 5
				return 1.0
			end
		end
	end)
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function trollnelves2:Inittrollnelves2()
	trollnelves2 = self
	DebugPrint('[TROLLNELVES2] Starting to load trollnelves2 trollnelves2...')
	trollnelves2:_Inittrollnelves2()
	DebugPrint('[TROLLNELVES2] Done loading trollnelves2 trollnelves2!\n\n')
end

function ModifyLumberPrice(amount)
	amount = string.match(amount,"[-]?%d+") or 0
	if GameRules.lumber_price + amount < 10 then
		GameRules.lumber_price = 10
	else
		GameRules.lumber_price = GameRules.lumber_price + amount
	end
	CustomGameEventManager:Send_ServerToAllClients("player_lumber_price_changed", {lumberPrice = GameRules.lumber_price} )
end

function SetResourceValues()
	for pID=0,DOTA_MAX_PLAYERS do
		if PlayerResource:IsValidPlayer( pID ) then
			CustomNetTables:SetTableValue("resources", tostring(pID) .. "_resource_stats", { gold = PlayerResource:GetGold(pID),lumber = PlayerResource:GetLumber(pID) , goldGained = PlayerResource:GetGoldGained(pID) , lumberGained = PlayerResource:GetLumberGained(pID) , goldGiven = PlayerResource:GetGoldGiven(pID) , lumberGiven = PlayerResource:GetLumberGiven(pID) , timePassed = GameRules:GetGameTime() - GameRules.startTime })
		end
	end
end

function UpdateSpells(unit)
	local hero = unit:IsRealHero() and unit or PlayerResource:GetSelectedHeroEntity(unit:GetPlayerOwnerID())
	for a = 0,15 do
		local tempAbility = unit:GetAbilityByIndex(a)
		if tempAbility then
			local bIsBuilding = GetAbilityKV(tempAbility:GetAbilityName()) and GetAbilityKV(tempAbility:GetAbilityName()).Building or 0
			if bIsBuilding == 1 then
				local bDisabled = false
				local requirements = GetUnitKV(GetAbilityKV(tempAbility:GetAbilityName()).UnitName).Requirements
				if requirements then
					local ReqsTable = {}
					for uname, ucount in pairs(requirements) do
						if not hero.buildings[uname] or hero.buildings[uname] < ucount then
							ReqsTable[uname] = ucount
							bDisabled = true
						end
					end
					CustomNetTables:SetTableValue("buildings",unit:GetPlayerOwnerID() .. GetAbilityKV(tempAbility:GetAbilityName()).UnitName , ReqsTable)
				end
				local building_name = GetAbilityKV(tempAbility:GetAbilityName()).UnitName
				local unique = GetAbilityKV(tempAbility:GetAbilityName()).UniqueBuilding or 0
				local limit = GetUnitKV(building_name,"Limit") or 0
				if limit > 0 then
					local currentCount = 0
					for k,v in pairs(hero.units) do
						if v and not v:IsNull() then
							if v:GetUnitName() == building_name then
								currentCount = currentCount + 1
							end
							if v.ancestors then
								for key,uname in pairs(v.ancestors) do
									if uname == building_name then
										currentCount = currentCount + 1
									end
								end
							end
						end
					end
					if currentCount >= limit then
						bDisabled = true
					end
				end

				if bDisabled and not GameRules.test then
					tempAbility:SetLevel(0)
					hero.disabledBuildings[building_name] = true
				else
					tempAbility:SetLevel(1)
					if hero.disabledBuildings[building_name] then
						hero.disabledBuildings[building_name] = false
					end
				end
			end
		end
	end
end

function UpdateUpgrades(building)
	if building and not building:IsNull() then
		local hero = building.builder or building:GetOwner()
		local upgrades = GetUnitKV(building:GetUnitName()).Upgrades
		if upgrades then
			if upgrades.Count then
				local abilities = {}
				for a = 0,15 do
					local tempAbility = building:GetAbilityByIndex(a)
					if tempAbility then
						table.insert(abilities,{tempAbility:GetAbilityName(),tempAbility:GetLevel()})
						building:RemoveAbility(tempAbility:GetAbilityName())
					end
				end
				local index = 0
				local count = tonumber(upgrades.Count)
				for i = 1, count, 1 do
					local upgrade = upgrades[tostring(i)]
					local upgraded_unit_name = upgrade.unit_name
					local bDisabled = false
					local ReqsTable = {}
					local ReqsClasses = {}
					--Check the requirements of upgraded unit
					if GetUnitKV(upgraded_unit_name).Requirements then
						for uname, ucount in pairs(GetUnitKV(upgraded_unit_name).Requirements) do
							if not hero.buildings[uname] or hero.buildings[uname] < ucount then
								bDisabled = true
								if not ReqsClasses[GetClass(uname)] then
									ReqsTable[uname] = ucount
									ReqsClasses[GetClass(uname)] = 1
								end
							end
						end
					end
					--Check the current building requirements
					if GetUnitKV(building:GetUnitName()).Requirements then
						for uname, ucount in pairs(GetUnitKV(building:GetUnitName()).Requirements) do
							if not hero.buildings[uname] or hero.buildings[uname] < ucount then
								bDisabled = true
								if not ReqsClasses[GetClass(uname)] then
									ReqsTable[uname] = ucount
									ReqsClasses[GetClass(uname)] = 1
								end
							end
						end
					end
					--Check the requirements of ancestors
					if building.ancestors then
						for _,ancestor in pairs(building.ancestors) do
							if GetUnitKV(ancestor).Requirements then
								for uname, ucount in pairs(GetUnitKV(ancestor).Requirements) do
									if not hero.buildings[uname] or hero.buildings[uname] < ucount then
										bDisabled = true
										if not ReqsClasses[GetClass(uname)] then
											ReqsTable[uname] = ucount
											ReqsClasses[GetClass(uname)] = 1
										end
									end
								end
							end
						end
					end
					CustomNetTables:SetTableValue("buildings", building:GetPlayerOwnerID() .. upgraded_unit_name , ReqsTable)
					local abilityName = "upgrade_to_" .. upgraded_unit_name
					building:AddAbility(abilityName)
					local upgradeAbility = building:GetAbilityByIndex(index)
					local unique = GetAbilityKV(abilityName).UniqueBuilding or 0
					if bDisabled and not GameRules.test then
						upgradeAbility:SetLevel(0)
					else
						upgradeAbility:SetLevel(1)
					end
					index = index + 1
				end
				for key,ability in pairs(abilities) do                    
					local abName
					local abPoints
					abName,abPoints = unpack(ability)
					if not string.match(abName,"upgrade_to") then
						building:AddAbility(abName)
						local tempAbility = building:GetAbilityByIndex(index)
						tempAbility:SetLevel(abPoints)
						index = index + 1
					end
				end
			end
		end
	end
end

function GetClass(unitName)
	if string.match(unitName,"rock") or string.match(unitName,"wall") then
		return "wall"
	elseif string.match(unitName,"tower") then
		return "tower"
	elseif string.match(unitName,"tent") or string.match(unitName,"barrack") then
		return "tent"
	elseif string.match(unitName,"trader") then
		return "trader"
	elseif string.match(unitName,"workers_guild") then
		return "workers_guild"
	elseif string.match(unitName,"mother_of_nature") then
		return "mother_of_nature"
	elseif string.match(unitName,"research_lab") then
		return "research_lab"
	end
end