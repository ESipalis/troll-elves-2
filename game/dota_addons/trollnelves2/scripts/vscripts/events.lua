function trollnelves2:OnGameRulesStateChange()
	DebugPrint("GameRulesStateChange ******************")
	local newState = GameRules:State_Get()
	DebugPrint(newState)
	if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		trollnelves2:GameSetup()
	elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
		self:PreStart()
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function trollnelves2:OnNPCSpawned(keys)
  DebugPrint("OnNPCSpawned ******************")
  local npc = EntIndexToHScript(keys.entindex)

  if npc.GetPhysicalArmorValue then
    npc:AddNewModifier(npc, nil, "modifier_custom_armor", {})
  end

  if npc:IsRealHero() and npc.bFirstSpawned == nil then
    npc.bFirstSpawned = true
    trollnelves2:OnHeroInGame(npc)
  end
end

function trollnelves2:OnPlayerReconnect(event)
	local playerID = event.PlayerID
	local notSelectedHero = GameRules.disconnectedHeroSelects[playerID]
	if notSelectedHero then
		PlayerResource:SetSelectedHero(playerID, notSelectedHero)
	end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if hero then
		if hero:HasModifier("modifier_disconnected") then
			hero:RemoveModifierByName("modifier_disconnected")
		end
		if hero:GetUnitName() == ELF_HERO and hero.alive == false then
			if hero.dced == true then
				hero.alive = true
				hero.dced = false
				-- Send info to client
				PlayerResource:ModifyGold(hero,0)
				PlayerResource:ModifyLumber(hero,0)
				PlayerResource:ModifyFood(hero,0)
				ModifyLumberPrice(0)
			else
				local player = PlayerResource:GetPlayer(playerID)
				if player then
					CustomGameEventManager:Send_ServerToPlayer(player, "show_helper_options", { })
				end
			end
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
  	DebugPrint("OnConnectFull ******************")
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

--[[
	This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
	It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function trollnelves2:OnAllPlayersLoaded()
	DebugPrint("[TROLLNELVES2] All Players have loaded into the game")
	
end


function trollnelves2:OnEntityKilled(keys)
    local killed = EntIndexToHScript(keys.entindex_killed)
    local attacker = EntIndexToHScript(keys.entindex_attacker)
    local bounty = -1
    local killedID = killed:GetPlayerOwnerID()
    local attackerID = attacker:GetPlayerOwnerID()
	
    if killed:IsRealHero() then
        if killed:IsElf() and killed.alive then
            bounty = ElfKilled(killed)
            if CheckTrollVictory() then
                SetResourceValues()
                Stats.SubmitMatchData(DOTA_TEAM_BADGUYS, callback)
                GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
                return
            end
        elseif killed:IsTroll() then
            SetResourceValues()
            Stats.SubmitMatchData(DOTA_TEAM_GOODGUYS, callback)
            GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
        elseif killed:IsWolf() then
            bounty = math.max(killed:GetNetworth() * 0.10,GameRules:GetGameTime())
            RespawnHelper(killed)
        elseif killed:IsAngel() then
            bounty = math.max(PlayerResource:GetGold(killedID),GameRules:GetGameTime())
            PlayerResource:SetGold(killed,0)
            RespawnHelper(killed)
        end
    end
    if bounty>=0 and attacker~=killed then
        local killedName = PlayerResource:GetSelectedHeroEntity(killedID) 
                and PlayerResource:GetSelectedHeroEntity(killedID):GetUnitName() or killed:GetUnitName()
        local attackerName = PlayerResource:GetSelectedHeroEntity(attackerID) 
                and PlayerResource:GetSelectedHeroEntity(attackerID):GetUnitName() or attacker:GetUnitName()
        bounty = math.floor(bounty)
        PlayerResource:ModifyGold(attacker,bounty)
        local message = "%s1 (" .. GetModifiedName(attackerName)  .. ") killed " .. PlayerResource:GetPlayerName(killedID) .. " (" .. GetModifiedName(killedName) .. ") for <font color='#F0BA36'>"..bounty.."</font> gold!"
        GameRules:SendCustomMessage(message, attackerID, 0)
    end
    if not killed:IsNull() and killed:GetKeyValue("FoodCost") then
        local food_cost = killed:GetKeyValue("FoodCost")
        local hero = PlayerResource:GetSelectedHeroEntity(killedID)
        PlayerResource:ModifyFood(hero,-food_cost)
    end

end

function ElfKilled(killed)
    local killedID = killed:GetPlayerOwnerID()
    killed.alive = false
    killed.legitChooser = true

    local bounty = PlayerResource:GetGold(killedID)
    PlayerResource:SetGold(killed,0)
	PlayerResource:SetLumber(killed,0)
	
    for i=1,#killed.units do
		if killed.units[i] then
			local unit = killed.units[i]
            if unit.minimapEntity then
                UTIL_Remove(unit.minimapEntity)
			end
			unit:ForceKill(false)
        end
    end
    killed:SetAbsOrigin(Vector(-10000,-10000,0))
    PlayerResource:SetCameraTarget(killedID, GameRules.trollHero)

    if GameRules:GetGameTime() - GameRules.startTime < WOLF_START_SPAWN_TIME then
        local args = {}
        args.team = DOTA_TEAM_GOODGUYS
        args.playerID = killedID
		ChooseHelpSide(args)
    else
        local orgPlayer = killed:GetPlayerOwner()
        if orgPlayer then
            CustomGameEventManager:Send_ServerToPlayer(orgPlayer, "show_helper_options", { })
            Timers:CreateTimer(30,function()
                if killed and killed.legitChooser then
                    local args = {}
                    args.team = RandomInt(0, 1) == 1 and DOTA_TEAM_GOODGUYS or DOTA_TEAM_BADGUYS
                    args.playerID = killedID
                    ChooseHelpSide(args)
                end
            end)
        else
            GameRules.dcedChoosers[killedID] = true
        end
    end

    return bounty
end

function CheckTrollVictory()
    for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) do
        local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i)
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        if hero and hero.alive then
            return false
        end
    end
    return true
