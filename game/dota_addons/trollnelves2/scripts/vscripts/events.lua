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

	local team = PlayerResource:GetTeam(playerID)
	if team == DOTA_TEAM_BADGUYS then
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