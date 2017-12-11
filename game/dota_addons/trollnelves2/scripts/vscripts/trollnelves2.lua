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
-- This library can be used for advancted physics/motion/collision of units.  See PhysicsReadme.txt for more information.
require('libraries/physics')
-- This library can be used for advanced 3D projectile systems.
require('libraries/projectiles')
-- This library can be used for sending panorama notifications to the UIs of players/teams/everyone
require('libraries/notifications')
-- This library can be used for starting customized animations on units from lua
require('libraries/animations')
-- This library can be used for performing "Frankenstein" attachments on units
require('libraries/attachments')
require('libraries/popups')
require('libraries/team')
require('libraries/player')


-- These internal libraries set up trollnelves2's events and processes.  Feel free to inspect them/change them if you need to.
require('internal/trollnelves2')
require('internal/events')

-- settings.lua is where you can specify many different properties for your game mode and is one of the core trollnelves2 files.
require('settings')
-- events.lua is where you can specify the actions to be taken when any event occurs and is one of the core trollnelves2 files.
require('events')

--[[
	This function should be used to set up Async precache calls at the beginning of the gameplay.

	In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
	after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
	be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
	precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
	defined on the unit.

	This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
	time, you can call the functions individually (for example if you want to precache units in a new wave of
	holdout).

	This function should generally only be used if the Precache() function in addon_game_mode.lua is not working.
]]
function trollnelves2:PostLoadPrecache()
	DebugPrint("[TROLLNELVES2] Performing Post-Load precache")
end

--[[
	This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
	It can be used to initialize state that isn't initializeable in Inittrollnelves2() but needs to be done before everyone loads in.
]]
function trollnelves2:OnFirstPlayerLoaded()
	DebugPrint("[TROLLNELVES2] First Player has loaded")
	if string.match(GetMapName(),"winter") then
		GameRules:GetGameModeEntity():SetCameraDistanceOverride(1400)
	end
end


function trollnelves2:OnPlayerReconnect(event)
	local playerID = event.PlayerID
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if hero:HasModifier("modifier_disconnected") then
		hero:RemoveModifierByName("modifier_disconnected")
	end
	if string.match(hero:GetUnitName(),"wisp") and hero.alive == false then
		if hero.dced and hero.dced == true then
			hero.alive = true
			hero.dced = false
			PlayerResource:modifyGold(hero,0)
			PlayerResource:modifyLumber(hero,0)
			PlayerResource:modifyFood(hero,0)
			modifyLumberPrice(0)
		else
			local player = PlayerResource:GetPlayer(playerID)
			if player then
				CustomGameEventManager:Send_ServerToPlayer(player, "show_helper_options", { })
			end
		end
	end
	if GameRules.trollID and playerID == GameRules.trollID then
		GameRules.trollHero:SetControllableByPlayer(playerID, false)
	end
	if hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
		local player = PlayerResource:GetPlayer(playerID)
		if player then
			CustomGameEventManager:Send_ServerToPlayer(player, "hide_cheese_panel", { })
		end
	end
end

function trollnelves2:OnDisconnect(event)
	local playerID = event.PlayerID
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local team = hero:GetTeamNumber()
	if team == DOTA_TEAM_GOODGUYS then
		hero:AddNewModifier(nil, nil, "modifier_disconnected", {})
		if hero.alive == true then
			hero.alive = false
			hero.dced = true
			local lastAlive = true
			for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) do
				local pID = PlayerResource:GetNthPlayerIDOnTeam(2, i)
				local hero2 = PlayerResource:GetSelectedHeroEntity(pID) or false
				if hero2 and hero2.alive then
						lastAlive = false
						break
				end
			end
			if lastAlive then
					hero:RemoveModifierByName("modifier_disconnected")
			end
		end
	elseif team == DOTA_TEAM_BADGUYS then
		hero:MoveToPosition(Vector(0,0,0))
	end
end

function trollnelves2:OnConnectFull(keys)
	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local player = EntIndexToHScript(entIndex)
	local userID = keys.userid
	GameRules.userIds = GameRules.userIds or {}
	-- The Player ID of the joining player
	local playerID = player:GetPlayerID()
	GameRules.userIds[userID] = playerID
	trollnelves2:_Capturetrollnelves2()
end