end


function GiveResources( event )
    local targetID = event.target
    local casterID = event.casterID
    local gold = math.floor(math.abs(tonumber(event.gold)))
    local lumber = math.floor(math.abs(tonumber(event.lumber)))
    if tonumber(event.gold) ~= nil and tonumber(event.lumber) ~= nil then
        if PlayerResource:GetSelectedHeroEntity(targetID) and PlayerResource:GetSelectedHeroEntity(targetID):GetTeam() == PlayerResource:GetSelectedHeroEntity(event.casterID):GetTeam() then
            local hero = PlayerResource:GetSelectedHeroEntity(targetID)
            local casterHero = PlayerResource:GetSelectedHeroEntity(casterID)
            if gold and lumber then
                if PlayerResource:GetGold(casterID) < gold or PlayerResource:GetLumber(casterID) < lumber then
                    SendErrorMessage(casterID, "#error_not_enough_resources")
                    return
                end
                PlayerResource:ModifyGold(casterHero,-gold,true)
                PlayerResource:ModifyLumber(casterHero,-lumber,true)
                PlayerResource:ModifyGold(hero,gold,true)
                PlayerResource:ModifyLumber(hero,lumber,true)
                PlayerResource:ModifyGoldGiven(targetID,-gold)
                PlayerResource:ModifyLumberGiven(targetID,-lumber)
                PlayerResource:ModifyGoldGiven(casterID,gold)
                PlayerResource:ModifyLumberGiven(casterID,lumber)
                if gold > 0 or lumber > 0 then
                    local text = PlayerResource:GetPlayerName(casterHero:GetPlayerOwnerID()) .. "(" .. GetModifiedName(casterHero:GetUnitName()) .. ") has sent "
                    if gold > 0 then
                        text = text .. "<font color = '#F0BA36'>" .. gold .. "</font> gold"
                    end
                    if gold > 0 and lumber > 0 then
                        text = text .. " and "
                    end
                    if lumber > 0 then
                        text = text .. "<font color = '#009900'>" .. lumber .. "</font> lumber"
                    end
                    text = text ..  " to " .. PlayerResource:GetPlayerName(hero:GetPlayerOwnerID()) .. "(" .. GetModifiedName(hero:GetUnitName()) .. ")!" 
                    GameRules:SendCustomMessageToTeam(text,casterHero:GetTeamNumber(),0,0)
                end
            else
                SendErrorMessage(event.casterID, "#error_enter_only_digits")
            end
        else
            SendErrorMessage(event.casterID, "#error_select_only_your_allies")
        end
    else
        SendErrorMessage(event.casterID, "#error_type_only_digits")
    end