function trollnelves2:OnGameRulesStateChange()
	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		GameRules.trolls = {}
		local playerCount = PlayerResource:GetPlayerCountForTeam( DOTA_TEAM_GOODGUYS )
		for i=1,playerCount do
			local pID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i)
			local player_choise = GameRules.players[pID] or 1
			if player_choise == 2 then
				table.insert(GameRules.trolls,pID)
			end
		end
		local trollPlayer
		if #GameRules.trolls > 0 then
			trollPlayer = GameRules.trolls[math.random(#GameRules.trolls)]
		else
			trollPlayer = math.random(playerCount) - 1
		end
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS , 12)
		if not GameRules.test then
			PlayerResource:SetCustomTeamAssignment( trollPlayer , DOTA_TEAM_BADGUYS )
			GameRules.trollID = trollPlayer
		end
	elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
		self:PreStart()
	end
end

--[[
	This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
	It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function trollnelves2:OnAllPlayersLoaded()
	DebugPrint("[TROLLNELVES2] All Players have loaded into the game")
	
end

function trollnelves2:InventoryUpdated(keys)

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
	PlayerResource:setGold(hero,0)
	PlayerResource:setLumber(hero,0) -- Secondary resource of the player
	if GameRules.stunHeroes then
		hero:AddNewModifier(nil, nil, "modifier_stunned", { })
		table.insert(GameRules.heroes,hero)
	end
	local pID = hero:GetPlayerOwnerID()
	Timers:CreateTimer(0.25,function()
		local player = PlayerResource:GetPlayer(pID)
		if player then
			CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = PlayerResource:getLumber(pID) })
			CustomGameEventManager:Send_ServerToPlayer(player, "player_custom_gold_changed", { gold = PlayerResource:getGold(pID) })
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

	local root = CreateItem("item_root_ability",hero,hero)
	local silence = CreateItem("item_silence_ability",hero,hero)
	local glyph = CreateItem("item_glyph_ability",hero,hero)
	local night = CreateItem("item_night_ability",hero,hero)
	local blink = CreateItem("item_blink_datadriven",hero,hero)
	hero:AddItem(rock)
	hero:AddItem(root)
	hero:AddItem(silence)
	hero:AddItem(glyph)
	hero:AddItem(night)
	hero:AddItem(blink)


	-- Learn all abilities (this isn't necessary on creatures)
	for i=0,15 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then ability:SetLevel(ability:GetMaxLevel()) end
	end
	hero:SetAbilityPoints(0)
	Timers.CreateTimer(0.03,function()
			UpdateSpells(hero)
		end)
	PlayerResource:setGold(hero,30)
	PlayerResource:setLumber(hero,0) -- Secondary resource of the player
	PlayerResource:modifyFood(hero,0)
	hero:NotifyWearablesOfModelChange(false)
end


function InitializeTroll(hero)
	local pID = hero:GetPlayerOwnerID()
	GameRules.trollID = pID
	PrecacheUnitByNameAsync("npc_dota_hero_troll_warlord",
		function()          
			PlayerResource:ReplaceHeroWith(pID, "npc_dota_hero_troll_warlord", 0 , 0)
			UTIL_Remove(hero)
			hero = PlayerResource:GetSelectedHeroEntity(pID)
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
			local item_count = hero:GetNumItemsInInventory()
			for i=0, item_count do
				local item = hero:GetItemInSlot(i)
				hero:RemoveItem(item)
			end
			PlayerResource:modifyGold(hero,0)
			PlayerResource:modifyLumber(hero,0) -- Secondary resource of the player
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
		end, 
	pID)

end


function trollnelves2:OnHeroInGame(hero)
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
	modifyLumberPrice(0)
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
							PlayerResource:setGold(pHero,0)
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

--[[
	This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
	gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
	is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function trollnelves2:OnGameInProgress()
	DebugPrint("[TROLLNELVES2] The game has officially begun")

end



-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function trollnelves2:Inittrollnelves2()
	trollnelves2 = self
	DebugPrint('[TROLLNELVES2] Starting to load trollnelves2 trollnelves2...')
	trollnelves2:_Inittrollnelves2()
	CustomGameEventManager:RegisterListener( "player_vote", OnPlayerVote )
	DebugPrint('[TROLLNELVES2] Done loading trollnelves2 trollnelves2!\n\n')
end

function trollnelves2:OnPlayerChat(keys)

end

function modifyLumberPrice(amount)
	amount = string.match(amount,"[-]?%d+") or 0
	if GameRules.lumber_price + amount < 10 then
		GameRules.lumber_price = 10
	else
		GameRules.lumber_price = GameRules.lumber_price + amount
	end
	CustomGameEventManager:Send_ServerToAllClients("player_lumber_price_changed", {lumberPrice = GameRules.lumber_price} )
end

function setResourceValues()
	for pID=0,DOTA_MAX_PLAYERS do
		if PlayerResource:IsValidPlayer( pID ) then
			CustomNetTables:SetTableValue("resources", tostring(pID) .. "_resource_stats", { gold = PlayerResource:getGold(pID),lumber = PlayerResource:getLumber(pID) , goldGained = PlayerResource:getGoldGained(pID) , lumberGained = PlayerResource:getLumberGained(pID) , goldGiven = PlayerResource:getGoldGiven(pID) , lumberGiven = PlayerResource:getLumberGiven(pID) , timePassed = GameRules:GetGameTime() - GameRules.startTime })
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

function CDOTA_BaseNPC:GetCollisionSize()
	if GetUnitKV(self:GetUnitName()) then
		return GetUnitKV(self:GetUnitName(),"CollisionSize")
	elseif GetUnitKV(self:GetUnitName()) then
		return GetUnitKV(self:GetUnitName(), "CollisionSize")
	end
end