end

function ChooseHelpSide(event)
    local team = event.team
    local pID = event.playerID
    local player = PlayerResource:GetPlayer(pID)
    local hero = PlayerResource:GetSelectedHeroEntity(pID)
    if hero then
        hero.legitChooser = false
    end
    Timers:CreateTimer(3,function()
        PlayerResource:SetCameraTarget(pID, nil)
    end)
    if team == DOTA_TEAM_GOODGUYS then
        PlayerResource:ReplaceHeroWith(pID, ANGEL_HERO, 0, 0)
        UTIL_Remove(hero)
        hero = PlayerResource:GetSelectedHeroEntity(pID)
        if hero then
            hero:ClearInventory()
            hero:AddItemByName("item_blink_datadriven")
            hero:SetAbsOrigin(Vector(0,0,0))
            RespawnHelper(hero)
            GameRules:SendCustomMessage("%s1 will keep helping elves and now is an " .. GetModifiedName(ANGEL_HERO) ,pID,0)
        end
    elseif team == DOTA_TEAM_BADGUYS then
        PlayerResource:SetCustomTeamAssignment(pID,team)
        PlayerResource:ReplaceHeroWith(pID, WOLF_HERO, 0, 0)
        UTIL_Remove(hero)
        hero = PlayerResource:GetSelectedHeroEntity(pID)
        if hero then
            hero:ClearInventory()
            RespawnHelper(hero)
			local trollHero = PlayerResource:GetSelectedHeroEntity(GameRules.trollID)
			local trollNetworth = trollHero:GetNetworth()
            local lumber = math.floor(trollNetworth/64000*0.3)
            local gold = math.floor((trollNetworth/64000*0.3 - lumber)*64000)
            PlayerResource:SetLumber(hero,lumber)
            PlayerResource:SetGold(hero,gold)
            PlayerResource:SetUnitShareMaskForPlayer(GameRules.trollID,pID, 2 , true)
            GameRules:SendCustomMessage("%s1 has joined the dark side and now will help " .. GetModifiedName(TROLL_HERO) .. ".%s1 is now a" .. GetModifiedName(WOLF_HERO) ,pID,0)
            Timers:CreateTimer(0.03,function()
                if hero and hero:IsAlive() then
                    AddFOWViewer(hero:GetTeamNumber(), hero:GetAbsOrigin(), 150, 0.03, false)
                end
                if not hero:IsNull() then
                    return 0.03
                end
            end)
        end
    end
    if hero then
        for i=0,15 do
            local ability = hero:GetAbilityByIndex(i)
            if ability then ability:SetLevel(ability:GetMaxLevel()) end
        end
    end

end

function RandomAngelLocation()
    return (GameRules.angel_spawn_points and #GameRules.angel_spawn_points and #GameRules.angel_spawn_points > 0) and GameRules.angel_spawn_points[RandomInt(1, #GameRules.angel_spawn_points)]:GetAbsOrigin() or Vector(0,0,0)
end

function RespawnHelper(hero)
	local team = hero:GetTeamNumber()
	local timer = team == DOTA_TEAM_GOODGUYS and 30 or 5
	local invul = team == DOTA_TEAM_GOODGUYS and true or false
	local pos = team == DOTA_TEAM_GOODGUYS and RandomAngelLocation() or Vector(0,-640,256)
	hero:SetRespawnsDisabled(false)
	hero:ForceKill(true)
	hero:SetRespawnPosition(pos)
	hero:SetTimeUntilRespawn(timer)
	local countdown = timer
	local countdownColor = team == DOTA_TEAM_GOODGUYS and "#0099FF" or "#800000"
	Timers:CreateTimer(0.03,function()
		if countdown > 0 then
			local player = hero:GetPlayerOwner()
			if player then
				Notifications:ClearBottom(player)
				Notifications:Bottom(player,{text="You will respawn in " .. countdown .. " seconds", style={color=countdownColor}, duration=1})
			end
			countdown = countdown - 1
			return 1.0
		else
			hero:RespawnHero(false,false)
			if invul == true then
				hero:AddNewModifier(hero,nil,"modifier_invulnerable",{duration = 5}) 
			end
			hero:NotifyWearablesOfModelChange(false)
		end

	end)
end